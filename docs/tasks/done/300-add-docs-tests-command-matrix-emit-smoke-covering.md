# Task 300: Add docs/tests command-matrix emit smoke covering all matrix commands with -g/-c and provider banner

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Depends on**: 299
**Blocks**: 301, 302
**Parent**: none
**Refined**: 0
**Reworked**: 1

## Problem

Unit tests cover scripts in isolation with stubs. There is no checked-in test
that walks **every command in `docs/guides/command-matrix.md`**, proves leading
`-g` / `-c` are accepted, and asserts the provider banner on AI paths under
`SPRINTMD_MODE=emit`. Session dogfood already proved this once; without a
committed test it will rot.

## Success criteria

- [x] New script under `docs/tests/` (e.g. `test-command-matrix-smoke.sh`) runs
      in a sandbox and needs **no network / no live CLI**
- [x] Covers every matrix command (create / chat / plan / work / look / keep)
      plus polish modes (`sweep`, `--code`, file deep-judge) where cheap
- [x] Asserts: `-g`/`-c` never “Unknown option”; AI paths print
      `▸ Provider: … (…-build) · mode: emit`; non-AI paths do **not** print it
- [x] Intentional short-circuits documented in the test (e.g. healthy `chat`
      with zero findings, `plan start --commit-only`, empty `deps` tree)
- [x] Fixtures seed templates, READY tasks, a plan for gate path, package.json
      for deps, hash-prefixed Depends on for chat-sprint findings
- [x] Exit non-zero on any failure; printable summary counts

## Notes

- Reuse the 2026-07-30 session harness as the design (38 cases, sandbox + emit).
- Prefer one file over many; keep under ~2–3 minutes wall time.
- Does **not** replace live dual-provider smoke (#301 / #296 / #297).

## References

docs/guides/command-matrix.md
docs/tests/test-sprint.sh
docs/tests/test-grok-provider.sh
docs/sprintmd/lib.sh
sprint.sh

## Completed

Authored `docs/tests/test-command-matrix-smoke.sh` — a network-free, no-live-CLI
sandbox smoke that walks every command in `docs/guides/command-matrix.md` under
`SPRINTMD_MODE=emit`, running each once with a leading `-g` and once with `-c`.
**136 assertions, all passing, ~21s wall time.**

Design (modeled on `test-sprint.sh` + `test-grok-provider.sh`):

- **One framework copy, cheap per-case reseeds.** `build_framework()` copies the
  whole `docs/sprintmd/` tree + root `sprint.sh` + templates once; `seed_fixtures()`
  resets the small work-item files before each case so a command that mutates in
  bash (`plan start --commit-only`, `deps` filing a task) can't leak state.
- **Fixtures**: task templates; a READY task in `next/` (work/split target); a
  READY task with a hash-prefixed unmet `Depends on: #999` (chat-sprint shape);
  an ungated `next/` task (so `gate` has something to review); a backlog task
  (so `gate <folder>` reports); a `review/` task (polish sweep + deep-judge); a
  plan (think/start/chat plan); a bug (chat bugs); a `package.json` + committed
  `app.js` (deps + `polish --code`).
- **Network-free `deps`**: a stub `npm` on `PATH` lets `deps` reach its AI half
  without touching the registry (deps gates each check on binary presence and
  swallows output).
- **Three invariants per command**: leading `-g`/`-c` never rejected as "Unknown
  option"; AI paths announce `▸ Provider: <cli> (<tier>) · mode: emit` with the
  correct tier per flag; non-AI paths (create / status / search / …) never
  announce it. Exits non-zero on any failure with a printable summary count.
- **Intentional short-circuits documented inline**: `plan start --commit-only`
  (pure mv, no AI → no banner), `plan done` on an unfinished plan (bash refusal),
  and the empty-`deps`-tree / empty-`polish --code`-arg paths that the fixtures
  deliberately avoid.

Coverage note: the matrix's `work count N` is documented target-state; the live
cap form is a bare number (`work 1`), which the test exercises — annotated inline
and consistent with the matrix's own "Live surface lag" section.

Ship note: `docs/tests/` is **not** under `docs/sprintmd/` and is dev-internal;
only `.TEMPLATE-test.md` ships (`ship.sh` `TEMPLATE_FILES`). The new `test-*.sh`
does **not** ship, consistent with every other test in the folder — no `ship.sh`
run needed.

### Files changed
docs/tests/test-command-matrix-smoke.sh
docs/tasks/doing/300-add-docs-tests-command-matrix-emit-smoke-covering.md

## Rework (round 1)

**Why:** The Problem statement and Success criteria demand the test walk
**every** command in `docs/guides/command-matrix.md`, but two named commands
are absent from `docs/tests/test-command-matrix-smoke.sh`: `promote` (work
family, matrix line 110) and `sync` (keep family, matrix line 163). Both exist
in the live registry and `sprint.sh` dispatch (`cmd_promote`/`cmd_sync`), so
the leading-`-g`/`-c` + no-banner contract on those two paths currently rots
untested — the exact regression this test exists to prevent. Both are
confirmed pure-shell, non-AI, network-free short-circuits in the sandbox
(`promote.sh` header: "Pure shell, NO AI" — task 61 has no `Tests` field, so it
stays in `review/` and exits 0; `sync.sh:31` exits 1 on "No 'origin' remote"
before any commit/push), so each is a cheap `expect_noai` case.

**Improve:**
- [x] Add `expect_noai "promote" promote` to the keep/work section and document
      the intentional short-circuit inline (review/ task carries no `Tests`
      field → promote leaves it in place, no AI, exit 0).
- [x] Add `expect_noai "sync" sync` and document its short-circuit inline (the
      sandbox git repo has no `origin` remote, so `sync` refuses before any
      network access — non-AI bash refusal, no banner).
- [x] Update the header comment / `## Completed` claim so "walks every command
      in the matrix" is accurate once both are covered (bump the assertion
      count in the summary note if you keep one).
      Also covered matrix-new `settle` as `expect_noai` (pure shell open-Q
      accept; fixture already clear → no-op). Full suite: **156 assertions,
      0 failed** (`bash docs/tests/test-command-matrix-smoke.sh`).

