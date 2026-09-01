# File Lifecycle

How a change moves from this repo into a user's project.

```
docs/  ──ship.sh──▶  src/  ──setup.sh──▶  user project
(edit + test)        (distributable)      (installed)
```

## Two trees

This repo has two parallel trees. Always know which one you're touching.

| Tree    | Role                                                        |
|---------|------------------------------------------------------------|
| `docs/` | Live dev environment. Edit and test here. `./sprint.sh` runs the scripts in `docs/sprintbias/`. We also dogfood SprintBias to manage our own work in `docs/tasks/`, `docs/features/`, etc. |
| `src/`  | The distributable package. `setup.sh` installs from here. Never edit or run anything in `src/` directly. |

## The flow

**Audience:** Steps 2–3 (and `git commit`) are for the **developer**. Agents
editing via `work` / `chat` do step 1 only — leave `./ship.sh` and commit to
the human. "Always edit `docs/`, then commit" is a developer rule, not an AI
order.

**1. Edit `docs/`** — Change scripts (`docs/sprintbias/scripts/`), AI guidance (`docs/sprintbias/ai/`), or `DOCUMENTATION.md` at the repo root. Run and test in place.

**2. `./ship.sh`** (developer) — The one and only mirror step. It rsyncs `docs/sprintbias/` and the root files (`sprint.sh`, `DOCUMENTATION.md`, `GETSTARTED.md`) into `src/`, then bumps `src/VERSION` (patch by default; `./ship.sh minor` or `major`). New files under `docs/sprintbias/` ship automatically. Preview first with `./ship.sh --dry-run`. Never hand-copy files into `src/`.

**3. `./setup.sh`** (developer) — Installs `src/` into a target project: `DOCUMENTATION.md` and `sprint.sh` at the root, plus `docs/sprintbias/` and empty `docs/tasks/`, `docs/features/`, etc. Re-running it updates the framework while preserving the user's own content and their generated `DOC_STATE.md` (counters are lifted to match the highest ID already on disk). Leftover files from an earlier docs system (old launcher, old framework folder, undotted templates) are removed.

## What does not flow

Only `src/` reaches users. These stay in the repo:

- **Root dev files** — `README.md`, `CLAUDE.md`, this file, `ship.sh`. If a file isn't under `src/`, it doesn't ship.
- **Our dogfood work** — everything in `docs/tasks/`, `docs/features/`, `docs/ideas/`, `docs/bugs/`. Users get empty starter folders, not our tasks.

## Editing outside the flow

A few things are edited directly, outside the `docs/ → ship.sh → src/` flow:

- `setup.sh` — the installer (one copy, not mirrored; no `docs/` counterpart).
- `ship.sh` — the release tool (edit its manifest only when a new distributable path appears outside the trees it already mirrors).
- GitHub files and the distribution AI pointer files — `src/.github/`, `src/CLAUDE.md`, `src/AGENTS.md`, … (no `docs/` counterpart).

Templates are **not** an exception, despite living beside our dogfood work items: edit the `.TEMPLATE-*` file under `docs/` (e.g. `docs/tasks/.TEMPLATE-task.md`), then `./ship.sh` mirrors it to `src/` via its `TEMPLATE_FILES` list — the same `docs/ → ship.sh → src/` flow as everything else.
