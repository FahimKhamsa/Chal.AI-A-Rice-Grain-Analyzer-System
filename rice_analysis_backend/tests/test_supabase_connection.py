"""
tests/test_supabase_connection.py
-----------------------------------
Diagnostic script: verifies that the backend can connect to your Supabase
instance, upload result images to Storage, and insert analysis records into
the database — using the exact same data structures that process_rice_analysis()
produces in production.

Run from the rice_analysis_backend/ directory:
    python -m tests.test_supabase_connection

Prerequisites:
  1. .env must contain SUPABASE_URL and SUPABASE_KEY (service_role key).
  2. Storage bucket 'analysis-results' must exist:
       Supabase Dashboard → Storage → New bucket → "analysis-results" → Private
  3. Database table 'rice_analysis_records' must exist.
     Run the following SQL once in Supabase Dashboard → SQL Editor:

     ── TABLE SCHEMA ──────────────────────────────────────────────────────────
     CREATE TABLE rice_analysis_records (
         id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
         analyzed_at          timestamptz      NOT NULL,
         processing_time_ms   integer          NOT NULL,
         integrity_score      real             NOT NULL,
         counts               jsonb            NOT NULL,
         morphology_report    jsonb            NOT NULL,
         color_report         jsonb            NOT NULL,
         morphology_image_url text,
         color_image_url      text,
         created_at           timestamptz      DEFAULT now()
     );
     ─────────────────────────────────────────────────────────────────────────
"""
import sys
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path

# Allow running as:  python -m tests.test_supabase_connection
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import cv2
import numpy as np
from supabase import create_client, Client

from app.core.config import settings

# ── Colour codes for terminal output ─────────────────────────────────────────
GREEN  = "\033[92m"
RED    = "\033[91m"
YELLOW = "\033[93m"
CYAN   = "\033[96m"
RESET  = "\033[0m"

PASS = f"{GREEN}[PASS]{RESET}"
FAIL = f"{RED}[FAIL]{RESET}"
INFO = f"{CYAN}[INFO]{RESET}"
WARN = f"{YELLOW}[WARN]{RESET}"


# ─────────────────────────────────────────────────────────────────────────────
# Helper: build a mock annotated image using OpenCV (no Pillow needed)
# ─────────────────────────────────────────────────────────────────────────────

