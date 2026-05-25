"""
app/core/config.py
------------------
Centralised application settings loaded from environment variables / .env file.
Use `from app.core.config import settings` anywhere in the project.
"""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ── Application ────────────────────────────────────────────────────────────
    APP_ENV: str = "development"
    APP_HOST: str = "0.0.0.0"
    APP_PORT: int = 8000

    # ── Security ───────────────────────────────────────────────────────────────
    # Set API_SECRET_KEY in production to enforce API key authentication.
    # Clients must send this value in the X-Api-Key header.
    # Leave empty to disable (development only).
    API_SECRET_KEY: str = ""

    # CORS: comma-separated allowed origins, or "*" for development.
    # Production example: "https://app.chalai.com,https://chalai.com"
    CORS_ALLOWED_ORIGINS: str = "*"

    # Maximum allowed upload file size in bytes (default: 10 MB)
    MAX_UPLOAD_SIZE_BYTES: int = 10 * 1024 * 1024

    # ── Model identifiers ──────────────────────────────────────────────────────
    DINO_MODEL_ID: str = "IDEA-Research/grounding-dino-base"
    SAM_MODEL_ID: str = "facebook/sam-vit-base"

    # ── Detection / segmentation hyper-parameters ─────────────────────────────
    DINO_TEXT_PROMPT: str = "white rice grain."
    DINO_BOX_THRESHOLD: float = 0.06
    DINO_IOU_THRESHOLD: float = 0.6

    # ── Color analysis hyper-parameters ───────────────────────────────────────
    COLOR_H_WEIGHT: float = 1.0
    COLOR_S_WEIGHT: float = 0.5
    COLOR_ANOMALY_THRESHOLD: float = 15.0

    # ── Supabase ───────────────────────────────────────────────────────────────
    SUPABASE_URL: str = ""
    SUPABASE_KEY: str = ""
    SUPABASE_RESULTS_BUCKET: str = "analysis-results"


# Single module-level instance — import this everywhere
settings = Settings()
