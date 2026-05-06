"""
app/services/cv_pipeline.py
----------------------------
Core computer-vision pipeline functions.

Every function here is *pure* with respect to the web layer — it takes numpy
arrays / tensors and returns numpy arrays / dicts.  No FastAPI, no HTTP.

Pipeline order:
  1. detect_objects_dino      — Grounding DINO bounding-box detection
  2. segment_objects_sam      — SAM mask segmentation using detected boxes
  3. analyze_quality          — Morphological classification (collects grain records)
  4. analyze_color_hsv        — HSV-based colour anomaly detection
  5. draw_morphology_annotation — Combined annotation: discolored grains override colour
  6. image_to_base64          — Utility: encode annotated image for JSON transport
"""
import base64
import logging

import cv2
import numpy as np
import torch
import torchvision

logger = logging.getLogger(__name__)

# Orange border used for discolored grains in the combined morphology image.
_DISCOLORED_COLOR: tuple[int, int, int] = (0, 0, 255)


# ─────────────────────────────────────────────────────────────────────────────
# Utility
# ─────────────────────────────────────────────────────────────────────────────

def image_to_base64(img_array: np.ndarray | None) -> str | None:
    """
    Encode an RGB numpy image as a JPEG base64 string.

    Args:
        img_array: H×W×3 RGB uint8 array, or None.

    Returns:
        Base64-encoded JPEG string, or None if input is None.
    """
    if img_array is None:
        return None
    # OpenCV expects BGR
    img_bgr = cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR)
    _, buffer = cv2.imencode(".jpg", img_bgr, [cv2.IMWRITE_JPEG_QUALITY, 85])
    return base64.b64encode(buffer).decode("utf-8")


# ─────────────────────────────────────────────────────────────────────────────
# Step 1 — Object detection with Grounding DINO
# ─────────────────────────────────────────────────────────────────────────────

def detect_objects_dino(
    image_rgb: np.ndarray,
    dino_model,
    dino_processor,
    text_prompt: str = "white rice grain.",
    box_threshold: float = 0.06,
    iou_threshold: float = 0.6,
) -> tuple[torch.Tensor, torch.Tensor]:
    """
    Run Grounding DINO on an RGB image and return filtered bounding boxes.

    Args:
        image_rgb:      H×W×3 RGB uint8 array.
        dino_model:     Loaded GroundingDinoForObjectDetection.
        dino_processor: Matching GroundingDinoProcessor.
        text_prompt:    Open-vocabulary detection prompt.
        box_threshold:  Minimum sigmoid score to keep a box.
        iou_threshold:  IoU threshold for NMS.

    Returns:
        Tuple of (boxes [N,4] in pixel coords, scores [N]) on the model device.
        Both tensors are empty (shape [0,4] / [0]) when no objects are found.
    """
    device = next(dino_model.parameters()).device
    img_h, img_w = image_rgb.shape[:2]

    with torch.no_grad():
        inputs = dino_processor(
            images=image_rgb, text=text_prompt, return_tensors="pt"
        ).to(device)
        outputs = dino_model(**inputs)

        logits = outputs.logits[0]       # [num_queries, num_classes]
        pred_boxes = outputs.pred_boxes[0]  # [num_queries, 4]  (cx cy w h, normalised)

        probs = torch.sigmoid(logits).max(dim=-1)[0]
        keep_mask = probs > box_threshold

        dino_scores = probs[keep_mask]
        raw_boxes = pred_boxes[keep_mask]

        if len(raw_boxes) == 0:
            logger.debug("DINO: no boxes above threshold %.3f", box_threshold)
            return (
                torch.empty((0, 4), device=device),
                torch.empty((0,), device=device),
            )

        # Convert from (cx, cy, w, h) normalised → (x1, y1, x2, y2) pixels
        cx, cy, w, h = raw_boxes.unbind(-1)
        x1, y1 = cx - 0.5 * w, cy - 0.5 * h
        x2, y2 = cx + 0.5 * w, cy + 0.5 * h
        dino_boxes = torch.stack((x1, y1, x2, y2), dim=-1)
        dino_boxes = dino_boxes * torch.tensor(
            [img_w, img_h, img_w, img_h], device=device
        )

        # Discard boxes that are implausibly large (>5 % of image area)
        image_area = img_w * img_h
        box_areas = (dino_boxes[:, 2] - dino_boxes[:, 0]) * (
            dino_boxes[:, 3] - dino_boxes[:, 1]
        )
        valid_area_mask = box_areas < (image_area * 0.05)
        dino_boxes = dino_boxes[valid_area_mask]
        dino_scores = dino_scores[valid_area_mask]

        # Non-Maximum Suppression
        if len(dino_boxes) > 0:
            keep_indices = torchvision.ops.nms(dino_boxes, dino_scores, iou_threshold)
            dino_boxes = dino_boxes[keep_indices]
            dino_scores = dino_scores[keep_indices]

    logger.debug("DINO: detected %d objects", len(dino_boxes))
    return dino_boxes, dino_scores


