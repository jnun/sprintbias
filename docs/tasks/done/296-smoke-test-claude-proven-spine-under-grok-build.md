# Task 296: Smoke-test Claude-proven spine under Grok Build

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Plan**: 11
**Depends on**: 291, 292, 293
**Blocks**: 297
**Parent**: none

**Status: READY**

## Problem

Plan 5 shipped Grok as a peer tier with unit tests, but we have not re-run the
spine that already works under Claude Code (`chat` / `plan start` / `work` /
`gate` / `polish` / emit vs exec) under Grok. Without a systematic smoke,
later plans will inherit silent Grok regressions.

## Success criteria

- [x] Written smoke checklist (and optional small script under `docs/tests/` or
      `docs/tmp` protocol) covering at least:
      1. Config/doctor: tier `grok-build`, mode exec outside agent / emit with
         `GROK_AGENT`
      2. Exec: interactive `chat` opens Grok TUI (or documented skip if no TTY)
      3. Exec: one-shot `work` headless with mapped tools / always-approve
      4. Emit: multi-task orchestration wording + observed spawn behavior
      5. `gate` or `plan start` multi-member path under Grok
      6. `model show` / set if #294 already landed; otherwise config pin
- [x] Checklist run once on this machine; results recorded (pass/fail notes)
- [x] Bugs found become tasks or in-plan fixes before marking this done
      (none found — see Completed)
- [x] Does not require a second git remote — local dogfood is enough

## Notes

- Prefer reusing disposable tasks / `--commit-only` where gating would hang.
- This is Grok-only confidence for known paths; dual fresh-project is #297.

## References

docs/guides/grok-provider-tier.md
docs/guides/claude-provider-tier.md
docs/tests/test-grok-provider.sh
docs/sprintmd/guides/use_chat.md

## Questions

**Status: READY**

### Already complete

This is a smoke-test/dogfood task — the deliverable is a run checklist plus
recorded results, not new product code. The entire spine it exercises is
already built and present:

- `grok-build` tier + `cli/grok.sh` profile exist; `-g/--grok` and `-c/--claude`
  global flags are wired in `sprint.sh` (lines 359–366), setting
  `SPRINTMD_CLI` / `SPRINTMD_PROVIDER` per run.
- Orchestration/model/subagent helpers exist in `docs/sprintmd/lib.sh`
  (`sprintmd_orchestration_capable`, `sprintmd_tier_model`,
  `sprintmd_subagent_*`) and are consumed by `work.sh` / `gate.sh` /
  `gate-lib.sh` / `plan-start.sh` / `polish.sh` / `chat.sh`.
- `grok` binary is on PATH on this machine (`~/.grok/bin/grok`), so the
  exec-mode items (interactive `chat` TUI, headless `work -p`) are actually
  runnable here — no forced skip.
- `docs/tests/test-grok-provider.sh` already asserts tier inference, `GROK_AGENT`
  emit detection, profile load, tier-default model, orchestration helpers, and
  tool-mapping fail-open — but by its own header does **not** launch a live TUI
  or observe spawn behavior. That is precisely the residual gap this task closes.

The provider guide (`docs/guides/grok-provider-tier.md`) gives the exact
tier/flag/tool-ID facts the checklist needs to assert against, so no research is
required before running.

### Remaining work

Nothing is implemented yet for this task itself — the checklist has not been
authored or run. Scope for the sprint:

1. Write the 6-part smoke checklist (optionally as a small script/protocol under
   `docs/tests/` or a `docs/tmp` note) covering config/doctor, exec `chat`, exec
   headless `work`, emit multi-task orchestration wording + observed spawn, a
   multi-member `gate`/`plan start` path, and `model show`/set-or-config-pin.
2. Run it once on this machine and record pass/fail notes in the task (or a
   linked results file).
3. Turn any bug found into a follow-up task (or in-plan fix) before this is
   marked done — the audit-task-done rule: the deliverable of a QA task is
   execute-ready follow-ups, not just notes.

Dependencies are already recorded correctly: **Depends on: 291, 292, 293** —
those harden the exact Grok paths being smoke-tested (tool ID map, emit subagent
handoff, subagent types). The runner holds this in `next/` until they reach
review/done. Task 294 (`model show`/set) is a *soft* input only: item #6 already
degrades gracefully to a config pin if 294 has not landed, so it is deliberately
not a hard dependency.

