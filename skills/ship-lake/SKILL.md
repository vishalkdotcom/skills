---
name: ship-lake
description: Ship merge-ready WPM slices in click-lake — implement, tight validate, code-review, commit. Use when driving a ticket slice or PRD chunk to done here.
---

# Ship (click-lake)

Use `uv run`. Follow `.cursorrules` for dbt layers and PeerDB. No unit-test gate — suggest `dbt test` for the user; do not run dbt commands directly.

Merge-ready gates: read [`ship-core/REFERENCE.md`]($HOME/.agents/skills/ship-core/REFERENCE.md) before Understand (active branch), Review, and any branch or commit request.

## 1. Understand

Read PRD/vault ticket first (`docs/agents/issue-tracker.md`, `CONTEXT.md` when present). Not ticket-ready → `/triage`, `/wayfinder`, or `/grill-with-docs`.

**Done when:** spec read; on the ticket’s **active branch** for this repo (resolve per ship-core; base `master`).

## 2. Plan

Skip when upstream already planned; otherwise sketch before coding. Weigh table vs incremental for model changes.

**Done when:** approach is agreed or upstream plan accepted.

## 3. Implement

**Done when:** every planned model/file change is in place and matches the agreed plan.

## 4. Validate (tight)

```bash
uv run pre-commit run --files <paths-you-changed>
uv run sqlfluff lint --dialect clickhouse <changed.sql>
```

Suggest `dbt parse`, `dbt run --select …`, `dbt test --select …` for the user.

**Done when:** pre-commit clean; sqlfluff clean on changed SQL.

## 5. Review

Read ship-core → apply Review criterion.

## 6. Commit

Read ship-core → apply Commit and Early finalize criteria. Opens when **merge-ready**.
