#!/usr/bin/env bash
# promote.sh — Test-gated promotion of review/ tasks to done/. See: ./sprint.sh help promote
#
# Invoked as: ./sprint.sh promote [id] [--dry-run]
#             ./sprint.sh promote --accept <id>     (your sign-off: closes a task with no Tests)
#             ./sprint.sh promote --reject <id> "what is wrong"
#             ./sprint.sh promote plan:N [--fresh]   (sign off a whole LANDED plan)
#
# Pure shell, except the breaker: before sign-off, each landed task with no
# **Breaker**: line gets one breaker pass (sprintbias_break_signoff; off with
# BREAK=off or --no-break). This is the one automated way a task leaves review/ for
# done/. For each task in docs/tasks/review/, read its **Tests**: field (legacy
# alias **Proven by**) — one or more docs/tests/*.sh paths that prove the work.
# Run them. Every named test green → git mv review/ → done/. A task whose field
# is `none` (or missing) stays in review/ for a human: automation never guesses
# a task is finished; it demands a passing suite script that says so.
#
# Two gates, one lifecycle. **Depends on** gates the close the same way it gates
# the run: a review/ task whose prerequisite has not landed (review/ with a
# **Proof**: line) or reached done/ is
# held (not moved), so a dependent never lands in done/ ahead of the work it
# needs. **Tests** gates the close: a task closes only when its suite scripts
# pass AND its prerequisites are already closed. The Depends-on hold uses #328's
# sprintbias_classify_dep, so a missing/folded prereq is classified, never
# assumed satisfied. Holds self-clear: a later promote closes newly-eligible
# dependents (a chain closes over successive runs — single pass, no --drain).
#
# A third hold: a rejected original carries **Held**: fix #N and stays in
# review/ until fix #N is in done/ (--reject files that fix task through
# sprintbias_file_fix_task in lib.sh).
#
# plan:N is the sign-off batch: on a LANDED plan it runs the project's full
# suite once (config TEST_SUITE), files fix tasks on failure, and on success
# shows the plan's combined Signoff (human) checklist; one "y" moves every
# member to done/. A green run leaves a pass stamp in docs/tmp/ keyed to a
# working-tree fingerprint; the next plan:N on the same tree reuses it (--fresh
# re-runs). The stamp is a cache, never a state.
#
# After promoting, name any plan whose every member now sits in done/ so the
# developer can retire it with `./sprint.sh plan done <id>`. Retirement stays an
# explicit step — promote never retires a plan itself.

# Bash reads a script as it runs. A long run can outlive edits to this file
# (an agent's task, or a setup.sh update), so the braces make bash parse the
# whole script before running any of it.
{
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
REJECT=0
ACCEPT=0
REPORT=""
PLAN_ID=""
FRESH=0
NO_BREAK=0
BREAK_JOBS=""
_STEADY=0
_next_is_jobs=0
# One plan-target reader (lib.sh): plan N / plan:N, and a bare number that
# names no task but a plan.
sprintbias_plan_args --bare "$@"
set -- ${SPRINTBIAS_ARGS[@]+"${SPRINTBIAS_ARGS[@]}"}
for _arg in "$@"; do
  if [ "$REJECT" -eq 1 ] && [ -n "$ONLY_ID" ] && [ -z "$REPORT" ]; then
    REPORT="$_arg"; continue
  fi
  if [ "$_next_is_jobs" -eq 1 ]; then
    case "$_arg" in ''|*[!0-9]*|0) echo "✗ --jobs needs a number 1 or greater" >&2; exit 2 ;; esac
    BREAK_JOBS="$_arg"; _next_is_jobs=0; continue
  fi
  case "$_arg" in
    --no-break) NO_BREAK=1 ;;
    --jobs)    _next_is_jobs=1 ;;
    --steady)  _STEADY=1 ;;
    --reject)  REJECT=1 ;;
    --accept)  ACCEPT=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --audit)   AUDIT=1 ;;
    --move)    MOVE=1 ;;
    --fresh)   FRESH=1 ;;
    plan:[0-9]*) PLAN_ID="${_arg#plan:}" ;;
    -h|--help) exec "$(dirname "${BASH_SOURCE[0]}")/../../../sprint.sh" help promote ;;
    [0-9]*)    [ -z "$ONLY_ID" ] && ONLY_ID="$_arg" ;;
    *)         echo "Unknown argument: $_arg (try: ./sprint.sh help promote)" >&2; exit 2 ;;
  esac
done
unset _arg
[ "$_next_is_jobs" -eq 1 ] && { echo "✗ --jobs needs a number" >&2; exit 2; }
# The breaker before sign-off runs in parallel: 4 at a time in fast mode, 2
# otherwise; --steady one at a time; --jobs N sets the count.
if [ -z "$BREAK_JOBS" ]; then
  if [ "$_STEADY" -eq 1 ]; then BREAK_JOBS=1
  elif sprintbias_fast_on; then BREAK_JOBS=4
  else BREAK_JOBS=2; fi
fi
[ "$NO_BREAK" -eq 1 ] && export SPRINTBIAS_BREAK=off
unset _STEADY _next_is_jobs

# --move only means anything under --audit; the default mode has --dry-run.
if [ "$MOVE" -eq 1 ] && [ "$AUDIT" -eq 0 ]; then
  echo "✗ --move applies to --audit only. Default promote already moves proven-green tasks;" >&2
  echo "  use --dry-run to preview it. Did you mean:  ./sprint.sh promote --audit --move" >&2
  exit 2
fi

