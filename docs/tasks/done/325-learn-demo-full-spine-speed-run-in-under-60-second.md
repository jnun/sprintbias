# Task 325: S6 learn demo: full-spine speed run (< ~60s, momentum only)

**Feature**: none
**Created**: 2026-07-31
**Docs**: none
**Plan**: 13
**Depends on**: 313, 315
**Blocks**: none
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

After the teaching demos, a new user may still doubt SprintBias is *fast*. They
need a different emotional register than S0's explanatory session: a **speed run**
— bug or task through the spine to review in under ~60 seconds of screen time —
that sells momentum, not lessons. If this demo grows explanatory beats, it
collapses into a slower twin of S0 and should be cut or folded into S0 `--fast`
instead of shipping.

## Success criteria

- [x] `./sprint.sh learn speedrun` (or chosen name) plays
      `docs/sprintmd/learning/speedrun.py` — self-contained python3+stdlib,
      writes-nothing, flags + non-TTY + Ctrl-C.
- [x] **Default pacing ≤ ~60s** wall time on a normal terminal; `--fast` much
      shorter. No long narrator "why" beats — momentum register only.
- [x] Catalog one-liner states speed/momentum (e.g. "whole spine in under a
      minute"), never "learn how X works."
- [x] Clearly distinct from S0 (teaching session) and S2 (bug conversion focus).
      If distinction fails in review, **do not ship** — fold into S0 or drop.
- [x] Auto-registers; reuses house atoms lightly (prefer after 315).

## Notes

**Curriculum role:** Story **S6** — last in soft catalog order. Optional in
spirit: only ships if the distinctiveness bar clears. Plan 13 Full includes the
slot; quality gate can still refuse a near-duplicate.

**Soft-after 315.** Hard depend 313.

**Host command:** **catalog-only** (`learn speedrun`) — momentum piece, not a
single-command tutorial. No `--demo` mapping required.

**Out of scope:** teaching conversion (317), plan think (inside 324), parallelism
(316); `--demo` intercept.

## References

docs/sprintmd/learning/README.md
docs/sprintmd/learning/session.py
docs/plans/13-autolearning.md
docs/tasks/backlog/313-add-a-learning-feature-in-app-interactive-demos-th.md

## Questions

**Status: READY**

### Already complete

Nothing for this demo exists yet. `docs/sprintmd/learning/` is an empty
directory — no `session.py`, no `speedrun.py`, no README, and the `learn`
command is not on any surface (`_registry`, `sprint.sh` dispatch, `help/`,
`DOCUMENTATION.md`). The engine, flat home, S0 `session.py`, and the launcher
that would play `speedrun.py` are all owned by **task 313** (currently in
`next/`), and the house atoms this demo "reuses lightly" come from **315**
(backlog). So this task has no implemented work to carry over — it is a
net-new script gated on its prerequisites.

Plan 13 confirms the slot is real and consistent with this task:
`docs/sprintmd/learning/speedrun.py` is listed as **S6 — full spine < ~60s,
momentum only (325)** with the strict distinctiveness bar. No contradiction
between the task, the plan, and the (empty) current state.

### Remaining work

1. **Write `docs/sprintmd/learning/speedrun.py`** modeled on 313's
   `session.py`: python3 + stdlib only, writes nothing, honors `--fast` /
   `--no-color`, degrades on non-TTY, clean Ctrl-C (exit 130). It plays a
   bug-or-task through the spine to `review/` in ≤ ~60s of screen time, in a
   **momentum register** — no long narrator "why" beats.
2. **`--fast` path** much shorter than default.
3. **Catalog one-liner (docstring first line)** states speed/momentum
   ("whole spine in under a minute"), never "learn how X works" — this is how
   the auto-registering `learn` launcher lists it.
4. **Auto-registration verify**: once dropped in `docs/sprintmd/learning/`, it
   appears in `./sprint.sh learn` with no launcher edit; `./ship.sh` mirrors it
   automatically (whole-tree rsync).
5. **Distinctiveness review**: confirm it reads clearly apart from S0 (teaching
   session) and S2 (bug-conversion focus, 317). If it doesn't, do **not** ship —
   fold into S0 `--fast` or drop, per the success criteria.

### Questions for the developer

None — task is fully defined.

The only open judgment is the distinctiveness bar, and the task already binds it
to a review-time gate (ship only if it clears; otherwise fold into S0 or drop) —
that is acceptance criteria, not a decision needed before starting. This task
holds in `next`-style sequencing until **313** reaches review (and preferably
**315** for the shared house atoms); a developer could start it the moment those
land, with no open questions.

## Completed

Wrote `docs/sprintmd/learning/speedrun.py` — the S6 speed run. Prerequisites had
landed (313 and 315 are both in `review/`), so the engine, flat home, house
atoms, and the auto-registering `learn` launcher were all in place.

**What it does:** one plain task (`rate-limit the login endpoint`) races the full
spine — `newtask → chat → work` — from `backlog/` to `review/` with no teaching
beats. A signature **momentum device** replaces S0's explanatory asides: a
four-stage track (`capture ▸ sharpen ▸ run ▸ review`) that lights each stage
green as the task blows past it, so you *watch the whole spine fill up*.

**Register / distinctiveness (the ship gate):**
- vs **S0** (`session.py`, teaching): S0 uses long `beat()` "why" asides across
  two acts. Speed run drops them — the `beat` helper is kept for house
  consistency but the register is momentum-only; faster typing (`cps` ~half S0),
  shorter naps, tighter spinners, and the stage track carry it. Outro explicitly
  points doubters to `learn session` for the why.
- vs **S2** (`bug.py`, conversion): S2's beating heart is report→task conversion.
  Speed run deliberately uses a **plain task** (never a bug), so there is no
  conversion beat at all — pure lifecycle velocity.

**Verified:**
- `python3 -m py_compile` clean; `-h/--help` exits 0 and prints the docstring.
- `--fast` runs instantly; default (non-`--fast`) wall time ≈ **8s** — well
  under the ~60s ceiling and reads as a sprint, not a lesson.
- Non-TTY auto-drops color; `--no-color` honored; Ctrl-C (SIGINT) prints the dim
  interrupt line and exits **130**.
- **Auto-registers** with zero launcher edit: `./sprint.sh learn` lists
  `speedrun` with its momentum one-liner ("the whole spine in under a minute:
  capture to review, one breath") — speed/momentum framing, never "learn how X
  works."
- Trust contract held: stdlib only, writes nothing, no network; the sandbox
  promise is the first thing shown.

**Not shipped to `src/`:** left to the developer's batched `./ship.sh` step. The
sibling learning demos (session/bug/gate/feature-plan/parallel, all in `review/`)
are likewise not yet mirrored, and `ship.sh`'s whole-tree rsync picks up any new
`learning/*.py` automatically — no manifest edit is required for this file.

### Files changed
docs/sprintmd/learning/speedrun.py

<!-- When this task is finished, leave an audit trail of what it touched.
     Reviews and the change manifest read this. Copy the two headings
     below to column 0 (UNINDENTED — they are indented here only so a fresh,
     unworked task is not mistaken for a finished one), then list one
     repo-relative path per line under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintmd/scripts/example.sh
       docs/tasks/.TEMPLATE-task.md

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. -->

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
