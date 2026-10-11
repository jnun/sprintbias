#!/usr/bin/env bash
# Test: validate-tasks.sh
# Integrity checks: IDs, title match, duplicates, Depends on / Blocks tokens

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_UNDER_TEST="$(cd "$(dirname "$0")/../sprintbias/scripts" && pwd)/validate-tasks.sh"
SPRINTBIAS_SRC="$(cd "$(dirname "$0")/../sprintbias" && pwd)"

setup() {
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    # validate-tasks.sh uses SCRIPT_DIR/../../.. as PROJECT_ROOT
    mkdir -p "$TMPDIR/docs/sprintbias/scripts"
    mkdir -p "$TMPDIR/docs/tasks/backlog"
    mkdir -p "$TMPDIR/docs/tasks/next"
    mkdir -p "$TMPDIR/docs/tasks/doing"
    mkdir -p "$TMPDIR/docs/tasks/blocked"
    mkdir -p "$TMPDIR/docs/tasks/review"
    mkdir -p "$TMPDIR/docs/tasks/done"

    cp "$SCRIPT_UNDER_TEST" "$TMPDIR/docs/sprintbias/scripts/validate-tasks.sh"
    # The script sources lib.sh (task_id/task_title/move_file + id-list parsers
    # live there, and lib.sh loads a cli/ provider profile), so the temp tree
    # must carry both or the `source` line aborts under set -e.
    cp "$SPRINTBIAS_SRC/lib.sh" "$TMPDIR/docs/sprintbias/lib.sh"
    cp -R "$SPRINTBIAS_SRC/cli" "$TMPDIR/docs/sprintbias/cli"
}

