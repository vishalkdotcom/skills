# Ship core — merge-ready gates

Shared reference for `ship-django`, `ship-next`, `ship-cra`, and `ship-lake`. Repo skills point here for the tail gates.

## Active branch

One **active** WIP branch per WPM ticket per git repo. Vault **slices** (issues under the ticket folder) share that branch — they are not branch units.

**Base:** `dev` for wovo-django and wovo_frontend; `master` for click-lake (or `dev` when that exists as the shared default).

**Convention name:** `vishalk/` + the vault ticket folder slug lowercased  
(e.g. folder `WPM-3552-score-column-means-brand-metabase` → `vishalk/wpm-3552-score-column-means-brand-metabase`).  
`wovo_frontend` is one monorepo (`next/` + `frontend/`) → one branch for both packages.

**Resolve before implement (in order):**

1. Ticket README **Branches** table row for this repo, if present and that ref still exists.
2. Else convention name (local or `origin`).
3. Else (rare) any single `vishalk/wpm-xxxx-*` for this ticket key; if several unmerged tips, ask which is active.

| Situation | Action |
| --------- | ------ |
| Active WIP found (local/remote, PR not merged) | Check it out and continue — do **not** `checkout -b` from a slice issue slug |
| None, or prior PR for this ticket already merged | Create convention name (or `vishalk/wpm-xxxx-<short-purpose>` after a merge) from an updated base |
| User asks for an extra concurrent branch | Only then |

**Branches table** (ticket README — write or update when creating / switching active branch):

```markdown
## Branches

| Repo | Branch |
|------|--------|
| wovo-django | `vishalk/wpm-3552-score-column-means-brand-metabase` |
```

**Wrong base / wrong branch:** stash → pull base → check out or create the **active** branch → stash pop. Do not implement on `dev`/`master` or a slice-named fork while an active ticket branch exists.

**Done when:** HEAD is the ticket’s active branch for this repo, based on updated base when the branch was created.

## Merge-ready

A branch is **merge-ready** when Validate and Review completion criteria are both met. Commit opens only then.

## Review

Invoke `/code-review` against the ticket/spec or branch merge-base (e.g. `dev...HEAD`).

**Done when:** Standards and Spec reports produced; every finding fixed or listed for the user; tests still green after fixes.

## Commit

Final step. Follow git safety — no destructive git without explicit user consent.

**Opens when:** branch is merge-ready.

## Early finalize

When the user requests a branch or commit before gates pass: complete remaining gates, then fulfill the request. Waive Review only when the user explicitly accepts shipping without review.
