#!/usr/bin/env bash
# plan-polish.sh — Excellence-judge a plan's completed work. See: ./sprint.sh help plan
#
# Invoked as: ./sprint.sh plan polish [id] [--force]
#
# The plan-scoped equivalent of `polish <id>`: run the excellence deep-judge over
# every member of a plan that has reached review/ or done/ — the plan's finished
# body of work. Each finished member is judged by the one excellence unit
# (polish-judge.sh / audit-excellence.md): never edits product code, never
# reopens a task, appends a ## Excellence section, and files enhancements as new
# backlog/ tasks. Members still in backlog/next/doing/blocked are skipped — not
# finished. A member already carrying a ## Excellence section is skipped too,
# unless --force re-judges it. Members not yet finished are skipped with a notice.
#
# This never reopens work and never touches state a `plan done` cares about; the
# reopen sweep and the code audit stay on `polish` itself. See ./sprint.sh help plan.

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PLANS_DIR="docs/plans"
PROTOCOL="docs/sprintbias/ai/audit-excellence.md"

# ── Args: plan id (positional) + --force ─────────────────────────────
FORCE=0
PLAN_ID=""
while [ $# -gt 0 ]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    -h|--help) echo "Usage: ./sprint.sh plan polish [id] [--force]"; exit 0 ;;
    -*) echo "✗ Unknown flag: $1" >&2; echo "Usage: ./sprint.sh plan polish [id] [--force]" >&2; exit 1 ;;
    *) [ -z "$PLAN_ID" ] && PLAN_ID="$1"; shift ;;
  esac
done

AI_MODE="$(sprintbias_ai_mode)"

if [ "$AI_MODE" != "emit" ] && ! command -v "$SPRINTBIAS_CLI" &>/dev/null; then
  echo "✗ AI CLI '$SPRINTBIAS_CLI' not found in PATH"
  echo "  Edit docs/sprintbias/config to change CLI, or install the tool."
  echo "  Required by: plan polish (excellence judge over a plan's finished work)"
  exit 1
fi

# ── Plan resolve / picker (shared shape with plan-think / plan-done) ──
list_plans() { sprintbias_list_plans; }
find_plan() { sprintbias_find_plan "$1"; }

# Resolve a member ID to its task file path (first lifecycle stage it appears
# in), or fail. The path already encodes the stage — `basename $(dirname …)` —
# so one lookup answers both "where does it live" and "what's the file."
member_path() {
  local id="$1" stage match
  for stage in backlog next doing blocked review done; do
    match=$(find "docs/tasks/$stage" -maxdepth 1 -name "${id}-*.md" 2>/dev/null | head -1) || true
    [ -n "$match" ] && { printf '%s' "$match"; return 0; }
  done
  return 1
}

# Count of ## Excellence sections in a task file — polish-judge.sh appends one
# per run, so a bump across a run confirms it actually wrote a verdict. Mirrors
# polish.sh's own _rework_sections shape. Always prints a number (0 on none).
_excellence_count() { local n; n=$(grep -c '^## Excellence' "$1" 2>/dev/null) || true; echo "${n:-0}"; }

