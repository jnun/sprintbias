# Task 464: Crew keeps what lasts in project files, not agent memory

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

On heavymetal, crew setup closed with "I also updated the crew roster in my memory notes." An agent's memory is private to that session's CLI and machine; other members and other providers never read it, so a roster or call kept there drifts from docs/crew/.

## Done when (automated)

- [x] The crew method says everything the crew needs lives in project files and members read the files, not memory notes. Proven by `bash docs/tests/test-crew.sh`
- [x] Every crew session's rules say anything that must last goes in a task or plan file, never only in a message or the agent's own memory notes. Proven by `bash docs/tests/test-crew.sh`

## Signoff (human)



## Notes

- Decided: stated as where the record lives (project files), not as a ban on memory, because the files being the source of truth is the rule.

## References

docs/sprintbias/ai/crew-setup.md
docs/sprintbias/scripts/crew.sh
docs/tests/test-crew.sh

## Completed

**Summary**: Crew sessions now keep everything that must last in project files rather than their own memory notes.

Fixed in place during the heavymetal plan 69 crew run (2026-10-12), then filed so the record matches the code.

**Proof**: 2026-10-12 · bash docs/tests/test-crew.sh; bash docs/tests/test-finish-rule.sh · pass

### Files changed
docs/sprintbias/ai/crew-setup.md
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