if [ "$FRESH" -eq 1 ] && [ -z "$PLAN_ID" ]; then
  echo "✗ --fresh applies to plan:N only: ./sprint.sh promote plan:N --fresh" >&2
  exit 2
fi

# --accept <id>: the person's sign-off for one task. A task with no **Tests**
# closes on it (the person is the judge); named Tests still run and must pass;
# Held and Depends on holds still apply. Handled in the main loop below.
if [ "$ACCEPT" -eq 1 ]; then
  if [ -z "$ONLY_ID" ]; then
    echo "Usage: ./sprint.sh promote --accept <id>" >&2
    exit 2
  fi
  if [ "$REJECT" -eq 1 ] || [ "$AUDIT" -eq 1 ] || [ "$MOVE" -eq 1 ] || [ -n "$PLAN_ID" ]; then
    echo "✗ --accept stands alone with one task id: ./sprint.sh promote --accept <id>" >&2
    exit 2
  fi
fi

# ── --reject: send a review/ task back as a linked fix task ──────────
# The original stays in review/ with **Held**: fix #N; the fix task carries
# **Fixes**, the report as tests to add, and the original's Crew and Plan.
# The report also becomes one ## Known edges line in the project map.
if [ "$REJECT" -eq 1 ]; then
  if [ -z "$ONLY_ID" ] || [ -z "$REPORT" ]; then
    echo "Usage: ./sprint.sh promote --reject <id> \"what is wrong\"" >&2
    exit 2
  fi
  if [ "$DRY_RUN" -eq 1 ] || [ "$AUDIT" -eq 1 ] || [ "$MOVE" -eq 1 ]; then
    echo "✗ --reject stands alone: it files a fix task and moves nothing." >&2
    exit 2
  fi
  sprintbias_file_fix_task "$ONLY_ID" "$REPORT" || exit 1
  # The rejected case joins the project map's ## Known edges, so later work in
  # that area tests it (no map: nothing to add to).
  if [ -f "$SPRINTBIAS_PROJECT_MAP" ]; then
    sprintbias_add_known_edge "$ONLY_ID" "$REPORT"
    echo "▸ Added to ## Known edges in $SPRINTBIAS_PROJECT_MAP"
  fi
  echo ""
  echo "  Next: shape and run the fix —  ./sprint.sh work $SPRINTBIAS_FIX_ID"
  case "$(sprintbias_task_path "$ONLY_ID" 2>/dev/null)" in docs/tasks/review/*)
    echo "  promote closes #$ONLY_ID once #$SPRINTBIAS_FIX_ID is in done/." ;; esac
  exit 0
fi

[ -d "$REVIEW_DIR" ] || [ -n "$PLAN_ID" ] || { echo "No $REVIEW_DIR/ — nothing to promote."; exit 0; }
mkdir -p "$DONE_DIR"

# Doc follow-ups recorded in finished work become one backlog task before
# anything closes (a preview files nothing).
[ "$DRY_RUN" -eq 1 ] || sprintbias_file_doc_followups

# ── Gather review/ tasks (optionally a single id) ────────────────────
declare -a TASKS=()
while IFS= read -r f; do
  [ -f "$f" ] || continue
  case "$(basename "$f")" in .TEMPLATE-*|TEMPLATE-*) continue ;; esac
  if [ -n "$ONLY_ID" ]; then
    [ "$(basename "$f" | grep -oE '^[0-9]+')" = "$ONLY_ID" ] || continue
  fi
  # A plan's human test is the person's to run; it closes with promote plan:N.
  if sprintbias_is_human_task "$f"; then
    if [ -n "$ONLY_ID" ]; then
      _hp=$(sprintbias_meta_value "$f" "Plan" | tr -dc '0-9')
      echo "#$ONLY_ID is the human test for plan ${_hp:-?}: run its checks, write any"
      echo "failure under its ## Results, then close it with the plan:"
      echo "    ./sprint.sh promote plan:${_hp:-N}"
      exit 0
    fi
    continue
  fi
  TASKS+=("$f")
done < <(find "$REVIEW_DIR" -maxdepth 1 -name '*.md' -type f | sort -t/ -k4)

if [ ${#TASKS[@]} -eq 0 ] && [ -z "$PLAN_ID" ]; then
  if [ -n "$ONLY_ID" ]; then
    echo "No task #$ONLY_ID in $REVIEW_DIR/. Find it:  ./sprint.sh search $ONLY_ID"
  else
    echo "No tasks in $REVIEW_DIR/ to promote. Build some:  ./sprint.sh work"
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
# of the work it needs. A prereq counts as satisfied ONLY under the shared rule
# sprintbias_dep_landed: in done/, or in review/ with a **Proof**: line. A
# review/ prereq without proof prints "in review, unproven"; every other
# classification (backlog/next/doing/blocked, folded, or missing) holds the
# dependent too. Uses #328's classify helper so a missing/folded id is
# classified, never assumed done. Prints one "#ID → reason" line per
# unsatisfied prereq; empty output means clear. Always exits 0 — a no-match
# under set -e must not kill the caller.
task_held_by() {
  local f="$1" raw kind id cls fixes fix
  # A rejected original closes only after every fix it names is in done/.
  for fix in $(sprintbias_held_fixes "$f"); do
    [ "$(sprintbias_classify_dep "$fix" missing)" = "done" ] \
      || printf 'fix #%s → %s (Held: closes after its fix is in done/)\n' "$fix" "$(sprintbias_classify_dep "$fix" missing)"
  done
  raw=$(sprintbias_meta_value "$f" "Depends on")
  [ -z "$raw" ] && return 0
  while read -r kind id; do
    [ "$kind" = "id" ] || continue
    cls=$(sprintbias_classify_dep "$id" missing)
    case "$cls" in
      review|done)
        # Landed (review/ + proof) or signed off (done/) releases the dependent.
        if ! sprintbias_dep_landed "$id"; then
          fixes=$(sprintbias_held_fixes "$(sprintbias_task_path "$id")" | sed 's/^/#/' | tr '\n' ' ')
          if [ -n "$fixes" ]; then
            printf '#%s → held (fix %snot landed)\n' "$id" "$fixes"
          else
            printf '#%s → %s\n' "$id" "$SPRINTBIAS_UNPROVEN_LABEL"
          fi
        fi
        ;;
      *) printf '#%s → %s\n' "$id" "$cls" ;;
    esac
  done <<EOF
$(sprintbias_iter_id_list "$raw")
EOF
  return 0
}

# unproven_note — printed once per run when any hold names a review/
# prerequisite without a proof line. Tasks that reached review/ before proof
# lines existed land here: sign them off (promote with **Tests**, or move to
# done/) or record proof, and their dependents release.
HELD_UNPROVEN=0
note_unproven() {
  case "$1" in *"$SPRINTBIAS_UNPROVEN_LABEL"*) HELD_UNPROVEN=1 ;; esac
}
unproven_note() {
  [ "$HELD_UNPROVEN" -eq 1 ] || return 0
  echo "  Note: a review/ prerequisite releases its dependents only with a proof line."
  echo "  Sign it off (./sprint.sh promote <id>, or move it to done/), or add"
  echo "  '**Proof**: YYYY-MM-DD · <test commands> · pass' under its ## Completed."
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
  bash -c "$(sprintbias_test_cmd "$p")" >/dev/null 2>&1
  rc=$?
  set -e
  RC_PATHS+=("$p"); RC_CODES+=("$rc")
  printf '%s' "$rc"
}

# ═════════════════════════════════════════════════════════════════════
# MODE: plan:N — the sign-off batch. A plan signs off as one unit:
#   1. only a LANDED plan (every member landed, no open fix task) proceeds;
#   2. the project's full suite (config TEST_SUITE) runs once;
#   3. a failure files fix tasks (sprintbias_file_fix_task) for the members
#      whose files the failing output names, and moves nothing;
#   4. a pass shows the plan's human test (created or refreshed here from
#      every ## Signoff (human) and ### Assumptions) and asks once — "y" moves
#      every member and the human test to done/. No answer moves nothing:
#      humans own done/.
# At any state, each '- fail: …' line under the human test's ## Results is
# filed as a fix task first, so what the person found reaches the agents.
# ═════════════════════════════════════════════════════════════════════

# signoff_items FILE — the ## Signoff (human) body, comments and blank lines
# dropped. An old task with no such section prints nothing.
signoff_items() {
  awk '
    /^## Signoff \(human\)[[:space:]]*$/ { cap = 1; next }
    cap && /^## / { exit }
    !cap { next }
    incom { if (index($0, "-->")) incom = 0; next }
    {
      gsub(/<!--.*-->/, "")
      if (index($0, "<!--")) { sub(/<!--.*/, ""); incom = 1 }
      if ($0 ~ /[^[:space:]]/ && $0 !~ /^[[:space:]]*-[[:space:]]*\[[ xX]\][[:space:]]*$/) print
    }
  ' "$1" 2>/dev/null
}

