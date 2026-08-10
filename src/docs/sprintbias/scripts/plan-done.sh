#!/usr/bin/env bash
# plan-done.sh — Retire a plan whose every member is finished. See: ./sprint.sh help plan
#
# Invoked as: ./sprint.sh plan done [id]
#
# Pure shell, NO AI. A plan is done only when EVERY member task is in
# docs/tasks/done/ — sign-off lives in the folder a task sits in, never in a
# hand-stamped DONE on the plan. This script verifies that invariant and, on a
# full pass, deletes the plan file (git rm || rm). Any member missing or in a
# non-done/ folder → FAIL report, exit 1, plan untouched. DONE on a plan is a
# delete, never a written status.

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

PLANS_DIR="docs/plans"
DONE_DIR="docs/tasks/done"

# ── Args: plan id (any position) ─────────────────────────────────────
PLAN_ID=""
for _arg in "$@"; do
  case "$_arg" in
    *) [ -z "$PLAN_ID" ] && PLAN_ID="$_arg" ;;
  esac
done
unset _arg

# ── Plan helpers (shared shape with plan-start.sh) ───────────────────

list_plans() { sprintbias_list_plans; }
find_plan() { sprintbias_find_plan "$1"; }

# Where does a member live? Prints the stage name (backlog/next/.../done) or
# empty if no task file exists anywhere.
member_stage() {
  local id="$1" stage dir match
  for stage in backlog next doing blocked review done; do
    dir="docs/tasks/$stage"
    match=$(find "$dir" -maxdepth 1 -name "${id}-*.md" 2>/dev/null | head -1) || true
    [ -n "$match" ] && { printf '%s' "$stage"; return 0; }
  done
  return 1
}

# ── Pick / resolve plan ──────────────────────────────────────────────

if [ -z "$PLAN_ID" ]; then
  echo "▸ plan done — retire a plan whose every member is in done/"
  echo ""
  if ! ls "$PLANS_DIR"/*.md >/dev/null 2>&1; then
    echo "No plans to retire."
    exit 1
  fi
  echo "Plans:"
  list_plans
  echo ""
  if [ -t 0 ] && [ -t 1 ]; then
    printf "Plan id to finish (or blank to cancel): "
    read -r PLAN_ID </dev/tty 2>/dev/null || PLAN_ID=""
  else
    echo "Usage: ./sprint.sh plan done <id>"
    exit 1
  fi
  [ -n "$PLAN_ID" ] || { echo "Cancelled."; exit 0; }
fi

if ! [[ "$PLAN_ID" =~ ^[0-9]+$ ]]; then
  echo "Error: '$PLAN_ID' is not a plan id."
  echo "Usage: ./sprint.sh plan done [id]   # plan id, not a task id"
  exit 1
fi

if ! PLAN_FILE="$(find_plan "$PLAN_ID")"; then
  echo "Error: No plan found with ID $PLAN_ID in $PLANS_DIR/"
  echo "Existing plans:"
  list_plans
  exit 1
fi

echo "▸ Finishing plan: $(basename "$PLAN_FILE")"
echo ""

# ── Collect members ──────────────────────────────────────────────────

MEMBER_IDS=$(grep -oE '^- (\[[ xX]\] )?#[0-9]+' "$PLAN_FILE" 2>/dev/null | grep -oE '[0-9]+' | awk '!seen[$0]++' || true)
if [ -z "$MEMBER_IDS" ]; then
  echo "Plan $PLAN_ID has no member tasks — nothing to sign off."
  echo "Add members with: ./sprint.sh chat plan $PLAN_ID"
  exit 1
fi

# ── Verify every member is in done/ ──────────────────────────────────
# Sign-off = done/ ONLY (not review/). Missing file or any other folder fails.

declare -a NOT_DONE=()
for id in $MEMBER_IDS; do
  if [ -n "$(find "$DONE_DIR" -maxdepth 1 -name "${id}-*.md" 2>/dev/null | head -1)" ]; then
    continue
  fi
  if stage="$(member_stage "$id")"; then
    NOT_DONE+=("#$id — in $stage/ (needs done/)")
  else
    NOT_DONE+=("#$id — no task file found")
  fi
done

if [ ${#NOT_DONE[@]} -gt 0 ]; then
  echo "✗ Plan $PLAN_ID is not finished — every member must be in done/:"
  for line in "${NOT_DONE[@]}"; do
    echo "    $line"
  done
  echo ""
  echo "  Finish the work above, then re-run: ./sprint.sh plan done $PLAN_ID"
  exit 1
fi

# ── Full pass: normalize member lines, then delete the plan ──────────
# Tick every member checkbox to [x] (they are all in done/). Handles a missing
# or unticked checkbox alike; keeps the trailing title text intact.
sed_inplace -E 's/^- (\[[ xX]\] )?#([0-9]+)/- [x] #\2/' "$PLAN_FILE"

# DONE on a plan is a delete, never a stored status. git rm keeps the removal in
# history when tracked; plain rm covers an untracked plan. Developer owns the commit.
git rm -q "$PLAN_FILE" 2>/dev/null || rm -f "$PLAN_FILE"

echo "✓ Plan $PLAN_ID complete — every member in done/. Removed $(basename "$PLAN_FILE")."
echo "  (git rm staged the removal when tracked; commit is yours.)"
exit 0
