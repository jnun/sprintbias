# Task 317: S2 learn demo: bug becomes a task

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

A brand-new user can file a bug (or find one) but doesn't see how that becomes
**work the pipeline can run** — bug report → task with Problem/Success → sitting
in backlog or next. The starter session (S0) rushes past conversion; this demo
is the conversion lesson. Watching one bug become a real task makes the intake
path click.

## Success criteria

- [x] `./sprint.sh learn bug` (or equivalent) plays a self-contained python3+stdlib
      demo at `docs/sprintmd/learning/bug.py`, writes-nothing, honoring `--fast` /
      `--no-color` / non-TTY / Ctrl-C.
- [x] Story center of gravity is **conversion**: bug (or bug-shaped report) →
      task file with a real Problem + success check → placed where the pipeline
      expects it (backlog/next). Not a full multi-plan epic.
- [x] Auto-registers in the catalog with a one-line description that says
      conversion, not "speed run."
- [x] Distinct from S0 (session end-to-end) and S6 (325 pure momentum): this demo
      teaches *how work enters*, with light narration allowed.
- [x] Reuses house vocabulary per learning README (prefer after 315).
- [x] Registry maps a host command (likely **`newbug`**) → this demo so
      `./sprint.sh newbug --demo` works once 314 exists.

## Notes

**Curriculum role:** Story **S2**. Re-scoped from an earlier "speed run" sketch —
speed/momentum is **325 (S6)** so this file stays a teaching demo.

**Soft-after 315.** Hard depend 313 only.

**Out of scope:** full spine to review as the main lesson (that's S0/S6);
feature→plan (324); parallelism (316); the `--demo` intercept itself (314).

## References

docs/sprintmd/learning/README.md
docs/sprintmd/learning/session.py
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

## Plan Think

**Rescope decision:** 317 = S2 bug→task (teach conversion). S6 speed run is 325
with a hard distinctiveness bar. Avoids catalog twin of S0.

## Questions

**Status: READY**

### Already complete

Nothing is implemented yet. Verified in the current tree:

- `docs/sprintmd/learning/` exists but is **empty** — no `bug.py`, no
  `session.py`, no `README.md`.
- There is no `learn` command anywhere: not in `help/_registry`, not in
  `help/`, not in `scripts/`, not in `lib.sh`. The engine and catalog
  auto-registration this demo plugs into do not exist yet.
- The existing `docs/learning/sprint_demo.py` (python3 + stdlib, honors
  `--fast` / `--no-color` / `-h`, ~303 lines) is the S0 seed that **313**
  relocates to `docs/sprintmd/learning/session.py`. It confirms the demo
  pattern this task copies is real and stdlib-only — good news for scope.

### Remaining work

Author `docs/sprintmd/learning/bug.py`: a self-contained python3 + stdlib
cinematic demo whose center of gravity is **conversion** — a bug (or bug-shaped
report) becoming a task file with a real Problem + success check, placed where
the pipeline expects it (backlog/next). It must write nothing, hit no network,
and honor `--fast` / `--no-color` / non-TTY / Ctrl-C, following whatever shared
narration/trust-guard conventions **313** establishes in `session.py`. Register
it in the `learn` catalog with a one-line description that reads *conversion*,
not "speed run," and keep it visibly distinct from S0 (313) and S6 (325). Prefer
authoring after 315 so it uses the README house vocabulary.

**Dependencies (sequencing, not blockers):**
- **313** (hard, already recorded in `**Depends on**`) — provides the learn
  engine, the flat `learning/` home, the catalog auto-registration hook, the
  no-writes trust guard, and `session.py` as the pattern to copy. This task
  cannot run until 313 lands, but the runner holds it in `next/` automatically.
- **315** (soft) — provides `learning/README.md` with the house vocabulary and
  authoring rules referenced by success criterion 5 ("prefer after 315"). Not a
  hard blocker; left out of `**Depends on**` deliberately so the runner isn't
  forced to wait on style-only guidance. If 315 hasn't landed when this runs,
  match `session.py`'s established tone.

### Questions for the developer

None — task is fully defined. The only wait is on prerequisite tasks (313 hard,
315 soft), which the runner sequences automatically; there is no open decision
on this task itself.

## Completed

Authored `docs/sprintmd/learning/bug.py` (S2), a self-contained python3 + stdlib
demo whose center of gravity is **conversion**: a bug report (`newbug` →
`docs/bugs/8-...md`, a flat inbox note) becomes a real task via `chat bugs`
`[w] work it` — minting `docs/tasks/backlog/43-fix-...md` with a Problem that
has a person in it and two testable Success checks, then deleting the report.
A short third act queues it through the gate into `next/` so the viewer sees it
enter the pipeline like any task. Faithful to the real flow verified in
`create-bug.sh` / `chat-bugs.sh` / `create-task.sh`.

- Copied the house vocabulary block verbatim from the newest peer `gate.py`
  (type_out / spinner / prompt_and_type / moved / beat / act / claude / you /
  ok / held / note / nextstep), plus one small local helper `card()` for the
  before/after file previews that make the report-vs-task contrast visible.
- Honors `--fast` / `--no-color` / non-TTY (auto-drops color) / `-h` / Ctrl-C
  (prints `…demo interrupted.`, exits 130). Writes nothing, no network.
- Auto-registers in the catalog — first docstring line reads *conversion*
  ("a bug report becomes a real, workable task"), not "speed run." Confirmed it
  shows in `./sprint.sh learn`.
- Registry: added the 5th field `bug` on the `newbug` row so `newbug --demo`
  maps here once #314's intercept ships. `validate --commands` passes.
- Distinct from S0 `session.py` (end-to-end) and S6 `speedrun.py` (#325
  momentum): this teaches *how work enters* with light narration.

Verified: `-h` exits 0; full `--fast --no-color` run exits 0 with clean stderr;
docstring summary correct; `learn` catalog lists it; `validate --commands` green.

### Files changed
docs/sprintmd/learning/bug.py
docs/sprintmd/help/_registry
