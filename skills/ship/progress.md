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
