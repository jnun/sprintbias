#!/usr/bin/env bash
# Test: Grok Build first-class provider (plan 5 / tasks 251–256)
#
# Covers tier inference, emit detection (GROK_AGENT), profile load, model
# default, orchestration helpers, and tool-mapping fail-open behavior.
# Does not launch a live Grok TUI or call the network.

set -euo pipefail

PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SPRINTBIAS="$ROOT/docs/sprintbias"

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc"
    printf '    expected: %q\n' "$expected"
    printf '    actual:   %q\n' "$actual"
    FAIL=$((FAIL + 1))
  fi
}

assert_true() {
  local desc="$1"; shift
  if "$@"; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc (expected success)"
    FAIL=$((FAIL + 1))
  fi
}

assert_false() {
  local desc="$1"; shift
  if "$@"; then
    echo "  FAIL: $desc (expected failure)"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  fi
}

assert_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if printf '%s' "$haystack" | grep -qF -- "$needle"; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc (expected to contain '$needle')"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if printf '%s' "$haystack" | grep -qF -- "$needle"; then
    echo "  FAIL: $desc (expected NOT to contain '$needle')"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  fi
}

echo "=== test-grok-provider.sh ==="

# Isolate config so this repo's live CLI/PROVIDER don't leak into tests.
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
mkdir -p "$TMPDIR/docs/sprintbias/cli" "$TMPDIR/docs/sprintbias/ai" "$TMPDIR/docs/tmp"
cp "$SPRINTBIAS/lib.sh" "$TMPDIR/docs/sprintbias/lib.sh"
cp "$SPRINTBIAS/cli/"*.sh "$TMPDIR/docs/sprintbias/cli/"
# Minimal config: empty MODE, no PROVIDER (force inference from CLI).
cat > "$TMPDIR/docs/sprintbias/config" << 'EOF'
CLI=grok
PROVIDER=
MODE=
MODEL_DEFAULT=
MODEL_CHAT=
EOF

cd "$TMPDIR"
# Clear agent env so mode tests start clean.
unset CLAUDECODE CLAUDE_CODE_SESSION_ID CURSOR_TRACE_ID CURSOR_SESSION_ID
unset GROK_AGENT AI_AGENT SPRINTBIAS_IN_AGENT SPRINTBIAS_MODE SPRINTBIAS_PROVIDER SPRINTBIAS_CLI
export SPRINTBIAS_CLI=grok
# shellcheck source=/dev/null
source docs/sprintbias/lib.sh

echo "Test 1: tier inference CLI=grok → grok-build"
assert_eq "tier is grok-build" "grok-build" "$(sprintbias_ai_tier)"

echo "Test 2: profile defines interactive + exec"
assert_true "sprintbias_provider_exec is a function" declare -F sprintbias_provider_exec
assert_true "sprintbias_provider_interactive is a function" declare -F sprintbias_provider_interactive
assert_eq "SPRINTBIAS_PROVIDER_INTERACTIVE=1" "1" "${SPRINTBIAS_PROVIDER_INTERACTIVE:-}"

echo "Test 3: GROK_AGENT → emit mode"
_SPRINTBIAS_MODE_CACHE=""
export GROK_AGENT=1
assert_eq "mode emit with GROK_AGENT" "emit" "$(sprintbias_ai_mode)"
unset GROK_AGENT
_SPRINTBIAS_MODE_CACHE=""

echo "Test 4: no agent env + CLI on PATH → exec (or emit if grok missing)"
# Force CLI presence via a fake binary if needed for stable exec.
if ! command -v grok >/dev/null 2>&1; then
  mkdir -p "$TMPDIR/bin"
  printf '#!/bin/sh\nexit 0\n' > "$TMPDIR/bin/grok"
  chmod +x "$TMPDIR/bin/grok"
  export PATH="$TMPDIR/bin:$PATH"
fi
_SPRINTBIAS_MODE_CACHE=""
assert_eq "mode exec outside agent" "exec" "$(sprintbias_ai_mode)"

echo "Test 5: explicit MODE overrides auto-detect"
export SPRINTBIAS_MODE=emit
_SPRINTBIAS_MODE_CACHE=""
assert_eq "MODE=emit override" "emit" "$(sprintbias_ai_mode)"
export SPRINTBIAS_MODE=exec
_SPRINTBIAS_MODE_CACHE=""
assert_eq "MODE=exec override" "exec" "$(sprintbias_ai_mode)"
unset SPRINTBIAS_MODE
_SPRINTBIAS_MODE_CACHE=""

