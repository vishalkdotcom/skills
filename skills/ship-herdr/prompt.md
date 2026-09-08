# Occupant prompt

Fill the angle brackets. One string to `herdr agent prompt <name> … --wait`.

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

On `Clear: Findings`, quote the findings to clear verbatim under `Findings:`.
On a re-validate after a fix pass, add `Re-run only: <commands>` (scoped, see below).

## Orchestrator rules

- **Claimed stub.** Fresh ticket: after claim-gate passes, write the progress file stub — the template's headers with the `ticket:` line filled and every other field blank — before starting the implement occupant. The occupant's Claim step then sees an existing progress file and skips claim-gate.
- **Pass numbering.** `fix <n>` and `review <n>` count from the progress file's Log: the nth fix pass, the nth review of this ticket.
- **Slot values per unit:**
  - implement, first run — `Pass: first`, `Clear: none`, `Session: new`
  - implement, fix pass — `Pass: fix <n>`, `Clear: Findings` (+ quoted findings), `Session: reuse` (bounded by the Rotation rule below)
  - validate, first run — `Pass: first`, `Clear: none`, `Session: new`
  - validate, re-validate after a fix pass — `Pass: fix <n>`, `Clear: Findings`, `Session: reuse`, plus `Re-run only: <scoped commands>`
  - review — `Pass: review <n>`, `Clear: none`, `Session: new`
  - pr — `Pass: first`, `Clear: none`, `Session: new`
- **Scoped re-validation.** A re-validate run executes only the commands the fix-pass diff can affect — the `check` and `typecheck` scripts `package.json` names, plus the test files at the ticket's seams — never the full CI battery. Browser QA re-runs only when the fix-pass diff touches UI routes or components (the existing condition in `ship-validate`).
- **Never in the prompt:** repo slug, claim-gate status, tool-calls path — the skill files and Herdr own those.
- **Rotation.** When the session-policy budget override rotates a reused implement/validate occupant, the fresh occupant gets `Session: new` + `Handoff: <path>` (the doc the outgoing occupant's `handoff` skill wrote, or an orchestrator-reconstructed one). Every other prompt is `Handoff: none`.
