#!/usr/bin/env bash
# work.sh — Execute tasks from next/. See: ./sprint.sh help work

set -euo pipefail

# ── Argument parsing ────────────────────────────────────────────────
MAX_TASKS=999
PARALLEL=0
MAX_JOBS=2
SPRINTBIAS_SKIP_DRIFT_CHECK=1
RUN_AUDIT=0
RUN_EXCELLENCE=0
FORCE=0
_NO_LIMITS=0
_next_is_jobs=0
_next_is_model=0
_next_is_count=0
VERBOSE=0
# A bare number is now a TASK ID (work just that one task). The old
# "run at most N" cap moved behind the `count` sub-word. _SINGLE latches
# the single-named-task path so the queue scan / readiness gate / prereq
# drain are skipped for it.
TASK_ID=""
_SINGLE=0
for arg in "$@"; do
  if [ "$_next_is_jobs" -eq 1 ]; then
    MAX_JOBS="$arg"
    _next_is_jobs=0
    continue
  fi
  # --model <id> pins the model for THIS run only by exporting the resolver's
  # per-run lever (SPRINTBIAS_MODEL_DEFAULT) — no config edit. See ./sprint.sh model.
  if [ "$_next_is_model" -eq 1 ]; then
    [ -n "$arg" ] || { echo "✗ --model needs a model id" >&2; exit 1; }
    export SPRINTBIAS_MODEL_DEFAULT="$arg"
    _next_is_model=0
    continue
  fi
  # `count N` restores the old "run at most N tasks" cap under a plain-language
  # sub-word, freeing the bare number to mean a task id.
  if [ "$_next_is_count" -eq 1 ]; then
    case "$arg" in
      ''|*[!0-9]*) echo "✗ count needs a number: ./sprint.sh work count N" >&2; exit 1 ;;
      *) MAX_TASKS="$arg" ;;
    esac
    _next_is_count=0
    continue
  fi
  case "$arg" in
    --drift)      SPRINTBIAS_SKIP_DRIFT_CHECK=0 ;;
    --audit)      RUN_AUDIT=1 ;;
    --excellence) RUN_EXCELLENCE=1 ;;
    --parallel) PARALLEL=1 ;;
    --fast)     PARALLEL=1; MAX_JOBS=4 ;;
    --max)      _NO_LIMITS=1 ;;
    --force)    FORCE=1 ;;
    --assist)   _ASSIST=1 ;;
    --jobs)     _next_is_jobs=1 ;;
    --model)    _next_is_model=1 ;;
    --verbose)  VERBOSE=1 ;;
    count)      _next_is_count=1 ;;
    # A bare number is a TASK ID — work just that task. Two ids is a usage
    # error, not "work both"; the count cap now lives behind `count N`.
    [0-9]*)
      if [ -n "$TASK_ID" ]; then
        echo "✗ work takes one task id — got '$TASK_ID' and '$arg'" >&2
        echo "  For a count cap use: ./sprint.sh work count N" >&2
        exit 1
      fi
      TASK_ID="$arg"
      ;;
    # No silent ignore: an unknown flag or stray token is a mistake, not a no-op.
    *) echo "✗ Unknown argument: $arg" >&2; echo "  See: ./sprint.sh help work" >&2; exit 1 ;;
  esac
done
[ "$_next_is_jobs" -eq 1 ] && { echo "✗ --jobs needs a number" >&2; exit 1; }
[ "$_next_is_model" -eq 1 ] && { echo "✗ --model needs a model id" >&2; exit 1; }
[ "$_next_is_count" -eq 1 ] && { echo "✗ count needs a number: ./sprint.sh work count N" >&2; exit 1; }
unset _next_is_jobs _next_is_model _next_is_count

# ── Interactive assist mode ─────────────────────────────────────────
if [ "${_ASSIST:-0}" -eq 1 ]; then
  echo ""
  echo "  ┌─────────────────────────────────────────┐"
  echo "  │         SprintBias Task Runner             │"
  echo "  └─────────────────────────────────────────┘"
  echo ""
  echo "  Pick a run mode:"
  echo ""
  echo "  1) Standard              sequential"
  echo "  2) Fast parallel         --fast (4 concurrent jobs)"
  echo "  3) Full quality          --max --audit --excellence (correctness + excellence)"
  echo "  4) Full quality + fast   --max --audit --excellence --fast"
  echo ""
  printf "  Choice [1-4]: "
  read -r _choice </dev/tty 2>/dev/null || _choice="1"
  echo ""
  case "$_choice" in
    1) set -- ;;
    2) set -- --fast ;;
    3) set -- --max --audit --excellence ;;
    4) set -- --max --audit --excellence --fast ;;
    *) echo "  Invalid choice, running standard."; set -- ;;
  esac

  # Re-parse the selected flags
  MAX_TASKS=999; PARALLEL=0; MAX_JOBS=2; RUN_AUDIT=0; RUN_EXCELLENCE=0
  _NO_LIMITS=0; SPRINTBIAS_SKIP_DRIFT_CHECK=1
  for arg in "$@"; do
    case "$arg" in
      --drift)      SPRINTBIAS_SKIP_DRIFT_CHECK=0 ;;
      --audit)      RUN_AUDIT=1 ;;
      --excellence) RUN_EXCELLENCE=1 ;;
      --parallel) PARALLEL=1 ;;
      --fast)     PARALLEL=1; MAX_JOBS=4 ;;
      --max)      _NO_LIMITS=1 ;;
    esac
  done
fi
unset _ASSIST

NEXT_DIR="docs/tasks/next"
WORKING_DIR="docs/tasks/doing"
REVIEW_DIR="docs/tasks/review"
BLOCKED_DIR="docs/tasks/blocked"
LOG_DIR="docs/tmp"
# Basenames that land in review/ this run (human sign-off or promote).
TO_REVIEW=()
# Tasks that did NOT complete this run (hard fail, incomplete, or drift-blocked).
# Each element packs "name<US>result<US>dir<US>reason" for the closing recap.
FAIL_DELIM=$'\x1f'
TO_FAIL=()

# ── Config ───────────────────────────────────────────────────────────
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"
# Shared workability gate — same code `gate` and `plan start` run. `work N`
# reuses it to screen-and-promote a named backlog/blocked task inline instead
# of growing work's own argument surface.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/gate-lib.sh"

# Record a basename that moved to review/ this run.
_note_review() {
  TO_REVIEW+=("$1")
}

# Record a task that did not complete this run, for the closing recap.
#   _note_fail NAME RESULT DIR REASON   RESULT ∈ failed|incomplete|blocked
_note_fail() {
  TO_FAIL+=("$1${FAIL_DELIM}$2${FAIL_DELIM}$3${FAIL_DELIM}$4")
}

# To run one invocation against a different CLI or mode, prefix the command:
#   SPRINTBIAS_CLI=codex ./sprint.sh work       (exec that CLI in a plain terminal)
#   SPRINTBIAS_MODE=emit ./sprint.sh work       (force prompt emit for any agent)

MODEL="$(sprintbias_tier_model WORK)"

TOOLS="Read,Edit,Write,Bash,Grep,Glob,Agent"
PERMISSIONS="auto"

# No turn cap: readiness (gate) gates entry, and on a tier that supports
# spending caps (today Claude Code) the budget below is the backstop. A turn cap
# decapitates normal runs mid-work and mislabels them "too complex" — a healthy
# task run is ~25-30 turns.
# --max removes the budget cap where one is armed; on a capless tier there was
# never a cap to remove, so it is silently a no-op.
if [ "$_NO_LIMITS" -eq 1 ]; then
  SPRINTBIAS_BUDGET_WORK=""
fi
unset _NO_LIMITS

# ── Preflight ───────────────────────────────────────────────────────
# run_with_timeout comes from lib.sh. In emit mode no CLI binary is needed;
# in exec mode sprintbias_ai_mode already verified the binary exists.
DRIFT_TIMEOUT=120
AI_MODE="$(sprintbias_ai_mode)"

mkdir -p "$LOG_DIR"

for dir in "$NEXT_DIR" "$WORKING_DIR" "$REVIEW_DIR" "$BLOCKED_DIR"; do
  if [ ! -d "$dir" ]; then
    echo "✗ Missing directory: $dir"
    exit 1
  fi
done

# Drop a finished task's '## Completed' / '### Files changed' audit block so a
# re-run is real: the completion router keys off the presence of '## Completed'
# (see _route_result), so an un-reset review/done task would route straight back
# to review/ without ever being worked. Removes from the '## Completed' heading
# to the next '## ' heading (or EOF — the block is normally last).
_reset_completed() {
  local file="$1" tmp="$1.reset.$$"
  awk '
    /^## Completed[[:space:]]*$/ { skip=1; next }
    skip && /^## / { skip=0 }
    !skip { print }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}

# Strip any existing '## Outcome' block (heading to the next '## ' or EOF).
# Shared by the stamp (rewrite-in-place) and the success route (clear a stale
# failure stamp so a task that later completes doesn't carry a dead Outcome
# into review/).
_strip_outcome() {
  local file="$1" tmp="$1.outcome.$$"
  [ -f "$file" ] || return 0
  awk '
    /^## Outcome[[:space:]]*$/ { skip=1; next }
    skip && /^## / { skip=0 }
    !skip { print }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}

