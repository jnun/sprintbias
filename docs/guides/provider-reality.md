# Provider reality inventory

Living list of **known knowns** and **known unknowns** for dual-provider
SprintBias (Claude Code + Grok Build): tools, subagents, models, spine, and
install. Later real-project work should not re-derive the same fog.

**This guide lives in `docs/guides/` (repo-only, not mirrored into `src/`).**
It is maintainer / agent truth for *this* repo’s dual-provider edges. Installed
projects never receive it.

Peers: [command-matrix.md](./command-matrix.md) (command catalog),
[grok-provider-tier.md](./grok-provider-tier.md),
[claude-provider-tier.md](./claude-provider-tier.md),
[dual-provider-smoke.md](./dual-provider-smoke.md).

---

## Maintain this file

| When you… | Also… |
|-----------|--------|
| Change provider behavior (CLI profile, tool map, emit, subagents, model resolution, install tier) | Update the matching KK / KU row here — stamp, note, owner |
| Prove or disprove a known unknown (smoke, live probe, unit test) | Stamp it; if still open, keep the owner path |
| Surface something new in smoke or a real project | Append under **Surfaced unknowns** (do not invent a fake catalog of UU) |
| Close a follow-up task that owned a KU | Re-stamp that KU from COVERED → RESOLVED / WONT / DEFER |

Stamps: `RESOLVED — works` | `RESOLVED — does not / WONT` | `COVERED by #N` |
`STILL OPEN` | `DEFER`. Honesty over fake certainty.

Historical first burn (pass 1, 2026-07-30): task **#298**. That task file is
the burn log; **this guide is the living home**.

---

## Classes

| Class | Meaning |
|-------|---------|
| Known knowns (KK) | Established works / does not / out of scope — with evidence or code path |
| Known unknowns (KU) | We know the question; answer not locked |
| Unknown unknowns (UU) | Only smoke and real projects surface them — watchlist + append log only |

---

## Known knowns (KK)

### Host & modes

| ID | Claim | Stamp | Notes |
|----|--------|-------|-------|
| KK-01 | Claude Code and Grok Build are first-class orchestration peers (`claude-code`, `grok-build`) | RESOLVED — works | Generic tiers stay sequential |
| KK-02 | Emit vs exec are different channels: emit prints into the host; exec spawns CLI | RESOLVED — works | Tool flags only affect exec |
| KK-03 | `GROK_AGENT=1` → emit; Claude session markers → emit | RESOLVED — works | Nested CLI avoided inside agents |
| KK-04 | Explicit `MODE=exec` / `MODE=emit` (or `SPRINTBIAS_MODE`) overrides auto-detect | RESOLVED — works | Operators can force path |
| KK-05 | Interactive chat needs profile + real TTY | RESOLVED — works | `claude` and `grok` only today |
| KK-06 | Shipping AI pointers stay minimal; Grok loads `CLAUDE.md` / `AGENTS.md` | RESOLVED — works | No mandatory `GROK.md` |
| KK-07 | Dual tree: edit `docs/` → `./ship.sh` → `src/` | RESOLVED — works | Hand-copy is wrong |

### Tools (exec)

| ID | Claim | Stamp | Notes |
|----|--------|-------|-------|
| KK-10 | Scripts speak Claude-style tool names (`Read,Edit,Write,Bash,…`) | RESOLVED — works | Profiles map or drop |
| KK-11 | Claude profile maps `--tools` → `--allowedTools` | RESOLVED — works | `cli/claude.sh` |
| KK-12 | Grok profile maps `--tools` → Grok **`--tools`** (internal IDs) | RESOLVED — works | Never use Grok `--allowedTools` for allowlists |
| KK-13 | Unmapped Grok tools **fail open** (omit allowlist) | RESOLVED — works | Wrong empty allowlist is worse than none |
| KK-14 | `Agent` / `Task` are not Grok `--tools` allowlist entries | RESOLVED — works | Subagents controlled separately |
| KK-15 | Grok headless: `--tools` / `--disallowed-tools` / `--max-turns` are headless-only | RESOLVED — works | Interactive TUI ignores them |
| KK-16 | Grok `--disallowed-tools Agent` blocks subagent spawn | RESOLVED — works | Different surface from Claude allowlists |
| KK-17 | Emit mode discards `--tools` / permissions / budget from the printed prompt | RESOLVED — works | Surrounding agent keeps its toolset |
| KK-18 | Budget caps are gated by `sprintbias_budget_capable` (today `claude-code` only) and omitted at source elsewhere; profile drop-with-warning stays as fallback | RESOLVED — works | Do not invent USD flags; add a tier to the capability `case` when it ships a real cap |
| KK-19 | Canonical shell id is `run_terminal_command`; map accepts `run_terminal_cmd` too | RESOLVED — works | Locked by #291 + `grok-provider-tier.md` |
| KK-19b | Neutral `stream-json` contract for headless progress | RESOLVED — works | Call sites (esp. `work`) pass `--output-format stream-json` only. Claude profile: keep `stream-json` and auto-add `--verbose`. Grok profile: map → `streaming-messages-json` (Anthropic Messages NDJSON; work progress filter), drop `--verbose`. Never forward Claude-only flags from call sites. Locked by `test-grok-provider.sh` Test 15 (2026-08-07) |

