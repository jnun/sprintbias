# Claude Provider Tier (as built)

How SprintBias runs at full strength today when the AI provider is **Claude Code**.
This is one of two first-class orchestration tiers (peer: **Grok Build** —
`docs/guides/grok-provider-tier.md`). Other providers degrade from these designs,
not the other way around. Living KK/KU inventory:
`docs/guides/provider-reality.md`.

Ship truth for flags and gates lives in code; this guide is the human/agent map
of that design. Capability matrix: `docs/sprintbias/ai/provider-capabilities.md`.

## Identity

Field				Value
Tier name			claude-code
CLI binary			claude
Profile				docs/sprintbias/cli/claude.sh
Config				CLI=claude and PROVIDER=claude-code in docs/sprintbias/config
Setup pick			Claude Code (default in setup.sh)
Instruction file	CLAUDE.md (optional create/prepend at install)

## Two modes

Mode	When																		What happens
emit	Inside Claude Code (CLAUDECODE / CLAUDE_CODE_SESSION_ID set, or MODE=emit)	Print the prompt into this session. The driver agent runs it. No nested claude process.
exec	Plain terminal, CI, loops (MODE empty and no agent env, or MODE=exec)		Spawn claude via the profile. One-shot or interactive depending on the command.

Auto-detect prefers emit when already in an agent so you never nest CLIs. Override
with MODE=emit or MODE=exec in config.

## Neutral interface

Scripts never call claude flags directly. They call one of these and the profile
maps them.

Call						Use
sprintbias_run				One-shot job (work, gate, polish, plan think, …)
sprintbias_run_interactive	Live dialogue (chat, profile, conversational creates)
sprintbias_ai_tier			Returns claude-code so scripts can branch
sprintbias_tier_model SFX		Model for a script; on this tier empty config → opus for heavy flows
sprintbias_interactive_ok		True when exec + profile interactive + real TTY

## Flag map (neutral → Claude)

Neutral flag			Claude flag						Notes
-p PROMPT				-p PROMPT						Headless print mode; single response then exit
positional prompt		positional						Interactive only — starts the REPL on that message
--model					--model							From MODEL_* / SPRINTBIAS_MODEL_* / tier default
--max-turns				--max-turns						Caps agent turns on long jobs
--tools					--allowedTools					Claude tool names: Read, Edit, Write, Bash, Grep, Glob, …
--permissions			--permission-mode				e.g. auto
--skip-permissions		--dangerously-skip-permissions	Unattended loops / batch
--output-format			--output-format					json; may upgrade to stream-json for live progress
--budget				--max-budget-usd				Spend cap when set. Claude is the only budget-capable tier (sprintbias_budget_capable), so it is the only one call sites send this to
--name					--name							Session label
--append-system-prompt	--append-system-prompt			Extra system rules for the run

## Profile extras (exec only)

These live in cli/claude.sh. Other tiers do not get them for free.

Extra				What it does
Stream filter		When JSON + stderr is a TTY, upgrade to stream-json and narrate tool steps on stderr
Transient retry		Resume the same session after connection drops (SPRINTBIAS_RETRIES, SPRINTBIAS_RETRY_WAIT)
Wall-clock cap		Kill a wedged attempt after SPRINTBIAS_ATTEMPT_TIMEOUT (needs gtimeout/timeout)
Interactive gate	SPRINTBIAS_PROVIDER_INTERACTIVE=1 so chat can host a live REPL

## Orchestration (why Claude is fast)

The product idea is simple: **one fresh context per unit of work**, orchestrated
from a thin driver session. Unrelated tasks do not share a prompt window.

Command					Emit on claude-code																									Exec on claude-code
work					Driver prompt: one Task-tool subagent per task file; parallel when --fast/--parallel; route doing → review/blocked	One claude process per task (parallel jobs = parallel processes)
gate (many files)		One subagent per task, all in parallel, shared review contract														Per-file / sequential via sprintbias_run as coded
plan start (many)		Same gate parallel path (`sprintbias_gate_parallel`) for multi-member promote											Per-file gate via sprintbias_run
polish (many)			One judge subagent per task; route by verdict																		Per-file sprintbias_run
promote --audit (many)	One acceptance-judge subagent per task; route DONE → done/ (with --move)												Per-file sprintbias_run, sequential
chat chain				After READY, spawn a NEW subagent for ./sprint.sh chat next-id														Print or run the next chat command; human continues
next→blocked handoff	Same: fresh Task subagent for the upstream blocked dep																Command to run in a fresh window
plan think				Dual-persona critique via sprintbias_run (full flag surface)															Same through the profile

Token-saving rule the prompts encode: the orchestrator moves files and
dispatches; subagents do the work; contexts never pile into one mega-session.

## Models

Source							Behavior
MODEL_DEFAULT / MODEL_CHAT / …	Config or SPRINTBIAS_MODEL_* env
Empty + sprintbias_tier_model		On claude-code only: fall back to opus for reasoning-heavy scripts (feature, idea, chat, …)
Empty + other resolve paths		CLI picks its own default

## What scripts gate on claude-code today

These branches are intentional. Generic tiers get the honest sequential path.

Script		Gate
work.sh	Emit orchestration vs sequential fallback
gate.sh	Parallel multi-file emit review
gate-lib.sh	Shared parallel prompt ("Task tool") used by gate + plan start
plan-start.sh	Multi-member emit gate via sprintbias_gate_parallel
polish.sh	Parallel multi-file emit judge
promote.sh	--audit: emit acceptance judge (orchestrator/standalone) vs sequential exec loop
chat.sh		Continue-the-chain subagent wording
lib.sh		next→blocked Path A subagent wording; sprintbias_tier_model opus default

## User path (Claude)

Step	Action
1		Install Claude Code so claude is on PATH
2		./setup.sh → pick Claude Code (or keep CLI=claude PROVIDER=claude-code)
3		Inside Claude Code: run ./sprint.sh chat / work / polish — emit mode
4		From a plain terminal: same commands — exec launches claude
5		Parallel batch: ./sprint.sh work --fast (or --parallel --jobs N)
6		Per-run override (no config rewrite): ./sprint.sh -c work or --claude (peer: -g / --grok)

## Related

Path											Role
docs/guides/dual-provider-smoke.md				Pre-release smoke ritual for both hosts
docs/sprintbias/cli/claude.sh						Profile implementation
docs/sprintbias/lib.sh							Mode, tier, run helpers
docs/sprintbias/ai/provider-capabilities.md		Matrix source of truth
docs/sprintbias/guides/use_chat.md				chat emit vs exec vs degraded
docs/guides/grok-provider-tier.md				Target design for a peer Grok tier
docs/plans/5-grok-build-first-class-provider.md	Work plan to ship Grok as a peer
