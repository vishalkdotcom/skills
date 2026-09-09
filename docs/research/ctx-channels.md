# Prototype: Token-tracking instrumentation — ctx% channels (ticket 12)

Decision ticket: [Token-tracking instrumentation: prototype ctx% channels and decide](https://github.com/vishalkdotcom/skills/issues/12). Source of truth: `docs/research/ship-herdr-loop-102-validated-advice.md` §9 token-tracking paragraph. Serves [Session policy: per-role reuse, rotation threshold, handoff artifact](https://github.com/vishalkdotcom/skills/issues/7) — this ticket only decides **how** ctx% is read, not the ~50–60% threshold.

## Decision in one line

Adopt **Herdr pane metadata** as the orchestrator source of truth: `~/.cursor/statusline.js` detached-pushes `herdr pane report-metadata <pane> --source cursor-statusline --token ctx=<pct> --ttl-ms 300000`; the orchestrator reads `tokens.ctx` from `herdr agent get` (fallback `pane get`). Keep **TUI scrape** (`herdr agent read --source visible`) as the fallback when the token is missing. Do not adopt a JSONL file as the read path. Do not use `stop` / `afterAgentResponse` hook token totals.

## Evidence from live tests (2026-09-08, herdr `0.9.0-preview.2026-09-08`)

All of this ran against real Herdr panes and real Cursor CLI sessions on this machine.

### (a) Scrape — leftover #102 occupants, no helper installed yet

`herdr agent get` exposes **no** token fields until something pushes metadata. Visible TUI (and `--source recent`) both contain the statusline.js line:

```
Cursor Grok 4.6 Extra High  ctx ▓▓▓░░░░░░░ 26% · 66.8k/256k
```

`scripts/read-ctx.ps1` against those occupants:

| name | pane | session_id | pct | source |
|---|---|---|---|---|
| pr | w7:p4 | `9ecab8d9-34f0-45c8-8969-dd9798a82192` | 26 | scrape |
| review | w7:p5 | `c323fa8e-49dc-477c-90b3-52bd9132a264` | 26 | scrape |
| checks | w7:p6 | `0b646bcf-3d73-4461-8f60-2e75eef496fe` | 33 | scrape |

`--format text` still keeps the `▓░` bar. Parse the **last** `ctx…N%` match so conversation text cannot steal the number.

### Metadata write/read/TTL (idle pane `w5:p5`)

- PowerShell gotcha: `herdr pane report-metadata --source … <pane>` treats the pane id as an option. **Pane id first:** `herdr pane report-metadata w5:p5 --source ctx-proto --token ctx=26`.
- `herdr pane get w5:p5` then returns `"tokens":{"ctx":"26"}`. Help text says "display-only"; that means it is not agent lifecycle state — the CLI **does** round-trip it.
- `--ttl-ms 2500`: token present immediately, **gone** from `pane get` ~3s later. Freshness is built in.
- Idle-pane env (via `herdr pane run`): `HERDR_PANE_ID=w5:p5`, `HERDR_ENV=1`, `HERDR_BIN_PATH` set to the standalone herdr.exe. Same env the Cursor `sessionStart` hook (`~/.cursor/herdr-agent-state.ps1`) already uses for `report-agent-session`.

### (b) statusline.js → metadata — throwaway occupant `ctxproto`

Installed `skills/ship-herdr/scripts/statusline-ctx-log.js` as `~/.cursor/statusline-ctx-log.js` and required it from `~/.cursor/statusline.js`. Then `herdr agent start ctxproto --kind cursor --pane w5:p4 -- --force --trust` and a one-word prompt.

After the prompt, `herdr agent get ctxproto` included `"tokens":{"ctx":"7"}`. `read-ctx.ps1 -Name ctxproto` returned `source=metadata`, `pct=7`. Visible TUI: `ctx ▓░░░░░░░░░ 7% · 18.7k/256k`.

JSONL (diagnostic, `CURSOR_CTX_JSONL` was not yet gated) at `%TEMP%/cursor-ctx-log/db0dc9ca-30e0-43e1-9119-737a23223424.jsonl`:

```json
{"ts":1788883331722,"session_id":"db0dc9ca-30e0-43e1-9119-737a23223424","pane_id":"w5:p4","herdr_env":"1","pct":7,"total_input_tokens":18688,"context_window_size":256000}
```

That `session_id` **equals** `agent_session.value`. `pane_id` **equals** `HERDR_PANE_ID`. So the statusline child process inherits the pane env, and Cursor's statusline payload `session_id` is the same id Herdr's sessionStart hook already reports.

Mock pipe through the same `statusline.js` (this shell, env injected) rendered unchanged and pushed `tokens.ctx=17` onto `w5:p5`.

### Rejected channels

- **JSONL as orchestrator read.** Works, and `session_id` joins cleanly, but it is a second store. `agent get` / `pane get` already return `tokens.ctx`. Unbounded appends every statusline tick (~300ms). Keep the write **opt-in** (`CURSOR_CTX_JSONL=1`) for debugging; do not read it in ship-herdr.
- **`stop` / `afterAgentResponse` hook `input_tokens`.** Advice doc: cumulative across calls; statusline `total_input_tokens` is the fill number. Not prototyped; not adopted.
- **Calling `herdr` synchronously from statusline.js.** Statusline `timeoutMs` default 2000; in-flight process is killed on the next update. Detached `spawn` + `unref` is the shape that survived the live occupant (same idea as the existing sessionStart hook, without blocking stdout).

## Proposed machine setup (one-time, like the Herdr Cursor hook)

1. Copy `skills/ship-herdr/scripts/statusline-ctx-log.js` → `~/.cursor/statusline-ctx-log.js`.
2. In `~/.cursor/statusline.js`, immediately after `JSON.parse`, add:

```javascript
try {
  require("./statusline-ctx-log.js").report(p);
} catch {
  /* ctx helper optional */
}
```

This machine already has that splice (backup: `~/.cursor/statusline.js.bak-ctx-proto`). Revert by restoring the backup and deleting `statusline-ctx-log.js`. Helper is a no-op unless `HERDR_ENV=1` and `HERDR_PANE_ID` are set, so non-Herdr CLI sessions do not call herdr.

## Proposed orchestrator read

Before every **reuse** prompt (implement fix-pass / validate re-run only — review/PR never reuse):

```powershell
pwsh -NoProfile -File scripts/read-ctx.ps1 -Name <occupant>
```

JSON: `{name, pane_id, session_id, pct, source}` where `source` is `metadata` | `scrape` | `unknown`.

- `pct >= 50` → rotate (bottom of the session-policy ~50–60% band). Threshold itself is owned by [Session policy: per-role reuse, rotation threshold, handoff artifact](https://github.com/vishalkdotcom/skills/issues/7).
- `source: unknown` / exit 2 → treat as under budget and reuse. Do not rotate on a read failure.
- Prefer `metadata`; scrape is for occupants whose statusline has not fired yet (fresh start) or whose TTL (5 min) expired.

Replace the "quick / robust" sentence in the session-policy `## Session policy` budget paragraph with:

> **Budget override (circuit breaker):** reuse only while the occupant's context stays under ~50–60%. Before every reuse prompt, run `pwsh -NoProfile -File scripts/read-ctx.ps1 -Name <occupant>` (`tokens.ctx` from statusline.js → `report-metadata`, scrape fallback). If `pct >= 50`, rotate instead of prompting again.

## Prototype assets (this branch)

- [`skills/ship-herdr/scripts/read-ctx.ps1`](../../skills/ship-herdr/scripts/read-ctx.ps1)
- [`skills/ship-herdr/scripts/statusline-ctx-log.js`](../../skills/ship-herdr/scripts/statusline-ctx-log.js)

Throwaway occupant `ctxproto` on pane `w5:p4` was prompted once (`pong`) and had already left the pane (`agent_not_running`) when `/exit` was attempted.

## Notes for [Assemble the ship-herdr loop upgrade spec](https://github.com/vishalkdotcom/skills/issues/11)

- File-level: add the two scripts under `skills/ship-herdr/scripts/`; splice statusline.js as machine setup, not a repo file (`~/.cursor/` is user-global, same class as `herdr-agent-state.ps1`).
- Done-when for this item: a reused implement/validate occupant that has crossed 50% is rotated rather than prompted; the orchestrator never invents `localhost`-style guesses for ctx% — it only reads `read-ctx.ps1`.
- Do not re-litigate Portless, session-role matrix, or the 50–60% band.
- PowerShell: pane id **before** `--source` on `report-metadata`. The helper already does this.

## Sources

- Advice doc `docs/research/ship-herdr-loop-102-validated-advice.md` §9 (doc:83).
- [Session policy](https://github.com/vishalkdotcom/skills/issues/7) resolution + `docs/research/session-policy.md` on `research/session-policy`.
- Live herdr `0.9.0-preview.2026-09-08`: `agent get/read/start/prompt`, `pane get/run/report-metadata/process-info`.
- Cursor CLI statusline spec (`~/.cursor/skills-cursor/statusline/SKILL.md`): payload `session_id`, `context_window.used_percentage` / `total_input_tokens` / `context_window_size`; command spawned per update; `timeoutMs` 2000; kill on next update.
- `~/.cursor/statusline.js` (renders-only until this prototype), `~/.cursor/statusline.cmd`, `~/.cursor/cli-config.json` `statusLine.command`.
- `~/.cursor/herdr-agent-state.ps1` (sessionStart → `report-agent-session` using `HERDR_PANE_ID`).
