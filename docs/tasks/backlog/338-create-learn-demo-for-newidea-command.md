# Task 338: Create learn demo for newidea command

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

A newcomer with a half-formed idea that solves a real problem has no way to
*see* what `newidea` does before running it, so capture feels risky and the
command's value is invisible. The learning catalog (plan 18) needs one short,
watchable vignette — safe theater — of a person turning a fuzzy thought into a
captured, named idea file with `newidea`, touching nothing in their project.
This is a standalone demo `docs/sprintbias/learning/newidea.py`, per plan 18's
per-command coverage decision (the earlier "fold into session.py" argument is
superseded).



## Success criteria

<!-- Observable behaviors that show it's done: "User can [do what]" /
     "App shows [result]". Clear and succinct — anyone can verify. -->

- [ ]
- [ ]
- [ ]

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

**Stub status:** empty template — no Problem, no Success criteria, `**Plan**: none`. Too vague to annotate as written; a sharper draft is proposed at the end.

**Perspective check.**
- *Chief Platform Architect:* `newidea` is a thin creator with almost no data-integrity surface, so a demo is cheap and safe. The concern is duplication — `session.py` (S0) already opens on capture, and shipping a second capture demo splits the "one voice, one look" the learning README exists to protect.
- *Chief Experience Officer:* This is the single most emotionally important on-ramp — "I have a fuzzy thought" becoming something the system holds. Enormous first-touch value, *if* it is a person-with-an-idea vignette rather than a flag tour of `[name]` vs no-name Q&A.

**Tension and resolution.** Architect sees redundancy with S0; CXO sees the highest-value onboarding moment. They resolve the same way: `newidea` is a *beat inside the capture story*, not a standalone command demo. Fold it into `session.py`'s opening rather than mint a 10th near-identical file. If it must stand alone, it has to earn a distinct situation the curriculum doesn't already show.

**Sharper rewrite (only if kept):** *Problem:* a brand-new user with a half-formed idea doesn't trust that capturing it is safe or worthwhile. *Success:* `./sprint.sh newidea --demo` plays a <60s vignette of an idea being captured and named, touching nothing; registry 5th field maps `newidea → <demo>`; `learn-sandbox.sh` passes.
