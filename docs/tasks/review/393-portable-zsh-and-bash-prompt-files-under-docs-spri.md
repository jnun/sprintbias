# Task 393: Portable zsh and bash prompt files under docs/sprintbias/shell

**Feature**: docs/features/portable-shell-setup.md
**Created**: 2026-10-04
**Docs**: none
**Plan**: 27
**From plan**: none
**Depends on**: none
**Dependents**: 394
**Parent**: none
**Crew**: none
**Tests**: docs/tests/test-shell.sh
**Refined**: 0
**Reworked**: 0

## Problem

The friendly prompt we built (machine name, path, branch with dirty marker, date and time
with zone and UTC offset, slow-command timer, tab titles) lives only in one
maintainer's `~/.zshrc`, mixed in with personal aliases and PATH lines. It uses
zsh-only features, so it cannot be offered to people on Ubuntu bash or older
macOS bash, and there is nothing in SprintBias to ship.

## Success criteria

- [x] `docs/sprintbias/shell/` holds a zsh prompt file and a bash prompt file that a user can `source` from their rc file.
- [x] Both give the same look: blue short machine name (`hostname -s`, e.g. `Jasons-MacBook-Air`), cyan path with `~` for home, magenta `(branch)` or `(branch*)` when there are staged or unstaged changes, yellow `Sat Oct 4 14:05:09 PDT (UTC-0700)`, red `Ns` duration when the last command ran 3 seconds or more, input on the second line, and the tab/window title set to the path (plus the running command while it runs).
- [x] Works on macOS zsh, macOS stock bash 3.2, and bash 5 on Ubuntu with no extra installs; where a shell lacks a feature (for example the timer on bash 3.2) that segment is dropped silently, never an error.
- [x] Sourcing either file in a non-interactive shell does nothing; `NO_COLOR` set gives the same prompt without color.
- [x] Sourcing the file twice does not double-register hooks or stack titles.
- [x] A test under `docs/tests/` runs `zsh -n` / `bash -n` on the files and renders the prompt once in each shell inside a temp git repo, checking the branch and dirty marker appear.

## Notes

Reference look: maintainer `~/.zshrc` (PROMPT, RPROMPT, `__git_branch`,
precmd/preexec, `precmd_title`/`preexec_title`). Ship only the prompt; leave out
aliases, PATH edits, `aws-use`, `ghsync`, Docker aliases, completions.

Portability gotchas:
- `EPOCHSECONDS` needs `zmodload zsh/datetime` in zsh; bash has it only in 5.0+.
- bash has no `preexec` or `RPROMPT`. `PS0` (bash 4.4+) or a DEBUG trap can start the timer; the clock can sit at the end of line one instead of the right edge.
- Use `git --no-optional-locks` so the prompt never blocks on a repo lock.
- Use `precmd_functions`/`preexec_functions` arrays in zsh and append to `PROMPT_COMMAND` in bash rather than defining bare `precmd`/`preexec`, so the user's own hooks keep working.

Keep the files plain and well commented: this is a learning tool and people
will read them.


### Work log (2026-10-04)

- Added `docs/sprintbias/shell/prompt.zsh` and `prompt.bash`. Over SSH the
  machine name turns bold red (`SSH_CONNECTION`/`SSH_TTY`) so a server never
  looks like your laptop.
- bash differs on purpose: it has no right-side prompt, so the clock sits at
  the end of line one. The window title shows the path only, because bash has
  no clean preexec for the running command. The timer uses `PS0` + `SECONDS`
  (bash 4.4+) and drops out on 3.2.
- Branch comes from `symbolic-ref --short` with a `rev-parse --short`
  fallback, so a brand-new repo shows its branch and a detached HEAD shows the
  commit.
- Left out the maintainer's `REPORTTIME=3`. It makes zsh print its own timing
  report, so it is a personal choice.
- Verified on macOS (zsh, bash 3.2) and in an Ubuntu 24.04 container (bash 5,
  zsh): `docs/tests/test-shell.sh` 37/37.

### Audit (2026-10-04)

- Branch and dirty state now come from one `git status --porcelain=v2
  --branch` call instead of three git processes: about 14 ms vs 40 ms per
  prompt on this repo.
- bash `__sb_precmd` keeps `$?`, so later PROMPT_COMMAND hooks still see the
  last command's exit status. An existing `PS0` is kept, not overwritten.
- zsh uses `SECONDS` like bash (no `zmodload zsh/datetime`). The title is one
  `print` (two arguments would have printed a stray space). The `~` path
  substitution is quote-safe.

## References

docs/features/portable-shell-setup.md
docs/sprintbias/lib.sh
docs/tests/run-all.sh
