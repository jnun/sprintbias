# Task 459: Crew lead routes by May touch and single-owner steps

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

Orcha queued heavymetal #1798 for api, but #1798 adds a migration and heavymetal's db member is the only one that runs new-migration.sh. The lead routed by wave order without checking each member's May touch.

## Done when (automated)

- [x] The lead's rules say a lane fits when the member's May touch covers what the task changes, and a step only one member may run (a migration, a deploy) sends the task to that member. Proven by `bash docs/tests/test-crew.sh`

## Signoff (human)

- [ ] On heavymetal plan 69, orcha routes #1798 to db on its own.

## Notes



## References

docs/sprintbias/scripts/crew.sh

## Completed

**Summary**: The crew lead routes each task to the member whose May touch covers it, and single-owner steps such as migrations to their owner.

Fixed in place during the heavymetal plan 69 crew run (2026-10-12), then filed so the record matches the code.

**Proof**: 2026-10-12 · bash docs/tests/test-crew.sh · pass

### Files changed
docs/sprintbias/scripts/crew.sh

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
