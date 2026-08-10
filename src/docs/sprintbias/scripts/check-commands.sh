#!/usr/bin/env bash
# check-commands.sh — Command-surface completeness check.
#
# The command catalog is exposed through four surfaces that must agree:
#   1. the registry   docs/sprintbias/help/_registry   (the source of truth)
#   2. the dispatch   sprint.sh  (the case arms that route to cmd_* functions)
#   3. the help pages docs/sprintbias/help/<cmd>.md
#   4. the manual     DOCUMENTATION.md
# This asserts every user-facing command is present in all four, so a new
# command can never be silently missing from a surface. See: help validate.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

REGISTRY="$PROJECT_ROOT/docs/sprintbias/help/_registry"
DISPATCH="$PROJECT_ROOT/sprint.sh"
HELP_DIR="$PROJECT_ROOT/docs/sprintbias/help"
MANUAL="$PROJECT_ROOT/DOCUMENTATION.md"

# Commands that intentionally live in dispatch but are NOT catalogued —
# only the help command itself. Keep this list tiny; every entry is a
# command deliberately hidden from the registry.
HIDDEN=" help "

for f in "$REGISTRY" "$DISPATCH" "$MANUAL"; do
    [ -f "$f" ] || { echo -e "${RED}✗ Missing: $f${NC}"; exit 1; }
done

echo -e "${CYAN}=== Command-surface completeness (registry ↔ dispatch ↔ help ↔ manual) ===${NC}"
echo ""

# ── Gather the sets ──────────────────────────────────────────────────
# Registry: field 1 of each non-comment row, deduped (validate has 3 rows).
# tr -d ' \t' (not [:space:]) so the newlines BETWEEN commands survive.
REG_CMDS=$(grep -vE '^[[:space:]]*#' "$REGISTRY" | grep -E '\|' \
    | cut -d'|' -f1 | tr -d ' \t' | grep -E '.' | sort -u)

# Dispatch: case arms that route to a cmd_* function (help/*/"" have no
# cmd_ call and are skipped; HIDDEN filters intentional non-registry entries).
DISPATCH_CMDS=$(awk '/^[[:space:]]*[a-z][a-z-]*\)[[:space:]]/ && /cmd_/ {
        sub(/\).*/, "", $1); gsub(/[[:space:]]/, "", $1); print $1
    }' "$DISPATCH" | sort -u)

is_hidden()   { case "$HIDDEN" in *" $1 "*) return 0 ;; *) return 1 ;; esac; }
in_dispatch() { printf '%s\n' "$DISPATCH_CMDS" | grep -qxF "$1"; }
in_registry() { printf '%s\n' "$REG_CMDS" | grep -qxF "$1"; }

fail=0

# ── Check 1: every registered command actually dispatches ────────────
_missing=""
for c in $REG_CMDS; do in_dispatch "$c" || _missing="$_missing $c"; done
if [ -n "$_missing" ]; then
    fail=1
    echo -e "${RED}✗ In the registry but NOT dispatched by sprint.sh:${NC}"
    for c in $_missing; do echo "    $c   — add a case arm, or remove the registry row"; done
    echo ""
fi

# ── Check 2: every dispatched command is registered (the drift that hides
#            a new command from the index/manual/help) ─────────────────
_missing=""
for c in $DISPATCH_CMDS; do
    is_hidden "$c" && continue
    in_registry "$c" || _missing="$_missing $c"
done
if [ -n "$_missing" ]; then
    fail=1
    echo -e "${RED}✗ Dispatched by sprint.sh but NOT in the registry (so it is invisible in ./sprint.sh help):${NC}"
    for c in $_missing; do echo "    $c   — add a row to $REGISTRY"; done
    echo ""
fi

