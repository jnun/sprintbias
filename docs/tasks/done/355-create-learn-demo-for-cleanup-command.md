# Task 355: Create learn demo for cleanup command

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

**Stub status:** empty template. Recommendation: cut.

**Perspective check.**
- *Chief Platform Architect:* `cleanup` **deletes** stale scratch files — a destructive, real side effect. The demos' trust contract forbids writes/deletes, so a demo must fake the deletion. Faking a destructive command as safe theater is the highest-risk misrepresentation in the plan: a user could infer `cleanup` is gentler than it is.
- *Chief Experience Officer:* Housekeeping has no narrative and no first-run value. Nobody's onboarding hinges on watching files get swept, and "watch me delete things" is the opposite of a trust-building first impression.

**Tension and resolution.** Both agree, for different reasons — Architect on misrepresentation risk, CXO on zero story. Resolution: **cut.** Cover `cleanup`'s `--dry-run`/`--delete` semantics in `--help`, where the real (destructive) behavior is stated plainly rather than simulated.

## Audit

- **Steps run**: 1 (1 fixer + 0 verifier)
- **Final verdict**: PASS
- **Final mode**: fixer
- **Date**: 2026-08-05
- **Files audited**: 284
- **Context source**: git working tree diff
- **Build checks**: Python ast.parse: PASS (14/14 files)
