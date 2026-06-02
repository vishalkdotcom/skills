#!/usr/bin/env bash
# Discover assets, encode videos, emit upload page URL + draft markdown for a ticket.
set -euo pipefail

ticket=""
filter=""

usage() {
  echo "Usage: prepare-ticket-report.sh -Ticket wpm-xxxx [-Filter substring]" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -Ticket)
      ticket="${2:-}"
      shift 2
      ;;
    -Filter)
      filter="${2:-}"
      shift 2
      ;;
    -h | --help)
      usage
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      ;;
  esac
done

[[ -n "$ticket" ]] || usage

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_root="$(cd "$script_dir/.." && pwd)"
# shellcheck source=_git-context.sh
source "$script_dir/_git-context.sh"

trpm_ps() {
  bash "$script_dir/trpm.sh" "$@"
}

echo "## Upload page"
if upload_url="$(trpm_upload_page_url 2>/dev/null)"; then
  echo "$upload_url"
else
  echo "(could not derive from git — open the PR/compare page manually)"
fi
echo

echo "## Assets"
if [[ -n "$filter" ]]; then
  trpm_ps find-ticket-assets -Ticket "$ticket" | grep -i "$filter" || true
else
  trpm_ps find-ticket-assets -Ticket "$ticket"
fi
echo

echo "## Encode"
trpm_ps encode-test-reports -Ticket "$ticket"
echo

echo "## Draft test report"
if [[ -n "$filter" ]]; then
  trpm_ps generate-markdown -Ticket "$ticket" -Mode draft -Filter "$filter"
else
  trpm_ps generate-markdown -Ticket "$ticket" -Mode draft
fi
