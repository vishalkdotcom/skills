---
name: ship-herdr
description: "Herdr runtime for ship: apply the layout, start cursor-agent per unit, wait on the progress file."
disable-model-invocation: true
argument-hint: "ticket number"
---

# Ship — Herdr

Same units as `ship`. This skill owns **where** they run. Layout: [layout.json](layout.json) (labels and splits only — idle shells). Occupants: `--kind cursor` in those panes (`herdr agent --help`). Herdr has no Auto-review card, so start args after `--` are `--force --trust`.

Apply from **this skill’s directory**: `pwsh -File scripts/apply-layout.ps1 -Cwd <repo>`. `--Rebuild` is the script’s param. Pane labels come from `layout.json`. Server must already be running.

## This run

1. Resolve the ticket and repo cwd.
2. Read the progress file when it exists ([../ship/progress.md](../ship/progress.md)). Next unit from [../ship/SKILL.md](../ship/SKILL.md) Units table (`next` field, else implement).
3. Fresh ticket (no progress file): [../ship/claim-gate.md](../ship/claim-gate.md). Stop when that file says stop.
4. Run `apply-layout.ps1`. Keep the printed pane map.
5. **Implement / review / pr:** pane is an idle shell. `herdr agent start <name> --kind cursor --pane <id> -- --force --trust`. Session choice per unit: [Session policy](#session-policy).
6. **Validate:** `--kind cursor` occupant in the checks pane (browser QA), same start args. Progress file still comes from `ship-validate`.
7. Prompt from [prompt.md](prompt.md) with `--wait` (`herdr agent prompt --help`).
8. When `copy_agreed` is `no`, leave the pane `blocked` for the human.
9. **Unit complete:** the progress file has `unit_done` for this unit. Diagnose a stall with a short pane tail; the progress file is the boundary.
10. Loop 2–9 until `next: human-qa`. Then stop.

**Done when:** each finished unit has a progress file; this chat ran claim-gate on a fresh ticket, applied the layout, and started/waited on pane agents; the human still owns Guided QA and merge.

## Session policy

**Per-role rule (primary trigger):**

- **review** — always a new agent. `herdr pane run <pane> "/exit"`, wait for the shell prompt, then `agent start` again — or `/clear` for a same-process reset.
- **implement** — new on first run; a fix pass may reuse the same occupant.
- **validate** — new on first run; a re-validate may reuse with a delta prompt (`Re-run only:` scoped commands, see prompt.md).
- **pr** — always a fresh occupant.
- Do **not** new-session every step — a lean reused session is cheaper and already holds the diff in context.

**Budget override (circuit breaker):** reuse only while the occupant's context stays under ~50–60%. Before every reuse prompt, run `pwsh -NoProfile -File scripts/read-ctx.ps1 -Name <occupant>` (`tokens.ctx` from statusline.js → `report-metadata`, scrape fallback). If `pct >= 50`, rotate instead of prompting again.

**Bounded exception:** fix-pass reuse is safe when the session is well under budget *and* the findings to clear are quoted verbatim in the prompt (fully in context) — #102's 7-minute fix pass is the model. A fix pass that fails either condition rotates.

**Handoff artifact:** the `handoff` skill shape — a Markdown doc in the OS temp dir (never the workspace), tailored to what the next unit will do, with a suggested-skills section, and **references not copies** (ticket URL, progress file path, commits; specs and diffs are never duplicated). Its unique value over the progress file: it carries **why / dead ends / failed approaches** out of an occupant too full — or dead — to write the progress file itself. Production order: prompt the outgoing occupant to run its `handoff` skill (argument: what the next unit does) *before* `/exit`; if the occupant is already dead, the orchestrator reconstructs a minimal handoff from the progress file + Log + branch commits, or omits `Handoff:` — the progress file already covers intra-ticket state.

**Compaction:** `/summarize` (`/compact`) is an intra-unit safety valve only — never the handoff mechanism. At unit boundaries, fresh occupant + artifacts (progress file, handoff doc) beats compaction.
