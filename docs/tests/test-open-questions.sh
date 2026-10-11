#!/usr/bin/env bash
# Test: open-question detector, accept-suggestions, demote READY+openQ invariant
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SPRINTBIAS="$ROOT/docs/sprintbias"
# shellcheck source=/dev/null
source "$SPRINTBIAS/lib.sh"
# shellcheck source=/dev/null
source "$SPRINTBIAS/scripts/gate-lib.sh"

PASS=0
FAIL=0
assert_eq() {
  local name="$1" want="$2" got="$3"
  if [ "$want" = "$got" ]; then
    echo "  PASS: $name"; PASS=$((PASS + 1))
  else
    echo "  FAIL: $name (want='$want' got='$got')"; FAIL=$((FAIL + 1))
  fi
}
assert_true() {
  local name="$1"; shift
  if "$@"; then echo "  PASS: $name"; PASS=$((PASS + 1))
  else echo "  FAIL: $name"; FAIL=$((FAIL + 1)); fi
}
assert_false() {
  local name="$1"; shift
  if "$@"; then echo "  FAIL: $name (expected false)"; FAIL=$((FAIL + 1))
  else echo "  PASS: $name"; PASS=$((PASS + 1)); fi
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/docs/tasks/next" "$TMP/docs/tasks/blocked"
cd "$TMP"

echo "=== test-open-questions.sh ==="

echo "Test 1: sentinel detection (mid-line resolved, leading none)"
cat > docs/tasks/next/1-sample.md <<'EOF'
# Task 1: Sample

## Questions

**Status: READY**

### Questions for the developer

1. Shell donor — resolved centrally in the design standard.
2. (resolved) old note
3. None — task is fully defined. (should not match list form alone)
4. Real open question? (Suggestion: pick A because it matches criteria.)
EOF
# Item 3 is a list item starting with "None" — sentinel at first word after marker
# Item 4 is open with suggestion
n=$(sprintbias_open_questions docs/tasks/next/1-sample.md | grep -c . || true)
assert_eq "only real open Q remains" "1" "$n"
assert_true "has_open_questions" sprintbias_has_open_questions docs/tasks/next/1-sample.md
q=$(sprintbias_open_questions docs/tasks/next/1-sample.md)
case "$q" in *"Real open question"*) echo "  PASS: real Q kept"; PASS=$((PASS+1)) ;;
  *) echo "  FAIL: real Q missing ($q)"; FAIL=$((FAIL+1)) ;;
esac

echo "Test 2: accept suggestions folds and clears"
sprintbias_accept_suggestions docs/tasks/next/1-sample.md >/tmp/settle-out.$$
got=$(cat /tmp/settle-out.$$); rm -f /tmp/settle-out.$$
assert_eq "accept prints settled=1 remaining=0" "settled=1 remaining=0" "$got"
assert_false "no open questions after accept" sprintbias_has_open_questions docs/tasks/next/1-sample.md
assert_true "Notes has Settled" grep -q 'Settled (accept suggestions)' docs/tasks/next/1-sample.md
assert_true "None line written" grep -q 'None — task is fully defined' docs/tasks/next/1-sample.md

echo "Test 3: demote READY + open Q out of next/"
cat > docs/tasks/next/2-open.md <<'EOF'
# Task 2: Open

## Questions

**Status: READY**

### Questions for the developer

1. Needs a human with no suggestion at all?
EOF
assert_true "demote returns 0" sprintbias_demote_open_questions docs/tasks/next/2-open.md docs/tasks/blocked
assert_true "moved to blocked/" test -f docs/tasks/blocked/2-open.md
assert_false "gone from next/" test -f docs/tasks/next/2-open.md
assert_eq "stamp is BLOCKED" "BLOCKED" "$(sprintbias_review_verdict docs/tasks/blocked/2-open.md)"
assert_true "BLOCKED section present" grep -q '^## BLOCKED' docs/tasks/blocked/2-open.md

echo "Test 4: sweep takes suggested answers, demotes only the rest"
cat > docs/tasks/next/3-a.md <<'EOF'
# Task 3

## Questions
**Status: READY**
### Questions for the developer
1. Still open A? (Suggestion: do A.)
EOF
cat > docs/tasks/next/4-b.md <<'EOF'
# Task 4

## Questions
**Status: READY**
### Questions for the developer
1. Still open B without suggestion?
EOF
cat > docs/tasks/next/5-clean.md <<'EOF'
# Task 5

## Questions
**Status: READY**
### Questions for the developer
None — task is fully defined.
EOF
sprintbias_sweep_ready_open_questions docs/tasks/next docs/tasks/blocked
assert_eq "sweep demoted count" "1" "${SPRINTBIAS_SWEEP_DEMOTED:-}"
assert_true "clean READY stays in next/" test -f docs/tasks/next/5-clean.md
assert_true "3 (suggested answer) stays in next/" test -f docs/tasks/next/3-a.md
assert_false "4 demoted" test -f docs/tasks/next/4-b.md
assert_true "4 in blocked" test -f docs/tasks/blocked/4-b.md

echo "Test 5: demote takes each suggestion and demotes only what is left"
# put a suggestion task back in next/
cat > docs/tasks/next/6-sug.md <<'EOF'
# Task 6

## Notes

Optional hint.

## Questions

**Status: READY**

### Questions for the developer

1. Draw the meter line? (Suggestion: draw it; criteria already require it.)
2. Human only — no suggestion here?
EOF
# settle (retired in plan 32) did this by hand; the gate, work and the demote
# helper now take each suggestion on their own. Same outcome, one path.
demote_out="$(sprintbias_demote_open_questions docs/tasks/next/6-sug.md docs/tasks/blocked 2>&1 || true)"
# Q1 had a suggestion → taken; Q2 had none → task demoted to blocked
assert_true "6 demoted to blocked (remaining human Q)" test -f docs/tasks/blocked/6-sug.md
assert_true "human Q still open on demoted file" sprintbias_has_open_questions docs/tasks/blocked/6-sug.md
assert_true "Notes got Settled header" grep -q 'Settled (accept suggestions)' docs/tasks/blocked/6-sug.md
assert_true "Q1 suggestion folded (not only still in a question)" \
  grep -q 'Settled (accept suggestions)' docs/tasks/blocked/6-sug.md \
  && grep -q 'draw it' docs/tasks/blocked/6-sug.md
assert_true "Demote message names chat <id>" grep -q './sprint.sh chat 6' <<<"$demote_out"
assert_true "Demote message names work <id>" grep -q './sprint.sh work 6' <<<"$demote_out"
assert_false "Demote message names no settle" grep -q 'sprint.sh settle' <<<"$demote_out"
assert_true "BLOCKED section ends in the next commands" \
  grep -q './sprint.sh chat 6 — then run it: ./sprint.sh work 6' docs/tasks/blocked/6-sug.md

echo "Test 6: a suggested answer never holds a task (demote takes it)"
cat > docs/tasks/next/7-fast.md <<'EOF'
# Task 7

## Questions

**Status: READY**

### Questions for the developer

1. Lucide or emoji? (Suggestion: Lucide; the design standard picks it.)
EOF
assert_false "not demoted when every Q has a suggestion" \
  sprintbias_demote_open_questions docs/tasks/next/7-fast.md docs/tasks/blocked 2>/dev/null
assert_true "7 stays in next/" test -f docs/tasks/next/7-fast.md
assert_false "7 has no open questions left" sprintbias_has_open_questions docs/tasks/next/7-fast.md
assert_true "7 records the call in Notes" grep -q 'Lucide; the design standard' docs/tasks/next/7-fast.md

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
