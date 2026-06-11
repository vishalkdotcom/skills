# Artifact storage

Scripts in `wovo-browser-qa`; videos never in git; plans/evidence in Obsidian vault.

| Layer | Where |
| --- | --- |
| Scenario (`run.ps1`, `flow.js`) | `~/repos/wovo-browser-qa/scenarios/<slug>/` |
| Harness | `browser-demo-test/scripts/` (skills repo) |
| QA plan (AC text) | Vault `qa-plan.md` |
| Sign-off log | Vault `evidence/YYYY-MM-DD-browser-qa.md` |
| Run artifacts | `C:\Users\vishal\Videos\<scenario-slug>\` |
| PR evidence | `C:\Users\vishal\Videos\Wpm-*.mp4` → `test-report-pr-markdown` |

Use `wpm-*` in the slug/filename when the run is PR proof.

**Promote to PR:** Tier B re-record → HandBrake to `Wpm-….mp4` → `test-report-pr-markdown`. Do not commit `.webm` or copy videos into vaults.

`Videos/` folders are local scratch — delete when done.
