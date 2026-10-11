#!/usr/bin/env bash
# Test: create-bug.sh
# Tests bug creation, DOC_STATE.md updates, error cases

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_UNDER_TEST="$(cd "$(dirname "$0")/../sprintbias/scripts" && pwd)/create-bug.sh"
SPRINTBIAS_SRC="$(cd "$(dirname "$0")/../sprintbias" && pwd)"
DOCS_SRC="$(cd "$(dirname "$0")/.." && pwd)"

setup() {
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    mkdir -p "$TMPDIR/docs/sprintbias/scripts"
    mkdir -p "$TMPDIR/docs/bugs"

    cp "$SCRIPT_UNDER_TEST" "$TMPDIR/docs/sprintbias/scripts/create-bug.sh"
    # The script sources lib.sh (which loads a cli/ provider profile) and reads
    # the bug template at runtime — provide all three or it aborts.
    cp "$SPRINTBIAS_SRC/lib.sh" "$TMPDIR/docs/sprintbias/lib.sh"
    cp -R "$SPRINTBIAS_SRC/cli" "$TMPDIR/docs/sprintbias/cli"
    cp "$DOCS_SRC/bugs/.TEMPLATE-bug.md" "$TMPDIR/docs/bugs/.TEMPLATE-bug.md"

    cat > "$TMPDIR/docs/sprintbias/DOC_STATE.md" << 'EOF'
# SprintBias Documentation State

**Last Updated**: 2026-01-01
**sprint_VERSION**: 2.2.0
**sprint_TASK_ID**: 10
**sprint_BUG_ID**: 5
EOF

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
    if grep -qF "$needle" <<<"$haystack"; then
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

echo "=== test-create-bug.sh ==="

# Test 1: Happy path — creates bug file
echo "Test 1: Happy path creates bug file"
setup
(cd "$TMPDIR" && bash docs/sprintbias/scripts/create-bug.sh "Login button broken" > /dev/null 2>&1)
assert_file_exists "Bug file created" "$TMPDIR/docs/bugs/6-login-button-broken.md"

# Test 2: Bug file contains correct title
echo "Test 2: Bug file has correct title"
content=$(cat "$TMPDIR/docs/bugs/6-login-button-broken.md")
assert_contains "Title has bug ID" "$content" "# Bug 6: Login button broken"

# Test 3: Bug file contains severity placeholder
echo "Test 3: Bug file has severity field"
assert_contains "Severity field present" "$content" "**Severity:**"

# Test 4: Bug file contains required sections
echo "Test 4: Bug file has required sections"
assert_contains "Problem section" "$content" "## Problem"
assert_contains "Steps to reproduce" "$content" "## Steps to reproduce"
assert_contains "Success criteria" "$content" "## Success criteria"

# Test 5: DOC_STATE.md updated with new bug ID
echo "Test 5: DOC_STATE.md updated"
state=$(cat "$TMPDIR/docs/sprintbias/DOC_STATE.md")
assert_contains "Bug ID incremented to 6" "$state" "**sprint_BUG_ID**: 6"

# Test 6: Missing description — should fail
echo "Test 6: Missing description exits 1"
setup
if (cd "$TMPDIR" && bash docs/sprintbias/scripts/create-bug.sh "" > /dev/null 2>&1); then
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
if (cd "$TMPDIR" && bash docs/sprintbias/scripts/create-bug.sh "Some bug" > /dev/null 2>&1); then
    echo "  FAIL: Should have exited non-zero"
    FAIL=$((FAIL + 1))
else
    echo "  PASS: Exits non-zero without DOC_STATE.md"
    PASS=$((PASS + 1))
fi

# Test 8: Created date is today
echo "Test 8: Created date is today"
setup
(cd "$TMPDIR" && bash docs/sprintbias/scripts/create-bug.sh "Date check" > /dev/null 2>&1)
content=$(cat "$TMPDIR/docs/bugs/6-date-check.md")
today=$(date +%Y-%m-%d)
assert_contains "Created date is today" "$content" "**Created**: $today"

# --- Summary ---
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