# Minimal well-formed task body (template fields present for realism; default
# path no longer requires them).
good_task() {
    local id="$1" title="${2:-Test task}" depends="${3:-none}" blocks="${4:-none}"
    cat <<EOF
# Task ${id}: ${title}

**Feature**: none
**Created**: 2026-01-01
**Docs**: none
**Depends on**: ${depends}
**Blocks**: ${blocks}
**Parent**: none

## Problem

Something needs fixing.

## Success criteria

- [ ] It works
EOF
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

assert_not_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if grep -qF "$needle" <<<"$haystack"; then
        echo "  FAIL: $desc (should not contain '$needle')"
        FAIL=$((FAIL + 1))
    else
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
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

# --- Tests ---

echo "=== test-validate-tasks.sh ==="

# Test 1: No task files — exits 0
echo "Test 1: No tasks exits 0"
setup
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/validate-tasks.sh" 2>&1) || rc=$?
assert_exit_code "Exits 0" "0" "$rc"
assert_contains "All valid" "$output" "All task files are valid"

# Test 2: Valid task file — exits 0
echo "Test 2: Valid task exits 0"
setup
good_task 1 > "$TMPDIR/docs/tasks/backlog/1-test-task.md"
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/validate-tasks.sh" 2>&1) || rc=$?
assert_exit_code "Valid exits 0" "0" "$rc"

# Test 3: Title ID mismatch — exits 1
echo "Test 3: Title/filename ID mismatch exits 1"
setup
cat > "$TMPDIR/docs/tasks/backlog/2-bad-title-id.md" << 'EOF'
# Task 99: Wrong ID in title

**Feature**: none
**Depends on**: none
**Blocks**: none

## Problem

Stuff.

## Success criteria

- [ ] Done
EOF
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/validate-tasks.sh" 2>&1) || rc=$?
assert_exit_code "Mismatch exits 1" "1" "$rc"
assert_contains "Reports title ID mismatch" "$output" "does not match filename ID"

# Test 4: Bad title format (no Task N) — exits 1
echo "Test 4: Bad title format exits 1"
setup
cat > "$TMPDIR/docs/tasks/backlog/3-bad-title.md" << 'EOF'
# Bad title

**Feature**: none
**Depends on**: none

## Problem

Stuff.

## Success criteria

- [ ] Done
EOF
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/validate-tasks.sh" 2>&1) || rc=$?
assert_exit_code "Bad title exits 1" "1" "$rc"
assert_contains "Reports title format" "$output" "Title must start with"

# Test 5: Missing Feature / Problem / Success is OK (template-guaranteed, not checked)
echo "Test 5: Missing template fields still exits 0"
setup
cat > "$TMPDIR/docs/tasks/backlog/4-minimal.md" << 'EOF'
# Task 4: Minimal integrity-only task

**Depends on**: none
**Blocks**: none
EOF
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/validate-tasks.sh" 2>&1) || rc=$?
assert_exit_code "Minimal integrity-only exits 0" "0" "$rc"
assert_not_contains "Does not require Feature" "$output" "Missing required field"
assert_not_contains "Does not require Problem" "$output" "Missing required section"

# Test 6: Duplicate ID across stages — exits 1
echo "Test 6: Duplicate ID exits 1"
setup
good_task 5 "First copy" > "$TMPDIR/docs/tasks/backlog/5-first.md"
good_task 5 "Second copy" > "$TMPDIR/docs/tasks/next/5-second.md"
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/validate-tasks.sh" 2>&1) || rc=$?
assert_exit_code "Duplicate exits 1" "1" "$rc"
assert_contains "Reports duplicate" "$output" "Duplicate task ID 5"

# Test 7: Malformed Depends on token — exits 1
echo "Test 7: Bad Depends on token exits 1"
setup
good_task 6 "Bad dep" "not-a-number, 1" > "$TMPDIR/docs/tasks/backlog/6-bad-dep.md"
# also need a target for the valid "1" or archived is fine
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/validate-tasks.sh" 2>&1) || rc=$?
assert_exit_code "Bad dep exits 1" "1" "$rc"
assert_contains "Reports malformed Depends on" "$output" "Malformed **Depends on** token"

# Test 8: Archived / gone Depends on ID (no file) is OK
echo "Test 8: Archived Depends on ID exits 0"
setup
good_task 7 "Depends on gone" "999" > "$TMPDIR/docs/tasks/backlog/7-archived-dep.md"
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/validate-tasks.sh" 2>&1) || rc=$?
assert_exit_code "Archived dep exits 0" "0" "$rc"

# Test 9: Malformed Blocks token — exits 1
echo "Test 9: Bad Blocks token exits 1"
setup
good_task 8 "Bad blocks" "none" "xyz-junk" > "$TMPDIR/docs/tasks/backlog/8-bad-blocks.md"
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/validate-tasks.sh" 2>&1) || rc=$?
assert_exit_code "Bad blocks exits 1" "1" "$rc"
assert_contains "Reports malformed Blocks" "$output" "Malformed **Blocks** token"

# Test 10: --fix repairs title ID mismatch only
echo "Test 10: --fix repairs title ID"
setup
cat > "$TMPDIR/docs/tasks/backlog/9-fixable.md" << 'EOF'
# Task 42: Wrong number

**Depends on**: none
**Blocks**: none

## Problem

Needs title fix.

## Success criteria

- [ ] Fixed
EOF
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/validate-tasks.sh" --fix 2>&1) || rc=$?
content=$(cat "$TMPDIR/docs/tasks/backlog/9-fixable.md")
assert_contains "Title fixed to filename ID" "$content" "# Task 9:"
assert_contains "Keeps title text" "$content" "Wrong number"
# --fix with only title issues should end clean (fixed all)
assert_exit_code "Fix-only-title exits 0" "0" "$rc"

# Test 11: --help exits 0
echo "Test 11: --help exits 0"
setup
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/validate-tasks.sh" --help 2>&1) || rc=$?
assert_exit_code "Help exits 0" "0" "$rc"
assert_contains "Shows usage" "$output" "Usage:"
assert_contains "Mentions integrity" "$output" "integrity"

# Test 12: TEMPLATE files are skipped
echo "Test 12: TEMPLATE files skipped"
setup
cat > "$TMPDIR/docs/tasks/backlog/.TEMPLATE-task.md" << 'EOF'
# Template — not a real task
EOF
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/validate-tasks.sh" 2>&1) || rc=$?
assert_exit_code "Skips template exits 0" "0" "$rc"

# Test 13: Non-numeric ID in filename — exits 1
echo "Test 13: Non-numeric ID exits 1"
setup
cat > "$TMPDIR/docs/tasks/backlog/abc-bad-id.md" << 'EOF'
# Task abc: Bad ID
**Depends on**: none
## Problem
Bad.
## Success criteria
- [ ] Fix
EOF
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/validate-tasks.sh" 2>&1) || rc=$?
assert_exit_code "Non-numeric ID exits 1" "1" "$rc"
assert_contains "Reports invalid ID" "$output" "Invalid task ID"

# Test 14: Depends on range is accepted (no cycle check)
echo "Test 14: Depends on range OK"
setup
good_task 10 "Range dep" "1-3" > "$TMPDIR/docs/tasks/backlog/10-range.md"
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/validate-tasks.sh" 2>&1) || rc=$?
assert_exit_code "Range dep exits 0" "0" "$rc"

# Test 15: --fix on a file with a fixable title AND an unfixable issue — exits 1
# Regression: fixing the title must not mask a remaining malformed dependency
# token. The tool must not report "all valid" while an integrity issue stands.
echo "Test 15: --fix mixed fixable+unfixable exits 1"
setup
cat > "$TMPDIR/docs/tasks/backlog/11-mixed.md" << 'EOF'
# Task 99: Fixable title but bad dep

**Depends on**: junk-token
**Blocks**: none

## Problem

Title is wrong AND dependency token is malformed.

## Success criteria

- [ ] Fix
EOF
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/validate-tasks.sh" --fix 2>&1) || rc=$?
assert_exit_code "Mixed fix exits 1" "1" "$rc"
assert_not_contains "Does not claim all valid" "$output" "All task files are valid"
assert_contains "Still reports malformed dep" "$output" "Malformed **Depends on** token"

# --- Summary ---
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
