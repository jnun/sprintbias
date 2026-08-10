# Task 346: Create learn demo for polish command

**Feature**: none
**Created**: 2026-08-03
**Docs**: none
**Plan**: 18
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

<!-- Plan: which docs/plans/N-… this belongs to (membership reverse index).
     Depends on: task IDs that must finish first.
     Dependents: reverse edge — task IDs that wait on this one.
     Parent: task-to-task grouping only (not Plan).
     Docs: guide to read while building.
     Tests: docs/tests/*.sh that prove success criteria for `promote`
     (all must pass → review/ to done/). Product newtest loops are not Tests.
     Legacy aliases (read only): Dependents←Blocks, Tests←Proven by.
     Write only the canonical names. -->

## Problem

<!-- The problem as a short user story — who, what they can't do, why it
     matters. Loose Gherkin (Given/When/Then) is welcome, not required.
     2-5 sentences, plain English. -->



## Success criteria

<!-- Observable behaviors that show it's done: "User can [do what]" /
     "App shows [result]". Clear and succinct — anyone can verify. -->

- [x]
- [x]
- [x]

## Notes

<!-- Every relevant detail that helps build the solution fast and knowingly:
     decisions, constraints, edge cases, gotchas. Leave empty if none. -->

## References

<!-- Direct files that help build this — existing code to reuse (don't
     reinvent), specs, examples. One path per line. Leave empty if none. -->

<!-- When this task is finished, leave an audit trail of what it touched.
     Reviews and the change manifest read this. Copy the two headings
     below to column 0 (UNINDENTED — they are indented here only so a fresh,
     unworked task is not mistaken for a finished one), then list one
     repo-relative path per line under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintbias/scripts/example.sh
       docs/tasks/.TEMPLATE-task.md

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. -->

<!--
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->

## Plan Think

**Stub status:** empty template. Sharper draft proposed at end.

**Perspective check.**
- *Chief Platform Architect:* `polish` is subtle and powerful — a quality sweep of `review/`, deep-judging a file, or `--code` auditing, and it can reopen completed work. That "reopen done work" behavior has real state implications, so a demo would need to be careful not to imply it's routine.
- *Chief Experience Officer:* This is an advanced, later-in-the-journey concept. A beginner watching a review-quality sweep has no context for why it matters yet. It doesn't reduce first-run friction; it presumes a mature board.

**Tension and resolution.** Both place `polish` past the onboarding horizon. Resolution: **defer** behind the core curriculum. If it ever ships, the story should be "work looked done, a polish pass caught the rot" — a quality-safety-net vignette, not a flag tour of its three modes.

**Sharper rewrite (if ever built):** *Problem:* teams ship `review/` work without a second-look pass. *Success:* a demo shows `polish` catching a weak item in `review/` before it closes.
