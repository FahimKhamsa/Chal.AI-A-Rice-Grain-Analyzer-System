"""
app/core/ml_manager.py
-----------------------
Manages the lifecycle of heavy AI models (DINO + SAM).

Models are loaded ONCE at server startup into GPU/CPU memory and held as
module-level state so every request reuses the same in-memory weights.

Usage (in main.py startup event):
    from app.core.ml_manager import load_ai_models
    load_ai_models()

Usage (in endpoint):
    from app.core.ml_manager import models
    boxes, _ = detect_objects_dino(img, models.dino_model, models.dino_processor)
"""
import logging
import os

import torch
from transformers import (
    AutoImageProcessor,
    AutoTokenizer,
    GroundingDinoForObjectDetection,
    GroundingDinoProcessor,
    SamImageProcessor,
    SamModel,
    SamProcessor,
)

from app.core.config import settings

logger = logging.getLogger(__name__)

# Redirect HuggingFace cache to /tmp so RunPod's read-only root FS doesn't crash the boot.
# On local dev /tmp is also writable, so this is safe everywhere.
RUNPOD_CACHE_DIR = "/tmp/hf_cache"
os.environ["HF_HOME"] = RUNPOD_CACHE_DIR
os.environ["TRANSFORMERS_CACHE"] = RUNPOD_CACHE_DIR

_APP_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Use local weights when present (fast local dev); fall back to HF download on RunPod.
_DINO_LOCAL = os.path.join(_APP_DIR, "models", "dino")
_SAM_LOCAL  = os.path.join(_APP_DIR, "models", "sam")
# Check for actual weight files — config.json alone is not enough because the
# Dockerfile refresh step also creates config.json via processor save_pretrained.
def _weights_present(directory: str) -> bool:
    return (
        os.path.isfile(os.path.join(directory, "model.safetensors")) or
        os.path.isfile(os.path.join(directory, "pytorch_model.bin"))
    )

DINO_PATH = _DINO_LOCAL if _weights_present(_DINO_LOCAL) else settings.DINO_MODEL_ID
SAM_PATH  = _SAM_LOCAL  if _weights_present(_SAM_LOCAL)  else settings.SAM_MODEL_ID


class MLModels:
    """Container for all loaded model instances and their processors."""

    dino_model: GroundingDinoForObjectDetection | None = None
    dino_processor: GroundingDinoProcessor | None = None
    sam_model: SamModel | None = None
    sam_processor: SamProcessor | None = None
    device: str = "cpu"


# Module-level singleton — shared across all requests
models = MLModels()


def load_ai_models() -> None:
    """
    Loads DINO + SAM from local disk (app/models/) when weights are present,
    otherwise downloads from Hugging Face into /tmp/hf_cache (safe on RunPod).

    This should be called exactly once — from the FastAPI startup event or
    run_serverless.py before runpod.serverless.start().
    """
    device = "cuda" if torch.cuda.is_available() else "cpu"
    compute_dtype = torch.float16 if device == "cuda" else torch.float32
    models.device = device

    os.makedirs(RUNPOD_CACHE_DIR, exist_ok=True)
    logger.info("Loading AI models on device=%s dtype=%s …", device, compute_dtype)

    # ── Grounding DINO ────────────────────────────────────────────────────────
    logger.info("Loading Grounding DINO from %s …", DINO_PATH)
    # Construct the processor from its sub-components rather than using the
    # composite from_pretrained path. transformers 4.45+ has a regression in
    # ProcessorMixin.from_args_and_dict that passes image_processor twice when
    # the saved preprocessor_config.json also contains an image_processor key,
    # causing TypeError: got multiple values for argument 'image_processor'.
    _img_proc  = AutoImageProcessor.from_pretrained(DINO_PATH, cache_dir=RUNPOD_CACHE_DIR)
    _tokenizer = AutoTokenizer.from_pretrained(DINO_PATH, cache_dir=RUNPOD_CACHE_DIR)
    models.dino_processor = GroundingDinoProcessor(
        image_processor=_img_proc, tokenizer=_tokenizer
    )
    models.dino_model = GroundingDinoForObjectDetection.from_pretrained(
        DINO_PATH,
        torch_dtype=compute_dtype,
        cache_dir=RUNPOD_CACHE_DIR,
    ).to(device)
    models.dino_model.eval()

    # ── SAM ───────────────────────────────────────────────────────────────────
    logger.info("Loading SAM from %s …", SAM_PATH)
    # Same sub-component workaround as DINO — from_pretrained passes image_processor
    # twice when the saved config also contains it, causing TypeError.
    _sam_img_proc = SamImageProcessor.from_pretrained(SAM_PATH, cache_dir=RUNPOD_CACHE_DIR)
    models.sam_processor = SamProcessor(image_processor=_sam_img_proc)
    models.sam_model = SamModel.from_pretrained(
        SAM_PATH,
        torch_dtype=compute_dtype,
        cache_dir=RUNPOD_CACHE_DIR,
    ).to(device)
    models.sam_model.eval()

    logger.info("All models loaded successfully.")


def unload_ai_models() -> None:
    """
    Releases model weights from memory. Called on server shutdown to allow
    clean GPU VRAM reclamation in containerised environments.
    """
    logger.info("Unloading AI models …")
    models.dino_model = None
    models.dino_processor = None
    models.sam_model = None
    models.sam_processor = None

    if torch.cuda.is_available():
        torch.cuda.empty_cache()
    logger.info("AI models unloaded.")
