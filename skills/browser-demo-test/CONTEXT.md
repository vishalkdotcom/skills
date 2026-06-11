# Browser demo and test

## Language

**Scenario**: Folder under `wovo-browser-qa/scenarios/` with `run.ps1` (+ `flow.js` for Tier B).  
_Avoid_: test script in app repo

**Scenario repo**: `~/repos/wovo-browser-qa` — version-controlled Playwright CLI scenarios.  
_Avoid_: `wovo_frontend/scripts/browser-demo/`, vault ticket folders

**Tier B screencast**: `run-code` + `flow.js` using `page.screencast.showChapter` / `showOverlay` / `showActions`.  
_Avoid_: CLI-only video without AC overlays (Tier A) for PR-facing demos

**Scenario slug**: Kebab-case folder under `C:\Users\vishal\Videos\` (e.g. `wpm-3452-qa-signoff`).  
_Avoid_: test name, run id

**AC card**: `showChapter` beat displaying acceptance criterion text before interactions.  
_Avoid_: video-chapter (metadata-only; insufficient for PR reviewers)

**Harness**: Skill scripts (`run-windows-script.sh`) + local tools started only when needed (e.g. xlsx-viewer).  
_Avoid_: fixture, test server

**Scenario script**: `.ps1` + `.js` in git. **Artifact directory**: run output under `Videos/<slug>/`, never in git. **PR evidence**: flat `Wpm-*.mp4` for `test-report-pr-markdown`. **Vault evidence**: markdown in ticket `evidence/`, links to scenario repo.
