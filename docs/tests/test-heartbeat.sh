#!/usr/bin/env bash
# Test: the progress heartbeat never outlives its run.
#   1. Under an outer ticker, a skipped start/stop pair leaves the line owned,
#      so a retry's start starts no second ticker.
#   2. An inner skipped pair leaves the outer ticker running; the outer stop ends it.
#   3. A run killed by run_with_timeout's watchdog (never reaching stop) takes
#      its ticker with it: no orphan prints dots over the next prompt.
# The ticker needs a terminal, so the checks run under script(1); skips without one.

set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

if [ "${1:-}" != "--inner" ]; then
    command -v script >/dev/null 2>&1 || { echo "  SKIP: no script(1)"; echo "Results: 0 passed, 0 failed"; exit 0; }
    cmd="bash '$0' --inner"
    if script -q /dev/null true </dev/null >/dev/null 2>&1; then
        out="$(script -q /dev/null bash -c "$cmd" </dev/null 2>&1)"
    else
        out="$(script -q -c "$cmd" /dev/null </dev/null 2>&1)"
    fi
    printf '%s\n' "$out" | tr -d '\r' | grep -E 'PASS|FAIL|SKIP|Results'
    printf '%s\n' "$out" | grep -q 'Results: [0-9]* passed, 0 failed'
    exit $?
fi

PASS=0; FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  PASS: $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL: $1"; }
alive() { kill -0 "$1" 2>/dev/null; }

{ true >/dev/tty; } 2>/dev/null || { echo "  SKIP: no terminal"; echo "Results: 0 passed, 0 failed"; exit 0; }
# shellcheck source=/dev/null
source "$ROOT/docs/sprintbias/lib.sh"
export SPRINTBIAS_HEARTBEAT_SECS=1
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

echo "Test 1: a retry under an outer ticker starts no second one"
(
    _SPRINTBIAS_HEARTBEAT_ON=1          # what run_with_timeout_dots claims
    _sprintbias_heartbeat_start; _sprintbias_heartbeat_stop   # first attempt
    _sprintbias_heartbeat_start                               # the retry
    [ -z "$_SPRINTBIAS_HEARTBEAT_PID" ] && [ -n "${_SPRINTBIAS_HEARTBEAT_ON:-}" ]
) && ok "retry: line still owned, no ticker" || bad "retry: line still owned, no ticker"

echo "Test 2: an inner skipped pair leaves the outer ticker alone"
_sprintbias_heartbeat_start; outer="$_SPRINTBIAS_HEARTBEAT_PID"
_sprintbias_heartbeat_start; _sprintbias_heartbeat_stop
alive "$outer" && ok "nested: outer ticker still running" || bad "nested: outer ticker still running"
_sprintbias_heartbeat_stop; sleep 2
alive "$outer" && bad "nested: outer stop ends it" || ok "nested: outer stop ends it"

echo "Test 3: a timed-out run leaves no orphan ticker"
run_body() { _sprintbias_heartbeat_start; echo "$_SPRINTBIAS_HEARTBEAT_PID" > "$TMP/pid"; sleep 30; _sprintbias_heartbeat_stop; }
run_with_timeout 2 run_body
sleep 3
t="$(cat "$TMP/pid" 2>/dev/null)"
[ -n "$t" ] && ok "timeout: the run started a ticker" || bad "timeout: the run started a ticker"
[ -n "$t" ] && alive "$t" && { bad "timeout: ticker gone after the kill"; kill "$t" 2>/dev/null; } || ok "timeout: ticker gone after the kill"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
