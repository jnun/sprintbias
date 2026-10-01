#!/usr/bin/env bash
# create-task.sh — Create a task. See: ./sprint.sh help newtask
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

# Verify DOC_STATE.md exists and is valid
if [ ! -f "docs/sprintbias/DOC_STATE.md" ]; then
    echo -e "${RED}ERROR: docs/sprintbias/DOC_STATE.md not found!${NC}"
    echo "Run ./setup.sh first to initialize the project."
    exit 1
fi

# --from-plan N records which plan's work this task came out of (a rework,
# delta, deferred item, or enhancement filed while working plan N), so
# `newplan "…" from:N` can group the follow-ups once the plan is done.
FROM_PLAN=""
_pos=()
while [ $# -gt 0 ]; do
  case "$1" in
    --from-plan)   FROM_PLAN="${2:-}"; shift 2 || shift ;;
    --from-plan=*) FROM_PLAN="${1#--from-plan=}"; shift ;;
    *)             _pos+=("$1"); shift ;;
  esac
done
set -- ${_pos[@]+"${_pos[@]}"}
if [ -n "$FROM_PLAN" ] && ! [[ "$FROM_PLAN" =~ ^[0-9]+$ ]]; then
  echo -e "${RED}ERROR: --from-plan needs a plan id (a number), got '$FROM_PLAN'.${NC}"
  exit 1
fi

# Get the task description from the command line argument
DESCRIPTION="${1:-}"
if [ -z "$DESCRIPTION" ]; then
  echo "Usage: $0 \"Brief description of the task\" [feature-name]"
  echo ""
  echo "Examples:"
  echo "  $0 \"Fix login bug\""
  echo "  $0 \"Add user authentication\" user-auth"
  echo "  $0 \"Rework the login copy\" --from-plan 24"
  exit 1
fi

# Optional feature name
FEATURE="${2:-}"

# Convert to a filename-safe slug; reject descriptions with no slug-able text.
KEBAB_CASE_DESC=$(sprintbias_slug "$DESCRIPTION") || {
    echo -e "${RED}ERROR: Description has no letters or numbers to build a filename from.${NC}"
    echo "Provide a description with at least one alphanumeric character."
    exit 1
}

# Serialize ID allocation so concurrent creates never draw the same ID.
sprintbias_lock

# Read highest task ID and increment with error handling
NEW_ID=$(alloc_id sprint_TASK_ID 'docs/tasks/*/[0-9]*-*.md') || {
    echo -e "${RED}ERROR: Invalid or missing task ID in DOC_STATE.md${NC}"
    echo "Please fix docs/sprintbias/DOC_STATE.md manually. Expected format: '**sprint_TASK_ID**: NUMBER'"
    exit 1
}

FILENAME=$(printf "%d-%s.md" "$NEW_ID" "$KEBAB_CASE_DESC")

# No file anywhere in the task tree may already own this ID, whatever its slug.
# alloc_id reconciles the counter with disk, so this should never fire — if it
# does, DOC_STATE.md is corrupt or two files share a numeric prefix by hand.
# Glob-loop (not `ls | head`) so an unmatched pattern can't trip pipefail.
DUP=""
for existing in docs/tasks/*/"${NEW_ID}"-*.md; do
    [ -e "$existing" ] && { DUP="$existing"; break; }
done
if [ -n "$DUP" ]; then
    echo -e "${RED}ERROR: task ID ${NEW_ID} already exists: ${DUP}${NC}"
    echo "DOC_STATE.md's sprint_TASK_ID is out of sync with the files on disk."
    exit 1
fi

# Read template and substitute placeholders
TEMPLATE_FILE="docs/tasks/.TEMPLATE-task.md"
copy_template "$TEMPLATE_FILE" "docs/tasks/backlog/$FILENAME" || exit 1

if [ -n "$FEATURE" ]; then
    FEATURE_LINE="**Feature**: /docs/features/${FEATURE}.md"
else
    FEATURE_LINE="**Feature**: none"
fi

CREATED_DATE=$(date +%Y-%m-%d)

sed_inplace "s/\[ID\]/$NEW_ID/g" "docs/tasks/backlog/$FILENAME"
sed_inplace "s/\[Brief Description\]/$(sed_escape "$DESCRIPTION")/g" "docs/tasks/backlog/$FILENAME"
sed_inplace "s/YYYY-MM-DD/$CREATED_DATE/g" "docs/tasks/backlog/$FILENAME"
if [ -n "$FEATURE" ]; then
    sed_inplace "s/\*\*Feature\*\*: none/$(sed_escape "$FEATURE_LINE")/g" "docs/tasks/backlog/$FILENAME"
fi
if [ -n "$FROM_PLAN" ]; then
    if grep -q '^\*\*From plan\*\*:' "docs/tasks/backlog/$FILENAME"; then
        sed_inplace "s/^\*\*From plan\*\*:.*/**From plan**: $FROM_PLAN/" "docs/tasks/backlog/$FILENAME"
    else
        # An older project template without the field: add it under **Plan**.
        sed_inplace "/^\*\*Plan\*\*:/a\\
**From plan**: $FROM_PLAN
" "docs/tasks/backlog/$FILENAME"
    fi
fi

# Update DOC_STATE.md in place — only touch the fields that changed
LAST_UPDATED=$(date +%F)
bump_doc_state sprint_TASK_ID "$NEW_ID"
bump_doc_state "Last Updated" "$LAST_UPDATED"
sprintbias_unlock
echo -e "${GREEN}✓ DOC_STATE.md updated successfully${NC}"

# Verify task file was created successfully
if [ ! -f "docs/tasks/backlog/$FILENAME" ]; then
    echo -e "${RED}ERROR: Task file was not created${NC}"
    exit 1
fi

# Stage the changes (skip gracefully if not in a git repo)
git add docs/sprintbias/DOC_STATE.md "docs/tasks/backlog/$FILENAME" 2>/dev/null || true

echo -e "${GREEN}Created task: docs/tasks/backlog/$FILENAME${NC}"
echo ""
echo "Next: talk it into shape — ./sprint.sh chat $NEW_ID"
echo "      (fills in the problem, success criteria, and notes one question at a time;"
echo "       or just edit the file directly if you already know what it needs.)"
