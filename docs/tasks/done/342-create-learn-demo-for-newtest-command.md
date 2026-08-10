# Task 342: Create learn demo for newtest command

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

A newcomer scanning the learn catalog has no scenario for `newtest`, and the
integrity idea it carries — *work isn't done until it's proven* — is invisible.
`newtest` is a thin template stamp, so read cold it looks like the least
interesting command in the create group. A short vignette makes its value land:
right after a deploy, you capture a claim you can prove, and that test loop is
what gates `promote`. This is plan 18's per-command coverage, one member.

## Success criteria

<!-- Observable behaviors that show it's done: "User can [do what]" /
     "App shows [result]". Clear and succinct — anyone can verify. -->

- [x] `docs/sprintbias/learning/newtest.py` exists: a self-contained, scripted
      vignette (~40-60s) set in the moment right after a deploy. The spine is
      `./sprint.sh newtest "Signup converts cold visitors"` → the stamped test
      loop appears (claim / how-we'll-test / what-counts-as-success) → one
      closing beat *names* the payoff: this loop is what gates `promote`, and
      the task can't reach `done/` until this test passes.
- [x] It teaches the Tests→promote gate by naming it only — it does not replay
      the promote flow (that drama belongs to the promote demo, #347). Its own
      distinct situation is "capturing a claim you can prove."
- [x] It is a person-in-a-situation scenario, not a flag tour, and matches real
      `newtest` output and the shared output vocabulary (`type_out`, `spinner`,
      `beat`, `moved`, `claude`/`you`, `ok`/`note`/`held`) so it reads as the
      same tool talking.
- [x] It honors the trust contract — writes nothing, no network, Python 3
      stdlib only — and states that promise in its banner.
- [x] It honors the standard flags: `--fast` (no delays), `--no-color`
      (auto-dropped on non-TTY), `-h`/`--help` (prints docstring, exit 0), clean
      Ctrl-C (dim `…demo interrupted.`, exit 130). First docstring line is the
      short situational catalog summary.
- [x] `./sprint.sh learn` lists the demo and `./sprint.sh learn newtest` plays
      it (auto-registered from the docstring). The 5th field on the `newtest`
      row in `docs/sprintbias/help/_registry` maps `newtest → newtest`.
- [x] The learning sandbox check passes for the new demo (runs clean under
      `--fast`, no writes, no network).

## Notes

<!-- Every relevant detail that helps build the solution fast and knowingly:
     decisions, constraints, edge cases, gotchas. Leave empty if none. -->

- Fastest path: copy the newest demo in `learning/`, keep its helper block
  (each demo carries its own copy of the vocabulary helpers — there is no shared
  `_demokit.py` in v1), and rewrite the story. `session.py` is the reference for
  names, colors, and rhythm.
- `newtest` is a pure template stamp: `create-test.sh` copies
  `docs/tests/.TEMPLATE-test.md` into `docs/tests/` and requires a claim
  argument. There is no AI Q&A path (unlike `newidea`), so the spine is the
  stamp-and-payoff arc above, not a dramatized session. Storyboard the stamped
  file against the real template sections (What we're testing / How we'll test
  it / What counts as success).
- Overlap guard with the promote demo (#347): name the gate, don't play it.
  This demo's situation is capturing a provable claim; #347 owns the gate
  in action.
- Atomic and independent: build against what `newtest` does *today*, with no
  dependency on other plan-18 tasks. The demo file plus its registry mapping are
  complete on their own; `./sprint.sh learn newtest` plays it.

## References

<!-- Direct files that help build this — existing code to reuse (don't
     reinvent), specs, examples. One path per line. Leave empty if none. -->

docs/sprintbias/learning/README.md
docs/sprintbias/learning/session.py
docs/sprintbias/scripts/create-test.sh
docs/tests/.TEMPLATE-test.md
docs/sprintbias/help/_registry
docs/sprintbias/help/newtest.md
docs/plans/18-per-command-learn-demos.md

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

**Resolution (2026-08-10):** Problem and Success criteria are now defined — this
is a standalone `learning/newtest.py`. The "fold the Tests-gate lesson into the
spine/promote story" argument below is **superseded** by plan 18's owner
decision (full per-command coverage), the same call made for sibling #338. Kept
as history; the drama it worried about is handled by naming the gate here and
leaving the gate-in-action to the promote demo (#347).

**Perspective check.**
- *Chief Platform Architect:* This one the Architect actually wants. `newtest` creates the test loops that gate `promote` (Tests green → `done/`). It's a real data-integrity concept: work isn't done until it's proven. Teaching the Tests→promote contract raises the reliability floor of every install.
- *Chief Experience Officer:* Watching a test loop get authored is dry — there's no user delight in "I wrote a verification." The concept matters but the raw command is the least cinematic thing in the create group.

**Tension and resolution.** Architect prizes the integrity lesson; CXO fears a boring demo. They meet in the middle: teach the *concept* where it has stakes and drama — inside the close-the-loop story (`work.py`/`promote`), where a task can't reach `done/` until its Tests pass. Resolution: **keep the Tests-gate lesson, but as a beat in the spine/close story, not a standalone `newtest` demo.**

**Sharper rewrite (only if kept):** *Problem:* users promote work that was never proven. *Success:* the close-the-loop demo shows a task with a failing Test held out of `done/`, then passing and closing — `newtest` named as the origin of that gate.

## Refine (round 1)

**Sharpened:** Filled Problem and Success from an empty stub — locked this as a
standalone `learning/newtest.py` (superseding the fold-into-promote argument per
plan 18, matching sibling #338). Set the spine to the post-deploy stamp-and-
payoff arc, and drew the overlap line with the promote demo (#347): name the
Tests→promote gate here, play it there. Recorded that `newtest` is a pure
template stamp with no AI Q&A path.
