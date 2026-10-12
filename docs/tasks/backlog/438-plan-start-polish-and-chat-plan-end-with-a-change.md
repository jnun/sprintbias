# Task 438: plan start, polish and chat plan end with a change report (sprintbias_change_snapshot) instead of git diff advice

**Feature**: none
**Created**: 2026-10-10
**Docs**: none
**Plan**: 34
**From plan**: none
**Depends on**: 452
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-change-report.sh
**Refined**: 0
**Reworked**: 0

## Problem

`plan think` ends with a Changes report (every file it created, edited or
moved, with `+N −M` and a one-line summary), and that report is what lets the
person trust a pass without reading every file. `plan start`, `plan polish` and
`chat plan` change plan and task files too but end without one, so the person
has to diff by hand to see what moved.

## Done when (automated)

- [ ] `plan start`, `plan polish` and `chat plan` each end with the same Changes
  report `plan think` prints (one shared helper, not three copies), kept in
  `docs/tmp/<command>-<id>-changes.md`. Proven by
  `bash docs/tests/test-change-report.sh`
- [ ] The report opens with the run's Consequences (#452) before the file list,
  and its last line names the next command. Proven by
  `bash docs/tests/test-change-report.sh`
- [ ] A run that changed nothing prints one line saying so. Proven by
  `bash docs/tests/test-change-report.sh`
- [ ] Help for `plan` and `chat` names the report; `./sprint.sh validate --docs`
  passes.

## Signoff (human)

## Notes

- Decided: reuse plan think's before/after snapshot of `docs/tasks/` and
  `docs/plans/` as the shared helper, because it already works and one report
  shape reads the same everywhere.

## References

docs/sprintbias/scripts/plan-think.sh (Changes report)
docs/sprintbias/scripts/plan-start.sh
docs/sprintbias/scripts/plan-polish.sh
docs/sprintbias/scripts/chat-plan.sh

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
