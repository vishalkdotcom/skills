# Yaak CLI — command reference

Run `yaak <cmd> --help` for the source of truth; versions may add flags.

## Global options (top-level `yaak`)

| Flag                     | Purpose                                        |
| ------------------------ | ---------------------------------------------- |
| `--data-dir <DIR>`       | Yaak data directory                            |
| `-e, --environment <ID>` | Environment for variable substitution on sends |
| `--cookie-jar <ID>`      | Cookie jar for sends                           |
| `-v, --verbose`          | Verbose send output                            |
| `--log [LEVEL]`          | `error\|warn\|info\|debug\|trace`              |

## Command tree

### `yaak send <ID>`

Send a **request**, **folder**, or **workspace** by id.

| Flag          | Purpose                                    |
| ------------- | ------------------------------------------ |
| `--parallel`  | Run multiple requests concurrently         |
| `--fail-fast` | Stop on first failure (folders/workspaces) |

Inherits `-e`, `--cookie-jar`, `-v`, `--log`, `--data-dir`.

### `yaak workspace`

| Subcommand    | Notes                                  |
| ------------- | -------------------------------------- |
| `list`        |                                        |
| `show <id>`   | JSON                                   |
| `schema`      | Create/update JSON Schema              |
| `create`      | `--name`, `--json`, or positional JSON |
| `update`      | `--json` or positional JSON            |
| `delete <id>` | `-y` skip confirm                      |

### `yaak folder`

| Subcommand              | Notes                                            |
| ----------------------- | ------------------------------------------------ |
| `list [workspace_id]`   | Optional ws id if exactly one workspace          |
| `show <id>`             |                                                  |
| `create [workspace_id]` | `--name`, `--json`; id optional if one workspace |
| `update`                | `--json`                                         |
| `delete <id>`           | `-y`                                             |

### `yaak request`

| Subcommand                       | Notes                       |
| -------------------------------- | --------------------------- |
| `list [workspace_id]`            |                             |
| `show <id>`                      |                             |
| `send <id>`                      | Send single request         |
| `schema <http\|grpc\|websocket>` | `--pretty`                  |
| `create [workspace_id]`          | `-n`, `-m`, `-u`, `--json`  |
| `update`                         | `--json` or positional JSON |
| `delete <id>`                    | `-y`                        |

### `yaak environment`

| Subcommand            | Notes                                                 |
| --------------------- | ----------------------------------------------------- |
| `list [workspace_id]` |                                                       |
| `show <id>`           |                                                       |
| `schema`              |                                                       |
| `create`              | Multiple modes — see `yaak environment create --help` |
| `update`              | `--json`                                              |
| `delete <id>`         | `-y`                                                  |

### `yaak cookie-jar`

| Subcommand            | Notes |
| --------------------- | ----- |
| `list [workspace_id]` |       |

### `yaak auth`

| Subcommand | Notes         |
| ---------- | ------------- |
| `login`    | Browser login |
| `logout`   |               |
| `whoami`   |               |

### `yaak plugin`

| Subcommand         | Notes                              |
| ------------------ | ---------------------------------- |
| `generate`         | Starter plugin                     |
| `dev`              | Watch build                        |
| `build`            | Bundle                             |
| `install <SOURCE>` | Local path or `@org/pkg[@version]` |
| `publish [path]`   | Defaults to cwd                    |
