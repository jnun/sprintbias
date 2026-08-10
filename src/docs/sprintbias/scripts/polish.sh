#!/usr/bin/env bash
# polish.sh — THE post-work quality pass. Three modes, one command:
#
#   polish [limit] [--rounds N] [--max] [--force]
#       Sweep review/: judge each finished task; reopen ones worth another
#       pass into next/ via the shared workability gate (never raw promote).
#       Protocol: docs/sprintbias/ai/refine.md
#
#   polish <id|file|task.md> [file...]
#       Deep-judge ONE finished piece; file enhancement tasks to backlog/.
#       Never edits product code. Protocol: docs/sprintbias/ai/audit-excellence.md
#
#   polish --code <id|file|task.md> [file...] [-- max-passes]
#       Code-diff audit: fixer/verifier loop that may fix issues inline.
#
# Argument shape selects the mode: a bare number that names an existing task
# targets THAT task (deep judge, or code audit with --code); a number that
# resolves to no task is a sweep limit. A bare path is the deep judge; the
# same path with --code is the code audit. See: ./sprint.sh help polish

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/gate-lib.sh"

# ── Mode selection ───────────────────────────────────────────────────
# Modes: sweep | judge | code
CODE_FLAG=0
MAX_TASKS=999
MAX_ROUNDS=1
_NO_LIMITS=0
FORCE=0
# Parallel fan-out — sweep only. Same surface as work: --parallel (2 jobs),
# --fast (4), --jobs N. --jobs N caps the headless judge semaphore; in emit
# mode --parallel/--fast only flip the wording to concurrent fan-out (the cap
# is a headless-only knob and is never threaded into the emit prompt).
PARALLEL=0
MAX_JOBS=2
MAX_PASSES="${SPRINTBIAS_AUDIT_MAX_PASSES:-3}"
POSITIONAL=()

_usage() {
  cat >&2 <<'EOF'
Usage:
  ./sprint.sh polish [limit] [--rounds N] [--parallel|--fast|--jobs N] [--max] [--force]
      Sweep review/: reopen tasks worth another execution pass.
      --parallel/--fast/--jobs N fan the independent judges out concurrently.

  ./sprint.sh polish <id|task.md|file> [file...]
      Deep-judge one finished piece (an id targets that task); file
      enhancements to backlog/.

  ./sprint.sh polish --code <id|task.md|file> [file...] [-- max-passes]
      Code-diff audit (fixer/verifier); may fix issues inline.
EOF
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --code)  CODE_FLAG=1; shift ;;
    --rounds)
      [ $# -lt 2 ] && { echo "✗ --rounds needs a number" >&2; exit 1; }
      MAX_ROUNDS="$2"; shift 2
      ;;
    --max)   _NO_LIMITS=1; shift ;;
    --force) FORCE=1; shift ;;
    --parallel) PARALLEL=1; shift ;;
    --fast)     PARALLEL=1; MAX_JOBS=4; shift ;;
    --jobs)
      [ $# -lt 2 ] && { echo "✗ --jobs needs a number" >&2; exit 1; }
      PARALLEL=1; MAX_JOBS="$2"; shift 2
      ;;
    --model)
      # Pin the model for THIS run only via the resolver's per-run lever
      # (SPRINTBIAS_MODEL_DEFAULT) — no config edit. See ./sprint.sh model.
      [ $# -ge 2 ] && [ -n "$2" ] || { echo "✗ --model needs a model id" >&2; exit 1; }
      export SPRINTBIAS_MODEL_DEFAULT="$2"; shift 2 ;;
    --)
      shift
      [ $# -gt 0 ] && MAX_PASSES="$1"
      break
      ;;
    -h|--help) _usage ;;
    -*)
      echo "✗ Unknown flag: $1" >&2
      _usage
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

if ! [[ "$MAX_ROUNDS" =~ ^[0-9]+$ ]]; then
  echo "✗ --rounds needs a number (got: $MAX_ROUNDS)" >&2
  exit 1
fi
if ! [[ "$MAX_PASSES" =~ ^[0-9]+$ ]]; then
  echo "✗ max-passes needs a number (got: $MAX_PASSES)" >&2
  exit 1
fi
if ! [[ "$MAX_JOBS" =~ ^[0-9]+$ ]] || [ "$MAX_JOBS" -lt 1 ]; then
  echo "✗ --jobs needs a positive number (got: $MAX_JOBS)" >&2
  exit 1
fi

if [ "$_NO_LIMITS" -eq 1 ]; then
  SPRINTBIAS_BUDGET_AUDIT=""
fi
unset _NO_LIMITS

# Classify positionals into TASK_FILE / EXPLICIT_FILES / numeric limits.
TASK_FILE=""
EXPLICIT_FILES=()
_has_path=0
_numeric_limit=""
_resolved=""
RESOLVED_ID=""   # the id typed for the target task, for copy-pasteable guidance

