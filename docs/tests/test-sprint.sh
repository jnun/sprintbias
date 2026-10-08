#!/usr/bin/env bash
# Test: sprint.sh
# Tests the CLI router: help, unknown commands, missing args, status output
# Does NOT test end-to-end dispatch (covered by individual create-script tests)

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_UNDER_TEST="$(cd "$(dirname "$0")/../.." && pwd)/sprint.sh"

setup() {
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    # sprint.sh checks if $SCRIPT_DIR/docs/sprintbias/scripts exists to decide PROJECT_ROOT.
    # We place it at the project root level so it finds docs/sprintbias/scripts relative to itself.
    mkdir -p "$TMPDIR/docs/sprintbias/scripts"
    mkdir -p "$TMPDIR/docs/tasks/backlog"
    mkdir -p "$TMPDIR/docs/tasks/next"
    mkdir -p "$TMPDIR/docs/tasks/doing"
    mkdir -p "$TMPDIR/docs/tasks/review"
    mkdir -p "$TMPDIR/docs/tasks/done"

    # Mirror a real install: copy the whole framework tree (scripts, lib.sh,
    # cli/ profiles, ai/, help/, config) so the launcher and every helper resolve
    # their dependencies exactly as they would in a deployed project.
    cp -R "$(cd "$(dirname "$0")/../sprintbias" && pwd)/." "$TMPDIR/docs/sprintbias/"

    # sprint.sh is the root launcher; place it at the sandbox project root so its
    # own resolution (SCRIPT_DIR/docs/sprintbias/scripts exists -> PROJECT_ROOT=here)
    # matches a real install.
    cp "$SCRIPT_UNDER_TEST" "$TMPDIR/sprint.sh"

    cat > "$TMPDIR/docs/sprintbias/DOC_STATE.md" << 'EOF'
# SprintBias Documentation State

**Last Updated**: 2026-01-01
**sprint_VERSION**: 2.2.0
**sprint_TASK_ID**: 10
**sprint_BUG_ID**: 1
EOF

    git -C "$TMPDIR" init -q
}

assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    # -- so needles like --claude are not parsed as grep options (macOS grep).
    if echo "$haystack" | grep -qF -- "$needle"; then
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

# --- Tests ---

echo "=== test-sprint.sh ==="

# Test 1: Help output (no args)
echo "Test 1: No args shows help"
setup
output=$(bash "$TMPDIR/sprint.sh" 2>&1) || true
assert_contains "Shows CLI title" "$output" "SprintBias CLI"
assert_contains "Shows commands" "$output" "newtask"

# Test 2: help command
echo "Test 2: help command shows help"
setup
output=$(bash "$TMPDIR/sprint.sh" help 2>&1)
assert_contains "Help has usage" "$output" "Usage:"

# Test 3: --help flag
echo "Test 3: --help flag shows help"
setup
output=$(bash "$TMPDIR/sprint.sh" --help 2>&1)
assert_contains "--help shows usage" "$output" "Usage:"

# Test 4: Unknown command exits 1
echo "Test 4: Unknown command exits 1"
setup
rc=0
output=$(bash "$TMPDIR/sprint.sh" foobar 2>&1) || rc=$?
assert_exit_code "Exit code is 1" "1" "$rc"
assert_contains "Error mentions unknown" "$output" "Unknown command: foobar"

# Test 5: newtask without description exits 1
echo "Test 5: newtask without args exits 1"
setup
rc=0
bash "$TMPDIR/sprint.sh" newtask 2>/dev/null || rc=$?
assert_exit_code "newtask no-arg exits 1" "1" "$rc"

# Test 6: newfeature without a name enters AI Q&A mode (does NOT error).
# Per ./sprint.sh help: "newfeature [name]  (no name = AI Q&A)". A no-arg
# invocation is a valid entry point, not a usage error, so it must not exit 1.
echo "Test 6: newfeature without args enters Q&A (no error)"
setup
rc=0
bash "$TMPDIR/sprint.sh" newfeature </dev/null >/dev/null 2>&1 || rc=$?
assert_exit_code "newfeature no-arg does not error" "0" "$rc"

# Test 7: newidea without a name enters AI Q&A mode (does NOT error).
# Same dual path as newfeature: no name = AI session, not a usage error.
echo "Test 7: newidea without args enters Q&A (no error)"
setup
# Idea Q&A needs the idea template (create-idea.sh copies it).
mkdir -p "$TMPDIR/docs/ideas"
[ -f "$(cd "$(dirname "$0")/.." && pwd)/ideas/.TEMPLATE-idea.md" ] && \
  cp "$(cd "$(dirname "$0")/.." && pwd)/ideas/.TEMPLATE-idea.md" \
    "$TMPDIR/docs/ideas/.TEMPLATE-idea.md" 2>/dev/null || \
  printf '# [IDEA-NAME]\n' > "$TMPDIR/docs/ideas/.TEMPLATE-idea.md"
