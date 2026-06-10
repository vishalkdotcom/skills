# Scenario examples

Ready-to-run scenarios for specific products or flows. Copy and customize when building a new scenario, or run as-is for smoke checks.

| Script                          | Product | What it verifies                                          |
| ------------------------------- | ------- | --------------------------------------------------------- |
| `wovo-questionnaire-report.ps1` | WOVO    | Dev login → questionnaire report table view → 1080p video |

Run from WSL:

```bash
SKILL="$HOME/.agents/skills/browser-demo-test"
bash "$SKILL/scripts/run-windows-script.sh" wovo-questionnaire-report \
  "$SKILL/scripts/examples/wovo-questionnaire-report.ps1"
```

Harness-only smoke tests (e.g. xlsx-viewer) stay in their own repos — not here.
