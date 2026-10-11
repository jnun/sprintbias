# Task 433: Decide where work routes a task that ends a run without Completed

**Feature**: none
**Created**: 2026-10-10
**Docs**: none
**Plan**: none
**From plan**: 32
**Depends on**: none
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

When a worker ends its run with no `## Completed` (out of turns, crashed mid-task), work routes the task to blocked/ as Incomplete. That work did start, so under the finishing rule blocked/ is the wrong home: blocked/ is for work that cannot start. Retrying in place risks a loop that re-runs a task forever.

## Done when (automated)

- [ ] An incomplete task lands where the next `./sprint.sh work` resumes it (next/ with its `## Outcome` kept), retried at most once per run, and the end-of-run recap names `./sprint.sh work <id>` (`bash docs/tests/test-proof-loop.sh`)
- [ ] `loop` stops retrying a task that came back incomplete twice and lists it with its log (`bash docs/tests/test-dep-work.sh`)

## Signoff (human)

- [ ]

## Notes

Filed from plan 32's task 426, which kept today's route to stay in scope.

## References

docs/sprintbias/scripts/work.sh
docs/sprintbias/scripts/loop.sh
