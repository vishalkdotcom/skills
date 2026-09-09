# Research: review severity rules (ticket #3)

Question: exact replacement text for `skills/ship/review-rules.md` implementing advice item 1 of the validated #102 advice (`docs/research/ship-herdr-loop-102-validated-advice.md`, "Final advice" item 1).

Decision: replace the **Severity** section with cite-or-drop judgement, equivalent-shape-is-nit, and a stable rule; keep the battery as the real 3+1 passes; keep the reviewer/writer split verbatim.

## Proposed full replacement text for `skills/ship/review-rules.md`

```md
# Review rules

Shared by `ship-review` (classify) and `ship-implement` (clear findings).

## Battery

Against the uncommitted diff (`git diff HEAD`). Prefer parallel subagents.

| Pass | How |
| --- | --- |
| Standards + Spec | `/code-review`. Spec axis: the ticket and parent spec. Standards axis: `CODING_STANDARDS.md` (and other repo standards files). |
| Thermo-nuclear | Cursor subagents `thermo-nuclear-review-subagent` and `thermo-nuclear-code-quality-review-subagent`. `Full Repository Path: <repo root>`. `Diff: uncommitted changes`. |
| Bugbot | Cursor `bugbot` (or `/review-bugbot`). Same diff contract. |

Conditional 4th pass — security review, only when the human asks or the diff is security-sensitive. Dirty files outside the ticket: `Diff: natural language` listing only this ticket's paths.

A missing pass (tooling absent) is recorded on the progress file as untested.

## Severity

| Class | Meaning | Before commit |
| --- | --- | --- |
| **Hard** | Incorrect behavior, AC/spec miss, security issue, standards violation | Must clear |
| **Judgement** | Real smell or inconsistency **with a cite** — an AC, a spec line, or a named `CODING_STANDARDS.md` rule (e.g. workarounds and imperative React the standards ban: cite the banning rule) | Must clear |
| **Nit** | Format/lint noise tooling already enforces; any finding without a cite | May drop |

**Cite or drop.** A judgement finding names its cite inline (`AC 3`, spec section heading, standards rule name). No cite → nit. Equivalent markup or type shapes that already meet the AC are nit — never prescribe a different shape that meets the same AC.

**Stable.** Before classifying, check the progress file's cleared-finding record (the `## Log` lines, else prior **Findings** entries). A finding a previous review raised and the writer cleared stays cleared: a later review re-raising it, or reversing the fix that cleared it, is nit unless the current diff made that code newly hard.

Reviewer labels like "non-blocking" or "later" are **judgement** (cite required) unless they are a nit. Clear in this diff, or scope-wall to the human. Filing a follow-up ticket does not clear a finding.

**Scope wall:** when the proper fix belongs to a different open ticket or spec AC, stop and ask the human — expand now or hold (no commit).

**Promote recurring pain:** when the same judgement finding recurs across ships, fold the lesson into the matching file behind `CODING_STANDARDS.md`.

The reviewer writes findings only. The writer (implement unit) edits.
```

Diff against current `skills/ship/review-rules.md` (36bd1ce): Battery table unchanged; the security sentence gains the "conditional 4th pass" label; the Severity table's Judgement row gains the cite requirement and Nit gains "any finding without a cite"; the **Cite or drop** and **Stable** paragraphs are new; everything else verbatim.

## Rationale

1. **Judgement requires a cite (AC, spec line, named standards rule); uncited → nit.** Directly advice item 1 ("Final advice", docs/research/ship-herdr-loop-102-validated-advice.md:70). In the #102 autopsy the ticket "ACs never specified markup" (advice doc:13), so neither review's markup prescription had a possible cite — both become nit and the flip-flop dies at classification. Current rule with no cite requirement is the flip-flop enabler (advice doc:43; skills/ship/review-rules.md:24).
2. **Equivalent markup/type shapes that meet the AC are nit — never prescribe a different shape.** Advice item 1 verbatim (advice doc:70). This is the precise CompareSection kill: review 1 prescribed nested lists, the writer obeyed, fresh review 2 reversed it on an unchanged tree (advice doc:13). Under this rule, review 2's flattening prescription is nit because the nested-list shape already met the AC.
3. **Stable rule: cleared stays cleared; reversal is nit unless the current diff is newly hard.** Advice item 1 verbatim (advice doc:70). It must be file-backed because review is a **new agent every time** (skills/ship-herdr/SKILL.md:20; skills/ship/SKILL.md:25) — the fresh reviewer has no memory of prior verdicts, so the progress file is the only carrier, matching Anthropic's long-running-harness finding that state must live in files/git across windows, not context (https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents, as verified in advice doc:63). The "newly hard" escape hatch keeps reversals possible when the writer's fix pass actually broke something — the diff contract (`git diff HEAD`, skills/ship/review-rules.md:7) is what "current diff" refers to.
4. **Stable rule reads the Log, with prior Findings as fallback.** The `## Log` section is advice item 3 (advice doc:72) and belongs to the progress-file ticket (#4 blocks on this one, per the map), not this file. The fallback phrasing ("else prior **Findings** entries") keeps the rule operative against the current template (skills/ship/progress.md:27-34) before that ticket lands, without this change touching progress.md.
5. **Battery kept as 3 passes + conditional 4th (security), not "five-pass".** The table already encodes the real battery (skills/ship/review-rules.md:9-15); the "five-pass" framing was an autopsy error — "10 Task calls" was 3-pass × 2 turns + extras (advice doc:49). Only change: the security line is explicitly labelled the conditional 4th pass so future readers cannot re-miscount.
6. **Reviewer writes findings only; writer (implement unit) edits — kept verbatim.** Advice item 1 lists it under what works (ticket requirement; advice doc "Preserve what works" is implicit in item 1 keeping the reviewer/writer split unchanged). It is also the load-bearing boundary elsewhere: `ship-review` promises "Working tree unchanged by this chat" (skills/ship-review/SKILL.md:26) and `implement.md` owns clearing findings (skills/ship-implement/implement.md:3-5). Explicit control flow via severity classes matches HumanLayer 12-factor factor 8, "own your control flow" (https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-08-own-your-control-flow.md; verified advice doc:63).

## Notes for the implementing ticket

- The "no cite → nit" demotion intentionally narrows judgement: genuine smells with no AC/spec/standards anchor become droppable. The **Promote recurring pain** escape (kept verbatim) is the pressure valve — a smell that keeps mattering gets written into `CODING_STANDARDS.md`, after which it has a cite.
- #102's second failure mode (orchestrator re-ran the byte-identical review prompt on an unchanged tree, advice doc:14) is the circuit-breaker ticket (advice item 2), not this file — the stable rule here only stops the flip-flop when a redundant review does run.
