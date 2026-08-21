#!/usr/bin/env bash
# promote.sh — Test-gated promotion of review/ tasks to done/. See: ./sprint.sh help promote
#
# Invoked as: ./sprint.sh promote [id] [--dry-run]
#
# Pure shell, NO AI. This is the one automated way a task leaves review/ for
# done/. For each task in docs/tasks/review/, read its **Tests**: field (legacy
# alias **Proven by**) — one or more docs/tests/*.sh paths that prove the work.
# Run them. Every named test green → git mv review/ → done/. A task whose field
# is `none` (or missing) stays in review/ for a human: automation never guesses
# a task is finished; it demands a passing suite script that says so.
#
# Two gates, one lifecycle. **Depends on** gates the close the same way it gates
# the run: a review/ task whose prerequisite is not yet in review/ or done/ is
# held (not moved), so a dependent never lands in done/ ahead of the work it
# needs. **Tests** gates the close: a task closes only when its suite scripts
# pass AND its prerequisites are already closed. The Depends-on hold uses #328's
# sprintbias_classify_dep, so a missing/folded prereq is classified, never
# assumed satisfied. Holds self-clear: a later promote closes newly-eligible
# dependents (a chain closes over successive runs — single pass, no --drain).
#
# After promoting, name any plan whose every member now sits in done/ so the
# developer can retire it with `./sprint.sh plan done <id>`. Retirement stays an
# explicit step — promote never deletes a plan.

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

REVIEW_DIR="docs/tasks/review"
DONE_DIR="docs/tasks/done"
PLANS_DIR="docs/plans"
TESTS_PREFIX="docs/tests/"

# ── Args: optional task id, --dry-run, --audit, --move ───────────────
# Default mode is the pure-shell test-gate. --audit switches to the AI
# acceptance judge (judges each review/ task's Success criteria, protocol
# docs/sprintbias/ai/accept.md). --audit reports and moves NOTHING unless --move
# is also given — auto-advancing to done/ on an AI verdict is a one-way door, so
# it stays behind an explicit flag the same way --dry-run gates the default mode.
ONLY_ID=""
DRY_RUN=0
AUDIT=0
MOVE=0
for _arg in "$@"; do
  case "$_arg" in
    --dry-run) DRY_RUN=1 ;;
    --audit)   AUDIT=1 ;;
    --move)    MOVE=1 ;;
    -h|--help) exec "$(dirname "${BASH_SOURCE[0]}")/../../../sprint.sh" help promote ;;
    [0-9]*)    [ -z "$ONLY_ID" ] && ONLY_ID="$_arg" ;;
    *)         echo "Unknown argument: $_arg (try: ./sprint.sh help promote)" >&2; exit 2 ;;
  esac
done
unset _arg

# --move only means anything under --audit; the default mode has --dry-run.
if [ "$MOVE" -eq 1 ] && [ "$AUDIT" -eq 0 ]; then
  echo "✗ --move applies to --audit only. Default promote already moves proven-green tasks;" >&2
  echo "  use --dry-run to preview it. Did you mean:  ./sprint.sh promote --audit --move" >&2
  exit 2
fi

[ -d "$REVIEW_DIR" ] || { echo "No $REVIEW_DIR/ — nothing to promote."; exit 0; }
mkdir -p "$DONE_DIR"

# ── Gather review/ tasks (optionally a single id) ────────────────────
declare -a TASKS=()
while IFS= read -r f; do
  [ -f "$f" ] || continue
  case "$(basename "$f")" in .TEMPLATE-*|TEMPLATE-*) continue ;; esac
  if [ -n "$ONLY_ID" ]; then
    [ "$(basename "$f" | grep -oE '^[0-9]+')" = "$ONLY_ID" ] || continue
  fi
  TASKS+=("$f")
done < <(find "$REVIEW_DIR" -maxdepth 1 -name '*.md' -type f | sort -t/ -k4)

