---
name: ship-implement
description: "Ship unit: understand, branch, plan gate, TDD. Write the progress file and stop."
disable-model-invocation: true
argument-hint: "ticket number"
---

# Ship — implement

One ticket. This chat writes the ticket’s code.

Progress file: [../ship/progress.md](../ship/progress.md). Findings to clear: [../ship/review-rules.md](../ship/review-rules.md).

## Steps

1. **Understand** — `gh issue view <n> --comments`. Parent spec the ticket names. `CODING_STANDARDS.md` for every layer this ticket hits. UI tickets: prototype branch `NOTES.md` vs `DESIGN.md` (conflict with no recorded break → `DESIGN.md` is stale). Token budget: `docs/agents/to-tickets-guidance.md` when that file exists — if the work is overrunning, stop and propose a split.

   **Done when:** you can state the acceptance criteria, the spec constraints, and which component layers the work touches.

2. **Branch** — Branch per ticket as `docs/agents/to-tickets-guidance.md` (or `AGENTS.md` if that file is absent).

   **Done when:** HEAD is the ticket branch.

3. **Plan** — Architecture before code: layers, server/client split, where state lives (URL via nuqs / local / server). `CODING_STANDARDS.md` and the files it names. UI copy (titles, paragraphs, empty states): brainstorm with the human against `PRODUCT.md` when that file exists.

   **Done when:** the human has agreed the approach and, for UI tickets, the copy. Stop here while that is open.

4. **Implement** — Only what the ticket asks, under `CODING_STANDARDS.md`. TDD at ticket seams (`tdd` skill). During non-trivial edits, run the `check` and `typecheck` scripts `package.json` names. If Findings lists hard or judgement: clear those this unit, then re-run check and typecheck.

   **Done when:** every acceptance criterion holds in the working tree. If Findings listed hard or judgement, those are cleared as well.

5. **Progress** — Write the progress file from the template. `unit_done: implement`. `next: validate`. Pasteable next prompt naming `ship-validate`.

   **Done when:** that file is on disk with evidence and next prompt. Then stop.
