#!/usr/bin/env bash
# docs/sprintbias/cli/grok.sh — Grok Build CLI profile for SprintBias
#
# Defines sprintbias_provider_exec() and sprintbias_provider_interactive(), mapping
# the provider-neutral interface used by SprintBias scripts to Grok Build's CLI.
#
# Sourced automatically by lib.sh when SPRINTBIAS_CLI=grok.
#
# Verified against `grok --help` (2026-08-07): -p/--single, -m/--model,
# --max-turns, --tools (internal IDs), --permission-mode, --always-approve,
# --output-format (plain|json|streaming-json|streaming-messages-json), --rules.
#
# Claude → Grok format aliases (call sites like work.sh pass Claude names):
#   stream-json → streaming-messages-json  (Anthropic Messages NDJSON; matches
#     work.sh's progress filter and Claude-shaped result events)
#   --verbose is Claude-only (required for Claude stream-json); dropped here.
#
# Intentionally NOT ported from claude.sh: transient resume loop, wall-clock
# timeout. Native Grok streaming-json events (text/thought/end) differ from
# Claude; use streaming-messages-json when callers want Claude-shaped streams.

# Map Claude-style / neutral tool names → Grok internal IDs for headless --tools.
# Prints the comma-separated allowlist on success.
# Fail-open: if any name is unmapped (and not a known skip), returns non-zero
# so the caller omits --tools entirely — a wrong empty allowlist is worse than none.
# Agent/Task/spawn_subagent are not --tools entries on Grok (subagents are
# prompt-language spawn_subagent); they are skipped, not treated as unknown.
_sprintbias_grok_map_tools() {
  local input="$1"
  local result="" t mapped
  local unknown=0
  local IFS=','

  for t in $input; do
    # trim whitespace
    t="${t#"${t%%[![:space:]]*}"}"
    t="${t%"${t##*[![:space:]]}"}"
    [ -n "$t" ] || continue
    case "$t" in
      Read|read_file)                          mapped=read_file ;;
      Edit|search_replace)                     mapped=search_replace ;;
      Write|write)                             mapped=write ;;
      Bash|run_terminal_command|run_terminal_cmd) mapped=run_terminal_command ;;
      Grep|grep)                               mapped=grep ;;
      Glob|list_dir)                           mapped=list_dir ;;
      # Subagent spawn is prompt language, not a headless --tools allowlist entry.
      Agent|Task|spawn_subagent)               continue ;;
      *)                                       unknown=1; break ;;
    esac
    case ",${result}," in
      *",${mapped},"*) ;;
      *) result="${result:+$result,}${mapped}" ;;
    esac
  done

  if [ "$unknown" -eq 1 ]; then
    return 1
  fi
  printf '%s' "$result"
  return 0
}

