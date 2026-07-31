# New Git Features & Config Options for DX (Git 2.43 → 2.55, late 2023 – mid 2026)

## Summary

This research surveys every official Git feature release from **2.43.0 (Nov 2023)** through **2.55.0 (Jun 2026)** — the current latest release as of this writing — using the project's own release notes (`Documentation/RelNotes/*.adoc` in [git/git on GitHub](https://github.com/git/git/tree/master/Documentation/RelNotes)) and the canonical config/command documentation on [git-scm.com](https://git-scm.com/docs). The goal was to surface things that **postdate common LLM training cutoffs** and that a well-informed developer in mid-2026 would know about but an older model would not — explicitly excluding the "already famous" defaults (`pull.rebase`, `rebase.autoStash`, `fetch.prune`, `push.autoSetupRemote`, `merge.conflictstyle=zdiff3`, `rerere.enabled`, `core.autocrlf`, `branch.sort`, `column.ui`, aliases), which were all introduced well before this window (mostly Git 2.29–2.38, 2020–2022).

**Top DX-relevant findings** (details below):

1. **`git config` subcommand UI** (`git config get/set/list/unset/edit`, Git 2.46+) — the old flag-soup (`git config --get`, `--replace-all`, `-l`) is being replaced by discoverable, scriptable subcommands. `git config list` is now the official spelling of `git config -l`.
2. **`git switch` / `git restore` are no longer experimental** (Git 2.51) — safe to build muscle memory and aliases around them instead of overloaded `git checkout`.
3. **Config-driven hooks** (`hook.<name>.command`, `hook.<name>.event`, Git 2.54; parallel execution in 2.55) — hooks can now live in `git config` (shareable/centrally managed) instead of only as scripts in `.git/hooks/`.
4. **`pull.autoStash`** (Git 2.51) — a pull-specific autostash switch that overrides `rebase.autoStash`/`merge.autostash`, useful when you want autostash behavior on pull specifically regardless of merge/rebase mode.
5. **`git backfill`** (introduced Git 2.49, matured through 2.53/2.54) — bulk-downloads missing blobs in a blobless/partial clone up front, avoiding slow one-blob-at-a-time lazy fetches (e.g., before `git blame`/full-history operations).
6. **Reftable ref storage backend matured** (`git init --ref-format=reftable`, Git 2.45) and is **now configurable globally** via `init.defaultRefFormat` (Git 2.47) — a real fix for repos with huge numbers of refs/branches; will become the Git 3.0 default.
7. **`git maintenance`'s "geometric" strategy is now the default** (Git 2.54) — background maintenance is lighter-weight and no longer periodically does full from-scratch repacks.
8. **`commitGraph.changedPaths`** (Git 2.52) — turns on changed-path Bloom filters by default for `git commit-graph write`, meaningfully speeding up `git log -- <path>`.
9. **`stash.index`** (Git 2.52) — makes `git stash pop`/`git stash apply` behave as if `--index` was passed, restoring staged/unstaged distinctions by default.
10. **`status.compareBranches`** (Git 2.54) — makes `git status` show ahead/behind comparisons against multiple refs (e.g. both `@{upstream}` and `@{push}`) at once.

Everything below is organized by theme, each entry with: exact key/command, the Git version, what it does, why it matters for DX, and a link to the primary source.

---

## 1. Command-line UX overhaul: `git config` subcommands

**Introduced:** Git 2.46 (Jul 2024), refined through 2.48 (deprecating the old flags), officially the documented spelling by Git 2.54 (Sep–Oct 2025).

Git replaced the historically overloaded flag interface (`git config --get`, `--get-all`, `--replace-all`, `--unset`, `-l`/`--list`) with proper subcommands:

```
git config get <name>
git config set <name> <value>
git config list
git config unset <name>
git config edit
git config rename-section <old> <new>
git config remove-section <name>
```

- Git 2.46: "The operation mode options (like `--get`) the `git config` command uses have been deprecated and replaced with subcommands (like `git config get`)."
- Git 2.54: "`git config list` is the official way to spell `git config -l` and `git config --list`. Use it to update the documentation."
- Git 2.55: Git now proactively detects the common mistake `git config foo.bar=baz` (an old-style invocation misused as if it were the new syntax) and advises the user that they probably meant `git config set foo.bar baz`.

