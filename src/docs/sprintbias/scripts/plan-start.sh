#!/usr/bin/env bash
# plan-start.sh — Commit a plan's members into next/ (the sprint).
# See: ./sprint.sh help plan
#
# Invoked as: ./sprint.sh plan start [id] [--commit-only]
#
# next/ IS the sprint. Workability is decided before a member is runnable: each
# backlog member is run through the shared workability gate (gate-lib.sh — same
# code `./sprint.sh gate` runs). READY → stamp + next/; BLOCKED → blocked/;
# COMPLETE → review/. --commit-only skips the gate for pure backlog→next mv.
#
# Dependency workability (structural, both gated and --commit-only): a member
# may enter next/ only when every **Depends on** prerequisite is already in the
# sprint (next/ or doing/), finished (review/ or done/), or co-promoted in this
# same start. A dep still in backlog/ or blocked/ that is not itself being
# promoted makes the dependent unworkable — it stays in backlog/ (or is demoted
# from next/). Definition clarity alone is not enough.
#
# Size: promote EVERY listed member that is workable — no hard cap on plan size.
# A soft warning prints when the plan has more than 10 members (still promotes
# all workable ones). Plans are free to be larger; the warning is a nudge, not
# a gate.
#
# Misplaced members in next/ (no READY stamp): demote to backlog/ so a bad mv
# is self-healing. Default mode then gates them with everyone else; --commit-only
# leaves them in backlog (not re-promoted unvetted).
#
# Plan-file Status: interactive DRAFT auto-marks READY; STARTED re-runs without
# a prompt; non-interactive requires READY (loop --refill). Moves use move_file
# (git mv || mv); developer owns commits.

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"
# Shared workability review — same implementation as `./sprint.sh gate`. Both
# surfaces call one library so their verdicts and rules never drift.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/gate-lib.sh"

PLANS_DIR="docs/plans"
BACKLOG_DIR="docs/tasks/backlog"
NEXT_DIR="docs/tasks/next"
BLOCKED_DIR="docs/tasks/blocked"
REVIEW_DIR="docs/tasks/review"

# ── Args: plan id (any position) + optional --commit-only ────────────
COMMIT_ONLY=0
PLAN_ID=""
for _arg in "$@"; do
  case "$_arg" in
    --commit-only) COMMIT_ONLY=1 ;;
    *) [ -z "$PLAN_ID" ] && PLAN_ID="$_arg" ;;
  esac
done
unset _arg

# ── Plan helpers ─────────────────────────────────────────────────────

list_plans() { sprintbias_list_plans; }
find_plan() { sprintbias_find_plan "$1"; }

plan_status() {
  grep -m1 -E '^\*\*Status:\*\*' "$1" 2>/dev/null \
    | sed 's/.*\*\*Status:\*\*[[:space:]]*//' | tr -d '[:space:]' || true
}

# STARTED latch: set-or-replace the **Status:** line to STARTED (one-way).
# Idempotent — re-running plan start just re-stamps the single status line; it
# never appends a duplicate. Set regardless of how many members moved this run,
# because STARTED means "this plan has been committed to the sprint," not
# "members moved just now." Only DRAFT | READY are ever replaced here.
stamp_started() {
  local f="$1"
  if grep -qE '^\*\*Status:\*\*' "$f" 2>/dev/null; then
    sed_inplace 's/^\*\*Status:\*\*.*/**Status:** STARTED/' "$f"
  else
    # No status line at all (malformed plan) — append one; plan_status reads the
    # first match, so a single appended line still reports STARTED.
    printf '\n**Status:** STARTED\n' >> "$f"
  fi
}

# Flip plan **Status:** to READY (set-or-replace, never append a second line).
# Used when interactive plan start confirms a DRAFT plan is startable.
stamp_ready() {
  local f="$1"
  if grep -qE '^\*\*Status:\*\*' "$f" 2>/dev/null; then
    sed_inplace 's/^\*\*Status:\*\*.*/**Status:** READY/' "$f"
  else
    printf '\n**Status:** READY\n' >> "$f"
  fi
}

