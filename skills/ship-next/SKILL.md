---
name: ship-next
description: Ship merge-ready WPM slices in this Next.js repo — implement, tight validate, code-review, commit. Use when driving a ticket slice or PRD chunk to done here.
---

# Ship (next)

CRA sibling: `../frontend`. No unit-test gate — tests live in **wovo-django**.

Merge-ready tail gates: read [`ship-core/REFERENCE.md`]($HOME/.agents/skills/ship-core/REFERENCE.md) before Review and before any branch or commit request.

## 1. Understand

Read PRD/spec first. Vault tickets: `docs/agents/issue-tracker.md`. Not ticket-ready → `/triage`, `/wayfinder`, or `/grill-with-docs`.

**Done when:** spec read; on `vishalk/wpm-xxxx-…` from `dev` with matching ticket key (wrong-branch WIP moved per ship-core).

## 2. Plan

Skip when upstream already planned; otherwise sketch before coding.

**Done when:** approach is agreed or upstream plan accepted.

## 3. Implement

Run `npm run typecheck` during non-trivial TypeScript edits.

**Done when:** every planned file change is in place; typecheck passes on touched TypeScript.

## 4. Validate (tight)

From `next/`: `npm run typecheck` then `npm run lint:fix` until both pass. Heap OOM: `NODE_OPTIONS="--max-old-space-size=8192"` per `AGENTS.md`.

**Done when:** typecheck and lint:fix both green.

## 5. Review

Read ship-core → apply Review criterion.

## 6. Commit

Read ship-core → apply Commit and Early finalize criteria. Opens when **merge-ready**.
