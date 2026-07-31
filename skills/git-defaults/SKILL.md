---
name: git-defaults
description: Git config defaults and behavioral gotchas already applied globally on this machine (aliases, merge/pull/push/editor behavior). Use when running git commands whose behavior depends on custom config (commit, merge, rebase, push, stash, pull), or when asked about newer Git features/config added after typical model training cutoffs.
---

# Git Defaults

## Applied globally on this machine

| Key | Value |
|---|---|
| pull.rebase | true |
| pull.autostash | true |
| rebase.autostash | true |
| fetch.prune | true |
| push.default | current |
| push.autoSetupRemote | true |
| merge.ff | only |
| merge.conflictstyle | zdiff3 |
| diff.colorMoved | zebra |
| rerere.enabled | true |
| stash.index | true |
| commitGraph.changedPaths | true |
| core.autocrlf | true |
| core.longpaths | true |
| core.editor | scripts/git-editor.sh |
| help.autoCorrect | prompt |
| column.ui | auto |
| branch.sort | -committerdate |

Aliases: `st`=status, `co`=switch, `br`=branch, `lg`=log --oneline --graph --decorate --all, `last`=log -1 HEAD, `amend`=commit --amend --no-edit.

`core.autocrlf`/`core.longpaths` are Windows-specific entries — don't expect them on macOS/Linux machines. If a machine's state is otherwise uncertain, verify with `git config --global --list` rather than assuming these are set.

## Gotchas these defaults create

- `merge.ff=only` — a plain `git merge` fails unless fast-forwardable. Rebase onto the target first instead of assuming merge will succeed.
- `core.editor` runs [scripts/git-editor.sh](scripts/git-editor.sh): detects Zed, then Cursor, then plain VS Code by terminal env vars, else defaults to Cursor. Runs through Git for Windows' own bundled `sh`. Either way, any command that would open an editor (`commit` without `-m`, `rebase -i`, `tag -a` without `-m`) blocks until that window closes — pass an explicit message/flag instead of relying on it.
- `co` is aliased to `switch`, not `checkout` — it won't restore files (`git co -- path` doesn't work). Use `git restore <path>` instead.
- `push.default=current` + `push.autoSetupRemote` — first push of a new branch doesn't need `-u`/`--set-upstream`.
- These are `--global` scope only. Don't propagate them into a shared repo's tracked config without the user asking — teammates may not share these preferences.

## Newer Git features

Git ships new config keys and commands roughly every two months, so the defaults above can go stale. See [new-features.md](new-features.md) for researched additions sourced from official Git release notes, not yet folded into the defaults above. Check the version/date range it covers before citing a claim as current, and re-research (the `research` skill) if it looks out of date.
