# Task 339: Create learn demo for newfeature command

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
- *Chief Platform Architect:* The feature→tasks fan-out is already the S3 story (`feature-plan.py`) and is actively being built by #324. A separate `newfeature` demo duplicates a demo the catalog already ships and is a maintenance liability (two files telling one story drift apart).
- *Chief Experience Officer:* "A big idea becomes structured, plannable work" is a genuinely compelling arc — but it's compelling *because S3 already tells it well*. A second telling doesn't add clarity; it adds a second thing to choose between.

**Tension and resolution.** No real disagreement here — both personas land on cut. The `newfeature` moment is the front half of the existing feature→plan story; showcase it there. Resolution: **merge into `feature-plan.py` / #324, drop the standalone demo.**

**Sharper rewrite (only if kept):** *Problem:* users don't see how a raw feature turns into ordered tasks. *Success:* the S3 demo's opening explicitly shows `newfeature` as the entry point — no separate file, no second registry mapping.
