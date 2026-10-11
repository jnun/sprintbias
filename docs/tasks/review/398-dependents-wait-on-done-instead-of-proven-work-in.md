# Task 398: Dependents wait on done/ instead of proven work in review/

**Feature**: none
**Created**: 2026-10-08
**Docs**: none
**Plan**: 28
**From plan**: none
**Depends on**: none
**Dependents**: 400, 401, 402
**Parent**: none
**Crew**: none
**Tests**: docs/tests/test-dep-work.sh
**Refined**: 0
**Reworked**: 0

## Problem

Agents stall on human sign-off. A task's dependents should start the moment it
lands in review/ with recorded proof that it works, not when a human moves it to
done/. Some code already counts review/ as met, but nothing checks for proof, so
an unproven review/ task releases its dependents just like a proven one.

## Success criteria

- [x] `sprintbias_has_proof FILE` in lib.sh reports whether a task carries a `**Proof**:` line under ## Completed (format in plan 28).
- [x] A dependency counts as met when it is in done/, or in review/ with a proof line. In review/ without proof it holds its dependents, and the hold line says "in review, unproven".
- [x] Every place that decides "is this prerequisite met" uses the one rule: sprintbias_unmet_deps, work.sh's runnable and hold checks, plan-start.sh, promote.sh task_held_by, loop.
- [x] Tests in docs/tests/test-dep-work.sh: a dependent releases on a proven review/ prerequisite and holds on an unproven one; done/ still releases.
- [x] Tasks already in review/ before this change (no proof line) are covered: a one-time note in the hold message tells the human to promote them or add proof. No existing project wedges silently.

## Notes

Shared policy, names and formats: docs/plans/28-enhance-crews-and-efficiency.md → Policy. Use them exactly.

Verify first, then change: work.sh, plan-start.sh and promote.sh (task_held_by) already treat review|done as met. Change the shared rule in lib.sh and route callers through it rather than editing each check. This task owns the proof-line FORMAT and the reader; task 400 makes workers write it.

## References

docs/plans/28-enhance-crews-and-efficiency.md
docs/sprintbias/lib.sh (sprintbias_unmet_deps, sprintbias_classify_dep)
docs/sprintbias/scripts/work.sh
docs/sprintbias/scripts/plan-start.sh
docs/sprintbias/scripts/promote.sh
docs/sprintbias/scripts/loop.sh
docs/tests/test-dep-work.sh

## Grounding

**Sources:** `docs/plans/28-enhance-crews-and-efficiency.md` (Policy: landed, proof-line format, "in review, unproven"), `docs/sprintbias/lib.sh` (shared dependency rule: sprintbias_unmet_deps, sprintbias_classify_dep), `DOCUMENTATION.md` (blocked vs dependent, Depends on gates), `docs/sprintbias/help/work.md` and `docs/sprintbias/help/promote.md` (user-facing hold wording)
**Terms:**
- **Landed** — in review/ with a proof line. Landed work releases its dependents. In review/ without proof is "in review, unproven" and releases nothing. (plan 28 Policy)
- **Signed off** — in done/. Only humans move work there. (plan 28 Policy)
- **Dependent** — clear but waiting on another task via `Depends on`; not blocked. (DOCUMENTATION.md)
**Touching:** docs/sprintbias/lib.sh (sprintbias_has_proof, sprintbias_dep_met, sprintbias_unmet_deps, header comments only), docs/sprintbias/scripts/work.sh (_format_dep, hold messages, queue prompt dependency lines), docs/sprintbias/scripts/promote.sh (task_held_by), docs/sprintbias/help/work.md, docs/sprintbias/help/promote.md, docs/tests/test-dep-work.sh, docs/tests/fixtures/dep-glitch-matrix/seed.sh, docs/tests/test-promote.sh, CHANGELOG.md
**Conflicts:**
- Task Notes list plan-start.sh as a place that decides "is this prerequisite met" vs the code: plan-start.sh only asks "may this task enter next/" (sprintbias_deps_not_sprint_ready: backlog/blocked prereqs keep it out). An unproven review/ prereq is past the sprint gate, so the dependent may enter next/ and the run gate holds it there. → Leave plan-start.sh's entry rule as is; the run rule (sprintbias_unmet_deps) carries the proof check.
- loop.sh has no dependency check of its own; it drains through work.sh. → Covered by routing work.sh through the shared rule; no loop.sh edit.
- Workers do not write a proof line until #400 lands, so between this task and #400 every freshly routed review/ task holds its dependents. → Accepted sequencing per plan 28 (#400 depends on this task); the hold message tells the human to promote or add proof.
- DOCUMENTATION.md, help/work.md and help/promote.md say dependents release on review/ or done/. → Update help/work.md and help/promote.md wording here; the manual's broader rewrite belongs to #405 (Doc follow-up).
- gate-lib.sh prompt text says "until those dependencies reach review/ or done/" but gate-lib.sh is #399's file this round. → Doc follow-up; leave the file untouched.

