# Task 347: Create learn demo for promote command

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
- *Chief Platform Architect:* `promote` is *the* data-integrity gate — run each `review/` task's Tests, all green → `done/`. This is the concept the Architect most wants users to internalize: nothing closes unproven. High teaching value. But the registry already maps `promote → work`, so the spine demo is meant to carry it.
- *Chief Experience Officer:* "It's really, verifiably done" is a satisfying payoff beat. Users feel trust when they see the gate refuse to close a failing task. That beat belongs at the *end of the spine story*, where it lands emotionally, not in a standalone utility demo.

**Tension and resolution.** They converge: the promote payoff is the closing beat of the work/spine story it's already mapped to (`work.py`). A separate `promote` demo would duplicate that mapping and split the spine's climax across two files. Resolution: **fold the Tests-green→`done/` payoff into the spine/close story; drop the standalone `promote` demo** (and pair it with #342's Tests-gate lesson).

**Sharper rewrite (only if kept):** *Problem:* users don't see that closing is test-gated. *Success:* the spine demo ends on `promote` holding a red-Test task in `review/` and moving a green one to `done/`.
