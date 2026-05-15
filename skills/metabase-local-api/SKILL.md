---
name: metabase-local-api
description: Connects to Metabase over its REST API using an API key—especially local instances where Metabase runs on Windows and the agent or terminal runs in WSL. Covers discovering the reachable base URL, authentication headers, listing or inspecting collections/cards/dashboards/databases, and common admin-style GETs/POSTs. Use when the user mentions Metabase API, local Metabase, MB_LOCAL_API_KEY, WSL and localhost, listing collections or cards, or automating Metabase administration and queries.
---

# Metabase local API

## Prerequisites

- Metabase reachable from where commands run (browser vs WSL differ—see below).
- **API key** with sufficient permissions (Admin → **People** → **API keys**, or your Metabase version’s equivalent).
- **`MB_LOCAL_API_KEY` in the environment** (shell profile, secret manager, CI)—do **not** rely on a committed `.env` in the repo.

## Quick start

Bash:

```bash
export MB_LOCAL_API_KEY="mb_..."   # or define once in ~/.bashrc / comparable

# Optional: when WSL cannot use localhost (Metabase on Windows)
export MB_METABASE_BASE_URL="http://<windows-host-ip>:7000"

curl -sS -H "X-API-Key: $MB_LOCAL_API_KEY" \
  "${MB_METABASE_BASE_URL:-http://127.0.0.1:7000}/api/user/current"
```

Fish (persistent export in `~/.config/fish/config.fish`):

```fish
set -gx MB_LOCAL_API_KEY 'mb_...'
set -gx MB_METABASE_BASE_URL http://<windows-host-ip>:7000   # optional
```

Replace `<windows-host-ip>` with the default gateway from `ip route show default` or the nameserver in `/etc/resolv.conf` when needed.

## WSL vs Windows (why localhost breaks)

- **Browser on Windows**: `http://localhost:<port>` hits Metabase on Windows.
- **WSL**: `localhost` is the Linux VM. If Metabase listens only on Windows, use **`MB_METABASE_BASE_URL=http://<Windows-host-IP>:<port>`** or enable WSL **mirrored** networking so `localhost` is shared.

If probes fail, check Windows Firewall for inbound TCP on the Metabase port.

## Authentication

| Method                             | Header                                                                                     |
| ---------------------------------- | ------------------------------------------------------------------------------------------ |
| API key (preferred for automation) | `X-API-Key: <key>`                                                                         |
| Session (interactive)              | Obtain via `POST /api/session` JSON `username`/`password`, then `X-Metabase-Session: <id>` |

Use **HTTPS** and treat keys like passwords.

## Utility script (bundled with this skill)

Lists collections and cards with the same host probing as above. **uv** runs it via PEP 723 (stdlib only):

```bash
uv run "$HOME/.agents/skills/metabase-local-api/scripts/metabase_collections_cards.py"
```

Requires **`MB_LOCAL_API_KEY`** (and optionally `MB_METABASE_BASE_URL`, `MB_METABASE_HOST`, `MB_METABASE_PORT`) in the environment. Script path is next to this skill’s `SKILL.md` under `scripts/`.

## Workflows

### Discover OpenAPI for this instance

Open in browser (same machine as Metabase): `http://<host>:<port>/api/docs/`

### Read-only inventory

- Current user: `GET /api/user/current`
- Collections tree walk: `GET /api/collection/root/items` then repeat per collection id (see script above).
- All cards (visibility permitting): `GET /api/card`
- Dashboards: `GET /api/dashboard`
- Databases: `GET /api/database`

### Run or inspect a question (card)

- Card definition: `GET /api/card/:id`
- Dataset/query execution patterns vary by Metabase version; use `/api/docs` on the instance or **REFERENCE.md** for pointers.

### Administration (examples—confirm path/body in instance docs)

- Health: `GET /api/health`
- API keys management (admin): under `/api/api-key` in OpenAPI
- Users/groups: endpoints under `/api/user`, `/api/permissions`, etc., per generated docs

Always confirm **method, path, and JSON body** against `/api/docs` for the running version (OSS vs Enterprise differs).

## Agent behavior

- Prefer **`curl`** or **`uv run "$HOME/.agents/skills/metabase-local-api/scripts/metabase_collections_cards.py"`** so **localhost / Windows IP** behavior matches the user’s machine.
- Do **not** assume `WebFetch` can reach `localhost`; it cannot from isolated backends.
- Redact API keys in logs and chat.

More endpoints and notes: [REFERENCE.md](REFERENCE.md).
