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
5. **Implement / review / pr:** pane is an idle shell. `herdr agent start <name> --kind cursor --pane <id> -- --force --trust`. Review is a **new** agent every time that unit runs (writer may reuse the implement occupant for a fix pass).
6. **Validate:** `--kind cursor` occupant in the checks pane (browser QA), same start args. Progress file still comes from `ship-validate`.
7. Prompt from [prompt.md](prompt.md) with `--wait` (`herdr agent prompt --help`).
8. When `copy_agreed` is `no`, leave the pane `blocked` for the human.
9. **Unit complete:** the progress file has `unit_done` for this unit. Diagnose a stall with a short pane tail; the progress file is the boundary.
10. Loop 2–9 until `next: human-qa`. Then stop.

**Done when:** each finished unit has a progress file; this chat ran claim-gate on a fresh ticket, applied the layout, and started/waited on pane agents; the human still owns Guided QA and merge.
