#!/usr/bin/env bash
# Test: every message ends in an action (plan 32, task 429). The end-of-run
# and gate output of plan start, promote, polish and the gate tells the person
# what to check and the exact command to run next.
#
#   - plan start gates blocked/ members with the rest instead of stopping; a
#     member still BLOCKED is listed with ./sprint.sh chat <id>; the human-test
#     line names ./sprint.sh promote plan:<id>; the last line is Next: work
#   - promote ends each run on a ./sprint.sh line (empty review/, all green,
#     dry run, held) and its audit summary names a command for each outcome
#   - polish's summaries and BLOCKER lines name a command (static: the judge
#     needs a live AI)
#   - the gate's conflict print ends with a newtask line; promote_summary's
#     BLOCKED line names ./sprint.sh chat <id>
#
# Sandboxed boards with a stub CLI; no live AI. Discovered by run-all.sh.

set -euo pipefail
# The breaker before sign-off has its own test (test-edge-cases.sh); these
# fixtures check the shell gates, so it stays off here.
export SPRINTBIAS_BREAK=off

PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SB="$ROOT/docs/sprintbias"

ok()  { echo "  PASS: $1"; PASS=$((PASS + 1)); }
bad() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }
has()   { if grep -qF -- "$3" <<<"$2"; then ok "$1"; else bad "$1 (missing: $3)"; fi; }
lacks() { if grep -qF -- "$3" <<<"$2"; then bad "$1 (found: $3)"; else ok "$1"; fi; }
last_line_is_cmd() {  # last_line_is_cmd LABEL OUTPUT — the last non-rule line names ./sprint.sh
    local last
    last="$(printf '%s\n' "$2" | grep -v '^━' | grep -v '^[[:space:]]*$' | tail -1)"
    case "$last" in *"./sprint.sh "*) ok "$1" ;; *) bad "$1 (last line: $last)" ;; esac
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export NO_COLOR=1

board() {  # board NAME → a fresh board that mirrors an install
    local b="$TMP/$1"
    mkdir -p "$b/docs/tasks"/{backlog,next,doing,review,done,blocked} "$b/docs/plans" "$b/docs/tests" "$b/docs/tmp"
    cp -R "$SB" "$b/docs/sprintbias"
    cp "$ROOT/docs/tasks/.TEMPLATE-task.md" "$b/docs/tasks/"
    rm -f "$b/docs/sprintbias/config.local"
    git -C "$b" init -q
    printf '%s' "$b"
}

# Stub CLI for the gate: reads the task path from the prompt and stamps it.
# A file named *-stuck* is stamped BLOCKED; every other file READY, with a
# testable Done when and one Grounding conflict.
cat > "$TMP/gate-stub" <<'STUB'
#!/usr/bin/env bash
prompt=""
while [ $# -gt 0 ]; do case "$1" in -p) prompt="$2"; shift 2 ;; *) shift ;; esac; done
f="$(printf '%s\n' "$prompt" | sed -n 's/^The task file is at: \(.*\) — read it first\.$/\1/p' | head -1)"
if [ -n "$f" ] && [ -f "$f" ]; then
  case "$f" in
    *-stuck*) printf '\n## Questions\n\n**Status: BLOCKED**\n\n### Questions for the developer\n1. Which account holds the API key?\n' >> "$f" ;;
    *) printf '\n## Done when (automated)\n\n- [ ] works (`bash docs/tests/t.sh`)\n\n## Grounding\n\n**Conflicts:**\n- the task says A, the code says B → follow the code\n\n## Questions\n\n**Status: READY**\n\n### Questions for the developer\nNone — task is fully defined.\n' >> "$f" ;;
  esac
fi
printf '{"type":"result","subtype":"success","num_turns":1,"duration_ms":1,"total_cost_usd":0}\n'
STUB
chmod +x "$TMP/gate-stub"

