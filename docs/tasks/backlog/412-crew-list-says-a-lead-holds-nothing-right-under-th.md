# Task 412: Crew list says a lead holds nothing right under the plan it leads

**Feature**: none
**Created**: 2026-10-08
**Docs**: none
**Plan**: none
**From plan**: 29
**Depends on**: none
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-crew.sh
**Refined**: 1
**Reworked**: 0

## Problem

`./sprint.sh crew` prints a lead's `leads plan N: ...` line and then `holds
nothing` right under it. A lead holds its plan, so the two lines contradict
each other and a reader cannot tell whether the lead is busy. Found while
running plan 29 with a crew.

## Done when (automated)

- [ ] A lead with an assigned plan shows its `leads plan N: ...` line plus any
      tasks it holds, and no `holds nothing` line. `bash
      docs/tests/test-crew.sh` asserts the lead's list block lacks `holds
      nothing`.
- [ ] A lead with no plan and no tasks, and a member with no tasks, still show
      `holds nothing`. `bash docs/tests/test-crew.sh` asserts both.
- [ ] `bash docs/tests/run-all.sh` passes.

## Signoff (human)

None: the automated checks cover it.

## Notes

- `cmd_list` in `crew.sh` sets `held` only from the tasks loop, then prints
  `holds nothing` when `held` is empty. Treat a printed `leads plan` line as
  holding something.
- `test-crew.sh` already puts lead `orcha` on plan 5 (Tests 6/6a) and asserts
  the `leads plan 5` line. Add the missing negative check beside it.

## References

docs/sprintbias/scripts/crew.sh (cmd_list)
docs/tests/test-crew.sh


<!-- sb:hint  After work only — audit trail of what was touched. Helps committers,
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

     When the work made a source of truth wrong and updating it is out of
     scope (or it is a governing source), add under ## Completed:

       ### Doc follow-ups
       - `docs/GLOSSARY.md` — add "plan"; the code now uses it

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. Do not fill this before work. -->

<!-- sb:hint
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->
