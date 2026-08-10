# Task 341: Create learn demo for newplan command

**Feature**: none
**Created**: 2026-08-03
**Docs**: none
**Plan**: 18
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 1
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

A newcomer can't *see* what `newplan` does before running it, so the fast lane
of planning stays invisible. `newplan` exists for the moment you already know
which tasks belong together and just want them grouped — one line, no
conversation — as opposed to talking a plan into shape with `chat plan` /
`plan think`. The learning catalog (plan 18) needs one short, watchable vignette
of that felt moment: someone grouping known task IDs into a plan file in a single
command. This is a standalone demo `docs/sprintbias/learning/newplan.py`, per
plan 18's per-command coverage decision (the earlier "fold into the S3 plan
story" argument is superseded by the owner override in plan 18).

## Success criteria

<!-- Observable behaviors that show it's done: "User can [do what]" /
     "App shows [result]". Clear and succinct — anyone can verify. -->

- [x] `./sprint.sh learn newplan` (and `./sprint.sh newplan --demo`) plays a
      self-contained scenario for the `newplan` command.
- [x] The demo is a person-in-a-situation scenario, not a flag tour: a developer
      who has just captured a handful of related tasks (e.g. an auth rework —
      login, session, logout, tests) already sees they belong together, groups
      them with one `./sprint.sh newplan "<name>" <id> <id> ...` line, watches a
      plan file appear grouping them, and is handed to `plan think` for later
      ordering. The felt lesson: **when you already know the grouping, planning
      is one line, not a conversation.**
- [x] Output matches real `newplan` output and the shared vocabulary/look of the
      existing demos (`type_out`, `spinner`, `beat`, `moved`, `ok`/`note`) so it
      reads as the same tool talking as `session.py`.
- [x] Honors the trust contract: writes nothing, no network, Python-3 stdlib
      only; and the standard flags work (`--fast`, `--no-color`, `-h/--help`,
      clean Ctrl-C exiting 130). First non-empty docstring line is a short,
      situational catalog summary shown by `./sprint.sh learn`.
- [x] The `newplan` row in `docs/sprintbias/help/_registry` gains the 5th field
      mapping it to the demo (`newplan → newplan`), so `--demo` plays it and
      `--help` shows the pointer.
- [x] The new demo file and the registry change are mirrored into `src/` via
      `./ship.sh` (a change that lands only in `docs/` never reaches users).

## Notes

- Fastest path: copy the newest per-command demo in
  `docs/sprintbias/learning/` (each demo carries its own copy of the vocabulary
  helpers — there is no shared `_demokit.py` in v1) and rewrite the story.
  `session.py` (S0) is the reference for names, colors, and rhythm.
- Storyboard `newplan` truthfully. It creates a *plan* file (relational index),
  not a task. Its live shape is the fast lane: `newplan "<name>" <task-id...>`
  groups the listed IDs; the `parent:N` variant binds an open parent + its
  children. The scenario leads with the plain task-ID grouping; `parent:N` is at
  most a one-line aside, not the hero beat. Logic lives in
  `docs/sprintbias/scripts/create-plan.sh` — mirror its real success output.
- The demo is theater: it must NOT run `newplan` or write anything; render a
  plausible fake plan filename in the shared output shape.
- Atomic and independent: build against what `newplan` does today, with no
  dependency on other plan-18 tasks. The `--demo` intercept mechanism (#314) is
  the shared prerequisite for the whole plan, not this task's concern.

## References
docs/sprintbias/learning/session.py
docs/sprintbias/learning/feature-plan.py
docs/sprintbias/scripts/create-plan.sh
docs/sprintbias/help/_registry

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

## Refine (round 1)

**Sharpened:** Filled the empty stub into a real brief. Resolved the file's stale
`plan think` "cut / fold into S3" recommendation against plan 18's owner override
(full per-command coverage keeps this demo), then wrote Problem, Success, and
Notes around a confirmed scenario: a developer fast-lane-grouping already-known
task IDs into a plan with one `newplan` line, felt lesson "planning is one line,
not a conversation."
