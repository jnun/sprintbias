# Task 328: Add shared dependency-graph helpers classify rewrite fold

**Feature**: none
**Created**: 2026-08-01
**Docs**: docs/plans/15-dependency-integrity-and-work-completion-path.md
**Plan**: 15
**Depends on**: 327
**Dependents**: 329, 330, 331, 332
**Parent**: none
**Tests**: none
**Refined**: 1
**Reworked**: 0

## Problem

Dependency logic is scattered: `sprintmd_unmet_deps` only answers “open or
not,” chat-sprint grades stages ad hoc, and there is no single helper to list
dependents, rewrite id A→B after a fold, or classify a missing id. Without
shared primitives, work/chat/split each invent half-answers and silent orphans
return under stress.

## Success criteria

- [x] lib.sh exposes pure helpers (unit-testable, no AI):
      - classify dep id → stage + reason
        (`review|done|doing|next|backlog|blocked|missing|folded` …)
      - list reverse edges (who **Depends on** this id; read **Dependents**,
        legacy **Blocks**)
      - `sprintmd_rewrite_dep_id FROM TO` — update **Depends on** and
        **Dependents** on all open tasks; fold note on FROM if kept
      - ensure reciprocal edge (A depends on B ⇒ B lists A under **Dependents**)
- [x] Classification distinguishes open stage, review/done, missing (broken),
      folded, and archived-complete when safe (policy knob; default in #330)
- [x] Call sites not required in this task — seam only (#329–#330 wire it)
- [ ] Helpers covered by fixture asserts (see #332 / dep-glitch-matrix) —
      deferred to #332 (this task only lays the seam; #332 lands the asserts)

## Notes

- Build on `sprintmd_task_stage`, `sprintmd_task_path`, `sprintmd_unmet_deps`,
  `sprintmd_iter_id_list`.
- Positive API names; no bag-of-sed.
- Fold note: `**Folded into**: B` or HTML comment with date.
- When #332 lands `docs/tests/test-dep-*.sh`, set **Tests** on this task to
  those paths so promote can close without a human.

## References

docs/sprintmd/lib.sh
docs/sprintmd/scripts/work.sh
docs/sprintmd/scripts/chat-sprint.sh
docs/sprintmd/scripts/split.sh
docs/tests/fixtures/dep-glitch-matrix/
docs/plans/15-dependency-integrity-and-work-completion-path.md

## Questions

**Status: READY**

## Completed

Added a `── Dependency-graph helpers ──` section to `docs/sprintmd/lib.sh`
(pure, no AI, unit-testable from the repo root), built on the existing
`sprintmd_task_stage` / `sprintmd_task_path` / `sprintmd_meta_value` /
`sprintmd_iter_id_list` primitives. Reverse-edge reads honor both the canonical
**Dependents** and the legacy **Blocks** spelling (#327's contract). This task
lays the seam only — no call sites migrated (that is #329/#330).

New surface:

- `SPRINTMD_OPEN_STAGES` + `sprintmd_stage_is_open STAGE` — one source of truth
  for "which stages still hold incomplete work" (backlog/next/doing/blocked).
- `sprintmd_reverse_edge_value FILE` — single reader for **Dependents** with the
  legacy **Blocks** fallback, so no script re-invents the Dependents←Blocks read.
- `sprintmd_fold_target FILE` — the id a task was folded into, recognizing both
  fold-note shapes (`<!-- folded into #B DATE -->` and `**Folded into**: B`).
- `sprintmd_classify_dep ID [MISSING_AS]` — one classification token:
  `review|done|doing|next|backlog|blocked` (stage), `folded` (fold marker wins
  over stage so a kept-but-folded task never reads as open), or `missing`.
  Missing-id policy is a knob (`MISSING_AS` arg or `$SPRINTMD_DEP_MISSING_AS`,
  default `missing`) — plan 15's archived-complete default is set in #330.
- `sprintmd_dependents_of ID` — reverse edges, unioning authoritative forward
  edges (any task whose **Depends on** names ID) with ID's own declared
  **Dependents**/**Blocks**; numeric-sorted, de-duped, scans all stages.
- `sprintmd_rewrite_dep_id FROM TO` — folds FROM→TO across **Depends on**,
  **Dependents**, and legacy **Blocks** on every task via `sprintmd_iter_id_list`
  (positive rebuild, not a bag of sed), prints each rewritten file, and leaves an
  idempotent `<!-- folded into #TO DATE -->` note on FROM's kept file
  (`$SPRINTMD_TODAY` override for deterministic tests). Helpers
  `_sprintmd_rewrite_field` / `_sprintmd_write_field` are internal.
- `sprintmd_ensure_reciprocal DEP DEPENDENT` — ensures DEP's reverse-edge field
  lists DEPENDENT (writes canonical **Dependents** unless only legacy **Blocks**
  is present); no-op when DEP has no file or already lists it.

Also catalogued all new helpers in the file's header `Provides:` block, matching
the file's own self-documenting convention.

Verified: `bash -n` clean, and an isolated sandbox exercise of all four required
helpers (classify blocked/done/folded/missing + policy knob; dependents_of
unioning forward+reverse edges; rewrite_dep_id across Depends on/Dependents/
Blocks + fold note; ensure_reciprocal) produced the expected output.

The **Tests** field stays `none` — the fixture asserts land in #332; per the
Notes, set **Tests** to `docs/tests/test-dep-*.sh` once #332 creates them.

### Files changed
docs/sprintmd/lib.sh
docs/tasks/doing/328-add-shared-dependency-graph-helpers-classify-rewri.md
