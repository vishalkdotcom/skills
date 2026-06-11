# Reference

## What lives where

| Location | In git? | Purpose |
| --- | --- | --- |
| `~/repos/wovo-browser-qa/scenarios/<slug>/` | Yes | Ticket scenarios (`run.ps1` + `flow.js`) |
| `~/repos/wovo-browser-qa/lib/` | Yes | Shared screencast helpers |
| `browser-demo-test/scripts/` | Yes (skills repo) | Harness only — run, check, verify |
| Obsidian vault `qa-plan.md` | Yes (vault) | AC source of truth |
| Obsidian vault `evidence/` | Yes (vault) | Pass/fail log + artifact paths |
| `C:\Users\vishal\Videos\<slug>\` | No | Run output per execution |
| `C:\Users\vishal\Videos\Wpm-*.mp4` | No | PR encodes for `test-report-pr-markdown` |

Do not commit videos. Do not put scenario scripts in `wovo_frontend/next/` or the vault.

## Authoring a Tier B scenario

1. Copy `wovo-browser-qa/scenarios/demo/` to `scenarios/<slug>/`.
2. Map each AC from vault `qa-plan.md` to `showChapter` in `flow.js`.
3. Set env in `run.ps1` (`DEMO_VIDEO_PATH`, URLs, credentials).
4. Assert in `flow.js`; `run.ps1` verifies video file + prints `SCENARIO_OK`.

See [tier-b-screencast.md](references/tier-b-screencast.md).

**Legacy Tier A** (CLI-only `.ps1` without `flow.js`): still runs, but migrate to Tier B before PR re-records.

## Execute

```bash
bash "$HOME/.agents/skills/browser-demo-test/scripts/run-windows-script.sh" <slug> <path-to/run.ps1>
```

`run-windows-script.sh` copies `run.ps1`, sibling `*.js`, `lib/`, and `parse-playwright-result.ps1` into `Videos/<slug>/`.

Return: pass/fail, video path + size, snapshot paths, console errors.

## Report

- Pass/fail and what was verified
- Video path + size ([video-quality.md](references/video-quality.md))
- Vault evidence note with script path + run command
- PR path: HandBrake encode → `test-report-pr-markdown`

## Bundled harness scripts

| Script | Purpose |
| --- | --- |
| `check-prerequisites.sh` | `curl` app + `playwright-cli --version` |
| `run-windows-script.sh` | Copy scenario + run via Windows `pwsh` |
| `parse-playwright-result.ps1` | Parse `### Result` from eval output (Tier A) |
| `verify-video-resolution.sh` | `ffprobe` 1080p check |
