# ship <N>

Fill every field. Point at GitHub, paths, and commands. `unit_done` and `next` are set at the end of each unit.

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

(review unit only; empty otherwise)

- hard:
- judgement:
- nit:
- scope_wall: (ask the human — expand or hold)

## Tree

- dirty paths:
- HEAD:

## Next prompt

(pasteable: skill name, ticket, this file's path)
