# Task 446: crew setup prints usage when given extra arguments

**Feature**: none
**Created**: 2026-10-11
**Docs**: none
**Plan**: 33
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

./sprint.sh crew setup ignores anything typed after setup, so a
mistyped or guessed argument (crew setup plan:5) silently starts an AI session
that never sees it.

## Done when (automated)

- [x] `./sprint.sh crew setup anything` prints usage and exits 1 without
      starting AI. Checked by `bash docs/tests/test-crew.sh`.
- [x] `./sprint.sh crew setup` alone still starts the guided build.

## Signoff (human)



## Notes



## References

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

## Completed

**Summary**: crew setup now prints usage and exits 1 when given extra arguments instead of silently starting an AI session.

**Proof**: 2026-10-11 · bash docs/tests/test-crew.sh · pass

**Breaker**: 7 cases tried · 1 fixed · 0 filed (crew.sh setup --help / -h now print usage and exit 0 instead of exiting 1; empty, two-argument and plan:N arguments still refuse) · $0.34

**Breaker**: 7 cases tried · 0 fixed · 0 filed (second pass: through ./sprint.sh — plan:5, "--", a blank argument exit 1 with usage; help and -h exit 0; bare setup still starts the guided build; added a launcher round-trip test)

**Breaker**: 5 cases tried · 0 fixed · 0 filed (third pass: setup help word form and --help with trailing words exit 0 without a session; --plan and a quoted phrase exit 1; no doc, help page or example promises an argument to crew setup)

### Files changed
docs/sprintbias/scripts/crew.sh
docs/tests/test-crew.sh
