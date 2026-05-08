---
name: yaak-cli
description: Installs and uses the Yaak CLI to list, create, update, delete, and send workspaces, folders, environments, and HTTP requests against the same local database as the Yaak desktop app, including plugin build/publish and agent-friendly JSON workflows. Use when the user mentions Yaak CLI, @yaakapp/cli, Yaak from the terminal, agentic API testing, batch-sending collections, or migrating from the Yaak MCP server plugin.
---

# Yaak CLI

## Quick start

1. Install: `npm install -g @yaakapp/cli` (binary: `yaak`).
2. Run the **Yaak desktop app** on the same machine; CLI reads/writes the **same local database** ([docs](https://yaak.app/docs/getting-started/cli-usage)).
3. Discover IDs: `yaak workspace list`, then `yaak request list <workspace_id>`.
4. Send: `yaak send <request_or_folder_or_workspace_id>` with optional `-e <environment_id>`, `--parallel`, `--fail-fast`.

## Best DX for agents

- **Schema before mutating**: `yaak request schema http [--pretty]`, `yaak workspace schema`, `yaak environment schema` — use output to shape `--json` payloads.
- **Prefer `--json` for complex creates/updates**; shorthand flags exist for simple cases (`--name`, `-m`, `-u` on `request create`).
- **Verbose sends**: `yaak send ... -v` (or top-level `-v`) for streamed body and events when debugging.
- **Non-interactive deletes**: pass `-y` / `--yes` so automation does not block on confirmation.
- **Environments**: `-e <ENVIRONMENT_ID>` on the root command substitutes template variables when sending; create envs with flag mode or JSON (see `yaak environment create --help`).
- **Cookie jars**: `--cookie-jar <id>` when sends must use stored cookies; `yaak cookie-jar list [workspace_id]`.
- **Custom data directory**: `--data-dir <path>` if the user’s Yaak data is not in the default location.
- **Logging**: `--log debug|trace` for CLI diagnostics separate from send verbosity.
- **Template syntax in saved requests** (critical): variables use `${[ var ]}`, not `{{ ... }}`; functions use `${[ ns.func(a='x') ]}`.

## Common use cases

| Goal                                   | Approach                                                                                     |
| -------------------------------------- | -------------------------------------------------------------------------------------------- |
| Smoke test a folder or whole workspace | `yaak send <folder_or_workspace_id> --parallel` (optional `--fail-fast`)                     |
| Scaffold a collection from code        | `schema` → `workspace create` / `folder create` / `request create` with `--json`             |
| CI / headless send                     | Set `-e`, `--cookie-jar` as needed; use `-y` for any scripted deletes                        |
| Plugin author loop                     | `yaak plugin generate`, `yaak plugin dev`, `yaak plugin build`, `yaak plugin publish [path]` |
| Registry vs local plugin               | `yaak plugin install ./path` or `yaak plugin install @org/plugin[@version]`                  |

## Official references

- CLI overview: https://yaak.app/docs/getting-started/cli-usage
- Package / agent hints (mirrors `yaak --help`): https://www.npmjs.com/package/@yaakapp/cli
- Full command tree and extra flags: [REFERENCE.md](REFERENCE.md)

## When things go wrong

- Commands fail to see data: confirm Yaak app has been opened at least once and `--data-dir` matches the user’s install if non-default.
- Wrong variable values on send: verify environment id with `yaak environment list`, pass `-e` on **parent** `yaak` invocation.
- Payload errors: re-fetch the relevant `schema` subcommand; request schema types are `http`, `grpc`, `websocket`.
