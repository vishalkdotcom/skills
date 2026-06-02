#!/usr/bin/env bash
# Sync skills from mattpocock/skills into this repo's flat skills/ tree.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
FORKS_FILE="$REPO_ROOT/.upstream-forks"
EXCLUDE_FILE="$REPO_ROOT/.upstream-exclude"
UPSTREAM_REPO="${UPSTREAM_REPO:-https://github.com/mattpocock/skills.git}"
UPSTREAM_REF="${UPSTREAM_REF:-main}"

DRY_RUN=0
FORCE=0
ADD=0
TARGETS=()

usage() {
  cat <<'EOF'
Usage: sync-upstream.sh [options] [skill-name ...]

Sync skill folders from mattpocock/skills into skills/<name>/.

Options:
  --dry-run    Show planned copies without writing
  --force      Overwrite skills listed in .upstream-forks
  --add        Install skill even if not present locally (respects .upstream-exclude)
  -h, --help   Show this help

Environment:
  UPSTREAM_REPO   Git URL (default: https://github.com/mattpocock/skills.git)
  UPSTREAM_REF    Branch or tag (default: main)

With no skill names, syncs every upstream skill that exists locally, is not forked, and is not excluded.
EOF
}

log() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --force) FORCE=1; shift ;;
    --add) ADD=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) die "unknown option: $1" ;;
    *) TARGETS+=("$1"); shift ;;
  esac
done

declare -A FORKS=()
if [[ -f "$FORKS_FILE" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="$(echo "$line" | xargs)"
    [[ -z "$line" ]] && continue
    FORKS["$line"]=1
  done < "$FORKS_FILE"
fi

declare -A EXCLUDED=()
if [[ -f "$EXCLUDE_FILE" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="$(echo "$line" | xargs)"
    [[ -z "$line" ]] && continue
    EXCLUDED["$line"]=1
  done < "$EXCLUDE_FILE"
fi

is_forked() {
  [[ -n "${FORKS[$1]+x}" ]]
}

is_excluded() {
  [[ -n "${EXCLUDED[$1]+x}" ]]
}

TMPDIR="${TMPDIR:-/tmp}"
CLONE_DIR="$(mktemp -d "$TMPDIR/skills-upstream-XXXXXX")"
cleanup() { rm -rf "$CLONE_DIR"; }
trap cleanup EXIT

log "Cloning $UPSTREAM_REPO ($UPSTREAM_REF) ..."
git clone --depth 1 --branch "$UPSTREAM_REF" "$UPSTREAM_REPO" "$CLONE_DIR" --quiet

declare -A UPSTREAM_DIRS=()
while IFS= read -r skill_md; do
  dir="$(dirname "$skill_md")"
  name="$(basename "$dir")"
  UPSTREAM_DIRS["$name"]="$dir"
done < <(find "$CLONE_DIR/skills" -name SKILL.md -type f 2>/dev/null | sort)

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  for name in "${!UPSTREAM_DIRS[@]}"; do
    is_excluded "$name" && continue
    [[ -d "$SKILLS_DIR/$name" ]] || continue
    TARGETS+=("$name")
  done
  # stable order
  IFS=$'\n' TARGETS=($(printf '%s\n' "${TARGETS[@]}" | sort -u))
  unset IFS
fi

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  log "Nothing to sync."
  exit 0
fi

SYNCED=0
SKIPPED=0
MISSING=0

for name in "${TARGETS[@]}"; do
  src="${UPSTREAM_DIRS[$name]:-}"
  dest="$SKILLS_DIR/$name"

  if is_excluded "$name"; then
    log "skip $name — excluded (see .upstream-exclude)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if [[ -z "$src" ]]; then
    log "skip $name — not found in upstream"
    MISSING=$((MISSING + 1))
    continue
  fi

  if is_forked "$name" && [[ "$FORCE" -eq 0 ]]; then
    log "skip $name — forked (see .upstream-forks; use --force to overwrite)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if [[ ! -d "$dest" ]]; then
    if [[ "$ADD" -eq 0 ]]; then
      log "skip $name — not present locally (use --add to install)"
      MISSING=$((MISSING + 1))
      continue
    fi
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "add  $name — would install from ${src#$CLONE_DIR/}"
      SYNCED=$((SYNCED + 1))
      continue
    fi
    log "add  $name ..."
    mkdir -p "$dest"
    rsync -a "$src/" "$dest/"
    SYNCED=$((SYNCED + 1))
    continue
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    if diff -qr "$src" "$dest" >/dev/null 2>&1; then
      log "ok   $name — already identical"
    else
      log "sync $name — would update from ${src#$CLONE_DIR/}"
      diff -qr "$src" "$dest" 2>/dev/null | sed 's/^/      /' || true
    fi
    SYNCED=$((SYNCED + 1))
    continue
  fi

  log "sync $name ..."
  rsync -a --delete "$src/" "$dest/"
  SYNCED=$((SYNCED + 1))
done

log ""
log "Done: $SYNCED processed, $SKIPPED fork-skipped, $MISSING not found/missing-local."
if [[ "$DRY_RUN" -eq 1 ]]; then
  log "(dry-run — no files written)"
fi
