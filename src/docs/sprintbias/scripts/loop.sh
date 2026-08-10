#!/usr/bin/env bash
# loop.sh — Continuous task runner. See: ./sprint.sh help loop

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Defaults ────────────────────────────────────────────────────────
MAX_HOURS=0
MAX_ATTEMPTS=0
COOLDOWN=10
REFILL=0
RETRY=0
PASSTHROUGH=()
# Active plan goal (set by plan start during --refill); cheap run context only.
ACTIVE_PLAN_GOAL=""
ACTIVE_PLAN_ID=""

# ── Argument parsing ────────────────────────────────────────────────
# --hours/--max/--cooldown take a numeric value. Validate it here: unlike
# work.sh's boolean --max, loop's --max expects a count, so a bare
# `loop --max --audit` would otherwise capture "--audit" as the limit, and
# every later `[ "$MAX_ATTEMPTS" -gt 0 ]` test would error to stderr and never
# trip — a silent runaway. Reject a missing or non-integer value up front.
_require_int() {  # _require_int FLAG VALUE
  if [ -z "$2" ] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
    echo "✗ $1 needs a whole number, got '${2:-}'" >&2
    echo "  e.g. ./sprint.sh loop $1 10" >&2
    exit 1
  fi
}
while [ $# -gt 0 ]; do
  case "$1" in
    --hours)     _require_int --hours "${2:-}";    MAX_HOURS="$2"; shift 2 ;;
    --max)       _require_int --max "${2:-}";       MAX_ATTEMPTS="$2"; shift 2 ;;
    --cooldown)  _require_int --cooldown "${2:-}";  COOLDOWN="$2"; shift 2 ;;
    --refill)    REFILL=1
                 # Optional numeric arg was the old auto-planner size; ignore if
                 # present so existing `loop --refill 3` invocations still work.
                 if [ $# -gt 1 ] && [[ "$2" =~ ^[0-9]+$ ]]; then
                   shift
                 fi
                 shift ;;
    --retry)     RETRY=1; shift ;;
    *)           PASSTHROUGH+=("$1"); shift ;;
  esac
done

# ── Directories ─────────────────────────────────────────────────────
NEXT_DIR="docs/tasks/next"
DOING_DIR="docs/tasks/doing"
BLOCKED_DIR="docs/tasks/blocked"
REVIEW_DIR="docs/tasks/review"
BACKLOG_DIR="docs/tasks/backlog"

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/gate-lib.sh"

# ── State ───────────────────────────────────────────────────────────
COMPLETED=0
FAILED=0
RETRIED=0
REFILLS=0
TOTAL_START=$SECONDS
_RETRY_USED=0

