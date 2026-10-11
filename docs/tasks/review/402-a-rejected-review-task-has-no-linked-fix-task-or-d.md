# Task 402: A rejected review/ task has no linked fix task or dependent trace

**Feature**: none
**Created**: 2026-10-08
**Docs**: none
**Plan**: 28
**From plan**: none
**Depends on**: 398, 399
**Dependents**: 403, 405
**Parent**: none
**Crew**: none
**Tests**: docs/tests/test-promote.sh
**Refined**: 0
**Reworked**: 0
**Touching:** docs/sprintbias/lib.sh (sprintbias_dep_landed, new sprintbias_held_fixes / sprintbias_file_fix_task / sprintbias_add_test_log next to them; header index lines), docs/sprintbias/scripts/promote.sh, docs/tasks/.TEMPLATE-task.md, docs/sprintbias/help/promote.md, docs/sprintbias/help/_registry (promote row), docs/guides/command-matrix.md (promote rows), docs/tests/test-promote.sh, DOCUMENTATION.md (promote section, if it lists flags), CHANGELOG.md

## Problem

When a human rejects a task in review/, there's no structured way to send it
back. Reworking the original erases its history, and the tasks built on it
aren't traced. A rejection should file a linked fix task for the same crew
member and mark everything the rejected work affects.

## Done when (automated)

- [x] `./sprint.sh promote --reject <id> "what is wrong"` (a flag on promote) files a fix task through newtask with `**Fixes**: #<id>`, **Crew** and **Plan** copied from the original, and the fix listed on the original's plan. Proven by `bash docs/tests/test-promote.sh`.
- [x] The fix task's ## Done when (automated) turns each reported line (bug, error output, user story) into a test to add; untestable lines (look, feel, wording, a person's judgment) go under ## Signoff (human). `bash docs/tests/test-promote.sh`
- [ ] The original stays in review/ with `**Held**: fix #<new>`; `sprintbias_dep_landed` treats it as unlanded until the fix lands, and promote holds it out of done/ until the fix is in done/. `bash docs/tests/test-promote.sh`, `bash docs/tests/test-dep-work.sh`
- [ ] Every dependent of the original that is landed (review/ + proof) or signed off (done/) gets a re-check line in its ## Test log; done/ dependents are flagged in the output and stay put. `bash docs/tests/test-promote.sh`
- [ ] `sprintbias_file_fix_task ORIGINAL_ID "report"` in lib.sh files the fix task (reusable by #403). `bash docs/tests/test-promote.sh`
- [ ] The task template carries `**Fixes**: none`; help/promote.md, the promote registry row and the command matrix name `--reject`. `./sprint.sh validate --commands`, `./sprint.sh validate --docs`, `bash docs/tests/test-create-task.sh`

## Signoff (human)

- [ ] Reject a real review/ task with a two-line report and read the fix task: it reads as a clear, workable brief.

## Notes

Shared policy, names and formats: docs/plans/28-enhance-crews-and-efficiency.md → Policy. Use them exactly.

Use newtask so IDs stay locked. Task 399 has landed its template change: add `**Fixes**: none` to the template header; **Held** appears only on a rejected original, so it stays out of the template.

Held rule: extend `sprintbias_dep_landed` so one rule serves every caller (a held review/ task counts as landed only once its fix lands), and promote's close gate holds a held original until its fix is in done/. **Held** stays on the file as history.

## References

docs/plans/28-enhance-crews-and-efficiency.md
docs/sprintbias/scripts/promote.sh
docs/sprintbias/scripts/create-task.sh
docs/tasks/.TEMPLATE-task.md
docs/sprintbias/help/promote.md
docs/tests/test-promote.sh

## Grounding

**Sources:** `docs/plans/28-enhance-crews-and-efficiency.md` (Policy: Fixes, Held, Test log, section names, landed vs signed off), `docs/sprintbias/lib.sh` (sprintbias_dep_landed, sprintbias_has_proof, sprintbias_dependents_of, plan member index), `docs/sprintbias/scripts/promote.sh` (close gate), `docs/sprintbias/scripts/create-task.sh` (ID lock), `docs/tasks/.TEMPLATE-task.md` (header fields), `docs/sprintbias/help/_registry` + `docs/guides/command-matrix.md` (command surfaces)
**Terms:**
- **Landed** — in review/ with a proof line. Landed work releases its dependents.
- **Signed off** — in done/. Only humans move work there.
- **Fixes / Held** — `**Fixes**: #<id>` on the fix task; `**Held**: fix #<new>` on the rejected original, which stays in review/ and releases nothing until the fix lands.
**Conflicts:**
- **Plan** is derived from plan files (`sprintbias_reconcile_task_plan`), so copying it alone would drift → the fix task is also listed on the original's plan, right under the original's member line.
- Policy says a held original releases nothing "until the fix lands", the task says it reaches done/ "only after its fix task does" → both hold: dependents release when the fix lands; promote closes the original only once the fix is in done/.

## Questions

**Status: READY**

### Already complete
- `sprintbias_dep_landed` / `sprintbias_has_proof` (lib.sh, #398) and the new task sections plus `sprintbias_done_when_heading` (#399) are in place and read correctly.
- None of the reject path exists: promote.sh has no --reject, no **Fixes**/**Held** field anywhere.

### Remaining work
- `promote --reject <id> "report"` plus `sprintbias_file_fix_task` in lib.sh.
- Held check inside `sprintbias_dep_landed` and promote's close gate.
- Dependent trace (## Test log re-check lines, done/ flagged).
- Template **Fixes** field, help, registry, command matrix, tests, changelog.

### Questions for the developer
None — task is fully defined.

## Completed

**Held rule:** `sprintbias_dep_landed` counts a review/ task with `**Held**: fix #N` as landed only once every fix it names has landed (one rule for work, loop, promote and the queue prompts). promote's close gate keeps the held original in review/ until each fix is in done/. **Held** stays on the file as history; nothing clears it.

Fix-task items: each `- ` / `* ` / `N. ` bullet, else each blank-line paragraph (an error excerpt stays one item). An item prefixed `human:` / `signoff:`, or mentioning look / feel / wording / tone / ugly / confusing / hard to read, goes under Signoff (human); every other item becomes a test to add. The fix is also listed on the original's plan (the plan file is the membership authority) and copies the original's **Tests**.

**Proof**: 2026-10-08 · bash docs/tests/test-promote.sh; bash docs/tests/test-dep-work.sh; bash docs/tests/test-create-task.sh; ./sprint.sh validate --commands; ./sprint.sh validate --docs · pass

### Files changed
docs/sprintbias/lib.sh
docs/sprintbias/scripts/promote.sh
docs/tasks/.TEMPLATE-task.md
docs/sprintbias/help/promote.md
docs/sprintbias/help/_registry
docs/guides/command-matrix.md
docs/tests/test-promote.sh
DOCUMENTATION.md
CHANGELOG.md