# ── plan start ───────────────────────────────────────────────────────
echo "plan start"
B="$(board ps)"
printf '# Task 1: one\n\n**Depends on**: none\n\n## Signoff (human)\n\n- [ ] Look at it\n' > "$B/docs/tasks/backlog/1-one.md"
printf '# Task 2: two\n\n**Depends on**: none\n' > "$B/docs/tasks/blocked/2-two.md"
printf '# Task 3: stuck\n\n**Depends on**: none\n' > "$B/docs/tasks/blocked/3-stuck.md"
printf '# Plan 5: P\n\n**Status:** READY\n\n## Goal\n\nG\n\n## Member tasks\n\n- #1 — one\n- #2 — two\n- #3 — stuck\n' \
    > "$B/docs/plans/5-p.md"
out="$(cd "$B" && env -u CLAUDECODE -u CLAUDE_CODE_SESSION_ID -u AI_AGENT -u SPRINTBIAS_IN_AGENT \
    SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$TMP/gate-stub" ./docs/sprintbias/scripts/plan.sh start 5 </dev/null 2>&1)" \
    && rc=0 || rc=$?
if [ "$rc" = 0 ]; then ok "plan start: a blocked/ member does not stop the start"; else bad "plan start: exit $rc"; fi
[ -f "$B/docs/tasks/next/1-one.md" ] && ok "plan start: backlog member reached next/" || bad "plan start: backlog member reached next/"
[ -f "$B/docs/tasks/next/2-two.md" ] && ok "plan start: blocked/ member that can start reached next/" || bad "plan start: blocked/ member that can start reached next/"
[ -f "$B/docs/tasks/blocked/3-stuck.md" ] && ok "plan start: member that cannot start stays in blocked/" || bad "plan start: member that cannot start stays in blocked/"
has   "plan start: blocked member named with its command" "$out" "#3 cannot start yet (see its ## BLOCKED) → ./sprint.sh chat 3"
has   "plan start: human test names promote plan:N" "$out" "→ ./sprint.sh promote plan:5"
has   "plan start: conflicts end in a newtask line" "$out" 'Disagree? → ./sprint.sh newtask "<the change you want>"'
lacks "plan start: no stop on blocked/"   "$out" "resolve decisions/clarifications before starting"
last_line_is_cmd "plan start: last line is a command" "$out"

B="$(board ps2)"
printf '# Task 4: four\n\n**Depends on**: none\n\n## Questions\n\n**Status: READY**\n' > "$B/docs/tasks/backlog/4-four.md"
printf '# Task 6: six\n\n**Depends on**: none\n' > "$B/docs/tasks/blocked/6-six.md"
printf '# Plan 7: Q\n\n**Status:** READY\n\n## Goal\n\nG\n\n## Member tasks\n\n- #4 — four\n- #6 — six\n' \
    > "$B/docs/plans/7-q.md"
out="$(cd "$B" && ./docs/sprintbias/scripts/plan.sh start 7 --commit-only </dev/null 2>&1)" && rc=0 || rc=$?
if [ "$rc" = 0 ]; then ok "plan start --commit-only: runs with a blocked/ member"; else bad "plan start --commit-only: exit $rc"; fi
[ -f "$B/docs/tasks/next/4-four.md" ] && ok "plan start --commit-only: the rest reached next/" || bad "plan start --commit-only: the rest reached next/"
[ -f "$B/docs/tasks/blocked/6-six.md" ] && ok "plan start --commit-only: blocked/ member left in place" || bad "plan start --commit-only: blocked/ member left in place"
has   "plan start --commit-only: blocked member named" "$out" "#6 cannot start yet (see its ## BLOCKED) → ./sprint.sh chat 6"