# member_paths FILE — the file paths a member says it touched: its
# ### Files changed lines, its **Touching:** line and its **Tests** paths.
member_paths() {
  {
    awk '
      /^### Files changed[[:space:]]*$/ { cap = 1; next }
      cap && /^#/ { cap = 0 }
      cap { print }
    ' "$1"
    { grep -m1 -E '^\*\*Touching:?\*\*:?' "$1" || true; } | sed -E 's/\([^)]*\)//g'
    sprintbias_meta_value "$1" "Tests"
  } | tr ',`' '  ' | tr ' \t' '\n\n' \
    | { grep -E '^[A-Za-z0-9_.][A-Za-z0-9_./-]*\.[A-Za-z0-9]+$' || true; } | awk '!seen[$0]++'
}

# member_hit FILE FAILLINES — exit 0 when the failing lines name one of the
# member's paths (full path, or a basename of 4+ characters).
member_hit() {
  local p b
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    grep -qF -- "$p" "$2" && return 0
    b="${p##*/}"
    [ "${#b}" -ge 4 ] && grep -qF -- "$b" "$2" && return 0
  done <<EOF
$(member_paths "$1")
EOF
  return 1
}

# tree_fingerprint SUITE — one hash of the working tree as the suite would see
# it: every tracked and untracked, non-ignored file (content, plus the
# executable bit), docs/tmp/ left out so the suite's own log, scratch and the
# stamp never invalidate a run, and the TEST_SUITE command folded in. Hashing
# reads files only (git hash-object without -w writes no objects). Prints
# nothing when git cannot take it: the caller then runs the suite every time.
tree_fingerprint() {
  local list
  command -v git >/dev/null 2>&1 || return 0
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  list=$(mktemp "${TMPDIR:-/tmp}/sprintbias-fp.XXXXXX")
  git ls-files -co --exclude-standard -- . ':(exclude)docs/tmp' 2>/dev/null \
    | while IFS= read -r p; do
        [ -f "$p" ] || continue
        if [ -x "$p" ]; then printf 'x %s\n' "$p"; else printf -- '- %s\n' "$p"; fi
      done | LC_ALL=C sort -k2 > "$list"
  {
    printf 'suite %s\n' "$1"
    cut -c3- "$list" | git hash-object --stdin-paths 2>/dev/null | paste -d' ' "$list" -
  } | git hash-object --stdin 2>/dev/null || true
  rm -f "$list"
}

