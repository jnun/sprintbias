#!/usr/bin/env bash
# Test: create-task.sh
# Tests task creation, DOC_STATE.md updates, error cases

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_UNDER_TEST="$(cd "$(dirname "$0")/../sprintbias/scripts" && pwd)/create-task.sh"
SPRINTBIAS_SRC="$(cd "$(dirname "$0")/../sprintbias" && pwd)"
DOCS_SRC="$(cd "$(dirname "$0")/.." && pwd)"

setup() {
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    # Create project structure
    mkdir -p "$TMPDIR/docs/sprintbias/scripts"
    mkdir -p "$TMPDIR/docs/tasks/backlog"

    # Copy script into correct location
    cp "$SCRIPT_UNDER_TEST" "$TMPDIR/docs/sprintbias/scripts/create-task.sh"
    # The script sources lib.sh (which loads a cli/ provider profile) and reads
    # the task template at runtime — provide all three or it aborts.
    cp "$SPRINTBIAS_SRC/lib.sh" "$TMPDIR/docs/sprintbias/lib.sh"
    cp -R "$SPRINTBIAS_SRC/cli" "$TMPDIR/docs/sprintbias/cli"
    cp "$DOCS_SRC/tasks/.TEMPLATE-task.md" "$TMPDIR/docs/tasks/.TEMPLATE-task.md"

    # Create minimal DOC_STATE.md
    cat > "$TMPDIR/docs/sprintbias/DOC_STATE.md" << 'EOF'
# SprintBias Documentation State

**Last Updated**: 2026-01-01
**sprint_VERSION**: 2.2.0
**sprint_TASK_ID**: 10
**sprint_BUG_ID**: 1
EOF

    # Init git so `git add` works
    git -C "$TMPDIR" init -q
}

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected '$expected', got '$actual')"
        FAIL=$((FAIL + 1))
    fi
}

assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if echo "$haystack" | grep -qF "$needle"; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected to contain '$needle')"
        FAIL=$((FAIL + 1))
    fi
}

assert_file_exists() {
    local desc="$1" path="$2"
    if [ -f "$path" ]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (file not found: $path)"
        FAIL=$((FAIL + 1))
    fi
}

# --- Tests ---

echo "=== test-create-task.sh ==="

# Test 1: Happy path — creates task file
echo "Test 1: Happy path creates task file"
setup
(cd "$TMPDIR" && bash docs/sprintbias/scripts/create-task.sh "Fix login bug" > /dev/null 2>&1)
assert_file_exists "Task file created" "$TMPDIR/docs/tasks/backlog/11-fix-login-bug.md"

# Test 2: Task file contains correct title
echo "Test 2: Task file has correct title"
content=$(cat "$TMPDIR/docs/tasks/backlog/11-fix-login-bug.md")
assert_contains "Title has task ID" "$content" "# Task 11: Fix login bug"

# Test 3: DOC_STATE.md updated with new ID
echo "Test 3: DOC_STATE.md updated"
state=$(cat "$TMPDIR/docs/sprintbias/DOC_STATE.md")
assert_contains "Task ID incremented to 11" "$state" "**sprint_TASK_ID**: 11"

# Test 4: Feature reference defaults to none
echo "Test 4: Feature defaults to none"
assert_contains "Feature is none" "$content" '**Feature**: none'

# Test 5: Happy path with feature argument
echo "Test 5: Task with feature argument"
setup
(cd "$TMPDIR" && bash docs/sprintbias/scripts/create-task.sh "Add auth flow" "user-auth" > /dev/null 2>&1)
content=$(cat "$TMPDIR/docs/tasks/backlog/11-add-auth-flow.md")
assert_contains "Feature reference set" "$content" '**Feature**: /docs/features/user-auth.md'

# Test 6: Missing description — should fail
echo "Test 6: Missing description exits 1"
setup
if (cd "$TMPDIR" && bash docs/sprintbias/scripts/create-task.sh "" > /dev/null 2>&1); then
    echo "  FAIL: Should have exited non-zero"
    FAIL=$((FAIL + 1))
else
    echo "  PASS: Exits non-zero on empty description"
    PASS=$((PASS + 1))
fi

# Test 7: Missing DOC_STATE.md — should fail
echo "Test 7: Missing DOC_STATE.md exits 1"
setup
rm "$TMPDIR/docs/sprintbias/DOC_STATE.md"
if (cd "$TMPDIR" && bash docs/sprintbias/scripts/create-task.sh "Some task" > /dev/null 2>&1); then
    echo "  FAIL: Should have exited non-zero"
    FAIL=$((FAIL + 1))
else
    echo "  PASS: Exits non-zero without DOC_STATE.md"
    PASS=$((PASS + 1))
fi

# Test 8: Long description truncated
echo "Test 8: Long description truncated to 50 chars"
setup
long_desc="This is a very long task description that exceeds the fifty character filename limit"
(cd "$TMPDIR" && bash docs/sprintbias/scripts/create-task.sh "$long_desc" > /dev/null 2>&1)
# Find created file
created=$(ls "$TMPDIR/docs/tasks/backlog/" 2>/dev/null | head -1)
assert_eq "File was created" "true" "$([ -n "$created" ] && echo true || echo false)"

# Test 9: Created date is today
echo "Test 9: Created date is today"
setup
(cd "$TMPDIR" && bash docs/sprintbias/scripts/create-task.sh "Date test" > /dev/null 2>&1)
content=$(cat "$TMPDIR/docs/tasks/backlog/11-date-test.md")
today=$(date +%Y-%m-%d)
assert_contains "Created date is today" "$content" "**Created**: $today"

# --- Summary ---
# --from-plan N stamps **From plan** (both spellings); bad id is refused
echo "Test: --from-plan marks a follow-up from a plan"
setup
(cd "$TMPDIR" && bash docs/sprintbias/scripts/create-task.sh "Rework the login copy" --from-plan 24 >/dev/null 2>&1)
_f=$(ls "$TMPDIR"/docs/tasks/backlog/*rework-the-login-copy.md 2>/dev/null | head -1)
assert_eq "From plan stamped" "**From plan**: 24" "$(grep -m1 '^\*\*From plan\*\*' "$_f")"
assert_eq "description is not swallowed by the flag" "1" "$(grep -c '^# Task .*: Rework the login copy$' "$_f")"
(cd "$TMPDIR" && bash docs/sprintbias/scripts/create-task.sh --from-plan=7 "Retry on expiry" >/dev/null 2>&1)
_f=$(ls "$TMPDIR"/docs/tasks/backlog/*retry-on-expiry.md 2>/dev/null | head -1)
assert_eq "--from-plan=N form works" "**From plan**: 7" "$(grep -m1 '^\*\*From plan\*\*' "$_f")"
rc=0
out=$(cd "$TMPDIR" && bash docs/sprintbias/scripts/create-task.sh "Bad" --from-plan x 2>&1) || rc=$?
assert_eq "non-numeric plan id exits 1" "1" "$rc"
assert_contains "says what is wrong" "$out" "needs a plan id"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
