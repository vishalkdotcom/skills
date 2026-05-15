---
name: obsidian-vault
description: Entry point for the user's personal Obsidian vault. Use when creating, finding, or organizing notes, PRDs, ticket folders, daily notes, or `.base` dashboards in the vault. Routes to the vault README for conventions and to the official obsidian-* skills for mechanics.
---

# Obsidian Vault

## Path

| | |
|---|---|
| **WSL** | `/mnt/c/Users/vishal/vaults/obsidian` |
| **Windows** | `C:\Users\vishal\vaults\obsidian` |
| **Remote** | `git@github.com:vishalkdotcom/work-vault.git` (private; auto-synced via the `obsidian-git` plugin) |

## Conventions

**Read `{vault}/README.md` before adding or moving files.** It is the single source of truth for:

- Folder layout (codebase folders at root; `archive/` is frozen)
- Ticket folder naming (`{TICKET-ID}-{slug}`, kebab-case, no spaces)
- Frontmatter schema for ticket READMEs and daily notes
- The `tickets.base` dashboard

Do not duplicate those rules here — update the README instead.

## Mechanics — defer to the official skills

| Skill | Use for |
|---|---|
| `obsidian-cli` | `obsidian.com` CLI commands (search, read, create, append, daily, tasks, backlinks) |
| `obsidian-markdown` | Wikilinks, callouts, embeds, properties, Obsidian-flavoured Markdown |
| `obsidian-bases` | Authoring and editing `.base` files (filters, views, formulas) |
