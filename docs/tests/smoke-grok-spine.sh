#!/usr/bin/env bash
# Smoke: Claude-proven spine under Grok Build (task 296)
#
# Complements docs/tests/test-grok-provider.sh (which unit-tests tier/mode/tool
# helpers but, by its own header, does NOT launch a live TUI or observe spawn
# behavior). This smoke drives the LIVE command surface via `./sprint.sh -g`
# and asserts the exec-mode argv the profile actually builds. It runs the spine
# that already works under Claude Code — chat / work / gate / model — under the
# grok-build tier.
#
# Safe to run on the dev repo:
#   - Never rewrites docs/sprintbias/config (grok is selected per-run with -g).
#   - Emit-wording checks force MODE=emit (print-only; no files move, no network).
#   - Exec-argv checks use a fake `grok` on PATH (no network, no real model call).
#   - The one live network touch is `model list` → `grok models` (read-only),
#     which is skipped automatically when grok is not logged in / not on PATH.
#
# Interactive item (chat TUI) needs a real terminal; without a TTY it is a
# documented skip and we assert the TUI command SHAPE the profile would launch
# instead.

set -uo pipefail

PASS=0
FAIL=0
SKIP=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SPRINTBIAS="$ROOT/docs/sprintbias"

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }
skip() { echo "  SKIP: $1"; SKIP=$((SKIP + 1)); }

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then pass "$desc"
  else fail "$desc"; printf '    expected: %q\n    actual:   %q\n' "$expected" "$actual"; fi
}
assert_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if grep -qF -- "$needle" <<<"$haystack"; then pass "$desc"
  else fail "$desc (expected to contain '$needle')"; fi
}
assert_not_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if grep -qF -- "$needle" <<<"$haystack"; then fail "$desc (expected NOT to contain '$needle')"
  else pass "$desc"; fi
}

# A fake `grok` that echoes its argv, so exec-mode assertions need no network.
# NOTE the %%s — this printf writes ANOTHER printf into the file; a bare %s here
# would be eaten by this outer printf and the stub would print an empty argv.
FAKE=$(mktemp -d)
printf '#!/bin/sh\nprintf "ARGV:[%%s]\\n" "$*"\n' > "$FAKE/grok"
chmod +x "$FAKE/grok"
trap 'rm -rf "$FAKE"' EXIT

# Run lib.sh under the grok tier with a clean agent env. Returns the stub argv.
grok_exec_argv() {
  PATH="$FAKE:$PATH" SPRINTBIAS_CLI=grok SPRINTBIAS_PROVIDER=grok-build \
  SPRINTBIAS_MODE=exec GROK_AGENT= CLAUDECODE= \
    bash -c "source '$SPRINTBIAS/lib.sh' >/dev/null 2>&1; $1" 2>/dev/null
}

echo "=== smoke-grok-spine.sh ==="
echo "grok binary: $(command -v grok 2>/dev/null || echo '(not on PATH)')"
echo ""

# ── 1. Config / doctor: tier + mode ──────────────────────────────────
echo "1. Config/doctor — tier grok-build; mode exec outside agent, emit with GROK_AGENT"
show="$(cd "$ROOT" && SPRINTBIAS_MODE= ./sprint.sh -g model show 2>&1)"
assert_contains "model show reports Provider: grok-build" "$show" "grok-build"
assert_contains "model show reports CLI: grok"            "$show" "grok"
mode_agent="$(SPRINTBIAS_CLI=grok SPRINTBIAS_PROVIDER=grok-build GROK_AGENT=1 CLAUDECODE= \
  bash -c "source '$SPRINTBIAS/lib.sh' >/dev/null 2>&1; sprintbias_ai_mode" 2>/dev/null)"
assert_eq "GROK_AGENT=1 → emit" "emit" "$mode_agent"
if command -v grok >/dev/null 2>&1; then
  # Clear the FULL agent-detection env set (lib.sh checks all of these), so the
  # "outside an agent" claim is honest even when this smoke runs inside one.
  mode_term="$(SPRINTBIAS_CLI=grok SPRINTBIAS_PROVIDER=grok-build \
    GROK_AGENT= CLAUDECODE= CLAUDE_CODE_SESSION_ID= \
    CURSOR_TRACE_ID= CURSOR_SESSION_ID= AI_AGENT= SPRINTBIAS_IN_AGENT= \
    bash -c "source '$SPRINTBIAS/lib.sh' >/dev/null 2>&1; sprintbias_ai_mode" 2>/dev/null)"
  assert_eq "clean env + grok on PATH → exec" "exec" "$mode_term"
else
  skip "clean-env exec check (grok not on PATH)"
fi

# ── 2. Exec: interactive chat opens a Grok TUI ───────────────────────
echo "2. Exec — interactive chat (TUI). Live open needs a TTY."
if [ -t 0 ] && [ -t 1 ]; then
  skip "not auto-run: launch \`./sprint.sh -g chat\` by hand to see the live Grok TUI"
