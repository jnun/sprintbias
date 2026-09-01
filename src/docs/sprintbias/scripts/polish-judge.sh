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
NEXT_DIR="docs/tasks/next"
PROTOCOL="docs/sprintbias/ai/audit-excellence.md"
AI_MODE="$(sprintbias_ai_mode)"

# Resolve the change manifest first — the idempotency guard keys on the CURRENT
# contents of the audited files, so it must know the file list (and its content
# hash) before it can decide whether a prior verdict is still fresh.
sprintbias_change_manifest "$TASK_FILE" ${EXPLICIT_FILES[@]+"${EXPLICIT_FILES[@]}"}
CHANGED_FILES="$SPRINTBIAS_CHANGED_FILES"
CONTEXT_SOURCE="$SPRINTBIAS_CONTEXT_SOURCE"
STATE_KEY="$(sprintbias_manifest_state_hash "$CHANGED_FILES")"

# ── Idempotency guard (code-state-aware) ─────────────────────────────
# A finished piece is judged once — for the code as it stood when judged. If it
# already carries a ## Excellence section AND the audited files still hash to the
# stamped Code state, skip it (exit 0, cleanly) unless --force. When the files
# moved since the audit, the stamped verdict is stale, so re-judge instead of
# presenting a stale verdict as current — replacing the block, never stacking.
# A section with no stamp (written before code-state stamping) or an unresolvable
# manifest degrades to the old "judged once" skip rather than re-judging blindly.
# The staleness test lives in lib.sh (sprintbias_excellence_is_stale) so
# plan-polish.sh's pre-filter runs the SAME test — the two guards can't diverge.
if [ -n "$TASK_FILE" ] && [ "$FORCE" -ne 1 ] && sprintbias_excellence_has_section "$TASK_FILE"; then
  if sprintbias_excellence_is_stale "$TASK_FILE" "$STATE_KEY"; then
    echo "↻ Re-judging $(basename "$TASK_FILE") — audited files changed since the last verdict."
    echo "  The stale ## Excellence block is replaced in place."
    echo ""
  else
    echo "⊘ Already judged — $(basename "$TASK_FILE") carries a ## Excellence section."
    echo "  Re-judge anyway:  ./sprint.sh polish --force $TASK_FILE"
    exit 0
  fi
fi

if [ ! -f "$PROTOCOL" ]; then
  echo "✗ Protocol file missing: $PROTOCOL" >&2
  exit 1
fi
mkdir -p "$LOG_DIR" "$BACKLOG_DIR" "$NEXT_DIR"

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

# ── Correctness marker ───────────────────────────────────────────────
# The excellence judge audits altitude, not syntax, and its protocol presumes
# correctness. That presumption is only sound when a code audit (polish --code)
# actually ran AND passed — the `## Audit` marker on the task file. Derive the
# state here (deterministic, shared with plan polish via lib.sh) so the judge is
# never silently told the work is correct when nothing established it, and stamp
# the state on the ## Excellence section for the record.
CORRECTNESS="unverified"
[ -n "$TASK_FILE" ] && CORRECTNESS="$(sprintbias_correctness_state "$TASK_FILE")"

_audit_fix="./sprint.sh polish --code ${TASK_FILE:-<id>}"
case "$CORRECTNESS" in
  audited)
    echo "  Correctness: audited — a passed 'polish --code' is on record; correctness is established." ;;
  unverified)
    echo "  ⚠ Correctness: unverified — no code audit has run on this work."
    echo "    Excellence judges altitude, not correctness. Establish correctness first:"
    echo "      $_audit_fix" ;;
  failed)
    echo "  ⚠ Correctness: FAILED — a 'polish --code' ran and did NOT clear this work."
    echo "    This is worse than unverified: a known-bad audit is on record. Re-run it:"
    echo "      $_audit_fix" ;;
esac
echo ""

