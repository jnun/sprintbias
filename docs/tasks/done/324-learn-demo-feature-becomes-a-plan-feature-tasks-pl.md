# Task 324: S3 learn demo: feature → plan (includes plan-think act, then plan start)

**Feature**: none
**Created**: 2026-07-31
**Docs**: none
**Plan**: 13
**Depends on**: 313
**Blocks**: none
**Parent**: none
**Refined**: 0
**Reworked**: 1

## Problem

A brand-new user can create tasks but doesn't see how a **feature-shaped** pile
of work becomes an intentional **plan**, gets critiqued, and only then starts.
Without watching it: feature/idea → several tasks → plan file → a short
**plan-think** pass (empty members, bad deps, ship risks) → fix → `plan start`.
That critique beat is easy to skip in real life; the demo must make "don't start
on skeletons" visceral. Plan think is **not** a separate catalog entry — it is an
act inside this story (Plan 13 decision D2).

## Success criteria

- [x] `./sprint.sh learn feature-plan` (or chosen name) plays
      `docs/sprintmd/learning/feature-plan.py` — self-contained python3+stdlib,
      writes-nothing, `--fast` / `--no-color` / non-TTY / Ctrl-C.
- [x] Story arc includes all of:
      1. Feature-shaped work (or named feature) breaks into concrete tasks
      2. Tasks are grouped into a plan (relational index, not a folder dump)
      3. **Plan-think act:** critique finds at least one real issue (e.g. empty
         member, missing `Depends on`, ship-path risk) and shows it fixed in the
         task/plan text
      4. Only then: `plan start` (or clear "now start is honest") beat
- [x] Auto-registers with a one-line description that mentions plan + think-before-
      start (not only "make a plan").
- [x] Distinct from S0 (single session rush) and S2 (bug conversion only).
- [x] File motion over monologue: viewer sees plan/task text change; not a long
      talking-heads meeting. Default pacing should stay watchable in one sitting
      (~2–3 min; `--fast` snappy).
- [x] Reuses house vocabulary per learning README (prefer after 315).
- [x] Registry maps **`plan` → this demo** for `./sprint.sh plan --demo` (314
      owns intercept; this task owns the mapping when the script ships).

## Notes

**Curriculum role:** Story **S3** — the grouping + quality-before-start lesson.
Absorbs what might have been a standalone "plan think" demo so the catalog stays
small and concept-focused for new users.

**Soft-after 315.** Hard depend 313.

**`--demo` host:** registry-map **`plan`** (and only plan — not every plan
subcommand page) → this demo so `./sprint.sh plan --demo` plays S3 once 314
exists. Add a success checkbox if missing: mapping only; intercept is 314.

**Out of scope:** separate `plan-think.py` catalog entry; parallelism; speed run;
`--demo` intercept (314).

## References

docs/sprintmd/learning/README.md
docs/plans/13-autolearning.md
docs/tasks/backlog/313-add-a-learning-feature-in-app-interactive-demos-th.md
docs/tmp/plan-think.md                   — real critique shape to theatricalize

## Questions

**Status: READY**

### Already complete

The demo is built and largely correct — the earlier authoring pass shipped it in
full, then a rework round (below) opened three fixes that are **not yet applied**.
`docs/sprintmd/learning/feature-plan.py` exists and, verified against the code:

- **Self-contained + trust contract.** python3 + stdlib only, writes nothing, no
  network. `--fast`, `--no-color`, non-TTY auto-degrade (line 24), and Ctrl-C
  exits `130` with the dim `…demo interrupted.` line (lines 308–310). Mirrors the
  S0 shape. Good.
- **Four-beat arc present.** Act 1 fans a feature into tasks 51/52/53, Act 2 binds
  them with `newplan` into a relational `plan_card`, Act 3 `plan think 7` shows
  three real issues change on screen via `fix()`/updated cards (empty member 53,
  missing `Depends on: 51`, 52/53 overlap), Act 4 `plan start 7` gates and moves
  members to `next/`. The critique-before-start lesson lands and is distinct from
  S0/S2. Good.
- **Auto-registration + registry map.** Docstring line 2 names plan +
  think-before-start; `_registry` maps `plan → feature-plan` (verified in the
  Completed section, not re-run here).

**Correctness defect (rework round 1) — fixed:** Act 1 no longer stages
`chat plan dark-mode` as a task-drafter. Tasks are created first (`newtask` +
`chat` split), then `newplan` scaffolds, then `chat plan 7` authors by plan id,
then `plan think` / `plan start`. Outro spine matches.

### Remaining work

None — rework round 1 applied. Act 1 captures with `newtask` then `chat <id>`
splits the too-big parent into three backlog children (real chat breakdown
path). Act 2 scaffolds with `newplan … 51 52 53`, authors with `chat plan 7`
(plan id). Acts 3–4 unchanged (`plan think 7` → `plan start 7`). Outro spine:
`newtask → chat → newplan → chat plan → plan think → plan start → work`.

## Completed

