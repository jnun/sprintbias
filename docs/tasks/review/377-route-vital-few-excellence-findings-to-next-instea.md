# Task 377: Route vital-few excellence findings to next/ instead of always backlog/

**Feature**: none
**Created**: 2026-08-27
**Docs**: none
**Plan**: 24
**Depends on**: 376
**Dependents**: 378
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 1

## Problem

Every enhancement the deep-judge files lands in `backlog/` regardless of size or
confidence. `audit-excellence.md` §Severity routes all ENHANCEMENT findings
through `newtask` (which creates in `docs/tasks/backlog/`), and `polish-judge.sh`
counts them there. Backlog is the coldest queue — it may never surface. A
single-test, freshly-reviewed, high-confidence altitude fix takes the same
`newtask → backlog → work → review` path a large speculative feature does. There
is no temperature signal from the judge to the queue, so good, act-now findings
go cold next to everything else. This is the biggest throughput win of the three
handoff findings.

## Success criteria

- [x] The judge makes a per-finding routing decision: default `backlog/`, but a
      finding it rates BOTH high-confidence AND high-value (the "a senior
      engineer, told about this, would act now" bar already in the protocol) may
      be routed to `next/`.
- [x] Warm routing goes through the shared workability path, never a raw `git
      mv` into `next/` — reuse `promote-to-sprint.sh` / the gate the sweep and
      `plan start` already use, so a warm-routed task is gated READY before it
      sits in `next/`.
- [x] A single audit can warm-route at most a small capped number of findings
      (e.g. 1–2), so the judge cannot fast-track everything by self-declaring it
      all urgent. The cap and the guard against "everything is urgent" are
      explicit in the protocol.
- [x] The verdict/summary surfaces the split, e.g. `FILED — 3 (1 → next/, 2 →
      backlog/)`, and the `## Excellence` section records where each filed task
      went — added as a field on the single `## Excellence` spec 376 unifies, so
      both run paths render it identically.
- [x] The filed-task counter must SEE both destinations. Today
      `polish-judge.sh` counts filed tasks by diffing `backlog/*.md` before/after
      the run (`_backlog_count`); a task warm-routed into `next/` leaves
      `backlog/`, so that diff nets it to zero and undercounts exactly the
      warm-routed tasks. The count (and the `n (x → next/, y → backlog/)` split)
      must be computed from a mechanism that observes tasks landing in BOTH
      `backlog/` and `next/` — never the backlog-only diff alone.
- [x] Acceptance: a small, high-confidence altitude fix on freshly-reviewed code
      can land in `next/` without a human re-triaging it out of `backlog/`; a
      low-confidence or large finding still lands in `backlog/`.
- [x] `help/polish.md` (and `DOCUMENTATION.md`'s polish text) are updated to
      describe warm routing and the `FILED — n (x → next/, y → backlog/)`
      summary, so the shipped docs do not go stale.
- [x] No product code is edited by the judge; the no-edit / no-reopen rule and
      the deep-judge's mode boundary stay intact.

## Notes

- The warm-routing bar must be *narrow*. Bias the default to `backlog/`;
  `next/` is the exception the judge must justify, not the norm. The protocol
  language should make "act now" mean genuinely act-now, not "seems nice."
- Reuse, do not reinvent: `sprintbias_promote_to_sprint` / `promote-to-sprint.sh`
  is the one gate entry the sweep path already calls (`polish.sh`
  `_route_refine`). Warm routing is a filed *new* task being promoted, which
  differs from the sweep reopening the *same* task — keep that distinction crisp.
- Serialized after 376 (hard `Depends on`): both edit the same `## Excellence`
  writer and the same runner, so they are worked in order, not in parallel — the
  gate holds this task in `next/` until 376 reaches `done/`. Keep the
  `correctness:` stamp (376) and the routing summary (this task) as separate,
  composable lines on the block.
- The cap interacts with the emit path (`AI_MODE=emit`) where the orchestrating
  agent files tasks itself — the cap and routing rule must be stated in the emit
  prompt too, not only enforced in the headless counter.

## References

docs/sprintbias/scripts/polish-judge.sh
docs/sprintbias/ai/audit-excellence.md
docs/sprintbias/scripts/promote-to-sprint.sh
docs/sprintbias/scripts/polish.sh
docs/sprintbias/help/polish.md

## Plan Think

- **Platform Architect:** the fragile part is the routing authority. A judge
  that can promote its own findings to `next/` is a new privilege — it must run
  through the *same* workability gate (`promote-to-sprint.sh`) the sweep and
  `plan start` already use, never a raw `git mv`. Reusing that gate means warm
  routing inherits READY-vetting for free and adds no new promotion path to
  maintain.
- **Experience Officer:** the value is that a vital-few, act-now finding stops
  going cold in `backlog/`. But the failure mode is everything self-declaring
  "urgent," so the cap (1–2 per audit) and a narrow "senior engineer would act
  now" bar are what keep the signal trustworthy. The `FILED — n (x → next/, y →
  backlog/)` summary keeps the split visible.
- **Tension → resolution:** throughput vs. `next/` discipline. Resolved by
  making `backlog/` the default and `next/` the justified exception, hard-capped.
  Lens driving the change: **antifragility** — a capped, gated warm lane makes
  the queue more responsive without letting the judge flood the sprint.
- **Sequencing:** hard-serialized after 376 — both extend the same
  `## Excellence` block and the same runner, so the shared writer is the single
  point of collision and the plan resolves it by working them strictly in order,
  not independently. The gate holds this task in `next/` until 376 is done.

### Alignment pass (plan 24 re-review)

- **Platform Architect caught an instrumentation bug:** the filed-task count is
  computed by diffing `backlog/*.md` before/after the run (`_backlog_count` in
  `polish-judge.sh`). Warm-routing a filed task into `next/` removes it from
  `backlog/`, so that diff nets it to zero — the counter would silently
  UNDERCOUNT the very tasks this feature promotes, and the `FILED — n (x → next/,
  y → backlog/)` summary the criteria promise is unproducible from a backlog-only
  diff. **Lens: correctness.** Added a criterion requiring the counter to observe
  both `backlog/` and `next/`.
- **Experience Officer:** an inaccurate FILED summary is worse than none — it
  tells the operator "2 filed" when 3 were, quietly hiding the warm-routed win.
  The both-destinations counter is what makes the split trustworthy.
- **Left as-is:** the routing bar (narrow "act now," hard cap 1–2, reuse
  `promote-to-sprint.sh`, no raw `git mv`) was already right — untouched. Task
  stays in backlog/, malleable; no delta task needed.

## Questions

**Status: READY**

### Already complete
Round-1 build is in the codebase and verified against the success criteria — the
single-piece warm-route lane is done:
- `ai/audit-excellence.md` — "Where a filed task lands" bar: default `backlog/`,
  cap 1–2, narrow "act now" guard, warm-route via `promote-to-sprint.sh` (no raw
  `git mv`), FILED/`VERDICT:` lines carry the split.
- `lib.sh` — `sprintbias_excellence_block` has the `routing` field so both run
  paths render the split from one spec; `sprintbias_excellence_rules`
  (`lib.sh:2122`) states the default/cap/gate and writes the `Routing` field.
- `polish-judge.sh` — `_dir_count` over BOTH `backlog/` and `next/` replaces the
  backlog-only diff (fixes the undercount); step 4/5 and the emit `APPEND_STEP`
  teach the warm route and render the split; `- **Routing**:` is written on the
  member block (`polish-judge.sh:301`).
- `help/polish.md` + `DOCUMENTATION.md` — document warm routing, cap, gate, and
  the `FILED — n (x → next/, y → backlog/)` verdict.

### Remaining work
Round-1 rework: the single-piece judge is correct, but `plan polish` — which
routes every member through the same `polish-judge.sh` and so can warm-route into
`next/` — still hardcodes a backlog-only rollup. Confirmed still stale in the
current code:
- `plan-polish.sh:283` — "Done:" summary hardcodes `($FILED_TASKS enhancement
  task(s) → backlog/)`; replace with the real split read from each member's
  `- **Routing**:` field. Aggregate that field in the EXEC loop (`:271` reads
  only `Tasks filed`).
- `plan-polish.sh:285` — review pointer sends only to `chat backlog`; also point
  at `next/` when any member was warm-routed.
- `plan-polish.sh:207-208` and `:226-227` — emit prompts still assert filed
  enhancements "land in docs/tasks/backlog/; nothing was reopened or moved,"
  contradicting the `_rules` fragment they inject. State the backlog default with
  up to 1–2 per member warm-routed into `next/`.
- `lib.sh:2141` (`sprintbias_excellence_rules`) — verdict contract ends `FILED —
  <n> enhancement task(s)` with no split; carry `(<x> → next/, <y> → backlog/)`
  so fan-out subagents state the same verdict shape as the protocol.
- Re-run `./sprint.sh validate --commands` / `--docs` and `./ship.sh` to mirror
  `plan-polish.sh` + `lib.sh` into `src/` and bump the version.

### Questions for the developer
None — task is fully defined.

## Completed

Built the warm-route lane: the excellence deep-judge now makes a per-finding
routing decision instead of dumping every enhancement into `backlog/`. Default
stays `backlog/`; the vital-few, act-now findings are promoted into `next/`
through the same workability gate the sweep and `plan start` use — capped, gated,
and counted from both queues. Serialized cleanly on top of 376's unified
`## Excellence` block: the new `Routing` field is a separate composable line
alongside 376's `Correctness` field, rendered from the one shared spec.

**What changed**

- **`ai/audit-excellence.md` — the routing bar.** Added a "Where a filed task
  lands" subsection under Severity and Routing: `backlog/` is the default; the
  vital few rated BOTH high-confidence AND high-value ("a senior engineer would
  act now") may be warm-routed to `next/` via `promote-to-sprint.sh` — never a
  raw `git mv`, never the reopening of the audited task. Two hard limits are
  explicit: a **cap of 1–2 per audit** (a third urgent-feeling finding is the
  signal to stop) and a narrow "act now means genuinely act-now, when in doubt
  backlog/" guard. Report Format's FILED lines now mark destination and the
  `VERDICT:` line carries the `n (x → next/, y → backlog/)` split.
- **`lib.sh` — one field spec, extended once.** `sprintbias_excellence_block`
  gained a `routing` field (arg 5, between `tasks_filed` and `files_reviewed`),
  so both run paths render the split identically and it cannot drift. The
  `sprintbias_excellence_rules` fragment (used by `plan polish` emit fan-out)
  now states the warm-route default/cap/gate and the routing field.
- **`polish-judge.sh` — count both queues, render the split.** Replaced the
  backlog-only `_backlog_count` diff (which nets a warm-routed task to zero) with
  `_dir_count` over BOTH `backlog/` and `next/`, before/after the run, yielding
  `NEXT_FILED` + `BACKLOG_FILED` = `FILED_COUNT` and a `ROUTING` string. Step 4
  of the prompt teaches the warm-route command, the 1–2 cap, and the "when in
  doubt backlog/" bar; step 5's verdict shows the split; the emit `APPEND_STEP`
  renders the block with a routing placeholder the orchestrator fills. The FILED
  echo, the UNCLEAR echo, and the aborted note all report the split.
  `_dir_count` uses `find` (not a glob) and both queue dirs are `mkdir -p`'d, so
  an empty `next/` — the common case — yields 0 instead of a non-matching glob
  that would trip `set -o pipefail`.
- **`help/polish.md` + `DOCUMENTATION.md`.** Document warm routing, the cap, the
  gate path, the new `routing:` field, and the `FILED — n (x → next/, y →
  backlog/)` verdict.

**Verification**

- `bash -n` clean on `lib.sh` and `polish-judge.sh`.
- `sprintbias_excellence_block` renders the `Routing` field correctly for both a
  warm-route split and the nothing-filed (`—`) case.
- Counter simulated: file 3 in `backlog/`, promote 1 into `next/` → total 3,
  next 1, backlog 2 (the exact undercount the old backlog-only diff produced,
  now fixed).
- Confirmed the pipefail hazard was real (empty/missing dir tripped `set -e`
  under the ls-glob) and that the `find` + `mkdir -p` fix survives empty and
  missing dirs.
- Emit-mode acceptance (`SPRINTBIAS_MODE=emit`): the rendered prompt carries the
  warm-route step 4, the split verdict in step 5, and the `## Excellence` block
  with a `Routing` placeholder — all consistent with the headless path;
  `correctness: unverified` still derives correctly (no `## Audit`).
- `./sprint.sh validate --commands` and `--docs`: clean, no drift.
- `./ship.sh`: mirrored the 5 files to `src/`, `src/` byte-clean, version
  0.0.112 → 0.0.113.

### Files changed
docs/sprintbias/lib.sh
docs/sprintbias/scripts/polish-judge.sh
docs/sprintbias/ai/audit-excellence.md
docs/sprintbias/help/polish.md
DOCUMENTATION.md
src/docs/sprintbias/lib.sh
src/docs/sprintbias/scripts/polish-judge.sh
src/docs/sprintbias/ai/audit-excellence.md
src/docs/sprintbias/help/polish.md
src/DOCUMENTATION.md
src/VERSION

## Rework (round 1)

**Why:** The single-task judge (`polish <id>`) is correct, but `plan polish` —
which routes every member through the same `polish-judge.sh` and so *can*
warm-route findings into `next/` — never learned about the split. Its aggregate
summary hardcodes all filed tasks as backlog-bound
(`plan-polish.sh:283`: `($FILED_TASKS enhancement task(s) → backlog/)`), its
review pointer sends the operator only to `chat backlog` (`plan-polish.sh:285`),
and its emit prompts assert "Filed enhancements land in docs/tasks/backlog/;
nothing was reopened or moved" (`plan-polish.sh:207-208`, `:226-227`) while the
`_rules` fragment they inject (`lib.sh:2122`, `sprintbias_excellence_rules`)
tells the very same subagents to warm-route into `next/`. This is the exact
failure the task's own alignment pass flagged — an inaccurate FILED summary that
quietly hides the warm-routed win — caught for the single-task counter but missed
for the plan rollup. The per-member `## Excellence` blocks are correct; only the
plan-scoped rollup and its prompts are stale.

**Improve:**
- [x] In `plan-polish.sh` EXEC loop, aggregate the `- **Routing**:` field
      (already written on each member's `## Excellence` block) alongside the
      existing `- **Tasks filed**:` read, so the pass tracks how many filed tasks
      went to `next/` vs `backlog/` across members.
- [x] Replace the hardcoded `($FILED_TASKS enhancement task(s) → backlog/)` in
      the `plan-polish.sh:283` "Done:" summary with the real split (e.g.
      `3 enhancement task(s) — 1 → next/, 2 → backlog/`), and update the
      `chat backlog` review pointer (`:285`) to also point at `next/` when any
      task was warm-routed.
- [x] Fix the emit-path orchestrator prompts (`plan-polish.sh:207-208` and
      `:226-227`): drop the "nothing was moved / land in backlog/" claim and
      state that filed tasks default to `backlog/` with up to 1–2 per member
      warm-routed into `next/`, consistent with the injected `_rules`.
- [x] Align the verdict contract in `sprintbias_excellence_rules`
      (`lib.sh:2141`) with the protocol's FILED line — carry the
      `(<x> → next/, <y> → backlog/)` split — so the plan fan-out subagents state
      the same verdict shape the single-piece judge and the protocol require.
- [x] Re-run `./sprint.sh validate --commands` / `--docs` and `./ship.sh` to
      mirror the `plan-polish.sh` + `lib.sh` changes into `src/` and bump the
      version.

**Done (rework round 1):** The plan rollup now reads each member's
`- **Routing**:` field, aggregating `NEXT_TASKS`/`BACKLOG_TASKS` in the EXEC
loop; the "Done:" summary renders the real split when any task was warm-routed
(plain `→ backlog/` otherwise), and the review pointer sends the operator to
`chat next` as well as `chat backlog` in that case. The keyword-anchored parse
(`[0-9]+[^0-9]+next/` / `…backlog/`) is locale-independent — verified under
`LC_ALL=C` against the multibyte `→`, and against the `—` nothing-filed case
(nets 0/0). Both emit-path prompts now state the backlog-default + 1–2 warm-route
rule and ask for the split, matching the injected `_rules`; the
`sprintbias_excellence_rules` verdict contract carries the split too. `bash -n`
clean; `validate --commands`/`--docs` clean; `./ship.sh` mirrored
`plan-polish.sh` + `lib.sh` to `src/`, version 0.0.114 → 0.0.115.


## Excellence

- **Date**: 2026-08-27
- **Verdict**: FILED
- **Correctness**: unverified
- **Tasks filed**: 1
- **Routing**: 0 → next/, 1 → backlog/
- **Files reviewed**: 10
- **Context source**: task ## Completed section
- **Code state**: 37c9a803eed48f29

Task 377 adds a warm-route lane to the excellence deep-judge: enhancement findings default to `backlog/`, but the vital few rated act-now can be promoted into `next/` through the shared `promote-to-sprint.sh` gate, capped at 1–2 per audit, with the split counted from both queues and rendered from one shared `## Excellence` spec. The work meets its bar — the design is clean (directory-diff counting measures where tasks *actually* landed, so it stays correct even if the gate rejects a promotion; the shared `sprintbias_excellence_block` field set prevents drift between run paths; docs are thorough and consistent across `help/polish.md`, `DOCUMENTATION.md`, the protocol, and the `lib.sh` rules fragment). Correctness state was **unverified** (no `## Audit` marker); I found no defect while tracing the path. The one altitude gap: the 1–2 cap that makes the whole warm lane trustworthy is purely prose-advisory — the shell already computes the warm-route count but never signals when a run exceeds it.

### Findings
- [ENHANCEMENT] Warm-route cap (1–2) has no shell backstop or observability signal; `polish-judge.sh:272` computes `NEXT_FILED` but never compares it to the cap, and `plan-polish.sh:295/310` rolls it up with the same blind spot — an over-cap run looks identical to a compliant one. FILED → backlog/.
- [NIT] plan-polish.sh aggregates the split by re-parsing the rendered `Routing` string it already emitted as integers upstream (`plan-polish.sh:292-296`); keyword-anchored and locale-tested, so acceptable, but a render-then-reparse coupling. Not filed.
- [NIT] A plan containing both pre-feature `## Excellence` blocks (no `Routing` field) and new ones can make the rollup's split undercount the total (`NEXT_TASKS + BACKLOG_TASKS < FILED_TASKS`); narrow transition-window edge, degrades gracefully. Not filed.
- FILED → backlog/: docs/tasks/backlog/380-add-a-shell-side-observability-signal-when-an-exce.md (default)
