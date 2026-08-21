#!/usr/bin/env bash
# plan.sh — Decisive plan verbs only. See: ./sprint.sh help plan
#
# Authoring is conversational: ./sprint.sh chat plan [id]
# This entry is the namespace for:
#   plan think  [id]  — dual-persona critique (plan-think.sh)
#   plan start  [id]  — commit members into next/ (plan-start.sh)
#   plan polish [id]  — excellence-judge the plan's finished work (plan-polish.sh)
#   plan done   [id]  — retire a plan whose every member is in done/ (plan-done.sh)
#
# The old auto-planner (theme guess + auto-move + cached plan file) is
# retired. Bare `plan` prints usage. next/ IS the sprint.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_sub() {
  local script="$SCRIPT_DIR/$1"
  shift
  if [ -x "$script" ]; then
    exec "$script" "$@"
  else
    exec bash "$script" "$@"
  fi
}

usage() {
  cat <<'EOF'
plan — decisive plan verbs (authoring is chat plan)

Usage:
  ./sprint.sh plan think  [id]   dual-persona critique of a plan
  ./sprint.sh plan start  [id]   commit plan members into next/ (the sprint)
  ./sprint.sh plan polish [id]   excellence-judge the plan's finished work (review/ + done/; --force re-judges)
  ./sprint.sh plan done   [id]   retire a plan once every member is in done/

  ./sprint.sh chat plan [id]     author/refine a plan conversationally
  ./sprint.sh newplan "<name>"   scaffold a new plan file

Bare `plan` no longer auto-selects backlog tasks. Group work with chat plan,
then plan start when READY.
EOF
}

case "${1:-}" in
  think)  shift; run_sub plan-think.sh "$@" ;;
  start)  shift; run_sub plan-start.sh "$@" ;;
  polish) shift; run_sub plan-polish.sh "$@" ;;
  done)   shift; run_sub plan-done.sh "$@" ;;
  -h|--help|help) usage; exit 0 ;;
  "")
    usage
    exit 0
    ;;
  *)
    echo "Unknown plan subcommand: $1" >&2
    echo "" >&2
    usage >&2
    exit 1
    ;;
esac
