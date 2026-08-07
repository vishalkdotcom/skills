---
name: dev-tooling
description: Dev tooling on this machine (`uv`/`uvx`, `bun`/`bunx`, `fnm`) and Windows/pwsh gotchas for env/deps/tool runs. Use when creating envs, installing dependencies, or running language CLIs (`uv`/`bun`/`fnm`), enabling Corepack/pnpm because a project requires it, or when a repo already uses these tools (`uv.lock`, `bun.lock*`, `.node-version`/`packageManager`).
---

# Dev Tooling

## Available on this machine

| Tool | Role |
|---|---|
| `uv` / `uvx` | Python envs, deps, lockfiles, one-off Python CLIs; managed CPython via `uv` (3.14.x installed) |
| `bun` / `bunx` | JS runtime, package installs, one-off JS CLIs |
| `fnm` | Node version manager — **v24.18.x** default, **v18.20.x** also installed |
| Corepack → `pnpm` / `yarn` | Not global; enable when a project requires them (`packageManager`, `pnpm-lock.yaml`, etc.) |

Versions drift; if uncertain, check with `uv --version`, `bun --version`, `fnm --version` / `fnm list`. Leave CLI surface to `--help` — this file is inventory and gotchas only.

## Gotchas on this machine

- Fresh agent shells lack `node`/`npm` on PATH until `fnm env` is applied. In pwsh: `fnm env --shell power-shell | ForEach-Object { Invoke-Expression $_ }`, or run via `fnm exec -- <cmd>`.
- ExecutionPolicy blocks `*.ps1` shims (`npm.ps1`, some Scoop scripts). Call the `.cmd` entrypoint (e.g. `npm.cmd`) or another non-ps1 shim.
- `python` / `python.exe` under WindowsApps is the Store stub, not a real interpreter — `uv` provides working envs/installs/`uv run`/`uvx`.
- `FNM_COREPACK_ENABLED` is false by default. When a project needs pnpm/yarn: apply `fnm env`, run `corepack enable`, then use what `packageManager` / the lockfile asks for.
- Project wins: follow existing lockfiles and `packageManager`. This skill advertises availability; it does not override a repo’s chosen toolchain.
