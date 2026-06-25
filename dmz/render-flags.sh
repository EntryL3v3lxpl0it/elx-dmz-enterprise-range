#!/usr/bin/env bash
# Render per-deploy flag tokens into .flags.env (gitignored). AUTHORIZED LAB USE ONLY.
set -euo pipefail
cd "$(dirname "$0")"

OUT=".flags.env"
: > "$OUT"
for chain in web01 web02 web03 web04 web08; do
  tok="$(openssl rand -hex 8)"
  var="FLAG_$(printf '%s' "$chain" | tr '[:lower:]' '[:upper:]')"
  printf '%s=ELX{%s_%s}\n' "$var" "$chain" "$tok" >> "$OUT"
done
chmod 600 "$OUT"
echo "[+] Wrote $(wc -l < "$OUT") flags to $OUT (gitignored):"
cat "$OUT"
