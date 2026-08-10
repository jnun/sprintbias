# Task 344: Create learn demo for loop command

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

`loop` is SprintBias's autopilot — it refills the sprint (`plan start`, gating
as it commits) and drains `work`, all unattended. It's the command a new user is
most afraid to trust, because it acts when no human is watching. Yet the learning
catalog has no demo for it, and loop's registry row has no `--demo` mapping, so a
newcomer can't *watch* it run safely before believing it. Nothing in the catalog
today shows the gate still holding mid-autopilot — loop's whole reason to exist.

## Success criteria

<!-- Observable behaviors that show it's done: "User can [do what]" /
     "App shows [result]". Clear and succinct — anyone can verify. -->

- [x] A new demo file `docs/sprintbias/learning/loop.py` exists and follows the
      house guide (first docstring line = catalog summary; no deps; stdlib only).
- [x] `./sprint.sh learn` lists it automatically; `./sprint.sh learn loop` plays it.
- [x] The demo is pure theater — it writes/moves no files, runs no network, and
      touches nothing in the user's project.
- [x] The story shows **unattended** autopilot: refill (plan start gating as it
      commits) then work drain, running with no human at the keyboard — and a
      not-ready task gets gated out mid-run so the viewer sees the gate hold.
- [x] `loop`'s row in `docs/sprintbias/help/_registry` gains its optional 5th
      pipe field `| loop` (the demo-name), so `./sprint.sh loop --demo` plays the
      new demo and `loop --help` shows the auto-generated "Demo:" pointer.
- [x] Change is shipped: `./ship.sh` mirrors `learning/loop.py` and the registry
      edit into `src/` and bumps the version (the demo is distributable code).
- [x] The demo honors the house flags: `--fast`, `--no-color`, `-h/--help`
      (matching the sibling demos).
- [x] `speedrun.py` (S6) is left unchanged — its human-driven momentum beat stays.
- [x] The curriculum map in `docs/sprintbias/learning/README.md` gains loop's row.
- [x] `./sprint.sh validate --commands` and `--docs` stay green (registry, help,
      and manual remain in sync after the demo map is added).

## Notes

**The distinguishing beat vs `speedrun.py`.** speedrun sells *speed* of one
human-driven task; loop sells *trust in unattended automation*. Don't merge them
— the earlier Plan Think proposed retargeting speedrun, but speedrun never shows
the `loop` command or the no-human-watching safety promise, so a fresh demo is
warranted. In the curriculum this is loop's "automate" beat (README's story
arc is capture → convert → plan → automate). Match the voice, palette, and flag
handling of the existing demos — mirror `work.py`/`gate.py` for the skeleton.

**How `loop` actually works today** (source: `docs/sprintbias/scripts/loop.sh`)
— the demo should narrate this faithfully, as theater, not run it:
- On start it recovers any task stranded in `doing/` from an interrupted run
  (moves it back to `next/`), prints a banner with queue counts, then iterates.
- Each iteration works the lowest-id task in `next/` by shelling `work count 1`
  (one task, fresh context) → the task lands in `review/` on success.
- `--refill`: when `next/` empties, it runs `plan start` on the lowest-id
  **READY** plan in `docs/plans/`. `plan start` **gates each member as it commits
  it** into `next/` — this is the "gate holds while nobody watches" moment.
- `--retry`: when `next/` empties, it re-gates (not raw-promotes) tasks that
  landed in `blocked/` *during this run*, once — still must pass workability.
- A task the runner can't work leaves `next/` untouched; when nothing moves,
  loop stops with "none are ready to execute" rather than spinning. Any task
  left in `doing/` after an iteration is swept to `blocked/` (needs a decision).
- Limits: `--hours N`, `--max N` (task count), `--cooldown N`; extra flags pass
  through to `work` (e.g. `--fast`, `--force`, `--audit`).

The trust beat to dramatize: a not-ready task hits the refill/gate boundary and
is held out of `next/` (or bounced to `blocked/`) while the loop keeps draining
the ready ones — no human at the keyboard, and nothing unready slips through.

