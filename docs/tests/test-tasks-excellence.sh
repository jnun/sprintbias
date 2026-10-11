#!/usr/bin/env bash
# Test: work.sh --excellence chain
# Exercises the exec-mode quality chain (task run → excellence audit) with a
# stub CLI — no real AI provider is invoked. Covers three things the flag
# promises: the excellence pass runs after a task lands in review/, a BLOCKER
# verdict does NOT halt the queue (it is only counted in the summary), and the
# enhancement task the pass files into backlog/ never joins the current run
# (work.sh snapshots its task list up front).

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_UNDER_TEST="$(cd "$(dirname "$0")/../sprintbias/scripts" && pwd)/work.sh"

# Stub CLI: two personalities selected by the prompt it receives.
#   - Excellence audit prompt  → emit a JSON verdict (FILED or BLOCKER via
#     STUB_VERDICT) and file an enhancement task into docs/tasks/backlog/.
#   - Any other prompt (task run) → append a '## Completed' section to the
#     task now in doing/ and emit a stream-json result line.
write_stub() {
    STUB="$TMPDIR/stub-cli"
    cat > "$STUB" <<'STUBEOF'
#!/usr/bin/env bash
prompt=""
while [ $# -gt 0 ]; do
  case "$1" in
    -p) prompt="$2"; shift 2 ;;
    *)  shift ;;
  esac
done

if grep -q 'Excellence audit' <<<"$prompt"; then
  mkdir -p docs/tasks/backlog
  printf '# Task 900: filed by the excellence pass\n' \
    > docs/tasks/backlog/900-filed-by-excellence.md
  if [ "${STUB_VERDICT:-FILED}" = "BLOCKER" ]; then
    cat <<'JSON'
{"result": "## Summary\nThe work does not meet its own task's goal.\n\nVERDICT: BLOCKER — fails goal"}
JSON
  else
    cat <<'JSON'
{"result": "## Summary\nFiled one enhancement.\n\nFILED: docs/tasks/backlog/900-filed-by-excellence.md\n\nVERDICT: FILED — 1 enhancement task(s)"}
JSON
  fi
else
  for f in docs/tasks/doing/*.md; do
    [ -f "$f" ] || continue
    printf '\n## Completed\n\n- Edited sample.txt\n' >> "$f"
  done
  printf '{"type":"result","subtype":"success","num_turns":1,"duration_ms":10,"total_cost_usd":0}\n'
fi
STUBEOF
    chmod +x "$STUB"
}

# Build a fresh sandbox with N ready tasks in next/ (numbered 100, 101, …).
setup() {
    local n="${1:-1}"
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    mkdir -p "$TMPDIR/docs/tasks/next" "$TMPDIR/docs/tasks/doing" \
             "$TMPDIR/docs/tasks/review" "$TMPDIR/docs/tasks/blocked" \
             "$TMPDIR/docs/tasks/backlog" "$TMPDIR/docs/tmp" \
             "$TMPDIR/docs/sprintbias/ai"
    printf 'Excellence protocol stub.\n' > "$TMPDIR/docs/sprintbias/ai/audit-excellence.md"
    printf 'sample\n' > "$TMPDIR/sample.txt"

    local i
    for ((i=0; i<n; i++)); do
        cat > "$TMPDIR/docs/tasks/next/$((100 + i))-original.md" <<TASKEOF
# Task $((100 + i)): Original work

Do the thing.

## Questions

**Status: READY**
TASKEOF
    done

    write_stub
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

assert_missing() {
    local desc="$1" haystack="$2" needle="$3"
    if grep -qF "$needle" <<<"$haystack"; then
        echo "  FAIL: $desc (did NOT expect '$needle')"
        FAIL=$((FAIL + 1))
    else
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    fi
}

assert_file() {
    local desc="$1" path="$2"
    if [ -f "$path" ]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (missing: $path)"
        FAIL=$((FAIL + 1))
    fi
}

assert_no_file() {
    local desc="$1" path="$2"
    if [ ! -f "$path" ]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (unexpected: $path)"
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

echo "=== test-work-excellence.sh ==="

# Test 1: --audit --excellence chain, FILED verdict, snapshot holds.
echo "Test 1: excellence runs after the task lands in review/, snapshot holds"
setup 1
rc=0
output=$(cd "$TMPDIR" && SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" NO_COLOR=1 \
    bash "$SCRIPT_UNDER_TEST" --excellence 2>&1) || rc=$?
assert_exit_code "Exits 0" "0" "$rc"
assert_contains "Runs the excellence audit" "$output" "Running excellence audit"
assert_contains "One task completed" "$output" "1 completed"
assert_file "Original task routed to review/" "$TMPDIR/docs/tasks/review/100-original.md"
assert_contains "Excellence section appended" \
    "$(cat "$TMPDIR/docs/tasks/review/100-original.md")" "## Excellence"
assert_contains "Records the FILED verdict" \
    "$(cat "$TMPDIR/docs/tasks/review/100-original.md")" "**Verdict**: FILED"
# Snapshot: the enhancement filed mid-run lands in backlog/ and never joins.
assert_file "Enhancement filed to backlog/" \
    "$TMPDIR/docs/tasks/backlog/900-filed-by-excellence.md"
assert_no_file "Filed task did NOT join the run (not in review/)" \
    "$TMPDIR/docs/tasks/review/900-filed-by-excellence.md"
assert_no_file "Filed task did NOT join the run (not in doing/)" \
    "$TMPDIR/docs/tasks/doing/900-filed-by-excellence.md"
assert_missing "A FILED verdict is not counted as a blocker" \
    "$output" "excellence blocker"

# Test 2: a BLOCKER verdict does not halt the queue; both tasks still route to
# review/ and the summary counts the blockers.
echo "Test 2: BLOCKER verdict does not halt the queue, blockers are counted"
setup 2
rc=0
output=$(cd "$TMPDIR" && SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" NO_COLOR=1 \
    STUB_VERDICT=BLOCKER bash "$SCRIPT_UNDER_TEST" --excellence 2>&1) || rc=$?
assert_exit_code "Queue does not fail on a blocker (exits 0)" "0" "$rc"
assert_contains "Both tasks completed" "$output" "2 completed"
assert_file "First task routed to review/ despite blocker" \
    "$TMPDIR/docs/tasks/review/100-original.md"
assert_file "Second task routed to review/ despite blocker" \
    "$TMPDIR/docs/tasks/review/101-original.md"
assert_contains "Summary counts the blockers" "$output" "2 excellence blocker(s)"
assert_contains "Records the BLOCKER verdict" \
    "$(cat "$TMPDIR/docs/tasks/review/100-original.md")" "**Verdict**: BLOCKER"

# Test 3: without --excellence the audit does not run (opt-in only).
echo "Test 3: excellence audit is opt-in"
setup 1
rc=0
output=$(cd "$TMPDIR" && SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" NO_COLOR=1 \
    bash "$SCRIPT_UNDER_TEST" 2>&1) || rc=$?
assert_exit_code "Exits 0" "0" "$rc"
assert_missing "Excellence audit did not run" "$output" "Running excellence audit"
# The breaker is a separate step that runs by default (task 443); the code and
# excellence audits stay opt-in.
assert_contains "Breaker runs by default" "$output" "Breaker: trying to break the change"
assert_missing "Code audit did not run" "$output" "Running code audit"
assert_no_file "No enhancement was filed" \
    "$TMPDIR/docs/tasks/backlog/900-filed-by-excellence.md"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
