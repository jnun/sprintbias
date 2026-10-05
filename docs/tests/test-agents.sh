#!/usr/bin/env bash
# Test: agents.sh / agents.py
# Builds a fake Claude config dir (a session registry plus a transcript) for a
# live stand-in process and a dead one, then checks the listing, the JSON
# facts, and flag handling. No ssh, no AI.

set -euo pipefail

PASS=0
FAIL=0
SCRIPTS="$(cd "$(dirname "$0")/../sprintbias/scripts" && pwd)"

assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if printf '%s' "$haystack" | grep -qF -- "$needle"; then
        echo "  PASS: $desc"; PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected to contain '$needle')"; FAIL=$((FAIL + 1))
    fi
}

assert_not_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if printf '%s' "$haystack" | grep -qF -- "$needle"; then
        echo "  FAIL: $desc (did not expect '$needle')"; FAIL=$((FAIL + 1))
    else
        echo "  PASS: $desc"; PASS=$((PASS + 1))
    fi
}

echo "=== test-agents.sh ==="

if ! command -v python3 >/dev/null 2>&1; then
    echo "  SKIP: python3 not found"
    exit 0
fi

TMP=$(mktemp -d)
sleep 300 &
LIVE=$!
trap 'kill "$LIVE" 2>/dev/null || true; rm -rf "$TMP"' EXIT

PROJECT="$TMP/work/demo-proj"
mkdir -p "$TMP/claude/sessions" "$PROJECT/docs/crew"
printf '# Crew: fixer\n\n**Role**: Finds and fixes bugs\n**Lead**: no\n' > "$PROJECT/docs/crew/fixer.md"
SLUG=$(printf '%s' "$PROJECT" | sed 's/[^A-Za-z0-9]/-/g')
mkdir -p "$TMP/claude/projects/$SLUG"

NOW_MS=$(( $(date +%s) * 1000 ))
cat > "$TMP/claude/sessions/$LIVE.json" <<EOF
{"pid": $LIVE, "sessionId": "sess-live", "cwd": "$PROJECT", "startedAt": $((NOW_MS - 7200000)),
 "kind": "interactive", "name": "fixer", "status": "busy", "statusUpdatedAt": $NOW_MS, "version": "9.9.9"}
EOF
# A registry file whose process has ended must not be listed.
cat > "$TMP/claude/sessions/999999.json" <<EOF
{"pid": 999999, "sessionId": "sess-dead", "cwd": "$PROJECT", "startedAt": $NOW_MS, "name": "ghost", "status": "idle"}
EOF
cat > "$TMP/claude/projects/$SLUG/sess-live.jsonl" <<'EOF'
{"type":"summary"}
{"type":"user","message":{"role":"user","content":"fix the login bug"}}
{"type":"assistant","isSidechain":true,"message":{"model":"claude-haiku-4-5-20251001","usage":{"input_tokens":5}}}
{"type":"assistant","message":{"model":"claude-opus-5-5","usage":{"input_tokens":1000,"cache_read_input_tokens":40000,"cache_creation_input_tokens":2000,"output_tokens":500}}}
{"type":"last-prompt","lastPrompt":"fix the login bug"}
{"type":"ai-title","aiTitle":"Login bug fix"}
EOF

agents() { CLAUDE_CONFIG_DIR="$TMP/claude" NO_COLOR=1 python3 "$SCRIPTS/agents.py" "$@" 2>&1; }

echo "-- listing"
out=$(agents --local)
assert_contains "lists the live session by name" "$out" "fixer"
assert_contains "shows its state" "$out" "busy"
assert_contains "shows the project folder" "$out" "demo-proj"
assert_contains "shows uptime from the registry" "$out" "up 2h00m"
assert_contains "shows the main thread's model, not a subagent's" "$out" "opus-5-5"
assert_contains "context sums every input bucket and output" "$out" "ctx 44k"
assert_contains "shows the transcript topic" "$out" "Login bug fix"
assert_contains "shows the last prompt" "$out" '"fix the login bug"'
assert_contains "shows the crew role" "$out" "[Finds and fixes bugs]"
assert_not_contains "skips a registry file whose process ended" "$out" "ghost"
assert_contains "summary counts the running sessions" "$out" "1 agent running"

echo "-- json"
json=$(agents --local --json)
facts=$(printf '%s' "$json" | python3 -c '
import json, sys
s = json.load(sys.stdin)[0]
print(s["name"], s["pid"], s["model"], s["context_tokens"], s["project"])')
assert_contains "json carries the facts" "$facts" "fixer $LIVE claude-opus-5-5 43500 demo-proj"

echo "-- flags"
assert_contains "python rejects an unknown option" "$(agents --bogus || true)" "unknown option --bogus"
wrapped=$(bash "$SCRIPTS/agents.sh" --bogus 2>&1 || true)
assert_contains "wrapper prints usage on an unknown flag" "$wrapped" "Usage: ./sprint.sh agents"
wrapped=$(bash "$SCRIPTS/agents.sh" --host 2>&1 || true)
assert_contains "wrapper wants a value after --host" "$wrapped" "Usage: ./sprint.sh agents"

echo "-- unreachable host"
out=$(agents --host "no-such-host.invalid")
assert_contains "an unreachable host is reported, not fatal" "$out" "unreachable"
assert_contains "local sessions still list beside it" "$out" "fixer"

echo ""
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]
