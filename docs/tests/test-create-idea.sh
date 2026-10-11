#!/usr/bin/env bash
# Test: create-idea.sh
# Tests idea creation and error cases

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_UNDER_TEST="$(cd "$(dirname "$0")/../sprintbias/scripts" && pwd)/create-idea.sh"
SPRINTBIAS_SRC="$(cd "$(dirname "$0")/../sprintbias" && pwd)"
DOCS_SRC="$(cd "$(dirname "$0")/.." && pwd)"

setup() {
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    mkdir -p "$TMPDIR/docs/sprintbias/scripts"
    mkdir -p "$TMPDIR/docs/ideas"

    cp "$SCRIPT_UNDER_TEST" "$TMPDIR/docs/sprintbias/scripts/create-idea.sh"
    # The script sources lib.sh (which loads a cli/ provider profile) and reads
    # the idea template at runtime — provide all three or it aborts.
    cp "$SPRINTBIAS_SRC/lib.sh" "$TMPDIR/docs/sprintbias/lib.sh"
    cp -R "$SPRINTBIAS_SRC/cli" "$TMPDIR/docs/sprintbias/cli"
    cp "$DOCS_SRC/ideas/.TEMPLATE-idea.md" "$TMPDIR/docs/ideas/.TEMPLATE-idea.md"

    git -C "$TMPDIR" init -q
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

echo "=== test-create-idea.sh ==="

# Test 1: Happy path — creates idea file
echo "Test 1: Happy path creates idea file"
setup
(cd "$TMPDIR" && bash docs/sprintbias/scripts/create-idea.sh "AI Code Review" > /dev/null 2>&1)
assert_file_exists "Idea file created" "$TMPDIR/docs/ideas/ai-code-review.md"

# Test 2: Idea file contains correct title
echo "Test 2: Idea file has correct title"
content=$(cat "$TMPDIR/docs/ideas/ai-code-review.md")
assert_contains "Title correct" "$content" "# Idea: AI Code Review"

# Test 3: Idea file has the eight-phase Feynman scaffold
echo "Test 3: Idea file has Feynman phases"
assert_contains "Phase 1" "$content" "## Phase 1: The Spark"
assert_contains "Phase 2" "$content" "## Phase 2: The Problem"
assert_contains "Phase 5" "$content" "## Phase 5: The Bet"
assert_contains "Phase 8" "$content" "## Phase 8: The Handoff"

# Test 4: Status is DRAFT
echo "Test 4: Status is DRAFT"
assert_contains "Status DRAFT" "$content" "**Status:** DRAFT"

# Test 5: Created date is today
echo "Test 5: Created date is today"
today=$(date +%Y-%m-%d)
assert_contains "Created date" "$content" "**Created:** $today"

# Test 6: No name launches the AI-assisted refinement session instead of
# erroring. With no argument the script drops into the interactive Feynman
# session; in emit mode (no CLI spawned) it prints the prompt and exits 0.
echo "Test 6: Empty name launches refinement session"
setup
rc=0
output=$(cd "$TMPDIR" && SPRINTBIAS_MODE=emit bash docs/sprintbias/scripts/create-idea.sh "" 2>&1) || rc=$?
if [ "$rc" -eq 0 ]; then
    echo "  PASS: Session path exits 0"; PASS=$((PASS + 1))
else
    echo "  FAIL: Session path expected exit 0, got $rc"; FAIL=$((FAIL + 1))
fi
assert_contains "Starts idea session" "$output" "idea refinement session"

# Test 7: Duplicate idea — should fail
echo "Test 7: Duplicate idea exits 1"
setup
(cd "$TMPDIR" && bash docs/sprintbias/scripts/create-idea.sh "Caching" > /dev/null 2>&1)
if (cd "$TMPDIR" && bash docs/sprintbias/scripts/create-idea.sh "Caching" > /dev/null 2>&1); then
    echo "  FAIL: Should have exited non-zero for duplicate"
    FAIL=$((FAIL + 1))
else
    echo "  PASS: Exits non-zero on duplicate idea"
    PASS=$((PASS + 1))
fi

# --- Summary ---
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
