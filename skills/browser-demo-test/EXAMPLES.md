# Examples

| Script                                           | Product | Verifies                                             |
| ------------------------------------------------ | ------- | ---------------------------------------------------- |
| `scripts/examples/wovo-questionnaire-report.ps1` | WOVO    | Dev login → questionnaire report table → 1080p video |

```bash
SKILL="$HOME/.agents/skills/browser-demo-test"
bash "$SKILL/scripts/run-windows-script.sh" wovo-questionnaire-report \
  "$SKILL/scripts/examples/wovo-questionnaire-report.ps1"
```

Harness smoke tests (e.g. xlsx-viewer) live in their own repos.
