# Ship-herdr loop advice after #102 — validated

Source: Cursor session `e98c929b-35a6-4132-9861-a1feace9eb7f` ("Session improvement strategies", Sep 8 2026), which autopsied the `ship-herdr 102` run and produced improvement advice. This doc records whether that advice is correct (checked against the raw session transcripts, the local Herdr binary + herdr.dev, the actual skill files, and primary web sources) and states the final, corrected advice.

Verdict in one line: **the core diagnosis and advice are correct; four factual errors and two over-attributions need correction.**

## Validation results

### #102 autopsy — accurate

All twelve factual claims about the run verified against the raw transcripts (`.scratch/cursor-session-extract/`, `~/.cursor/projects/c-vishal-repos-awesomeapps/agent-transcripts/`):

- Three implement/validate/review cycles on a ~28-line `CompareSection`; review 1 prescribed nested lists, writer obeyed, fresh review 2 reversed it and prescribed flattening, writer obeyed again. Ticket ACs never specified markup.
- The orchestrator sent the byte-identical review prompt into the same review occupant at 6:44 PM and 7:05 PM (Sep 7), re-running the full review battery on an unchanged tree.
- The failed earlier run (`78ab19c6`) burned ~106k tokens on research, hit "Named models unavailable" on a free plan, slipped into Plan mode, and never wrote a progress file.
- Full CI battery ran three times; occupants stamped `unit_done` prematurely (implement stamped it at Brief/branch stage, before any product code); PR unit produced commit `7d2cfa8` / PR #193 with a one-line prompt addition that worked.
- Timeline claims all check out to the minute. The "user stopped the loop ~9:14, PR started ~9:22" ordering is real: the stop message interrupted the parent's wait turn while review 3 was already running; review 3 finished clean, then PR started.

One error found inside the autopsy's orchestrator report (not in its main conclusions): it claimed "a third review agent was aborted mid-start." The raw record shows review 3 (`c323fa8e`) started 8:53 PM and completed normally — the abort hit the parent's in-flight wait, not a review start.

### Herdr CLI claims — correct, minor corrections

Verified against `herdr 0.9.0-preview.2026-09-08` (`--help` output, a live `agent_pane_busy` probe, herdr.dev docs):

- `agent start` on an occupied pane fails with `agent_pane_busy` — confirmed live. No replace/restart command exists.
- `prompt --wait` semantics (idle|done|blocked matcher, 5s stall window → `agent_prompt_stalled`, does not track turns, never watches the progress file) — verbatim in `--help` and docs.
- Fresh review recipe (`pane run <pane> "/exit"` → wait for shell → `agent start`) and same-process `/clear` — correct per Cursor CLI slash-command docs.
- `layout.json` is labels+splits only; `apply-layout.ps1` creates idle shells and never spawns processes — confirmed against the script on disk. No `herdr layout` CLI; socket `layout.apply` can launch argv.
- Dev tab via `herdr pane run <dev> "pnpm dev"` + `pane wait-output` — correct.

Corrections:

1. `release-agent` is `herdr pane release-agent`, not `herdr agent release-agent`.
2. `pane report-agent` requires the positional pane ID.
3. `pane wait-output --regex` matches one line at a time — keep readiness patterns single-line.
4. "Cursor goes idle between tool rounds" (the false-done mechanism) is **plausible but unproven**: Cursor state comes from screen-manifest detection with an `idle` fallback, so transient idle is possible in principle, but it is not documented for Cursor specifically. Treat `--wait` as "pane settled enough to read," never as unit-done — which the advice already says.

### Skill-file claims — mostly correct, three errors

Verified against `C:\Users\Vishal\.agents\skills\ship*\` (canonical home is the separate `C:\vishal\repos\skills` repo, symlinked into `~/.agents/skills`; the repo's `.claude/skills/ship` is a 12-line stub via a junction to the repo's own `.agents/skills`):

- "Review is a new agent every time; writer may reuse implement for a fix pass" is in `ship-herdr/SKILL.md:20`. `ship/SKILL.md:25,28` independently mandate a new review when the diff changed.
- `review-rules.md` really does make **judgement = must clear** with no "cleared finding stays" rule — the flip-flop enabler is real.
- `ship-herdr` loops until `next: human-qa` with no circuit breaker; step 9 already names the progress file as the boundary.
- The proposed additions (`## Log`, `stable` rule, Pass/Clear/Session slots) genuinely do not exist yet.

