# Task 340: Create learn demo for newtask command

**Feature**: none
**Created**: 2026-08-03
**Docs**: none
**Plan**: 18
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 2
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

A newcomer meeting SprintBias for the first time hesitates that capturing work
is heavyweight — that `newtask` means a ceremony, a form, a place to file it.
The learning catalog has no way to *show* them otherwise. This task fills that
gap with a short, sandboxed demo of `newtask`: watch a real person capture one
task in a single line and see it land in `backlog/`, so the cost of capture
feels as small as it actually is. Member #340 of Plan 18 (per-command demos).

## Success criteria

<!-- Observable behaviors that show it's done: "User can [do what]" /
     "App shows [result]". Clear and succinct — anyone can verify. -->

- [x] `./sprint.sh learn newtask` (and `./sprint.sh newtask --demo`) plays a
      self-contained scenario for the `newtask` command.
- [x] The demo is a person-in-a-situation scenario, not a flag tour: an
      **interruption capture** — the user is heads-down on a task, a new problem
      surfaces, one `newtask <description>` line lands it in `backlog/`, and they
      return to the original work. The felt lesson is "capture is a reflex that
      doesn't break flow."
- [x] Output matches the shared vocabulary and look of the existing demos
      (`type_out`, `spinner`, `beat`, `prompt_and_type`, `moved`, `ok`/`note`)
      so it reads as the same tool talking as `session.py`.
- [x] Honors the trust contract: writes nothing, no network, Python-3 stdlib
      only; and the standard flags work (`--fast`, `--no-color`, `-h/--help`,
      clean Ctrl-C exiting 130).
- [x] The demo auto-registers: first non-empty docstring line is a short,
      situational catalog summary shown by `./sprint.sh learn`.
- [x] The `newtask` row in `docs/sprintbias/help/_registry` gains the 5th field
      (`… | newtask`) mapping it to the demo, so `--demo` plays it and `--help`
      shows the pointer.
- [x] The new demo file and the registry row are mirrored into `src/` via
      `./ship.sh` (a change that lands only in `docs/` never reaches users).

## Notes

This task is fully actionable now — the demo mechanism it plugs into already
ships. Everything below is verified against the live code in this repo.

### How `newtask` actually works today (storyboard it truthfully)

`./sprint.sh newtask "<description>"` (dispatch: `cmd_newtask` in `sprint.sh`;
logic in `docs/sprintbias/scripts/create-task.sh`) does:
- slugifies the description, allocates the next ID from
  `docs/sprintbias/DOC_STATE.md` (`sprint_TASK_ID`), and copies
  `docs/tasks/.TEMPLATE-task.md` to `docs/tasks/backlog/<ID>-<slug>.md`;
- rejects an empty description, or one with no alphanumeric characters;
- prints, on success (mirror this in the demo so it reads true):

      ✓ DOC_STATE.md updated successfully
      Created task: docs/tasks/backlog/<ID>-<slug>.md

      Next: talk it into shape — ./sprint.sh chat <ID>

The file always lands in `backlog/`; there is no separate mapping or prompt.
The demo is theater — it must NOT run `newtask` or write anything; render a
plausible fake ID/filename in that shared output shape.

### How to wire it (the mechanism is already live — #314 is done)

- Drop a self-contained `docs/sprintbias/learning/newtask.py`. `learn.sh` scans
  `learning/*.py` and auto-lists it — no launcher edit. Its catalog summary is
  the **first non-empty line of the module docstring** (parsed by `_docline`
  in `learn.sh`), so make that line short and situational.
- Map the command by appending the 5th field to its row in
  `docs/sprintbias/help/_registry`. The row is currently:

      newtask       | create   | <description>       | Create a new task

  Change it to end with `| newtask` (see the live `work`/`status` rows for the
  exact shape). That alone makes `./sprint.sh newtask --demo` play it and
  `./sprint.sh newtask --help` print the `Demo:` pointer — both interceptors
  (`sprint.sh` lines ~155-162 and ~481-496) are already shipped.

### Shape and trust (don't reinvent)

- Copy the newest demo, keep its helper block, rewrite the story (README's
  practical path). Good references: `feature-plan.py`, `work.py`. The canonical
  vocabulary lives in `session.py` (`type_out`, `prompt_and_type`, `spinner`,
  `beat`, `act`, `ok`, `moved`, `note`, `nextstep`, `claude`, `you`, `banner`);
  a capture scene won't need every helper.
- Honor the trust contract and standard flags exactly as the README specifies.
- Then `./ship.sh` to mirror `learning/newtask.py` + the registry row into
  `src/` and bump the version (per root CLAUDE.md — never hand-copy to `src/`).

## References

docs/plans/18-per-command-learn-demos.md          — plan + shared build recipe
docs/sprintbias/learning/README.md                — house guide: voice, vocabulary, trust contract
docs/sprintbias/learning/session.py               — canonical helper block to copy
docs/sprintbias/learning/feature-plan.py          — recent demo to copy from
docs/sprintbias/scripts/create-task.sh            — real newtask behavior to storyboard
docs/sprintbias/help/_registry                    — add the 5th field on the newtask row
docs/sprintbias/scripts/learn.sh                  — how demos list/play + auto-registration
sprint.sh                                         — live --demo / --help intercepts

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

**Sharpened:** Promoted Plan 18's shared build recipe into a real Problem and
six verifiable Success criteria, and set the story angle: the demo is an
*interruption capture* scene (problem surfaces mid-flow → one `newtask` line →
back to work), so it earns its runtime instead of being "thin theater."
Reframed the stale plan-think conclusion (which wanted the standalone cut) as a
design constraint, per the plan owner's full-coverage override.

## Refine (round 2)

**Sharpened:** Made the task fully self-contained against the live codebase.
Documented `newtask`'s real behavior and exact success output (so the demo
storyboards truthfully), the current `_registry` row and the one-field edit that
wires it, and confirmed the `--demo`/`--help` intercepts are already shipped
(#314 is done) — so this task has no blocking dependency. Added a `./ship.sh`
mirror criterion and exact References with per-file purpose.

## Think Notes

**Standalone vs. beat — resolved by Plan 18.** An earlier plan-think pass argued
`newtask` is too small for its own demo ("thin theater") and should be folded
into `session.py`'s S0 beat. Plan 18's owner override rejected that in favor of
full per-command coverage, so the standalone `newtask.py` stands. The valid
insight from that pass survives as the design constraint, not a reason to cut:
`newtask` is undramatic run in isolation, so the demo must borrow tension from a
*situation*. The interruption-capture framing (see Success criteria) is that
tension — the scene isn't "create a task," it's "a problem surfaced mid-flow and
capturing it cost nothing."
