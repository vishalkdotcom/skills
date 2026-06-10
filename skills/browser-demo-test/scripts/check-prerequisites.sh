#!/usr/bin/env bash
set -euo pipefail

URL="${1:-http://localhost:3001/next/login}"

echo "Checking app: $URL"
code="$(curl -s -o /dev/null -w '%{http_code}' "$URL" || true)"
if [[ "$code" != "200" && "$code" != "302" ]]; then
  echo "FAIL: expected HTTP 200/302, got $code" >&2
  exit 1
fi
echo "OK: app responded $code"

echo "Checking Windows playwright-cli..."
pwsh.exe -NoProfile -Command "playwright-cli --version" >/dev/null
echo "OK: playwright-cli available"

echo "PREREQ_OK"
