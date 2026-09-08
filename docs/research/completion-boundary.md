# Research: Completion boundary — orchestrator unit-done detection

Ticket: vishalkdotcom/skills#8 (map #1, advice item 6)
Source doc: `docs/agent/ship-herdr-loop-102-validated-advice.md` in vishalkdotcom/awesomeapps ("the advice doc" below).

## Decision

### The algorithm (orchestrator-side, per unit)

1. **Snapshot before prompting.** Before `herdr agent prompt`, record the progress file's current `## Log` line count (or whole-file hash). This is the baseline for "one new Log line."
2. **Send the prompt with `--wait`, and treat its return as "pane settled enough to read" — never as unit-done.** `--wait` matches `idle|done|blocked` after a 5s must-start-working window; it does not track turns, and transient idle between tool rounds can produce a false `idle`. (`agent prompt --help`; advice doc §Herdr CLI correction 4.)
3. **Poll the progress file every 30s.** The unit is complete only when BOTH hold:
   - `unit_done:` equals this unit, and
   - the `## Log` has ≥1 line beyond the step-1 snapshot (the per-unit Log line — schema owned by the progress-file ticket #5: one ≤20-word line, `pass`, class, why, next; referenced, not redesigned here).
   Both conditions come from advice item 6 verbatim: "poll the progress file for this unit's `unit_done` + one new Log line."
4. **Classify while polling:**
   - Progress file changed within the last 10 min → **still working**, keep polling regardless of what `--wait` returned.
   - `agent_prompt_stalled` from step 2 → the prompt never landed (no working/blocked state within 5s of submission). Read a short pane tail, re-check pane state, resubmit once; if it stalls again, treat as blocked.
   - No progress-file change for 10 min → **suspicious**, audit (step 5).
5. **Audit with `herdr agent explain <name>` plus a short pane tail (`herdr agent read <name> --lines 40`).** What the audit changes:
   - `explain` shows `working` (or the tail shows an in-flight turn) → the idle/done reading was transient; keep polling, do **not** re-prompt (a duplicate prompt mid-turn is how you get double work).
   - `explain` shows `idle`/`done` and the tail shows a finished unit that never stamped `unit_done`/Log → re-prompt once with a stamp-only delta: "Stamp `unit_done: <unit>` and append your Log line to <progress-file>; change nothing else."
   - `explain` shows `blocked` → escalation path (step 6).
6. **Escalate to the human (leave the pane `blocked`, stop polling this unit) when any of:**
   - the pane is `blocked` (matches the existing `copy_agreed: no` posture, step 8),
   - 45 min with no progress-file change and no `working` state in `explain`,
   - a stamp-only re-prompt was already sent and the stamp still didn't land within 10 min.
   Otherwise keep waiting — the default is patience, because a false escalation costs the human's attention while a false wait costs only poll cycles.
7. On completion, proceed per the Units table `next` field (existing steps 2/10).

### Exact `SKILL.md` patch text

Target: `skills/ship-herdr/SKILL.md`, steps 7 and 9, **as they read in the current working tree** (the uncommitted drift that the "Commit the uncommitted ship* baseline" ticket makes canonical). Step 7 line is `7. Prompt from [prompt.md](prompt.md) with `--wait` (`herdr agent prompt --help`).`; step 9 is `9. **Unit complete:** the progress file has `unit_done` for this unit. Diagnose a stall with a short pane tail; the progress file is the boundary.`

```diff
--- a/skills/ship-herdr/SKILL.md
+++ b/skills/ship-herdr/SKILL.md
@@
-7. Prompt from [prompt.md](prompt.md) with `--wait` (`herdr agent prompt --help`).
+7. Prompt from [prompt.md](prompt.md) with `--wait` (`herdr agent prompt --help`). First note the progress file's Log line count. `--wait` returning means the pane settled enough to read — never that the unit is done.
@@
-9. **Unit complete:** the progress file has `unit_done` for this unit. Diagnose a stall with a short pane tail; the progress file is the boundary.
+9. **Unit complete — the progress file is the boundary.** Poll it every 30s until BOTH `unit_done` is this unit AND the Log has one new line since the prompt. File changed within 10 min → still working. `agent_prompt_stalled` → the prompt never landed; tail the pane, resubmit once. No file change for 10 min → audit: `herdr agent explain <name>` + `agent read --lines 40`. Explain shows working → keep polling, don't re-prompt. Finished but unstamped → re-prompt once: "stamp `unit_done` + your Log line, nothing else." Leave the pane `blocked` for the human on: pane blocked, 45 min with no file change and no working state, or a second missing stamp.
```

The rest of the file is unchanged; step 10's loop bound (`Loop 2–9`) already covers the new step 9.

## Rationale

- **Boundary = `unit_done` + one new Log line, both required.** Advice item 6 states exactly this pair (advice doc line 75). The Log-line half is not redundant with `unit_done`: #102 occupants stamped `unit_done` prematurely (implement stamped at Brief stage, before any product code — advice doc §#102 autopsy), and units repeat by name (review ran 3×), so a bare `unit_done: review` can be stale or early. The new-Log-line requirement forces proof that *this* pass ran to its end. The Log line's content schema (`pass`, class, why, next, ≤20 words) is deliberately **not** restated here beyond a pointer — ticket #5 owns it; the composition point is only "count lines before prompting, require +1 after."
- **`--wait` demoted to a settle signal, kept in the flow.** `--wait` is still useful — it blocks the orchestrator until there is something worth reading — but its return value carries no turn information (`agent prompt --help`: "It does not track turns: if the agent is already working, that active turn's completion may match"). The false-done mechanism (Cursor idle between tool rounds) is plausible-but-unproven per advice doc correction 4, which is exactly why the boundary must not depend on it: we don't need the mechanism proven to justify distrusting a signal that was never designed to mean unit-done.
- **Poll cadence 30s.** A progress-file read is a local file stat/read — no Herdr call, no pane interaction — so it is nearly free, and 30s is far below any real unit duration (#102's cheapest unit was a 7-minute fix pass — advice doc §9). Faster polling buys nothing; slower polling delays the loop's cheapest transition.
- **10 min "no file change" → suspicious.** Deliberately chosen, not sourced (advice item 2's "pick your own number deliberately" applies to thresholds generally). Real units run many minutes without touching the progress file — Evidence is written near the end — so the audit trigger must be well above normal working stretches; 10 min of total silence is past that for every unit type seen in #102, while still catching a wedged occupant within a fraction of a unit's budget.
- **45 min hard ceiling.** Also deliberately chosen. #102's full review battery (3 passes × 2 turns + extras — advice doc §Skill-file errors, correcting "five-pass") fit well inside this per unit; 45 min of *no file change and no working state* means the occupant is dead or hung, not slow. The conjunction (no file change **and** `explain` ≠ working) is what makes escalation safe: either alone is not enough.
- **`agent explain` is the audit tool, paired with a pane tail.** `herdr agent explain --help` describes it as "Explain agent detection state" — it answers *why Herdr reads the pane as idle/done/blocked*, which is precisely the question when a `--wait` reading is suspicious (advice item 6: "use `agent explain` to audit suspicious idle readings"). The pane tail (`agent read --lines 40`) complements it with what the occupant actually did last; the existing step 9 already prescribed "a short pane tail," so this keeps that instinct and gives it a decision procedure. What the audit changes is made explicit because the two failure modes need opposite responses: transient idle → **wait** (re-prompting mid-turn duplicates work — #102's byte-identical double review prompt shows the cost, advice doc §#102 autopsy); finished-but-unstamped → **one stamp-only re-prompt**, and only one, because a second missing stamp means the occupant won't self-report and the human should look.
- **`agent_prompt_stalled` handling.** Per `agent prompt --help`, this fires when no working/blocked state is observed within 5000ms of an accepted submission — i.e., the prompt likely never started a turn. Resubmitting once is safe because nothing ran; a second stall means the pane itself is the problem, so it routes to the blocked/human path rather than a resubmit loop.
- **Escalate-vs-wait default is "wait."** Three explicit escalation triggers (blocked, hard ceiling, second missing stamp) and everything else keeps polling. This follows HumanLayer factor 8 ("own your control flow" — cited in advice doc §Methodology) in the specific sense that the orchestrator, not the model's signal, decides; and it matches the advice doc's correction of the "~3 failures" over-attribution — no magic retry counts, only stated conditions.
- **Placement: rewrite step 9 in place, one clause added to step 7.** The ticket names "step 9 territory," and step 9 already declares "the progress file is the boundary" — the patch turns that slogan into the algorithm without renumbering (step 10's `Loop 2–9` still fits). The step-7 clause ("never that the unit is done") puts the warning at the point of temptation, where `--wait` is introduced. Keeping it in `SKILL.md` rather than a new file matches the skill's terse single-file style and the fact that only the orchestrator chat reads it.

## Sources

- Advice doc: item 6 (line 75), §Herdr CLI claims + correction 4 (lines 26, 36), §#102 autopsy premature `unit_done` and double review prompt (lines 14–16), §Skill-file errors battery correction (line 49), §9 cheap-fix-pass timing (line 81), item 2 "pick your own number" (line 71), §Methodology factor-8 + over-attributions (lines 63–64).
- Repo: `skills/ship-herdr/SKILL.md:22,24` (working tree — steps 7 and 9; drift vs committed main confirmed via `git diff`), `skills/ship/progress.md:7` (current `unit_done` field), `skills/ship-herdr/prompt.md` (untracked; the prompt the boundary gates on).
- Herdr CLI (live `--help`, binary `0.9.0-preview.2026-09-08`): `agent prompt` (idle|done|blocked matcher, 5s stall → `agent_prompt_stalled`, "does not track turns"), `agent explain` ("Explain agent detection state"), `agent wait`, `agent read --lines`.
- Cross-ticket: vishalkdotcom/skills#5 owns the `## Log` line schema and the "`unit_done` written once, last, after Evidence" ordering this algorithm relies on.
