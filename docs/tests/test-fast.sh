#!/usr/bin/env bash
# Each check is a string run by eval, so its $vars expand at check time.
# shellcheck disable=SC2016
# Test: fast mode switch — `./sprint.sh fast [on|off]` (scripts/fast.sh), the
# lib.sh reader sprintbias_fast_on, leading --fast / --steady, work / polish
# --fast, and the fast: on|off line in the provider banner and status. Fast on
# also skips the AI CLI's permission prompts and runs work / polish in parallel,
# and every agent prompt carries the sprintbias_fast_rules block.
# Runs on a temp board so the real config.local is never touched.

set -euo pipefail

PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

ok()   { echo "  PASS: $1"; PASS=$((PASS + 1)); }
bad()  { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }
check() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

# ── A temp board that mirrors an install ─────────────────────────────
B="$TMP/board"
mkdir -p "$B/docs/sprintbias" "$B/docs/tasks"/{backlog,next,doing,review,done,blocked}
cp -R "$ROOT/docs/sprintbias/." "$B/docs/sprintbias/"
cp "$ROOT/sprint.sh" "$B/sprint.sh"
rm -f "$B/docs/sprintbias/config.local"
unset SPRINTBIAS_FAST SPRINTBIAS_CONFIG_FILE SPRINTBIAS_CONFIG_LOCAL_FILE
export NO_COLOR=1
LOCAL="$B/docs/sprintbias/config.local"
TRACKED="$B/docs/sprintbias/config"
tracked_sum() { cksum < "$TRACKED"; }
SUM0="$(tracked_sum)"

sb() { (cd "$B" && ./sprint.sh "$@" 2>&1); }
fast_on() {  # fast_on [ENV=val] → prints on|off via the lib.sh reader
    (cd "$B" && env "$@" bash -c 'source docs/sprintbias/lib.sh; sprintbias_fast_state')
}

echo "Syntax"
check "fast.sh parses"   'bash -n "$ROOT/docs/sprintbias/scripts/fast.sh"'

# ── Default ──────────────────────────────────────────────────────────
echo "Default"
check "tracked config ships FAST=off"     'grep -qx "FAST=off" "$TRACKED"'
check "reader defaults to off"            '[ "$(fast_on)" = off ]'
out="$(sb fast)"
check "bare fast prints fast: off"        '[[ "$out" == *"fast: off"* ]]'
check "bare fast shows how to flip"       '[[ "$out" == *"./sprint.sh fast on"* && "$out" == *"./sprint.sh fast off"* ]]'
check "bare fast writes nothing"          '[ ! -f "$LOCAL" ]'
out="$(grep -v '^FAST=' "$TRACKED" > "$TMP/nofast"; cp "$TMP/nofast" "$TRACKED"; fast_on)"
check "no FAST key anywhere → off"        '[ "$out" = off ]'
cp "$ROOT/docs/sprintbias/config" "$TRACKED"

# ── fast on / off write config.local ─────────────────────────────────
echo "Switch"
out="$(sb fast on)"
check "fast on creates config.local"      '[ -f "$LOCAL" ] && grep -qx "FAST=on" "$LOCAL"'
check "fast on reports on"                '[[ "$out" == *"fast: on"* ]]'
check "reader sees on"                    '[ "$(fast_on)" = on ]'
check "tracked config untouched"          '[ "$(tracked_sum)" = "$SUM0" ]'
echo "MODEL_DEFAULT=sonnet" >> "$LOCAL"
out="$(sb fast off)"
check "fast off rewrites in place"        '[ "$(grep -c "^FAST=" "$LOCAL")" = 1 ] && grep -qx "FAST=off" "$LOCAL"'
check "other local keys kept"             'grep -qx "MODEL_DEFAULT=sonnet" "$LOCAL"'
check "reader sees off"                   '[ "$(fast_on)" = off ]'
check "tracked config still untouched"    '[ "$(tracked_sum)" = "$SUM0" ]'
check "bad argument exits non-zero"       '! sb fast maybe >/dev/null'

