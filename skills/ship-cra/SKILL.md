---
name: ship-cra
description: Ship merge-ready WPM slices in the legacy CRA frontend — implement, validate, code-review, commit. Use when driving a ticket slice or PRD chunk to done here.
---

# Ship (CRA)

Next sibling: `../next`. No unit-test gate — tests live in **wovo-django**.

Merge-ready tail gates: read [`ship-core/REFERENCE.md`]($HOME/.agents/skills/ship-core/REFERENCE.md) before Review and before any branch or commit request.

## 1. Understand

Read PRD/spec first. Vault tickets: `docs/agents/issue-tracker.md`. Not ticket-ready → `/triage`, `/wayfinder`, or `/grill-with-docs`.

**Done when:** spec read; on `vishalk/wpm-xxxx-…` from `dev` with matching ticket key (wrong-branch WIP moved per ship-core).

## 2. Plan

Skip when upstream already planned; otherwise sketch before coding.

**Done when:** approach is agreed or upstream plan accepted.

## 3. Implement

**Done when:** every planned file change is in place.

## 4. Validate

No dedicated typecheck/lint script in this package. Use IDE diagnostics on edited files.

**Done when:** zero diagnostics on every touched file; residual risks listed for the user if any remain.

## 5. Review

Read ship-core → apply Review criterion.

## 6. Commit

Read ship-core → apply Commit and Early finalize criteria. Opens when **merge-ready**.
