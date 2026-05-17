"""
app/services/inference.py
--------------------------
Framework-agnostic inference engine.

Contains process_rice_analysis() — the pure Python execution path used by
run_serverless.py (RunPod) and local_test.py.  Zero FastAPI imports so this
module can be loaded in the serverless container without dragging in the HTTP
layer.
"""
import logging
import time
import uuid
from datetime import datetime, timezone

import torch

from app.core.config import settings
from app.core.ml_manager import models
from app.services.cv_pipeline import (
    analyze_color_hsv,
    analyze_quality,
    detect_objects_dino,
    draw_morphology_annotation,
    image_to_base64,
    segment_objects_sam,
)
from app.services.image_processing import resize_for_inference
from app.services.supabase_client import download_image_from_url, upload_result_image

logger = logging.getLogger(__name__)


def process_rice_analysis(image_url: str, threshold: float = 0.06) -> dict:
    """
    Framework-agnostic analysis function. Accepts a URL, runs the full
    DINO+SAM pipeline, uploads annotated images to Supabase Storage, and
    returns a JSON-serialisable dict.

    Args:
        image_url:  HTTP(S) URL of the rice image (Supabase signed URL or public URL).
        threshold:  Grounding DINO box confidence threshold (default 0.06).

    Returns:
        Dict with counts, scores, Supabase image URLs, and raw reports.

    Raises:
        RuntimeError: If models are not loaded in memory.
    """
    if models.dino_model is None or models.sam_model is None:
        raise RuntimeError("AI models are not loaded. Call load_ai_models() first.")

    logger.info("process_rice_analysis: image_url=%s  threshold=%.3f", image_url, threshold)
    start_time = time.monotonic()

    # ── 1. Download + decode image ────────────────────────────────────────────
    img_rgb = download_image_from_url(image_url)
    img_rgb = resize_for_inference(img_rgb)

    # ── 2 & 3. DINO detection + SAM segmentation ──────────────────────────────
    use_cuda = models.device == "cuda"
    autocast_ctx = (
        torch.autocast(device_type="cuda", dtype=torch.float16)
        if use_cuda
        else torch.no_grad()
    )

    with autocast_ctx:
        boxes, _ = detect_objects_dino(
            img_rgb,
            models.dino_model,
            models.dino_processor,
            text_prompt=settings.DINO_TEXT_PROMPT,
            box_threshold=threshold,
            iou_threshold=settings.DINO_IOU_THRESHOLD,
        )
        masks = (
            segment_objects_sam(img_rgb, boxes, models.sam_model, models.sam_processor)
            if len(boxes) > 0
            else []
        )

    # ── 4. Morphological analysis ─────────────────────────────────────────────
    morph_stats, grain_records, valid_masks = analyze_quality(masks)

    # ── 5. Colour analysis ────────────────────────────────────────────────────
    color_stats: dict = {}
    color_img = None
    discolored_indices: set = set()
    if valid_masks:
        color_stats, color_img, discolored_indices = analyze_color_hsv(
            img_rgb,
            valid_masks,
            h_weight=settings.COLOR_H_WEIGHT,
            s_weight=settings.COLOR_S_WEIGHT,
            anomaly_threshold=settings.COLOR_ANOMALY_THRESHOLD,
        )

    # ── 6. Draw combined morphology annotation ────────────────────────────────
    morph_img = draw_morphology_annotation(img_rgb, grain_records, discolored_indices)

    # ── 7. Summary stats ──────────────────────────────────────────────────────
    morph_deductions: dict[str, int] = {}
    for record in grain_records:
        if record["valid_idx"] != -1 and record["valid_idx"] in discolored_indices:
            cat = record["category"]
            morph_deductions[cat] = morph_deductions.get(cat, 0) + 1

    healthy = morph_stats.get("Healthy", 0) - morph_deductions.get("Healthy", 0)
    three_quarter_broken = (
        morph_stats.get("3/4 Broken", 0) - morph_deductions.get("3/4 Broken", 0)
    )
    half_broken = (
        morph_stats.get("Half Broken", 0) - morph_deductions.get("Half Broken", 0)
    )
    impurity = morph_stats.get("Impurity (Dust)", 0)
    discolored = color_stats.get("Discolored", 0)
    total = max(healthy + three_quarter_broken + half_broken + impurity + discolored, 1)
    integrity_score = round(healthy / total * 100, 1)
    processing_ms = int((time.monotonic() - start_time) * 1000)

    # ── 8. Upload annotated images to Supabase Storage ────────────────────────
    run_id = str(uuid.uuid4())
    morph_url = upload_result_image(morph_img, f"morphology/{run_id}.jpg")
    color_url = upload_result_image(color_img, f"color/{run_id}.jpg")

    logger.info(
        "process_rice_analysis complete — morphology=%s  colour=%s  time=%dms",
        morph_stats,
        color_stats,
        processing_ms,
    )

    return {
        "id": run_id,
        "analyzed_at": datetime.now(timezone.utc).isoformat(),
        "processing_time_ms": processing_ms,
        "integrity_score": integrity_score,
        "counts": {
            "healthy": healthy,
            "three_quarter_broken": three_quarter_broken,
            "half_broken": half_broken,
            "impurity": impurity,
            "discolored": discolored,
        },
        "morphology_report": morph_stats,
        "color_report": color_stats,
        "morphology_image_url": morph_url,
        "color_image_url": color_url,
    }
