---
name: test-report-pr-markdown
description: Builds GitHub test-report PR markdown from ShareX screen recordings and screenshots for wpm-* tickets—discovers assets, encodes videos with HandBrakeCLI, derives summary titles from filenames, resolves video upload names from user-attachments URLs via the GitHub Markdown API, and outputs collapsible details blocks plus a clickable GitHub compare/PR upload page URL from the current git branch. Use when creating test report PR descriptions, encoding ShareX recordings, converting wpm ticket assets to GitHub markdown, or assembling QA evidence for a pull request.
---

# Test report PR markdown

## Defaults

| Setting          | Default                                                                           |
| ---------------- | --------------------------------------------------------------------------------- |
| ShareX folder    | `C:\Users\vishal\scoop\apps\sharex\current\ShareX\Screenshots`                    |
| Encoded videos   | `C:\Users\vishal\Videos`                                                          |
| Encoder          | `handbrakecli.exe -Z "Very Fast 1080p30"`                                         |
| GitHub `context` | `owner/repo` from `git remote origin` in cwd, else `laborsolutions/wovo_frontend` |
| Upload page URL  | existing PR URL via `gh`, else `compare/{branch}?expand=1` from current branch      |
| PR creation      | **Only when the user explicitly asks** — default is markdown output only          |

Assets use **`wpm-*`** filenames. Images are not re-encoded.

## Quick start

From WSL in the ticket’s git repo, run the full workflow:

```bash
SKILL="$HOME/.agents/skills/test-report-pr-markdown"
bash "$SKILL/scripts/trpm.sh" prepare-ticket-report -Ticket wpm-3370
```

Optional name filter (substring match on filenames):

```bash
bash "$SKILL/scripts/trpm.sh" prepare-ticket-report -Ticket wpm-3370 -Filter audit-user-fix
```

Use **`trpm.sh`** for all scripts — it routes to bash (git/upload URL) or PowerShell (`wslpath -w` for ShareX paths).

Direct `powershell.exe -File "$SKILL/..."` with a WSL `/home/...` path **does not work**.

Requires `gh auth login` for URL resolution (private repo attachments).

## Workflows

### A. Full ticket workflow (preferred)

1. **Prepare** — `prepare-ticket-report.sh -Ticket wpm-xxxx` (discover → encode → upload URL → draft markdown)
2. **Upload** — open the **Upload page** link; drag-drop encoded videos + screenshots into the PR composer
3. **Final** — `generate-markdown.ps1 -Mode final -UrlFile urls.txt` (add `-ImageUrls` for screenshots)

### B. Upload page URL only

```bash
bash "$SKILL/scripts/trpm.sh" get-upload-page-url
# https://github.com/laborsolutions/wovo-django/compare/vishalk/wpm-3370-fix-backfill-audit-user-ids?expand=1
```

Best effort from cwd: `origin` remote → owner/repo, current branch, existing PR via `gh pr view`.

### C. URLs only (user already uploaded)

```bash
bash "$SKILL/scripts/trpm.sh" resolve-asset-name -Url 'https://github.com/user-attachments/assets/UUID'
```

### D. Images in markdown

Bare image URLs do **not** resolve filenames via the API. Use the ShareX filename for `alt` and the summary title:

```html
<img width="2250" height="3620" alt="wpm-3267-swagger-endpoint" src="https://github.com/user-attachments/assets/..." />
```

## Agent behavior

- Run **`prepare-ticket-report`** (or equivalent steps) and return results directly — **do not ask the user to provide draft markdown**.
- Always include the **Upload page** URL when derivable from git; user opens it for manual asset upload.
- Prefer bundled scripts over reimplementing encode/title/API logic.
- Do **not** create a PR unless the user asks.
- Do **not** commit large video files to git.
- Asset order is **not prescribed** — use script output as-is; optional `-Filter` when the user scopes assets by filename.
- After draft output, only mention re-run for **final** markdown once URLs exist — do not block on URL paste unless the user wants final output.

## Scripts

| Script                            | Purpose                                              |
| --------------------------------- | ---------------------------------------------------- |
| `scripts/prepare-ticket-report.sh`| Full workflow + upload URL + draft markdown          |
| `scripts/get-upload-page-url.sh`  | GitHub compare/PR URL from cwd                       |
| `scripts/_git-context.sh`         | Shared git remote/branch helpers (bash)              |
| `scripts/_common.ps1`             | Paths, git context, title derivation                 |
| `scripts/find-ticket-assets.ps1`  | List ShareX + Videos files for a ticket              |
| `scripts/encode-test-reports.ps1` | HandBrakeCLI batch encode                            |
| `scripts/resolve-asset-name.ps1`  | URL → upload filename                                |
| `scripts/generate-markdown.ps1`   | Draft or final `<details>` markdown (`-Filter` opt.) |
| `scripts/trpm.sh`                 | WSL entrypoint (bash + PowerShell)                   |

More naming rules and examples: [REFERENCE.md](REFERENCE.md), [EXAMPLES.md](EXAMPLES.md).
