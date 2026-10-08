# Task 397: Bring project docs in step with landed work

**Feature**: none
**Created**: 2026-10-08
**Docs**: none
**Plan**: none
**From plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Crew**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

Landed work changed what project documents describe, or found gaps in
them (a missing term, a moved source). Each item under ## Follow-ups names
the document, what must change, and the task it came from.

## Success criteria

- [ ] Every item under ## Follow-ups is resolved: the named document states
      the current facts, or the item is struck with a one-line reason.
- [ ] Project-map items are settled with ./sprint.sh profile (profile check is clean).

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

       ### Files changed
       docs/sprintbias/scripts/example.sh
       docs/sprintbias/help/example.md

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

- [ ] `docs/guides/provider-reality.md` — note `agents` reads Claude Code session records; Grok Build support unknown (from #396)