if [ ${#TASKS[@]} -eq 0 ]; then
  if [ -n "$ONLY_ID" ]; then
    echo "No task #$ONLY_ID in $REVIEW_DIR/."
  else
    echo "No tasks in $REVIEW_DIR/ to promote."
  fi
  exit 0
fi

# Read the **Tests**: value (raw, may be `none` or a path list). Prefer the
# canonical **Tests** header; fall back to legacy **Proven by** for one
# compatibility window. Always exits 0 — a no-match under set -e must not kill
# the caller.
task_tests() {
  local v
  v=$( { grep -m1 -iE '^\*\*Tests\*\*:' "$1" 2>/dev/null || true; } \
    | sed 's/^[^:]*://; s/^[[:space:]]*//; s/[[:space:]]*$//' )
  if [ -z "$v" ]; then
    v=$( { grep -m1 -iE '^\*\*Proven by\*\*:' "$1" 2>/dev/null || true; } \
      | sed 's/^[^:]*://; s/^[[:space:]]*//; s/[[:space:]]*$//' )
  fi
  printf '%s' "$v"
}

# task_held_by FILE — the Depends-on close gate. A review/ task must not close
# while a prerequisite is still open: a dependent must never reach done/ ahead
# of the work it needs. A prereq counts as satisfied ONLY when it has itself
# reached review/ or done/; every other classification (backlog/next/doing/
# blocked, folded, or missing) holds the dependent. Uses #328's classify helper
# so a missing/folded id is classified, never assumed done. Prints one
# "#ID → stage" reason line per unsatisfied prereq; empty output means clear.
# Always exits 0 — a no-match under set -e must not kill the caller.
task_held_by() {
  local f="$1" raw kind id cls
  raw=$(sprintbias_meta_value "$f" "Depends on")
  [ -z "$raw" ] && return 0
  while read -r kind id; do
    [ "$kind" = "id" ] || continue
    cls=$(sprintbias_classify_dep "$id" missing)
    case "$cls" in
      review|done) ;;  # prerequisite closed enough to release the dependent
      *) printf '#%s → %s\n' "$id" "$cls" ;;
    esac
  done <<EOF
$(sprintbias_iter_id_list "$raw")
EOF
  return 0
}

# Label prefix: "(dry-run) " only when the flag is set (DRY_RUN=0 is non-empty,
# so ${DRY_RUN:+…} would wrongly fire — test the value explicitly).
DRY_LABEL=""
[ "$DRY_RUN" -eq 1 ] && DRY_LABEL="(dry-run) "

# Cache test results within one run so a test shared by two tasks runs once.
# Keyed by path → "0" pass / non-zero fail. Bash 3.2 has no assoc arrays we can
# rely on across hosts, so use two parallel arrays.
declare -a RC_PATHS=() RC_CODES=()
run_test() {  # prints exit code, running the test at most once per path
  local p="$1" i rc
  for i in "${!RC_PATHS[@]}"; do
    [ "${RC_PATHS[$i]}" = "$p" ] && { printf '%s' "${RC_CODES[$i]}"; return; }
  done
  set +e
  bash "$p" >/dev/null 2>&1
  rc=$?
  set -e
  RC_PATHS+=("$p"); RC_CODES+=("$rc")
  printf '%s' "$rc"
}

