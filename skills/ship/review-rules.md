# Review rules

Shared by `ship-review` (classify) and `ship-implement` (clear findings).

## Battery

Against the uncommitted diff (`git diff HEAD`). Prefer parallel subagents.

| Pass | How |
| --- | --- |
| Standards + Spec | `/code-review`. Spec axis: the ticket and parent spec. Standards axis: `CODING_STANDARDS.md` (and other repo standards files). |
| Thermo-nuclear | Cursor subagents `thermo-nuclear-review-subagent` and `thermo-nuclear-code-quality-review-subagent`. `Full Repository Path: <repo root>`. `Diff: uncommitted changes`. |
| Bugbot | Cursor `bugbot` (or `/review-bugbot`). Same diff contract. |

Security review only when the human asks or the diff is security-sensitive. Dirty files outside the ticket: `Diff: natural language` listing only this ticket's paths.

A missing pass (tooling absent) is recorded on the progress file as untested.

## Severity

| Class | Meaning | Before commit |
| --- | --- | --- |
| **Hard** | Incorrect behavior, AC/spec miss, security issue, standards violation | Must clear |
| **Judgement** | Real smell or inconsistency — including workarounds and imperative React the standards ban | Must clear |
| **Nit** | Format/lint noise tooling already enforces | May drop |

Reviewer labels like "non-blocking" or "later" are **judgement** unless they are a nit. Clear in this diff, or scope-wall to the human. Filing a follow-up ticket does not clear a finding.

**Scope wall:** when the proper fix belongs to a different open ticket or spec AC, stop and ask the human — expand now or hold (no commit).

**Promote recurring pain:** when the same judgement finding recurs across ships, fold the lesson into the matching file behind `CODING_STANDARDS.md`.

The reviewer writes findings only. The writer (implement unit) edits.