# Stamp a durable '## Outcome' block on a task file (plan 15 §5). A route to
# blocked/, an incomplete stop, or a hard fail records why here so the next run
# and every dependent's hold line can name the reason instead of reading as a
# mystery hold. Idempotent: replaces any prior Outcome block.
#   _stamp_outcome FILE RESULT REASON     RESULT ∈ incomplete|failed|blocked
_stamp_outcome() {
  local file="$1" result="$2" reason="$3" today
  [ -f "$file" ] || return 0
  today="${SPRINTBIAS_TODAY:-$(date +%Y-%m-%d)}"
  _strip_outcome "$file"
  printf '\n## Outcome\n**Result**: %s\n**Reason**: %s\n**At**: %s\n' \
    "$result" "$reason" "$today" >> "$file"
}

# Read a task's '## Outcome' stamp as a short "result: reason" phrase for hold
# lines (empty when unstamped). Lets a dependent's needs-clause say
# `9032 (blocked/ — incomplete: run ended without a '## Completed' …)` instead
# of a bare stage. It renders whatever Reason the file carries, so honest stamp
# wording flows through unchanged.
_outcome_brief() {
  local file="$1" result reason
  [ -f "$file" ] || return 0
  result="$(sprintbias_meta_value "$file" "Result")"
  [ -n "$result" ] || return 0
  reason="$(sprintbias_meta_value "$file" "Reason" \
    | tr '\n' ' ' | cut -c1-60 | sed 's/[[:space:]]*$//')"
  if [ -n "$reason" ]; then
    printf '%s: %s' "$result" "$reason"
  else
    printf '%s' "$result"
  fi
}

# ── Single named task (work N) ───────────────────────────────────────
# `work N` resolves task N by number and runs just that one task, screening
# and promoting it into the sprint first if needed — the same screen-and-run
# steps a user would do by hand (resolve → gate/promote → dependency check),
# then handing off to the normal runner. It narrows the run to a single-task
# TASK_FILES/COUNT=1 BEFORE the emit/exec branch, so it behaves identically in
# emit mode (the repo default) and exec mode.
if [ -n "$TASK_ID" ]; then
  _stage="$(sprintbias_task_stage "$TASK_ID" 2>/dev/null || true)"
  _path="$(sprintbias_task_path "$TASK_ID" 2>/dev/null || true)"
  if [ -z "$_stage" ] || [ -z "$_path" ]; then
    echo "✗ No task $TASK_ID found in any lifecycle folder."
    echo "  Checked backlog/, next/, doing/, blocked/, review/, done/."
    exit 1
  fi
  _name="${_path##*/}"

  # doing/ means one of two things the file alone can't tell apart: a run has
  # it in flight right now, OR a previous run left it here (crash, Ctrl-C, or a
  # bail). We don't fake an ownership check we can't make — we state what we
  # know and hand the user the reclaim paths. --force resumes it in place.
  if [ "$_stage" = "doing" ]; then
    if [ "$FORCE" -eq 1 ]; then
      echo "▸ $TASK_ID is in doing/ — resuming it in place (--force)."
      echo ""
      TASK_FILES=("$_path")
    else
      echo "✗ $TASK_ID is in doing/ — it may be mid-work, or left by an interrupted run."
      echo "  The file can't say which. If a run has it, leave it be. If it was"
      echo "  abandoned, reclaim it one of these ways:"
      echo "    ./sprint.sh loop                 — auto-requeues interrupted doing/ tasks"
      echo "    ./sprint.sh work $TASK_ID --force  — resume just this one now"
      exit 1
    fi
  fi

  # Promotion is earned by runnability, not just definition clarity: check
  # dependencies BEFORE any promote. An unmet prerequisite holds the task and
  # changes nothing — no promote, no demote, no work — and the prerequisite is
  # NOT pulled in behind it. A well-defined backlog/ task merely waiting on a
  # prereq stays in backlog/; a next/ task stays queued in place.
  _unmet="$(sprintbias_unmet_deps "$_path")"
  if [ -n "$_unmet" ]; then
    echo "⏳ held: waiting on $(printf '%s' "$_unmet" | tr ' ' ',')"
    echo "   $TASK_ID depends on unfinished work — run that first, or work the"
    echo "   sprint so the chain drains in order. Left in $_stage/ untouched."
    exit 0
  fi

  case "$_stage" in
    next)
      # Already in the sprint: work it exactly as the queue would, unless it
      # is not stamped READY (unvetted) or still has open decisions, and
      # --force was not passed.
      if [ "$FORCE" -ne 1 ]; then
        if [ "$(sprintbias_review_verdict "$_path")" != "READY" ]; then
          echo "⊘ $TASK_ID is in next/ but not stamped READY — held (unvetted)."
          echo "  Vet it:         ./sprint.sh gate"
          echo "  Or run anyway:  ./sprint.sh work $TASK_ID --force"
          exit 0
        fi
        if sprintbias_has_open_questions "$_path"; then
          # Invariant: READY + open Q cannot stay in next/. Demote loudly.
          sprintbias_demote_open_questions "$_path" "$BLOCKED_DIR" || true
          echo ""
          echo "  Not worked — settle or answer, then promote back to next/:"
          echo "    ./sprint.sh settle $TASK_ID"
          echo "    ./sprint.sh chat $TASK_ID"
          echo "  Or run anyway (skips the check):  ./sprint.sh work $TASK_ID --force"
          exit 0
        fi
      fi
      TASK_FILES=("$_path")
      ;;
    backlog|blocked)
      # Screen-and-promote through the shared gate — the same pathway plan
      # start uses. READY → next/ (then work it); BLOCKED → blocked/ (report,
      # do NOT work); COMPLETE → review/ (work already in the codebase).
      echo "▸ $TASK_ID is in $_stage/ — screening it through the gate before working…"
      echo ""
      sprintbias_promote_to_sprint "$_path" work
      case "${SPRINTBIAS_GATE_VERDICT:-}" in
        READY)
          sprintbias_promote_summary "$_name"
          echo ""
          TASK_FILES=("$NEXT_DIR/$_name")
          ;;
        EMIT)
          # Emit mode: the surrounding agent runs the gate + move itself, so
          # the promote can't chain into work in this process. Land it READY
          # first, then re-run work N to execute it.
          echo ""
          echo "▸ Gate review emitted for $_name — run the prompt above."
          echo "  When it lands READY in next/, run: ./sprint.sh work $TASK_ID"
          exit 0
          ;;
        *)
          sprintbias_promote_summary "$_name"
          echo ""
          echo "  Not worked — resolve the above, then re-run: ./sprint.sh work $TASK_ID"
          exit 0
          ;;
      esac
      ;;
    review|done)
      # Re-run: pull it back to doing/, reset the old ## Completed audit block
      # so the router doesn't short-circuit, rework it, and re-route to review/.
      echo "▸ $TASK_ID is in $_stage/ — re-running it (reset audit block + rework)."
      echo ""
      move_file "$_path" "$WORKING_DIR/$_name"
      _reset_completed "$WORKING_DIR/$_name"
      TASK_FILES=("$WORKING_DIR/$_name")
      ;;
  esac

  MAX_TASKS=1
  _SINGLE=1
fi

if [ "$_SINGLE" -eq 0 ]; then
TASK_FILES=()
while IFS= read -r f; do
  TASK_FILES+=("$f")
done < <(
  ls -1 "$NEXT_DIR"/*.md 2>/dev/null \
    | sed 's|.*/||' \
    | sort -t- -k1,1n \
    | sed "s|^|$NEXT_DIR/|"
)