sprintbias_provider_exec() {
  # ── Parse provider-neutral arguments ──────────────────────────────
  local prompt="" model="" max_turns="" tools="" permissions=""
  local output_format="" budget="" name="" system_prompt=""
  local skip_permissions=0
  local -a extra_args=()
  local -a dropped=()

  while [ $# -gt 0 ]; do
    case "$1" in
      -p)                     prompt="$2";        shift 2 ;;
      --model)                model="$2";         shift 2 ;;
      --max-turns)            max_turns="$2";     shift 2 ;;
      --tools)                tools="$2";         shift 2 ;;
      --permissions)          permissions="$2";   shift 2 ;;
      --output-format)        output_format="$2"; shift 2 ;;
      --budget)               [ -n "$2" ] && dropped+=("budget caps"); budget="$2"; shift 2 ;;
      --name)                 [ -n "$2" ] && dropped+=("session name"); name="$2"; shift 2 ;;
      --append-system-prompt) system_prompt="$2"; shift 2 ;;
      --skip-permissions)     skip_permissions=1; shift ;;
      # Claude stream-json requires --verbose; Grok has no equivalent flag.
      --verbose)              shift ;;
      --)                     shift; extra_args+=("$@"); break ;;
      *)                      extra_args+=("$1"); shift ;;
    esac
  done

  # Warn once per session when valued Claude-only flags are dropped.
  if [ ${#dropped[@]} -gt 0 ] && [ -z "${_SPRINTBIAS_GROK_DROP_WARNED:-}" ]; then
    local list
    list=$(printf '%s, ' "${dropped[@]}"); list="${list%, }"
    printf 'SprintBias: grok profile — %s not supported by Grok CLI; running without them.\n' \
      "$list" >&2
    _SPRINTBIAS_GROK_DROP_WARNED=1
  fi

  # Map Claude / neutral output-format names onto Grok CLI values.
  # work.sh (and Claude-shaped filters) pass stream-json; Grok rejects it.
  # streaming-messages-json is Anthropic Messages NDJSON — same event types
  # (assistant / result) the work progress filter already understands.
  case "$output_format" in
    stream-json) output_format="streaming-messages-json" ;;
  esac

  # Map tool allowlist; fail-open (omit) if unmapped names appear.
  local mapped_tools=""
  if [ -n "$tools" ]; then
    if ! mapped_tools="$(_sprintbias_grok_map_tools "$tools")"; then
      if [ -z "${_SPRINTBIAS_GROK_TOOLS_WARNED:-}" ]; then
        printf 'SprintBias: grok profile — unmapped tools in allowlist; omitting --tools (fail-open).\n' >&2
        _SPRINTBIAS_GROK_TOOLS_WARNED=1
      fi
      mapped_tools=""
    fi
  fi

  # Always pin a Grok-native model id. Coerce Claude-only aliases (opus/sonnet/…)
  # when a caller bypassed lib resolve; empty → grok-4.5. No grok exec omits
  # --model, and none ever forwards an unknown Claude id.
  if declare -F sprintbias_coerce_model >/dev/null 2>&1; then
    model="$(sprintbias_coerce_model "$model")"
  else
    case "$model" in
      opus|sonnet|haiku|OPUS|SONNET|HAIKU|claude*|Claude*|CLAUDE*) model="grok-4.5" ;;
    esac
  fi
  [ -n "$model" ] || model="grok-4.5"

  # ── Build command ─────────────────────────────────────────────────
  local -a cmd=("$SPRINTBIAS_CLI")

  [ -n "$system_prompt" ] && cmd+=(--rules "$system_prompt")
  [ -n "$prompt" ]        && cmd+=(-p "$prompt")
  cmd+=(--model "$model")
  [ -n "$max_turns" ]     && cmd+=(--max-turns "$max_turns")
  [ -n "$mapped_tools" ]  && cmd+=(--tools "$mapped_tools")
  [ -n "$output_format" ] && cmd+=(--output-format "$output_format")

  if [ "$skip_permissions" -eq 1 ]; then
    cmd+=(--always-approve)
  elif [ -n "$permissions" ]; then
    cmd+=(--permission-mode "$permissions")
  fi

  if [ ${#extra_args[@]} -gt 0 ]; then
    cmd+=("${extra_args[@]}")
  fi

  "${cmd[@]}"
}

# This provider can host a live interactive session (see sprintbias_interactive_ok
# in lib.sh). Set at source time so the gate sees it.
SPRINTBIAS_PROVIDER_INTERACTIVE=1

# sprintbias_provider_interactive — launch a live Grok Build TUI session.
#
# Same contract as cli/claude.sh: no stdout capture, no -p (which forces
# headless print-and-exit), opening message as a positional so the session
# starts on it yet stays interactive. Headless-only flags are consumed.
sprintbias_provider_interactive() {
  local prompt="" model="" tools="" permissions="" name="" system_prompt=""
  local skip_permissions=0
  local -a extra_args=()

  while [ $# -gt 0 ]; do
    case "$1" in
      -p)                     prompt="$2";        shift 2 ;;
      --model)                model="$2";         shift 2 ;;
      --tools)                tools="$2";         shift 2 ;;
      --permissions)          permissions="$2";   shift 2 ;;
      --name)                 name="$2";          shift 2 ;;
      --append-system-prompt) system_prompt="$2"; shift 2 ;;
      --skip-permissions)     skip_permissions=1; shift ;;
      # Headless / one-shot flags — consume so they never leak onto the TUI.
      --max-turns|--output-format|--budget) shift 2 ;;
      --verbose)              shift ;;
      --)                     shift; extra_args+=("$@"); break ;;
      *)                      extra_args+=("$1"); shift ;;
    esac
  done

  # Interactive TUI ignores --tools (and may warn); omit rather than pass.
  : "${tools:=}" "${name:=}"

  # Same model pin as exec: coerce Claude-only aliases; empty → grok-4.5.
  if declare -F sprintbias_coerce_model >/dev/null 2>&1; then
    model="$(sprintbias_coerce_model "$model")"
  else
    case "$model" in
      opus|sonnet|haiku|OPUS|SONNET|HAIKU|claude*|Claude*|CLAUDE*) model="grok-4.5" ;;
    esac
  fi
  [ -n "$model" ] || model="grok-4.5"

  local -a cmd=("$SPRINTBIAS_CLI")
  [ -n "$system_prompt" ] && cmd+=(--rules "$system_prompt")
  cmd+=(--model "$model")
  if [ "$skip_permissions" -eq 1 ]; then
    cmd+=(--always-approve)
  elif [ -n "$permissions" ]; then
    cmd+=(--permission-mode "$permissions")
  fi
  [ ${#extra_args[@]} -gt 0 ] && cmd+=("${extra_args[@]}")
  # Opening message as positional — -p would print one answer and exit.
  [ -n "$prompt" ] && cmd+=("$prompt")

  "${cmd[@]}"
}

# The Grok result reader, kept in a variable and run with `python3 -c` (same
# pattern as cli/claude.sh's _SPRINTBIAS_INTERPRET_PY). It writes five
# NUL-delimited fields on stdout — outcome, turns, cost, verdict text, summary
# (verdict/summary may be multiline, so NUL is the only safe separator). No
# single quotes in this code.
#
# Grok's buffered `--output-format json` is NOT Claude-shaped (verified against
# a real captured log, 2026-08-27 — see docs/guides/provider-reality.md):
#   result text  -> "text"          (Claude uses "result")
#   stop signal  -> "stopReason"    (Claude uses "is_error" + "subtype")
#   turns/cost   -> "num_turns" / "total_cost_usd"  (same keys as Claude)
# There is no is_error/subtype key, so the Claude-shaped fallback read every
# Grok run as finished. Map Grok's native stopReason instead:
#   cancelled                              -> max_turns  (under SprintBias every
#       headless call is turn-bounded, and Grok surfaces max-turns exhaustion as
#       stopReason=cancelled with "max turns reached" on stderr — which callers
#       suppress, so the log's stopReason is the only surviving signal)
#   end_turn / stop_sequence / max_tokens  -> finished
#   any other non-empty stopReason         -> error
#   empty stopReason                        -> finished if text present, else error
_SPRINTBIAS_GROK_INTERPRET_PY="$(cat <<'PYEOF'
import json, sys, re

def emit(outcome, turns="", cost="", verdict="", summary=""):
    sys.stdout.write("\0".join([outcome, str(turns), str(cost),
                                verdict, summary]) + "\0")
    sys.exit(0)

raw = open(sys.argv[1], encoding="utf-8", errors="replace").read()
try:
    d = json.loads(raw)
except Exception:
    # Grok writes a JSON object under --output-format json; a non-JSON log is a
    # last-resort case — grep raw text and let the caller find its verdict.
    emit("finished", "", "", raw, raw[-2000:] if len(raw) > 2000 else raw)

turns = d.get("num_turns", "")
cost = d.get("total_cost_usd", "")
text = d.get("text", "") or d.get("result", "") or ""
stop = (d.get("stopReason") or d.get("stop_reason") or "").lower()

def summarize(t):
    if not t:
        return ""
    m = re.search(r"## Summary\n(.*?)(?=\nVERDICT:|\Z)", t, re.DOTALL)
    if m:
        return m.group(1).strip()
    lines = t.strip().split("\n")
    vi = None
    for i, l in enumerate(lines):
        if "VERDICT:" in l:
            vi = i
    if vi is not None and vi > 0:
        return "\n".join(lines[max(0, vi - 30):vi]).strip()
    return t[-2000:] if len(t) > 2000 else t

if stop == "cancelled":
    emit("max_turns", turns, cost, text, summarize(text))
# Any non-normal stopReason means the run did not complete cleanly. Report
# error (never finished) so the caller does not trust a partial/aborted run.
if stop and stop not in ("end_turn", "stop_sequence", "max_tokens"):
    emit("error", turns, cost, text, summarize(text))
# Empty stopReason with no text at all: the object carried no usable result.
if not stop and not text:
    emit("error", turns, cost, text, summarize(text))
emit("finished", turns, cost, text, summarize(text))
PYEOF
)"

