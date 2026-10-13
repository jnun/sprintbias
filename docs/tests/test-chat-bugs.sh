#!/usr/bin/env bash
# Test: chat bugs — the sort acts on each lane with no menu.
#   TASK   → a shell copy of the report, one glean pass, the report deleted;
#            when the glean pass fails, the copy stands
#   FIXED  → the report deleted, no task
#   DECIDE → the same backlog task, carrying the question as an open question
#            (so it waits for an answer), the report deleted
# Drives the real script through a pseudo-terminal (script(1)); skips without one.

set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SB="$ROOT/docs/sprintbias"
PASS=0; FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  PASS: $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL: $1"; }
has()   { if grep -qF -- "$3" <<<"$2"; then ok "$1"; else bad "$1 (missing: $3)"; fi; }
lacks() { if grep -qF -- "$3" <<<"$2"; then bad "$1 (found: $3)"; else ok "$1"; fi; }

if ! command -v script >/dev/null 2>&1; then echo "  SKIP: no script(1)"; echo "Results: 0 passed, 0 failed"; exit 0; fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
export NO_COLOR=1
BUG=docs/bugs/3-buttons-on-dashboard-are-odd.md

board() {
    local b="$TMP/$1"
    mkdir -p "$b/docs/tasks"/{backlog,next,doing,review,done,blocked} "$b/docs/bugs" "$b/docs/tmp"
    cp -R "$SB" "$b/docs/sprintbias"
    cp "$ROOT/docs/tasks/.TEMPLATE-task.md" "$b/docs/tasks/"
    rm -f "$b/docs/sprintbias/config.local"
    git -C "$b" init -q
    printf '# Bug 3: buttons on dashboard are odd\n\n**Severity:** LOW\n\n## Problem\n\nThe buttons look inconsistent.\n\n## Steps to reproduce\n\n1.\n\n## Success criteria\n\n- [ ]\n\n## Notes\n\n' \
        > "$b/$BUG"
    printf '%s' "$b"
}

# Stub CLI: the verdict prompt gets the lane in STUB_LANE (default TASK) and
# logs that it ran; the glean prompt (it names a Task file) appends a marker
# to that task, or fails when GLEAN_FAIL is set.
cat > "$TMP/stub" <<'STUB'
#!/usr/bin/env bash
prompt=""
while [ $# -gt 0 ]; do case "$1" in -p) prompt="$2"; shift 2 ;; *) shift ;; esac; done
t="$(printf '%s\n' "$prompt" | sed -n 's/^Task file:  \([^ ]*\) .*/\1/p' | head -1)"
if [ -n "$t" ]; then
  [ -n "${GLEAN_FAIL:-}" ] && exit 1
  printf '\n- Decided: GLEANED, because the stub ran\n' >> "$t"; exit 0
fi
echo verdict >> docs/tmp/stub-verdicts
printf 'LANE: %s\nSUMMARY: The cards differ.\nQUESTION: %s\nSTANDARD: `docs/guides/design-system.md` → Dashboard action cards\n' \
  "${STUB_LANE:-TASK}" "$([ "${STUB_LANE:-}" = DECIDE ] && echo 'Which card layout is right?' || echo none)"
STUB
chmod +x "$TMP/stub"

sweep() {  # sweep BOARD ANSWER [ENV...] → the sweep's output, answering one prompt
    local b="$1" choice="$2"; shift 2
    local cmd="cd '$b' && env -u CLAUDECODE -u CLAUDE_CODE_SESSION_ID -u AI_AGENT -u SPRINTBIAS_IN_AGENT SPRINTBIAS_MODE=exec SPRINTBIAS_CLI='$TMP/stub' $* bash docs/sprintbias/scripts/chat-bugs.sh"
    if script -q /dev/null true </dev/null >/dev/null 2>&1; then
        { sleep 4; printf '%s\n' "$choice"; sleep 2; } | script -q /dev/null bash -c "$cmd" 2>&1
    else
        { sleep 4; printf '%s\n' "$choice"; sleep 2; } | script -q -c "$cmd" /dev/null 2>&1
    fi
}

echo "Test 1: TASK copies, gleans, deletes — no menu"
B="$(board one)"
out="$(sweep "$B" s)"
lacks "task: no per-bug menu" "$out" "[c] Create task"
has "task: lane shown" "$out" "TASK → backlog"
has "task: names the standard" "$out" "Standard: \`docs/guides/design-system.md\` → Dashboard action cards"
t="$(ls "$B"/docs/tasks/backlog/*-fix-*.md 2>/dev/null | head -1)"
[ -n "$t" ] && ok "task: fix task in backlog/" || bad "task: fix task in backlog/"
body="$(cat "$t" 2>/dev/null)"
has "task: report copied" "$body" "The buttons look inconsistent."
has "task: standard carried" "$body" "**Standard:** \`docs/guides/design-system.md\` → Dashboard action cards"
has "task: glean pass ran"   "$body" "- Decided: GLEANED"
[ ! -f "$B/$BUG" ] && ok "task: report deleted" || bad "task: report deleted"
has "task: tally" "$out" "Tasks (backlog/):   1"
has "task: copyable chat line" "$out" "./sprint.sh chat $(basename "$t" | cut -d- -f1)    # Fix: buttons on dashboard are odd"

echo "Test 2: a failed glean keeps the copy"
B="$(board two)"
out="$(sweep "$B" s GLEAN_FAIL=1)"
t="$(ls "$B"/docs/tasks/backlog/*-fix-*.md 2>/dev/null | head -1)"
body="$(cat "$t" 2>/dev/null)"
has "glean fail: copy stands" "$body" "The buttons look inconsistent."
has "glean fail: says so"     "$out" "kept the report's copy"
[ ! -f "$B/$BUG" ] && ok "glean fail: report still deleted" || bad "glean fail: report still deleted"

echo "Test 3: FIXED discards"
B="$(board three)"
out="$(sweep "$B" s STUB_LANE=FIXED)"
has "fixed: lane shown" "$out" "FIXED → discarded"
[ ! -f "$B/$BUG" ] && ok "fixed: report deleted" || bad "fixed: report deleted"
[ -z "$(ls "$B"/docs/tasks/backlog/*.md 2>/dev/null)" ] && ok "fixed: no task" || bad "fixed: no task"
has "fixed: evidence listed" "$out" "3-buttons-on-dashboard-are-odd.md — The cards differ."

echo "Test 4: DECIDE files a task that waits on the question"
B="$(board four)"
out="$(sweep "$B" s STUB_LANE=DECIDE)"
lacks "decide: no prompt" "$out" "[t]"
has "decide: lane shown" "$out" "DECIDE → backlog, waiting on your answer"
t="$(ls "$B"/docs/tasks/backlog/*-fix-*.md 2>/dev/null | head -1)"
[ -n "$t" ] && ok "decide: task in backlog/" || bad "decide: task in backlog/"
[ ! -f "$B/$BUG" ] && ok "decide: report deleted" || bad "decide: report deleted"
q="$(cd "$ROOT" && bash -c 'source docs/sprintbias/lib.sh; sprintbias_open_questions "$1"' _ "$t")"
has "decide: question is open on the task" "$q" "Which card layout is right?"
has "decide: summary lists it" "$out" "./sprint.sh chat $(basename "$t" | cut -d- -f1)    # waiting on you: Which card layout is right?"
has "decide: tally" "$out" "Waiting on you:     1"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
