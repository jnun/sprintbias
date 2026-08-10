#!/usr/bin/env bash
set -euo pipefail
# context.sh — Generate AI context summary. See: ./sprint.sh help context

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

# Determine project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
DOCS_DIR="$PROJECT_ROOT/docs"

_list_md() {
    local dir="$1" fallback="$2" limit="${3:-0}"
    local files
    files=$(find "$dir" -maxdepth 1 -name '*.md' -exec basename {} \; 2>/dev/null | sort)
    if [ -n "$files" ]; then
        if [ "$limit" -gt 0 ]; then echo "$files" | head -n "$limit"; else echo "$files"; fi
    else
        echo "$fallback"
    fi
}

echo "# Project Context Summary"
echo ""
echo "## Global State (DOC_STATE.md)"
if [ -f "$DOCS_DIR/sprintbias/DOC_STATE.md" ]; then
    cat "$DOCS_DIR/sprintbias/DOC_STATE.md"
else
    echo "DOC_STATE.md not found."
fi
echo ""

echo "## Blocked (need decision or clarification)"
if [ -d "$DOCS_DIR/tasks/blocked" ]; then
    blocked_files=$(_list_md "$DOCS_DIR/tasks/blocked" "")
    if [ -n "$blocked_files" ]; then
        echo "$blocked_files"
        echo ""
        echo "These tasks cannot be worked given current conditions — docs changed,"
        echo "dependencies shifted, or the task is undefined. They need analysis and"
        echo "resolution before the sprint can move forward."
    else
        echo "No blocked tasks."
    fi
else
    echo "No blocked tasks."
fi
echo ""

echo "## Active Tasks (Doing)"
if [ -d "$DOCS_DIR/tasks/doing" ]; then
    _list_md "$DOCS_DIR/tasks/doing" "No active tasks."
else
    echo "Doing directory not found."
fi
echo ""

echo "## Up Next (Sprint Queue)"
if [ -d "$DOCS_DIR/tasks/next" ]; then
    _list_md "$DOCS_DIR/tasks/next" "No tasks in queue."
else
    echo "Next directory not found."
fi
echo ""

echo "## Plans (Relational Groupings)"
# A plan is a named index over tasks, NOT a lifecycle stage and NOT a task.
# List each plan and resolve its "- #ID" members to their current folder so
# the grouping's progress is visible without ever counting the plan as a task.
if [ -d "$DOCS_DIR/plans" ]; then
    _plan_any=0
    for _sf in "$DOCS_DIR"/plans/*.md; do
        [ -f "$_sf" ] || continue
        case "$(basename "$_sf")" in .TEMPLATE-*|TEMPLATE-*) continue ;; esac
        _plan_any=1
        _stitle=$(grep -m1 '^# ' "$_sf" | sed 's/^# *//')
        echo "- ${_stitle:-$(basename "$_sf" .md)}"
        for _id in $(grep -oE '^- (\[[ xX]\] )?#[0-9]+' "$_sf" 2>/dev/null | grep -oE '[0-9]+'); do
            _loc=""
            for _stage in "${SPRINTBIAS_STAGES[@]}"; do
                if ls "$DOCS_DIR/tasks/$_stage/${_id}-"*.md >/dev/null 2>&1; then _loc="$_stage/"; break; fi
            done
            [ -z "$_loc" ] && _loc="(done or archived)"
            echo "    #${_id}  ${_loc}"
        done
    done
    [ "$_plan_any" -eq 0 ] && echo "No plans."
else
    echo "No plans."
fi
echo ""

echo "## Ideas (In Refinement)"
if [ -d "$DOCS_DIR/ideas" ]; then
    _list_md "$DOCS_DIR/ideas" "No ideas." 5
else
    echo "Ideas directory not found."
fi
echo ""

echo "## Recent Bugs"
if [ -d "$DOCS_DIR/bugs" ]; then
    _list_md "$DOCS_DIR/bugs" "No active bugs." 5
else
    echo "Bugs directory not found."
fi
echo ""

echo "## Suggested Action"
# Priority: blocked > doing > next > backlog
blocked_count=$(find "$DOCS_DIR/tasks/blocked" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
doing_count=$(find "$DOCS_DIR/tasks/doing" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
next_count=$(find "$DOCS_DIR/tasks/next" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')

if [ "$blocked_count" -gt 0 ]; then
    echo "Tasks in blocked/ need a decision or clarification before work can start."
    echo "Run './sprint.sh chat <task-id>' on a blocked task to answer open questions and write each answer as instruction in the body."
elif [ "$doing_count" -gt 0 ]; then
    echo "Focus on completing the active task in 'doing/'."
elif [ "$next_count" -gt 0 ]; then
    echo "Pick a task from 'next/' and move it to 'doing/'."
else
    echo "Check 'backlog/' for new tasks or create one."
fi
