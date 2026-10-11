#!/usr/bin/env bash
# help-ask.sh — read-only AI answer to a help question. See: ./sprint.sh help
#
# Reached from bare `./sprint.sh help` at a terminal: when the person's words
# match no single command, the prompt offers "Ask the AI instead? [y/N]" and a
# yes lands here with the question. The session is grounded in the registry,
# the help pages and the manual (ai/help-ask.md), answers with the
# ./sprint.sh command(s) to run, and edits no files: read tools only, plan
# permission mode, and fast mode held off so its skip-permissions never lifts
# that. -c / -g and the configured provider apply as for every AI command.

set -euo pipefail

# Read-only: fast mode would add --skip-permissions, which outranks plan mode.
export SPRINTBIAS_FAST=off

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"
cd "$_SPRINTBIAS_LIB_DIR/../.."

QUESTION="$*"
if [ -z "$QUESTION" ]; then
  echo "Usage: ./sprint.sh help   (at a terminal, then ask your question)"
  exit 1
fi

_MODEL="$(sprintbias_tier_model CHAT)"
_model_args=()
[ -n "$_MODEL" ] && _model_args=(--model "$_MODEL")

sprintbias_run_interactive \
  --append-system-prompt "$(cat "$_SPRINTBIAS_LIB_DIR/ai/help-ask.md")" \
  ${_model_args[@]+"${_model_args[@]}"} \
  --tools "Read,Grep,Glob" \
  --permissions "plan" \
  --name "help-ask" \
  "$QUESTION"
