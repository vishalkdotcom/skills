# Claim and gate

First write of a fresh ticket. `<n>` is the ticket number. `gh` flags: [tool-calls.md](tool-calls.md).

1. Claim: `gh issue edit <n> --add-assignee "@me"` — quote `"@me"` on PowerShell.
2. `gh issue view <n> --json state` — if `CLOSED`, stop.
3. `gh issue view <n>` — if any issue in **Blocked by** is still open, stop and name it.

**Done when:** you are the assignee, the issue is open, and no open blocker remains.