# The prompt rule the judge sees for correctness — conditional on the marker.
# When audited, correctness is established and the judge audits altitude only.
# Otherwise it is NOT established: a stumbled-on defect is a DEFECT finding
# recommending polish --code, never waved by and never fixed here.
if [ "$CORRECTNESS" = "audited" ]; then
  CORRECTNESS_RULE="- Correctness IS established — a code audit (polish --code) passed on this work
  (a PASS/FIXED ## Audit marker is on file). Audit altitude, not syntax; do not
  re-litigate bugs."
else
  CORRECTNESS_RULE="- Correctness is NOT established (state: $CORRECTNESS — no passing ## Audit
  marker). Do NOT presume the work correct. If you stumble on a genuine defect,
  record it as a DEFECT finding recommending './sprint.sh polish --code' — do not
  wave it by, and never fix it yourself."
fi

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
  # Render the SAME field set the headless appender writes (sprintbias_excellence_block),
  # with placeholders for the fields you supply — so both paths carry one spec.
  APPEND_STEP="
6. Append a '## Excellence' section to $TASK_FILE — EXACTLY these fields, in this
   order. Fill in <VERDICT>, the <N> tasks you filed, the routing split, and your
   Summary; the other fields are already resolved for you, copy them verbatim
   (Code state is the audited files' content hash — copy it exactly, do not
   recompute it). Routing is the warm-route split of what you filed — e.g.
   '1 → next/, 2 → backlog/' (or '—' if you filed nothing):
$(sprintbias_excellence_block "$(date +%Y-%m-%d)" "<VERDICT>" "$CORRECTNESS" "<N>" "<x → next/, y → backlog/>" "$FILE_COUNT" "$CONTEXT_SOURCE" "$STATE_KEY" "<your 2–5 sentence Summary>")
   If a '## Excellence' section already exists (this is a re-judge), REPLACE it in
   place — remove the old block through its next '## ' heading and write this one;
   never stack a second '## Excellence'. Do not modify any other part of the file."
fi

PROMPT="Excellence audit. CLAUDE.md is auto-loaded.${PROFILE_LINE}

Follow this protocol exactly. The hard rules:
- You NEVER edit code — enhancements become backlog tasks, not edits.
$CORRECTNESS_RULE

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
4. For each ENHANCEMENT finding (the vital few, not the trivial many), run:
   ./sprint.sh newtask \"<description>\" then append Why and Scope to the created
   file in docs/tasks/backlog/. Default every filed task to backlog/. A finding
   you rate BOTH high-confidence AND high-value — the \"a senior engineer, told
   about this, would act now\" bar — you may WARM-ROUTE to next/ by promoting it
   through the shared gate (never a raw git mv):
     bash docs/sprintbias/scripts/promote-to-sprint.sh docs/tasks/backlog/<id>-<slug>.md
   Warm-route AT MOST 1–2 findings per audit, and only when \"act now\" is
   genuinely true — not \"seems nice\" and not large/speculative. When in doubt,
   leave it in backlog/. See the protocol's \"Severity and Routing\" for the bar.
5. Output the report per the protocol. Your VERY LAST line must be the verdict
   and nothing after it — the literal word VERDICT, a colon, a space, then ONE
   uppercase token (EXCELLENT, FILED, or BLOCKER), no bold. On FILED, the token
   is followed by the routing split. A short reason may follow the token:
   VERDICT: EXCELLENT | VERDICT: FILED — <n> (<x> → next/, <y> → backlog/) | VERDICT: BLOCKER — <reason>$APPEND_STEP"

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

# Count enhancement tasks the audit actually files by diffing the queues across
# the run — deterministic, and it works even when the CLI errors out before
# emitting any result text (the old grep of $OUTPUT reported 0 in exactly that
# case). Warm routing files into backlog/ then promotes into next/, so a filed
# task can land in EITHER queue; observing only backlog/ would net a warm-routed
# task to zero and undercount exactly what this lane promotes. Diff both, so the
# total and the `n (x → next/, y → backlog/)` split are both recoverable.
# find (not a glob) so an empty next/ — the common case — yields 0 rather than a
# non-matching glob that trips `set -o pipefail`; the dirs are mkdir -p'd above.
_dir_count() { find "$1" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' '; }
_backlog_before=$(_dir_count "$BACKLOG_DIR")
_next_before=$(_dir_count "$NEXT_DIR")

