# Task 474: Tasks a crew files during a plan carry --from-plan

**Feature**: none
**Created**: 2026-10-12
**Docs**: none
**Plan**: 35
**From plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-crew.sh
**Refined**: 0
**Reworked**: 0

## Problem

During heavymetal plan 69 the crew filed #1810, #1816, #1821, #1823 and #1824 with **Plan**: none and **From plan**: none. plan done lists a plan's follow-ups by **From plan**, so these would never be named when plan 69 retires and could drift out of sight.

## Done when (automated)

- [x] The crew rules tell every member and the lead to file a task found while working a plan as `./sprint.sh newtask "<the task>" --from-plan <id>`, so plan done lists it. Proven by `bash docs/tests/test-crew.sh`

## Signoff (human)



## Notes

- Decided: --from-plan, not --plan membership, because a found task is a follow-up the plan's goal does not need; the lead adds it as a member when it does.
- Heavymetal's five orphans can be linked by hand (set **From plan**: 69) or folded with ./sprint.sh newplan "Plan 69 follow-ups" 1810 1816 1821 1823 1824.

## References

docs/sprintbias/scripts/crew.sh
docs/tests/test-crew.sh

## Completed

**Summary**: Tasks a crew files while working a plan now carry --from-plan, so plan done lists them as follow-ups.

Fixed in place during the heavymetal plan 69 crew run (2026-10-12), then filed so the record matches the code.

**Proof**: 2026-10-12 · bash docs/tests/test-crew.sh · pass

### Files changed
docs/sprintbias/scripts/crew.sh
docs/tests/test-crew.sh

<!-- sb:hint  After work only — audit trail of what was touched. Helps committers,
     later audits, and "what broke?" recovery. List the product files you
     edited to complete the task — one repo-relative path per line. Leave this
     task file out: its folder location and git history already track it. Copy
     the two headings below to column 0
     (UNINDENTED — they are indented here only so a fresh, unworked task is not
     mistaken for a finished one), then list the paths under "Files changed":

       ## Completed

       **Summary**: <one plain sentence: what changed, for someone reading
       the project's history>

       ### Files changed
       docs/sprintbias/scripts/example.sh
       docs/sprintbias/help/example.md

     When the work rests on something only a person can confirm (a device,
     a live account), add under ## Completed; it joins the plan's human test:

       ### Assumptions
       - The scanner sends one line per barcode

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
