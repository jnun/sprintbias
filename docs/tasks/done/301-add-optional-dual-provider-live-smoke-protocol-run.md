# Task 301: Add optional dual-provider live smoke protocol runner for Claude Code and Grok Build exec paths

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Depends on**: 300, 296, 297
**Blocks**: 302
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

Unit tests and emit-matrix smoke never call a real AI CLI. Regressions in Grok
headless flags, Claude stream/JSON, auth, and true exec interactivity only show
up in manual dogfood. Plan 11 already tracks spine smoke (#296) and dual fresh
project (#297); we still need a **runnable optional harness** maintainers can
invoke when both CLIs are installed.

## Success criteria

- [x] Protocol + runner (script under `docs/tests/` or `docs/guides/`) that can
      execute (or skip with clear reason) live checks for **both**
      `claude-code` and `grok-build`
- [x] Covers at least: provider banner under real exec; one headless one-shot
      (e.g. polish or work with stub task); optional interactive chat skip if
      no TTY; emit detection notes when `GROK_AGENT` / `CLAUDECODE` set
- [x] Default is **opt-in** (`LIVE_SMOKE=1` or `--live`) so CI/unit suite stays
      offline by default
- [x] Records pass/fail/skip per step to stdout (and optional log under
      `docs/tmp/`)
- [x] Aligns with checklists in #296 / #297 rather than inventing a third
      competing protocol
- [x] Document how to run it in the test harness task (#302) or a short guide
      note

## Notes

- Prefer disposable sandbox project or throwaway tasks; never mutate
  production task state without a flag.
- Network and auth required; failures should say “auth/network” vs “product
  bug”.
- Depends on #296/#297 for the checklist content; this task is the **automation
  wrapper + opt-in runner**.

## References

docs/tasks/backlog/296-smoke-test-claude-proven-spine-under-grok-build.md
docs/tasks/backlog/297-dual-provider-smoke-protocol-on-a-fresh-project-fo.md
docs/guides/grok-provider-tier.md
docs/guides/claude-provider-tier.md
docs/tests/test-grok-provider.sh

## Questions

**Status: READY**

### Already complete

Nothing in *this* task's own deliverable is built yet — no live-smoke runner
exists. A grep for `LIVE_SMOKE` / `--live` / `live-smoke` across `docs/` returns
only this task file and #302. So the opt-in runner is 100% remaining work.

But every substrate the runner will drive already exists and is verified, so no
research is needed before building:

- **Provider banner under real exec** — `sprintmd_announce_provider` in
  `docs/sprintmd/lib.sh` prints `▸ Provider: … (…-build) · mode: …` once per
  process, on AI paths only. `test-grok-provider.sh` Test 11 already asserts the
  string; the live runner just needs to observe it under a real `exec`.
- **`-g` / `-c` per-run provider switch** — wired in `sprint.sh` (leading flags
  export `SPRINTMD_CLI` / `SPRINTMD_PROVIDER`), the exact mechanism the runner
  uses to hit each provider without rewriting config.
- **Emit detection** — `GROK_AGENT` → emit and `CLAUDECODE` → emit are the
  detection cases the runner must note (see `sprintmd_ai_mode`); `test-grok-
  provider.sh` Tests 3/5 cover them offline.
- **`grok` on PATH here** (`~/.grok/bin/grok`) so the exec-mode live steps are
  actually runnable on this machine, not forced skips.
- **Reusable harness patterns** — `test-grok-provider.sh` (config isolation +
  agent-env clearing + banner capture) and `test-sprint.sh` (full-tree sandbox)
  are ready-to-copy scaffolding for the skip/record plumbing.

### Remaining work

Author one runnable, **opt-in** live-smoke runner (a script, not a unit test)
that:

1. Runs live steps for **both** providers only when `LIVE_SMOKE=1` (or `--live`)
   is set; otherwise prints a one-line "skipped (set LIVE_SMOKE=1)" and exits 0
   so the offline suite / CI stays green.
2. Per provider: self-skips with a clear reason when the CLI is missing
   (`command -v grok` / `claude`) or when there is no TTY for interactive
   `chat`, distinguishing "auth/network" failures from "product bug".
3. Covers at least: provider banner under a real `exec`; one headless one-shot
   (polish or work against a stub/disposable task); optional interactive-chat
   skip when no TTY; and notes emit detection when `GROK_AGENT` / `CLAUDECODE`
   is set.
4. Records **pass / fail / skip per step** to stdout, with an optional log
   written under `docs/tmp/`.
5. Uses disposable sandbox tasks — never mutates production task state without a
   flag — and mirrors (does not reinvent) the checklists from #296 / #297.

Dependencies are recorded correctly: **Depends on: 300, 296, 297**. 300 gives
the sandbox/emit harness pattern to reuse; 296/297 author the checklist content
this runner wraps (the task's own Notes: "Depends on #296/#297 for the checklist
content; this task is the automation wrapper"). All three are in `next/`, so the
runner holds until they reach review/done — sequencing only, not a definition
gap. The runner's own shape (banner, headless one-shot, TTY skip, emit
detection) is fully specified here even before those land.

Minor cleanup while in here: the References list points 296/297 at
`docs/tasks/backlog/…`, but both now live in `docs/tasks/next/…`; update or
ignore, not blocking.

### Questions for the developer

1. Put the runner in `docs/tests/` or `docs/guides/`? (Suggestion: `docs/tests/`
   with the other runnable `*.sh` — it's executable, dev-only, and #302's
   run-all `--live` tier expects to find it there.)
2. How should the runner name/guard itself so #302's default `run-all` unit tier
   doesn't execute the live steps? (Suggestion: name it **outside** the
   `test-*.sh` glob that run-all sweeps — e.g. `smoke-live-dual-provider.sh` —
   *and* self-skip to exit 0 when `LIVE_SMOKE` is unset, so it's safe even if a
   harness does pick it up. Belt and suspenders; coordinate the exact name with
   #302's globbing decision.)

## Completed

Built the opt-in live-smoke runner `docs/tests/smoke-live-dual-provider.sh`,
resolving both developer questions as suggested: it lives in `docs/tests/` with
the other runnable `*.sh`, and is named **outside** the `test-*.sh` glob that
#302's `run-all.sh` sweeps (belt: the name; suspenders: it self-skips to exit 0
when neither `LIVE_SMOKE=1` nor `--live` is set).

What it does, per provider (`claude`/`claude-code`, then `grok`/`grok-build`):

- **CLI-present gate** — `command -v` missing → skip the whole leg (never fail).
- **Emit detection** — sets `CLAUDECODE` / `GROK_AGENT` and asserts
  `sprintmd_ai_mode` → `emit`, mirroring `test-grok-provider.sh` Tests 3/5.
- **Provider banner + headless one-shot under a REAL exec** — one live call
  (agent-detection env fully cleared, `SPRINTMD_MODE=exec`) drives
  `sprintmd_run -p … --max-turns 1`. Stderr yields the `▸ Provider: <cli> …
  mode: exec` banner (checked); stdout must carry the round-trip token. On
  failure it classifies **auth/network → SKIP** (login/quota/connection/timeout
  markers, rc 124/137) vs **product bug → FAIL**, per the Notes.
- **Interactive chat** — skips with a clear reason when there is no TTY; on a
  real TTY it never auto-opens a TUI (prints the `./sprint.sh -c/-g chat` hint)
  and asserts `sprintmd_interactive_ok`.

Records **PASS / FAIL / SKIP per step** to stdout; `--log` / `SMOKE_LOG=1`
tees a timestamped log under `docs/tmp/` (gitignored). No production task state
is mutated — the one-shot is a throwaway prompt, no files move.

Aligns with (does not replace) the two checklists: the header cross-references
`docs/guides/dual-provider-smoke.md` (#297) and `docs/tests/smoke-grok-spine.sh`
(#296), and the guide (#297) was updated to point at this runner as the
automation of its non-interactive subset (Related table + scope note), noting
that the fresh-`setup.sh` install legs stay a human step.

**Verified live on this machine** (both CLIs on PATH, logged in):
`LIVE_SMOKE=1 ./docs/tests/smoke-live-dual-provider.sh --log` →
`6 passed, 0 failed, 2 skipped` (both banners + both emit-detection + both live
one-shots pass; interactive chat skips for no TTY). Default (no opt-in) prints
one skip line and exits 0; unknown args exit 2; `bash -n` clean.

Not shipped, by design: `docs/tests/` (beyond `.TEMPLATE-test.md`) and
`docs/guides/` are dev-only and not mirrored by `ship.sh`, so no `./ship.sh`
was needed. Wiring #302's `run-all.sh --live` tier to invoke this runner is
left to #302 (its deliverable; it already has the `--live` branch and depends
on 301).

Note: this task's own **References** list still points #296/#297 at
`docs/tasks/backlog/…`; both now live in `docs/tasks/next/…`. Left as-is —
flagged non-blocking in the Questions section.

### Files changed
docs/tests/smoke-live-dual-provider.sh
docs/guides/dual-provider-smoke.md