# Extract ## Goal body (until next ## heading), HTML comments stripped, first
# non-empty lines collapsed. Guidance comments in the section are ignored so
# only the author's prose is returned.
plan_goal_text() {
  local f="$1"
  awk '
    BEGIN{g=0; c=0}
    /^## Goal/{g=1; next}
    g && /^## /{exit}
    !g{next}
    {
      line=$0
      while (1) {
        if (c) {
          idx=index(line, "-->")
          if (idx==0) { line=""; break }
          line=substr(line, idx+3); c=0
        } else {
          idx=index(line, "<!--")
          if (idx==0) break
          rest=substr(line, idx+4)
          cidx=index(rest, "-->")
          if (cidx==0) { line=substr(line,1,idx-1); c=1; break }
          line=substr(line,1,idx-1) substr(rest, cidx+3)
        }
      }
      gsub(/^[ \t]+|[ \t]+$/, "", line)
      if (length(line)) print line
    }
  ' "$f" | head -5 | tr '\n' ' ' | sed 's/[[:space:]]\{1,\}/ /g; s/^ //; s/ $//'
}

# Find task file by id across all stages. Prints "path<TAB>stage" or returns 1.
resolve_member() {
  local id="$1" stage dir match
  for stage in backlog next doing blocked review done; do
    dir="docs/tasks/$stage"
    match=$(find "$dir" -maxdepth 1 -name "${id}-*.md" 2>/dev/null | head -1) || true
    if [ -n "$match" ]; then
      printf '%s\t%s' "$match" "$stage"
      return 0
    fi
  done
  return 1
}

# ── Pick / resolve plan ──────────────────────────────────────────────

if [ -z "$PLAN_ID" ]; then
  echo "▸ plan start — pick a plan to commit into next/"
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
    printf "Plan id to start (or blank to cancel): "
    read -r PLAN_ID </dev/tty 2>/dev/null || PLAN_ID=""
  else
    echo "Usage: ./sprint.sh plan start <id>"
    exit 1
  fi
  [ -n "$PLAN_ID" ] || { echo "Cancelled."; exit 0; }
fi

if ! [[ "$PLAN_ID" =~ ^[0-9]+$ ]]; then
  echo "Error: '$PLAN_ID' is not a plan id."
  echo "Usage: ./sprint.sh plan start [id]   # plan id, not a task id"
  exit 1
fi

if ! PLAN_FILE="$(find_plan "$PLAN_ID")"; then
  echo "Error: No plan found with ID $PLAN_ID in $PLANS_DIR/"
  echo "Existing plans:"
  list_plans
  exit 1
fi

STATUS="$(plan_status "$PLAN_FILE")"
[ -n "$STATUS" ] || STATUS="(none)"

echo "▸ Starting plan: $(basename "$PLAN_FILE")"
echo "  Status: $STATUS"
echo ""

# Plan-file **Status:** READY is the autonomy latch for loop --refill.
# Explicit plan start always means "commit this plan":
#   STARTED  → re-run is safe (heal misplaced next/, gate remaining backlog)
#   READY    → proceed
#   DRAFT/…  → interactive: auto-mark READY (start *is* the confirm);
#              non-interactive: refuse (loop only starts READY plans)
case "$STATUS" in
  READY) ;;
  STARTED)
    echo "  Plan already STARTED — checking members."
    echo ""
    ;;
  *)
    if [ -t 0 ] && [ -t 1 ]; then
      stamp_ready "$PLAN_FILE"
      echo "  Marking plan READY and starting (was $STATUS)."
      STATUS="READY"
      echo ""
    else
      echo "⚠ Plan is not marked READY (status: $STATUS)."
      echo "  Author/refine with: ./sprint.sh chat plan $PLAN_ID"
      echo "  Non-interactive start requires **Status:** READY (loop --refill only starts READY plans)."
      exit 1
    fi
    ;;
esac

# ── Collect members ──────────────────────────────────────────────────
# Every listed member is in scope — no hard cap. Soft warn only when large.

