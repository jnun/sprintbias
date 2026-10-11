# Task 428: Close a task with no Tests in one command: promote --accept

**Feature**: none
**Created**: 2026-10-10
**Docs**: none
**Plan**: 32
**From plan**: none
**Depends on**: 426
**Dependents**: 429, 432
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-promote.sh, docs/tests/test-proof-loop.sh
**Refined**: 0
**Reworked**: 0

## Problem

The end-of-run checklist's last step for a task with no **Tests** is a two-clause `git mv … || mv …` with a glob, and promote's own skip advice prints a different long form. Closing a task you are happy with should be one short line that reads like the `promote --reject` step right above it.

- Decided: `./sprint.sh promote --accept <id>`, because it pairs with `--reject <id>` and keeps done/ moves inside the one command that owns them.

## Done when (automated)

- [x] `./sprint.sh promote --accept <id>` moves review/<id> to done/ when the task has no Tests; when Tests are named they run and must pass; **Held** and **Depends on** holds still apply; a human test (`**Owner**: human`) points to `./sprint.sh promote plan:N` (`bash docs/tests/test-promote.sh`)
- [x] work's checklist closes a task with no Tests with `./sprint.sh promote --accept <id>` and one with Tests with `./sprint.sh promote <id>` (`bash docs/tests/test-proof-loop.sh`)
- [x] promote's skip summary names `./sprint.sh promote --accept <id>` for each skipped task (`bash docs/tests/test-promote.sh`)
- [x] help/promote.md, the registry usage, DOCUMENTATION.md and command-matrix.md document `--accept` (`./sprint.sh validate --commands --docs`)

## Signoff (human)

Checked in the plan's one human test, #434.

## Notes

`--accept` is the person's sign-off, so it closes an unproven task too; the checklist already shows the Test log step first.

## References

docs/sprintbias/scripts/promote.sh
docs/sprintbias/scripts/work.sh
docs/sprintbias/help/promote.md
docs/tests/test-promote.sh

## Grounding

**Sources:** `docs/sprintbias/help/_registry` (command catalog: promote usage line), `docs/sprintbias/help/promote.md` (promote help page), `DOCUMENTATION.md` (user manual), `docs/guides/command-matrix.md` (command surfaces), `docs/sprintbias/scripts/promote.sh` (review/ → done/ moves), `docs/sprintbias/scripts/work.sh` (end-of-run checklist and its emit spec)
**Terms:**
- None.
**Conflicts:**
- The Notes say `--accept` closes an unproven task, while the first Done when item says named Tests run and must pass → `--accept` treats a missing **Proof** line as the person's sign-off, and it still runs any named **Tests** and refuses on red.
- work.sh prints the old `git mv … || mv …` close line in two places: the live checklist (`_review_checklist`, around line 944) and the emit checklist spec (around line 1114) → change both to `./sprint.sh promote --accept <id>`. Task 426 edits the same emit spec, so this task waits on it (Depends on 426).
- `docs/tests/test-proof-loop.sh` has no promote assertion yet → the work adds the checklist assertion there, as the Tests field already names.

## Questions

**Status: READY**

### Already complete
None — no matching implementation found.
- `docs/sprintbias/scripts/promote.sh` parses `--reject`, `--dry-run`, `--audit`, `--move`, `--fresh`, `plan:N` and ids (lines 70-79); there is no `--accept`, so it exits 2 as an unknown argument.
- The promote skip summary (lines 882-897) still prints the long `git mv … || mv …` close line.
- The work.sh checklist (lines 939-945) and its emit spec (line 1114) print the `git mv` glob for a task with no Tests and `./sprint.sh promote <id>` for one with Tests.
- The human-test redirect to `promote plan:N` already exists for a plain id (`sprintbias_is_human_task`, lines 131-135). `--accept` can reuse it.
- None of the registry, help/promote.md, DOCUMENTATION.md or command-matrix.md mention `--accept`.

### Remaining work
- Add `--accept <id>` to promote.sh. It takes one id, moves review/<id> to done/ with `git mv || mv`, runs any named Tests first (red keeps the task in review/), applies the **Held** and **Depends on** holds, and sends a human test to `./sprint.sh promote plan:N`.
- Cover each of those paths in `docs/tests/test-promote.sh`.
- Change promote's skip summary to `./sprint.sh promote --accept <id>`, one line per skipped task.
- Change the work.sh checklist and emit spec to close a no-Tests task with `./sprint.sh promote --accept <id>`, and assert it in `docs/tests/test-proof-loop.sh`.
- Document `--accept` in the registry usage line, help/promote.md, DOCUMENTATION.md and command-matrix.md, then check with `./sprint.sh validate --commands --docs`. Add a CHANGELOG `### Added` bullet.

### Questions for the developer
None — task is fully defined.

## Test log

- `bash docs/tests/test-promote.sh` Test 3 asserted the skip line says "human sign-off" → corrected to assert the skip line's one-line close (`./sprint.sh promote --accept 702`), because the check pinned the old wording and the close command is what the person needs.

## Completed

- `promote --accept <id>`: the person's sign-off for one task. No Tests → done/; named Tests still run and must pass; **Held** and **Depends on** holds apply; the human test still points to `promote plan:N`; it refuses other modes and needs an id.
- promote's skip line and skip summary print `./sprint.sh promote --accept <id>` per skipped task (the hand `git mv … || mv …` advice is gone).
- work's checklist (exec and emit spec) closes a no-Tests task with `./sprint.sh promote --accept <id>`.
- help/promote.md, the registry usage, DOCUMENTATION.md and command-matrix.md document it; CHANGELOG.md Added bullet. The plan 30 Added bullet that called deciding fast-only now names only fast's reach.

### Assumptions
- Decided: `--accept` on a task with named Tests runs them like `promote <id>`, because a person's sign-off should not close work its own suite says is broken.
- Decided: edit the plan 30 Unreleased bullet in CHANGELOG.md, because it would ship telling users that only fast mode decides, which #424 changed.

### Files changed
docs/sprintbias/scripts/promote.sh
docs/sprintbias/scripts/work.sh
docs/sprintbias/help/promote.md
docs/sprintbias/help/_registry
docs/guides/command-matrix.md
DOCUMENTATION.md
CHANGELOG.md
docs/tests/test-promote.sh
docs/tests/test-proof-loop.sh

**Proof**: 2026-10-10 · bash docs/tests/test-promote.sh, bash docs/tests/test-proof-loop.sh, ./sprint.sh validate --commands --docs · pass

## Plan Think

FINISHED (review/). `promote --accept <id>` closes a task in one line and still runs any named Tests. Architect: done/ moves stay inside promote. Experience: the close command pairs with `--reject`. Nothing more is needed. Left as-is.