# Snapshot pre-existing blocked/ tasks so retry only touches ones that landed
# this run (need a decision or clarification)
_INITIAL_BLOCKED=$(mktemp)
trap 'rm -f "$_INITIAL_BLOCKED"' EXIT
ls "$BLOCKED_DIR"/*.md 2>/dev/null | while read -r f; do basename "$f"; done > "$_INITIAL_BLOCKED" 2>/dev/null || true

# ── Helpers ─────────────────────────────────────────────────────────
count_tasks() { find "$1" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' '; }

# The limit is checked between iterations, not mid-task. A task that starts at
# 3h59m of a 4h cap runs to completion — deliberate: killing a task mid-flight
# would strand a half-edited tree. On a tier that supports spending caps (today
# Claude Code) the CLI's own --budget also bounds a single run; other tiers run
# uncapped. Treat --hours as "stop starting new work after N hours".
time_up() {
  [ "$MAX_HOURS" -gt 0 ] || return 1
  local elapsed=$(( SECONDS - TOTAL_START ))
  local limit=$(( MAX_HOURS * 3600 ))
  [ "$elapsed" -ge "$limit" ]
}

attempts_up() {
  [ "$MAX_ATTEMPTS" -gt 0 ] && [ $(( COMPLETED + FAILED )) -ge "$MAX_ATTEMPTS" ]
}

status_line() {
  local next_n blocked_n review_n doing_n elapsed
  next_n=$(count_tasks "$NEXT_DIR")
  blocked_n=$(count_tasks "$BLOCKED_DIR")
  review_n=$(count_tasks "$REVIEW_DIR")
  doing_n=$(count_tasks "$DOING_DIR")
  elapsed=$(( SECONDS - TOTAL_START ))
  echo ""
  echo "  ┌─ Loop ─────────────────────────────────"
  echo "  │  ✓ $COMPLETED completed  ✗ $FAILED failed"
  echo "  │  ↻ $RETRIED retried  ⟳ $REFILLS refills"
  echo "  │  Queue: $next_n next, $doing_n doing, $blocked_n blocked, $review_n review"
  printf '  │  Elapsed: %dh %dm %ds\n' "$((elapsed/3600))" "$(((elapsed%3600)/60))" "$((elapsed%60))"
  echo "  └────────────────────────────────────────"
  echo ""
}

cleanup_and_exit() {
  echo ""
  status_line
  echo "▸ Loop interrupted."
  rm -f "$_INITIAL_BLOCKED"
  exit 130
}
trap cleanup_and_exit INT TERM

# ── Preflight ───────────────────────────────────────────────────────
for dir in "$NEXT_DIR" "$DOING_DIR" "$BLOCKED_DIR" "$REVIEW_DIR"; do
  [ -d "$dir" ] || { echo "✗ Missing: $dir"; exit 1; }
done

# ── Recover orphaned doing/ tasks ───────────────────────────────────
# Re-queue only: these already entered next/ via the gate before work moved
# them to doing/. Not a first-time promote — no re-gate (stamp preserved).
DOING_COUNT=$(count_tasks "$DOING_DIR")
if [ "$DOING_COUNT" -gt 0 ]; then
  echo "⚠ Found $DOING_COUNT task(s) in doing/ from an interrupted run"
  for f in "$DOING_DIR"/*.md; do
    [ -f "$f" ] || continue
    name="${f##*/}"
    move_file "$f" "$NEXT_DIR/$name"
    echo "  ↻ $name → next/ (re-queue interrupted work)"
  done
  echo ""
fi

