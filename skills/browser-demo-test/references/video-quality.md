# Video quality (1080p)

Default CLI recording uses the browser viewport size. Low resolution usually means the viewport was never resized.

## Standard fix (CLI chapters)

After `open`, before `video-start`:

```powershell
playwright-cli resize 1920 1080
playwright-cli video-start $videoFile
```

Use the same size for screenshots if capturing evidence:

```powershell
playwright-cli screenshot --filename="$outDir\frame.png"
```

## Polished demos (`run-code`)

For narrated demos with chapter cards and highlights, prefer a single `run-code` script with explicit screencast size:

```js
async (page) => {
  await page.setViewportSize({ width: 1920, height: 1080 });
  await page.screencast.start({
    path: "C:\\Users\\vishal\\Videos\\my-slug\\demo.webm",
    size: { width: 1920, height: 1080 },
  });
  // ... actions, page.screencast.showChapter(...), pauses ...
  await page.screencast.stop();
};
```

```bash
playwright-cli run-code --filename=./demo-recording.js
```

Workflow: probe the scenario once with CLI + snapshots on disk, then convert locators into `run-code` for the final recording.

## Post-encode for PRs

WebM from Playwright is fine for review. For GitHub PR attachments, encode with HandBrake (see `test-report-pr-markdown`):

```
handbrakecli.exe -Z "Very Fast 1080p30" -i demo.webm -o demo.mp4
```

## Check output

After `video-stop`, confirm file size is reasonable (sub‑100KB often means empty or tiny viewport). Target **≥ 1 MB** for a 30–60s 1080p clip.
