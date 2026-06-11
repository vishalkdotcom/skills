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

```js
async (page) => {
  const videoPath = process.env.DEMO_VIDEO_PATH;

  const showAc = async (title, description) => {
    await page.screencast.showChapter(title, { description, duration: 2500 });
  };

  await page.screencast.start({ path: videoPath, size: { width: 1920, height: 1080 } });
  await page.screencast.showActions({ duration: 800, position: 'top-right', cursor: 'pointer' });

  await showAc('AC1: …', 'Given …, when …, then …');
  // actions + assertions
  await page.screencast.showOverlay(`<div style="…">✓ Expected outcome</div>`, { duration: 2000 });

  await page.screencast.stop();
};
```

## run.ps1 skeleton

```powershell
$env:DEMO_VIDEO_PATH = Join-Path $PSScriptRoot 'demo.webm'
playwright-cli close-all 2>$null
playwright-cli run-code --filename=(Join-Path $PSScriptRoot 'flow.js')
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
| `wovo-browser-qa/scenarios/wpm-3452-qa-signoff/` | A — migrate to B when re-recording |

## Probe then convert

1. Probe locators with CLI (`open`, `fill`, `click`, `eval`) on a failing path.
2. Move beats into `flow.js` with `showChapter` per AC.
3. Keep assertions in `flow.js` (`throw new Error`) — `run.ps1` checks video + `SCENARIO_OK`.

See `playwright-cli` skill → `references/video-recording.md` for API details.