if [ ${#TASK_FILES[@]} -eq 0 ]; then
  echo "No tasks in $NEXT_DIR"
  exit 0
fi
fi

# ── Readiness gate ──────────────────────────────────────────────────
# gate (and plan start) stamps '**Status: READY**' into tasks it has vetted. A
# task without that verdict hasn't been checked for clarity — and a headless run
# can't ask clarifying questions, so ambiguity turns into wandering and failure.
# So rather than skip an unvetted next/ task, work GATES it first — the same
# gate `gate` runs on next/. The verdict then routes it: READY stays in next/ and
# is worked below; BLOCKED (not defined well enough) goes to blocked/ with a
# chat/define pointer; COMPLETE (already in the codebase) goes to review/.
# Invariant: READY + open questions cannot stay in next/ — demote to blocked/
# with a loud report (same path as work N). A dependency wait is separate:
# unfinished **Depends on** keeps a fully-defined READY task in next/ until
# prereqs reach review/ or done/. --force bypasses the gate entirely (work
# whatever is queued). Skipped for work N: the single-task path already resolved
# readiness (and demoted open-Q files).
if [ "$FORCE" -ne 1 ] && [ "$_SINGLE" -eq 0 ]; then
  # Hygiene first: demote any next/ file that still has open questions so the
  # queue cannot silently re-accumulate READY+openQ integrity bugs.
  sprintbias_sweep_ready_open_questions "$NEXT_DIR" "$BLOCKED_DIR"

  # Rebuild the candidate list after demotions (paths under next/ may have moved).
  TASK_FILES=()
  while IFS= read -r f; do
    TASK_FILES+=("$f")
  done < <(
    ls -1 "$NEXT_DIR"/*.md 2>/dev/null \
      | sed 's|.*/||' \
      | sort -t- -k1,1n \
      | sed "s|^|$NEXT_DIR/|"
  )

  # Partition: already-READY (work them) vs. not-yet-gated (gate them first).
  _unvetted=()
  for _f in "${TASK_FILES[@]}"; do
    [ "$(sprintbias_review_verdict "$_f")" = "READY" ] && continue
    _unvetted+=("$_f")
  done

  if [ ${#_unvetted[@]} -gt 0 ]; then
    if [ "$AI_MODE" = "emit" ]; then
      # Emit mode can't gate a file and then work it in the same process — the
      # surrounding agent runs the emitted gate. Hand off the gate now and stop;
      # re-running work after the verdicts land executes whatever graded READY.
      echo "▸ ${#_unvetted[@]} task(s) in $NEXT_DIR not yet gated — gating them first."
      echo "  (Emit mode gates and works in separate passes.)"
      echo ""
      sprintbias_gate_init gate "$NEXT_DIR"
      if sprintbias_orchestration_capable && [ ${#_unvetted[@]} -gt 1 ]; then
        sprintbias_gate_parallel "${_unvetted[@]}"
      else
        for _f in "${_unvetted[@]}"; do sprintbias_gate_review "$_f"; done
      fi
      echo ""
      echo "▸ Run the gate above, then re-run ./sprint.sh work:"
      echo "    READY    → worked on the next run"
      echo "    BLOCKED  → not defined well enough; ./sprint.sh chat <id> or define it first"
      echo "    COMPLETE → routed to review/ (already in the codebase)"
      exit 0
    fi

    # Exec mode: gate each unvetted task synchronously and route it now.
    echo "▸ ${#_unvetted[@]} task(s) in $NEXT_DIR not yet gated — gating before work…"
    echo ""
    sprintbias_gate_init gate "$NEXT_DIR"
    _blocked=()
    for _f in "${_unvetted[@]}"; do
      _name="${_f##*/}"
      echo "  ▸ Gating ${_name}…"
      sprintbias_gate_review "$_f"
      case "$SPRINTBIAS_GATE_VERDICT" in
        READY)    echo "    ✓ READY — queued for work" ;;
        BLOCKED)  _blocked+=("$_name"); echo "    ⊘ BLOCKED → $BLOCKED_DIR/ — needs a decision" ;;
        COMPLETE) echo "    ✓ COMPLETE → $REVIEW_DIR/ (already in the codebase)" ;;
        *)        echo "    ✗ ${SPRINTBIAS_GATE_VERDICT} — left in $NEXT_DIR/${SPRINTBIAS_GATE_LOG:+ (log: $SPRINTBIAS_GATE_LOG)}" ;;
      esac
    done
    if [ ${#_blocked[@]} -gt 0 ]; then
      echo ""
      echo "⊘ ${#_blocked[@]} task(s) not defined well enough to work → $BLOCKED_DIR/:"
      for _n in "${_blocked[@]}"; do echo "    $_n"; done
      echo "  Settle the open decisions, then re-enter via the gate:"
      echo "    ./sprint.sh chat <id>     # answer the questions, turn each into instruction"
    fi
    echo ""
    unset _blocked _n
  fi

  # Rebuild the ready set from next/ (ID order) — originally-READY tasks plus any
  # just gated READY; BLOCKED/COMPLETE have moved out.
  TASK_FILES=()
  while IFS= read -r f; do
    [ "$(sprintbias_review_verdict "$f")" = "READY" ] && TASK_FILES+=("$f")
  done < <(
    ls -1 "$NEXT_DIR"/*.md 2>/dev/null \
      | sed 's|.*/||' \
      | sort -t- -k1,1n \
      | sed "s|^|$NEXT_DIR/|"
  )
  if [ ${#TASK_FILES[@]} -eq 0 ]; then
    echo "No ready tasks in $NEXT_DIR"
    exit 0
  fi
  unset _unvetted _f _name
fi

# ── Prerequisite resolution (stage-aware) ─────────────────────────────
# For every READY next/ task, walk each unmet Depends-on id by stage:
#   review/done → already complete (not unmet)
#   doing/      → resume this run (route to review if ## Completed already;
#                 otherwise pull into the queue and re-run)
#   next/       → frontier ordering; runs when READY and its own deps clear
#   backlog/    → not auto-lifted (not fully vetted); surface chat <id>
#   blocked/    → needs a decision; surface chat <id>
# Dependents stay in next/ on hold until prereqs land in review/done.
#
# Format a single unmet dep id for human messages (stage + next action).
_format_dep() {
  local id="$1" stage path verdict oc
  stage="$(sprintbias_task_stage "$id" 2>/dev/null || true)"
  case "$stage" in
    doing)
      path="$(sprintbias_task_path "$id" 2>/dev/null || true)"
      if [ -n "$path" ] && grep -q '^## Completed' "$path" 2>/dev/null; then
        printf '%s (doing/ — ## Completed, routing to review/)' "$id"
      else
        oc="$(_outcome_brief "$path")"
        if [ -n "$oc" ]; then
          printf '%s (doing/ — %s)' "$id" "$oc"
        else
          printf '%s (doing/ — resuming unfinished work this run)' "$id"
        fi
      fi
      ;;
    next)
      path="$(sprintbias_task_path "$id" 2>/dev/null || true)"
      verdict=""
      [ -n "$path" ] && verdict="$(sprintbias_review_verdict "$path")"
      if [ "$verdict" = "READY" ]; then
        printf '%s (next/ — runs when its own deps clear)' "$id"
      else
        printf '%s (next/ — not READY; ./sprint.sh chat %s or gate)' "$id" "$id"
      fi
      ;;
    backlog)
      printf '%s (backlog/ — not vetted for work; ./sprint.sh chat %s)' "$id" "$id"
      ;;
    blocked)
      path="$(sprintbias_task_path "$id" 2>/dev/null || true)"
      oc="$(_outcome_brief "$path")"
      if [ -n "$oc" ]; then
        printf '%s (blocked/ — %s) — chat %s' "$id" "$oc" "$id"
      else
        printf '%s (blocked/ — needs a decision; ./sprint.sh chat %s)' "$id" "$id"
      fi
      ;;
    review|done)
      printf '%s (%s/)' "$id" "$stage"
      ;;
    *)
      # No file resolves anywhere — classify via #328 rather than the old
      # "treated complete" silent green. A fold marker means the edge should
      # point at the fold target; otherwise it is a broken reference.
      case "$(sprintbias_classify_dep "$id" missing)" in
        folded)
          path="$(sprintbias_fold_target "$(sprintbias_task_path "$id" 2>/dev/null || true)")"
          printf '%s (folded into %s — update **Depends on**)' "$id" "${path:-?}"
          ;;
        *)
          printf '%s (broken ref — no such task; fix **Depends on** or ./sprint.sh chat %s)' "$id" "$id"
          ;;
      esac
      ;;
  esac
}

# Build a "needs: …" clause for one task file from its current unmet deps.
_needs_clause() {
  local file="$1" unmet id parts=""
  unmet="$(sprintbias_unmet_deps "$file")"
  [ -z "$unmet" ] && return 0
  for id in $unmet; do
    [ -n "$parts" ] && parts="$parts; "
    parts="${parts}$(_format_dep "$id")"
  done
  printf '%s' "$parts"
}

# Resume/route open prereqs that sit in doing/; collect backlog/blocked advice.
# Prepends incomplete doing/ prereqs onto TASK_FILES so the scheduler runs them
# before their dependents. Idempotent for ids already queued.
_PREREQ_ROUTED=0
_PREREQ_RESUME=()
_PREREQ_ADVICE=()
_PREREQ_BROKEN=()
_PREREQ_FOLDED=()
_seen_resume=" "
_seen_advice=" "
_seen_broken=" "

# Classify EVERY declared Depends-on id (not just the unmet ones the gate holds
# on) so a missing or folded reference surfaces loudly instead of reading as a
# silent green. sprintbias_unmet_deps drops missing/folded ids from the gate (a
# stale ref must never wedge the queue); this pass names them for the human via
# #328's sprintbias_classify_dep. Archived-complete (review/done) ids are truly
# done and stay quiet.
_scan_broken_deps_from() {
  local file="$1" raw kind id target
  raw="$(sprintbias_meta_value "$file" "Depends on")"
  [ -z "$raw" ] && return 0
  while read -r kind id; do
    [ "$kind" = "id" ] || continue
    case "$(sprintbias_classify_dep "$id" missing)" in
      missing)
        case "$_seen_broken" in *" m$id "*) continue ;; esac
        _seen_broken="$_seen_broken m$id "
        _PREREQ_BROKEN+=("$id  (referenced by ${file##*/})")
        ;;
      folded)
        case "$_seen_broken" in *" f$id "*) continue ;; esac
        _seen_broken="$_seen_broken f$id "
        target="$(sprintbias_fold_target "$(sprintbias_task_path "$id" 2>/dev/null || true)")"
        _PREREQ_FOLDED+=("$id → ${target:-?}  (referenced by ${file##*/})")
        ;;
    esac
  done <<EOF
