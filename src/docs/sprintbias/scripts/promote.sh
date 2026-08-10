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

# ── Args: optional task id, --dry-run ────────────────────────────────
ONLY_ID=""
DRY_RUN=0
for _arg in "$@"; do
  case "$_arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) exec "$(dirname "${BASH_SOURCE[0]}")/../../../sprint.sh" help promote ;;
    [0-9]*)    [ -z "$ONLY_ID" ] && ONLY_ID="$_arg" ;;
    *)         echo "Unknown argument: $_arg (try: ./sprint.sh help promote)" >&2; exit 2 ;;
  esac
done
unset _arg

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
