# Task 416: Fast mode skips permission prompts and runs work in parallel

**Feature**: none
**Created**: 2026-10-10
**Docs**: none
**Plan**: 30
**From plan**: none
**Depends on**: 415
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-fast.sh
**Refined**: 0
**Reworked**: 0

## Problem

In fast mode agents still stop for the AI CLI's permission prompts, and parallel work needs a separate `--fast` flag on work and polish that means only "4 jobs". The word fast means two different things, and an autonomous run still waits on the person.

## Done when (automated)

- [x] With fast on, interactive and exec runs pass `--skip-permissions` (Claude: --dangerously-skip-permissions; Grok: --always-approve); with fast off they keep `--permissions auto` (`bash docs/tests/test-fast.sh`)
- [x] With fast on, `work` and `polish` run in parallel at 4 jobs without a flag; `--jobs N` still sets an explicit count and `--steady` runs sequentially (`bash docs/tests/test-fast.sh`)
- [x] The old `work --fast` / `polish --fast` keep working as the per-run override from #415, so existing scripts do not break (`bash docs/tests/test-fast.sh`)
- [x] docs/guides/provider-reality.md records the skip-permissions flag per provider; help/work.md and help/polish.md describe fast as the mode; DOCUMENTATION.md says fast is safest on a dev server or a clean git tree (`./sprint.sh validate --docs`)
- [ ] `bash docs/tests/run-all.sh` passes

## Signoff (human)

- [ ] Run `./sprint.sh work` with fast on in a scratch project; no permission prompt appears and independent tasks run at once

## Notes

Decided with the human (2026-10-10): fast skips permission prompts (true dangerous mode) and absorbs the old --fast. Human-owned actions stay walled by rule, not by prompt: commit, push, ship.sh, done/ sign-off, production credentials. The manual says plainly that fast is safest on a dev server or a clean git tree.

## References

docs/sprintbias/cli/claude.sh
docs/sprintbias/cli/grok.sh
docs/sprintbias/scripts/work.sh
docs/sprintbias/scripts/polish.sh
docs/guides/provider-reality.md
docs/sprintbias/lib.sh

## Grounding

