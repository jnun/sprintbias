#!/usr/bin/env bash
# plan-check.sh — Read-only plan health report. See: ./sprint.sh help plan
#
# Invoked as: ./sprint.sh plan check [id]
#
# Pure shell, NO AI. Reads a plan and its members and prints one glance at where
# the plan stands. Changes NOTHING — no task or plan file is created, edited,
# moved, or deleted, and no model is called. This is the read-only inverse of
# `plan start` (gates + moves) and `plan done` (deletes on a full pass).
#
# It answers three questions:
#   1. Plan state — not started / started / in process / completed, from the
#      plan **Status:** field plus where members live. A plan is completed only
#      when every member is in done/ (the point `plan done` would retire it).
#   2. Lifecycle — which folder each member sits in (backlog/next/doing/blocked/
#      review/done), with a count rollup so the spread is visible at a glance.
#   3. Definition — undefined / defined / in process / abandoned, derived from
#      the task body (never a stored stamp): undefined = not fully defined
#      (placeholder success criteria, open Questions, or sitting in blocked/);
#      defined = real success criteria and no open questions; in process = a
#      live doing/ claim; abandoned = a stale doing/ claim left with a failure
#      stamp (the same state `work` reclaims). blocked is undefined, not
#      abandoned.

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

PLANS_DIR="docs/plans"

# ── Args: plan id (any position) ─────────────────────────────────────
PLAN_ID=""
for _arg in "$@"; do
  case "$_arg" in
    *) [ -z "$PLAN_ID" ] && PLAN_ID="$_arg" ;;
  esac
done
unset _arg

list_plans() { sprintbias_list_plans; }
find_plan()  { sprintbias_find_plan "$1"; }

# plan_status FILE -> DRAFT | READY | STARTED | "(no status)"
plan_status() {
  local s
  s=$(grep -m1 -E '^\*\*Status:\*\*' "$1" 2>/dev/null \
      | sed 's/.*\*\*Status:\*\*[[:space:]]*//' | tr -d '[:space:]')
  printf '%s' "${s:-(no status)}"
}

# has_success_criteria FILE -> exit 0 when the ## Success criteria section holds
# at least one checkbox with real text (checked or unchecked). Empty "- [ ]"
# placeholders from a fresh task template do not count.
has_success_criteria() {
  awk '
    /^## Success criteria[[:space:]]*$/ { cap=1; next }
    cap && /^## / { cap=0 }
    cap && /^-[[:space:]]*\[[ xX]\][[:space:]]*[^[:space:]]/ { found=1 }
    END { exit(found ? 0 : 1) }
  ' "$1" 2>/dev/null
}

# outcome_result FILE -> the ## Outcome **Result**: value (failed|incomplete|…) or empty.
outcome_result() {
  { grep -m1 -E '^\*\*Result\*\*:' "$1" 2>/dev/null || true; } \
    | sed 's/.*\*\*Result\*\*:[[:space:]]*//' | tr -d '[:space:]'
}

# def_state FILE STAGE -> undefined | defined | in-process | abandoned
# The well-formedness question (undefined vs defined) only applies to work not
# yet finished. A member in doing/ is a live or stale claim; a member in
# review/done was necessarily defined enough to be worked, so it reads defined
# (its folder already shows it is finished). blocked and unworkable
# backlog/next members read undefined.
def_state() {
  local file="$1" stage="$2"
  case "$stage" in
    doing)
      case "$(outcome_result "$file")" in
        failed|incomplete|blocked) printf 'abandoned' ;;
        *) printf 'in-process' ;;
      esac
      return 0 ;;
    review|done)
      printf 'defined'; return 0 ;;
    blocked)
      printf 'undefined'; return 0 ;;
  esac
  # backlog / next: defined only when it has real success criteria and no open
  # questions holding it out of work.
  if sprintbias_has_open_questions "$file" || ! has_success_criteria "$file"; then
    printf 'undefined'
  else
    printf 'defined'
  fi
}

# ── Pick / resolve plan ──────────────────────────────────────────────

