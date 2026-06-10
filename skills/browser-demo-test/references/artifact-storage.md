# Artifact storage

Scripts in git; videos never in git.

| Layer           | Where                                                               |
| --------------- | ------------------------------------------------------------------- |
| Script (`.ps1`) | Skill `scripts/examples/`, feature repo, or ticket folder           |
| Run artifacts   | `C:\Users\vishal\Videos\<scenario-slug>\` via `$PSScriptRoot`       |
| PR evidence     | Flat `C:\Users\vishal\Videos\Wpm-*.mp4` → `test-report-pr-markdown` |

Use `wpm-*` in the slug/filename when the run is PR proof.

**Promote to PR:** finish run → HandBrake to `Wpm-3370-….mp4` → `test-report-pr-markdown`. Do not commit `.webm` or copy into vaults.

`Videos/` folders are local scratch — delete when done.
