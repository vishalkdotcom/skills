---
name: ship
description: "Router: one GitHub ticket to one Engineering PR as four units and two human gates."
disable-model-invocation: true
argument-hint: "ticket number"
---

# Ship

One GitHub ticket becomes one Engineering PR.

This skill **names** the next unit, then stop.

Human gates (you):

1. Agree the plan (and copy, for UI) before code.
2. Guided QA, then merge.

## Units

| Unit | Skill | When |
| --- | --- | --- |
| implement | `ship-implement` | no progress file, or `next: implement` |
| validate | `ship-validate` | `next: validate` |
| review | `ship-review` | `next: review` (new chat every time the diff changed) |
| pr | `ship-pr` | `next: pr` |

After review findings: `ship-implement` (writer), then `ship-validate`, then a **new** `ship-review` when the diff changed.

Runtime with Herdr panes: `ship-herdr`. Same units. Layout: `ship-herdr/layout.json`.

## Progress file

Path: `.scratch/ship-<ticket>.md` in the repo (gitignored). Template: [progress.md](progress.md).

The next unit reads that file and GitHub.

## This run

1. Resolve the ticket number (argument, user message, or progress file).
2. If the progress file exists, its `next` field is the unit. Else the unit is `implement`.
3. Say the skill to open (`ship-implement` / `ship-validate` / `ship-review` / `ship-pr`, or `ship-herdr` when the user asked for Herdr). Give the progress path.
4. Stop.

**Done when:** the reply contains the next skill name and the progress path.
