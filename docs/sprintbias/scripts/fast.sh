#!/usr/bin/env bash
# fast.sh — show or flip fast mode. No AI is invoked. See: ./sprint.sh help fast
#
#   fast        print the current state, where it comes from, and how to flip it
#   fast on     write FAST=on  to docs/sprintbias/config.local
#   fast off    write FAST=off to docs/sprintbias/config.local (steady)
#
# The switch is per machine: config.local is gitignored and never ships, so
# the tracked config stays untouched. Scripts read the mode through
# sprintbias_fast_on (lib.sh).

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPTS_DIR/.." && pwd)/lib.sh"

# Where the effective value comes from, matching sprintbias_fast_on's order.
fast_source() {
    if [ -n "${SPRINTBIAS_FAST:-}" ]; then
        echo "this run (--fast / --steady or env SPRINTBIAS_FAST)"
    elif _sprintbias_cfg_read_file FAST "$SPRINTBIAS_CONFIG_LOCAL_FILE" >/dev/null; then
        echo "docs/sprintbias/config.local"
    elif [ -n "$(_sprintbias_cfg_read_file FAST "$SPRINTBIAS_CONFIG_FILE" || true)" ]; then
        echo "docs/sprintbias/config"
    else
        echo "default"
    fi
}

show_state() {
    local state label
    state="$(sprintbias_fast_state)"
    if [ "$state" = "on" ]; then label="autonomous, high throughput"; else label="steady"; fi
    echo -e "${CYAN}fast: ${state}${NC}  ($label — from $(fast_source))"
}

case "${1:-}" in
    "")
        show_state
        echo ""
        echo "Flip it for this machine:"
        echo "  ./sprint.sh fast on     # agents decide and keep going"
        echo "  ./sprint.sh fast off    # steady: agents stop to ask"
        echo "One run only:  ./sprint.sh --fast <command>  /  ./sprint.sh --steady <command>"
        ;;
    on|off)
        sprintbias_cfg_set FAST "$1" "$SPRINTBIAS_CONFIG_LOCAL_FILE"
        echo -e "${GREEN}✓${NC} FAST=$1 saved to docs/sprintbias/config.local"
        show_state
        ;;
    *)
        echo -e "${RED}✗ Unknown argument: $1${NC}" >&2
        echo "  Usage: ./sprint.sh fast [on|off]" >&2
        exit 1
        ;;
esac
