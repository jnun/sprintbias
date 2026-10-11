#!/usr/bin/env bash
# Test: the worker test-and-proof loop (task 400, plan 28 Policy).
#
#   1. sprintbias_proof_rule states the loop, and a proof line written in its
#      format passes sprintbias_has_proof (one format, two readers).
#   2. Every work prompt carries it: exec _task_prompt (captured by a stub CLI)
#      and both emit prompts (orchestrated and sequential).
#   3. The exec router lands a completed task without proof in review/ and says
#      it is in review, unproven; with proof it says nothing extra; a worker's
#      own **Result**: blocked Outcome routes to blocked/ with its Reason kept.
#
# Sandboxed in a temp dir with a stub CLI; no live AI. Discovered by run-all.sh.

set -euo pipefail

PASS=0
FAIL=0
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="$REPO/docs/sprintbias/scripts/work.sh"
# shellcheck source=/dev/null
source "$REPO/docs/sprintbias/lib.sh"

assert_contains() {
    if grep -qF -- "$3" <<<"$2"; then
        echo "  PASS: $1"; PASS=$((PASS + 1))
    else
        echo "  FAIL: $1 (expected to contain '$3')"; FAIL=$((FAIL + 1))
    fi
}
assert_missing() {
    if grep -qF -- "$3" <<<"$2"; then
        echo "  FAIL: $1 (did not expect '$3')"; FAIL=$((FAIL + 1))
    else
        echo "  PASS: $1"; PASS=$((PASS + 1))
    fi
}
assert_true() {
    local desc="$1"; shift
    if "$@"; then echo "  PASS: $desc"; PASS=$((PASS + 1))
    else echo "  FAIL: $desc"; FAIL=$((FAIL + 1)); fi
}
assert_file() {
    if [ -f "$2" ]; then echo "  PASS: $1"; PASS=$((PASS + 1))
    else echo "  FAIL: $1 (missing: $2)"; FAIL=$((FAIL + 1)); fi
}

SANDBOX=""
trap '[ -n "$SANDBOX" ] && rm -rf "$SANDBOX"' EXIT

# A fresh sandbox with one READY task 100 in next/ and a stub CLI. The stub
# saves the prompt it was given and finishes the task the way STUB_END says:
#   noproof (default) — ## Completed only
#   proof             — ## Completed with a proof line
#   blocked           — ## Test log + ## Outcome **Result**: blocked
setup() {
    [ -n "$SANDBOX" ] && rm -rf "$SANDBOX"
    SANDBOX=$(mktemp -d)
    mkdir -p "$SANDBOX"/docs/tasks/{next,doing,review,blocked,backlog,done} "$SANDBOX/docs/tmp"
    printf '# Task 100: Original work\n\nDo the thing.\n\n## Questions\n\n**Status: READY**\n' \
        > "$SANDBOX/docs/tasks/next/100-original.md"
    STUB="$SANDBOX/stub-cli"
    cat > "$STUB" <<'STUBEOF'
#!/usr/bin/env bash
prompt=""
while [ $# -gt 0 ]; do
  case "$1" in -p) prompt="$2"; shift 2 ;; *) shift ;; esac
