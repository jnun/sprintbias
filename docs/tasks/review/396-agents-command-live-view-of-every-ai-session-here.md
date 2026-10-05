# Task 396: agents command: live view of every AI session here and on AGENT_HOSTS servers, with label to title each terminal

**Feature**: none
**Created**: 2026-10-05
**Docs**: none
**Plan**: none
**From plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Crew**: none
**Tests**: docs/tests/test-agents.sh
**Refined**: 0
**Reworked**: 0

## Problem

A person running several AI sessions at once, on a laptop and on a dev server,
cannot see them together. They cannot tell which terminal tab holds which named
session, which ones are busy or waiting for them, how long each has run, or what
each is working on, without opening every tab and logging in to every server.

## Success criteria

- [x] `./sprint.sh agents` lists every running session on this machine: name, busy / waiting / idle and for how long, terminal app and tty (or tmux session:window), project and branch, uptime, last activity, model, context size, CPU and memory summed over its child processes, and a second line with crew role, topic and last prompt.
- [x] Hosts in `AGENT_HOSTS` (config or config.local) and `--host H` are listed over ssh in batch mode; an unreachable host shows the reason and the rest still list. `--local` skips hosts.
- [x] `--json` prints the same facts for scripts.
- [x] `./sprint.sh agents label` titles each terminal tab, or renames each tmux window, with the session name, here and on the hosts.
- [x] Registry files left by ended sessions are skipped; a host whose Claude Code keeps no registry still shows its `claude` processes as `claude-<pid>`.
- [x] Registry, dispatch, help page, manual, command matrix and changelog list the command; `validate --commands` and `validate --docs` pass for it.
- [x] `docs/tests/test-agents.sh` covers the listing, JSON, flags and an unreachable host.

## Notes

Reads Claude Code's own records: `~/.claude/sessions/<pid>.json` (name, status,
cwd, start time) and the transcript `~/.claude/projects/<cwd-slug>/<sessionId>.jsonl`
(ai-title, last-prompt, the main thread's last model and usage). Python 3 stdlib
only, so the same file runs on a server through `ssh HOST python3 - --collect`.
Claude-only for now; `docs/guides/provider-reality.md` should note what Grok
Build users get once its session records are known.

Claude Code retitles the terminal as it works, so a `label` stamp lasts until the
next retitle; sessions started with a name (`crew <name>`) keep it. Task 395 adds
the session name to the portable status line.

## References

docs/sprintbias/scripts/crew.sh
docs/tasks/backlog/395-portable-claude-code-status-line-and-done-time-hoo.md

## Completed

### Files changed
docs/sprintbias/scripts/agents.sh
docs/sprintbias/scripts/agents.py
docs/sprintbias/help/agents.md
docs/sprintbias/help/_registry
docs/sprintbias/config
sprint.sh
DOCUMENTATION.md
docs/guides/command-matrix.md
CHANGELOG.md
docs/tests/test-agents.sh

### Doc follow-ups
- `docs/guides/provider-reality.md` — note `agents` reads Claude Code session records; Grok Build support unknown