if [ -z "$PLAN_ID" ]; then
  echo "▸ plan polish — excellence-judge a plan's finished work (review/ + done/)"
  echo ""
  if ! ls "$PLANS_DIR"/*.md >/dev/null 2>&1; then
    echo "No plans yet. Author one first:"
    echo "  ./sprint.sh newplan \"<name>\""
    echo "  ./sprint.sh chat plan <id>"
    exit 1
  fi
  echo "Plans:"
  list_plans
  echo ""
  if [ -t 0 ] && [ -t 1 ]; then
    printf "Plan id to polish (or blank to cancel): "
    read -r PLAN_ID </dev/tty 2>/dev/null || PLAN_ID=""
  else
    echo "Usage: ./sprint.sh plan polish <id>"
    exit 1
  fi
  [ -n "$PLAN_ID" ] || { echo "Cancelled."; exit 0; }
fi

if ! [[ "$PLAN_ID" =~ ^[0-9]+$ ]]; then
  echo "Error: '$PLAN_ID' is not a plan id."
  echo "Usage: ./sprint.sh plan polish [id]   # plan id, not a task id"
  exit 1
fi

if ! PLAN_FILE="$(find_plan "$PLAN_ID")"; then
  echo "Error: No plan found with ID $PLAN_ID in $PLANS_DIR/"
  echo "Existing plans:"
  list_plans
  exit 1
fi

echo "▸ Plan: $(basename "$PLAN_FILE")"

# ── Collect members, keep the finished ones (review/ or done/) ───────
MEMBER_IDS=$(grep -oE '^- (\[[ xX]\] )?#[0-9]+' "$PLAN_FILE" 2>/dev/null | grep -oE '[0-9]+' | awk '!seen[$0]++' || true)
if [ -z "$MEMBER_IDS" ]; then
  echo "Plan $PLAN_ID has no member tasks — nothing to polish."
  echo "Add members with: ./sprint.sh chat plan $PLAN_ID"
  exit 1
fi

FIN_PATHS=()   # finished member task files (review/ or done/), in plan order
UNFINISHED=()  # "#id — in <stage>/" lines, for the skip notice
MISSING=()     # "#id — no task file" lines
for id in $MEMBER_IDS; do
  if path="$(member_path "$id")"; then
    stage=$(basename "$(dirname "$path")")
    case "$stage" in
      review|done) FIN_PATHS+=("$path") ;;
      *)           UNFINISHED+=("#$id — in $stage/") ;;
    esac
  else
    MISSING+=("#$id — no task file found")
  fi
done

if [ ${#UNFINISHED[@]} -gt 0 ] || [ ${#MISSING[@]} -gt 0 ]; then
  echo "⊘ Skipping $(( ${#UNFINISHED[@]} + ${#MISSING[@]} )) member(s) not yet finished:"
  for line in ${UNFINISHED[@]+"${UNFINISHED[@]}"}; do echo "    $line"; done
  for line in ${MISSING[@]+"${MISSING[@]}"};    do echo "    $line"; done
fi

if [ ${#FIN_PATHS[@]} -eq 0 ]; then
  echo ""
  echo "No finished members to polish — none of plan $PLAN_ID's members are in review/ or done/."
  echo "Finish some work first (./sprint.sh work), then re-run: ./sprint.sh plan polish $PLAN_ID"
  exit 0
fi

# ── Idempotency pre-filter (deterministic, shared predicate) ─────────
# A finished member already carrying a ## Excellence section was judged already;
# skip it unless --force. Enforced here in the shell for BOTH emit and exec so
# the guard is deterministic, not left to the model — the same test polish-judge.sh
# applies per file (sprintbias_excellence_has_section).
TO_JUDGE=()
ALREADY=()
for p in "${FIN_PATHS[@]}"; do
  if [ "$FORCE" -ne 1 ] && sprintbias_excellence_has_section "$p"; then
    ALREADY+=("$p")
  else
    TO_JUDGE+=("$p")
  fi
done

if [ ${#ALREADY[@]} -gt 0 ]; then
  echo "⊘ Skipping ${#ALREADY[@]} member(s) already judged (carry a ## Excellence section):"
  for p in "${ALREADY[@]}"; do echo "    ${p##*/}"; done
  echo "  Re-judge anyway:  ./sprint.sh plan polish $PLAN_ID --force"
fi