Errors in the session:

1. **"Five-pass battery"** — the battery is 3 passes (Standards+Spec, Thermo-nuclear, Bugbot) plus a conditional 4th (security, only when asked or security-sensitive). The "10 Task calls" observation was 3-pass × 2 turns + extras, not 5-pass × 2.
2. **"ship-implement has no fix-pass skip branch"** — it already has one: `ship-implement/SKILL.md:14` skips to Branch when Brief is filled, and `implement.md` already handles clearing findings. The session's proposed fix-pass branch is a *strengthening* (skip Branch too), not a new concept.
3. **Attribution slip** — "This chat stays in Agent." / "The ticket is the approach." live in `ship-implement/SKILL.md:10`, not `prompt.md`. Also `prompt.md` is 14 lines with an 8-line template block, and its `<unit-skill-path>` already is a unit slot.

Also noted: several changes the session discussed (`--force --trust`, claim-gate step, prompt.md) are currently **uncommitted** in the skills repo.

### External tools — advice holds, two claims outdated/wrong

- **Portless — all claims correct.** Loopback HTTPS proxy, named `https://<app>.localhost`, random `PORT` 4000–4999, `PORTLESS_URL` injected, Windows via certutil + Task Scheduler as SYSTEM, `-p 1355` / `--no-tls` fallbacks, `portless doctor` ([vercel-labs/portless](https://github.com/vercel-labs/portless)). Bonus fact strengthening the advice: portless **refuses to run under `CI=1`**, so keeping Playwright e2e on a fixed `PORT=3002` production server is mandatory, not just sensible. Next.js respects `PORT`.
- **RTK — verdict (skip) holds, two supporting claims are wrong.** Correct: only Shell/Bash tool output goes through the hook; Read/Grep bypass it; `rtk init --global --agent cursor` exists. Wrong: (a) WSL is **not** required — native Windows hooks work since v0.37.2; (b) the exit-code-3 Cursor no-op bug was real but **fixed 2026-06-29** ([rtk-ai/rtk#2372](https://github.com/rtk-ai/rtk/issues/2372)), not live; (c) "hooks.json collides with Herdr's sessionStart" is overstated — the actual `~/.cursor/hooks.json` already runs Herdr's `sessionStart` alongside two `preToolUse` hooks; arrays coexist by design. The skip verdict still stands because review work is mostly Read/Grep, which never touches the hook.
- **Headroom — verdict (wait) holds decisively.** ~20% for coding agents vs 60–95% for JSON matches its own README (some agent workloads benchmark higher, 21–57%). Critically, per [LiteLLM's Cursor docs](https://docs.litellm.ai/docs/tutorials/cursor_integration), `cursor-agent` **cannot target any LLM gateway** — a Herdr-spawned Cursor occupant cannot be routed through Headroom at all. Both RTK and Headroom are young, fast-churning repos (created Jan 2026; 1,840 / 665 open issues) — pin versions if ever adopted.

### Methodology attributions — core solid, two overreach

- **Correct:** Anthropic's [long-running harness post](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) confirms progress-file + git as cross-window memory, warns models overwrite Markdown, and uses a different prompt for the first window vs later windows. HumanLayer's "own your control flow" is [12-factor agents, factor 8](https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-08-own-your-control-flow.md). Yegge's Gas Town caveat is real (he gates it by user maturity, though he also calls it "the gold standard for 2026").
- **Over-attributed:** (a) "append-only journal, never rewrite earlier bullets" is **not** Anthropic's stated rule — their actual mitigation is JSON over Markdown, restricted edits, and git as the ledger; append-only is a reasonable extrapolation. (b) A "~3 repeated failures" cap has **no published source** — Anthropic's failure guidance is the opposite flavor ("let the agent adapt"). (c) "Compaction is last resort" contradicts Anthropic's context-engineering post, which calls compaction the **first** lever; only the weaker claim ("don't rely on compaction for cross-session handoff") is supported. (d) The per-role session-reuse matrix and "delta prompts / pass slots" are plausible engineering judgment, not published best practice.

## Final advice (corrected)

Priority order — 1–3 change the loop, 4 saves tokens, 5–6 are tooling.

1. **Fix the review severity rules** (`review-rules.md`). Judgement stays must-clear but requires a **cite** (AC, spec, or a named `CODING_STANDARDS.md` rule); equivalent markup/type shapes that already meet AC are **nit** (drop). Add the **stable** rule: a finding cleared in the Log stays cleared — a later review reversing it is nit unless the current diff is newly hard. This is what stops the CompareSection flip-flop; it works with the real 3+1-pass battery (not "five-pass").
2. **Add a circuit breaker** in `ship-herdr`: after 2 review units whose only findings are same-path judgement/nit, set `next: human-qa` (or leave the pane `blocked` for the human). Do not adopt a "~3 failures" cap as sourced practice — pick your own number deliberately.
3. **Make the progress file append-only memory**: keep Brief write-once, Findings = open items only, and add an append-only `## Log` (one ≤20-word line per finished unit: `pass`, class, why, next). Require `unit_done` written once, last, after Evidence. If you want to match Anthropic's actual mitigation rather than the extrapolated journal rule, the stronger form is: keep the mutable state minimal and let git be the ledger.
4. **Occupant prompt slots, not a thicker prompt.** Keep `prompt.md` short; drop the invariants the skill/Herdr already own (Repo, Claim-gate, Tool-calls); add `Pass: first|fix <n>|review <n>`, `Clear: none|Findings`, `Session: new|reuse`. Orchestrator writes a claimed stub after claim-gate so implement's existing progress-file skip actually fires. Fix-pass prompts quote the Findings to clear; re-validate runs only the commands the diff can affect (`check`, `typecheck`, ticket tests), not full CI.
5. **Session policy as advised — confirmed:** review always new (`pane run "/exit"` → shell → `agent start`, or `/clear` for same-process), implement reuse for fix passes, validate reuse with delta prompts, PR always a fresh occupant. Do not new-session every step. See §9 for the context-budget refinement of this policy.
6. **Completion boundary:** never treat `herdr agent prompt --wait` or `agent wait` as unit-done; poll the progress file for this unit's `unit_done` + one new Log line; use `agent explain` to audit suspicious idle readings.
7. **Dev tab:** add a third `dev` tab of idle shells to `layout.json`; after `apply-layout.ps1`, start the app with `herdr pane run <dev> "pnpm dev"` + single-line `pane wait-output --regex`. **Portless: adopt** for the named URL (`https://awesomeapps.localhost`), run `portless doctor` first to prove CA trust, fall back to `-p 1355` or `--no-tls` if 443 is noisy. Never tell occupants the app is `localhost:3000`. Keep e2e on `CI=true PORT=3002` (portless refuses CI anyway).
8. **RTK: skip** for this loop (review is Read/Grep-heavy, which bypasses its hook) — but drop the WSL/live-bug/hook-collision reasons, which are outdated or wrong; the correct reason is coverage. **Headroom: wait** — `cursor-agent` cannot be pointed at any LLM proxy, so it cannot help a Herdr-driven Cursor loop regardless of savings.

9. **Reuse-with-a-budget + handoff (follow-up, validated).** The proposed mix-and-match — reuse a session while its context stays lean, hand off to a fresh one when it fills — is the right instinct and is evidence-compatible, with corrections:
   - **The "smart zone" is real but has no proven cliff.** Context degradation is a gradual, task-dependent gradient, worst for exactly what a coding session accumulates (stale tool output, abandoned approaches = distractor-rich context; [Chroma Context Rot](https://www.trychroma.com/research/context-rot), [NoLiMa](https://arxiv.org/abs/2502.05167), [RULER](https://arxiv.org/abs/2404.06654)). No benchmark establishes 120k/256k as a boundary; vendor compaction walls sit at ~80–95% (Claude Code, Codex, Cursor). The closest evidence anchor: measured *effective* context for multi-hop work is ~50–65% of the advertised window, and HumanLayer's published policy keeps utilization at **40–60% proactively** — so "rotate around 130–155k of 256k" is a defensible conservative heuristic, not a discovered law. Content hygiene beats raw percentage: a lean 180k beats a noisy 120k.
   - **Policy: boundary first, threshold as circuit breaker.** Keep the per-role session rule from item 5 as the primary trigger (review/PR always fresh; fix-pass reuse allowed). Add the token threshold only as the override: if a reused implement/validate occupant crosses ~50–60% context, hand off and rotate instead of prompting again. Fix-pass reuse is then the *bounded* exception — safe when the session is well under budget and the findings to clear are fully in context (which #102's cheap 7-minute fix pass was).
   - **Handoff artifact: use the existing `handoff` skill shape.** It writes a Markdown doc (OS temp dir) with a next-unit-tailored summary, a "suggested skills" section, and **references, not copies** (ticket, progress file, commits — specs/diffs are never duplicated). Add a `Handoff: <path>` slot to `prompt.md` for rotated sessions. Note the progress file already covers most handoff content intra-ticket — the handoff's unique value is carrying **why / dead ends / failed approaches** out of an occupant that is too full (or dead) to write the progress file itself.
   - **Token tracking is not built in, but is buildable.** cursor-agent transcripts, `store.db`, and `herdr agent get` expose **no** token/context fields. Two working channels: (a) quick+fragile — `herdr agent read <name> --source visible` scrapes the TUI statusline, which mid-session renders `ctx ▓▓░░ 41% · 105.7k/256k`; (b) robust — Cursor invokes `~/.cursor/statusline.js` on every update with a JSON stdin payload containing `context_window.used_percentage` / `total_input_tokens` / `context_window_size`; extend it to append that to a per-session log or push `herdr pane report-metadata --token ctx=<pct>` (`$HERDR_PANE_ID` is set inside panes). The orchestrator then reads ctx% before deciding reuse vs rotate. (`stop` / `afterAgentResponse` hooks also carry per-turn token totals, but `input_tokens` there is cumulative across calls — the statusline's `total_input_tokens` is the true fill number.)
   - **Fresh + artifacts beats compaction at boundaries.** Anthropic's harness work found compaction alone insufficient across windows; their own task-matching rule puts milestone-driven pipelines (like ship's units) in the structured-notes/handoff camp, with compaction (`/summarize`, aka `/compact`) only as an intra-unit safety valve.

## Sources checked

- Raw transcripts: Cursor state.vscdb composer data + `~/.cursor/projects/c-vishal-repos-awesomeapps/agent-transcripts/*.jsonl` (9 unit sessions + parent + side chats), extracted to `.scratch/cursor-session-extract/`.
- Herdr: local binary `--help` output, live `agent_pane_busy` probe, [herdr.dev docs](https://herdr.dev/docs/cli-reference/).
- Skills: `C:\Users\Vishal\.agents\skills\ship*\` (canonical: `C:\vishal\repos\skills`), `prompt.md`, `apply-layout.ps1`, `progress.md`, `review-rules.md`.
- Web: [portless](https://github.com/vercel-labs/portless), [rtk](https://github.com/rtk-ai/rtk) (+ issue #2372), [headroom](https://github.com/headroomlabs-ai/headroom), [Cursor hooks](https://cursor.com/docs/hooks), [Cursor CLI slash commands](https://cursor.com/docs/cli/reference/slash-commands), [LiteLLM Cursor integration](https://docs.litellm.ai/docs/tutorials/cursor_integration), [Anthropic long-running harness](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents), [Anthropic context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents), [Anthropic multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system), [HumanLayer 12-factor agents](https://github.com/humanlayer/12-factor-agents), [Yegge's Gas Town](https://yegge.ai/gastown.html).
- Context-budget follow-up (§9): [Chroma Context Rot](https://www.trychroma.com/research/context-rot), [Lost in the Middle](https://aclanthology.org/2024.tacl-1.9/), [NoLiMa](https://arxiv.org/abs/2502.05167), [RULER](https://arxiv.org/abs/2404.06654), [HumanLayer advanced context engineering (FCA)](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents/blob/main/ace-fca.md), [Cursor dynamic context discovery](https://cursor.com/blog/dynamic-context-discovery), local `handoff` skill (`C:\Users\Vishal\.agents\skills\handoff\SKILL.md`), local Cursor `statusline.js` / `hooks.json` inspection, live `herdr agent get/list/read` probes.