if [ -n "$PLAN_ID" ]; then
  if [ -n "$ONLY_ID" ] || [ "$AUDIT" -eq 1 ] || [ "$MOVE" -eq 1 ] || [ "$REJECT" -eq 1 ]; then
    echo "✗ plan:N stands alone (only --fresh or --dry-run may join it): ./sprint.sh promote plan:$PLAN_ID" >&2
    exit 2
  fi
  PLAN_FILE=$(sprintbias_find_plan "$PLAN_ID") || {
    echo "✗ No plan #$PLAN_ID in $PLANS_DIR/." >&2; exit 1; }
  STATE=$(sprintbias_plan_state "$PLAN_FILE")

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "▸ promote plan:$PLAN_ID  sign-off batch — $(task_title "$PLAN_FILE" | sed 's/^Plan [0-9]*: *//')"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  if [ "$STATE" = "SIGNED OFF" ]; then
    echo "  Plan $PLAN_ID is SIGNED OFF: every member is in done/."
    echo "  Retire it:  ./sprint.sh plan done $PLAN_ID"
    exit 0
  fi
  # ── The human's results come back as agent work ──────────────────────
  HT=$(sprintbias_plan_human_test "$PLAN_FILE")
  if [ -n "$HT" ]; then
    echo "  Human test #$(task_id "$HT"): reading ## Results"
    if [ "$DRY_RUN" -eq 1 ]; then
      FAILS=$(sprintbias_human_test_failures "$HT" | grep -c . || true)
      if [ "${FAILS:-0}" -gt 0 ]; then
        echo "  (dry-run) $FAILS failure(s) under ## Results would become fix tasks. Nothing ran and nothing moved."
        exit 0
      fi
      echo ""
    else
    FILED=$(sprintbias_human_test_file_failures "$HT")
    if [ "${FILED:-0}" -gt 0 ]; then
      echo ""
      echo "  Filed $FILED fix task(s) from your results. Nothing moved."
      echo "  The agents build them:  ./sprint.sh work   (or a crew lane)"
      echo "  When the plan lands again, re-run your test, then:  ./sprint.sh promote plan:$PLAN_ID"
      exit 1
    fi
    echo ""
    fi
  fi

  if [ "$STATE" != "LANDED" ]; then
    echo "  Plan $PLAN_ID is $STATE, not LANDED. Sign-off waits for every member to land"
    echo "  (review/ with a proof line) and every fix task to close. Still open:"
    # An open fix task is usually also a plan member; list it once, as a fix.
    OPEN_FIXES=$(sprintbias_plan_open_fixes "$PLAN_FILE")
    FIX_IDS=" $(printf '%s\n' "$OPEN_FIXES" | awk '{print $1}' | tr '\n' ' ') "
    for mid in $(sprintbias_plan_member_ids "$PLAN_FILE"); do
      st=$(sprintbias_member_standing "$mid")
      case "$st" in
        landed|signed-off|human) ;;
        held)     echo "    #$mid  $(sprintbias_held_label "$mid")" ;;
        unproven) echo "    #$mid  $SPRINTBIAS_UNPROVEN_LABEL — add its **Proof**: line" ;;
        missing)  echo "    #$mid  missing — no task file" ;;
        *)        case "$FIX_IDS" in *" $mid "*) continue ;; esac
                  echo "    #$mid  open — $(sprintbias_task_stage "$mid")/  $(task_title "$(sprintbias_task_path "$mid")")" ;;
      esac
    done
    while read -r fid target; do
      [ -n "$fid" ] && echo "    fix #$fid for #$target  open — $(sprintbias_task_stage "$fid")/"
    done <<EOF
$OPEN_FIXES
EOF
    echo ""
    echo "  Nothing ran and nothing moved. Re-run once they land:  ./sprint.sh promote plan:$PLAN_ID"
    exit 0
  fi

  # The human test gathers every person-only check; refreshed so assumptions
  # recorded since plan start are on it. Created here for an older plan.
  if [ "$DRY_RUN" -eq 1 ]; then HT=$(sprintbias_plan_human_test "$PLAN_FILE")
  else HT=$(sprintbias_plan_ensure_human_test "$PLAN_FILE") || exit 1; fi

  # ── Batch: landed members in review/, in dependency order ──────────
  BATCH=" "
  for mid in $(sprintbias_plan_member_ids "$PLAN_FILE"); do
    [ "$(sprintbias_member_standing "$mid")" = "landed" ] && BATCH="$BATCH$mid "
  done
  # Edges: in-batch **Depends on** ids and **Held** fixes come first.
  ORDER=""; REMAIN="$BATCH"
  while [ -n "${REMAIN// /}" ]; do
    ready=""
    for mid in $REMAIN; do
      mpath=$(sprintbias_task_path "$mid")
      waits=0
      for pre in $(sprintbias_iter_id_list "$(sprintbias_meta_value "$mpath" "Depends on")" | awk '$1=="id"{print $2}') \
                 $(sprintbias_held_fixes "$mpath"); do
        case "$REMAIN" in *" $pre "*) [ "$pre" != "$mid" ] && waits=1 ;; esac
      done
      [ "$waits" -eq 0 ] && ready="$ready$mid "
    done
    [ -n "$ready" ] || ready="$REMAIN"   # a cycle: keep plan order rather than loop
    for mid in $ready; do ORDER="$ORDER$mid "; REMAIN="${REMAIN/ $mid / }"; done
  done
  # The human test closes last, with the batch.
  [ -n "$HT" ] && ORDER="$ORDER$(task_id "$HT") "

  # A prerequisite outside the batch still holds the close (same gate as
  # promote <id>); in-batch prerequisites and fixes move together.
  OUTSIDE=""
  for mid in $ORDER; do
    while IFS= read -r hr; do
      [ -n "$hr" ] || continue
      hid=$(printf '%s' "$hr" | grep -oE '[0-9]+' | head -1)
      case "$BATCH" in *" $hid "*) continue ;; esac
      OUTSIDE="$OUTSIDE    #$mid waits on $hr
