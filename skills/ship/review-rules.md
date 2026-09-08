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
