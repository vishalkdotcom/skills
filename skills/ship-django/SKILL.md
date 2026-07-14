---
name: ship-django
description: Ship merge-ready WPM slices in wovo-django — red implement, tight validate, code-review, commit. Use when driving a ticket slice or PRD chunk to done in this repo.
---

# Ship (wovo-django)

Use **`uv run`**. Only WOVO repo with a unit-test gate in ship.

Merge-ready gates: read [`ship-core/REFERENCE.md`]($HOME/.agents/skills/ship-core/REFERENCE.md) before Understand (active branch), Review, and any branch or commit request.

## 1. Understand

Read PRD/spec first. Vault tickets: `docs/agents/issue-tracker.md`. Read `CONTEXT.md` and ADRs in the touched area. Not ticket-ready → `/triage`, `/wayfinder`, or `/grill-with-docs`.

**Done when:** spec read; on the ticket’s **active branch** for this repo (resolve per ship-core).

## 2. Plan

Skip when upstream already planned; otherwise sketch before coding.

**Done when:** approach is agreed or upstream plan accepted.

## 3. Implement

Behaviour changes: **red → green**, one behaviour at a time.

1. **RED** — one failing test (`APITestCase` for APIs; test services, not Celery)
2. **GREEN** — minimal code
3. **REPEAT**

Refactoring belongs in Review. Narrow runs from `wovo/`: `uv run manage.py test <module_or_class>`.

Ticket names seams: still one **red** per behaviour before shared helpers. TDD depth: **`tdd`** skill. Skip red → green for migrations-only, config, non-behavioural edits.

**Done when:** every behaviour change had a failing test before the fix.

## 4. Validate (tight)

Command patterns: [`VALIDATE.md`](VALIDATE.md).

**Done when:** pre-commit clean; narrow tests green; parent module of every touched test file green once (behaviour changes).

## 5. Review

Read ship-core → apply Review criterion.

## 6. Commit

Read ship-core → apply Commit and Early finalize criteria. Opens when **merge-ready**.
