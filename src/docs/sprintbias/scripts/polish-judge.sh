#!/usr/bin/env bash
# polish-judge.sh — THE excellence deep-judge for ONE finished piece.
#
# The single home for excellence judgment. `polish <id>` (judge mode) and
# `plan polish` (per finished member) both route here, so the idempotency guard,
# the change-scoping, the ## Excellence append, and enhancement filing live in
# exactly one place. Judges finished work against a higher bar than "it runs":
# never edits product code, never reopens the task — enhancements become filed
# backlog/ tasks. Protocol: docs/sprintbias/ai/audit-excellence.md.
#
# Usage:
#   polish-judge.sh [--force] [--model M] --task <task-file.md> [extra-file...]
#   polish-judge.sh [--force] [--model M] <file1> <file2> ...   # no task file
#
# Callers pass already-resolved paths — this script does NO id resolution
# (polish.sh owns the CLI argument-shape classification). --force re-judges a
# piece that already carries a ## Excellence section (default: skip it).

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

FORCE=0
TASK_FILE=""
EXPLICIT_FILES=()

while [ $# -gt 0 ]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --task)
      [ $# -ge 2 ] && [ -n "$2" ] || { echo "✗ --task needs a file" >&2; exit 1; }
      TASK_FILE="$2"; shift 2 ;;
    --model)
      [ $# -ge 2 ] && [ -n "$2" ] || { echo "✗ --model needs a model id" >&2; exit 1; }
      export SPRINTBIAS_MODEL_DEFAULT="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: polish-judge.sh [--force] [--model M] --task <task.md> [file...]" >&2
      exit 0 ;;
    -*) echo "✗ Unknown flag: $1" >&2; exit 1 ;;
    *)  EXPLICIT_FILES+=("$1"); shift ;;
  esac
done

