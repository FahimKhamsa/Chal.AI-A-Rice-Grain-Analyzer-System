"""
app/services/supabase_client.py
--------------------------------
Supabase helpers: download images from any URL and upload annotated result
images to Supabase Storage.

Both functions gracefully no-op when SUPABASE_URL / SUPABASE_KEY are not
configured, so the pipeline still works in fully offline local testing.
"""
import logging

import cv2
import numpy as np
import requests

from app.core.config import settings

logger = logging.getLogger(__name__)


def download_image_from_url(image_url: str) -> np.ndarray:
    """
    Download an image from any HTTP(S) URL (Supabase signed URL, public URL,
    or any other source) and return it as an H×W×3 RGB uint8 numpy array.

    Raises:
        requests.HTTPError: If the server returns a non-2xx status code.
        ValueError:         If the downloaded bytes cannot be decoded as an image.
    """
    logger.info("Downloading image from %s …", image_url)
    response = requests.get(image_url, timeout=30)
    response.raise_for_status()

    img_bytes = np.frombuffer(response.content, dtype=np.uint8)
    img_bgr = cv2.imdecode(img_bytes, cv2.IMREAD_COLOR)
    if img_bgr is None:
        raise ValueError(f"Could not decode image downloaded from: {image_url}")

    logger.info("Image downloaded and decoded (%d bytes).", len(response.content))
    return cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)


def upload_result_image(img_rgb: np.ndarray | None, storage_path: str) -> str | None:
    """
    JPEG-encode img_rgb and upload it to the configured Supabase Storage bucket.

    Returns the public URL of the uploaded file, or None when:
      • img_rgb is None (no image to upload).
      • SUPABASE_URL / SUPABASE_KEY are not set (offline / local mode).

    Args:
        img_rgb:      H×W×3 RGB uint8 array to upload.
        storage_path: Destination path inside the bucket,
                      e.g. "morphology/run-uuid.jpg".
    """
    if img_rgb is None:
        return None

    if not settings.SUPABASE_URL or not settings.SUPABASE_KEY:
        logger.warning(
            "SUPABASE_URL or SUPABASE_KEY not set — skipping image upload for %s.",
            storage_path,
        )
        return None

    try:
        from supabase import create_client  # imported lazily so offline mode works

        img_bgr = cv2.cvtColor(img_rgb, cv2.COLOR_RGB2BGR)
        _, buffer = cv2.imencode(".jpg", img_bgr, [cv2.IMWRITE_JPEG_QUALITY, 85])
        file_bytes = buffer.tobytes()

        sb = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
        sb.storage.from_(settings.SUPABASE_RESULTS_BUCKET).upload(
            path=storage_path,
            file=file_bytes,
            file_options={"content-type": "image/jpeg", "upsert": "true"},
        )
        public_url: str = sb.storage.from_(
            settings.SUPABASE_RESULTS_BUCKET
        ).get_public_url(storage_path)

        logger.info("Uploaded result image → %s", public_url)
        return public_url

    except Exception as exc:
        logger.error("Supabase upload failed for %s: %s", storage_path, exc)
        return None
