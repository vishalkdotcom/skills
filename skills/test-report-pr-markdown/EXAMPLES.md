# Examples — test report PR markdown

## wpm-3370 (full workflow from git repo)

```bash
cd ~/repos/wovo-django
SKILL="$HOME/.agents/skills/test-report-pr-markdown"

bash "$SKILL/scripts/trpm.sh" prepare-ticket-report -Ticket wpm-3370 -Filter audit-user-fix
```

Output includes:

- **Upload page** — e.g. `https://github.com/laborsolutions/wovo-django/compare/vishalk/wpm-3370-fix-backfill-audit-user-ids?expand=1`
- Encoded video paths under `C:\Users\vishal\Videos\`
- Draft `<details>` markdown (paste into PR body after uploading assets)

## wpm-3267 (videos only)

### 1. Discover and encode

```bash
SKILL="$HOME/.agents/skills/test-report-pr-markdown"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SKILL/scripts/find-ticket-assets.ps1" -Ticket wpm-3267
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SKILL/scripts/encode-test-reports.ps1" -Ticket wpm-3267
```

Encoded outputs:

- `C:\Users\vishal\Videos\Wpm-3267-Test-Report-Dev-Server-Before-Fix.mp4`
- `C:\Users\vishal\Videos\Wpm-3267-Test-Report-Dev-Server-After-Fix.mp4`
- `C:\Users\vishal\Videos\Wpm-3267-Test-Report-Prod-Server-After-Fix.mp4`

### 2. Draft (before upload)

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SKILL/scripts/generate-markdown.ps1" -Ticket wpm-3267 -Mode draft
```

### 3. Final (after user pastes URLs)

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SKILL/scripts/generate-markdown.ps1" -Mode final -Ticket wpm-3267 -UrlFile urls.txt
```

`urls.txt` — one `user-attachments` URL per line.

### 4. Expected output shape

```markdown
<details>
<summary><b>Test Report - Dev Server Before Fix</b></summary>

https://github.com/user-attachments/assets/...
</details>

<details>
<summary><b>Test Report - Dev Server After Fix</b></summary>

https://github.com/user-attachments/assets/...
</details>

<details>
<summary><b>Test Report - Prod Server After Fix</b></summary>

https://github.com/user-attachments/assets/...
</details>
```

## Mixed ticket (videos + unit-test screenshot)

Use `-Ticket wpm-3367` for draft. For final markdown, pass video URLs via `-Urls` / `-UrlFile` and image URLs via `-ImageUrls` (same order as discovered PNGs) or `-ImageMap` JSON in `generate-markdown.ps1`.

## Resolve one video URL

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SKILL/scripts/resolve-asset-name.ps1" \
  -Url 'https://github.com/user-attachments/assets/690bf583-9724-4467-a376-284654a1629f'
# Wpm-3219-3225-Test-Report-Empty-Template-Download.mp4
```
