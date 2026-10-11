# Task 401: Plan check cannot tell landed work from signed-off work

**Feature**: none
**Created**: 2026-10-08
**Docs**: none
**Plan**: 28
**From plan**: none
**Depends on**: 398
**Dependents**: 403, 405
**Parent**: none
**Crew**: none
**Tests**: docs/tests/test-plan-lifecycle.sh
**Touching:** docs/sprintbias/lib.sh (new sprintbias_plan_counts / sprintbias_plan_state only, next to sprintbias_plan_member_rollup), docs/sprintbias/scripts/plan-check.sh, sprint.sh (status_plans), docs/tests/test-plan-lifecycle.sh, docs/sprintbias/help/plan.md, docs/sprintbias/help/status.md, DOCUMENTATION.md, CHANGELOG.md
**Refined**: 0
**Reworked**: 0

## Problem

A plan whose work is all in review/ looks stalled, because plan check and
status only count done/ as progress. The human can't see that the plan is ready
for sign-off, or which review/ tasks lack proof.

## Done when (automated)

- [x] plan check and status report three counts per plan: open (backlog/next/doing/blocked), landed (review/ with proof), signed off (done/). Proven by `bash docs/tests/test-plan-lifecycle.sh`.
- [x] The computed plan state reads STARTED (work open), LANDED (every member landed or signed off, at least one landed) or SIGNED OFF (every member in done/). A plan with every member landed never reads as stalled. Proven by `bash docs/tests/test-plan-lifecycle.sh`.
- [x] Both reports flag review/ tasks without proof ("in review, unproven") and open fix tasks (a task carrying `**Fixes**: #N` outside review/ and done/). Proven by `bash docs/tests/test-plan-lifecycle.sh`.
- [x] plan done still requires every member in done/; a plan with every member landed is refused. Proven by `bash docs/tests/test-plan-lifecycle.sh`.
- [x] The states are computed, never stamped: the plan file's **Status:** latch is unchanged by plan check and status. Proven by `bash docs/tests/test-plan-lifecycle.sh`.

## Signoff (human)

- Run `./sprint.sh plan check 28` and `./sprint.sh status`: the plan-28 counts match where its members sit, and the state line reads naturally.

## Notes

Shared policy, names and formats: docs/plans/28-enhance-crews-and-efficiency.md → Policy. Use them exactly.

The plan file's **Status:** latch (DRAFT/READY/STARTED) is written by plan start; LANDED and SIGNED OFF are computed from the folders, not stamped, so folders stay the only status.

## References

docs/plans/28-enhance-crews-and-efficiency.md
docs/sprintbias/scripts/plan-check.sh
sprint.sh (cmd_status)
docs/sprintbias/lib.sh (sprintbias_plan_member_rollup)
docs/tests/test-plan-lifecycle.sh

## Grounding

**Sources:** `docs/plans/28-enhance-crews-and-efficiency.md` (Policy: landed, signed off, proof line, Fixes field, plan states), `DOCUMENTATION.md` (plans and lifecycle folders), `docs/sprintbias/lib.sh` (sprintbias_has_proof, sprintbias_dep_landed, SPRINTBIAS_UNPROVEN_LABEL, sprintbias_plan_member_rollup), `docs/sprintbias/help/plan.md` and `docs/sprintbias/help/status.md` (command surfaces)
**Terms:**
- **Landed** — in review/ with a proof line. Landed work releases its dependents. In review/ without proof is "in review, unproven" and releases nothing.
- **Signed off** — in done/. Only humans move work there, at the end of a task or plan, after the full suite passes and the human checks are done.
- **Plan states** — computed from the folders: STARTED (work open), LANDED (every member landed), SIGNED OFF (every member in done/).
**Conflicts:**
- plan check today reports lowercase states (not started / started / in process / completed) → replace them with STARTED / LANDED / SIGNED OFF; keep "not started" only while the **Status:** latch is not STARTED and no member has moved past next/, since nothing has started.
- status counts review/ as complete and a missing member file as done → read both through the shared lib.sh rollup: review/ with proof is landed, review/ without proof is flagged unproven, a missing file is reported missing (plan done refuses it too).
- A review/ task without proof is neither open nor landed in the policy → show it as its own "in review, unproven" count and flag it by name; it keeps the plan STARTED.
- help/plan.md and help/status.md describe the old states → update them in the same change.

## Questions

**Status: READY**

### Already complete
- `sprintbias_has_proof`, `sprintbias_dep_landed` and `SPRINTBIAS_UNPROVEN_LABEL` exist in docs/sprintbias/lib.sh (task 398).
- plan-check.sh already reads the done-when section through `sprintbias_done_when` (task 399).
- plan-done.sh already refuses unless every member is in done/.

### Remaining work
- A lib.sh plan rollup that returns open / landed / signed off / unproven / missing counts and the computed state, shared by plan-check.sh and sprint.sh status.
- plan check prints the three counts, the computed state, and flags unproven review/ members and open fix tasks.
- status prints the same per plan.
- Tests in test-plan-lifecycle.sh for counts, LANDED state, unproven flag, Fixes flag, plan done refusal on all-landed, and an unchanged latch.

### Questions for the developer
None — task is fully defined.

## Completed

Plan state and counts now come from one lib.sh rollup (sprintbias_member_standing, sprintbias_plan_counts, sprintbias_plan_state, sprintbias_plan_open_fixes) shared by plan check and status. Landed is decided by sprintbias_dep_landed, so a later rule for held originals (task 402) flows through. A review/ member without proof is shown as its own count and flag, outside the three counts, and keeps the plan STARTED; a missing member file is reported missing (status used to count it as done). "not started" remains for a plan whose latch is not STARTED and where nothing has moved past next/.

### Files changed
docs/sprintbias/lib.sh
docs/sprintbias/scripts/plan-check.sh
sprint.sh
docs/tests/test-plan-lifecycle.sh
docs/sprintbias/help/plan.md
docs/sprintbias/help/status.md
DOCUMENTATION.md
docs/guides/command-matrix.md
CHANGELOG.md

**Proof**: 2026-10-08 · bash docs/tests/test-plan-lifecycle.sh; bash docs/tests/test-done-when.sh · pass
