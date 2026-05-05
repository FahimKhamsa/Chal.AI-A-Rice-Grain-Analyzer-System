"""
app/api/dependencies.py
------------------------
FastAPI dependency functions shared across multiple routers.

Add rate limiters, API-key checks, DB session factories, etc. here.
"""
from fastapi import Header, HTTPException


async def verify_api_key(x_api_key: str = Header(default=None)) -> None:
    """
    Optional API-key guard.

    Set the X-Api-Key header to enable.  Currently a no-op — add your secret
    comparison logic here before shipping to production.

    Example (enable by uncommenting):
        import os
        expected = os.environ.get("API_SECRET_KEY")
        if expected and x_api_key != expected:
            raise HTTPException(status_code=403, detail="Invalid API key.")
    """
    pass  # Remove this line and uncomment above for production auth
