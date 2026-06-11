# Video quality

Before `video-start`:

```powershell
playwright-cli resize 1920 1080
playwright-cli video-start $videoFile --size=1920x1080
```

`resize` sets the browser viewport; **`--size` sets the encoded video frame** (defaults to ~800×450 if omitted — not 1080p).

`run-windows-script.sh` copies `wovo_frontend/next/.playwright/cli.config.json` and sets `PLAYWRIGHT_MCP_CONFIG` for viewport defaults.

Sub-100KB after a 30–60s clip usually means `--size` was omitted. Target **≥ 1 MB** for 1080p.

**Verify after recording:**

```bash
bash "$HOME/.agents/skills/browser-demo-test/scripts/verify-video-resolution.sh" \
  /mnt/c/Users/vishal/Videos/<slug>/demo.webm
```

**Polished demos:** `run-code` with `page.screencast` — see `playwright-cli` skill `references/video-recording.md`. Probe with CLI first, then convert.

**PR encode:** `handbrakecli.exe -Z "Very Fast 1080p30" -i demo.webm -o Wpm-….mp4`