# ─────────────────────────────────────────────────────────────────────────────
# Step 2 — Instance segmentation with SAM
# ─────────────────────────────────────────────────────────────────────────────

def segment_objects_sam(
    image_rgb: np.ndarray,
    boxes: torch.Tensor,
    sam_model,
    sam_processor,
) -> np.ndarray:
    """
    Segment each detected bounding box with SAM.

    Args:
        image_rgb:     H×W×3 RGB uint8 array.
        boxes:         [N,4] pixel-space bounding boxes from DINO.
        sam_model:     Loaded SamModel.
        sam_processor: Matching SamProcessor.

    Returns:
        Binary mask array of shape [N, H, W] (float32, values 0.0 or 1.0).
        Returns an empty list [] when boxes is empty.
    """
    if len(boxes) == 0:
        return []

    device = next(sam_model.parameters()).device

    with torch.no_grad():
        input_boxes = [boxes.cpu().numpy().tolist()]
        sam_inputs = sam_processor(
            image_rgb, input_boxes=input_boxes, return_tensors="pt"
        ).to(device)
        sam_outputs = sam_model(**sam_inputs)

        masks = sam_processor.image_processor.post_process_masks(
            sam_outputs.pred_masks.cpu(),
            sam_inputs["original_sizes"].cpu(),
            sam_inputs["reshaped_input_sizes"].cpu(),
        )[0]  # [N, 1, H, W]

    logger.debug("SAM: generated %d masks", len(masks))
    return masks[:, 0, :, :].numpy()


# ─────────────────────────────────────────────────────────────────────────────
# Step 3 — Morphological quality analysis (collect records; do NOT draw yet)
# ─────────────────────────────────────────────────────────────────────────────

