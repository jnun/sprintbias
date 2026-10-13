# Task 469: Crew members prove a task with targeted tests; the full suite runs once at plan close

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

On heavymetal plan 69, each iOS task's proof ran the whole iOS simulator suite (994 to 1011 tests) plus a build, and parallel waves pushed the machine's load to 13 on 10 cores. The iOS tasks run in a chain (1801, 1803, 1802, 1804), so every full-suite run sat on the plan's critical path. work already proves with targeted tests; the crew rules never said so.

## Done when (automated)

- [x] The crew rules tell every member (and every member subagent the lead starts) to prove a task with the targeted tests for what it changes, and that the full suite runs once at plan close. Proven by `bash docs/tests/test-crew.sh`

## Signoff (human)

- [ ] On the next crew plan with iOS work, each iOS task's proof line names filtered sim tests, and the full suite runs once at close.

## Notes

- Decided: targeted tests per task and one full run at close, because that is work's rule already and the plan-close suite catches cross-task breaks.
- Measured on plan 69 (2026-10-12): gate 14:49; wave 1 landed 14:54 to 14:58; 1800 at 15:04; 1798 at 15:30; 1801 at 15:48; 1803 at 15:57; 1802 still building at 16:15.

## References

docs/sprintbias/scripts/crew.sh
docs/tests/test-crew.sh

## Completed

**Summary**: Crew members now prove each task with targeted tests and leave the full suite to one run at plan close, which shortens the critical path.

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
