# Task 463: agents crashes with no flags on macOS bash

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
**Tests**: docs/tests/test-agents.sh
**Refined**: 0
**Reworked**: 0

## Problem

`./sprint.sh agents` with no flags failed on heavymetal with `agents.sh: line 52: args[@]: unbound variable`. macOS ships bash 3.2, which treats an empty array as unset under `set -u`, so the command a crew uses to see live sessions (and to judge a stalled holder before a takeover) did not run.

## Done when (automated)

- [x] `agents.sh` passes its flags as `${args[@]+"${args[@]}"}`, and a bare run under /bin/bash 3.2 prints no unbound-variable error. Proven by `bash docs/tests/test-agents.sh`

## Signoff (human)



## Notes



## References

docs/sprintbias/scripts/agents.sh
docs/tests/test-agents.sh

## Completed

**Summary**: `./sprint.sh agents` with no flags runs again on macOS's bash 3.2.

Fixed in place during the heavymetal plan 69 crew run (2026-10-12), then filed so the record matches the code.

**Proof**: 2026-10-12 · bash docs/tests/test-agents.sh · pass

### Files changed
docs/sprintbias/scripts/agents.sh
docs/tests/test-agents.sh

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