def _make_mock_annotated_image() -> bytes:
    """
    Produce a 400×400 JPEG image that mimics a morphology annotation frame:
    green background with labelled bounding boxes for 3 mock grains.
    Returns raw JPEG bytes ready for Supabase Storage upload.
    """
    canvas = np.full((400, 400, 3), (34, 100, 34), dtype=np.uint8)  # dark green bg

    # Three mock grain bounding boxes (x1, y1, x2, y2) with categories
    grains = [
        ((60, 80), (160, 140),  (0, 255, 0),   "1.02x Healthy"),
        ((190, 90), (290, 145), (255, 255, 0),  "0.62x 3/4"),
        ((310, 85), (380, 135), (255, 0, 0),    "0.38x Half"),
    ]
    for (x1, y1), (x2, y2), color, label in grains:
        cv2.rectangle(canvas, (x1, y1), (x2, y2), color, 2)
        cv2.putText(canvas, label, (x1, y1 - 8),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.4, color, 1)

    cv2.putText(canvas, "DIAGNOSTIC MOCK IMAGE", (70, 230),
                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
    cv2.putText(canvas, "rice_analysis_backend", (95, 265),
                cv2.FONT_HERSHEY_SIMPLEX, 0.5, (200, 200, 200), 1)

    # Encode to JPEG bytes (OpenCV encodes in BGR — canvas is already BGR)
    _, buffer = cv2.imencode(".jpg", canvas, [cv2.IMWRITE_JPEG_QUALITY, 85])
    return buffer.tobytes()


# ─────────────────────────────────────────────────────────────────────────────
# Step helpers
# ─────────────────────────────────────────────────────────────────────────────

def step_init_client() -> Client:
    """STEP 1 — Validate credentials and create the Supabase client."""
    print(f"\n{CYAN}{'-' * 55}{RESET}")
    print(f"{CYAN}  STEP 1 · Initialise Supabase Client{RESET}")
    print(f"{CYAN}{'-' * 55}{RESET}")

    if not settings.SUPABASE_URL:
        raise EnvironmentError("SUPABASE_URL is not set in .env")
    if not settings.SUPABASE_KEY:
        raise EnvironmentError("SUPABASE_KEY is not set in .env")

    print(f"{INFO} Project URL : {settings.SUPABASE_URL}")
    print(f"{INFO} Key role    : service_role (masked)")
    print(f"{INFO} Bucket      : {settings.SUPABASE_RESULTS_BUCKET}")

    sb = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
    print(f"{PASS} Client initialised.")
    return sb


def step_storage_upload(sb: Client) -> tuple[str, str]:
    """STEP 2 — Generate a mock annotated image and upload it to Storage."""
    print(f"\n{CYAN}{'-' * 55}{RESET}")
    print(f"{CYAN}  STEP 2 · Storage Upload (bucket: {settings.SUPABASE_RESULTS_BUCKET}){RESET}")
    print(f"{CYAN}{'-' * 55}{RESET}")

    run_id = str(uuid.uuid4())
    morph_path = f"morphology/diagnostic_{run_id}.jpg"

    print(f"{INFO} Generating mock morphology annotation image …")
    img_bytes = _make_mock_annotated_image()
    print(f"{INFO} Image size  : {len(img_bytes):,} bytes")
    print(f"{INFO} Upload path : {morph_path}")

    sb.storage.from_(settings.SUPABASE_RESULTS_BUCKET).upload(
        path=morph_path,
        file=img_bytes,
        file_options={"content-type": "image/jpeg", "upsert": "true"},
    )

    public_url: str = sb.storage.from_(
        settings.SUPABASE_RESULTS_BUCKET
    ).get_public_url(morph_path)

    print(f"{PASS} Upload successful.")
    print(f"{INFO} Public URL  : {public_url}")
    return run_id, public_url


def step_database_insert(sb: Client, run_id: str, morph_url: str) -> None:
    """
    STEP 3 — Insert a mock record into rice_analysis_records using the EXACT
    field names and types that process_rice_analysis() returns in production.

    Requires the table to exist — see the SQL schema at the top of this file.
    """
    print(f"\n{CYAN}{'-' * 55}{RESET}")
    print(f"{CYAN}  STEP 3 · Database Insert (table: rice_analysis_records){RESET}")
    print(f"{CYAN}{'-' * 55}{RESET}")

    # Mirror the exact return dict of process_rice_analysis()
    # (app/api/v1/endpoints/analyze.py → process_rice_analysis)
    mock_record = {
        # ── Metadata ──────────────────────────────────────────────────────────
        "id":                   run_id,
        "analyzed_at":          datetime.now(timezone.utc).isoformat(),
        "processing_time_ms":   1420,           # int   — wall-clock ms

        # ── Derived score ─────────────────────────────────────────────────────
        "integrity_score":      88.5,           # float — healthy / total * 100

        # ── Grain counts (process_rice_analysis → "counts" dict) ──────────────
        # Discolored grains are subtracted from their morphology bucket here.
        "counts": {
            "healthy":              45,         # int
            "three_quarter_broken":  3,         # int
            "half_broken":           2,         # int
            "impurity":              1,         # int
            "discolored":            4,         # int
        },

        # ── Raw reports (pre-deduction; useful for debugging) ─────────────────
        "morphology_report": {
            "Healthy":          48,             # int (before discolored subtraction)
            "3/4 Broken":        4,
            "Half Broken":       2,
            "Impurity (Dust)":   1,
        },
        "color_report": {
            "Standard Color":   51,             # int
            "Discolored":        4,             # int
        },

        # ── Supabase Storage URLs ─────────────────────────────────────────────
        "morphology_image_url": morph_url,      # str  — uploaded in STEP 2
        "color_image_url":      None,           # str | None
    }

    print(f"{INFO} Record ID   : {run_id}")
    print(f"{INFO} Integrity   : {mock_record['integrity_score']}%")
    print(f"{INFO} Counts      : {mock_record['counts']}")

    sb.table("rice_analysis_records").insert(mock_record).execute()

    print(f"{PASS} Row inserted into 'rice_analysis_records'.")


# ─────────────────────────────────────────────────────────────────────────────
# Main diagnostic runner
# ─────────────────────────────────────────────────────────────────────────────

def run_diagnostic() -> None:
    print(f"\n{CYAN}{'=' * 55}{RESET}")
    print(f"{CYAN}  RICE ANALYSIS - SUPABASE CONNECTION DIAGNOSTIC{RESET}")
    print(f"{CYAN}{'=' * 55}{RESET}")

    results: dict[str, bool] = {
        "Client Init":      False,
        "Storage Upload":   False,
        "Database Insert":  False,
    }
    sb = None

    # ── Step 1: Client ────────────────────────────────────────────────────────
    try:
        sb = step_init_client()
        results["Client Init"] = True
    except Exception as exc:
        print(f"{FAIL} Client init failed: {exc}")
        _print_summary(results)
        return

    # ── Step 2: Storage ───────────────────────────────────────────────────────
    run_id = morph_url = None
    try:
        run_id, morph_url = step_storage_upload(sb)
        results["Storage Upload"] = True
    except Exception as exc:
        print(f"{FAIL} Storage upload failed: {exc}")
        print(f"{WARN} Make sure the bucket '{settings.SUPABASE_RESULTS_BUCKET}' exists.")

    # ── Step 3: Database ──────────────────────────────────────────────────────
    if run_id and morph_url:
        try:
            step_database_insert(sb, run_id, morph_url)
            results["Database Insert"] = True
        except Exception as exc:
            print(f"{FAIL} Database insert failed: {exc}")
            print(f"{WARN} Make sure 'rice_analysis_records' table exists.")
            print(f"{WARN} See the SQL schema at the top of this file.")
    else:
        print(f"\n{WARN} Skipping DB insert — Storage step failed (no URL to store).")

    _print_summary(results)


def _print_summary(results: dict[str, bool]) -> None:
    all_passed = all(results.values())
    print(f"\n{CYAN}{'=' * 55}{RESET}")
    print(f"{CYAN}  DIAGNOSTIC SUMMARY{RESET}")
    print(f"{CYAN}{'=' * 55}{RESET}")
    for step, passed in results.items():
        status = PASS if passed else FAIL
        print(f"  {status}  {step}")
    print(f"{CYAN}{'-' * 55}{RESET}")
    if all_passed:
        print(f"{GREEN}  ALL CHECKS PASSED - Supabase is ready for RunPod.{RESET}")
    else:
        print(f"{RED}  ONE OR MORE CHECKS FAILED - see details above.{RESET}")
    print(f"{CYAN}{'=' * 55}{RESET}\n")


if __name__ == "__main__":
    run_diagnostic()
