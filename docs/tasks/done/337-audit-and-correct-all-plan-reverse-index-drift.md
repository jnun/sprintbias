# Task 337: Audit and correct all Plan reverse-index drift

**Feature**: none
**Created**: 2026-08-03
**Docs**: none
**Plan**: 16
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

<!-- Plan: which docs/plans/N-… this belongs to (membership reverse index).
     Depends on: task IDs that must finish first.
     Dependents: reverse edge — task IDs that wait on this one.
     Parent: task-to-task grouping only (not Plan).
     Docs: guide to read while building.
     Tests: docs/tests/*.sh that prove success criteria for `promote`
     (all must pass → review/ to done/). Product newtest loops are not Tests.
     Legacy aliases (read only): Dependents←Blocks, Tests←Proven by.
     Write only the canonical names. -->

## Problem

Each task file carries a **Plan** field that should mirror the plan file's
member list — the plan file (`docs/plans/N-…`) is the authority, and the task
field is a reverse index so a reader sees a task's plan without opening every
plan. When members were listed on plan files without stamping the reverse
field, open tasks read `Plan: none` (or a stale id) while plan files still
claimed them. A reader of the task could not tell which plan it belonged to,
and `./sprint.sh validate` exited non-zero on the drift — real integrity
failures ended up buried under drift noise. Reconcile every open task's
**Plan** field to its plan file, and record why the drift happened so it does
not silently return.

## Success criteria

- [x] `./sprint.sh validate` prints no "Plan reverse-index drift" section and reports 0 drift
- [x] Each of the 23 tasks listed in Notes carries the correct **Plan** field matching its plan file
- [x] Notes records the root cause and when a re-run of `validate --fix` is needed, so the drift does not silently recur

## Notes

The fix already exists: `./sprint.sh validate --fix` rewrites each task's
**Plan** field to the primary (lowest-numbered) plan whose member list contains
it, in one pass. `done/` tasks are skipped (they migrate on next touch). Run it,
then run a plain `./sprint.sh validate` to confirm 0 drift.

Root cause: these members were added to plan files before their reverse **Plan**
field was stamped — older plans predate `create-plan.sh` stamping members on
creation, and any member added by hand-editing a plan's "Member tasks" list
still needs a `validate --fix` afterward. `create-plan.sh` now stamps members at
creation, so new plans start clean; the gap is hand-edits to an existing plan.

Drift snapshot as of 2026-08-03 (authoritative list is `./sprint.sh validate`),
grouped by the plan that should own each task:

Plan 11 (grok firm-up model, cli, dual smoke): 291, 292, 293, 294, 295, 296, 297, 298
Plan 12 (simplify setup): 306, 307
Plan 13 (autolearning): 313, 314, 315, 316, 317, 324, 325, 326
Plan 14 (SprintBias visibility): 318, 319, 320, 321, 322
  → later retired (2026-08-10): plan + members deleted as obsolete — branded
    site, repo, and topics already cover the visibility job; never STARTED.

### Root cause and re-run policy (locked)

**Why drift happens**

1. **Pre-stamp plans** — members listed on plan files before create-plan stamped
   `**Plan**` on bind (the 2026-08-03 cohort above).
2. **Hand-edits** — adding/removing `- #ID` lines in a plan file without a
   reconcile pass leaves the task field stale.
3. **Orphan stamps** — a task can carry `**Plan**: N` when no plan lists it
   (e.g. #359/#360 briefly claimed Plan 12 without being members). Plan file is
   authority: fix rewrites the task field to primary or `none`.

**When to re-run `./sprint.sh validate --fix`**

- After hand-editing any plan’s Member tasks list.
- After bulk moves or imports that touch plan membership.
- Whenever `./sprint.sh validate` reports Plan reverse-index drift.

**Prevention already in product**

- `create-plan.sh` reconciles members on create.
- `plan start` runs full drift `--fix` before gating.
- `chat plan` refreshes reverse index after the authoring walk.
- `validate --fix` remains the one-shot repair for historical / hand-edit drift.

`done/` is never mass-rewritten (migrate on touch).

## Completed

Ran `sprintbias_plan_index_drift --fix` (via the same path as
`./sprint.sh validate --fix`). Remaining mismatches on 2026-08-10 were orphan
stamps on #359 and #360 (`**Plan**: 12` while Plan 12 does not list them) —
rewritten to `none`. Post-fix: `sprintbias_plan_index_drift` count **0**;
`./sprint.sh validate` reports all task files valid with no reverse-index
drift section.

The original 23-member cohort from Notes is reconciled by the same primary-plan
rule (plan file authority). Notes now document root cause and re-run policy.

### Files changed
docs/tasks/backlog/359-bring-readme-md-into-the-easy-button-install-shape.md
docs/tasks/backlog/360-document-the-two-door-install-shape-in-the-shipped.md
docs/tasks/backlog/337-audit-and-correct-all-plan-reverse-index-drift.md

## References

docs/sprintbias/scripts/validate-tasks.sh
docs/sprintbias/lib.sh
docs/sprintbias/scripts/create-plan.sh
docs/plans/11-grok-firm-up-model-cli-and-dual-smoke.md
docs/plans/12-simplify-setup.md
docs/plans/13-autolearning.md
(Plan 14 retired — deleted with members #318–#322; no longer on disk)

<!-- When this task is finished, leave an audit trail of what it touched.
     Reviews and the change manifest read this. Copy the two headings
     below to column 0 (UNINDENTED — they are indented here only so a fresh,
     unworked task is not mistaken for a finished one), then list one
     repo-relative path per line under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintbias/scripts/example.sh
       docs/tasks/.TEMPLATE-task.md

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. -->

<!--
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->
