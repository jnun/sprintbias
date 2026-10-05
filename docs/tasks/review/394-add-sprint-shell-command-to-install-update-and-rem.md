# Task 394: Add sprint shell command to install, update, and remove the prompt

**Feature**: docs/features/portable-shell-setup.md
**Created**: 2026-10-04
**Docs**: none
**Plan**: 27
**From plan**: none
**Depends on**: 393
**Dependents**: 395
**Parent**: none
**Crew**: none
**Tests**: docs/tests/test-shell.sh
**Refined**: 0
**Reworked**: 0

## Problem

Shipping prompt files is not enough: a person learning the CLI should not have
to edit `~/.zshrc` by hand to try them, and must be able to undo it cleanly.
Their rc file is theirs, so SprintBias needs one safe, repeatable way to add,
refresh, and remove the prompt without touching anything else in it.

## Success criteria

- [x] `./sprint.sh shell` (no args) shows which shell is in use, which rc file applies, and whether the SprintBias prompt is installed and current. No changes made.
- [x] `./sprint.sh shell install` asks before changing anything, backs up the rc file, copies the prompt files to a stable per-user location (so it keeps working if the project folder moves or is deleted), and adds one marked block (`# >>> sprintbias shell >>>` … `# <<< sprintbias shell <<<`) that sources them.
- [x] Running `shell install` again refreshes the copied files and leaves exactly one block. This is the update path when a new SprintBias version ships prompt improvements.
- [x] `./sprint.sh shell remove` deletes the block and the copied files, and the rc file matches its pre-install content byte for byte.
- [x] Picks `~/.zshrc` for zsh and `~/.bashrc` for bash (on macOS bash also makes sure a login shell reaches it); a `--zsh` / `--bash` flag picks explicitly.
- [x] `shell` is in `help/_registry` (keep group) with a `help/shell.md` page, in the dispatch table, and in `DOCUMENTATION.md`; `./sprint.sh validate --commands` and `--docs` pass.
- [x] `docs/guides/command-matrix.md` has the new row and `CHANGELOG.md` has an Unreleased/Added bullet.
- [x] A test under `docs/tests/` runs install, install, remove against a temp `HOME` for both shells and checks idempotency and exact restore.

## Notes

Pattern to follow: the grok installer block in the maintainer's `~/.zshrc`
(`# >>> grok installer >>>`) and how `setup.sh` prepends one pointer line to a
user's `CLAUDE.md` instead of rewriting it.

Suggested stable location: `${XDG_CONFIG_HOME:-$HOME/.config}/sprintbias/shell/`.

The prompt files live in `docs/sprintbias/shell/`, so `./ship.sh` mirrors them
into `src/` automatically; no `ship.sh` manifest change needed.

Common-language name: `shell`. Sub-forms are `install` and `remove`; bare is
status. Avoid "dotfiles" or "rc" in user-facing text.


### Work log (2026-10-04)

- `docs/sprintbias/scripts/shell.sh`: bare = status per part (zsh / bash /
  tmux: installed, not set up, or not on this machine); `install` (alias
  `update`) / `remove` (alias `uninstall`). With no terminal and no `--yes`,
  it refuses.
- Install is guided (human ask, 2026-10-04). It asks one question per part,
  defaulting to what fits the machine: zsh for macOS / zsh login, bash for
  Linux / bash login, tmux yes when tmux is installed (framed for remote server
  sessions). It skips with a hint when a tool is missing, then confirms once.
  `--zsh` / `--bash` / `--tmux` name parts directly and can be mixed. Bare
  `--yes` sets up the login shell plus tmux if installed. The closing message
  says how to see it (new tab, or re-login over SSH) and that each new server
  needs its own install. The original `--no-tmux` flag was dropped as
  redundant with picks.
- Added an optional tmux add-on (`docs/sprintbias/shell/tmux.conf`, sourced
  from a marked block in `~/.tmux.conf`). It shows the host in the status bar,
  turns the bar red over SSH, sets the outer title to host - session - window,
  and adds comfortable defaults: mouse, scrollback, splits that keep the
  folder. Separators are ASCII so a C-locale server renders them.
- Exact restore: a `.state` file in the per-user folder records any shell file
  we created (deleted again on remove if empty) and any file we gave a
  trailing newline (taken back on remove).
- The backup `<file>.sprintbias-bak` is written once, on the first install
  into that file.
- Wired into sprint.sh dispatch, `_registry` (keep), `help/shell.md`,
  DOCUMENTATION.md, command-matrix, and CHANGELOG. `validate --commands` and
  `--docs` pass.

### Audit (2026-10-04)

- Login file: bash login shells read only the first of `.bash_profile`,
  `.bash_login`, `.profile`. The block goes there only when that file does
  not already load `.bashrc`. `.bash_profile` is created only when none
  exist; the old macOS rule could create one and hide the user's `.profile`.
  Applies on Linux too: SSH users with their own `.bash_profile` now get the
  prompt.
- Blocks write `$HOME/...`, not an absolute path, so synced dotfiles work
  across machines. tmux expands `$HOME` in `source-file` (checked on 3.4 and 3.7).
- Remove no longer eats a user's trailing newline when they added lines after
  our block. The awk rewrite also dropped the `perl` dependency. The backup is
  deleted once the file matches it again.
- Cleanup: one file list (`all_targets`), `need_terminal`, `ask_shell`,
  `host_name` via `uname -n`, no `A && B || C`, `cmd_$ACTION` dispatch.
  shellcheck is clean apart from the usual lib.sh source note.
- Test: 48 checks (exit status kept, login-file cases, `$HOME` block loads in
  a real shell, newline edge case, backup cleanup). Pass on macOS and Ubuntu
  24.04.

## References

docs/features/portable-shell-setup.md
docs/sprintbias/help/_registry
docs/sprintbias/help/config.md
docs/sprintbias/scripts/config.sh
sprint.sh
setup.sh
DOCUMENTATION.md
docs/guides/command-matrix.md
CHANGELOG.md
