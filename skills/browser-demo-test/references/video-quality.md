# Video quality

Before `video-start`:

```powershell
playwright-cli resize 1920 1080
playwright-cli video-start $videoFile
```

Sub-100KB after a 30–60s clip usually means viewport was not resized. Target **≥ 1 MB** for 1080p.

**Polished demos:** `run-code` with `page.screencast` — see `playwright-cli` skill `references/video-recording.md`. Probe with CLI first, then convert.

**PR encode:** `handbrakecli.exe -Z "Very Fast 1080p30" -i demo.webm -o Wpm-….mp4`
