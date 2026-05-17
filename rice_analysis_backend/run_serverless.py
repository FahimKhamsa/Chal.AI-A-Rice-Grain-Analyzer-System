"""
run_serverless.py
------------------
RunPod Serverless entrypoint.

Lifecycle:
  init_worker()     — called ONCE when the GPU container boots.
                      Loads DINO + SAM weights into VRAM.

  runpod_handler()  — called for EVERY job in the RunPod queue.
                      Receives { "input": { "image_url": "...", ... } }
                      Returns  { "status": "success", "output": { ... } }
                           or  { "status": "error",   "message": "..." }

Deploy:
  docker build -t <hub_user>/rice-analyzer-serverless:latest .
  docker push <hub_user>/rice-analyzer-serverless:latest
  → Create Serverless Endpoint on RunPod pointing to this image.

Environment variables required on RunPod:
  SUPABASE_URL             Your Supabase project URL
  SUPABASE_KEY             Supabase service-role secret key
  SUPABASE_RESULTS_BUCKET  Storage bucket name (default: analysis-results)
"""
import logging
import sys
import traceback

import runpod

from app.core.ml_manager import load_ai_models
from app.utils import configure_logging
from app.services.inference import process_rice_analysis

logger = logging.getLogger(__name__)


def init_worker() -> None:
    """
    Runs EXACTLY ONCE when the RunPod GPU container boots up.
    Loads DINO + SAM weights directly into the 16 GB VRAM cache.
    """
    configure_logging("INFO")
    logger.info("Initializing RunPod Worker Container …")
    load_ai_models()
    logger.info("Worker initialization complete. System ready for queue tasks.")


def runpod_handler(job: dict) -> dict:
    """
    Runs for EVERY job payload sent to the RunPod queue.

    Expected input:
        {
            "input": {
                "image_url":            "<Supabase or public image URL>",
                "confidence_threshold": 0.06   (optional)
            }
        }
    """
    job_input = job.get("input", {})

    image_url: str | None = job_input.get("image_url")
    threshold: float = float(job_input.get("confidence_threshold", 0.06))

    if not image_url:
        return {"status": "error", "message": "Missing required field: 'image_url'."}

    try:
        results = process_rice_analysis(image_url=image_url, threshold=threshold)
        return {"status": "success", "output": results}
    except Exception as exc:
        logger.error("Inference execution failure: %s", str(exc), exc_info=True)
        return {"status": "error", "message": str(exc)}


# ── Start the RunPod Serverless worker loop ───────────────────────────────────
# init_worker() runs once at container boot — weights hit VRAM before the first job.
# RunPod SDK does not support an "init" key; call it directly before start().
try:
    init_worker()
except Exception:
    logging.getLogger(__name__).error(
        "FATAL: Worker initialization failed:\n%s", traceback.format_exc()
    )
    sys.exit(1)

runpod.serverless.start({
    "handler": runpod_handler,
    "return_aggregate_stream": False,
})
