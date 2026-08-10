#!/usr/bin/env bash
# create-plan.sh — Create a plan. See: ./sprint.sh help newplan
#
# A plan is a RELATIONAL INDEX over tasks, not a container: one file that names
# a clump of related tasks and lists their IDs. The tasks never move here — each
# stays in its own lifecycle folder and flows through backlog → next → … on its
# own. This script allocates a plan ID (a dedicated DOC_STATE counter, exactly
# like task/bug IDs), writes docs/plans/N-name.md from the template, and fills
# in the member list from task IDs given on the command line or picked from
# backlog/ (the defining period, before work starts). Binding also stamps each
# member's **Plan** reverse index (see sprintbias_reconcile_task_plan).
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

# Verify DOC_STATE.md exists and is valid
if [ ! -f "docs/sprintbias/DOC_STATE.md" ]; then
    echo -e "${RED}ERROR: docs/sprintbias/DOC_STATE.md not found!${NC}"
    echo "Run ./setup.sh first to initialize the project."
    exit 1
fi

NAME="${1:-}"
if [ -z "$NAME" ]; then
    echo "Usage: $0 \"<plan name>\" [task-id | parent:N ...]"
    echo ""
    echo "A plan is a named list of task IDs — a relational grouping over tasks"
    echo "that each stay in their own lifecycle folder. Pass member task IDs as"
    echo "extra arguments (numbers, N-M ranges, and parent:N to bind an open"
    echo "parent plus its open children), or omit them to pick from backlog/"
    echo "interactively."
    echo ""
    echo "Examples:"
    echo "  $0 \"Method accuracy audit\" 213 214 215"
    echo "  $0 \"Method accuracy audit\" 213-220"
    echo "  $0 \"Finish split of 335\" parent:335"
    exit 1
fi
shift || true

# Convert to a filename-safe slug; reject names with no slug-able text.
SLUG=$(sprintbias_slug "$NAME") || {
    echo -e "${RED}ERROR: Name has no letters or numbers to build a filename from.${NC}"
    echo "Provide a name with at least one alphanumeric character."
    exit 1
}

# ── Collect member task IDs ──────────────────────────────────────────
# Expand a token list ("213 214" or "213-220") into individual numeric IDs.
# Mirrors sprintbias_unmet_deps' range handling so the two agree on syntax.
expand_ids() {
    local tok lo hi n
    for tok in "$@"; do
        tok="${tok//,/ }"
        for tok in $tok; do
            if [[ "$tok" =~ ^([0-9]+)-([0-9]+)$ ]]; then
                lo="${BASH_REMATCH[1]}"; hi="${BASH_REMATCH[2]}"
                [ "$lo" -le "$hi" ] || continue
                for ((n=lo; n<=hi; n++)); do printf '%s\n' "$n"; done
            elif [[ "$tok" =~ ^[0-9]+$ ]]; then
                printf '%s\n' "$tok"
            fi
        done
    done
}

