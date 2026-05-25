"""
app/main.py
-----------
FastAPI application factory and entry point.

Responsibilities:
  • Create the FastAPI app instance with OpenAPI metadata.
  • Configure structured logging.
  • Register startup / shutdown lifecycle hooks (model loading/unloading).
  • Mount versioned API routers.
  • Expose a root health-check endpoint.
"""
import logging

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.api.dependencies import limiter
from app.api.v1.endpoints import analyze
from app.core.config import settings
from app.core.ml_manager import load_ai_models, unload_ai_models
from app.utils import configure_logging

logger = logging.getLogger(__name__)


# ── Lifespan (replaces deprecated @app.on_event) ─────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    configure_logging("INFO")
    logger.info("Starting Rice Analysis API …")
    load_ai_models()
    yield
    logger.info("Shutting down Rice Analysis API …")
    unload_ai_models()


# ── Application instance ─────────────────────────────────────────────────────

_is_production = settings.APP_ENV == "production"

app = FastAPI(
    title="Rice Quality Analyzer API",
    description=(
        "Backend microservice for computer-vision rice grain analysis. "
        "Uses Grounding DINO for detection and SAM for instance segmentation."
    ),
    version="1.0.0",
    lifespan=lifespan,
    # Swagger/ReDoc disabled in production to avoid exposing API schema
    docs_url=None if _is_production else "/docs",
    redoc_url=None if _is_production else "/redoc",
)

# ── Rate limiting ─────────────────────────────────────────────────────────────

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)


# ── CORS ──────────────────────────────────────────────────────────────────────
# Set CORS_ALLOWED_ORIGINS env var in production, e.g.:
#   CORS_ALLOWED_ORIGINS="https://app.chalai.com,https://chalai.com"

_raw_origins = settings.CORS_ALLOWED_ORIGINS
_origins_list = (
    ["*"]
    if _raw_origins.strip() == "*"
    else [o.strip() for o in _raw_origins.split(",") if o.strip()]
)
# allow_credentials must be False when origins include "*" (browser restriction)
_allow_credentials = "*" not in _origins_list

app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins_list,
    allow_credentials=_allow_credentials,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


# ── Routers ───────────────────────────────────────────────────────────────────

app.include_router(
    analyze.router,
    prefix="/api/v1",
    tags=["Analysis"],
)


# ── Health check ──────────────────────────────────────────────────────────────

@app.get("/", tags=["Health"])
def health_check() -> dict:
    """Quick liveness probe — returns 200 when the server is running."""
    return {"status": "healthy", "service": "Rice Analysis CV Pipeline", "version": "1.0.0"}


@app.get("/health", tags=["Health"])
def readiness_check() -> dict:
    """Readiness probe for Kubernetes / load balancer checks."""
    return {"status": "ready"}
