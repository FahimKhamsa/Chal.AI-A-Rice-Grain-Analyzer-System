"""
app/schemas/analysis.py
------------------------
Pydantic v2 models that define the API contract between the Flutter app and
this backend.  FastAPI uses these to:
  • Validate incoming request bodies automatically.
  • Auto-generate the OpenAPI / Swagger documentation.
  • Serialise response payloads with correct types.
"""
from typing import Dict, Optional

from pydantic import BaseModel, Field


# ── Nested output schemas ─────────────────────────────────────────────────────

class GrainCountsOut(BaseModel):
    healthy: int
    threeQuarterBroken: int
    halfBroken: int
    impurity: int
    discolored: int


class LengthDistributionOut(BaseModel):
    shortPct: float
    mediumPct: float
    longPct: float


class DefectBreakdownOut(BaseModel):
    chalkyPct: float
    redStreakedPct: float
    immaturePct: float
    foreignMatterPct: float


# ── Response ──────────────────────────────────────────────────────────────────

class AnalysisResponse(BaseModel):
    """
    Payload returned by POST /api/v1/rice after a successful analysis run.

    Top-level fields mirror the Flutter AnalysisResult domain model so the
    client can deserialise directly.  Raw reports and annotated images are
    also included for debugging / future features.
    """

    # ── Metadata ──────────────────────────────────────────────────────────────
    id: str = Field(description="UUID for this analysis run.")
    batchName: str = Field(description="Batch label forwarded from the request.")
    analyzedAt: str = Field(description="ISO-8601 UTC timestamp of analysis completion.")
    processingTimeMs: int = Field(description="Wall-clock inference time in milliseconds.")

    # ── Core counts (Flutter GrainCounts) ─────────────────────────────────────
    counts: GrainCountsOut

    # ── Derived metrics ────────────────────────────────────────────────────────
    integrityScore: float = Field(description="Healthy grains as % of total (0–100).")
    detectedVariety: str = Field(default="Unknown")
    varietyConfidence: float = Field(default=0.0)

    # ── Chart data ─────────────────────────────────────────────────────────────
    lengthDistribution: LengthDistributionOut
    defectBreakdown: DefectBreakdownOut

    # ── Raw reports (kept for debugging / future features) ────────────────────
    morphology_report: Dict[str, int] = Field(
        description="Raw morphological grain counts from DINO+SAM pipeline."
    )
    color_report: Dict[str, int] = Field(
        description="Raw colour grain counts from HSV analysis."
    )
    morphology_image_b64: Optional[str] = Field(
        default=None,
        description="JPEG annotated morphology image, base64-encoded.",
    )
    color_image_b64: Optional[str] = Field(
        default=None,
        description="JPEG annotated colour image, base64-encoded.",
    )


# ── Error envelope (used for structured 422 / 500 responses) ─────────────────

class ErrorDetail(BaseModel):
    """Structured error payload for non-2xx responses."""

    detail: str = Field(description="Human-readable error message.")