# ═════════════════════════════════════════════════════════════════════
# MODE: audit — AI acceptance judge (opt-in). Judges each review/ task's
# Success criteria (protocol docs/sprintbias/ai/accept.md) and, only under
# --move, closes the DONE ones review/ → done/. The Depends-on hold gate still
# applies: a DONE task whose prerequisite is open is held, never moved.
# ═════════════════════════════════════════════════════════════════════
if [ "$AUDIT" -eq 1 ]; then
  PROTOCOL="docs/sprintbias/ai/accept.md"
  if [ ! -f "$PROTOCOL" ]; then
    echo "✗ Protocol file missing: $PROTOCOL" >&2
    exit 1
  fi
  AI_MODE="$(sprintbias_ai_mode)"
  MODEL="$(sprintbias_tier_model ACCEPT)"
  TOOLS="Read,Grep,Glob,Bash"    # acceptance is read-only — the judge writes nothing
  PERMISSIONS="auto"
  MAX_TURNS="${SPRINTBIAS_AUDIT_MAX_TURNS:-30}"
  LOG_DIR="docs/tmp"
  mkdir -p "$LOG_DIR"

  MOVE_LABEL="report-only"
  [ "$MOVE" -eq 1 ] && MOVE_LABEL="--move: DONE → done/"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "▸ promote --audit  review/ acceptance judge ($MOVE_LABEL)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Build the per-task accept prompt. Success criteria + ## Completed are the
  # yardstick; the changed-file list is a trust aid, so a missing manifest is not
  # fatal here (unlike --code) — the judge falls back to ## Completed.
  _accept_prompt() {
    local task_file="$1"
    sprintbias_change_manifest "$task_file"
    local changed="$SPRINTBIAS_CHANGED_FILES" ctx="$SPRINTBIAS_CONTEXT_SOURCE"
    local profile_line; profile_line="$(sprintbias_profile_line)"
    local changed_block
    if [ -n "$changed" ]; then
      changed_block="CHANGED FILES (source: $ctx):
$changed"
    else
      changed_block="CHANGED FILES: none detected ($ctx). Judge from the task's
## Completed section and Success criteria, confirming against git history."
    fi
    cat <<PROMPT
Acceptance judge on ONE finished task. CLAUDE.md is auto-loaded.${profile_line}

You judge ONE thing: are this task's Success criteria met by the work that
landed? You never edit anything — your only output is the verdict.

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

End with a '## Acceptance' section, then your VERY LAST line must be the verdict
and nothing after it:
VERDICT: DONE | VERDICT: NOT-DONE — <the unmet criterion>
PROMPT
  }

  # ── emit: hand the sweep to the surrounding agent ──────────────────
  if [ "$AI_MODE" = "emit" ]; then
    _profile_line="$(sprintbias_profile_line)"
    _task_list=""
    for f in "${TASKS[@]}"; do _task_list="${_task_list}
- ${f}"; done

    _move_rule="Move NOTHING. This is a report-only run (no --move): for each task
print its id and the subagent's verdict (DONE / NOT-DONE + reason), then stop.
Tell the developer to re-run with --move to close the DONE ones."
    if [ "$MOVE" -eq 1 ]; then
      _move_rule="For each task, route by the subagent's verdict:
   - DONE  → close it: git mv $REVIEW_DIR/<file> $DONE_DIR/<file> || mv (fallback).
             First confirm no open **Depends on** prerequisite (a prereq not yet
             in review/ or done/ HOLDS the task — leave it in review/ and say so).
   - NOT-DONE → leave it in $REVIEW_DIR/ and print the unmet criterion."
    fi

    _RULES="Follow $PROTOCOL exactly. Judge ACCEPTANCE only — are the task's
Success criteria met by what landed? You never edit anything. End with:
VERDICT: DONE | VERDICT: NOT-DONE — <unmet criterion>."

    # Summary tail — value check, not ${MOVE:+…} (MOVE=0 is a non-empty string).
    _summary_tail="DONE vs NOT-DONE"
    [ "$MOVE" -eq 1 ] && _summary_tail="DONE vs NOT-DONE and how many moved to done/"

    if sprintbias_orchestration_capable; then
      sprintbias_run -p "You are running the SprintBias promote --audit queue:
