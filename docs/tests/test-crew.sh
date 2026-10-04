#!/usr/bin/env bash
# Test: crew.sh
# Covers crew add, list (with held tasks), name checks, and the prompt a
# member and a lead start with (emit mode, so no AI CLI runs).

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_UNDER_TEST="$(cd "$(dirname "$0")/../sprintbias/scripts" && pwd)/crew.sh"
SPRINTBIAS_SRC="$(cd "$(dirname "$0")/../sprintbias" && pwd)"
DOCS_SRC="$(cd "$(dirname "$0")/.." && pwd)"

setup() {
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    mkdir -p "$TMPDIR/docs/sprintbias/scripts" "$TMPDIR/docs/crew" "$TMPDIR/docs/plans"
    for s in backlog next doing blocked review "done"; do mkdir -p "$TMPDIR/docs/tasks/$s"; done

    cp "$SCRIPT_UNDER_TEST" "$TMPDIR/docs/sprintbias/scripts/crew.sh"
    cp "$SPRINTBIAS_SRC/lib.sh" "$TMPDIR/docs/sprintbias/lib.sh"
    cp -R "$SPRINTBIAS_SRC/cli" "$TMPDIR/docs/sprintbias/cli"
    cp "$DOCS_SRC/crew/.TEMPLATE-crew.md" "$TMPDIR/docs/crew/.TEMPLATE-crew.md"
    printf '**sprint_TASK_ID**: 0\n' > "$TMPDIR/docs/sprintbias/DOC_STATE.md"

    git -C "$TMPDIR" init -q
}

crew() { (cd "$TMPDIR" && SPRINTBIAS_MODE=emit bash docs/sprintbias/scripts/crew.sh "$@" 2>&1); }

assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if printf '%s' "$haystack" | grep -qF -- "$needle"; then
        echo "  PASS: $desc"; PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected to contain '$needle')"; FAIL=$((FAIL + 1))
    fi
}

assert_not_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if printf '%s' "$haystack" | grep -qF -- "$needle"; then
        echo "  FAIL: $desc (did not expect '$needle')"; FAIL=$((FAIL + 1))
    else
        echo "  PASS: $desc"; PASS=$((PASS + 1))
    fi
}

assert_fails() {
    local desc="$1"; shift
    if crew "$@" >/dev/null; then
        echo "  FAIL: $desc (expected non-zero exit)"; FAIL=$((FAIL + 1))
    else
        echo "  PASS: $desc"; PASS=$((PASS + 1))
    fi
}

echo "=== test-crew.sh ==="
setup

echo "Test 1: empty crew explains how to start"
out="$(crew)"
assert_contains "Empty list hints at crew add" "$out" "crew add lead"

echo "Test 2: add writes name, role and lead flag"
crew add orcha "Keeps everyone rowing & routes tasks / plans" --lead >/dev/null
crew add dill "Finds and fixes bugs" >/dev/null
f="$TMPDIR/docs/crew/orcha.md"
assert_contains "Title uses the display name" "$(cat "$f")" "# Crew: Orcha"
assert_contains "Role keeps & and / literally" "$(cat "$f")" "**Role**: Keeps everyone rowing & routes tasks / plans"
assert_contains "Lead flag set" "$(cat "$f")" "**Lead**: yes"
assert_contains "Non-lead flag" "$(cat "$TMPDIR/docs/crew/dill.md")" "**Lead**: no"

echo "Test 3: bad and duplicate names are refused"
assert_fails "Uppercase name refused" add Dill "x"
assert_fails "Reserved name refused" add list "x"
assert_fails "Duplicate refused" add dill "x"
assert_fails "Missing role refused" add newbie

echo "Test 4: list shows who holds what"
printf '# Task 7: Fix the upload\n\n**Crew**: dill\n' > "$TMPDIR/docs/tasks/doing/7-fix-the-upload.md"
printf '# Task 8: Something else\n\n**Crew**: none\n' > "$TMPDIR/docs/tasks/next/8-something-else.md"
out="$(crew)"
assert_contains "Lead is marked" "$out" "orcha"
assert_contains "Lead label" "$out" "(lead)"
assert_contains "Held task listed" "$out" "doing/  7  Fix the upload"
assert_not_contains "Unrouted task not listed" "$out" "Something else"

echo "Test 5: a member starts with the crew rules and its target"
out="$(crew dill 7)"
assert_contains "Names the member" "$out" "You are dill"
assert_contains "Points at the member file" "$out" "docs/crew/dill.md"
assert_contains "Names the task" "$out" "Your work is task 7"
assert_contains "Claim rule" "$out" "set its **Crew** field to dill"
assert_not_contains "No lead rules for a member" "$out" "You lead this crew"

echo "Test 6: the lead gets lead rules on a plan"
printf '# Plan 3: Upload fixes\n\n**Status:** STARTED\n' > "$TMPDIR/docs/plans/3-upload-fixes.md"
out="$(crew orcha plan:3)"
assert_contains "Lead rules" "$out" "You lead this crew"
assert_contains "Plan target" "$out" "Your work is plan 3"

echo "Test 7: unknown member, task and plan fail"
assert_fails "Unknown member" nobody
assert_fails "Unknown task" dill 999
assert_fails "Unknown plan" orcha plan:99

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
