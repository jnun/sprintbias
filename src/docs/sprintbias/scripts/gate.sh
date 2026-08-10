#!/usr/bin/env bash
# shellcheck disable=SC2207
# gate.sh — Vet task quality. See: ./sprint.sh help gate
#
# Two modes, one command (off-spine; happy path is plan start → work):
#   next/ (default) — deep READY-gate: write ## Questions, move BLOCKED/COMPLETE
#   backlog|doing|blocked — quality report only: per-task verdict, no writes/moves
set -euo pipefail

FOLDER="next"
MAX_TASKS=999
FORCE=0

_usage() {
  echo "Usage: ./sprint.sh gate [folder] [limit] [--model <id>] [--force]" >&2
  echo "  folder: backlog|next|doing|blocked (default: next)" >&2
  echo "  --model <id>: pin the model for this run only (see ./sprint.sh model)" >&2
  echo "  On next/: stamps READY/BLOCKED/COMPLETE and moves unready tasks." >&2
  echo "  On other folders: quality report only — no writes, no moves." >&2
  exit 1
}

_next_is_model=0
for _arg in "$@"; do
  # --model <id> pins the model for THIS run only via the resolver's per-run
  # lever (SPRINTBIAS_MODEL_DEFAULT) — no config edit. See ./sprint.sh model.
  if [ "$_next_is_model" -eq 1 ]; then
    [ -n "$_arg" ] || { echo "✗ --model needs a model id" >&2; exit 1; }
    export SPRINTBIAS_MODEL_DEFAULT="$_arg"
    _next_is_model=0
    continue
  fi
  case "$_arg" in
    --force) FORCE=1 ;;
    --model) _next_is_model=1 ;;
    backlog|next|doing|blocked) FOLDER="$_arg" ;;
    review|done)
      echo "Error: Cannot gate $_arg/ — those are completed tasks." >&2
      echo "gate targets backlog, next, doing, or blocked." >&2
      exit 1
      ;;
    ''|*[!0-9]*) _usage ;;
    *) MAX_TASKS="$_arg" ;;
  esac
done
[ "$_next_is_model" -eq 1 ] && { echo "✗ --model needs a model id" >&2; exit 1; }
unset _arg _next_is_model

# ── Config ───────────────────────────────────────────────────────────
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"
# The READY-gate (next/ mode) is the shared workability gate — the same code
# `plan start` runs before promoting members. Library is gate-lib.sh so both
# surfaces call one implementation and never drift.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/gate-lib.sh"

DIR="docs/tasks/$FOLDER"
BLOCKED_DIR="docs/tasks/blocked"
REVIEW_DIR="docs/tasks/review"
LOG_DIR="docs/tmp"
AI_MODE="$(sprintbias_ai_mode)"