**Rework round 1 (applied):** fixed command staging in
`docs/sprintbias/learning/feature-plan.py` so the demo stages the real
`help/chat.md` / `help/plan.md` order — no longer invents `chat plan` as a
task-drafter. Act 1: `newtask "ship dark mode"` → `chat 50` splits into 51/52/53.
Act 2: `newplan dark-mode 51 52 53` scaffold → `chat plan 7` author (plan id).
Outro spine updated. Chose the chat-split path (not three explicit newtasks)
for cinematic feel while staying on a command that actually creates tasks.

Shipped **S3** as `docs/sprintbias/learning/feature-plan.py` — a self-contained
python3 + stdlib demo that plays the feature → tasks → plan → **plan think** →
plan start arc. Named it **`feature-plan`** (answering the open question): plain
language, matches the arc, auto-registers under 313's launcher with no wiring
change.

Verified against every criterion:

- **Plays both ways.** `./sprint.sh learn feature-plan` and (via the registry
  map added below) `./sprint.sh plan --demo`. `plan --help` now shows the
  `Demo:` pointer. `validate --commands` still passes (24 commands, all four
  surfaces agree).
- **Trust contract.** Ran in a temp dir; a recursive listing hash was identical
  before and after — writes nothing, no network, stdlib only.
- **Terminal controls.** `--fast`, `--no-color`, non-TTY degrade (auto-drops
  color), and a real SIGINT mid-run exits `130` with the dim
  `…demo interrupted.` line — mirrors S0's proven shape.
- **Four-beat arc.** (1) "dark mode" fans out to tasks 51/52/53; (2) `newplan`
  binds them into a relational plan index (not a folder dump); (3) **plan think**
  finds three real issues — an empty skeleton member (53), a missing
  `Depends on: 51` (52), and a 52/53 persistence overlap — and shows each one
  *change on screen* via red-out/green-in `fix()` lines and updated cards; (4)
  `plan start` gates and commits, honest only after the fixes. Lifted the
  *shape* of the real critique in `docs/tmp/plan-think.md`, not its plan-13 text.
- **Auto-registration.** Docstring first line names plan + think-before-start
  ("a feature fans out to tasks, then plan think before plan start"), so the
  launcher's catalog entry teaches the concept rather than just "make a plan".
- **House vocabulary.** Reuses S0/S2 atoms verbatim (`type_out`, `spinner`,
  `prompt_and_type`, `moved`, `beat`, `act`, `claude`/`you`, `ok`/`note`/
  `nextstep`, the `card` preview) plus S3-local `plan_card`/`fix` for visible
  text motion; same palette, same trust banner.
- **Distinct from siblings.** No single-session rush (S0) and no bug conversion
  (S2) — the lesson is grouping + quality-before-start.

**Registry map (this task's other deliverable):** added `feature-plan` as the
optional 5th field on the `plan` row of `docs/sprintmd/help/_registry`, mapping
`plan → feature-plan`. The `--demo` intercept already exists in `sprint.sh`
(313/314), so no dispatcher change was needed here — mapping only, per scope.

Not shipped to `src/` here (`./ship.sh` is the developer's mirror step, run at
release; and this demo lands via 313's `next/` sprint sequencing). No commit per
task rules.

### Files changed
docs/sprintbias/learning/feature-plan.py
docs/sprintbias/help/_registry
docs/tasks/blocked/324-learn-demo-feature-becomes-a-plan-feature-tasks-pl.md

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

## Rework (round 1)

**Why:** The demo's whole value — and its own stated bar — is that it "does not
invent a workflow; it stages one that already runs." But it misstages the two
plan-authoring commands against the documented flow in `help/chat.md` (lines
84–93). There, `chat plan <id>` **authors an already-scaffolded plan** (it takes
a *plan* id, "never a task id," and "writes only the plan file" — it records
existing member IDs, it does **not** draft tasks), and the real order is
`newplan` (scaffold) → `chat plan` (author) → `plan think` → `plan start`. The
demo inverts this: Act 1 (`feature-plan.py:174`) runs `./sprint.sh chat plan
dark-mode` and depicts it *fanning a feature into three new backlog tasks*
before any plan exists, then Act 2 (`feature-plan.py:196`) runs `newplan`
*afterward*. So the one command the demo most needs to get right is shown doing
the opposite of what it does, in the wrong order. The recap "spine you just
watched" (`feature-plan.py:295`) inherits the error — it reads `chat plan → plan
think → plan start → work`, omitting `newplan` and keeping the reversed order.

**Improve:**
- [x] Re-order the acts to match `help/chat.md`: first create the tasks, then
      `newplan dark-mode 51 52 53` to scaffold the plan, then `chat plan 7`
      (a **plan id**, not `dark-mode`) to author it, then `plan think 7`, then
      `plan start 7`. `chat plan` must be shown authoring/recording into an
      existing plan, not drafting tasks.
- [x] Fix Act 1's "feature fans into tasks" beat to use an honest
      task-creating depiction (e.g. `newtask`, or `chat` on the feature) rather
      than `chat plan` — the three tasks must exist before `newplan` binds them.
- [x] Update the outro "spine you just watched" line (`feature-plan.py:295`)
      and, if needed, the through-line block so the recap matches the acts
      actually shown, in the corrected order (include the plan-scaffold/author
      step).