# ── Check 3: every registered command has a help page ────────────────
_missing=""
for c in $REG_CMDS; do [ -f "$HELP_DIR/$c.md" ] || _missing="$_missing $c"; done
if [ -n "$_missing" ]; then
    fail=1
    echo -e "${RED}✗ Registered but missing a help page (./sprint.sh help <cmd> would 404):${NC}"
    for c in $_missing; do echo "    $c   — create docs/sprintbias/help/$c.md"; done
    echo ""
fi

# ── Check 4: every registered command is in the manual ───────────────
_missing=""
for c in $REG_CMDS; do
    grep -qE "sprint\.sh ${c}([[:space:]]|\$)" "$MANUAL" || _missing="$_missing $c"
done
if [ -n "$_missing" ]; then
    fail=1
    echo -e "${RED}✗ Registered but absent from DOCUMENTATION.md §Commands:${NC}"
    for c in $_missing; do echo "    $c   — add a line to the Commands block in $MANUAL"; done
    echo ""
fi

# ── Check 5: every registry group is one of the six families ─────────
#            (guards the "no parallel taxonomy" rule — the matrix demands
#            create · chat · plan · work · look · keep and nothing else).
ALLOWED_GROUPS=" create chat plan work look keep "
_badgroups=""
while IFS='|' read -r _c _g _rest; do
    _c="${_c//[[:space:]]/}"
    case "$_c" in ''|'#'*) continue ;; esac
    _g="${_g//[[:space:]]/}"
    case "$ALLOWED_GROUPS" in
        *" $_g "*) ;;
        *) _badgroups="$_badgroups ${_c}:${_g}" ;;
    esac
done < "$REGISTRY"
if [ -n "$_badgroups" ]; then
    fail=1
    echo -e "${RED}✗ Registry rows with a group outside create|chat|plan|work|look|keep:${NC}"
    for bg in $_badgroups; do echo "    $bg   — use one of the six family groups"; done
    echo ""
fi

# ── Check 6: registry row shape — no field may contain a literal '|' ──
#            The registry is pipe-delimited and sprint.sh splits it with
#            IFS='|'. One stray pipe inside a field silently shifts every
#            later field: the summary vanishes from the generated index and
#            demo_for_cmd reads the summary as a demo name. Two cheap guards:
#            a hard field-count cap, and 5th-field validity (when present it
#            must name a real learning/<demo>.py) — the second also catches a
#            stray pipe that happens to land on a legal field count.
_badrows=""
while IFS='|' read -r _c _g _u _s _d _extra; do
    _c="${_c//[[:space:]]/}"
    case "$_c" in ''|'#'*) continue ;; esac
    if [ -n "${_extra:-}" ]; then
        _badrows="$_badrows ${_c}:over-5-fields"
        continue
    fi
    _d="${_d//[[:space:]]/}"
    if [ -n "$_d" ] && [ ! -f "$PROJECT_ROOT/docs/sprintbias/learning/${_d}.py" ]; then
        _badrows="$_badrows ${_c}:no-demo(${_d})"
    fi
done < "$REGISTRY"
if [ -n "$_badrows" ]; then
    fail=1
    echo -e "${RED}✗ Malformed registry row(s) — a field contains a literal '|':${NC}"
    for br in $_badrows; do
        case "$br" in
            *:over-5-fields) echo "    ${br%%:*}   — more than 5 fields; remove the stray pipe" ;;
            *) echo "    ${br%%:*}   — field 5 ${br#*:no-demo} is not a learning/<demo>.py; a pipe likely shifted the fields" ;;
        esac
    done
    echo ""
fi

_count=$(printf '%s\n' "$REG_CMDS" | grep -cE '.')
if [ "$fail" -eq 0 ]; then
    echo -e "${BLUE}Checked $_count command(s) across all four surfaces.${NC}"
    echo -e "${CYAN}✓ Every command is fully surfaced.${NC}"
    exit 0
else
    echo -e "${BLUE}Checked $_count registered command(s).${NC}"
    echo -e "${RED}⚠ Command-surface drift found — fix the surface(s) above.${NC}"
    exit 1
fi
