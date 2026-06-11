#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: verify-video-resolution.sh <video.webm> [width] [height]" >&2
  exit 1
}

[[ $# -ge 1 ]] || usage

VIDEO="$1"
EXPECTED_W="${2:-1920}"
EXPECTED_H="${3:-1080}"

if [[ ! -f "$VIDEO" ]]; then
  echo "FAIL: file not found: $VIDEO" >&2
  exit 1
fi

if [[ "$VIDEO" == /* ]]; then
  WIN_VIDEO="$(wslpath -w "$VIDEO")"
else
  WIN_VIDEO="$VIDEO"
fi

ACTUAL="$(tr -d '\r' < <(
  pwsh.exe -NoProfile -Command \
    "ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 '$WIN_VIDEO'"
))"

ACTUAL_W="$(echo "$ACTUAL" | cut -d, -f1 | tr -d '[:space:]')"
ACTUAL_H="$(echo "$ACTUAL" | cut -d, -f2 | tr -d '[:space:]')"

if [[ "$ACTUAL_W" == "$EXPECTED_W" && "$ACTUAL_H" == "$EXPECTED_H" ]]; then
  echo "OK: ${ACTUAL_W}x${ACTUAL_H}"
  exit 0
fi

echo "FAIL: expected ${EXPECTED_W}x${EXPECTED_H}, got ${ACTUAL_W}x${ACTUAL_H}" >&2
exit 1
