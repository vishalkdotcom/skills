# Artifact storage

Scenario **scripts** are version-controlled; **videos and screenshots are not**.

## Three layers

| Layer | What | Where |
| ----- | ---- | ----- |
| **Script** | `.ps1` scenario source | Git: skill `scripts/examples/`, feature repo, or ticket folder |
| **Run artifacts** | `.webm`, snapshots, screenshots from one execution | `C:\Users\vishal\Videos\<scenario-slug>\` (never committed) |
| **PR evidence** | Encoded `.mp4` + images attached to a GitHub PR | Flat `C:\Users\vishal\Videos\` with `wpm-*` in the filename; see `test-report-pr-markdown` |

`run-windows-script.sh` copies the script into the run artifact folder as `run.ps1`. The script writes all outputs beside itself (`$PSScriptRoot`), so each slug gets an isolated directory under `Videos/`.

## Slug naming

| Use case | Slug example |
| -------- | ------------ |
| Reference / smoke | `wovo-questionnaire-report` |
| Ticket work | `wpm-3370-questionnaire-export` |

Use the ticket key in the slug when the run is proof for a WPM PR — makes handoff to `test-report-pr-markdown` obvious.

## Promoting a run to a PR

1. Finish the scenario run under `Videos\<slug>\`.
2. Encode for GitHub (HandBrake): save as `C:\Users\vishal\Videos\Wpm-3370-questionnaire-export-demo.mp4` (flat, `wpm-*` prefix).
3. Run `test-report-pr-markdown` to build PR markdown and upload links.

Do not copy `.webm` into git repos or Obsidian vaults. Link to the Windows path in chat or PR text; upload via GitHub compare/PR attachment UI.

## Cleanup

Run folders under `Videos/` are local scratch space. Delete old slugs when no longer needed — nothing in git depends on them.
