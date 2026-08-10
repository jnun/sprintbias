# Grok Provider Tier (as built)

How SprintBias runs when the AI provider is **Grok Build** — a peer to the
Claude tier, not a generic passthrough. Capability matrix:
`docs/sprintbias/ai/provider-capabilities.md`. Claude peer:
`docs/guides/claude-provider-tier.md`. Living KK/KU inventory (tools, emit,
models, install): `docs/guides/provider-reality.md`.

Ship truth for flags and gates lives in code; this guide is the human/agent map.

**Language:** live command surface (`chat` / `work` / `gate` / …).

## Identity

| Field | Value |
|-------|-------|
| Tier name | `grok-build` |
| CLI binary | `grok` |
| Profile | `docs/sprintbias/cli/grok.sh` |
| Config | `CLI=grok` and `PROVIDER=grok-build` |
| Setup pick | Grok Build (option 2 in `setup.sh`) |
| Session detect | `GROK_AGENT=1` → emit mode |
| Default model (tier) | `grok-4.5` when `MODEL_*` empty (`sprintbias_tier_model`) |

## Goal

| User outcome | Meaning |
|--------------|---------|
| One switch | Pick Grok at setup the same way you pick Claude |
| Live chat | `./sprint.sh chat` opens a Grok TUI from a plain terminal |
| Emit in-session | Inside Grok Build, prompts land here — no nested CLI |
| Parallel cycles | `work` / `gate` / `polish` / `plan start` use fresh subagents |
| Honest maps | Flags and tool names match real `grok --help`, or are dropped with a warning |

## Two modes (same product rule as Claude)

| Mode | When | What happens |
|------|------|--------------|
| emit | Inside Grok Build (`GROK_AGENT` set, or `MODE=emit`) | Print the prompt into this session. Driver uses `spawn_subagent` for parallel work. |
| exec | Plain terminal, CI, loops | Spawn `grok` via `cli/grok.sh`. Interactive or `-p` headless. |

## Neutral interface (unchanged)

Scripts keep calling `sprintbias_run` / `sprintbias_run_interactive`. Only the
profile and tier gates change. No script should hardcode `grok` flags.

## Flag map (neutral → Grok)