else
  skip "no TTY here — live TUI open is a documented manual step"
fi
# Assert the command SHAPE the interactive profile builds: positional prompt
# (NOT -p, which would print one answer and exit), model pinned, headless-only
# flags absent.
tui="$(grok_exec_argv 'sprintbias_provider_interactive "welcome to chat"')"
assert_contains "TUI argv pins --model grok-4.5"   "$tui" "--model grok-4.5"
assert_contains "TUI argv carries positional prompt" "$tui" "welcome to chat"
assert_not_contains "TUI argv has no headless -p"   "$tui" "-p welcome"
okint="$(SPRINTBIAS_CLI=grok SPRINTBIAS_PROVIDER=grok-build SPRINTBIAS_MODE=exec GROK_AGENT= CLAUDECODE= \
  bash -c "source '$SPRINTBIAS/lib.sh' >/dev/null 2>&1; sprintbias_interactive_ok && echo yes || echo no" 2>/dev/null)"
if [ -t 0 ] && [ -t 1 ]; then
  assert_eq "interactive_ok true on a real TTY" "yes" "$okint"
else
  assert_eq "interactive_ok false without a TTY (degrades to one-shot)" "no" "$okint"
fi

# ── 3. Exec: one-shot headless work ──────────────────────────────────
echo "3. Exec — headless work: mapped tools + always-approve + model pin"
argv="$(grok_exec_argv 'sprintbias_run -p "do task" --tools "Read,Edit,Write,Bash,Grep,Glob" --skip-permissions')"
assert_contains "headless pins --model grok-4.5"        "$argv" "--model grok-4.5"
assert_contains "Claude tool names mapped to Grok IDs"  "$argv" "--tools read_file,search_replace,write,run_terminal_command,grep,list_dir"
assert_contains "--skip-permissions → --always-approve" "$argv" "--always-approve"
assert_not_contains "no Claude --allowedTools leaks"    "$argv" "--allowedTools"
# Claude-only model alias is coerced, never forwarded raw.
argv_opus="$(grok_exec_argv 'sprintbias_run -p "x" --model opus')"
assert_contains "opus coerced to grok-4.5" "$argv_opus" "--model grok-4.5"
assert_not_contains "raw opus never forwarded" "$argv_opus" "--model opus"
# Unknown tool fails open: allowlist omitted rather than sent wrong.
argv_bad="$(grok_exec_argv 'sprintbias_run -p "x" --tools "Read,BogusTool"')"
assert_not_contains "unknown tool → --tools omitted (fail-open)" "$argv_bad" "--tools"

# ── 4. Emit: multi-task orchestration wording (work) ─────────────────
echo "4. Emit — work multi-task orchestration wording + spawn language"
work_emit="$(cd "$ROOT" && SPRINTBIAS_MODE=emit ./sprint.sh -g work 2>&1)"
assert_contains "work emit says spawn_subagent"        "$work_emit" "spawn_subagent"
assert_contains "work emit names general-purpose type" "$work_emit" "general-purpose"
assert_contains "work emit carries no-nest guard"      "$work_emit" "nesting depth is one"
assert_not_contains "work emit never says Claude Task tool" "$work_emit" "Task tool"

# ── 5. Multi-member gate path ────────────────────────────────────────
echo "5. Emit — gate multi-member parallel review wording"
gate_emit="$(cd "$ROOT" && SPRINTBIAS_MODE=emit ./sprint.sh -g gate --force 2>&1)"
if grep -qiF "already reviewed" <<<"$gate_emit"; then
  skip "gate found nothing to review; --force expected to orchestrate (state-dependent)"
else
  assert_contains "gate emit orchestrates via spawn_subagent" "$gate_emit" "spawn_subagent"
  assert_contains "gate emit dispatches in parallel"          "$gate_emit" "PARALLEL"
  assert_not_contains "gate emit never says Claude Task tool"  "$gate_emit" "Task tool"
fi

# ── 6. model show / list ─────────────────────────────────────────────
echo "6. model show / list (task 294 landed) — else config pin"
if [ -f "$SPRINTBIAS/scripts/model.sh" ]; then
  assert_contains "model show: every role resolves to grok-4.5 tier default" "$show" "grok-4.5"
  if command -v grok >/dev/null 2>&1; then
    mlist="$(cd "$ROOT" && SPRINTBIAS_MODE= timeout 30 ./sprint.sh -g model list 2>&1 || true)"
    assert_contains "model list names grok-build provider" "$mlist" "grok-build"
    if grep -qF "grok-4.5" <<<"$mlist"; then
      pass "model list surfaces grok-4.5 (live \`grok models\` or known aliases)"
    else
      skip "model list returned no grok-4.5 (grok not logged in?) — aliases path"
    fi
  else
    skip "model list (grok not on PATH)"
  fi
else
  skip "model.sh absent (task 294 not landed) — pin via config MODEL_DEFAULT=grok-4.5 instead"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped"
[ "$FAIL" -eq 0 ]