"
    done <<EOF
$(task_held_by "$(sprintbias_task_path "$mid")")
EOF
  done
  if [ -n "$OUTSIDE" ]; then
    echo "  Held — a prerequisite outside the plan is not landed or signed off:"
    printf '%s' "$OUTSIDE"
    echo ""
    echo "  Nothing ran and nothing moved. Close those first, then:  ./sprint.sh promote plan:$PLAN_ID"
    exit 0
  fi

  # ── The breaker, once per member that has not had it ──────────────
  BREAK_FILES=()
  for mid in $ORDER; do BREAK_FILES+=("$(sprintbias_task_path "$mid")"); done
  sprintbias_break_signoff "$BREAK_JOBS" "$DRY_RUN" "${BREAK_FILES[@]}"
  [ "$DRY_RUN" -eq 1 ] || sprintbias_lift_edges "${BREAK_FILES[@]}"
  if [ "$SPRINTBIAS_BREAK_EMIT" -eq 1 ]; then
    echo ""
    echo "  Nothing moved. Then:  ./sprint.sh promote plan:$PLAN_ID"
    exit 0
  fi
  if [ -n "$SPRINTBIAS_BREAK_LOST" ]; then
    echo ""
    echo "  The breaker found failures it could not fix; these lost their **Proof**: line:"
    for mid in $SPRINTBIAS_BREAK_LOST; do
      echo "    #$mid  read ## Test log in $(sprintbias_task_path "$mid") → ./sprint.sh work $mid"
    done
    echo ""
    echo "  Nothing moved. Land the fixes, then:  ./sprint.sh promote plan:$PLAN_ID"
    exit 1
  fi
  [ ${#BREAK_FILES[@]} -gt 0 ] && echo ""

  N_BATCH=$(printf '%s' "$ORDER" | wc -w | tr -d ' ')
  echo "  Plan $PLAN_ID is LANDED. $N_BATCH task(s) to sign off, in dependency order:"
  for mid in $ORDER; do
    echo "    #$mid  $(task_title "$(sprintbias_task_path "$mid")")"
  done
  echo ""
  if [ "$DRY_RUN" -eq 1 ]; then
    SUITE="$(sprintbias_cfg TEST_SUITE)"
    STAMP_FP=""; [ -f "docs/tmp/promote-plan-$PLAN_ID-suite.pass" ] && read -r STAMP_FP _ < "docs/tmp/promote-plan-$PLAN_ID-suite.pass" || true
    if [ -z "$SUITE" ]; then echo "  (dry-run) No full suite: TEST_SUITE is empty."
    elif [ "$FRESH" -eq 0 ] && [ -n "$STAMP_FP" ] && [ "$STAMP_FP" = "$(tree_fingerprint "$SUITE")" ]; then
      echo "  (dry-run) The full suite would be reused: nothing changed since its last green run."
    else echo "  (dry-run) The full suite would run once:  $SUITE"; fi
    echo "  (dry-run) Nothing ran and nothing moved. Sign off:  ./sprint.sh promote plan:$PLAN_ID"
    exit 0
  fi

  # ── The full suite, once ────────────────────────────────────────────
  SUITE="$(sprintbias_cfg TEST_SUITE)"
  if [ -z "$SUITE" ]; then
    echo "  No full suite: TEST_SUITE is empty in docs/sprintbias/config, so no suite ran."
    echo "  Set it to your project's full test command (e.g. TEST_SUITE=npm test) to gate"
    echo "  sign-off on it. Go on with the human checks below."
  else
    mkdir -p docs/tmp
    SUITE_LOG="docs/tmp/promote-plan-$PLAN_ID-suite.log"
    # Pass stamp: "<fingerprint> <time>" from the last green run on this plan.
    SUITE_STAMP="docs/tmp/promote-plan-$PLAN_ID-suite.pass"
    FP=$(tree_fingerprint "$SUITE")
    STAMP_FP=""; STAMP_AT=""
    [ -f "$SUITE_STAMP" ] && read -r STAMP_FP STAMP_AT < "$SUITE_STAMP" || true
    if [ "$FRESH" -eq 0 ] && [ -n "$FP" ] && [ "$FP" = "$STAMP_FP" ]; then
      SUITE_RC=0
      echo "  ✓ Full suite reused: it passed at $STAMP_AT and nothing changed since (--fresh re-runs it)."
    else
      echo "  Running the full suite once:  $SUITE"
      set +e
      bash -c "$SUITE" </dev/null >"$SUITE_LOG" 2>&1
      SUITE_RC=$?
      set -e
      # Only a green run is reused; a failure clears the old stamp.
      rm -f "$SUITE_STAMP"
      if [ "$SUITE_RC" -eq 0 ]; then
        [ -n "$FP" ] && printf '%s %s\n' "$FP" "$(date '+%Y-%m-%d %H:%M')" > "$SUITE_STAMP"
        echo "  ✓ Full suite passed. Output: $SUITE_LOG"
      fi
    fi
    if [ "$SUITE_RC" -ne 0 ]; then
      FAIL_LINES=$(mktemp "${TMPDIR:-/tmp}/sprintbias-suitefail.XXXXXX")
      { grep -iE 'fail|error|✗|not ok|traceback|exception|assert' "$SUITE_LOG" || true; } > "$FAIL_LINES"
      if [ -s "$FAIL_LINES" ]; then EXCERPT=$(head -40 "$FAIL_LINES"); else EXCERPT=$(tail -40 "$SUITE_LOG"); cp "$SUITE_LOG" "$FAIL_LINES"; fi
      echo "  ✗ Full suite failed (exit $SUITE_RC). Full output: $SUITE_LOG"
      printf '%s\n' "$EXCERPT" | sed 's/^/      /'
      echo ""
      # Route: each member whose files the failing lines name; else the
      # plan's last member in the batch.
      TARGETS=""; LAST=""
      for mid in $(sprintbias_plan_member_ids "$PLAN_FILE"); do
        case "$BATCH" in *" $mid "*) LAST="$mid" ;; *) continue ;; esac
        member_hit "$(sprintbias_task_path "$mid")" "$FAIL_LINES" && TARGETS="$TARGETS$mid "
      done
      [ -n "$TARGETS" ] || TARGETS="$LAST"
      rm -f "$FAIL_LINES"
      REPORT_TEXT="Full suite failed at plan $PLAN_ID sign-off: \`$SUITE\` exited $SUITE_RC. Failing output:
$(printf '%s\n' "$EXCERPT" | sed 's/^/> /')"
      for mid in $TARGETS; do
        sprintbias_file_fix_task "$mid" "$REPORT_TEXT" || exit 1
      done
      echo ""
      echo "  Nothing moved. Work the fix task(s), land them, then re-run:"
      echo "      ./sprint.sh promote plan:$PLAN_ID"
      exit 1
    fi
  fi
  echo ""

  # ── Combined human checklist, then one approval ─────────────────────
  if [ -n "$HT" ]; then
    echo "  Human test #$(task_id "$HT") — run these, then approve once:"
    echo "    $HT"
    echo ""
    signoff_items "$HT" | sed 's/^/    /'
  else
    echo "  No human checks: no member or the plan lists a Signoff (human) item."
  fi
  echo ""
  printf '  Approve plan %s and move %s task(s) to done/? [y/N] ' "$PLAN_ID" "$N_BATCH"
  ANSWER=""
  read -r ANSWER || true
  echo ""
  case "$ANSWER" in
    y|Y|yes|YES|Yes) ;;
    *)
      echo "  Not approved — nothing moved. Re-run and answer y to sign off:"
      echo "      ./sprint.sh promote plan:$PLAN_ID"
      if [ -n "$HT" ]; then
        echo "  Something failed? Write '- fail: <what you saw>' under ## Results in"
        echo "  $HT and re-run: each line becomes a fix task the agents build."
      fi
      exit 0 ;;
  esac
  sprintbias_file_doc_followups
  for mid in $ORDER; do
    mpath=$(sprintbias_task_path "$mid")
    move_file "$mpath" "$DONE_DIR/$(basename "$mpath")"
    echo "  ✓ #$mid → done/"
  done
  echo ""
  echo "  Plan $PLAN_ID is $(sprintbias_plan_state "$PLAN_FILE"). Retire it:  ./sprint.sh plan done $PLAN_ID"
  exit 0
fi

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
    local orient; orient="$(sprintbias_orient)"
    local changed_block
    if [ -n "$changed" ]; then
      changed_block="CHANGED FILES (source: $ctx):
$changed"
    else
      changed_block="CHANGED FILES: none detected ($ctx). Judge from the task's
## Completed section and Done when (automated), confirming against git history."
    fi
    cat <<PROMPT
Acceptance judge on ONE finished task.
${orient}

