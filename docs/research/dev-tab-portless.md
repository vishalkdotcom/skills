# Research: Dev tab layout + portless named-URL doctrine (ticket #9)

Decision ticket: `vishalkdotcom/skills#9`. Source of truth: `awesomeapps/docs/agent/ship-herdr-loop-102-validated-advice.md` ("advice doc", cited by line), final advice item 7. Prerequisite: [Run portless doctor and prove https://awesomeapps.localhost](https://github.com/vishalkdotcom/skills/issues/10) (closed) — this machine's proxy rung. Slot set: [Occupant prompt slots (Pass/Clear/Session)](https://github.com/vishalkdotcom/skills/issues/6) (`docs/research/prompt-slots.md` on `research/prompt-slots`) plus [Session policy](https://github.com/vishalkdotcom/skills/issues/7)'s `Handoff:` seventh line.

## Decision in one line

Third `dev` tab (one idle `dev` pane); after `apply-layout.ps1` start `portless` in that pane (not `pnpm dev`) and wait on the single-line Next.js `Ready in`; occupants get only `https://awesomeapps.localhost` via an `App:` prompt slot; no `-p 1355` / `--no-tls` on this machine; e2e stays `CI=true PORT=3002` on a production server.

## Proposed `skills/ship-herdr/layout.json` (full file)

`apply-layout.ps1` iterates `layout.tabs` and creates idle labelled shells only (`skills/ship-herdr/scripts/apply-layout.ps1:58-106`). A third tab needs no script change. JSON has no comments — doctrine does not live here.

```json
{
  "workspace_label": "ship",
  "tabs": [
    {
      "label": "agents",
      "panes": [
        { "label": "implement" },
        { "label": "review", "direction": "right" }
      ]
    },
    {
      "label": "checks",
      "panes": [{ "label": "checks" }]
    },
    {
      "label": "dev",
      "panes": [{ "label": "dev" }]
    }
  ]
}
```

Tab order is agents / checks / **dev** (advice: "add a third `dev` tab", advice doc:76). One pane, labelled `dev`, matching the existing `checks`/`checks` pattern. The printed pane map then has a `dev` key for `pane run`.

## Proposed orchestrator steps for `skills/ship-herdr/SKILL.md`

### Kill this sentence (current line 12)

> Pane labels come from `layout.json`. Server must already be running.

Replace with:

> Pane labels come from `layout.json`. The orchestrator starts the app in the `dev` pane (below).

### Insert after current step 4 (`Run apply-layout.ps1`. Keep the printed pane map.)

Numbering will be merged with [Completion boundary](https://github.com/vishalkdotcom/skills/issues/8) and [Circuit breaker](https://github.com/vishalkdotcom/skills/issues/4) at spec-assembly — those tickets also rewrite later steps. Insert this block immediately after apply-layout, before any `agent start`:

```markdown
5. **Dev server.** From the pane map, take the `dev` pane id.
   - If `herdr pane wait-output <dev> --regex "Ready in" --timeout 2000` already matches, reuse that process.
   - Else `herdr pane run <dev> portless` (cwd is the layout cwd — the target repo). Then `herdr pane wait-output <dev> --regex "Ready in" --timeout 120000`.
   - On wait failure: do not start occupants. Tail the pane, stop, leave it for the human.
   - Do **not** match `awesomeapps.localhost` as readiness — portless prints `-> https://awesomeapps.localhost` *before* it spawns Next.
```

### New section, after "This run" (peer of the Session-policy section from ticket #7)

```markdown
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
```

## Proposed `App:` slot for `skills/ship-herdr/prompt.md`

One-line append after ticket #7's `Handoff:` (eighth template line). Full template as it should land after #6 + #7 + this ticket:

```
Follow <unit-skill-path>.

Ticket: <url>
Progress file: <path>
Pass: first | fix <n> | review <n>
Clear: none | Findings
Session: new | reuse
Handoff: none | <path>
App: https://awesomeapps.localhost
```

Orchestrator always writes the actual named URL on `App:`. Layout.json cannot hold this (no comments). Unit skills do not currently name a URL, so the prompt is the occupant-facing doctrine; SKILL.md is the orchestrator-facing doctrine.

## Rationale

1. **Third `dev` tab, one idle `dev` pane, no `apply-layout.ps1` change.** Advice item 7 (advice doc:76) plus the validated Herdr claim that `layout.json` is labels+splits only and the script never spawns processes (advice doc:29; `apply-layout.ps1:1-2,58-106`). The script's `foreach ($tabSpec in $layout.tabs)` already creates any missing tab with `--cwd $Cwd` (`apply-layout.ps1:58,76`). One pane labelled `dev` gives `pane run` a stable map key, matching `checks`.

2. **Start with `portless`, not `pnpm dev`.** Advice item 7's example command is `herdr pane run <dev> "pnpm dev"` (advice doc:76). That is insufficient for the named URL: awesomeapps `package.json` `"dev"` is `"next dev"` with no portless wrap (`C:\vishal\repos\awesomeapps\package.json:7`), and this effort cannot change awesomeapps (map Notes). Zero-arg `portless` is the in-skills command: it infers the name from `package.json` `"name"` (`portless` 0.15.6 `inferProjectName` / `findPackageJsonName` in `dist/cli.js:1287-1324`), runs the `dev` script through the proxy (`handleDefaultSingle`, `dist/cli.js:7027-7062`), and on this machine printed `https://awesomeapps.localhost` with `PORT=4126` ([Run portless doctor](https://github.com/vishalkdotcom/skills/issues/10)). `herdr pane run` takes `<PANE_ID> <COMMAND>...` (`herdr pane run --help`); `portless` is one argv.

3. **Readiness regex is `Ready in`, timeout 120s; do not match the named URL.** `pane wait-output --regex` uses Rust regex and matches **one line at a time** (`herdr pane wait-output --help`; https://herdr.dev/docs/cli-reference/; advice doc:35). Portless prints `-> ${finalUrl}` *before* `spawnCommand` (`dist/cli.js:5174-5325`), so matching `awesomeapps.localhost` would fire while Next is still starting. Next.js 16 prints a dedicated ready line `✓ Ready in …ms` ([Next.js 16 blog/migration output](https://nextjs.org/blog/next-16); observed shape `✓ Ready in 320ms`). The checkmark is optional in the pattern; `Ready in` is the stable single-line token. `--timeout 120000` matches awesomeapps `playwright.config.ts` `webServer.timeout` (120_000). Omit `--timeout` and Herdr waits forever (CLI reference) — a hung Next would stall the loop. Reuse-if-already-ready avoids double-`pane run` on a leftover process: `apply-layout.ps1` reuses existing tabs/panes and does not kill processes (`apply-layout.ps1:80-84`).

4. **This machine: HTTPS 443, URL `https://awesomeapps.localhost`, no fallback.** Doctor ticket answer: proxy on 443, CA in current-user Root, working URL `https://awesomeapps.localhost` → `localhost:4126`, 0 failures. Explicit: do not fall back to `-p 1355` or `--no-tls`. `formatUrl` omits the port on 443/80 and includes it otherwise (`portless` `dist/chunk-SLEZT6EJ.js:73-76`): so `-p 1355` would have been `https://awesomeapps.localhost:1355`, and `--no-tls` `http://awesomeapps.localhost`. Occupants must be told the URL that matches the rung; this rung has no port suffix. The curl `CRYPT_E_NO_REVOCATION_CHECK` quirk is recorded on the doctor ticket as **not** a TLS failure.

5. **`App:` is the occupant-facing doctrine; SKILL.md is the orchestrator-facing doctrine.** Ticket 6 dropped Repo/Claim-gate/Tool-calls because skill files already own them (`docs/research/prompt-slots.md`). No unit skill currently names a URL (`skills/ship-validate/SKILL.md:20` says "the running app"). Without an `App:` line, occupants invent `localhost:3000` — the #102 failure mode item 7 exists to kill (advice doc:76). Layout.json cannot hold comments. Ticket 7 already set the precedent of a one-line append (`Handoff:`); `App:` is the eighth slot, always filled with the actual named URL.

6. **Worktree prefix is real but not this loop's default checkout.** `applyWorktreePrefix` prepends `<branch>.` only for a *linked* worktree (`dist/cli.js:1352-1404`); `worktreeCount <= 1` returns null, so a feature branch in the main checkout stays `awesomeapps.localhost`. `--name` does **not** strip the worktree prefix (`dist/cli.js:5418`). If someone ships from a linked worktree, the orchestrator fills `App:` from the printed `->` URL rather than the unprefixed default.

7. **e2e stays `CI=true PORT=3002` on production, out of band from the named URL.** Advice item 7 (advice doc:76) plus the bonus fact that portless is hostile to `CI=1` (advice doc:57). In 0.15.6 the hard exit is specifically `needsSudo && !isInteractive` where `isInteractive = stdin TTY && !CI` (`dist/cli.js:4997-5011`); on Windows `needsSudo` is false, so the Windows path will not itself refuse CI — the policy still holds because (a) Playwright's CI branch already runs `pnpm run start` not `dev` (`awesomeapps/playwright.config.ts:21-22`), (b) portless assigns `PORT` in 4000–4999, which would fight a fixed e2e port, (c) the advice forbids mixing them. **Gap (awesomeapps, out of this repo):** `playwright.config.ts` defaults `PORT` to `"3000"` and `baseURL` to `http://127.0.0.1:${port}` (`playwright.config.ts:3-4`). The validate occupant / CI command must pass `CI=true PORT=3002`; changing the default is not a skills-repo change. Browser QA (ship-validate step 2, playwright-cli) uses `App:` against the already-running named URL — that is not the Playwright `webServer` path.

8. **`portless service install` / Task Scheduler as SYSTEM is not required.** Doctor ticket: unelevated `portless proxy start` plus `certutil -addstore -user Root` was enough; `service install` was not used. Orchestrator does not install a service.

## Notes for the implementing / spec-assembly ticket

- Merge this SKILL.md insert with [Completion boundary](https://github.com/vishalkdotcom/skills/issues/8) (step 9 rewrite) and [Circuit breaker](https://github.com/vishalkdotcom/skills/issues/4) (new breaker step). All three patch `skills/ship-herdr/SKILL.md`. Apply-layout stays step 4; this start/wait block is the next step; breaker/completion keep their relative homes later in the loop.
- Compose `prompt.md` as #6 template + #7 `Handoff:` + this `App:` line. Do not land the currently committed 14-line Repo/Claim-gate/Tool-calls template.
- awesomeapps `playwright.config.ts` still defaults PORT 3000 — call that out in the spec as an occupant env requirement (`CI=true PORT=3002`), not a skills-repo patch.
- Proxy + CA are already live on this machine; the orchestrator just runs `portless` in the pane. First-time OpenSSL/CA was human work on the doctor ticket, not a ship-herdr step.
- `herdr pane run` / `wait-output` take the pane **id** from the apply-layout JSON map, not the label string.

## Sources

- Advice doc `awesomeapps/docs/agent/ship-herdr-loop-102-validated-advice.md`: item 7 (doc:76); Herdr wait-output one-line regex (doc:35); layout idle-shells (doc:29); portless claims + CI/e2e (doc:57).
- Doctor: [Run portless doctor and prove https://awesomeapps.localhost](https://github.com/vishalkdotcom/skills/issues/10) — HTTPS 443, no fallback, URL `https://awesomeapps.localhost`, curl revocation quirk.
- Sibling findings: `docs/research/prompt-slots.md` on `research/prompt-slots`; `docs/research/session-policy.md` on `research/session-policy` (`Handoff:` seventh slot).
- Repo: `skills/ship-herdr/layout.json`, `SKILL.md:12-25`, `scripts/apply-layout.ps1`, `prompt.md`; `skills/ship-validate/SKILL.md:16-20`.
- Herdr 0.9.0-preview.2026-09-08: `herdr pane run --help`, `herdr pane wait-output --help`, https://herdr.dev/docs/cli-reference/, https://herdr.dev/docs/agent-automation/.
- Portless 0.15.6 (global install): `portless --help`; `dist/cli.js` (`inferProjectName`, `handleDefaultSingle`, `runApp` print-then-spawn, CI/sudo gate, worktree prefix); `dist/chunk-SLEZT6EJ.js` `formatUrl`.
- awesomeapps (read-only): `package.json` (`name`, `dev` script); `playwright.config.ts` (PORT default, CI webServer command).
- Next.js 16 ready line: https://nextjs.org/blog/next-16 (redesigned terminal output); observed `✓ Ready in …ms` in Next 16 migration write-ups.
