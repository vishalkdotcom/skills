# Research: Progress file as append-only memory (ticket #5)

Decision ticket: `vishalkdotcom/skills#5`. Source of truth: `awesomeapps/docs/agent/ship-herdr-loop-102-validated-advice.md` ("advice doc"), final advice item 3 and §"Methodology attributions".

## Decision in one line

Adopt the **append-only journal** for a new `## Log` section, **combined with Anthropic's actual mitigation in the form that applies here**: minimal mutable state (write-once Brief, Findings = open items only, `unit_done` written once, last) plus restricted edits — with git as the ledger at the *code* level, not for the file itself.

## Why not pure "Anthropic actual" and why not pure "journal"

The doc flags "append-only journal, never rewrite earlier bullets" as a **reasonable extrapolation, not Anthropic's stated rule**; Anthropic's actual mitigation is JSON over Markdown, restricted edits, and git as the ledger (advice doc §Methodology attributions, over-attribution (a); [Anthropic long-running harness](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)). Applying their three levers to this loop:

1. **JSON over Markdown — rejected.** The progress file is written and read by Cursor occupants whose entire skill surface is Markdown, and by the human at a glance between units. A JSON file would also not fix the observed failure: #102's problem was not parse errors, it was lost history and premature `unit_done` stamps.
2. **Restricted edits — adopted, and it *is* the schema.** Write-once Brief, Findings-as-open-items-only, and `unit_done`-once-last are exactly "restricted edits" expressed as schema rules. This is Anthropic's real mitigation and it carries most of the weight.
3. **Git as the ledger — adopted at the code level, impossible at the file level.** The progress file lives at `.scratch/ship-<ticket>.md`, **gitignored** (`skills/ship/SKILL.md:34`: "Path: `.scratch/ship-<ticket>.md` in the repo (gitignored)"). Git cannot be the ledger for a file git does not track; the per-unit commits ship already makes are the durable code ledger, and each Log line's `pass`/`next` fields reference the unit that produced them. Because the file's own history has no git backing, the **in-file append-only Log is the only cross-window history that survives a fresh occupant** — which is exactly the hole the extrapolated journal rule fills (advice doc, final advice item 3).

So: the journal form wins for the Log *because* the ledger lever is unavailable for this file; the mutable-state-minimization levers win everywhere else. Both halves are deliberate, not a hedge.

## Full proposed `skills/ship/progress.md`

Composes with the uncommitted baseline (Brief with `ac`/`layers`/`lock`/`seams`, `copy_agreed`, no `plan_agreed`) read from the working tree; adds the append-only rules header and the `## Log` section. Nothing else from the baseline changes.

```markdown
# ship <N>

Append-only memory across units. Rules:

- Brief is write-once — never edit after first fill.
- Findings holds open items only; a cleared finding leaves the section (the Log keeps its record).
- Log is append-only — one line per finished unit; never edit, reorder, or delete earlier lines.
- `unit_done` is written once, last, after Evidence is filled.

- ticket: https://github.com/<owner>/<repo>/issues/<N>
- branch:
- unit_done: implement | validate | review | pr
- next: validate | review | implement | pr | human-qa
- copy_agreed: yes | n/a | no

## Brief

Exists before product code.

- ac: (every AC quoted from the ticket)
- layers: (paths this ticket touches)
- lock: (prototype path the ticket names, or n/a)
- seams: (paths the explore subagent returned)

## Evidence

- acceptance: (each AC — pass | fail | untested, with path or command)
- commands: (script + exit code)
- screenshots: (paths, or n/a)
- verified vs claimed: (what you re-ran this unit vs what a previous file said)

## Findings

(review unit only; empty otherwise. Open items only — cleared findings leave this section.)

- hard:
- judgement:
- nit:
- scope_wall: (ask the human — expand or hold)

## Log

Append-only, newest at the bottom. One ≤20-word line per finished unit: `unit · pass first|fix <n>|review <n> · class · why · next`. `class` is the worst finding class the unit left (hard | judgement | nit | none). Never touch earlier lines.

- e.g. `review · pass review 1 · judgement · nested-list markup not in AC · implement`

## Tree

- dirty paths:
- HEAD:

## Next prompt

(pasteable: skill name, ticket, this file's path)
```

## Rationale per choice

