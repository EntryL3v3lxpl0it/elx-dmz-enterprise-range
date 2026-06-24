#!/usr/bin/env python3
import argparse
import json
import secrets
from datetime import datetime, timezone
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(
        description="Generate ELX training range flags."
    )
    parser.add_argument("--cohort-id", required=True)
    parser.add_argument("--team-id", required=True)
    parser.add_argument("--out", default="flag-manifest.json")
    parser.add_argument("--env-out", default=".env")
    args = parser.parse_args()

    challenge_id = "northstar_customer_idor"
    token = secrets.token_hex(4)
    flag = f"ELX{{{args.team_id}:{challenge_id}:{token}}}"

    manifest = {
        "cohort_id": args.cohort_id,
        "team_id": args.team_id,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "flags": [
            {
                "challenge_id": challenge_id,
                "flag": flag,
                "points": 100,
            }
        ],
    }

    Path(args.out).write_text(json.dumps(manifest, indent=2) + "\n")
    Path(args.env_out).write_text(
        f"NORTHSTAR_FLAG={flag}\nFLAG_MANIFEST={args.out}\n"
    )

    print(f"[+] Generated flag for {args.team_id}: {challenge_id}")


if __name__ == "__main__":
    main()
