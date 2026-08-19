#!/usr/bin/env bash
# learn.sh — Play a shipped, sandboxed demo. See: ./sprint.sh help learn
#
# Thin launcher over docs/sprintbias/learning/*.py. No argument lists every demo
# with the first line of its docstring; a name plays it (flags pass straight
# through). Demos are pure terminal theater — python3 + stdlib only — and they
# touch nothing in your project. Drop a new *.py into learning/ and it shows up
# here automatically; no edit to this launcher.
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEARN_DIR="$SCRIPT_DIR/../learning"

# First non-empty line of a python module docstring — the demo's one-line
# summary. Pure awk so listing works even when python3 is missing.
_docline() {
    awk '
        /"""/ && !started {
            started = 1
            rest = $0; sub(/.*"""/, "", rest)
            if (rest ~ /[^ \t]/) { print rest; exit }
            next
        }
        started { if ($0 ~ /[^ \t]/) { print; exit } }
    ' "$1"
}

# List every demo as "name   summary". Sorted, stable, auto-registering.
_list_demos() {
    local found=0 f name
    for f in "$LEARN_DIR"/*.py; do
        [ -e "$f" ] || continue
        found=1
        name="$(basename "$f" .py)"
        printf "  ${CYAN}%-12s${NC} %s\n" "$name" "$(_docline "$f")"
    done
    [ "$found" -eq 1 ] || echo "  (no demos found in $LEARN_DIR)"
}

_usage() {
    echo -e "${CYAN}Interactive demos${NC} — watch the SprintBias flow run, safely."
    echo ""
    echo "Available demos (play one with:  ./sprint.sh learn <name>):"
    echo ""
    _list_demos
    echo ""
    echo -e "${BLUE}Everything is theater — a demo touches nothing in your project.${NC}"
    echo "Flags pass through, e.g.  ./sprint.sh learn example --fast"
}

NAME="${1:-}"

# No argument → show the catalog.
if [ -z "$NAME" ]; then
    _usage
    exit 0
fi

DEMO="$LEARN_DIR/$NAME.py"
if [ ! -f "$DEMO" ]; then
    echo -e "${RED}Unknown demo: $NAME${NC}"
    echo ""
    echo "Available demos:"
    _list_demos
    exit 1
fi

# Fail soft when the runtime is missing — explain and point at the manual.
if ! command -v python3 >/dev/null 2>&1; then
    echo -e "${YELLOW}Can't play '$NAME': python3 was not found on your PATH.${NC}"
    echo "The demos need python3 (stdlib only — no packages to install)."
    echo "Install python3, then re-run:  ./sprint.sh learn $NAME"
    echo "More: DOCUMENTATION.md → Commands → learn"
    exit 1
fi

# Hand off to the demo; flags after the name pass through unchanged.
shift
exec python3 "$DEMO" "$@"
