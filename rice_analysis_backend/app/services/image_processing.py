"""
app/services/image_processing.py
----------------------------------
Low-level image I/O and pre-processing utilities used across the pipeline.

Keeps byte-level / codec operations out of the endpoint and cv_pipeline layers.
"""
import logging

import cv2
import numpy as np

logger = logging.getLogger(__name__)

# Maximum dimension (px) we resize to before running inference.
# Reduces VRAM usage while preserving enough detail for grain analysis.
MAX_INFERENCE_DIM = 1280


def bytes_to_rgb(raw_bytes: bytes) -> np.ndarray:
    """
    Decode raw image bytes (JPEG / PNG / BMP / TIFF / WebP …) to an RGB array.

    Args:
        raw_bytes: Raw file bytes from an UploadFile.

    Returns:
        H×W×3 RGB uint8 numpy array.

    Raises:
        ValueError: If decoding fails (unsupported format or corrupt data).
    """
    nparr = np.frombuffer(raw_bytes, np.uint8)
    img_bgr = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if img_bgr is None:
        raise ValueError(
            "Could not decode image. "
            "Ensure the file is a valid JPEG, PNG, BMP, TIFF, or WebP."
        )
    return cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)


def resize_for_inference(image_rgb: np.ndarray, max_dim: int = MAX_INFERENCE_DIM) -> np.ndarray:
    """
    Proportionally downscale an image so its longest dimension ≤ max_dim.
    Images already within bounds are returned unchanged (no copy).

    Args:
        image_rgb: H×W×3 RGB uint8 array.
        max_dim:   Maximum pixel length for the longest side.

    Returns:
        Possibly-resized H×W×3 RGB uint8 array.
    """
    h, w = image_rgb.shape[:2]
    longest = max(h, w)
    if longest <= max_dim:
        return image_rgb

    scale = max_dim / longest
    new_w, new_h = int(w * scale), int(h * scale)
    logger.debug("Resizing image from %dx%d to %dx%d for inference", w, h, new_w, new_h)
    return cv2.resize(image_rgb, (new_w, new_h), interpolation=cv2.INTER_AREA)