## Questions

**Status: READY**

### Already complete

The main deliverable is done and verified against the current code:

- `docs/tests/test-command-matrix-smoke.sh` exists — a network-free, no-live-CLI
  sandbox smoke under `SPRINTMD_MODE=emit`. It copies the whole `docs/sprintmd/`
  tree + root `sprint.sh` once, reseeds fixtures per case, and stubs `npm` so
  `deps` reaches its AI half offline. Clean, well-commented, self-contained.
- The three invariants per command are correctly implemented: `assert_flag_ok`
  (no "Unknown option" for leading `-g`/`-c`), `assert_banner` (tier-correct
  `▸ Provider: <cli> (<tier>) · mode: emit`), `assert_no_banner` (non-AI paths
  silent). Tier strings match `lib.sh` — `-g` → `grok (grok-build)`, `-c` →
  `claude (claude-code)` — confirmed against `sprintmd_ai_tier` mappings.
- Coverage of the target catalog is complete: create ×6, chat ×5, plan ×3,
  work/gate/split/loop/promote/settle, polish ×3, look ×5, keep (profile,
  profile show, sync, validate, cleanup, deps, model show/list) are all present.
- Intentional short-circuits are documented inline (`plan start --commit-only`,
  `plan done` on an unfinished plan, empty `deps`/`--code` paths) — matches the
  success criteria.

### Remaining work

None — rework round 1 applied. `promote`, `sync`, and matrix-new `settle` are
`expect_noai` cases with inline short-circuit notes. Suite green:
`156 passed, 0 failed`.

`docs/tests/` is dev-internal and does not ship, so no `./ship.sh` run is needed
(consistent with every other `test-*.sh`).

**Depends on 299** (recorded in the header) — 299 greens the suite this test
joins. Sequencing only; the runner holds this task in `next/` until 299 reaches
review/ or done/, then runs it. Not a definition blocker.

### Questions for the developer

None — task is fully defined. The rework items are concrete, the two target
commands are confirmed pure-shell short-circuits, and the pattern to add them
(`expect_noai`) already exists in the file.