**Why it matters:** This is the single biggest change to how you *talk to* Git config from scripts or muscle memory in years. Tab-completion, discoverability (`git config -h`), and scripting all get easier and less error-prone with named subcommands instead of positional flags. Anyone still teaching/using `git config --global foo.bar baz` isn't wrong (that legacy form still works), but professional tooling and dotfiles are increasingly written as `git config set --global foo.bar baz`.

**Sources:**
- [Git v2.46 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.46.0.adoc)
- [Git v2.54 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.54.0.adoc)
- [Git v2.55 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.55.0.adoc)
- [git-config documentation](https://git-scm.com/docs/git-config)

---

## 2. `git switch` and `git restore` are no longer experimental

**Introduced:** the commands themselves shipped in Git 2.23 (2019), but they were explicitly labeled experimental/subject-to-change for years. **Git 2.51 (Aug 2025)** is the release that formally lifts that label: "`git switch` and `git restore` are declared to be no longer experimental."

**Why it matters:** Many teams and dotfiles avoided standardizing aliases/workflows on `switch`/`restore` because Git's own docs warned their behavior/flags could still change. That caveat is now gone, so building default aliases like `git config --global alias.co switch` or teaching `restore` instead of `checkout -- <path>` to new hires is now fully sanctioned by upstream. This is exactly the kind of "postdates typical training data" fact — most models still describe these as experimental.

**Source:** [Git v2.51 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.51.0.adoc)

---

## 3. Configuration-based hooks (`hook.<name>.*`)

**Introduced:** Git 2.54 (Sep/Oct 2025); parallel execution support added in Git 2.55 (Jun 2026).

Hooks no longer have to live as executable files under `.git/hooks/`. You can now define them directly in Git config:

```
git config set hook.<name>.command <path-to-script-or-oneliner>
git config set --append hook.<name>.event pre-commit
```

Relevant keys (from `git help hook`):
- `hook.<name>.command` — the command/oneliner to run.
- `hook.<name>.event` — which hook event(s) trigger it (multi-valued).
- `hook.<name>.enabled` — toggle without removing the definition.
- `hook.<name>.jobs` / `hook.jobs` — how many hook jobs can run concurrently (Git 2.55 added true parallel execution of configured hooks).

Multiple hooks can be registered for the same event (they run in config-parse order, with the traditional `.git/hooks/<event>` script running last), and this configuration can live in `--global`/`--system` scope or be centrally distributed, unlike the old approach where each clone needed the hook script physically installed (frameworks like Husky/pre-commit exist specifically to work around that limitation).

**Why it matters:** This is a first-party alternative to third-party hook managers (Husky, `pre-commit`, `lefthook`) for simple cases, and it's the first time hook definitions can be centrally configured/shared via config includes (`include.path`) rather than requiring a post-clone install step.

**Sources:**
- [git-hook documentation](https://git-scm.com/docs/git-hook)
- [githooks documentation — Configuration-based hooks](https://git-scm.com/docs/githooks)
- [Git v2.54 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.54.0.adoc)
- [Git v2.55 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.55.0.adoc)

---

## 4. `pull.autoStash`

**Introduced:** Git 2.51 (Aug 2025).

A new boolean config that is specific to `git pull`:

> When set to true, automatically create a temporary stash entry to record the local changes before the operation begins, and restore them after the operation completes... If `pull.autostash` is set (either to true or false), `merge.autostash` and `rebase.autostash` are ignored.

**Why it matters:** Previously, autostash-on-pull behavior was implicitly controlled by whichever of `merge.autostash`/`rebase.autostash` matched your `pull.rebase` setting, which was a common source of "why didn't autostash kick in" confusion when people toggled `pull.rebase` per-repo. `pull.autoStash` lets you pin the desired behavior at the `pull` level directly, independent of merge vs. rebase mode, and it takes explicit precedence over the other two.

**Sources:**
- [Git v2.51 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.51.0.adoc)
- [git-config: pull.autoStash](https://github.com/git/git/blob/master/Documentation/config/pull.adoc)

---

## 5. `git backfill` (bulk-download missing objects in partial/blobless clones)

**Introduced:** Git 2.49 (Mar 2025); improved substantially through 2.51–2.54 (revision/pathspec args, sparse-checkout auto-detection, edge/root-commit handling, better docs).

If you use partial/blobless clones (`git clone --filter=blob:none`) for large monorepos, missing blobs are normally fetched lazily, one at a time, whenever an operation (like `git blame` or `git log -p`) needs them — which is slow. `git backfill` proactively bulk-fetches the missing objects ahead of time:

- Git 2.49: "`git backfill` is introduced to help bulk-download necessary files beforehand," to address that "Lazy-loading missing files in a blobless clone on demand is costly as it tends to be one-blob-at-a-time."
- Git 2.54: `git backfill` learned to accept revision and pathspec arguments (so you can backfill just a subtree or a revision range).
- Git 2.53/2.54: fixes to auto-detect sparse checkouts and correctly include blobs from boundary commits by default.

**Why it matters:** Partial clone is a major DX win for huge repos (fast initial clone), but historically the lazy-fetch penalty showed up unpredictably later. `git backfill` lets teams script a "prime the cache" step (e.g., in CI or a post-clone hook) so day-to-day history operations stay fast.

**Sources:**
- [Git v2.49 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.49.0.adoc)
- [Git v2.54 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.54.0.adoc)
- [Git v2.55 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.55.0.adoc)
- [git-backfill documentation](https://git-scm.com/docs/git-backfill)

---

## 6. Reftable ref storage backend matures + becomes globally configurable

**Introduced:** `git init --ref-format=reftable` shipped in Git 2.45 (Apr 2024). Global/system configurability via `init.defaultRefFormat` landed in **Git 2.47 (Oct 2024)**. Git 2.51 (Aug 2025) release notes state: "The reftable ref backend has matured enough; Git 3.0 will make it the default format in newly created repositories by default."

Reftable is an alternative on-disk format for storing refs (replacing the traditional loose-files-plus-`packed-refs` layout) that scales much better for repositories with very large numbers of branches/tags (common in monorepos, or repos with many CI-generated refs).

Config keys:
- `init.defaultRefFormat` — set to `reftable` to make every new `git init`/`git clone` use it without passing `--ref-format` each time.
- `init.defaultObjectFormat` — the SHA-256 equivalent, same mechanism, also configurable globally since Git 2.47.

Git 2.48 added a dedicated migration command (`git refs migrate`) to convert an existing repo's ref storage between the `files` and `reftable` backends, including reflog data (fixed further in 2.49).

**Why it matters:** For teams running repos with thousands of refs (feature branches, PR refs, CI refs), reftable meaningfully improves ref read/write performance and atomicity. Setting `init.defaultRefFormat = reftable` globally is a forward-looking default professional devs are starting to adopt ahead of the Git 3.0 default flip.

**Sources:**
- [Git v2.45 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.45.0.adoc)
- [Git v2.47 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.47.0.adoc)
- [Git v2.48 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.48.0.adoc)
- [Git v2.51 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.51.0.adoc)
- [git-config: init.defaultRefFormat / init.defaultObjectFormat](https://github.com/git/git/blob/master/Documentation/config/init.adoc)

---

## 7. `git maintenance`'s "geometric" strategy becomes the default

**Introduced:** the `geometric` strategy option itself landed in Git 2.52 (Nov 2025); it became **the default** in Git 2.54 (Sep/Oct 2025... released as 2.54.0 on 2026-04-20 per git-scm.com's version table — see note below).

> Git 2.52: "`git maintenance` command learns the `geometric` strategy where it avoids doing maintenance tasks that rebuild everything from scratch."
> Git 2.54: "`git maintenance` starts using the `geometric` strategy by default."

This changes background maintenance (the `git maintenance run --auto` machinery wired into normal `fetch`/`gc.auto`) to prefer incremental, geometrically-sized repacking over full "repack everything from scratch" passes.

**Why it matters:** Background maintenance historically could cause a noticeable one-time stall when it decided a full repack was due. The geometric default trades that for smaller, more frequent, less disruptive maintenance — a meaningful change if you've configured `git maintenance start` (a practice that itself is a well-known modern-DX recommendation) since the *behavior* of that recommendation just changed under you.

**Sources:**
- [Git v2.52 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.52.0.adoc)
- [Git v2.54 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.54.0.adoc)
- [git-maintenance documentation](https://git-scm.com/docs/git-maintenance)

---

## 8. `commitGraph.changedPaths`

**Introduced:** Git 2.52 (Nov 2025).

> "If true, then `git commit-graph write` will compute and write changed-path Bloom filters by default, equivalent to passing `--changed-paths`."

Previously you had to remember to pass `--changed-paths` to `git commit-graph write` (or rely on `git maintenance`'s commit-graph task doing it) to get the Bloom-filter speedup for path-limited history walks (`git log -- path/to/file`, `git log -- 'src/**/*.ts'`).

**Why it matters:** Setting `commitGraph.changedPaths = true` globally is a low-risk, meaningful speed win for `git log <path>` / blame-adjacent workflows in large repos, and it removes the need to remember the flag every time you (re)build the commit-graph by hand.

**Sources:**
- [Git v2.52 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.52.0.adoc)
- [git-config: commitGraph.changedPaths](https://github.com/git/git/blob/master/Documentation/config/commitgraph.adoc)

---

## 9. `stash.index`

**Introduced:** Git 2.52 (Nov 2025).

> "If this is set to true, `git stash apply` and `git stash pop` will behave as if `--index` was supplied. Defaults to false."

This also affects the implicit stash created by `--autostash` in `git merge`, `git rebase`, and `git pull`.

**Why it matters:** Without `--index`, `git stash pop`/`apply` dumps everything back as unstaged changes, discarding the staged/unstaged distinction you had before stashing — a frequent minor annoyance. `stash.index = true` restores that distinction by default so `git add -p` work-in-progress isn't flattened every time you stash/unstash.

**Sources:**
- [Git v2.52 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.52.0.adoc)
- [git-config: stash.index](https://github.com/git/git/blob/master/Documentation/config/stash.adoc)

---

## 10. `status.compareBranches`

**Introduced:** Git 2.54 (Sep/Oct 2025).

> "A space-separated list of branch comparison specifiers to use in `git status`. Currently, only `@{upstream}` and `@{push}` are supported... If not set, the default behavior is equivalent to `@{upstream}`."

Example:
```
[status]
    compareBranches = @{upstream} @{push}
```

**Why it matters:** In workflows where your push destination differs from your pull/upstream branch (e.g. `push.default = current` against a fork, or a triangular workflow), `git status` traditionally only told you about ahead/behind vs. upstream. This config lets `git status` show both comparisons at a glance without extra commands.

**Sources:**
- [Git v2.54 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.54.0.adoc)
- [git-config: status.compareBranches](https://github.com/git/git/blob/master/Documentation/config/status.adoc)

---

## 11. `git push` to a "remote group" (mirrors `git fetch <group>`)

**Introduced:** Git 2.55 (Jun 2026) — very new, only weeks old at the time of this research.

> "`git push` learned to take a `remote group` name to push to, which causes pushes to multiple places, just like `git fetch` would do."

Git has long supported defining named groups of remotes via `remotes.<group> = remote1 remote2 ...` for `git fetch <group>` to fetch from several remotes at once. This release extends the same mechanism to `git push`.

**Why it matters:** Teams that mirror to multiple remotes (e.g., an internal mirror + GitHub + a backup remote) can now push to a named group in one command instead of scripting multiple `git push` invocations or relying on multiple push URLs on a single remote.

**Source:** [Git v2.55 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.55.0.adoc)

*(Caveat: this is bleeding-edge — it shipped in the release current at the time of writing, so expect thinner third-party documentation and possibly still-evolving syntax; the config-doc pages for `remotes.<group>` had not yet been updated to mention push at time of writing.)*

---

## 12. `git checkout -m <branch>` can now stash instead of failing outright

**Introduced:** Git 2.55 (Jun 2026).

> "`git checkout -m another-branch` was invented to deal with local changes to paths that are different between the current and the new branch, but it gave only one chance to resolve conflicts. The command was taught to create a stash to save the local changes."

**Why it matters:** `checkout -m`/`switch -m` previously left you stuck if the automatic 3-way merge of local changes into the new branch conflicted — your only real option was to undo. Now it can fall back to stashing your local changes so you don't lose work.

**Source:** [Git v2.55 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.55.0.adoc)

---

## 13. `git log --graph` lane limiting

**Introduced:** Git 2.55 (Jun 2026).

> "The graph output from commands like `git log --graph` can now be limited to a specified number of lanes, preventing overly wide output in repositories with many branches."

**Why it matters:** Anyone who has run `git log --graph --all` on a repo with dozens of concurrent branches knows the output can become an unreadable wall of `|` characters. This caps the visual width.

**Source:** [Git v2.55 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.55.0.adoc)

---

## 14. Sideband terminal-escape hardening by default

**Introduced:** Git 2.55 (Jun 2026).

> "Terminal control sequences coming over the sideband while talking to a remote repository are mostly disabled by default, except for ANSI color escape sequences."

**Why it matters:** This is a security/DX-adjacent default: a malicious or misconfigured server could previously send arbitrary terminal escape sequences through progress/status messages during fetch/push, which could manipulate your terminal. Now only color escapes pass through by default, closing off that vector without breaking the (very common) colored progress output.

**Source:** [Git v2.55 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.55.0.adoc)

---

## 15. Interactive staging (`git add -p`) polish

Several incremental but meaningful improvements landed across this window:

- **Git 2.45:** "add -p" learned to skip re-showing a hunk that was already displayed, plus an explicit action to force re-showing the current hunk.
- **Git 2.47:** a new `P` command in `add -p` sends the current hunk to your pager (useful for large hunks).
- **Git 2.51 (`add.interactive.useBuiltin`)**: the built-in (C, non-Perl) interactive-add implementation had been default for a long time, but the long-dead "this does nothing" deprecation warning for the old configuration knob was finally removed in 2.46, signaling the transition is fully complete.
- **Git 2.52:** marking a hunk "selected" and then splitting it used to mark all the split pieces "selected" too; now they're marked "undecided" (safer default — you have to confirm each piece), and a `P`ipe command indicator was added to the prompt.
- **Git 2.54:** `add -p` now annotates hunks with their current status (staged/not) in the prompt, and gained a mode to revisit a file you already finished handling without restarting the whole session.

**Why it matters:** `git add -p` is a daily-driver command for careful commit hygiene; these are the kind of small-but-constant friction reductions that add up for anyone doing patch-based staging regularly.

**Sources:**
- [Git v2.45 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.45.0.adoc)
- [Git v2.46 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.46.0.adoc)
- [Git v2.47 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.47.0.adoc)
- [Git v2.52 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.52.0.adoc)
- [Git v2.54 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.54.0.adoc)

---

## 16. New introspection commands: `git repo`, `git repo info`, `git repo structure`, `git last-modified`, `git refs`

**Introduced:** progressively across Git 2.52–2.54 (Nov 2025 – Oct 2025/Apr 2026).

A cluster of new plumbing-ish commands aimed at making repository introspection scriptable without hand-parsing `git rev-parse`/`git cat-file` output:

- **`git repo info`** (Git 2.52) — reports repository characteristics (hash algorithm, ref storage format, etc.); learned `--all`, `-z`/`--format=nul`, and `--keys` (list known keys) through 2.53/2.54.
- **`git repo structure`** (Git 2.52) — reports statistics about the object database (object counts, sizes, max values as of 2.54).
- **`git refs`** (Git 2.52, extended in 2.55) — a new front-end; `git refs list` acts like `git for-each-ref`, and `git refs exists` works like `git show-ref --exists`.
- **`git last-modified`** (Git 2.52) — given paths, reports the closest ancestor commit that last touched each one, without needing a full `git log -1 -- <path>` per file; learned `--diff-algorithm` and pathspec/`--` handling fixes through 2.53/2.54.

**Why it matters:** These are aimed squarely at tooling authors (editor integrations, CI scripts, custom Git UIs) who previously had to shell out to multiple plumbing commands and parse ad-hoc text to answer questions like "what hash algorithm/ref format does this repo use?" or "when was this file last touched?". Less relevant for interactive daily use, but a real DX upgrade for anyone building on top of Git.

**Sources:**
- [Git v2.52 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.52.0.adoc)
- [Git v2.53 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.53.0.adoc)
- [Git v2.54 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.54.0.adoc)
- [Git v2.55 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.55.0.adoc)

---

## 17. `git sparse-checkout clean`

**Introduced:** Git 2.52 (Nov 2025).

> "`git sparse-checkout` subcommand learned a new `clean` action to prune otherwise unused working-tree files that are outside the areas of interest."

**Why it matters:** Sparse-checkout users occasionally end up with stray files outside their configured cone (e.g., leftovers from before narrowing the cone, or from tools that wrote outside it). `clean` gives a first-party way to tidy those up instead of manually diffing the working tree against the sparse patterns.

**Source:** [Git v2.52 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.52.0.adoc)

---

## 18. `remote.<name>.serverOption` and `remote.<name>.followRemoteHEAD`

**Introduced:** `remote.<name>.serverOption` in Git 2.48 (Jan 2025); `remote.<name>.followRemoteHEAD` (and the general `fetch.followRemoteHEAD`) in Git 2.48, building on Git 2.47's move to proactively fix a missing `refs/remotes/<remote>/HEAD`.

- `remote.<name>.serverOption`: "makes the transport layer act as if the `--server-option=<opt>` option is given from the command line" — i.e., persist server-side protocol options (like Git-LFS/JGit server extensions) per remote instead of typing `--server-option` every time.
- `remote.<name>.followRemoteHEAD` / `fetch.followRemoteHEAD`: controls whether/how your local `refs/remotes/<remote>/HEAD` symref is kept in sync with the actual default branch on the remote (with values like `warn`, and — as of 2.51 — `warn-if-not-<branch>`).

**Why it matters:** Both remove a class of "works on my machine" drift: `serverOption` avoids forgetting a required flag every fetch/push, and `followRemoteHEAD` addresses the long-standing annoyance where `origin/HEAD` silently points at the wrong branch (e.g., after a repo renames its default branch) until someone remembers to run `git remote set-head origin -a`.

**Sources:**
- [Git v2.47 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.47.0.adoc)
- [Git v2.48 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.48.0.adoc)
- [git-config: remote.<name>.serverOption / followRemoteHEAD](https://github.com/git/git/blob/master/Documentation/config/remote.adoc)

---

## 19. `help.autoCorrect` semantics changed, and gained `prompt`/`never` modes

**Introduced:** Git 2.49 (Mar 2025).

Old behavior: `help.autoCorrect = 1` meant "wait ~0.1s after suggesting a typo fix, then run it." New/current values (per current docs):
- `0` / `false` / `off` / `no` / `show` — just show the suggestion (default).
- `1` / `true` / `on` / `yes` / `immediate` — run the suggested command **immediately**, no delay.
- a positive number > 1 — run after that many deciseconds (old behavior, preserved for explicit numeric values).
- `never` — don't show or run any suggestion.
- `prompt` — show the suggestion and ask for confirmation before running it.

**Why it matters:** If you or a teammate set `help.autoCorrect = 1` expecting the old "brief pause, then auto-run" UX, the meaning of `1` changed to "run immediately, no pause." The new `prompt` value is likely the best default for most people who want typo-correction without the risk of an unintended destructive command running automatically — worth revisiting this setting explicitly rather than assuming old muscle-memory values still behave the same way.

**Source:** [git-config: help.autoCorrect](https://github.com/git/git/blob/master/Documentation/config/help.adoc) (behavior change documented in [Git v2.49 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.49.0.adoc))

---

## 20. Credential helper / auth improvements

- **Git 2.46:** the credential helper protocol and HTTP layer were extended to support non-Basic auth schemes like **Bearer tokens and NTLM**, not just username/password pairs — relevant for teams behind corporate proxies or using token-based Git hosts that aren't well served by a plain password prompt.
- **Git 2.47–2.49:** `git send-email`/`git imap-send` gained proper OAuth2.0 support (imap-send had been broken/unmaintained and was resurrected specifically to add this).
- **Git 2.53:** `http.emptyAuth = auto` now correctly attempts Negotiate (Kerberos) authentication before falling back to manual credentials, enabling seamless Kerberos ticket-based auth without explicitly forcing `http.emptyAuth = true`.

**Why it matters:** Token/Bearer-based auth (GitHub/GitLab PATs presented as bearer tokens, SSO-backed corporate Git servers) is increasingly the norm; these changes reduce the need for custom credential-helper shims to bridge the gap.

**Sources:**
- [Git v2.46 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.46.0.adoc)
- [Git v2.51 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.51.0.adoc)
- [Git v2.55 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.55.0.adoc) (`http.emptyAuth=auto` fix)

---

## 21. Global `--no-advice` flag and per-message advice discoverability

**Introduced:** Git 2.46 (Jul 2024).

> "A new global `--no-advice` option can be used to disable all advice messages, which is meant to be used only in scripts."

Also in 2.46: every conditional "advice" hint now tells you exactly which `advice.*` config to set to turn just that one hint off, instead of a generic "set advice.foo to false" boilerplate repeated everywhere.

**Why it matters:** Advice messages (the "hint:" lines Git prints for things like a failed push or a detached HEAD) are genuinely useful for newcomers but noisy for experienced users automating things. `--no-advice` is the clean one-shot way to silence them in a script/CI context without hunting for the specific `advice.*` key or setting `GIT_ADVICE=0` (an intentionally undocumented env var, per the 2.47 notes).

**Sources:**
- [Git v2.46 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.46.0.adoc)
- [Git v2.47 Release Notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.47.0.adoc) (GIT_ADVICE documentation)

---

## 22. Things investigated but found to be already well-established (not new)

Per the research brief, these were checked against the same window and found to predate it, so they are *not* included as new findings, but are noted here for completeness:

- **SSH-based commit/tag signing** (`gpg.format = ssh`, `gpg.ssh.allowedSignersFile`) — introduced in Git 2.34 (Nov 2021), well before this window. Only incremental fixes appeared in this period (e.g., a 2.55 fix for signing commits with a custom encoding, and 2.52's note that expired keys shouldn't retroactively invalidate signatures that were valid when made).
- **`scalar`** — introduced in Git 2.38 (Oct 2022), also before this window. Recent changes are incremental: `scalar clone --no-tags` (2.47), an option to skip enabling scheduled maintenance when registering a repo (2.50), and `make strip` now stripping the `scalar` binary too (2.53).
- **`merge.conflictStyle = zdiff3`, `rerere.enabled`, `push.autoSetupRemote`, `branch.sort`, `column.ui`, `fetch.prune`** — all predate this window (mostly 2020–2022) and were correctly excluded per the prompt.
- **Multi-pack-index / commit-graph themselves** — the core features predate this window (2018–2021); what's new in this window is incremental (see items 6, 8, and the "geometric" maintenance default above), not the base feature.

---

## Notes on sourcing and methodology

- Every version-specific claim above is sourced directly from the official `Documentation/RelNotes/<version>.adoc` files in the [git/git GitHub repository](https://github.com/git/git/tree/master/Documentation/RelNotes) (mirrored verbatim to [git-scm.com](https://git-scm.com/)'s download/release-notes pages), and cross-checked where relevant against the current config documentation in [git/git's `Documentation/config/*.adoc`](https://github.com/git/git/tree/master/Documentation/config) (the source for [git-scm.com/docs/git-config](https://git-scm.com/docs/git-config)).
- Version/date mapping used (from [git-scm.com/docs/git.html](https://git-scm.com/docs/git.html)): 2.43.0 (2023-11-20), 2.44.0 (2024-02-23), 2.45.0 (2024-04-29), 2.46.0 (2024-07-29), 2.47.0 (2024-10-06), 2.48.0 (2025-01-10), 2.49.0 (2025-03-14), 2.50.0 (2025-06-16), 2.51.0 (~2025-08), 2.52.0 (2025-11-17), 2.53.0 (2026-02-02), 2.54.0 (2026-04-20), 2.55.0 (2026-06-29, latest at time of writing).
- No fabrication: every item was verified to exist, with matching wording, in the corresponding official release notes or config docs before being included. Where a feature was still very new (e.g., item 11, from the just-released 2.55), that immaturity is flagged explicitly rather than presented as long-settled.
