"""
download_weights.py
-------------------
One-time script to pull DINO and SAM weights from Hugging Face and save them
to app/models/ so the server can boot instantly from local disk on every run.

Run once from the rice_analysis_backend directory:
    python download_weights.py
"""
import os

from transformers import (
    GroundingDinoForObjectDetection,
    GroundingDinoProcessor,
    SamModel,
    SamProcessor,
)

DINO_DIR = "./app/models/dino"
SAM_DIR = "./app/models/sam"

os.makedirs(DINO_DIR, exist_ok=True)
os.makedirs(SAM_DIR, exist_ok=True)

print("Downloading Grounding DINO (IDEA-Research/grounding-dino-base)...")
dino_processor = GroundingDinoProcessor.from_pretrained("IDEA-Research/grounding-dino-base")
dino_model = GroundingDinoForObjectDetection.from_pretrained("IDEA-Research/grounding-dino-base")
print("Saving DINO to", DINO_DIR)
dino_processor.save_pretrained(DINO_DIR)
dino_model.save_pretrained(DINO_DIR)

print("\nDownloading SAM (facebook/sam-vit-base)...")
sam_processor = SamProcessor.from_pretrained("facebook/sam-vit-base")
sam_model = SamModel.from_pretrained("facebook/sam-vit-base")
print("Saving SAM to", SAM_DIR)
sam_processor.save_pretrained(SAM_DIR)
sam_model.save_pretrained(SAM_DIR)

print("\nAll models saved to app/models/. The server will now load from local disk.")
