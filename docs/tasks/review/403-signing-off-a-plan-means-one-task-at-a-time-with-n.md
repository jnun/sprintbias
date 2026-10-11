# Task 403: Signing off a plan means one task at a time with no full-suite gate

**Feature**: none
**Created**: 2026-10-08
**Docs**: none
**Plan**: 28
**From plan**: none
**Depends on**: 401, 402
**Dependents**: 404, 405, 406
**Parent**: none
**Crew**: none
**Tests**: docs/tests/test-promote.sh
**Refined**: 0
**Reworked**: 0

## Problem

Signing off a plan means approving tasks one at a time, and the full suite
never runs as a single gate before the work counts as done. The human needs
one batch: run the suite once, turn failures into fix tasks, and approve the
plan's combined human checklist in one step.

## Done when (automated)

- [x] `./sprint.sh promote plan:N` acts only when the plan reads LANDED (`sprintbias_plan_state`); otherwise it prints each open, unproven or missing member and each open fix task, and stops with nothing moved. `bash docs/tests/test-promote.sh`
- [x] On a LANDED plan it lists the landed members in dependency order (in-plan **Depends on** and **Held** fix edges) and runs the project's full suite exactly once: the `TEST_SUITE` command from docs/sprintbias/config. With no `TEST_SUITE` set it says plainly that no full suite ran and goes on to the checklist. `bash docs/tests/test-promote.sh`
- [x] A failing suite files fix tasks through `sprintbias_file_fix_task` with the failing output, one per member whose ### Files changed, **Touching:** or **Tests** paths appear in that output (the plan's last landed member when none match), then stops with nothing moved and exits 1. `bash docs/tests/test-promote.sh`
- [x] A passing suite prints the plan's combined `## Signoff (human)` checklist grouped by task (an old task without that section shows an empty checklist) and asks once; `y` moves every landed member to done/, any other answer or closed stdin moves nothing. `bash docs/tests/test-promote.sh`
- [ ] `./sprint.sh promote <id>` (one task at a time) behaves as before. `bash docs/tests/test-promote.sh`
- [ ] help/promote.md, the promote row in help/_registry and docs/guides/command-matrix.md name `plan:N`. `./sprint.sh validate --commands`, `./sprint.sh validate --docs`

## Signoff (human)

- [ ] On a temp board, run `./sprint.sh promote plan:N` once with a failing suite and once with a passing one: the fix tasks read as workable briefs, and the combined checklist reads clearly enough to approve in one answer.

## Notes

Shared policy, names and formats: docs/plans/28-enhance-crews-and-efficiency.md → Policy. Use them exactly.

The human owns done/: the batch moves files only on the human's approval in the run. Run the suite with stdin closed (bash docs/tests/run-all.sh </dev/null); test-cleanup-tmp.sh hangs otherwise.

Suite source: one config key, `TEST_SUITE=` (the project's full-suite command, empty by default; setup.sh merges new keys into existing configs). It is the honest "full suite once" from the Policy; members' **Tests** stay the targeted tests. Run it with stdin closed.

## References

docs/plans/28-enhance-crews-and-efficiency.md
docs/sprintbias/scripts/promote.sh
docs/sprintbias/help/promote.md
docs/tests/test-promote.sh

## Grounding

**Sources:** `docs/plans/28-enhance-crews-and-efficiency.md` (Policy: landed, signed off, plan states, Signoff (human), Test log, fix tasks, full suite once at plan close), `docs/sprintbias/lib.sh` (sprintbias_plan_state, sprintbias_member_standing, sprintbias_plan_open_fixes, sprintbias_file_fix_task, sprintbias_held_fixes, sprintbias_plan_member_ids, sprintbias_cfg), `docs/sprintbias/scripts/promote.sh` (close gate, run_test, --reject), `docs/sprintbias/config` (config keys), `docs/sprintbias/help/_registry` + `docs/guides/command-matrix.md` + `docs/sprintbias/help/promote.md` (command surfaces)
**Terms:**
- **Landed** — in review/ with a proof line. Landed work releases its dependents.
- **Signed off** — in done/. Only humans move work there, at the end of a task or plan, after the full suite passes and the human checks are done.
- **Plan states** — STARTED (work open), LANDED (every member landed), SIGNED OFF (every member in done/).
**Touching:** docs/sprintbias/scripts/promote.sh (plan:N batch), docs/sprintbias/config (TEST_SUITE key), docs/sprintbias/help/promote.md, docs/sprintbias/help/_registry (promote row), docs/guides/command-matrix.md (promote rows), DOCUMENTATION.md (promote line), docs/tests/test-promote.sh, CHANGELOG.md
**Conflicts:**
- The project map (docs/sprintbias/project.md, `## Commands` → `**Test:**`) is AI-written prose and absent in this repo; nothing in config names a full-suite command → add one config key, `TEST_SUITE`, and read only that.
- Policy says "prefer a flag on an existing command" → `plan:N` is an argument form on promote (the same `plan:N` shape crew uses), not a new command.
- A held original closes only after its fix is in done/; in a plan batch the fix and the original are both members and move together → order the fix before the original and move both on the one approval.

## Completed

`./sprint.sh promote plan:N` is the sign-off batch. Suite source: one config
key, `TEST_SUITE` (the project's full-suite command, empty by default), run
once with stdin closed. A failure routes a fix task to each member whose
### Files changed / **Touching:** / **Tests** paths appear in the failing
lines (else the plan's last member), via `sprintbias_file_fix_task`. In-plan
**Held** fixes order before their original and move in the same approval.

### Files changed
docs/sprintbias/scripts/promote.sh
docs/sprintbias/config
docs/sprintbias/help/promote.md
docs/sprintbias/help/_registry
docs/guides/command-matrix.md
DOCUMENTATION.md
docs/tests/test-promote.sh
CHANGELOG.md

### Doc follow-ups
- `docs/sprintbias/scripts/profile.sh` — the project map's `## Commands` → `**Test:**` line could point at `TEST_SUITE`, and `profile` could offer to set it.

Tests run: `bash docs/tests/test-promote.sh` (87 passed), `./sprint.sh validate --commands`, `./sprint.sh validate --docs`; full suite once with `bash docs/tests/run-all.sh </dev/null`: 27 of 28 scripts pass, only the known test-cleanup-tmp.sh fails.

**Proof**: 2026-10-08 · bash docs/tests/test-promote.sh, ./sprint.sh validate --commands, ./sprint.sh validate --docs · pass

## Questions

**Status: READY**

### Already complete
- #401's `sprintbias_plan_state` / `sprintbias_plan_counts` / `sprintbias_plan_open_fixes` compute LANDED from the folders (docs/sprintbias/lib.sh).
- #402's `sprintbias_file_fix_task` files a linked fix task and lists it on the plan; promote.sh's `task_held_by` and `run_test` are reusable.
- No plan-level batch exists in promote.sh today.

### Remaining work
- `plan:N` argument on promote: LANDED check, dependency order, one suite run from `TEST_SUITE`, fix-task routing on failure, combined checklist and one y/N approval on success.
- `TEST_SUITE=` key in docs/sprintbias/config.
- Tests in docs/tests/test-promote.sh on temp boards; help, registry, matrix, CHANGELOG.

### Questions for the developer
None — task is fully defined.

