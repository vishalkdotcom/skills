#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: run-windows-script.sh <scenario-slug> <path-to.ps1>" >&2
  exit 1
fi

SLUG="$1"
SCRIPT="$2"

if [[ ! -f "$SCRIPT" ]]; then
  echo "FAIL: script not found: $SCRIPT" >&2
  exit 1
fi

WIN_DIR="/mnt/c/Users/vishal/Videos/${SLUG}"
WIN_PS1="C:\\Users\\vishal\\Videos\\${SLUG}\\run.ps1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$WIN_DIR"
cp "$SCRIPT" "$WIN_DIR/run.ps1"
cp "$SCRIPT_DIR/parse-playwright-result.ps1" "$WIN_DIR/"

echo "Running $WIN_PS1"
pwsh.exe -NoProfile -Command "& '$WIN_PS1'"
