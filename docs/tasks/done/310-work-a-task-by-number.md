# Task 310: work a task by number

**Feature**: none
**Created**: 2026-07-31
**Docs**: none
**Depends on**: none
**Blocks**: none
**Parent**: none
**Refined**: 3
**Reworked**: 0

## Problem

<!-- The problem as a short user story — who, what they can't do, why it
     matters. Loose Gherkin (Given/When/Then) is welcome, not required.
     2-5 sentences, plain English. -->

`./sprint.sh work` executes the whole `next/` queue in order. There is no way
to run one specific task on its own. When a user wants to work a single item —
to re-run one task, or run one ahead of the rest of the sprint — they have no
handle for it. They should be able to name a task by its number and have `work`
run just that one.


## Success criteria

<!-- Observable behaviors that show it's done: "User can [do what]" /
     "App shows [result]". Clear and succinct — anyone can verify. -->

- [x] `sprint work 311` works task 311 when it is in `next/` and `Status: READY` (moves it `doing/` → work → `review/`), the same as the queue would.
- [x] `sprint work` with no args still runs the whole `next/` queue in order (unchanged).
- [x] `sprint work count N` runs at most N ready tasks; the old bare-number-as-count (`work 3`) no longer means a count.
- [x] `sprint work 311` for a task in `backlog/` runs the workability gate inline: on pass it stamps READY, moves the task to `next/`, and works it; on fail it routes the task to `blocked/`, reports why, and does NOT work it.
- [x] A named task with an unmet dependency is held and reported ("held: waiting on <id>"), not worked, and its prerequisite is not pulled in behind it. For a task still in `backlog/`, an unmet dependency means it is NOT promoted — it stays in `backlog/` and only the held message is printed (promotion is earned by runnability, not just definition clarity).
- [x] `sprint work <n>` for a task in `review/` or `done/` **re-runs** it: moves it back to `doing/`, clears its old `## Completed` / `### Files changed` block so the run is real (the router keys off that section — an un-reset task would route straight back without working), reworks it, and re-routes to `review/`.
- [x] `sprint work <n>` for a task in `doing/` (in flight) refuses with a clear message and does not touch it — the loop's orphan sweep owns crash recovery there.
- [x] `sprint work <n>` where no task `<n>` exists in any lifecycle folder errors clearly.
- [x] `help/work.md` usage and the `work` entry in `help/_registry` document the new grammar and agree (`validate --commands` passes).
- [x] `loop.sh` calls `work count 1` (not bare `work 1`) so the autonomous loop still runs one task per iteration under the new grammar; a quick sweep confirms no other live callers still use bare `work <number>` as a count.
- [x] `work N` runs only the one resolved task in BOTH emit mode (orchestration path) and exec mode — the run is narrowed to a single-task `TASK_FILES`/`COUNT=1` before the emit/exec branch, so emit mode does not hand the surrounding agent the whole `next/` queue.

## Notes

<!-- Every relevant detail that helps build the solution fast and knowingly:
     decisions, constraints, edge cases, gotchas. Leave empty if none. -->

**Invocation grammar (decided):**
- `sprint work 311` — a bare number is a task id; work just that task.
- `sprint work` — no args, run the whole `next/` queue (unchanged).
- `sprint work count N` — the old "run at most N tasks" cap, moved behind the
  plain-language `count` sub-word so the bare number is free for the task id.

Parse edges (sensible defaults): a single bare number is one task id — two
bare numbers (`work 311 312`) is a usage error, not "work both"; `count` with
no following number is a usage error. Flags still compose (`work 311 --force`,
`work count 3 --fast`).

Why: working one specific task is the common case, so it earns the shortest
command. The `work N` = count meaning has to move; `count N` reads the same to
a person and an agent (house style) and is self-describing. This is a
deliberate, documented break of the old `work 3` / `work 1` count syntax — cheap
because the tool is dogfooded and pre-release, and the two everyday modes are
"run all" (`work`) and "work one task" (`work N`).

**Scope (decided): the invariant holds — tasks are only worked in the sprint,
only when READY — but `work N` will PROMOTE a named task into the sprint for
you first.** This is the rush path: you wrote a bug report, turned it into a
task sitting in `backlog/`, and you just want it worked now.

`work 311` resolves task 311 by number and branches on where it lives:
- **In `next/`, `Status: READY`** → work it exactly as the queue would (move to
  `doing/`, work, land in `review/`).