done
printf '%s' "$prompt" > docs/tmp/stub-prompt.txt
for f in docs/tasks/doing/*.md; do
  [ -f "$f" ] || continue
  case "${STUB_END:-noproof}" in
    proof)   printf '\n## Completed\n\n**Proof**: 2026-10-08 · bash t.sh · pass\n' >> "$f" ;;
    blocked) printf '\n## Test log\n\n- bash t.sh — test 2 — expected 1, got 2\n\n## Outcome\n**Result**: blocked\n**Reason**: needs the production API key\n' >> "$f" ;;
    *)       printf '\n## Completed\n\n- Edited sample.txt\n' >> "$f" ;;
  esac
done
printf '{"type":"result","subtype":"success","num_turns":1,"duration_ms":10,"total_cost_usd":0}\n'
STUBEOF
    chmod +x "$STUB"
}

run_exec() {
    # The breaker has its own test (test-edge-cases.sh); here the stub's last
    # prompt must be the worker's.
    (cd "$SANDBOX" && SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" NO_COLOR=1 SPRINTBIAS_BREAK=off \
        bash "$WORK" "$@" 2>&1) || true
}

echo "=== test-proof-loop.sh ==="

echo "Test 1: the rule states the loop and its proof format passes has_proof"
rule="$(sprintbias_proof_rule)"
assert_contains "Smallest testable outcome first" "$rule" "smallest testable outcome first"
assert_contains "Targeted tests from Done when" "$rule" "## Done when (automated) names"
assert_contains "Targeted tests from Touching" "$rule" "**Touching:**"
assert_contains "Full suite at plan close only" "$rule" "full suite runs once, at plan close"
assert_contains "Test log with its fields" "$rule" "## Test log (command, failing test, error excerpt)"
assert_contains "Cannot start → blocked Outcome" "$rule" "**Result**: blocked"
assert_contains "Audits a failing test first" "$rule" "Audit the test first"
assert_contains "Unexplained failure still lands" "$rule" "Still unexplained: land without **Proof**"
assert_contains "Decisions are assumed, not blocked" "$(sprintbias_assume_rule)" '- Decided: X, because Y'
assert_contains "Proof line format" "$rule" "**Proof**: YYYY-MM-DD · <targeted test commands> · pass"
assert_contains "Unproven label" "$rule" "$SPRINTBIAS_UNPROVEN_LABEL"
assert_contains "Asks for the history summary" "$rule" "open ## Completed with **Summary**:"
assert_contains "Asks for an assertion per case" "$rule" "add one assertion per ## Done when case"
assert_contains "Carries the edge-case classes" "$rule" "$(sprintbias_edge_cases | head -1)"
lines=$(printf '%s\n' "$rule" | wc -l | tr -d ' ')
elines=$(sprintbias_edge_cases | wc -l | tr -d ' ')
lines=$((lines - elines - 1))
# 15: task 421 added the **Summary**: ask, which plan done copies into history.
# 19: task 443 added the per-case assertion and fix-or-file lines.
assert_true "Rule stays short (<= 19 lines + edge cases, got $lines)" [ "$lines" -le 19 ]
fmt="$(printf '%s\n' "$rule" | grep -m1 '^ *\*\*Proof\*\*:' | sed 's/^ *//')"
filled="${fmt/YYYY-MM-DD/2026-10-08}"
filled="${filled/<targeted test commands>/bash docs/tests/test-x.sh}"
tmpf="$(mktemp)"
printf '# Task 1: x\n\n## Completed\n\n### Files changed\na.sh\n\n%s\n' "$filled" > "$tmpf"
assert_true "A proof line in the rule's format passes sprintbias_has_proof" sprintbias_has_proof "$tmpf"
rm -f "$tmpf"

echo "Test 2: exec prompt carries the loop; an unproven task lands, flagged"
setup
out="$(run_exec)"
prompt="$(cat "$SANDBOX/docs/tmp/stub-prompt.txt" 2>/dev/null || true)"
assert_contains "Exec prompt has the test loop" "$prompt" "Test loop:"
assert_contains "Exec prompt has the proof format" "$prompt" "**Proof**: YYYY-MM-DD · <targeted test commands> · pass"
assert_contains "Exec prompt still has the parallel rule" "$prompt" "Parallel work:"
assert_file "Unproven task still lands in review/" "$SANDBOX/docs/tasks/review/100-original.md"
assert_contains "Router says it is unproven" "$out" "No **Proof**: line — $SPRINTBIAS_UNPROVEN_LABEL"

echo "Test 3: a proven task lands without the unproven note"
setup
out="$(STUB_END=proof run_exec)"
assert_file "Proven task lands in review/" "$SANDBOX/docs/tasks/review/100-original.md"
assert_true "It carries proof" sprintbias_has_proof "$SANDBOX/docs/tasks/review/100-original.md"
assert_missing "No unproven note" "$out" "$SPRINTBIAS_UNPROVEN_LABEL"

