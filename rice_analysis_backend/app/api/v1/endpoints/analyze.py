"""
app/api/v1/endpoints/analyze.py
--------------------------------
POST /api/v1/rice — Rice grain quality analysis endpoint.

Design notes:
  • Uses a regular `def` (not `async def`) so PyTorch's blocking GPU ops run
    inside FastAPI's threadpool executor and never block the event loop.
  • All heavy logic lives in `services/cv_pipeline.py`; this file is purely
    HTTP glue: receive → delegate → respond.
  • torch.autocast is used only when a CUDA GPU is available to avoid errors
    on CPU-only machines.
"""
import logging

import cv2
import numpy as np
import torch
from fastapi import APIRouter, File, HTTPException, UploadFile

from app.core.ml_manager import models
from app.schemas.analysis import AnalysisResponse
from app.services.cv_pipeline import (
    analyze_color_hsv,
    analyze_quality,
    detect_objects_dino,
    image_to_base64,
    segment_objects_sam,
)
from app.services.image_processing import bytes_to_rgb, resize_for_inference
from app.core.config import settings

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post(
    "/rice",
    response_model=AnalysisResponse,
    summary="Analyse rice grain image",
    description=(
        "Upload a JPEG/PNG photo of rice grains. "
        "Returns morphological quality counts and HSV colour-anomaly counts, "
        "plus base64-encoded annotated images for both analyses."
    ),
)
def analyze_rice_image(file: UploadFile = File(...)) -> AnalysisResponse:
    """
    Full analysis pipeline:
      1. Decode uploaded image bytes → RGB array.
      2. Resize for GPU efficiency (≤ 1280 px longest side).
      3. Grounding DINO detection → bounding boxes.
      4. SAM segmentation → binary masks.
      5. Morphological quality classification.
      6. HSV colour anomaly detection (on non-dust grains).
      7. Return JSON with counts + annotated images.
    """
    if models.dino_model is None or models.sam_model is None:
        raise HTTPException(
            status_code=503,
            detail="AI models are not yet loaded. Please retry in a moment.",
        )

    try:
        # ── 1. Decode image ────────────────────────────────────────────────────
        raw_bytes = file.file.read()
        try:
            img_rgb = bytes_to_rgb(raw_bytes)
        except ValueError as exc:
            raise HTTPException(status_code=400, detail=str(exc))

        # ── 2. Resize ──────────────────────────────────────────────────────────
        img_rgb = resize_for_inference(img_rgb)

        # ── 3 & 4. DINO detection + SAM segmentation ──────────────────────────
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
                box_threshold=settings.DINO_BOX_THRESHOLD,
                iou_threshold=settings.DINO_IOU_THRESHOLD,
            )
            masks = (
                segment_objects_sam(
                    img_rgb, boxes, models.sam_model, models.sam_processor
                )
                if len(boxes) > 0
                else []
            )

        # ── 5. Morphological analysis ──────────────────────────────────────────
        morph_stats, morph_img, valid_masks = analyze_quality(img_rgb, masks)

        # ── 6. Colour analysis (skip if no valid grains) ───────────────────────
        color_stats: dict = {}
        color_img = None
        if len(valid_masks) > 0:
            color_stats, color_img = analyze_color_hsv(
                img_rgb,
                valid_masks,
                h_weight=settings.COLOR_H_WEIGHT,
                s_weight=settings.COLOR_S_WEIGHT,
                anomaly_threshold=settings.COLOR_ANOMALY_THRESHOLD,
            )

        # ── 7. Build and return response ───────────────────────────────────────
        logger.info(
            "Analysis complete — morphology=%s  colour=%s", morph_stats, color_stats
        )
        return AnalysisResponse(
            morphology_report=morph_stats,
            color_report=color_stats,
            morphology_image_b64=image_to_base64(morph_img),
            color_image_b64=image_to_base64(color_img),
        )

    except HTTPException:
        raise  # Re-raise HTTP exceptions as-is
    except Exception as exc:
        logger.exception("Unhandled error during rice analysis")
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    finally:
        file.file.close()