# expand_parent_token N — open parent (if any) + open-stage children stamped
# **Parent**: N exactly. Emits one id per line. Notes on stdout stderr for
# "parent retired" when children match but parent is not open.
expand_parent_token() {
    local pid="$1" stage f id pval parent_open=0 child_count=0
    # Parent itself only if open-stage.
    if hit=$(sprintbias_find_task "$pid" \
                docs/tasks/backlog docs/tasks/next docs/tasks/doing docs/tasks/blocked); then
        printf '%s\n' "$pid"
        parent_open=1
    fi
    for stage in "${SPRINTBIAS_OPEN_STAGES[@]}"; do
        for f in "docs/tasks/$stage"/*.md; do
            [ -f "$f" ] || continue
            id=$(task_id "$(basename "$f")")
            [ -n "$id" ] || continue
            [ "$id" = "$pid" ] && continue
            pval=$(sprintbias_meta_value "$f" "Parent")
            pval="${pval//[[:space:]]/}"
            # Exact id match — parent:33 must not pull Parent 335 / 133.
            [ "$pval" = "$pid" ] || continue
            printf '%s\n' "$id"
            child_count=$((child_count + 1))
        done
    done
    if [ "$parent_open" -eq 0 ] && [ "$child_count" -gt 0 ]; then
        echo "  note: parent #$pid is not open — binding children only" >&2
    fi
}

MEMBER_IDS=()
PREBOUND=0
HAD_PLAIN_IDS=0
PARENT_TOKENS=0

if [ "$#" -gt 0 ]; then
    PREBOUND=1
    _raw_out=$(mktemp)
    for _tok in "$@"; do
        _tok="${_tok//,/ }"
        for _tok in $_tok; do
            if [[ "$_tok" =~ ^[Pp]arent:([0-9]+)$ ]]; then
                PARENT_TOKENS=$((PARENT_TOKENS + 1))
                expand_parent_token "${BASH_REMATCH[1]}" >> "$_raw_out" || true
            elif [[ "$_tok" =~ ^([0-9]+)-([0-9]+)$ ]] || [[ "$_tok" =~ ^[0-9]+$ ]]; then
                HAD_PLAIN_IDS=1
                expand_ids "$_tok" >> "$_raw_out"
            elif [[ "$_tok" =~ ^[Pp]arent: ]]; then
                echo -e "${RED}ERROR: invalid parent token '$_tok' (use parent:N with a numeric id).${NC}"
                rm -f "$_raw_out"
                exit 1
            else
                echo -e "${RED}ERROR: unrecognized member token '$_tok'.${NC}"
                echo "Use task ids, N-M ranges, or parent:N."
                rm -f "$_raw_out"
                exit 1
            fi
        done
    done
    while IFS= read -r _id; do MEMBER_IDS+=("$_id"); done < <(awk '!seen[$0]++' "$_raw_out")
    rm -f "$_raw_out"
    # parent:N alone with zero matches → fail loud (no empty silent plan).
    if [ "$PARENT_TOKENS" -gt 0 ] && [ "$HAD_PLAIN_IDS" -eq 0 ] && [ "${#MEMBER_IDS[@]}" -eq 0 ]; then
        echo -e "${RED}ERROR: parent: token(s) matched no open tasks.${NC}"
        echo "Open stages are: ${SPRINTBIAS_OPEN_STAGES[*]}."
        echo "Include the parent only if it is still open; children need **Parent**: N exactly."
        exit 1
    fi
elif [ -t 0 ] && [ -t 1 ]; then
    # Interactive: a plan is the defining period, so offer backlog/ — the tasks
    # you choose before work starts. (next/blocked/doing/review/done are all
    # post-start; you can still type any ID by hand.)
    echo -e "${CYAN}Tasks in backlog/ (the pool you plan from):${NC}"
    _any=0
    for f in docs/tasks/backlog/*.md; do
        [ -f "$f" ] || continue
        _any=1
        printf "  ${BOLD}%s${NC}  %s\n" "$(task_id "$(basename "$f")")" "$(task_title "$f")"
    done
    [ "$_any" -eq 0 ] && echo "  (backlog is empty — you can still enter any task ID)"
    echo ""
    printf "Enter member task IDs (space/comma separated, N-M ranges or parent:N; blank for none): "
    read -r _line </dev/tty 2>/dev/null || _line=""
    if [ -n "$_line" ]; then
        # Re-enter through the same argv parser for parent: support.
        # shellcheck disable=SC2086
        set -- $_line
        PREBOUND=1
        _raw_out=$(mktemp)
        for _tok in "$@"; do
            if [[ "$_tok" =~ ^[Pp]arent:([0-9]+)$ ]]; then
                expand_parent_token "${BASH_REMATCH[1]}" >> "$_raw_out" || true
            else
                expand_ids "$_tok" >> "$_raw_out"
            fi
        done
        while IFS= read -r _id; do MEMBER_IDS+=("$_id"); done < <(awk '!seen[$0]++' "$_raw_out")
        rm -f "$_raw_out"
    fi
fi

# ── Allocate the plan ID (serialized, like newtask/newbug) ───────────
sprintbias_lock

NEW_ID=$(alloc_id sprint_PLAN_ID 'docs/plans/[0-9]*-*.md') || {
    echo -e "${RED}ERROR: Invalid or missing plan ID in DOC_STATE.md${NC}"
    echo "Please fix docs/sprintbias/DOC_STATE.md manually. Expected: '**sprint_PLAN_ID**: NUMBER'"
    exit 1
}

FILENAME=$(printf "%d-%s.md" "$NEW_ID" "$SLUG")
DEST="docs/plans/$FILENAME"

# No plan file may already own this ID, whatever its slug. alloc_id reconciles
# the counter with disk, so this should never fire — if it does, DOC_STATE.md
# is corrupt or two files share a numeric prefix by hand.
# Glob-loop (not `ls | head`) so an unmatched pattern can't trip pipefail.
DUP=""
for existing in docs/plans/"${NEW_ID}"-*.md; do
    [ -e "$existing" ] && { DUP="$existing"; break; }
done
if [ -n "$DUP" ]; then
    echo -e "${RED}ERROR: plan ID ${NEW_ID} already exists: ${DUP}${NC}"
    echo "DOC_STATE.md's sprint_PLAN_ID is out of sync with the files on disk."
    exit 1
fi

copy_template "docs/plans/.TEMPLATE-plan.md" "$DEST" || exit 1

CREATED_DATE=$(date +%Y-%m-%d)
sed_inplace "s/\[ID\]/$NEW_ID/g" "$DEST"
sed_inplace "s/\[Plan Name\]/$(sed_escape "$NAME")/g" "$DEST"
sed_inplace "s/YYYY-MM-DD/$CREATED_DATE/g" "$DEST"

# ── Write the member list ────────────────────────────────────────────
# Replace the template's single "- #ID — short title" placeholder with one
# resolved line per member. Each ID is looked up across every lifecycle folder
# (a plan references tasks wherever they currently sit); an ID that resolves
# to no file is kept as a reference — a plan lists IDs, not paths, and a
# member that was completed and archived is still a member.
sed_inplace '/^- #ID — short title$/d' "$DEST"

{
    for id in ${MEMBER_IDS[@]+"${MEMBER_IDS[@]}"}; do
        if hit=$(sprintbias_find_task "$id" \
                    docs/tasks/backlog docs/tasks/next docs/tasks/doing \
                    docs/tasks/blocked docs/tasks/review docs/tasks/done); then
            fpath="${hit%%$'\t'*}"
            printf -- '- #%s — %s\n' "$id" "$(task_title "$fpath")"
        else
            printf -- '- #%s — (no task file found — completed or archived)\n' "$id"
        fi
    done
} >> "$DEST"

# ── Refresh each member's **Plan** reverse index ─────────────────────
# The plan file (now written) is the membership authority; mirror it onto each
# member task's **Plan** field so single-file readers see the plan. Migrate on
# touch: reconcile derives the primary (lowest) plan from all plan files, so a
# member already in a lower-numbered plan keeps that id. done/ is left alone.
for id in ${MEMBER_IDS[@]+"${MEMBER_IDS[@]}"}; do
    sprintbias_reconcile_task_plan "$id" >/dev/null || true
done

# Update DOC_STATE.md — only the fields that changed.
bump_doc_state sprint_PLAN_ID "$NEW_ID"
bump_doc_state "Last Updated" "$(date +%F)"
sprintbias_unlock
echo -e "${GREEN}✓ DOC_STATE.md updated (sprint_PLAN_ID=$NEW_ID)${NC}"

# Stage the changes (skip gracefully if not in a git repo)
git add docs/sprintbias/DOC_STATE.md "$DEST" 2>/dev/null || true

echo -e "${GREEN}Created plan: $DEST${NC}"
if [ "${#MEMBER_IDS[@]}" -gt 0 ]; then
    echo "  Members: ${MEMBER_IDS[*]}"
else
    echo "  No members yet — edit the file to add '- #ID — title' lines."
fi
echo ""
if [ "$PREBOUND" -eq 1 ] && [ "${#MEMBER_IDS[@]}" -gt 0 ]; then
    # Fast lane: members already known — skip authoring ceremony as the default next step.
    echo "Next (fast lane — members already bound):"
    echo "  ./sprint.sh plan start $NEW_ID     # gate members → next/ (latches STARTED)"
    echo "  ./sprint.sh work                  # execute READY work from next/"
    echo ""
    echo "Optional: refine goal/members with ./sprint.sh chat plan $NEW_ID"
    echo "          or critique with ./sprint.sh plan think $NEW_ID"
    echo "If members are already READY-stamped and you want a pure move (no AI gate):"
    echo "  ./sprint.sh plan start $NEW_ID --commit-only"
else
    echo "Next: author with ./sprint.sh chat plan $NEW_ID, optionally critique with"
    echo "./sprint.sh plan think $NEW_ID, then commit with ./sprint.sh plan start $NEW_ID"
    echo "(or commit one member via: bash docs/sprintbias/scripts/promote-to-sprint.sh <task-file>)."
fi
echo "The plan file itself never moves."