${#TASKS[@]} finished task(s) in review/ to judge for acceptance. CLAUDE.md /
AGENTS.md is auto-loaded when present.${_profile_line}

Judge each task in $(sprintbias_subagent_own_fresh polish) so contexts never mix.
You are the orchestrator — the subagents judge; you route the files.

For EACH task file below:
1. Launch a subagent whose entire instruction is:
     \"Acceptance judge on ONE finished task. Read the task file at <path> and
      judge it. $(sprintbias_subagent_no_nest)
$_RULES\"
2. When it returns, $_move_rule

Tasks (in order):$_task_list

When every task is judged, report a one-line summary: how many $_summary_tail."
    else
      sprintbias_run -p "You are running the SprintBias promote --audit queue:
${#TASKS[@]} finished task(s) in review/ to judge for acceptance. CLAUDE.md is
auto-loaded.${_profile_line}

Work the tasks ONE AT A TIME, in the listed order. You have no subagent tool, so
you are the judge — after each task, reset your focus and start the next clean.

For EACH task file below:
1. Read the task file at <path> and judge it.
$_RULES
2. $_move_rule

Tasks (in order):$_task_list

When every task is judged, report a one-line summary: how many $_summary_tail."
    fi
    exit 0
  fi

  # ── exec: headless loop, one judge per task, serialized ────────────
  if ! command -v "$SPRINTBIAS_CLI" &>/dev/null; then
    echo "✗ AI CLI '$SPRINTBIAS_CLI' not found in PATH" >&2
    echo "  Edit docs/sprintbias/config to change CLI, or install the tool." >&2
    exit 1
  fi

  _model_args=(); [ -n "$MODEL" ] && _model_args=(--model "$MODEL")
  _budget_args=()
  if sprintbias_budget_capable && [ -n "${SPRINTBIAS_BUDGET_AUDIT:-}" ]; then
    _budget_args=(--budget "$SPRINTBIAS_BUDGET_AUDIT")
  fi

  A_DONE=0; A_NOTDONE=0; A_MOVED=0; A_HELD=0; A_UNCLEAR=0
  N=0; TOTAL=${#TASKS[@]}
  for f in "${TASKS[@]}"; do
    name=$(basename "$f")
    id=$(echo "$name" | grep -oE '^[0-9]+' || true)
    N=$((N + 1))
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "▸ Audit $N/$TOTAL: #$id  $name"

    LOG_FILE="$(sprintbias_log_path promote-audit "$name")"
    sprintbias_run -p "$(_accept_prompt "$f")" \
      ${_model_args[@]+"${_model_args[@]}"} \
      ${_budget_args[@]+"${_budget_args[@]}"} \
      --tools "$TOOLS" \
      --permissions "$PERMISSIONS" \
      --max-turns "$MAX_TURNS" \
      --output-format json > "$LOG_FILE" 2>/dev/null || true

    VERDICT=$(sprintbias_parse_verdict 'DONE|NOT-DONE' < "$LOG_FILE")
    # NOT-DONE contains DONE as a substring — parse_verdict returns the first
    # token it matched, so guard the order explicitly.
    if grep -qiE 'VERDICT:[[:space:]]*NOT-DONE' "$LOG_FILE" 2>/dev/null; then
      VERDICT="NOT-DONE"
    fi

    if [ "$VERDICT" = "DONE" ]; then
      held=$(task_held_by "$f")
      if [ -n "$held" ]; then
        echo "  ⊘ #$id  DONE but held — **Depends on** prerequisite not yet closed:"
        while IFS= read -r hr; do
          [ -n "$hr" ] && echo "        $hr  (needs review/ or done/)"
        done <<EOF
$held
EOF
        A_HELD=$((A_HELD + 1))
      elif [ "$MOVE" -eq 1 ]; then
        move_file "$f" "$DONE_DIR/$name"
        echo "  ✓ #$id  DONE → done/"
        A_DONE=$((A_DONE + 1)); A_MOVED=$((A_MOVED + 1))
      else
        echo "  ✓ #$id  DONE → would move to done/ (re-run with --move)"
        A_DONE=$((A_DONE + 1))
      fi
    elif [ "$VERDICT" = "NOT-DONE" ]; then
      # Strip through "NOT-DONE" then any leading punctuation/space (an em-dash is
      # multibyte, so drop non-alphanumeric leading bytes rather than match it).
      reason=$(grep -iE 'VERDICT:[[:space:]]*NOT-DONE' "$LOG_FILE" 2>/dev/null | head -1 | sed 's/.*NOT-DONE//; s/^[^[:alnum:]]*//')
      echo "  ○ #$id  NOT-DONE — stays in review/${reason:+: $reason}"
      A_NOTDONE=$((A_NOTDONE + 1))
    else
      A_UNCLEAR=$((A_UNCLEAR + 1))
      if _re=$(sprintbias_run_error "$LOG_FILE"); then
        echo "  ⚠ #$id  judge did not finish — $_re. Left in review/. See $LOG_FILE"
      else
        echo "  ? #$id  judge finished with no VERDICT token — left in review/. See $LOG_FILE"
      fi
    fi
  done

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if [ "$MOVE" -eq 1 ]; then
    echo "▸ audit: $A_MOVED moved → done/, $A_NOTDONE not-done, $A_HELD held (dep), $A_UNCLEAR unclear"
  else
    echo "▸ audit: $A_DONE done, $A_NOTDONE not-done, $A_HELD held (dep), $A_UNCLEAR unclear — moved nothing"
    [ "$A_DONE" -gt 0 ] && echo "  Close the $A_DONE DONE task(s):  ./sprint.sh promote --audit --move${ONLY_ID:+ $ONLY_ID}"
  fi
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "▸ promote  ${DRY_LABEL}review/ → done/ (test-gated)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PROMOTED=0; FAILED=0; SKIPPED=0; HELD=0
declare -a PROMOTED_IDS=()
SKIP_SAMPLE=""   # basename of first skipped task (exact close path for single-id runs)

for f in "${TASKS[@]}"; do
  name=$(basename "$f")
  id=$(echo "$name" | grep -oE '^[0-9]+' || true)
  proven=$(task_tests "$f")

  # No field, or an explicit `none` → not automatable; leave for a human.
  if [ -z "$proven" ] || [ "$(printf '%s' "$proven" | tr '[:upper:]' '[:lower:]')" = "none" ]; then
    echo "  ○ #$id  no **Tests** — stays in review/ for human sign-off"
    SKIPPED=$((SKIPPED + 1))
    [ -z "$SKIP_SAMPLE" ] && SKIP_SAMPLE="$name"
    continue
  fi

  # Depends-on gate: a task with green Tests still may not close while a
  # prerequisite is open. Hold it (do not run its tests, do not move) and name
  # each unsatisfied prereq with its stage. Self-clearing on a later run.
  held=$(task_held_by "$f")
  if [ -n "$held" ]; then
    echo "  ⊘ #$id  held in review/ — **Depends on** prerequisite not yet closed:"
    while IFS= read -r hr; do
      [ -n "$hr" ] && echo "        $hr  (needs review/ or done/)"
    done <<EOF
$held
EOF
    HELD=$((HELD + 1))
    continue
  fi

  # Split the value on commas and whitespace into candidate test paths.
  all_green=1
  declare -a why=()
  IFS=', ' read -r -a paths <<< "$proven"
  for p in "${paths[@]}"; do
    [ -n "$p" ] || continue
    # Guardrail: only run scripts under the testsuite. A **Tests** path
    # elsewhere is a mis-authored field, not a licence to run any path.
    case "$p" in
      "$TESTS_PREFIX"*) ;;
      *) all_green=0; why+=("$p → not under $TESTS_PREFIX"); continue ;;
    esac
    if [ ! -f "$p" ]; then
      all_green=0; why+=("$p → test file not found"); continue
    fi
    rc=$(run_test "$p")
    if [ "$rc" -ne 0 ]; then
      all_green=0; why+=("$p → FAIL (exit $rc)")
    fi
  done

  if [ "$all_green" -eq 1 ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "  ✓ #$id  proven green → would move to done/  [$proven]"
    else
      move_file "$f" "$DONE_DIR/$name"
      echo "  ✓ #$id  proven green → done/  [$proven]"
    fi
    PROMOTED=$((PROMOTED + 1))
    PROMOTED_IDS+=("$id")
  else
    echo "  ✗ #$id  stays in review/:"
    for w in "${why[@]}"; do echo "        $w"; done
    FAILED=$((FAILED + 1))
  fi
  unset why paths
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "▸ ${DRY_LABEL}$PROMOTED promoted, $FAILED failed, $HELD held (dep), $SKIPPED skipped (no test)"

# ── How to finish what promote could not auto-close ──────────────────
# Skips are not failures (exit 0) but they leave a dead-end-looking summary
# unless we say what to do next — same contract work prints when it lands
# tasks in review/ with Tests: none.
if [ "$SKIPPED" -gt 0 ]; then
  echo ""
  echo "  Skipped = **Tests** is missing or \`none\`. promote only moves review/ → done/"
  echo "  when the field names suite scripts under docs/tests/ and every one exits 0."
  echo ""
  echo "  Close them:"
  if [ -n "$SKIP_SAMPLE" ] && { [ -n "$ONLY_ID" ] || [ "$SKIPPED" -eq 1 ]; }; then
    echo "    Human — approve, then move (git mv first; plain mv if untracked):"
    echo "      git mv $REVIEW_DIR/$SKIP_SAMPLE $DONE_DIR/$SKIP_SAMPLE || mv $REVIEW_DIR/$SKIP_SAMPLE $DONE_DIR/$SKIP_SAMPLE"
  else
    echo "    Human — approve each task, then move (git mv first; plain mv if untracked):"
    echo "      git mv $REVIEW_DIR/<file>.md $DONE_DIR/ || mv $REVIEW_DIR/<file>.md $DONE_DIR/"
  fi
  echo "    Auto next time — edit the task header, then re-run promote:"
  echo "      **Tests**: docs/tests/<suite>.sh"
  echo "  After every plan member is in done/:  ./sprint.sh plan done <id>"
fi
if [ "$FAILED" -gt 0 ]; then
  echo ""
  echo "  Failed = a named suite exited non-zero, the file is missing, or the path"
  echo "  is outside docs/tests/. Fix the suite (or **Tests** path), then:"
  echo "      ./sprint.sh promote${ONLY_ID:+ $ONLY_ID}"
fi
if [ "$HELD" -gt 0 ]; then
  echo ""
  echo "  Held = a **Depends on** prerequisite is still open (not yet in review/ or"
  echo "  done/). promote closes in dependency order so a dependent never lands in"
  echo "  done/ ahead of the work it needs — Depends on gates the close the same way"
  echo "  it gates the run. Close the prerequisite first (promote or finish it), then"
  echo "  re-run — the dependent releases automatically:"
  echo "      ./sprint.sh promote${ONLY_ID:+ $ONLY_ID}"
fi

# ── Name plans now fully in done/ so they can be retired ─────────────
if [ "$PROMOTED" -gt 0 ] && [ -d "$PLANS_DIR" ]; then
  declare -a RETIRABLE=()
  for plan in "$PLANS_DIR"/*.md; do
    [ -f "$plan" ] || continue
    case "$(basename "$plan")" in .TEMPLATE-*|TEMPLATE-*) continue ;; esac
    pid=$(basename "$plan" | grep -oE '^[0-9]+' || true)
    [ -n "$pid" ] || continue
    members=$(grep -oE '^- (\[[ xX]\] )?#[0-9]+' "$plan" 2>/dev/null | grep -oE '[0-9]+' | awk '!seen[$0]++' || true)
    [ -n "$members" ] || continue
    all_done=1
    for m in $members; do
      [ -n "$(find "$DONE_DIR" -maxdepth 1 -name "${m}-*.md" 2>/dev/null | head -1)" ] || { all_done=0; break; }
    done
    [ "$all_done" -eq 1 ] && RETIRABLE+=("$pid")
  done
  if [ ${#RETIRABLE[@]} -gt 0 ]; then
    echo ""
    echo "  Plans now fully in done/ — retire with:"
    for pid in "${RETIRABLE[@]}"; do echo "    ./sprint.sh plan done $pid"; done
  fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
[ "$FAILED" -gt 0 ] && exit 1
exit 0