### Subagents & orchestration

| ID | Claim | Stamp | Notes |
|----|--------|-------|-------|
| KK-20 | Claude emit multi-task uses **Task tool** language | RESOLVED — works | work / gate / polish / promote --audit |
| KK-21 | Grok emit multi-task uses **`spawn_subagent`** language | RESOLVED — works | Same story, different host API |
| KK-22 | Shared helpers: `sprintbias_orchestration_capable`, `sprintbias_subagent_*` | RESOLVED — works | No six independent tier forks |
| KK-23 | Grok subagent nesting depth is **one** | RESOLVED — works | Workers must not re-orchestrate |
| KK-24 | Grok types: `general-purpose`, `explore`, `plan` | RESOLVED — works | Type picks capability |
| KK-25 | Grok `capability_mode`: read-only / read-write / execute / all | RESOLVED — works | Optional coarse filter on children |
| KK-26 | Exec `--parallel` is multi-**process**, not host subagents | RESOLVED — works | Subagent uncertainty does not apply |
| KK-27 | Role → type seam is `sprintbias_subagent_type_for`; all roles → `general-purpose` today | RESOLVED — works | #293: gate needs Edit + shell `git mv`; no restricted mode grants both |
| KK-28 | Live multi-task emit dogfood (orchestrator actually spawns N workers) | COVERED by #292 | Unit wording alone is not enough |

### Models

| ID | Claim | Stamp | Notes |
|----|--------|-------|-------|
| KK-30 | Resolution: env → `--model` → `config.local` → `config` (`MODEL_<ROLE>` → `MODEL_DEFAULT` per file) → tier default → CLI default | RESOLVED — works | `sprintbias_tier_model` / `model show` |
| KK-31 | Tier defaults when empty: Claude → `opus`; Grok → `grok-4.5` | RESOLVED — works | Spine commands use `sprintbias_tier_model` |
| KK-32 | `grok models` may list only `grok-4.5` | RESOLVED — works | Re-check often; `model list` shells out |
| KK-33 | First-class `./sprint.sh model` show / list / set | RESOLVED — works | #294 — keep family |
| KK-34 | Per-run model overrides discoverable on help / spine | COVERED by #295 | Env + optional flags |
| KK-35 | `config.local` overlay: same keys, wins over `config` per-key, `KEY=` clears; gitignored + `ship.sh` `TREE_EXCLUDES` so it never ships/commits | RESOLVED — works | `sprintbias_cfg` reads local→tracked; ship-safe personal pin (CLI/PROVIDER/MODE/MODEL_*/budgets) |

### Product spine & process

| ID | Claim | Stamp | Notes |
|----|--------|-------|-------|
| KK-40 | Live spine: `chat` → `plan start` → `work` → `polish` | RESOLVED — works | Retired names must not reappear |
| KK-41 | `plan start` default AI-gates members; `--commit-only` skips gate | RESOLVED — works | READY members can still pay tax |
| KK-42 | Plan status STARTED is one-way; retirement is `plan done` (delete file) | RESOLVED — works | Progress lives in task folders |
| KK-43 | Unit tests cover tier / emit detect / profile / map / helpers | RESOLVED — works | Not a substitute for TUI / emit dogfood |
| KK-44 | Per-AI product instruction trees rejected as default design | RESOLVED — works | Core doctrine + code adapters |
| KK-45 | This repo dogfoods SprintBias; users do not get our tasks/board | RESOLVED — works | Smoke must also use fresh setup |

---

## Known unknowns (KU)

Prefer mapping open items to a task or smoke step. When resolved, re-stamp and
shorten the note — keep the row for grep stability.

### Tools & IDs