echo "Test 6: orchestration helpers"
assert_true "orchestration_capable on grok-build" sprintbias_orchestration_capable
assert_eq "subagent tool name" "spawn_subagent" "$(sprintbias_subagent_tool_name)"
_phrase="$(sprintbias_subagent_spawn_phrase "next-id")"
assert_contains "spawn phrase mentions spawn_subagent" "$_phrase" "spawn_subagent"
assert_contains "spawn phrase has general-purpose" "$_phrase" "general-purpose"
assert_contains "own fresh has spawn_subagent" "$(sprintbias_subagent_own_fresh)" "spawn_subagent"
assert_contains "parallel dispatch has spawn_subagent" "$(sprintbias_subagent_parallel_dispatch)" "spawn_subagent"
_nonest="$(sprintbias_subagent_no_nest)"
assert_contains "no-nest names spawn_subagent" "$_nonest" "spawn_subagent"
assert_contains "no-nest says NOT" "$_nonest" "NOT"
assert_contains "no-nest cites nesting depth" "$_nonest" "nesting depth is one"

echo "Test 7: claude-code helpers still say Task tool"
export SPRINTBIAS_PROVIDER=claude-code
assert_true "orchestration_capable on claude-code" sprintbias_orchestration_capable
assert_eq "claude subagent tool name" "Task tool" "$(sprintbias_subagent_tool_name)"
assert_contains "claude own fresh Task tool" "$(sprintbias_subagent_own_fresh)" "Task tool"
_cnonest="$(sprintbias_subagent_no_nest)"
assert_contains "claude no-nest says Task tool" "$_cnonest" "Task tool"
assert_not_contains "claude no-nest never says spawn_subagent" "$_cnonest" "spawn_subagent"
export SPRINTBIAS_PROVIDER=generic
assert_false "generic not orchestration_capable" sprintbias_orchestration_capable
unset SPRINTBIAS_PROVIDER
assert_eq "back to grok-build" "grok-build" "$(sprintbias_ai_tier)"

echo "Test 8: tier model default grok-4.5"
assert_eq "tier model CHAT is grok-4.5" "grok-4.5" "$(sprintbias_tier_model CHAT)"

echo "Test 8b: Claude model pins coerce to grok-4.5 on grok-build"
export SPRINTBIAS_PROVIDER=grok-build
export SPRINTBIAS_MODEL_GATE=opus
_SPRINTBIAS_MODEL_COERCE_WARNED=""
_coerced="$(sprintbias_resolve_model GATE 2>/dev/null)"
assert_eq "MODEL_GATE=opus → grok-4.5" "grok-4.5" "$_coerced"
export SPRINTBIAS_MODEL_GATE=sonnet
_SPRINTBIAS_MODEL_COERCE_WARNED=""
assert_eq "MODEL_GATE=sonnet → grok-4.5" "grok-4.5" "$(sprintbias_resolve_model GATE 2>/dev/null)"
export SPRINTBIAS_MODEL_GATE=claude-opus-4
_SPRINTBIAS_MODEL_COERCE_WARNED=""
assert_eq "MODEL_GATE=claude-opus-4 → grok-4.5" "grok-4.5" "$(sprintbias_resolve_model GATE 2>/dev/null)"
# Native grok id passes through
export SPRINTBIAS_MODEL_GATE=grok-4.5
assert_eq "native grok id unchanged" "grok-4.5" "$(sprintbias_resolve_model GATE 2>/dev/null)"
unset SPRINTBIAS_MODEL_GATE
# Reverse: grok pin on claude-code → opus
export SPRINTBIAS_PROVIDER=claude-code
export SPRINTBIAS_MODEL_WORK=grok-4.5
_SPRINTBIAS_MODEL_COERCE_WARNED=""
assert_eq "grok pin on claude → opus" "opus" "$(sprintbias_resolve_model WORK 2>/dev/null)"
unset SPRINTBIAS_MODEL_WORK
unset SPRINTBIAS_PROVIDER
assert_eq "back to grok-build after coerce tests" "grok-build" "$(sprintbias_ai_tier)"

