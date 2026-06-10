# Browser demo and test

Agent workflow for scripted localhost browser verification and 1080p demo recordings via Windows Playwright CLI.

## Language

**Scenario**:
A PowerShell script that drives the browser through a defined flow, asserts UI state, and optionally records video.
_Avoid_: Test script (when you mean an app walkthrough, not a unit test), demo script

**Scenario slug**:
Kebab-case name for a scenario; becomes the folder under the Windows artifact root (e.g. `wpm-3370-questionnaire-export`).
_Avoid_: Test name, run id

**Template**:
Generic `.ps1` skeleton agents copy and customize when authoring a new scenario (`scripts/demo-template.ps1`).
_Avoid_: Example, sample

**Example**:
A ready-to-run scenario for a specific product or flow (`scripts/examples/`). WOVO-specific examples live here, not in harness repos.
_Avoid_: Template, smoke test

**Harness**:
A standalone local tool a scenario starts only for the steps that need it (e.g. xlsx-viewer on port 8765 for export preview).
_Avoid_: Fixture, helper repo, test server

**Beat**:
One narrated segment inside a recorded scenario, marked with `video-chapter` (e.g. login beat, export-preview beat).
_Avoid_: Step, section (in video context)

**Scenario script**:
The `.ps1` source that defines a scenario — safe to commit in git (skill examples or feature repo).
_Avoid_: Storing this next to video files as if it were an artifact

**Artifact directory**:
Windows folder `C:\Users\vishal\Videos\<scenario-slug>\` holding video, snapshots, and screenshots from one run. Never committed to git.
_Avoid_: Output dir, results folder, repo path

**PR evidence**:
Encoded `.mp4` and images promoted for a GitHub PR — flat files under `C:\Users\vishal\Videos\` with a `wpm-*` prefix, discovered by `test-report-pr-markdown`.
_Avoid_: Checking PR videos into the repo

**Proof-of-work**:
Artifacts (especially `.webm` video and screenshots) that show a scenario completed successfully.
_Avoid_: Evidence bundle, deliverables
