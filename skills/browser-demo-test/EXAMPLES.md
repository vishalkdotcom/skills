# Examples

All scenarios live in `~/repos/wovo-browser-qa/scenarios/`.

| Scenario | Tier | Verifies |
| --- | --- | --- |
| `demo/` | B | Login page loads with AC card + pass badge |
| `wovo-questionnaire-report/` | B | Dev login → questionnaire report grid with AC overlays |
| `wpm-3452-qa-signoff/` | A → B | Full WPM-3452 revert QA (migrate to Tier B on re-record) |

```bash
SKILL="$HOME/.agents/skills/browser-demo-test"
REPO="$HOME/repos/wovo-browser-qa"

bash "$SKILL/scripts/run-windows-script.sh" wovo-questionnaire-report \
  "$REPO/scenarios/wovo-questionnaire-report/run.ps1"
```

Harness smoke tests (e.g. xlsx-viewer) live in their own repos.
