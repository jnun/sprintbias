# Task 427: Retire settle now that gate and work take suggestions

**Feature**: none
**Created**: 2026-10-10
**Docs**: none
**Plan**: 32
**From plan**: none
**Depends on**: 424
**Dependents**: 430
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-open-questions.sh, docs/tests/test-no-stale-refs.sh, docs/tests/test-command-matrix-smoke.sh
**Refined**: 0
**Reworked**: 0

## Problem

`settle` folds `(Suggestion: …)` answers into a task, but the gate, `work` and `sprintbias_demote_open_questions` now take every suggestion on their own. A person never needs to type `settle`, yet it costs a help page, a registry row, a dispatch arm, and messages across lib.sh and the docs that send people to it instead of to the command that moves work forward.

- Decided: retire `settle`, because every path into next/ (gate, plan start, `work <id>`) already takes suggested answers; successor is `work <id>` (auto-gates a blocked task back in) or `chat <id>` (no reasonable reading yet).

## Done when (automated)

- [x] settle.sh, help/settle.md, the registry row and the dispatch arm are gone; command-matrix.md lists `settle` under Retired names (`./sprint.sh validate --commands`)
- [x] No shipped file tells the person to run settle: lib.sh demote and sweep messages, work.sh, help/gate.md, help/work.md, DOCUMENTATION.md, ai/task-creation.md; test-no-stale-refs.sh guards `./sprint.sh settle` (`bash docs/tests/test-no-stale-refs.sh`)
- [x] The demote and sweep messages end with the exact next command (`./sprint.sh work <id>` or `./sprint.sh chat <id>`) (`bash docs/tests/test-open-questions.sh`)
- [x] test-open-questions.sh proves Test 5's outcome through `sprintbias_demote_open_questions` (suggestion taken, unsuggested question demoted) instead of settle.sh (`bash docs/tests/test-open-questions.sh`)
- [x] test-command-matrix-smoke.sh no longer runs settle (`bash docs/tests/test-command-matrix-smoke.sh`)
- [x] An upgrading install prunes the old files: setup.sh `RETIRED_FRAMEWORK_FILES` lists `docs/sprintbias/scripts/settle.sh` and `docs/sprintbias/help/settle.md` under a `# settle → work · chat` comment (`grep -n 'settle' setup.sh`)
- [x] CHANGELOG.md `## Unreleased` carries one plain-language bullet saying settle is retired and naming `work <id>` / `chat <id>` (`grep -n 'settle' CHANGELOG.md`)
- [x] The full suite passes (`bash docs/tests/run-all.sh`)

## Signoff (human)

Checked in the plan's one human test, #434.

## Notes

Keep `sprintbias_accept_suggestions` (the gate and demote use it) and the "Settled (accept suggestions)" block it writes; `_task_calls` reads that block. Plain-English uses of the word "settle" stay.

- Decided: the demote messages point to `./sprint.sh chat <id>` first (a demoted task only keeps questions with no suggestion), then `./sprint.sh work <id>` to re-gate and run it, because suggested answers are already taken before demote runs.
- Decided: add settle.sh and help/settle.md to setup.sh's retired-file list, because an upgrade otherwise leaves a dead script and help page in the user's install.
- Decided: reword the work.sh comment near line 885 ("suggestions taken by settle") to name the gate/demote, because it describes behavior that outlives the command.

## References

docs/sprintbias/scripts/settle.sh
docs/sprintbias/help/settle.md
docs/sprintbias/help/_registry
sprint.sh
docs/guides/command-matrix.md
docs/sprintbias/lib.sh
docs/sprintbias/scripts/work.sh
docs/sprintbias/help/gate.md
docs/sprintbias/help/work.md
docs/sprintbias/ai/task-creation.md
DOCUMENTATION.md
setup.sh
docs/tests/test-open-questions.sh
docs/tests/test-no-stale-refs.sh
docs/tests/test-command-matrix-smoke.sh

## Grounding

**Sources:** `docs/sprintbias/help/_registry` (command catalog, source of truth for commands), `docs/guides/command-matrix.md` (command surface and Retired names), `DOCUMENTATION.md` (user manual), `CONTRIBUTING.md` (surfaces kept in step for a retired command: registry, help, manual, matrix, changelog), `setup.sh` (retired-file pruning on upgrade)
**Terms:**
- None. (No glossary; project map not yet created.)
**Conflicts:**
- CONTRIBUTING.md requires a retirement to update the changelog and setup.sh prunes retired files, but the original Done when listed neither → added both as Done when outcomes.
- work.sh:885 comment says suggestions are "taken by settle" while the task keeps the behavior and drops the command → reword the comment to name the gate/demote.
- Tasks 425 (gate procedure) and 426 (work prompts) also edit help/gate.md, help/work.md and work.sh → edit only the settle lines here; this task already depends on 424 and the overlap is sequencing, not scope.

