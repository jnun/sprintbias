# Task 395: Portable Claude Code status line and done-time hook as opt-in shell add-on

**Feature**: docs/features/portable-shell-setup.md
**Created**: 2026-10-04
**Docs**: none
**Plan**: 27
**From plan**: none
**Depends on**: 394
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-shell.sh
**Refined**: 1
**Reworked**: 0

## Problem

The maintainer's Claude Code status line shows session name, machine, path,
branch, clock, the time of the last reply, context left, and session cost. It
helps anyone driving SprintBias with Claude, but it lives in personal
`~/.claude/statusline-*.sh` scripts that run only on macOS (`stat -f`) and call
`npx ccusage@latest` over the network in the background. SprintBias users
cannot opt into it.

## Done when (automated)

- [ ] `docs/sprintbias/shell/` holds one status-line script and one Stop-hook
      script. Fed sample status-line JSON, the status line prints, in order:
      session name, short machine name, path, branch with a dirty marker,
      clock with zone and UTC offset, `done <time>` from the Stop hook,
      `ctx:N%`, and `$X.XX session`. `bash docs/tests/test-shell.sh` asserts
      each segment.
- [ ] The session name comes from `~/.claude/sessions/<pid>.json` (or
      `$CLAUDE_CONFIG_DIR/sessions`) matched by the input's `session_id`, the
      same source `./sprint.sh agents` reads. `bash docs/tests/test-shell.sh`
      asserts it with a fixture sessions folder.
- [ ] Both scripts use only calls that work on macOS and Linux, and still print
      a line when `jq` or `git` is missing. `bash docs/tests/test-shell.sh`
      asserts a line with each removed from `PATH`.
- [ ] The today-across-sessions total (`ccusage` via `npx`) is off by default
      and runs only when its option is set. `bash docs/tests/test-shell.sh`
      asserts no `npx` call by default.
- [ ] `./sprint.sh shell install --statusline` asks first, backs up
      `~/.claude/settings.json`, sets `statusLine`, and adds the Stop hook while
      keeping every other key and hook. `./sprint.sh shell remove` takes back
      only what install added. When the user already has their own
      `statusLine`, install says so and keeps it unless they confirm. `bash
      docs/tests/test-shell.sh` asserts all three against a fixture settings
      file with an unrelated key and hook.
- [ ] `./sprint.sh validate --commands` and `./sprint.sh validate --docs`
      pass, and `bash docs/tests/run-all.sh` passes.

## Signoff (human)

- [ ] In a live Claude Code session on macOS, install with `--statusline` and
      confirm the line reads cleanly and `done <time>` updates after a reply.
- [ ] Same check on a Linux machine.

## Notes

- Write the per-session done time under the per-user SprintBias folder from
  #394 (`${XDG_CONFIG_HOME:-$HOME/.config}/sprintbias/shell`), never inside
  `~/.claude/`, and prune old session files.
- Reference scripts on the maintainer's machine:
  `~/.claude/statusline-combined.sh`, `statusline-command.sh`, `statusline.sh`,
  `hooks/record-stop-time.sh`. Merge them into one status-line script; the
  combined wrapper exists only because they grew separately. The tests above
  define the required behavior where those files are absent.
- Merge `settings.json` with `python3` (already required); `jq` stays
  optional.
- #394 is in review/ with no `**Proof**:` line yet, so it has not landed and
  this task waits on it.
- Update `help/shell.md`, `DOCUMENTATION.md` if it lists shell flags,
  `docs/guides/command-matrix.md`, and `docs/guides/provider-reality.md` (this
  is a Claude Code feature; Grok Build users get the shell prompt only unless
  Grok offers an equivalent). Add an `### Added` bullet to `CHANGELOG.md`.

## References

docs/features/portable-shell-setup.md
docs/guides/provider-reality.md