def analyze_quality(
    masks: np.ndarray | list,
) -> tuple[dict, list, list]:
    """
    Classify each grain by size relative to the median (healthy) grain.

    Categories:
      • Healthy        — area ratio ≥ 0.75 of median
      • 3/4 Broken     — 0.50 ≤ ratio < 0.75
      • Half Broken    — 0.20 ≤ ratio < 0.50
      • Impurity (Dust)— ratio < 0.20

    This function intentionally does NOT draw any annotation.  Drawing is
    deferred to draw_morphology_annotation() so that colour-analysis results
    can override the boundary colour for discolored grains.

    Args:
        masks: [N, H, W] binary float masks from SAM.

    Returns:
        (stats_dict, grain_records, valid_masks)

        grain_records — one dict per grain:
            rect        : cv2.minAreaRect result
            morph_color : RGB tuple for morphology category
            label       : text label drawn on the image
            valid_idx   : index into valid_masks (-1 for impurity/dust grains)

        valid_masks — non-dust masks in encounter order, passed to
                      analyze_color_hsv() for colour analysis.
    """
    if len(masks) == 0:
        return {}, [], []

    grain_data, areas = [], []

    for i, mask in enumerate(masks):
        mask_uint8 = (mask * 255).astype(np.uint8)
        contours, _ = cv2.findContours(
            mask_uint8, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
        )
        if not contours:
            continue
        main_contour = max(contours, key=cv2.contourArea)
        rect = cv2.minAreaRect(main_contour)
        width, height = rect[1]

        # Use 90 % of bounding-rect area to account for non-rectangular grains
        adjusted_area = (width * height) * 0.90
        areas.append(adjusted_area)
        grain_data.append({"adjusted_area": adjusted_area, "rect": rect, "mask_idx": i})

    if not areas:
        return {}, [], []

    baseline_area = float(np.median(areas))
    stats = {"Healthy": 0, "3/4 Broken": 0, "Half Broken": 0, "Impurity (Dust)": 0}
    valid_masks: list = []
    grain_records: list = []
    valid_idx = 0

    for grain in grain_data:
        ratio = grain["adjusted_area"] / baseline_area
        rect  = grain["rect"]

        if ratio < 0.20:
            morph_color = (255, 0, 255)   # Magenta — Impurity
            stats["Impurity (Dust)"] += 1
            label = "Dust"
            grain_valid_idx = -1          # Excluded from colour analysis
            category = "Impurity (Dust)"
        else:
            valid_masks.append(masks[grain["mask_idx"]])
            grain_valid_idx = valid_idx
            valid_idx += 1

            if ratio >= 0.75:
                morph_color = (0, 255, 0)     # Green — Healthy
                stats["Healthy"] += 1
                label = f"{ratio:.2f}x"
                category = "Healthy"
            elif ratio >= 0.50:
                morph_color = (255, 255, 0)   # Yellow — 3/4 Broken
                stats["3/4 Broken"] += 1
                label = f"{ratio:.2f}x"
                category = "3/4 Broken"
            else:
                morph_color = (255, 0, 0)     # Red — Half Broken
                stats["Half Broken"] += 1
                label = f"{ratio:.2f}x"
                category = "Half Broken"

        grain_records.append({
            "rect":        rect,
            "morph_color": morph_color,
            "label":       label,
            "valid_idx":   grain_valid_idx,
            "category":    category,
        })

    logger.debug("Morphology stats: %s", stats)
    return stats, grain_records, valid_masks


# ─────────────────────────────────────────────────────────────────────────────
# Step 4 — Colour analysis (HSV anomaly detection)
# ─────────────────────────────────────────────────────────────────────────────

