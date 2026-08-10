#!/usr/bin/env bash
# validate-tasks.sh — Task-file integrity (IDs + dependency refs).
# See: ./sprint.sh help validate
#
# Default path checks what the runtime actually needs — numeric filename IDs,
# title/filename ID match, unique IDs across stages, and well-formed
# **Depends on** / **Dependents** tokens. Template-stamped presence checks
# (**Feature**, ## Problem, ## Success criteria) are not re-checked; those are
# guaranteed by create-task.sh from .TEMPLATE-task.md.
#
# Cycle detection among Depends-on edges is intentionally out of scope (v1).

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

# Options
FIX_MODE=false
DRY_RUN=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --fix)
            FIX_MODE=true
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --docs)
            # Delegate to the doc-drift checker (help/*.md vs script flags).
            exec bash "$SCRIPT_DIR/check-docs.sh"
            ;;
        --commands)
            # Delegate to the command-surface completeness checker
            # (registry ↔ dispatch ↔ help pages ↔ manual).
            exec bash "$SCRIPT_DIR/check-commands.sh"
            ;;
        --help|-h)
            echo "Usage: $0 [--fix] [--dry-run] [--docs] [--commands]"
            echo ""
            echo "Default: integrity checks on every task file under docs/tasks/*/"
            echo "  — numeric filename ID"
            echo "  — title ID matches filename"
            echo "  — no duplicate task IDs across stages"
            echo "  — **Depends on** / **Dependents** token shape (no cycle detection)"
            echo "  — **Tests** paths exist, live under docs/tests/, and are runnable (report only)"
            echo ""
            echo "Options:"
            echo "  --fix       Auto-fix safe issues (title-line ID + Plan reverse-index drift)"
            echo "  --dry-run   Show what --fix would change without writing"
            echo "  --docs      Check help/*.md for flag drift against scripts"
            echo "  --commands  Check every command is fully surfaced (registry/dispatch/help/manual)"
            echo "  --help      Show this help message"
            exit 0
            ;;
    esac
done

# Counters
TOTAL_FILES=0
VALID_FILES=0
INVALID_FILES=0
FIXED_FILES=0
REMAINING_INVALID=0
echo "🔍 Validating task integrity..."
echo ""

# ── Collect every task file (skip templates) ─────────────────────────
# Build a flat list of paths and an "id path" index for duplicate detection.
# Bash 3.2 has no associative arrays, so the index is a temp file.
TASK_FILES=()
ID_INDEX=$(mktemp)
trap 'rm -f "$ID_INDEX"' EXIT

