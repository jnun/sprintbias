# Task 472: Every worker follows one six-step loop: build, test, adjust, resolve, fix, submit

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
**Tests**: docs/tests/test-proof-loop.sh
**Refined**: 0
**Reworked**: 0

## Problem

The test loop every worker and crew member receives was a list of rules in no stated order, so an agent decided for itself when to test, when to fix and when to land. The person's settled order of work is: build what was defined, test what was built, adjust what fails, resolve known conflicts, fix all bugs, submit for review. Stating it once, in that order, is the fastest path and leaves nothing to re-decide.

## Done when (automated)

- [x] sprintbias_proof_rule states the loop as six numbered steps in that order, each carrying its existing rule (smallest outcome first; targeted tests and one assertion per case; Test log and audit the test first; resolve conflicts by best practice and record each; fix every known bug as deep as needed with ### Edges found; Summary and Proof line), within the 19-line budget. Proven by `bash docs/tests/test-proof-loop.sh`
- [x] work, crew and the breaker prompts still carry the loop (Test loop: header). Proven by `bash docs/tests/test-edge-cases.sh`, `bash docs/tests/test-finish-rule.sh`, `bash docs/tests/test-fast.sh`
- [x] help/work.md and DOCUMENTATION.md name the six steps.

## Signoff (human)



## Notes

- Decided: step 4 names the conflicts an agent meets mid-task (the docs, a - Decided: line, a task in doing/), because those are the ones a worker can resolve; plan-level conflicts stay with plan think and the gate.
- Decided: the loop is a strict order rather than a guideline, because a fixed protocol saves the thinking an agent spends choosing one.

## References

docs/sprintbias/lib.sh
docs/sprintbias/help/work.md
DOCUMENTATION.md
docs/tests/test-edge-cases.sh

## Completed

**Summary**: Every worker now follows one six-step loop in order: build what was defined, test what was built, adjust what fails, resolve known conflicts, fix all bugs, submit for review.

Fixed in place during the heavymetal plan 69 crew run (2026-10-12), then filed so the record matches the code.

**Proof**: 2026-10-12 · bash docs/tests/test-proof-loop.sh; bash docs/tests/test-edge-cases.sh; bash docs/tests/test-finish-rule.sh; bash docs/tests/test-fast.sh · pass

### Files changed
docs/sprintbias/lib.sh
docs/sprintbias/help/work.md
DOCUMENTATION.md
docs/tests/test-edge-cases.sh

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