- **Rules header at the top** — the file's own edit contract must be the first thing an occupant reads; #102 showed occupants rewrite Markdown freely (Anthropic harness post: models overwrite Markdown; advice doc §Methodology attributions). Placing the four rules above every field makes them unmissable.
- **Brief stays write-once with the uncommitted ac/layers/lock/seams fields** — required by the ticket; the baseline is what `ship-implement/SKILL.md:24` already gates "Done when" on. Write-once is the restricted-edit lever (advice doc, final advice item 3).
- **Findings = open items only** — cleared findings leaving the section is what makes the **stable rule** (advice doc, final advice item 1: "a finding cleared in the Log stays cleared") checkable: review N+1 diffs its findings against the Log, not against a stale Findings pile. This directly serves the flip-flop fix that ticket #7 owns.
- **Log line format `unit · pass · class · why · next`, ≤20 words** — the ticket names pass/class/why/next; the `pass first|fix <n>|review <n>` vocabulary matches the prompt slots in advice item 4 (`Pass: first|fix <n>|review <n>`), so the Log line and the occupant prompt use one shared grammar. `class` (worst class left) gives the circuit breaker (advice item 2: "2 review units whose only findings are same-path judgement/nit") something greppable to count.
- **`unit_done` written once, last, after Evidence** — #102 autopsy: implement stamped `unit_done` at Brief/branch stage, before product code (advice doc §#102 autopsy). Making it the terminal write means a fresh occupant can trust `unit_done` + one new Log line as the completion boundary, which is what `ship-herdr/SKILL.md:24` polls for (advice item 6).
- **Tree and Next prompt stay mutable** — they are per-unit snapshots, not memory; minimizing mutable state does not mean freezing the one section that must reflect *now*. History lives in the Log.
- **JSON form rejected, git-as-file-ledger rejected** — see "Why not" above; both are deliberate departures from the letter of Anthropic's mitigation while adopting its substance (advice doc §Methodology attributions over-attribution (a)).

## Migration notes for in-flight progress files

In-flight files were written under the committed HEAD schema (`plan_agreed` field, no Brief, no Log) or the uncommitted baseline (Brief, no Log). Migrate in place, never rewrite history:

1. **Keep the file; append, don't reformat.** Do not reorder or delete existing content — the migration follows the same append-only discipline the new schema imposes.
2. **Header:** add the four rules block at the top. Delete a stale `plan_agreed:` line if present (the uncommitted baseline already dropped it; `copy_agreed` covers the blocking semantics). Leave every other filled field untouched.
3. **Brief:** if absent and product code already exists, fill it **once** from the ticket (`gh issue view <N>`), marking unknowns `migrated: unknown` (e.g. `lock: migrated: unknown`) rather than re-running the explore subagent — the Brief's gates are already past, so its remaining job is AC visibility for later units.
4. **Log:** seed one reconstructed line per already-finished unit (from the file's own `unit_done`/history and the branch's commit log), tagged `migrated`, e.g. `- implement · pass first · none · migrated: pre-Log unit · validate`. These seed lines are the only lines a migration may write retroactively; afterwards the append-only rule applies.
5. **Findings:** leave as-is — they are already open items. Any finding the writer believes is cleared gets cleared by the next implement fix pass and leaves the section normally; do not bulk-edit during migration.
6. **`unit_done`:** if the current file already carries a premature `unit_done` (the #102 failure mode), the next unit's first act is to verify Evidence is real for that unit; if it is not, clear `unit_done` and route `next` back to that unit. This is the one sanctioned rewrite, because a false `unit_done` poisons the completion boundary the herdr loop polls.

## Sources

- Advice doc `awesomeapps/docs/agent/ship-herdr-loop-102-validated-advice.md`: final advice items 1, 2, 3, 4, 6; §Methodology attributions (over-attribution (a)); §#102 autopsy (premature `unit_done`).
- `skills/ship/SKILL.md:34` (progress file path, gitignored); `skills/ship-herdr/SKILL.md:24` (progress file as completion boundary); `skills/ship-implement/SKILL.md:14,24` (Brief gates).
- Working-tree `skills/ship/progress.md` (uncommitted baseline: Brief ac/layers/lock/seams, `copy_agreed`, no `plan_agreed`); committed `HEAD:skills/ship/progress.md` (old schema for migration).
- [Anthropic, Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) (progress file + git as cross-window memory; models overwrite Markdown; JSON-over-Markdown / restricted edits / git ledger mitigations) — as verified and qualified by the advice doc.
