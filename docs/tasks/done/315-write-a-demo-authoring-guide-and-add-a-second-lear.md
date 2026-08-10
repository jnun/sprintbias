# Task 315: Authoring guide (README) + S1 gate demo

**Feature**: none
**Created**: 2026-07-31
**Docs**: none
**Plan**: 13
**Depends on**: 313
**Blocks**: none
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

One demo proves the idea; a small **catalog** teaches a few new concepts to a
brand-new user. For `learn` to grow without rot, authors (human or agent) need a
house guide: flat layout, story curriculum, presentation atoms, trust contract,
and how demos auto-register. We also need a second demo so the pattern is not a
one-off — the **gate** is the biggest "why did it do that?" moment, so it earns
Story **S1**.

## Success criteria

- [x] `docs/sprintmd/learning/README.md` exists and covers:
      - **Curriculum map** (S0–S6 names, one-line lesson each, which file)
      - Flat layout rule (`*.py` + this README; no nested dirs until multi-runtime)
      - Shared output vocabulary (typewriter, spinner, moved, beat, …)
      - `--fast` / `--no-color` / non-TTY / Ctrl-C
      - stdlib-only + **writes-nothing** contract
      - How a new demo is picked up by `learn` (docstring first line = catalog)
      - Self-contained demos for v1 (no shared `_demokit.py` unless we reverse this)
- [x] **S1** demo `gate.py` (or equivalent) plays under `./sprint.sh learn gate`:
      half-baked task held at the gate → chat/sharpen → re-gate passes — situation,
      not a feature list.
- [x] `./sprint.sh learn` lists S0 and S1 with one-line descriptions; no launcher
      change required to register the new file.
- [x] S1 reuses S0's presentation vocabulary (factor only if duplication truly
      hurts; default self-contained).
- [x] Same flags and trust contract as 313.
- [x] Registry maps **`gate` → this demo** so `./sprint.sh gate --demo` works once
      314's intercept exists (or add the field now; 314 reads it). Help for gate
      will mention `--demo` via 314 — this task only owns the mapping + script.

## Notes

Depends on 313 (engine + home + S0). **Soft precedence (plan queue):** finish
this **before** 316/317/324/325 so later stories copy the guide instead of
inventing style — preferred order is 313 → 315 → other stories even when the
dep graph allows parallel after 313.

**S1 story beat:** user tries to push a vague task; gate holds with a clear
reason; short chat sharpens Problem/Success; re-run works. Honesty over theater —
the gate is a real guardrail.

**Self-contained vs kit:** lean self-contained for v1; README states the rule.
Revisit only if duplication bites across the Full catalog.

**README should document the on-ramp pair:** for a host-mapped command,
**`--help` explains how the command works**; **`--demo` plays a python scenario**
that starts from a common problem and showcases that command’s feature set
(safe theater, not a live run against the user’s project). `learn` is the catalog
(and demos without a host command). Registry demo-field format is owned by 314;
stories only populate their host row.

**Out of scope:** implementing the `--demo` intercept (314); other stories
(317/324/316/325).

## References

docs/sprintmd/learning/session.py        — S0 after 313 relocates (or docs/learning/sprint_demo.py until then)
docs/tasks/backlog/313-add-a-learning-feature-in-app-interactive-demos-th.md
docs/plans/13-autolearning.md            — full curriculum

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

## Completed

Wrote the `learning/` authoring guide (governance: curriculum map, flat-layout
rule, shared output vocabulary, flag/TTY/Ctrl-C behavior, stdlib-only +
writes-nothing contract, docstring-first-line auto-registration, self-contained
v1 rule, and the `--help` vs `--demo` on-ramp pair). Authored the **S1** `gate.py`
demo — a vague task held BLOCKED with a clear reason → short chat sharpens
Problem/Success → re-gate passes — self-contained, reusing S0's vocabulary and
flag/trust contract verbatim. Mapped `gate → gate` as the optional 5th registry
field so `./sprint.sh gate --demo` works once 314's intercept lands.

Verified in place: `./sprint.sh learn` lists S0 and S1 from docstrings with no
launcher edit; `learn gate --fast` plays clean; `--no-color`/non-TTY drops ANSI
and exits 0; the run writes nothing (git porcelain unchanged); `gate.py` compiles
clean; `validate --commands` stays green with the added demo field.

Deferred to the developer (out of this task's scope): `./ship.sh` — the repo has
many unrelated pending `docs/` changes, so mirroring to `src/` and bumping VERSION
is a release step the developer controls.

### Files changed
docs/sprintmd/learning/README.md
docs/sprintmd/learning/gate.py
docs/sprintmd/help/_registry
docs/tasks/doing/315-write-a-demo-authoring-guide-and-add-a-second-lear.md

## Plan Think

**Locked:** README is governance (curriculum + invariants); gate is S1 worked
example; self-contained v1; soft-before other story demos. Architect cares that
the engine stays closed while the catalog stays open. CXO cares catalog lines and
consistent house look.

## Questions

**Status: READY**

### Already complete
Nothing yet. The dependencies this task builds on come from task 313 (in
`next/`): the `learn` engine, the flat learning home at
`docs/sprintmd/learning/`, and the S0 demo. As of now none has landed —
`docs/sprintmd/learning/` is an empty directory, there is no `learn` script or
help page, no `README.md`, no `gate.py`, and the S0 demo still sits at its
pre-313 path `docs/learning/sprint_demo.py`. So every success criterion here is
remaining work.

### Remaining work
- Write `docs/sprintmd/learning/README.md` as the authoring guide/governance
  doc, covering exactly the seven bullets listed: curriculum map (S0–S6 name +
  one-line lesson + file), flat-layout rule, shared output vocabulary,
  flag/TTY/Ctrl-C behavior, stdlib-only + writes-nothing contract, docstring
  first-line = catalog auto-registration, and the self-contained-for-v1 rule.
- Author the **S1** `gate.py` demo playable via `./sprint.sh learn gate`: a
  vague task held at the gate → short chat/sharpen → re-gate passes. Situational
  story, not a feature list; honesty over theater.
- Confirm `./sprint.sh learn` lists both S0 and S1 with one-line descriptions
  purely from the new file's docstring — no launcher edit to register it.
- Match S0's presentation vocabulary and the same `--fast` / `--no-color` /
  non-TTY / Ctrl-C flags and trust contract; stay self-contained (factor only if
  duplication genuinely hurts).

### Questions for the developer
None — task is fully defined. The only wait is on task 313 landing the engine,
home, and S0; that dependency is already recorded in the `**Depends on**: 313`
field, and the task runner holds this in `next/` until 313 reaches review/done.
