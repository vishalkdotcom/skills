---
name: ship-pr
description: "Ship unit: commit, Engineering PR, Guided QA comment. Then stop for human QA."
disable-model-invocation: true
argument-hint: "ticket number"
---

# Ship — PR

One ticket. Opens the Engineering PR. The human does Guided QA and merge.

Read the progress file: [../ship/progress.md](../ship/progress.md). Findings hard/judgement empty per [../ship/review-rules.md](../ship/review-rules.md).

## Steps

1. **Commit** — On the ticket branch. Follow the user's git safety rules. Message: why, not what.

   **Done when:** the ticket diff is committed.

2. **Push and PR** — `git push -u` as needed. Body: `.github/PULL_REQUEST_TEMPLATE.md`. Researched PR: `.github/PULL_REQUEST_TEMPLATE/researched.md`.

   **Done when:** the PR URL exists.

3. **Guided QA comment** — Separate PR comment. Numbered steps mapped one-to-one to acceptance criteria (open this page, do this, expect this). UI tickets: step screenshots via `--attach` (`gh-attach` skill). Non-UI: command-level steps.

   **Done when:** that comment is on the PR. UI: every screenshot is a `user-attachments` URL on that comment.

4. **Progress** — `unit_done: pr`. `next: human-qa`. PR URL in the file.

   **Done when:** the progress file is updated. Then stop.
