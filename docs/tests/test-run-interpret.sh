#!/usr/bin/env bash
# Test: per-profile run interpreters (task 368)
#
# sprintbias_interpret_run dispatches to the active profile's
# profile_interpret_run. Each shipped profile owns its own result shape:
#   claude  — Claude result JSON (is_error / subtype / result)
#   grok    — Grok's native buffered json (text / stopReason)
#   default — no result object at all (plain provider stdout)
# This locks the honest outcome vocabulary — finished | max_turns | no_start |
# error — across all three, using synthetic logs only (no network, no CLI).

set -euo pipefail

PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SPRINTBIAS="$ROOT/docs/sprintbias"

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc"
    printf '    expected: %q\n' "$expected"
    printf '    actual:   %q\n' "$actual"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== test-run-interpret.sh ==="

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# interpret_run under a chosen profile; echoes the five record fields the
# audits consume, one per line, so a subshell keeps each profile's sourced
# functions isolated from the next.
interp() {
  local cli="$1" log="$2" rc="${3:-}"
  SPRINTBIAS_CLI="$cli" bash -c '
    set -euo pipefail
    export SPRINTBIAS_CLI="$1"
    source "'"$SPRINTBIAS"'/lib.sh"
    sprintbias_interpret_run "$2" "$3"
    printf "%s\n" "$SPRINTBIAS_RUN_OUTCOME"
    printf "%s\n" "$SPRINTBIAS_RUN_TURNS"
    printf "%s\n" "$SPRINTBIAS_RUN_COST"
  ' _ "$cli" "$log" "$rc"
}

echo "Test 1: grok end_turn → finished, carries turns/cost from Grok keys"
printf '%s' '{"text":"done\nVERDICT: PASS","stopReason":"end_turn","num_turns":4,"total_cost_usd":0.05}' > "$TMPDIR/g-fin.json"
out=$(interp grok "$TMPDIR/g-fin.json")
assert_eq "outcome finished" "finished" "$(sed -n 1p <<<"$out")"
assert_eq "turns from num_turns" "4"        "$(sed -n 2p <<<"$out")"
assert_eq "cost from total_cost_usd" "0.05" "$(sed -n 3p <<<"$out")"

echo "Test 2: grok cancelled (max-turns exhaustion) → max_turns, NOT finished"
printf '%s' '{"text":"working...","stopReason":"cancelled","num_turns":1,"total_cost_usd":0.01}' > "$TMPDIR/g-cancel.json"
assert_eq "cancelled → max_turns" "max_turns" "$(sed -n 1p <<<"$(interp grok "$TMPDIR/g-cancel.json")")"

echo "Test 3: grok has no is_error key — a bare Claude-shaped read would call this finished"
# Regression guard: the old fallback saw no is_error and printed finished.
printf '%s' '{"text":"x","stopReason":"cancelled","num_turns":9,"total_cost_usd":0.9}' > "$TMPDIR/g-reg.json"
assert_eq "grok owns its shape (not finished)" "max_turns" "$(sed -n 1p <<<"$(interp grok "$TMPDIR/g-reg.json")")"

echo "Test 4: grok empty log → no_start"
: > "$TMPDIR/empty.log"
assert_eq "empty → no_start" "no_start" "$(sed -n 1p <<<"$(interp grok "$TMPDIR/empty.log")")"

echo "Test 5: default plain-text log with output → finished (verdict grep still works)"
printf 'did the work\nVERDICT: PASS\n' > "$TMPDIR/d-fin.log"
out=$(interp someunknowncli "$TMPDIR/d-fin.log")
assert_eq "default finished" "finished" "$(sed -n 1p <<<"$out")"
assert_eq "default turns unknown (empty, not faked 0)" "" "$(sed -n 2p <<<"$out")"
assert_eq "default cost unknown (empty, not faked 0)"  "" "$(sed -n 3p <<<"$out")"

echo "Test 6: default non-zero rc → error (honest failure, was silently 'finished')"
printf 'partial output before crash\n' > "$TMPDIR/d-err.log"
assert_eq "rc=1 → error" "error" "$(sed -n 1p <<<"$(interp someunknowncli "$TMPDIR/d-err.log" 1)")"

echo "Test 7: default empty log → no_start"
assert_eq "empty → no_start" "no_start" "$(sed -n 1p <<<"$(interp someunknowncli "$TMPDIR/empty.log")")"

echo "Test 8: claude result JSON still reads via its own profile (unchanged)"
printf '%s' '{"is_error":true,"subtype":"error_max_turns","num_turns":7,"total_cost_usd":0.3,"result":"ran"}' > "$TMPDIR/c-mt.json"
assert_eq "claude error_max_turns → max_turns" "max_turns" "$(sed -n 1p <<<"$(interp claude "$TMPDIR/c-mt.json")")"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
