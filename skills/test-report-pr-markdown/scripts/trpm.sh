#!/usr/bin/env bash
# WSL helper: run test-report-pr-markdown scripts (PowerShell or bash).
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: trpm.sh <script-name-without-extension> [args...]" >&2
  echo "Example: trpm.sh find-ticket-assets -Ticket wpm-3267" >&2
  echo "Example: trpm.sh prepare-ticket-report -Ticket wpm-3370" >&2
  exit 1
fi

script_name="$1"
shift

skill_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bash_script="$skill_root/scripts/${script_name}.sh"
ps_script="$skill_root/scripts/${script_name}.ps1"

if [[ -f "$bash_script" ]]; then
  exec bash "$bash_script" "$@"
fi

if [[ ! -f "$ps_script" ]]; then
  echo "Script not found: $bash_script or $ps_script" >&2
  exit 1
fi

win_script="$(wslpath -w "$ps_script")"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$win_script" "$@"
