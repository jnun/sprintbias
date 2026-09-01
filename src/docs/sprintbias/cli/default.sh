#!/usr/bin/env bash
# docs/sprintbias/cli/default.sh — Bare-minimum CLI profile for SprintBias
#
# Fallback profile used when SPRINTBIAS_CLI is set to an unsupported provider
# or when no provider-specific profile exists.  Passes only the prompt via
# -p and any extra arguments.  All richer flags (model, tools, budget, turn
# and output-format caps) are dropped — but no longer silently: the first
# time a run actually supplies one, a one-line warning naming the dropped
# capabilities is printed to stderr (once per shell session).
#
# Sourced automatically by config.sh when no matching profile is found.

sprintbias_provider_exec() {
  local prompt=""
  local -a extra_args=()
  local -a dropped=()

  while [ $# -gt 0 ]; do
    case "$1" in
      -p)                    prompt="$2"; shift 2 ;;
      # Consume richer flags so they don't leak to the CLI, but note any that
      # carry a real value so we can warn the user they were dropped.
      --model)               [ -n "$2" ] && dropped+=("model selection");  shift 2 ;;
      --tools)               [ -n "$2" ] && dropped+=("tool restriction");  shift 2 ;;
      --budget)              [ -n "$2" ] && dropped+=("budget caps");       shift 2 ;;
      --max-turns)           [ -n "$2" ] && dropped+=("turn caps");         shift 2 ;;
      --output-format)       [ -n "$2" ] && dropped+=("JSON output");       shift 2 ;;
      --permissions|--name|--append-system-prompt)
                             shift 2 ;;
      --skip-permissions)    shift ;;
      --)                    shift; extra_args+=("$@"); break ;;
      *)                     extra_args+=("$1"); shift ;;
    esac
  done

  # Warn once per session, only when a dropped flag actually carried a value.
  if [ ${#dropped[@]} -gt 0 ] && [ -z "${_SPRINTBIAS_DROP_WARNED:-}" ]; then
    local list
    list=$(printf '%s, ' "${dropped[@]}"); list="${list%, }"
    printf 'SprintBias: %s has no profile — %s unsupported, running without them.\n' \
      "$SPRINTBIAS_CLI" "$list" >&2
    _SPRINTBIAS_DROP_WARNED=1
  fi

  local -a cmd=("$SPRINTBIAS_CLI")
  [ -n "$prompt" ] && cmd+=(-p "$prompt")

  if [ ${#extra_args[@]} -gt 0 ]; then
    cmd+=("${extra_args[@]}")
  fi

  "${cmd[@]}"
}

# profile_interpret_run LOG [rc] — the no-result-object reading of a run.
# Called by sprintbias_interpret_run (lib.sh). The default profile drops
# --output-format entirely, so the log is plain provider stdout with no result
# JSON to key off. Derive the normalized record from what a plain log does
# carry:
#   empty / absent log     -> no_start  (the CLI produced nothing at all)
#   rc given and non-zero  -> error     (the run exited badly, when a caller
#                                        threads the rc through as $2)
#   otherwise              -> finished  (caller greps its VERDICT token from
#                                        the raw text below)
# The raw stdout becomes the verdict text so the shared VERDICT grep still
# works, and its tail becomes the summary. There is no structured result here,
# so cost/turns have no honest source — they stay empty (unknown), never a
# faked 0. This is the first-class no-JSON case, not a Claude-shape assumption.
profile_interpret_run() {
  local log="$1" rc="${2:-}"
  SPRINTBIAS_RUN_OUTCOME="" SPRINTBIAS_RUN_TURNS="" SPRINTBIAS_RUN_COST=""
  SPRINTBIAS_RUN_VERDICT_TEXT="" SPRINTBIAS_RUN_SUMMARY=""
  if [ ! -s "$log" ]; then
    SPRINTBIAS_RUN_OUTCOME="no_start"
    return 0
  fi
  if [ -n "$rc" ] && [ "$rc" != "0" ]; then
    SPRINTBIAS_RUN_OUTCOME="error"
  else
    SPRINTBIAS_RUN_OUTCOME="finished"
  fi
  SPRINTBIAS_RUN_VERDICT_TEXT="$(cat "$log")"
  SPRINTBIAS_RUN_SUMMARY="$(tail -c 2000 "$log")"
  return 0
}

# No sprintbias_provider_interactive here on purpose: a generic CLI can't be
# trusted to host a live REPL, so this profile does not set
# SPRINTBIAS_PROVIDER_INTERACTIVE. sprintbias_interactive_ok then returns false and
# sprintbias_run_interactive routes chat to the one-shot sprintbias_provider_exec
# above — while chat.sh points the user at the guide for the full experience.
