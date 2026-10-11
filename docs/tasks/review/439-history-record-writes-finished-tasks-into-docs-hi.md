# Task 439: history record writes finished tasks into docs/history

**Feature**: none
**Created**: 2026-10-10
**Docs**: none
**Plan**: 31
**From plan**: none
**Depends on**: 421, 423
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-history.sh
**Refined**: 0
**Reworked**: 0

## Problem

Only `plan done` writes history, so two kinds of finished work never reach
`docs/history/`: tasks done outside any plan (83 of 148 in this repo's
`done/`) and tasks whose plan was retired before records existed (plans 11,
12, 13, 15, 16, 18, 21, 22, 23, 24, 25). A person wants one command that writes them down, so `docs/history/`
covers all finished work once each plan in flight closes.

## Done when (automated)

- [x] `./sprint.sh history record` writes `docs/history/YYYY-MM-DD-tasks.md`
      (`-2`, `-3`… when that day's file exists) covering every `done/` task
      that no existing record names (by its `- #ID —` line) and that is
      either `**Plan**: none` or in a plan whose file no longer exists in
      `docs/plans/`. A task with no `**Plan**` line counts as `none`.
      Members of open plans are left
      for `plan done`, so no task is ever written twice.
      `bash docs/tests/test-history.sh`
- [x] The record uses task 421's line shape and summary rule:
      `# Work recorded YYYY-MM-DD`, a `**Finished**` header line with the task
      count, one `### Plan N: <title>` group per retired plan (title from the
      deleted plan file in git history, else `Plan N`), then `### Other work`;
      each line `- #ID — title: <summary> (docs/tasks/done/<file>.md)`.
      `bash docs/tests/test-history.sh`
- [x] With nothing to record it writes no file, prints "History is up to date
      with done/.", and exits 0. The
      record is `git add`ed in a git work tree; pure shell, no AI.
      `bash docs/tests/test-history.sh`
- [x] `history` and `history --since` (task 423) read these records too: the
      list shows them as `<date> · tasks · <count> tasks`, and the notes put
      their lines under `### Other work` after the plan sections, keeping each
      `### Plan N` group. `bash docs/tests/test-history.sh`
- [x] Surfaces in step: `help/_registry` (`history` row gains `record`),
      `help/history.md`, `DOCUMENTATION.md`, `docs/guides/command-matrix.md`.
      `./sprint.sh validate --commands` and `bash docs/tests/run-all.sh` pass;
      one `### Added` bullet in `CHANGELOG.md`.

## Signoff (human)

- [ ] Run `./sprint.sh history record` in this repo (the first run backfills
      every planless task and every retired plan's members) and check the record
      reads as an honest account of where the project is.

## Notes

- Decided: write records rather than scan `done/` at read time, because then
  `docs/history/` is the one source the `history` views read, and records
  survive any later pruning of `done/`.
- Decided: leave members of open plans to `plan done`, because recording them
  here too would list a task twice and need a dedupe rule; `plan check` already
  shows where an open plan stands.
- Decided: `**Finished**` on a `history record` file is the day it was
  written, because tasks carry no reliable finish stamp. A backfill therefore
  lands in one dated record; `--since <git ref>` (tree comparison) stays exact.
- Decided: `history record` is run by hand (before a release or whenever),
  because writing on every `promote` would create a file per task.
- Decided: a `done/` task with no `**Plan**` line counts as `**Plan**: none`,
  because 72 of this repo's 148 `done/` tasks predate the field; together with
  the 11 stamped `none` they make the 83 planless tasks the Problem counts.
- Decided: "retired plan" means any plan id whose file is absent from
  `docs/plans/` (today 11, 12, 13, 15, 16, 18, 21, 22, 23, 24, 25), not only
  the four named when the task was written, because the rule, not a list,
  decides; plan 21 has no deleted file in git history, so its group heading
  falls back to `Plan 21`.
- Hint: `git log --diff-filter=D --format=%h -1 -- 'docs/plans/N-*'` finds
  the commit that deleted plan N; its parent holds the title line.
- Decided: once 421 lands, a retired plan with a `docs/history/*-plan-N-*.md`
  record still has its members recorded only by `- #ID —` match, so a plan
  retired through `plan done` never repeats here.

## References

docs/sprintbias/scripts/history.sh
docs/sprintbias/scripts/plan-done.sh
docs/tests/test-history.sh
docs/sprintbias/help/history.md
docs/sprintbias/help/_registry
docs/tasks/next/421-plan-done-writes-a-history-record-to-docs-history.md
docs/tasks/next/423-generate-release-notes-from-docs-history-records.md
docs/plans/31-plan-history-in-docs-history.md

## Grounding

**Sources:** `CLAUDE.md` / `CONTRIBUTING.md` (repo map, docs/ → src/ flow,
surfaces kept in step), `docs/sprintbias/help/_registry` (command catalog),
`DOCUMENTATION.md` (user manual, lifecycle folders, plans),
`docs/guides/command-matrix.md` (command surface matrix), task 421 (history
record format and summary rule), task 423 (`history` reader and
`docs/tests/test-history.sh`)
**Terms:**
- None. The project has no glossary (`docs/sprintbias/project.md` not yet
  created).
**Conflicts:**
- Task vs current code: `docs/sprintbias/scripts/history.sh`,
  `docs/tests/test-history.sh`, `help/history.md`, the `history` registry row
  and `docs/history/` do not exist yet → they come from 421 and 423, recorded
  as `**Depends on**: 421, 423`; this task extends them.
- Task text vs repo state: the Problem named plans 18, 22, 23, 24 as the
  retired ones, but 11, 12, 13, 15, 16, 21 and 25 are also absent from
  `docs/plans/` with members in `done/` → the absent-file rule governs; text
  corrected (see Decided).
- Task vs code: 72 `done/` tasks carry no `**Plan**` line at all → read as
  `none` (see Decided).
- "plan" here is the task-grouping (the CLI is "sprint"), per the manual; no
  conflict.
- Task 421's `member_summary` lives in `plan-done.sh`; `history record` needs
  the same rule → move it to `lib.sh` as `sprintbias_task_summary` and call it
  from both (421 is in review/, no agent holds it).

**Touching:** docs/sprintbias/scripts/history.sh, docs/sprintbias/lib.sh,
docs/sprintbias/scripts/plan-done.sh, docs/tests/test-history.sh,
docs/sprintbias/help/history.md, docs/sprintbias/help/_registry,
DOCUMENTATION.md, docs/guides/command-matrix.md, CHANGELOG.md

## Questions

**Status: READY**

### Already complete
None — no matching implementation found.
- No `history.sh`, `test-history.sh`, `help/history.md` or `history` registry
  row exists; `docs/history/` is absent; `plan-done.sh` still deletes the plan
  without a record (421 in next/ builds that, 423 builds the reader).
- Verified counts: 148 tasks in `done/`, 11 stamped `**Plan**: none`, 72 with
  no `**Plan**` line; retired-plan members in `done/` belong to plans 11, 12,
  13, 15, 16, 18, 21, 22, 23, 24, 25.

### Remaining work
- `history record` subcommand: select unrecorded `done/` tasks that are
  planless or in a retired plan, group by retired plan (title from git
  history, else `Plan N`) then `### Other work`, write
  `docs/history/YYYY-MM-DD-tasks[-N].md` with 421's line shape and summary
  rule, `git add` it; no-op message and exit 0 when nothing to record.
- Extend 423's list and `--since` notes to read `*-tasks.md` records
  (`<date> · tasks · <count> tasks`; lines under `### Other work` after plan
  sections).
- Fixtures in `docs/tests/test-history.sh` for: planless, missing `**Plan**`
  line, retired plan, open-plan member skipped, already-recorded skipped,
  same-day suffix, empty run.
- Surfaces: `_registry`, `help/history.md`, `DOCUMENTATION.md`,
  `command-matrix.md`, `CHANGELOG.md` `### Added`; `validate --commands` and
  `run-all.sh` green.

### Questions for the developer
None — task is fully defined.

## Completed

**Summary**: `./sprint.sh history record` writes every finished task no record covers (planless, or in a retired plan) into a dated `docs/history/YYYY-MM-DD-tasks.md`, and `history` / `history --since` read those records beside the plan records.

### Assumptions
- Decided: a plan record's `## Follow-ups` lines do not count as "recorded", because they name work that was still open when the plan closed; counting them would skip that task forever once it lands in done/.
- Decided: a retired plan whose deletion is not committed yet takes its title from `HEAD`, because this repo's plans 18, 22, 23 and 24 are deleted only in the working tree and would otherwise fall back to `Plan N`.
- Decided: the summary rule moved from `plan-done.sh` into `lib.sh` as `sprintbias_task_summary`, because `plan done` and `history record` must write the same line shape.
- Decided: the list line is printed exactly as `<date> · tasks · <count> tasks` (also for a count of 1), because the task specifies that shape.
- Decided: `history record` takes no arguments and errors on any, because there is nothing to choose; it is the only `history` form that writes, noted in the help and the command matrix.

### Files changed
- docs/sprintbias/scripts/history.sh
- docs/sprintbias/lib.sh
- docs/sprintbias/scripts/plan-done.sh
- docs/tests/test-history.sh
- docs/sprintbias/help/history.md
- docs/sprintbias/help/_registry
- DOCUMENTATION.md
- docs/guides/command-matrix.md
- CHANGELOG.md

### Tests run
- `bash docs/tests/test-history.sh` — 60 passed (after breaker)
- `bash docs/tests/test-plan-lifecycle.sh` — 130 passed (shared summary rule)
- `./sprint.sh validate --commands` and `--docs` — clean
- `bash docs/tests/run-all.sh` — 36 of 36 scripts green

**Proof**: 2026-10-11 · bash docs/tests/test-history.sh; bash docs/tests/test-plan-lifecycle.sh; ./sprint.sh validate --commands · pass

**Breaker**: 11 cases tried · 3 fixed · 0 filed
- Fixed: a board in a subfolder of a larger git repo lost retired-plan titles (git paths were repo-root relative); now `git log --relative` and `rev:./path`.
- Fixed: a CRLF task file put a carriage return inside its record line; the title is stripped of `\r`.
- Fixed: `**Plan**: 07` missed open plan 7 and was recorded early (then again by `plan done`); the id is read as a number.
