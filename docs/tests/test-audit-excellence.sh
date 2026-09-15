#!/usr/bin/env bash
# Test: polish.sh deep-judge mode (formerly audit-excellence.sh)
# Exercises the shared change-manifest and summary helpers with a stub CLI —
# no real AI provider is invoked.

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_UNDER_TEST="$(cd "$(dirname "$0")/../sprintbias/scripts" && pwd)/polish.sh"

setup() {
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    mkdir -p "$TMPDIR/docs/tmp"
    mkdir -p "$TMPDIR/docs/sprintbias/ai"
    printf 'Excellence protocol stub.\n' > "$TMPDIR/docs/sprintbias/ai/audit-excellence.md"
    printf 'x = 1\n' > "$TMPDIR/sample.py"

    # Stub CLI: emits a JSON result with a Summary and an EXCELLENT verdict.
    STUB="$TMPDIR/stub-cli"
    cat > "$STUB" <<'STUBEOF'
#!/usr/bin/env bash
cat <<'JSON'
{"result": "## Summary\nMeets the bar.\n\nVERDICT: EXCELLENT"}
JSON
STUBEOF
    chmod +x "$STUB"
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

echo "=== test-audit-excellence.sh (polish deep-judge) ==="

# Test 1: exec mode, explicit file -> EXCELLENT verdict, exit 0
echo "Test 1: exec mode with explicit file meets the bar"
setup
rc=0
output=$(cd "$TMPDIR" && SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" \
    bash "$SCRIPT_UNDER_TEST" sample.py 2>&1) || rc=$?
assert_exit_code "Exits 0" "0" "$rc"
assert_contains "Context source is explicit list" "$output" "explicit file list"
assert_contains "Reports meeting the bar" "$output" "meets the bar"

# Test 2: emit mode prints the prompt with the manifest, exit 0
echo "Test 2: emit mode prints prompt"
setup
rc=0
output=$(cd "$TMPDIR" && SPRINTBIAS_MODE=emit SPRINTBIAS_CLI="$STUB" \
    bash "$SCRIPT_UNDER_TEST" sample.py 2>&1) || rc=$?
assert_exit_code "Exits 0" "0" "$rc"
assert_contains "Prompt lists changed files" "$output" "CHANGED FILES"
assert_contains "Prompt names the audited file" "$output" "sample.py"

# Test 3: AUDIT_MANIFEST env wins the priority chain (paired with a task arg,
# as work.sh always invokes it — the bare no-arg form hits the usage guard).
echo "Test 3: AUDIT_MANIFEST env is the manifest source"
setup
printf '# Task 1: Sample\n' > "$TMPDIR/1-sample.md"
printf 'sample.py\n' > "$TMPDIR/manifest.txt"
rc=0
output=$(cd "$TMPDIR" && SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" \
    AUDIT_MANIFEST="manifest.txt" bash "$SCRIPT_UNDER_TEST" 1-sample.md 2>&1) || rc=$?
assert_exit_code "Exits 0" "0" "$rc"
assert_contains "Context source is the manifest" "$output" "manifest from work.sh"

# Test 4: missing protocol file -> preflight error, exit 1
echo "Test 4: missing protocol exits 1"
setup
rm -f "$TMPDIR/docs/sprintbias/ai/audit-excellence.md"
rc=0
output=$(cd "$TMPDIR" && SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" \
    bash "$SCRIPT_UNDER_TEST" sample.py 2>&1) || rc=$?
assert_exit_code "Exits 1" "1" "$rc"
assert_contains "Reports missing protocol" "$output" "Protocol file missing"

# Test 5: deep-judge emit prompt teaches the UPGRADED altitude bar — the dimension
# vocabulary now references the protocol's full set (Antifragility included), tags
# every finding by dimension, and expects full Considered coverage. Guards the
# closed drift: the old hardcoded five-name step-3 list must not reappear.
echo "Test 5: deep-judge emit teaches the upgraded bar (Antifragility, coverage, tags)"
setup
rc=0
output=$(cd "$TMPDIR" && SPRINTBIAS_MODE=emit SPRINTBIAS_CLI="$STUB" \
    bash "$SCRIPT_UNDER_TEST" sample.py 2>&1) || rc=$?
assert_exit_code "Exits 0" "0" "$rc"
assert_contains "Prompt names Antifragility" "$output" "Antifragility"
assert_contains "Prompt asks 'could this be better?'" "$output" "could this be better?"
assert_contains "Prompt tags findings by dimension" "$output" "Tag each finding with the dimension"
assert_contains "Prompt expects Considered coverage" "$output" "Considered block"

# Test 6: refine sweep prompt is Audit-gated and teaches the scannable Improve
# shape. A capturing stub records the exec prompt built by _refine_prompt for a
# review/ task with NO passing '## Audit' — so correctness is unverified and the
# old unconditional "presumed correct" must be gone. PASS verdict keeps routing
# trivial (task stays in review/).
echo "Test 6: refine sweep prompt is Audit-gated and teaches scannable Improve"
setup
mkdir -p "$TMPDIR/docs/tasks/review" "$TMPDIR/docs/tasks/next" "$TMPDIR/docs/tasks/blocked"
printf 'Refine protocol stub.\n' > "$TMPDIR/docs/sprintbias/ai/refine.md"
cat > "$TMPDIR/docs/tasks/review/900-demo.md" <<'TASK'
# Task 900: Demo

**Reworked**: 0

## Completed

### Files changed
sample.py
TASK
CAP="$TMPDIR/captured-prompt.txt"
CAPSTUB="$TMPDIR/capture-cli"
cat > "$CAPSTUB" <<'STUBEOF'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$CAPTURE"
cat <<'JSON'
{"result": "## Summary\nMeets the bar.\n\nVERDICT: PASS"}
JSON
STUBEOF
chmod +x "$CAPSTUB"
rc=0
output=$(cd "$TMPDIR" && SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$CAPSTUB" CAPTURE="$CAP" \
    bash "$SCRIPT_UNDER_TEST" 2>&1) || rc=$?
assert_exit_code "Exits 0" "0" "$rc"
captured="$(cat "$CAP" 2>/dev/null || true)"
assert_contains "Sweep prompt drops unconditional 'presumed correct'" \
    "$(printf '%s' "$captured" | grep -c 'The work is presumed correct' || true)" "0"
assert_contains "Sweep prompt is Audit-gated (correctness not established)" \
    "$captured" "Correctness is NOT established"
assert_contains "Sweep prompt teaches the Improve list" "$captured" "**Improve:**"
assert_contains "Sweep prompt teaches one-line done-look" "$captured" "one-line done-look"
assert_contains "Sweep prompt rejects edit recipes" "$captured" "not line-specific edit recipes"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
