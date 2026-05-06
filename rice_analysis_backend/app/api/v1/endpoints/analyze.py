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
import time
import uuid
from datetime import datetime, timezone

import torch
from fastapi import APIRouter, File, Form, HTTPException, UploadFile

from app.core.config import settings
from app.core.ml_manager import models
from app.schemas.analysis import (
    AnalysisResponse,
    DefectBreakdownOut,
    GrainCountsOut,
    LengthDistributionOut,
)
from app.services.cv_pipeline import (
    analyze_color_hsv,
    analyze_quality,
    detect_objects_dino,
    draw_morphology_annotation,
    image_to_base64,
    segment_objects_sam,
)
from app.services.image_processing import bytes_to_rgb, resize_for_inference

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post(
    "/rice",
    response_model=AnalysisResponse,
    summary="Analyse rice grain image",
    description=(
        "Upload a JPEG/PNG photo of rice grains. "
        "Returns structured quality metrics plus base64-encoded annotated images."
    ),
)
def analyze_rice_image(
    file: UploadFile = File(...),
    batch_name: str = Form(""),
) -> AnalysisResponse:
    """
    Full analysis pipeline:
      1. Decode uploaded image bytes → RGB array.
      2. Resize for GPU efficiency (≤ 1280 px longest side).
      3. Grounding DINO detection → bounding boxes.
      4. SAM segmentation → binary masks.
      5. Morphological quality classification (collect grain records).
      6. HSV colour anomaly detection (on non-dust grains).
      7. Draw combined morphology annotation (discolored → orange border).
      8. Map raw reports → Flutter-compatible structured response.
    """
    if models.dino_model is None or models.sam_model is None:
        raise HTTPException(
            status_code=503,
            detail="AI models are not yet loaded. Please retry in a moment.",
        )

    start_time = time.monotonic()

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

        # ── 5. Morphological analysis (collect grain records; no drawing yet) ────
        morph_stats, grain_records, valid_masks = analyze_quality(masks)

        # ── 6. Colour analysis (skip if no valid grains) ───────────────────────
        color_stats: dict = {}
        color_img = None
        discolored_indices: set = set()
        if len(valid_masks) > 0:
            color_stats, color_img, discolored_indices = analyze_color_hsv(
                img_rgb,
                valid_masks,
                h_weight=settings.COLOR_H_WEIGHT,
                s_weight=settings.COLOR_S_WEIGHT,
                anomaly_threshold=settings.COLOR_ANOMALY_THRESHOLD,
            )

        # ── 7. Draw combined morphology annotation ─────────────────────────────
        # Discolored grains receive an orange border regardless of break grade.
        morph_img = draw_morphology_annotation(img_rgb, grain_records, discolored_indices)

        # ── 8. Map raw reports → structured Flutter response ──────────────────
        # Discolored is an exclusive category: subtract discolored grains from
        # the morphology category they were originally assigned to.
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

        logger.info(
            "Analysis complete — morphology=%s  colour=%s  time=%dms",
            morph_stats,
            color_stats,
            processing_ms,
        )

        return AnalysisResponse(
            id=str(uuid.uuid4()),
            batchName=batch_name.strip() or "Batch A",
            analyzedAt=datetime.now(timezone.utc).isoformat(),
            processingTimeMs=processing_ms,
            counts=GrainCountsOut(
                healthy=healthy,
                threeQuarterBroken=three_quarter_broken,
                halfBroken=half_broken,
                impurity=impurity,
                discolored=discolored,
            ),
            integrityScore=integrity_score,
            detectedVariety="Unknown",
            varietyConfidence=0.0,
            lengthDistribution=LengthDistributionOut(
                shortPct=0.0,
                mediumPct=0.0,
                longPct=100.0,
            ),
            defectBreakdown=DefectBreakdownOut(
                chalkyPct=0.0,
                redStreakedPct=0.0,
                immaturePct=0.0,
                foreignMatterPct=0.0,
            ),
            morphology_report=morph_stats,
            color_report=color_stats,
            morphology_image_b64=image_to_base64(morph_img),
            color_image_b64=image_to_base64(color_img),
        )

    except HTTPException:
        raise
    except Exception as exc:
        logger.exception("Unhandled error during rice analysis")
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    finally:
        file.file.close()
