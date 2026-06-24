#!/usr/bin/env bash
set -euo pipefail

PORTAL_URL="${PORTAL_URL:-http://127.0.0.1:8000}"
SCORING_URL="${SCORING_URL:-http://127.0.0.1:9000}"
COOKIE_FILE="/tmp/northstar.cookies"

echo "[+] Checking northstar-portal health"
curl -fsS "${PORTAL_URL}/health" | jq

echo "[+] Checking scoring-api health"
curl -fsS "${SCORING_URL}/health" | jq

echo "[+] Logging in as alex.customer"
curl -fsS -i \
  -c "${COOKIE_FILE}" \
  -X POST "${PORTAL_URL}/login" \
  -F "username=alex.customer" \
  -F "password=Password123!" >/tmp/northstar-login.txt

grep -q "302 Found" /tmp/northstar-login.txt
grep -q "location: /customers/1001" /tmp/northstar-login.txt

echo "[+] Validating legitimate profile access"
curl -fsS \
  -b "${COOKIE_FILE}" \
  "${PORTAL_URL}/customers/1001" \
  | tee /tmp/northstar-1001.html \
  | grep -q "Alex Rivera"

echo "[+] Validating intentional IDOR path"
FLAG_VALUE="$(
  curl -fsS \
    -b "${COOKIE_FILE}" \
    "${PORTAL_URL}/customers/1002" \
    | tee /tmp/northstar-1002.html \
    | grep -o 'ELX{[^}]*}'
)"

if [[ -z "${FLAG_VALUE}" ]]; then
  echo "[-] Failed to extract flag"
  exit 1
fi

echo "[+] Extracted flag: ${FLAG_VALUE}"

echo "[+] Submitting valid flag"
curl -fsS -X POST "${SCORING_URL}/submit-flag" \
  -F "team_id=team1" \
  -F "flag=${FLAG_VALUE}" \
  | tee /tmp/flag-submit-valid.json \
  | jq

jq -e '.accepted == true' /tmp/flag-submit-valid.json >/dev/null

echo "[+] Submitting invalid flag"
set +e
curl -s -X POST "${SCORING_URL}/submit-flag" \
  -F "team_id=team1" \
  -F "flag=ELX{wrong}" \
  | tee /tmp/flag-submit-invalid.json \
  | jq
set -e

jq -e '.accepted == false' /tmp/flag-submit-invalid.json >/dev/null

echo "[+] Validating PDF upload"
printf '%s\n' '%PDF-1.4' 'ELX MVP validation report placeholder' '%%EOF' > /tmp/team1-report.pdf

curl -fsS -X POST "${SCORING_URL}/upload-report" \
  -F "team_id=team1" \
  -F "report=@/tmp/team1-report.pdf" \
  | tee /tmp/report-upload.json \
  | jq

jq -e '.accepted == true' /tmp/report-upload.json >/dev/null

echo "[+] Local MVP validation passed"
