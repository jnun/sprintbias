#!/usr/bin/env bash
# Test: a task's automated done-when section (plan 28 Policy).
#   - sprintbias_done_when reads '## Done when (automated)', and falls back to an
#     older '## Success criteria' so existing tasks keep working
#   - sprintbias_done_when_testable needs a test or command in backticks
#   - the gate (exec mode) refuses READY when Done when names no test or command
#   - plan check counts the old heading as defined
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
mkdir -p "$TMP/docs/tasks/backlog" "$TMP/docs/tasks/next" "$TMP/docs/tasks/blocked" \
         "$TMP/docs/tasks/review" "$TMP/docs/tmp"
cd "$TMP"

echo "=== test-done-when.sh ==="

echo "Test 1: new heading is read, hint comments stripped"
cat > new.md <<'EOF'
# Task 1: New

## Problem

Login is broken.

## Done when (automated)

<!-- sb:hint  name the proving test in backticks (`npm test`) -->

- [ ] User can log in; `bash docs/tests/test-login.sh` passes

## Signoff (human)

- [ ] Log in on a phone
EOF
assert_eq "heading" "Done when (automated)" "$(sprintbias_done_when_heading new.md)"
body="$(sprintbias_done_when new.md | grep -v '^[[:space:]]*$')"
assert_eq "body is the one item" "- [ ] User can log in; \`bash docs/tests/test-login.sh\` passes" "$body"
assert_true "testable" sprintbias_done_when_testable new.md

echo "Test 2: old ## Success criteria reads as Done when (automated)"
cat > old.md <<'EOF'
# Task 2: Old

## Success criteria

- [ ] Export completes; `npm test -- export` passes

## Notes

- [ ] not a criterion
EOF
assert_eq "fallback heading" "Success criteria" "$(sprintbias_done_when_heading old.md)"
assert_eq "fallback body" "- [ ] Export completes; \`npm test -- export\` passes" \
  "$(sprintbias_done_when old.md | grep -v '^[[:space:]]*$')"
assert_true "fallback testable" sprintbias_done_when_testable old.md

echo "Test 3: both headings — the new one wins"
cat > both.md <<'EOF'
## Success criteria

- [ ] old item

## Done when (automated)

- [ ] new item
EOF
assert_eq "new wins" "- [ ] new item" "$(sprintbias_done_when both.md | grep -v '^[[:space:]]*$')"

echo "Test 4: neither heading — empty body, writers get the new heading"
printf '# Task 4\n\n## Problem\n\nx\n' > none.md
assert_eq "empty body" "" "$(sprintbias_done_when none.md)"
_heading_quiet() { sprintbias_done_when_heading "$1" >/dev/null; }
assert_false "heading reports missing" _heading_quiet none.md
assert_eq "writer heading" "Done when (automated)" "$(sprintbias_done_when_heading none.md || true)"

echo "Test 5: testable needs a backticked test or command"
printf '## Done when (automated)\n\n- [ ] Login works and is tested\n' > vague.md
assert_false "no command → not testable" sprintbias_done_when_testable vague.md
printf '## Done when (automated)\n\n- [ ] `## Problem` is filled\n' > headonly.md
assert_false "backticked heading only → not testable" sprintbias_done_when_testable headonly.md
cp "$ROOT/docs/tasks/.TEMPLATE-task.md" tpl.md
assert_false "fresh template → not testable (hint example does not count)" sprintbias_done_when_testable tpl.md
assert_eq "fresh template heading" "Done when (automated)" "$(sprintbias_done_when_heading tpl.md)"
assert_true "template has ## Signoff (human)" grep -q '^## Signoff (human)$' tpl.md

echo "Test 6: gate refuses READY without a testable Done when (automated)"
# Stub the model: exec mode, and a 'review' that stamps READY with no questions.
sprintbias_ai_mode() { echo exec; }
sprintbias_run() {
  local f
  f="$(ls docs/tasks/backlog/*.md docs/tasks/next/*.md 2>/dev/null | head -1)"
  printf '\n## Questions\n\n**Status: READY**\n\n### Questions for the developer\nNone — task is fully defined.\n' >> "$f"
  echo '{}'
}
cp vague.md docs/tasks/backlog/10-vague.md
sprintbias_promote_to_sprint docs/tasks/backlog/10-vague.md test 2>/dev/null
assert_eq "verdict BLOCKED" "BLOCKED" "$SPRINTBIAS_GATE_VERDICT"
assert_true "moved to blocked/" test -f docs/tasks/blocked/10-vague.md
assert_false "not in next/" test -f docs/tasks/next/10-vague.md
assert_eq "stamp rewritten" "BLOCKED" "$(sprintbias_review_verdict docs/tasks/blocked/10-vague.md)"
assert_true "## BLOCKED names the gap" grep -q 'names no test or command' docs/tasks/blocked/10-vague.md

echo "Test 7: gate passes READY with a testable Done when (new and old heading)"
cp new.md docs/tasks/backlog/11-new.md
sprintbias_promote_to_sprint docs/tasks/backlog/11-new.md test 2>/dev/null
assert_eq "new heading → READY" "READY" "$SPRINTBIAS_GATE_VERDICT"
assert_true "moved to next/" test -f docs/tasks/next/11-new.md
mv docs/tasks/next/11-new.md docs/tasks/review/
cp old.md docs/tasks/backlog/12-old.md
sprintbias_promote_to_sprint docs/tasks/backlog/12-old.md test 2>/dev/null
assert_eq "old heading → READY" "READY" "$SPRINTBIAS_GATE_VERDICT"
assert_true "old heading moved to next/" test -f docs/tasks/next/12-old.md

echo "Test 8: plan check reads the old heading as defined"
cd "$ROOT"
PC="$TMP/pc"
mkdir -p "$PC/docs/plans" "$PC/docs/tasks/backlog" "$PC/docs/sprintbias"
cp -R "$SPRINTBIAS/." "$PC/docs/sprintbias/"
printf '# Plan 1: p\n\n**Status:** DRAFT\n\n## Member tasks\n\n- #21\n- #22\n- #23\n' > "$PC/docs/plans/1-p.md"
sed 's/^# Task 2: Old/# Task 21: Old/' "$TMP/old.md" > "$PC/docs/tasks/backlog/21-old.md"
sed 's/^# Task 1: New/# Task 22: New/' "$TMP/new.md" > "$PC/docs/tasks/backlog/22-new.md"
sed 's/^# Task \[ID\]/# Task 23/' "$ROOT/docs/tasks/.TEMPLATE-task.md" > "$PC/docs/tasks/backlog/23-blank.md"
out="$(cd "$PC" && bash docs/sprintbias/scripts/plan-check.sh 1 </dev/null 2>&1 || true)"
line21="$(printf '%s\n' "$out" | grep -E '#?21\b' | head -1)"
line22="$(printf '%s\n' "$out" | grep -E '#?22\b' | head -1)"
line23="$(printf '%s\n' "$out" | grep -E '#?23\b' | head -1)"
assert_true "old heading → defined" grep -q 'defined' <<<"$line21"
assert_false "old heading not undefined" grep -q 'undefined' <<<"$line21"
assert_false "new heading not undefined" grep -q 'undefined' <<<"$line22"
assert_true "blank template → undefined" grep -q 'undefined' <<<"$line23"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