You judge ONE thing: is this task's ## Done when (automated) met by the work
that landed (an older ## Success criteria reads as it)? You never edit anything — your only output is the verdict.

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
    _orient="$(sprintbias_orient)"
    _task_list=""
    for f in "${TASKS[@]}"; do _task_list="${_task_list}
- ${f}"; done

    _move_rule="Move NOTHING. This is a report-only run (no --move): for each task
print its id and the subagent's verdict (DONE / NOT-DONE + reason), then stop.
Tell the developer to re-run with --move to close the DONE ones."
    if [ "$MOVE" -eq 1 ]; then
      _move_rule="For each task, route by the subagent's verdict:
   - DONE  → close it: git mv $REVIEW_DIR/<file> $DONE_DIR/<file> || mv (fallback).
             First confirm no open **Depends on** prerequisite (a prereq not in
             done/, and not in review/ with a **Proof**: line under ## Completed,
             HOLDS the task — leave it in review/ and say so).
   - NOT-DONE → leave it in $REVIEW_DIR/ and print the unmet criterion."
    fi

    _RULES="Follow $PROTOCOL exactly. Judge ACCEPTANCE only — are the task's
Done when (automated) met by what landed (an older ## Success criteria reads
as it)? You never edit anything. End with:
VERDICT: DONE | VERDICT: NOT-DONE — <unmet criterion>."

    # Summary tail — value check, not ${MOVE:+…} (MOVE=0 is a non-empty string).
    _summary_tail="DONE vs NOT-DONE"
    [ "$MOVE" -eq 1 ] && _summary_tail="DONE vs NOT-DONE and how many moved to done/"

    if sprintbias_orchestration_capable; then
      sprintbias_run -p "You are running the SprintBias promote --audit queue:
${#TASKS[@]} finished task(s) in review/ to judge for acceptance.
${_orient}

Judge each task in $(sprintbias_subagent_own_fresh polish) so contexts never mix.
You are the orchestrator — the subagents judge; you route the files.

For EACH task file below:
1. Launch a subagent whose entire instruction is:
     \"Acceptance judge on ONE finished task. Read the task file at <path> and
      judge it. $(sprintbias_subagent_no_nest)
$_RULES\"
2. When it returns, $_move_rule

Tasks (in order):$_task_list

When every task is judged, report a one-line summary: how many $_summary_tail.
Then one line per NOT-DONE task: ./sprint.sh promote --reject <id> \"what is missing\"
End with the next command (./sprint.sh status when nothing else is left)."
    else
      sprintbias_run -p "You are running the SprintBias promote --audit queue:
${#TASKS[@]} finished task(s) in review/ to judge for acceptance.
${_orient}

Work the tasks ONE AT A TIME, in the listed order. You have no subagent tool, so
you are the judge — after each task, reset your focus and start the next clean.

For EACH task file below:
1. Read the task file at <path> and judge it.
$_RULES
2. $_move_rule

Tasks (in order):$_task_list

When every task is judged, report a one-line summary: how many $_summary_tail.
Then one line per NOT-DONE task: ./sprint.sh promote --reject <id> \"what is missing\"
End with the next command (./sprint.sh status when nothing else is left)."
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

  declare -a A_NOTDONE_IDS=()
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

    # One read of the run: outcome + the text to grep a verdict from. A judge
    # that aborted (max-turns / never started) produced no verdict for a very
    # different reason than one that answered oddly — say which, and leave the
    # task in review/ rather than blaming the verdict parse.
    sprintbias_interpret_run "$LOG_FILE"
    if [ "$SPRINTBIAS_RUN_OUTCOME" != "finished" ]; then
      A_UNCLEAR=$((A_UNCLEAR + 1))
      echo "  ⚠ #$id  judge did not finish — $(sprintbias_run_hint "$SPRINTBIAS_RUN_OUTCOME"). Left in review/. See $LOG_FILE"
      continue
    fi

    VERDICT=$(printf '%s' "$SPRINTBIAS_RUN_VERDICT_TEXT" | sprintbias_parse_verdict 'DONE|NOT-DONE')
    # NOT-DONE contains DONE as a substring — parse_verdict returns the first
    # token it matched, so guard the order explicitly.
    if grep -qiE 'VERDICT:[[:space:]]*NOT-DONE' <<<"$SPRINTBIAS_RUN_VERDICT_TEXT"; then
      VERDICT="NOT-DONE"
    fi

    if [ "$VERDICT" = "DONE" ]; then
      held=$(task_held_by "$f")
      if [ -n "$held" ]; then
        echo "  ⊘ #$id  DONE but held — a prerequisite or fix is not yet closed:"
        while IFS= read -r hr; do
          case "$hr" in
            "") ;;
            fix*|*"→ held ("*) echo "        $hr" ;;
            *) echo "        $hr  (needs review/ with proof, or done/)" ;;
          esac
        done <<EOF
$held
EOF
        A_HELD=$((A_HELD + 1))
        note_unproven "$held"
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
      reason=$(printf '%s' "$SPRINTBIAS_RUN_VERDICT_TEXT" | grep -iE 'VERDICT:[[:space:]]*NOT-DONE' | head -1 | sed 's/.*NOT-DONE//; s/^[^[:alnum:]]*//')
      echo "  ○ #$id  NOT-DONE — stays in review/${reason:+: $reason}"
      A_NOTDONE=$((A_NOTDONE + 1))
      A_NOTDONE_IDS+=("$id")
    else
      A_UNCLEAR=$((A_UNCLEAR + 1))
      echo "  ? #$id  judge finished with no VERDICT token — left in review/. See $LOG_FILE"
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
  for nid in ${A_NOTDONE_IDS[@]+"${A_NOTDONE_IDS[@]}"}; do
    echo "  #$nid is not done — send it back:  ./sprint.sh promote --reject $nid \"what is missing\""
  done
  [ "$A_UNCLEAR" -gt 0 ] && echo "  No verdict for $A_UNCLEAR task(s) — re-judge:  ./sprint.sh promote --audit${ONLY_ID:+ $ONLY_ID}"
  if [ "$A_DONE" -eq 0 ] && [ "$A_NOTDONE" -eq 0 ] && [ "$A_UNCLEAR" -eq 0 ] || [ "$MOVE" -eq 1 ]; then
    echo "  Next: ./sprint.sh status   # see what is left to build or sign off"
  fi
  unproven_note
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "▸ promote  ${DRY_LABEL}review/ → done/ (test-gated)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── The breaker, before sign-off, on each task this run could close ──
BREAK_FILES=()
for f in "${TASKS[@]}"; do
  [ -z "$(task_held_by "$f")" ] || continue
  _t=$(task_tests "$f")
  if [ "$ACCEPT" -eq 1 ] || { [ -n "$_t" ] && [ "$(printf '%s' "$_t" | tr '[:upper:]' '[:lower:]')" != "none" ]; }; then
    BREAK_FILES+=("$f")
  fi
