---
name: browser-demo-test
description: Records 1080p browser demo videos and runs scripted localhost UI checks via Windows Playwright CLI and shell subagents. Use when the user asks for a demo video, browser QA, playwright-cli smoke test, proof-of-work capture, or repeatable UI verification on localhost.
allowed-tools: Bash(playwright-cli:*) Bash(pwsh.exe:*) Bash(npx:*) Bash(npm:*)
---

# Browser demo and test

## Defaults

| Setting      | Value                                                                   |
| ------------ | ----------------------------------------------------------------------- |
| Automation   | Windows `pwsh` + `playwright-cli --browser=chromium` (not WSL/WSLg)     |
| Video        | `resize 1920 1080` before `video-start`                                 |
| Artifacts    | `C:\Users\vishal\Videos\<scenario-slug>\` — scripts in git, videos not  |
| XLSX preview | `~/repos/xlsx-viewer` on **8765** — start only for export-preview beats |

## Quick start

```bash
SKILL="$HOME/.agents/skills/browser-demo-test"
bash "$SKILL/scripts/check-prerequisites.sh" http://localhost:3001/next/login
bash "$SKILL/scripts/run-windows-script.sh" wovo-questionnaire-report \
  "$SKILL/scripts/examples/wovo-questionnaire-report.ps1"
```

## Workflow

1. **Intake** — slug, URL, assertions, whether video/xlsx-viewer beat is needed. Confirm app is up.
2. **Author** — copy `scripts/demo-template.ps1` or `scripts/examples/`. See [REFERENCE.md](REFERENCE.md).
3. **Run** — shell subagent: `run-windows-script.sh <slug> <path-to.ps1>`.
4. **Report** — pass/fail, video path + size, artifact paths. PR: `test-report-pr-markdown`.

## Guardrails

- Playwright CLI over Browser MCP; snapshots on disk, not in chat.
- Stop harness servers when done.
- SSO redirect on login → user handoff or `state-save` / `state-load`.

## More

| Doc                                                              | Contents                                 |
| ---------------------------------------------------------------- | ---------------------------------------- |
| [REFERENCE.md](REFERENCE.md)                                     | Authoring steps, layout, bundled scripts |
| [EXAMPLES.md](EXAMPLES.md)                                       | Ready-to-run scenarios                   |
| [references/artifact-storage.md](references/artifact-storage.md) | Scripts vs videos vs PR evidence         |
| [references/wovo-local.md](references/wovo-local.md)             | WOVO ports, login, export flow           |
| [references/video-quality.md](references/video-quality.md)       | 1080p, `run-code`, HandBrake             |
| [CONTEXT.md](CONTEXT.md)                                         | Terminology                              |
