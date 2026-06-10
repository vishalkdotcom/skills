---
name: browser-demo-test
description: Records 1080p browser demo videos and runs scripted UI verification via Windows Playwright CLI with token-efficient subagent orchestration. Use when the user asks for a demo video, browser QA, scenario walkthrough, playwright-cli testing, proof-of-work capture, or repeatable UI smoke tests on localhost.
allowed-tools: Bash(playwright-cli:*) Bash(pwsh.exe:*) Bash(npx:*) Bash(npm:*)
---

# Browser demo and test

Domain terms: [CONTEXT.md](CONTEXT.md).

## Defaults

| Setting              | Value                                                                        |
| -------------------- | ---------------------------------------------------------------------------- |
| Browser automation   | **Windows `pwsh`** — `playwright-cli --browser=chromium` (not WSL/WSLg)      |
| Agent reads skills   | WSL `~/.agents/skills` (symlink to `~/repos/skills/skills`)                  |
| Video resolution     | **1920×1080** — `playwright-cli resize 1920 1080` before `video-start`       |
| Artifact directory   | `C:\Users\vishal\Videos\<scenario-slug>\` (`.webm`, snapshot `.yml`, `.png`) |
| XLSX preview harness | `~/repos/xlsx-viewer` on port **8765** (start only for export-preview beats) |
| PR test reports      | Pair with `test-report-pr-markdown` when attaching to a WPM PR               |

WOVO login, ports, and app paths: [references/wovo-local.md](references/wovo-local.md).  
Where scripts vs videos live: [references/artifact-storage.md](references/artifact-storage.md).  
Polished demos with chapters/overlays: [references/video-quality.md](references/video-quality.md).

## Quick start

```bash
SKILL="$HOME/.agents/skills/browser-demo-test"
bash "$SKILL/scripts/check-prerequisites.sh" http://localhost:3001/next/login

# Run a bundled WOVO example
bash "$SKILL/scripts/run-windows-script.sh" wovo-questionnaire-report \
  "$SKILL/scripts/examples/wovo-questionnaire-report.ps1"
```

## What lives where

| Location                                     | In git? | Purpose                                                          |
| -------------------------------------------- | ------- | ---------------------------------------------------------------- |
| `scripts/demo-template.ps1`                  | Yes     | **Template** — copy when authoring a new scenario                |
| `scripts/examples/*.ps1`                     | Yes     | **Examples** — ready-to-run product-specific scenarios           |
| Feature repo `scripts/` (optional)           | Yes     | Ticket-specific scenario scripts co-located with the PR          |
| `~/repos/xlsx-viewer/scripts/smoke-test.ps1` | Yes     | **Harness smoke test** — xlsx-viewer only                        |
| `C:\Users\vishal\Videos\<slug>\`             | **No**  | Run artifacts: `.webm`, snapshots, screenshots                 |
| `C:\Users\vishal\Videos\Wpm-*.mp4`           | **No**  | PR-ready encodes for `test-report-pr-markdown`                   |

Do not commit videos or screenshots. Do not put app scenarios in harness repos.

## Workflow

### 1. Intake

From the user request, define:

- **Scenario slug** — kebab-case artifact folder name (e.g. `wpm-3370-questionnaire-export`)
- **Start URL** and **beats** — navigation, clicks, filters, downloads
- **Assertions** — URL fragment, grid/table count, visible text, no error banner
- **Proof-of-work** — video required? xlsx-viewer beat? screenshot for PR?

Confirm the dev stack is up (`curl` the entry URL). Do not start long-running servers unless the scenario needs them.

### 2. Author a scenario script

Copy [scripts/demo-template.ps1](scripts/demo-template.ps1) or an [scripts/examples/](scripts/examples/) script. Customize:

1. `$scenarioSlug`, `$outDir`, `$videoFile`, URLs, credentials (env vars preferred — see `WOVO_TEST_USER` in examples)
2. `playwright-cli open $url --browser=chromium`
3. **`playwright-cli resize 1920 1080`** — always, before recording
4. `playwright-cli video-start $videoFile` + `video-chapter` per beat
5. Interact via CLI (`fill`, `click`, `goto`, `snapshot` to disk — **do not load snapshots into chat**)
6. Assert with `playwright-cli eval` + [scripts/parse-playwright-result.ps1](scripts/parse-playwright-result.ps1)
7. `playwright-cli video-stop` → `close-all`
8. Exit `0` with `SCENARIO_OK` or throw on failure

For **exported Excel proof**: start xlsx-viewer harness (`npm start` in `~/repos/xlsx-viewer`), `tab-new` to `http://localhost:8765/viewer.html?file=...`, hold 2–3s, `video-chapter "Export preview"`.

### 3. Execute (subagent)

Parent agent plans; **shell subagent** runs Windows automation:

```bash
bash "$HOME/.agents/skills/browser-demo-test/scripts/run-windows-script.sh" <slug> <path-to.ps1>
```

Subagent returns: pass/fail, video path + size, snapshot summary (read YAML from disk, not tool output), console errors.

### 4. Report

Deliver:

- Pass/fail and what was verified
- `C:\Users\vishal\Videos\<slug>\*.webm` path and size (see [references/video-quality.md](references/video-quality.md) for size sanity checks)
- Screenshot/snapshot paths
- Blocking vs noise console errors

Optional: HandBrake encode + `test-report-pr-markdown` for PR attachment.

## Guardrails

- Prefer **Playwright CLI** over Browser MCP — keeps context small; snapshots live on disk.
- **Never** leave harness servers (xlsx-viewer, `http-server`) running after the scenario unless asked.
- Parse `playwright-cli eval` with `Get-PlaywrightResult` / `Out-String` — raw output is multiline markdown.
- Use `playwright-cli console error` — treat 404 on non-critical APIs as noise if UI passes.
- SSO/Keycloak: if `/next/login` redirects away, pause for user handoff or use stored session (`state-save` / `state-load`).

## Bundled scripts

| Script                                | Purpose                                                |
| ------------------------------------- | ------------------------------------------------------ |
| `scripts/check-prerequisites.sh`      | `curl` app URL + `playwright-cli --version` on Windows |
| `scripts/run-windows-script.sh`       | Copy `.ps1` to artifact dir and execute on Windows     |
| `scripts/demo-template.ps1`           | Template: 1080p video + chapter + assertion skeleton   |
| `scripts/examples/`                   | Ready-to-run product scenarios                         |
| `scripts/parse-playwright-result.ps1` | Extract `### Result` value from CLI output             |