sprintbias_run -p "$PROMPT" \
  ${_model_args[@]+"${_model_args[@]}"} \
  ${_budget_args[@]+"${_budget_args[@]}"} \
  --tools "$TOOLS" \
  --permissions "$PERMISSIONS" \
  --max-turns "$MAX_TURNS" \
  --output-format json >"$LOG_FILE" 2>/dev/null || true

BACKLOG_FILED=$(( $(_dir_count "$BACKLOG_DIR") - _backlog_before ))
NEXT_FILED=$(( $(_dir_count "$NEXT_DIR") - _next_before ))
[ "$BACKLOG_FILED" -lt 0 ] && BACKLOG_FILED=0
[ "$NEXT_FILED" -lt 0 ] && NEXT_FILED=0
FILED_COUNT=$(( BACKLOG_FILED + NEXT_FILED ))
# The routing split for the ## Excellence 'Routing' field and the verdict line.
if [ "$FILED_COUNT" -gt 0 ]; then
  ROUTING="$NEXT_FILED → next/, $BACKLOG_FILED → backlog/"
else
  ROUTING="—"
fi

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
      echo "- **Correctness**: $CORRECTNESS"
      echo "- **Tasks filed before stopping**: $FILED_COUNT"
      echo "- **Routing**: $ROUTING"
      echo "- **Files reviewed**: $FILE_COUNT"
      echo "- **Code state**: $STATE_KEY"
      echo "- **Log**: $LOG_FILE"
    } >> "$TASK_FILE" \
      || echo "⚠ Could not append aborted note to $TASK_FILE (see $LOG_FILE)"
  fi
  echo ""
  echo "⚠ Excellence audit did not finish — $RUN_HINT"
  if [ "$FILED_COUNT" -gt 0 ]; then
    echo "  It filed $FILED_COUNT enhancement task(s) ($ROUTING) before stopping — those are real output."
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
  # Replace, not stack: a re-judge (forced, or auto-triggered by a code move)
  # rewrites the single ## Excellence block instead of appending a second one.
  # Scoped to that exact block — Success criteria, ## Completed, ## Audit, and any
  # '## Excellence (aborted …)' note are untouched. Only on this success path; an
  # aborted re-judge below never strips a valid prior verdict.
  sprintbias_excellence_has_section "$TASK_FILE" && sprintbias_excellence_strip_section "$TASK_FILE"
  # ONE field spec, shared with the emit path above — see lib.sh. STATE_KEY stamps
  # the code state this verdict judged, so the guard can tell fresh from stale.
  sprintbias_excellence_block \
    "$(date +%Y-%m-%d)" "$VERDICT" "$CORRECTNESS" "$FILED_COUNT" "$ROUTING" "$FILE_COUNT" "$CONTEXT_SOURCE" "$STATE_KEY" "$SUMMARY" \
    >> "$TASK_FILE" \
    || echo "⚠ Could not append ## Excellence section to $TASK_FILE (see $LOG_FILE)"
fi

echo ""
case "$VERDICT" in
  EXCELLENT)
    echo "✓ Excellence audit: meets the bar — nothing filed"
    exit 0
    ;;
  FILED)
    echo "✓ Excellence audit: FILED — $FILED_COUNT enhancement task(s) ($ROUTING)"
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
      echo "  It filed $FILED_COUNT enhancement task(s) ($ROUTING)."
    fi
    echo "  Last lines of the report:"
    printf '%s\n' "$SUMMARY" | tail -8 | sed 's/^/    /'
    echo "  Full log: $LOG_FILE"
    exit 1
    ;;
esac
