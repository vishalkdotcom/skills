# WOVO local defaults

Use when the scenario targets the WOVO Next + legacy stack on the developer machine.

## URLs and ports

| Service                 | URL                          |
| ----------------------- | ---------------------------- |
| Next app (base)         | `http://localhost:3001/next` |
| Legacy CRA (standalone) | `http://localhost:3000`      |
| Django API              | `http://localhost:8000`      |
| xlsx-viewer harness     | `http://localhost:8765`      |

Next dev serves legacy pages via rewrites on **3001** — prefer that for integrated flows.

## Dev login (no Keycloak)

When `.env` has no Keycloak values:

| Field     | Default                            |
| --------- | ---------------------------------- |
| Login URL | `http://localhost:3001/next/login` |
| Username  | `vishal_admin`                     |
| Password  | `Wovo@123`                         |

Selectors:

```powershell
playwright-cli fill 'input[name="username"]' $username
playwright-cli fill 'input[name="password"]' $password
playwright-cli click 'button[type="submit"]'
```

If Keycloak is configured, the dev login form is skipped — use `state-save` after manual SSO once, or ask the user to complete login.

## Example scenario

Questionnaire report table (parameterize `id`, filters in query string):

```
http://localhost:3001/next/questionnaire/info?id=<uuid>&section=report&viewMode=table&groupBy=company&responseType=unique&responseSource=url&clientIds=<id>
```

Reference example: `~/repos/skills/skills/browser-demo-test/scripts/examples/wovo-questionnaire-report.ps1`

## Download → xlsx-viewer

1. Click **Download** → **This page (XLS)** on the report toolbar.
2. Save/intercept the `.xlsx` to a known path under `Videos/<slug>/`.
3. Start xlsx-viewer only for the preview beat:

```bash
cd ~/repos/xlsx-viewer && npm start   # port 8765; stop when done
```

```powershell
playwright-cli tab-new "http://localhost:8765/viewer.html?file=/samples/demo.xlsx"
# Or ?file=<url-encoded-http-url-to-saved-xlsx> if served from viewer origin
```

## Related skills

- `playwright-cli` — full CLI command reference
- `test-report-pr-markdown` — encode video + PR markdown for WPM tickets