if [ ${#TO_JUDGE[@]} -eq 0 ]; then
  echo ""
  echo "Nothing to judge — every finished member of plan $PLAN_ID is already judged."
  echo "Re-judge them all:  ./sprint.sh plan polish $PLAN_ID --force"
  exit 0
fi

COUNT=${#TO_JUDGE[@]}
echo "▸ Finished members to judge: $COUNT (review/ + done/)$([ "$FORCE" -eq 1 ] && echo ' · --force')"
echo ""

# ═════════════════════════════════════════════════════════════════════
# EMIT — one orchestration prompt: excellence-judge each finished member
# ═════════════════════════════════════════════════════════════════════
if [ "$AI_MODE" = "emit" ]; then
  if [ ! -f "$PROTOCOL" ]; then
    echo "✗ Protocol file missing: $PROTOCOL" >&2
    exit 1
  fi
  _profile_line="$(sprintbias_profile_line)"
  _rules="$(sprintbias_excellence_rules)"

  _member_list=""
  for p in "${TO_JUDGE[@]}"; do
    _member_list="${_member_list}
- ${p}  ($(basename "$(dirname "$p")")/)"
  done

  if sprintbias_orchestration_capable; then
    sprintbias_run -p "You are running the SprintBias plan-polish pass: $COUNT finished
member task(s) of plan $PLAN_ID (in review/ or done/) to excellence-judge.
CLAUDE.md / AGENTS.md is auto-loaded when present.${_profile_line}

Judge each member in $(sprintbias_subagent_own_fresh polish) so contexts never
mix. You are the orchestrator — the subagents judge and write; you only route.

For EACH member task file below, launch a subagent whose entire instruction is:
   \"Excellence-judge ONE finished task. Read the task file at <path> and judge
    its finished work against the higher bar.
$(sprintbias_subagent_no_nest)
$_rules\"

Members (plan order):$_member_list

When every member is judged, report a one-line summary: how many EXCELLENT vs
FILED (with total enhancement tasks filed) vs BLOCKER. Filed enhancements land
in docs/tasks/backlog/; nothing was reopened or moved." || {
      echo "✗ plan polish failed" >&2; exit 1; }
  else
    sprintbias_run -p "You are running the SprintBias plan-polish pass: $COUNT finished
member task(s) of plan $PLAN_ID (in review/ or done/) to excellence-judge.
CLAUDE.md is auto-loaded.${_profile_line}

Work the members ONE AT A TIME, in the listed order. You have no subagent tool,
so you are the judge — after each member, reset your focus and start the next
from a clean slate.

For EACH member task file below:
1. Read the task file at <path> and judge its finished work.
$_rules

Members (plan order):$_member_list

When every member is judged, report a one-line summary: how many EXCELLENT vs
FILED (with total enhancement tasks filed) vs BLOCKER. Filed enhancements land
in docs/tasks/backlog/; nothing was reopened or moved."
  fi
  exit 0
fi

# ═════════════════════════════════════════════════════════════════════
# EXEC — loop: route each member through the one excellence unit
# ═════════════════════════════════════════════════════════════════════
# polish-judge.sh IS the excellence deep-judge for one finished piece — the same
# unit `polish <id>` runs. plan polish is a thin plan-scoped selector over it, so
# scoping, the ## Excellence append, filing, and the guard all live in one place.
#
# Each result is read from the ## Excellence block polish-judge.sh appends — its
# own verdict contract (- **Verdict**: … / - **Tasks filed**: …), not its human
# stdout. A bump in the section count confirms a verdict was written; no bump
# means polish-judge.sh bailed before judging (it could not scope the task's
# changes), surfaced as unscoped rather than miscounted. Members are pre-filtered
# above, so a guard-skip never reaches this loop.
EXCELLENT=0; FILED_MEMBERS=0; FILED_TASKS=0; BLOCKERS=0; UNCLEAR=0; UNSCOPED=0
TOTAL_START=$SECONDS

for ((i=0; i<COUNT; i++)); do
  p="${TO_JUDGE[$i]}"
  N=$((i + 1))
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "▸ plan polish $N/$COUNT: ${p##*/} ($(basename "$(dirname "$p")")/)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  _pj_args=(--task "$p")
  [ "$FORCE" -eq 1 ] && _pj_args=(--force --task "$p")

  before=$(_excellence_count "$p")
  bash "$SCRIPT_DIR/polish-judge.sh" "${_pj_args[@]}" || true
  after=$(_excellence_count "$p")

  if [ "$after" -le "$before" ]; then
    # No new ## Excellence section — polish-judge.sh bailed before judging.
    UNSCOPED=$((UNSCOPED + 1))
  else
    verdict=$(grep '^- \*\*Verdict\*\*:' "$p" | tail -1 | sed 's/^[^:]*: *//' | tr -d '[:space:]')
    case "$verdict" in
      EXCELLENT) EXCELLENT=$((EXCELLENT + 1)) ;;
      FILED)
        FILED_MEMBERS=$((FILED_MEMBERS + 1))
        n=$(grep '^- \*\*Tasks filed\*\*:' "$p" | tail -1 | grep -oE '[0-9]+' | head -1)
        [[ "$n" =~ ^[0-9]+$ ]] && FILED_TASKS=$((FILED_TASKS + n))
        ;;
      BLOCKER)   BLOCKERS=$((BLOCKERS + 1)) ;;
      *)         UNCLEAR=$((UNCLEAR + 1)) ;;
    esac
  fi
  echo ""
done

TOTAL_ELAPSED=$((SECONDS - TOTAL_START))
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "▸ Done: $EXCELLENT excellent, $FILED_MEMBERS filed ($FILED_TASKS enhancement task(s) → backlog/), $BLOCKERS blocker(s), $UNCLEAR unclear, $UNSCOPED unscoped — total $((TOTAL_ELAPSED / 60))m $((TOTAL_ELAPSED % 60))s"
if [ "$FILED_TASKS" -gt 0 ]; then
  echo "  → Review filed enhancements:  ./sprint.sh chat backlog"
fi
if [ "$UNSCOPED" -gt 0 ]; then
  echo "  → $UNSCOPED member(s) had no scopable change set — add a '### Files changed' block under ## Completed, then re-run."
fi
if [ "$BLOCKERS" -gt 0 ] || [ "$UNCLEAR" -gt 0 ] || [ "$UNSCOPED" -gt 0 ]; then
  exit 1
fi
