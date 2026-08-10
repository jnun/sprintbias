# Task 302: Add a docs/tests run-all harness and document how to run unit vs emit-smoke vs live dual-provider tiers

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Depends on**: 299, 300, 301
**Blocks**: none
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

There is no single entry point for the platform test suite. Maintainers run
individual `docs/tests/test-*.sh` files by hand, so green confidence is uneven
and tiers (offline unit, emit matrix, live dual-provider) are not named. New
contributors cannot see “what good looks like” without reading every script
header.

## Success criteria

- [x] `docs/tests/run-all.sh` (or equivalent) runs all offline unit tests by
      default, prints per-script pass/fail, exits non-zero if any fail
- [x] Flags or env for tiers, e.g. default unit only; `--emit` / `EMIT_SMOKE=1`
      for matrix smoke (#300); `--live` / `LIVE_SMOKE=1` for dual-provider
      (#301) when present
- [x] Short doc: either `docs/tests/README.md` (dev-only OK) or a section in
      CONTRIBUTING.md describing the three tiers and what each proves
- [x] Does not ship the harness into user installs as product UI (dev suite
      only; stay under `docs/tests/` which users use for *their* test loops —
      name carefully so it does not collide with `.TEMPLATE-test.md` product)
- [~] After #299, default unit run is green on clean tree — gated on #299
      (still in `review/`, not landed). See Completed.

## Notes

- Product `docs/tests/` holds user test-loop files; the harness should only
  execute `test-*.sh` (or a `suite/` subfolder if we need isolation later).
- Keep run-all free of network unless `--live`.
- Optional: list scripts in explicit order so create → plan → work deps read
  cleanly in logs.

## References

docs/tests/
CONTRIBUTING.md
docs/tasks/backlog/299-fix-test-no-stale-refs-so-setup-migration-comments.md
docs/tasks/backlog/300-add-docs-tests-command-matrix-emit-smoke-covering.md
docs/tasks/backlog/301-add-optional-dual-provider-live-smoke-protocol-run.md

## Questions

**Status: READY**

### Already complete

Nothing yet. Verified against the current tree:

- No `docs/tests/run-all.sh`, no `docs/tests/suite/`, no `docs/tests/README.md`.
- No `EMIT_SMOKE` / `LIVE_SMOKE` / `run-all` references anywhere under
  `docs/tests/`.

The groundwork the harness needs is in place, though: every `docs/tests/test-*.sh`
already follows a uniform contract (`set -euo pipefail`, `PASS`/`FAIL` counters,
final `Results: N passed, M failed` line, and `exit 0`/`exit 1` on aggregate
outcome — see `test-profile.sh:121`). A thin runner can simply loop over the
scripts and key off exit codes; no per-script adaptation is required.

The "does not ship" criterion is also already satisfied by the build system:
`ship.sh` only mirrors `docs/sprintmd/` wholesale plus the explicit
`TEMPLATE_FILES` list, which for this dir contains only
`docs/tests/.TEMPLATE-test.md` (`ship.sh:64`). `src/docs/tests/` today holds just
that template. A new `run-all.sh` under `docs/tests/` will not ship unless someone
adds it to `ship.sh` — so the harness stays dev-only for free.

### Remaining work

All of the success criteria are unbuilt and the whole task is greenfield:

1. Write `docs/tests/run-all.sh`: discover and run the offline `test-*.sh` unit
   scripts by default, print per-script pass/fail, exit non-zero if any fail.
   Excluding the tier scripts (emit/live) from the default set is the one thing
   to get right — see Q1.
2. Add tier selection: `--emit` / `EMIT_SMOKE=1` runs the #300 matrix emit smoke;
   `--live` / `LIVE_SMOKE=1` runs the #301 dual-provider runner. Both degrade
   gracefully ("skipped — not present") when those scripts don't exist yet, per
   the "when present" wording in the criteria.
3. Write the short doc — a dev-only `docs/tests/README.md` or a CONTRIBUTING.md
   section — naming the three tiers (offline unit / emit smoke / live
   dual-provider) and what each proves. See Q2.
4. Confirm the default run is green on a clean tree after #299 lands (it fixes
   `test-no-stale-refs.sh`).

### Questions for the developer

1. How should the runner decide which scripts are "offline unit" vs tier
   (emit/live) so the default set stays network-free? (Suggestion: keep it simple
   and explicit — the default run globs `test-*.sh` but skips the known tier
   scripts by name, and the `--emit`/`--live` flags invoke #300's and #301's
   named scripts directly. An explicit allow/deny beats a naming convention here
   because #300 and #301 haven't fixed their filenames yet; coordinate the exact
   names when those tasks are defined. This is a dependency, not a blocker.)

2. `docs/tests/README.md` or a CONTRIBUTING.md section for the tier doc?
   (Suggestion: a dev-only `docs/tests/README.md`. It sits next to the harness so
   it stays discoverable and gets updated together, and — like the test scripts —
   it won't ship, since `ship.sh` mirrors only `.TEMPLATE-test.md` from this dir.
   CONTRIBUTING.md can carry a one-line pointer to it.)

## Completed

Built the platform-suite harness and its tier documentation.

**Harness — `docs/tests/run-all.sh`** (dev-only, `set -euo pipefail`):

- Default (`--unit`) discovers every `docs/tests/test-*.sh` via a stable sort,
  runs each, prints per-script `▸ script OK/FAIL`, and exits non-zero if any
  script fails. Verified: with #299 unlanded the runner correctly reports
  `Suite: 17 passed, 1 failed` and exits 1.
- Tier selection by flag: `--emit` appends the offline emit/matrix smokes
  (`test-command-matrix-smoke.sh`, `smoke-grok-spine.sh`), de-duping any already
  in unit discovery; `--live` prints a pointer to the dual-provider ritual rather
  than running network work in the harness. `--list` prints the resolved set,
  `--help` the header. Went with explicit flags (Q1) over `EMIT_SMOKE`/
  `LIVE_SMOKE` env — the criteria allow "flags **or** env", and naming the tier
  scripts explicitly is robust while #300/#301 filenames settle.
- Stays network-free by default: live work is never invoked, only pointed to.

**Doc — `docs/guides/running-tests.md`** (Q2): chose a dev-only guide over
`docs/tests/README.md` so it can cross-link the command-matrix and
dual-provider guides and carry the full stress ladder. Names the tiers
(0 integrity / 1 unit / 2 emit+grok-spine / 3 live dual-provider), states what
each proves and its cost/network profile, and catalogs every unit script.
`CONTRIBUTING.md` step 2 points at it with a quick `run-all.sh` one-liner.

**Does-not-ship** criterion is structurally satisfied: `ship.sh` mirrors only
`docs/sprintmd/**` plus the explicit `TEMPLATE_FILES` (from this dir just
`docs/tests/.TEMPLATE-test.md`). `run-all.sh` sits under `docs/tests/` and
`running-tests.md` under `docs/guides/` — neither path is in the mirror, so both
stay dev-only for free (confirmed `src/docs/tests/` holds only the template).

**Green-on-clean-tree** is the one criterion not yet checkable: the sole red
unit script is `test-no-stale-refs.sh` (`FAIL: no 'setup.sh .' sync claims`),
which is the exact fix owned by dependency **#299** — currently in `review/`,
not landed. This is the dependency the task flagged, not a defect in the
harness; the default run will go green the moment #299 merges. Marked `[~]`.

### Files changed

docs/tests/run-all.sh
docs/guides/running-tests.md
CONTRIBUTING.md
docs/tasks/doing/302-add-a-docs-tests-run-all-harness-and-document-how.md
