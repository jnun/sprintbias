#!/usr/bin/env bash
# Test: cleanup-tmp.sh
# Tests scratch file cleanup: dry-run, --force, confirm prompt, stale detection.
# Every call feeds its answer or </dev/null so an open stdin never hangs the
# suite at the [y/N] prompt.

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_UNDER_TEST="$(cd "$(dirname "$0")/../sprintbias/scripts" && pwd)/cleanup-tmp.sh"
SPRINTBIAS_SRC="$(cd "$(dirname "$0")/../sprintbias" && pwd)"

setup() {
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    # cleanup-tmp.sh resolves PROJECT_ROOT from SCRIPT_DIR
    # If SCRIPT_DIR/docs/sprintbias/scripts exists, PROJECT_ROOT = SCRIPT_DIR
    mkdir -p "$TMPDIR/docs/sprintbias/scripts"
    mkdir -p "$TMPDIR/docs/tmp"

    cp "$SCRIPT_UNDER_TEST" "$TMPDIR/docs/sprintbias/scripts/cleanup-tmp.sh"
    # The script sources lib.sh (and lib.sh loads a cli/ provider profile),
    # so the temp tree must carry both or the `source` line aborts under set -e.
    cp "$SPRINTBIAS_SRC/lib.sh" "$TMPDIR/docs/sprintbias/lib.sh"
    cp -R "$SPRINTBIAS_SRC/cli" "$TMPDIR/docs/sprintbias/cli"
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

assert_exit_code() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected exit $expected, got $actual)"
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

assert_file_missing() {
    local desc="$1" path="$2"
    if [ ! -f "$path" ]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (file still exists: $path)"
        FAIL=$((FAIL + 1))
    fi
}

# --- Tests ---

echo "=== test-cleanup-tmp.sh ==="

# Test 1: Empty tmp dir — clean message, exit 0
echo "Test 1: Empty tmp dir is clean"
setup
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/cleanup-tmp.sh" </dev/null 2>&1) || rc=$?
assert_exit_code "Exits 0" "0" "$rc"
assert_contains "Clean message" "$output" "clean"

# Test 2: No tmp dir at all — handled gracefully
echo "Test 2: Missing tmp dir exits 0"
setup
rm -rf "$TMPDIR/docs/tmp"
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/cleanup-tmp.sh" </dev/null 2>&1) || rc=$?
assert_exit_code "Exits 0" "0" "$rc"
assert_contains "Not found message" "$output" "not found"

# Test 3: Dry run with stale files does not delete
echo "Test 3: Dry run preserves stale files"
setup
# Create a file backdated 10 days
touch -t 202601010000 "$TMPDIR/docs/tmp/old-file.txt"
output=$(bash "$TMPDIR/docs/sprintbias/scripts/cleanup-tmp.sh" </dev/null 2>&1) || true
assert_file_exists "Stale file preserved" "$TMPDIR/docs/tmp/old-file.txt"
assert_contains "Shows stale file" "$output" "old-file.txt"

# Test 4: --force deletes stale files without confirmation
echo "Test 4: --force deletes stale files"
setup
touch -t 202601010000 "$TMPDIR/docs/tmp/stale.txt"
output=$(bash "$TMPDIR/docs/sprintbias/scripts/cleanup-tmp.sh" --force </dev/null 2>&1) || true
assert_file_missing "Stale file deleted" "$TMPDIR/docs/tmp/stale.txt"
assert_contains "Deleted message" "$output" "Deleted"

# Test 5: --force keeps recent files
echo "Test 5: --force keeps recent files"
setup
touch -t 202601010000 "$TMPDIR/docs/tmp/stale.txt"
echo "recent content" > "$TMPDIR/docs/tmp/fresh.txt"
output=$(bash "$TMPDIR/docs/sprintbias/scripts/cleanup-tmp.sh" --force </dev/null 2>&1) || true
assert_file_missing "Stale deleted" "$TMPDIR/docs/tmp/stale.txt"
assert_file_exists "Recent kept" "$TMPDIR/docs/tmp/fresh.txt"

# Test 6: log-*.json always classified as stale
echo "Test 6: log-*.json always stale"
setup
echo "{}" > "$TMPDIR/docs/tmp/log-session.json"
output=$(bash "$TMPDIR/docs/sprintbias/scripts/cleanup-tmp.sh" --force </dev/null 2>&1) || true
assert_file_missing "Log file deleted" "$TMPDIR/docs/tmp/log-session.json"

# Test 7: .gitkeep is never deleted
echo "Test 7: .gitkeep preserved"
setup
touch "$TMPDIR/docs/tmp/.gitkeep"
touch -t 202601010000 "$TMPDIR/docs/tmp/old.txt"
bash "$TMPDIR/docs/sprintbias/scripts/cleanup-tmp.sh" --force </dev/null > /dev/null 2>&1 || true
assert_file_exists ".gitkeep preserved" "$TMPDIR/docs/tmp/.gitkeep"

# Test 8: answering y deletes only stale files; recent files are always kept.
# Passing the retired --all flag deletes nothing extra.
echo "Test 8: confirm y deletes stale only, even with --all"
setup
touch -t 202601010000 "$TMPDIR/docs/tmp/stale.txt"
echo "recent" > "$TMPDIR/docs/tmp/fresh.txt"
output=$(echo "y" | bash "$TMPDIR/docs/sprintbias/scripts/cleanup-tmp.sh" --all 2>&1) || true
assert_file_missing "Stale deleted" "$TMPDIR/docs/tmp/stale.txt"
assert_file_exists "Recent kept" "$TMPDIR/docs/tmp/fresh.txt"

# Test 9: no answer (closed stdin) deletes nothing and returns promptly
echo "Test 9: no answer at the prompt deletes nothing"
setup
touch -t 202601010000 "$TMPDIR/docs/tmp/stale.txt"
output=$(bash "$TMPDIR/docs/sprintbias/scripts/cleanup-tmp.sh" </dev/null 2>&1) || true
assert_file_exists "Stale kept without a y" "$TMPDIR/docs/tmp/stale.txt"

# --- Summary ---
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
