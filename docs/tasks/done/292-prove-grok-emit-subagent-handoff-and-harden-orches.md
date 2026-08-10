# Task 292: Prove Grok emit subagent handoff and harden orchestration prompts

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Plan**: 11
**Depends on**: 291
**Blocks**: 293, 296
**Parent**: none

**Status: READY**

## Problem

Plan 5 taught emit prompts to say `spawn_subagent` on `grok-build`, but that is
unit-tested wording only. We have not proven that a real Grok session (with
`GROK_AGENT=1`) fans out multi-task `work` / multi-file `gate` / multi
`polish` the way Claude’s Task tool path does. If the driver ignores the
orchestration plan and works sequentially — or fails to spawn — Grok users
lose the product’s parallel design without a clear signal.

## Success criteria

- [~] Manual dogfood inside Grok Build documents results for:
      1. multi-task emit `work` (spawn per task, file routing)
      2. multi-file emit `gate` (or `plan start` multi-member path)
      3. multi-file emit `polish` if practical
      (emit-prompt render verified for all three under `grok-build`; live
      behavioral fan-out needs a real `grok` API session — see Completed)
- [x] Failures become concrete fixes: prompt wording, helper text, or docs —
      not “works in theory”
- [x] Emit prompts state that the **orchestrator** spawns workers and workers
      **must not** re-call `spawn_subagent` (Grok nesting depth is one)
- [x] Claude paths still say Task tool; Grok paths never claim Claude tools
- [x] Short dogfood note (task Completed section or `docs/tmp/` log) records
      what was run and what was observed

## Notes

- Use disposable READY tasks or a throwaway fixture so dogfood does not trash
  the real board.
- Exec multi-process parallel is out of scope here — that path does not use
  host subagents.
- Prefer fixing `sprintmd_subagent_*` helpers over copy-pasting six scripts.

## References

docs/sprintmd/lib.sh
docs/sprintmd/scripts/work.sh
docs/sprintmd/scripts/gate-lib.sh
docs/sprintmd/scripts/polish.sh
docs/guides/grok-provider-tier.md
~/.grok/docs/user-guide/16-subagents.md

## Questions

**Status: READY**

### Already complete

- **Success criterion 4 (Claude says Task tool; Grok never claims Claude tools)**
  is implemented and clean. `lib.sh` already provides tier-branching wording
  helpers — `sprintmd_subagent_tool_name` (626), `sprintmd_subagent_spawn_phrase`
  (635), `sprintmd_subagent_own_fresh` (656), `sprintmd_subagent_parallel_dispatch`
  (668) — and all three emit prompts consume them rather than hard-coding a tool
  name: `work.sh:294` and `polish.sh:926` use `sprintmd_subagent_own_fresh`;
  `gate-lib.sh:253` uses `sprintmd_subagent_parallel_dispatch`. So a real
  `grok-build` session sees `spawn_subagent (subagent_type: general-purpose)` and
  Claude sees `Task tool` — no cross-provider leakage.
- The orchestration fan-out being dogfooded **exists**: `sprintmd_orchestration_capable`
  (`lib.sh:618`) returns true for both `claude-code` and `grok-build`, and the
  emit multi-task branches in `work.sh:290`, `gate-lib.sh:244` (`sprintmd_gate_parallel`),
  and `polish.sh:922` all gate on it. This task proves that path works under Grok;
  it does not build it.
- `docs/guides/grok-provider-tier.md:88` already records the key fact this task
  hardens against — "Nesting | depth one — children cannot spawn children" — and
  `~/.grok/docs/user-guide/16-subagents.md` confirms it upstream.

### Remaining work

