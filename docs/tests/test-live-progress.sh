#!/usr/bin/env bash
# Each check is a string run by eval, so its $vars expand at check time.
# shellcheck disable=SC2016
# Test: a headless run shows its progress while it runs.
#   1. The Claude profile passes raw stream-json through live: the caller's log
#      holds the first step before the CLI exits, and the stream is not
#      replayed a second time at the end.
#   2. sprintbias_stream_last_step reads a task's latest step from its log.
#   3. work with one task runs it on the live sequential path, even with --jobs.
#   4. work with several tasks in parallel prints a status line per running
#      task (elapsed + latest step) every SPRINTBIAS_PROGRESS_SECS.

set -euo pipefail

PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

ok()   { echo "  PASS: $1"; PASS=$((PASS + 1)); }
bad()  { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }
check() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

# A stub CLI: one tool step, a pause, then the result.
STUB="$TMP/stub"
cat > "$STUB" <<'STUB'
#!/usr/bin/env bash
printf '{"type":"system","subtype":"init","model":"stub"}\n'
printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit","input":{"file_path":"app/src/CheckoutForm.tsx"}}]}}\n'
sleep "${STUB_PAUSE:-3}"
printf '{"type":"result","subtype":"success","num_turns":1,"duration_ms":1,"total_cost_usd":0}\n'
STUB
chmod +x "$STUB"

# ── 1. Live pass-through in the Claude profile ───────────────────────
echo "Claude profile streams stream-json live"
LOG="$TMP/live.json"
(
    # shellcheck source=/dev/null
    source "$ROOT/docs/sprintbias/lib.sh"
    # shellcheck source=/dev/null
    source "$ROOT/docs/sprintbias/cli/claude.sh"
    SPRINTBIAS_CLI="$STUB" SPRINTBIAS_ATTEMPT_TIMEOUT=0 SPRINTBIAS_RETRIES=0 \
        sprintbias_provider_exec -p "x" --output-format stream-json > "$LOG" 2>/dev/null
) &
pid=$!
sleep 1.5
mid="$(cat "$LOG" 2>/dev/null || true)"
wait "$pid" && rc=0 || rc=$?
check "first step is in the log before the CLI exits" '[[ "$mid" == *"CheckoutForm.tsx"* && "$mid" != *"\"type\":\"result\""* ]]'
check "run exits 0"                                    '[ "$rc" -eq 0 ]'
check "stream is not replayed at the end"              '[ "$(grep -c "\"type\":\"result\"" "$LOG")" -eq 1 ]'
check "stream-json caller still gets the whole stream" '[ "$(grep -c "\"type\":" "$LOG")" -eq 3 ]'

# ── 2. Latest step from a live log ───────────────────────────────────
echo "sprintbias_stream_last_step"
last() { (source "$ROOT/docs/sprintbias/lib.sh"; sprintbias_stream_last_step "$1"); }
check "tool step reads as name + target"  '[ "$(last "$LOG")" = "Edit app/src/CheckoutForm.tsx" ]'
printf '{"type":"assistant","message":{"content":[{"type":"text","text":"Running the  suite now."}]}}\n' > "$TMP/text.json"
check "agent words read as the step"      '[ "$(last "$TMP/text.json")" = "Running the suite now." ]'
: > "$TMP/empty.json"
check "empty log prints nothing"          '[ -z "$(last "$TMP/empty.json")" ]'
check "missing log prints nothing"        '[ -z "$(last "$TMP/nope.json")" ]'

# ── 3 & 4. work on a temp board ──────────────────────────────────────
B="$TMP/board"
mkdir -p "$B/docs/sprintbias" "$B/docs/tasks"/{backlog,next,doing,review,done,blocked} "$B/docs/tmp"
cp -R "$ROOT/docs/sprintbias/." "$B/docs/sprintbias/"
cp "$ROOT/sprint.sh" "$B/sprint.sh"
rm -f "$B/docs/sprintbias/config.local"
(cd "$B" && git init -q)
unset SPRINTBIAS_FAST SPRINTBIAS_CONFIG_FILE SPRINTBIAS_CONFIG_LOCAL_FILE
export NO_COLOR=1
task() {  # task ID → a READY task in next/
    printf '# Task %s: Thing %s\n\n## Problem\n\nX\n\n## Done when (automated)\n\n- [ ] `true`\n\n## Questions\n\n**Status: READY**\n' \
        "$1" "$1" > "$B/docs/tasks/next/$1-thing-$1.md"
}
work() {
    (cd "$B" && SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" STUB_PAUSE="${STUB_PAUSE:-1}" \
        SPRINTBIAS_ATTEMPT_TIMEOUT=0 BREAK=off \
        bash docs/sprintbias/scripts/work.sh "$@" </dev/null 2>&1 || true)
}

echo "One task runs live, even with --jobs"
task 101
out="$(work --jobs 4 --no-break)"
check "one task takes the sequential path"     '[[ "$out" == *"Task 1/1: 101-thing-101.md"* && "$out" != *"Running up to"* ]]'
check "its step shows on screen"               '[[ "$out" == *"-> Edit app/src/CheckoutForm.tsx"* ]]'

echo "Parallel tasks print status lines"
rm -f "$B"/docs/tasks/*/1*.md
task 201; task 202
out="$(STUB_PAUSE=5 SPRINTBIAS_PROGRESS_SECS=2 work --jobs 2 --no-break)"
check "parallel path runs both"                '[[ "$out" == *"Running up to 2 task(s)"* ]]'
check "status line names task, time and step"  '[[ "$out" =~ "· #201  0m0"[0-9]"s  Edit app/src/CheckoutForm.tsx" ]]'
check "each running task gets a line"          '[[ "$out" == *"· #202  "* ]]'
out="$(rm -f "$B"/docs/tasks/*/2*.md; task 301; task 302; STUB_PAUSE=3 SPRINTBIAS_PROGRESS_SECS=0 work --jobs 2 --no-break)"
check "SPRINTBIAS_PROGRESS_SECS=0 turns lines off" '[[ "$out" != *"· #30"* ]]'

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