for _stage in "${SPRINTBIAS_STAGES[@]}"; do
    task_dir="$PROJECT_ROOT/docs/tasks/$_stage"
    [ -d "$task_dir" ] || continue
    for file in "$task_dir"/*.md; do
        [ -e "$file" ] || continue
        filename=$(basename "$file")
        if [[ "$filename" == .TEMPLATE* ]] || [[ "$filename" == TEMPLATE* ]]; then
            continue
        fi
        TASK_FILES+=("$file")
        tid=$(task_id "$filename")
        # Index every file, even non-numeric IDs (those fail the per-file check)
        printf '%s\t%s\n' "$tid" "$file" >> "$ID_INDEX"
    done
done

# Duplicate numeric IDs across any stage (same N- prefix in two places, or
# two files sharing N). Non-numeric ids are ignored here — per-file check covers them.
DUP_IDS=$(awk '$1 ~ /^[0-9]+$/ {print $1}' "$ID_INDEX" | sort | uniq -d || true)

# id_is_duplicate N -> 0 if N is a known duplicate
id_is_duplicate() {
    local id="$1" d
    [ -z "$DUP_IDS" ] && return 1
    for d in $DUP_IDS; do
        [ "$d" = "$id" ] && return 0
    done
    return 1
}

# paths_for_id N -> newline-separated paths from the index
paths_for_id() {
    local id="$1"
    awk -F'\t' -v id="$id" '$1 == id { print $2 }' "$ID_INDEX"
}

# Check one dependency-style field (Depends on / Dependents). Prints one issue
# line per problem (caller collects into its local issues array — bash 3.2
# locals are not visible to callees). Numeric IDs that resolve to zero files
# are treated as archived/gone (OK). Malformed tokens are reported. Cycle
# detection is out of scope.
#
# Optional third arg is a legacy fallback field: if $field is absent, read it
# instead (used so **Dependents** falls back to the old **Blocks** spelling for
# one compatibility window). Issues are reported under whichever spelling was
# actually found, so the message names the field the file really uses.
check_id_list_field() {
    local file="$1" field="$2" fallback="${3:-}"
    local raw kind tok label="$2"
    raw=$(sprintbias_meta_value "$file" "$field")
    if [ -z "$raw" ] && [ -n "$fallback" ]; then
        raw=$(sprintbias_meta_value "$file" "$fallback")
        [ -n "$raw" ] && label="$fallback"
    fi
    [ -z "$raw" ] && return 0
    while read -r kind tok; do
        [ -n "$kind" ] || continue
        if [ "$kind" = "bad" ]; then
            printf 'Malformed **%s** token (not a task ID or none): %s\n' "$label" "$tok"
        fi
        # kind=id: bare number, present or archived — always OK for integrity
    done <<EOF
$(sprintbias_iter_id_list "$raw")
EOF
}

# check_tests_field FILE — Tests-field integrity (report-only, close-path).
# promote closes a review/ task only when every **Tests** path (legacy alias
# **Proven by**) runs green. A path that is a typo, missing, outside docs/tests/,
# or not a runnable script never promotes and never says why — the task strands
# in review/ forever (antifragile rule 6). Surface each here instead. Prints one
# "path → reason" line per problem; empty output means the field is clean. A
# `none`/empty/missing field is fine (human sign-off). Mirrors the edge check's
# shape: pure shell, no AI, reports the offending path so a human can fix it.
check_tests_field() {
    local file="$1" raw low p
    raw=$(sprintbias_meta_value "$file" "Tests")
    [ -z "$raw" ] && raw=$(sprintbias_meta_value "$file" "Proven by")
    [ -z "$raw" ] && return 0
    low=$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')
    case "$low" in none|n/a|-) return 0 ;; esac
    # Split on commas and whitespace, the same shape promote runs.
    local _paths=()
    IFS=', ' read -r -a _paths <<< "$raw"
    for p in "${_paths[@]}"; do
        [ -n "$p" ] || continue
        case "$p" in
            docs/tests/*) ;;
            *) printf '%s → not under docs/tests/\n' "$p"; continue ;;
        esac
        if [ ! -e "$PROJECT_ROOT/$p" ]; then
            printf '%s → file not found (typo or missing)\n' "$p"; continue
        fi
        if [ ! -f "$PROJECT_ROOT/$p" ]; then
            printf '%s → not a runnable script (not a file)\n' "$p"; continue
        fi
        if [ ! -x "$PROJECT_ROOT/$p" ]; then
            printf '%s → not a runnable script (chmod +x)\n' "$p"; continue
        fi
    done
    return 0
}

# Rewrite first-line title to match filename ID. Only safe auto-fix remaining.
fix_title_line() {
    local file="$1"
    local task_id="$2"
    local title_text temp_file

    title_text=$(task_title "$file" || true)
    if [ -z "$title_text" ]; then
        title_text=$(basename "$file" .md | sed -E 's/^[0-9]+-?//; s/-/ /g')
        [ -z "$title_text" ] && title_text="untitled"
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would set title to: # Task ${task_id}: ${title_text}"
        return 0
    fi

    temp_file="${file}.tmp"
    {
        echo "# Task ${task_id}: ${title_text}"
        tail -n +2 "$file"
    } > "$temp_file"
    move_file "$temp_file" "$file"
    return 0
}

validate_task() {
    local file="$1"
    local task_id
    local filename
    local issues=()
    local title_line title_id
    local can_fix_title=false

    filename=$(basename "$file")
    TOTAL_FILES=$((TOTAL_FILES + 1))
    task_id=$(task_id "$filename")

    # 1. Numeric filename ID
    if ! [[ "$task_id" =~ ^[0-9]+$ ]]; then
        issues+=("Invalid task ID in filename (must be numeric): $filename")
        INVALID_FILES=$((INVALID_FILES + 1))
        REMAINING_INVALID=$((REMAINING_INVALID + 1))
        printf "${RED}✗${NC} %s\n" "$file"
        for issue in "${issues[@]}"; do
            printf "  ${YELLOW}⚠${NC}  %s\n" "$issue"
        done
        return 1
    fi

    if [ ! -f "$file" ]; then
        issues+=("File does not exist")
        INVALID_FILES=$((INVALID_FILES + 1))
        REMAINING_INVALID=$((REMAINING_INVALID + 1))
        printf "${RED}✗${NC} %s\n" "$file"
        for issue in "${issues[@]}"; do
            printf "  ${YELLOW}⚠${NC}  %s\n" "$issue"
        done
        return 1
    fi

    # 2. Title ID matches filename
    title_line=$(head -n1 "$file")
    if [[ "$title_line" =~ ^#\ Task\ ([0-9]+): ]]; then
        title_id="${BASH_REMATCH[1]}"
        if [ "$title_id" != "$task_id" ]; then
            issues+=("Title ID ($title_id) does not match filename ID ($task_id)")
            can_fix_title=true
        fi
    else
        issues+=("Title must start with '# Task $task_id: ' (found: $title_line)")
        can_fix_title=true
    fi

    # 3. Duplicate ID across stages
    if id_is_duplicate "$task_id"; then
        local others="" p
        while IFS= read -r p; do
            [ -z "$p" ] && continue
            [ "$p" = "$file" ] && continue
            others="${others}${others:+, }${p}"
        done <<EOF
$(paths_for_id "$task_id")
EOF
        issues+=("Duplicate task ID $task_id (also at: ${others:-?})")
    fi

    # 4–5. Depends on / Dependents token integrity (no cycle detection).
    #      Dependents falls back to the legacy **Blocks** spelling on read.
    local _dep_issue
    while IFS= read -r _dep_issue; do
        [ -n "$_dep_issue" ] && issues+=("$_dep_issue")
    done <<EOF
$(check_id_list_field "$file" "Depends on")
$(check_id_list_field "$file" "Dependents" "Blocks")
EOF

    if [ ${#issues[@]} -eq 0 ]; then
        VALID_FILES=$((VALID_FILES + 1))
        printf "${GREEN}✓${NC} %s\n" "$file"
        return 0
    fi

    INVALID_FILES=$((INVALID_FILES + 1))
    printf "${RED}✗${NC} %s\n" "$file"
    for issue in "${issues[@]}"; do
        printf "  ${YELLOW}⚠${NC}  %s\n" "$issue"
    done

    # --fix: only title-line ID mismatch / missing Task N prefix is safe.
    # A file is "fully repaired" only when the title was its *sole* issue and
    # the fix succeeded; any other issue (duplicate ID, bad dependency token)
    # leaves the file invalid regardless of the title fix.
    local fully_repaired=false
    if [ "$FIX_MODE" = true ] && [ "$can_fix_title" = true ]; then
        printf "  ${BLUE}🔧 Attempting to fix title...${NC}\n"
        if fix_title_line "$file" "$task_id"; then
            FIXED_FILES=$((FIXED_FILES + 1))
            printf "  ${GREEN}✓${NC} Title fixed\n"
            [ ${#issues[@]} -eq 1 ] && fully_repaired=true
        else
            printf "  ${RED}✗${NC} Could not auto-fix title\n"
        fi
    fi

    if [ "$fully_repaired" = false ]; then
        REMAINING_INVALID=$((REMAINING_INVALID + 1))
    fi

    return 1
}

# Report global duplicate summary once (per-file lines already detail each hit)
if [ -n "$DUP_IDS" ]; then
    echo "Duplicate task IDs detected: $DUP_IDS"
    echo ""
fi

# Validate every collected file
for file in "${TASK_FILES[@]+"${TASK_FILES[@]}"}"; do
    validate_task "$file" || true
done

# ── Plan reverse-index drift ─────────────────────────────────────────
# The plan file member list is the membership authority; each task's **Plan**
# field mirrors it. Flag drift both ways: a task claiming Plan N no plan lists
# (removed member / stale id), and a task saying none/wrong when a plan does
# list it. --fix rewrites each to the primary (lowest) plan. done/ is skipped
# (migrate on touch). One line per drifted task: ID  field → computed.
PLAN_DRIFT=0
PLAN_FIXED=0
(cd "$PROJECT_ROOT" && sprintbias_plan_index_drift) > "$ID_INDEX.plan" 2>/dev/null || true
if [ -s "$ID_INDEX.plan" ]; then
    echo ""
    echo "Plan reverse-index drift (plan file is authority):"
    while IFS=$'\t' read -r _pid _cur _want; do
        [ -n "$_pid" ] || continue
        PLAN_DRIFT=$((PLAN_DRIFT + 1))
        printf "  ${YELLOW}⚠${NC}  #%s  Plan: %s → %s\n" "$_pid" "$_cur" "$_want"
    done < "$ID_INDEX.plan"
    if [ "$FIX_MODE" = true ] && [ "$DRY_RUN" = false ]; then
        (cd "$PROJECT_ROOT" && sprintbias_plan_index_drift --fix) >/dev/null 2>&1 || true
        PLAN_FIXED=$PLAN_DRIFT
        PLAN_DRIFT=0
        printf "  ${GREEN}✓${NC} Synced Plan on %d task(s)\n" "$PLAN_FIXED"
    fi
fi
rm -f "$ID_INDEX.plan"

# ── Tests-field integrity (report-only, promote close-path) ──────────
# The dependency edge is only half the graph; the **Tests** path is the other
# gate promote runs. A path that is a typo, missing, out-of-tree, or not runnable
# silently strands a task in review/ — report each with its task id so it never
# becomes a silent never-promote. Report-only: it never flips the exit code.
TESTS_ISSUES=0
TESTS_REPORT=""
for file in "${TASK_FILES[@]+"${TASK_FILES[@]}"}"; do
    _tnotes=$(check_tests_field "$file")
    [ -n "$_tnotes" ] || continue
    _tid=$(task_id "$(basename "$file")")
    while IFS= read -r _tn; do
        [ -n "$_tn" ] || continue
        TESTS_REPORT="${TESTS_REPORT}  ${YELLOW}⚠${NC}  #${_tid}  Tests: ${_tn}
"
        TESTS_ISSUES=$((TESTS_ISSUES + 1))
    done <<EOF
$_tnotes
EOF
done
if [ "$TESTS_ISSUES" -gt 0 ]; then
    echo ""
    echo "Tests-field integrity (promote close-path — report only):"
    printf '%s' "$TESTS_REPORT"
fi

# Print summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "Total files:    %d\n" "$TOTAL_FILES"
printf "${GREEN}Valid files:    %d${NC}\n" "$VALID_FILES"
printf "${RED}Invalid files:  %d${NC}\n" "$INVALID_FILES"

if [ "$FIX_MODE" = true ]; then
    printf "${BLUE}Fixed files:    %d${NC}\n" "$FIXED_FILES"
    [ "$PLAN_FIXED" -gt 0 ] && printf "${BLUE}Plan synced:    %d${NC}\n" "$PLAN_FIXED"
fi
[ "$PLAN_DRIFT" -gt 0 ] && printf "${YELLOW}Plan drift:     %d${NC}\n" "$PLAN_DRIFT"
[ "$TESTS_ISSUES" -gt 0 ] && printf "${YELLOW}Tests issues:   %d (report only)${NC}\n" "$TESTS_ISSUES"

echo ""

# Exit with error code if any file is still invalid after fixes are applied.
# REMAINING_INVALID (not FIXED_FILES < INVALID_FILES) is the source of truth:
# a file with both a fixed title and an unfixable issue stays counted here.
# Unfixed Plan drift is also non-clean — --fix reconciles it in one pass.
if [ "$REMAINING_INVALID" -gt 0 ] || [ "$PLAN_DRIFT" -gt 0 ]; then
    if [ "$REMAINING_INVALID" -gt 0 ]; then
        if [ "$FIX_MODE" = false ]; then
            echo "💡 Tip: Run with --fix to auto-correct title-line ID mismatches and Plan drift"
        else
            echo "⚠️  Some files could not be auto-fixed (duplicates / bad dependency tokens need a human)"
        fi
    elif [ "$PLAN_DRIFT" -gt 0 ]; then
        echo "💡 Tip: Run with --fix to sync each task's **Plan** to its plan file"
    fi
    exit 1
fi

echo "✅ All task files are valid!"
exit 0