| Neutral flag | Grok flag | Notes |
|--------------|-----------|-------|
| `-p PROMPT` | `-p` / `--single PROMPT` | Headless; prints and exits |
| positional prompt | positional | Interactive TUI open message |
| `--model` | `-m` / `--model` | e.g. `grok-4.5` |
| `--max-turns` | `--max-turns` | Headless-oriented; cap long jobs |
| `--tools` | **`--tools`** | Grok **internal** tool IDs. **Not** `--allowedTools` |
| `--permissions` | `--permission-mode` | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan` |
| `--skip-permissions` | `--always-approve` | Unattended batch / loop |
| `--output-format` | `--output-format` | `plain`, `json`, `streaming-json`, `streaming-messages-json`. **Alias:** Claude `stream-json` → `streaming-messages-json` (Anthropic Messages NDJSON; keeps `work.sh` progress filter working) |
| `--verbose` | (drop) | Claude-only (required for Claude `stream-json`); Grok rejects the flag |
| `--budget` | (drop) | No verified USD budget flag. Call sites gate on `sprintbias_budget_capable`, so this never arrives on the primary path; the drop-and-warn-once stays as fallback |
| `--name` | (drop) | No direct equivalent — warn once |
| `--append-system-prompt` | `--rules` | Append rules to system prompt |

**JSON resume field:** headless result uses `sessionId` (camelCase). Resume with
`grok --resume <id>`. Native `streaming-json` events are ACP-shaped (`text` /
`thought` / `end`). Callers that pass Claude `stream-json` get
`streaming-messages-json` instead so the shared work progress filter still
parses `assistant` / `result` events.

## Tool names

Claude allowlists are mapped in `cli/grok.sh` for headless `--tools`. Unmapped
names fail open (omit allowlist).

| Claude-style | Grok tool ID |
|--------------|--------------|
| Read | `read_file` |
| Edit / Write | `search_replace` / `write` |
| Bash | `run_terminal_command` |
| Grep | `grep` |
| Glob | `list_dir` |
| Task / Agent (subagent) | prompt language `spawn_subagent` (not a `--tools` entry) |

**Verified shell id:** live `grok` **0.2.117** registers the shell tool as
`run_terminal_command` in its `available_commands` tool registry, and accepts
**both** `run_terminal_command` and `run_terminal_cmd` as `--tools` input
(exit 0). We emit `run_terminal_command`; the map accepts either. Headless docs
still say `run_terminal_cmd` (Grok-side doc drift). Verified 2026-07-30;
re-check on next Grok minor.

## Subagents (Grok native)

| Concept | Grok |
|---------|------|
| Spawn child | `spawn_subagent` |
| Default worker | `general-purpose` |
| Read-only research | `explore` |
| Planning only | `plan` |
| Nesting | depth one — children cannot spawn children |

**Role → `subagent_type`.** The wording helpers source the Grok type from one
seam, `sprintbias_subagent_type_for <role>`. Every role resolves to
`general-purpose` today, and the mapping records why:

| Role | Caller | Type | Why |
|------|--------|------|-----|
| `work` | `work.sh` | `general-purpose` | implements product code — full toolset |
| `gate` | `gate-lib.sh` | `general-purpose` | must Edit/Write the task file **and** `git mv` it (shell); no restricted mode grants both (read-write = edits, no shell; execute = shell, no edits), so `explore` / `read-write` / `execute` all break the contract |
| `polish` | `polish.sh` | `general-purpose` | reads and rewrites the task file only; the one role where `capability_mode: read-write` would be a safe future restriction — its entry in the seam is where to add it |
| `chain` | `chat.sh`, `sprintbias_next_blocked_resolution` | `general-purpose` | hands a task toward READY in a fresh context — defines/edits task files |

A future specialization is a one-line change in `sprintbias_subagent_type_for`, not
edits across the four call sites.

Emit prompts get wording from `sprintbias_subagent_*` helpers in `lib.sh` so Claude
says "Task tool" and Grok says `spawn_subagent`. Because nesting is depth-one,
every spawned worker's instruction carries `sprintbias_subagent_no_nest` — a
tier-worded line telling the worker it is a worker, not an orchestrator, and must
not re-spawn. It rides in the `work`, `gate`, and `polish` emit fan-outs.

## Orchestration

Shared helper: `sprintbias_orchestration_capable` is true for `claude-code` and
`grok-build`. Used by:

- `work.sh` emit multi-task
- `gate.sh` / `gate-lib.sh` / `plan-start.sh` multi-member
- `polish.sh` multi-task judge
- `chat.sh` continue-the-chain
- `lib.sh` `sprintbias_next_blocked_resolution` Path A

## Models

| Source | Behavior |
|--------|----------|
| `MODEL_*` config | Honored via `--model` after coerce |
| Empty + tier model | Every AI command uses `sprintbias_tier_model` → `grok-4.5` |
| Claude-only pins (`opus`/`sonnet`/…) | Coerced to `grok-4.5` (lib + `cli/grok.sh`) |
| Grok profile exec/interactive | Always passes `--model` (never omits; default `grok-4.5`) |
| Per-script pins | `MODEL_CHAT` / `MODEL_WORK` / `MODEL_GATE` / … |
| Per-run provider | `./sprint.sh -g …` → `CLI=grok` + `PROVIDER=grok-build` for that run |

## Setup

1. Install Grok Build so `grok` is on PATH
2. `./setup.sh` → choose **Grok Build** → writes `CLI=grok` `PROVIDER=grok-build`
   (or edit `docs/sprintbias/config` the same way; no reinstall needed to switch)
3. Optional: pin `MODEL_DEFAULT=grok-4.5` (or leave empty for tier default)
4. Inside Grok: `./sprint.sh chat` / `work` / `polish` → emit
5. Terminal: same commands → exec launches `grok`
6. Parallel: `./sprint.sh work --fast`
7. Per-run override (does not rewrite config): `./sprint.sh -g work` or
   `./sprint.sh --grok chat 12` (peer: `-c` / `--claude`)

Grok auto-loads `AGENTS.md` / `CLAUDE.md` when present — no mandatory extra
shipping pointer file.

## Capability matrix row

See `docs/sprintbias/ai/provider-capabilities.md` (single source of truth).

## Out of scope (follow-ups)

Claude stream-json filter parity, invented budget caps, Grok `workflow` as
orchestrator (prefer `spawn_subagent` for Claude parity), Gemini/Mistral
profiles.

## Related

| Path | Role |
|------|------|
| `docs/guides/dual-provider-smoke.md` | Pre-release smoke ritual for both hosts |
| `docs/guides/claude-provider-tier.md` | As-built peer tier |
| `docs/guides/command-matrix.md` | Live command names |
| `docs/plans/5-grok-build-first-class-provider.md` | Plan + member tasks |
| `docs/sprintbias/cli/grok.sh` | Profile |
| `docs/sprintbias/guides/use_chat.md` | chat modes |
