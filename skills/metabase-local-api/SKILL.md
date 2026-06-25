---
name: metabase-local-api
description: Connects to Metabase over its REST API using an API key when Metabase runs on Windows and the agent or terminal runs in WSL. Probes the Windows host IP before localhost, lists cards/collections, and runs card queries. Use when the user mentions Metabase API, local Metabase, MB_LOCAL_API_KEY, WSL, port 7000, or automating Metabase administration.
---

# Metabase local API

## WSL rule (read first)

Metabase on this machine runs on **Windows**, not inside WSL. From WSL:

- **Do not** default to `http://127.0.0.1:7000` or `http://localhost:7000`.
- **Do** set `MB_METABASE_BASE_URL` to the Windows host IP, e.g. `http://172.29.48.1:7000`.
- Discover IP when unsure: `ip route show default | awk '/default/ {print $3; exit}'` (often `172.29.48.1`).

The bundled script probes **Windows host IP before localhost**.

## Prerequisites

- **`MB_LOCAL_API_KEY`** in the environment (shell profile, `~/.config/secrets/metabase.env`, CI).
- **`MB_METABASE_BASE_URL`** set for WSL (recommended persistent export).

## Quick start

```bash
export MB_LOCAL_API_KEY="mb_..."
export MB_METABASE_BASE_URL="http://$(ip route | awk '/^default/ {print $3; exit}'):7000"

curl -sS -H "X-API-Key: $MB_LOCAL_API_KEY" \
  "$MB_METABASE_BASE_URL/api/user/current"
```

List collections and cards:

```bash
uv run "$HOME/.agents/skills/metabase-local-api/scripts/metabase_collections_cards.py"
```

## Authentication

| Method  | Header                                          |
| ------- | ----------------------------------------------- |
| API key | `X-API-Key`                                     |
| Session | `X-Metabase-Session` (from `POST /api/session`) |

## Common workflows

### Inspect / run a card

- `GET /api/card/:id`
- `POST /api/card/:id/query` with `parameters` array (id + value per template tag)

### Read-only inventory

- `GET /api/user/current`, `/api/card`, `/api/collection/root/items`

OpenAPI: `$MB_METABASE_BASE_URL/api/docs/`

## Agent behavior

- **Always** export or pass `MB_METABASE_BASE_URL` with the Windows host IP before Metabase `curl`/scripts.
- **Never** try `localhost` first from WSL — it hits the Linux VM, not Windows Metabase.
- Do **not** use `WebFetch` for local Metabase URLs.
- Redact API keys in logs and chat.

More env vars and endpoints: [REFERENCE.md](REFERENCE.md).
