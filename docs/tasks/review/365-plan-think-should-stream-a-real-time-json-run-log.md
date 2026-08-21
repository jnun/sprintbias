# Task 365: plan think should stream a real-time JSON run log to docs/tmp/ like work and polish — add --output-format json + tee log-plan-think-<id>-<ts>.json in plan-think.sh

**Feature**: none
**Created**: 2026-08-20
**Docs**: none
**Plan**: 22
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

`plan think` runs a headless, non-conversational AI critique but keeps no record
of the run. `work` and `polish` both persist their run to a timestamped JSON log
under `docs/tmp/` (`log-work-*.json`, `log-polish-*.json`); `work` also streams
that log live so you can watch progress. `plan think` produces no such log — when
a run stalls, exits early, or finishes without the `PLAN THINK COMPLETE` marker,
there is nothing to inspect. It should stream a real-time JSON run log to
`docs/tmp/` like `work` and `polish`, giving a diagnosable record of the run.

## Success criteria

- [x] The exec run in `plan-think.sh` requests a JSON output format and tees the
      raw event stream to `docs/tmp/log-plan-think-<id>-<ts>.json`, named via
      `sprintbias_log_path plan-think "$PLAN_ID"`.
- [x] The log streams in real time (use `--output-format stream-json` and
      `tee` through a live filter, matching `work`'s behavior) rather than only
      being written after the run ends.
- [x] The terminal still shows readable progress while the full raw log lands in
      the file.
- [x] The failure / no-completion-marker branches point at the log path so a
      partial or missing run is diagnosable.
- [x] Emit mode is unchanged: no log file, existing `sprintbias_emitted`
      early-exit path preserved.
- [x] Provider-neutral — the run still goes through `sprintbias_run`, so
      non-Claude profiles translate the output-format flag (same as `work`).
- [x] `./ship.sh` mirrors the change into `src/` and bumps `VERSION`.

## Notes

- Pattern to copy: `work.sh` `_run_task` (`docs/sprintbias/scripts/work.sh:1100`)
  — `--output-format stream-json 2>&1 | tee "$log" | _stream_filter` for live
  progress. `polish.sh` uses buffered `--output-format json + tee`; `work`'s
  streaming form fits the "real-time" goal here.
- Log naming helper: `sprintbias_log_path` (`docs/sprintbias/lib.sh:556`) already
  produces `docs/tmp/log-<kind>-<name>-<ts>.json`; pass kind `plan-think` and the
  plan id as the name.
- Independent of #364 — the plan records `#365 ∥ #364` (disjoint files: #365
  touches only `plan-think.sh`). This is a sibling logging fix, not a #364
  follow-on, so it does not wait on the audit.
- `docs/tmp/` retention is handled by `cleanup-tmp.sh` — no new cleanup needed.

## References

docs/sprintbias/scripts/plan-think.sh
docs/sprintbias/scripts/work.sh
docs/sprintbias/scripts/polish.sh
docs/sprintbias/lib.sh

<!-- After work only — audit trail of what was touched. Helps committers,
     later audits, and "what broke?" recovery. List the product files you
     edited to complete the task — one repo-relative path per line. Leave this
     task file out: its folder location and git history already track it. Copy
     the two headings below to column 0
     (UNINDENTED — they are indented here only so a fresh, unworked task is not
     mistaken for a finished one), then list the paths under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintbias/scripts/example.sh
       docs/sprintbias/help/example.md

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. Do not fill this before work. -->

## Completed

`plan-think.sh` now streams a real-time JSON run log, matching `work`:

- Added a `_stream_filter` (copied from `work.sh`, local to that script) that
  renders stream-json events as one readable line per step.
- Split the run into two branches on `$AI_MODE`. Emit mode calls
  `sprintbias_run` directly with no log file and keeps the same early-exit
  message — behavior identical to before (the old `sprintbias_emitted` check
  branched on the same mode value).
- Exec mode names a log via `sprintbias_log_path plan-think "$PLAN_ID"` and runs
  `sprintbias_run … --output-format stream-json 2>&1 | tee "$LOG_FILE" |
  _stream_filter` — full raw stream lands in
  `docs/tmp/log-plan-think-<id>-<ts>.json` while the terminal shows live
  progress. `pipefail` (already set) preserves the CLI's failure exit through
  the pipe.
- The no-completion-marker branch and the failure branch now print
  `Full run log: $LOG_FILE` / `Run log: $LOG_FILE` so a partial or missing run
  is diagnosable.
- Provider-neutral: still routed through `sprintbias_run`, so non-Claude
  profiles translate the `--output-format` flag the same way `work` relies on.

