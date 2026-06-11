# Reference

## What lives where

| Location                                     | In git? | Purpose                                  |
| -------------------------------------------- | ------- | ---------------------------------------- |
| `scripts/demo-template.ps1`                  | Yes     | Template for new scenarios               |
| `scripts/examples/*.ps1`                     | Yes     | Product-specific examples                |
| Feature repo `scripts/`                      | Yes     | Ticket-specific scenario scripts         |
| `~/repos/xlsx-viewer/scripts/smoke-test.ps1` | Yes     | Harness smoke test only                  |
| `C:\Users\vishal\Videos\<slug>\`             | No      | Run artifacts per execution              |
| `C:\Users\vishal\Videos\Wpm-*.mp4`           | No      | PR encodes for `test-report-pr-markdown` |

Do not commit videos. Do not put app scenarios in harness repos.

## Authoring a scenario

Copy `scripts/demo-template.ps1` or an example. Customize:

1. `$outDir = $PSScriptRoot` (set by `run-windows-script.sh`)
2. `open` → `resize 1920 1080` → `video-start … --size=1920x1080` → `video-chapter` per beat
3. Interact: `fill`, `click`, `goto`, `snapshot` / `screenshot` to `$outDir`
4. Assert: `playwright-cli eval` + `Get-PlaywrightResult` from `parse-playwright-result.ps1`
5. `video-stop` → `close-all` → print `SCENARIO_OK` or throw

Credentials: prefer env vars (`WOVO_TEST_USER`, `WOVO_TEST_PASSWORD` — see examples).

**Excel export beat:** `npm start` in `~/repos/xlsx-viewer`, then `tab-new` to `http://localhost:8765/viewer.html?file=...`. Stop server when done.

## Execute

Parent plans; shell subagent runs:

```bash
bash "$HOME/.agents/skills/browser-demo-test/scripts/run-windows-script.sh" <slug> <path-to.ps1>
```

Return: pass/fail, video path + size, snapshot paths (read YAML from disk), console errors.

## Report

- Pass/fail and what was verified
- Video path + size ([video-quality.md](references/video-quality.md) sanity checks)
- Blocking vs noise console errors (404s on non-critical APIs may be noise)

PR path: HandBrake encode → `test-report-pr-markdown`.

## Bundled scripts

| Script                        | Purpose                                 |
| ----------------------------- | --------------------------------------- |
| `check-prerequisites.sh`      | `curl` app + `playwright-cli --version` |
| `run-windows-script.sh`       | Copy `.ps1` to `Videos/<slug>/` and run |
| `demo-template.ps1`           | 1080p skeleton                          |
| `parse-playwright-result.ps1` | Parse `### Result` from eval output     |
| `verify-video-resolution.sh`  | `ffprobe` check encoded width×height    |
