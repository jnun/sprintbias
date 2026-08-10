# Task 332: Suite tests and docs for dependency integrity and completion path

**Feature**: none
**Created**: 2026-08-01
**Docs**: docs/guides/running-tests.md
**Plan**: 15
**Depends on**: 327, 328, 329, 330, 331, 333
**Dependents**: none
**Parent**: none
**Tests**: docs/tests/test-dep-graph.sh, docs/tests/test-dep-work.sh
**Refined**: 3
**Reworked**: 0

## Problem

Plan 15's surfaces are now built: the header contract (#327), the dependency-
graph helpers (#328), the fold/split/retire rewrite call sites (#329), the
`work` completion path with `## Outcome` stamps (#330), the plan↔task reverse
index (#331), and the close path (#333 — `promote` honors **Depends on**,
`validate` checks **Tests**) have all landed. Without hard asserts over those
finished surfaces, fold rewrite and stage classification regress quietly, and
without the manual language locked, agents invent fields or forget **Plan** /
**Tests**. This task locks the contract in the platform suite and confirms the
user-facing docs stay green so stress fails loud.

## Success criteria

- [x] `docs/tests/test-dep-*.sh` asserts, discovered automatically by
      `run-all.sh` (`test-*.sh` glob), cover:
  - reciprocal edge ensure and `sprintbias_rewrite_dep_id` fold A→B rewrite
    (both ends updated; fold note on the kept file)
  - `sprintbias_classify_dep` distinguishing missing vs folded vs
    archived-complete (never silent "unmet empty")
  - `sprintbias_dependents_of` returning forward + reverse edges
  - `work` hold messaging by stage (backlog/blocked → `chat <id>`; doing →
    resume) and `## Outcome` stamp on an incomplete/failed/blocked route
  - **Plan** reverse-index drift between a plan's member list and a member's
    **Plan** field
- [x] Promote coverage is confirmed, not re-authored: #333 landed
      `docs/tests/test-promote.sh` (in `review/` as of 2026-08-10). Verify that
      `run-all.sh` discovers it, and that it asserts the dependency-order hold
      (a review/ task with an open **Depends on** prereq is not moved) plus the
      **Proven by** read-alias. If either assert is absent, add it to
      `test-promote.sh` — do not restate promote behavior in `test-dep-*.sh`.
- [x] Docs stay locked and consistent (most already landed — verify, don't
      re-author): DOCUMENTATION.md and help (`chat`, `newtask`, `promote`,
      `newplan`, `validate`, `work`) describe **Depends on**, **Dependents**,
      **Plan**, **Docs** vs **Tests**, the fold protocol, and
      "backlog never auto-promotes." That surface list is the whole checklist —
      a wording gap inside it is fixed here; anything larger (a missing command
      surface, a behavior change) is filed as a new task, not absorbed.
- [x] `bash docs/tests/run-all.sh` green, and `./sprint.sh validate`,
      `validate --docs`, `validate --commands` all green after any help edits
- [x] Plan 15's member checklist marks 327–333 complete, and
      `sprintbias_plan_index_drift 15` reports no drift between that member list
      and each member's **Plan** field. Plan 15's settled decisions stay settled
      — a disagreement surfaced while testing is filed, not reopened here.
- [x] Once `test-dep-*.sh` exists and is green, set this task's **Tests** to
      those paths so `promote` can close it

## Notes

- Start from `docs/tests/fixtures/dep-glitch-matrix/` (MATRIX.md, seed.sh,
  board/ at IDs 9000–9099, check-inventory.sh false-green detector). Promote
  those diagnostics into `docs/tests/test-dep-*.sh`; `run-all.sh` picks up any
  new `test-*.sh` with no wiring change.
- Assert against the real helpers in `docs/sprintbias/lib.sh`:
  `sprintbias_classify_dep`, `sprintbias_dependents_of`,
  `sprintbias_rewrite_dep_id`, `sprintbias_fold_target`. `validate-tasks.sh`
  already checks **Depends on** / **Dependents** token shape (no cycle
  detection — out of scope); #333 adds **Tests**-path integrity.
- `promote.sh` already reads **Tests** (legacy alias **Proven by**,
  `promote.sh:68`), guards the `docs/tests/` prefix, and hints plan retirement
  (`promote.sh:191`). The dependency-order close is #333's to build and prove.
- When asserting `sprintbias_classify_dep`, pin the missing-id default the way
  the call sites already do: `work.sh:492,541` pass `missing` explicitly. Note
  that `sprintbias_unmet_deps` (`lib.sh:932`) is a separate older walk that does
  its own `find` — it reads a folded or missing prereq as satisfied. Asserting
  that divergence is in scope; changing it is not.
- No live AI required for these asserts.
- Guide for agents: `docs/guides/running-tests.md`.

## References

docs/tests/
docs/tests/run-all.sh
docs/tests/fixtures/dep-glitch-matrix/
docs/guides/running-tests.md
docs/sprintbias/lib.sh
docs/sprintbias/scripts/promote.sh
docs/sprintbias/scripts/validate-tasks.sh
docs/sprintbias/help/work.md
docs/sprintbias/help/chat.md
docs/sprintbias/help/validate.md
docs/sprintbias/help/promote.md
docs/sprintbias/help/newtask.md
DOCUMENTATION.md
docs/plans/15-dependency-integrity-and-work-completion-path.md

## Refine (round 3)

**Sharpened:** Drew the 332/333 boundary — 333 owns `test-promote.sh`, so this
task verifies that coverage rather than restating promote asserts in
`test-dep-*.sh`. Bounded the docs criterion to its named surface list (larger
gaps get filed, not absorbed) and made the plan-15 criterion verifiable via
`sprintbias_plan_index_drift 15`. Recorded two code-checked facts: the
missing-id default is already pinned to `missing` at the `work.sh` call sites,
and `sprintbias_unmet_deps` is a separate older walk that reads folded/missing
prereqs as satisfied. Mid-session, #333 completed into `review/` with
`test-promote.sh` carrying the alias and dependency-hold asserts (its Tests 5,
6, 6b) — this task's promote criterion is now a verification, already
satisfiable.

## Questions

**Status: READY**

## Completed

Plan 15's finished surfaces now have hard asserts, and the doc/plan contract is
verified locked. Two new suite scripts, both discovered by `run-all.sh` via the
`test-*.sh` glob, both seeding a throwaway copy of the glitch matrix (never the
real board) and sourcing the *repo* helpers so they track shipped code, no live
AI:

- **`docs/tests/test-dep-graph.sh`** (22 asserts) — `sprintbias_classify_dep`
  (missing / folded / archived-complete, never a silent unmet-empty, and its
  in-scope divergence from the older `sprintbias_unmet_deps` walk, which is
  asserted, not changed); `sprintbias_dependents_of` (forward ∪ reverse edges,
  including the one-way 9016→9017 case); `sprintbias_ensure_reciprocal`
  (adds the back-edge, idempotent); `sprintbias_rewrite_dep_id` (fold A→B
  rewrites the stale dependent's **Depends on** and stamps a dated fold note on
  the kept file); `sprintbias_plan_index_drift` (both directions —
  member-without-back-index, back-index-without-membership, stale plan id).
- **`docs/tests/test-dep-work.sh`** (30 asserts) — the stage-aware hold-line and
  Outcome helpers pulled verbatim out of the real `work.sh` by name
  (`_format_dep`, `_needs_clause`, `_stamp_outcome`, `_outcome_brief`): backlog/
  and blocked/ → `chat <id>`; doing/ → resume / route-to-review / surface a
  failed Outcome; missing → loud broken ref; a durable, idempotent `## Outcome`
  block for incomplete/failed/blocked that `_outcome_brief` reads back for a
  hold line. Plus `work N` end to end for the two pre-AI paths (a doing/ task is
  offered `work N --force`, exit 1; a next/ task with an open prereq is held on
  it, exit 0).

**Fixture fix (in-scope test infra):** the matrix's own "Intentionally omitted
members" prose used `- #9082` bullets, which `sprintbias_plan_member_ids` reads
as real members — silently healing the very drift case #9082 exists to prove.
Code-quoted the ids in `seed.sh` so the prose no longer parses as membership;
the `9082 90 none` drift row now surfaces and is asserted. The committed
`board/` snapshot is regenerated on demand from `seed.sh` (and is already stale
from the wider `sprintmd→sprintbias` rename), so it was left untouched; the
tests seed fresh temp boards.

**Verified, not re-authored:**
- Promote coverage — `run-all.sh` discovers `test-promote.sh` (22 asserts,
  green); it already carries the dependency-order hold (Test 6/6b: a review/
  task with an open **Depends on** prereq stays put, self-clears once the prereq
  reaches review/) and the **Proven by** read-alias (Test 5). Nothing added
  there; no promote asserts restated in `test-dep-*.sh`.
- Docs — DOCUMENTATION.md and help (`chat`, `newtask`, `promote`, `newplan`,
  `validate`, `work`) already describe **Depends on**, **Dependents**, **Plan**,
  **Docs** vs **Tests**, the fold/reciprocal protocol, and "backlog is not
  auto-lifted (not fully vetted)". No wording gap inside that surface list, so
  no help edits — `validate --docs` / `--commands` stay green with no re-sync
  needed.

**Green after all changes:** `bash docs/tests/run-all.sh` (22/22 scripts),
`./sprint.sh validate` (127/127 files, incl. this task's new **Tests**-path
integrity), `validate --docs`, `validate --commands`.

Plan 15's member checklist marks 327–333 complete;
`sprintbias_plan_index_drift` reports no drift for any plan-15 member. This
task's **Tests** now points at the two new scripts so `promote` can close it.

### Files changed

docs/tests/test-dep-graph.sh
docs/tests/test-dep-work.sh
docs/tests/fixtures/dep-glitch-matrix/seed.sh
docs/plans/15-dependency-integrity-and-work-completion-path.md
docs/tasks/doing/332-tests-and-docs-for-dependency-integrity-and-work-c.md