**How demos register** (source: `docs/sprintbias/scripts/learn.sh`) — there is
no manifest and no launcher edit. `learn.sh` resolves `learn <name>` to
`learning/<name>.py`; the no-arg catalog scans `learning/*.py` and uses each
module's **first non-empty docstring line** as its summary. So naming the file
`loop.py` is what makes `./sprint.sh learn loop` play it and lists it in
`./sprint.sh learn`. Stdlib-only Python 3, no packages.

**How `loop --demo` maps** (source: `docs/sprintbias/help/_registry`, header
comment) — `--demo` is a global dispatcher intercept (`sprint.sh`), not parsed
by `loop.sh`. It reads the registry row's **optional 5th pipe field** =
`demo-name`. loop's row currently has four fields; add `| loop` as the fifth:

    loop  | work | [--refill] [--retry]| Autopilot spine … work drain | loop

That one edit makes `./sprint.sh loop --demo` play `learning/loop.py` and adds a
"Demo:" pointer to `loop --help` automatically. Do not invent a second
command→demo mapping scheme.

**After editing (this is distributable code).** `learning/` ships under
`docs/sprintbias/`, so finish with the repo flow: edit in `docs/`, play it in
place (`./sprint.sh learn loop`, `./sprint.sh loop --demo`), then run `./ship.sh`
to mirror into `src/` and bump the version. Verify catalog/help/manual stay in
sync with `./sprint.sh validate --commands` and `--docs`.

## References

docs/sprintbias/learning/README.md            — house guide: voice, flat layout, auto-registration
docs/sprintbias/learning/work.py              — closest skeleton to mirror (docstring, flags, palette, timing helpers)
docs/sprintbias/learning/gate.py              — reference for dramatizing the gate holding
docs/sprintbias/learning/speedrun.py          — the S6 momentum demo to leave unchanged (and stay distinct from)
docs/sprintbias/scripts/loop.sh               — the real command this demo narrates
docs/sprintbias/scripts/learn.sh              — how a demo name resolves and auto-registers
docs/sprintbias/help/_registry                — add the 5th demo field to loop's row (format in its header comment)
sprint.sh                                     — the global --demo / --help intercept and demo_for_cmd resolver
ship.sh                                       — mirror docs/ → src/ and bump version after the change

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
- *Chief Platform Architect:* `loop` is autopilot over the spine — `plan start` refill (gating as it commits) then `work` drain. Showing unattended automation actually run, safely, is a real trust story with integrity stakes: the viewer needs to believe the gate still holds when no human is watching.
- *Chief Experience Officer:* Hands-off momentum is delightful to watch — the tool doing the boring parts. This is a demo users would enjoy. But `speedrun.py` (S6) already sells "the momentum of the whole spine in one short run."

**Tension and resolution (settled 2026-08-10).** Both liked the *content*; both worried S6 already owned the momentum slot. On inspection `speedrun.py` is a *human-driven* race of one task — it never shows the `loop` command or the no-human-watching safety promise. So the earlier "retarget S6" resolution was overturned: loop's trust beat is genuinely absent from the catalog. **Decision: ship a new `loop.py` mapped to `loop --demo`; leave `speedrun.py` untouched.** See Problem / Success criteria above.

## Refine (round 1)

**Sharpened:** Filled the empty stub into a real brief. Settled the pivotal
scope decision — ship a new `loop.py` demo mapped to `loop --demo`, rather than
retargeting `speedrun.py` as the old Plan Think proposed — because speedrun is a
human-driven speed race and never shows loop's distinguishing beat: the gate
holding during unattended autopilot. Wrote verifiable Success criteria and
preserved S6.

## Refine (round 2)

**Sharpened:** Made the task self-contained. Verified loop's real behavior in
`loop.sh` (refill via `plan start` gating-as-it-commits, `--retry` re-gate,
`work count 1` per iteration, doing/→blocked/ sweep, "none ready" stop, limit
flags) and the exact registration mechanics (`learn.sh` name→file + docstring
auto-register; registry 5th field `| loop` drives `loop --demo` via the
dispatcher intercept). Folded all of it into Notes, added the `./ship.sh` +
`validate` steps, and expanded References with per-file purpose so a builder
needs nothing outside the file.
