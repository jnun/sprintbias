# Task 363: Add --parallel and --fast options to polish sweep so review queue can fan out like work

**Feature**: none
**Created**: 2026-08-10
**Docs**: none
**Plan**: none
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

`polish` sweep queues every eligible task in `review/` but always runs them
one at a time (headless for-loop; emit mode asks for one subagent per task
without parallel dispatch). A five-task review queue waits on five sequential
judges even though each judgment is independent: sweep only writes its own
task file, never product code, and is designed for a fresh context per task.
`work` already exposes `--parallel` / `--fast` / `--jobs N`; polish should
match that surface so a long review/ backlog finishes in wall-clock, not N×
latency.

## Success criteria

- [x] `./sprint.sh polish --parallel`, `--fast`, and `--jobs N` are accepted on the sweep path and documented in help polish (same meaning as work: concurrent judges, default 2 / 4 / N jobs)
- [x] Headless sweep runs up to N concurrent refine calls (the `--jobs N` cap governs this semaphore). Emit + orchestration-capable tiers instruct the orchestrator to judge the queue in parallel — fan the judge subagents out concurrently and route each as it returns — instead of "one subagent each, when it returns." The emit prompt does NOT thread the numeric cap; `--jobs N` stays a headless-only knob, and `--parallel`/`--fast` simply flip emit wording from sequential to parallel fan-out
- [x] Sequential remains the default; deep-judge and `--code` modes stay single-target (no false parallel on those shapes)
- [x] Only the judging runs concurrently: each concurrent judge writes nothing but its own task file and its own log. Verdict parsing, the `**Reworked**` bump, gate promotion, and the run counters all stay serialized in the sweep itself, after a judge finishes
- [x] The end-of-run summary (reopened / passed / blocker / unclear) is correct under `--jobs 4` — no count is lost to a background job
- [x] Concurrent REOPEN paths still promote only through the shared gate; no shared product-file writes; round cap / `--force` / limit args still work with parallel
- [x] Maintainer surfaces stay in sync: help polish, command-matrix row notes if needed, and any polish smoke/docs tests cover the new flags

## Notes

- The unit of parallelism is the task FILE: run judges concurrently ACROSS
  multiple task files, but never work a single task file concurrently with
  itself. Deep-judge and `--code` operate within one task file (and may touch
  the same product code), so they stay single-target — multiple elements/rework
  rounds of one file are inherently sequential. Only the review/ sweep, with
  more than one eligible file, fans out.
- Sweep is the safe parallel surface (task-file-only writes). Do not invent
  parallel for `polish --code` when two audits could edit the same files.
- Promotion never runs concurrently: the gate (`git mv` via
  promote-to-sprint.sh), the `**Reworked**` bump, verdict parsing, and the run
  counters all execute serialized in the parent AFTER each judge returns —
  exactly the guarantee `work`'s `_route_result` gives. So there is no
  concurrent `git mv` / `.git/index.lock` contention to defend against; do not
  build for it.
- Soft caveats only: overlapping blast-radius reopen notes (noise) and budget
  burn — same class of risk work --parallel already accepts.
- Round cap (`--rounds`, default 1) is per-task rework budget, not concurrency; keep that wording clear in help so "round cap: 1" is not misread as serial-only.
- Mirror work's flag parsing and MAX_JOBS defaults rather than inventing a second dialect.
- `work` already proved the safe division of labour for this: the backgrounded
  child only runs the CLI into a log (`work.sh` `_run_task`), and the parent
  routes and counts after it exits (`_route_result`). Polish's sweep currently
  parses the verdict, bumps `**Reworked**`, and calls the gate inline in the
  loop body — backgrounding that body as-is would run concurrent `git mv`s
  through the gate and lose `SPRINTBIAS_GATE_VERDICT` (a global) with the
  subshell, silently zeroing the counters.

## References

docs/sprintbias/scripts/polish.sh
docs/sprintbias/help/polish.md
docs/sprintbias/scripts/work.sh
docs/sprintbias/help/work.md
docs/sprintbias/scripts/gate-lib.sh
docs/guides/command-matrix.md

## Refine (round 1)

**Sharpened:** Fixed the parallelism boundary — the unit is the task FILE
(parallel across files, sequential within one, so a file never conflicts with
itself); pinned emit mode to a bare "judge in parallel" with `--jobs N` staying
a headless-only cap; and corrected the Notes so promotion/`git mv`/counters are
documented as serialized in the parent (no phantom concurrent-`git mv` risk).

## Questions

**Status: READY**

### Already complete
None — no matching implementation found. Verified against the current code:
- `polish.sh` flag loop (lines 52-81) accepts `--code`, `--rounds`, `--max`,
  `--force`, `--model`, `--`, `-h/--help` only. No `--parallel`, `--fast`, or
  `--jobs`; no `MAX_JOBS` variable exists in the script.
- The headless sweep runner (lines 1029-1099) is a strict serial `for` loop:
  each iteration runs the refine call, parses the verdict, bumps `**Reworked**`
  via `_bump_reworked`, promotes through `sprintbias_promote_to_sprint`, and
  updates the `REOPENED/PASSED/BLOCKED/UNCLEAR` counters inline before the next
  task — no backgrounding.