echo "Test 9: tool mapping (map known Claude names; fail-open on unknown)"
# shellcheck source=/dev/null
source docs/sprintbias/cli/grok.sh
mapped="$(_sprintbias_grok_map_tools "Read,Edit,Write,Bash,Grep,Glob")"
assert_eq "map core tools" "read_file,search_replace,write,run_terminal_command,grep,list_dir" "$mapped"
# Accept-either: both shell ids normalize to the verified canonical run_terminal_command
# (live grok 0.2.117 registry lists run_terminal_command; accepts either as --tools input).
assert_eq "run_terminal_cmd normalizes to canonical" "run_terminal_command" "$(_sprintbias_grok_map_tools "run_terminal_cmd")"
assert_eq "run_terminal_command passes through" "run_terminal_command" "$(_sprintbias_grok_map_tools "run_terminal_command")"
mapped_agent="$(_sprintbias_grok_map_tools "Read,Edit,Agent" || true)"
# Agent is skipped; Read+Edit still map
assert_eq "Agent skipped, rest map" "read_file,search_replace" "$mapped_agent"
if _sprintbias_grok_map_tools "Read,UnknownTool" >/dev/null 2>&1; then
  echo "  FAIL: unmapped tool should fail-open (return non-zero)"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: unmapped tool fails open"
  PASS=$((PASS + 1))
fi

echo "Test 10: profile file ships under docs (ship mirrors to src)"
assert_true "cli/grok.sh exists in docs" test -f "$SPRINTBIAS/cli/grok.sh"

echo "Test 11: provider banner once per process"
# Capture stderr only (pipe so -t 2 is false; no /dev/tty double in CI).
banner_out=$(
  SPRINTBIAS_CLI=grok SPRINTBIAS_PROVIDER=grok-build SPRINTBIAS_MODE=exec \
  GROK_AGENT= CLAUDECODE= \
  bash -c '
    source "'"$SPRINTBIAS"'/lib.sh"
    sprintbias_announce_provider
    sprintbias_announce_provider
  ' 2>&1 >/dev/null
)
assert_contains "banner names grok" "$banner_out" "Provider: grok (grok-build)"
assert_contains "banner names mode" "$banner_out" "mode: exec"
# Exactly one banner line (second call is a no-op).
banner_lines=$(printf '%s\n' "$banner_out" | grep -c 'Provider:' || true)
assert_eq "banner once only" "1" "$banner_lines"

echo "Test 12: every AI role resolves to grok-4.5 under grok-build (empty config)"
export SPRINTBIAS_PROVIDER=grok-build
unset SPRINTBIAS_MODEL_GATE SPRINTBIAS_MODEL_WORK SPRINTBIAS_MODEL_CHAT
_SPRINTBIAS_MODEL_COERCE_WARNED=""
for _role in GATE WORK CHAT SPLIT PLAN_THINK DEPS PROFILE TRIAGE DRIFT FEATURE IDEA POLISH CODE_AUDIT EXCELLENCE AUDIT; do
  _m="$(sprintbias_tier_model "$_role" 2>/dev/null)"
  assert_eq "tier_model $_role → grok-4.5" "grok-4.5" "$_m"
done

echo "Test 13: grok profile always passes --model grok-4.5 (empty and opus)"
# Fake grok prints argv so we can assert --model without network.
_fake_bin="$TMPDIR/bin"
mkdir -p "$_fake_bin"
printf '#!/bin/sh\nprintf "%%s\\n" "$*"\n' > "$_fake_bin/grok"
chmod +x "$_fake_bin/grok"
_argv=$(
  PATH="$_fake_bin:$PATH" \
  SPRINTBIAS_CLI=grok SPRINTBIAS_PROVIDER=grok-build SPRINTBIAS_MODE=exec \
  GROK_AGENT= CLAUDECODE= \
  bash -c '
    source "'"$SPRINTBIAS"'/lib.sh"
    sprintbias_run -p "hi" 2>/dev/null
  '
)
assert_contains "empty model → --model grok-4.5" "$_argv" "--model grok-4.5"
_argv_opus=$(
  PATH="$_fake_bin:$PATH" \
  SPRINTBIAS_CLI=grok SPRINTBIAS_PROVIDER=grok-build SPRINTBIAS_MODE=exec \
  GROK_AGENT= CLAUDECODE= \
  bash -c '
    source "'"$SPRINTBIAS"'/lib.sh"
    sprintbias_run -p "hi" --model opus 2>/dev/null
  '
)
assert_contains "raw --model opus coerced in profile" "$_argv_opus" "--model grok-4.5"
if printf '%s' "$_argv_opus" | grep -qE -- '--model opus(\s|$)'; then
  echo "  FAIL: profile still forwarded --model opus"; FAIL=$((FAIL + 1))
