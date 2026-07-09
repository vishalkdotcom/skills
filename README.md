# skills

Private agent skills (Cursor, Claude, and other tools that read the same tree). Tracked in Git for history and portability—**never commit credentials**.

## Layout

- `skills/<skill-name>/` — each skill is a folder (typically with `SKILL.md` and optional refs/scripts).

Runtime expects:

- `~/.agents/skills` → **`/absolute/path/to/this/repo/skills`** (symlink).

## First-time setup (new machine)

1. Clone (HTTPS or SSH):

   ```bash
   git clone https://github.com/vishalkdotcom/skills.git
   cd skills
   ```

2. **Backup** any existing directory (only if `~/.agents/skills` is a real folder, not already this symlink):

   ```bash
   mv ~/.agents/skills ~/.agents/skills.bak."$(date +%Y%m%d-%H%M)"
   ```

3. Point agents at the repo’s `skills/` subtree (use the **absolute** path to your clone):

   ```bash
   ln -sfn "$(pwd)/skills" ~/.agents/skills
   ```

4. Confirm:

   ```bash
   ls -la ~/.agents/skills
   test -f ~/.agents/skills/grilling/SKILL.md && echo OK
   ```

### Other tools

Configure each product to the same files if it uses a different directory (e.g. Claude). Prefer another symlink to `…/repo/skills` rather than duplicating folders.

### Windows (native clone — not a WSL mount)

Keep a **second clone on NTFS** so Windows Cursor/agents never read skills over `\\wsl$\`. Do **not** junction to the WSL filesystem.

In **Windows** PowerShell / pwsh:

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\repos" | Out-Null
git clone https://github.com/vishalkdotcom/skills.git "$env:USERPROFILE\repos\skills"
pwsh -File "$env:USERPROFILE\repos\skills\scripts\setup-windows-agents-link.ps1"
```

That backs up any existing `%USERPROFILE%\.agents\skills` folder and creates a junction to the clone’s `skills\` tree. Day-to-day: `git pull` in `C:\Users\vishal\repos\skills` after you push from WSL.

## Day-to-day workflow

- Edit files under `skills/` (your editor can open the clone directly; if you use the symlink, edits are the same inode).
- **Sync from [mattpocock/skills](https://github.com/mattpocock/skills):** see [UPSTREAM.md](./UPSTREAM.md). Run `./scripts/sync-upstream.sh --dry-run`, then `./scripts/sync-upstream.sh` when you want updates — usually only after Matt ships changes.
- Commit when a skill change is in a good state:

  ```bash
  cd /path/to/skills   # repo root
  git status
  git add -p           # optional: review hunks
  git commit -m "skill-name: concise summary"
  git push
  ```

- On another machine: `git pull` in the clone (and keep the symlink pointed at `…/skills`).

## Safety

- Do not put API keys, passwords, or tokens in tracked files; use env vars or untracked local files (see `.gitignore`).
- If employer policy forbids mixing work-specific and personal content, keep work-only notes out of this repo or sanitize before commit.
