---
name: gh-attach
description: Attach local images and videos onto GitHub issues, PRs, and comments with `--attach`. Use when posting or editing an issue, PR, or comment that includes a screenshot or recording, including Guided QA.
---

# gh --attach

Pass `--attach` on the same `gh` write that posts the body, once per file. Commands: `gh {issue|pr} {create|edit|comment}`. If that command's `--help` has no `--attach`, update `gh` and retry.

## Post

Write Markdown with ordinary local paths. `gh` rewrites each referenced path to the uploaded URL and keeps that alt text; unreferenced attaches append.

```markdown
![Idle desktop](./idle.png)
```

Agent shells are PowerShell. Quote every `--attach` value so `#` alt text is not a comment.

```powershell
gh pr comment 12 --body-file qa.md --attach './idle.png' --attach './pair.png#Pair door'
```

`#` alt on the flag applies only to appended files.

## Already posted without media

Put the local-path image refs in the body file, then `--edit-last` with `--body-file` and `--attach` so the rewrite lands in place.

## Done when

Every local image or video the issue, PR, or comment should show is a `https://github.com/user-attachments/assets/...` URL in `gh pr view <n> --comments` or `gh issue view <n> --comments`.
