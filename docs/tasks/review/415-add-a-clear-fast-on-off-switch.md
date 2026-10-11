# Task 415: Add a clear fast on/off switch

**Feature**: none
**Created**: 2026-10-10
**Docs**: none
**Plan**: 30
**From plan**: none
**Depends on**: none
**Dependents**: 416, 417
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-fast.sh
**Refined**: 0
**Reworked**: 0

## Problem

People cannot tell agents "go" and later "slow down". There is no single setting for an autonomous, high-throughput mode, and no way to see which mode a session runs in. Fast mode (also called dangerous mode) needs one clear on/off switch that every AI command reads.

## Done when (automated)

- [x] `./sprint.sh fast on` and `./sprint.sh fast off` write `FAST=on` / `FAST=off` to docs/sprintbias/config.local (creating it when absent, leaving the tracked config untouched); bare `./sprint.sh fast` prints the current state and how to flip it (`bash docs/tests/test-fast.sh`)
- [x] Leading `--fast` / `--steady` (`./sprint.sh --fast chat 12`) override the setting for that run only, without rewriting config.local; `work --fast` and `polish --fast` also turn fast on for their run and keep their 4-job parallel behavior (`bash docs/tests/test-fast.sh`)
- [x] A lib.sh helper (`sprintbias_fast_on`) is the one place scripts read the mode: per-run flag / env SPRINTBIAS_FAST → config.local → config; default off (`bash docs/tests/test-fast.sh`)
- [x] Every AI session's provider banner (`sprintbias_announce_provider`) and `./sprint.sh status` show `fast: on` or `fast: off` (`bash docs/tests/test-fast.sh`)
- [x] `fast` is in help/_registry with help/fast.md, DOCUMENTATION.md, and docs/guides/command-matrix.md; `./sprint.sh validate --commands` and `./sprint.sh validate --docs` pass
- [ ] `bash docs/tests/run-all.sh` passes

## Signoff (human)

- [ ] Flip fast on and off; the banner on the next `chat` session says which mode it is in, at a glance

## Notes

Decided with the human (2026-10-10): top-level word `fast on|off`, stored per machine in config.local (never ships), because trust is a property of the machine. Steady is the name for off. The setting governs decisions, permissions and parallelism together; those behaviors land in #416 and #417.

## References

docs/sprintbias/config
docs/sprintbias/scripts/config.sh
docs/sprintbias/lib.sh
docs/sprintbias/help/_registry
sprint.sh
docs/sprintbias/scripts/work.sh
docs/sprintbias/scripts/polish.sh
src/.gitignore.template

## Grounding

**Sources:** `CLAUDE.md` / `CONTRIBUTING.md` (repo map, what ships, surfaces kept in step), `docs/sprintbias/help/_registry` (command catalog, source of truth), `docs/guides/command-matrix.md` (command surfaces), `docs/sprintbias/lib.sh` (config reader `sprintbias_cfg`, banner `sprintbias_announce_provider`), `docs/sprintbias/config` / `config.local` (settings; local wins, gitignored via `src/.gitignore.template`), `sprint.sh` (leading global flags, dispatch, `cmd_status`), `docs/plans/30-fast-mode-autonomous-agents-fewer-blockers.md` (plan policy)
**Terms:**
- None. The project has no glossary.
**Conflicts:**
- `--fast` already exists on `work` and `polish` meaning "4 parallel jobs" → keep that behavior and also set fast on for the run; plan 30 says fast mode absorbs the old `--fast`, and #416 makes fast on imply parallel.
- Task named `docs/sprintbias/tests/test-fast.sh`, but the suite lives in `docs/tests/` (run by `run-all.sh`; `docs/sprintbias/tests/` holds only the learn sandbox) → write `docs/tests/test-fast.sh`.
- Precedence listed "env → per-run flag" as separate steps → a flag exports `SPRINTBIAS_FAST` for the run, the same way `-c`/`-g` export `SPRINTBIAS_CLI`, so flag and env are one tier above config.local.
- `sprintbias_cfg_set` writes only the tracked config → `fast on|off` needs a write to config.local (a small local-writer helper or a parameter on the existing one).
- "Fast mode" is new vocabulary with no glossary entry → read it as the plan 30 Goal defines it; "steady" names off. DOCUMENTATION.md gets a short entry when the command lands.
**Touching:** sprint.sh, docs/sprintbias/lib.sh, docs/sprintbias/config, docs/sprintbias/scripts/fast.sh (new), docs/sprintbias/scripts/work.sh, docs/sprintbias/scripts/polish.sh, docs/sprintbias/help/_registry, docs/sprintbias/help/fast.md (new), docs/sprintbias/help/work.md, docs/sprintbias/help/polish.md, DOCUMENTATION.md, docs/guides/command-matrix.md, docs/tests/test-fast.sh (new), CHANGELOG.md

## Questions

**Status: READY**

