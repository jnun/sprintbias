#!/usr/bin/env bash
# Test: `work plan N` narrows the queue to plan N's members in next/; every
# other next/ task stays put, ungated and unworked. Pre-AI paths only.
#
# Discovered by run-all.sh (test-*.sh). Pure shell.

set -euo pipefail

PASS=0
FAIL=0
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="$REPO/docs/sprintbias/scripts/work.sh"

BOARD=$(mktemp -d)
trap 'rm -rf "$BOARD"' EXIT
mkdir -p "$BOARD/docs/tasks/"{backlog,next,doing,blocked,review,done} "$BOARD/docs/plans" \
  "$BOARD/docs/sprintbias" "$BOARD/docs/tmp"
cd "$BOARD"

for id in 7101 7102; do
  printf '# Task %s: probe\n\n**Status: READY**\n\nBody.\n' "$id" > "docs/tasks/next/$id-probe.md"
done
printf '# Plan 71: probe\n\n- #7102 — probe\n' > docs/plans/71-probe.md
printf '# Plan 72: empty\n\n- #7199 — not in next\n' > docs/plans/72-empty.md

assert_eq() {
  if [ "$2" = "$3" ]; then echo "  PASS: $1"; PASS=$((PASS + 1))
  else echo "  FAIL: $1 (expected '$2', got '$3')"; FAIL=$((FAIL + 1)); fi
}
assert_contains() {
  if grep -qF "$3" <<<"$2"; then echo "  PASS: $1"; PASS=$((PASS + 1))
  else echo "  FAIL: $1 (expected '$3' in '$2')"; FAIL=$((FAIL + 1)); fi
}
run() { set +e; out="$(bash "$WORK" "$@" 2>&1 </dev/null)"; rc=$?; set -e; }

echo "=== test-work-plan.sh ==="

# The queue helper, pulled verbatim from work.sh: only plan 71's member queues.
# shellcheck source=/dev/null
source "$REPO/docs/sprintbias/lib.sh"
eval "$(awk '/^_queue_files\(\) \{/{g=1} g{print} g&&/^\}/{exit}' "$WORK")"
NEXT_DIR=docs/tasks/next PLAN_ID=71 _PLAN_MEMBERS=" 7102 "
assert_eq "plan 71 queues only its member" "docs/tasks/next/7102-probe.md" "$(_queue_files)"
PLAN_ID=""
assert_eq "no plan queues all of next/" "2" "$(_queue_files | wc -l | tr -d ' ')"

run plan 72
assert_eq "a plan with nothing in next/ exits 0" "0" "$rc"
assert_contains "…and points at plan check" "$out" "plan check 72"
assert_eq "other next/ tasks stay put" "2" "$(ls docs/tasks/next | wc -l | tr -d ' ')"

run plan 79
assert_eq "an unknown plan exits 1" "1" "$rc"
run plan
assert_eq "plan without a number exits 1" "1" "$rc"
run plan 71 7101
assert_eq "a plan and a task id together exit 1" "1" "$rc"

# A member in backlog/ brings plan start in first (emit mode: no live AI).
printf '# Task 7301: probe\n\n**Depends on**: none\n\nBody.\n' > docs/tasks/backlog/7301-probe.md
printf '# Plan 73: backlog\n\n**Status:** READY\n\n- #7301 — probe\n' > docs/plans/73-backlog.md
SPRINTBIAS_MODE=emit run plan 73
assert_eq "a backlog member exits 0 after the emitted start" "0" "$rc"
assert_contains "…says it starts the plan first" "$out" "starting it first"
assert_contains "…and hands back the re-run" "$out" "work plan 73"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
