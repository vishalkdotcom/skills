# Tier B screencast authoring

PR-quality demo videos: acceptance criteria on screen, visible interactions, pass/fail badges.

## Pattern

Each scenario folder in `~/repos/wovo-browser-qa/scenarios/<slug>/`:

| File | Role |
|------|------|
| `run.ps1` | Set env vars, invoke `run-code`, verify video size, print `SCENARIO_OK` |
| `flow.js` | `async page => { … }` — screencast, navigation, assertions, overlays |

Vault `qa-plan.md` is the AC source of truth. Copy criterion text into `showChapter` descriptions.

## flow.js skeleton

**Constraints:** no trailing `;` on the function (run-code wraps as `(code)(page)`). No `process.env` in the VM. Use `__DEMO_VIDEO_PATH__` placeholder — `run.ps1` injects the absolute path into `flow.runtime.js` before `run-code` (playwright-cli cwd is often the Next repo, not the scenario dir).

```js
async (page) => {
  const videoPath = '__DEMO_VIDEO_PATH__';

  const showAc = async (title, description) => {
    await page.screencast.showChapter(title, { description, duration: 2500 });
  };

  await page.screencast.start({ path: videoPath, size: { width: 1920, height: 1080 } });
  await page.screencast.showActions({ duration: 800, position: 'top-right', cursor: 'pointer' });

  await showAc('AC1: …', 'Given …, when …, then …');
  // actions + assertions
  await page.screencast.showOverlay(`<div style="…">✓ Expected outcome</div>`, { duration: 2000 });

  await page.screencast.stop();
}
```

## run.ps1 skeleton

```powershell
$env:DEMO_VIDEO_PATH = Join-Path $PSScriptRoot 'demo.webm'
$loginUrl = $env:DEMO_LOGIN_URL ?? 'http://localhost:3001/next/login'
if (Test-Path $env:DEMO_VIDEO_PATH) { Remove-Item $env:DEMO_VIDEO_PATH -Force }
playwright-cli close-all 2>$null
playwright-cli open $loginUrl --browser=chromium
playwright-cli resize 1920 1080
$runtimeFlow = Join-Path $PSScriptRoot 'flow.runtime.js'
$videoPathJs = ($videoFile -replace '\\', '/')
(Get-Content $flowFile -Raw).Replace('__DEMO_VIDEO_PATH__', $videoPathJs) | Set-Content -Path $runtimeFlow -NoNewline
playwright-cli run-code --filename=$runtimeFlow
if ($LASTEXITCODE -ne 0) { throw "run-code failed" }
playwright-cli close-all 2>$null
# throw if video missing or < 100 KB
Write-Output 'SCENARIO_OK'
```

## Overlay APIs

| API | Use |
|-----|-----|
| `showChapter(title, { description, duration })` | Full-screen AC card before each beat |
| `showOverlay(html, { duration? })` | Pass/fail badge; sticky if no duration |
| `showActions({ duration, position, cursor })` | Highlight clicks + synthetic pointer |
| `pressSequentially(text, { delay: 50 })` | Readable typing |

Overlays are `pointer-events: none` — safe during clicks.

## Helpers

Copy patterns from `~/repos/wovo-browser-qa/lib/screencast-helpers.js` into `flow.js` (run-code is single-file).

## Exemplars

| Scenario | Tier |
|----------|------|
| `wovo-browser-qa/scenarios/demo/` | B — minimal login page |
| `wovo-browser-qa/scenarios/wovo-questionnaire-report/` | B — login + report grid |
| `wovo-browser-qa/scenarios/wpm-3452-qa-signoff/` | B — full AC sign-off (7 ACs + draft rule) |

## Probe then convert

1. Probe locators with CLI (`open`, `fill`, `click`, `eval`) on a failing path.
2. Move beats into `flow.js` with `showChapter` per AC.
3. Keep assertions in `flow.js` (`throw new Error`) — `run.ps1` checks video + `SCENARIO_OK`.

See `playwright-cli` skill → `references/video-recording.md` for API details.
