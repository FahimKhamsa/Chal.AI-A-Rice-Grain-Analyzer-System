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
    GroundingDinoForObjectDetection,
    GroundingDinoProcessor,
    SamModel,
    SamProcessor,
)

from app.core.config import settings

logger = logging.getLogger(__name__)

# Paths resolved relative to this file so they work regardless of working directory
_APP_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DINO_PATH = os.path.join(_APP_DIR, "models", "dino")
SAM_PATH = os.path.join(_APP_DIR, "models", "sam")


class MLModels:
    """Container for all loaded model instances and their processors."""

    dino_model: GroundingDinoForObjectDetection | None = None
    dino_processor: GroundingDinoProcessor | None = None
    sam_model: SamModel | None = None
    sam_processor: SamProcessor | None = None
    device: str = "cpu"


# Module-level singleton — shared across all requests
models = MLModels()


def _model_source(local_path: str, hf_id: str) -> str:
    """Return local path if weights exist there, otherwise fall back to HF id."""
    return local_path if os.path.isdir(local_path) else hf_id


def load_ai_models() -> None:
    """
    Loads DINO + SAM from local disk (app/models/) when weights are present,
    otherwise falls back to downloading from Hugging Face on first run.
    Run download_weights.py once to populate local weights for instant startup.

    This should be called exactly once from the FastAPI startup event.
    """
    device = "cuda" if torch.cuda.is_available() else "cpu"
    compute_dtype = torch.float16 if device == "cuda" else torch.float32
    models.device = device

    dino_source = _model_source(DINO_PATH, settings.DINO_MODEL_ID)
    sam_source = _model_source(SAM_PATH, settings.SAM_MODEL_ID)

    logger.info("Loading AI models on device=%s dtype=%s …", device, compute_dtype)

    # ── Grounding DINO ────────────────────────────────────────────────────────
    logger.info("Loading Grounding DINO from %s …", dino_source)
    models.dino_processor = GroundingDinoProcessor.from_pretrained(dino_source)
    models.dino_model = GroundingDinoForObjectDetection.from_pretrained(
        dino_source,
        torch_dtype=compute_dtype,
    ).to(device)
    models.dino_model.eval()

    # ── SAM ───────────────────────────────────────────────────────────────────
    logger.info("Loading SAM from %s …", sam_source)
    models.sam_processor = SamProcessor.from_pretrained(sam_source)
    models.sam_model = SamModel.from_pretrained(
        sam_source,
        torch_dtype=compute_dtype,
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
