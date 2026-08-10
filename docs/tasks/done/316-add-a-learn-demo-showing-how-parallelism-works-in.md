# Task 316: S5 learn demo: honest parallelism (independent tasks)

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

A brand-new user hears "run independent tasks in parallel" and can't picture
what that means at the terminal — do two things literally happen at once? What
makes that *safe*? Prose doesn't land it. A short `learn` demo should show two
tasks with **no shared files** advancing on separate tracks, then converging, so
the *independence that makes concurrency safe* becomes visible. It must not imply
a magic scheduler SprintBias doesn't run.

## Success criteria

- [x] `./sprint.sh learn parallel` (or the chosen name) plays a self-contained,
      python3+stdlib, writes-nothing demo under `docs/sprintmd/learning/parallel.py`,
      honoring `--fast` / `--no-color` / non-TTY / Ctrl-C.
- [x] Auto-registers in `./sprint.sh learn` with a clear one-line description; no
      launcher change.
- [x] Depicts **independence honestly** — disjoint tasks / disjoint edit surfaces
      advancing; no implied magic multi-agent engine the product doesn't have.
- [x] Reuses house presentation vocabulary per `docs/sprintmd/learning/README.md`
      (prefer authoring after 315).
- [x] Catalog line reads as a concept for a new user, not internal jargon.

## Notes

**Curriculum role:** Story **S5** in Plan 13. Soft-after 315 (guide). Hard
depend only on 313.

**Honesty bar (non-negotiable):** a demo that teaches a false concurrency model
is a correctness bug in documentation form. Show why two tasks *can* run without
stepping on each other; don't oversell orchestration.

**Host command:** default **catalog-only** (`learn parallel`) — no forced
`--demo` mapping unless a natural host is obvious later. Do not map to `work`
if the story is about independence, not "run work."

**Out of scope:** real parallel runner changes; other stories; `--demo` intercept.

## References

docs/sprintmd/learning/README.md         — after 315
docs/sprintmd/learning/session.py        — presentation atoms to mirror
docs/plans/13-autolearning.md
docs/tasks/backlog/313-add-a-learning-feature-in-app-interactive-demos-th.md

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

Authored the S5 `learn parallel` demo. It plays a three-act cinematic run:
two READY tasks with **disjoint edit surfaces** (`src/api/limits.py` vs
`web/footer.html`) advance on interleaved A/B tracks and converge in `review/`;
then a third task that would touch the *same* file as A is held via
`Depends on:` and sequenced after it. That contrast is the honesty bar: the demo
shows independence — not a magic scheduler — is what makes concurrency safe, and
that overlapping edits are sequenced rather than merged by any engine. This
mirrors SprintBias's real `work --fast` behavior (independent tasks overlap,
dependents wait; see `docs/sprintmd/help/work.md`).

Mirrors the house presentation vocabulary from `session.py`/`gate.py` verbatim
(`type_out`, `spinner`, `prompt_and_type`, `moved`, `beat`, `act`, `ok`,
`held`, `note`, `nextstep`) plus one clearly-scoped, S5-specific two-track
visual. Carries its own helper block (self-contained, python3+stdlib, writes
nothing) per the README's no-shared-kit rule.

Verified:
- `./sprint.sh learn` auto-lists it — catalog line "independence is what makes
  parallel work safe" — no launcher edit needed.
- `./sprint.sh learn parallel --fast --no-color` plays clean, exits 0.
- `--help`/`-h` prints the docstring and exits 0.
- `docs/sprintmd/tests/learn-sandbox.sh` passes — the demo writes nothing and
  leaves the project tree byte-identical.
- `python3 -m py_compile` clean.

No changes to `learn.sh` (auto-registers), the sandbox test (auto-discovers),
or `src/` — this is a `docs/`-side authoring task; `./ship.sh` mirrors it on the
next release. The registry `demo-name` mapping is intentionally **not** set:
per the task, `learn parallel` stays catalog-only (no `work --demo` intercept),
because the story is about independence, not "run work."

### Files changed
docs/sprintmd/learning/parallel.py

## Plan Think

Filled from plan-think draft. Architect: no false scheduler. CXO: high teaching
value if honest. Soft-after 315.

## Questions

**Status: READY**

### Already complete
Nothing yet. The learning infrastructure this task builds on does not exist in
the current tree — `docs/sprintmd/learning/` is empty, there is no `learn` entry
in `docs/sprintmd/help/_registry`, and there is no `session.py` or `README.md`.
That is expected: all of it is produced by prerequisite tasks, not by this one.

### Remaining work
Author a self-contained S5 demo at `docs/sprintmd/learning/parallel.py`
(python3 + stdlib, writes nothing) that shows two tasks with **no shared files**
advancing on separate tracks and then converging, making the *independence that
makes concurrency safe* visible — without implying a scheduler SprintBias doesn't
run. Auto-register it in `./sprint.sh learn` with a plain-language catalog line,
mirror the presentation atoms established in `session.py`, and honor
`--fast` / `--no-color` / non-TTY / Ctrl-C. Add the writes-nothing regression
check the way the other demos do.

Dependencies (sequencing, not blockers — already recorded in **Depends on**):
- **313** (hard, in next/) — builds the `learn` engine, the flat
  `docs/sprintmd/learning/` home, the `learn` registry entry, and `session.py`,
  which supply the launcher, registration path, and presentation vocabulary this
  demo mirrors. Author this task after 313 reaches review/done.
- **315** (soft, backlog) — authors `learning/README.md`, the house
  presentation-vocabulary reference. The task notes make this a *prefer-after*,
  not a hard gate ("Hard depend only on 313"): if 315 hasn't landed, mirror
  `session.py` directly. Left out of the hard **Depends on** field on purpose so
  the runner isn't over-constrained.

### Questions for the developer
None — task is fully defined. The demo name (`parallel`) and the
"two tracks then converge" shape are stated with a sensible default; any
refinement is an authoring choice, not a decision that gates start.
