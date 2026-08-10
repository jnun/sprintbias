# Task 298: Inventory known knowns and known unknowns for dual-provider tools models and smoke

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Plan**: 11
**Depends on**: none
**Blocks**: 291, 292, 293, 296, 297
**Parent**: none

**Status: READY**

## Living home (post-burn)

**The living inventory is `docs/guides/provider-reality.md`.** Keep KK/KU stamps
and the Surfaced unknowns log there whenever provider behavior or commands
change. This task file remains the **first burn log** (pass 1, 2026-07-30) and
historical detail; do not treat it as the single source of truth after promotion.

## Problem

Plan 5 made Grok a peer tier, and plan 11 will firm tools, models, and smoke.
But the full set of **what we already know** and **what we know we do not know**
is scattered across conversation, guides, and code comments. Without one
living inventory, human + AI will re-discover the same edges on every real
project, miss questions that should block ship, and confuse:

| Class | Meaning |
|-------|---------|
| **Known knowns** | We know it works / does not work / is out of scope — and whether a task already covers it |
| **Known unknowns** | We know the question; the answer is not proven yet |
| **Unknown unknowns** | Only smoke and real projects will surface these — we do not list them as facts, only as a catch bucket |

This task is the laundry list and the burn-down: walk every item with human +
AI, mark resolution, and spawn follow-up tasks only where still needed.
Expect heavy human judgment (you); AI helps classify, probe, and file work.

## Success criteria

- [x] Every item in **Known knowns** and **Known unknowns** below has an
      outcome stamp in this file (or a linked log):
      `RESOLVED — works` | `RESOLVED — does not / WONT` | `COVERED by #N` |
      `NEW TASK #N` | `DEFER` | `STILL OPEN` (with next probe)