MEMBER_IDS=$(grep -oE '^- (\[[ xX]\] )?#[0-9]+' "$PLAN_FILE" 2>/dev/null | grep -oE '[0-9]+' | awk '!seen[$0]++' || true)
if [ -z "$MEMBER_IDS" ]; then
  echo "Plan $PLAN_ID has no member tasks."
  echo "Add members with: ./sprint.sh chat plan $PLAN_ID"
  exit 1
fi

MEMBER_COUNT=0
for _ in $MEMBER_IDS; do MEMBER_COUNT=$((MEMBER_COUNT + 1)); done
# Soft size nudge only — still promotes every member. Not a refuse threshold.
PLAN_SIZE_WARN=10
if [ "$MEMBER_COUNT" -gt "$PLAN_SIZE_WARN" ]; then
  echo "⚠ Plan $PLAN_ID has $MEMBER_COUNT members (over $PLAN_SIZE_WARN)."
  echo "  Promoting all of them — plan start has no hard member cap."
  echo "  If the sprint feels unwieldy, split into smaller plans later; size alone does not block start."
  echo ""
fi

mkdir -p "$BACKLOG_DIR" "$NEXT_DIR"

# Preflight: classify every member before any promote.
# next/ without a READY stamp is treated as accidental — demote to backlog/
# so the sprint only holds stamped work. Default mode then gates those files
# with the rest of the backlog; --commit-only leaves them in backlog.
declare -a MOVE_PATHS=() MOVE_NAMES=()
declare -a SKIP_NEXT=() SKIP_PAST=()
declare -a BLOCKED_IDS=() MISSING_IDS=()
DEMOTED=0

for id in $MEMBER_IDS; do
  if ! hit=$(resolve_member "$id"); then
    MISSING_IDS+=("$id")
    continue
  fi
  fpath="${hit%%$'\t'*}"
  stage="${hit##*$'\t'}"
  name=$(basename "$fpath")
  case "$stage" in
    backlog)
      MOVE_PATHS+=("$fpath")
      MOVE_NAMES+=("$name")
      ;;
    next)
      if [ "$(sprintbias_review_verdict "$fpath")" = "READY" ]; then
        SKIP_NEXT+=("#$id $name")
      else
        # Not stamped READY — wrong place. Park in backlog.
        dest="$BACKLOG_DIR/$name"
        if [ -e "$dest" ]; then
          echo "  ⚠ not READY in next/ but backlog already has $name — left in next/"
        else
          move_file "$fpath" "$dest"
          echo "  · not READY → backlog/: #$id $name"
          DEMOTED=$((DEMOTED + 1))
          # Default start will gate+promote if workable; --commit-only does not
          # re-push unvetted work into next/.
          if [ "$COMMIT_ONLY" -eq 0 ]; then
            MOVE_PATHS+=("$dest")
            MOVE_NAMES+=("$name")
          fi
        fi
      fi
      ;;
    blocked)
      BLOCKED_IDS+=("$id")
      ;;
    doing|review|done)
      SKIP_PAST+=("#$id $name ($stage/)")
      ;;
  esac
done

