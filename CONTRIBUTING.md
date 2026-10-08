# Contributing to SprintBias

SprintBias is a file-based project-management system that installs into other
people's projects. You are working on the system itself. This repo also uses
SprintBias to track its own work; that work is incidental and never ships.

## Setup

```bash
git clone git@github.com:jnun/sprintbias.git && cd sprintbias
```

No build step and no packages: Bash, Markdown, and a few standard-library
Python 3 scripts. You need `bash`, `git`, and `python3`. The AI commands also
need Claude Code (`claude`) or Grok Build (`grok`).

## How a change reaches users

```
docs/  ──./ship.sh──▶  src/  ──./setup.sh──▶  user's project
(edit + test here)     (distribution mirror)   (installed)
```

- **`docs/`** is the live environment. `./sprint.sh` runs the scripts in
  `docs/sprintbias/scripts/` directly, so a change works the moment you save it.
- **`src/`** is the package `setup.sh` installs from. It is a mirror: edit and
  run in `docs/`, and let `ship.sh` fill `src/`.
- **`./ship.sh`** (dev-only) is the one mirror step. It rsyncs
  `docs/sprintbias/` wholesale, plus the root `sprint.sh`, `DOCUMENTATION.md`,
  `GETSTARTED.md` and the `.TEMPLATE-*` files, into `src/`. It bumps
  `src/VERSION` (patch; `minor` / `major`), rolls the changelog, and
  byte-verifies the mirror. New files under `docs/sprintbias/` ship
  automatically; edit its manifest only for a new distributable path outside
  those trees. Preview with `./ship.sh --dry-run`.
- **`./setup.sh`** (one copy, not mirrored) installs `src/` into a project:
  `sprint.sh`, the manual, `GETSTARTED.md`, minimal `CLAUDE.md`/`AGENTS.md`
  pointers, `.gitignore` entries, `docs/sprintbias/`, and empty starter folders
  with their templates. Re-running it updates the framework and keeps the
  user's work and ID counters.

## Repo map: what ships

**If you can't point to a file under `src/`, it does not ship.** When in doubt,
the answer is no.

| Path | Ships? | What it is |
|------|--------|------------|
| `docs/sprintbias/` | yes, via `ship.sh` | The framework: `scripts/`, `lib.sh`, `config`, `help/` (+ `_registry`, the command catalog), `ai/` (AI guidance), `cli/` (provider profiles), `guides/`, `learning/` (demos), `shell/`, `tests/` |
| `sprint.sh`, `DOCUMENTATION.md`, `GETSTARTED.md` | yes, via `ship.sh` | Launcher, user manual, onboarding guide |
| `docs/*/.TEMPLATE-*` | yes, via `ship.sh` | Work-item templates (task, bug, feature, idea, test, plan, crew); `create-*.sh` reads the `docs/` copy at runtime |
| `src/CLAUDE.md`, `src/AGENTS.md`, `src/.cursorrules`, `src/.windsurfrules`, `src/.github/` | yes, edit in `src/` | AI pointer files and GitHub templates; no `docs/` copy |
| `docs/tasks/`, `docs/plans/`, `docs/bugs/`, `docs/features/`, `docs/ideas/`, `docs/crew/` | folder only | Our own work; users get these folders empty |
| `docs/tests/`, `docs/guides/` | folder only | Our test suite (`bash docs/tests/run-all.sh`) and maintainer guides; users get these folders empty |
| `setup.sh`, `install.sh`, `ship.sh` | no | Installer, curl bootstrap, mirror tool |
| `CLAUDE.md`, `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md` | no | Development support |

Keep the `src/` AI pointer files to a few lines pointing at `DOCUMENTATION.md`.
The user owns those files in their project; the installer prepends a reference
or asks before creating one. Leave them as pointers: no enriching, generating,
or templatizing.

## Making a change

1. **Edit the live file** from the map: a script, help page, AI guidance, the
   manual, a `.TEMPLATE-*`, `setup.sh`, or a `src/` pointer file.
2. **Run it**: the real `./sprint.sh` command, then the suite. Full test
   ladder: [docs/guides/running-tests.md](docs/guides/running-tests.md).
3. **Keep the surfaces in step** in the same change:
   - A user-facing command (dispatch, registry, help, script, family,
     retirement) → `help/_registry`, its `help/<cmd>.md`, `DOCUMENTATION.md`,
     and [docs/guides/command-matrix.md](docs/guides/command-matrix.md).
     Check with `./sprint.sh validate --commands`; `--docs` checks help flags.
   - Provider / dual-host behavior (CLI profile, tool map, emit, subagents,
     model resolution, install tier) or a proven known unknown →
     [docs/guides/provider-reality.md](docs/guides/provider-reality.md).
4. **Log user-facing changes**: one plain-language bullet under `## Unreleased`
   in `CHANGELOG.md` (`### Added` / `### Changed` / `### Fixed`). Internal
   refactors need no entry.
5. **Ship** (maintainer): `./ship.sh`, then verify a fresh install. A broken
   install is a release blocker:

   ```bash
   mkdir /tmp/test-sprint && ./setup.sh   # enter /tmp/test-sprint, check output
   rm -rf /tmp/test-sprint
   ```

6. **Commit** (maintainer). `ship.sh` prints the suggested message.

Agents working through `work` or `chat` do steps 1–4 and stop.

## Tracking our own work

Create items with `./sprint.sh newtask "..."` (or `newbug`, `newidea`,
`newfeature`, `newplan`), which assign IDs and use the templates. Move task
files between lifecycle folders (`backlog → next → doing → review → done`, or
`blocked/`) with:

```bash
git mv SRC DEST || mv SRC DEST
```

`git mv` keeps history when the file is tracked; plain `mv` finishes the move
for a new, uncommitted task. `DOCUMENTATION.md` explains the whole system;
`./sprint.sh help <command>` covers each command.