## Questions

**Status: READY**

### Already complete
- work.sh, promote.sh (task_held_by) and the unmet-deps gate already count review/ as met: sprintbias_unmet_deps (lib.sh) scans only backlog/next/doing/blocked; task_held_by accepts `review|done` from sprintbias_classify_dep; work.sh _format_dep prints `review|done` stages plainly. No proof check exists anywhere.
- plan-start.sh gates entry via sprintbias_deps_not_sprint_ready (backlog/blocked only); correct for its question and unaffected.

### Remaining work
- Add `sprintbias_has_proof FILE` to lib.sh: true when a `**Proof**:` line sits under ## Completed.
- One shared "is this prerequisite met" rule in lib.sh (done/, or review/ with proof, or missing = archived); sprintbias_unmet_deps and promote.sh task_held_by both use it.
- work.sh hold lines say "in review, unproven" for an unproven review/ prereq, plus one note per hold message: promote it or add a proof line.
- Seed fixture: the healthy review/ prereq gets a proof line; add an unproven review/ prereq and a dependent on it; tests in test-dep-work.sh cover proven, unproven and done/.
- Update help/work.md and help/promote.md wording; CHANGELOG bullet.

### Questions for the developer
None — task is fully defined.


## Completed

`sprintbias_has_proof` and `sprintbias_dep_landed` in lib.sh are the one
"is this prerequisite met" rule: done/, or review/ with a passing `**Proof**:`
line under `## Completed` (date first, ends in `pass`). `sprintbias_unmet_deps`
(work, loop through work, chat/gate hold lines) and promote's `task_held_by`
route through it; a review/ prereq without proof reads "in review, unproven"
and holds. Each hold message (work N, the work run banner and held report,
promote) prints one note: sign it off (promote or done/) or add the proof line.
plan-start.sh is unchanged by design: its entry rule (deps not in backlog/ or
blocked/) answers a different question, and the run gate holds the dependent
in next/. loop.sh has no check of its own. The fixture board gains 9021
(review/, no proof) and 9090 (depends on it); 9002 now carries a proof line.

### Files changed
docs/sprintbias/lib.sh
docs/sprintbias/scripts/work.sh
docs/sprintbias/scripts/promote.sh
docs/sprintbias/scripts/crew.sh
docs/sprintbias/scripts/chat-sprint.sh
docs/sprintbias/help/work.md
docs/sprintbias/help/promote.md
docs/tests/test-dep-work.sh
docs/tests/test-promote.sh
docs/tests/fixtures/dep-glitch-matrix/seed.sh
docs/tests/fixtures/dep-glitch-matrix/MATRIX.md
docs/tests/fixtures/dep-glitch-matrix/board/INVENTORY.txt
docs/tests/fixtures/dep-glitch-matrix/board/docs/plans/90-dep-glitch-matrix-synthetic.md
docs/tests/fixtures/dep-glitch-matrix/board/docs/tasks/review/9002-healthy-review-prereq.md
docs/tests/fixtures/dep-glitch-matrix/board/docs/tasks/review/9021-review-unproven-prereq.md
docs/tests/fixtures/dep-glitch-matrix/board/docs/tasks/next/9090-depends-on-unproven-review.md
CHANGELOG.md

### Doc follow-ups
- `DOCUMENTATION.md` — the review/ row ("done, awaiting your approval") and the Depends on field should say a dependent releases on landed work (review/ with a proof line) or done/; owned by #405.
- `docs/sprintbias/scripts/gate-lib.sh` — the gate prompt says the runner holds a dependent "until those dependencies reach review/ or done/"; it should read "land (review/ with a proof line) or reach done/". Left alone: #399 owned the file this round.

**Proof**: 2026-10-08 · bash docs/tests/test-dep-work.sh; bash docs/tests/test-promote.sh; bash docs/tests/test-dep-graph.sh; bash docs/tests/run-all.sh; ./sprint.sh validate --commands; ./sprint.sh validate --docs · pass
