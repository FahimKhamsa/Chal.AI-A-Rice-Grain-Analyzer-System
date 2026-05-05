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

from app.api.v1.endpoints import analyze
from app.core.ml_manager import load_ai_models, unload_ai_models
from app.utils import configure_logging

logger = logging.getLogger(__name__)


# ── Lifespan (replaces deprecated @app.on_event) ─────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Modern FastAPI lifespan context manager.

    Everything before `yield` runs at startup; everything after at shutdown.
    Using this instead of @app.on_event("startup") is the recommended pattern
    in FastAPI ≥ 0.95.
    """
    configure_logging("INFO")
    logger.info("Starting Rice Analysis API …")
    load_ai_models()   # Heavy model loading happens here — blocks until done
    yield
    logger.info("Shutting down Rice Analysis API …")
    unload_ai_models()


# ── Application instance ─────────────────────────────────────────────────────

app = FastAPI(
    title="Rice Quality Analyzer API",
    description=(
        "Backend microservice for computer-vision rice grain analysis. "
        "Uses Grounding DINO for detection and SAM for instance segmentation."
    ),
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",       # Swagger UI
    redoc_url="/redoc",     # ReDoc
)


# ── CORS — allow all origins for local development ────────────────────────────
# Restrict `allow_origins` to your Flutter app's host in production.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
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
