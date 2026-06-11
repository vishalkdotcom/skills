# Upstream skill sync

This repo is a **personal skills library**: a flat `skills/<name>/` tree symlinked at `~/.agents/skills`. Most engineering/productivity skills originate from [mattpocock/skills](https://github.com/mattpocock/skills); the rest are local-only.

## Source of truth

| Role | Location |
| --- | --- |
| **Upstream** | `https://github.com/mattpocock/skills` (categories under `skills/engineering/`, `skills/productivity/`, etc.) |
| **This repo** | Flat `skills/<name>/` (no category prefix) |
| **Runtime install (other machines)** | `npx skills@latest add mattpocock/skills -g` installs upstream directly to agent dirs — **not** this repo |

Use **this repo** when you want Git history, local forks, and custom skills in one tree. Use **`npx skills`** when installing Matt's pack into a project or agent without maintaining a fork.

## Skill inventory

### From Matt (sync as-is with `./scripts/sync-upstream.sh`)

`diagnose`, `grill-me`, `grill-with-docs`, `handoff`, `improve-codebase-architecture`, `prototype`, `setup-matt-pocock-skills`, `setup-pre-commit`, `tdd`, `teach`, `to-issues`, `to-prd`, `triage`, `write-a-skill`

No local forks — all Matt skills match upstream unless you explicitly `--force` a one-off experiment.

### Local-only (yours — never synced from Matt)

`browser-demo-test`, `defuddle`, `json-canvas`, `metabase-local-api`, `obsidian-bases`, `obsidian-cli`, `obsidian-markdown`, `obsidian-vault`, `playwright-cli`, `test-report-pr-markdown`, `wovo-prototypes`, `yaak-cli`

(`obsidian-vault` shares a name with Matt's personal skill but is **your** vault router — listed in `.upstream-exclude` so sync never overwrites it.)

### Removed / excluded (will not be installed)

Listed in [`.upstream-exclude`](./.upstream-exclude): removed skills, `obsidian-vault`, `git-guardrails-claude-code`, `scaffold-exercises`, `edit-article`, in-progress skills except `teach`, etc.

## Sync workflow

One command when Matt publishes updates:

```bash
./scripts/sync-upstream.sh --dry-run   # preview
./scripts/sync-upstream.sh             # apply
```

Install a new upstream skill (if not excluded):

```bash
./scripts/sync-upstream.sh --add teach
```

Control files:

| File | Purpose |
| --- | --- |
| [`.upstream-forks`](./.upstream-forks) | Matt skills with local customizations — currently empty |
| [`.upstream-exclude`](./.upstream-exclude) | Never install or sync these names (local skills + blocklist) |

After syncing, review and commit:

```bash
git diff skills/
git commit -m "upstream: sync from mattpocock/skills"
```

## Upstream path mapping

Upstream nests skills under category folders. The sync script resolves by **skill name** (directory basename), e.g. `skills/engineering/tdd/` → `skills/tdd/`.