### Questions for the developer

None — task is fully defined.

## Completed

The deliverable is a runnable smoke checklist plus one recorded run on this
machine (`grok 0.2.117` on PATH; repo config left as `CLI=claude` —
grok-build is selected per-run with `-g`, never rewriting config).

**Checklist:** `docs/tests/smoke-grok-spine.sh` — complements the existing unit
test (`test-grok-provider.sh`, which by its own header does *not* launch a live
TUI or observe spawn wording). It drives the LIVE command surface via
`./sprint.sh -g` and asserts the exec-mode argv the profile actually builds.
Safe on the dev repo: it never rewrites `docs/sprintmd/config`, emit-wording
checks force `MODE=emit` (print-only, no files move, no network), exec-argv
checks use a fake `grok` on PATH (no network), and the one live touch
(`model list` → `grok models`) is read-only and auto-skips when grok is
absent/logged-out.

**Run result: 25 passed, 0 failed, 1 skipped.** The skip is the live `chat`
TUI open, which requires a real terminal — documented as a manual step; the
smoke instead asserts the TUI command *shape* (positional prompt, `--model`
pin, no headless `-p`) and that `sprintmd_interactive_ok` correctly returns
false without a TTY (degrading to one-shot exec).

Coverage against the six required items:

1. **Config/doctor** — `-g model show` reports `Provider: grok-build`, `CLI: grok`;
   `GROK_AGENT=1` → emit; clean env + grok on PATH → exec. PASS.
2. **Exec interactive `chat`** — live open SKIPPED (no TTY on this run); TUI argv
   shape (`--model grok-4.5` + positional prompt, no `-p`) and TTY-gated routing
   asserted instead. PASS.
3. **Exec headless `work`** — `sprintmd_run -p … --tools Read,Edit,Write,Bash,Grep,Glob
   --skip-permissions` builds
   `--model grok-4.5 --tools read_file,search_replace,write,run_terminal_command,grep,list_dir
   --always-approve`; `--model opus` coerces to `grok-4.5` (raw opus never
   forwarded); unknown tool fails open (omits `--tools`); no Claude
   `--allowedTools` leak. PASS.
4. **Emit multi-task orchestration** — `-g work` (emit) says `spawn_subagent`,
   `subagent_type: general-purpose`, carries the depth-one no-nest guard, and
   never says Claude "Task tool". PASS.
5. **Multi-member gate** — `-g gate --force` (emit) orchestrates a parallel
   per-task review via `spawn_subagent`, dispatches "ALL IN PARALLEL", no Task
   tool leak. (Plain `gate` correctly short-circuits — all 7 `next/` tasks are
   already reviewed — so `--force` is used to exercise the orchestration path.)
   PASS.
6. **`model show`/`list`** — task 294 landed (`scripts/model.sh` present), so this
   is tested live, not degraded to a config pin: every role resolves to the
   `grok-4.5` tier default; `model list` names the `grok-build` provider and
   surfaces `grok-4.5` from the live `grok models` call. PASS.

**Bugs found: none.** Every Grok spine path re-run under `grok-build` behaves as
the guide (`docs/guides/grok-provider-tier.md`) specifies, so there are no
follow-up bug tasks to file. One false-positive surfaced *during authoring* and
was a test-harness bug, not a product bug: an unescaped `%s` in the fake-grok
stub (`printf` ate it) made argv look empty, and clearing an incomplete set of
agent-detection env vars made "exec outside agent" read as emit — both fixed in
the checklist (the stub uses `%%s`; the mode check clears the full
`CLAUDECODE`/`CLAUDE_CODE_SESSION_ID`/`CURSOR_*`/`AI_AGENT`/`SPRINTMD_IN_AGENT`
set). The existing unit test (`test-grok-provider.sh`) still passes 66/66.

Note: `docs/tests/` is dev-territory (not under `docs/sprintmd/`), so this
smoke is not distributed — no `./ship.sh` step applies.

### Files changed
docs/tests/smoke-grok-spine.sh
docs/tasks/doing/296-smoke-test-claude-proven-spine-under-grok-build.md