for p in "${POSITIONAL[@]+"${POSITIONAL[@]}"}"; do
  if [ -f "$p" ]; then
    _has_path=1
    if [[ "$p" == *.md ]] && [ -z "$TASK_FILE" ] && [ ${#EXPLICIT_FILES[@]} -eq 0 ]; then
      TASK_FILE="$p"
    else
      EXPLICIT_FILES+=("$p")
    fi
  elif [[ "$p" =~ ^[0-9]+$ ]]; then
    # Bare number, resolved ID-first (the user's chosen reading): a number that
    # names an existing task file targets THAT task — uniform with work/chat —
    # and only a number that resolves to no task falls back to the numeric
    # sweep-limit / max-passes meaning. Exception: once --code already has a
    # target, a trailing number is the max-passes count, never a second target.
    if [ "$CODE_FLAG" -eq 1 ] && { [ -n "$TASK_FILE" ] || [ ${#EXPLICIT_FILES[@]} -gt 0 ]; }; then
      MAX_PASSES="$p"
    elif _resolved=$(sprintbias_task_path "$p") && [ -n "$_resolved" ]; then
      _has_path=1
      if [[ "$_resolved" == *.md ]] && [ -z "$TASK_FILE" ] && [ ${#EXPLICIT_FILES[@]} -eq 0 ]; then
        TASK_FILE="$_resolved"
        [ -z "$RESOLVED_ID" ] && RESOLVED_ID="$p"
      else
        EXPLICIT_FILES+=("$_resolved")
      fi
      echo "▸ Task $p → $_resolved" >&2
    else
      _numeric_limit="$p"
    fi
  else
    # Non-existent path-like arg — fail early with a clear message.
    if [[ "$p" == */* ]] || [[ "$p" == *.* ]]; then
      echo "✗ File not found: $p" >&2
      exit 1
    fi
    echo "✗ Unexpected argument: $p" >&2
    _usage
  fi
done

if [ "$CODE_FLAG" -eq 1 ]; then
  MODE="code"
elif [ "$_has_path" -eq 1 ]; then
  MODE="judge"
else
  MODE="sweep"
  [ -n "$_numeric_limit" ] && MAX_TASKS="$_numeric_limit"
fi

# Parallel fan-out is a sweep-only affordance: only the review/ sweep writes
# nothing but task files, so only it is safe to overlap. Deep-judge and --code
# operate within one task file (and --code may edit product code), so they stay
# single-target — the flags are ignored there with a note rather than silently.
if [ "$PARALLEL" -eq 1 ] && [ "$MODE" != "sweep" ]; then
  echo "▸ --parallel/--fast/--jobs apply to the review/ sweep only — ignored for $MODE mode" >&2
  PARALLEL=0
fi

# Honest bail when no changed-file manifest can be built for a finished task.
# By design polish never audits an unscoped tree — when it cannot tell which
# files a task touched, it says so and shows the two ways to give it a list,
# rather than silently judging every uncommitted change. Reads TASK_FILE /
# RESOLVED_ID / CONTEXT_SOURCE from the caller; $1 is the flag to echo in the
# example ("--code " for code mode, "" for judge). Exits 0 (nothing to do).
_no_manifest_bail() {
  local flag="$1"
  local target="${RESOLVED_ID:-${TASK_FILE:-<task>}}"
  echo "✗ Can't scope this task's changes — nothing to audit."
  echo "  Context source: $CONTEXT_SOURCE"
  [ -n "$TASK_FILE" ] && echo "  Task: $TASK_FILE"
  echo ""
  echo "  Give the audit a file list one of two ways:"
  echo "    • Add a '### Files changed' block under '## Completed' in the task"
  echo "      (one repo-relative path per line), then re-run."
  echo "    • Pass the files directly:"
  echo "        ./sprint.sh polish ${flag}${target} <file>..."
  exit 0
}

# ═════════════════════════════════════════════════════════════════════
# MODE: code — fixer/verifier code-diff audit (formerly review-code)
# ═════════════════════════════════════════════════════════════════════
if [ "$MODE" = "code" ]; then
  MODEL="$(sprintbias_tier_model CODE_AUDIT)"
  TOOLS_FIXER="Read,Edit,Write,Bash,Grep,Glob,Agent"
  TOOLS_VERIFIER="Read,Bash,Grep,Glob,Agent"
  PERMISSIONS="auto"
  MAX_TURNS=30
  LOG_DIR="docs/tmp"
  AI_MODE="$(sprintbias_ai_mode)"

  if [ -z "$TASK_FILE" ] && [ ${#EXPLICIT_FILES[@]} -eq 0 ]; then
    echo "Usage:" >&2
    echo "  ./sprint.sh polish --code <task-file.md> [max-passes]" >&2
    echo "  ./sprint.sh polish --code <file1> <file2> ... [-- max-passes]" >&2
    exit 1
  fi

  if [ "$AI_MODE" != "emit" ] && ! command -v "$SPRINTBIAS_CLI" &>/dev/null; then
    echo "✗ AI CLI '$SPRINTBIAS_CLI' not found in PATH" >&2
    echo "  Edit docs/sprintbias/config to change CLI, or install the tool." >&2
    exit 1
  fi

  mkdir -p "$LOG_DIR"

  sprintbias_change_manifest "$TASK_FILE" ${EXPLICIT_FILES[@]+"${EXPLICIT_FILES[@]}"}
  CHANGED_FILES="$SPRINTBIAS_CHANGED_FILES"
  CONTEXT_SOURCE="$SPRINTBIAS_CONTEXT_SOURCE"

  if [ -z "$CHANGED_FILES" ]; then
    _no_manifest_bail "--code "
  fi

  FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l | tr -d ' ')
  TASK_NAME=""
  TASK_CONTENT=""
  if [ -n "$TASK_FILE" ]; then
    TASK_NAME=$(basename "$TASK_FILE")
    TASK_CONTENT=$(<"$TASK_FILE")
  fi

  echo "▸ Auditing $FILE_COUNT changed file(s)${TASK_NAME:+ for: $TASK_NAME}"
  echo "  Context source: $CONTEXT_SOURCE"
  echo "  Max fixer passes: $MAX_PASSES"
  echo "  Files:"
  echo "$CHANGED_FILES" | sed 's/^/    /'
  echo ""

  if [ "$AI_MODE" = "emit" ]; then
    sprintbias_run -p "You are auditing the code changes below for the developer.

CLAUDE.md is auto-loaded with project context and conventions. Read it first.

${TASK_FILE:+ORIGINAL TASK FILE: $TASK_FILE
}CHANGED FILES (context source: $CONTEXT_SOURCE):
$CHANGED_FILES

Do a fresh-eyes code audit:
1. Build an impact graph — grep for imports/references to the changed files.
2. Audit for correctness, project conventions, style (touched lines only),
   build/type safety, and unsafe patterns.
3. Fix any issues you find directly.
4. Re-verify your fixes with read-only checks.

Finish with a '## Summary' section, then a final line:
VERDICT: PASS — no issues | FIXED — fixed all | FAIL — couldn't fix all | BLOCKED — needs human"
    exit 0
  fi

  if [ -n "$TASK_CONTENT" ]; then
    TASK_BLOCK="TASK FILE: $TASK_FILE

ORIGINAL TASK:
---
$TASK_CONTENT
---"
  else
    TASK_BLOCK="No task file provided. Auditing the listed files directly."
  fi

  run_build_checks() {
    local results=""
    local py_files=()
    local ts_files=()

    while IFS= read -r f; do
      case "$f" in
        *.py)          py_files+=("$f") ;;
        *.ts|*.tsx)    ts_files+=("$f") ;;
      esac
    done <<< "$CHANGED_FILES"

    if [ ${#py_files[@]} -gt 0 ]; then
      if command -v python3 &>/dev/null; then
        local py_pass=0 py_fail=0 py_errors=""
        for f in "${py_files[@]}"; do
          if [ -f "$f" ]; then
            local err
            err=$(python3 -c "import ast,sys; ast.parse(open(sys.argv[1]).read())" "$f" 2>&1) && {
              py_pass=$((py_pass + 1))
            } || {
              py_fail=$((py_fail + 1))
              py_errors="${py_errors}\n  FAIL: $f — $err"
            }
          fi
        done
        if [ "$py_fail" -eq 0 ]; then
          results="${results}Python ast.parse: PASS ($py_pass/$((py_pass + py_fail)) files)\n"
        else
          results="${results}Python ast.parse: FAIL ($py_fail failures)${py_errors}\n"
        fi
      else
        results="${results}Python ast.parse: SKIPPED (python3 not found)\n"
      fi
    fi

    if [ ${#ts_files[@]} -gt 0 ]; then
      local ts_dir=""
      for f in "${ts_files[@]}"; do
        local dir
        dir=$(dirname "$f")
        while true; do
          if [ -f "$dir/tsconfig.json" ]; then
            ts_dir="$dir"
            break 2
          fi
          [ "$dir" = "." ] || [ "$dir" = "/" ] && break
          dir=$(dirname "$dir")
        done
      done

      local tsc_runner=""
      if [ -n "$ts_dir" ]; then
        if command -v pnpm &>/dev/null; then tsc_runner="pnpm"
        elif command -v npx &>/dev/null; then tsc_runner="npx"
        fi
      fi

      if [ -n "$tsc_runner" ]; then
        local tsc_err
        tsc_err=$(cd "$ts_dir" && "$tsc_runner" tsc --noEmit 2>&1) && {
          results="${results}TypeScript tsc: PASS (in $ts_dir)\n"
        } || {
          results="${results}TypeScript tsc: FAIL (in $ts_dir)\n$(echo "$tsc_err" | head -20 | sed 's/^/  /')\n"
        }
      else
        results="${results}TypeScript tsc: SKIPPED (pnpm/npx not found or no tsconfig.json)\n"
      fi
    fi

    printf '%b' "$results"
  }

  BUILD_CHECK_RESULTS=""
  echo "▸ Running build checks..."
  BUILD_CHECK_RESULTS=$(run_build_checks)
  if [ -n "$BUILD_CHECK_RESULTS" ]; then
    echo "$BUILD_CHECK_RESULTS" | sed 's/^/  /'
  else
    echo "  (no applicable build checks)"
  fi
  echo ""

  STEP=0
  FIXER_COUNT=0
  VERIFY_COUNT=0
  VERDICT="FAIL"
  NEXT_MODE="fixer"
  PREV_SUMMARY=""
  TIMESTAMP_BASE=$(date +%Y%m%d-%H%M%S)
  _model_args=()
  [ -n "$MODEL" ] && _model_args=(--model "$MODEL")
  # Budget only on a cap-capable tier (today Claude Code) — see lib.sh.
  _budget_args=()
  if sprintbias_budget_capable && [ -n "${SPRINTBIAS_BUDGET_AUDIT:-}" ]; then
    _budget_args=(--budget "$SPRINTBIAS_BUDGET_AUDIT")
  fi
  _log_name="${TASK_NAME:-adhoc}"

  MAX_STEPS=$((MAX_PASSES * 2))

  _cleanup_files=()
  trap 'echo ""; echo "▸ Audit interrupted"; rm -f "${_cleanup_files[@]}" 2>/dev/null; exit 130' INT TERM

  LAST_MODE=""

  while true; do
    MODE_STEP="$NEXT_MODE"

    if [ "$STEP" -ge "$MAX_STEPS" ]; then
      echo "  ✗ Max total steps ($MAX_STEPS) reached"
      break
    fi

    if [ "$MODE_STEP" = "fixer" ]; then
      if [ "$FIXER_COUNT" -ge "$MAX_PASSES" ]; then
        echo "  ✗ Max fixer passes ($MAX_PASSES) reached"
        break
      fi
      FIXER_COUNT=$((FIXER_COUNT + 1))
    else
      VERIFY_COUNT=$((VERIFY_COUNT + 1))
    fi

    STEP=$((STEP + 1))
    LAST_MODE="$MODE_STEP"

    echo "── Step $STEP ($MODE_STEP) ──────────────────────────────────"

    if [ "$MODE_STEP" = "verifier" ]; then
      ACTIVE_TOOLS="$TOOLS_VERIFIER"
    else
      ACTIVE_TOOLS="$TOOLS_FIXER"
    fi

    if [ "$STEP" -gt 1 ]; then
      NEW_CHANGES=$(git diff --name-only 2>/dev/null || true)
      NEW_STAGED=$(git diff --cached --name-only 2>/dev/null || true)
      ALL_NEW=$(printf '%s\n%s' "$NEW_CHANGES" "$NEW_STAGED" | sort -u | grep -v '^$' || true)
      if [ -n "$ALL_NEW" ]; then
        MERGED=$(printf '%s\n%s' "$CHANGED_FILES" "$ALL_NEW" | sort -u | grep -v '^$' || true)
        if [ "$MERGED" != "$CHANGED_FILES" ]; then
          CHANGED_FILES="$MERGED"
          FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l | tr -d ' ')
          echo "  ▸ Updated file list ($FILE_COUNT files after rescan)"
        fi
      fi
    fi

    PRE_DIFF_FILE=""
    if [ "$MODE_STEP" = "fixer" ]; then
      PRE_DIFF_FILE=$(mktemp "$LOG_DIR/pre-diff-XXXXXX")
      _cleanup_files+=("$PRE_DIFF_FILE")
      git diff HEAD > "$PRE_DIFF_FILE" 2>/dev/null || git diff > "$PRE_DIFF_FILE" 2>/dev/null || true
    fi

    BUILD_BLOCK=""
    if [ -n "$BUILD_CHECK_RESULTS" ]; then
      BUILD_BLOCK="
PRE-AUDIT BUILD CHECK RESULTS:
$BUILD_CHECK_RESULTS
Note: These checks ran outside the AI before audit started. Review results but
do not re-run them unless you changed the relevant files during this pass."
    fi

    FEED_FORWARD=""
    if [ -n "$PREV_SUMMARY" ]; then
      FEED_FORWARD="
PREVIOUS PASS SUMMARY:
$PREV_SUMMARY"
    fi

    if [ "$MODE_STEP" = "verifier" ]; then
      PASS_CONTEXT="You are VERIFYING fixes made by a previous auditor. You have READ-ONLY tools.
$FEED_FORWARD"

      PROMPT="Code verifier (READ-ONLY). CLAUDE.md is auto-loaded.

$TASK_BLOCK
$PASS_CONTEXT

CHANGED FILES:
$CHANGED_FILES

1. Read changed files and trace imports/references.
2. Verify: correctness, conventions, safety.
$BUILD_BLOCK

Your response's VERY LAST line must be the verdict and nothing after it, in
exactly this form — the literal word VERDICT, a colon, a space, then ONE
uppercase token, no bold, no punctuation, no trailing text:
VERDICT: PASS    (fixes hold up)   or   VERDICT: FAIL   (issues remain)"

    else
      if [ "$STEP" -eq 1 ]; then
        PASS_CONTEXT="This is the first audit pass. Be thorough."
      else
        PASS_CONTEXT="This is fixer pass $FIXER_COUNT. A previous pass identified issues.
$FEED_FORWARD

Focus on the specific issues identified above. Fix them if you can."
      fi

      PROMPT="Code auditor with FRESH EYES. CLAUDE.md is auto-loaded.

$TASK_BLOCK
$PASS_CONTEXT

CHANGED FILES:
$CHANGED_FILES

1. Build impact graph: Grep for imports/references to changed files.
2. Audit: correctness, conventions, style (touched lines only), build, safety.
3. Fix issues you find.
$BUILD_BLOCK

End with a '## Summary' section. Then your VERY LAST line must be the verdict
and nothing after it, in exactly this form — the literal word VERDICT, a colon,
a space, then ONE uppercase token, no bold, no punctuation, no trailing text:
VERDICT: PASS
Choose the token by meaning — PASS: no issues · FIXED: fixed all you found ·
FAIL: couldn't fix all · BLOCKED: needs a human."
    fi

    LOG_FILE="$LOG_DIR/log-polish-code-${_log_name%.md}-step${STEP}-${MODE_STEP}-$TIMESTAMP_BASE.json"

    OUTPUT=$(sprintbias_run -p "$PROMPT" \
      ${_model_args[@]+"${_model_args[@]}"} \
      ${_budget_args[@]+"${_budget_args[@]}"} \
      --tools "$ACTIVE_TOOLS" \
      --permissions "$PERMISSIONS" \
      --max-turns "$MAX_TURNS" \
      --output-format json 2>/dev/null | tee "$LOG_FILE") || true

    STEP_VERDICT=$(printf '%s' "$OUTPUT" | sprintbias_parse_verdict 'PASS|FIXED|FAIL|BLOCKED')
    [ -z "$STEP_VERDICT" ] && STEP_VERDICT="UNCLEAR"

    echo "  Result: $STEP_VERDICT"

    if [ "$MODE_STEP" = "fixer" ] && [ -n "$PRE_DIFF_FILE" ]; then
      POST_DIFF_FILE=$(mktemp "$LOG_DIR/post-diff-XXXXXX")
      _cleanup_files+=("$POST_DIFF_FILE")
      git diff HEAD > "$POST_DIFF_FILE" 2>/dev/null || git diff > "$POST_DIFF_FILE" 2>/dev/null || true

      DIFF_PATCH="$LOG_DIR/diff-polish-code-step${STEP}-$TIMESTAMP_BASE.patch"
      DIFF_DELTA=$(diff "$PRE_DIFF_FILE" "$POST_DIFF_FILE" 2>/dev/null || true)

      rm -f "$PRE_DIFF_FILE" "$POST_DIFF_FILE"
      _cleanup_files=()

      if [ -n "$DIFF_DELTA" ]; then
        echo "$DIFF_DELTA" > "$DIFF_PATCH"
        echo "  ▸ Changes captured in $(basename "$DIFF_PATCH")"
      fi

      if [ -z "$DIFF_DELTA" ]; then
        if [ "$STEP_VERDICT" = "FAIL" ]; then
          echo "  ⚠ FAIL with no actual changes — escalating to BLOCKED"
          STEP_VERDICT="BLOCKED"
        elif [ "$STEP_VERDICT" = "FIXED" ]; then
          echo "  ⚠ FIXED with no actual changes — treating as PASS"
          STEP_VERDICT="PASS"
        fi
      fi
    fi

    PREV_SUMMARY=$(sprintbias_extract_summary "$LOG_FILE")

    case "$STEP_VERDICT" in
      PASS)
        VERDICT="PASS"
        if [ "$MODE_STEP" = "verifier" ]; then
          echo "  ✓ Verified — audit complete"
        else
          echo "  ✓ Clean pass — no issues found"
        fi
        break
        ;;
      FIXED)
        VERDICT="FIXED"
        if [ "$MODE_STEP" = "verifier" ]; then
          echo "  ✓ Verified (verifier reported FIXED) — audit complete"
          VERDICT="PASS"
          break
        else
          echo "  ▸ Issues fixed — scheduling verify pass"
          NEXT_MODE="verifier"
        fi
        ;;
      FAIL)
        VERDICT="FAIL"
        if [ "$MODE_STEP" = "verifier" ]; then
          echo "  ⚠ Verification failed — scheduling fixer pass"
          NEXT_MODE="fixer"
        else
          echo "  ⚠ Issues remain — re-running fixer"
          NEXT_MODE="fixer"
        fi
        ;;
      BLOCKED)
        VERDICT="BLOCKED"
        echo "  ✗ Blocked — needs human intervention"
        break
        ;;
      *)
        echo "  ? Could not parse verdict — treating as FAIL"
        VERDICT="UNCLEAR"
        NEXT_MODE="fixer"
        ;;
    esac
  done

  echo ""

  if [ -n "$TASK_FILE" ]; then
    {
      echo ""
      echo "## Audit"
      echo ""
      echo "- **Steps run**: $STEP ($FIXER_COUNT fixer + $VERIFY_COUNT verifier)"
      echo "- **Final verdict**: $VERDICT"
      echo "- **Final mode**: ${LAST_MODE:-$MODE_STEP}"
      echo "- **Date**: $(date +%Y-%m-%d)"
      echo "- **Files audited**: $FILE_COUNT"
      echo "- **Context source**: $CONTEXT_SOURCE"
      if [ -n "$BUILD_CHECK_RESULTS" ]; then
        echo "- **Build checks**: $(echo "$BUILD_CHECK_RESULTS" | head -1 | tr -d '\n')"
      fi
    } >> "$TASK_FILE"
  fi

  case "$VERDICT" in
    PASS)
      echo "✓ Code audit passed ($STEP step(s): $FIXER_COUNT fixer + $VERIFY_COUNT verifier)"
      exit 0
      ;;
    UNCLEAR)
      echo "? Code audit: could not parse a verdict after $STEP step(s)"
      if [ -n "${LOG_FILE:-}" ] && [ ! -s "$LOG_FILE" ]; then
        echo "  Last log is empty — the AI CLI likely failed to start (check '$SPRINTBIAS_CLI' install/auth)"
      else
        echo "  The model's final line held no recognizable VERDICT token."
        echo "  Inspect the log tail in $LOG_DIR/, then re-run: ./sprint.sh polish --code <files>"
      fi
      exit 1
      ;;
    *)
      echo "⚠ Code audit completed with warnings after $STEP step(s)"
      echo "  Final verdict: $VERDICT"
      echo "  Review audit logs in $LOG_DIR/"
      exit 1
      ;;
  esac
fi

# ═════════════════════════════════════════════════════════════════════
# MODE: judge — deep single-piece judgment (formerly excellence)
# ═════════════════════════════════════════════════════════════════════
if [ "$MODE" = "judge" ]; then
  MODEL="$(sprintbias_tier_model EXCELLENCE)"
  TOOLS="Read,Grep,Glob,Bash,Edit,Agent"
  PERMISSIONS="auto"
  MAX_TURNS=30
  LOG_DIR="docs/tmp"
  PROTOCOL="docs/sprintbias/ai/audit-excellence.md"
  AI_MODE="$(sprintbias_ai_mode)"

  if [ -z "$TASK_FILE" ] && [ ${#EXPLICIT_FILES[@]} -eq 0 ]; then
    echo "Usage:" >&2
    echo "  ./sprint.sh polish <task-file.md>" >&2
    echo "  ./sprint.sh polish <file1> <file2> ..." >&2
    exit 1
  fi

  if [ ! -f "$PROTOCOL" ]; then
    echo "✗ Protocol file missing: $PROTOCOL" >&2
    exit 1
  fi

  mkdir -p "$LOG_DIR"

  sprintbias_change_manifest "$TASK_FILE" ${EXPLICIT_FILES[@]+"${EXPLICIT_FILES[@]}"}
  CHANGED_FILES="$SPRINTBIAS_CHANGED_FILES"
  CONTEXT_SOURCE="$SPRINTBIAS_CONTEXT_SOURCE"

  if [ -z "$CHANGED_FILES" ]; then
    _no_manifest_bail ""
  fi

  FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l | tr -d ' ')
  TASK_NAME=""
  if [ -n "$TASK_FILE" ]; then
    TASK_NAME=$(basename "$TASK_FILE")
  fi

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

  OUTPUT=$(sprintbias_run -p "$PROMPT" \
    ${_model_args[@]+"${_model_args[@]}"} \
    ${_budget_args[@]+"${_budget_args[@]}"} \
    --tools "$TOOLS" \
    --permissions "$PERMISSIONS" \
    --max-turns "$MAX_TURNS" \
    --output-format json 2>/dev/null | tee "$LOG_FILE") || true

  VERDICT=$(printf '%s' "$OUTPUT" | sprintbias_parse_verdict 'EXCELLENT|FILED|BLOCKER')
  [ -z "$VERDICT" ] && VERDICT="UNCLEAR"

  SUMMARY=$(sprintbias_extract_summary "$LOG_FILE")

  FILED_COUNT=$(echo "$OUTPUT" | grep -oE 'FILED: docs/tasks/backlog/' | wc -l | tr -d ' ' || true)

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
      echo "✓ Excellence audit: $FILED_COUNT enhancement task(s) filed to docs/tasks/backlog/"
      exit 0
      ;;
    BLOCKER)
      echo "✗ Excellence audit: BLOCKER — the work does not meet its own task's goal"
      echo "  See ${TASK_FILE:-$LOG_FILE} for details"
      exit 1
      ;;
    *)
      echo "? Excellence audit: could not parse a verdict — see $LOG_FILE"
      if [ ! -s "$LOG_FILE" ]; then
        echo "  Log is empty — the AI CLI likely failed to start (check '$SPRINTBIAS_CLI' install/auth)"
      fi
      exit 1
      ;;
  esac
fi

# ═════════════════════════════════════════════════════════════════════
# MODE: sweep — serialized refine pass over review/ (original polish)
# ═════════════════════════════════════════════════════════════════════
MODEL="$(sprintbias_tier_model POLISH)"
TOOLS="Read,Edit,Grep,Glob,Bash,Agent"
PERMISSIONS="auto"
MAX_TURNS=30
PROTOCOL="docs/sprintbias/ai/refine.md"

REVIEW_DIR="docs/tasks/review"
NEXT_DIR="docs/tasks/next"
LOG_DIR="docs/tmp"

if [ ! -f "$PROTOCOL" ]; then
  echo "✗ Protocol file missing: $PROTOCOL" >&2
  exit 1
fi
for dir in "$REVIEW_DIR" "$NEXT_DIR"; do
  if [ ! -d "$dir" ]; then
    echo "✗ Missing directory: $dir" >&2
    exit 1
  fi
done
mkdir -p "$LOG_DIR"

AI_MODE="$(sprintbias_ai_mode)"

TASK_FILES=()
while IFS= read -r f; do
  TASK_FILES+=("$f")
done < <(
  ls -1 "$REVIEW_DIR"/*.md 2>/dev/null \
    | sed 's|.*/||' \
    | sort -t- -k1,1n \
    | sed "s|^|$REVIEW_DIR/|"
)

if [ ${#TASK_FILES[@]} -eq 0 ]; then
  echo "No tasks in $REVIEW_DIR — nothing to polish"
  exit 0
fi

# The round cap keys on the **Reworked**: header integer — state that ONLY
# polish increments — never on '## Rework'/'## Refine' headings in the body
# (those can be written by a pre-work gate pass, a chat walk, or a hand edit,
# so counting them skips tasks polish never actually judged). A missing field
# reads as 0, so legacy review/ tasks become judgeable again rather than being
# back-counted from old headings.
_rework_count() {
  local n
  n=$(grep -m1 '^\*\*Reworked\*\*:' "$1" 2>/dev/null | sed 's/.*: *//' | tr -d '[:space:]')
  [[ "$n" =~ ^[0-9]+$ ]] || n=0
  echo "$n"
}

# Reopen-confirmation signal: count polish's own '## Rework' sections so the
# runner can confirm the judge actually appended one before it reopens a task.
_rework_sections() { local n; n=$(grep -c '^## Rework' "$1" 2>/dev/null) || true; echo "${n:-0}"; }

# Increment the **Reworked**: header by 1 on a confirmed reopen. The shell owns
# this state write (deterministic beats trusting the model to edit a header
# exactly). A legacy task without the field gets it seeded after **Parent**:.
_bump_reworked() {
  local f="$1" new
  new=$(( $(_rework_count "$f") + 1 ))
  if grep -q '^\*\*Reworked\*\*:' "$f" 2>/dev/null; then
    sed_inplace "s|^\*\*Reworked\*\*:.*|**Reworked**: ${new}|" "$f"
  else
    # Legacy task lacking the field: seed it at the end of the metadata block
    # (the run of '**...**:' header lines), just before the blank line that
    # closes it — so it groups with Feature/Created/… rather than floating.
    awk -v v="$new" '
      !ins && seen && /^[[:space:]]*$/ { print "**Reworked**: " v; ins=1 }
      /^\*\*[^*]+\*\*:/ { seen=1 }
      { print }
      END { if (!ins) exit 3 }
    ' "$f" > "$f.tmp" && mv "$f.tmp" "$f" || {
      rm -f "$f.tmp"
      awk -v v="$new" 'NR==1{print; print "**Reworked**: " v; next} {print}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    }
  fi
}

ELIGIBLE=()
CAPPED=()
for f in "${TASK_FILES[@]}"; do
  if [ "$FORCE" -ne 1 ] && [ "$(_rework_count "$f")" -ge "$MAX_ROUNDS" ]; then
    CAPPED+=("$f")
  else
    ELIGIBLE+=("$f")
  fi
done

if [ ${#CAPPED[@]} -gt 0 ]; then
  echo "⊘ Skipping ${#CAPPED[@]} task(s) already at the round cap ($MAX_ROUNDS):"
  for f in "${CAPPED[@]}"; do echo "    ${f##*/}"; done
  echo "  Re-polish anyway:  ./sprint.sh polish --force"
  echo ""
fi

TASK_FILES=(${ELIGIBLE[@]+"${ELIGIBLE[@]}"})
if [ ${#TASK_FILES[@]} -eq 0 ]; then
  echo "No eligible tasks to polish in $REVIEW_DIR"
  exit 0
fi

COUNT=${#TASK_FILES[@]}
[ "$COUNT" -gt "$MAX_TASKS" ] && COUNT=$MAX_TASKS

echo "▸ $COUNT task(s) queued from $REVIEW_DIR (round cap: $MAX_ROUNDS)"
echo ""

_refine_prompt() {
  local task_file="$1" next_round="$2"
  sprintbias_change_manifest "$task_file"
  local changed="$SPRINTBIAS_CHANGED_FILES"
  local ctx="$SPRINTBIAS_CONTEXT_SOURCE"
  local profile_line; profile_line="$(sprintbias_profile_line)"

  local changed_block
  if [ -n "$changed" ]; then
    changed_block="CHANGED FILES (source: $ctx):
$changed"
  else
    changed_block="CHANGED FILES: none detected ($ctx). Infer the change from
the task's ## Completed section and recent git history."
  fi

  cat <<PROMPT
Refine pass on ONE finished task. CLAUDE.md is auto-loaded.${profile_line}

Follow this protocol exactly. The hard rules:
- You NEVER edit product code — your only write is this task file.
- The work is presumed correct — you judge altitude, not syntax.
- Reopen only when a second execution pass would close a real, bounded gap.
- If you reopen, title the appended section exactly: ## Rework (round $next_round)

PROTOCOL ($PROTOCOL):
---
$(<"$PROTOCOL")
---

TASK FILE: $task_file

ORIGINAL TASK:
---
$(<"$task_file")
---

$changed_block

Steps:
1. Read the task (header included), the changed files, and their blast radius.
2. Trace the end-to-end path; judge the excellence dimensions.
3. Decide: PASS, REOPEN, or BLOCKER per the protocol's reopen test.
4. If REOPEN: use Edit to APPEND a '## Rework (round $next_round)' section to
   $task_file with a Why and an unchecked '- [ ]' improvement checklist.
   Do not alter the task's existing Success criteria, ## Completed section, or
   its '**Status: READY**' stamp.
5. Output the report per the protocol. Your VERY LAST line must be the verdict
   and nothing after it:
   VERDICT: PASS | VERDICT: REOPEN — <n> improvement(s) | VERDICT: BLOCKER — <reason>
PROMPT
}

if [ "$AI_MODE" = "emit" ]; then
  _profile_line="$(sprintbias_profile_line)"

  _task_list=""
  for ((i=0; i<COUNT; i++)); do
    _f="${TASK_FILES[$i]}"
    _n=$(( $(_rework_count "$_f") + 1 ))
    _task_list="${_task_list}
- ${_f}  (next round: $_n)"
  done

  _RULES="Follow docs/sprintbias/ai/refine.md exactly. You never edit product
code — your only write is the task file. Reopen only when a second execution
pass would close a real, bounded gap; otherwise PASS. If you reopen, APPEND a
'## Rework (round N)' section (use the next-round number shown for that task)
with a Why and an unchecked '- [ ]' checklist, and leave the task's existing
Success criteria, ## Completed, and '**Status: READY**' stamp untouched. End
with: VERDICT: PASS | REOPEN — <n> | BLOCKER — <reason>."

  if sprintbias_orchestration_capable; then
    # --parallel/--fast only flips the dispatch wording from sequential
    # ("one subagent, when it returns") to concurrent fan-out. The numeric
    # --jobs cap is a headless-only knob and is deliberately NOT threaded here.
    if [ "$PARALLEL" -eq 1 ]; then
      _dispatch="Fan the judge subagents out CONCURRENTLY: launch one subagent per task
file below at the same time — do not wait for one to return before starting the
next. The judges run in parallel; you serialize only the routing. Each
subagent's entire instruction is:
     \"Refine ONE finished task. Read the task file at <path> and judge it.
$(sprintbias_subagent_no_nest)
$_RULES\"
As each subagent returns, read its task file and route by its verdict:"
    else
      _dispatch="For EACH task file below:
1. Launch a subagent whose entire instruction is:
     \"Refine ONE finished task. Read the task file at <path> and judge it.
$(sprintbias_subagent_no_nest)
$_RULES\"
2. When it returns, read the task file and route by the subagent's verdict:"
    fi
    sprintbias_run -p "You are running the SprintBias polish queue: $COUNT finished
task(s) in review/ to judge. CLAUDE.md / AGENTS.md is auto-loaded when present.${_profile_line}

Judge each task in $(sprintbias_subagent_own_fresh polish) so contexts never mix.
You are the orchestrator — the subagents judge and rewrite; you move the files.

$_dispatch
   - REOPEN (it appended a '## Rework (round N)' section) → increment the
     '**Reworked**:' header integer by 1 (seed the field as 1 if the task
     lacks it), then COMMIT TO SPRINT via the shared gate ONLY:
       bash docs/sprintbias/scripts/promote-to-sprint.sh <path>
     NEVER raw git mv into $NEXT_DIR/. Gate routes READY → next/, BLOCKED →
     blocked/, COMPLETE → review/.
   - PASS    → leave it in $REVIEW_DIR/
   - BLOCKER → leave it in $REVIEW_DIR/ (note it for the human)

Tasks (in order):$_task_list

When every task is routed, report a one-line summary: how many reopened to
next/ (gate READY) vs left in review/ (and any blockers)."
  else
    sprintbias_run -p "You are running the SprintBias polish queue: $COUNT finished
task(s) in review/ to judge. CLAUDE.md is auto-loaded.${_profile_line}

Work the tasks ONE AT A TIME, in the listed order. You have no subagent tool,
so you are the judge, not an orchestrator — after each task, reset your focus
and start the next from a clean slate.

For EACH task file below:
1. Read the task file at <path> and judge it.
$_RULES
2. Route by your verdict:
   - REOPEN (you appended a '## Rework (round N)' section) → increment the
     '**Reworked**:' header integer by 1 (seed the field as 1 if the task
     lacks it), then COMMIT TO SPRINT via the shared gate ONLY:
       bash docs/sprintbias/scripts/promote-to-sprint.sh <path>
     NEVER raw git mv into $NEXT_DIR/. Gate routes READY → next/, BLOCKED →
     blocked/, COMPLETE → review/.
   - PASS    → leave it in $REVIEW_DIR/
   - BLOCKER → leave it in $REVIEW_DIR/ (note it for the human)

Tasks (in order):$_task_list

When every task is routed, report a one-line summary: how many reopened to
next/ (gate READY) vs left in review/ (and any blockers)."
  fi
  exit 0
fi

REOPENED=0
PASSED=0
BLOCKED=0
UNCLEAR=0
TOTAL_START=$SECONDS

_model_args=();  [ -n "$MODEL" ] && _model_args=(--model "$MODEL")
# Budget only on a cap-capable tier (today Claude Code) — see lib.sh.
_budget_args=()
if sprintbias_budget_capable && [ -n "${SPRINTBIAS_BUDGET_AUDIT:-}" ]; then
  _budget_args=(--budget "$SPRINTBIAS_BUDGET_AUDIT")
fi

# ── Per-task state captured BEFORE any judge runs ──────────────────────
# Log path, next-round number, and the pre-judge '## Rework' section count are
# read up front so a backgrounded judge changes nothing the parent relies on to
# route. Each judge writes ONLY its own task file and its own log; the parent
# parses the verdict and owns every shared mutation (the four counters, the
# **Reworked** bump, and the gate) AFTER a judge returns — exactly the division
# of labour work.sh's _run_task/_route_result give.
LOGS=(); ROUNDS=(); BEFORE=()
for ((i=0; i<COUNT; i++)); do
  LOGS+=("$(sprintbias_log_path polish "${TASK_FILES[$i]##*/}")")
  ROUNDS+=("$(( $(_rework_count "${TASK_FILES[$i]}") + 1 ))")
  BEFORE+=("$(_rework_sections "${TASK_FILES[$i]}")")
done

# Run the refine judge for task i into its OWN log. Backgroundable: it must not
# touch a shared counter or call the gate — those are the parent's job.
_run_refine() {
  local i="$1"
  sprintbias_run -p "$(_refine_prompt "${TASK_FILES[$i]}" "${ROUNDS[$i]}")" \
    ${_model_args[@]+"${_model_args[@]}"} \
    ${_budget_args[@]+"${_budget_args[@]}"} \
    --tools "$TOOLS" \
    --permissions "$PERMISSIONS" \
    --max-turns "$MAX_TURNS" \
    --output-format json > "${LOGS[$i]}" 2>/dev/null || true
}

# Route task i by the verdict in its log. Runs ONLY in the parent (never
# backgrounded), so REOPENED/PASSED/BLOCKED/UNCLEAR, the **Reworked** bump, and
# gate promotion all stay serialized even under --jobs N — no count is lost to a
# background job and no concurrent git mv reaches the gate.
_route_refine() {
  local i="$1"
  local TASK_FILE="${TASK_FILES[$i]}" TASK_NAME="${TASK_FILES[$i]##*/}"
  local LOG_FILE="${LOGS[$i]}" NEXT_ROUND="${ROUNDS[$i]}" BEFORE_SECTIONS="${BEFORE[$i]}"
  local VERDICT AFTER_SECTIONS
  VERDICT=$(sprintbias_parse_verdict 'PASS|REOPEN|BLOCKER' < "$LOG_FILE")
  [ -z "$VERDICT" ] && VERDICT="UNCLEAR"
  AFTER_SECTIONS="$(_rework_sections "$TASK_FILE")"

  case "$VERDICT" in
    REOPEN)
      if [ "$AFTER_SECTIONS" -gt "$BEFORE_SECTIONS" ]; then
        _bump_reworked "$TASK_FILE"
        # Re-enter next/ only through the shared gate (same as plan start / chat).
        sprintbias_promote_to_sprint "$TASK_FILE" polish
        case "${SPRINTBIAS_GATE_VERDICT:-}" in
          READY|EMIT)
            REOPENED=$((REOPENED + 1))
            echo "  ↩ Reopened — $(sprintbias_promote_summary "$TASK_NAME") (round $NEXT_ROUND)"
            ;;
          BLOCKED|COMPLETE)
            echo "  ↩ Rework written — $(sprintbias_promote_summary "$TASK_NAME") (not queued in next/)"
            ;;
          *)
            echo "  ⚠ Rework written but gate did not promote: $(sprintbias_promote_summary "$TASK_NAME")"
            [ -n "${SPRINTBIAS_GATE_LOG:-}" ] && echo "    Log: $SPRINTBIAS_GATE_LOG"
            ;;
        esac
      else
        PASSED=$((PASSED + 1))
        echo "  ⚠ Verdict REOPEN but no '## Rework' section was written — left in review/"
        echo "    Log: $LOG_FILE"
      fi
      ;;
    PASS)
      PASSED=$((PASSED + 1))
      echo "  ✓ Meets the bar — left in review/"
      ;;
    BLOCKER)
      BLOCKED=$((BLOCKED + 1))
      echo "  ✗ BLOCKER — needs a human, not a re-run. Left in review/"
      echo "    See $TASK_FILE (or $LOG_FILE)"
      ;;
    *)
      UNCLEAR=$((UNCLEAR + 1))
      echo "  ? Could not parse a verdict — left in review/. See $LOG_FILE"
      [ -s "$LOG_FILE" ] || echo "    Log is empty — the AI CLI likely failed to start (check '$SPRINTBIAS_CLI')"
      ;;
  esac
}

if [ "$PARALLEL" -eq 1 ] && [ "$COUNT" -gt 1 ]; then
  # ── Parallel sweep — fan the judges out, route each as it returns ─────
  # A semaphore keeps at most MAX_JOBS refine calls in flight. Each judge runs
  # backgrounded into its own log; the parent polls, and the instant one exits
  # it routes and counts it — serialized — before topping the pool back up.
  echo "▸ Judging up to $COUNT task(s) concurrently, --jobs $MAX_JOBS..."
  echo ""
  STATE=(); PIDS=()
  for ((i=0; i<COUNT; i++)); do STATE+=(0); PIDS+=(0); done

  # shellcheck disable=SC2154
  trap '
    echo ""; echo "▸ Interrupted — killing background judges..."
    for p in "${PIDS[@]}"; do [ "$p" -ne 0 ] && kill "$p" 2>/dev/null; done
    wait 2>/dev/null
    echo "▸ Tasks left in '"$REVIEW_DIR"'/ for inspection"
    exit 130' INT TERM

  LAUNCHED=0; RUNNING=0; NEXT=0
  _launch_more() {
    while [ "$RUNNING" -lt "$MAX_JOBS" ] && [ "$NEXT" -lt "$COUNT" ]; do
      _run_refine "$NEXT" &
      PIDS[$NEXT]=$!
      STATE[$NEXT]=1
      RUNNING=$((RUNNING + 1)); LAUNCHED=$((LAUNCHED + 1))
      echo "  ▸ Judging $((NEXT + 1))/$COUNT: ${TASK_FILES[$NEXT]##*/} (round ${ROUNDS[$NEXT]})"
      NEXT=$((NEXT + 1))
    done
  }
  _launch_more
  echo ""

  while [ "$RUNNING" -gt 0 ]; do
    _progressed=0
    for ((i=0; i<COUNT; i++)); do
      if [ "${STATE[$i]}" -eq 1 ] && ! kill -0 "${PIDS[$i]}" 2>/dev/null; then
        wait "${PIDS[$i]}" 2>/dev/null || true
        STATE[$i]=2
        RUNNING=$((RUNNING - 1))
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "▸ Judged ${TASK_FILES[$i]##*/} ($((SECONDS - TOTAL_START))s elapsed)"
        _route_refine "$i"
        echo ""
        _progressed=1
      fi
    done
    [ "$_progressed" -eq 1 ] && _launch_more
    [ "$RUNNING" -gt 0 ] && sleep 3
  done

else
  # ── Sequential sweep (default) ───────────────────────────────────────
  for ((i=0; i<COUNT; i++)); do
    TASK_NAME="${TASK_FILES[$i]##*/}"
    N=$((i + 1))
    TASK_START=$SECONDS

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "▸ Polish $N/$COUNT: $TASK_NAME (round ${ROUNDS[$i]})"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    _run_refine "$i"
    _route_refine "$i"

    TASK_ELAPSED=$((SECONDS - TASK_START))
    echo "⏱ Elapsed: $((TASK_ELAPSED / 60))m $((TASK_ELAPSED % 60))s"
    echo ""
  done
fi

TOTAL_ELAPSED=$((SECONDS - TOTAL_START))
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "▸ Done: $REOPENED reopened → next/, $PASSED passed, $BLOCKED blocker(s), $UNCLEAR unclear — total $((TOTAL_ELAPSED / 60))m $((TOTAL_ELAPSED % 60))s"
if [ "$REOPENED" -gt 0 ]; then
  echo "  ↩ Run ./sprint.sh work to re-execute the $REOPENED reopened task(s)."
fi
