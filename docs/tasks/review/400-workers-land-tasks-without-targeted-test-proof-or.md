# Task 400: Workers land tasks without targeted test proof or a test log

**Feature**: none
**Created**: 2026-10-08
**Docs**: none
**Plan**: 28
**From plan**: none
**Depends on**: 398, 399
**Dependents**: 404, 405
**Parent**: none
**Crew**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

Workers land tasks with nothing recorded to show they work, and when tests fail
the history is lost. Running the full suite after every task is slow. Workers
need a tight loop: targeted tests, a test log of every failure, and a proof line
when the task lands.

## Done when (automated)

- [x] `sprintbias_proof_rule` in lib.sh holds the agent loop, short, like `sprintbias_parallel_rule`: build the smallest testable outcome first; run only targeted tests (the tests Done when names, plus the tests for code the **Touching:** files feed), never the full suite; log each failure under `## Test log` (command, failing test, error excerpt), fix and re-run until green.
- [x] A failure that needs a decision sends the task to blocked/ with its Test log and an ## Outcome reason.
- [x] Landing writes the `**Proof**:` line in the plan 28 format under ## Completed, then moves the task to review/.
- [x] The work prompts (exec `_task_prompt` and both emit prompts) and the crew member prompt carry the rule. Proven by `bash docs/tests/test-proof-loop.sh` and `bash docs/tests/test-crew.sh`.
- [x] The exec router still moves a completed task without proof to review/ and says it is in review, unproven. Proven by `bash docs/tests/test-proof-loop.sh`.
- [x] `bash docs/tests/test-dep-work.sh`, `./sprint.sh validate --commands` and `./sprint.sh validate --docs` still pass.

## Signoff (human)

- Read the rule text in a real `./sprint.sh work <id>` prompt: it reads as one short loop an agent follows without translating.

## Notes

Shared policy, names and formats: docs/plans/28-enhance-crews-and-efficiency.md → Policy. Use them exactly.

Keep the added prompt text small: it is sent with every task. Reuse sprintbias_has_proof's format from task 398 (one source).

## References

docs/plans/28-enhance-crews-and-efficiency.md
docs/sprintbias/lib.sh (sprintbias_parallel_rule is the pattern)
docs/sprintbias/scripts/work.sh (_TASK_RULES, emit prompts)
docs/sprintbias/scripts/crew.sh
docs/tests/test-crew.sh

## Grounding

**Sources:** `docs/plans/28-enhance-crews-and-efficiency.md` (Policy: proof line, Test log, landed vs unproven), `docs/sprintbias/lib.sh` (sprintbias_parallel_rule pattern, sprintbias_has_proof format reader), `docs/sprintbias/scripts/work.sh` (worker prompts, `_route_result`), `docs/sprintbias/scripts/crew.sh` (member prompt), `CLAUDE.md` (guiding principles: positive instruction, minimal context cost)
**Terms:**
- **Landed** — in review/ with a proof line. Landed work releases its dependents. In review/ without proof is "in review, unproven" and releases nothing.
- **Proof line** — `**Proof**: YYYY-MM-DD · <targeted test commands> · pass`, under ## Completed.
- **Test log** — `## Test log` (each failure: command, failing test, error excerpt).
**Touching:** docs/sprintbias/lib.sh (new sprintbias_proof_rule only, next to sprintbias_parallel_rule; header index line), docs/sprintbias/scripts/work.sh (_task_prompt, emit prompts, _route_result unproven line), docs/sprintbias/scripts/crew.sh (member rules), docs/tests/test-proof-loop.sh (new), docs/tests/test-crew.sh, CHANGELOG.md
**Conflicts:**
- The brief names `_route_task`; work.sh calls the exec router `_route_result` → work on `_route_result`.
- The brief's Notes say "Reuse sprintbias_has_proof's format (one source)"; the format lives in that function's awk and in the policy text → the rule function states the format once and a test checks a line written in it passes `sprintbias_has_proof`.

## Questions

**Status: READY**

### Already complete
- #398: `sprintbias_has_proof`, `sprintbias_dep_landed`, `SPRINTBIAS_UNPROVEN_LABEL` in lib.sh; work.sh hold lines name "in review, unproven".
- #399: `sprintbias_done_when*` helpers; the worker brief in work.sh `_TASK_RULES` already says to run the tests Done when names.
- `_route_result` (work.sh) moves any task with ## Completed to review/ with no proof check, so unproven tasks already land; it does not say they are unproven.
- No worker prompt mentions targeted tests, a Test log or the proof line.

### Remaining work
- Add `sprintbias_proof_rule` to lib.sh and use it next to `$_parallel` in `_task_prompt`, both emit prompts, and crew.sh's member rules.
- `_route_result`: when the landed task has no proof line, say it is in review, unproven and holds its dependents.
- New `docs/tests/test-proof-loop.sh`; extend `docs/tests/test-crew.sh`.

### Questions for the developer
None — task is fully defined.


## Completed

Added `sprintbias_proof_rule` to lib.sh (next to `sprintbias_parallel_rule`, 11
lines): smallest testable outcome first, targeted tests from Done when and the
**Touching:** files, every failure under `## Test log`, a decision stops with
`**Result**: blocked`, and landing ends ## Completed with the plan 28 proof line.
work.sh sends it in `_task_prompt` and both emit prompts (beside `$_parallel`);
crew.sh sends it in the member rules, and rule 4 now says to finish with the
proof line.

Exec router (`_route_result`): a completed task still lands in review/ with or
without proof; without it the run prints "No **Proof**: line — in review,
unproven; its dependents wait." Testing the blocked path showed the router
overwrote a worker's own ## Outcome with "run ended without a '## Completed'
section", losing the decision; it now keeps an Outcome marked
`**Result**: blocked` and its Reason, and routes the task to blocked/. Both emit
prompts say the same (keep the worker's blocked Outcome, else append one).

### Files changed
docs/sprintbias/lib.sh
docs/sprintbias/scripts/work.sh
docs/sprintbias/scripts/crew.sh
docs/sprintbias/help/work.md
docs/tests/test-proof-loop.sh
docs/tests/test-crew.sh
CHANGELOG.md

### Doc follow-ups
- `DOCUMENTATION.md` — describe the worker test loop (targeted tests, ## Test log, proof line) in the work and crew sections; task 405 owns the solo/crew docs pass.

**Proof**: 2026-10-08 · bash docs/tests/test-proof-loop.sh; bash docs/tests/test-crew.sh; bash docs/tests/test-dep-work.sh; bash docs/tests/test-tasks-excellence.sh; bash docs/tests/run-all.sh (27/28; test-cleanup-tmp.sh fails before this change); ./sprint.sh validate --commands; ./sprint.sh validate --docs · pass
