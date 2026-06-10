# Browser demo and test

## Language

**Scenario**: PowerShell script that drives a browser flow with assertions and optional video.  
_Avoid_: test script, demo script

**Scenario slug**: Kebab-case folder under `C:\Users\vishal\Videos\` (e.g. `wpm-3370-questionnaire-export`).  
_Avoid_: test name, run id

**Template** / **Example**: Generic skeleton (`demo-template.ps1`) vs ready-to-run product script (`scripts/examples/`).  
_Avoid_: Using interchangeably

**Harness**: Local tool started only for steps that need it (e.g. xlsx-viewer).  
_Avoid_: fixture, test server

**Beat**: Recorded segment marked with `video-chapter`.  
_Avoid_: step (in video context)

**Scenario script**: `.ps1` in git. **Artifact directory**: run output under `Videos/<slug>/`, never in git. **PR evidence**: flat `Wpm-*.mp4` for `test-report-pr-markdown`.
