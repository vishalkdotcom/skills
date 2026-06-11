---
name: browser-demo-test
description: Records 1080p PR-quality browser demo videos with on-screen AC overlays via Tier B screencast (run-code + flow.js) and runs scripted localhost UI checks on Windows Playwright CLI. Use when the user asks for a demo video, browser QA, playwright-cli smoke test, proof-of-work capture, or repeatable UI verification on localhost.
allowed-tools: Bash(playwright-cli:*) Bash(pwsh.exe:*) Bash(npx:*) Bash(npm:*)
---

# Browser demo and test

## Defaults

| Setting      | Value                                                                   |
| ------------ | ----------------------------------------------------------------------- |
| Automation   | Windows `pwsh` + `playwright-cli --browser=chromium` (not WSL/WSLg)     |
| Video        | Tier B: `run-code` + `page.screencast` at 1920×1080                   |
| Scripts      | `~/repos/wovo-browser-qa/scenarios/<slug>/` (`run.ps1` + `flow.js`)     |
| Artifacts    | `C:\Users\vishal\Videos\<scenario-slug>\` — videos never in git       |
| Plans/evidence | Obsidian vault `qa-plan.md` + `evidence/` — link to scenario repo     |

## Quick start

```bash
SKILL="$HOME/.agents/skills/browser-demo-test"
REPO="$HOME/repos/wovo-browser-qa"
bash "$SKILL/scripts/check-prerequisites.sh" http://localhost:3001/next/login
bash "$SKILL/scripts/run-windows-script.sh" wovo-questionnaire-report \
  "$REPO/scenarios/wovo-questionnaire-report/run.ps1"
```

## Workflow

1. **Intake** — slug, AC list from vault `qa-plan.md`, URLs, fixtures. Confirm app is up.
2. **Author** — copy `wovo-browser-qa/scenarios/demo/` or an exemplar. **Tier B required** for PR demos. See [tier-b-screencast.md](references/tier-b-screencast.md).
3. **Run** — `run-windows-script.sh <slug> <path-to/run.ps1>` (copies `flow.js` + `lib/`).
4. **Report** — pass/fail, video path + size, screenshots. Vault `evidence/` note. PR: `test-report-pr-markdown`.

## Guardrails

- Playwright CLI over Browser MCP; snapshots on disk, not in chat.
- Scripts in `wovo-browser-qa`, not app repos or Obsidian vault.
- Stop harness servers when done.
- SSO redirect on login → user handoff or `state-save` / `state-load`.

## More

| Doc | Contents |
| --- | --- |
| [tier-b-screencast.md](references/tier-b-screencast.md) | AC overlays, flow.js authoring |
| [REFERENCE.md](REFERENCE.md) | Harness scripts, execution |
| [EXAMPLES.md](EXAMPLES.md) | Ready-to-run scenarios |
| [references/artifact-storage.md](references/artifact-storage.md) | Scripts vs videos vs PR evidence |
| [references/wovo-local.md](references/wovo-local.md) | WOVO ports, login |
| [references/video-quality.md](references/video-quality.md) | 1080p checks, HandBrake |
| [CONTEXT.md](CONTEXT.md) | Terminology |