rc=0
bash "$TMPDIR/sprint.sh" newidea </dev/null >/dev/null 2>&1 || rc=$?
assert_exit_code "newidea no-arg does not error" "0" "$rc"

# Test 8: newbug without description exits 1
echo "Test 8: newbug without args exits 1"
setup
rc=0
bash "$TMPDIR/sprint.sh" newbug 2>/dev/null || rc=$?
assert_exit_code "newbug no-arg exits 1" "1" "$rc"

# Test 9: split without path exits 1
echo "Test 9: split without args exits 1"
setup
rc=0
bash "$TMPDIR/sprint.sh" split 2>/dev/null || rc=$?
assert_exit_code "split no-arg exits 1" "1" "$rc"

# Test 10: status command shows project status
echo "Test 10: status command shows counts"
setup
# Add a task file to backlog
cat > "$TMPDIR/docs/tasks/backlog/1-test-task.md" << 'EOF'
# Task 1: Test task
EOF
output=$(bash "$TMPDIR/sprint.sh" status 2>&1)
assert_contains "Shows Project Status header" "$output" "Project Status"
assert_contains "Shows Backlog count" "$output" "Backlog:"

# Test 11: status with doing task shows in-progress
echo "Test 11: status shows doing tasks"
setup
cat > "$TMPDIR/docs/tasks/doing/5-active-task.md" << 'EOF'
# Task 5: Active task
EOF
output=$(bash "$TMPDIR/sprint.sh" status 2>&1)
assert_contains "Shows in progress section" "$output" "In progress:"
assert_contains "Shows task name" "$output" "5-active-task"

# Test 12: help documents global provider flags
echo "Test 12: help documents -c/-g provider flags"
setup
output=$(bash "$TMPDIR/sprint.sh" help 2>&1)
assert_contains "Usage mentions -c|-g" "$output" "[-c|-g]"
assert_contains "Help lists --claude" "$output" "--claude"
assert_contains "Help lists --grok" "$output" "--grok"

# Test 12b: help shows how to run several agents (one machine and a server)
echo "Test 12b: help covers several agents at once"
assert_contains "Help has the several-agents section" "$output" "Several agents at once:"
assert_contains "Help names work N side by side" "$output" "work N in each terminal"
assert_contains "Help names the server setup" "$output" "AGENT_HOSTS"
assert_contains "Help points to help crew" "$output" "help crew"

# Test 13: -g exports Grok provider for child scripts
echo "Test 13: -g sets SPRINTBIAS_CLI/PROVIDER for this run"
setup
cat > "$TMPDIR/docs/sprintbias/scripts/work.sh" << 'EOF'
#!/usr/bin/env bash
printf 'CLI=%s\n' "${SPRINTBIAS_CLI:-}"
printf 'PROVIDER=%s\n' "${SPRINTBIAS_PROVIDER:-}"
EOF
chmod +x "$TMPDIR/docs/sprintbias/scripts/work.sh"
output=$(bash "$TMPDIR/sprint.sh" -g work 2>&1)
assert_contains "-g sets CLI=grok" "$output" "CLI=grok"
assert_contains "-g sets PROVIDER=grok-build" "$output" "PROVIDER=grok-build"

# Test 14: -c / --claude export Claude provider
echo "Test 14: -c and --claude set Claude provider"
setup
cat > "$TMPDIR/docs/sprintbias/scripts/work.sh" << 'EOF'
#!/usr/bin/env bash
printf 'CLI=%s\n' "${SPRINTBIAS_CLI:-}"
printf 'PROVIDER=%s\n' "${SPRINTBIAS_PROVIDER:-}"
EOF
chmod +x "$TMPDIR/docs/sprintbias/scripts/work.sh"
output=$(bash "$TMPDIR/sprint.sh" -c work 2>&1)
assert_contains "-c sets CLI=claude" "$output" "CLI=claude"
assert_contains "-c sets PROVIDER=claude-code" "$output" "PROVIDER=claude-code"
output=$(bash "$TMPDIR/sprint.sh" --claude work 2>&1)
assert_contains "--claude sets CLI=claude" "$output" "CLI=claude"

# Test 15: last leading provider flag wins
echo "Test 15: last provider flag wins"
setup
cat > "$TMPDIR/docs/sprintbias/scripts/work.sh" << 'EOF'
#!/usr/bin/env bash
printf 'CLI=%s\n' "${SPRINTBIAS_CLI:-}"
EOF
chmod +x "$TMPDIR/docs/sprintbias/scripts/work.sh"
output=$(bash "$TMPDIR/sprint.sh" -g -c work 2>&1)
assert_contains "last flag (-c) wins" "$output" "CLI=claude"

# Test 16: unknown global option exits 1
echo "Test 16: unknown global option exits 1"
setup
rc=0
output=$(bash "$TMPDIR/sprint.sh" -x work 2>&1) || rc=$?
assert_exit_code "Unknown option exits 1" "1" "$rc"
assert_contains "Unknown option message" "$output" "Unknown option: -x"

# --- Summary ---
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
