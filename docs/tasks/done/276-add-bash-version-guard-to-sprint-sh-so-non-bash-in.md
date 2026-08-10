# Task 276: Add BASH_VERSION guard to sprint.sh so non-bash invocation fails clearly

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Depends on**: none
**Blocks**: none
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

Users and agents sometimes invoke the CLI as `zsh sprint.sh`, `sh sprint.sh`, or
another non-bash interpreter. That bypasses the shebang and dies on bashisms
(`BASH_SOURCE`, arrays, `[[ ]]`) with cryptic errors. `setup.sh` already refuses
non-bash; `sprint.sh` did not. Interactive shell (zsh on Mac) is fine when the
user runs `./sprint.sh` — only forced wrong-interpreter invocation is the bug.

## Success criteria

- [x] `sprint.sh` exits immediately with a clear error when `BASH_VERSION` is unset
- [x] Message tells the user to run `./sprint.sh` or `bash sprint.sh`
- [x] Normal `./sprint.sh help` (and the setup alias `sprint='./sprint.sh'`) still work
- [x] Guard sits before `set -u` so the check itself cannot trip nounset
- [x] Change ships via `./ship.sh` so `src/sprint.sh` matches

## Notes

- Mirror `setup.sh` guard style; do not require bash 4+ or Homebrew bash.
- Option 1 policy: write around stock bash 3.2; interactive shell is irrelevant.
- Out of scope: fish auto-alias, walk-up-to-root default, alias offer on update.
- On macOS, `/bin/sh` is often bash in POSIX mode, so `BASH_VERSION` is set and
  the guard does not fire — same as `setup.sh`. Real non-bash (`zsh`, dash as
  `sh` on many Linux hosts) is refused.

## References

setup.sh
DOCUMENTATION.md
docs/sprintmd/guides/sprint_command.md

## Completed

### Files changed
sprint.sh
DOCUMENTATION.md
src/sprint.sh
src/DOCUMENTATION.md
src/VERSION

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
