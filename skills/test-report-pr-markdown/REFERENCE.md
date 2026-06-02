# Reference — test report PR markdown

## Path overrides (optional env vars)

| Variable                | Default                                                        |
| ----------------------- | -------------------------------------------------------------- |
| `TRPM_SHAREX_DIR`       | `C:\Users\vishal\scoop\apps\sharex\current\ShareX\Screenshots` |
| `TRPM_VIDEOS_DIR`       | `C:\Users\vishal\Videos`                                       |
| `TRPM_HANDBRAKE_PRESET` | `Very Fast 1080p30`                                            |
| `TRPM_GITHUB_CONTEXT`   | from git remote, else `laborsolutions/wovo_frontend`           |

## Filename → summary title

1. Strip extension.
2. Match `^wpm-\d+-test-report-(.+)$` (primary pattern).
3. Else match `^wpm-\d+-(.+)$`.
4. Prefix **`Test Report -`** + title-cased slug (hyphens → spaces).

Examples:

| Filename                                         | Summary                             |
| ------------------------------------------------ | ----------------------------------- |
| `wpm-3267-test-report-dev-server-before-fix.mp4` | Test Report - Dev Server Before Fix |
| `wpm-3367-test-report-unit-tests.png`            | Test Report - Unit Tests            |
| `wpm-3398-3399-test-report.mp4`                  | Test Report - 3398 3399             |

HandBrake output uses Title Case with hyphens preserved in the basename (e.g. `Wpm-3267-Test-Report-Dev-Server-Before-Fix.mp4`); title derivation is case-insensitive on the slug.

## GitHub Markdown API (video URLs)

```powershell
gh api markdown `
  -f text='https://github.com/user-attachments/assets/{uuid}' `
  -f mode='gfm' `
  -f context='owner/repo'
```

Parse `<span class="m-1">filename.mp4</span>` from HTML. **`context` is required** (any valid `owner/repo` the token can access). **`gh auth`** required for private attachments.

Images pasted as bare URLs return a plain link — use local filename for titles and `alt`.

## Markdown templates

**Video:**

```markdown
<details>
<summary><b>Test Report - {Title}</b></summary>

{asset_url}

</details>
```

**Image:**

```markdown
<details>
<summary><b>Test Report - {Title}</b></summary>

<img width="2250" height="3620" alt="{slug}" src="{asset_url}" />
</details>
```

Separate major sections with `---` when the user’s report includes follow-up blocks (e.g. UPDATED).

## Ordering

Script sort prefers logical filename hints (`before-fix`, `after-fix`, etc.) when present. **Do not ask the user to confirm order.** Use `-Filter substring` when the user scopes assets by filename.

## Upload limitation

GitHub has no public API to upload `user-attachments`. User uploads in the web UI, then provides URLs to the agent or `-Urls` / `-UrlFile`.

## Upload page URL (best effort)

Derived from the **current git repository** (run from WSL bash in the repo):

1. Parse `origin` → `owner/repo`.
2. If `gh pr view` returns a URL for the current branch, use that (existing PR).
3. Else `https://github.com/{owner}/{repo}/compare/{branch}?expand=1`.

```bash
bash "$SKILL/scripts/trpm.sh" get-upload-page-url
bash "$SKILL/scripts/trpm.sh" prepare-ticket-report -Ticket wpm-3370
```

Surface this link for manual drag-drop upload — the agent outputs draft markdown directly without asking the user to supply it first.

## PR creation (explicit request only)

```bash
gh pr create --title "..." --body-file test-report.md
```

Ensure the markdown file contains final asset URLs before creating the PR.
