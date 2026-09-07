---
name: ship-herdr
description: "Herdr runtime for ship: apply the layout, start cursor-agent per unit, wait on the progress file."
disable-model-invocation: true
argument-hint: "ticket number"
---

# Ship — Herdr

Same units as `ship`. This skill owns **where** they run. Layout: [layout.json](layout.json) (labels and splits only — idle shells). Occupants: `--kind cursor` in those panes (`herdr agent --help`).

Apply from **this skill’s directory**: `pwsh -File scripts/apply-layout.ps1 -Cwd <repo>`. `--Rebuild` is the script’s param. Pane labels come from `layout.json`. Server must already be running.

## This run

1. Resolve the ticket and repo cwd. Run `apply-layout.ps1`. Keep the printed pane map.
2. Read the progress file when it exists ([../ship/progress.md](../ship/progress.md)). Next unit from [../ship/SKILL.md](../ship/SKILL.md) Units table (`next` field, else implement).
3. **Implement / review / pr:** pane is an idle shell. Start `--kind cursor` (`herdr agent --help`). Review is a **new** agent every time that unit runs (writer may reuse the implement occupant for a fix pass).
4. **Validate:** `--kind cursor` occupant in the checks pane (browser QA). Progress file still comes from `ship-validate`.
5. Prompt with `--wait` (`herdr agent prompt --help`). The prompt names the unit skill (`ship-implement` / …), the ticket, and the progress file.
6. When plan or copy is still open, leave the pane `blocked` for the human.
7. **Unit complete:** the progress file has `unit_done` for this unit. Diagnose a stall with a short pane tail; the progress file is the boundary.
8. Loop 2–7 until `next: human-qa`. Then stop.

**Done when:** each finished unit has a progress file; this chat only applied the layout and started/waited on pane agents; the human still owns Guided QA and merge.
