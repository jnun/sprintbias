# Task 391: Add plan check <id> read-only plan health report

**Feature**: none
**Created**: 2026-09-15
**Docs**: none
**Plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

A user with a plan in flight wants one read-only glance that answers "where does
this plan actually stand?" — without opening every member task by hand. A plan
is a relational index whose members live in their own lifecycle folders, so its
real progress is scattered across `backlog/next/doing/review/done`, and each
member can be anywhere from not-yet-defined to finished. Today the only way to
learn that is to open the plan file, list its members, and inspect each task's
folder and body one at a time.

The user wants `./sprint.sh plan check <id>` to read the plan and its members and
print a health rollup, changing nothing on disk. It answers three questions at a
glance: how far along the plan is, where each member sits in the lifecycle, and
how well-formed each member is.

## Success criteria

- [x] `./sprint.sh plan check <id>` prints a health report for the named plan
      and exits 0; with no id it either reports the sole plan or lists the plans
      to choose from. It is strictly read-only — no task or plan file is created,
      edited, moved, or deleted, and no AI/model call is made.
- [x] The report states the plan's overall state as one of **started**,
      **in process**, or **completed**, derived from the plan `**Status:**` field
      plus where its members live (STARTED with no member past next/ reads as
      started; at least one member in doing/review/done but not all done reads as
      in process; every member in `docs/tasks/done/` reads as completed — the
      point where `plan done` would retire it).
- [x] For every member, the report shows which lifecycle folder it currently
      sits in — backlog, next, review, or done (also doing and blocked) — and a
      count rollup across those folders so the spread is visible at a glance.
- [x] For every member, the report shows a definition state of **undefined**,
      **defined**, **in process**, or **abandoned**, read from the task file:
      undefined = not fully defined (placeholder/empty success criteria, open
      `### Questions for the developer`, or sitting in blocked/); defined =
      real success criteria and no open questions; in process = a live claim in
      doing/; abandoned = a stale doing/ claim left unfinished (the same state
      `work` reclaims). See [[blocked-vs-dependent]] — blocked is undefined, not
      abandoned.
- [x] A member listed in the plan that has no task file anywhere is reported as
      missing rather than silently dropped, and a plan with zero members reports
      cleanly instead of erroring.
- [x] `plan check` is wired as a real subcommand: `plan` usage lists it, `plan
      check --help` explains it, and the four command surfaces agree
      (`./sprint.sh validate --commands` passes). The command matrix guide gains
      its row.

## Notes

Read-only health report — the opposite of `plan start` (which gates and moves
members) and `plan done` (which deletes on a full pass). This command only
inspects and prints, so it must not source the gate or make model calls.

Reuse existing plan plumbing rather than re-deriving it: `plan-done.sh` already
has `member_stage()` (which folder a member sits in) and the shared
`sprintbias_list_plans` / `sprintbias_find_plan` helpers in `lib.sh`. Plan
`**Status:**` is DRAFT | READY | STARTED only — never a folder, never a stored
DONE; completion is "every member in done/", not a written status.

The three plan states the user asked for map onto SprintBias reality as above;
keep the exact started/in-process boundary simple and documented in the help so
the rollup reads the same to a person and an agent. next/ IS the sprint —
inspect it live, never cache a member list.

Definition state is inferred from the task body, not stored: an undefined task
has empty or placeholder success-criteria checkboxes or an open Questions
section. Do not add a new stamp to task files to support this — derive it.

## References

docs/sprintbias/scripts/plan.sh
docs/sprintbias/scripts/plan-done.sh
docs/sprintbias/scripts/plan-start.sh
docs/sprintbias/scripts/lib.sh
docs/sprintbias/help/plan.md
docs/guides/command-matrix.md
docs/sprintbias/ai/task-creation.md

## Completed

Added `./sprint.sh plan check <id>` — a pure-shell, read-only plan health
report (no AI, no file moves). It resolves a plan (or the sole plan / an
interactive pick), reads its members via the shared lib helpers, and prints:
plan state (not started / started / in process / completed, from **Status:** +
where members live), a lifecycle count rollup + per-member folder, and a
per-member definition state (undefined / defined / in process / abandoned)
derived from the task body — open Questions or placeholder success criteria =
undefined; a live doing/ claim = in process; a doing/ claim with a failure
stamp = abandoned; worked members in review/done = defined. Missing member
files and empty plans report cleanly. Verified read-only against live plans
(no task/plan files changed); `validate --commands` and `validate --docs` pass.

### Files changed
docs/sprintbias/scripts/plan-check.sh
docs/sprintbias/scripts/plan.sh
docs/sprintbias/help/plan.md
docs/sprintbias/help/_registry
docs/guides/command-matrix.md
DOCUMENTATION.md