- **In `next/`, not READY** → same treatment the queue gives an unvetted task
  (held/skipped), unless the existing `--force` is passed.
- **In `backlog/`** → run the workability gate on it inline, then:
    - gate PASSES → stamp `Status: READY`, move it into `next/`, work it. BAM.
      (Unmet dependency short-circuits this earlier — see "Promotion is earned
      by runnability" below.)
    - gate FAILS (needs a decision/clarification) → route to `blocked/` and
      report why; it is NOT worked. The gate is the screen; nothing
      unvetted gets run.
- **In `blocked/`** → re-run the gate. Open question still unresolved → gates
  back to `blocked/` (still not worked), the correct outcome. Resolved →
  promotes and works like a `backlog/` task.
- **In `review/` or `done/`** → **re-run** (decided, see below): move back to
  `doing/`, reset the `## Completed` block, rework, re-route to `review/`.
- **In `doing/`** → in flight; refuse and report ("311 is in doing/ — a run
  owns it"). Do not touch it; crash recovery is the loop's orphan sweep.
- **Number resolves to no task file anywhere** → error.

**Re-run (decided): `work N` on an already-worked task reworks it.** The Problem
names "re-run one task" as a core motivation, so a task in `review/` or `done/`
is pulled back to `doing/` and worked again. The one correctness trap: the runner
routes a finished task to `review/` by the PRESENCE of a `## Completed` section
(`work.sh:411`), and a `review/`/`done/` task already has one — so re-run MUST
clear the old `## Completed` / `### Files changed` audit block before working, or
the router short-circuits and nothing runs. Resetting it also keeps the audit
trail honest: the trail reflects the new pass, not the stale one. A task in
`doing/` is left alone (a run already owns it).

Net: the readiness gate stays the single guardrail. `work N` adds no bypass —
it just runs the existing screen-and-promote step for one task so the user
doesn't hand-run `gate` / `plan start` in a hurry. A task in `blocked/` with an
open question will simply gate back to `blocked/` (still not worked), which is
the correct outcome.

**Dependencies:** `work N` runs the one named task and stops — it does not
drain a chain. If task N has an unmet prerequisite (not yet in `review/`), hold
it and report ("held: waiting on <id>"), same as the queue holds a dependent
task; do not silently pull the prerequisite in behind it.

**Promotion is earned by runnability, not just definition clarity (decided).**
The dependency check runs BEFORE promotion, reusing the existing
`sprintmd_unmet_deps` helper (see `work.sh:179`, `:477`). Flow for `work N`:
resolve the task → if it has an unmet dependency, print the held message and
STOP, changing nothing → else promote (gate/`plan start`) and run. So a
well-defined `backlog/` task that is merely waiting on a prerequisite is NOT
pulled into `next/`; it stays in `backlog/`. Rationale, tied to the guiding
principles: promoting a task that would immediately be held is motion without
progress (fails "bias for real forward movement"), and it silently grows the
sprint the user didn't ask to enlist (fails "tracked, safe work"). The user said
"work this one" — if it can't run now, the least-surprising, most-minimal
outcome is to report why and leave the file untouched. A task ALREADY in `next/`
that is held on a dep gets the same held message and is left in place — no
demotion, since it was deliberately queued.

**Implementation lean (keep `work` clean):** an out-of-frame task should be
screened-and-promoted by reusing the *existing* gate / promotion pathway
(`gate` / `plan start`), invoked automatically — not by adding new
argument-handling or new flags into the work flow. `work`'s surface stays
minimal: a bare number (id) and the `count` sub-word. The promotion machinery
already exists; `work N` just calls through to it.

The model is: `work N` puts the one named task through the *same scripts a user
would run by hand, in succession* (resolve → gate/`plan start` promote →
readiness/dependency check), then hands off to the normal runner. Concretely,
`work N` resolves the task and narrows the run to that single file —
`TASK_FILES` = just that task, `COUNT=1` — **before** the emit/exec branch at
`work.sh:268`. Because both modes read from the same `TASK_FILES`, this makes
`work N` behave identically whether the run is emit (orchestration hands one task
to the surrounding agent) or exec (CLI runs one task). Without this, emit mode —
the default path in this repo — would still hand the agent the entire `next/`
queue and ignore the id.

**Surfaces to update:** this changes `work`'s argument grammar, so the usage in
`help/work.md` and the `work` entry in `help/_registry` must both reflect
`work N` / `work count N` (the registry validation enforces the surfaces agree
— see `validate --commands`).

**Internal caller (must not break):** `loop.sh` is a live functional caller of the
old bare-number-as-count syntax — each iteration runs
`bash …/work.sh 1 …` meaning MAX_TASKS=1. Under the new grammar that becomes
"work task id 1" and the autonomous loop dies. Update that call to
`work count 1` (or equivalent argv) as part of this task — not a follow-up.

**Caller sweep (2026-07-31):** only live code caller of bare `work <number>` as
a count is `docs/sprintmd/scripts/loop.sh:266`. Docs still show the old meaning
in `help/work.md` (intentional surface update). Tests invoke bare `work` without
a numeric cap. No other scripts pass a bare number into `work.sh` as MAX_TASKS.

## Refine (round 3)

**Sharpened:** Closed three gaps a stress-test surfaced. (1) `work N` narrows the
run to a single-task `TASK_FILES`/`COUNT=1` BEFORE the emit/exec branch, so it
behaves identically in emit mode (the repo default) and exec mode — previously
unspecified, and emit mode would have ignored the id and run the whole queue.
(2) Promotion is earned by runnability: an unmet dependency is checked before
`plan start`, so a `backlog/` task that can't run stays in `backlog/` rather than
being silently enlisted into `next/` — real forward movement over motion. (3)
Scoped in re-run (the Problem's second motivation): a `review/`/`done/` task is
pulled back to `doing/` and reworked, resetting the `## Completed` block so the
router (which keys off that section) doesn't short-circuit; `doing/` is refused.

## Refine (round 2)

**Sharpened:** Named `loop.sh` as an explicit success criterion and reference —
the autonomous loop is the one functional caller of bare `work 1` as a count, so
repurposing that grammar without updating the call breaks per-iteration execution.
Caller sweep confirmed loop.sh is the only live code site; docs/tests are the
other surfaces already on the list.

## References

<!-- Direct files that help build this — existing code to reuse (don't
     reinvent), specs, examples. One path per line. Leave empty if none. -->

docs/sprintmd/scripts/work.sh        — the work flow: argument parse, queue loop, doing/→review/ moves
docs/sprintmd/scripts/loop.sh        — MUST update: currently `work.sh 1` for one task per iteration → `work count 1`
docs/sprintmd/help/work.md           — usage text to update (bare number = id, `count N`)
docs/sprintmd/help/_registry         — canonical `work` command entry; must agree with help (validate --commands)
docs/sprintmd/scripts/gate.sh        — the workability gate to reuse for inline screen-and-promote
docs/sprintmd/scripts/gate-lib.sh    — gate internals / READY stamping
docs/sprintmd/scripts/plan-start.sh  — existing gate-and-promote-into-next/ pathway to call through to

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

## Refine (round 1)

**Sharpened:** Took this from an empty stub to a full brief — merged the
duplicate task 311 into this one, then defined the whole feature: `sprint work
N` = work task N (bare number is an id), `work count N` replaces the old
bare-number count, and `work` unchanged. Decided the scope: naming a task
out of frame auto-runs the existing gate to screen-and-promote it into `next/`
before working (pass → work, fail → `blocked/`), keeping the "worked only when
READY in the sprint" invariant intact while reusing existing machinery rather
than growing `work`'s argument surface.

## Questions

**Status: READY**

### Already complete
Nothing in this task is implemented yet. Verified against current code:

- `work.sh:44` still maps a bare number to `MAX_TASKS` (the count) — the old
  grammar this task deliberately replaces. No task-id resolution, no `count`
  sub-word, no promote/re-run/hold branching exists.
- `loop.sh:266` still calls `bash "$SCRIPT_DIR/work.sh" 1 …` (bare number = count).
- `help/work.md` (Usage block) and `_registry:34` (`work | [limit] [--fast]`)
  still document the old count grammar.

All the machinery the task reuses **does** exist and is correctly referenced —
so the task is fully executable today:
- `sprintmd_unmet_deps`, `sprintmd_task_stage`, `sprintmd_review_verdict`,
  `sprintmd_task_path` all live in `lib.sh` (562+, 480, 538, and used throughout
  `work.sh`).
- The gate/promote pathway exists: `gate-lib.sh` is the shared workability
  review, and `plan-start.sh` already runs it to promote backlog → next/
  (READY → next, BLOCKED → blocked/, COMPLETE → review/).
- The completion router keys off the presence of a `## Completed` section
  (`work.sh` `_route_result`, and the emit-mode instruction) — the re-run
  reset the task describes is aimed at the right anchor.

### Remaining work
The full feature, roughly in build order:

1. **Argument grammar** in `work.sh`: a bare number becomes a task id (not
   `MAX_TASKS`); add a `count N` sub-word for the old cap; keep bare `work`
   unchanged. Parse edges per Notes (two bare numbers = error, `count` with no
   number = error, flags still compose).
2. **Resolve + branch** on the id by lifecycle stage (`sprintmd_task_stage`):
   next/READY → work; next/not-READY → held unless `--force`; backlog/ → inline
   gate then promote-or-blocked; blocked/ → re-gate; review/ or done/ → re-run
   (reset the `## Completed` / `### Files changed` block, rework, re-route);
   doing/ → refuse; missing → error.
3. **Dependency-before-promotion**: check `sprintmd_unmet_deps` *before* promote;
   an unmet dep prints the held message and changes nothing (backlog task stays
   in backlog).
4. **Narrow the run to one file** — set `TASK_FILES` to just the resolved task
   and `COUNT=1` **before** the emit/exec branch, so emit mode (the repo default)
   works the one task instead of handing the agent the whole `next/` queue.
5. **Caller + surfaces**: update `loop.sh` to `work count 1`; update
   `help/work.md` Usage and `_registry` `work` entry so `validate --commands`
   passes.

Note on stale line anchors: the numeric references in Notes/References
(`work.sh:411`, `:179`, `:477`, `:268`) predate later edits to `work.sh` and no
longer point where the text says — the emit/exec branch is now ~line 499, the
`## Completed` router is in `_route_result` (~671), and `sprintmd_unmet_deps`
lives in `lib.sh`, not at those `work.sh` lines. Find them by name, not number.

### Questions for the developer
None — task is fully defined.

## Completed

`work N` (bare number = task id) now works one task by number, screening and
promoting it into the sprint first when needed, and narrowing the run to a
single-task `TASK_FILES`/`COUNT=1` **before** the emit/exec branch so it behaves
identically in emit (repo default) and exec mode. The old bare-number count
moved behind the `count N` sub-word.

Implementation in `work.sh`:
- Arg grammar: added the `count` sub-word (with `count N` validation, including a
  trailing `_next_is_count` check and a "count needs a number" error); a bare
  number is now captured as `TASK_ID` (two bare numbers = usage error).
- Sourced `gate-lib.sh` to reuse `sprintmd_promote_to_sprint` /
  `sprintmd_promote_summary` — no new promote machinery.
- Single-task resolution block: resolves by `sprintmd_task_stage`/`_task_path`,
  refuses `doing/`, holds on unmet deps *before* any promote (backlog task stays
  in backlog, prereq not pulled in), then branches: next/READY → work;
  next/not-READY → held unless `--force`; backlog|blocked → gate-promote
  (READY→next/→work, BLOCKED→blocked/, COMPLETE→review/; emit mode emits the gate
  and tells the user to re-run); review|done → re-run (move to doing/, strip the
  `## Completed`/`### Files changed` block via new `_reset_completed`, rework);
  missing → error. Sets `TASK_FILES`, `MAX_TASKS=1`, `_SINGLE=1`.
- Guarded the queue scan and readiness gate with `_SINGLE` so the named-task path
  bypasses them; the prereq-drain block is a natural no-op (deps already cleared).

Callers/surfaces: `loop.sh` now calls `work count 1`; `help/work.md` Usage +
new grammar section, the `_registry` `work` row, and the DOCUMENTATION.md quick
reference all document `work N` / `count N`. Caller sweep confirmed loop.sh was
the only live bare-number-as-count caller (`cmd_work` passes args through).

Verified: parse edges (two ids, `count` w/o number) error; nonexistent errors;
`doing/` refused; next/not-READY held; backlog+unmet-dep held and NOT promoted;
review/ re-run moves to doing/ and strips the audit block; `work N` emits exactly
one task even with 5 in next/; `work count 1` caps at one; bare `work` unchanged
(all 5). `validate --commands` and `validate --docs` pass; `bash -n` clean.

### Files changed
docs/sprintmd/scripts/work.sh
docs/sprintmd/scripts/loop.sh
docs/sprintmd/help/work.md
docs/sprintmd/help/_registry
DOCUMENTATION.md
