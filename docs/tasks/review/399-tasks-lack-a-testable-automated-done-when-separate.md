# Task 399: Tasks lack a testable automated done-when separate from human sign-off

**Feature**: none
**Created**: 2026-10-08
**Docs**: none
**Plan**: 28
**From plan**: none
**Depends on**: none
**Dependents**: 400, 402
**Parent**: none
**Crew**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

A task has one success section that mixes what a machine can prove with what
only a person can judge. Agents can't tell when they're done, and humans can't
see what's left for them to check. The task needs a testable automated
done-when, kept separate from the human sign-off list.

## Done when (automated)

- [x] The task template replaces ## Success criteria with `## Done when (automated)` (the outcome plus the tests or commands that prove it) and `## Signoff (human)` (what a person checks).
- [x] One lib.sh helper returns a task's automated done-when section, and every reader goes through it. A task with only the old ## Success criteria is read as Done when (automated), so existing tasks keep working.
- [x] The gate (gate-lib.sh) fills in or sharpens both sections before a task enters next/, and refuses READY when Done when (automated) names no test or command.
- [x] ai/task-creation.md, ai/refine.md and the chat/split/plan-think prompts write the new sections.
- [x] Proven by `bash docs/tests/test-done-when.sh` (gate refuses READY without a testable Done when (automated); old-heading fallback), plus `bash docs/tests/test-scrub-scaffold.sh`, `bash docs/tests/test-open-questions.sh`, `bash docs/tests/test-plan-lifecycle.sh`, `./sprint.sh validate --commands` and `./sprint.sh validate --docs`.

## Signoff (human)

- Create a task with `./sprint.sh newtask "..."` and read it: the two sections say plainly what a machine proves and what a person checks.
- Open an older task with only ## Success criteria and run `./sprint.sh plan check` on its plan: it still reads as defined.

## Notes

Shared policy, names and formats: docs/plans/28-enhance-crews-and-efficiency.md → Policy. Use them exactly.

"Success criteria" is parsed in about 15 scripts (grep -l 'Success criteria' docs/sprintbias). Add one helper and point readers at it rather than hand-editing each regex; leave the helper's fallback to the old heading in place. The heading text is a contract: lib.sh and the runners key off headings verbatim. The work.sh doc-follow-up block at lib.sh ~692 writes a ## Success criteria section; move it to the new heading.

## References

docs/plans/28-enhance-crews-and-efficiency.md
docs/tasks/.TEMPLATE-task.md
docs/sprintbias/scripts/gate-lib.sh
docs/sprintbias/lib.sh
docs/sprintbias/ai/task-creation.md
docs/sprintbias/ai/refine.md
docs/sprintbias/scripts/validate-tasks.sh

## Grounding

**Sources:** `docs/plans/28-enhance-crews-and-efficiency.md` (Policy: section names and the old-heading rule), `CLAUDE.md` / `CONTRIBUTING.md` (docs/ is live, src/ is shipped by the human, surfaces kept in step), `docs/tasks/.TEMPLATE-task.md` (task shape), `docs/sprintbias/lib.sh` (shared helpers; headings are a verbatim contract)
**Touching:** docs/tasks/.TEMPLATE-task.md, docs/sprintbias/lib.sh (new sprintbias_done_when* helpers next to sprintbias_open_questions; doc-follow-up tracker awk line), docs/sprintbias/scripts/gate-lib.sh, docs/sprintbias/scripts/plan-check.sh (has_success_criteria), docs/sprintbias/scripts/chat-bugs.sh, prompt text only in chat.sh, chat-sprint.sh, chat-plan.sh, split.sh, plan-think.sh, polish.sh, work.sh (one line in the worker brief), promote.sh (accept prompt lines only), docs/sprintbias/ai/{task-creation,refine,accept,conversation}.md, docs/sprintbias/scripts/validate-tasks.sh (comment), help/{newtask,chat,validate,promote}.md (Success-criteria lines only), docs/tests/test-done-when.sh (new), docs/tests/test-scrub-scaffold.sh, CHANGELOG.md
**Terms:**
- None. (No project glossary; plan 28 Policy defines `## Done when (automated)`, `## Signoff (human)`.)
**Conflicts:**
- Task vs plan Policy: "testable" is not defined → a Done when (automated) section is testable when it names at least one command or test in backticks (for example `bash docs/tests/test-x.sh`); the gate prompt states this positively and the shell checks it.
- Task vs framework: ai/accept.md and promote's accept prompt judge "Success criteria"; a task with only the new headings would read as having none → point them at Done when (automated) (old heading still counts).
- Task vs code: bug reports (docs/bugs/.TEMPLATE-bug.md) keep ## Success criteria; they are not tasks → chat-bugs copies a report's criteria into the task's done-when section through the helper; the bug template is unchanged.

