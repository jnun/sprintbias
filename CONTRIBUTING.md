# Contributing to SprintBias

SprintBias is a file-based project-management system that installs into other
people's projects. **You are working on the system itself, not on a project
that uses it.** This repo happens to use SprintBias to manage its own
development — but that dogfooding is incidental. The product is what ships in
`src/`, not the task files we keep in `docs/`.

## Quick start

```bash
git clone git@github.com:jnun/sprintbias.git && cd sprintbias
```

No build step, no dependencies. The project is Bash scripts and Markdown. If
you can run `bash`, you can develop it.

## Development workflow

**For the developer:** Always edit `docs/`, then run `./ship.sh`, then commit.
That release path is yours — not the AI's. Agents implementing via `work` /
`chat` edit and test under `docs/` and stop; you ship and commit.

The one rule that governs everything: **edit `docs/` → test in place → `./ship.sh`.**

1. **Edit in `docs/`** — the live environment. Scripts in
   `docs/sprintbias/scripts/` run the moment you invoke `./sprint.sh`. Changes
   take effect immediately, no mirror step needed to test.
2. **Test your change** — run the real `./sprint.sh` command it affects, then
   the platform suite. Full ladder (unit → emit smoke → live dual-provider):
   **[docs/guides/running-tests.md](docs/guides/running-tests.md)**. Quick unit
   pass: `bash docs/tests/run-all.sh`.
3. **Update maintainer guides when the surface moves** (repo-only; not shipped):
   - **New or changed command** → edit
     **[docs/guides/command-matrix.md](docs/guides/command-matrix.md)** (catalog
     row, family, or retired-names table) in the same change as dispatch /
     registry / help / script.
   - **Provider / dual-host behavior** (tool map, emit, subagents, models,
     install tier) or a proven known-unknown → edit
     **[docs/guides/provider-reality.md](docs/guides/provider-reality.md)**
     (KK/KU stamps and Surfaced unknowns).
4. **Run `./sprint.sh validate`** — integrity-checks task IDs and dependency
   links. Add `--commands` if you touched a command's help, dispatch, or the
   manual (it enforces that all four surfaces agree), and `--docs` if you
   changed a script's flags.
5. **Mirror to `src/`** — run `./ship.sh` (preview first with
   `./ship.sh --dry-run`). It rsyncs the live tree into `src/`, bumps the
   version, and byte-verifies the mirror. Patch bump by default;
   `./ship.sh minor` / `major` for larger changes. **Never hand-copy files
   into `src/`.**
6. **Verify a fresh install** (see below).
7. **Commit** — the maintainer handles commits and releases unless you're asked
   to. `ship.sh` prints the suggested `git commit -m "ship: vX.Y.Z"` line.

### The two trees

- **`docs/`** is where you develop. Scripts run from here. Edit here first,
  always.
- **`src/`** is the distribution package — exactly what `setup.sh` installs into
  a user's project. It is **not** a development environment. Never iterate
  inside `src/`; `./ship.sh` is the one and only step that mirrors
  `docs/` → `src/`, after you've tested.

A change that lands only in `docs/` works locally but never reaches users. A
change that lands only in `src/` ships untested. See [LIFECYCLE.md](LIFECYCLE.md)
for the full file flow.

### Verify a fresh install

```bash
mkdir /tmp/test-sprint && ./setup.sh
# enter /tmp/test-sprint when prompted, verify output, then:
rm -rf /tmp/test-sprint
```

If this breaks, it's a **release blocker** — it means a user's first experience
with your change is broken. (`install.sh` at the repo root is the one-line curl
bootstrap that fetches the tree and runs `setup.sh` for end users; you rarely
touch it while developing.)

## What goes where

| I want to change... | Edit here | Reaches `src/` via |
|---|---|---|
| A command / script | `docs/sprintbias/scripts/` **and** `docs/guides/command-matrix.md` | scripts via `./ship.sh`; matrix is repo-only |
| AI guidance (`chat`, `plan`, task authoring) | `docs/sprintbias/ai/` | `./ship.sh` |
| CLI help pages, provider CLIs, shipped guides | `docs/sprintbias/{help,cli,guides}/` | `./ship.sh` |
| Dual-provider reality (KK/KU inventory) | `docs/guides/provider-reality.md` | — (repo-only, never ships) |
| Shared helpers / config | `docs/sprintbias/{lib.sh,config}` | `./ship.sh` |
| The command catalog | `docs/sprintbias/help/_registry` | `./ship.sh` (the help index is generated from it) |
| The user manual | `DOCUMENTATION.md` (root) | `./ship.sh` |
| Getting-started guide | `GETSTARTED.md` (root) | `./ship.sh` |
| A work-item template | `docs/{tasks,bugs,features,ideas,tests,plans}/.TEMPLATE-*` | `./ship.sh` (its `TEMPLATE_FILES` list mirrors each to `src/docs/…`) |
| The installer | `setup.sh` (root) | — (one copy, not mirrored) |
| The curl bootstrap | `install.sh` (root) | — (one copy, not mirrored) |
| The ship tool | `ship.sh` (root) | — (dev-only, never ships) |
| GitHub issue/PR templates, workflows | `src/.github/` | — (edit `src/` directly; no `docs/` copy) |
| AI pointer files (`CLAUDE.md`, `AGENTS.md`, `.cursorrules`, …) | `src/CLAUDE.md`, `src/AGENTS.md`, … | — (edit `src/` directly; no `docs/` copy) |

Everything under `docs/sprintbias/` is mirrored **wholesale**, so a brand-new
script, help page, or guide ships automatically — no `ship.sh` edit needed. You
touch `ship.sh`'s manifest only when a new distributable path appears *outside*
the trees it already covers (a new root file, or a whole new `docs/` subtree).

Two traps worth naming:

- **Root files don't ship unless listed.** `README.md`, `CONTRIBUTING.md`,
  `LIFECYCLE.md`, and this repo's own `CLAUDE.md` support *developing*
  SprintBias — they never reach users. Only `sprint.sh`, `DOCUMENTATION.md`, and
  `GETSTARTED.md` are wired into `ship.sh`'s `ROOT_FILES`.
- **Keep the `src/` AI pointer files minimal.** `src/CLAUDE.md`,
  `src/AGENTS.md`, and friends are a few lines pointing at `DOCUMENTATION.md`
  *on purpose*. The installer prepends them to a user's existing AI instruction
  file (or asks before creating one) and never clobbers. Don't enrich,
  generate, or templatize them — the user owns those files.

## Tracking work

This repo uses SprintBias to manage itself. Create work items with the CLI —
never write those files by hand:

```bash
./sprint.sh newtask "<description>"     # a task
./sprint.sh newbug  "<description>"     # a bug
./sprint.sh newidea                     # an idea (AI Q&A if no name)
./sprint.sh newfeature                  # a feature
```

Tasks flow through lifecycle folders `backlog → next → doing → review → done`
(plus `blocked/`). Move a task between folders with `git mv SRC DEST || mv SRC
DEST` — `git mv` first to keep history, plain `mv` when it isn't tracked yet.
See `DOCUMENTATION.md` → Moving Tasks. None of `docs/tasks/`, `docs/bugs/`,
etc. is distributed; users get empty starter folders, not our work.

## Questions

`DOCUMENTATION.md` explains the whole system end-to-end. `./sprint.sh help`
lists every command; `./sprint.sh help <command>` opens its page.
