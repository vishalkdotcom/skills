# Ship core — merge-ready gates

Shared reference for `ship-django`, `ship-next`, `ship-cra`, and `ship-lake`. Repo skills point here for the tail gates.

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

## Wrong branch

Move WIP onto `vishalk/wpm-xxxx-…` from an updated base before implementing: stash → pull base → new branch → stash pop.