### Already complete
None — no matching implementation found. Checked:
- `sprint.sh` leading-flag loop (~line 471) handles only `-c/--claude`, `-g/--grok`, `-h`; no `fast` dispatch case; `cmd_status` (~line 196) prints no mode.
- `lib.sh`: no `FAST` key or `sprintbias_fast_on`; `sprintbias_cfg` already reads config.local over config (line 403); `sprintbias_cfg_set` (line 412) writes only the tracked config; `sprintbias_announce_provider` (line 2861) prints provider/tier/mode/model, no fast state.
- `work.sh` (lines 61, 122) and `polish.sh` (line 72) parse `--fast` as `PARALLEL=1; MAX_JOBS=4` only.
- `config` has no `FAST=`; `help/_registry` has no `fast` row; no `help/fast.md`.
- `src/.gitignore.template` line 40 already ignores `docs/sprintbias/config.local` in installed projects.

### Remaining work
- `fast` command: `on` / `off` write `FAST=` to config.local; bare form prints state plus the flip commands.
- `sprintbias_fast_on` in lib.sh with the precedence above; every script reads the mode through it.
- Leading `--fast` / `--steady` in sprint.sh export `SPRINTBIAS_FAST` for the run; `work --fast` / `polish --fast` export it as well.
- `fast: on|off` in the provider banner and `./sprint.sh status`.
- Add `FAST=off` with a one-line comment to docs/sprintbias/config.
- Registry row, help/fast.md, DOCUMENTATION.md, command-matrix entry; mention `--steady` in work/polish help where `--fast` appears.
- New `docs/tests/test-fast.sh` on a temp board covering set, read, precedence, per-run override, banner and status.
- One `### Added` bullet in CHANGELOG.md under Unreleased.

### Questions for the developer
None — task is fully defined.

## Test log

- `bash docs/tests/run-all.sh` → 28/29 scripts pass; `test-proof-loop.sh` fails Test 5 (7 asserts: "Orchestrated emit: fresh subagents", "Sequential emit: one at a time", …). work.sh emit now gates the ungated fixture first ("▸ 1 task(s) in docs/tasks/next not yet gated — gating them first"), so the work prompt never prints. It fails the same way on a copy of the tree with this task's edits removed, so it is not caused by this task. `test-proof-loop.sh` is untracked (another agent's work). Left as is.
- `bash docs/tests/test-command-matrix-smoke.sh` → once 162/164 standalone, then 164/164 on three re-runs and inside run-all. Flaky; failing asserts not captured.

## Completed

`./sprint.sh fast [on|off]` is the switch: on/off write `FAST=` to `docs/sprintbias/config.local` through `sprintbias_cfg_set`, which now takes an optional target file. Bare `fast` prints the state, where it comes from, and how to flip it. `sprintbias_fast_on` / `sprintbias_fast_state` in lib.sh read it in this order: `SPRINTBIAS_FAST` → config.local → config → off. A leading `--fast` / `--steady` exports `SPRINTBIAS_FAST` for the run. `work --fast` / `polish --fast` keep 4 jobs and export it on; `--steady` exports it off. The provider banner ends with `· fast: on|off`, and `status` shows a `Mode:` line at the top. The tracked config ships `FAST=off`.

### Assumptions
- Accepted values for on: `on`, `1`, `true`, `yes` (`on` is case-insensitive); anything else reads as off.
- `work` / `polish` also accept `--steady` (fast off for the run), to match the leading flag and keep help and script flags in step.
- The `fast` help text describes on as "agents decide and keep going" and steady as "agents stop to ask". The behaviors behind those words land in #416 / #417.

### Files changed
- sprint.sh
- docs/sprintbias/lib.sh
- docs/sprintbias/config
- docs/sprintbias/scripts/fast.sh
- docs/sprintbias/scripts/work.sh
- docs/sprintbias/scripts/polish.sh
- docs/sprintbias/help/_registry
- docs/sprintbias/help/fast.md
- docs/sprintbias/help/work.md
- docs/sprintbias/help/polish.md
- DOCUMENTATION.md
- docs/guides/command-matrix.md
- docs/tests/test-fast.sh
- CHANGELOG.md

### Doc follow-ups
- `docs/tests/test-proof-loop.sh` — Test 5's fixture is ungated, so work.sh emit gates instead of printing the work prompt; its owner should gate the fixture (or set it as already gated) so the full suite is green.

Tests run: `bash docs/tests/test-fast.sh` (33/33), `bash docs/tests/test-sprint.sh` (30/30), `bash docs/tests/test-command-matrix-smoke.sh` (164/164), `bash docs/tests/test-no-stale-refs.sh` (18/18), `./sprint.sh validate --commands`, `./sprint.sh validate --docs` — all pass. Full suite: 28/29, the one failure is pre-existing (see Test log).

**Proof**: 2026-10-10 · bash docs/tests/test-fast.sh; bash docs/tests/test-sprint.sh; bash docs/tests/test-command-matrix-smoke.sh; ./sprint.sh validate --commands; ./sprint.sh validate --docs · pass
