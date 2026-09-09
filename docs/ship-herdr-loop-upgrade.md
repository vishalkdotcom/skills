# Ship-herdr loop upgrade spec

Apply the validated #102 autopsy advice (items 1–7, plus item 9's session-budget policy and token-tracking instrumentation) to the `skills/ship*` files. Execute top to bottom. Each item names its decision ticket (detail lives there), the exact file changes, and a done-when tied to the failure it kills.

This spec is the execution source. The autopsy itself is frozen at `docs/research/ship-herdr-loop-102-validated-advice.md` (line-cited by the research files). Do not edit that blob, and do not implement from its "Final advice."

Verbatim replacement texts live in `docs/research/<name>.md` on `main`. Each item below points at its file.

## Preconditions (already done — verify, do not redo)

- Baseline committed: `42785c7` on `main` — claim-gate, `--force --trust`, Brief/copy rewrite, extracted `claim-gate.md` / `tool-calls.md` / `implement.md`. Ticket: [Commit the uncommitted ship* baseline](https://github.com/vishalkdotcom/skills/issues/2). Verify `git status` is clean for `skills/ship*` before starting.
- Portless proven on this machine: HTTPS on 443, CA in current-user Root, working URL `https://awesomeapps.localhost`. Never `-p 1355`, never `--no-tls` here. Ticket: [Run portless doctor and prove https://awesomeapps.localhost](https://github.com/vishalkdotcom/skills/issues/10).

## 1. Progress file: append-only memory

Decision: hybrid schema — append-only `## Log` journal + minimal mutable state (write-once Brief, Findings = open items only, `unit_done` written once, last, after Evidence). Ticket: [Progress file as append-only memory](https://github.com/vishalkdotcom/skills/issues/5).

Files:

- `skills/ship/progress.md` — replace with the full text in `docs/research/progress-file.md`. The changes against the baseline:
  - Add a rules header at the top: Brief write-once; Findings open-items-only; Log append-only; `unit_done` once, last, after Evidence.
  - Findings section gains "(open items only — cleared findings leave this section)".
  - New `## Log` section before `## Tree`: append-only, newest at bottom, one ≤20-word line per finished unit — `unit · pass first|fix <n>|review <n> · class · why · next`, `class` = worst finding class left (hard | judgement | nit | none).
- Migration for in-flight `.scratch/ship-<ticket>.md` files (migrate in place, never reformat): add the rules header; drop any stale `plan_agreed:`; fill a missing Brief once with `migrated: unknown` markers; seed one `migrated`-tagged Log line per finished unit; leave Findings alone. One sanctioned rewrite: a premature/false `unit_done` may be cleared, with `next` routed back to that unit.

Done-when: `unit_done` can never precede Evidence by schema rule — the #102 premature-stamp failure (implement stamped `unit_done` at Brief stage) is impossible, and a fresh occupant reconstructs full unit history from the Log alone (the file is gitignored; git cannot be its ledger).

## 2. Review severity rules

Decision: judgement stays must-clear but requires an inline cite (AC, spec line, or named `CODING_STANDARDS.md` rule) — no cite → nit; equivalent shapes meeting the AC are nit; stable rule: cleared stays cleared. Ticket: [Review severity rules: cite requirement, judgement→nit, stable rule](https://github.com/vishalkdotcom/skills/issues/3).

Files:

- `skills/ship/review-rules.md` — replace with the full text in `docs/research/review-rules.md`. Changes are confined to:
  - Severity table: Judgement row gains "with a cite — an AC, a spec line, or a named `CODING_STANDARDS.md` rule"; Nit row gains "any finding without a cite".
  - New **Cite or drop** paragraph: no cite → nit; equivalent markup/type shapes that already meet the AC are nit — never prescribe a different shape meeting the same AC.
  - New **Stable** paragraph: before classifying, check the progress file's cleared-finding record (`## Log` lines, else prior Findings entries); re-raising or reversing a cleared finding is nit unless the current diff made that code newly hard.
  - Security sentence labelled "Conditional 4th pass" (kills the erroneous five-pass framing). Battery table, scope wall, promote-recurring-pain, reviewer-writes/writer-edits: unchanged.

Done-when: a CompareSection-style flip-flop is impossible by rule — a fresh review reversing a cleared finding on an unchanged diff demotes to nit twice over (equivalent-shape + stable), and no uncited markup prescription can survive as must-clear.

## 3. Occupant prompt slots

Decision: 6-line template; `Repo:` / `Claim-gate:` / `Tool calls:` dropped; slots `Pass:` / `Clear:` / `Session:` added; orchestrator rules for claimed stub, pass numbering, slot values per unit, scoped re-validation. Ticket: [Occupant prompt slots (Pass/Clear/Session) and scoped re-validation](https://github.com/vishalkdotcom/skills/issues/6).

Files:

- `skills/ship-herdr/prompt.md` — replace with the full text in `docs/research/prompt-slots.md`, then apply the two one-line slot appends from items 5 and 6 below (`Handoff:`, `App:`). The final template, after all appends, is:

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

- Orchestrator rules land under the template (full text in the findings file): claimed stub written to the progress file right after claim-gate so ship-implement's skip branch fires; pass numbers counted from the Log; per-unit slot values (implement first = first/none/new; implement fix = fix n/Findings+quoted findings/reuse; validate re-run adds `Re-run only:`; review and pr always new); `Clear: Findings` quotes the findings verbatim; scoped re-validation = only `check`, `typecheck`, and the ticket's seam test files — never full CI; browser QA re-runs only when the fix-pass diff touches UI.
- No skill-file edits. Do not copy "This chat stays in Agent. / The ticket is the approach." into the prompt — it stays in `skills/ship-implement/SKILL.md:10`.

Done-when: no occupant prompt carries Repo/Claim-gate/Tool-calls; every fix-pass prompt quotes its findings verbatim; a re-validate after a fix pass never runs the full CI battery (#102 ran it three times).

## 4. Token-tracking instrumentation

Decision: statusline.js pushes `tokens.ctx` (5-min TTL) via `herdr pane report-metadata`; orchestrator reads it with `read-ctx.ps1`; TUI scrape is the fallback; JSONL and hook totals not adopted. Ticket: [Token-tracking instrumentation: prototype ctx% channels and decide](https://github.com/vishalkdotcom/skills/issues/12).

Files:

- `skills/ship-herdr/scripts/read-ctx.ps1` and `skills/ship-herdr/scripts/statusline-ctx-log.js` — already on `main` (cherry-picked from `prototype/ctx-channels` as `b0bb25f`, with `docs/research/ctx-channels.md`).
- Machine setup (not a repo file; this machine already has it): copy `statusline-ctx-log.js` to `~/.cursor/`, splice `require("./statusline-ctx-log.js").report(p)` into `~/.cursor/statusline.js` after `JSON.parse`. Backup exists at `~/.cursor/statusline.js.bak-ctx-proto`. Helper is a no-op outside Herdr panes.
- Orchestrator read pattern: before every reuse prompt, `pwsh -NoProfile -File scripts/read-ctx.ps1 -Name <occupant>` → JSON `{name, pane_id, session_id, pct, source}`. `pct >= 50` → rotate (item 5). `source: unknown` / exit 2 → reuse; never rotate on a read failure.

Done-when: the orchestrator never guesses context fill — every reuse decision reads `read-ctx.ps1`, and a reused occupant at or past 50% ctx is rotated instead of prompted again.

## 5. Session policy (per-role reuse, rotation threshold, handoff)

Decision: per-role rule is primary (review/PR always fresh, implement fix-pass and validate re-run may reuse); ~50–60% ctx is the circuit-breaker override; handoff artifact = existing `handoff` skill shape, produced before `/exit`; compaction is intra-unit only. Ticket: [Session policy: per-role reuse, rotation threshold, handoff artifact](https://github.com/vishalkdotcom/skills/issues/7).

Files:

- `skills/ship-herdr/SKILL.md` — add the `## Session policy` section after "This run". Full text in `docs/research/session-policy.md`, with one substitution: in the **Budget override** paragraph, replace the "quick: … robust: …" sentence with the resolved read pattern from item 4:

  > **Budget override (circuit breaker):** reuse only while the occupant's context stays under ~50–60%. Before every reuse prompt, run `pwsh -NoProfile -File scripts/read-ctx.ps1 -Name <occupant>` (`tokens.ctx` from statusline.js → `report-metadata`, scrape fallback). If `pct >= 50`, rotate instead of prompting again.

  Section contents: per-role rule (review new via `pane run <pane> "/exit"` → wait for shell → `agent start`, or `/clear` same-process; implement fix-pass reuse; validate re-validate reuse with delta prompt; pr always fresh; never new-session every step); budget override above; bounded exception (reuse only when well under budget AND findings quoted verbatim in the prompt); handoff artifact (OS-temp Markdown, next-unit-tailored, suggested-skills, references-not-copies; produced by the outgoing occupant's `handoff` skill before `/exit`; dead occupant → orchestrator reconstructs from progress file + Log + commits, or omits `Handoff:`); compaction = intra-unit safety valve only.
- `skills/ship-herdr/SKILL.md` step 5 — replace the trailing sentence "Review is a **new** agent every time that unit runs (writer may reuse the implement occupant for a fix pass)." with: "Session choice per unit: [Session policy](#session-policy)."
- `skills/ship-herdr/prompt.md` — append the `Handoff: none | <path>` template line (already in the final template under item 3) plus the Rotation orchestrator rule (rotated occupants get `Session: new` + `Handoff: <path>`; every other prompt is `Handoff: none`), both from the findings file.

Done-when: no review or PR unit ever reuses a session; every rotation writes a handoff artifact before `/exit` so why / dead ends / failed approaches survive the occupant; compaction never carries state across a unit boundary.

## 6. Dev tab + named URL doctrine

Decision: third `dev` tab; orchestrator starts `portless` (not `pnpm dev`) and waits on the single-line `Ready in`; occupants get only `https://awesomeapps.localhost` via the `App:` slot; e2e stays `CI=true PORT=3002` on a production server. Ticket: [Dev tab layout + portless named-URL doctrine](https://github.com/vishalkdotcom/skills/issues/9).

Files:

- `skills/ship-herdr/layout.json` — add a third tab after `checks`: `{ "label": "dev", "panes": [{ "label": "dev" }] }`. Full file in `docs/research/dev-tab-portless.md`. No `apply-layout.ps1` change (it iterates tabs). No comments — JSON cannot hold them.
- `skills/ship-herdr/SKILL.md` line 12 — replace "Server must already be running." with "The orchestrator starts the app in the `dev` pane (below)."
- `skills/ship-herdr/SKILL.md` — insert the dev-server step after apply-layout (final numbering in the merged list below):

  > **Dev server.** From the pane map, take the `dev` pane id.
  > - If `herdr pane wait-output <dev> --regex "Ready in" --timeout 2000` already matches, reuse that process.
  > - Else `herdr pane run <dev> portless` (cwd is the layout cwd — the target repo). Then `herdr pane wait-output <dev> --regex "Ready in" --timeout 120000`.
  > - On wait failure: do not start occupants. Tail the pane, stop, leave it for the human.
  > - Do **not** match `awesomeapps.localhost` as readiness — portless prints the URL *before* it spawns Next.

- `skills/ship-herdr/SKILL.md` — add the `## Named URL` section after "This run" (full text in the findings file): occupants are told only the named URL, never `localhost:<port>`; fill `App:` with the URL portless actually printed (linked worktrees prefix the hostname); this machine's rung is HTTPS 443, no `-p 1355` / `--no-tls`, no `portless service install`; the curl `CRYPT_E_NO_REVOCATION_CHECK` quirk is not a TLS failure; fallback ladder for other machines (443 → `-p 1355` → `--no-tls`); e2e is `CI=true PORT=3002` against `pnpm start`, never portless under CI.
- `skills/ship-herdr/prompt.md` — append the `App: https://awesomeapps.localhost` template line (already in the final template under item 3). The orchestrator always writes the actual named URL.
- Not this repo: awesomeapps `playwright.config.ts` still defaults `PORT` to 3000 — occupants must pass `CI=true PORT=3002` for e2e. Do not patch it from here.

Done-when: no occupant ever sees or invents a `localhost:<port>` URL; the loop starts the app itself and blocks occupant start on `Ready in`; "Server must already be running" is gone from the skill.

## 7. Completion boundary (orchestrator unit-done detection)

Decision: unit-done = progress-file poll for this unit's `unit_done` + one new Log line; `--wait` demoted to "settled enough to read"; `agent explain` audits; 45-min human escalation. Ticket: [Completion boundary: orchestrator unit-done detection](https://github.com/vishalkdotcom/skills/issues/8).

Files:

- `skills/ship-herdr/SKILL.md` prompt step — append: "First note the progress file's Log line count. `--wait` returning means the pane settled enough to read — never that the unit is done."
- `skills/ship-herdr/SKILL.md` unit-complete step — replace with:

  > **Unit complete — the progress file is the boundary.** Poll it every 30s until BOTH `unit_done` is this unit AND the Log has one new line since the prompt. File changed within 10 min → still working. `agent_prompt_stalled` → the prompt never landed; tail the pane, resubmit once. No file change for 10 min → audit: `herdr agent explain <name>` + `agent read --lines 40`. Explain shows working → keep polling, don't re-prompt. Finished but unstamped → re-prompt once: "stamp `unit_done` + your Log line, nothing else." Leave the pane `blocked` for the human on: pane blocked, 45 min with no file change and no working state, or a second missing stamp.

  Exact diff in `docs/research/completion-boundary.md`.

Done-when: the orchestrator never again stamps or accepts `unit_done` off a `--wait` idle reading — completion requires this unit's `unit_done` plus one new Log line, both, and a transient idle between tool rounds only triggers an audit, never a re-prompt.

## 8. Circuit breaker for judgement/nit-only review loops

Decision: N = 2 consecutive same-path review units whose only findings are judgement/nit; tripping writes `next: human-qa` + one breaker Log line; hard or scope_wall resets the count. Ticket: [Circuit breaker for judgement/nit-only review loops](https://github.com/vishalkdotcom/skills/issues/4).

Files:

- `skills/ship-herdr/SKILL.md` — new step between unit-complete and the loop step (final numbering in the merged list below):

  > **Circuit breaker:** count back through the Log's `review` lines. When the last 2 consecutive review units both left class `judgement` or `nit` only — no `hard`, no `scope_wall` — on the same paths (you read each unit's Findings; compare paths), the review loop is oscillating. Trip it: write `next: human-qa` on the progress file, append one Log line `- orchestrator · breaker · <worst class> · 2 same-path judgement/nit reviews · human-qa`, and start no further units. Any `hard` class or scope wall resets the count.

  Exact diff in `docs/research/circuit-breaker.md`. The breaker line extends the Log grammar with two one-token values (`unit: orchestrator`, `pass: breaker`); no `progress.md` change.

Done-when: two consecutive same-path judgement/nit-only reviews end the machine loop at Guided QA instead of burning a third full review battery on an unchanged diff — the #102 oscillation stops at review 2, with the open findings visible to the human.

## Final merged `skills/ship-herdr/SKILL.md` "This run" list

Items 5–8 all patch this file. Apply them to produce exactly this list (intro line about the server already replaced per item 6):

1. Resolve the ticket and repo cwd.
2. Read the progress file when it exists ([../ship/progress.md](../ship/progress.md)). Next unit from [../ship/SKILL.md](../ship/SKILL.md) Units table (`next` field, else implement).
3. Fresh ticket (no progress file): [../ship/claim-gate.md](../ship/claim-gate.md). Stop when that file says stop.
4. Run `apply-layout.ps1`. Keep the printed pane map.
5. **Dev server.** (item 6 block: reuse if `Ready in` already matches, else `pane run <dev> portless` + `wait-output "Ready in"` 120s; failure → stop, no occupants.)
6. **Implement / review / pr:** pane is an idle shell. `herdr agent start <name> --kind cursor --pane <id> -- --force --trust`. Session choice per unit: [Session policy](#session-policy).
7. **Validate:** `--kind cursor` occupant in the checks pane (browser QA), same start args. Progress file still comes from `ship-validate`.
8. Prompt from [prompt.md](prompt.md) with `--wait` (`herdr agent prompt --help`). First note the progress file's Log line count. `--wait` returning means the pane settled enough to read — never that the unit is done.
9. When `copy_agreed` is `no`, leave the pane `blocked` for the human.
10. **Unit complete — the progress file is the boundary.** (item 7 block: 30s poll, `unit_done` + one new Log line, stall classes, `agent explain` audit, escalation triggers.)
11. **Circuit breaker:** (item 8 block: 2 consecutive same-path judgement/nit-only reviews → `next: human-qa` + breaker Log line.)
12. Loop 2–11 until `next: human-qa`. Then stop.

Two new sections after "This run": `## Session policy` (item 5) and `## Named URL` (item 6). The `Done when:` block is unchanged.

## Out of scope

- Advice item 8 (RTK / Headroom): already decided — RTK skipped, Headroom waits. Nothing to do.
- Validation of the upgraded loop: organic, on the user's next real tasks. No controlled #102-style re-run.
