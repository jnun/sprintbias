# Feature: Portable shell setup

**Status:** BACKLOG
**Created:** 2026-10-04
**Updated:** 2026-10-04

## Overview

A ready-made, friendly terminal prompt that SprintBias offers to install for
people learning to develop on the command line. It shows which machine you are on, where you are (path),
what branch you are on (with an uncommitted-changes marker), the date, time,
time zone and UTC offset, and how long the last slow command took. An optional
add-on brings the same look to the Claude Code status line, plus context left,
session cost, and when the AI last finished a reply.

It works the same in macOS Terminal (zsh) and on Ubuntu or other Linux (bash),
installs as one clearly marked line in the user's own shell file, and updates
in place as we keep improving it.

## User Stories

- As a developer with more than one machine (or an SSH session), I want the machine name in my prompt, so that I always know which computer I am typing into.
- As someone new to the CLI, I want a prompt that tells me where I am and which branch I am on, so that I stop running commands in the wrong place.
- As a developer who works across a Mac and a Linux box, I want the same prompt on both, so that I read my terminal the same way everywhere.
- As a user who already customized my shell, I want SprintBias to add one marked line and never rewrite my file, so that I can try it and remove it cleanly.
- As a Claude Code user, I want the status line to show path, branch, clock, context left, and session cost, so that I can see what the session is doing and spending.
- As a SprintBias maintainer, I want the prompt to live as plain files under `docs/sprintbias/shell/`, so that improvements ship with every `./ship.sh` and reach users on their next `sprint shell install`.

## Requirements

- [ ] Prompt files for zsh and bash with matching look: blue short machine name, cyan path, magenta branch with `*` when dirty, yellow date/time/zone/UTC offset, red duration for commands over 3 seconds, terminal tab and window title set to the path.
- [ ] Works on macOS default zsh, macOS stock bash 3.2, and bash 5 on Ubuntu; degrades quietly (drops a segment) when a feature is missing rather than printing errors.
- [ ] Only the prompt ships. Personal aliases, PATH lines, cloud and Docker helpers from the maintainer's own config stay out.
- [ ] One command, `./sprint.sh shell`, to see status, install, update, and remove. Install adds a single marked block to the user's rc file, backs the file up first, and is safe to run twice.
- [ ] The Claude Code status line and Stop hook are opt-in, merged into `~/.claude/settings.json` without dropping the user's existing settings, and work without network access (cost-of-today lookup is optional).
- [ ] Respects `NO_COLOR` and does nothing in non-interactive shells.
- [ ] Over SSH the machine name turns bold red; an optional tmux add-on (`shell install --tmux`) shows the host in the status bar (red over SSH) and in the outer terminal title.

## Acceptance Criteria

- [ ] On a Mac, `./sprint.sh shell install` then opening a new Terminal tab shows the SprintBias prompt; `./sprint.sh shell remove` restores the rc file to exactly its prior content.
- [ ] On Ubuntu bash, the same two commands give the same prompt and the same clean removal.
- [ ] Running install twice leaves one block, not two.
- [ ] After `./ship.sh`, a fresh `setup.sh` install contains `docs/sprintbias/shell/` and `./sprint.sh help shell` works.
- [ ] With the status-line add-on installed, Claude Code shows machine name, path, branch, clock, context left, and session cost on both macOS and Linux.

## Implementation Tasks

- [ ] Task #393 - Portable zsh and bash prompt files under docs/sprintbias/shell
- [ ] Task #394 - `sprint shell` command to install, update, and remove the prompt
- [ ] Task #395 - Portable Claude Code status line and done-time hook as opt-in add-on

## Notes

Source of the current look: the maintainer's `~/.zshrc` (PROMPT/RPROMPT,
`__git_branch`, precmd/preexec timers and titles) and `~/.claude/statusline-*.sh`
plus `~/.claude/hooks/record-stop-time.sh`. Those files are reference only; the
shipped versions are rewritten to be portable and free of personal settings.

The user's shell rc files are theirs, the same way `CLAUDE.md` and `AGENTS.md`
are: add one marked line, ask before touching, never rewrite.

Later, not now: fish support, a starship preset, and a theme switch. Keep the
first version dependency-free so a brand-new laptop gets it with no installs.