| ID | Question | Stamp | Owner / notes |
|----|----------|-------|---------------|
| KU-01 | Live shell tool id | RESOLVED — works | Both ids accepted; emit `run_terminal_command` (#291) |
| KU-02 | Core Claude-name → Grok-id map for Read/Edit/Write/Bash/Grep/Glob | RESOLVED — works | #291 + unit tests |
| KU-03 | Do MCP meta-tools remain available under `--tools` allowlist? | STILL OPEN | Probe in smoke or dedicated note |
| KU-04 | Does interactive Grok honor tool restriction? | RESOLVED — works | Headless-only per product docs |
| KU-05 | Permission-rule prefixes vs neutral `permissions` string | COVERED by #296 | Unattended path |
| KU-06 | Is fail-open / soft-fail on bad allowlist too loud? | RESOLVED — works | Invalid ids can still allow shell; document, don’t assume strict |

### Subagents & emit

| ID | Question | Stamp | Owner / notes |
|----|----------|-------|---------------|
| KU-10 | Real Grok session: multi-task emit calls `spawn_subagent` N times? | COVERED by #292 | Live dogfood |
| KU-11 | Fan-out parallel vs serialized? | COVERED by #292 | Throughput |
| KU-12 | Can gate workers use pure `explore`? | RESOLVED — does not / WONT | Gate needs Edit + `git mv`; stay GP (#293) |
| KU-13 | Does `capability_mode: read-write` allow shell for moves? | RESOLVED — does not / WONT | No mode grants edit+shell; seam documents this |
| KU-14 | Do children inherit parent MCP / project rules? | COVERED by #292 | |
| KU-15 | Worker calls `spawn_subagent` anyway — depth error text? | COVERED by #292 | Prompt hardening |
| KU-16 | Is `plan` subagent type useful for plan think / authoring? | DEFER | Not plan 11 |
| KU-17 | Claude still passes `Agent` in TOOLS=; Grok map strips it | RESOLVED — works | Emit ignores tools |
| KU-18 | Unsolicited child spawn on single headless work? | COVERED by #296 | |

### Models

| ID | Question | Stamp | Owner / notes |
|----|----------|-------|---------------|
| KU-20 | More than `grok-4.5` soon; list reliability | RESOLVED — works (today) | `model list` → `grok models` |
| KU-21 | Cheap Claude model list from CLI? | RESOLVED — does not / WONT | Known aliases + see provider |
| KU-22 | Strongest tier defaults for all roles vs cheap work? | RESOLVED — works | Spine uses tier_model (strong default) |
| KU-23 | Which spine commands get per-invocation `--model`? | COVERED by #295 | |
| KU-24 | Empty `MODEL_WORK` gets tier default? | RESOLVED — works | work / gate / polish use `sprintbias_tier_model` |

### Reliability & exec parity

| ID | Question | Stamp | Owner / notes |
|----|----------|-------|---------------|
| KU-30 | Grok resume on transient failure | DEFER | Out of plan 11 unless smoke fails |
| KU-31 | Streaming-json progress narration for parity | RESOLVED — works (via messages stream) | Grok maps neutral `stream-json` → `streaming-messages-json`; work filter already understands assistant/result. Native ACP `streaming-json` still unused for work |
| KU-32 | Wall-clock timeout for wedged Grok exec | DEFER | |
| KU-33 | always-approve / permission-mode deny interactions | COVERED by #296 | |

### Setup, install, dual project

| ID | Question | Stamp | Owner / notes |
|----|----------|-------|---------------|
| KU-40 | Fresh setup → Grok: profile + tier correct every time? | COVERED by #297 | |
| KU-41 | Flip Claude ↔ Grok mid-life without re-setup (config only)? | COVERED by #294 + #297 | |
| KU-42 | plan start / loop --refill parity emit vs emit | COVERED by #296 | |
| KU-43 | plan start without `--commit-only` hang/cost under either provider | RESOLVED — works (process) | Use `--commit-only` when members READY |

### Product & process for real projects

| ID | Question | Stamp | Owner / notes |
|----|----------|-------|---------------|
| KU-50 | Minimum smoke gate before a future plan ships both providers | COVERED by #297 | dual-provider-smoke.md |
| KU-51 | Both CLIs on maintainer machine vs sequential smokes | RESOLVED — works (process) | Sequential OK |
| KU-52 | Tag Grok-only vs core product bugs | DEFER | Convention later |
| KU-53 | Week of `CLI=grok` dogfood after plan 11 | DEFER | Human |
| KU-54 | Hard-coded Claude-only user-facing strings left? | RESOLVED — works | Interactive copy dual-named; re-grep on renames |

---

## Unknown unknowns (UU) — watchlist only

We cannot list them. We list **where** they usually appear. Append under
**Surfaced unknowns** when smoke or real projects hit them.

| Where | What often hides there |
|-------|------------------------|
| First interactive `chat` on Grok TUI | Prompt size, rules load, permissions prompts, quit/save |
| First multi-task emit `work` | Orchestrator ignoring spawn; partial moves; context blowups |
| First headless `loop` / long work | Hang, auth expiry, rate limits, partial writes |
| Fresh `setup.sh` on empty repo | Missing profile, PATH, config defaults, instruction offer |
| Switching models mid-session | Stale env, wrong tier default |
| Gate on messy real tasks | False BLOCKED, tool denial, dependency edges |
| Subagent + MCP + permissions combo | Child missing tools parent had |
| Git mv / dirty tree under agent | Move failures, partial lifecycle |

---

## Surfaced unknowns

- 2026-08-07 — Grok `work` exec died immediately: `invalid value 'stream-json'` and (next) unexpected `--verbose`. Root cause: `work.sh` hardcoded Claude CLI flags; Grok profile passed them through. Fix: neutral `stream-json` contract + profile maps (KK-19b); unit Test 15.

Append as smoke and real projects hit them.

Format: `- YYYY-MM-DD — short description — disposition (NEW TASK / DEFER / fixed / documented)`

- 2026-07-30 — Grok `--tools` with **invalid** tool id still allowed shell (soft fail). Disposition: documented in #291 / KK-13 / KU-06.
- 2026-07-30 — Product docs disagree on shell id (`run_terminal_cmd` vs `run_terminal_command`); both work live. Disposition: #291 pin dual-alias; prefer `run_terminal_command`.
- 2026-08-10 — Easy Button install smoke (#362, v0.0.81) found **no** provider-tier divergence beyond the intended model defaults: both doors install identically (109 files, `All Checks Passed`) and differ only in the `CLI=`/`PROVIDER=` pair. Offline spine confirmed the pair *resolves*: Claude tree → all roles **`opus`** (tier default); Grok tree → all roles **`grok-4.5`** (tier default). `newtask`/`status` output is identical across doors. Scaffold branches (user-owned `DOCUMENTATION.md` → `SPRINTDOCUMENTATION.md`, silent prepend, same-version re-run) are provider-independent. Disposition: documented in `dual-provider-smoke.md` → Last dry run; nothing new to open.
- 2026-08-10 — Marker shape is not uniform and that is intentional: SprintBias-owned files (`GETSTARTED.md`, the manual) carry an opening `<!-- SprintBias v… -->` stamp only, while prepend targets (`CLAUDE.md`, `AGENTS.md`, `README.md`, `.gitignore`) carry the paired `<!-- end SprintBias -->` wrapper. A marker check that expects both lines everywhere will false-positive. Disposition: documented in `dual-provider-smoke.md`.
- 2026-08-20 — `promote --audit` (#373) adds a new AI *acceptance* pass: one judge per `review/` task (Success-criteria sign-off → `done/` with `--move`), riding the same emit fan-out family as `work`/`gate`/`polish` (KK-20/21 wording, `sprintbias_subagent_*` helpers) and a new **`ACCEPT`** model role registered in `model.sh` `KNOWN_ROLES`. Read-only judge (no Edit tool). Provider-independent by construction — no new tier fork. Disposition: documented here + `claude-`/`grok-provider-tier.md`; nothing to open.
- 2026-08-27 — **Grok buffered `--output-format json` is NOT Claude-shaped** (resolves the audit-364 known unknown). Verified against a real captured log: the result object carries `text` (the answer, where Claude uses `result`), `stopReason` (`end_turn` on clean completion, `cancelled` on max-turns exhaustion — where Claude uses `is_error` + `subtype`), and Claude-compatible `num_turns` / `total_cost_usd`. **There is no `is_error`/`subtype` key**, so the old Claude-shaped fallback read *every* Grok run — including a max-turns abort — as `finished`. Max-turns surfaces as `stopReason: cancelled` plus `Error: max turns reached` on stderr (which every SprintBias call site suppresses via `2>/dev/null`), so the log's `stopReason` is the only surviving signal; a genuine mid-run error shape was not observed (still a minor UU). Fix (#368): Grok owns `profile_interpret_run` in `cli/grok.sh` — maps `cancelled → max_turns`, normal stops → `finished`, other non-empty stops → `error`, reads verdict from `text`. Locked live: `grok -p … --output-format json` returns `{text, stopReason, num_turns, total_cost_usd, …}`. Disposition: documented; `cancelled`-vs-real-error disambiguation deferred (rc not threaded to the interpreter today).

---

## Related code & tests

| Area | Path |
|------|------|
| Grok profile / tool map | `docs/sprintbias/cli/grok.sh` |
| Claude profile | `docs/sprintbias/cli/claude.sh` |
| Shared helpers | `docs/sprintbias/lib.sh` |
| Capability matrix | `docs/sprintbias/ai/provider-capabilities.md` |
| Model CLI | `docs/sprintbias/scripts/model.sh` |
| Unit tests | `docs/tests/test-grok-provider.sh` |
| Emit / matrix smoke | `docs/tests/test-command-matrix-smoke.sh` |
| Dual-provider ritual | `docs/guides/dual-provider-smoke.md` |
| Plan | `docs/plans/11-grok-firm-up-model-cli-and-dual-smoke.md` |
| First burn log | `docs/tasks/review/298-inventory-known-knowns-and-known-unknowns-for-dual.md` |
