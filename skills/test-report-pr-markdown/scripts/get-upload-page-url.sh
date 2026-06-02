#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_git-context.sh
source "$script_dir/_git-context.sh"

if ! trpm_git_in_repo; then
  echo "Not inside a git repository." >&2
  exit 1
fi

if ! url="$(trpm_upload_page_url)"; then
  echo "Could not derive GitHub upload page URL (check git remote origin)." >&2
  exit 1
fi

printf '%s\n' "$url"