## Questions

**Status: READY**

### Already complete
None — no matching implementation found. Checked:
- `docs/sprintbias/scripts/settle.sh`, `help/settle.md` exist; `help/_registry:37` row and `sprint.sh:394-396,572` dispatch are present.
- `command-matrix.md:129` still lists settle as live; Retired names has no settle row.
- Settle pointers remain at `lib.sh:1413-1414,1423,1452`, `work.sh:360-361`, `help/gate.md:62`, `help/work.md:164`, `ai/task-creation.md:86`, `DOCUMENTATION.md:205`.
- `sprintbias_demote_open_questions` (`lib.sh:1366-1377`) already takes suggestions first, so the replacement behavior exists.
- `test-open-questions.sh` Test 5 still calls settle.sh; `test-command-matrix-smoke.sh:329-331` still runs settle; `test-no-stale-refs.sh` has no settle guard; setup.sh's retired list lacks settle.

### Remaining work
- Delete settle.sh, help/settle.md, the registry row and the sprint.sh function and dispatch arm; move settle to Retired names in command-matrix.md (successor `work · chat`).
- Rewrite the lib.sh demote/BLOCKED-section/sweep messages, work.sh, help/gate.md, help/work.md, ai/task-creation.md and DOCUMENTATION.md to point to `chat <id>` / `work <id>`.
- Add a `./sprint.sh settle` guard to test-no-stale-refs.sh; rework Test 5 through `sprintbias_demote_open_questions`; drop the smoke-test settle case.
- Add settle files to setup.sh `RETIRED_FRAMEWORK_FILES`; add the CHANGELOG bullet.

### Questions for the developer
None — task is fully defined.

## Test log

- `bash docs/tests/test-open-questions.sh` — new check "BLOCKED section ends in the next commands" failed: with gate-lib loaded, demote writes gate-lib's own ## BLOCKED text ("Needs a decision … Chat: ./sprint.sh chat N"), not lib.sh's fallback → clear cause, fixed: both writers now say the task cannot start and end `./sprint.sh chat N — then run it: ./sprint.sh work N`.

## Completed

- Removed settle.sh, help/settle.md, the registry row and the `cmd_settle` dispatch; command-matrix.md lists `settle` under Retired names (successor `work <id>` · `chat <id>`); setup.sh prunes both files on upgrade.
- Every message that sent the person to settle now ends in `./sprint.sh chat <id>` then `./sprint.sh work <id>`: lib.sh demote and sweep, gate-lib's BLOCKED sections, work.sh's single-task hold, help/gate.md, help/work.md, ai/task-creation.md; DOCUMENTATION.md lost the settle line.
- test-open-questions.sh Test 5 proves the outcome through `sprintbias_demote_open_questions`; test-no-stale-refs.sh guards `./sprint.sh settle`; test-command-matrix-smoke.sh dropped its settle row; CHANGELOG.md bullet.

### Assumptions
- Decided: gate-lib's two ## BLOCKED writers get the same chat-then-work ending as the demote message, because the demote path calls gate-lib's writer whenever it is loaded and the two texts would otherwise disagree.

### Files changed
sprint.sh
setup.sh
DOCUMENTATION.md
CHANGELOG.md
docs/sprintbias/help/_registry
docs/guides/command-matrix.md
docs/sprintbias/lib.sh
docs/sprintbias/scripts/gate-lib.sh
docs/sprintbias/scripts/work.sh
docs/sprintbias/help/gate.md
docs/sprintbias/help/work.md
docs/sprintbias/ai/task-creation.md
docs/sprintbias/scripts/settle.sh (deleted)
docs/sprintbias/help/settle.md (deleted)
docs/tests/test-open-questions.sh
docs/tests/test-no-stale-refs.sh
docs/tests/test-command-matrix-smoke.sh

**Proof**: 2026-10-10 · bash docs/tests/test-open-questions.sh, bash docs/tests/test-no-stale-refs.sh, bash docs/tests/test-command-matrix-smoke.sh, ./sprint.sh validate --commands, bash docs/tests/run-all.sh · pass

## Plan Think

FINISHED (review/). settle is retired, with pruning on upgrade and a stale-reference guard. Architect: retiring the command removes one dispatch arm and a help page (the context-cost lens). Experience: every BLOCKED message ends in `chat <id>` then `work <id>`. Nothing more is needed. Left as-is.
