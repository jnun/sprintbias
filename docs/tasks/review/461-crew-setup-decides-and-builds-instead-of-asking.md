# Task 461: crew setup decides and builds instead of asking

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

crew setup asked up to three questions (which lanes run in parallel, who deploys, where each lane runs), proposed a crew and built it only on a yes. Those are agent decisions the project already answers, and asking them spends the person's time.

## Done when (automated)

- [x] crew setup settles each call from what the project shows and records it as a `- Decided:` line in the lead's file; it asks nothing. Proven by `bash docs/tests/test-crew.sh`
- [x] Its opening message is the go-ahead, and it closes with the crew table, its calls (each with the newtask line to change it) and the start commands. Proven by `bash docs/tests/test-crew.sh`
- [x] help/crew.md, help/_registry, the crew guide and DOCUMENTATION.md say it builds the crew. Proven by `./sprint.sh validate --commands`

## Signoff (human)



## Notes

- Decided: defaults are parallel lanes for disjoint files, one deploy owner (ops, or the person when no deploy tooling exists), and each lane on this machine unless it needs another (iOS on a Mac), because those match the recommended crews.

## References

docs/sprintbias/ai/crew-setup.md
docs/sprintbias/scripts/crew.sh
docs/sprintbias/help/crew.md
docs/sprintbias/help/_registry
docs/sprintbias/guides/crew.md
DOCUMENTATION.md
docs/tests/test-crew.sh

## Completed

**Summary**: crew setup now builds the crew without questions, records its calls and closes with the table and start commands.

Fixed in place during the heavymetal plan 69 crew run (2026-10-12), then filed so the record matches the code.

**Proof**: 2026-10-12 · bash docs/tests/test-crew.sh; ./sprint.sh validate --commands · pass

### Files changed
docs/sprintbias/ai/crew-setup.md
docs/sprintbias/scripts/crew.sh
docs/sprintbias/help/crew.md
docs/sprintbias/help/_registry
docs/sprintbias/guides/crew.md
DOCUMENTATION.md
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
