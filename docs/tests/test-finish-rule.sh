#!/usr/bin/env bash
# Test: the finishing rule (plan 32). One rule, stated once in lib.sh
# (sprintbias_assume_rule) and carried by every prompt that can stop work or
# ask the person: decide, record `- Decided: X, because Y`, keep going; ask only
# goal questions in a live conversation; blocked/ only for work that cannot
# start. Fast mode adds reach only (sprintbias_fast_rules).
#
# Pure text checks plus prompt renders in a sandbox; no live AI. Discovered by
# run-all.sh. Later plan-32 tasks add their surfaces below.

set -euo pipefail

PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SB="$ROOT/docs/sprintbias"

ok()  { echo "  PASS: $1"; PASS=$((PASS + 1)); }
bad() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }
# Here-string, not a pipe: grep -q exits on the first match, and under pipefail
# the writer's SIGPIPE on a large body would read as a miss.
# Whitespace runs collapse on both sides, so a needle wrapped across lines must
# match as one phrase (grep -F reads each needle line as its own pattern).
_flat() { tr -s '[:space:]' ' ' <<<"$1" | sed 's/ $//'; }
_found() { local n; n="$(_flat "$2")"; grep -qF -- "$n" <<<"$(_flat "$1")"; }
has()  { if _found "$2" "$3"; then ok "$1"; else bad "$1 (missing: $3)"; fi; }
lacks() { if _found "$2" "$3"; then bad "$1 (found: $3)"; else ok "$1"; fi; }

rule()  { (cd "$ROOT" && bash -c 'source docs/sprintbias/lib.sh; sprintbias_assume_rule'); }
fastr() { (cd "$ROOT" && SPRINTBIAS_FAST="$1" bash -c 'source docs/sprintbias/lib.sh; sprintbias_fast_rules'); }

# ── 424: one finishing rule; fast adds reach only ────────────────────
echo "Finishing rule (lib.sh)"
R="$(rule)"
has   "rule: decide by best practice"      "$R" "best practice, good security, elegant code and the"
has   "rule: Decided bullet form"          "$R" "  - Decided: X, because Y"
has   "rule: Assumptions during work"      "$R" "### Assumptions under ## Completed"
has   "rule: change a call with newtask"   "$R" './sprint.sh newtask "<the change you want>"'
has   "rule: person-only check → Signoff"  "$R" "## Signoff (human)"
has   "rule: ask only in a live conversation" "$R" "only in a live conversation"
has   "rule: only goal-changing questions" "$R" "changes
  the goal or the result"
has   "rule: one-keystroke form"           "$R" "1/2/3 with one marked (suggested)"
has   "rule: go on with the suggested option" "$R" "Go on
  with the suggested option meanwhile"
has   "rule: headless decides"             "$R" "Without a conversation, decide."
has   "rule: blocked/ = cannot start"      "$R" "blocked/ is for work that cannot start"
has   "rule: access the person holds"      "$R" "access or credentials only the person holds"
has   "rule: tool idea → newtask"          "$R" 'A tool or process idea becomes ./sprint.sh newtask'
lines="$(printf '%s\n' "$R" | wc -l | tr -d ' ')"
# 22: task 443 added the build-in-class / filed-scope-out lines.
if [ "$lines" -le 22 ]; then ok "rule: short (<= 22 lines, got $lines)"; else bad "rule: short (<= 22 lines, got $lines)"; fi
has   "rule: design choice in class is built" "$R" "Decide and build each design choice inside the example's class"
has   "rule: scope-out names its task"      "$R" "- Decided: X is out of scope, because Y; filed as #N"
F="$(fastr on)"
has   "fast: adds reach"                   "$F" "Fast mode adds reach:"
lacks "fast: no second decide rule"        "$F" "Decided:"
if [ -z "$(fastr off)" ]; then ok "fast: empty when off"; else bad "fast: empty when off"; fi
LIB="$(cat "$SB/lib.sh")"
for gone in "goal-shaping item waits" "write the question into the task file" \
            "product/scope fork for the human"; do
    lacks "lib.sh: no \"$gone\"" "$LIB" "$gone"
done
G="$(cd "$ROOT" && bash -c 'source docs/sprintbias/lib.sh; sprintbias_grounding_rule')"
has   "grounding: scope conflict is decided" "$G" "decided like any call"

