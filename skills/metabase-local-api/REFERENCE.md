# Metabase API reference notes

Official overview: [Metabase API documentation](https://www.metabase.com/docs/latest/api)

## Instance-specific truth

The authoritative contract for **your** server is the bundled OpenAPI UI:

`http://<host>:<port>/api/docs/`

Download JSON/YAML from that page if you want codegen or static search.

## Common read endpoints (names may vary slightly by version)

| Goal                        | Typical endpoint                                            |
| --------------------------- | ----------------------------------------------------------- |
| Session health / smoke test | `GET /api/user/current`                                     |
| Root collection             | `GET /api/collection/root`                                  |
| Items in a collection       | `GET /api/collection/{id}/items`                            |
| List cards                  | `GET /api/card`                                             |
| One card                    | `GET /api/card/{id}`                                        |
| Dashboards                  | `GET /api/dashboard`, `GET /api/dashboard/{id}`             |
| Database connections        | `GET /api/database`                                         |
| Search                      | `GET /api/search` (query params for models/text—check docs) |

## Execution / datasets

Running queries via API is version-sensitive (parameters for MBQL, exports, pivots). Use `/api/docs` on the instance for:

- `dataset` / query execution routes
- Card-adjacent execution routes

## Enterprise-only prefixes

Routes under `/api/ee/...` require Enterprise; ignore or expect 404 on OSS.

## Environment variables (local automation)

Set these in your shell profile (e.g. Fish `set -gx` in `config.fish`), `export` in bash/zsh, direnv, or CI secrets—not from a tracked `.env` file unless you manage that yourself.

**Recommended (Fish + Cursor agent):** keep **`MB_LOCAL_API_KEY`** in **`~/.config/secrets/metabase.env`** (single `KEY='value'` line, **`chmod 600`**). Source it from **`~/.profile`** and **`~/.bashrc`** (before bash’s interactive-only early exit) with `set -a; . …; set +a`, and **`export BASH_ENV="$HOME/.config/secrets/metabase.bash_env"`** so **non-interactive `bash -c`** (how many agents run) still loads the key. Fish should **`set -gx BASH_ENV`** to the same path so subprocess bash inherits it.

| Variable               | Purpose                                             |
| ---------------------- | --------------------------------------------------- |
| `MB_LOCAL_API_KEY`     | Metabase API key (`X-API-Key`)                      |
| `MB_METABASE_BASE_URL` | Full base, e.g. `http://172.29.48.1:7000`           |
| `MB_METABASE_HOST`     | Host only; combine with `MB_METABASE_PORT`          |
| `MB_METABASE_PORT`     | Default often `3000` or `7000` depending on install |

**Skill helper:** `uv run "$HOME/.agents/skills/metabase-local-api/scripts/metabase_collections_cards.py"` (lists collections and cards; PEP 723 / stdlib).

## WSL → Windows host IP (quick copy-paste)

```bash
ip route show default | awk '/default/ {print $3; exit}'
# fallback:
awk '/^nameserver/ {print $2; exit}' /etc/resolv.conf
```

## Firewall

If `curl` from WSL to the Windows IP times out, allow inbound TCP on the Metabase port for the WSL/Hyper-V interface or the hosting process.