## Questions

**Status: READY**

### Already complete
None — no matching implementation found. Checked: the template still has ## Success criteria; plan-check.sh `has_success_criteria`, chat-bugs.sh and lib.sh's doc-follow-up tracker key off `## Success criteria` directly; gate-lib.sh has no testability check.

### Remaining work
- Template sections, lib.sh helper with old-heading fallback, readers routed through it.
- Gate contract text plus a shell check that refuses READY on an untestable Done when (automated).
- AI guidance and prompts write the new sections; tests for refusal and fallback.

### Questions for the developer
None — task is fully defined.

## Completed

Helper: `sprintbias_done_when FILE` (lib.sh) prints a task's
`## Done when (automated)` body with hint comments removed, falling back to an
older `## Success criteria`; `sprintbias_done_when_heading` names the heading a
file carries (writers use it), and `sprintbias_done_when_testable` holds when
the section names a test or command in backticks. The gate's exec route
overrides a READY stamp to BLOCKED (with a ## BLOCKED reason) when that check
fails; the emit prompt states the same rule.

### Files changed
docs/tasks/.TEMPLATE-task.md
docs/sprintbias/lib.sh
docs/sprintbias/scripts/gate-lib.sh
docs/sprintbias/scripts/plan-check.sh
docs/sprintbias/scripts/chat-bugs.sh
docs/sprintbias/scripts/chat.sh
docs/sprintbias/scripts/chat-sprint.sh
docs/sprintbias/scripts/chat-plan.sh
docs/sprintbias/scripts/split.sh
docs/sprintbias/scripts/plan-think.sh
docs/sprintbias/scripts/polish.sh
docs/sprintbias/scripts/work.sh
docs/sprintbias/scripts/promote.sh
docs/sprintbias/scripts/validate-tasks.sh
docs/sprintbias/ai/task-creation.md
docs/sprintbias/ai/refine.md
docs/sprintbias/ai/accept.md
docs/sprintbias/ai/conversation.md
docs/sprintbias/help/chat.md
docs/sprintbias/help/newtask.md
docs/sprintbias/help/plan.md
docs/sprintbias/help/promote.md
docs/sprintbias/help/validate.md
docs/tests/test-done-when.sh
docs/tests/test-scrub-scaffold.sh
CHANGELOG.md

### Doc follow-ups
- `DOCUMENTATION.md` — the manual does not yet describe the task sections (Done when (automated), Signoff (human)); task 405 owns the docs pass.
- `docs/sprintbias/learning/session.py` — the demo still says "Writing that into Success criteria"; task 406 owns the demos.

Overlap with #398: work.sh, promote.sh, lib.sh and help/promote.md are shared; only the Success-criteria lines changed here, and the new helpers sit after sprintbias_has_open_questions. The bug template (docs/bugs/.TEMPLATE-bug.md) keeps ## Success criteria by design; chat-bugs copies it into the new task's done-when section.

**Proof**: 2026-10-08 · `bash docs/tests/test-done-when.sh`, `bash docs/tests/test-scrub-scaffold.sh`, `bash docs/tests/test-open-questions.sh`, `bash docs/tests/test-plan-lifecycle.sh`, `bash docs/tests/run-all.sh` (26/27; test-cleanup-tmp.sh fails before this change), `./sprint.sh validate --commands`, `./sprint.sh validate --docs` · pass