- Both emit branches (lines 961-1012) instruct "launch a subagent, and WHEN IT
  RETURNS route it" one task at a time; neither fans judges out concurrently.
- `help/polish.md` documents no parallel flags.

The `work` pattern this task mirrors is real and shippable: `work.sh` parses
`--parallel`/`--fast`/`--jobs` into `MAX_JOBS` (lines 9, 53-54, 58), and its
parallel scheduler (`_try_launch`, lines 1256-1310) backgrounds `_run_task`
while the parent serializes `_route_result` after each child exits — exactly the
division of labour Notes calls for.

### Remaining work
- Add `--parallel` (jobs=2), `--fast` (jobs=4), and `--jobs N` to polish's flag
  parser, mirroring `work.sh` defaults; guard them to the sweep path only
  (deep-judge and `--code` stay single-target — reject or ignore the flags on
  those shapes).
- Headless sweep: run up to `MAX_JOBS` refine calls concurrently against a
  semaphore, but keep verdict parsing, the `**Reworked**` bump, gate promotion,
  and the four run counters serialized in the parent after each judge returns
  (background only the CLI-into-log body; do not background the routing/counter
  block — that would run concurrent `git mv`s and lose the
  `SPRINTBIAS_GATE_VERDICT` global to the subshell).
- Emit branches: flip the orchestration-capable prompt from "one subagent, when
  it returns" to "fan the judge subagents out concurrently and route each as it
  returns" when `--parallel`/`--fast` is set. Do NOT thread the numeric `--jobs`
  cap into the emit prompt (headless-only knob).
- Keep sequential the default; verify round cap / `--force` / limit args all
  still work under parallel, and that the end-of-run summary is correct with no
  count lost to a background job.
- Update `help/polish.md` (new flags, same meaning as work; keep "round cap: 1"
  distinct from concurrency), add a command-matrix note if the row needs it, and
  extend any polish smoke/docs test to cover the flags.

### Questions for the developer
None — task is fully defined.

<!-- After work only — audit trail of what was touched. Helps committers,
     later audits, and "what broke?" recovery. Copy the two headings below to
     column 0 (UNINDENTED — they are indented here only so a fresh, unworked
     task is not mistaken for a finished one), then list one repo-relative
     path per line under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintbias/scripts/example.sh
       docs/tasks/.TEMPLATE-task.md

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. Do not fill this before work. -->

<!--
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->

## Completed

Added `--parallel` (2 jobs), `--fast` (4 jobs), and `--jobs N` to `polish`,
mirroring `work`'s flag surface and MAX_JOBS defaults. Scope-limited to the
review/ sweep: the flags are ignored (with a note) for deep-judge and `--code`,
which stay single-target.

- Flag parsing in `polish.sh` mirrors `work.sh`: `PARALLEL`/`MAX_JOBS`, numeric
  validation, and a sweep-only guard that unsets `PARALLEL` (with a stderr note)
  when the resolved mode is `judge` or `code`.
- Headless sweep refactored into `_run_refine` (backgroundable — runs the CLI
  into its own per-task log and nothing else) + `_route_refine` (parent-only —
  parses the verdict from the log, bumps `**Reworked**`, promotes through the
  shared gate, and updates the four counters). Per-task state (log path,
  next-round number, pre-judge `## Rework` section count) is captured up front so
  a backgrounded judge changes nothing the parent routes on. This is exactly
  work.sh's `_run_task`/`_route_result` division of labour, so verdict parsing,
  the counter bump, the gate `git mv`, and the run counters all stay serialized
  in the parent — no concurrent gate, no count lost to a background job.
- A semaphore runner keeps at most `MAX_JOBS` judges in flight, routing each the
  instant it exits before topping the pool back up. Falls back to sequential
  when `COUNT <= 1` (no false parallel on a single file). Sequential is still the
  default. Verified the scheduler mechanics (all tasks routed, concurrency
  capped, counters persist in parent, clean exit under `set -euo pipefail`) with
  a standalone harness.
- Emit orchestration prompt: `--parallel`/`--fast` flip the dispatch wording from
  "launch a subagent, when it returns route it" to "fan the judge subagents out
  concurrently, route each as it returns." The numeric `--jobs` cap is NOT
  threaded into the emit prompt (headless-only knob). The no-subagent tier stays
  one-at-a-time. Verified both wordings in emit mode for claude-code + grok.
- Docs/surfaces: help polish (synopsis, parallel section keeping "round cap: 1"
  distinct from concurrency, usage lines), command-matrix polish row note, and
  three new command-matrix smoke assertions. `validate --commands` and
  `validate --docs` clean (no flag drift); `ship.sh --dry-run` mirrors the two
  shipping files cleanly. Not shipped/committed — that is the developer's step.

### Files changed
docs/sprintbias/scripts/polish.sh
docs/sprintbias/help/polish.md
docs/guides/command-matrix.md
docs/tests/test-command-matrix-smoke.sh
