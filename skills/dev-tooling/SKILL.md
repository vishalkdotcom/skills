---
name: dev-tooling
description: Node, pnpm, Python, and JS CLIs on this machine (fnm, Scoop pnpm, uv, bun). Use when installing dependencies, running package scripts, or invoking node, npm, pnpm, uv, bun, or fnm.
---

# Dev Tooling

## Apply fnm when the command needs Node

Agent shells already have Scoop `pnpm`, `uv`, and `bun` on PATH. They start without `node`. Before `node`, `npm`, `npx`, or any command that runs project JavaScript (`pnpm test`, `pnpm exec`, `pnpm dev`), apply fnm **once per shell**:

```powershell
fnm env --shell powershell | ForEach-Object { Invoke-Expression $_ }
```

Done when `node --version` prints a version that `fnm list` knows (default is 24). Skip this step when that is already true.

One-shot without mutating PATH:

```powershell
fnm exec -- node --version
fnm exec -- npm.cmd --version
```

`fnm exec` resolves `node.exe` by name. npm/npx need the `.cmd` name. Scoop pnpm is `pnpm.exe` — invoke `pnpm` directly.

Chain agent Shell commands with `;`.

## Project toolchain

Follow the repo's lockfile and `packageManager` / `devEngines.packageManager`. Scoop `pnpm` honors `packageManager` (`pmOnFail: download`). Use `uv` in Python repos, `bun` when the repo is bun.

## On this machine

| Tool | Role |
|---|---|
| `uv` / `uvx` | Python envs, deps, lockfiles, one-off CLIs |
| `bun` / `bunx` | JS runtime, installs, one-off CLIs |
| `fnm` | Node versions — `fnm list` is the inventory |
| `pnpm` | Scoop `pnpm.exe` |

CLI surface is `--help`. Prefer `.exe` / `.cmd` shims (`pnpm.exe`, `npm.cmd`) from Windows PowerShell.

`python` / `python3` under WindowsApps are Store stubs — `uv run` / `uvx` are the working interpreters.
