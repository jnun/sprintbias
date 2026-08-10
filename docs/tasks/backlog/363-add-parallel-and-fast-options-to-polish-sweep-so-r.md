# Task 363: Add --parallel and --fast options to polish sweep so review queue can fan out like work

**Feature**: none
**Created**: 2026-08-10
**Docs**: none
**Plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 0
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

- [ ] `./sprint.sh polish --parallel`, `--fast`, and `--jobs N` are accepted on the sweep path and documented in help polish (same meaning as work: concurrent judges, default 2 / 4 / N jobs)
- [ ] Headless sweep runs up to N concurrent refine calls; emit + orchestration-capable tiers instruct parallel fan-out (mirroring work/gate), not only "one subagent each"
- [ ] Sequential remains the default; deep-judge and `--code` modes stay single-target (no false parallel on those shapes)
- [ ] Only the judging runs concurrently: each concurrent judge writes nothing but its own task file and its own log. Verdict parsing, the `**Reworked**` bump, gate promotion, and the run counters all stay serialized in the sweep itself, after a judge finishes
- [ ] The end-of-run summary (reopened / passed / blocker / unclear) is correct under `--jobs 4` — no count is lost to a background job
- [ ] Concurrent REOPEN paths still promote only through the shared gate; no shared product-file writes; round cap / `--force` / limit args still work with parallel
- [ ] Maintainer surfaces stay in sync: help polish, command-matrix row notes if needed, and any polish smoke/docs tests cover the new flags

## Notes

- Sweep is the safe parallel surface (task-file-only writes). Do not invent parallel for `polish --code` when two audits could edit the same files.
- Soft caveats only: overlapping blast-radius reopen notes (noise), budget burn, concurrent git mv of different paths — same class of risk work --parallel already accepts.
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
