# Video quality

## Tier B (default)

`flow.js` must call:

```js
await page.screencast.start({ path: videoPath, size: { width: 1920, height: 1080 } });
await page.screencast.showActions({ duration: 800, position: 'top-right', cursor: 'pointer' });
```

`run.ps1` sets `DEMO_VIDEO_PATH` to an absolute path under `Videos/<slug>/`.

## Tier A (legacy)

```powershell
playwright-cli resize 1920 1080
playwright-cli video-start $videoFile --size=1920x1080
```

## Verify

```bash
bash "$HOME/.agents/skills/browser-demo-test/scripts/verify-video-resolution.sh" \
  /mnt/c/Users/vishal/Videos/<slug>/demo.webm
```

Sub-100KB after a 30–60s clip usually means missing `size: { width: 1920, height: 1080 }`. Target **≥ 1 MB** for 1080p.

`run-windows-script.sh` copies `wovo_frontend/next/.playwright/cli.config.json` when `WOVO_NEXT_REPO` is set.

**PR encode:** `handbrakecli.exe -Z "Very Fast 1080p30" -i demo.webm -o Wpm-….mp4`