if [ -z "$TASK_FILE" ] && [ ${#EXPLICIT_FILES[@]} -eq 0 ]; then
  echo "Usage:" >&2
  echo "  polish-judge.sh --task <task-file.md> [file...]" >&2
  echo "  polish-judge.sh <file1> <file2> ..." >&2
  exit 1
fi
if [ -n "$TASK_FILE" ] && [ ! -f "$TASK_FILE" ]; then
  echo "✗ Task file not found: $TASK_FILE" >&2
  exit 1
fi

MODEL="$(sprintbias_tier_model EXCELLENCE)"
TOOLS="Read,Grep,Glob,Bash,Edit,Agent"
PERMISSIONS="auto"
# A deep judge of many files can genuinely need more than the default 30 turns.
# Tunable per-run so a max-turns abort has a real next step (see the error branch).
MAX_TURNS="${SPRINTBIAS_AUDIT_MAX_TURNS:-30}"
LOG_DIR="docs/tmp"
BACKLOG_DIR="docs/tasks/backlog"
PROTOCOL="docs/sprintbias/ai/audit-excellence.md"
AI_MODE="$(sprintbias_ai_mode)"

# ── Idempotency guard ────────────────────────────────────────────────
# A finished piece is judged once. If it already carries a ## Excellence section,
# skip it (exit 0, cleanly) unless --force — a re-judge otherwise stacks a second
# section and re-files the same enhancements. The predicate lives in lib.sh so
# plan-polish.sh pre-filters members with the identical test.
if [ -n "$TASK_FILE" ] && [ "$FORCE" -ne 1 ] && sprintbias_excellence_has_section "$TASK_FILE"; then
  echo "⊘ Already judged — $(basename "$TASK_FILE") carries a ## Excellence section."
  echo "  Re-judge anyway:  ./sprint.sh polish --force $TASK_FILE"
  exit 0
fi

if [ ! -f "$PROTOCOL" ]; then
  echo "✗ Protocol file missing: $PROTOCOL" >&2
  exit 1
fi
mkdir -p "$LOG_DIR"

sprintbias_change_manifest "$TASK_FILE" ${EXPLICIT_FILES[@]+"${EXPLICIT_FILES[@]}"}
CHANGED_FILES="$SPRINTBIAS_CHANGED_FILES"
CONTEXT_SOURCE="$SPRINTBIAS_CONTEXT_SOURCE"

# Honest bail when no changed-file manifest can be built — never judge an
# unscoped tree; show the two ways to give it a file list. Exit 0 (nothing to do).
if [ -z "$CHANGED_FILES" ]; then
  echo "✗ Can't scope this task's changes — nothing to audit."
  echo "  Context source: $CONTEXT_SOURCE"
  [ -n "$TASK_FILE" ] && echo "  Task: $TASK_FILE"
  echo ""
  echo "  Give the audit a file list one of two ways:"
  echo "    • Add a '### Files changed' block under '## Completed' in the task"
  echo "      (one repo-relative path per line), then re-run."
  echo "    • Pass the files directly:"
  echo "        ./sprint.sh polish ${TASK_FILE:-<task>} <file>..."
  exit 0
fi

FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l | tr -d ' ')
TASK_NAME=""
[ -n "$TASK_FILE" ] && TASK_NAME=$(basename "$TASK_FILE")

echo "▸ Excellence audit: $FILE_COUNT file(s)${TASK_NAME:+ for: $TASK_NAME}"
echo "  Context source: $CONTEXT_SOURCE"
echo "  Files:"
echo "$CHANGED_FILES" | sed 's/^/    /'
echo ""

if [ -n "$TASK_FILE" ]; then
  TASK_BLOCK="TASK FILE: $TASK_FILE

ORIGINAL TASK:
---
$(<"$TASK_FILE")
---"
else
  TASK_BLOCK="No task file provided. Audit the listed files directly; infer the
intended goal from the code and recent git history."
fi

PROFILE_LINE="$(sprintbias_profile_line)"

APPEND_STEP=""
if [ "$AI_MODE" = "emit" ] && [ -n "$TASK_FILE" ]; then
  APPEND_STEP="
6. Append a '## Excellence' section to $TASK_FILE: date, verdict, and your
   Summary. Do not modify any other part of the task file."
fi

PROMPT="Excellence audit. CLAUDE.md is auto-loaded.${PROFILE_LINE}

Follow this protocol exactly. The two hard rules:
- You NEVER edit code — enhancements become backlog tasks, not edits.
- The work is presumed correct — you audit altitude, not syntax.

PROTOCOL ($PROTOCOL):
---
$(<"$PROTOCOL")
---

$TASK_BLOCK

CHANGED FILES:
$CHANGED_FILES

1. Read the task, the changed files, and their blast radius (grep for
   imports/references to the changed files).
2. Trace the end-to-end path as the person who will actually use this work.
3. Judge: effectiveness, efficiency, design fit, operability, robustness.
4. For each ENHANCEMENT finding, run: ./sprint.sh newtask \"<description>\"
   then append Why and Scope to the created task file in docs/tasks/backlog/.
5. Output the report per the protocol. Your VERY LAST line must be the verdict
   and nothing after it — the literal word VERDICT, a colon, a space, then ONE
   uppercase token (EXCELLENT, FILED, or BLOCKER), no bold. A short reason may
   follow the token:
   VERDICT: EXCELLENT | VERDICT: FILED — <n> enhancement task(s) | VERDICT: BLOCKER — <reason>$APPEND_STEP"

_model_args=()
[ -n "$MODEL" ] && _model_args=(--model "$MODEL")
# Budget only on a cap-capable tier (today Claude Code) — see lib.sh.
_budget_args=()
if sprintbias_budget_capable && [ -n "${SPRINTBIAS_BUDGET_AUDIT:-}" ]; then
  _budget_args=(--budget "$SPRINTBIAS_BUDGET_AUDIT")
fi

if [ "$AI_MODE" = "emit" ]; then
  sprintbias_run -p "$PROMPT"
  exit 0
fi

LOG_FILE="$(sprintbias_log_path polish-judge "${TASK_NAME:-adhoc}")"

# Count enhancement tasks the audit actually files by diffing backlog/ across the
# run — deterministic, and it works even when the CLI errors out before emitting
# any result text (the old grep of $OUTPUT reported 0 in exactly that case).
_backlog_count() { ls -1 "$BACKLOG_DIR"/*.md 2>/dev/null | wc -l | tr -d ' '; }
_filed_before=$(_backlog_count)

sprintbias_run -p "$PROMPT" \
  ${_model_args[@]+"${_model_args[@]}"} \
  ${_budget_args[@]+"${_budget_args[@]}"} \
  --tools "$TOOLS" \
  --permissions "$PERMISSIONS" \
  --max-turns "$MAX_TURNS" \
  --output-format json >"$LOG_FILE" 2>/dev/null || true

FILED_COUNT=$(( $(_backlog_count) - _filed_before ))
[ "$FILED_COUNT" -lt 0 ] && FILED_COUNT=0

# ── Did the run finish at all? ───────────────────────────────────────
# A max-turns abort or a CLI that never started produces no verdict — but for a
# very different reason than a model that answered in an odd format. The
# interpreter reads the run once and hands back the outcome and the result
# text; we branch on the outcome rather than blaming the verdict parse. On abort
# we DON'T stamp a normal verdict block: we append a clearly-labelled 'aborted'
# note so the task file never claims a judgment it never got.
sprintbias_interpret_run "$LOG_FILE"
if [ "$SPRINTBIAS_RUN_OUTCOME" != "finished" ]; then
  RUN_HINT="$(sprintbias_run_hint "$SPRINTBIAS_RUN_OUTCOME")"
  if [ -n "$TASK_FILE" ]; then
    {
      echo ""
      echo "## Excellence (aborted — no verdict)"
      echo ""
      echo "- **Date**: $(date +%Y-%m-%d)"
      echo "- **Outcome**: the audit $RUN_HINT"
      echo "- **Tasks filed before stopping**: $FILED_COUNT"
      echo "- **Files reviewed**: $FILE_COUNT"
      echo "- **Log**: $LOG_FILE"
    } >> "$TASK_FILE" \
      || echo "⚠ Could not append aborted note to $TASK_FILE (see $LOG_FILE)"
  fi
  echo ""
  echo "⚠ Excellence audit did not finish — $RUN_HINT"
  if [ "$FILED_COUNT" -gt 0 ]; then
    echo "  It filed $FILED_COUNT enhancement task(s) to $BACKLOG_DIR/ before stopping — those are real output."
  fi
  echo "  No verdict was reached, so ${TASK_NAME:-the work} was NOT judged."
  case "$SPRINTBIAS_RUN_OUTCOME" in
    max_turns)
      echo "  It ran out of room in $MAX_TURNS turns. Either:"
      echo "    • give it more:    SPRINTBIAS_AUDIT_MAX_TURNS=60 ./sprint.sh polish --force ${TASK_FILE:-<files>}"
      echo "    • or narrow scope: ./sprint.sh polish ${TASK_FILE:-<task>} <fewer files>"
      ;;
    no_start)
      echo "  Confirm the '$SPRINTBIAS_CLI' CLI is installed and authenticated, then re-run."
      ;;
    *)
      echo "  Inspect $LOG_FILE, then re-run:  ./sprint.sh polish --force ${TASK_FILE:-<files>}"
      ;;
  esac
  exit 1
fi

# ── Run finished normally — parse its verdict ────────────────────────
VERDICT=$(printf '%s' "$SPRINTBIAS_RUN_VERDICT_TEXT" | sprintbias_parse_verdict 'EXCELLENT|FILED|BLOCKER')
[ -z "$VERDICT" ] && VERDICT="UNCLEAR"

SUMMARY=$(sprintbias_extract_summary "$LOG_FILE")

if [ -n "$TASK_FILE" ]; then
  {
    echo ""
    echo "## Excellence"
    echo ""
    echo "- **Date**: $(date +%Y-%m-%d)"
    echo "- **Verdict**: $VERDICT"
    echo "- **Tasks filed**: $FILED_COUNT"
    echo "- **Files reviewed**: $FILE_COUNT"
    echo "- **Context source**: $CONTEXT_SOURCE"
    echo ""
    echo "$SUMMARY"
  } >> "$TASK_FILE" \
    || echo "⚠ Could not append ## Excellence section to $TASK_FILE (see $LOG_FILE)"
fi

echo ""
case "$VERDICT" in
  EXCELLENT)
    echo "✓ Excellence audit: meets the bar — nothing filed"
    exit 0
    ;;
  FILED)
    echo "✓ Excellence audit: $FILED_COUNT enhancement task(s) filed to $BACKLOG_DIR/"
    exit 0
    ;;
  BLOCKER)
    echo "✗ Excellence audit: BLOCKER — the work does not meet its own task's goal"
    echo "  See ${TASK_FILE:-$LOG_FILE} for details"
    exit 1
    ;;
  *)
    # The run completed but its final line carried no VERDICT token — a genuine
    # formatting slip, not a crash. Show the tail of what it actually wrote so
    # the human can read the judgment instead of opening a JSON blob.
    echo "? Excellence audit finished but its final line held no VERDICT token."
    echo "  It ran to completion — this is a formatting slip, not a crash."
    if [ -n "$FILED_COUNT" ] && [ "$FILED_COUNT" -gt 0 ]; then
      echo "  It filed $FILED_COUNT enhancement task(s) to $BACKLOG_DIR/."
    fi
    echo "  Last lines of the report:"
    printf '%s\n' "$SUMMARY" | tail -8 | sed 's/^/    /'
    echo "  Full log: $LOG_FILE"
    exit 1
    ;;
esac