**Sources:** `CLAUDE.md` / `CONTRIBUTING.md` (repo map, surfaces kept in step), `docs/plans/30-fast-mode-autonomous-agents-fewer-blockers.md` (fast-mode policy, human-owned invariants), `docs/sprintbias/lib.sh` (`sprintbias_run`, `sprintbias_run_interactive`, `sprintbias_emit_prompt`; `sprintbias_fast_on` arrives with #415), `docs/sprintbias/cli/claude.sh` / `grok.sh` / `default.sh` (provider flag translation), `docs/sprintbias/scripts/work.sh` / `polish.sh` (parallel flags), `docs/guides/provider-reality.md` (provider behavior record), `docs/sprintbias/help/work.md` / `help/polish.md`, `DOCUMENTATION.md`
**Terms:**
- None. The project has no glossary.
**Conflicts:**
- Done when named `docs/sprintbias/tests/test-fast.sh`, but the suite lives in `docs/tests/` and #415 creates `docs/tests/test-fast.sh` → extend `docs/tests/test-fast.sh`; paths above corrected.
- Every AI call site sets `--permissions auto` on its own (chat.sh, crew.sh, work.sh, polish.sh, gate-lib.sh, split.sh, promote.sh, plan-think.sh, deps.sh …) → apply fast at the shared run layer (`sprintbias_run` / `sprintbias_run_interactive` swap `--permissions X` for `--skip-permissions` when `sprintbias_fast_on`) so one place governs it; call sites stay as they are.
- `--steady` is new on `work` / `polish`; #415 adds leading `./sprint.sh --steady` → `work --steady` / `polish --steady` export the same steady override for the run and run sequentially (`PARALLEL=0`).
- "Fast mode" has no glossary entry → read it as plan 30's Goal defines it; DOCUMENTATION.md entry lands with #415/#417.
**Touching:** docs/sprintbias/lib.sh, docs/sprintbias/scripts/work.sh, docs/sprintbias/scripts/polish.sh, docs/tests/test-fast.sh, docs/guides/provider-reality.md, docs/sprintbias/help/work.md, docs/sprintbias/help/polish.md, docs/sprintbias/help/fast.md, DOCUMENTATION.md, CHANGELOG.md

## Questions

**Status: READY**

### Already complete
- Provider profiles already translate `--skip-permissions`: `cli/claude.sh` lines 307-308 and 484-485 add `--dangerously-skip-permissions`; `cli/grok.sh` lines 141-142 and 201-202 add `--always-approve`; `cli/default.sh` line 30 and `lib.sh` `sprintbias_emit_prompt` (line 2839) consume it. Clean; `--skip-permissions` wins over `--permissions` in both profiles.
- `work --fast` (work.sh lines 61, 122) and `polish --fast` (polish.sh line 72) already mean `PARALLEL=1; MAX_JOBS=4`; `--jobs N` validated in both.
- Nothing reads a fast setting yet: no `sprintbias_fast_on`, no `FAST` key (that is #415).

### Remaining work
- When `sprintbias_fast_on`, interactive and exec runs pass `--skip-permissions` instead of `--permissions auto`; fast off leaves today's flags untouched.
- When fast is on and no parallel flag is given, `work` and `polish` set `PARALLEL=1; MAX_JOBS=4`; `--jobs N` wins; `--steady` forces sequential. Keep polish's "ignored for $MODE mode" behavior for non-sweep modes.
- `work --fast` / `polish --fast` also turn fast on for the run (shared with #415 — reuse its export, do not duplicate).
- Update the work.sh interactive menu wording (lines 98-109) so option 2 reads as fast mode.
- Extend `docs/tests/test-fast.sh`: stub provider captures argv for fast on/off (claude and grok), and parallel defaults for work/polish with fast on, `--jobs N`, `--steady`.
- provider-reality.md: per-provider skip-permissions row; help/work.md and help/polish.md describe fast as the mode; DOCUMENTATION.md safety line; CHANGELOG `### Changed` bullet.

### Questions for the developer
None — task is fully defined.

## Completed

Fast mode now skips permission prompts and runs work/polish in parallel.

- `lib.sh`: `sprintbias_run` and `sprintbias_run_interactive` lead with
  `--skip-permissions` when `sprintbias_fast_on`; both profiles let it win over
  the call site's `--permissions`, so no call site changed. New
  `sprintbias_fast_parallel [STEADY]` settles `PARALLEL` / `MAX_JOBS` for both
  scripts: `--steady` → sequential; no parallel flag + fast on → 4 jobs;
  otherwise the flags stand.
- `work.sh` / `polish.sh`: `--steady` now also runs sequentially; `--jobs N`
  wins whatever its position (`--jobs 6 --fast` → 6). Polish applies the fast
  default to the sweep only, so judge / `--code` modes print no "ignored" note.
  `work --assist` menu reads 1) Steady (`--steady`), 2) Fast mode.
- Docs: provider-reality KK-18b, help work/polish/fast, DOCUMENTATION.md fast
  paragraph (safety line), CHANGELOG `### Changed`.

### Assumptions
- `work --jobs N` now turns parallel on by itself, as help/work.md already said
  ("run parallel with N concurrent jobs") and as polish already did; before, it
  only set the count.
- Fast mode applies to every AI call through the shared run layer, not only
  work/polish (chat, gate, plan think, crew …), per plan 30's "true dangerous
  mode".
- `work --assist` option 1 passes `--steady`, so "Steady" stays sequential even
  when the machine is in fast mode.

### Files changed
- docs/sprintbias/lib.sh
- docs/sprintbias/scripts/work.sh
- docs/sprintbias/scripts/polish.sh
- docs/sprintbias/help/work.md
- docs/sprintbias/help/polish.md
- docs/sprintbias/help/fast.md
- docs/guides/provider-reality.md
- DOCUMENTATION.md
- CHANGELOG.md
- docs/tests/test-fast.sh

Tests run: `bash docs/tests/test-fast.sh` (52/52), `bash docs/tests/test-grok-provider.sh` (75/75), `bash docs/tests/test-command-matrix-smoke.sh` (164/164), `bash docs/tests/test-sprint.sh` (30/30), `bash docs/tests/test-no-stale-refs.sh` (18/18), `bash docs/tests/test-dep-work.sh` (46/46), `bash docs/tests/test-proof-loop.sh` (30/30), `bash docs/tests/test-audit-code.sh`, `test-audit-excellence.sh`, `test-tasks-excellence.sh`, `test-scrub-scaffold.sh` (all pass), `./sprint.sh validate --docs`, `./sprint.sh validate --commands` — pass. Full suite (`run-all.sh`) is left for plan close.

**Proof**: 2026-10-10 · bash docs/tests/test-fast.sh; bash docs/tests/test-grok-provider.sh; bash docs/tests/test-command-matrix-smoke.sh; bash docs/tests/test-dep-work.sh; ./sprint.sh validate --docs; ./sprint.sh validate --commands · pass
