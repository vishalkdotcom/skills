#!/usr/bin/env bash
# GitHub repo/branch helpers for test-report-pr-markdown (run from WSL bash in a git repo).

trpm_git_in_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

trpm_git_branch() {
  git branch --show-current 2>/dev/null || true
}

trpm_git_context() {
  local remote

  if ! trpm_git_in_repo; then
    return 1
  fi

  remote="$(git remote get-url origin 2>/dev/null || true)"
  if [[ "$remote" =~ github\.com[:/]+([^/]+)/([^/.]+)(\.git)?$ ]]; then
    printf '%s/%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
    return 0
  fi

  return 1
}

trpm_upload_page_url() {
  local ctx branch owner repo pr_url

  if ! ctx="$(trpm_git_context)"; then
    return 1
  fi

  owner="${ctx%%/*}"
  repo="${ctx#*/}"
  branch="$(trpm_git_branch)"

  if command -v gh >/dev/null 2>&1; then
    pr_url="$(gh pr view --json url -q .url 2>/dev/null || true)"
    if [[ -n "$pr_url" ]]; then
      printf '%s\n' "$pr_url"
      return 0
    fi
  fi

  if [[ -n "$branch" ]]; then
    printf 'https://github.com/%s/%s/compare/%s?expand=1\n' "$owner" "$repo" "$branch"
    return 0
  fi

  printf 'https://github.com/%s/%s/compare?expand=1\n' "$owner" "$repo"
}
