#!/usr/bin/env bash
# agents.sh — see every AI session running here and on your servers. No AI.
# See: ./sprint.sh help agents
#
#   agents                  list sessions here and on each AGENT_HOSTS host
#   agents --local          this machine only
#   agents --host H         add a host for this run (repeatable)
#   agents --json           machine-readable output
#   agents label            title each session's terminal tab (tmux window) with its name
#
# Hosts are ssh aliases in AGENT_HOSTS (space-separated) in docs/sprintbias/config,
# or better config.local, since servers are personal. The work is in agents.py.

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPTS_DIR/.." && pwd)/lib.sh"

usage() {
  cat <<'USAGE'
Usage: ./sprint.sh agents [--local] [--host H]... [--json]   list running AI sessions
       ./sprint.sh agents label [--local] [--host H]...      title each session's terminal with its name
USAGE
}

if ! command -v python3 >/dev/null 2>&1; then
  echo -e "${YELLOW}agents needs python3 (stdlib only, nothing to install beyond it).${NC}"
  exit 1
fi

args=()
case "${1:-}" in
  -h|--help|help) usage; exit 0 ;;
  label) shift; args+=(--label) ;;
esac

# Configured hosts first; --host on the command line adds more.
for host in $(sprintbias_cfg AGENT_HOSTS); do args+=(--host "$host"); done

while [ $# -gt 0 ]; do
  case "$1" in
    --local) args+=(--local) ;;
    --json)  args+=(--json) ;;
    --host)
      [ -n "${2:-}" ] || { usage; exit 1; }
      args+=(--host "$2"); shift ;;
    *) usage; exit 1 ;;
  esac
  shift
done

exec python3 "$SCRIPTS_DIR/agents.py" "${args[@]}"
