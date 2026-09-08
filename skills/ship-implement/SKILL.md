---
name: ship-implement
description: "Ship unit: brief, branch, copy, TDD. Write the progress file and stop."
disable-model-invocation: true
argument-hint: "ticket number"
---

# Ship — implement

One ticket. This chat writes the ticket’s code. This chat stays in Agent. The ticket is the approach.

Progress file: [../ship/progress.md](../ship/progress.md). `gh` and retries: [../ship/tool-calls.md](../ship/tool-calls.md).

If the progress Brief is already filled and `copy_agreed` is `yes` or `n/a`, skip to Branch then [implement.md](implement.md).

## Steps

1. **Claim** — Fresh ticket only (no progress file): [../ship/claim-gate.md](../ship/claim-gate.md).

   **Done when:** that file's Done when holds, or a progress file already exists.

2. **Brief** — One `gh issue view <n> --comments`. Quote every AC into the progress Brief. Parent spec: the section the ticket names. `CODING_STANDARDS.md` index; open a child for a layer the ticket's files sit in. UI: prototype path the ticket names (`NOTES.md` vs `DESIGN.md`; conflict with no recorded break → `DESIGN.md` is stale). Seam paths the ticket needs: one explore subagent; parent writes the paths it returns. Search the repo cwd and paths the ticket names. Token budget: `docs/agents/to-tickets-guidance.md` when that file exists — if the Brief still cannot be filled after that explore pass, stop and propose a split.

   **Done when:** the progress Brief quotes every AC, names layers, names the lock path or `n/a`, and lists seam paths from the explore subagent.

3. **Copy** — User-facing strings. If every string is in the ticket, `copy_agreed: n/a`. If a string is missing, ask against `PRODUCT.md` when that file exists; wait until the human answers.

   **Done when:** `copy_agreed` is `yes` or `n/a`. Stop while it is `no`.

4. **Branch** — Branch per ticket as `docs/agents/to-tickets-guidance.md` (or `AGENTS.md` if that file is absent).

   **Done when:** HEAD is the ticket branch.

5. **Code** — [implement.md](implement.md).

   **Done when:** that file's Done when holds.
