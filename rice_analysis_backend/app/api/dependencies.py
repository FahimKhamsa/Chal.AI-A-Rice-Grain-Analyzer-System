"""
app/api/dependencies.py
------------------------
FastAPI dependency functions and shared middleware utilities.
"""
import logging

from fastapi import Header, HTTPException
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.core.config import settings

logger = logging.getLogger(__name__)

# Shared rate limiter — attach to app.state.limiter in main.py
limiter = Limiter(key_func=get_remote_address)


async def verify_api_key(x_api_key: str = Header(default=None)) -> None:
    """
    API key guard. Reads API_SECRET_KEY from environment.

    If API_SECRET_KEY is not set the check is skipped (development mode).
    In production, set API_SECRET_KEY and all clients must pass it via
    the X-Api-Key request header.
    """
    expected = settings.API_SECRET_KEY
    if not expected:
        logger.warning(
            "API_SECRET_KEY is not set — endpoint is open. Set it in production."
        )
        return
    if x_api_key != expected:
        raise HTTPException(status_code=403, detail="Invalid or missing API key.")
