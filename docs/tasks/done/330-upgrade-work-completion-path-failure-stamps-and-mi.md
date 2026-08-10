# Task 330: Upgrade work completion path outcome stamps and missing-prereq class

**Feature**: none
**Created**: 2026-08-01
**Docs**: docs/plans/15-dependency-integrity-and-work-completion-path.md
**Plan**: 15
**Depends on**: 327, 328
**Dependents**: 332, 333
**Parent**: none
**Tests**: none
**Refined**: 1
**Reworked**: 1

## Problem

`work` already stage-classifies open prereqs (doing resume; backlog/blocked →
chat). Gaps remain: a missing prereq id is treated as complete (false green);
a failed or incomplete prereq leaves no durable stamp; hold lines do not ask
“was this folded?” Failures in doing/ look like mystery holds, not diagnosable
outcomes. Stress should leave clearer stamps, not quieter failures.

## Success criteria

- [x] Missing prereq ids classified via #328 (broken vs archived-complete vs
      folded-into-N) — no silent false green
- [x] On route to blocked/ or hard fail, work writes durable **Outcome**:
      ```
      ## Outcome
      **Result**: incomplete | failed | blocked
      **Reason**: …
      **At**: YYYY-MM-DD
      ```
- [x] Hold/report lines for dependents mention that outcome
      (e.g. `needs: 294 (blocked/ — incomplete: budget) — chat 294`)
- [x] doing/ resume remains: `## Completed` → review/; else re-run; loop orphan
      recovery stays compatible
- [x] Backlog prereqs never auto-promote; message stays
      `Consider: ./sprint.sh chat <id>`

## Notes

- Extend the existing work prepass; do not replace it.
- v1: stamp the failed prereq + surface in messaging; do not rewrite every
  dependent file on each failure.
- **Dependents** (legacy **Blocks**) is how we find who to mention in reports.

## References

docs/sprintbias/scripts/work.sh
docs/sprintbias/help/work.md
docs/sprintbias/lib.sh
docs/sprintbias/scripts/loop.sh
docs/tests/fixtures/dep-glitch-matrix/MATRIX.md
docs/plans/15-dependency-integrity-and-work-completion-path.md

## Completed

Extended `work`'s existing prepass and completion router (did not replace them)
to make failure legible instead of quiet:

- **Missing-id classification (no silent green).** New `_scan_broken_deps_from`
  runs over every queued task and classifies each declared **Depends on** id via
  #328's `sprintbias_classify_dep`. A `missing` id is reported as a broken
  reference; a `folded` id is reported as "folded into N — update **Depends
  on**" (fold target via `sprintbias_fold_target`). Archived-complete (review/
  done) ids stay quiet. The gate (`sprintbias_unmet_deps`) is left untouched so a
  stale ref still can't wedge the queue — the pass surfaces, it doesn't hold.
- **Durable `## Outcome` stamps.** New `_stamp_outcome FILE RESULT REASON`
  (with `_strip_outcome`) writes the plan-15 §5 block. Wired into
  `_route_result`: incomplete → blocked/ stamps `incomplete`; hard fail (left in
  doing/) stamps `failed` before loop's orphan sweep moves it to blocked/. Drift
  routes to blocked/ (OUTDATED, manual-review choice) stamp `blocked`. A task
  that later completes drops any stale stamp on the way to review/. Emit-mode
  prompts (orchestrator + sequential fallback) now instruct the surrounding
  agent to write the same block before moving to blocked/, so behavior can't
  drift between exec and emit.
- **Hold lines name the outcome.** `_format_dep` now reads a dep's `## Outcome`
  via `_outcome_brief` and renders `294 (blocked/ — incomplete: budget) — chat
  294` and `9007 (doing/ — failed: …)`, matching MATRIX rows 177/178 and the
  fixture stamps on board tasks 9007/9032. The missing branch classifies via
  #328 instead of the old "treated complete" line.
- **Unchanged invariants.** doing/ resume (`## Completed` → review/, else
  re-run) and loop orphan recovery are untouched; the Outcome stamp only rides
  along on the doing/ file loop already sweeps. Backlog prereqs still surface
  `Consider: ./sprint.sh chat <id>` with no auto-promote.
- **Rework round 1 — every review/ route strips.** Drift `COMPLETE` and the
  prereq-resume path (`## Completed` prereq already in doing/) now call
  `_strip_outcome` before `move_file` to review/, matching the success route in
  `_route_result`. All three review/ landings strip; FIXED→proceed falls through
  to the success strip; FIXED→blocked / OUTDATED re-stamp via `_stamp_outcome`
  (idempotent). No route leaves a success wearing a stale failure stamp.

Verified with isolated sandbox boards and against the real dep-glitch-matrix
fixtures: `_format_dep` renders the MATRIX-expected doing/failed and
blocked/incomplete lines; the scan classifies a missing id as broken and a
fold-marked id as folded-into-N while leaving existing deps out of the broken
list; `_stamp_outcome` is idempotent (replaces a prior block) and
`_strip_outcome` clears it. Structural check: every `move_file … REVIEW_DIR`
is preceded by `_strip_outcome`. `bash -n` clean.

Not shipped: `./ship.sh` mirrors the whole `docs/sprintbias/` tree and would pull
sibling plan-15 tasks' unshipped edits (lib.sh, chat.sh, split.sh, …) into
`src/` under one version bump — that batch mirror is the developer's call, not
this task's scope.

### Files changed
docs/sprintbias/scripts/work.sh
docs/sprintbias/help/work.md

## Rework (round 1)

**Why:** The task's own invariant — "a task that later completes drops any
stale stamp on the way to review/" — was enforced only on the success route
(`_route_result` calls `_strip_outcome` before moving to review/). The drift
`COMPLETE` branch was a second completion route to review/ and moved the file
without stripping. A task stopped short → blocked/ with `## Outcome: incomplete`,
re-promoted (nothing on the blocked→next promote path strips the stamp), then
re-worked with `--drift` where drift concludes `COMPLETE`, landed in review/
carrying a stale failure stamp — a success wearing a failure `## Outcome`, the
exact inversion of this task's "make failure legible" thesis.

**Improve:**
- [x] In the drift `COMPLETE` branch (before
      `move_file "$WORKING_DIR/$TASK_NAME" "$REVIEW_DIR/$TASK_NAME"`), add
      `_strip_outcome "$WORKING_DIR/$TASK_NAME"` so a task drift decides is
      already complete drops any stale `## Outcome` stamp on its way to review/,
      matching the success route in `_route_result`.
- [x] Confirm no other route into review/ carries a stale stamp: the FIXED
      →proceed path (falls through to normal work → success route strips) and
      FIXED→blocked / OUTDATED paths (re-stamp via `_stamp_outcome`, which is
      idempotent) are already covered. Prereq-resume (`## Completed` prereq in
      doing/) was the second miss — also strips before move.
