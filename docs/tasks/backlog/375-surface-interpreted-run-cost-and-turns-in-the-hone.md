# Task 375: Surface interpreted run cost and turns in the honest abort line and audit records

**Feature**: none
**Created**: 2026-08-21
**Docs**: none
**Plan**: none
**From plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-run-interpret.sh, docs/tests/test-audit-code.sh
**Refined**: 1
**Reworked**: 0

## Problem

When an audit run stops early, the one-line reason it prints
(`sprintbias_run_hint`) says "hit its turn limit before finishing" and nothing
more. The run's turn count and dollar cost are already captured in
`SPRINTBIAS_RUN_TURNS` and `SPRINTBIAS_RUN_COST`, but nothing reads them. A
person looking at a stopped run cannot tell a cheap 30-turn stop from a $3
runaway, which is what they need to decide whether to raise the turn limit or
narrow the scope.

## Done when (automated)

- [ ] `sprintbias_run_hint` adds the run size to its line when the interpreter
      captured it, e.g. `hit its turn limit before finishing (42 turns, $1.37)`.
      `bash docs/tests/test-run-interpret.sh` asserts the line for a max_turns
      and an error record that carry turns and cost.
- [ ] When turns or cost is empty, the line shows only what is known, and shows
      no brackets when both are empty. `bash docs/tests/test-run-interpret.sh`
      asserts all three cases (both, one, neither) and that no bare
      `( turns, $)` appears.
- [ ] The `## Audit (aborted ...)` note that `polish --code` writes carries a
      `Run size:` line with the same turns and cost. `bash
      docs/tests/test-audit-code.sh` asserts it.
- [ ] `bash docs/tests/run-all.sh` passes.

## Signoff (human)

None: the automated checks cover it.

## Notes

- Put the formatting in `sprintbias_run_hint` (or a small helper beside it in
  `lib.sh`) so every caller prints the same line. Callers today: `deps.sh`,
  `polish-judge.sh`, `promote.sh`, and four sites in `polish.sh`. Each caller
  keeps owning its own verdict wording.
- Read the numbers from the globals the interpreter already sets. One read of
  the run log per run stays the rule.
- `SPRINTBIAS_RUN_SUMMARY` already has readers (`polish.sh`,
  `polish-judge.sh`); it is out of scope.
- Task 374 edits the same aborted-note block in `polish.sh`. Whichever lands
  second adds its line beside the other's.

## References

docs/sprintbias/lib.sh
docs/sprintbias/cli/claude.sh
docs/sprintbias/scripts/polish.sh
docs/sprintbias/scripts/deps.sh
docs/sprintbias/scripts/polish-judge.sh
docs/tasks/review/367-add-a-profile-owned-single-pass-run-interpreter-an.md

<!-- After work only — audit trail of what was touched. Helps committers,
     later audits, and "what broke?" recovery. List the product files you
     edited to complete the task — one repo-relative path per line. Leave this
     task file out: its folder location and git history already track it. Copy
     the two headings below to column 0
     (UNINDENTED — they are indented here only so a fresh, unworked task is not
     mistaken for a finished one), then list the paths under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintbias/scripts/example.sh
       docs/sprintbias/help/example.md

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. Do not fill this before work. -->

<!--
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->