DOC="$(cat "$ROOT/DOCUMENTATION.md")"
has   "manual: chat asks, work finishes"  "$DOC" "**Chat asks; work finishes.**"
FASTSEC="$(awk '/^### Fast mode/{f=1;next} f&&/^## /{exit} f' "$ROOT/DOCUMENTATION.md")"
has   "manual: fast adds reach"            "$FASTSEC" "Fast mode adds reach"
lacks "manual: fast section has no second question rule" "$FASTSEC" "Ask only goal questions"
lacks "manual: no one-at-a-time rule"      "$DOC" "Raise decisions one at a time"


# ── 425: the gate's question procedure is the finishing rule ─────────
echo "Gate contract (gate-lib.sh)"
gate_contract() {
    (cd "$ROOT" && bash -c 'source docs/sprintbias/lib.sh; source docs/sprintbias/scripts/gate-lib.sh
        SPRINTBIAS_GATE_ORIENT=""; SPRINTBIAS_GATE_SPRINT_BLOCK=""; sprintbias_gate_contract T.md')
}
GC_ERR="$(gate_contract 2>&1 >/dev/null)"
GC="$(gate_contract 2>/dev/null)"
if [ -z "$GC_ERR" ]; then ok "gate: renders with nothing on stderr"; else bad "gate: renders with nothing on stderr ($GC_ERR)"; fi
has   "gate: carries the finishing rule"   "$GC" "$(rule | head -1)"
has   "gate: literal Decided format"       "$GC" "Decided: X, because Y"
has   "gate: decide each question"         "$GC" "Questions in the gate: decide each one."
has   "gate: READY needs the None line"    "$GC" "None — task is fully defined."
has   "gate: BLOCKED = cannot start"       "$GC" "BLOCKED — the task cannot start"
has   "gate: BLOCKED ends in chat command" "$GC" "Run ./sprint.sh chat <task-number>."
for gone in "GET the answer" "Bar for an open question" "(Suggestion: [pick and why])" \
            "needs a decision or clarification before work can start"; do
    lacks "gate: no \"$gone\"" "$GC" "$gone"
done
qlines="$(printf '%s\n' "$GC" | awk '/^Questions in the gate:/{f=1} f&&/^$/{exit} f' | wc -l | tr -d ' ')"
if [ "$qlines" -le 12 ]; then ok "gate: question procedure <= 12 lines ($qlines)"; else bad "gate: question procedure <= 12 lines ($qlines)"; fi
glines="$(printf '%s\n' "$GC" | wc -l | tr -d ' ')"
# 240 lines before plan 32 (orientation and sprint index left out).
if [ "$glines" -le 210 ]; then ok "gate: contract at least 30 lines shorter ($glines)"; else bad "gate: contract at least 30 lines shorter ($glines)"; fi


# ── 426: work prompts carry the rule once and no fork-stop ───────────
echo "Work prompts (work.sh)"
W_SB="$(mktemp -d)"
trap 'rm -rf "$W_SB"' EXIT
mkdir -p "$W_SB"/docs/tasks/{next,doing,review,blocked,backlog,done} "$W_SB/docs/tmp"
cat > "$W_SB/stub" <<'STUB'
#!/usr/bin/env bash
while [ $# -gt 0 ]; do case "$1" in -p) printf '%s' "$2" > docs/tmp/prompt.txt; shift 2 ;; *) shift ;; esac; done
printf '{"type":"result","subtype":"success","num_turns":1,"duration_ms":1,"total_cost_usd":0}\n'
STUB
chmod +x "$W_SB/stub"
seed_task() { printf '# Task 100: Thing\n\nDo it.\n\n## Questions\n\n**Status: READY**\n' > "$W_SB/docs/tasks/next/100-thing.md"; }
seed_task
(cd "$W_SB" && SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$W_SB/stub" NO_COLOR=1 \
    bash "$SB/scripts/work.sh" </dev/null >/dev/null 2>&1) || true
WX="$(cat "$W_SB/docs/tmp/prompt.txt" 2>/dev/null || true)"
rm -f "$W_SB"/docs/tasks/*/*.md; seed_task
WO="$(cd "$W_SB" && SPRINTBIAS_MODE=emit SPRINTBIAS_PROVIDER=claude-code NO_COLOR=1 bash "$SB/scripts/work.sh" </dev/null 2>&1 || true)"
WS="$(cd "$W_SB" && SPRINTBIAS_MODE=emit SPRINTBIAS_PROVIDER=generic NO_COLOR=1 bash "$SB/scripts/work.sh" </dev/null 2>&1 || true)"
HEAD1="$(rule | head -1)"
for pair in "exec:$WX" "orchestrated emit:$WO" "sequential emit:$WS"; do
    label="${pair%%:*}"; body="${pair#*:}"
    n="$(printf '%s\n' "$body" | grep -cxF -- "$HEAD1" || true)"
    if [ "$n" = 1 ]; then ok "work $label: finishing rule once"; else bad "work $label: finishing rule once (got $n)"; fi
    for gone in "Product/scope fork" "product/scope fork" "pick a sensible default" \
                "A person-only check never holds a task" "Choose best practice and finish"; do
        lacks "work $label: no \"$gone\"" "$body" "$gone"
    done
done
has   "work emit: Reason names cannot-start causes" "$WO" "no reasonable reading,
          access or credentials only the person holds"
has   "proof rule: cannot start = no reading or access" "$(cd "$ROOT" && bash -c 'source docs/sprintbias/lib.sh; sprintbias_proof_rule')" "no reasonable reading, or access or credentials"


# ── 430: chat guidance interviews; refine/work guidance decides ──────
echo "AI guidance (ai/)"
CV="$(cat "$SB/ai/conversation.md")"
has   "conversation: one issue at a time"  "$CV" "## Many decisions: one issue at a time"
has   "conversation: ask and wait"         "$CV" "End with the question
   and wait."
has   "conversation: (suggested) pick"     "$CV" "(suggested)"
has   "conversation: self-settled calls recorded" "$CV" '`- Decided: X, because Y`'
has   "conversation: recap ends with the next command" "$CV" "end with
the exact next command"
RF="$(cat "$SB/ai/refine.md")"
has   "refine: a design choice is decided" "$RF" "A design choice inside the gap (which of two designs?)"
has   "refine: BLOCKER reason names chat"  "$RF" 'reason names `./sprint.sh chat <id>`'
has   "refine: BLOCKER reason names polish --code" "$RF" 'reason names `./sprint.sh polish --code <file>`'
lacks "refine: no BLOCKER for a human choice" "$RF" "BLOCKER for human attention"
lacks "refine: no fix-needs-a-human"       "$RF" "the fix needs a human"
TC="$(cat "$SB/ai/task-creation.md")"
has   "task-creation: questions become instructions" "$TC" "### Questions become instructions"
has   "task-creation: blocked = cannot start" "$TC" "means *this* task cannot start"
has   "task-creation: Q&A waits for answers" "$TC" "Wait for answers."
has   "task-creation: confirm understanding" "$TC" "### 5. Confirm Understanding"
has   "task-creation: open question never holds work" "$TC" "work\` takes the
suggestion as the answer"
lacks "task-creation: no open-questions-block" "$TC" "Open questions keep the task **BLOCKED**"


# ── 431: chat sessions ask; plan think and crew decide ───────────────
echo "Interactive prompts (chat, chat plan, chat sprint, plan think, crew)"
IB="$(mktemp -d)"
trap 'rm -rf "$W_SB" "$IB"' EXIT
mkdir -p "$IB/docs/tasks"/{backlog,next,doing,review,done,blocked} "$IB/docs/plans" "$IB/docs/crew" "$IB/docs/tmp"
cp -R "$SB" "$IB/docs/sprintbias"; cp "$ROOT/sprint.sh" "$IB/"
cp "$ROOT/docs/crew/.TEMPLATE-crew.md" "$IB/docs/crew/"
rm -f "$IB/docs/sprintbias/config.local"
printf '# Task 100: Thing\n\n**Plan**: 1\n\n## Problem\n\nX\n' > "$IB/docs/tasks/backlog/100-thing.md"
printf '# Task 101: Queued\n\n**Plan**: none\n\n## Problem\n\nY\n' > "$IB/docs/tasks/next/101-queued.md"
printf '# Plan 1: P\n\n**Status:** DRAFT\n\n## Goal\n\nG\n\n## Member tasks\n\n- #100 — Thing\n' > "$IB/docs/plans/1-p.md"
(cd "$IB" && git init -q)
iemit() {  # iemit ARGS… → the emitted prompt (fast off)
    (cd "$IB" && env -u CLAUDECODE -u CLAUDE_CODE_SESSION_ID -u AI_AGENT -u SPRINTBIAS_IN_AGENT \
        SPRINTBIAS_FAST=off SPRINTBIAS_MODE=emit SPRINTBIAS_CLI=claude ./sprint.sh "$@" </dev/null 2>&1) || true
}
(cd "$IB" && ./sprint.sh crew add dill "Finds and fixes bugs" >/dev/null 2>&1; ./sprint.sh crew add orcha "Leads" --lead >/dev/null 2>&1) || true
PCHAT="$(iemit chat 100)"
PPLAN="$(iemit chat plan 1)"
PSPRINT="$(iemit chat)"
PTHINK="$(iemit plan think 1)"
PMEM="$(iemit crew dill 100)"
PLEAD="$(iemit crew orcha plan:1)"
PSETUP="$(iemit crew setup)"
# work-side sessions make best-practice calls: they carry the finishing rule.
for pair in "plan think:$PTHINK" "crew member:$PMEM" "crew lead:$PLEAD" "crew setup:$PSETUP"; do
    label="${pair%%:*}"; body="${pair#*:}"
    has "$label: carries the finishing rule" "$body" "$HEAD1"
done
# chat sessions dig into questions with the person: no finishing rule, Q&A kept.
for pair in "chat:$PCHAT" "chat plan:$PPLAN" "chat sprint:$PSPRINT"; do
    label="${pair%%:*}"; body="${pair#*:}"
    lacks "$label: no finishing rule (chat asks)" "$body" "$HEAD1"
done
has   "chat: one question, wait"            "$PCHAT" "One question at a time; wait for the answer."
has   "chat: questions become instructions" "$PCHAT" "Questions become instructions:"
has   "chat: chat is where questions get dug into" "$PCHAT" "This is the time to dig into questions and decisions with the person"
has   "chat: closes with the next command"  "$PCHAT" "End with the exact next command (usually ./sprint.sh work 100)"
has   "chat: open question keeps its suggestion" "$PCHAT" "work takes the suggestion as the answer"
has   "chat: demote only when it cannot start" "$PCHAT" "Demote
only when the task cannot start at all"
has   "chat plan: focused Q&A"              "$PPLAN" "Through focused Q&A"
has   "chat plan: one question, wait"       "$PPLAN" "One question at a time; wait for the answer."
has   "chat plan: ends with plan start"     "$PPLAN" "end with the next command: './sprint.sh plan start 1'"
has   "chat sprint: user answers or decides" "$PSPRINT" "Let the user ANSWER or DECIDE"
has   "chat sprint: ends with work"         "$PSPRINT" "End with the next command: ./sprint.sh work."
lacks "chat sprint: no keep-BLOCKED-while-open" "$PSPRINT" "remains open, keep the task BLOCKED"
has   "plan think: records calls in the plan" "$PTHINK" "under a ## Decided heading in"
has   "plan think: holds only goal questions" "$PTHINK" "HOLD a finding only when its answer changes the plan's goal"
lacks "plan think: no hold-for-the-human list" "$PTHINK" "genuinely their call"
lacks "crew lead: no one-at-a-time decisions" "$PLEAD" "Raise decisions for the human one at a time"
has   "crew lead: closes with the calls"   "$PLEAD" 'list the calls the crew made (each - Decided: line, with ./sprint.sh newtask "<the change you want>" to change one)'
has   "crew lead: closes with the plan's sign-off" "$PLEAD" "then the next command: ./sprint.sh promote plan:1."
lacks "crew: no ask-the-human for a target" "$(cat "$SB/scripts/crew.sh")" "ask the human which plan to lead"

# ── 436: blocked/ means cannot start on every surface ─────────────────
echo ""
echo "blocked/ = cannot start (436)"
CF="$(cat "$SB/scripts/chat-folder.sh")"
has   "sweep: BLOCKED = cannot start"       "$CF" "BLOCKED = THIS task cannot start: no reasonable reading of it, or it needs access or credentials only the person holds."
has   "sweep: open choice is decided"       "$CF" "An open choice with a reasonable pick is not BLOCKED: decide it, record it in the task's ## Notes as '- Decided: X, because Y'"
has   "sweep verdict: BLOCKED = cannot start" "$CF" "- BLOCKED: THIS task cannot start — no reasonable reading of it"
has   "sweep verdict: open choice → READY + Decided" "$CF" "is NOT blocked: decide it and say READY"
lacks "sweep: no unresolved-choice block"   "$CF" "unresolved choice, open question, contradiction"
has   "sweep: BLOCKED line names chat <id>" "$CF" 'cannot start (not merely waiting on a dep); ./sprint.sh chat $(task_id "$file")'
# [w] writes the sweep's Decided call into ## Notes before the gate runs.
eval "$(sed -n '/^record_decided()/,/^}/p' "$SB/scripts/chat-folder.sh")"
_rd="$IB/rd-task.md"
printf '# Task 9: x\n\n## Notes\n\n- hint\n\n## Questions\n\nNone\n' > "$_rd"
record_decided "$_rd" "Work it: '- Decided: use the blue theme, because it's the house style' to record in ## Notes." >/dev/null
has   "sweep [w]: records the Decided line" "$(cat "$_rd")" "- Decided: use the blue theme, because it's the house style"
has   "sweep [w]: line sits in ## Notes"    "$(awk '/^## Notes/{f=1} /^## Questions/{f=0} f' "$_rd")" "- Decided: use the blue"
record_decided "$_rd" "Move it to next/ via the gate." >/dev/null
has   "sweep [w]: no Decided, file unchanged" "$(grep -c 'Decided' "$_rd")" "1"
has   "status: cannot start + chat <id>"    "$(cat "$ROOT/sprint.sh")" 'Blocked (cannot start):'
has   "status: per-task chat line"          "$(cat "$ROOT/sprint.sh")" 'echo "    ./sprint.sh chat $(basename "$task"'
GT="$(cat "$SB/scripts/gate.sh")"
has   "gate: per-task label"                "$GT" '⊘ Blocked (cannot start) → $BLOCKED_DIR/$TASK_NAME'
has   "gate: summary label above chat queue" "$GT" "⊘ Blocked (cannot start) — each file's ## BLOCKED section says why:"
WK="$(cat "$SB/scripts/work.sh")"
has   "work: drift names its reason"        "$WK" '(drift: outdated)"'
has   "work: drift names chat <id>"         "$WK" 'echo "    ./sprint.sh chat $(task_id "$TASK_NAME")"'
has   "work: drift route kept"              "$WK" 'move_file "$WORKING_DIR/$TASK_NAME" "$BLOCKED_DIR/$TASK_NAME"'
LP="$(cat "$SB/scripts/loop.sh")"
has   "loop: rescue names its reason"       "$LP" 'incomplete → blocked/ (incomplete run)"'
has   "loop: rescue names work <id>"        "$LP" 'echo "    ./sprint.sh work $(task_id "$name")"'
has   "help/status: cannot start"           "$(cat "$SB/help/status.md")" "items in blocked/ that cannot"
has   "help/chat: cannot start"             "$(cat "$SB/help/chat.md")" "means *this* task cannot start"
HW="$(cat "$SB/help/work.md")"
has   "help/work: finish-first decides"     "$HW" 'decide each open call, record it as `- Decided: X, because Y`, and finish.'
has   "help/work: review line cannot start" "$HW" "blocked/ only when the task cannot start)"
lacks "help/work: no human-decision stop"   "$HW" "human decision"
has   "use_chat: BLOCKED = cannot start"    "$(cat "$SB/guides/use_chat.md")" "*This* task cannot start"
# Guard: the old meaning of blocked/ stays gone from every shipped surface.
# Each file is read with whitespace collapsed, so a phrase wrapped across lines
# is caught too.
_old="$(cd "$ROOT" && find docs/sprintbias sprint.sh DOCUMENTATION.md GETSTARTED.md docs/guides/command-matrix.md \
    -type f ! -path '*/tests/*' ! -path '*/__pycache__/*' ! -name '*.pyc' -print0 \
  | xargs -0 perl -0ne 's/\s+/ /g; while (/(decisions? ?(?:or|\/) ?clarifications?|needs? (?:a )?decision|waiting on a decision|owes a decision|scope fork|not defined well enough)/gi) { print "$ARGV: $1\n" }' || true)"
if [ -z "$_old" ]; then ok "no old blocked/ meaning in docs/sprintbias, sprint.sh, DOCUMENTATION.md, GETSTARTED.md, command-matrix"
else bad "old blocked/ meaning found:"; printf '%s\n' "$_old" | sed 's/^/    /'; fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