Verified: `bash -n` passes; emit mode (`SPRINTBIAS_MODE=emit ./sprint.sh plan
think 22`) emits the prompt, exits early, and writes no log file; the stream
filter renders a sample tool_use/result/raw stream correctly. `./ship.sh`
mirrored into `src/` (clean-mirror verified) and bumped `VERSION` 0.0.101 →
0.0.102.

### Files changed
docs/sprintbias/scripts/plan-think.sh

## Questions

**Status: READY**

### Already complete
None — no matching implementation found. What I checked:
- `plan-think.sh` (`docs/sprintbias/scripts/plan-think.sh:165`) calls
  `sprintbias_run` with `--tools/--permissions/--max-turns` but no
  `--output-format` and no `tee`/log — the run output is not persisted.
- `work.sh` `_run_task` (`docs/sprintbias/scripts/work.sh:1100`) already does the
  target pattern (`stream-json` + `tee "$log" | _stream_filter`,
  `sprintbias_log_path work`); `polish.sh` uses the buffered `json` + `tee` form
  (`docs/sprintbias/scripts/polish.sh:510`). `sprintbias_log_path` exists
  (`lib.sh:556`) and `sprintbias_run` is provider-neutral (`lib.sh:1712`).

### Remaining work
- Add a log path via `sprintbias_log_path plan-think "$PLAN_ID"` and stream the
  exec run to it: `--output-format stream-json 2>&1 | tee "$log" | <filter>`.
  Reuse a `work`-style stream filter for terminal progress (or a trimmed inline
  variant — `_stream_filter` is local to `work.sh`).
- Keep the emit-mode branch and the `PLAN THINK COMPLETE` marker check intact;
  add the log path to the "ended without a completion marker" / failure messages.
- Run `plan think <id>` locally to confirm the log lands in `docs/tmp/` and
  progress still renders, then `./ship.sh` to mirror and bump `VERSION`.

### Questions for the developer
None — task is fully defined.

<!--
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->

## Excellence Audit

### Summary
`plan think` now streams a real-time stream-json run log to `docs/tmp/` and tees
the raw event stream through a live filter, exactly mirroring `work`. Every
success criterion holds: emit mode is untouched (no log, same early exit), exec
mode names the log via `sprintbias_log_path plan-think "$PLAN_ID"`, both the
no-completion-marker and failure branches point at the log, and the run stays
provider-neutral through `sprintbias_run` (which lists `--output-format` among
its translatable flags, lib.sh:1675). The work meets the bar. The one altitude
finding: the `_stream_filter` Python renderer is now a byte-identical copy in
`work.sh` and `plan-think.sh`, a design-fit/maintainability seam worth paying
down — filed, not a blocker.

### Findings
- [ENHANCEMENT] `_stream_filter` (plan-think.sh:160) is byte-identical to
  work.sh:1057 — a duplicated ~35-line embedded Python renderer with no shared
  home; it drifts the moment either copy is edited. lib.sh is the established
  place for shared `sprintbias_*` logic.
- FILED: docs/tasks/backlog/372-extract-the-duplicated-stream-json-stream-filter-i.md

VERDICT: FILED — 1 enhancement task

## Excellence

- **Date**: 2026-08-20
- **Verdict**: FILED
- **Tasks filed**: 1
- **Files reviewed**: 1
- **Context source**: task ## Completed section

Task 365 adds a real-time stream-json run log to `plan think`, tee'd to `docs/tmp/log-plan-think-<id>-<ts>.json` and rendered live through a `work`-style filter. The implementation is a faithful mirror of `work.sh`'s proven pattern: emit mode is untouched (no log, same early exit), exec mode names the log via `sprintbias_log_path plan-think "$PLAN_ID"`, both failure branches point at the log for diagnosis, and `pipefail` (already set) preserves the CLI's non-zero exit through the pipe. Provider-neutrality holds — `sprintbias_run` lists `--output-format` among its translatable flags (lib.sh:1675). The work meets the bar; the single altitude finding is that the `_stream_filter` renderer is now a byte-identical copy in two scripts.

### Findings
- [ENHANCEMENT] `_stream_filter` (plan-think.sh:160) is byte-identical to work.sh:1057 — a duplicated ~35-line embedded Python renderer with no shared home in lib.sh; it drifts the moment either copy is edited.
- FILED: docs/tasks/backlog/372-extract-the-duplicated-stream-json-stream-filter-i.md

No defects, no blockers: every success criterion is satisfied and the end-to-end path (run → live progress + raw log → diagnosable failure branches) is intact.