# ── Banner ──────────────────────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "▸ SprintBias Loop Runner"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Queue:      $(count_tasks "$NEXT_DIR") tasks in next/"
echo "  Blocked:    $(count_tasks "$BLOCKED_DIR") in blocked/"
echo "  Backlog:    $(count_tasks "$BACKLOG_DIR") in backlog/"
[ "$MAX_HOURS" -gt 0 ]    && echo "  Time limit: ${MAX_HOURS}h"
[ "$MAX_ATTEMPTS" -gt 0 ] && echo "  Task limit: $MAX_ATTEMPTS"
echo "  Cooldown:   ${COOLDOWN}s"
[ "$REFILL" -eq 1 ]       && echo "  Refill:     plan start (next READY plan) when empty"
[ "$RETRY" -eq 1 ]        && echo "  Retry:      re-queue tasks that landed in blocked/ this run (once)"
[ ${#PASSTHROUGH[@]} -gt 0 ] && echo "  Flags:      ${PASSTHROUGH[*]}"
echo ""

# ── Active plan goal helper (cheap context for this loop process) ───
# Find the lowest-id plan marked READY. Used by --refill and for banner context.
next_ready_plan() {
  local f id status best="" best_id=999999999
  for f in docs/plans/*.md; do
    [ -f "$f" ] || continue
    case "$(basename "$f")" in .TEMPLATE-*|TEMPLATE-*) continue ;; esac
    id=$(basename "$f" | grep -oE '^[0-9]+' || true)
    [ -n "$id" ] || continue
    status=$(grep -m1 -E '^\*\*Status:\*\*' "$f" 2>/dev/null \
      | sed 's/.*\*\*Status:\*\*[[:space:]]*//' | tr -d '[:space:]')
    [ "$status" = "READY" ] || continue
    if [ "$id" -lt "$best_id" ]; then
      best_id=$id
      best=$f
    fi
  done
  [ -n "$best" ] && printf '%s' "$best"
}

plan_goal_oneline() {
  awk 'BEGIN{g=0} /^## Goal/{g=1; next} g && /^## /{exit} g && NF{print}' "$1" \
    | head -3 | tr '\n' ' ' | sed 's/[[:space:]]\{1,\}/ /g; s/^ //; s/ $//'
}

# ── Main loop ───────────────────────────────────────────────────────
ITERATION=0

while true; do
  ITERATION=$((ITERATION + 1))

  # ── Check limits ────────────────────────────────────────────────
  if time_up; then
    echo "▸ Time limit reached (${MAX_HOURS}h)"
    break
  fi
  if attempts_up; then
    echo "▸ Task limit reached ($MAX_ATTEMPTS)"
    break
  fi

  NEXT_COUNT=$(count_tasks "$NEXT_DIR")

  # ── Retry: re-gate tasks that landed in blocked/ during this run ──
  # Still must pass workability before re-entering next/ (no raw promote).
  if [ "$NEXT_COUNT" -eq 0 ] && [ "$RETRY" -eq 1 ] && [ "$_RETRY_USED" -eq 0 ]; then
    _RETRY_USED=1
    _retried_any=0
    for f in "$BLOCKED_DIR"/*.md; do
      [ -f "$f" ] || continue
      name="${f##*/}"
      # Only retry tasks that weren't already in blocked/ before this run
      if ! grep -qxF "$name" "$_INITIAL_BLOCKED" 2>/dev/null; then
        echo "  ↻ Retrying (gate): $name"
        sprintbias_promote_to_sprint "$f" loop-retry
        echo "    $(sprintbias_promote_summary "$name")"
        if [ "${SPRINTBIAS_GATE_VERDICT:-}" = "READY" ] || [ "${SPRINTBIAS_GATE_VERDICT:-}" = "EMIT" ]; then
          RETRIED=$((RETRIED + 1))
          _retried_any=1
        fi
      fi
    done
    [ "$_retried_any" -eq 1 ] && echo ""
    NEXT_COUNT=$(count_tasks "$NEXT_DIR")
  fi

  # ── Refill: plan start on next READY plan (human-authored only) ─
  if [ "$NEXT_COUNT" -eq 0 ] && [ "$REFILL" -eq 1 ]; then
    _ready_plan="$(next_ready_plan || true)"
    if [ -n "$_ready_plan" ]; then
      _ready_id=$(basename "$_ready_plan" | grep -oE '^[0-9]+')
      echo "▸ Refilling via plan start $_ready_id ($(basename "$_ready_plan"))..."
      if bash "$SCRIPT_DIR/plan-start.sh" "$_ready_id" < /dev/null; then
        ACTIVE_PLAN_ID="$_ready_id"
        ACTIVE_PLAN_GOAL="$(plan_goal_oneline "$_ready_plan")"
        export SPRINTBIAS_ACTIVE_PLAN_ID="$ACTIVE_PLAN_ID"
        export SPRINTBIAS_ACTIVE_PLAN_FILE="$_ready_plan"
        export SPRINTBIAS_ACTIVE_PLAN_GOAL="$ACTIVE_PLAN_GOAL"
        if [ -n "$ACTIVE_PLAN_GOAL" ]; then
          echo "  Active plan goal: $ACTIVE_PLAN_GOAL"
        fi
        # plan start already gated members before promoting them into next/ —
        # no separate define step. SPRINTBIAS_ACTIVE_PLAN_* stays exported as
        # cheap run context that tasks may read.
        REFILLS=$((REFILLS + 1))
      else
        echo "  ⚠ plan start $_ready_id failed — fix blocked/dangling members or status"
      fi
      NEXT_COUNT=$(count_tasks "$NEXT_DIR")
      echo ""
    else
      echo "▸ Refill requested but no READY plan in docs/plans/"
      echo "  Author one: ./sprint.sh newplan \"…\" && ./sprint.sh chat plan <id>"
      echo "  Mark READY, then re-run loop --refill."
    fi
  fi

  # ── Nothing left ────────────────────────────────────────────────
  if [ "$NEXT_COUNT" -eq 0 ]; then
    echo "▸ No tasks remaining in next/"
    break
  fi

  # ── Identify next task ──────────────────────────────────────────
  CURRENT_TASK=$(ls -1 "$NEXT_DIR"/*.md 2>/dev/null | sed 's|.*/||' | sort -t- -k1,1n | head -1)

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "▸ Iteration $ITERATION: $CURRENT_TASK ($NEXT_COUNT in queue)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # ── Run one task ────────────────────────────────────────────────
  BEFORE_REVIEW=$(count_tasks "$REVIEW_DIR")
  BEFORE_BLOCKED=$(count_tasks "$BLOCKED_DIR")

  # `count 1` caps this iteration at one task. A bare `1` now means "work task
  # id 1", so the loop must use the count sub-word to keep one-task-per-iteration.
  bash "$SCRIPT_DIR/work.sh" count 1 "${PASSTHROUGH[@]+"${PASSTHROUGH[@]}"}" || true

  # Rescue any task left in doing/ (crash recovery)
  for f in "$DOING_DIR"/*.md; do
    [ -f "$f" ] || continue
    name="${f##*/}"
    move_file "$f" "$BLOCKED_DIR/$name"
    echo "  ⚠ $name incomplete → blocked/ (needs decision or clarification)"
  done

  AFTER_REVIEW=$(count_tasks "$REVIEW_DIR")
  AFTER_BLOCKED=$(count_tasks "$BLOCKED_DIR")
  AFTER_NEXT=$(count_tasks "$NEXT_DIR")

  # Nothing moved at all → the runner's readiness gate declined every task.
  # Iterating again would spin forever on the same undefined queue.
  if [ "$AFTER_NEXT" -eq "$NEXT_COUNT" ] && [ "$AFTER_REVIEW" -eq "$BEFORE_REVIEW" ] \
     && [ "$AFTER_BLOCKED" -eq "$BEFORE_BLOCKED" ]; then
    echo "▸ No progress — $AFTER_NEXT task(s) in next/ but none are ready to execute."
    echo "  Vet them with ./sprint.sh gate, or loop with --force."
    break
  fi

  if [ "$AFTER_REVIEW" -gt "$BEFORE_REVIEW" ]; then
    COMPLETED=$((COMPLETED + 1))
  else
    FAILED=$((FAILED + 1))
  fi

  status_line

  # ── Cooldown ────────────────────────────────────────────────────
  NEXT_COUNT=$(count_tasks "$NEXT_DIR")
  if [ "$COOLDOWN" -gt 0 ] && [ "$NEXT_COUNT" -gt 0 ]; then
    echo "  ⏳ ${COOLDOWN}s cooldown"
    sleep "$COOLDOWN"
  fi
done

# ── Summary ─────────────────────────────────────────────────────────
TOTAL_ELAPSED=$(( SECONDS - TOTAL_START ))
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "▸ Loop complete"
echo "  Completed: $COMPLETED"
echo "  Failed:    $FAILED"
echo "  Retried:   $RETRIED"
echo "  Refills:   $REFILLS"
printf '  Duration:  %dh %dm %ds\n' "$((TOTAL_ELAPSED/3600))" "$(((TOTAL_ELAPSED%3600)/60))" "$((TOTAL_ELAPSED%60))"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
