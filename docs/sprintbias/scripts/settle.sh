#!/usr/bin/env bash
# settle.sh — Accept (Suggestion: …) open questions, fold into the body, clear.
# See: ./sprint.sh help settle
#
# Closes the "READY + open questions" loop without a full chat session:
#   1. For each open question that carries (Suggestion: …), write the pick into
#      ## Notes and delete the question.
#   2. When the list is empty, write "None — task is fully defined."
#   3. Demote any task that still has open questions (no suggestion) out of
#      next/ so READY + open Q cannot stay queued.
#
# Usage:
#   ./sprint.sh settle              # all next/ (and optional --blocked)
#   ./sprint.sh settle 966          # one task id (any stage)
#   ./sprint.sh settle --dry-run    # report only
#   ./sprint.sh settle --blocked    # also process blocked/ (bulk)

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"
# ## BLOCKED section helper when demoting
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/gate-lib.sh" 2>/dev/null || true

NEXT_DIR="docs/tasks/next"
BLOCKED_DIR="docs/tasks/blocked"
DRY_RUN=0
INCLUDE_BLOCKED=0
TASK_ID=""

for arg in "$@"; do
  case "$arg" in
    --dry-run)  DRY_RUN=1 ;;
    --blocked)  INCLUDE_BLOCKED=1 ;;
    --help|-h)
      echo "Usage: ./sprint.sh settle [id] [--dry-run] [--blocked]"
      echo "  Accept every open question that has a (Suggestion: …), fold it into"
      echo "  ## Notes, clear the list, demote any that still need a human answer."
      exit 0
      ;;
    [0-9]*)
      if [ -n "$TASK_ID" ]; then
        echo "✗ settle takes at most one task id" >&2
        exit 1
      fi
      TASK_ID="$arg"
      ;;
    *)
      echo "✗ Unknown argument: $arg" >&2
      echo "  See: ./sprint.sh help settle" >&2
      exit 1
      ;;
  esac
done

_targets=()
if [ -n "$TASK_ID" ]; then
  _path="$(sprintbias_task_path "$TASK_ID" 2>/dev/null || true)"
  if [ -z "$_path" ] || [ ! -f "$_path" ]; then
    echo "✗ Task $TASK_ID not found under docs/tasks/" >&2
    exit 1
  fi
  _targets+=("$_path")
else
  for f in "$NEXT_DIR"/*.md; do
    [ -f "$f" ] || continue
    _targets+=("$f")
  done
  if [ "$INCLUDE_BLOCKED" -eq 1 ]; then
    for f in "$BLOCKED_DIR"/*.md; do
      [ -f "$f" ] || continue
      _targets+=("$f")
    done
  fi
fi

if [ ${#_targets[@]} -eq 0 ]; then
  echo "No task files to settle."
  exit 0
fi

SETTLED_FILES=0
SETTLED_QS=0
REMAINING_FILES=0
DEMOTED=0
SKIPPED=0

echo "▸ settle — accept (Suggestion: …) open questions"
[ "$DRY_RUN" -eq 1 ] && echo "  (dry-run — no writes)"
echo ""

for f in "${_targets[@]}"; do
  name="${f##*/}"
  id="${name%%-*}"
  if ! sprintbias_has_open_questions "$f"; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  n_before=$(sprintbias_open_questions "$f" | grep -c . || true)
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  · $id  would settle questions with suggestions ($n_before open):"
    sprintbias_open_questions "$f" | sed 's/^/      /'
    # Count how many carry Suggestion
    n_sug=$(sprintbias_open_questions "$f" | grep -ciE '\(Suggestion:' || true)
    echo "      → $n_sug with Suggestion (would fold); $((n_before - n_sug)) need a human"
    SETTLED_FILES=$((SETTLED_FILES + 1))
    continue
  fi

  result="$(sprintbias_accept_suggestions "$f")"
  # result: settled=N remaining=M
  s="${result##*settled=}"; s="${s%% *}"
  r="${result##*remaining=}"
  s="${s:-0}"; r="${r:-0}"

  if [ "${s:-0}" -gt 0 ] 2>/dev/null; then
    SETTLED_FILES=$((SETTLED_FILES + 1))
    SETTLED_QS=$((SETTLED_QS + s))
    echo "  ✓ $id  accepted $s suggestion(s) → ## Notes; remaining open: $r"
  else
    echo "  · $id  no (Suggestion: …) to accept ($n_before open — need chat)"
  fi

  if sprintbias_has_open_questions "$f"; then
    REMAINING_FILES=$((REMAINING_FILES + 1))
    # Demote out of next/ (and doing/) so work never sees READY+openQ.
    case "$f" in
      "$NEXT_DIR"/*|"docs/tasks/doing"/*)
        if sprintbias_demote_open_questions "$f" "$BLOCKED_DIR"; then
          DEMOTED=$((DEMOTED + 1))
        fi
        ;;
      *)
        # Already blocked or elsewhere: ensure stamp is BLOCKED when Qs remain.
        case "$(sprintbias_review_verdict "$f")" in
          READY|COMPLETE)
            sprintbias_set_review_status "$f" "BLOCKED" || true
            echo "  ⚠ $id  stamp → BLOCKED (open questions remain)"
            ;;
        esac
        ;;
    esac
  else
    # Fully cleared: if stamp was BLOCKED and file is in blocked/, leave it —
    # promote is the human/gate path back to next/. If still in next/ with
    # READY, leave READY (list is clear).
    if [ "$(sprintbias_review_verdict "$f")" = "BLOCKED" ] \
         && ! sprintbias_has_open_questions "$f"; then
      echo "  · $id  questions clear — re-enter via: bash docs/sprintbias/scripts/promote-to-sprint.sh $f"
    fi
  fi
done

echo ""
echo "▸ Done: $SETTLED_FILES file(s) settled ($SETTLED_QS suggestion(s) folded),"
echo "        $REMAINING_FILES still have open questions, $DEMOTED demoted to blocked/,"
echo "        $SKIPPED already clear."
if [ "$DRY_RUN" -eq 0 ] && [ "$REMAINING_FILES" -gt 0 ]; then
  echo "  Remaining need a human: ./sprint.sh chat <id>"
fi
exit 0
