#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: run-windows-script.sh <scenario-slug> <path-to-run.ps1>" >&2
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

SCRIPT_DIR="$(cd "$(dirname "$SCRIPT")" && pwd)"
HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WOVO_QA_REPO="${WOVO_BROWSER_QA_REPO:-$HOME/repos/wovo-browser-qa}"

resolve_cli_config() {
  if [[ -n "${PLAYWRIGHT_CLI_CONFIG:-}" && -f "${PLAYWRIGHT_CLI_CONFIG}" ]]; then
    echo "$PLAYWRIGHT_CLI_CONFIG"
    return
  fi

  local next_repo="${WOVO_NEXT_REPO:-/home/vishal/repos/wovo_frontend/next}"
  local config="${next_repo}/.playwright/cli.config.json"
  if [[ -f "$config" ]]; then
    echo "$config"
    return
  fi

  echo "FAIL: Playwright CLI config not found (set PLAYWRIGHT_CLI_CONFIG or WOVO_NEXT_REPO)" >&2
  exit 1
}

CLI_CONFIG="$(resolve_cli_config)"
WIN_CLI_CONFIG="$(wslpath -w "$CLI_CONFIG")"

mkdir -p "$WIN_DIR/.playwright" "$WIN_DIR/lib"
cp "$SCRIPT" "$WIN_DIR/run.ps1"
cp "$HARNESS_DIR/parse-playwright-result.ps1" "$WIN_DIR/"
cp "$CLI_CONFIG" "$WIN_DIR/.playwright/cli.config.json"

shopt -s nullglob
for js in "$SCRIPT_DIR"/*.js; do
  cp "$js" "$WIN_DIR/"
done

if [[ -d "$SCRIPT_DIR/lib" ]]; then
  cp -r "$SCRIPT_DIR/lib/." "$WIN_DIR/lib/"
elif [[ -d "$WOVO_QA_REPO/lib" ]]; then
  cp -r "$WOVO_QA_REPO/lib/." "$WIN_DIR/lib/"
fi

echo "Running $WIN_PS1 (PLAYWRIGHT_MCP_CONFIG=$WIN_CLI_CONFIG)"
pwsh.exe -NoProfile -Command "\$env:PLAYWRIGHT_MCP_CONFIG='$WIN_CLI_CONFIG'; & '$WIN_PS1'"