# ── promote ──────────────────────────────────────────────────────────
echo "promote"
B="$(board pr)"
pr() { (cd "$B" && bash docs/sprintbias/scripts/promote.sh "$@" </dev/null 2>&1) || true; }
out="$(pr)"
has   "promote: empty review/ names work"  "$out" "Build some:  ./sprint.sh work"
out="$(pr 42)"
has   "promote: missing id names search"   "$out" "./sprint.sh search 42"
printf '#!/usr/bin/env bash\nexit 0\n' > "$B/docs/tests/green.sh"
printf '# Task 10: g\n\n**Tests**: docs/tests/green.sh\n**Depends on**: none\n' > "$B/docs/tasks/review/10-g.md"
out="$(pr --dry-run)"
last_line_is_cmd "promote --dry-run: ends in a command" "$out"
has   "promote --dry-run: run it for real" "$out" "Run it for real:  ./sprint.sh promote"
out="$(pr)"
last_line_is_cmd "promote all green: ends in a command" "$out"
has   "promote all green: next is status"  "$out" "Next: ./sprint.sh status"
printf '# Task 11: n\n\n**Tests**: none\n**Depends on**: none\n' > "$B/docs/tasks/review/11-n.md"
out="$(pr)"
last_line_is_cmd "promote skip: ends in a command" "$out"
printf '# Task 12: d\n\n**Tests**: docs/tests/green.sh\n**Depends on**: 13\n' > "$B/docs/tasks/review/12-d.md"
printf '# Task 13: p\n\n**Depends on**: none\n' > "$B/docs/tasks/backlog/13-p.md"
out="$(pr 12)"
last_line_is_cmd "promote held: ends in a command" "$out"
P="$(cat "$SB/scripts/promote.sh")"
has   "promote --audit: NOT-DONE gets a reject line" "$P" './sprint.sh promote --reject $nid \"what is missing\"'
has   "promote --audit: unclear gets a re-judge line" "$P" "re-judge:  ./sprint.sh promote --audit"
has   "promote plan:N: outside hold names the command" "$P" 'Close those first, then:  ./sprint.sh promote plan:$PLAN_ID'
lacks "promote: no bare re-run prose" "$P" "re-run your test and this command."
has   "promote --accept --dry-run: real run keeps --accept" "$P" '[ "$ACCEPT" -eq 1 ] && _real="$_real --accept"'
WK="$(cat "$SB/scripts/work.sh")"
has   "work: landed task names its close command" "$WK" 'Requires human review → $(_close_cmd'
lacks "work: no conditional close prose" "$WK" "promote when **Tests** is set"

# ── polish (static: the judge needs a live AI) ───────────────────────
echo "polish"
PO="$(cat "$SB/scripts/polish.sh")"
has   "polish: summary always names a next command" "$PO" "Next: ./sprint.sh promote   # close what passed"
has   "polish: BLOCKER names polish --code"   "$PO" 'correctness is unproven:  ./sprint.sh polish --code $TASK_FILE'
has   "polish: BLOCKER names chat <id>"       "$PO" 'misses its goal:                      ./sprint.sh chat ${TASK_NAME%%-*}'
has   "polish --code PASS names promote"      "$PO" 'Next: ./sprint.sh promote${_pid:+ $_pid}'
has   "polish --code warnings name a command" "$PO" 'push the work forward:  $_code_cmd'
has   "polish --code re-run is a real command" "$PO" '_code_cmd="./sprint.sh polish --code"'
lacks "polish --code: no <files> placeholder"  "$PO" '<files>}'
has   "polish sweep summary: blocker names chat" "$PO" 'blocker → ./sprint.sh chat $_bid'
lacks "polish sweep: no path re-judge (that is deep-judge)" "$PO" 're-judge:  ./sprint.sh polish $TASK_FILE'
has   "polish: empty review/ names work"      "$PO" "nothing to polish. Build some:  ./sprint.sh work"
lacks "polish: no needs-a-human dead end"     "$PO" "needs a human, not a re-run"
lacks "polish: no needs human intervention"   "$PO" "needs human intervention"

# ── gate ─────────────────────────────────────────────────────────────
echo "gate"
GS="$(cd "$ROOT" && bash -c 'source docs/sprintbias/lib.sh; source docs/sprintbias/scripts/gate-lib.sh
    SPRINTBIAS_GATE_VERDICT=BLOCKED; sprintbias_promote_summary 9-x.md')"
has   "promote_summary: BLOCKED names chat <id>" "$GS" "→ ./sprint.sh chat 9"
GE="$(cd "$ROOT" && env -u CLAUDECODE SPRINTBIAS_MODE=emit bash -c 'source docs/sprintbias/lib.sh; source docs/sprintbias/scripts/gate-lib.sh
    sprintbias_gate_init gate; printf "%s" "$SPRINTBIAS_GATE_MOVE_INSTR"' 2>/dev/null)"
has   "gate emit: conflict print ends in newtask" "$GE" 'Disagree? → ./sprint.sh newtask "<the change you want>"'

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
