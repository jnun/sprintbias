# Task 395: Portable Claude Code status line and done-time hook as opt-in shell add-on

**Feature**: docs/features/portable-shell-setup.md
**Created**: 2026-10-04
**Docs**: none
**Plan**: 27
**From plan**: none
**Depends on**: 394
**Dependents**: none
**Parent**: none
**Crew**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

The Claude Code status line we built (machine name, path, branch, clock, "done" time of the
last reply, context left, session cost, and today's total) is valuable for
anyone driving SprintBias with Claude, but it lives in personal
`~/.claude/statusline-*.sh` scripts that only run on macOS (`stat -f`) and quietly
call `npx ccusage@latest` in the background.

## Success criteria

- [ ] `docs/sprintbias/shell/` holds a status-line script and a Stop-hook script that reproduce today's segments: blue short machine name, cyan path, magenta branch with dirty marker, yellow clock with zone and UTC offset, green `done <time>` from the Stop hook, dim `ctx:N%` and `$X.XX session`.
- [ ] The status line leads with the session's name (bold), read from Claude Code's `~/.claude/sessions/<pid>.json` registry by the input's `session_id`, so each terminal shows the same name `./sprint.sh agents` and other sessions use. Reference: maintainer `~/.claude/statusline-command.sh` (added 2026-10-05).
- [ ] Both run on macOS and Linux (no `stat -f`-only or GNU-only calls) and print a usable line even when `jq` or git is missing.
- [ ] The today-across-sessions total via `ccusage` is off by default and turned on with an explicit option, because it reaches the network through `npx`.
- [ ] `./sprint.sh shell install --statusline` asks first, backs up `~/.claude/settings.json`, sets `statusLine` and adds the Stop hook while keeping every existing setting and hook, and `shell remove` takes back only what it added.
- [ ] If the user already has a `statusLine` of their own, install says so and leaves it alone unless they confirm replacing it.
- [ ] `docs/guides/provider-reality.md` notes this is a Claude Code feature and what Grok Build users get (the shell prompt only, unless Grok exposes an equivalent).
- [ ] A test feeds sample status-line JSON to the script and checks the segments, and checks the settings merge keeps an unrelated existing key and hook.

## Notes

Reference scripts: maintainer `~/.claude/statusline-combined.sh`,
`statusline-command.sh`, `statusline.sh`, `hooks/record-stop-time.sh`. Merge them
into one status-line script; the "combined" wrapper exists only because they
grew separately.

Write the per-session done time under the per-user SprintBias location from
task 394, not inside `~/.claude/`, and prune old session files.

## References

docs/features/portable-shell-setup.md
docs/guides/provider-reality.md
