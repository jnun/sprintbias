# Task 462: No budget cap by default; a project sets one when it wants a ceiling

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
**Tests**: docs/tests/test-edge-cases.sh
**Refined**: 0
**Reworked**: 0

## Problem

The shipped config capped work at $10, audits at $5 and the breaker at $2, and lib.sh filled an empty value with $5, $3 and $2, so "Empty = no cap" was not true. The goal is finished work; a cap stops agents mid-task and costs the person time.

## Done when (automated)

- [x] The shipped config leaves BUDGET_WORK, BUDGET_AUDIT and BUDGET_BREAK empty, and an empty value means no cap. Proven by `bash docs/tests/test-edge-cases.sh` and `source docs/sprintbias/lib.sh` printing empty budgets
- [x] A value set in config or config.local still caps; `work --max` clears the work and breaker caps for one run. Proven by `bash docs/tests/test-edge-cases.sh`
- [x] help/work.md and DOCUMENTATION.md say there is no cap by default and how to set one (BUDGET_WORK=5.00).

## Signoff (human)



## Notes

- Decided: the breaker's cap no longer depends on BUDGET_WORK being set, because with no default those two are independent; `--max` now clears both.

## References

docs/sprintbias/config
docs/sprintbias/lib.sh
docs/sprintbias/scripts/work.sh
docs/sprintbias/help/work.md
DOCUMENTATION.md

## Completed

**Summary**: Agents now run with no spending cap unless the project sets one, such as BUDGET_WORK=5.00.

Fixed in place during the heavymetal plan 69 crew run (2026-10-12), then filed so the record matches the code.

**Proof**: 2026-10-12 · bash docs/tests/test-edge-cases.sh · pass

### Files changed
docs/sprintbias/config
docs/sprintbias/lib.sh
docs/sprintbias/scripts/work.sh
docs/sprintbias/help/work.md
DOCUMENTATION.md

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
