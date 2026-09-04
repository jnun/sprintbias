# Task 381: Add 'work --resume' consumer for the run journal. The run-level JSONL now written to docs/tmp/run-work-*.jsonl (by work.sh) records the queue plan and every task transition (run/task_started/routed/crashed). Build the consumer that reads the newest journal, reconstructs plan + position, and continues an interrupted run: re-queue tasks that were task_started but never routed, skip those already routed to review/done, and resume a crashed task in place (it stays in doing/). Wire it as './sprint.sh work --resume'. Include the journal-format contract in the help/registry surfaces. Origin: 2026-09-03 real-world failure hardening (see docs/guides/provider-reality.md Surfaced unknowns 2026-09-03); the journal-writing half shipped, this is the read half.

**Feature**: none
**Created**: 2026-09-03
**Docs**: none
**Plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

<!-- sb:hint  Clear, simple language. Concisely define the problem at a high
     level — who is stuck, what is wrong, why it matters. 2–5 short sentences.
     User-story height — not a build plan. -->



## Success criteria

<!-- sb:hint  What done looks like. When these are met, the task is done.
     Observable checks anyone can verify. For a library or detailed technical
     fix, state the new technical needs as outcomes — still not a step outline. -->

- [ ]
- [ ]
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

       ### Files changed
       docs/sprintbias/scripts/example.sh
       docs/sprintbias/help/example.md

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. Do not fill this before work. -->

<!-- sb:hint
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->
