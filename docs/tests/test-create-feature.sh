#!/usr/bin/env bash
# Test: create-feature.sh
# Tests feature creation and error cases

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_UNDER_TEST="$(cd "$(dirname "$0")/../sprintbias/scripts" && pwd)/create-feature.sh"
SPRINTBIAS_SRC="$(cd "$(dirname "$0")/../sprintbias" && pwd)"
DOCS_SRC="$(cd "$(dirname "$0")/.." && pwd)"

setup() {
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    mkdir -p "$TMPDIR/docs/sprintbias/scripts"
    mkdir -p "$TMPDIR/docs/features"

    cp "$SCRIPT_UNDER_TEST" "$TMPDIR/docs/sprintbias/scripts/create-feature.sh"
    # The script sources lib.sh (which loads a cli/ provider profile) and reads
    # the feature template at runtime — provide all three or it aborts.
    cp "$SPRINTBIAS_SRC/lib.sh" "$TMPDIR/docs/sprintbias/lib.sh"
    cp -R "$SPRINTBIAS_SRC/cli" "$TMPDIR/docs/sprintbias/cli"
    cp "$DOCS_SRC/features/.TEMPLATE-feature.md" "$TMPDIR/docs/features/.TEMPLATE-feature.md"

    git -C "$TMPDIR" init -q
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

echo "=== test-create-feature.sh ==="

# Test 1: Happy path — creates feature file
echo "Test 1: Happy path creates feature file"
setup
(cd "$TMPDIR" && bash docs/sprintbias/scripts/create-feature.sh "User Authentication" > /dev/null 2>&1)
assert_file_exists "Feature file created" "$TMPDIR/docs/features/user-authentication.md"

# Test 2: Feature file contains correct title
echo "Test 2: Feature file has correct title"
content=$(cat "$TMPDIR/docs/features/user-authentication.md")
assert_contains "Title correct" "$content" "# Feature: User Authentication"

# Test 3: Feature file has required sections
echo "Test 3: Feature file has required sections"
assert_contains "Status field" "$content" "**Status:** BACKLOG"
assert_contains "Overview section" "$content" "## Overview"
assert_contains "User Stories section" "$content" "## User Stories"
assert_contains "Requirements section" "$content" "## Requirements"
assert_contains "Acceptance Criteria section" "$content" "## Acceptance Criteria"

# Test 4: Created date is today
echo "Test 4: Created date is today"
today=$(date +%Y-%m-%d)
assert_contains "Created date" "$content" "**Created:** $today"

# Test 5: No name launches the AI-assisted Q&A instead of erroring.
# With no argument the script drops into interactive feature definition; in
# emit mode (no CLI spawned) it prints the Q&A prompt and exits 0.
echo "Test 5: Empty name launches Q&A"
setup
rc=0
output=$(cd "$TMPDIR" && SPRINTBIAS_MODE=emit bash docs/sprintbias/scripts/create-feature.sh "" 2>&1) || rc=$?
if [ "$rc" -eq 0 ]; then
    echo "  PASS: Q&A path exits 0"; PASS=$((PASS + 1))
else
    echo "  FAIL: Q&A path expected exit 0, got $rc"; FAIL=$((FAIL + 1))
fi
assert_contains "Starts feature Q&A" "$output" "feature definition Q&A"

# Test 6: Duplicate feature — should fail
echo "Test 6: Duplicate feature exits 1"
setup
(cd "$TMPDIR" && bash docs/sprintbias/scripts/create-feature.sh "Payments" > /dev/null 2>&1)
if (cd "$TMPDIR" && bash docs/sprintbias/scripts/create-feature.sh "Payments" > /dev/null 2>&1); then
    echo "  FAIL: Should have exited non-zero for duplicate"
    FAIL=$((FAIL + 1))
else
    echo "  PASS: Exits non-zero on duplicate feature"
    PASS=$((PASS + 1))
fi

# Test 7: Kebab-case conversion
echo "Test 7: Name converted to kebab-case"
setup
(cd "$TMPDIR" && bash docs/sprintbias/scripts/create-feature.sh "My Cool Feature" > /dev/null 2>&1)
assert_file_exists "Kebab-case filename" "$TMPDIR/docs/features/my-cool-feature.md"

# --- Summary ---
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