# Hard errors first: dangling members
if [ ${#MISSING_IDS[@]} -gt 0 ]; then
  echo "✗ Dangling member(s) — no task file found:"
  for id in "${MISSING_IDS[@]}"; do
    echo "    #$id"
  done
  echo "  Fix the plan member list (chat plan $PLAN_ID) and re-run."
  exit 1
fi

# Blocked: stop entirely so the sprint is not half-committed around work that
# still needs a decision or clarification
if [ ${#BLOCKED_IDS[@]} -gt 0 ]; then
  echo "✗ Member(s) still in blocked/ — resolve decisions/clarifications before starting this plan:"
  for id in "${BLOCKED_IDS[@]}"; do
    echo "    ./sprint.sh chat $id"
  done
  echo "  Then re-run: ./sprint.sh plan start $PLAN_ID"
  exit 1
fi

# ── Reconcile the Plan reverse index ─────────────────────────────────
# The plan file is the membership authority; refresh each member's **Plan**
# field to match. sprintbias_plan_index_drift --fix scans every open task, so it
# also clears a stale **Plan** on a task that was removed from this plan (its
# primary falls back to another plan or none). Migrate on touch — done/ is left
# untouched. Runs before the gate; the Plan field is independent of stage.
PLAN_SYNCED=$(sprintbias_plan_index_drift --fix | wc -l | tr -d '[:space:]')
if [ "${PLAN_SYNCED:-0}" -gt 0 ] 2>/dev/null; then
  echo "  · synced Plan on $PLAN_SYNCED task(s)"
fi

# ── Dependency workability filter ────────────────────────────────────
# Audit **Depends on** before any promote. Co-promote candidates (backlog
# members in MOVE_*) count as sprint-ready once they themselves clear this
# filter — so A→B both in the plan can enter next/ together. A dep still in
# backlog/ or blocked/ that is NOT a co-promote candidate holds the dependent
# out of next/. READY next/ members with the same gap are demoted to backlog/.
HELD_DEP=0

# Candidate ids being considered for promote / stay-in-next this run.
_cand_ids=""
if [ ${#MOVE_NAMES[@]} -gt 0 ]; then
  for _n in "${MOVE_NAMES[@]}"; do
    _cand_ids="$_cand_ids ${_n%%-*}"
  done
fi
if [ ${#SKIP_NEXT[@]} -gt 0 ]; then
  for _line in "${SKIP_NEXT[@]}"; do
    _rid="$(printf '%s' "$_line" | grep -oE '[0-9]+' | head -1)"
    [ -n "$_rid" ] || continue
    _cand_ids="$_cand_ids $_rid"
  done
fi

# Fixed-point: an id is workable when every outside-sprint dep is itself a
# workable co-promote candidate (or there are no such deps).
_workable=""
_changed=1
while [ "$_changed" -eq 1 ]; do
  _changed=0
  for _cid in $_cand_ids; do
    case " $_workable " in *" $_cid "*) continue ;; esac
    _cpath="$(sprintbias_task_path "$_cid" 2>/dev/null || true)"
    [ -n "$_cpath" ] || continue
    _outside="$(sprintbias_deps_not_sprint_ready "$_cpath")"
    _pending=0
    _hard=""
    for _d in $_outside; do
      case " $_workable " in
        *" $_d "*) continue ;;  # co-promote already cleared
      esac
      case " $_cand_ids " in
        *" $_d "*) _pending=1 ;;  # may clear on a later pass
        *) _hard="${_hard} $_d" ;;
      esac
    done
    if [ -z "$_hard" ] && [ "$_pending" -eq 0 ]; then
      _workable="$_workable $_cid"
      _changed=1
    fi
  done
done
_workable=" ${_workable} "

# Format "depends on #N (stage/)" for hold messages; skip co-candidates.
_held_dep_bits() {
  local file="$1" outside d stage bits=""
  outside="$(sprintbias_deps_not_sprint_ready "$file")"
  for d in $outside; do
    case " $_cand_ids " in *" $d "*) continue ;; esac
    stage="$(sprintbias_task_stage "$d" 2>/dev/null || true)"
    [ -n "$stage" ] || stage="?"
    [ -n "$bits" ] && bits="$bits, "
    bits="${bits}#${d} (${stage}/)"
  done
  if [ -n "$bits" ]; then
    printf '%s' "$bits"
  else
    printf 'unresolved co-promote deps'
  fi
}

# Rebuild MOVE_* keeping only workable candidates; report holds.
if [ ${#MOVE_PATHS[@]} -gt 0 ]; then
  _new_paths=()
  _new_names=()
  i=0
  while [ "$i" -lt "${#MOVE_PATHS[@]}" ]; do
    _src="${MOVE_PATHS[$i]}"
    _name="${MOVE_NAMES[$i]}"
    _id="${_name%%-*}"
    case "$_workable" in
      *" $_id "*)
        _new_paths+=("$_src")
        _new_names+=("$_name")
        ;;
      *)
        _bits="$(_held_dep_bits "$_src")"
        echo "  ⊘ held (deps not in sprint): #${_id} depends on ${_bits} — left in backlog/"
        echo "    A task is workable for next/ only when every dependency is in next/"
        echo "    (or doing/review/done), or co-promoted in this start. Define/start"
        echo "    the missing dep first, or add it to this plan."
        HELD_DEP=$((HELD_DEP + 1))
        ;;
    esac
    i=$((i + 1))
  done
  MOVE_PATHS=("${_new_paths[@]+"${_new_paths[@]}"}")
  MOVE_NAMES=("${_new_names[@]+"${_new_names[@]}"}")
fi

# Demote READY next/ members whose deps are still outside the sprint.
if [ ${#SKIP_NEXT[@]} -gt 0 ]; then
  _keep_next=()
  for _line in "${SKIP_NEXT[@]}"; do
    _rid="$(printf '%s' "$_line" | grep -oE '[0-9]+' | head -1)"
    _rname="$(printf '%s' "$_line" | sed 's/^#[0-9][0-9]*[[:space:]]*//')"
    case "$_workable" in
      *" $_rid "*)
        _keep_next+=("$_line")
        ;;
      *)
        _rpath="$(sprintbias_task_path "$_rid" 2>/dev/null || true)"
        _bits="unresolved co-promote deps"
        [ -n "$_rpath" ] && _bits="$(_held_dep_bits "$_rpath")"
        dest="$BACKLOG_DIR/$_rname"
        if [ -e "$dest" ]; then
          echo "  ⚠ deps not in sprint but backlog already has $_rname — left in next/"
          _keep_next+=("$_line")
        elif [ -n "$_rpath" ]; then
          move_file "$_rpath" "$dest"
          echo "  ⊘ held (deps not in sprint): #${_rid} depends on ${_bits} — demoted next/ → backlog/"
          DEMOTED=$((DEMOTED + 1))
          HELD_DEP=$((HELD_DEP + 1))
        else
          _keep_next+=("$_line")
        fi
        ;;
    esac
  done
  SKIP_NEXT=("${_keep_next[@]+"${_keep_next[@]}"}")
fi
unset -f _held_dep_bits
unset _cand_ids _workable _changed _cid _cpath _outside _pending _hard _d
unset _new_paths _new_names _src _name _id _bits _keep_next
unset _rid _rname _rpath _n _line dest i

# Notices for skips
if [ ${#SKIP_NEXT[@]} -gt 0 ]; then
  for line in "${SKIP_NEXT[@]}"; do
    echo "  · already in next/ (READY): $line"
  done
fi
if [ ${#SKIP_PAST[@]} -gt 0 ]; then
  for line in "${SKIP_PAST[@]}"; do
    echo "  · past next/ (skipped): $line"
  done
fi

# ── Gate / promote backlog members ───────────────────────────────────
# Default: gate each backlog member in place; only READY is promoted into
# next/. --commit-only skips the gate for pure filesystem promote.

READY_MOVED=0   # READY members promoted into next/
BLOCKED_CT=0    # graded BLOCKED, landed in blocked/
COMPLETE_CT=0  # graded COMPLETE, landed in review/
ERR_CT=0        # gate errored, member left in backlog/
EMITTED=0       # a review prompt was emitted for the surrounding agent to run

if [ "$COMMIT_ONLY" -eq 1 ]; then
  # Pure filesystem promote — no AI, no vetting.
  if [ ${#MOVE_PATHS[@]} -gt 0 ]; then
    i=0
    while [ "$i" -lt "${#MOVE_PATHS[@]}" ]; do
      src="${MOVE_PATHS[$i]}"
      name="${MOVE_NAMES[$i]}"
      dest="$NEXT_DIR/$name"
      if [ -e "$dest" ]; then
        echo "  ⚠ destination exists, skipping: $dest"
      else
        move_file "$src" "$dest"
        echo "  → $name  backlog/ → next/"
        READY_MOVED=$((READY_MOVED + 1))
      fi
      i=$((i + 1))
    done
  fi
elif [ ${#MOVE_PATHS[@]} -gt 0 ]; then
  mkdir -p docs/tmp
  # READY_DIR = next/: only what grades READY is promoted into the sprint;
  # BLOCKED → blocked/, COMPLETE → review/ (handled inside the shared gate).
  sprintbias_gate_init plan "$NEXT_DIR" "$NEXT_DIR"

  # Orchestration-capable emit fast path: one subagent per member, in parallel.
  # The agent runs each review and promote/move per folded-in instructions.
  # Only worth the orchestration for more than one member.
  if [ "$(sprintbias_ai_mode)" = "emit" ] && sprintbias_orchestration_capable \
     && [ ${#MOVE_PATHS[@]} -gt 1 ]; then
    sprintbias_gate_parallel "${MOVE_PATHS[@]}"
    EMITTED=1
  else
    for src in "${MOVE_PATHS[@]}"; do
      name="$(basename "$src")"
      echo "▸ Gating: $name"
      sprintbias_gate_review "$src"
      case "$SPRINTBIAS_GATE_VERDICT" in
        EMIT)    EMITTED=1 ;;
        READY)   READY_MOVED=$((READY_MOVED + 1)); echo "  ✓ READY → next/: $name" ;;
        BLOCKED) BLOCKED_CT=$((BLOCKED_CT + 1));   echo "  ⊘ BLOCKED → blocked/: $name" ;;
        COMPLETE) COMPLETE_CT=$((COMPLETE_CT + 1)); echo "  ✓ COMPLETE → review/: $name" ;;
        NOSTAMP|FAILED)
          ERR_CT=$((ERR_CT + 1))
          echo "  ✗ gate $SPRINTBIAS_GATE_VERDICT: $name — left in backlog/"
          [ -n "$SPRINTBIAS_GATE_LOG" ] && echo "    log: $SPRINTBIAS_GATE_LOG"
          ;;
      esac
    done
  fi
fi

# ── Summary ──────────────────────────────────────────────────────────
echo ""
if [ "$EMITTED" -eq 1 ]; then
  echo "▸ Plan $PLAN_ID ($MEMBER_COUNT members): gating ${#MOVE_PATHS[@]} backlog member(s) — run the review prompt(s) above."
  echo "  Gate every listed member (no subset). READY → next/; BLOCKED → blocked/, COMPLETE → review/."
elif [ "$COMMIT_ONLY" -eq 1 ]; then
  echo "▸ Plan $PLAN_ID committed (--commit-only): $MEMBER_COUNT members — moved $READY_MOVED into next/ (gate skipped — not vetted)"
  [ "$DEMOTED" -gt 0 ] && echo "  (demoted $DEMOTED unstamped next/ → backlog/)"
else
  echo "▸ Plan $PLAN_ID started ($MEMBER_COUNT members): $READY_MOVED ready → next/, $BLOCKED_CT blocked, $COMPLETE_CT complete"
  [ "$DEMOTED" -gt 0 ] && echo "  (demoted $DEMOTED unstamped next/ → backlog/ before gate)"
  [ "$ERR_CT" -gt 0 ] && echo "  ($ERR_CT gate error(s) — left in backlog/)"
fi
[ ${#SKIP_NEXT[@]} -gt 0 ] && echo "  (already queued READY: ${#SKIP_NEXT[@]})"
[ ${#SKIP_PAST[@]} -gt 0 ] && echo "  (already past next/: ${#SKIP_PAST[@]})"
[ "${HELD_DEP:-0}" -gt 0 ] && echo "  (held — deps not in sprint: $HELD_DEP)"

# One-way STARTED latch: this plan has now been committed to the sprint. Set on
# every successful exit — gated, emit, --commit-only, and idempotent re-runs —
# regardless of how many members moved this run. It never reverts as members
# flow through next/doing/review/done; `plan done` later deletes the file.
stamp_started "$PLAN_FILE"

GOAL="$(plan_goal_text "$PLAN_FILE")"
if [ -n "$GOAL" ]; then
  echo ""
  echo "  Goal: $GOAL"
fi

# Export for parent (loop) and any child process in this shell tree.
# shellcheck disable=SC2034
export SPRINTBIAS_ACTIVE_PLAN_ID="$PLAN_ID"
export SPRINTBIAS_ACTIVE_PLAN_FILE="$PLAN_FILE"
export SPRINTBIAS_ACTIVE_PLAN_GOAL="${GOAL:-}"

echo ""
echo "Next: ./sprint.sh work"
exit 0
