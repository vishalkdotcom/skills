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
