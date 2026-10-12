# Task 458: Crew sessions start working when they open

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
**Tests**: docs/tests/test-finish-rule.sh
**Refined**: 0
**Reworked**: 0

## Problem

`crew orcha plan:69` described its first step (run plan start, write the board, route wave 1) and stopped, waiting for a go-ahead the person never meant to give. The opening message asked for a description: "tell me in two or three lines who you are and what you will do first."

## Done when (automated)

- [x] The opening message to every crew member and lead says to name itself in one or two lines and start now, and that the message is the go-ahead. Proven by `bash docs/tests/test-finish-rule.sh` (crew lead, crew member)

## Signoff (human)

- [ ] `./sprint.sh crew orcha plan:69` on a READY plan runs plan start and routes wave 1 with no prompt from you.

## Notes

- Decided: the lead's existing "Run ./sprint.sh plan start first" line stays; only the opening message changed, because that was what ended the turn.

## References

docs/sprintbias/scripts/crew.sh
docs/tests/test-finish-rule.sh

## Completed

**Summary**: Crew sessions now start working the moment they open instead of describing their first step and waiting.

Fixed in place during the heavymetal plan 69 crew run (2026-10-12), then filed so the record matches the code.

**Proof**: 2026-10-12 · bash docs/tests/test-finish-rule.sh; bash docs/tests/test-crew.sh · pass

### Files changed
docs/sprintbias/scripts/crew.sh
docs/tests/test-finish-rule.sh

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
