---
name: ship-validate
description: "Ship unit: repo checks and browser QA. Write the progress file and stop."
disable-model-invocation: true
argument-hint: "ticket number"
---

# Ship — validate

One ticket. This chat runs checks and browser QA.

Read the progress file first: [../ship/progress.md](../ship/progress.md).

## Steps

1. **Scripts** — Run the commands the repo’s Engineering PR CI runs, in that workflow’s order (`.github/workflows/`, script names from `package.json`). Skip CI-only setup (for example `playwright install --with-deps`).

   **Done when:** those commands exit 0. Record each command and exit code in the progress file.

2. **Browser QA** — When the ticket touches UI routes or components: `playwright-cli` skill against the running app. Pages load. No console errors. The ticket's key interaction works. Capture screenshots for the Guided QA comment. Data/lib-only tickets skip this step and mark screenshots `n/a`.

   **Done when:** smoke pass succeeded and screenshot paths are in the progress file, or the skip is recorded.

3. **Progress** — Update the progress file. `unit_done: validate`. `next: review`. Pasteable next prompt naming `ship-review`.

   **Done when:** that file matches this unit's evidence. Then stop.
