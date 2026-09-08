---
name: ship-herdr
description: "Herdr runtime for ship: apply the layout, start cursor-agent per unit, wait on the progress file."
disable-model-invocation: true
argument-hint: "ticket number"
---

# Ship — Herdr

Same units as `ship`. This skill owns **where** they run. Layout: [layout.json](layout.json) (labels and splits only — idle shells). Occupants: `--kind cursor` in those panes (`herdr agent --help`). Herdr has no Auto-review card, so start args after `--` are `--force --trust`.

Apply from **this skill’s directory**: `pwsh -File scripts/apply-layout.ps1 -Cwd <repo>`. `--Rebuild` is the script’s param. Pane labels come from `layout.json`. The orchestrator starts the app in the `dev` pane (below).

## This run

1. Resolve the ticket and repo cwd.
2. Read the progress file when it exists ([../ship/progress.md](../ship/progress.md)). Next unit from [../ship/SKILL.md](../ship/SKILL.md) Units table (`next` field, else implement).
3. Fresh ticket (no progress file): [../ship/claim-gate.md](../ship/claim-gate.md). Stop when that file says stop.
4. Run `apply-layout.ps1`. Keep the printed pane map.
5. **Dev server.** From the pane map, take the `dev` pane id.
   - If `herdr pane wait-output <dev> --regex "Ready in" --timeout 2000` already matches, reuse that process.
   - Else `herdr pane run <dev> portless` (cwd is the layout cwd — the target repo). Then `herdr pane wait-output <dev> --regex "Ready in" --timeout 120000`.
   - On wait failure: do not start occupants. Tail the pane, stop, leave it for the human.
   - Do **not** match `awesomeapps.localhost` as readiness — portless prints `-> https://awesomeapps.localhost` *before* it spawns Next.
6. **Implement / review / pr:** pane is an idle shell. `herdr agent start <name> --kind cursor --pane <id> -- --force --trust`. Session choice per unit: [Session policy](#session-policy).
7. **Validate:** `--kind cursor` occupant in the checks pane (browser QA), same start args. Progress file still comes from `ship-validate`.
8. Prompt from [prompt.md](prompt.md) with `--wait` (`herdr agent prompt --help`). First note the progress file's Log line count. `--wait` returning means the pane settled enough to read — never that the unit is done.
9. When `copy_agreed` is `no`, leave the pane `blocked` for the human.
10. **Unit complete — the progress file is the boundary.** Poll it every 30s until BOTH `unit_done` is this unit AND the Log has one new line since the prompt. File changed within 10 min → still working. `agent_prompt_stalled` → the prompt never landed; tail the pane, resubmit once. No file change for 10 min → audit: `herdr agent explain <name>` + `agent read --lines 40`. Explain shows working → keep polling, don't re-prompt. Finished but unstamped → re-prompt once: "stamp `unit_done` + your Log line, nothing else." Leave the pane `blocked` for the human on: pane blocked, 45 min with no file change and no working state, or a second missing stamp.
11. Loop 2–10 until `next: human-qa`. Then stop.

**Done when:** each finished unit has a progress file; this chat ran claim-gate on a fresh ticket, applied the layout, and started/waited on pane agents; the human still owns Guided QA and merge.

## Session policy

**Per-role rule (primary trigger):**

- **review** — always a new agent. `herdr pane run <pane> "/exit"`, wait for the shell prompt, then `agent start` again — or `/clear` for a same-process reset.
- **implement** — new on first run; a fix pass may reuse the same occupant.
- **validate** — new on first run; a re-validate may reuse with a delta prompt (`Re-run only:` scoped commands, see prompt.md).
- **pr** — always a fresh occupant.
- Do **not** new-session every step — a lean reused session is cheaper and already holds the diff in context.

**Budget override (circuit breaker):** reuse only while the occupant's context stays under ~50–60%. Before every reuse prompt, run `pwsh -NoProfile -File scripts/read-ctx.ps1 -Name <occupant>` (`tokens.ctx` from statusline.js → `report-metadata`, scrape fallback). If `pct >= 50`, rotate instead of prompting again.

**Bounded exception:** fix-pass reuse is safe when the session is well under budget *and* the findings to clear are quoted verbatim in the prompt (fully in context) — #102's 7-minute fix pass is the model. A fix pass that fails either condition rotates.

**Handoff artifact:** the `handoff` skill shape — a Markdown doc in the OS temp dir (never the workspace), tailored to what the next unit will do, with a suggested-skills section, and **references not copies** (ticket URL, progress file path, commits; specs and diffs are never duplicated). Its unique value over the progress file: it carries **why / dead ends / failed approaches** out of an occupant too full — or dead — to write the progress file itself. Production order: prompt the outgoing occupant to run its `handoff` skill (argument: what the next unit does) *before* `/exit`; if the occupant is already dead, the orchestrator reconstructs a minimal handoff from the progress file + Log + branch commits, or omits `Handoff:` — the progress file already covers intra-ticket state.

**Compaction:** `/summarize` (`/compact`) is an intra-unit safety valve only — never the handoff mechanism. At unit boundaries, fresh occupant + artifacts (progress file, handoff doc) beats compaction.

## Named URL

Occupants are told **only** the named portless URL. Never `localhost:<port>`, never `127.0.0.1:<port>`, never invent a port.

This loop's URL is `https://awesomeapps.localhost` (HTTPS, proxy on 443). Fill the occupant prompt's `App:` slot with that string. If a linked git worktree prefixes the hostname, fill `App:` with the URL portless actually printed (`-> …`), not the unprefixed default.

**Start command:** `herdr pane run <dev> portless` — zero-arg `portless` runs the package.json `dev` script through the proxy. Do not run `pnpm dev` in that pane; awesomeapps's `dev` is unwrapped `next dev`.

**Proxy rung (this machine):** default HTTPS on 443. Do **not** pass `-p 1355` or `--no-tls`. Do not `portless service install`. If the proxy is not running, `portless` auto-starts it; CA trust and OpenSSL are already done (doctor ticket).

**Fallback ladder** (other machines only — not this one):

| Rung | Proxy | Occupant URL |
| --- | --- | --- |
| default | HTTPS 443 | `https://<name>.localhost` |
| 443 noisy | `-p 1355` (keep TLS) | `https://<name>.localhost:1355` |
| TLS itself fails | `--no-tls` | `http://<name>.localhost` |

`curl.exe` without `--ssl-no-revoke` failing `CRYPT_E_NO_REVOCATION_CHECK (0x80092012)` is a schannel revocation quirk, **not** TLS-trust failure — do not step to `--no-tls` because of it. Occupants use the browser / playwright-cli, not bare curl.

**e2e:** `CI=true PORT=3002` against a production server (`pnpm start`). Never start portless under CI. Browser QA (ship-validate step 2) uses `App:` against the already-running named URL.