- [x] Known unknowns that block plan 11 ship are either resolved or mapped to
      an existing plan-11 member (#291–#297)
- [x] A short **Unknown-unknowns watchlist** (not a fake inventory) lists
      *where* they are likely to appear (smoke steps / real-project moments)
- [x] Outcomes feed #291–#297 and future real-project tasks without requiring
      re-reading this whole chat history
- [x] No requirement that every STILL OPEN is closed in this task — honesty
      over fake certainty; open items stay open with an owner path

**Burn status (2026-07-30 pass 1):** first full pass complete. Live probes on
this machine's `grok` 0.2.114. Human still owns emit multi-task dogfood (#292)
and dual-project smoke (#296/#297). Re-open items only when smoke contradicts.

## Notes

### How to burn this down (human + AI)

1. Walk section by section in a session (or split sessions by theme).
2. For each item: try a 5-minute probe if cheap; otherwise mark DEFER / COVERED.
3. When an answer changes product code, file or amend a task — do not only
   chat about it.
4. Append a `## Burn log` at the bottom as you go (date, item id, outcome).
5. Unknown unknowns that surface during #296/#297 get appended under
   **Surfaced unknowns** with date and disposition.

### Item ids

Use the `KK-` / `KU-` prefixes when logging so grep stays easy.

---

## Known knowns (KK)

Things we believe are established. Burn-down confirms or corrects them.

### Host & modes

| ID | Claim | Implication | Task? |
|----|--------|-------------|--------|
| KK-01 | Claude Code and Grok Build are first-class orchestration peers (`claude-code`, `grok-build`) | Generic tiers stay sequential | Plan 5 shipped |
| KK-02 | Emit vs exec are different channels: emit prints into the host; exec spawns CLI | Tool flags only affect exec | Documented |
| KK-03 | `GROK_AGENT=1` → emit; `CLAUDECODE` / session ids → emit | Nested CLI avoided inside agents | Plan 5 #253 |
| KK-04 | Explicit `MODE=exec` / `MODE=emit` overrides auto-detect | Operators can force path | Config |
| KK-05 | Interactive chat needs profile + real TTY (`SPRINTMD_PROVIDER_INTERACTIVE`) | `claude` and `grok` only today | use_chat.md |
| KK-06 | Shipping AI pointers stay minimal; Grok loads `CLAUDE.md` / `AGENTS.md` | No mandatory `GROK.md` | Plan 5 decision |
| KK-07 | Dual tree: edit `docs/` → `./ship.sh` → `src/` | Hand-copy is wrong | CLAUDE.md |

### Tools (exec)

| ID | Claim | Implication | Task? |
|----|--------|-------------|--------|
| KK-10 | Scripts speak Claude-style tool names (`Read,Edit,Write,Bash,…`) | Profiles must map or drop | Neutral interface |
| KK-11 | Claude profile maps `--tools` → `--allowedTools` | Claude-native | cli/claude.sh |
| KK-12 | Grok profile maps `--tools` → Grok **`--tools`** (internal IDs) | Never use Grok `--allowedTools` for allowlists (that is permission-rule alias) | cli/grok.sh |
| KK-13 | Unmapped Grok tools **fail open** (omit allowlist) | Wrong empty allowlist is worse than none | cli/grok.sh |
| KK-14 | `Agent` / `Task` are **not** Grok `--tools` allowlist entries | Stripped on Grok map; subagents controlled separately | cli/grok.sh |
| KK-15 | Grok headless: `--tools` / `--disallowed-tools` / `--max-turns` are headless-only | Interactive TUI ignores them | Grok docs |
| KK-16 | Grok `--disallowed-tools Agent` blocks subagent spawn | Different surface from Claude including Agent in allowlist | Grok docs |
| KK-17 | Emit mode discards `--tools` / permissions / budget from the printed prompt | Surrounding agent keeps its own toolset | lib.sh emit |
| KK-18 | Budget caps are Claude-only today; Grok drops `--budget` with warning | Do not invent USD flags | Plan 5 |

### Subagents & orchestration

| ID | Claim | Implication | Task? |
|----|--------|-------------|--------|
| KK-20 | Claude emit multi-task uses **Task tool** language | Orchestrator spawns workers | work/gate/polish |
| KK-21 | Grok emit multi-task uses **`spawn_subagent`** language | Same story, different host API | Plan 5 #254 |
| KK-22 | Shared helpers: `sprintmd_orchestration_capable`, `sprintmd_subagent_*` | No six independent tier forks | lib.sh |
| KK-23 | Grok subagent nesting depth is **one** | Workers must not re-orchestrate | Grok docs |
| KK-24 | Grok types: `general-purpose`, `explore`, `plan` | Type picks capability, not our TOOLS= string | Grok docs |
| KK-25 | Grok `capability_mode`: read-only / read-write / execute / all | Optional coarse filter on children | Grok docs |
| KK-26 | Exec `--parallel` is multi-**process**, not host subagents | Subagent uncertainty does not apply to that path | work.sh |
| KK-27 | All Grok emit prompts currently say `general-purpose` only | Specialization not done | **#293** |
| KK-28 | Emit handoff is **prompt-proven in unit tests only**, not live dogfood | Parallel Grok may be theater until proven | **#292** |

### Models

| ID | Claim | Implication | Task? |
|----|--------|-------------|--------|
| KK-30 | Resolution: `SPRINTMD_MODEL_*` env → `MODEL_<ROLE>` → `MODEL_DEFAULT` → tier default → CLI default | Operators have knobs; hard to discover | config + lib |
| KK-31 | Tier defaults when empty: Claude → `opus`; Grok → `grok-4.5` | Strong default for reasoning flows | sprintmd_tier_model |
| KK-32 | Live `grok models` (2026-07-30): only `grok-4.5` advertised | List may be short; pin is simple | re-check often |
| KK-33 | No first-class `./sprint.sh model` command yet | Hand-edit config or env | **#294** |
| KK-34 | Per-run env overrides exist but are poorly taught | Help/`--model` gap | **#295** |

### Product spine & process

| ID | Claim | Implication | Task? |
|----|--------|-------------|--------|
| KK-40 | Live spine: `chat` → `plan start` → `work` → `polish` | Retired names must not reappear | plan 8 |
| KK-41 | `plan start` default AI-gates members; can hang / spend; `--commit-only` skips gate | READY members can still pay tax | felt on plan 5 |
| KK-42 | Plan status STARTED is one-way; retirement is `plan done` (delete file) | Progress lives in task folders | plan lifecycle |
| KK-43 | Unit test `test-grok-provider.sh` covers tier, emit detect, profile, map, helpers | Not a substitute for TUI/emit dogfood | plan 5 #256 |
| KK-44 | Per-AI product instruction trees are **rejected** as default design | Core doctrine + code adapters | design chat |
| KK-45 | This repo dogfoods SprintBias; users do not get our tasks/board | Smoke must also use fresh setup | dual tree |

---

## Known unknowns (KU)

Questions we know to ask. Answers not locked. Prefer map to #291–#297 when in scope.

### Tools & IDs

| ID | Question | Why it matters | Probe / owner |
|----|----------|----------------|---------------|
| KU-01 | Is the live shell tool id `run_terminal_command` or `run_terminal_cmd` (or both)? | Map wrong → fail-open or no shell | **#291** |
| KU-02 | Exact set of internal IDs for write vs search_replace vs multi-edit equivalents? | Incomplete map → fail-open always | **#291** |
| KU-03 | Do MCP meta-tools remain available under `--tools` allowlist as docs say? | Security / surprise tools | **#291** + smoke |
| KU-04 | Does interactive Grok ever honor tool restriction, or always full tools? | Chat risk model | Grok docs say headless-only — confirm |
| KU-05 | Permission-rule prefixes on Grok (`Bash(...)`, `Edit(...)`) vs our neutral permissions string — what do scripts actually get? | Unattended hang vs over-broad approve | profile + **#296** |
| KU-06 | Is fail-open too loud in practice (always omitting)? | Restriction never engages | metrics during smoke |

### Subagents & emit

| ID | Question | Why it matters | Probe / owner |
|----|----------|----------------|---------------|
| KU-10 | Does a real Grok session obey multi-task emit and call `spawn_subagent` N times? | Parallel product claim | **#292** |
| KU-11 | Does Grok fan out in parallel or serialize spawns? | Throughput | **#292** |
| KU-12 | Can gate workers use `explore` if gate must Edit the task file and/or `git mv`? | Type specialization | **#293** |
| KU-13 | Does `capability_mode: read-write` allow shell `git mv` for routing? | Emit routing contract | **#293** |
| KU-14 | Do children inherit parent MCP servers / project rules as docs claim? | Workers missing context | **#292** dogfood |
| KU-15 | What happens if a worker calls `spawn_subagent` anyway (depth error text)? | Prompt hardening | **#292** |
| KU-16 | Is `plan` subagent type useful for `plan think` / plan authoring emit? | Optional later | DEFER unless smoke needs |
| KU-17 | Claude Task tool: do we still pass `Agent` in TOOLS= for exec work, and does emit care? | Consistency | note only if broken |
| KU-18 | Exec single-process `grok -p` with subagents enabled: does work ever spawn children without being asked? | Surprise cost / nesting | **#296** |

### Models

| ID | Question | Why it matters | Probe / owner |
|----|----------|----------------|---------------|
| KU-20 | Will Grok expose more than `grok-4.5` soon, and how do we list them reliably? | `model list` design | **#294** |
| KU-21 | Cheap reliable way to list Claude models from CLI? | Parity of `model list` | **#294** open decision |
| KU-22 | Should tier defaults stay “strongest” for all roles, or cheap TRIAGE vs strong CHAT explicitly in `model show`? | Cost / UX | **#294** |
| KU-23 | Per-invocation `--model` on which spine commands is enough (work/chat/gate/polish only)? | Scope of **#295** | human call |
| KU-24 | Does empty `MODEL_WORK` on Grok always resolve to `grok-4.5` via tier_model, and does work.sh use tier_model or only resolve_model? | work may not get tier default today | **verify in #294** — work uses `sprintmd_resolve_model` not `tier_model` |

### Reliability & exec parity

| ID | Question | Why it matters | Probe / owner |
|----|----------|----------------|---------------|
| KU-30 | Grok resume on transient failure (`sessionId` + `--resume`) — worth plan 11 or later? | Overnight loop trust | DEFER (out of plan 11 scope) unless smoke fails |
| KU-31 | Grok streaming-json progress narration — needed for parity? | Operator visibility | DEFER |
| KU-32 | Wall-clock timeout for wedged Grok exec? | Hang risk | DEFER unless smoke hangs |
| KU-33 | Always-approve vs permission-mode for loop unattended — any deny-rule interaction that still blocks? | Autopilot stuck | **#296** |

### Setup, install, dual project

| ID | Question | Why it matters | Probe / owner |
|----|----------|----------------|---------------|
| KU-40 | Fresh setup → Grok: is `cli/grok.sh` present and tier written correctly every time? | Install path | **#297** |
| KU-41 | Can one project flip Claude ↔ Grok mid-life without setup re-run (config only)? | Real projects | **#294** + **#297** |
| KU-42 | Does plan start / loop --refill behavior differ under Grok emit vs Claude emit beyond wording? | Spine parity | **#296** |
| KU-43 | `plan start` without `--commit-only` under Grok exec: still hangs / costs like Claude? | Human workflow | human note; process not only code |

### Product & process for real projects

| ID | Question | Why it matters | Probe / owner |
|----|----------|----------------|---------------|
| KU-50 | What is the minimum smoke gate before marking a **future** plan shipped for both providers? | Protocol length | **#297** |
| KU-51 | Do we require both CLIs on the maintainer machine, or sequential smokes OK? | Practicality | human |
| KU-52 | When a bug is Grok-only vs core product, how do we tag tasks? | Board hygiene | DEFER convention |
| KU-53 | Should this dogfood repo run `CLI=grok` for a week after plan 11? | Discovery rate | human |
| KU-54 | Are there command paths still hard-coded to Claude in help strings or errors beyond interactive notes? | Polish | grep pass in #296 |

---

## Unknown unknowns (UU) — watchlist only

We cannot list them. We **can** list where they usually appear. During #296/#297
and real-project work, append under **Surfaced unknowns** below.

| Where | What often hides there |
|-------|-------------------------|
| First interactive `chat` on Grok TUI | Prompt size, rules load, permissions prompts, quit/save behavior |
| First multi-task emit `work` | Orchestrator ignoring spawn; partial file moves; context blowups |
| First headless `loop` / long work | Hang, auth expiry, rate limits, partial writes |
| Fresh `setup.sh` on empty repo | Missing profile, PATH, config defaults, instruction file offer |
| Switching models mid-session | Stale cache, wrong env still set, tier default surprising |
| Gate on messy real tasks | False BLOCKED, tool denial mid-review, dependency graph edge cases |
| Subagent + MCP + permissions combo | Child missing tools parent had |
| Git mv / dirty tree under agent | Move failures, partial lifecycle |

---

## Outcome index (pass 1 — 2026-07-30)

### Known knowns — all stamped

| IDs | Stamp | Notes |
|-----|--------|------|
| KK-01–KK-07 | **RESOLVED — works** | Host/modes/dual-tree as designed; verified against code + plan 5 ship |
| KK-10–KK-18 | **RESOLVED — works** | Tool channel design correct; see KU-01/06 for map edge cases |
| KK-20–KK-26 | **RESOLVED — works** | Subagent design + helpers verified when `PROVIDER=grok-build` |
| KK-27 | **COVERED by #293** | Still always `general-purpose` in prompts |
| KK-28 | **COVERED by #292** | Emit handoff not live-dogfooded yet |
| KK-30–KK-32 | **RESOLVED — works** | Model resolution + `grok models` = only `grok-4.5` today |
| KK-33–KK-34 | **COVERED by #294 / #295** | No `model` CLI yet; env poorly taught |
| KK-40–KK-45 | **RESOLVED — works** | Spine/process/unit tests; plan start hang felt earlier |

### Known unknowns — stamps

| ID | Stamp | Notes |
|----|--------|------|
| KU-01 | **RESOLVED — works** | Live install accepts **both** `run_terminal_command` and `run_terminal_cmd` for shell-only `--tools`. Canonical in getting-started/hooks/skills: `run_terminal_command`. Headless guide still says `run_terminal_cmd` (doc drift). Map output `run_terminal_command` is correct; accept both as input. **#291** should pin this + dual-alias test |
| KU-02 | **RESOLVED — works** (core set) | Core map Read/Edit/Write/Bash/Grep/Glob → verified IDs works in unit test + profile. No multi-edit special case needed for v1. **#291** locks tests |
| KU-03 | **STILL OPEN** | Docs claim MCP meta-tools remain under allowlist; not probed. Probe in **#291** or **#296** |
| KU-04 | **RESOLVED — works** (docs + product) | Headless guide: `--tools` headless-only; TUI warns and ignores. Interactive = full tools |
| KU-05 | **STILL OPEN** / **COVERED by #296** | Permission-rule vs neutral `permissions=auto` / always-approve — smoke unattended path |
| KU-06 | **RESOLVED — works** (with caveat) | Invalid `--tools not_a_real_tool_xyz` still ran shell successfully → Grok appears to **fail soft** (restriction not applied or ignored). Our fail-open is safe; strict restriction may be weaker than assumed. **#291** document; optional probe empty vs invalid |
| KU-10–KU-11 | **COVERED by #292** | Need live multi-task emit dogfood |
| KU-12–KU-13 | **RESOLVED — partial** + **#293** | Gate emit contract **requires** Edit/Write on task file + `git mv` (shell). Pure `explore` (no edits) is **insufficient** for full gate path. Prefer `general-purpose` or verify read-write + shell before choosing explore |
| KU-14–KU-15 | **COVERED by #292** | MCP inherit + depth error text — dogfood |
| KU-16 | **DEFER** | `plan` type for plan think — not plan 11 |
| KU-17 | **RESOLVED — works** | Exec work still passes `Agent` in TOOLS=; Grok map strips it. Emit ignores tools. No bug |
| KU-18 | **COVERED by #296** | Unsolicited child spawn on single headless work |
| KU-20 | **RESOLVED — works** (today) | Only `grok-4.5` listed; **#294** list can shell out to `grok models` |
| KU-21 | **RESOLVED — does not / WONT** (cheap list) | No reliable `claude models` list API on this machine (`claude models` entered chat). **#294**: Claude list = known aliases + “see provider”, not fake API |
| KU-22 | **COVERED by #294** | Human product choice for show layout |
| KU-23 | **COVERED by #295** | Spine flags only |
| KU-24 | **RESOLVED — works** (bug confirmed) | `work`/`gate`/`polish` use `sprintmd_resolve_model` only — **empty config does not pin tier default**. Chat/feature/idea use `sprintmd_tier_model`. On Grok, CLI default is already `grok-4.5` so work “works by accident.” On Claude, work does **not** get opus unless configured. **Must fix in #294** (or tiny dedicated fix): either switch spine to `tier_model` or document intentional cheap-default for work |
| KU-30–KU-32 | **DEFER** | Resume/stream/timeout — out of plan 11 unless smoke hangs |
| KU-33 | **COVERED by #296** | always-approve unattended |
| KU-40–KU-42 | **COVERED by #297 / #296** | Install + flip + spine parity |
| KU-43 | **RESOLVED — works** (process) | plan start AI-gate can hang/spend; use `--commit-only` when members already READY. Product improvement optional later |
| KU-50–KU-51 | **COVERED by #297** + human | Protocol length; sequential smokes OK |
| KU-52 | **DEFER** | Grok-only task tag convention |
| KU-53 | **DEFER** / human | Week of `CLI=grok` dogfood optional after plan 11 |
| KU-54 | **RESOLVED — works** | Interactive notes already say “claude or grok”; no remaining hard claude-only user-facing interactive warnings found in scripts |

### Actions for plan 11 members (from this burn)

| Task | Extra clarity from burn |
|------|-------------------------|
| **#291** | Pin shell dual-alias; document Grok soft-fail on bad allowlist; MCP optional probe |
| **#292** | Only way to close KU-10/11/14/15 — human in Grok session |
| **#293** | Do **not** default gate to pure `explore` without proving edit+mv; likely stay GP or GP+capability_mode |
| **#294** | `model list` for Claude = aliases not API; **fix or document** resolve vs tier_model on work/gate/polish (KU-24) |
| **#295** | Spine `--model` only |
| **#296/#297** | Permission hangs, unsolicited spawn, install path, UU watchlist |

---

## Surfaced unknowns

<!-- Append as smoke and real projects hit them.
     Format: - YYYY-MM-DD — short description — disposition (NEW TASK / DEFER / fixed) -->

- 2026-07-30 — Grok `--tools` with **invalid** tool id still allowed shell execution (soft fail / ignore). Disposition: document in #291; not a SprintBias map bug.
- 2026-07-30 — Product docs disagree on shell id (`run_terminal_cmd` vs `run_terminal_command`); both work live. Disposition: COVERED by #291 pin dual-alias + prefer `run_terminal_command`.

---

## Burn log

- 2026-07-30 — **pass 1 start** — AI session; live `grok` 0.2.114, logged in.
- 2026-07-30 — KK-01..07 — RESOLVED — works — code + plan 5 ship + config mode paths.
- 2026-07-30 — KK-10..18 — RESOLVED — works — cli/grok.sh + emit strip verified in lib.sh.
- 2026-07-30 — KK-20..26 — RESOLVED — works — helpers return spawn_subagent when PROVIDER=grok-build; Task tool when claude-code.
- 2026-07-30 — KK-27 — COVERED by #293 — still general-purpose only in prompts.
- 2026-07-30 — KK-28 — COVERED by #292 — no live multi emit yet.
- 2026-07-30 — KK-30..32 — RESOLVED — works — `grok models` → only grok-4.5; resolvers behave as coded.
- 2026-07-30 — KK-33..34 — COVERED by #294/#295.
- 2026-07-30 — KK-40..45 — RESOLVED — works — including plan start hang experience.
- 2026-07-30 — KU-01 — RESOLVED — works — shell-only `--tools run_terminal_command` and `run_terminal_cmd` both ran `echo SHELL_CMD_OK`.
- 2026-07-30 — KU-02 — RESOLVED — works (core) — unit map + live headless OK.
- 2026-07-30 — KU-03 — STILL OPEN — MCP under allowlist not probed.
- 2026-07-30 — KU-04 — RESOLVED — works — headless-only tools per docs.
- 2026-07-30 — KU-05 — COVERED by #296.
- 2026-07-30 — KU-06 — RESOLVED — works (caveat) — invalid tool allowlist still had shell.
- 2026-07-30 — KU-10..11 — COVERED by #292.
- 2026-07-30 — KU-12..13 — RESOLVED partial — gate needs Edit+Write+shell; explore alone insufficient; #293.
- 2026-07-30 — KU-14..15 — COVERED by #292.
- 2026-07-30 — KU-16 — DEFER.
- 2026-07-30 — KU-17 — RESOLVED — works — Agent strip on Grok map.
- 2026-07-30 — KU-18 — COVERED by #296.
- 2026-07-30 — KU-20 — RESOLVED — works (today) — single model.
- 2026-07-30 — KU-21 — RESOLVED — does not / WONT — no cheap claude models list.
- 2026-07-30 — KU-22..23 — COVERED by #294/#295.
- 2026-07-30 — KU-24 — RESOLVED — works (bug confirmed) — work/gate/polish resolve_model only; chat uses tier_model. Fix under #294.
- 2026-07-30 — KU-30..32 — DEFER.
- 2026-07-30 — KU-33 — COVERED by #296.
- 2026-07-30 — KU-40..42 — COVERED by #296/#297.
- 2026-07-30 — KU-43 — RESOLVED — works (process) — --commit-only escape hatch.
- 2026-07-30 — KU-50..51 — COVERED by #297 + human.
- 2026-07-30 — KU-52..53 — DEFER.
- 2026-07-30 — KU-54 — RESOLVED — works — interactive copy already dual-named.
- 2026-07-30 — **pass 1 end** — success criteria for inventory stamps met; live emit dogfood remains human/#292.

## References

docs/guides/provider-reality.md
docs/guides/command-matrix.md
docs/plans/11-grok-firm-up-model-cli-and-dual-smoke.md
docs/guides/grok-provider-tier.md
docs/guides/claude-provider-tier.md
docs/sprintbias/cli/grok.sh
docs/sprintbias/cli/claude.sh
docs/sprintbias/lib.sh
docs/sprintbias/ai/provider-capabilities.md
docs/tests/test-grok-provider.sh
~/.grok/docs/user-guide/14-headless-mode.md
~/.grok/docs/user-guide/16-subagents.md
