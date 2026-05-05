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


# ── Response ──────────────────────────────────────────────────────────────────

class AnalysisResponse(BaseModel):
    """
    Payload returned by POST /api/v1/rice after a successful analysis run.

    All images are JPEG-encoded and base64-encoded so they can be safely
    transported in a JSON body without binary encoding issues.
    """

    morphology_report: Dict[str, int] = Field(
        description=(
            "Grain counts by morphological category: "
            "Healthy, 3/4 Broken, Half Broken, Impurity (Dust)."
        )
    )
    color_report: Dict[str, int] = Field(
        description="Grain counts by colour category: Standard Color, Discolored."
    )
    morphology_image_b64: Optional[str] = Field(
        default=None,
        description="JPEG annotated image of morphology analysis, base64-encoded.",
    )
    color_image_b64: Optional[str] = Field(
        default=None,
        description="JPEG annotated image of colour analysis, base64-encoded.",
    )

    model_config = {
        "json_schema_extra": {
            "example": {
                "morphology_report": {
                    "Healthy": 28,
                    "3/4 Broken": 2,
                    "Half Broken": 1,
                    "Impurity (Dust)": 1,
                },
                "color_report": {
                    "Standard Color": 24,
                    "Discolored": 4,
                },
                "morphology_image_b64": "<base64_jpeg_string>",
                "color_image_b64": "<base64_jpeg_string>",
            }
        }
    }


# ── Error envelope (used for structured 422 / 500 responses) ─────────────────

class ErrorDetail(BaseModel):
    """Structured error payload for non-2xx responses."""

    detail: str = Field(description="Human-readable error message.")