else
  echo "  PASS: profile does not forward --model opus"; PASS=$((PASS + 1))
fi

echo "Test 14: spine scripts use sprintbias_tier_model (not bare resolve)"
for _pair in \
  "gate-lib.sh:sprintbias_tier_model GATE" \
  "work.sh:sprintbias_tier_model WORK" \
  "polish.sh:sprintbias_tier_model POLISH" \
  "chat.sh:sprintbias_tier_model CHAT" \
  "plan-think.sh:sprintbias_tier_model PLAN_THINK" \
  "split.sh:sprintbias_tier_model SPLIT" \
  "deps.sh:sprintbias_tier_model DEPS" \
  "profile.sh:sprintbias_tier_model PROFILE"
do
  _file="${_pair%%:*}"; _needle="${_pair#*:}"
  if grep -qF "$_needle" "$SPRINTBIAS/scripts/$_file" 2>/dev/null; then
    echo "  PASS: $_file uses $_needle"; PASS=$((PASS + 1))
  else
    echo "  FAIL: $_file missing $_needle"; FAIL=$((FAIL + 1))
  fi
done

echo "Test 15: stream-json dual-host contract (work-shaped argv)"
# work.sh requests neutral --output-format stream-json. Profiles must translate:
#   Grok  → streaming-messages-json, never forward --verbose
#   Claude → stream-json + auto --verbose
# Regression: Grok CLI rejects stream-json and --verbose (exit 2, zero work).
_argv_work=$(
  PATH="$_fake_bin:$PATH" \
  SPRINTBIAS_CLI=grok SPRINTBIAS_PROVIDER=grok-build SPRINTBIAS_MODE=exec \
  GROK_AGENT= CLAUDECODE= \
  bash -c '
    source "'"$SPRINTBIAS"'/lib.sh"
    sprintbias_run -p "hi" --model grok-4.5 \
      --tools "Read,Edit,Write,Bash,Grep,Glob,Agent" \
      --permissions auto \
      --output-format stream-json --verbose 2>/dev/null
  '
)
assert_contains "work stream-json → streaming-messages-json" "$_argv_work" "--output-format streaming-messages-json"
assert_not_contains "work never forwards stream-json to grok" "$_argv_work" "stream-json"
assert_not_contains "work never forwards --verbose to grok" "$_argv_work" "--verbose"
assert_contains "work tools map on grok" "$_argv_work" "--tools read_file,search_replace,write,run_terminal_command,grep,list_dir"
assert_contains "work permissions auto on grok" "$_argv_work" "--permission-mode auto"
# work.sh itself must not hardcode Claude-only --verbose on the AI line
if grep -nE -- '--output-format stream-json --verbose' "$SPRINTBIAS/scripts/work.sh" >/dev/null 2>&1; then
  echo "  FAIL: work.sh still passes Claude-only --verbose with stream-json"
  FAIL=$((FAIL + 1))
else
  echo "  PASS: work.sh uses neutral stream-json (no --verbose on AI line)"
  PASS=$((PASS + 1))
fi
# Claude profile: same call site must keep stream-json and add --verbose
printf '#!/bin/sh\nprintf "%%s\\n" "$*"\n' > "$_fake_bin/claude"
chmod +x "$_fake_bin/claude"
_argv_claude=$(
  PATH="$_fake_bin:$PATH" \
  SPRINTBIAS_CLI=claude SPRINTBIAS_PROVIDER=claude-code SPRINTBIAS_MODE=exec \
  GROK_AGENT= CLAUDECODE= \
  bash -c '
    source "'"$SPRINTBIAS"'/lib.sh"
    sprintbias_run -p "hi" --model opus \
      --tools "Read,Edit,Write,Bash,Grep,Glob,Agent" \
      --permissions auto \
      --output-format stream-json 2>/dev/null
  '
)
assert_contains "claude keeps stream-json" "$_argv_claude" "--output-format stream-json"
assert_contains "claude auto-adds --verbose for stream-json" "$_argv_claude" "--verbose"
assert_contains "claude maps tools → allowedTools" "$_argv_claude" "--allowedTools"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