$(sprintbias_iter_id_list "$raw")
EOF
}

_collect_prereqs_from() {
  local file="$1" id stage path name
  for id in $(sprintbias_unmet_deps "$file"); do
    stage="$(sprintbias_task_stage "$id" 2>/dev/null || true)"
    case "$stage" in
      doing)
        path="$(sprintbias_task_path "$id" 2>/dev/null || true)"
        [ -n "$path" ] || continue
        name="${path##*/}"
        if grep -q '^## Completed' "$path" 2>/dev/null; then
          # Prior run finished the work but never routed — complete the move.
          # Drop any stale ## Outcome (e.g. re-promoted from blocked/) so
          # review/ never wears a failure stamp next to ## Completed.
          _strip_outcome "$path"
          move_file "$path" "$REVIEW_DIR/$name"
          _PREREQ_ROUTED=$((_PREREQ_ROUTED + 1))
          _note_review "$name"
          echo "  ✓ Prerequisite $name already has ## Completed → $REVIEW_DIR/"
        else
          case "$_seen_resume" in *" $id "*) continue ;; esac
          _seen_resume="$_seen_resume$id "
          _PREREQ_RESUME+=("$path")
          echo "  ↻ Will resume unfinished prerequisite: $name (in doing/)"
        fi
        ;;
      backlog)
        case "$_seen_advice" in *" b$id "*) continue ;; esac
        _seen_advice="$_seen_advice b$id "
        _PREREQ_ADVICE+=("This task depends on $id, which is still in backlog/. Consider: ./sprint.sh chat $id")
        ;;
      blocked)
        case "$_seen_advice" in *" x$id "*) continue ;; esac
        _seen_advice="$_seen_advice x$id "
        _PREREQ_ADVICE+=("This task depends on $id, which still needs a decision in blocked/. Consider: ./sprint.sh chat $id")
        ;;
    esac
  done
}

