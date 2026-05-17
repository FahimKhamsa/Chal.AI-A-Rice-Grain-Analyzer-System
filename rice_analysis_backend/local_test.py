"""
local_test.py
--------------
Free local testing script — zero RunPod usage, zero cloud cost.

Runs the full DINO+SAM pipeline on your own hardware using a real image URL
(Supabase signed URL, any public HTTPS URL, or a localhost URL if you expose
one via a tool like ngrok).

Usage:
    python local_test.py

    # Override the test image at the command line:
    python local_test.py https://your-supabase-project.supabase.co/storage/v1/object/sign/...

Configuration:
    Edit the TEST_IMAGE_URL constant below, or set the env var TEST_IMAGE_URL.
    Set SUPABASE_URL + SUPABASE_KEY in .env to enable Supabase image upload.
    Leave them empty to skip upload and test only the CV pipeline locally.
"""
import json
import os
import sys

# ── Test configuration ────────────────────────────────────────────────────────
# Replace with a real rice image URL accessible from this machine.
# Can be a Supabase signed/public URL, any HTTPS image URL, or a local server.
TEST_IMAGE_URL: str = os.environ.get(
    "TEST_IMAGE_URL",
    "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/White_rice.jpg/640px-White_rice.jpg",
)
TEST_THRESHOLD: float = float(os.environ.get("TEST_THRESHOLD", "0.06"))

# ── Optionally override Supabase credentials before loading settings ──────────
# Remove or leave empty to run in offline mode (skips Supabase upload).
if not os.environ.get("SUPABASE_URL"):
    os.environ.setdefault("SUPABASE_URL", "")
if not os.environ.get("SUPABASE_KEY"):
    os.environ.setdefault("SUPABASE_KEY", "")


def run_local_test(image_url: str = TEST_IMAGE_URL, threshold: float = TEST_THRESHOLD) -> None:
    from app.core.ml_manager import load_ai_models
    from app.utils import configure_logging
    from app.services.inference import process_rice_analysis

    configure_logging("INFO")

    # Accept an image URL override from the command line
    if len(sys.argv) > 1:
        image_url = sys.argv[1]

    print("=" * 60)
    print("RICE ANALYSIS — LOCAL TEST")
    print("=" * 60)

    print("\n[STEP 1] Loading AI models on local hardware …")
    load_ai_models()
    print("[STEP 1] Models loaded.\n")

    print(f"[STEP 2] Running pipeline on: {image_url}")
    print(f"         Threshold: {threshold}\n")

    try:
        output = process_rice_analysis(image_url=image_url, threshold=threshold)

        print("\n" + "=" * 60)
        print("LOCAL TEST PASSED")
        print("=" * 60)
        print(json.dumps(output, indent=2))

    except Exception as exc:
        print("\n" + "=" * 60)
        print("LOCAL TEST FAILED")
        print("=" * 60)
        print(f"Error: {exc}")
        raise


if __name__ == "__main__":
    run_local_test()