# ── Precedence: env/flag → config.local → config ─────────────────────
echo "Precedence"
sb fast off >/dev/null
check "env on beats config.local off"     '[ "$(fast_on SPRINTBIAS_FAST=on)" = on ]'
sb fast on >/dev/null
check "env off beats config.local on"     '[ "$(fast_on SPRINTBIAS_FAST=off)" = off ]'
rm -f "$LOCAL"
sed 's/^FAST=off$/FAST=on/' "$ROOT/docs/sprintbias/config" > "$TRACKED"
check "tracked config read when no local" '[ "$(fast_on)" = on ]'
echo "FAST=off" > "$LOCAL"
check "config.local beats tracked config" '[ "$(fast_on)" = off ]'
cp "$ROOT/docs/sprintbias/config" "$TRACKED"; SUM0="$(tracked_sum)"

# ── Per-run leading flags ────────────────────────────────────────────
echo "Per-run flags"
echo "FAST=off" > "$LOCAL"
out="$(sb --fast fast)"
check "--fast turns it on for the run"    '[[ "$out" == *"fast: on"* && "$out" == *"this run"* ]]'
check "--fast leaves config.local alone"  '[ "$(cat "$LOCAL")" = "FAST=off" ]'
echo "FAST=on" > "$LOCAL"
out="$(sb --steady fast)"
check "--steady turns it off for the run" '[[ "$out" == *"fast: off"* ]]'
check "--steady leaves config.local alone" '[ "$(cat "$LOCAL")" = "FAST=on" ]'
out="$(sb --steady -c fast)"
check "--steady combines with -c"         '[[ "$out" == *"fast: off"* ]]'

# work / polish --fast keep 4 jobs and export fast on for the run.
W="$ROOT/docs/sprintbias/scripts/work.sh"
P="$ROOT/docs/sprintbias/scripts/polish.sh"
check "work --fast: 4 jobs + fast on"     '[ "$(grep -cE -- "--fast\)[[:space:]]+PARALLEL=1; MAX_JOBS=4; export SPRINTBIAS_FAST=on" "$W")" = 2 ]'
check "work --steady: fast off"           'grep -qE -- "--steady\)[[:space:]]+export SPRINTBIAS_FAST=off" "$W"'
check "polish --fast: 4 jobs + fast on"   'grep -qE -- "--fast\)[[:space:]]+PARALLEL=1; MAX_JOBS=4; export SPRINTBIAS_FAST=on" "$P"'
check "polish --steady: fast off"         'grep -qE -- "--steady\)[[:space:]]+export SPRINTBIAS_FAST=off" "$P"'

# ── Fast skips permission prompts ────────────────────────────────────
# Stub claude / grok binaries record their argv; the real profiles translate.
echo "Permissions"
mkdir -p "$TMP/bin"
for c in claude grok; do
    printf '#!/bin/sh\nprintf "%%s\\n" "$@" > "%s/argv"\n' "$TMP" > "$TMP/bin/$c"
    chmod +x "$TMP/bin/$c"