echo "Test 4: a worker's blocked Outcome routes to blocked/ with its Reason kept"
setup
out="$(STUB_END=blocked run_exec)"
f="$SANDBOX/docs/tasks/blocked/100-original.md"
assert_file "Blocked task in blocked/" "$f"
body="$(cat "$f" 2>/dev/null || true)"
assert_contains "Worker's Reason kept" "$body" "**Reason**: needs the production API key"
assert_contains "Test log kept" "$body" "## Test log"
assert_missing "Not restamped as incomplete" "$body" "run ended without"
assert_contains "Run names the reason" "$out" "needs the production API key"

echo "Test 5: both emit prompts carry the loop"
setup
out="$(cd "$SANDBOX" && SPRINTBIAS_MODE=emit SPRINTBIAS_PROVIDER=claude-code NO_COLOR=1 \
    bash "$WORK" 2>&1 || true)"
assert_contains "Orchestrated emit: fresh subagents" "$out" "OWN fresh subagent"
assert_contains "Orchestrated emit: test loop" "$out" "Test loop:"
assert_contains "Orchestrated emit: proof format" "$out" "**Proof**: YYYY-MM-DD · <targeted test commands> · pass"
assert_contains "Orchestrated emit: keeps a worker's blocked Outcome" "$out" "keep
      one the worker wrote with **Result**: blocked"
out="$(cd "$SANDBOX" && SPRINTBIAS_MODE=emit SPRINTBIAS_PROVIDER=generic NO_COLOR=1 \
    bash "$WORK" 2>&1 || true)"
assert_contains "Sequential emit: one at a time" "$out" "ONE AT A TIME"
assert_contains "Sequential emit: test loop" "$out" "Test loop:"
assert_contains "Sequential emit: proof format" "$out" "**Proof**: YYYY-MM-DD · <targeted test commands> · pass"


echo "Test 6: the checklist counts only tasks still in review/; emit spec names every call source"
setup
out="$(STUB_END=proof run_exec)"
assert_contains "Header counts the landed task" "$out" "▸ Your turn — 1 task(s) built and waiting for you"
# A name in TO_REVIEW whose file has gone (moved by another agent) is not counted.
fn="$(awk '/^_task_tests_value\(\) \{/{f=1} f; f&&/^_report_human_review\(\) \{/{g=1} g&&/^}$/{exit}' "$WORK")"
out="$(cd "$SANDBOX" && bash -c "$fn"'
    sprintbias_grounding_conflicts() { :; }; sprintbias_has_proof() { return 0; }
    REVIEW_DIR=docs/tasks/review; TO_REVIEW=(100-original.md 999-gone.md); _report_human_review' 2>&1)"
assert_contains "Missing file not counted" "$out" "▸ Your turn — 1 task(s)"
assert_missing "Missing file not listed" "$out" "#999"
setup
out="$(cd "$SANDBOX" && SPRINTBIAS_MODE=emit SPRINTBIAS_PROVIDER=claude-code NO_COLOR=1 bash "$WORK" 2>&1 || true)"
assert_contains "Emit spec: suggestions the gate took" "$out" "suggestion the gate took"


echo "Test 7: the checklist's last step is one line"
setup
out="$(STUB_END=proof run_exec)"
assert_contains "No Tests: close with promote --accept" "$out" "→ ./sprint.sh promote --accept 100"
assert_missing "No hand move" "$out" "git mv docs/tasks/review/"
setup
printf '# Task 100: Original work\n\n**Tests**: docs/tests/t.sh\n\nDo the thing.\n\n## Questions\n\n**Status: READY**\n' \
    > "$SANDBOX/docs/tasks/next/100-original.md"
out="$(STUB_END=proof run_exec)"
assert_contains "With Tests: close with promote <id>" "$out" "→ ./sprint.sh promote 100"
out="$(cd "$SANDBOX" && rm -f docs/tasks/*/*.md && printf '# Task 100: x\n\n## Questions\n\n**Status: READY**\n' > docs/tasks/next/100-x.md \
    && SPRINTBIAS_MODE=emit SPRINTBIAS_PROVIDER=claude-code NO_COLOR=1 bash "$WORK" 2>&1 || true)"
assert_contains "Emit spec: close with promote --accept" "$out" "→ ./sprint.sh promote --accept <id>"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
