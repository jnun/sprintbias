# Task 426: Work prompts follow the finishing rule end to end

**Feature**: none
**Created**: 2026-10-10
**Docs**: none
**Plan**: 32
**From plan**: none
**Depends on**: 424
**Dependents**: 428, 432
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-proof-loop.sh, docs/tests/test-finish-rule.sh
**Refined**: 0
**Reworked**: 0

## Problem

work's own rules contradict the finishing rule they splice in. `_TASK_RULES` ends with "Product/scope fork that needs a human: one-line ## Outcome Reason, then stop", `_WORKER_GOAL` says "## Outcome, then blocked/", and the emit routing step offers "product/scope fork for a human" as a Reason. Other lines restate the rule ("pick a sensible default and finish", "A person-only check never holds a task"), so each prompt says it twice in different words. The emit checklist spec lists fewer call sources than `_task_calls`, and the "Your turn" header counts tasks whose files have gone.

## Done when (automated)

- [x] The exec prompt and both emit prompts carry no fork-stop line; the only stop left is the proof rule's cannot-start case (`bash docs/tests/test-finish-rule.sh`, `bash docs/tests/test-proof-loop.sh`)
- [x] The emit routing Reason names only cannot-start causes: no reasonable reading, or access or credentials the person holds (`bash docs/tests/test-finish-rule.sh`)
- [x] The rule text appears once per prompt: the restating lines in `_TASK_RULES` and `_WORKER_GOAL` are gone (`bash docs/tests/test-finish-rule.sh`)
- [x] The emit checklist spec lists the same call sources as `_task_calls`: Grounding conflicts, `Decided:` lines, and suggestions the gate took (`bash docs/tests/test-proof-loop.sh`)
- [x] The "Your turn" header counts only tasks still in review/ (`bash docs/tests/test-proof-loop.sh`)

## Signoff (human)

Checked in the plan's one human test, #434.

## Notes

- Decided: tasks that finish a run with no ## Completed keep today's route (blocked/ with an Incomplete reason), because changing it touches the retry loop in `loop`; a follow-up task records the question (task 433).
- Decided: the cannot-start case in `sprintbias_proof_rule` names both causes (no reasonable reading; access or credentials the person holds), because the emit Reason and 424's finishing rule name both and the one stop left in each prompt should match them.
- Decided: the third call source is worded "suggestions the gate took" (the `Settled (accept suggestions)` block), because 427 retires `settle` but keeps that block, and `_task_calls` keeps reading it.

## References

docs/sprintbias/scripts/work.sh
docs/sprintbias/lib.sh
docs/tests/test-proof-loop.sh
docs/tests/test-finish-rule.sh (created by 424)
docs/tasks/backlog/433-*.md (routing follow-up)

## Grounding

**Sources:** `CLAUDE.md` (guiding principles: positive instruction, context cost), `DOCUMENTATION.md` (task workflow and lifecycle folders), `docs/sprintbias/lib.sh` (shared prompt rules: `sprintbias_assume_rule`, `sprintbias_proof_rule`, `sprintbias_grounding_rule`), `docs/sprintbias/scripts/work.sh` (`_TASK_RULES`, `_WORKER_GOAL`, emit prompts, `_task_calls`, `_report_human_review`)
**Terms:**
- None. (No project glossary yet; `docs/sprintbias/project.md` is absent.)
**Conflicts:**
- `docs/tests/test-finish-rule.sh` does not exist yet → task 424 creates it (Depends on: 424); this task adds its assertions there.
- `sprintbias_proof_rule` names only "missing access or credentials" as cannot-start, while the emit Reason here also names "no reasonable reading" → align the proof rule to both causes (recorded as `Decided:` in Notes).
- `_task_calls` comment credits suggestions "taken by settle", which 427 retires → describe that source as suggestions the gate took; keep reading the `Settled (accept suggestions)` block.

## Questions

**Status: READY**

### Already complete
- `_task_calls` (docs/sprintbias/scripts/work.sh ~886) already gathers all three sources: Grounding conflicts, `Decided:` bullets, and the `Settled (accept suggestions)` block. Clean.
- `sprintbias_proof_rule` (lib.sh ~728) already carries the cannot-start stop (`**Result**: blocked`), the one stop meant to remain.
- test-proof-loop.sh Test 5 already renders both emit prompts (orchestrated and sequential), so new assertions slot in there.

### Remaining work
- Remove the fork-stop lines: `_TASK_RULES` "Product/scope fork that needs a human: one-line ## Outcome Reason, then stop." and `_WORKER_GOAL` "Product/scope fork that needs a human: ## Outcome, then blocked/."
- Remove the restating lines: "pick a sensible default and finish" (`_TASK_RULES`), "Choose best practice and finish." and "A person-only check never holds a task: assume, record it, land it." (`_WORKER_GOAL`); the spliced `sprintbias_assume_rule` carries the rule once.
- Both emit routing steps (3b): Reason names only cannot-start causes (no reasonable reading, or access or credentials the person holds).
- `_EMIT_REPORT` step 1 lists all three call sources, matching `_task_calls`.
- `_report_human_review` header counts only `TO_REVIEW` entries whose file is still in review/; `_EMIT_REPORT` says to count tasks still in review/.
- Align the cannot-start wording in `sprintbias_proof_rule` (see Notes).
- Add assertions to test-finish-rule.sh (no fork-stop, no restating line, Reason causes) and test-proof-loop.sh (checklist sources, header count with a missing file).

### Questions for the developer
None — task is fully defined.

## Test log

- `bash docs/tests/test-proof-loop.sh` Test 4 — its stub worker blocked on "pick JSON or YAML for the store", a decision the finishing rule now makes → corrected the stub Reason to "needs the production API key", because the test checks routing of a cannot-start Outcome and its example should be one.
- `bash docs/tests/test-proof-loop.sh` Test 6 (new) — "Emit spec: suggestions the gate took" failed: the exec run before it had moved the task to review/, so emit had nothing to print → test setup fixed (fresh sandbox before the emit call); work.sh was right.

## Completed

- `_TASK_RULES` lost the fork-stop line, the "pick a sensible default" restatement and its duplicate commit/ship line (the finishing rule carries it); `_WORKER_GOAL` says workers decide, record and finish, and only work that cannot start goes to blocked/.
- Both emit routing templates ask for a Reason naming why the work could not finish (no reasonable reading, access only the person holds, or the run ran out).
- `sprintbias_proof_rule`'s cannot-start case names both causes.
- The emit checklist spec lists all three call sources; the exec "Your turn" header counts only tasks still in review/.

### Assumptions
- Decided: the emit Reason keeps "or the run ran out" as a third cause, because route b also catches workers that stopped mid-task, which is not a cannot-start case and is task #433's to re-home.

### Files changed
docs/sprintbias/scripts/work.sh
docs/sprintbias/lib.sh
docs/tests/test-proof-loop.sh
docs/tests/test-finish-rule.sh

**Proof**: 2026-10-10 · bash docs/tests/test-proof-loop.sh, bash docs/tests/test-finish-rule.sh, bash docs/tests/test-fast.sh, bash docs/tests/test-dep-work.sh · pass

## Plan Think

FINISHED (review/). The fork-stop lines are gone from the work prompts, and the checklist sources match `_task_calls`. Architect: there is now one stop path, the proof rule's cannot-start case. Experience: "Your turn" counts only real review/ tasks. Tension: help/work.md:102 and :120 still describe the fork-stop, and work.sh:1789's drift label says "needs decision". This task's Done when named only the prompts, so delta #436 carries the doc and the label. Left as-is.