def analyze_color_hsv(
    image_rgb: np.ndarray,
    masks: list,
    h_weight: float = 1.0,
    s_weight: float = 0.5,
    anomaly_threshold: float = 15.0,
) -> tuple[dict, np.ndarray | None, set]:
    """
    Detect colour-discoloured grains by comparing each grain's mean HSV
    against the population median.

    Args:
        image_rgb:         Original RGB image.
        masks:             List of binary float masks (non-dust grains only).
        h_weight:          Weight applied to hue difference in anomaly score.
        s_weight:          Weight applied to saturation difference.
        anomaly_threshold: Threshold above which a grain is 'Discolored'.

    Returns:
        (stats_dict, annotated_image_rgb, discolored_valid_indices)

        discolored_valid_indices — set of 0-based indices into `masks` whose
            grains were classified as Discolored.  Passed to
            draw_morphology_annotation() to override their border colour.
    """
    if len(masks) == 0:
        return {}, None, set()

    image_hsv = cv2.cvtColor(image_rgb, cv2.COLOR_RGB2HSV)
    annotated_img = image_rgb.copy()
    grain_colors: list[dict] = []

    for i, mask in enumerate(masks):
        bool_mask = mask > 0.5
        grain_pixels_hsv = image_hsv[bool_mask]

        if len(grain_pixels_hsv) == 0:
            continue

        mean_H = float(np.mean(grain_pixels_hsv[:, 0]))
        mean_S = float(np.mean(grain_pixels_hsv[:, 1]))

        mask_uint8 = (mask * 255).astype(np.uint8)
        moments = cv2.moments(mask_uint8)
        if moments["m00"] != 0:
            cx = int(moments["m10"] / moments["m00"])
            cy = int(moments["m01"] / moments["m00"])
        else:
            cx, cy = 0, 0

        grain_colors.append(
            {"H": mean_H, "S": mean_S, "cx": cx, "cy": cy,
             "mask": mask_uint8, "valid_idx": i}
        )

    if not grain_colors:
        return {}, None, set()

    median_H = float(np.median([g["H"] for g in grain_colors]))
    median_S = float(np.median([g["S"] for g in grain_colors]))

    stats = {"Standard Color": 0, "Discolored": 0}
    color_overlay = np.zeros_like(annotated_img)
    discolored_valid_indices: set[int] = set()

    for grain in grain_colors:
        # Circular hue difference (0-180 OpenCV hue range)
        h_diff = min(
            abs(grain["H"] - median_H), 180 - abs(grain["H"] - median_H)
        )
        s_diff = abs(grain["S"] - median_S)
        anomaly_score = float(
            np.sqrt((h_weight * h_diff) ** 2 + (s_weight * s_diff) ** 2)
        )

        if anomaly_score > anomaly_threshold:
            stats["Discolored"] += 1
            overlay_color = [0, 0, 255]     # Blue overlay on color image
            text_color    = (0, 0, 255)
            discolored_valid_indices.add(grain["valid_idx"])
        else:
            stats["Standard Color"] += 1
            overlay_color = [0, 255, 0]
            text_color    = (0, 255, 0)

        color_overlay[grain["mask"] > 0] = overlay_color
        cv2.putText(
            annotated_img,
            f"S:{anomaly_score:.1f}",
            (grain["cx"] - 20, grain["cy"]),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.4,
            text_color,
            1,
        )

    annotated_img = cv2.addWeighted(annotated_img, 0.7, color_overlay, 0.3, 0)
    logger.debug("Colour stats: %s  |  discolored indices: %s", stats, discolored_valid_indices)
    return stats, annotated_img, discolored_valid_indices


# ─────────────────────────────────────────────────────────────────────────────
# Step 5 — Combined morphology annotation
# ─────────────────────────────────────────────────────────────────────────────

def draw_morphology_annotation(
    image_rgb: np.ndarray,
    grain_records: list,
    discolored_valid_indices: set | None = None,
) -> np.ndarray | None:
    """
    Draw oriented bounding boxes on a copy of image_rgb using grain_records
    collected by analyze_quality().

    Colour priority:
      1. Orange (_DISCOLORED_COLOR) — grain's valid_idx is in
         discolored_valid_indices (colour-analysis override).
      2. Morphology colour — Green / Yellow / Red / Magenta as classified
         by size ratio.

    Args:
        image_rgb:                 H×W×3 RGB uint8 source image.
        grain_records:             List of dicts from analyze_quality().
        discolored_valid_indices:  Set of valid_mask indices flagged by
                                   analyze_color_hsv() as discolored.

    Returns:
        Annotated RGB image, or None if grain_records is empty.
    """
    if not grain_records:
        return None

    discolored = discolored_valid_indices or set()
    annotated_img = image_rgb.copy()

    for record in grain_records:
        valid_idx = record["valid_idx"]

        # Discolored overrides morphology colour (impurity grains are
        # excluded from colour analysis so valid_idx == -1 is never in the set)
        if valid_idx != -1 and valid_idx in discolored:
            color = _DISCOLORED_COLOR
        else:
            color = record["morph_color"]

        box = np.int32(cv2.boxPoints(record["rect"]))
        cv2.drawContours(annotated_img, [box], 0, color, 2)
        cv2.putText(
            annotated_img,
            record["label"],
            (int(record["rect"][0][0]) - 15, int(record["rect"][0][1]) - 10),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.4,
            color,
            1,
        )

    return annotated_img
