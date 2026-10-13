# Task 465: crew setup builds the project map first when a project has none

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

heavymetal has no project map (`docs/sprintbias/project.md`), so crew setup
worked from CLAUDE.md, agent files and plans, and could not point members at an
**Invariants:** line (#445). Every AI command orients from the map, so a crew
built without one starts each member colder than it needs to.

## Done when (automated)

- [ ] When `docs/sprintbias/project.md` is missing, crew setup builds it first
  (the profile method, deciding what profile would ask), then builds the crew
  from it. Proven by `bash docs/tests/test-crew.sh`
- [ ] Members' Reads first point at the map's **Invariants:** line when the map
  has one. Proven by `bash docs/tests/test-crew.sh`

## Signoff (human)

- [ ] On a project with no map, `./sprint.sh crew setup` leaves a project map
  and a crew whose Reads first names the invariants document.

## Notes

- Decided: crew setup builds the map itself instead of telling the person to
  run profile, because the map is a prerequisite it can produce and asking
  costs the person's time.
- Origin: heavymetal crew setup, 2026-10-12.

## References

docs/sprintbias/ai/crew-setup.md
docs/sprintbias/scripts/profile.sh

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