# ═════════════════════════════════════════════════════════════════════
# Quality-report mode (non-next folders): classify each task, report only.
# Preserves audit's COMPLETE/OUTDATED/UNDEFINED/KEEP verdicts without mutations.
# ═════════════════════════════════════════════════════════════════════
if [ "$FOLDER" != "next" ]; then
  timeout_sec=120
  MAX_TURNS=15
  MODEL="$(sprintbias_tier_model AUDIT)"
  # Fall back to GATE if AUDIT is unset — one model surface for gate.
  [ -z "$MODEL" ] && MODEL="$(sprintbias_tier_model GATE)"

  if [ "$AI_MODE" != "emit" ]; then
    command -v "$SPRINTBIAS_CLI" &>/dev/null || {
      echo "Error: AI CLI '$SPRINTBIAS_CLI' not found in PATH. Edit docs/sprintbias/config (CLI) or install the tool. Claude Code: https://docs.anthropic.com/en/docs/claude-code/overview" >&2
      exit 1
    }
  fi

  if [ ! -d "$DIR" ]; then
    echo "Error: Not found: $DIR" >&2
    exit 1
  fi

  IFS=$'\n' files=($(
    find "$DIR" -maxdepth 1 -type f -name '*.md' -exec basename {} \; \
      | awk -F- '/^[0-9]+-/ { print $0 }' \
      | sort -t- -k1,1n \
      | if [ "$MAX_TASKS" -lt 999 ] && [ "$MAX_TASKS" -gt 0 ]; then head -"$MAX_TASKS"; else cat; fi \
      | sed "s|^|$DIR/|"
  ))
  unset IFS

  total=${#files[@]}
  run_log=""

  if [ "$AI_MODE" = "emit" ]; then
    if [ "$total" -eq 0 ]; then
      echo "No tasks to gate in $FOLDER/."
      exit 0
    fi
    _file_list=$(printf '%s\n' "${files[@]}")
    sprintbias_run -p "You are vetting task-file quality in $FOLDER/ for the developer.

CLAUDE.md is auto-loaded with project context and conventions. Read it first.

Task files to vet, in order:
$_file_list

READ-ONLY: do not edit, move, or delete any task file. Report only.

For EACH task file in order:
1. Read the task file, then check the current codebase.
2. Decide EXACTLY ONE verdict:
   - COMPLETE  — the work described is already present in the codebase (not the done/ folder)
   - OUTDATED  — it references files/patterns/features that no longer exist
   - UNDEFINED — it is too vaguely defined to be actionable
   - KEEP      — still relevant, well-defined, and not yet completed
   Be conservative: if in doubt, KEEP.
3. Print one line per task: 'VERDICT | <taskname> | <one-line reason>'.

After all tasks, print a short summary count per verdict."
    exit 0
  fi

  echo "=== Task quality report ($FOLDER): $total tasks (${timeout_sec}s timeout, read-only) ==="

  _model_args=()
  [ -n "$MODEL" ] && _model_args=(--model "$MODEL")

  for i in "${!files[@]}"; do
    file="${files[$i]}"
    idx=$((i + 1))
    taskname=$(basename "$file")
    echo ""
    echo "[$idx/$total] Vetting: $taskname"

    _report_prompt="You are vetting a task file from $FOLDER/ for quality.

CLAUDE.md is auto-loaded with project context and conventions.
Read it first to understand the project's tech stack and structure.

Read the task file at: $file

Then check the current codebase to determine if this task has ALREADY been completed,
if the task references files/features that no longer exist or are unrecognizable,
or if the task is too vaguely defined to be actionable.

Your job is to output EXACTLY ONE of these verdicts on the first line, followed by
a brief one-line reason on the second line:

COMPLETE - The work described is already present in the codebase (verdict COMPLETE, not the done/ folder)
OUTDATED - The task references files, patterns, or features that no longer exist or are unrecognizable
UNDEFINED - The task is not defined well enough to work (missing problem statement, success criteria, or actionable details)
KEEP - The task is still relevant, well-defined, and not yet completed

Rules:
- Be conservative: if in doubt, say KEEP
- COMPLETE means the specific work described is clearly present in the codebase — not that the file is in docs/tasks/done/
- OUTDATED means the task cannot be worked because its context is gone
- UNDEFINED means someone would need to rewrite the task before working it
- Only output the verdict line and reason line, nothing else
- READ-ONLY: do not edit, move, or delete any files"

    verdict=$(run_with_timeout "$timeout_sec" sprintbias_run -p "$_report_prompt" \
      ${_model_args[@]+"${_model_args[@]}"} --max-turns "$MAX_TURNS" --skip-permissions 2>/dev/null) || true

    action=$(echo "$verdict" | grep -oE '^(COMPLETE|DONE|OUTDATED|UNDEFINED|KEEP)' | head -1 || true)
    if [ -z "$action" ]; then
      action=$(echo "$verdict" | grep -oE '\b(COMPLETE|DONE|OUTDATED|UNDEFINED|KEEP)\b' | head -1 || true)
    fi
    [ "$action" = "DONE" ] && action="COMPLETE"
    [ -z "$action" ] && action="TIMEOUT"

    reason=$(echo "$verdict" | tail -1)
    [ -z "$reason" ] && reason="No response (timed out after ${timeout_sec}s)"

    echo "  Verdict: $action"
    echo "  Reason:  $reason"
    run_log+="$action | $taskname | $reason"$'\n'
  done

  echo ""
  echo "=== Quality report complete (read-only — no files changed) ==="
  echo ""
  echo "--- Summary (this run) ---"
  echo "  COMPLETE:  $(echo "$run_log" | grep -cE '^(COMPLETE|DONE)' || true)"
  echo "  OUTDATED:  $(echo "$run_log" | grep -c '^OUTDATED' || true)"
  echo "  UNDEFINED: $(echo "$run_log" | grep -c '^UNDEFINED' || true)"
  echo "  KEEP:      $(echo "$run_log" | grep -c '^KEEP' || true)"
  echo "  Timed out: $(echo "$run_log" | grep -c '^TIMEOUT' || true)"
  echo ""
  echo "--- Per-task ---"
  printf '%s' "$run_log"
  exit 0
fi

# ═════════════════════════════════════════════════════════════════════
# READY-gate mode (next/): deep review, write ## Questions, move files.
# The review contract, sprint-context builder, verdict routing, and file
# moves are the shared workability gate — see gate.sh. This section is the
# gate-specific orchestration around it: which tasks to review, the run
# summary, and the chat queue for what came back blocked.
# ═════════════════════════════════════════════════════════════════════

NEXT_DIR="$DIR"

mkdir -p "$LOG_DIR"

for dir in "$NEXT_DIR" "$BLOCKED_DIR" "$REVIEW_DIR"; do
  if [ ! -d "$dir" ]; then
    echo "✗ Missing directory: $dir"
    exit 1
  fi
done

# Integrity first: READY/COMPLETE + open questions must not sit in next/.
# Demote those before the skip logic can treat a false READY as "already done".
sprintbias_sweep_ready_open_questions "$NEXT_DIR" "$BLOCKED_DIR"

# Skip tasks that already carry a review verdict so a re-run after a partial
# failure (API error mid-batch) retries only what's missing instead of
# re-reviewing — and re-paying for — the whole queue. --force re-reviews all.
TASK_FILES=()
SKIPPED_REVIEWED=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  # Only READY skips: a BLOCKED/COMPLETE-stamped task sitting in next/ means the
  # user re-queued it after addressing the questions — re-review it.
  # Open questions on a READY stamp were demoted above, so this skip is safe.
  if [ "$FORCE" -ne 1 ] && [ "$(sprintbias_review_verdict "$f")" = "READY" ] \
       && ! sprintbias_has_open_questions "$f"; then
    SKIPPED_REVIEWED=$((SKIPPED_REVIEWED + 1))
    continue
  fi
  TASK_FILES+=("$f")
done < <(ls -1 "$NEXT_DIR"/*.md 2>/dev/null | sed 's|.*/||' | sort -t- -k1,1n | sed "s|^|$NEXT_DIR/|")

if [ "$SKIPPED_REVIEWED" -gt 0 ]; then
  echo "▸ Skipping $SKIPPED_REVIEWED already-reviewed task(s) — use --force to re-review"
fi

if [ ${#TASK_FILES[@]} -eq 0 ]; then
  if [ "$SKIPPED_REVIEWED" -gt 0 ]; then
    echo "All tasks in $NEXT_DIR are already reviewed"
  else
    echo "No tasks in $NEXT_DIR"
  fi
  exit 0
fi

COUNT=${#TASK_FILES[@]}
if [ "$COUNT" -gt "$MAX_TASKS" ]; then
  COUNT=$MAX_TASKS
fi

echo "▸ Reviewing $COUNT task(s) from $NEXT_DIR"
echo ""

# Build the shared gate's invariant context once (profile pointer, next/
# backlog index, emit-mode move instruction, model/tool surface). READY tasks
# stay in next/, so that is the gate's stay-dir.
sprintbias_gate_init gate "$NEXT_DIR"

# ── Orchestration-capable fast path: parallel subagents in emit mode ──
# On claude-code / grok-build in emit mode, one subagent per task is strictly
# faster than N sequential prompts; reviews are independent. Other tiers and
# exec mode fall through to the sequential loop. Only when COUNT > 1.
if [ "$AI_MODE" = "emit" ] && sprintbias_orchestration_capable && [ "$COUNT" -gt 1 ]; then
  sprintbias_gate_parallel "${TASK_FILES[@]:0:$COUNT}"
  echo ""
  exit 0
fi

# ── Runner ──────────────────────────────────────────────────────────

# Echo the file's ## BLOCKED section (guaranteed to exist by the routing
# below) so the reason is also visible on screen. The FILE is the record;
# this is a convenience copy for whoever is watching.
_show_blocked() {
  awk '/^## BLOCKED[[:space:]]*$/{f=1; next} f && /^## /{exit} f' "$1" \
    | head -20 | sed 's/^/    /'
}

# One printable chat line: "    ./sprint.sh chat 12   Add auth middleware   [next]  needs: 8"
# id=$1 file=$2 (may be empty/missing) needs=$3 (space-separated, may be empty)
_chat_line() {
  local id="$1" file="$2" needs="$3" title="" stage="" tail=""
  if [ -n "$file" ] && [ -f "$file" ]; then
    title="$(task_title "$file")"
    stage="$(basename "$(dirname "$file")")"
  fi
  [ -n "$title" ] || title="(task $id)"
  [ ${#title} -gt 44 ] && title="${title:0:41}..."
  [ -n "$stage" ] && tail="  [$stage]"
  [ -n "$needs" ] && tail="$tail  needs: $(echo "$needs" | tr -s ' ' | sed 's/^ *//; s/ *$//')"
  printf '    ./sprint.sh chat %-4s %-44s%s\n' "$id" "$title" "$tail"
}

# Turn the tasks that need a decision/clarification this run into a
# dependency-ordered chat queue. An open decision is often on an UPSTREAM task,
# so a flat "these are blocked" list hides the real work. This orders it
# top-down: dependency-free items and unresolved upstream deps first; dependents
# that wait on them come after. Chat the top of the list and the rest often fall
# out READY on the next gate run.
# Args: the blocked task basenames (as in $BLOCKED_DIR).
_chat_queue() {
  [ "$#" -gt 0 ] || return 0
  local name id f deps
  local blocked_ids="" roots="" waiters="" all_deps=""

  # Partition: no open deps (roots) vs. dependent on others (waiters — on hold).
  for name in "$@"; do
    blocked_ids="$blocked_ids ${name%%-*}"
  done
  for name in "$@"; do
    id="${name%%-*}"
    f="$BLOCKED_DIR/$name"
    deps="$(sprintbias_unmet_deps "$f")"
    all_deps="$all_deps $deps"
    if [ -z "$deps" ]; then roots="$roots $id"; else waiters="$waiters $id"; fi
  done

  # Upstream deps that aren't in blocked/ themselves but still need a decision
  # or definition (not yet stamped READY). Surface them ABOVE the blocked tasks
  # that depend on them. A READY-but-unfinished dep only needs `work` to run it
  # (dependent/on hold), not chat, so it's left off this list.
  local upstream="" d dfile _res
  for d in $(printf '%s' "$all_deps" | tr ' ' '\n' | grep -E '^[0-9]+$' | sort -un); do
    case " $blocked_ids " in *" $d "*) continue ;; esac
    _res="$(sprintbias_find_task "$d")" || continue
    dfile="${_res%%$'\t'*}"
    [ "$(sprintbias_review_verdict "$dfile")" = "READY" ] && continue
    upstream="$upstream $d"
  done

  echo ""
  echo "▸ Chat queue — settle decisions/clarifications, top-down:"
  echo "  (the AI raises the questions, you make the calls)"
  echo ""
  local first_group=1
  if [ -n "$upstream$roots" ]; then
    echo "  Chat these first — no open prerequisite decisions ahead of them:"
    for d in $(printf '%s' "$upstream" | tr ' ' '\n' | grep -E '^[0-9]+$' | sort -un); do
      _res="$(sprintbias_find_task "$d")" && _chat_line "$d" "${_res%%$'\t'*}" ""
    done
    for id in $(printf '%s' "$roots" | tr ' ' '\n' | grep -E '^[0-9]+$' | sort -un); do
      f="$(find "$BLOCKED_DIR" -maxdepth 1 -name "${id}-*.md" 2>/dev/null | head -1)"
      _chat_line "$id" "$f" ""
    done
    first_group=0
  fi
  if [ -n "$waiters" ]; then
    [ "$first_group" -eq 0 ] && echo ""
    echo "  Then these — they depend on the tasks above (dependent / on hold for sequencing,"
    echo "  and still need their own decisions settled):"
    for id in $(printf '%s' "$waiters" | tr ' ' '\n' | grep -E '^[0-9]+$' | sort -un); do
      f="$(find "$BLOCKED_DIR" -maxdepth 1 -name "${id}-*.md" 2>/dev/null | head -1)"
      _chat_line "$id" "$f" "$(sprintbias_unmet_deps "$f")"
    done
  fi
  echo ""
  echo "  Once decisions are settled, re-enter next/ only through the gate:"
  echo "    bash docs/sprintbias/scripts/promote-to-sprint.sh $BLOCKED_DIR/<file>"
}

READY=0
BLOCKED=0
COMPLETE=0
BLOCKED_TASKS=()
ERROR_TASKS=()
TOTAL_START=$SECONDS

for i in $(seq 0 $((COUNT - 1))); do
  TASK_FILE="${TASK_FILES[$i]}"
  TASK_NAME=$(basename "$TASK_FILE")
  N=$((i + 1))
  TASK_START=$SECONDS

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "▸ Review $N/$COUNT: $TASK_NAME"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Run the shared gate on this task. It runs the review, writes the stamp,
  # and (in exec mode) moves the file by verdict. We only report the outcome.
  sprintbias_gate_review "$NEXT_DIR/$TASK_NAME"

  case "$SPRINTBIAS_GATE_VERDICT" in
    EMIT)
      # Emit mode: the prompt was printed for the surrounding agent, which runs
      # the review and moves the file itself. Nothing to count or route here.
      echo ""
      continue
      ;;
    BLOCKED)
      BLOCKED=$((BLOCKED + 1))
      BLOCKED_TASKS+=("$TASK_NAME")
      echo ""
      echo "⊘ Blocked (needs decision or clarification) → $BLOCKED_DIR/$TASK_NAME"
      echo "  Why (the file's ## BLOCKED section):"
      _show_blocked "$BLOCKED_DIR/$TASK_NAME"
      echo "  Next: chat it through, or answer the questions inline, then re-enter via the gate:"
      echo "    ./sprint.sh chat ${TASK_NAME%%-*}"
      echo "    bash docs/sprintbias/scripts/promote-to-sprint.sh $BLOCKED_DIR/$TASK_NAME"
      ;;
    COMPLETE)
      COMPLETE=$((COMPLETE + 1))
      echo ""
      echo "✓ COMPLETE (work already in codebase) → $REVIEW_DIR/$TASK_NAME"
      ;;
    READY)
      READY=$((READY + 1))
      echo ""
      echo "✓ Ready — reviewed in $NEXT_DIR/$TASK_NAME"
      ;;
    NOSTAMP)
      ERROR_TASKS+=("$TASK_NAME → no verdict stamp, log: $SPRINTBIAS_GATE_LOG")
      echo ""
      echo "✗ No verdict found in $TASK_NAME — leaving in $NEXT_DIR"
      echo "  Log: $SPRINTBIAS_GATE_LOG"
      ;;
    FAILED)
      ERROR_TASKS+=("$TASK_NAME → ${SPRINTBIAS_GATE_ERROR:-review failed}, log: $SPRINTBIAS_GATE_LOG")
      echo ""
      echo "✗ Review failed for $TASK_NAME — left in $NEXT_DIR"
      [ -n "$SPRINTBIAS_GATE_ERROR" ] && echo "  Cause: $SPRINTBIAS_GATE_ERROR"
      echo "  Log: $SPRINTBIAS_GATE_LOG"
      ;;
  esac

  TASK_ELAPSED=$((SECONDS - TASK_START))
  echo "⏱ Elapsed: $((TASK_ELAPSED / 60))m $((TASK_ELAPSED % 60))s"
  echo ""
done

TOTAL_ELAPSED=$((SECONDS - TOTAL_START))
ERRS=${#ERROR_TASKS[@]}
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "▸ Done: $READY ready, $COMPLETE complete, $BLOCKED blocked, $ERRS errors — total $((TOTAL_ELAPSED / 60))m $((TOTAL_ELAPSED % 60))s"

if [ "$BLOCKED" -gt 0 ]; then
  echo ""
  echo "⊘ Blocked (need decision or clarification) — each file's ## BLOCKED section says why:"
  for _t in ${BLOCKED_TASKS[@]+"${BLOCKED_TASKS[@]}"}; do
    echo "    $BLOCKED_DIR/$_t"
  done
  _chat_queue ${BLOCKED_TASKS[@]+"${BLOCKED_TASKS[@]}"}
fi

if [ "$ERRS" -gt 0 ]; then
  echo ""
  echo "✗ Errors — these tasks were NOT reviewed and remain in $NEXT_DIR:"
  for _t in ${ERROR_TASKS[@]+"${ERROR_TASKS[@]}"}; do
    echo "    $_t"
  done
  echo "  Retry with: ./sprint.sh gate   (already-reviewed tasks are skipped)"
fi
