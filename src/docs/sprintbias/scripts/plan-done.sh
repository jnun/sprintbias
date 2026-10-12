#!/usr/bin/env bash
# plan-done.sh — Retire a plan whose every member is finished. See: ./sprint.sh help plan
#
# Invoked as: ./sprint.sh plan done [id]
#
# Pure shell, NO AI. A plan is done only when EVERY member task is in
# docs/tasks/done/ — sign-off lives in the folder a task sits in, never in a
# hand-stamped DONE on the plan. This script verifies that invariant and, on a
# full pass, retires the plan into a history record: it writes
# docs/history/YYYY-MM-DD-plan-N-<slug>.md (goal, decisions, one line per
# member, follow-ups), then removes the plan file (git rm || rm). Any member
# missing or in a non-done/ folder → FAIL report, exit 1, plan untouched, no
# record. DONE is never a stored status on the plan.

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

PLANS_DIR="docs/plans"
DONE_DIR="docs/tasks/done"
HISTORY_DIR="docs/history"

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

# plan_section FILE HEADING — body of "## HEADING" with HTML comments stripped,
# outer blank lines trimmed and inner blank runs squeezed. Empty when absent.
plan_section() {
  awk -v h="## $2" '
    { sub(/\r$/, ""); t = $0; sub(/[ \t]+$/, "", t) }
    /^## / { if (on) exit; if (t == h) on = 1; next }
    !on { next }
    {
      line = $0; out = ""; had = 0
      while (1) {
        if (inc) { i = index(line, "-->"); if (!i) { line = ""; break }
                   line = substr(line, i + 3); inc = 0 }
        i = index(line, "<!--"); if (!i) { out = out line; break }
        had = 1; out = out substr(line, 1, i - 1); line = substr(line, i + 4); inc = 1
      }
      if ((had || inc) && out ~ /^[ \t]*$/) next
      n++; buf[n] = out
    }
    END {
      first = 0; last = 0
      for (k = 1; k <= n; k++) if (buf[k] !~ /^[ \t]*$/) { if (!first) first = k; last = k }
      blank = 0
      for (k = first; k && k <= last; k++) {
        if (buf[k] ~ /^[ \t]*$/) { if (!blank) print ""; blank = 1 } else { print buf[k]; blank = 0 }
      }
    }' "$1"
}

# write_record PLAN_FILE RECORD — build the history record in a temp file
# beside RECORD, then rename it into place, so a record is whole or absent.
write_record() {
  local plan="$1" rec="$2" tmp id f title summ stage goal why decided fu_lines=""
  mkdir -p "$HISTORY_DIR" 2>/dev/null || return 1
  tmp=$(mktemp "$HISTORY_DIR/.record.XXXXXX" 2>/dev/null) || return 1

  # Follow-ups: tasks anywhere stamped **From plan**: N that are not members.
  for stage in backlog next doing blocked review done; do
    for f in "docs/tasks/$stage"/*.md; do
      [ -f "$f" ] || continue
      [ "$(sprintbias_meta_value "$f" "From plan" | tr -d '[:space:]#')" = "$PLAN_ID" ] || continue
      id=$(basename "$f" | grep -oE '^[0-9]+' || true)
      [ -n "$id" ] || continue
      grep -qx "$id" <<<"$MEMBER_IDS" && continue
      fu_lines+="- #$id — $(task_title "$f" | tr -d '\r') ($f)"$'\n'
    done
  done

  goal=$(plan_section "$plan" "Goal")
  why=$(plan_section "$plan" "Why")
  decided=$(plan_section "$plan" "Decided")

  {
    printf '# Plan %s: %s\n\n' "$PLAN_ID" "${_title:-Plan $PLAN_ID}"
    printf '**Finished**: %s · **Members**: %s\n' "$TODAY" "$(wc -l <<<"$MEMBER_IDS" | tr -d ' ')"
    [ -n "$goal" ] && printf '\n## Goal\n\n%s\n' "$goal"
    [ -n "$why" ] && printf '\n## Why\n\n%s\n' "$why"
    [ -n "$decided" ] && printf '\n## Decided\n\n%s\n' "$decided"
    printf '\n## What changed\n\n'
    for id in $MEMBER_IDS; do
      f=$(find "$DONE_DIR" -maxdepth 1 -name "${id}-*.md" 2>/dev/null | head -1)
      title=$(task_title "$f" | tr -d '\r')
      summ=$(sprintbias_task_summary "$f")
      if [ -n "$summ" ]; then
        printf -- '- #%s — %s: %s (%s)\n' "$id" "$title" "$summ" "$f"
      else
        printf -- '- #%s — %s (%s)\n' "$id" "$title" "$f"
      fi
    done
    if [ -n "$fu_lines" ]; then printf '\n## Follow-ups\n\n%s' "$fu_lines"; fi
  } > "$tmp" && mv -f "$tmp" "$rec" || { rm -f "$tmp"; return 1; }
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

# ── Full pass: write the history record, then remove the plan ───────
# The record is read from the plan, so it is written (whole) before the plan
# file goes. A failed write leaves the plan in place and exits non-zero.
_title=$({ grep -m1 '^# ' "$PLAN_FILE" || true; } | tr -d '\r' | sed -E 's/^# *(Plan *[0-9]+: *)?//')
TODAY=$(date +%Y-%m-%d)
_slug=$(basename "$PLAN_FILE" .md); _slug="${_slug#"$PLAN_ID"-}"
RECORD="$HISTORY_DIR/$TODAY-plan-$PLAN_ID-$_slug.md"

if ! write_record "$PLAN_FILE" "$RECORD"; then
  echo "✗ Could not write the history record $RECORD — plan $PLAN_ID left in place."
  exit 1
fi

# The plan file goes; its story lives on in the record. git rm keeps the removal
# in history when tracked (-f: a staged, uncommitted plan too; the record
# holds its content); plain rm covers an untracked plan. Staging the record
# beside the removal makes the pair read as one retirement. Developer owns the commit.
git rm -qf "$PLAN_FILE" 2>/dev/null || rm -f "$PLAN_FILE"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git add -- "$RECORD" 2>/dev/null || true
fi

echo "✓ Plan $PLAN_ID complete — every member in done/. Retired $(basename "$PLAN_FILE") into $RECORD."
echo "  (In a git repo the record and the removal are staged; the commit is yours.)"
echo ""
echo "▸ Changelog line, ready to paste:"
echo "    - Plan $PLAN_ID: ${_title:-Plan $PLAN_ID} — see $RECORD"

# The rework this plan's review filed (**From plan**: N) is the natural next
# plan — name the exact commands so burning through it is one step away.
_fu=$(sprintbias_plan_followups "$PLAN_ID" | wc -l | tr -d ' ')
if [ "$_fu" -gt 0 ]; then
  echo ""
  echo "▸ $_fu follow-up task(s) came out of this plan. Group and work them:"
  echo "    ./sprint.sh newplan \"${_title:-Plan $PLAN_ID} — follow-ups\" from:$PLAN_ID"
  echo "    ./sprint.sh plan start <new plan id>"
  echo "    ./sprint.sh work"
fi
exit 0
