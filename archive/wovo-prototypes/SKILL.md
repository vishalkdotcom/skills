---
name: wovo-prototypes
description: Routes WOVO throwaway work to the personal ~/repos/wovo-prototypes monorepo (Trino comparisons, Streamlit, Vite mocks). Use when prototyping analytics scores, filter math, or UI spikes that must not land in wovo_frontend, wovo-django, or click-lake; complements the generic prototype skill.
---

# wovo-prototypes

**Repo:** `~/repos/wovo-prototypes` · **Agents:** `AGENTS.md` there · **Data pipe:** `~/repos/click-lake-local`

## When to use this vs other skills

| Situation | Use |
|-----------|-----|
| Generic “try a design / state machine” | [prototype](../prototype/SKILL.md) — pick logic vs UI branch |
| WOVO Trino scores, CF cohorts, compare paths | **This repo** — `wovo-compare` + Streamlit |
| WOVO screen layout without production Next | **This repo** — `apps/mock` (Vite) |
| Ship feature / fix CI | `wovo_frontend`, `wovo-django`, `click-lake` team branches |

Do **not** add prototype routes to production Next unless absorbing a decided design.

## New spike checklist

1. `prototypes/wpm-xxxx-slug/NOTES.md` — state the question first
2. Reuse `wovo_trino` / `wovo_compare` when SQL is shared; else keep code in the ticket folder
3. Document **one** run command in root `README.md`
4. Trino: `iceberg.analytics`; refresh via `click-lake-local/scripts/refresh-survey-analytics.sh`
5. Verdict in `NOTES.md` → vault grill/PRD → delete or `archive/` the folder

## Active example: WPM-3379

```bash
cd ~/repos/wovo-prototypes && uv sync
cd ~/repos/click-lake-local && ./scripts/refresh-survey-analytics.sh
cd ~/repos/wovo-prototypes
uv run wovo-compare discover && uv run wovo-compare batch
make compare-3379   # :8502
```

## Stack (repo conventions)

- **Python:** `uv sync` · CLI `wovo-compare` (Typer + Rich) · UI Streamlit in `apps/compare/`
- **JS:** `pnpm install` · `pnpm mock` → `@wovo-prototypes/mock` (create-vite `react-ts`)
- **Git:** personal repo, `main` only, no secrets
