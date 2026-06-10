# WOVO local defaults

| Service                  | URL                          |
| ------------------------ | ---------------------------- |
| Next (+ legacy rewrites) | `http://localhost:3001/next` |
| Django API               | `http://localhost:8000`      |
| xlsx-viewer              | `http://localhost:8765`      |

**Dev login** (no Keycloak): `http://localhost:3001/next/login` — `vishal_admin` / `Wovo@123`.  
Keycloak configured → `state-save` after manual SSO or user handoff.

**Report URL pattern:**

```
http://localhost:3001/next/questionnaire/info?id=<uuid>&section=report&viewMode=table&groupBy=company&responseType=unique&responseSource=url&clientIds=<id>
```

Example: `scripts/examples/wovo-questionnaire-report.ps1`

**Export preview:** Download XLS → save under `Videos/<slug>/` → `npm start` in `~/repos/xlsx-viewer` → `tab-new` to `viewer.html?file=...` → stop server.
