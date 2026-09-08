# Ticket #6 — Occupant prompt slots (Pass/Clear/Session) and scoped re-validation

Branch: `research/prompt-slots`. Parent map: vishalkdotcom/skills#1.
Source of truth: `awesomeapps/docs/agent/ship-herdr-loop-102-validated-advice.md` ("advice doc" below, cited by line).

## Decision in one line

`skills/ship-herdr/prompt.md` shrinks to a 6-line template (skill path, ticket, progress file, Pass, Clear, Session) plus a short orchestrator-rules section; everything the skill files or Herdr already own leaves the prompt.

## Proposed `skills/ship-herdr/prompt.md` (full text)

```markdown
# Occupant prompt

Fill the angle brackets. One string to `herdr agent prompt <name> … --wait`.

```
Follow <unit-skill-path>.

Ticket: <url>
Progress file: <path>
Pass: first | fix <n> | review <n>
Clear: none | Findings
Session: new | reuse
```

On `Clear: Findings`, quote the findings to clear verbatim under `Findings:`.
On a re-validate after a fix pass, add `Re-run only: <commands>` (scoped, see below).

## Orchestrator rules

- **Claimed stub.** Fresh ticket: after claim-gate passes, write the progress file stub — the template's headers with the `ticket:` line filled and every other field blank — before starting the implement occupant. The occupant's Claim step then sees an existing progress file and skips claim-gate.
- **Pass numbering.** `fix <n>` and `review <n>` count from the progress file's Log: the nth fix pass, the nth review of this ticket.
- **Slot values per unit:**
  - implement, first run — `Pass: first`, `Clear: none`, `Session: new`
  - implement, fix pass — `Pass: fix <n>`, `Clear: Findings` (+ quoted findings), `Session: reuse` (bounded: rotate to `new` with a handoff doc if the occupant's context crosses the reuse budget — owned by the session-policy follow-up ticket)
  - validate, first run — `Pass: first`, `Clear: none`, `Session: new`
  - validate, re-validate after a fix pass — `Pass: fix <n>`, `Clear: Findings`, `Session: reuse`, plus `Re-run only: <scoped commands>`
  - review — `Pass: review <n>`, `Clear: none`, `Session: new` (always a new agent)
  - pr — `Pass: first`, `Clear: none`, `Session: new` (always a fresh occupant)
- **Scoped re-validation.** A re-validate run executes only the commands the fix-pass diff can affect — the `check` and `typecheck` scripts `package.json` names, plus the test files at the ticket's seams — never the full CI battery. Browser QA re-runs only when the fix-pass diff touches UI routes or components (the existing condition in `ship-validate`).
- **Never in the prompt:** repo slug, claim-gate status, tool-calls path — the skill files and Herdr own those.
```

## Rationale per choice

- **Drop `Repo:`, `Claim-gate:`, `Tool calls:` from the template.** Advice item 4: "drop the invariants the skill or Herdr already own (Repo, Claim-gate, Tool-calls)" (advice doc:73). Repo and `gh` retry rules are already referenced from `skills/ship-implement/SKILL.md:12` and `skills/ship/claim-gate.md:3`; claim-gate is step 3 of `skills/ship-herdr/SKILL.md` — the occupant never needs them as prompt input.
- **Keep the template to one unit slot + three pass slots.** Advice item 4 names exactly `Pass: first|fix <n>|review <n>`, `Clear: none|Findings`, `Session: new|reuse` (advice doc:73), matching the ticket. `<unit-skill-path>` already is a unit slot (advice doc:51), so it stays.
- **`Session:` values per unit.** Advice item 5: review always new, implement reuse for fix passes, validate reuse with delta prompts, PR always fresh (advice doc:74); independently mandated by `skills/ship-herdr/SKILL.md:20` and `skills/ship/SKILL.md:25,28`. First runs of implement/validate are `new` because their panes start as idle shells (`skills/ship-herdr/SKILL.md:20-21`).
- **Reuse is the bounded exception.** §9: fix-pass reuse is safe when the session is well under the context budget and the findings to clear are fully in context (advice doc:81); the threshold/rotation machinery is the follow-up session-policy ticket, so this file only names the escape hatch, not the mechanism.
- **Claimed stub after claim-gate.** Ticket requirement; advice item 4 (advice doc:73). The branch it enables is `skills/ship-implement/SKILL.md:18-20`: Claim's Done-when holds when "a progress file already exists". The failed run `78ab19c6` never wrote a progress file and burned ~106k tokens before dying (advice doc:15) — the stub is also the earliest proof-of-life on disk.
- **Fix-pass prompts quote the Findings verbatim.** Advice item 4 (advice doc:73). `skills/ship-implement/implement.md:3` already clears Findings and re-runs check/typecheck; quoting them in the prompt makes the delta explicit for a reused session instead of relying on stale context.
- **Scoped re-validation, not full CI.** Advice item 4: "re-validate runs only the commands the diff can affect (`check`, `typecheck`, ticket tests), not full CI" (advice doc:73); #102 ran the full CI battery three times (advice doc:16). `skills/ship-validate/SKILL.md:16` (run the repo's CI workflow in order) stays correct for the **first** validate; this rule narrows re-validate runs only, delivered via the `Re-run only:` line.
- **No `Handoff:` slot yet.** §9 proposes `Handoff: <path>` for rotated sessions (advice doc:82) — it belongs to the session-policy follow-up ticket this one blocks (#7); the slot list above is the ticket's authoritative set. Adding it later is a one-line append to the template.
- **"This chat stays in Agent. / The ticket is the approach." stays out of prompt.md.** It lives in `skills/ship-implement/SKILL.md:10`; putting it in the prompt was an attribution slip corrected in the advice doc (advice doc:51).

## Not in scope

- Editing `skills/ship-validate/SKILL.md` to distinguish first-validate from re-validate (full battery vs scoped) — the prompt carries the scope via `Re-run only:` until a skill-edit ticket lands.
- Context-budget tracking and handoff mechanics (advice doc §9) — follow-up ticket.