done
unset _t
sprintbias_break_signoff "$BREAK_JOBS" "$DRY_RUN" ${BREAK_FILES[@]+"${BREAK_FILES[@]}"}
[ "$DRY_RUN" -eq 1 ] || sprintbias_lift_edges ${BREAK_FILES[@]+"${BREAK_FILES[@]}"}
if [ "$SPRINTBIAS_BREAK_EMIT" -eq 1 ]; then
  echo ""
  _again="./sprint.sh promote"; [ "$ACCEPT" -eq 1 ] && _again="$_again --accept"
  echo "  Nothing moved. Then:  $_again${ONLY_ID:+ $ONLY_ID}"
  exit 0
fi
[ ${#BREAK_FILES[@]} -gt 0 ] && echo ""

PROMOTED=0; FAILED=0; SKIPPED=0; HELD=0
declare -a PROMOTED_IDS=()
declare -a SKIP_IDS=()   # skipped (no Tests) ids — each gets its --accept line

for f in "${TASKS[@]}"; do
  name=$(basename "$f")
  id=$(echo "$name" | grep -oE '^[0-9]+' || true)
  proven=$(task_tests "$f")

  # The breaker found a failure it could not fix and removed the proof line.
  case " $SPRINTBIAS_BREAK_LOST " in *" $id "*)
    echo "  ✗ #$id  stays in review/: the breaker found a failure it could not fix"
    echo "        read ## Test log in $f → ./sprint.sh work $id"
    FAILED=$((FAILED + 1))
    continue ;;
  esac

  # A rejected original (**Held**) is held before anything else, so the
  # no-Tests hint never invites a hand move ahead of its fix.
  held=""
  [ -n "$(sprintbias_held_fixes "$f")" ] && held=$(task_held_by "$f")
  if [ -n "$held" ]; then
    echo "  ⊘ #$id  held in review/ — a prerequisite or fix is not yet closed:"
    while IFS= read -r hr; do
      [ -n "$hr" ] && echo "        $hr"
    done <<EOF
$held
EOF
    HELD=$((HELD + 1))
    continue
  fi

  # No field, or an explicit `none` → not automatable. --accept is the
  # person's sign-off and closes it (holds still apply); otherwise it waits.
  if [ -z "$proven" ] || [ "$(printf '%s' "$proven" | tr '[:upper:]' '[:lower:]')" = "none" ]; then
    if [ "$ACCEPT" -eq 1 ]; then
      held=$(task_held_by "$f")
      if [ -n "$held" ]; then
        echo "  ⊘ #$id  held in review/ — a prerequisite or fix is not yet closed:"
        while IFS= read -r hr; do
          [ -n "$hr" ] && echo "        $hr"
        done <<EOF
$held
EOF
        HELD=$((HELD + 1))
        note_unproven "$held"
        continue
      fi
      if [ "$DRY_RUN" -eq 1 ]; then
        echo "  ✓ #$id  accepted → would move to done/  (your sign-off)"
      else
        move_file "$f" "$DONE_DIR/$name"
        echo "  ✓ #$id  accepted → done/  (your sign-off)"
      fi
      PROMOTED=$((PROMOTED + 1))
      PROMOTED_IDS+=("$id")
      continue
    fi
    echo "  ○ #$id  no **Tests** — waits for your sign-off:  ./sprint.sh promote --accept $id"
    SKIPPED=$((SKIPPED + 1))
    SKIP_IDS+=("$id")
    continue
  fi

  # Depends-on gate: a task with green Tests still may not close while a
  # prerequisite is open. Hold it (do not run its tests, do not move) and name
  # each unsatisfied prereq with its stage. Self-clearing on a later run.
  held=$(task_held_by "$f")
  if [ -n "$held" ]; then
    echo "  ⊘ #$id  held in review/ — a prerequisite or fix is not yet closed:"
    while IFS= read -r hr; do
      case "$hr" in
        "") ;;
        fix*|*"→ held ("*) echo "        $hr" ;;
        *) echo "        $hr  (needs review/ with proof, or done/)" ;;
      esac
    done <<EOF
$held
EOF
    HELD=$((HELD + 1))
    note_unproven "$held"
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
unproven_note
if [ "$SKIPPED" -eq 0 ] && [ "$FAILED" -eq 0 ] && [ "$HELD" -eq 0 ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    _real="./sprint.sh promote"; [ "$ACCEPT" -eq 1 ] && _real="$_real --accept"
    echo "  Run it for real:  $_real${ONLY_ID:+ $ONLY_ID}"
  else
    echo "  Next: ./sprint.sh status   # see what is left to build or sign off"
  fi
fi

# ── How to finish what promote could not auto-close ──────────────────
# Skips are not failures (exit 0) but they leave a dead-end-looking summary
# unless we say what to do next — same contract work prints when it lands
# tasks in review/ with Tests: none.
if [ "$SKIPPED" -gt 0 ]; then
  echo ""
  echo "  Skipped = **Tests** is missing or \`none\`. promote only moves review/ → done/"
  echo "  when the field names suite scripts under docs/tests/ and every one exits 0."
  echo ""
  echo "  Try each one; happy with it? Close it with your sign-off:"
  for sid in "${SKIP_IDS[@]}"; do
    echo "      ./sprint.sh promote --accept $sid"
  done
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
  echo "  re-run — the dependent releases automatically. A rejected task (**Held**:"
  echo "  fix #N) closes once its fix task is in done/:"
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
exit
}
