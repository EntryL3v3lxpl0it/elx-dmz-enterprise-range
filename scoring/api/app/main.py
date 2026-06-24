from fastapi import FastAPI, Form, UploadFile, File
from fastapi.responses import JSONResponse
from pathlib import Path
import json
import os
import shutil
from datetime import datetime, timezone

app = FastAPI(title="ELX Scoring API")

FLAG_MANIFEST = Path(os.getenv("FLAG_MANIFEST", "/data/flag-manifest.json"))
SUBMISSIONS = Path("/data/submissions.jsonl")
REPORT_DIR = Path("/data/reports")
REPORT_DIR.mkdir(parents=True, exist_ok=True)

def load_flags():
    if not FLAG_MANIFEST.exists():
        return {}
    manifest = json.loads(FLAG_MANIFEST.read_text())
    return {item["flag"]: item for item in manifest.get("flags", [])}

@app.get("/health")
def health():
    return {"status": "ok", "service": "scoring-api"}

@app.post("/submit-flag")
def submit_flag(team_id: str = Form(...), flag: str = Form(...)):
    flags = load_flags()
    accepted = flag in flags

    event = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "team_id": team_id,
        "flag": flag,
        "accepted": accepted,
        "challenge_id": flags.get(flag, {}).get("challenge_id"),
        "points": flags.get(flag, {}).get("points", 0)
    }

    with SUBMISSIONS.open("a") as f:
        f.write(json.dumps(event) + "\n")

    if accepted:
        return {"accepted": True, "challenge_id": event["challenge_id"], "points": event["points"]}

    return JSONResponse({"accepted": False, "message": "Invalid flag"}, status_code=400)

@app.post("/upload-report")
def upload_report(team_id: str = Form(...), report: UploadFile = File(...)):
    if not report.filename.lower().endswith(".pdf"):
        return JSONResponse({"accepted": False, "message": "PDF required"}, status_code=400)

    out_path = REPORT_DIR / f"{team_id}-final-report.pdf"
    with out_path.open("wb") as f:
        shutil.copyfileobj(report.file, f)

    return {"accepted": True, "path": str(out_path)}
