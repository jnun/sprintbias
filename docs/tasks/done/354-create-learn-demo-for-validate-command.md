# Task 354: Create learn demo for validate command

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

**Stub status:** empty template. Recommendation: the one utility that could earn a demo — if story-framed.

**Perspective check.**
- *Chief Platform Architect:* `validate` is the integrity checker — task IDs, the Depends-on/Dependents graph, help/flag drift. This is the Architect's favorite command: it is *literally* data integrity. And it's read-only, so it sandboxes cleanly. Real, high-value teaching.
- *Chief Experience Officer:* On its face a validator is dry and diagnostic — no delight. A user won't watch a green check parade. But framed as a *near-miss story* — "a broken dependency edge, caught before it bit" — integrity becomes suspense, and that a newcomer will watch.

**Tension and resolution.** Architect strongly wants it; CXO is indifferent to the raw command but sold on a story frame. Resolution: **keep as the single utility-group demo candidate, but only if authored as a person-catches-a-broken-graph vignette**, not a flag tour. This is the one place a "keep" command turns integrity into narrative and both personas win.

**Sharper rewrite (if kept):** *Problem:* users don't trust that a tangled dependency graph will be caught. *Success:* a demo shows `validate` surfacing a dangling `Depends on` edge and pointing at the fix, all read-only; sandbox passes.
