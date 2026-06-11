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

mkdir -p "$WIN_DIR/.playwright"
cp "$SCRIPT" "$WIN_DIR/run.ps1"
cp "$SCRIPT_DIR/parse-playwright-result.ps1" "$WIN_DIR/"
cp "$CLI_CONFIG" "$WIN_DIR/.playwright/cli.config.json"

echo "Running $WIN_PS1 (PLAYWRIGHT_MCP_CONFIG=$WIN_CLI_CONFIG)"
pwsh.exe -NoProfile -Command "\$env:PLAYWRIGHT_MCP_CONFIG='$WIN_CLI_CONFIG'; & '$WIN_PS1'"
