---
name: ship-review
description: "Ship unit: read-only review battery. Findings go in the progress file, then stop."
disable-model-invocation: true
argument-hint: "ticket number"
---

# Ship — review

One ticket. **New memory.** Fresh chat. Read the progress file and `git diff HEAD`.

Rules: [../ship/review-rules.md](../ship/review-rules.md). Template: [../ship/progress.md](../ship/progress.md).

## Steps

1. **Battery** — Run every pass in `review-rules.md` against `git diff HEAD`.

   **Done when:** each pass has a report, or the progress file records that pass as untested with why.

2. **Classify** — Every finding is hard, judgement, or nit per `review-rules.md`. Scope wall items ask the human.

   **Done when:** the progress **Findings** section lists every finding under those headings.

3. **Progress** — `unit_done: review`. `next: implement` when hard or judgement remain; `next: pr` when they are empty (nits may remain). Pasteable next prompt.

   **Done when:** the progress file is updated. Working tree unchanged by this chat. Then stop.
