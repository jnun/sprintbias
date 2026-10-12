# Task 447: Bring project docs in step with landed work

**Feature**: none
**Created**: 2026-10-11
**Docs**: none
**Plan**: none
**From plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

Landed work changed what project documents describe, or found gaps in
them (a missing term, a moved source). Each item under ## Follow-ups names
the document, what must change, and the task it came from.

## Done when (automated)

- [ ] Every item under ## Follow-ups is resolved: the named document states
      the current facts, or the item is struck with a one-line reason.
- [ ] Project-map items are settled: `./sprint.sh profile check` is clean.

## Signoff (human)

<!-- sb:hint  What only a person can judge: user stories to try, screens to
     look at, real hardware to try. Never holds the work: in a plan these
     gather into one human test, run at the end. Leave empty when a machine
     proves everything. -->

- [ ]

## Notes

<!-- sb:hint  Optional helpful hints that assist the developer: constraints, edge
     cases, gotchas. Guidance from answered questions also lives here when it
     shapes how (and is not already a success criterion). Leave empty if none. -->

## References

<!-- sb:hint  Direct paths to docs or files known to be related. One path per
     line. Leave empty if none. -->

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

<!-- sb:doc-followups -->
## Follow-ups

- [ ] Fixed: a plan file with no `# ` heading made `plan done` exit 1 silently (pipefail on the title grep); it now retires titled "Plan N". (from #421)
- [ ] Fixed: a `**Summary**:` line was cut at its first ". " (e.g. "e.g.") and lost its wrapped second line, the shape the task template shows; the Summary is now taken whole and joined, and only the prose fallback is cut to one sentence (`sprintbias_task_summary`, shared with `history record`). (from #421)
- [ ] Fixed: CRLF plan and task files lost the member summary and put carriage returns in titles and sections; both now read like LF files. (from #421)
- [ ] Fixed: a plan that was `git add`ed but never committed was left as `AD` in the index (git rm refused, rm fallback did not stage); `git rm -f` now stages the removal, since the record already holds the plan. (from #421)
- [ ] Held up: run twice (second run finds no plan, record unchanged, no temp files), `%` and backslashes in titles/goal/summary, refusal, write failure, follow-ups, history neighbors (`test-history.sh`). (from #421)
