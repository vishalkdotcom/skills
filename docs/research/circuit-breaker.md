# Research: circuit breaker for judgement/nit-only review loops (ticket #4)

Decision ticket: `vishalkdotcom/skills#4`. Source of truth: `awesomeapps/docs/agent/ship-herdr-loop-102-validated-advice.md` ("advice doc"), final advice item 2. Composes with ticket #3's severity vocabulary ([docs/research/review-rules.md on research/review-rules](https://github.com/vishalkdotcom/skills/blob/research/review-rules/docs/research/review-rules.md)) and ticket #5's Log line grammar ([docs/research/progress-file.md on research/progress-file](https://github.com/vishalkdotcom/skills/blob/research/progress-file/docs/research/progress-file.md)).

## Decision in one line

After **2 consecutive review units** whose only findings are **same-path judgement or nit** (no hard, no scope wall), the orchestrator trips the breaker: it writes `next: human-qa` and one `orchestrator · breaker · …` Log line to the progress file, and stops starting units. Implemented as a **new step 10** in `skills/ship-herdr/SKILL.md`, between the unit-complete boundary (step 9) and the loop step.

## The four decisions

### N = 2 consecutive same-path judgement/nit-only review units

Adopt the doc's suggested 2 (advice doc:71), deliberately:

- **Not 1.** A single judgement/nit-only review is legitimate work: cite-backed judgement is must-clear under the new severity rules and deserves its fix pass (ticket #3 findings, Severity table). One such unit proves nothing about oscillation.
- **2 is exactly where #102's oscillation manifested.** Review 1 prescribed nested lists, the writer obeyed, fresh review 2 reversed it on an unchanged tree (advice doc:13). The flip-flop is visible at the *second* same-path review; waiting for a third burns another full review battery for no decision-relevant information.
- **The trigger is already narrow, so N can be small.** "Same-path" + "only judgement/nit" (no hard, no scope wall) excludes every productive review. A second review meeting all those conditions is not adapting — it is re-litigating. This is an oscillation detector, not a generic failure cap; hard findings never trip it.
- **Cost asymmetry favors tripping early.** A redundant review unit runs the full 3+1-pass battery, the loop's most expensive unit (advice doc:49; the failed earlier run burned ~106k tokens, advice doc:15). A false trip costs the human one Guided-QA glance at findings that are by definition only judgement/nit.
- **The "~3 repeated failures" cap is rejected as sourced practice**, per the ticket and the doc: it has no published source, and Anthropic's failure guidance is the opposite flavor ("let the agent adapt") (advice doc:64, :71).

### Trigger phrasing (ticket #3's vocabulary)

The breaker trips when the last **2 consecutive `review` Log lines** both satisfy:

1. **class ∈ {judgement, nit}** — the worst finding class the unit left (the greppable `class` field of ticket #5's Log grammar: `unit · pass first|fix <n>|review <n> · class · why · next`). `class: hard` or a `scope_wall` finding resets the count — the loop is making real progress or has correctly escalated.
2. **same-path** — the unit's findings are on the same paths the previous review flagged. The orchestrator reads each unit's **Findings** section as it dispatches the next unit (the progress file is the boundary, `skills/ship-herdr/SKILL.md:24`), so it has seen both reviews' findings and compares paths directly; this does not depend on the ≤20-word Log `why` carrying paths.
3. Under ticket #3's severity rules this means: findings that are nit (uncited, or equivalent-shape, or a reversal demoted by the **stable** rule), plus any cite-backed judgement that survived a fix pass and a fresh review on the same paths — the residual oscillation the stable rule alone cannot kill, because a *cited* judgement is not demotable to nit (ticket #3 findings, rationale 1 and 3).

### What tripping does: `next: human-qa` (not pane-blocked)

- The orchestrator writes `next: human-qa` on the progress file and appends one Log line, then starts no further units. `human-qa` is the loop's existing defined exit (`skills/ship-herdr/SKILL.md:25`; the `next` enum already includes it, `skills/ship/progress.md:8`), and the human already owns Guided QA and merge. Open findings stay visible: Findings is open-items-only (ticket #5 findings), so the human sees exactly the judgement/nit items left unresolved.
- **Pane `blocked` rejected.** It mirrors the `copy_agreed: no` path (`skills/ship-herdr/SKILL.md:23`) but has no resume semantics — it parks the loop indefinitely on findings that are definitionally non-hard. The breaker's purpose is to end the machine loop and hand the judgement call to the human, which `human-qa` already does.
- **The orchestrator writes the trip record itself.** Tripping is an orchestrator control-flow decision, not a unit outcome, so no occupant will write it. This is the one sanctioned orchestrator write beyond polling; the boundary stays the progress file. Explicit, file-recorded control flow is HumanLayer 12-factor factor 8, "own your control flow" (https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-08-own-your-control-flow.md; verified advice doc:63).

### Where it lives: new step 10 in `skills/ship-herdr/SKILL.md`

Between step 9 (unit-complete boundary) and the loop step, because the check needs this unit's `unit_done` + Log line to have landed, and must run before the next unit is dispatched.

## Exact patch text for `skills/ship-herdr/SKILL.md`

Against the current working-tree file (which carries the uncommitted ship* drift — the 10-step loop with the boundary at step 9, matching what this ticket names). Replace steps 9–10:

```diff
 9. **Unit complete:** the progress file has `unit_done` for this unit. Diagnose a stall with a short pane tail; the progress file is the boundary.
-10. Loop 2–9 until `next: human-qa`. Then stop.
+10. **Circuit breaker:** count back through the Log's `review` lines. When the last 2 consecutive review units both left class `judgement` or `nit` only — no `hard`, no `scope_wall` — on the same paths (you read each unit's Findings; compare paths), the review loop is oscillating. Trip it: write `next: human-qa` on the progress file, append one Log line `- orchestrator · breaker · <worst class> · 2 same-path judgement/nit reviews · human-qa`, and start no further units. Any `hard` class or scope wall resets the count.
+11. Loop 2–10 until `next: human-qa`. Then stop.
```

Everything else in the file is unchanged, including the `Done when:` block (the human still owns Guided QA and merge — the breaker hands off to exactly that).

If applied to committed `main` (36bd1ce) instead of the drifted working tree, the same text slots in as a new step between HEAD's step 7 (`**Unit complete:** … the progress file is the boundary.`) and step 8 (`Loop 2–7 …`), with the loop adjusted to `Loop 2–8`.

## Grammar note for the implementing ticket (#11)

The breaker Log line extends ticket #5's Log grammar (`unit · pass · class · why · next`) with two one-token values: `unit: orchestrator` and `pass: breaker`. `class` carries the worst class of the tripping reviews (`judgement` or `nit`); `why` carries the fixed text `2 same-path judgement/nit reviews`; `next: human-qa`. The line is ≤20 words as the grammar requires. No other change to `progress.md` is needed — `next: human-qa` is already in the enum.

## Rationale per choice (sources)

1. **N=2** — advice doc:71 (suggestion), :13 (flip-flop visible at review 2), :49 and :15 (review-battery cost), :64/:71 (rejection of the unsourced "~3 failures" cap; Anthropic's opposite-flavor guidance), ticket #3 findings Severity table (one cited-judgement unit is legitimate must-clear work).
2. **Trigger phrasing** — ticket requirement; `class` field from ticket #5's Log grammar (progress-file findings, "Log line format" rationale); cite/stable vocabulary from ticket #3's replacement Severity section (review-rules findings, proposed text); path comparison via the orchestrator's own reads of Findings, the boundary named at `skills/ship-herdr/SKILL.md:24`.
3. **`next: human-qa` over pane-blocked** — advice item 2 offers both (advice doc:71); `human-qa` chosen because it is the defined exit with resume semantics (`skills/ship-herdr/SKILL.md:25`, `skills/ship/progress.md:8`) while `blocked` (SKILL.md:23) has none; findings visibility guaranteed by Findings-is-open-items-only (ticket #5 findings).
4. **Orchestrator writes the trip record** — tripping is control flow, not a unit outcome; file-recorded explicit control flow per HumanLayer factor 8 (verified advice doc:63); progress file as the single boundary (advice item 6, advice doc:75; `skills/ship-herdr/SKILL.md:24`).
5. **Placement as new step 10** — ticket names the numbered steps as the loop and step 9 as the boundary; the check must follow unit completion and precede dispatch. Patch targets the drifted working tree (the ticket's step numbering matches it); HEAD mapping provided for the drift-owning ticket.