# profile_interpret_run LOG [rc] — the Grok reading of a run's result.
# Called by sprintbias_interpret_run (lib.sh). Parses Grok's buffered result
# JSON once and fills the normalized record the audits consume:
#   SPRINTBIAS_RUN_OUTCOME  finished | max_turns | no_start | error
#   SPRINTBIAS_RUN_TURNS / _COST / _VERDICT_TEXT / _SUMMARY
# empty/absent log -> no_start; otherwise the stopReason mapping documented on
# _SPRINTBIAS_GROK_INTERPRET_PY above. This is where the Grok JSON shape lives.
profile_interpret_run() {
  local log="$1"
  SPRINTBIAS_RUN_OUTCOME="" SPRINTBIAS_RUN_TURNS="" SPRINTBIAS_RUN_COST=""
  SPRINTBIAS_RUN_VERDICT_TEXT="" SPRINTBIAS_RUN_SUMMARY=""
  if [ ! -s "$log" ]; then
    SPRINTBIAS_RUN_OUTCOME="no_start"
    return 0
  fi
  {
    IFS= read -r -d '' SPRINTBIAS_RUN_OUTCOME
    IFS= read -r -d '' SPRINTBIAS_RUN_TURNS
    IFS= read -r -d '' SPRINTBIAS_RUN_COST
    IFS= read -r -d '' SPRINTBIAS_RUN_VERDICT_TEXT
    IFS= read -r -d '' SPRINTBIAS_RUN_SUMMARY
  } < <(python3 -c "$_SPRINTBIAS_GROK_INTERPRET_PY" "$log")
  return 0
}