if [ -z "$PLAN_ID" ]; then
  if ! ls "$PLANS_DIR"/*.md >/dev/null 2>&1; then
    echo "No plans to check."
    exit 1
  fi
  # Sole plan → check it. Otherwise list, and prompt when interactive.
  _only=$(find "$PLANS_DIR" -maxdepth 1 -name '*.md' 2>/dev/null \
            ! -name '.TEMPLATE-*' ! -name 'TEMPLATE-*')
  if [ "$(printf '%s\n' "$_only" | grep -c .)" -eq 1 ]; then
    PLAN_ID=$(sprintbias_plan_file_id "$_only")
  else
    echo "▸ plan check — read-only plan health report"
    echo ""
    echo "Plans:"
    list_plans
    echo ""
    if [ -t 0 ] && [ -t 1 ]; then
      printf "Plan id to check (or blank to cancel): "
      read -r PLAN_ID </dev/tty 2>/dev/null || PLAN_ID=""
    else
      echo "Usage: ./sprint.sh plan check <id>"
      exit 1
    fi
    [ -n "$PLAN_ID" ] || { echo "Cancelled."; exit 0; }
  fi
fi

if ! [[ "$PLAN_ID" =~ ^[0-9]+$ ]]; then
  echo "Error: '$PLAN_ID' is not a plan id."
  echo "Usage: ./sprint.sh plan check [id]   # plan id, not a task id"
  exit 1
fi

if ! PLAN_FILE="$(find_plan "$PLAN_ID")"; then
  echo "Error: No plan found with ID $PLAN_ID in $PLANS_DIR/"
  echo "Existing plans:"
  list_plans
  exit 1
fi

PLAN_TITLE=$(grep -m1 '^# ' "$PLAN_FILE" 2>/dev/null | sed 's/^# *//')
STATUS=$(plan_status "$PLAN_FILE")

# ── Collect members and tally ────────────────────────────────────────

MEMBER_IDS=$(sprintbias_plan_member_ids "$PLAN_FILE")

echo "▸ Plan $PLAN_ID health — ${PLAN_TITLE:-$(basename "$PLAN_FILE")}"
echo ""

if [ -z "$MEMBER_IDS" ]; then
  echo "  Plan state:  empty (no member tasks)  [**Status:** $STATUS]"
  echo ""
  echo "  Add members with: ./sprint.sh chat plan $PLAN_ID"
  exit 0
fi

# Old bash (3.2, macOS default) has no associative arrays. Collect one
# "id stage dstate" record per member into an indexed array; derive every count
# by filtering that list, so no `declare -A` is needed.
TOTAL=0; DONE=0; PROGRESSED=0; MISSING=0
RECORDS=()

for id in $MEMBER_IDS; do
  TOTAL=$((TOTAL + 1))
  if ! stage="$(sprintbias_task_stage "$id")"; then
    MISSING=$((MISSING + 1))
    RECORDS+=("$id missing missing")
    continue
  fi
  file="$(sprintbias_task_path "$id")"
  dstate="$(def_state "$file" "$stage")"
  [ "$stage" = "done" ] && DONE=$((DONE + 1))
  case "$stage" in doing|review|done) PROGRESSED=$((PROGRESSED + 1)) ;; esac
  RECORDS+=("$id $stage $dstate")
done

# count_field N VALUE -> how many records have VALUE in whitespace field N (2|3).
count_field() {
  local n="$1" val="$2" c=0 rec
  for rec in "${RECORDS[@]}"; do
    [ "$(echo "$rec" | cut -d' ' -f"$n")" = "$val" ] && c=$((c + 1))
  done
  printf '%s' "$c"
}

# ── Plan state ───────────────────────────────────────────────────────
# completed = every member in done/. Otherwise progress is read from where
# members live, gated by whether the plan has been started (STARTED latch).
if [ "$DONE" -eq "$TOTAL" ]; then
  PLAN_STATE="completed"
elif [ "$STATUS" != "STARTED" ]; then
  PLAN_STATE="not started ($STATUS)"
elif [ "$PROGRESSED" -gt 0 ]; then
  PLAN_STATE="in process"
else
  PLAN_STATE="started"
fi

echo "  Plan state:  $PLAN_STATE  [**Status:** $STATUS · $DONE/$TOTAL in done/]"
echo ""

# ── Lifecycle rollup ─────────────────────────────────────────────────
_roll=""
for stage in "${SPRINTBIAS_STAGES[@]}" missing; do
  c=$(count_field 2 "$stage")
  [ "$c" -gt 0 ] && _roll="$_roll  $stage:$c"
done
echo "  Lifecycle: $_roll"

# ── Definition rollup ────────────────────────────────────────────────
_def=""
for d in undefined defined in-process abandoned; do
  c=$(count_field 3 "$d")
  [ "$c" -gt 0 ] && _def="$_def  $d:$c"
done
echo "  Definition:$_def"
echo ""

# ── Per-member table ─────────────────────────────────────────────────
echo "  Member    Folder    State"
for rec in "${RECORDS[@]}"; do
  set -- $rec
  if [ "$2" = "missing" ]; then
    printf '  #%-4s  %-8s  %s\n' "$1" "missing" "no task file found"
  else
    printf '  #%-4s  %-8s  %s\n' "$1" "$2" "$3"
  fi
done

if [ "$MISSING" -gt 0 ]; then
  echo ""
  echo "  ⚠ $MISSING member(s) have no task file — listed in the plan but not on disk."
fi

exit 0