done
argv() {  # argv CLI on|off RUNFN → the stub CLI's argv on one line
    rm -f "$TMP/argv"
    (cd "$B" && env -u CLAUDECODE -u CLAUDE_CODE_SESSION_ID -u AI_AGENT \
        -u SPRINTBIAS_IN_AGENT -u GROK_AGENT PATH="$TMP/bin:$PATH" \
        SPRINTBIAS_CLI="$1" SPRINTBIAS_MODE=exec SPRINTBIAS_FAST="$2" bash -c \
        'source docs/sprintbias/lib.sh; sprintbias_load_profile "$SPRINTBIAS_CLI"
         sprintbias_interactive_ok() { return 0; }
         '"$3"' -p hi --permissions auto' </dev/null >/dev/null 2>&1) || true
    tr '\n' ' ' < "$TMP/argv" 2>/dev/null
}
for fn in sprintbias_run sprintbias_run_interactive; do
    out="$(argv claude on $fn)"
    check "claude fast on, $fn: --dangerously-skip-permissions" \
        '[[ "$out" == *"--dangerously-skip-permissions"* && "$out" != *"--permission-mode"* ]]'
    out="$(argv claude off $fn)"
    check "claude fast off, $fn: --permission-mode auto" \
        '[[ "$out" == *"--permission-mode auto"* && "$out" != *"skip-permissions"* ]]'
    out="$(argv grok on $fn)"
    check "grok fast on, $fn: --always-approve" \
        '[[ "$out" == *"--always-approve"* && "$out" != *"--permission-mode"* ]]'
    out="$(argv grok off $fn)"
    check "grok fast off, $fn: --permission-mode auto" \
        '[[ "$out" == *"--permission-mode auto"* && "$out" != *"--always-approve"* ]]'
done

# ── Fast runs work / polish in parallel ──────────────────────────────
echo "Parallel"
par() {  # par FAST PARALLEL MAX_JOBS STEADY → "PARALLEL MAX_JOBS" after fast mode
    (cd "$B" && env SPRINTBIAS_FAST="$1" PARALLEL="$2" MAX_JOBS="$3" bash -c \
        'source docs/sprintbias/lib.sh; sprintbias_fast_parallel '"$4"'; echo "$PARALLEL $MAX_JOBS"')
}
check "fast on, no flag → parallel at 4"   '[ "$(par on 0 2 0)" = "1 4" ]'
check "fast off, no flag → sequential"     '[ "$(par off 0 2 0)" = "0 2" ]'
check "fast on, --jobs 6 → 6 jobs"         '[ "$(par on 1 6 0)" = "1 6" ]'
check "fast on, --parallel → 2 jobs"       '[ "$(par on 1 2 0)" = "1 2" ]'
check "fast on, --steady → sequential"     '[ "$(par on 0 2 1)" = "0 2" ]'
check "--steady beats --parallel"          '[ "$(par off 1 2 1)" = "0 2" ]'
check "work settles via sprintbias_fast_parallel"   'grep -q "sprintbias_fast_parallel \"\$_STEADY\"" "$W"'
check "polish settles via sprintbias_fast_parallel" 'grep -q "\"\$MODE\" = \"sweep\" ] && sprintbias_fast_parallel \"\$_STEADY\"" "$P"'
check "work --jobs sets the count after flags" 'grep -q "\[ -n \"\$_JOBS\" \] && MAX_JOBS=\"\$_JOBS\"" "$W"'
check "polish --jobs sets the count after flags" 'grep -q "\[ -n \"\$_JOBS\" \] && MAX_JOBS=\"\$_JOBS\"" "$P"'
out="$(sb work --jobs abc)" || true
check "work --jobs still validates"        '[[ "$out" == *"--jobs needs a number"* ]]'

# ── Banner and status ────────────────────────────────────────────────
echo "Banner + status"
banner() {
    (cd "$B" && env "$@" SPRINTBIAS_CLI=claude bash -c \
        'source docs/sprintbias/lib.sh; sprintbias_announce_provider --model opus' 2>&1 </dev/null)
}
echo "FAST=off" > "$LOCAL"
out="$(banner)"
check "banner shows fast: off"            '[[ "$out" == *"▸ Provider:"*"fast: off"* ]]'
out="$(banner SPRINTBIAS_FAST=on)"
check "banner shows fast: on"             '[[ "$out" == *"▸ Provider:"*"fast: on"* ]]'
out="$(sb status)"
check "status shows fast: off"            '[[ "$out" == *"fast: off"* ]]'
out="$(sb --fast status)"
check "status shows fast: on"             '[[ "$out" == *"fast: on"* ]]'

# ── Fast rules ride in every agent prompt ────────────────────────────
# sprintbias_fast_rules (lib.sh) prints the decide-and-move block when fast is
# on and nothing when off; chat, chat plan, crew (member + setup) and work
# (exec + emit) splice it in. Emit mode prints each prompt; work exec hands
# its prompt to a stub CLI that saves it.
echo "Fast rules"
FR="Fast mode adds reach:"
rules() { (cd "$B" && env SPRINTBIAS_FAST="$1" bash -c 'source docs/sprintbias/lib.sh; sprintbias_fast_rules'); }
out="$(rules on)"
check "rules: heading when on"            '[[ "$out" == "$FR"* ]]'
check "rules: subagents build missing pieces" '[[ "$out" == *"Start a subagent to build a missing piece"* ]]'
check "rules: cross-plan rule"            '[[ "$out" == *"read that plan"*"Goal first, serve both goals"* && "$out" == *"Touched by plan N: #id — what and why"* ]]'
# Deciding, recording and question form live in the finishing rule
# (sprintbias_assume_rule, every mode; docs/tests/test-finish-rule.sh), so the
# fast block carries none of it and nothing that waits or parks a question.
for gone in "Decided:" "goal-shaping item waits" "write the question into the task file" \
            "reversible call proceeds" "Commits, ship and deploys"; do
    check "rules: no \"$gone\" (finishing rule owns it)" '[[ "$out" != *"$gone"* ]]'
done
lines="$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
check "rules: short (<= 6 lines)"         '[ "$lines" -le 6 ]'
check "rules: empty when off"             '[ -z "$(rules off)" ]'

mkdir -p "$B/docs/plans" "$B/docs/crew" "$B/docs/tmp"
cp "$ROOT/docs/crew/.TEMPLATE-crew.md" "$B/docs/crew/"
printf '# Task 100: Thing\n\n**Plan**: 1\n\n## Problem\n\nX\n\n## Questions\n\n**Status: READY**\n' \
    > "$B/docs/tasks/backlog/100-thing.md"
printf '# Plan 1: P\n\n**Status:** DRAFT\n\n## Goal\n\nG\n\n## Member tasks\n\n- #100 — Thing\n' \
    > "$B/docs/plans/1-p.md"
(cd "$B" && git init -q)
rm -f "$LOCAL"
emit() {  # emit on|off ARGS… → the command's emitted prompt
    (cd "$B" && env -u CLAUDECODE -u CLAUDE_CODE_SESSION_ID -u AI_AGENT -u SPRINTBIAS_IN_AGENT \
        SPRINTBIAS_FAST="$1" SPRINTBIAS_MODE=emit SPRINTBIAS_CLI=claude ./sprint.sh "${@:2}" </dev/null 2>&1) || true
}
sb crew add dill "Finds and fixes bugs" >/dev/null
for cmd in "chat 100" "chat plan 1" "crew dill 100" "crew setup"; do
    # shellcheck disable=SC2086
    out="$(emit on $cmd)"
    check "$cmd: fast on carries the block"  '[[ "$out" == *"$FR"* ]]'
    # shellcheck disable=SC2086
    out="$(emit off $cmd)"
    check "$cmd: fast off omits it"          '[[ "$out" != *"$FR"* && -n "$out" ]]'
done
mv "$B/docs/tasks/backlog/100-thing.md" "$B/docs/tasks/next/"
for prov in claude-code other; do
    out="$(cd "$B" && SPRINTBIAS_FAST=on SPRINTBIAS_MODE=emit SPRINTBIAS_PROVIDER=$prov \
        bash docs/sprintbias/scripts/work.sh </dev/null 2>&1 || true)"
    check "work emit ($prov): fast on carries the block" '[[ "$out" == *"$FR"* ]]'
    out="$(cd "$B" && SPRINTBIAS_FAST=off SPRINTBIAS_MODE=emit SPRINTBIAS_PROVIDER=$prov \
        bash docs/sprintbias/scripts/work.sh </dev/null 2>&1 || true)"
    check "work emit ($prov): fast off omits it" '[[ "$out" != *"$FR"* && "$out" == *"Test loop:"* ]]'
done
cat > "$TMP/bin/work-stub" <<'STUB'
#!/usr/bin/env bash
while [ $# -gt 0 ]; do case "$1" in -p) printf '%s' "$2" > docs/tmp/prompt.txt; shift 2 ;; *) shift ;; esac; done
printf '{"type":"result","subtype":"success","num_turns":1,"duration_ms":1,"total_cost_usd":0}\n'
STUB
chmod +x "$TMP/bin/work-stub"
work_exec() {  # work_exec on|off → the prompt work's exec path handed the CLI
    rm -f "$B/docs/tmp/prompt.txt"
    for d in doing blocked review; do mv "$B/docs/tasks/$d/"*.md "$B/docs/tasks/next/" 2>/dev/null || true; done
    (cd "$B" && SPRINTBIAS_FAST="$1" SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$TMP/bin/work-stub" \
        bash docs/sprintbias/scripts/work.sh </dev/null >/dev/null 2>&1) || true
    cat "$B/docs/tmp/prompt.txt" 2>/dev/null || true
}
out="$(work_exec on)"
check "work exec: fast on carries the block" '[[ "$out" == *"$FR"* ]]'
out="$(work_exec off)"
check "work exec: fast off omits it"         '[[ "$out" != *"$FR"* && "$out" == *"Test loop:"* ]]'

# ── Crew holds and lanes (task 419) ──────────────────────────────────
# Fast lets a member take over a stalled hold and treats May touch as a
# routing preference; the lead builds and asks only goal questions. Steady
# keeps rules 2 and 3 and "Leave product code to the members" as they were.
echo "Crew holds and lanes"
sb crew add orcha "Holds the plan and routes tasks" --lead >/dev/null
TK="Takeover: #id from <holder> to dill"
out="$(emit on crew dill 100)"
check "member (on): message the holder first"  '[[ "$out" == *"message the holder first"* ]]'
check "member (on): agents shows no live session" '[[ "$out" == *"./sprint.sh agents shows no live session for the holder"* ]]'
check "member (on): set Crew to itself"        '[[ "$out" == *"set **Crew** to dill"* ]]'
check "member (on): one takeover line on the board" '[[ "$out" == *"one takeover line to the plan'"'"'s ## Crew board ($TK"* ]]'
check "member (on): May touch is a preference"  '[[ "$out" == *"May touch in your member file is your routing preference"* ]]'
check "member (on): Touching announcement stays" '[[ "$out" == *"**Touching:**"* ]]'
check "member (on): never revert others stays"  '[[ "$out" == *"stash, reset, checkout, or revert them"* ]]'
check "member (on): human ships (rule 6)"      '[[ "$out" == *"6. The human approves, commits and ships."* ]]'
check "member (on): no steady wall"            '[[ "$out" != *"Leave it alone and tell the lead"* && "$out" != *"Stay inside what your member file says"* ]]'
out="$(emit off crew dill 100)"
check "member (off): rule 2 unchanged"         '[[ "$out" == *"is theirs. Leave it alone and tell the lead if you need it."* ]]'
check "member (off): rule 3 unchanged"         '[[ "$out" == *"3. Stay inside what your member file says you may touch."* ]]'
check "member (off): no takeover text"         '[[ "$out" != *"Takeover"* && "$out" != *"routing preference"* ]]'
out="$(emit on crew orcha plan:1)"
check "lead (on): builds too"                  '[[ "$out" == *"you build too"* ]]'
check "lead (on): carries the fast rules"      '[[ "$out" == *"$FR"* && "$out" == *"ask the human only goal questions"* ]]'
check "lead (on): no one-at-a-time decisions"  '[[ "$out" != *"Raise decisions for the human one at a time"* && "$out" != *"Leave product code"* ]]'
check "lead (on): promote stays the human's"   '[[ "$out" == *"That approval is the human'"'"'s"* ]]'
out="$(emit off crew orcha plan:1)"
check "lead (off): lead bullet, finishing rule" '[[ "$out" == *"- Leave product code to the members. You plan, route, unblock and check landed work. Decide by the finishing rule above; ask the human only goal questions."* ]]'
check "lead (off): no one-at-a-time decisions" '[[ "$out" != *"Raise decisions for the human one at a time"* ]]'
check "lead (off): no takeover or build text"  '[[ "$out" != *"Takeover"* && "$out" != *"you build too"* ]]'

# ── Plan chat reach (task 418) ───────────────────────────────────────
# Every mode: newtask, task edits, reciprocal cross-plan deps, backlog/ ↔ next/,
# and the human-owned line. Fast adds Agent to --tools plus plan start / work /
# build-to-review; steady keeps the base toolset and building out of reach.
echo "Plan chat reach"
CP="$ROOT/docs/sprintbias/scripts/chat-plan.sh"
plan_tools() {  # plan_tools on|off → the toolset chat plan hands claude (--allowedTools)
    rm -f "$TMP/argv"
    (cd "$B" && env -u CLAUDECODE -u CLAUDE_CODE_SESSION_ID -u AI_AGENT -u SPRINTBIAS_IN_AGENT \
        -u GROK_AGENT PATH="$TMP/bin:$PATH" SPRINTBIAS_CLI=claude SPRINTBIAS_MODE=exec \
        SPRINTBIAS_FAST="$1" ./sprint.sh chat plan 1 </dev/null >/dev/null 2>&1) || true
    grep -A1 -x -- '--allowedTools' "$TMP/argv" 2>/dev/null | tail -1
}
for m in off on; do
    out="$(emit $m chat plan 1)"
    check "chat plan ($m): newtask allowed"       '[[ "$out" == *"Create a missing task with '"'"'./sprint.sh newtask"* ]]'
    check "chat plan ($m): edits member + other plans' tasks" '[[ "$out" == *"Edit task files — members and tasks of other plans"* ]]'
    check "chat plan ($m): cross-plan deps, both sides" '[[ "$out" == *"**Depends on** / **Dependents** across plans, always on both sides"* ]]'
    check "chat plan ($m): backlog/ ↔ next/ moves"  '[[ "$out" == *"Move tasks between backlog/ and next/"* ]]'
    check "chat plan ($m): human-owned line"        '[[ "$out" == *"Commit, push, ./ship.sh and moving tasks to done/ stay the human'"'"'s."* ]]'
done
out="$(emit on chat plan 1)"
check "chat plan (on): plan start + work allowed" '[[ "$out" == *"FAST MODE — build and start"* && "$out" == *"./sprint.sh plan start 1"* && "$out" == *"./sprint.sh work"* ]]'
check "chat plan (on): build to review/ with proof" '[[ "$out" == *"subagent (Agent tool)"* && "$out" == *"Land it in review/ with a proof line"* ]]'
out="$(emit off chat plan 1)"
check "chat plan (off): building stays fast-only" '[[ "$out" != *"FAST MODE — build and start"* && "$out" == *"is fast mode'"'"'s job"* ]]'
check "chat plan (on): tools add Agent"   '[ "$(plan_tools on)" = "Read,Edit,Write,Bash,Grep,Glob,Agent" ]'
check "chat plan (off): base toolset"     '[ "$(plan_tools off)" = "Read,Edit,Write,Bash,Grep,Glob" ]'
for gone in "Your ONLY durable write" "do not run it yourself" "you never move or edit task files" \
            "WRITES: only" "do not mv task files, do not edit task bodies" "Write only the plan file" \
            "(read-only over backlog/"; do
    check "chat-plan.sh: no \"$gone\"" '! grep -qF -- "$gone" "$CP"'
done

# ── Question format and the manual ───────────────────────────────────
echo "Docs"
CONV="$ROOT/docs/sprintbias/ai/conversation.md"
check "conversation.md: numbered options + (suggested)" 'grep -q "numbered list of options" "$CONV" && grep -q "(suggested)" "$CONV"'
check "DOCUMENTATION.md: Fast mode section"  'grep -q "^### Fast mode" "$ROOT/DOCUMENTATION.md"'
check "DOCUMENTATION.md: Decided: line"      'grep -q "Decided: X, because Y" "$ROOT/DOCUMENTATION.md"'

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
