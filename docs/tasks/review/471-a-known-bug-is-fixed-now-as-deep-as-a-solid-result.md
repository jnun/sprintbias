# Task 471: A known bug is fixed now, as deep as a solid result needs, and teaches the project

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

Workers and the breaker fixed defects in the code they changed but filed defects in any other code path as new backlog tasks, so a known bug could wait in backlog while its task landed. Fix chains had no stated depth, and only defects a person rejected reached the project map's ## Known edges; everything the agents found and fixed was forgotten.

## Done when (automated)

- [x] The test loop tells every worker that a known bug gets fixed now, in the code it changes or any code that reaches, as deep as a solid result needs, including a defect a fix uncovers; only a step a crew lane's single owner runs goes to that owner, and that fix runs now. Proven by `bash docs/tests/test-edge-cases.sh`
- [x] The breaker fixes defects in neighboring code too and files only what it cannot fix after auditing it. Proven by `bash docs/tests/test-edge-cases.sh`
- [x] Workers and the breaker list each real defect under ### Edges found; sign-off (promote) copies each case into the project map's ## Known edges once, one task at a time. Proven by `bash docs/tests/test-edge-cases.sh` (lift twice, one line each)
- [x] At plan close the crew lead routes each suite failure to its builder in that turn and re-runs the suite as many rounds as green takes. Proven by `bash docs/tests/test-crew.sh`
- [x] help/work.md and DOCUMENTATION.md describe fixing known bugs and Edges found.

## Signoff (human)

- [ ] On a real plan, a defect the breaker finds in neighboring code is fixed in the same task, and the case shows up in the project map's ## Known edges after promote.

## Notes

- Decided: no depth cap on fix chains, because the person wants as deep as a solid outcome needs; the ## Known edges prune at ~15 lines (profile check) keeps the map short.
- Decided: edges are lifted at sign-off rather than by each agent, because parallel agents would otherwise edit the map at once.
- Decided: the gate still files a gap it finds in another code path, because the gate shapes work rather than building it.

## References

docs/sprintbias/lib.sh
docs/sprintbias/scripts/promote.sh
docs/sprintbias/scripts/crew.sh
docs/sprintbias/help/work.md
DOCUMENTATION.md
docs/tests/test-edge-cases.sh

## Completed

**Summary**: Agents now fix every known bug they find, as deep as needed, and each fixed case joins the project's Known edges at sign-off so later agents test it.

Fixed in place during the heavymetal plan 69 crew run (2026-10-12), then filed so the record matches the code.

**Proof**: 2026-10-12 · bash docs/tests/test-edge-cases.sh; bash docs/tests/test-crew.sh · pass

### Files changed
docs/sprintbias/lib.sh
docs/sprintbias/scripts/promote.sh
docs/sprintbias/scripts/crew.sh
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