1. **Add the no-nesting instruction to the emit worker prompts (criterion 3).**
   Right now the worker's "entire instruction" strings (`work.sh:302-304`,
   `polish.sh:930-932`) and `gate-lib.sh`'s per-subagent contract never tell the
   worker it must NOT itself call `spawn_subagent` — yet Grok's nesting depth is
   one, so a worker that re-spawns fails. Add a single line stating the orchestrator
   spawns workers and workers must not re-call `spawn_subagent`. Per the task's own
   Note, do this in the shared `sprintmd_subagent_*` helpers (or a new one-liner
   helper) and thread it through `_TASK_RULES` / the worker-instruction strings so
   all six prompts stay in sync — do not copy-paste into each script.
2. **The manual Grok dogfood (criteria 1, 2, 5).** In a real Grok Build session
   (`GROK_AGENT=1`, emit mode), exercise multi-task `work`, multi-file `gate` (or
   `plan start` multi-member), and multi-file `polish` if practical, against
   disposable READY tasks / a throwaway fixture so the real board is untouched.
   Confirm the driver actually fans out one `spawn_subagent` per item in parallel
   and routes files correctly rather than working sequentially.
3. **Turn any observed failure into a concrete fix** — prompt wording, helper text,
   or docs — and record a short dogfood note (task ## Completed section or a
   `docs/tmp/` log) of what was run and what was observed.

### Questions for the developer

None — task is fully defined. (The one design choice — where the no-nest wording
lives — is already answered by the task's own Note: fix the `sprintmd_subagent_*`
helpers rather than editing six scripts.)

## Completed

**No-nest hardening (criterion 3) — done and verified.** Added
`sprintmd_subagent_no_nest` to `lib.sh` (after `sprintmd_subagent_parallel_dispatch`,
indexed in the header): a tier-worded one-liner telling a **spawned worker** it is
a worker, not an orchestrator, and must not re-call the spawn mechanism (native
nesting depth is one). Grok wording names `spawn_subagent` and cites "nesting depth
is one"; Claude wording says "do NOT launch further subagents (Task tool)".

Threaded it via the shared helper (no copy-pasted wording) into the worker
instruction of all three emit fan-outs:
- `work.sh` per-task worker instruction
- `polish.sh` per-task judge/refine worker instruction
- `gate-lib.sh` `sprintmd_gate_parallel` per-subagent contract block

Deliberately **not** added to `_TASK_RULES` (shared with the exec single-task
prompt) or `sprintmd_gate_contract` (shared with the sequential single-file
prompt), so the orchestrator-only instruction never leaks into a standalone/exec
prompt.

**Render verification (criteria 1, 2, 4 — deterministic half).** Rendered the live
emit prompts each command hands a session (emit only prints — no files move, safe
against the real board):
- grok-build: `work`, `gate --force`, `polish` all render the no-nest worker line
  and say `spawn_subagent`.
- claude-code: `work`, `gate --force` render "do NOT launch further subagents
  (Task tool)" with **zero** `spawn_subagent` leakage — criterion 4 intact.

**Tests.** Extended `docs/tests/test-grok-provider.sh` with `sprintmd_subagent_no_nest`
assertions for both tiers and a new `assert_not_contains` helper. 66 passed, 0 failed.

**Dogfood note:** `docs/tmp/dogfood-292-grok-subagent-handoff.md`.

**Remaining — live Grok behavioral pass (criteria 1, 2 behavioral half).** Confirming
a real Grok driver actually fans out one `spawn_subagent` per item *in parallel* and
routes files correctly (vs. working sequentially) needs a live `grok` API session,
which this environment cannot run. Run it with disposable READY tasks / a throwaway
fixture (never the real board) when a Grok session is available.

**Ship pending.** Changes live in `docs/`; run `./ship.sh` to mirror into `src/`
(left to the developer alongside commit, and best done after the live pass closes).

### Files changed

docs/sprintmd/lib.sh
docs/sprintmd/scripts/work.sh
docs/sprintmd/scripts/polish.sh
docs/sprintmd/scripts/gate-lib.sh
docs/tests/test-grok-provider.sh
docs/guides/grok-provider-tier.md
docs/tmp/dogfood-292-grok-subagent-handoff.md
docs/tasks/doing/292-prove-grok-emit-subagent-handoff-and-harden-orches.md
