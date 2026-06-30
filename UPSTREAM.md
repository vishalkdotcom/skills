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

### From Matt (sync with `./scripts/sync-upstream.sh`)

`ask-matt`, `codebase-design`, `decision-mapping`, `diagnosing-bugs`, `domain-modeling`, `grill-me`, `grill-with-docs`, `grilling`, `handoff`, `implement`, `improve-codebase-architecture`, `loop-me`, `prototype`, `resolving-merge-conflicts`, `setup-matt-pocock-skills`, `setup-pre-commit`, `tdd`, `teach`, `to-issues`, `to-prd`, `triage`, `writing-great-skills`

No local forks — all Matt skills match upstream unless you explicitly `--force` a one-off experiment.

**Composable stacks (Jun 2026 refactor):**

- `/grill-with-docs` → runs `/grilling` + `/domain-modeling`
- `/improve-codebase-architecture` → uses `/codebase-design` vocabulary
- `/ask-matt` → router over user-invoked skills

**Upstream renames (sync script does not auto-migrate — handle manually):**

| Old name | New name |
| --- | --- |
| `diagnose` | `diagnosing-bugs` |
| `write-a-skill` | `writing-great-skills` |

### Local-only (yours — never synced from Matt)

`browser-demo-test`, `defuddle`, `json-canvas`, `metabase-local-api`, `obsidian-bases`, `obsidian-cli`, `obsidian-markdown`, `obsidian-vault`, `playwright-cli`, `subagent-explore`, `subagent-investigate`, `test-report-pr-markdown`, `yaak-cli`

Scenario scripts (Tier B `run.ps1` + `flow.js`) live in the separate **`~/repos/wovo-browser-qa`** repo — not in this skills tree.

(`obsidian-vault` shares a name with Matt's personal skill but is **your** vault router — listed in `.upstream-exclude` so sync never overwrites it.)

### Removed / archived (will not be installed)

Listed in [`.upstream-exclude`](./.upstream-exclude): removed skills, `obsidian-vault`, `git-guardrails-claude-code`, `scaffold-exercises`, `edit-article`, in-progress skills except `teach`, `decision-mapping`, and `loop-me`, etc.

**Archived locally:** see [archive/README.md](./archive/README.md).

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