if [ ${#TASK_FILES[@]} -gt 0 ]; then
  _had_prereq_action=0
  for _f in "${TASK_FILES[@]}"; do
    [ -n "$(sprintbias_unmet_deps "$_f")" ] || continue
    _had_prereq_action=1
    break
  done
  if [ "$_had_prereq_action" -eq 1 ]; then
    echo "▸ Resolving open prerequisites for tasks in $NEXT_DIR/..."
    for _f in "${TASK_FILES[@]}"; do
      _collect_prereqs_from "$_f"
    done
    # Re-scan: routing a completed doing/ prereq may clear several dependents;
    # also catch transitive resumes (A needs B in doing, B needs C in doing).
    _pass=0
    while [ "$_pass" -lt 8 ]; do
      _pass=$((_pass + 1))
      _before=${#_PREREQ_RESUME[@]}
      _before_routed=$_PREREQ_ROUTED
      for _p in ${_PREREQ_RESUME[@]+"${_PREREQ_RESUME[@]}"}; do
        _collect_prereqs_from "$_p"
      done
      for _f in "${TASK_FILES[@]}"; do
        _collect_prereqs_from "$_f"
      done
      [ ${#_PREREQ_RESUME[@]} -eq "$_before" ] && [ "$_PREREQ_ROUTED" -eq "$_before_routed" ] && break
    done
    if [ "$_PREREQ_ROUTED" -gt 0 ] || [ ${#_PREREQ_RESUME[@]} -gt 0 ]; then
      echo ""
    fi
  fi
  unset _had_prereq_action _f _p _pass _before _before_routed
fi

# Prepend incomplete doing/ prereqs so they launch before their dependents.
if [ ${#_PREREQ_RESUME[@]} -gt 0 ]; then
  TASK_FILES=("${_PREREQ_RESUME[@]}" "${TASK_FILES[@]}")
fi

# Broken / folded prereq references — surfaced even when no dep is "unmet" (the
# gate treats missing ids as complete so it can't wedge; this pass keeps that
# from being a silent green). Scan every queued task, including any doing/ prereq
# just prepended for resume.
for _f in "${TASK_FILES[@]}"; do
  _scan_broken_deps_from "$_f"
done
if [ ${#_PREREQ_FOLDED[@]} -gt 0 ]; then
  echo "⚠ Prerequisite(s) folded into another id — update **Depends on**:"
  for _b in "${_PREREQ_FOLDED[@]}"; do echo "    ${_b}"; done
  echo "  The edge still points at a retired id; repoint it at the fold target."
  echo ""
fi
if [ ${#_PREREQ_BROKEN[@]} -gt 0 ]; then
  echo "⚠ Broken prerequisite reference(s) — no such task (not a silent green):"
  for _b in "${_PREREQ_BROKEN[@]}"; do echo "    ${_b}"; done
  echo "  Fix the **Depends on** id, or ./sprint.sh chat the referencing task."
  echo ""
fi
unset _f _b _seen_broken

# Dependency-waiting banner (informational — scheduler still holds them).
_waiting=()
for _f in "${TASK_FILES[@]}"; do
  # Skip resume paths under doing/ for the "on hold" banner — those execute.
  case "$_f" in
    "$WORKING_DIR"/*) continue ;;
  esac
  _clause="$(_needs_clause "$_f")"
  [ -n "$_clause" ] && _waiting+=("${_f##*/}  (needs: ${_clause})")
done
if [ ${#_waiting[@]} -gt 0 ]; then
  echo "⏳ ${#_waiting[@]} dependent task(s) start on hold — released automatically"
  echo "   as those prerequisites land in review/ during this run:"
  for _w in "${_waiting[@]}"; do echo "    ${_w}"; done
  echo ""
fi
if [ ${#_PREREQ_ADVICE[@]} -gt 0 ]; then
  echo "⚠ Prerequisite(s) outside the sprint (not auto-lifted):"
  for _a in "${_PREREQ_ADVICE[@]}"; do echo "    ${_a}"; done
  echo "  Backlog tasks are assumed not fully vetted — chat them to define/promote."
  echo ""
fi
unset _waiting _f _w _a _clause _seen_resume _seen_advice

# COUNT is the launch cap for this pass (how many tasks may execute). It bounds
# the scheduler below; a run may execute fewer if some dependents stay on hold
# for prerequisites that never land this pass. loop.sh passes MAX_TASKS=1 to
# run a single task per iteration — that still holds here.
COUNT=${#TASK_FILES[@]}
if [ "$COUNT" -gt "$MAX_TASKS" ]; then
  COUNT=$MAX_TASKS
fi

_resume_n=${#_PREREQ_RESUME[@]}
if [ "$_resume_n" -gt 0 ]; then
  echo "▸ up to $COUNT task(s) queued ($((COUNT > _resume_n ? COUNT - _resume_n : 0)) from $NEXT_DIR, $_resume_n resumed from $WORKING_DIR)"
else
  echo "▸ up to $COUNT task(s) queued from $NEXT_DIR"
fi
[ "$_PREREQ_ROUTED" -gt 0 ] && echo "  ($_PREREQ_ROUTED prerequisite(s) already complete — routed to $REVIEW_DIR/)"
echo ""
unset _resume_n

# Nothing to execute (empty queue, or launch cap 0 after prereq routing only).
if [ "$COUNT" -eq 0 ]; then
  if [ "${_PREREQ_ROUTED:-0}" -gt 0 ]; then
    echo "▸ No tasks launched this pass — prerequisites were resolved; run work again to continue."
  else
    echo "▸ No tasks to launch this pass."
  fi
  exit 0
fi

# Deterministic cleanup at run time: strip the task template's authoring
# scaffolding (section guidance comments, the after-work Completed how-to block,
# the AI footer) from every task about to be worked, in both emit and exec
# modes. The comments have done their authoring job by now; removing them here
# keeps them out of the worked task and off every later reader's context.
for ((_i = 0; _i < COUNT; _i++)); do
  sprintbias_scrub_template_scaffold "${TASK_FILES[$_i]}" || true
done
unset _i

if [ "$VERBOSE" -eq 1 ]; then
  for ((i=0; i<COUNT; i++)); do
    _vf="${TASK_FILES[$i]}"
    _vn="${_vf##*/}"
    echo "──────────────────────────────────────────────────────────"
    echo "  $((i + 1))/$COUNT: $_vn"
    echo "──────────────────────────────────────────────────────────"
    sed 's/^/  /' "$_vf"
    echo ""
  done
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
fi

# ── Runner ──────────────────────────────────────────────────────────

COMPLETED=0
FAILED=0
INCOMPLETE=0
BLOCKERS=0
HARD_FAIL=0
TOTAL_START=$SECONDS
# Quality chain lives in polish.sh: --code = correctness, bare path = deep-judge.
POLISH_SCRIPT="$(dirname "${BASH_SOURCE[0]}")/polish.sh"

# Read **Tests** (legacy **Proven by**) from a task file — empty means none.
_task_tests_value() {
  local v
  v=$( { grep -m1 -iE '^\*\*Tests\*\*:' "$1" 2>/dev/null || true; } \
    | sed 's/^[^:]*://; s/^[[:space:]]*//; s/[[:space:]]*$//' )
  if [ -z "$v" ]; then
    v=$( { grep -m1 -iE '^\*\*Proven by\*\*:' "$1" 2>/dev/null || true; } \
      | sed 's/^[^:]*://; s/^[[:space:]]*//; s/[[:space:]]*$//' )
  fi
  printf '%s' "$v"
}

# After the queue: tell the human what needs eyes (and when promote can help).
_report_human_review() {
  local name path tests id human=0 promo=0
  [ ${#TO_REVIEW[@]} -eq 0 ] && return 0
  echo ""
  echo "▸ Requires human review (${#TO_REVIEW[@]} landed in $REVIEW_DIR/ this run):"
  for name in "${TO_REVIEW[@]}"; do
    path="$REVIEW_DIR/$name"
    [ -f "$path" ] || continue
    id=$(printf '%s' "$name" | grep -oE '^[0-9]+' || true)
    tests="$(_task_tests_value "$path")"
    if [ -z "$tests" ] || [ "$(printf '%s' "$tests" | tr '[:upper:]' '[:lower:]')" = "none" ]; then
      human=$((human + 1))
      echo "    $name"
      echo "      Tests: none — human sign-off before done/"
      echo "      → git mv $REVIEW_DIR/$name docs/tasks/done/$name || mv $REVIEW_DIR/$name docs/tasks/done/$name"
    else
      promo=$((promo + 1))
      echo "    $name"
      echo "      Tests: $tests"
      echo "      → ./sprint.sh promote ${id:-}   # suite green → done/ (still your call to run)"
    fi
  done
  if [ "$human" -gt 0 ] || [ "$promo" -gt 0 ]; then
    echo "  Review is not blocked/ — implementation is done; close is human (or promote)."
  fi
  echo ""
}

# After the queue: recap every task that did NOT complete (fail/incomplete/
# drift-blocked). The reason and location are already stamped and printed
# inline mid-run, but a long parallel run scrolls them off-screen — this
# repeats them at the end with the AI-assisted rework command, so a bare
# "N failed" count is never the only thing the human is left holding.
_report_failures() {
  local rec name result dir reason id
  [ ${#TO_FAIL[@]} -eq 0 ] && return 0
  echo ""
  echo "▸ Needs your attention (${#TO_FAIL[@]} did not complete this run):"
  for rec in "${TO_FAIL[@]}"; do
    IFS="$FAIL_DELIM" read -r name result dir reason <<< "$rec"
    id=$(printf '%s' "$name" | grep -oE '^[0-9]+' || true)
    echo "    $name  [$result]"
    [ -n "$reason" ] && echo "      Why:   $reason"
    echo "      Where: $dir/$name"
    [ "$result" = "failed" ] && echo "      Log:   $LOG_DIR/log-work-${name%.md}-*.json"
    echo "      → ./sprint.sh chat ${id:-$name}   # rework or redefine with AI assistance"
  done
  echo "  Not review/ — these need a redefine or fix before they can re-run."
  echo ""
}

_model_args=();  [ -n "$MODEL" ] && _model_args=(--model "$MODEL")
# Budget rides only on a tier that can enforce a USD cap (today Claude Code).
# Elsewhere the cap is omitted at source, so no provider is handed a spending
# limit it cannot honor. See sprintbias_budget_capable in lib.sh.
_budget_args=()
if sprintbias_budget_capable && [ -n "${SPRINTBIAS_BUDGET_WORK:-}" ]; then
  _budget_args=(--budget "$SPRINTBIAS_BUDGET_WORK")
fi

# Shared execution rules — exec + emit worker (one string). Action-bias:
# conversation.md / polish — standards decide → ## Completed.
_TASK_RULES="- Implement the Success criteria. Prefer project conventions and
  clear best practice; pick a sensible default and finish. Prerequisites in
  review/ or done/ are complete.
- Prior '## Outcome': fix its Reason, then finish.
- Scope: files relevant to this task. Grep/Glob, Edit/Write, test what you touched.
- Done: check off items; ## Completed with '### Files changed' (one repo-relative
  path per product file you created or modified).
- Product/scope fork that needs a human: one-line ## Outcome Reason, then stop.
  Otherwise ## Completed.
- git commit / ./ship.sh when the human asks in this conversation; otherwise
  ## Completed and stop."

# Emit orchestrator goal (fan-out + sequential).
_WORKER_GOAL="Land each task ## Completed → review/. Choose best practice and finish.
Product/scope fork that needs a human: ## Outcome, then blocked/."

# Build the execution prompt for a task file at a given path (exec mode).
_task_prompt() {
  local path="$1" content profile_line
  content=$(<"$path")
  profile_line="$(sprintbias_profile_line)"
  cat <<PROMPT
You are executing ONE task from the project queue.
CLAUDE.md is auto-loaded.${profile_line}
Task file: $path

TASK:
---
$content
---

Rules:
$_TASK_RULES
PROMPT
}

# ── Emit mode: hand the queue to the surrounding agent ───────────────
# On orchestration-capable tiers (claude-code Task tool; grok-build
# spawn_subagent) we emit a parallel plan: one FRESH subagent per task so
# contexts never mix. Other tiers get the honest sequential fallback. Same
# routing rules either way so behavior can't drift.
if [ "$AI_MODE" = "emit" ]; then
  _profile_line="$(sprintbias_profile_line)"

  _task_list=""
  for ((i=0; i<COUNT; i++)); do
    _tf="${TASK_FILES[$i]}"
    _tn="${_tf##*/}"
    case "$_tf" in
      "$WORKING_DIR"/*)
        _task_list="${_task_list}
- $_tf  (already in doing/ — RESUME unfinished work; do not re-gate)"
        ;;
      *)
        _task_list="${_task_list}
- $_tf"
        ;;
    esac
  done
  unset _tf _tn

  _jobs_hint="in parallel, a few at a time"
  [ "$PARALLEL" -eq 1 ] && _jobs_hint="in parallel, up to $MAX_JOBS at a time"

  _audit_step=""
  [ "$RUN_AUDIT" -eq 1 ] && _audit_step="
   c. If it landed in review/, run: ./sprint.sh polish --code docs/tasks/review/<name>"

  # Deep-judge (polish <file>) presumes correctness, so it runs AFTER the
  # code audit. A BLOCKER verdict does not halt the queue — file stays in review/.
  _excellence_step=""
  [ "$RUN_EXCELLENCE" -eq 1 ] && _excellence_step="
   d. If it landed in review/, run: ./sprint.sh polish docs/tasks/review/<name>
      (leave it in review/ even if the verdict is BLOCKER)"

  _dep_order_note="
Dependency order: only start a task when every '**Depends on**' id is in
review/ or done/ (or absent from disk). Prefer lowest-ID runnable first.
If a listed path is already under doing/, it is a RESUME — work it in place
(do not move from next/). Prerequisites still in backlog/ or blocked/ are
NOT auto-lifted; leave their dependents in next/ and tell the user to run
./sprint.sh chat <id>."

  # Shared closing-report spec. Both emit prompts (orchestrated + sequential)
  # end with this so their summary matches, in shape, what work prints in exec
  # mode (_report_human_review + _report_failures). One source so a user gets
  # the same '▸ Needs your attention' recap whichever mode ran — emit no longer
  # drops the failure recap that exec produces.
  _EMIT_REPORT="When every task has been routed, print a final summary in exactly this
shape (it must match what work prints in exec mode, so the user sees the same
report whichever mode ran). Omit any section that has no tasks.

▸ Done: <N> completed, <N> failed, <N> incomplete, <N> skipped

For each task now in review/ (implementation done — needs a human to close):
▸ Requires human review (<N> landed in docs/tasks/review/ this run):
    <name>
      Tests: none — human sign-off before done/
      → git mv docs/tasks/review/<name> docs/tasks/done/<name> || mv docs/tasks/review/<name> docs/tasks/done/<name>
  (when that task's Tests field names suite scripts instead, replace the two
   lines under it with:)
      Tests: <path>
      → ./sprint.sh promote <id>   # suite green → done/ (still your call to run)
  Review is not blocked/ — implementation is done; close is human (or promote).

For each task that did NOT complete (landed in blocked/, or a hard fail left in doing/):
▸ Needs your attention (<N> did not complete this run):
    <name>  [failed|incomplete|blocked]
      Why:   <the one-line Reason from that task's ## Outcome stamp>
      Where: <docs/tasks/blocked/<name>, or docs/tasks/doing/<name> for a hard fail>
      → ./sprint.sh chat <id>   # rework or redefine with AI assistance
  Not review/ — these need a redefine or fix before they can re-run.

Use each task's numeric id for <id>."

  if sprintbias_orchestration_capable; then
    sprintbias_run -p "You are running the SprintBias task queue: $COUNT task(s) to execute.
CLAUDE.md / AGENTS.md is auto-loaded when present.${_profile_line}

Execute each task in $(sprintbias_subagent_own_fresh work) so tasks never share
context. Dispatch them $_jobs_hint. You are the orchestrator — the subagents
do the work, you move the files.

Always move with: git mv SRC DEST || mv SRC DEST (git mv first; plain mv finishes when untracked).
$_dep_order_note
$_WORKER_GOAL

For EACH task file listed below (honor dependency order):
1. If it is not already in doing/: move it — git mv <path> docs/tasks/doing/ || mv <path> docs/tasks/doing/
   If it is already in doing/, skip the move (resume in place).
2. Launch a subagent whose entire instruction is:
     \"Execute ONE task. Read the task file at docs/tasks/doing/<name> and do the work.
$(sprintbias_subagent_no_nest)
$_TASK_RULES\"
3. When the subagent returns, read docs/tasks/doing/<name> and route it:
   a. contains a '## Completed' section → first DELETE any stale '## Outcome'
      block left by a prior failed attempt (a completed task must not carry a
      contradictory failure stamp into review/), then git mv it to
      docs/tasks/review/ || mv it to docs/tasks/review/
      Then tell the user: Requires human review (or ./sprint.sh promote when **Tests** is set).
   b. otherwise → before moving, append a durable failure stamp to the file so
      every dependent's hold line can name the reason:
        ## Outcome
        **Result**: incomplete
        **Reason**: <one line — product/scope fork for a human, or hard-stop cause>
        **At**: <today, YYYY-MM-DD>
      then git mv it to docs/tasks/blocked/ || mv it to docs/tasks/blocked/${_audit_step}${_excellence_step}

Tasks (in order):$_task_list

$_EMIT_REPORT"
  else
    # Honest sequential fallback — no subagent tool assumed.
    sprintbias_run -p "You are running the SprintBias task queue: $COUNT task(s) to execute.
CLAUDE.md / AGENTS.md is auto-loaded when present.${_profile_line}

Work the tasks ONE AT A TIME, in dependency order (then lowest ID). You do not
have a subagent tool, so you are the worker, not an orchestrator — after
finishing each task, reset your focus and start the next one from a clean slate.

Always move with: git mv SRC DEST || mv SRC DEST (git mv first; plain mv finishes when untracked).
$_dep_order_note
$_WORKER_GOAL

For EACH task file listed below:
1. If it is not already in doing/: move it — git mv <path> docs/tasks/doing/ || mv <path> docs/tasks/doing/
   If it is already in doing/, skip the move (resume in place).
2. Read docs/tasks/doing/<name> and do the work:
$_TASK_RULES
3. Route it:
   a. you wrote a '## Completed' section → first DELETE any stale '## Outcome'
      block left by a prior failed attempt (a completed task must not carry a
      contradictory failure stamp into review/), then git mv it to
      docs/tasks/review/ || mv it to docs/tasks/review/
      Then tell the user: Requires human review (or ./sprint.sh promote when **Tests** is set).
   b. otherwise → before moving, append a durable failure stamp to the file so
      every dependent's hold line can name the reason:
        ## Outcome
        **Result**: incomplete
        **Reason**: <one line — product/scope fork for a human, or hard-stop cause>
        **At**: <today, YYYY-MM-DD>
      then git mv it to docs/tasks/blocked/ || mv it to docs/tasks/blocked/${_audit_step}${_excellence_step}

Tasks (in order):$_task_list

$_EMIT_REPORT"
  fi
  exit 0
fi

# ── exec helpers (shared by sequential and parallel) ─────────────────

# Live progress rendering is sprintbias_stream_filter (lib.sh) — one readable
# line per stream-json step, shared with plan think and any future streaming
# command so the renderer stays in lockstep.

# Run the AI on a task already in doing/. Requests the provider-neutral
# stream-json contract (NDJSON progress + Claude-shaped assistant/result
# events). Profiles translate: Claude keeps stream-json (+ --verbose);
# Grok maps to streaming-messages-json and drops Claude-only flags.
# Raw event log always lands in docs/tmp/; pass display=1 (sequential) to
# also render live progress on the terminal. Returns the CLI's exit code.
_run_task() {
  local name="$1" display="${2:-0}" log
  log="$(sprintbias_log_path work "$name")"
  if [ "$display" -eq 1 ]; then
    sprintbias_run -p "$(_task_prompt "$WORKING_DIR/$name")" \
      ${_model_args[@]+"${_model_args[@]}"} \
      ${_budget_args[@]+"${_budget_args[@]}"} \
      --tools "$TOOLS" \
      --permissions "$PERMISSIONS" \
      --output-format stream-json 2>&1 \
      | tee "$log" | sprintbias_stream_filter
  else
    sprintbias_run -p "$(_task_prompt "$WORKING_DIR/$name")" \
      ${_model_args[@]+"${_model_args[@]}"} \
      ${_budget_args[@]+"${_budget_args[@]}"} \
      --tools "$TOOLS" \
      --permissions "$PERMISSIONS" \
      --output-format stream-json > "$log" 2>&1
  fi
}

# Route a finished task (in doing/) to review/ or blocked/, update counters.
# Args: name  exit_code
_route_result() {
  local name="$1" rc="$2"
  if [ "$rc" -eq 0 ] && grep -q '^## Completed' "$WORKING_DIR/$name"; then
    if [ "$RUN_AUDIT" -eq 1 ] && [ -f "$POLISH_SCRIPT" ]; then
      echo "  ▸ Running code audit..."
      if bash "$POLISH_SCRIPT" --code "$WORKING_DIR/$name"; then
        echo "  ✓ Audit passed"
      else
        echo "  ⚠ Audit completed with warnings (see task file)"
      fi
    fi
    # Deep-judge (polish <file>) presumes correctness, so it runs AFTER the
    # code audit. It appends its own '## Excellence' section to the task file.
    # A BLOCKER verdict does NOT halt the queue — the task still routes to
    # review/; the blocker is only counted in the end-of-run summary. Detect
    # it by the appended verdict line, not the exit code: exit 1 also covers
    # the UNCLEAR/parse-failure case, which is not a blocker.
    if [ "$RUN_EXCELLENCE" -eq 1 ] && [ -f "$POLISH_SCRIPT" ]; then
      echo "  ▸ Running excellence audit..."
      if bash "$POLISH_SCRIPT" "$WORKING_DIR/$name"; then
        echo "  ✓ Excellence audit passed"
      else
        echo "  ⚠ Excellence audit completed with findings (see task file)"
      fi
      if grep -q '^- \*\*Verdict\*\*: BLOCKER' "$WORKING_DIR/$name"; then
        BLOCKERS=$((BLOCKERS + 1))
        echo "  ⚠ Excellence: BLOCKER recorded — routing to review/ for human attention"
      fi
    fi
    # Completed cleanly — drop any stale failure stamp from a prior attempt so
    # it doesn't ride into review/ contradicting the ## Completed section.
    _strip_outcome "$WORKING_DIR/$name"
    move_file "$WORKING_DIR/$name" "$REVIEW_DIR/$name"
    COMPLETED=$((COMPLETED + 1))
    _note_review "$name"
    echo "  ✓ Complete → $REVIEW_DIR/$name"
    echo "    Requires human review (or ./sprint.sh promote when **Tests** is set)"
  elif [ "$rc" -eq 0 ]; then
    # Ran to completion but never wrote ## Completed. Stamp only what we
    # observed — the section is missing — and name no cause, because nothing
    # here measured one. The wording is identical on every tier.
    _stamp_outcome "$WORKING_DIR/$name" incomplete \
      "run ended without a '## Completed' section"
    move_file "$WORKING_DIR/$name" "$BLOCKED_DIR/$name"
    INCOMPLETE=$((INCOMPLETE + 1))
    _note_fail "$name" incomplete "$BLOCKED_DIR" \
      "run ended without a '## Completed' section"
    echo "  ⚠ Incomplete — no '## Completed' section."
    echo "    → Moved to $BLOCKED_DIR/$name (## Outcome stamped: incomplete)"
  else
    # Hard fail: the CLI exited non-zero. Leave the file in doing/ for
    # inspection (loop's orphan sweep rescues it to blocked/), but stamp the
    # Outcome first so the failure is diagnosable and dependents can name it.
    _stamp_outcome "$WORKING_DIR/$name" failed \
      "task run exited non-zero (rc=$rc) — see docs/tmp/log-work-${name%.md}-*.json"
    FAILED=$((FAILED + 1))
    _note_fail "$name" failed "$WORKING_DIR" "CLI exited non-zero (rc=$rc)"
    HARD_FAIL=1
    echo "  ✗ Failed (exit $rc) — left in $WORKING_DIR/$name (## Outcome stamped: failed)"
    echo "    Log: docs/tmp/log-work-${name%.md}-*.json"
  fi
}

trap 'echo ""; [ -n "${TASK_NAME:-}" ] && echo "▸ Interrupted — current task left in $WORKING_DIR/$TASK_NAME" || echo "▸ Interrupted"; exit 130' INT TERM

# Recursively kill a process and all of its descendants. `_run_task` runs in a
# wrapper subshell whose PID we track, but the actual CLI child (and whatever it
# spawns) is a grandchild — killing only the tracked PID would orphan the CLI,
# leaving a zombie burning tokens. Walk the tree leaves-first so parents don't
# reap-and-replace before we reach the children.
_kill_tree() {
  local pid="$1" child
  for child in $(pgrep -P "$pid" 2>/dev/null || true); do
    _kill_tree "$child"
  done
  kill "$pid" 2>/dev/null || true
}

# _is_runnable FILE -> 0 if every declared dependency is complete (has reached
# review/ or done/, or was never a real task), 1 if it still waits on one. The
# check is filesystem-based (sprintbias_unmet_deps scans backlog/next/doing/blocked),
# so it is always current: re-calling it after a task routes to review/ is how a
# dependent releases mid-run. A task in doing/ (actively running) still reads as
# incomplete, so a dependent correctly waits until its prerequisite finishes.
# Resume paths already under doing/ are runnable w.r.t. their own file location
# (their Depends on still applies).
_is_runnable() { [ -z "$(sprintbias_unmet_deps "$1")" ]; }

# Ensure the task is in doing/ for execution. Resume paths already live there;
# next/ (or other) paths are moved in. Always prints the working path basename.
_ensure_in_doing() {
  local src="$1" name="${1##*/}"
  if [ "$src" != "$WORKING_DIR/$name" ]; then
    move_file "$src" "$WORKING_DIR/$name"
  fi
  printf '%s' "$name"
}

# Print any never-launched tasks passed as arguments (their next/ paths),
# splitting genuine dependency holds from tasks left only because the launch cap
# was hit. Positional-arg based — no bash-4 namerefs (this repo targets 3.2).
# Hold lines name each prereq's stage and the action (chat / wait / resume).
_report_held() {
  local f unmet _held_dep=() _held_cap=() _held_advice=() id stage clause
  local _adv_seen=" "
  for f in "$@"; do
    # Resume entries under doing/ that never launched are still open work, not
    # "left in next/" — report them separately via unmet on dependents.
    case "$f" in
      "$WORKING_DIR"/*)
        if [ -n "$(sprintbias_unmet_deps "$f")" ]; then
          _held_dep+=("${f##*/}  (needs: $(_needs_clause "$f"))  [resume still held]")
        else
          _held_cap+=("${f##*/}  [resume in doing/ — not started]")
        fi
        continue
        ;;
    esac
    unmet="$(sprintbias_unmet_deps "$f")"
    if [ -n "$unmet" ]; then
      clause="$(_needs_clause "$f")"
      _held_dep+=("${f##*/}  (needs: ${clause})")
      for id in $unmet; do
        stage="$(sprintbias_task_stage "$id" 2>/dev/null || true)"
        case "$stage" in
          backlog)
            case "$_adv_seen" in *" b$id "*) continue ;; esac
            _adv_seen="$_adv_seen b$id "
            _held_advice+=("This task depends on $id, which is still in backlog/. Consider: ./sprint.sh chat $id")
            ;;
          blocked)
            case "$_adv_seen" in *" x$id "*) continue ;; esac
            _adv_seen="$_adv_seen x$id "
            _held_advice+=("This task depends on $id, which still needs a decision in blocked/. Consider: ./sprint.sh chat $id")
            ;;
        esac
      done
    else
      _held_cap+=("${f##*/}")
    fi
  done
  if [ ${#_held_dep[@]} -gt 0 ]; then
    echo "⏳ ${#_held_dep[@]} dependent task(s) on hold (unfinished prerequisites) — left in $NEXT_DIR/:"
    for f in "${_held_dep[@]}"; do echo "    ${f}"; done
    echo "  They run automatically once those dependencies reach review/ or done/."
    echo ""
  fi
  if [ ${#_held_advice[@]} -gt 0 ]; then
    echo "⚠ Prerequisite(s) outside the sprint (not auto-lifted):"
    for f in "${_held_advice[@]}"; do echo "    ${f}"; done
    echo "  Backlog tasks are assumed not fully vetted — chat them to define/promote."
    echo ""
  fi
  if [ ${#_held_cap[@]} -gt 0 ]; then
    echo "▸ ${#_held_cap[@]} runnable task(s) not started — launch cap reached. Run again to continue."
    echo ""
  fi
}

# ── Parallel runner ────────────────────────────────────────────────
# Dependency-aware job pool. Unlike a fixed index sweep, this only launches a
# task whose prerequisites are already complete, moves it to doing/ AT launch
# time (a task still waiting stays in next/, where dependents correctly read it
# as incomplete), and routes each finished task IMMEDIATELY — so a dependent
# becomes launchable the moment its prerequisite lands in review/, all within
# this one run. Sequential order among ready tasks is preserved (lowest ID first).
if [ "$PARALLEL" -eq 1 ]; then

  NTASK=${#TASK_FILES[@]}
  STATE=(); PIDS=()                       # STATE[i]: 0 pending, 1 running, 2 done
  for ((i=0; i<NTASK; i++)); do STATE+=(0); PIDS+=(0); done

  # Interrupt handling. Kill the whole process tree of every running task (the
  # CLI child is a grandchild of the tracked wrapper PID and would otherwise
  # orphan). Running tasks stay in doing/ for inspection — loop.sh's orphan
  # sweep rescues them; pending tasks were never moved, so they remain in next/.
  # shellcheck disable=SC2154
  trap '
    echo ""; echo "▸ Interrupted — killing background tasks..."
    for p in "${PIDS[@]}"; do [ "$p" -ne 0 ] && _kill_tree "$p"; done
    wait 2>/dev/null
    echo "▸ In-progress tasks left in $WORKING_DIR/ (loop rescues them); pending tasks remain in $NEXT_DIR/"
    exit 130' INT TERM

  LAUNCHED=0; RUNNING=0

  # Launch lowest-ID pending+runnable tasks while a slot and the cap remain.
  _try_launch() {
    local idx j name
    while [ "$RUNNING" -lt "$MAX_JOBS" ] && [ "$LAUNCHED" -lt "$COUNT" ]; do
      idx=-1
      for ((j=0; j<NTASK; j++)); do
        [ "${STATE[$j]}" -eq 0 ] || continue
        if _is_runnable "${TASK_FILES[$j]}"; then idx=$j; break; fi
      done
      [ "$idx" -lt 0 ] && break          # nothing runnable right now
      name="$(_ensure_in_doing "${TASK_FILES[$idx]}")"
      TASK_FILES[$idx]="$WORKING_DIR/$name"
      _run_task "$name" &
      PIDS[$idx]=$!
      STATE[$idx]=1
      RUNNING=$((RUNNING + 1)); LAUNCHED=$((LAUNCHED + 1))
      echo "  ▸ Launched $LAUNCHED/$COUNT: $name"
    done
  }

  echo "▸ Running up to $COUNT task(s), --jobs $MAX_JOBS (dependency-aware)..."
  echo ""
  _try_launch
  if [ "$RUNNING" -eq 0 ]; then
    echo "  (no tasks are currently runnable — all remaining wait on unfinished dependencies)"
  fi
  echo ""

  # Poll for completions; route each immediately, then try to launch more so
  # dependents released from hold start without waiting for the whole batch.
  while [ "$RUNNING" -gt 0 ]; do
    _progressed=0
    for ((i=0; i<NTASK; i++)); do
      if [ "${STATE[$i]}" -eq 1 ] && ! kill -0 "${PIDS[$i]}" 2>/dev/null; then
        _rc=0
        wait "${PIDS[$i]}" 2>/dev/null && _rc=0 || _rc=$?
        STATE[$i]=2
        RUNNING=$((RUNNING - 1))
        _elapsed=$((SECONDS - TOTAL_START))
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "▸ Finished ${TASK_FILES[$i]##*/} (${_elapsed}s)"
        _route_result "${TASK_FILES[$i]##*/}" "$_rc"
        echo ""
        _progressed=1
      fi
    done
    [ "$_progressed" -eq 1 ] && _try_launch
    [ "$RUNNING" -gt 0 ] && sleep 3
  done

  # Report anything never launched (dependency-held, or cap reached).
  _undone=()
  for ((i=0; i<NTASK; i++)); do
    [ "${STATE[$i]}" -eq 2 ] || _undone+=("${TASK_FILES[$i]}")
  done
  [ ${#_undone[@]} -gt 0 ] && _report_held "${_undone[@]}"

# ── Sequential runner (default) ───────────────────────────────────
# Dependency-aware, one task at a time. Each pass picks the lowest-ID task that
# is not yet done and whose prerequisites are complete, so a chain queued in the
# same run drains here too: A runs and lands in review/, then B becomes runnable
# on the very next pick. Undefined/blocked-dependency tasks are simply never
# picked and reported at the end. --fast (above) is what overlaps independents.
else

DONE_FLAG=()
for ((i=0; i<${#TASK_FILES[@]}; i++)); do DONE_FLAG+=(0); done
LAUNCHED=0

while [ "$LAUNCHED" -lt "$COUNT" ]; do
  # Pick the lowest-ID pending, runnable task.
  _pick=-1
  for ((i=0; i<${#TASK_FILES[@]}; i++)); do
    [ "${DONE_FLAG[$i]}" -eq 0 ] || continue
    if _is_runnable "${TASK_FILES[$i]}"; then _pick=$i; break; fi
  done
  [ "$_pick" -lt 0 ] && break             # nothing runnable remains

  i=$_pick
  TASK_FILE="${TASK_FILES[$i]}"
  TASK_NAME="$(_ensure_in_doing "$TASK_FILE")"
  TASK_FILES[$i]="$WORKING_DIR/$TASK_NAME"
  DONE_FLAG[$i]=1
  LAUNCHED=$((LAUNCHED + 1))
  N=$LAUNCHED
  TASK_START=$SECONDS

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "▸ Task $N/$COUNT: $TASK_NAME"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  TASK_CONTENT=$(<"$WORKING_DIR/$TASK_NAME")

  # ── Pre-work drift check (opt-in via --drift) ──────────────────────
  if [ "${SPRINTBIAS_SKIP_DRIFT_CHECK:-}" != "1" ]; then
    echo "  ▸ Drift check..."

    _drift_model="$(sprintbias_tier_model DRIFT)"
    _drift_model_args=()
    [ -n "$_drift_model" ] && _drift_model_args=(--model "$_drift_model")

    DRIFT_PROMPT="You are checking whether a task is still relevant before it gets worked.

CLAUDE.md is auto-loaded with project context and conventions.

Read the task file at: $WORKING_DIR/$TASK_NAME

Then check the current codebase to determine:
- Has this work ALREADY been completed? (the features/fixes described exist)
- Does the task reference files, patterns, or APIs that no longer exist?

If the task is OUTDATED, try to fix it:
- Identify what changed (renamed files, moved APIs, refactored code)
- Update the task file with corrected references and adjusted action items
- After editing the file, list the fixes you made as bullet points

Output EXACTLY ONE of these verdicts on the LAST line of your response:

COMPLETE - The work is already present in the codebase (nothing left to implement; not the done/ folder)
FIXED - The task was outdated but you updated the file with corrections
OUTDATED - The task is outdated and you cannot resolve the drift
PROCEED - The task is still relevant and ready to work

Rules:
- Be conservative: if in doubt, say PROCEED
- COMPLETE means the specific work is clearly already present in the codebase (not docs/tasks/done/)
- FIXED means you edited the task file to account for codebase drift
- OUTDATED means the drift is too severe for you to fix — needs human rewrite
- Before your verdict, list any fixes you made as bullet points (for FIXED)"

    DRIFT_VERDICT=$(run_with_timeout "$DRIFT_TIMEOUT" sprintbias_run -p "$DRIFT_PROMPT" \
      "${_drift_model_args[@]}" \
      --tools "Read,Edit,Write,Grep,Glob,Bash" \
      --skip-permissions \
      --max-turns 20 2>/dev/null) || true

    _drift_action=$(echo "$DRIFT_VERDICT" | grep -oE '\b(COMPLETE|DONE|FIXED|OUTDATED|PROCEED)\b' | tail -1 || true)
    [ "$_drift_action" = "DONE" ] && _drift_action="COMPLETE"
    [ -z "$_drift_action" ] && _drift_action="PROCEED"

    case "$_drift_action" in
      COMPLETE)
        _drift_reason=$(echo "$DRIFT_VERDICT" | grep -iE 'complete|done' | head -1)
        echo "  ✓ Drift check: COMPLETE (work already in codebase) — $_drift_reason"
        echo "    → Moving to review/"
        # Same invariant as the success route in _route_result: a task that
        # lands in review/ must not carry a stale failure ## Outcome.
        _strip_outcome "$WORKING_DIR/$TASK_NAME"
        move_file "$WORKING_DIR/$TASK_NAME" "$REVIEW_DIR/$TASK_NAME"
        COMPLETED=$((COMPLETED + 1))
        _note_review "$TASK_NAME"
        echo "    Requires human review (or ./sprint.sh promote when **Tests** is set)"
        echo ""
        continue
        ;;
      FIXED)
        echo "  ⚠ Drift check: task was outdated — fixes applied."
        echo ""
        _updated_content=$(<"$WORKING_DIR/$TASK_NAME")
        _diff_output=$(diff --unified=2 <(echo "$TASK_CONTENT") <(echo "$_updated_content") || true)
        if [ -n "$_diff_output" ]; then
          echo "  Changes made to task file:"
          echo "$_diff_output" | head -40 | sed 's/^/    /'
          echo ""
        fi
        _drift_explanation=$(echo "$DRIFT_VERDICT" | sed '/^[[:space:]]*FIXED[[:space:]]*$/d' | tail -20)
        if [ -n "$_drift_explanation" ]; then
          echo "  AI reasoning:"
          echo "$_drift_explanation" | sed 's/^/    /'
          echo ""
        fi
        echo "  Updated task: $WORKING_DIR/$TASK_NAME"
        echo ""
        echo "  1) Looks good, work the task"
        echo "  2) Move to blocked for manual review"
        echo ""
        printf "  Choice [1/2] (auto-proceeds in 15s): "
        if read -r -t 15 _drift_choice </dev/tty 2>/dev/null; then :; else _drift_choice="1"; echo "1"; fi
        case "$_drift_choice" in
          2)
            echo "    → Moving to $BLOCKED_DIR/$TASK_NAME"
            _stamp_outcome "$WORKING_DIR/$TASK_NAME" blocked \
              "drift check flagged codebase drift; sent to manual review"
            move_file "$WORKING_DIR/$TASK_NAME" "$BLOCKED_DIR/$TASK_NAME"
            _note_fail "$TASK_NAME" blocked "$BLOCKED_DIR" \
              "drift check flagged codebase drift; sent to manual review"
            echo ""
            continue
            ;;
          *)
            echo "    → Proceeding with updated task"
            ;;
        esac
        ;;
      OUTDATED)
        _drift_reason=$(echo "$DRIFT_VERDICT" | grep -i 'outdated' | head -1)
        echo "  ✗ Drift check: outdated — $_drift_reason"
        echo "    → Moving to $BLOCKED_DIR/$TASK_NAME (needs decision or clarification)"
        _stamp_outcome "$WORKING_DIR/$TASK_NAME" blocked \
          "drift check: outdated — ${_drift_reason:-references stale codebase}"
        move_file "$WORKING_DIR/$TASK_NAME" "$BLOCKED_DIR/$TASK_NAME"
        echo ""
        continue
        ;;
      *)
        echo "  ✓ Drift check: proceed"
        ;;
    esac
  fi

  # '|| _rc=$?' keeps set -e from killing the whole queue on a CLI error —
  # the result must reach _route_result so the task gets routed and reported.
  _rc=0
  _run_task "$TASK_NAME" 1 || _rc=$?
  _route_result "$TASK_NAME" "$_rc"

  TASK_ELAPSED=$((SECONDS - TASK_START))
  echo "⏱ Elapsed: $((TASK_ELAPSED / 60))m $((TASK_ELAPSED % 60))s"
  echo ""

  # Stop the queue on a genuine crash (non-zero exit with no turn cap).
  [ "$HARD_FAIL" -eq 1 ] && break
done

# Report anything never picked (dependency-held, or cap reached).
_undone=()
for ((i=0; i<${#TASK_FILES[@]}; i++)); do
  [ "${DONE_FLAG[$i]}" -eq 1 ] || _undone+=("${TASK_FILES[$i]}")
done
[ ${#_undone[@]} -gt 0 ] && _report_held "${_undone[@]}"

fi # end parallel/sequential branch

TOTAL_ELAPSED=$((SECONDS - TOTAL_START))
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# "skipped" = tasks left in next/ this pass (held on deps, or beyond the launch
# cap) = defined tasks minus those that executed. Uses the full defined set, not
# COUNT, so held dependents are counted even when the cap was not the limiter.
_done_extra=""
[ "${_PREREQ_ROUTED:-0}" -gt 0 ] && _done_extra=" (${_PREREQ_ROUTED} prereq(s) auto-routed from doing/)"
echo "▸ Done: $COMPLETED completed, $FAILED failed, $INCOMPLETE incomplete, $(( ${#TASK_FILES[@]} - COMPLETED - FAILED - INCOMPLETE )) skipped — total $((TOTAL_ELAPSED / 60))m $((TOTAL_ELAPSED % 60))s${_done_extra}"
unset _done_extra
_report_human_review
_report_failures
# `if`, not `&&`: this is the script's last statement, and a false `[ ]` on a
# blocker-free run would become the script's non-zero exit status.
if [ "$BLOCKERS" -gt 0 ]; then
  echo "  ⚠ $BLOCKERS excellence blocker(s) recorded — inspect the '## Excellence' section in review/ before merging"
fi
