#!/usr/bin/env bash
# Test: polish.sh --code mode (formerly audit-code.sh)
# Exercises the shared change-manifest helper and the emit/exec paths with a
# stub CLI — no real AI provider is invoked.

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_UNDER_TEST="$(cd "$(dirname "$0")/../sprintbias/scripts" && pwd)/polish.sh"

setup() {
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    mkdir -p "$TMPDIR/docs/tmp"
    # A file to audit
    printf 'x = 1\n' > "$TMPDIR/sample.py"

    # Stub CLI: ignores args, emits a JSON result with a clean PASS verdict.
    STUB="$TMPDIR/stub-cli"
    cat > "$STUB" <<'STUBEOF'
#!/usr/bin/env bash
cat <<'JSON'
{"result": "## Summary\nStub audit — nothing to fix.\n\nVERDICT: PASS — no issues"}
JSON
STUBEOF
    chmod +x "$STUB"
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

echo "=== test-audit-code.sh (polish --code) ==="

# Test 1: exec mode, explicit file list -> clean PASS, exit 0
echo "Test 1: exec mode with explicit file passes"
setup
rc=0
output=$(cd "$TMPDIR" && SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" \
    bash "$SCRIPT_UNDER_TEST" --code sample.py 2>&1) || rc=$?
assert_exit_code "Exits 0" "0" "$rc"
assert_contains "Context source is explicit list" "$output" "explicit file list"
assert_contains "Reports a passed audit" "$output" "Code audit passed"

# Test 2: emit mode builds the manifest and runs, exit 0
echo "Test 2: emit mode builds the manifest"
setup
rc=0
output=$(cd "$TMPDIR" && SPRINTBIAS_MODE=emit SPRINTBIAS_CLI="$STUB" \
    bash "$SCRIPT_UNDER_TEST" --code sample.py 2>&1) || rc=$?
assert_exit_code "Exits 0" "0" "$rc"
assert_contains "Announces the audited file count" "$output" "Auditing 1 changed file"
assert_contains "Lists the audited file" "$output" "sample.py"

# Test 3: AUDIT_MANIFEST env wins the priority chain (paired with a task arg,
# as work.sh always invokes it — the bare no-arg form hits the usage guard).
echo "Test 3: AUDIT_MANIFEST env is the manifest source"
setup
printf '# Task 1: Sample\n' > "$TMPDIR/1-sample.md"
printf 'sample.py\n' > "$TMPDIR/manifest.txt"
rc=0
output=$(cd "$TMPDIR" && SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" \
    AUDIT_MANIFEST="manifest.txt" bash "$SCRIPT_UNDER_TEST" --code 1-sample.md 2>&1) || rc=$?
assert_exit_code "Exits 0" "0" "$rc"
assert_contains "Context source is the manifest" "$output" "manifest from work.sh"

# Test 4: --code with no file args -> usage error, exit 1
echo "Test 4: --code with no files prints usage and exits 1"
setup
rc=0
output=$(cd "$TMPDIR" && SPRINTBIAS_CLI="$STUB" bash "$SCRIPT_UNDER_TEST" --code 2>&1) || rc=$?
assert_exit_code "Exits 1" "1" "$rc"
assert_contains "Shows usage" "$output" "Usage:"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
