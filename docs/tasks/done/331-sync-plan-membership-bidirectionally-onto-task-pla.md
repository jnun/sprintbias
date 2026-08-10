# Task 331: Sync plan membership bidirectionally onto task Plan field

**Feature**: none
**Created**: 2026-08-01
**Docs**: docs/plans/15-dependency-integrity-and-work-completion-path.md
**Plan**: 15
**Depends on**: 327, 328
**Dependents**: 332
**Parent**: none
**Tests**: none
**Refined**: 1
**Reworked**: 0

## Problem

Plan membership lives only in `docs/plans/N-….md` member lists. Opening a task
does not show which plan it belongs to. When members are added or removed,
nothing writes **Plan** on the task, so the reverse index drifts and single-file
readers cannot find the plan.

## Success criteria

- [x] Tasks carry `**Plan**: N` or `none` (template from #327)
- [x] Membership-setting paths refresh **Plan** on members (`newplan` args,
      plan start reconcile; optional validate fix)
- [x] Removing a member sets that task’s **Plan** to `none` (or remaining
      primary plan id)
- [x] validate or chat-sprint flags drift both ways (task says Plan N but plan
      omits id; plan lists id but task Plan is wrong/none)
- [x] Plan *file* remains authority for “who is in the plan”; task field is
      reverse index only — no second membership algorithm

## Notes

- Locked: single primary **Plan** id (lowest id if multi-plan); extras only on
  plan files.
- Prefer reconcile on `plan start` + validate offer; keep chat-plan
  plan-file-only write scope if that boundary stays useful.
- Migrate on touch; no mass rewrite of done/.

## References

docs/sprintmd/scripts/create-plan.sh
docs/sprintmd/scripts/plan-start.sh
docs/sprintmd/scripts/chat.sh
docs/plans/.TEMPLATE-plan.md
docs/sprintmd/lib.sh
docs/plans/15-dependency-integrity-and-work-completion-path.md

## Questions

**Status: READY**

## Completed

Built the plan-membership reverse index so a task's **Plan** field mirrors the
plan files, with the plan *file* member list kept as the single membership
authority — one reader over `docs/plans/*.md` decides membership and the task
field is only ever written to match, never the other way (no second membership
algorithm).

**New lib.sh helpers** (pure, unit-testable, catalogued in the header
`Provides:` block, section `── Plan-membership reverse index ──`):

- `sprintmd_plan_member_ids PLAN_FILE` — member task ids from the `- #ID` lines
  (same extraction `plan-start.sh` uses, so the two never disagree).
- `sprintmd_primary_plan_of ID` — the task's single primary plan id: the
  **lowest-numbered** plan that lists it (locked multi-plan rule; extras live
  only on plan files), or empty when no plan claims it.
- `sprintmd_set_task_plan FILE VALUE` — writes the **Plan** field in place; for
  a pre-#327 task with no field, inserts it after **Docs** (falling back to
  **Created**). Prints the path only when it changed the value.
- `sprintmd_reconcile_task_plan ID` — derives the primary plan and writes it
  onto the task (the one path that writes **Plan**); skips `done/`.
- `sprintmd_plan_index_drift [--fix]` — reports every open/`review/` task whose
  **Plan** disagrees with the plan files, one line as `ID<TAB>field<TAB>computed`;
  `--fix` rewrites each. Catches drift **both ways** — task claims Plan N no plan
  lists (removed member / stale id) *and* task says none/wrong when a plan lists
  it. `done/` is never touched (migrate on touch).

**Wired the membership-setting paths:**

- `create-plan.sh` (the `newplan` args path) — after writing the member list,
  reconciles each member's **Plan** so single-file readers see the plan
  immediately.
- `plan-start.sh` — reconciles via `sprintmd_plan_index_drift --fix` after the
  dangling/blocked hard-error checks and before the gate; this refreshes members
  *and* clears a stale **Plan** on a task that was removed from the plan (its
  primary falls back to another plan or `none`). Prints `· synced Plan on N
  task(s)`.
- `validate-tasks.sh` — added a dedicated Plan-drift pass: reports drift both
  ways under a `Plan reverse-index drift` section, `--fix` reconciles it, and
  unfixed drift makes the run non-clean (exit 1) so the reverse index can't
  silently rot. Summary shows `Plan drift:` / `Plan synced:`.

`chat-plan.sh` deliberately keeps its plan-file-only write scope (locked
decision) — removal happens there by dropping the member line, and the next
`plan start` / `validate --fix` reconciles the removed task's field.

**Verified** in an isolated sandbox: multi-plan task resolves to the lowest plan
id (40 in plans 7 & 12 → 7); both-way drift detected and `--fix` synced
(none→7, stale 99→12); a pre-#327 task got **Plan** inserted after **Docs**; a
`done/` task listed in a plan was left untouched; reconcile is idempotent.
`bash -n` clean on all four files. Real-repo `./sprint.sh validate` correctly
flags 23 real drifts (open tasks in plans 11–14 whose field still says `none`)
and exits 1 with the `--fix` tip. `test-plan-lifecycle.sh` 19/19 pass.

Notes for the developer:
- The 23 real drifts on this repo's own board are left unfixed on purpose (they
  are unrelated task files; run `./sprint.sh validate --fix` to sync them).
- `test-validate-tasks.sh` shows 1 pre-existing failure (Test 9, "Malformed
  **Blocks** token") — it stems from an earlier uncommitted change to the
  Dependents←Blocks read path, not this task; my edits never touch that path
  (it passes against HEAD).
- Run `./ship.sh` to mirror these `docs/sprintmd/` changes into `src/` for
  distribution.

### Files changed
docs/sprintmd/lib.sh
docs/sprintmd/scripts/create-plan.sh
docs/sprintmd/scripts/plan-start.sh
docs/sprintmd/scripts/validate-tasks.sh
docs/tasks/doing/331-sync-plan-membership-bidirectionally-onto-task-pla.md
