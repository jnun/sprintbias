# Task 392: Add crew: named agent sessions with roles, a lead that coordinates them, and a Crew field that routes and claims tasks

**Feature**: none
**Created**: 2026-10-04
**Docs**: none
**Plan**: none
**From plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Crew**: none
**Tests**: docs/tests/test-crew.sh
**Refined**: 0
**Reworked**: 0

## Problem

People already run several AI sessions side by side on one project and give each a name and a job: a lead that keeps everyone rowing, a builder, a cloud production operator, a bug fixer. Today that setup lives in their heads and is retyped every morning ("Your name is Dill..."). Session names drift between restarts, so agents lose track of each other, and nothing stops two sessions from picking up the same task. SprintBias should make a crew repeatable: each member's role written down once, started by name, and the tasks in flight showing who holds them.

## Success criteria

- [x] A crew member is a markdown file at `docs/crew/<name>.md` holding the role, what it reads first, what it may touch, and how it reports. `./sprint.sh crew add <name> "<role>"` creates one from `docs/crew/.TEMPLATE-crew.md`.
- [x] `./sprint.sh crew` lists the crew and the tasks each member holds (no AI).
- [x] `./sprint.sh crew <name> [plan-id or task-id]` starts an interactive AI session named `<name>` with the crew rules, the member's file and the optional target loaded.
- [x] A member file marked `**Lead**: yes` gets lead rules: run the plan, route tasks, keep the plan's `## Crew` board current, and leave product code to the others.
- [x] Tasks carry a `**Crew**:` field. Setting it routes the task to a member; a member moving a task into `doing/` sets it to their own name, which is the claim.
- [x] Registry row, help page, manual section, command matrix, changelog entry, starter folder in `setup.sh` and the template in `ship.sh` are all in place; `./sprint.sh validate --commands` and `--docs` pass.
- [x] `docs/tests/test-crew.sh` covers add, list, the claim display and the prompt a member starts with.

## Notes

Comes from running a crew by hand on a real project (Orcha the lead, Devops the builder, Cloudy for cloud production ops, Dill for bugs). Ship generic starter wording; the names are the user's.

The files are the shared state. Messages between sessions (Claude Code's SendMessage) are the nudge, not the record, so the feature works for any provider.

## References

docs/sprintbias/scripts/chat.sh
docs/sprintbias/lib.sh
docs/sprintbias/help/_registry

## Completed

Built `crew` as one command in the work family. Members are files in `docs/crew/`; the claim is the task's new `Crew` field plus the `doing/` folder, so there are no lock files and no new stage. Sessions start through the existing `sprintbias_run_interactive` with `--name <member>` and no tool allowlist, so a member can message others by crew name. `./sprint.sh validate`, `validate --commands`, `validate --docs`, `test-crew.sh` (23 checks) and the related existing suites pass. `./ship.sh --dry-run` lists the template, script and help page. Not yet run: `./ship.sh` and a fresh `setup.sh` install (human-owned).

### Files changed
docs/sprintbias/scripts/crew.sh
docs/sprintbias/help/crew.md
docs/sprintbias/guides/crew.md
docs/sprintbias/learning/crew.py
docs/sprintbias/learning/README.md
docs/sprintbias/help/_registry
docs/crew/.TEMPLATE-crew.md
docs/tasks/.TEMPLATE-task.md
docs/tests/test-crew.sh
docs/guides/command-matrix.md
sprint.sh
DOCUMENTATION.md
CHANGELOG.md
setup.sh
ship.sh
