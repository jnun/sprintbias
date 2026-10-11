# Task 424: One finishing rule: default decides, fast adds only fast-specific reach

**Feature**: none
**Created**: 2026-10-10
**Docs**: none
**Plan**: 32
**From plan**: none
**Depends on**: none
**Dependents**: 425, 426, 427, 430, 431
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-finish-rule.sh, docs/tests/test-fast.sh
**Refined**: 0
**Reworked**: 0

## Problem

Two prompt blocks give agents two different rules. `sprintbias_assume_rule` (every mode) says take the most reasonable pick and keep going. `sprintbias_fast_rules` (fast only) tells a headless agent to write its question into the task file and take the next task, and lets "the one goal-shaping item" wait. In fast mode an agent gets both and stalls. In steady mode agents miss the parts of the fast block that are simply good practice: the `Decided:` format, tool ideas filed as a backlog task, one-keystroke questions. `sprintbias_grounding_rule` still calls a scope conflict "a product/scope fork for the human".

## Done when (automated)

- [x] `sprintbias_assume_rule` is the one finishing rule for every mode: decide by best practice, good security, elegant code and the best UX; record each call as a `- Decided: X, because Y` bullet under `### Assumptions` (the form work's `_task_calls` reads); a question goes to the person only in a live conversation and only when its answer changes the goal or the result, asked as yes/no or 1/2/3 with one `(suggested)` option, and the work goes on with the suggested option; headless agents never wait; blocked/ holds only work with no reasonable reading or that needs access or credentials the person holds; a tool or process idea becomes `./sprint.sh newtask "..."` and the agent returns to the goal (`bash docs/tests/test-finish-rule.sh`)
- [x] `sprintbias_fast_rules` carries only what fast adds: subagents may build missing pieces, and the cross-plan rule (read the other plan's Goal, serve both goals, add `Touched by plan N: #id — what and why`); it prints nothing when fast is off (`bash docs/tests/test-fast.sh`)
- [x] No lib.sh rule tells an agent to wait or to park a question and leave ("Only the one goal-shaping item waits", "write the question into the task file" are gone) (`bash docs/tests/test-finish-rule.sh`)
- [x] `sprintbias_grounding_rule` settles a scope conflict by the finishing rule (`Decided:`) instead of handing it to the person (`bash docs/tests/test-finish-rule.sh`)
- [x] DOCUMENTATION.md describes the decide-and-record rule once for all modes; its Fast mode section lists only what fast adds (`bash docs/tests/test-fast.sh`)

## Signoff (human)

Checked in the plan's one human test, #434.

## Notes

Fast mode's shell behavior (no permission prompts, parallel work/polish) already lives in cli/ profiles and `sprintbias_fast_parallel`; the prompt block needs none of it. Keep both blocks short: they load with every task. Instruct positively (CLAUDE.md principle 4).

- Decided: keep the function name `sprintbias_assume_rule`, because work.sh, its tests and the lib.sh index already use it and a rename buys nothing.
- Decided: the "Commits, ship and deploys stay with the human." line leaves the fast block, because it holds in every mode and the steady prompts already carry it (`sprintbias_orient` names deploys and secrets as human-owned; work.sh's prompt names the human-owned commit and ship steps). Add it to `sprintbias_assume_rule` only if a prompt that loads the rule lacks it.
- Decided: `docs/sprintbias/help/fast.md` moves in step with DOCUMENTATION.md (its decide-and-record lines become a pointer to the one rule plus the fast add-ons), because the help page and the manual describe the same switch.
- Decided: update test-fast.sh's "Fast rules" checks to the new block (drop the waits / headless-writes / decide checks, assert their absence, keep the cross-plan, subagent and empty-when-off checks), because those checks pin the wording this task retires.

New test `docs/tests/test-finish-rule.sh` is the home for the plan's cross-surface prompt checks; later tasks add to it.

## References

docs/sprintbias/lib.sh
docs/tests/test-fast.sh
DOCUMENTATION.md
docs/sprintbias/help/fast.md

## Grounding

**Sources:** `CLAUDE.md` (guiding principles: positive instruction, context cost; human-owned actions), `CONTRIBUTING.md` (keep the surfaces in step; changelog), `DOCUMENTATION.md` (user manual, Fast mode section), `docs/sprintbias/lib.sh` (the prompt-rule blocks), `docs/sprintbias/help/fast.md` (fast help page), `docs/plans/32-bias-for-finishing-end-to-end.md` (plan policy: `- Decided: X, because Y` under `### Assumptions`)
**Terms:**
- None. (No project glossary; the project map docs/sprintbias/project.md does not exist yet.)
**Conflicts:**
- `docs/tests/test-fast.sh` asserts "Only the one goal-shaping item waits", "write the question into the task file" and "reversible call proceeds" in the fast block → this task retires that wording; update those checks in the same change (see Notes).
- `docs/tests/test-proof-loop.sh:99` asserts `sprintbias_assume_rule` contains `` `Decided: X, because Y` `` → keep that literal in the new rule so the check stays green.
- `sprintbias_assume_rule`'s comment says it serves "work, the gate and the authoring prompts", but only work.sh splices it today → wiring it into the gate, chat, plan and crew is sibling work (425, 426, 430, 431); this task changes the rule's text, and the comment is accurate once they land.
- `sprintbias_grounding_rule` calls a scope conflict "a product/scope fork for the human" while plan 32 says decide and record → rewrite that sentence to settle by `Decided:`; the gate contract in gate-lib.sh splices the function, so it picks up the change.

## Questions

**Status: READY**

### Already complete
None — no matching implementation found.
- `docs/sprintbias/lib.sh:470` `sprintbias_fast_rules` still holds the decide, ask, wait and headless-park lines plus the human-owned line; no subagent line.
- `docs/sprintbias/lib.sh:748` `sprintbias_assume_rule` carries `Decided: X, because Y` and the person-only check rule, but has no question form, no headless-never-waits line, no blocked/ bar and no newtask-for-tool-ideas line.
- `docs/sprintbias/lib.sh:632` `sprintbias_grounding_rule` still hands scope conflicts to the human.
- `docs/tests/test-finish-rule.sh` does not exist.
- `DOCUMENTATION.md:344-360` lists decide-and-record as fast-only.

### Remaining work
- Rewrite `sprintbias_assume_rule` as the one finishing rule for every mode (content per Done when), short and positive.
- Cut `sprintbias_fast_rules` to the fast add-ons: subagents may build missing pieces; the cross-plan rule. Still empty when fast is off.
- Change the scope-conflict sentence in `sprintbias_grounding_rule` to settle by `Decided:`.
- Add `docs/tests/test-finish-rule.sh` (assume-rule content, no wait/park wording anywhere in lib.sh, grounding-rule wording); update the `docs/tests/test-fast.sh` Fast rules checks.
- DOCUMENTATION.md: describe decide-and-record once for all modes; the Fast mode section lists only the add-ons. Bring `help/fast.md` in step. Add a `### Changed` bullet to CHANGELOG.md.
- Run `bash docs/tests/test-finish-rule.sh`, `bash docs/tests/test-fast.sh`, `bash docs/tests/test-proof-loop.sh`, then the suite.

### Questions for the developer
None — task is fully defined.

## Test log

- `bash docs/tests/test-fast.sh` — "Fast rules" checks pinned the retired fast wording (decide by best practice, goal-shaping item waits, headless writes the question, reversible proceeds) → corrected: the test now asserts the fast block carries only reach and none of that wording, because the finishing rule owns it.
- `bash docs/tests/test-proof-loop.sh` — "Decisions are assumed, not blocked" pinned the backticked `` `Decided: X, because Y` `` → corrected to the bullet form `- Decided: X, because Y`, because a bullet is what `_task_calls` reads and the rule now shows it.

## Completed

- `sprintbias_assume_rule` is the one finishing rule (decide, record a `- Decided:` bullet, ask only in a live conversation on goal questions, blocked/ = cannot start, tool ideas → newtask, commit/push/ship stay the person's).
- `sprintbias_fast_rules` now holds only fast's reach: subagents and the cross-plan rule.
- `sprintbias_grounding_rule` decides a scope conflict instead of handing it to the person.
- DOCUMENTATION.md agent rule 6 states the rule once for all modes; the Fast mode section and help/fast.md list only what fast adds.
- New `docs/tests/test-finish-rule.sh`; test-fast.sh and test-proof-loop.sh corrected (see ## Test log).

### Assumptions
- Decided: show the record form as its own indented bullet line instead of inline backticks, because an agent copies the example and only a plain `- Decided:` bullet reaches the end-of-run checklist.
- Decided: wiring the rule into chat, chat plan and crew prompts stays with #431, because that task owns those prompts; until it lands those prompts carry only the fast block in fast mode.
- Decided: replace DOCUMENTATION.md rule 6 ("Raise decisions one at a time") with the finishing rule, because it was the manual's one-place statement of how agents handle decisions and it contradicted the plan.

### Files changed
docs/sprintbias/lib.sh
docs/sprintbias/help/fast.md
DOCUMENTATION.md
CHANGELOG.md
docs/tests/test-finish-rule.sh
docs/tests/test-fast.sh
docs/tests/test-proof-loop.sh

**Proof**: 2026-10-10 · bash docs/tests/test-finish-rule.sh, bash docs/tests/test-fast.sh, bash docs/tests/test-proof-loop.sh, bash docs/tests/test-open-questions.sh · pass

## Plan Think

FINISHED (review/, Proof 2026-10-10). The finishing rule lives once in `sprintbias_assume_rule`, and the fast block carries only reach. Architect: one rule in one function is the right single source. Experience: the person gets the same behavior in every mode. Tension: this task rewrote the rule, but surfaces it never named still define blocked/ the old way. Resolved by delta #436, not by reopening this task. Left as-is.
