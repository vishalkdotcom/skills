# Research: Session policy — per-role reuse, rotation threshold, handoff artifact (ticket #7)

Decision ticket: `vishalkdotcom/skills#7`. Source of truth: `awesomeapps/docs/agent/ship-herdr-loop-102-validated-advice.md` ("advice doc", cited by line), final advice items 5 and 9. Prerequisites: #5 (Log schema, `docs/research/progress-file.md` on `research/progress-file`) and #6 (slot set, `docs/research/prompt-slots.md` on `research/prompt-slots`), which deferred the `Handoff:` slot here.

## Decision in one line

Keep the per-role session rule as the primary trigger (review/PR always fresh; implement fix-pass and validate re-run may reuse); add a **~50–60% context circuit breaker** as the only override — cross it and rotate with a handoff doc instead of prompting again; the handoff artifact is the existing `handoff` skill shape, and compaction stays an intra-unit safety valve only.

## Proposed `## Session policy` section for `skills/ship-herdr/SKILL.md`

Full text of the new section, placed after the "This run" steps. It also replaces the parenthetical in step 5 (`SKILL.md:20`, "Review is a **new** agent every time that unit runs (writer may reuse the implement occupant for a fix pass)") with a pointer: "Session choice per unit: [Session policy](#session-policy)."

```markdown
## Session policy

**Per-role rule (primary trigger):**

- **review** — always a new agent. `herdr pane run <pane> "/exit"`, wait for the shell prompt, then `agent start` again — or `/clear` for a same-process reset.
- **implement** — new on first run; a fix pass may reuse the same occupant.
- **validate** — new on first run; a re-validate may reuse with a delta prompt (`Re-run only:` scoped commands, see prompt.md).
- **pr** — always a fresh occupant.
- Do **not** new-session every step — a lean reused session is cheaper and already holds the diff in context.

**Budget override (circuit breaker):** reuse only while the occupant's context stays under ~50–60%. Before every reuse prompt, read the pane's ctx% — quick: `herdr agent read <name> --source visible` scrapes the TUI statusline (`ctx … N% · used/total`); robust: extend `~/.cursor/statusline.js` to append `context_window.used_percentage` to a per-session log or push `herdr pane report-metadata --token ctx=<pct>`. If the occupant has crossed the threshold, rotate instead of prompting again: handoff (below), then start a fresh occupant with `Session: new` and `Handoff: <path>`.

**Bounded exception:** fix-pass reuse is safe when the session is well under budget *and* the findings to clear are quoted verbatim in the prompt (fully in context) — #102's 7-minute fix pass is the model. A fix pass that fails either condition rotates.

**Handoff artifact:** the `handoff` skill shape — a Markdown doc in the OS temp dir (never the workspace), tailored to what the next unit will do, with a suggested-skills section, and **references not copies** (ticket URL, progress file path, commits; specs and diffs are never duplicated). Its unique value over the progress file: it carries **why / dead ends / failed approaches** out of an occupant too full — or dead — to write the progress file itself. Production order: prompt the outgoing occupant to run its `handoff` skill (argument: what the next unit does) *before* `/exit`; if the occupant is already dead, the orchestrator reconstructs a minimal handoff from the progress file + Log + branch commits, or omits `Handoff:` — the progress file already covers intra-ticket state.

**Compaction:** `/summarize` (`/compact`) is an intra-unit safety valve only — never the handoff mechanism. At unit boundaries, fresh occupant + artifacts (progress file, handoff doc) beats compaction.
```

## `Handoff:` slot for `skills/ship-herdr/prompt.md` (owned by #6; one-line append)

Append one line to the template, after `Session: new | reuse`:

```
Handoff: none | <path>
```

Plus one orchestrator rule appended to prompt.md's rules list:

> - **Rotation.** When the session-policy budget override rotates a reused implement/validate occupant, the fresh occupant gets `Session: new` + `Handoff: <path>` (the doc the outgoing occupant's `handoff` skill wrote, or an orchestrator-reconstructed one). Every other prompt is `Handoff: none`.

## Rationale per choice

- **Per-role rule as primary trigger, not the threshold.** Advice doc final advice item 5 (doc:74): "review always new … implement reuse for fix passes, validate reuse with delta prompts, PR always a fresh occupant. Do not new-session every step." §9 confirms it stays primary, with the token threshold "only as the override" (doc:81). Review-always-new is also already mandated independently by `skills/ship/SKILL.md:25,28` (new review when the diff changed) and `skills/ship-herdr/SKILL.md:20`. The new-agent recipe (`pane run "/exit"` → shell → `agent start`, `/clear` same-process) is validated against Herdr 0.9.0 and Cursor CLI slash-command docs (doc:27); `agent start` on an occupied pane fails with `agent_pane_busy`, so the `/exit`-first ordering is required, not optional (doc:25).
- **~50–60% threshold, stated honestly as a heuristic.** Grounding per §9 (doc:80): context degradation is a gradual, task-dependent gradient — worst for exactly what a coding session accumulates (stale tool output, abandoned approaches) — with **no proven cliff** at any boundary ([Chroma Context Rot](https://www.trychroma.com/research/context-rot), [NoLiMa](https://arxiv.org/abs/2502.05167), [RULER](https://arxiv.org/abs/2404.06654)); vendor auto-compaction walls sit at ~80–95%, i.e. they are backstops, not targets. The two honest anchors: measured *effective* context for multi-hop work is ~50–65% of the advertised window, and HumanLayer's published policy keeps utilization at **40–60% proactively** ([HumanLayer FCA](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents/blob/main/ace-fca.md)). So 50–60% is a defensible conservative heuristic, not a discovered law — the policy text therefore says "crossed the threshold" without pretending a cliff, and §9's own warning that **content hygiene beats raw percentage** ("a lean 180k beats a noisy 120k", doc:80) is why the per-role rule, not the meter, drives normal operation.
- **Bounded exception for fix-pass reuse.** §9 (doc:81): reuse is safe "when the session is well under budget and the findings to clear are fully in context (which #102's cheap 7-minute fix pass was)". The verbatim-quoting mechanism that puts findings fully in context is #6's `Clear: Findings` rule (`docs/research/prompt-slots.md`, prompt-slots branch), so the exception cites both conditions.
- **ctx% is readable, so the circuit breaker is enforceable.** Not built in, but two working channels are validated in §9 (doc:83): scrape the TUI statusline via `herdr agent read --source visible` (quick, fragile), or extend `~/.cursor/statusline.js` — which Cursor invokes on every update with a JSON payload carrying `context_window.used_percentage` / `total_input_tokens` — to log per-session or push `herdr pane report-metadata --token ctx=<pct>` (robust). The policy names both so the orchestrator has a quick path today and a build target later. The `input_tokens` in `stop`/`afterAgentResponse` hooks is cumulative across calls and must not be used as the fill number (doc:83).
- **Handoff artifact = existing `handoff` skill shape, not a new format.** The skill already writes a Markdown doc to the OS temp dir, tailored to the next session via its argument, with a suggested-skills section, references-not-copies, and redaction (`C:\Users\Vishal\.agents\skills\handoff\SKILL.md:8-15`); §9 prescribes exactly this shape (doc:82). Its unique value is **why / dead ends / failed approaches** — content the progress file deliberately does not hold (the #5 Log is ≤20-word what/next lines, `docs/research/progress-file.md`) — carried out of an occupant too full or dead to write the progress file itself (doc:82). Production order (handoff *before* `/exit`) follows from the recipe: once `/exit` runs, the conversation is gone; the dead-occupant fallback (orchestrator reconstructs from progress file + Log + commits, or omits the slot) keeps rotation possible even then, because the progress file already covers intra-ticket state (doc:82).
- **`Handoff: none | <path>` as the seventh slot line.** #6 explicitly deferred this slot as a one-line append ("Adding it later is a one-line append to the template", `docs/research/prompt-slots.md`) and its slot table already routes rotated sessions to `Session: new` with the escape hatch "rotate + handoff". Defaulting to `none` keeps non-rotated prompts byte-identical in shape to #6's template.
- **Compaction demoted to intra-unit safety valve.** Anthropic's harness work found compaction alone insufficient across windows, and their task-matching rule puts milestone-driven pipelines (ship's units) in the structured-notes/handoff camp (doc:84; [Anthropic long-running harness](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)). The advice doc corrects the stronger "compaction is last resort" claim — Anthropic's context-engineering post calls compaction the *first* lever intra-session (doc:64) — so the policy keeps `/summarize` available inside a unit and forbids it only as the cross-session mechanism.

## Sources

- Advice doc `awesomeapps/docs/agent/ship-herdr-loop-102-validated-advice.md`: final advice item 5 (doc:74); §9 (doc:79–84); Herdr validation (doc:25, 27); methodology-attribution correction on compaction (doc:64); #102 autopsy fix-pass observation (doc:81).
- Sibling findings: `docs/research/progress-file.md` on `research/progress-file` (#5, Log schema — what the progress file does and does not carry); `docs/research/prompt-slots.md` on `research/prompt-slots` (#6, slot set + deferred `Handoff:` slot + `Clear: Findings` verbatim-quoting rule).
- Repo: `skills/ship-herdr/SKILL.md:20` (current session parenthetical this section replaces), `skills/ship-herdr/SKILL.md:24` (progress file as completion boundary), `skills/ship/SKILL.md:25,28` (new review when diff changed).
- Handoff skill: `C:\Users\Vishal\.agents\skills\handoff\SKILL.md` (full file, 16 lines).
- Primary sources (as already verified by the advice doc): [Chroma Context Rot](https://www.trychroma.com/research/context-rot), [NoLiMa](https://arxiv.org/abs/2502.05167), [RULER](https://arxiv.org/abs/2404.06654), [HumanLayer FCA](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents/blob/main/ace-fca.md), [Anthropic long-running harness](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents), [Anthropic context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents).
