#!/usr/bin/env bash
set -euo pipefail

# cleanup-tmp.sh — Clear scratch files. See: ./sprint.sh help cleanup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/docs/sprintbias/scripts" ]; then
    PROJECT_ROOT="$SCRIPT_DIR"
else
    PROJECT_ROOT="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
fi

TMP_DIR="$PROJECT_ROOT/docs/tmp"

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

MODE="${1:-}"
STALE_DAYS=7

if [ ! -d "$TMP_DIR" ]; then
    echo -e "${GREEN}docs/tmp/ not found. Nothing to clean.${NC}"
    exit 0
fi

# Get file age in days from mtime
file_age_days() {
    local file="$1"
    local mtime_epoch now_epoch
    if stat -f "%m" "$file" >/dev/null 2>&1; then
        mtime_epoch=$(stat -f "%m" "$file")
    elif stat -c "%Y" "$file" >/dev/null 2>&1; then
        mtime_epoch=$(stat -c "%Y" "$file")
    else
        echo 0; return
    fi
    now_epoch=$(date "+%s")
    echo $(( (now_epoch - mtime_epoch) / 86400 ))
}

format_age() {
    local days="$1"
    if [ "$days" -eq 0 ]; then echo "today"
    elif [ "$days" -eq 1 ]; then echo "1 day ago"
    else echo "${days} days ago"
    fi
}

# Classify files into stale (auto-clean) vs recent (keep unless --all)
stale=()
recent=()

while IFS= read -r file; do
    rel="${file#$TMP_DIR/}"
    age=$(file_age_days "$file")

    # Always stale: AI session logs (log-*.json), including nested ones
    if [[ "${rel##*/}" == log-*.json ]]; then
        stale+=("$file")
        continue
    fi

    # Stale if older than threshold
    if [ "$age" -ge "$STALE_DAYS" ]; then
        stale+=("$file")
    else
        recent+=("$file")
    fi
done < <(find "$TMP_DIR" -type f -not -name '.gitkeep' -not -name '.DS_Store' | sort)

total_count=$(( ${#stale[@]} + ${#recent[@]} ))

if [ "$total_count" -eq 0 ]; then
    echo -e "${GREEN}docs/tmp/ is clean. Nothing to remove.${NC}"
    exit 0
fi

# Report
echo -e "${CYAN}=== docs/tmp/ cleanup ===${NC}"
echo ""

if [ ${#stale[@]} -gt 0 ]; then
    echo -e "${RED}Stale (${#stale[@]} files):${NC}"
    for file in "${stale[@]}"; do
        rel="${file#$TMP_DIR/}"
        age=$(file_age_days "$file")
        echo -e "  ${RED}✗${NC} $rel ${DIM}($(format_age "$age"))${NC}"
    done
    echo ""
fi

if [ ${#recent[@]} -gt 0 ]; then
    echo -e "${GREEN}Recent (${#recent[@]} files — keeping):${NC}"
    for file in "${recent[@]}"; do
        rel="${file#$TMP_DIR/}"
        age=$(file_age_days "$file")
        echo -e "  ${GREEN}✓${NC} $rel ${DIM}($(format_age "$age"))${NC}"
    done
    echo ""
fi

# Only stale files are ever removed. Recent files are kept; a user who wants
# everything gone can rm -rf docs/tmp/ themselves.
if [ ${#stale[@]} -eq 0 ]; then
    echo -e "${GREEN}Nothing stale to clean. ${#recent[@]} recent files kept.${NC}"
    exit 0
fi

targets=("${stale[@]}")

# Confirm unless --force (for scripts and CI where no one answers y/N).
if [ "$MODE" != "--force" ]; then
    echo -en "Delete ${#stale[@]} stale files? [y/N] "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy] ]]; then
        echo "Aborted."
        exit 0
    fi
fi

deleted=0
for file in "${targets[@]}"; do
    rel="${file#$TMP_DIR/}"
    if rm -- "$file" 2>/dev/null; then
        echo -e "  ${RED}Deleted${NC} $rel"
        deleted=$((deleted + 1))
    else
        echo -e "  ${YELLOW}Could not delete${NC} $rel"
    fi
done

# Remove empty subdirectories (but not the tmp dir itself)
find "$TMP_DIR" -mindepth 1 -type d -empty -delete 2>/dev/null || true
echo -e "\n${GREEN}Cleared ${deleted} files from docs/tmp/${NC}"
