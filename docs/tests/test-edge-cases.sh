#!/usr/bin/env bash
# Test: work finds and fixes edge cases a task never names (task 443).
#
#   1. One edge-cases fragment (sprintbias_edge_cases) appears once in the gate
#      contract, the work prompts (exec + both emit) and a crew member prompt.
#   2. The breaker runs by default after a task lands in exec and both emit
#      prompts; BREAK=off and work --no-break skip it. A breaker that cannot
#      fix removes **Proof**, so the task lands unproven.
#   3. promote --reject appends a ## Known edges line to the project map (none
#      without a map); orient points at it; profile check ignores its paths and
#      warns past 15 lines.
#
# Sandboxed with a stub CLI; no live AI. Discovered by run-all.sh.

set -euo pipefail

PASS=0
FAIL=0
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$REPO/docs/sprintbias"
# shellcheck source=/dev/null
source "$SRC/lib.sh"

ok()  { echo "  PASS: $1"; PASS=$((PASS + 1)); }
bad() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }
has()   { if grep -qF -- "$3" <<<"$2"; then ok "$1"; else bad "$1 (missing: $3)"; fi; }
lacks() { if grep -qF -- "$3" <<<"$2"; then bad "$1 (found: $3)"; else ok "$1"; fi; }
count_of() { grep -cF -- "$2" <<<"$1" || true; }
is() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi; }

FRAG_HEAD="$(sprintbias_edge_cases | head -1)"
FRAG_LAST="$(sprintbias_edge_cases | tail -1)"

SANDBOX=""
trap '[ -n "$SANDBOX" ] && rm -rf "$SANDBOX"' EXIT

# A sandbox project with the framework, one READY task 100 in next/, and a
# stub CLI. The stub appends every prompt to docs/tmp/prompts.log. As the
# worker it lands the task with a proof line (STUB_MOVE=1 also moves it to
# review/ itself, as a real worker does); as the breaker (STUB_BREAK):
#   fix (default) — adds a **Breaker** line
#   unfixed       — logs a failure and removes the **Proof** line
setup() {
    [ -n "$SANDBOX" ] && rm -rf "$SANDBOX"
    SANDBOX=$(mktemp -d)
    mkdir -p "$SANDBOX"/docs/tasks/{next,doing,review,blocked,backlog,done} "$SANDBOX/docs/tmp" "$SANDBOX/docs/plans"
    cp -R "$SRC" "$SANDBOX/docs/sprintbias"
    rm -f "$SANDBOX/docs/sprintbias/config.local" "$SANDBOX/docs/sprintbias/project.md"
    cp "$REPO/docs/tasks/.TEMPLATE-task.md" "$SANDBOX/docs/tasks/"
    printf '# Task 100: Import contacts\n\nDo the thing.\n\n## Done when (automated)\n\n- [ ] `bash t.sh`\n\n## Questions\n\n**Status: READY**\n' \
        > "$SANDBOX/docs/tasks/next/100-import.md"
    STUB="$SANDBOX/stub-cli"
    cat > "$STUB" <<'STUBEOF'
#!/usr/bin/env bash
prompt=""
while [ $# -gt 0 ]; do
  case "$1" in -p) prompt="$2"; shift 2 ;; *) shift ;; esac
done
printf '%s\n=====\n' "$prompt" >> docs/tmp/prompts.log
for f in docs/tasks/doing/*.md docs/tasks/review/*.md docs/tasks/done/*.md; do
  [ -f "$f" ] || continue
  case "$prompt" in
    *"You are the breaker"*)
      grep -qF "Task file: $f" <<<"$prompt" || continue
      [ "${STUB_BREAK:-fix}" = "crash" ] && exit 3
      if [ "${STUB_BREAK:-fix}" = "unfixed" ]; then
        grep -v '^\*\*Proof\*\*:' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
        printf '\n## Test log\n\n- bash t.sh — imports twice — duplicate rows\n' >> "$f"
      else
        printf '**Breaker**: 4 cases tried · 1 fixed · 0 filed\n' >> "$f"
      fi ;;
    *"Test loop:"*)
      case "$f" in docs/tasks/doing/*) ;; *) continue ;; esac
      printf '\n## Completed\n\n**Proof**: 2026-10-10 · bash t.sh · pass\n' >> "$f"
      if [ "${STUB_DECIDED:-0}" = "1" ]; then
        printf '\n## Notes\n\n- Decided: decimal hours (1.5h) stay out of scope, because they need a rounding rule; file a newtask if wanted.\n- Decided: duplicates on re-import are out of scope here; filed as task 2\n- Decided: trailing spaces are out of scope, because the parser trims; filed as #7\n' >> "$f"
      fi
      # STUB_MOVE=1: land like a real worker — move to review/ itself.
      [ "${STUB_MOVE:-0}" = "1" ] && mv "$f" docs/tasks/review/ ;;
  esac
done
printf '{"type":"result","subtype":"success","num_turns":1,"duration_ms":10,"total_cost_usd":%s}\n' "${STUB_COST:-0}"
STUBEOF
    chmod +x "$STUB"
}

run_exec() {
    (cd "$SANDBOX" && SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" NO_COLOR=1 \
        bash docs/sprintbias/scripts/work.sh "$@" 2>&1) || true
}
run_emit() {
    local provider="$1"; shift
    (cd "$SANDBOX" && SPRINTBIAS_MODE=emit SPRINTBIAS_PROVIDER="$provider" NO_COLOR=1 \
        bash docs/sprintbias/scripts/work.sh "$@" 2>&1) || true
}
prompts() { cat "$SANDBOX/docs/tmp/prompts.log" 2>/dev/null || true; }

echo "=== test-edge-cases.sh ==="

echo "Test 1: the edge-cases fragment appears once per prompt"
F="$(sprintbias_edge_cases)"
is  "fragment is at most 8 lines" "$(printf '%s\n' "$F" | wc -l | tr -d ' ')" "8"
has "names the example's class"   "$F" "the class its example stands for"
has "round trips"                 "$F" "what the real tools people use emit"
has "again and after"             "$F" "Again and after: run twice"
has "empty, one, many, malformed" "$F" "Empty, one, many, malformed."
has "neighbors"                   "$F" "Neighbors: other code that reads or writes the same data"
GC="$(cd "$REPO" && bash -c 'source docs/sprintbias/lib.sh; source docs/sprintbias/scripts/gate-lib.sh
    SPRINTBIAS_GATE_ORIENT=""; SPRINTBIAS_GATE_SPRINT_BLOCK=""; sprintbias_gate_contract T.md' 2>/dev/null)"
is  "gate: fragment once" "$(count_of "$GC" "$FRAG_HEAD")" "1"
has "gate: a check per listed case" "$GC" "A Done when line that lists cases names a check per case"
has "gate: other code path is filed" "$GC" "A gap you find in another code path: ./sprint.sh newtask"
R="$(sprintbias_proof_rule)"
has "proof rule: assertion per case"   "$R" "add one assertion per ## Done when case and per realistic"
has "proof rule: a known bug is fixed now" "$R" "Fix all bugs: each known bug, in any code it reaches"
has "proof rule: as deep as needed"   "$R" "as deep as a solid result"
has "proof rule: lists Edges found"   "$R" "### Edges found"
has "proof rule: Decided is not a parking lot" "$R" "Never park a known failure"
setup
run_exec >/dev/null
P="$(prompts | awk '/^=====$/{exit} {print}')"
has "exec worker prompt: test loop"    "$P" "Test loop:"
is  "exec worker prompt: fragment once" "$(count_of "$P" "$FRAG_HEAD")" "1"
setup
P="$(run_emit claude-code --no-break)"
is  "orchestrated emit (--no-break): fragment once" "$(count_of "$P" "$FRAG_HEAD")" "1"
P="$(run_emit generic --no-break)"
is  "sequential emit (--no-break): fragment once" "$(count_of "$P" "$FRAG_HEAD")" "1"
mkdir -p "$SANDBOX/docs/crew"
printf '# Crew member: dill\n\n**Role**: builder\n' > "$SANDBOX/docs/crew/dill.md"
P="$(cd "$SANDBOX" && SPRINTBIAS_MODE=emit bash docs/sprintbias/scripts/crew.sh dill 100 2>&1 || true)"
is  "crew member prompt: fragment once" "$(count_of "$P" "$FRAG_HEAD")" "1"

echo "Test 2: the breaker runs by default; BREAK=off and --no-break skip it"
setup
out="$(run_exec)"
P="$(prompts)"
is  "exec: worker then breaker (2 prompts)" "$(count_of "$P" "=====")" "2"
has "exec: breaker prompt sent" "$P" "You are the breaker"
has "exec: breaker prompt names the task" "$P" "Task file: docs/tasks/doing/100-import.md"
is  "exec: breaker prompt carries the fragment once" "$(prompts | awk '/You are the breaker/{f=1} f' | grep -cF -- "$FRAG_HEAD")" "1"
has "exec: says the breaker ran" "$out" "Breaker done — 4 cases tried · 1 fixed · 0 filed"
has "exec: lands in review/" "$(ls "$SANDBOX/docs/tasks/review/")" "100-import.md"
lacks "exec: proven task has no unproven note" "$out" "No **Proof**: line"
setup
out="$(cd "$SANDBOX" && SPRINTBIAS_BREAK=off SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" NO_COLOR=1 \
    bash docs/sprintbias/scripts/work.sh 2>&1 || true)"
is  "BREAK=off (env): only the worker runs" "$(count_of "$(prompts)" "=====")" "1"
setup
sed -i.bak 's/^BREAK=on$/BREAK=off/' "$SANDBOX/docs/sprintbias/config" && rm -f "$SANDBOX/docs/sprintbias/config.bak"
run_exec >/dev/null
is  "BREAK=off (config): only the worker runs" "$(count_of "$(prompts)" "=====")" "1"
setup
out="$(run_exec --no-break)"
is  "--no-break: only the worker runs" "$(count_of "$(prompts)" "=====")" "1"
lacks "--no-break: no breaker line" "$out" "Breaker"
setup
out="$(cd "$SANDBOX" && STUB_BREAK=unfixed SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" NO_COLOR=1 \
    bash docs/sprintbias/scripts/work.sh 2>&1 || true)"
has "unfixed failure: lands in review/" "$(ls "$SANDBOX/docs/tasks/review/")" "100-import.md"
has "unfixed failure: lands unproven" "$out" "No **Proof**: line"
has "unfixed failure: Test log kept" "$(cat "$SANDBOX/docs/tasks/review/100-import.md")" "imports twice"
echo "Test 2b: a worker that moves its task to review/ itself still gets the breaker and --audit"
setup
out="$(cd "$SANDBOX" && STUB_MOVE=1 SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" NO_COLOR=1 \
    bash docs/sprintbias/scripts/work.sh 2>&1 || true)"
has "self-landed: breaker prompt sent for review/ path" "$(prompts)" "Task file: docs/tasks/review/100-import.md"
has "self-landed: says the breaker ran" "$out" "Breaker done — 4 cases tried"
has "self-landed: Breaker line in the task" "$(cat "$SANDBOX/docs/tasks/review/100-import.md")" "**Breaker**: 4 cases tried"
has "self-landed: counted complete" "$out" "moved there during the run"
setup
out="$(cd "$SANDBOX" && STUB_MOVE=1 STUB_BREAK=unfixed SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" NO_COLOR=1 \
    bash docs/sprintbias/scripts/work.sh 2>&1 || true)"
has "self-landed, unfixed: reported unproven" "$out" "No **Proof**: line"
setup
out="$(cd "$SANDBOX" && STUB_MOVE=1 SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" NO_COLOR=1 \
    bash docs/sprintbias/scripts/work.sh --audit --no-break 2>&1 || true)"
has "self-landed: --audit runs" "$out" "Running code audit"
setup
out="$(run_exec --audit --no-break)"
has "doing/ path: --audit runs" "$out" "Running code audit"

echo "Test 2c: an out-of-scope call with no filed task is listed as an unfiled gap"
setup
out="$(cd "$SANDBOX" && STUB_DECIDED=1 SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" NO_COLOR=1 \
    bash docs/sprintbias/scripts/work.sh --no-break 2>&1 || true)"
has   "unfiled gap listed with its newtask" "$out" 'Unfiled gap: decimal hours (1.5h) stay out of scope → ./sprint.sh newtask "decimal hours (1.5h) stay out of scope"'
is    "only the unfiled one is listed" "$(count_of "$out" "Unfiled gap:")" "1"
lacks "filed as task N is not a gap" "$out" "Unfiled gap: duplicates"
lacks "filed as #N is not a gap" "$out" "Unfiled gap: trailing"
setup
P="$(run_emit generic --no-break)"
has   "emit report spec lists unfiled gaps" "$P" "Unfiled gap: <the gap>"

setup
P="$(run_emit claude-code)"
has "orchestrated emit: breaker step" "$P" "launch one more
   FRESH subagent"
has "orchestrated emit: breaker fires on a worker-moved task" "$P" "already moved
   to review/ by the worker"
has "orchestrated emit: breaker instruction" "$P" "You are the breaker"
is  "orchestrated emit: fragment in worker + breaker" "$(count_of "$P" "$FRAG_HEAD")" "2"
P="$(run_emit generic)"
has "sequential emit: breaker step" "$P" "reset your focus and act as a"
has "sequential emit: breaker instruction" "$P" "You are the breaker"
P="$(run_emit claude-code --no-break)"
lacks "orchestrated emit --no-break: no breaker" "$P" "You are the breaker"
P="$(cd "$SANDBOX" && SPRINTBIAS_BREAK=off SPRINTBIAS_MODE=emit SPRINTBIAS_PROVIDER=generic NO_COLOR=1 \
    bash docs/sprintbias/scripts/work.sh 2>&1 || true)"
lacks "sequential emit BREAK=off: no breaker" "$P" "You are the breaker"

echo "Test 3: promote --reject records a Known edge; profile check handles it"
setup
printf '# Task 200: Import contacts\n\n**Tests**: none\n\n## Completed\n\n**Proof**: 2026-10-10 · bash t.sh · pass\n' \
    > "$SANDBOX/docs/tasks/review/200-import.md"
printf '# Task 201: Export\n\n**Tests**: none\n\n## Completed\n' > "$SANDBOX/docs/tasks/review/201-export.md"
printf '# State\n**sprint_TASK_ID**: 300\n**Last Updated**: 2026-01-01\n' > "$SANDBOX/docs/sprintbias/DOC_STATE.md"
out="$(cd "$SANDBOX" && bash docs/sprintbias/scripts/promote.sh --reject 201 "Exports drop the last row" 2>&1 || true)"
has   "no map: fix task still filed" "$out" "Next: shape and run the fix"
is    "no map: none created" "$([ -f "$SANDBOX/docs/sprintbias/project.md" ] && echo yes || echo no)" "no"
printf '# Project Profile\n\n## Code\n**Structure:** `docs/` docs\n\n**Checked:** 2026-10-10\n' > "$SANDBOX/docs/sprintbias/project.md"
O="$(cd "$SANDBOX" && bash -c 'source docs/sprintbias/lib.sh; sprintbias_orient')"
lacks "orient: no Known edges sentence without the section" "$O" "Known edges"
out="$(cd "$SANDBOX" && bash docs/sprintbias/scripts/promote.sh --reject 200 "Re-import: the same file imported twice duplicates contacts" 2>&1 || true)"
has   "reject says it added a Known edge" "$out" "Added to ## Known edges"
MAP="$(cat "$SANDBOX/docs/sprintbias/project.md")"
has   "map has the section" "$MAP" "## Known edges"
has   "map line carries the case and the task" "$MAP" "- Re-import: the same file imported twice duplicates contacts (#200)"
O="$(cd "$SANDBOX" && bash -c 'source docs/sprintbias/lib.sh; sprintbias_orient')"
has   "orient: points at Known edges" "$O" "Its ## Known edges lists cases that broke before"
printf -- '- `missing/path.sh` broke on empty input (#9)\n' >> "$SANDBOX/docs/sprintbias/project.md"
out="$(cd "$SANDBOX" && bash -c 'source docs/sprintbias/lib.sh; sprintbias_profile_check' 2>&1 || true)"
lacks "profile check: Known edges paths are not tracked" "$out" "missing/path.sh"
for i in $(seq 1 15); do printf -- '- case %s (#%s)\n' "$i" "$i" >> "$SANDBOX/docs/sprintbias/project.md"; done
out="$(cd "$SANDBOX" && bash -c 'source docs/sprintbias/lib.sh; sprintbias_profile_check' 2>&1 || true)"
has   "profile check: warns past 15 lines" "$out" "17 ## Known edges lines (keep ~15)"
has   "profile format documents the section" "$(cat "$SRC/scripts/profile.sh")" "## Known edges"

echo "Test 4: the breaker rule starts from real use, re-decides, names filed tasks"
BR="$(sprintbias_break_rule T.md)"
has "breaker: real use first"        "$BR" "Start from real use: the commands and inputs as people type or paste them"
has "breaker: extremes after"        "$BR" "Reach for extremes after"
has "breaker: re-decides a bad call" "$BR" "When a - Decided: line caused it,"
has "breaker: replaces the Decided line" "$BR" "replace that line (say what"
has "breaker: failing test names its task" "$BR" "A test left failing names its filed task"
has "breaker: fixes neighboring code too" "$BR" "A defect in a neighboring code path is fixed too"
has "breaker: lists Edges found"     "$BR" "### Edges found"

# sign-off lifts each task's ### Edges found into the map's ## Known edges, once
LE="$(mktemp -d)"
printf '# Project map\n\n## Code\n\n- src/\n' > "$LE/project.md"
printf '# Task 77: Parse\n\n## Completed\n\n### Edges found\n- quoting: a path with a space\n- empty: a blank CSV row\n\n### Files changed\nsrc/a.sh\n' > "$LE/77-parse.md"
SPRINTBIAS_PROJECT_MAP="$LE/project.md" sprintbias_lift_edges "$LE/77-parse.md" >/dev/null
SPRINTBIAS_PROJECT_MAP="$LE/project.md" sprintbias_lift_edges "$LE/77-parse.md" >/dev/null
has "lift edges: case added with its id" "$(cat "$LE/project.md")" "- quoting: a path with a space (#77)"
is  "lift edges: each case once across runs" "$(grep -c 'blank CSV row' "$LE/project.md")" "1"
lacks "lift edges: Files changed not lifted" "$(cat "$LE/project.md")" "src/a.sh (#77)"
rm -rf "$LE"

echo "Test 5: polish --break runs the breaker alone on landed work"
setup
rm -f "$SANDBOX/docs/tasks/next/100-import.md"
printf '# Task 300: Parse input\n\n## Completed\n\n**Proof**: 2026-10-10 · bash t.sh · pass\n' > "$SANDBOX/docs/tasks/review/300-parse.md"
printf '# Task 301: Save input\n\n## Completed\n\n**Proof**: 2026-10-10 · bash t.sh · pass\n' > "$SANDBOX/docs/tasks/done/301-save.md"
printf '# Task 302: Human test\n\n**Owner**: human\n' > "$SANDBOX/docs/tasks/review/302-human-test.md"
printf '# Task 303: Later\n\n**Status: READY**\n' > "$SANDBOX/docs/tasks/next/303-later.md"
printf '# Plan 9: Input\n\n## Member tasks\n\n- #300 — parse\n- #301 — save\n- #302 — human test\n- #303 — later\n' > "$SANDBOX/docs/plans/9-input.md"
pol() { (cd "$SANDBOX" && SPRINTBIAS_MODE="${M:-exec}" SPRINTBIAS_CLI="$STUB" NO_COLOR=1 \
    bash docs/sprintbias/scripts/polish.sh --break "$@" 2>&1); }
out="$(pol 300 || true)"
has "single id: breaker prompt for the task" "$(prompts)" "Task file: docs/tasks/review/300-parse.md"
has "single id: prints the Breaker line" "$out" "#300  **Breaker**: 4 cases tried"
has "single id: summary and next command" "$out" "▸ Breaker: 1 task(s) checked · 0 lost its proof — next: ./sprint.sh promote 300"
lacks "single id: no worker prompt" "$(prompts)" "Test loop:"
: > "$SANDBOX/docs/tmp/prompts.log"
out="$(pol plan:9 || true)"
is  "plan: only the unchecked member is broken (#300 already has a Breaker line)" "$(count_of "$(prompts)" "You are the breaker")" "1"
has "plan: done/ member included" "$(prompts)" "Task file: docs/tasks/done/301-save.md"
has "plan: prints each checked member's line" "$out" "#301  **Breaker**: 4 cases tried"
: > "$SANDBOX/docs/tmp/prompts.log"
out="$(pol plan:9 || true)"
is  "plan: every member checked — no run" "$(prompts)" ""
has "plan: names the single-task re-run" "$out" "Re-run one:  ./sprint.sh polish --break <id>"
lacks "plan: human test skipped" "$(prompts)" "302-human-test.md"
lacks "plan: unlanded member skipped" "$(prompts)" "303-later.md"
has "plan: next is plan check, then promote plan:N" "$out" "next: ./sprint.sh plan check 9   # then sign off: ./sprint.sh promote plan:9"
out="$(cd "$SANDBOX" && STUB_BREAK=unfixed SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" NO_COLOR=1 \
    bash docs/sprintbias/scripts/polish.sh --break 300 2>&1 || true)"
has "unfixed: counts the lost proof" "$out" "1 lost its proof"
rc=0; out="$(pol 303)" || rc=$?
is  "unlanded task: exits 1" "$rc" "1"
has "unlanded task: says land it first" "$out" "has not landed"
: > "$SANDBOX/docs/tmp/prompts.log"
out="$(M=emit pol plan:9 || true)"
has "emit: breaker rule" "$out" "You are the breaker"
has "emit: lists landed members" "$out" "- docs/tasks/done/301-save.md"
lacks "emit: no human test" "$out" "302-human-test.md"
is  "emit: no CLI run" "$(prompts)" ""

echo "Test 6: promote runs the breaker before sign-off"
setup
rm -f "$SANDBOX/docs/tasks/next/100-import.md"
mkdir -p "$SANDBOX/docs/tests"
printf '#!/usr/bin/env bash\nexit 0\n' > "$SANDBOX/docs/tests/t.sh"
landed() {  # landed ID SLUG [EXTRA-LINE]
    printf '# Task %s: %s\n\n**Tests**: docs/tests/t.sh\n**Depends on**: none\n\n## Completed\n\n**Proof**: 2026-10-10 · bash docs/tests/t.sh · pass\n%s' \
        "$1" "$2" "${3:-}" > "$SANDBOX/docs/tasks/review/$1-$2.md"
}
prom() { (cd "$SANDBOX" && SPRINTBIAS_MODE="${M:-exec}" SPRINTBIAS_CLI="$STUB" NO_COLOR=1 \
    bash docs/sprintbias/scripts/promote.sh "$@" 2>&1 </dev/null); }
landed 400 parse
out="$(prom --dry-run 400 || true)"
has "dry-run: lists the check" "$out" "#400  would be checked"
is  "dry-run: no AI" "$(prompts)" ""
out="$(prom 400 || true)"
has "checks before sign-off" "$out" "▸ Checking 1 task(s) before sign-off (breaker)…"
has "prints the task's Breaker line" "$out" "#400  **Breaker**: 4 cases tried"
has "then signs it off" "$(ls "$SANDBOX/docs/tasks/done/")" "400-parse.md"
: > "$SANDBOX/docs/tmp/prompts.log"
landed 401 save "**Breaker**: 3 cases tried · 0 fixed · 0 filed
"
out="$(prom 401 || true)"
is  "a Breaker line already: not re-run" "$(prompts)" ""
has "…and signed off" "$(ls "$SANDBOX/docs/tasks/done/")" "401-save.md"
landed 402 load
out="$(cd "$SANDBOX" && STUB_BREAK=unfixed SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" NO_COLOR=1 \
    bash docs/sprintbias/scripts/promote.sh 402 2>&1 </dev/null)" && rc=0 || rc=$?
is  "lost proof: exits 1" "$rc" "1"
has "lost proof: says why and what to run" "$out" "the breaker found a failure it could not fix"
has "lost proof: next command" "$out" "./sprint.sh work 402"
has "lost proof: stays in review/" "$(ls "$SANDBOX/docs/tasks/review/")" "402-load.md"
landed 403 crash
out="$(cd "$SANDBOX" && STUB_BREAK=crash SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" NO_COLOR=1 \
    bash docs/sprintbias/scripts/promote.sh 403 2>&1 </dev/null || true)"
has "crash: warns, checked not run" "$out" "breaker did not finish — checked, not run"
has "crash: never blocks sign-off" "$(ls "$SANDBOX/docs/tasks/done/")" "403-crash.md"
has "crash: stamped so it is not re-run" "$(cat "$SANDBOX/docs/tasks/done/403-crash.md")" "**Breaker**: not run"
: > "$SANDBOX/docs/tmp/prompts.log"
landed 404 off
out="$(cd "$SANDBOX" && SPRINTBIAS_BREAK=off SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" bash docs/sprintbias/scripts/promote.sh 404 2>&1 </dev/null || true)"
is  "BREAK=off: no breaker" "$(prompts)" ""
landed 405 nobreak
out="$(prom --no-break 405 || true)"
is  "--no-break: no breaker" "$(prompts)" ""
has "--no-break: signed off" "$(ls "$SANDBOX/docs/tasks/done/")" "405-nobreak.md"
landed 406 emit
out="$(M=emit prom 406 || true)"
has "emit: names the polish --break command" "$out" "./sprint.sh polish --break 406"
has "emit: nothing moved" "$(ls "$SANDBOX/docs/tasks/review/")" "406-emit.md"
rm -f "$SANDBOX"/docs/tasks/review/*.md; : > "$SANDBOX/docs/tmp/prompts.log"
landed 407 two-a; landed 408 two-b
out="$(prom --jobs 2 || true)"
is  "batch: both checked in one run" "$(count_of "$(prompts)" "You are the breaker")" "2"
has "batch: both signed off" "$(ls "$SANDBOX/docs/tasks/done/")" "408-two-b.md"

echo "Test 7: promote plan:N checks members, skips the human test"
setup
rm -f "$SANDBOX/docs/tasks/next/100-import.md"
mkdir -p "$SANDBOX/docs/tests"; printf '#!/usr/bin/env bash\nexit 0\n' > "$SANDBOX/docs/tests/t.sh"
landed 420 member
printf '# Task 421: Human test for plan 12\n\n**Owner**: human\n**Plan**: 12\n\n## Signoff (human)\n\n- [ ] try it\n' > "$SANDBOX/docs/tasks/review/421-human-test.md"
printf '# Plan 12: Input\n\n**Status:** STARTED\n\n## Member tasks\n\n- #420 — member\n- #421 — human test\n' > "$SANDBOX/docs/plans/12-input.md"
printf '\n## Results\n\n<!-- sb:hint\n       - fail: an example inside a comment\n     -->\n' >> "$SANDBOX/docs/tasks/review/421-human-test.md"
out="$(prom plan:12 --dry-run || true)"
has "plan dry-run: lists the check" "$out" "#420  would be checked"
has "plan dry-run: ends with the sign-off command" "$out" "(dry-run) Nothing ran and nothing moved. Sign off:  ./sprint.sh promote plan:12"
is  "plan dry-run: no AI" "$(prompts)" ""
has "plan dry-run: nothing moved" "$(ls "$SANDBOX/docs/tasks/review/")" "420-member.md"
printf -- '- fail: the export button does nothing\n' >> "$SANDBOX/docs/tasks/review/421-human-test.md"
out="$(prom plan:12 --dry-run || true)"
has "plan dry-run: counts real failures only" "$out" "(dry-run) 1 failure(s) under ## Results"
lacks "plan dry-run: files no fix task" "$(ls "$SANDBOX/docs/tasks/backlog/" "$SANDBOX/docs/tasks/next/" 2>/dev/null)" "fix"
sed -i.bak '/^- fail: the export button/d' "$SANDBOX/docs/tasks/review/421-human-test.md" && rm -f "$SANDBOX/docs/tasks/review/421-human-test.md.bak"
out="$(prom plan:12 || true)"
has "plan: member checked" "$out" "#420  **Breaker**: 4 cases tried"
lacks "plan: human test not checked" "$(prompts)" "421-human-test.md"
has "plan: goes on to the approval" "$out" "Approve plan 12"

echo "Test 8: one plan-target reader (plan N, plan:N, bare plan id, both-exist hint)"
setup
printf '# Plan 31: Input\n\n## Member tasks\n\n- #100 — import\n' > "$SANDBOX/docs/plans/31-input.md"
printf '# Plan 100: Same number\n\n## Member tasks\n\n- #100 — import\n' > "$SANDBOX/docs/plans/100-same.md"
w() { (cd "$SANDBOX" && SPRINTBIAS_MODE=emit SPRINTBIAS_PROVIDER=generic NO_COLOR=1 bash docs/sprintbias/scripts/work.sh "$@" 2>&1 || true); }
has "work plan 31: plan's member queued" "$(w plan 31 --no-break)" "docs/tasks/next/100-import.md"
has "work plan:31: plan's member queued" "$(w plan:31 --no-break)" "docs/tasks/next/100-import.md"
out="$(w 31 --no-break)"
has "work 31 (no task): uses the plan" "$out" "▸ No task 31 — using plan 31."
has "…and queues its member" "$out" "docs/tasks/next/100-import.md"
has "work 100 (both): hint" "$(w 100 --no-break)" "(plan 100 also exists: plan 100)"
has "promote plan 31: plan mode" "$(prom plan 31 || true)" "promote plan:31"
out="$(prom 31 || true)"
has "promote 31 (no task): uses the plan" "$out" "▸ No task 31 — using plan 31."
has "…in plan mode" "$out" "promote plan:31"
has "promote 100 (both): hint" "$(prom 100 || true)" "(plan 100 also exists: plan 100)"
has "polish --break plan 31: plan target" "$(pol plan 31 || true)" "Plan 31 has no landed members"
has "polish --break 31 (no task): uses the plan" "$(pol 31 || true)" "▸ No task 31 — using plan 31."
mkdir -p "$SANDBOX/docs/crew"; printf '# Crew member: lea\n\n**Role**: lead\n' > "$SANDBOX/docs/crew/lea.md"
has "crew plan 31: plan target" "$(cd "$SANDBOX" && SPRINTBIAS_MODE=emit bash docs/sprintbias/scripts/crew.sh lea plan 31 2>&1 || true)" "Your work is plan 31"
has "crew 31 (no task): uses the plan" "$(cd "$SANDBOX" && SPRINTBIAS_MODE=emit bash docs/sprintbias/scripts/crew.sh lea 31 2>&1 || true)" "▸ No task 31 — using plan 31."
has "polish sweep limit untouched (no --break)" "$(cd "$SANDBOX" && SPRINTBIAS_MODE=emit bash docs/sprintbias/scripts/polish.sh 31 2>&1 || true)" "No tasks"

echo "Test 9: breaker caps from config, cost on the Breaker line, status --edges"
setup
rm -f "$SANDBOX/docs/tasks/next/100-import.md"
printf 'BREAK_MAX_TURNS=40\nBREAK_TIMEOUT=1200\nBUDGET_BREAK=5.00\n' > "$SANDBOX/docs/sprintbias/config.local"
caps="$(cd "$SANDBOX" && env -u SPRINTBIAS_BREAK_MAX_TURNS -u SPRINTBIAS_BREAK_TIMEOUT -u SPRINTBIAS_BUDGET_BREAK \
    bash -c 'source docs/sprintbias/lib.sh; echo "$SPRINTBIAS_BREAK_MAX_TURNS $SPRINTBIAS_BREAK_TIMEOUT $SPRINTBIAS_BUDGET_BREAK"')"
is  "config.local raises the breaker caps" "$caps" "40 1200 5.00"
rm -f "$SANDBOX/docs/sprintbias/config.local"
caps="$(cd "$SANDBOX" && env -u SPRINTBIAS_BREAK_MAX_TURNS -u SPRINTBIAS_BREAK_TIMEOUT \
    bash -c 'source docs/sprintbias/lib.sh; echo "$SPRINTBIAS_BREAK_MAX_TURNS $SPRINTBIAS_BREAK_TIMEOUT"')"
is  "defaults: 25 turns, 900 seconds" "$caps" "25 900"
printf '# Task 300: Parse input\n\n**Plan**: 9\n\n## Completed\n\n**Proof**: 2026-10-10 · bash t.sh · pass\n' > "$SANDBOX/docs/tasks/review/300-parse.md"
(cd "$SANDBOX" && STUB_COST=1.234 SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" NO_COLOR=1 \
    bash docs/sprintbias/scripts/polish.sh --break 300 >/dev/null 2>&1) || true
is  "cost stamped on the Breaker line" "$(sprintbias_break_line "$SANDBOX/docs/tasks/review/300-parse.md")" '4 cases tried · 1 fixed · 0 filed · $1.23'
printf '# Task 307: Free run\n\n## Completed\n\n**Proof**: 2026-10-10 · bash t.sh · pass\n' > "$SANDBOX/docs/tasks/review/307-free.md"
(cd "$SANDBOX" && SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" NO_COLOR=1 \
    bash docs/sprintbias/scripts/polish.sh --break 307 >/dev/null 2>&1) || true
is  "no cost reported: line left as written" "$(sprintbias_break_line "$SANDBOX/docs/tasks/review/307-free.md")" '4 cases tried · 1 fixed · 0 filed'
rm -f "$SANDBOX/docs/tasks/review/307-free.md"
# The board: #300 breaker-checked (plan 9), #301 unchecked, #303 breaker not run,
# #302 plan 9's human test. Fix tasks: #304 rejects #300, #305 rejects #301,
# #306 a human-test failure (plan 9 is checked).
printf '# Task 300: Parse input\n\n**Plan**: 9\n\n## Completed\n\n**Proof**: 2026-10-10 · bash t.sh · pass\n**Breaker**: 10 cases tried · 3 fixed · 1 filed — trims input · $2.00\n' > "$SANDBOX/docs/tasks/review/300-parse.md"
printf '# Task 301: Save input\n\n**Plan**: none\n' > "$SANDBOX/docs/tasks/done/301-save.md"
printf '# Task 302: Human test\n\n**Owner**: human\n**Plan**: 9\n' > "$SANDBOX/docs/tasks/review/302-human-test.md"
printf '# Task 303: Load input\n\n**Breaker**: not run (crashed or timed out, 2026-10-11) — re-run: ./sprint.sh polish --break 303\n' > "$SANDBOX/docs/tasks/done/303-load.md"
printf '# Task 304: Fix #300: Parse input\n\n**Fixes**: #300\n**Plan**: 9\n' > "$SANDBOX/docs/tasks/backlog/304-fix.md"
printf '# Task 305: Fix #301: Save input\n\n**Fixes**: #301\n' > "$SANDBOX/docs/tasks/backlog/305-fix.md"
printf '# Task 306: Fix #302: empty file crashes\n\n**Fixes**: #302\n**Plan**: 9\n' > "$SANDBOX/docs/tasks/next/306-fix.md"
edges() { (cd "$SANDBOX" && NO_COLOR=1 bash docs/sprintbias/scripts/edges.sh "$@" 2>&1); }
out="$(edges || true)"
has "landed split: 1 checked, 2 unchecked (not run counts unchecked)" "$out" "Tasks landed (review/ + done/)              1   2"
has "escapes split: 2 past the breaker, 1 without" "$out" "Found by you (escaped)                      2   1"
has "reject escapes" "$out" "via promote --reject                      1   1"
has "human-test escapes count for a checked plan" "$out" "via a human test                          1   0"
has "breaker totals" "$out" "Breaker on 1 task(s): 10 cases tried · 3 fixed · 1 filed"
has "catch rate counts fixed + filed" "$out" "Catch rate: 67% — agents found 4, you found 2"
has "cost and cost per defect" "$out" 'Breaker cost: $2.00 over 1 run(s) · $0.50 per defect caught'
has "not-run count with the re-run command" "$out" "Breaker not run (crash or timeout): 1"
has "lists the escape from a reject" "$out" "#304 (rejected #300, backlog)"
has "lists the escape from a human test" "$out" "#306 (human test #302, next)"
lacks "an unchecked escape is not in the learn list" "$out" "#305 ("
has "no map: points at profile" "$out" "./sprint.sh profile"
out="$(edges plan:9 || true)"
has "plan scope" "$out" "Scope: plan 9"
has "plan scope drops other tasks" "$out" "Tasks landed (review/ + done/)              1   0"
printf '# Project map\n\n## Known edges\n\n- #300: empty file crashes\n- #301: BOM header\n\n## Commands\n\n- x\n' > "$SANDBOX/docs/sprintbias/project.md"
has "counts known edges in the map" "$(edges || true)" "Known edges in docs/sprintbias/project.md: 2"
rc=0; edges plan:x >/dev/null || rc=$?
is  "bad plan id: exits 2" "$rc" "2"
has "status --edges dispatches to the scorecard" "$(cd "$SANDBOX" && cp "$REPO/sprint.sh" . && NO_COLOR=1 bash sprint.sh status --edges 2>&1 || true)" "=== Edge cases: caught by agents vs found by you ==="

echo "Test 10: parallel breakers never share a code file (lanes)"
L="$(mktemp -d)"
printf '# Task 1\n\n## Completed\n\n### Files changed\n- api/import.py\n- docs/guide.md\n\nTests run: `pytest api/shared.py`\n' > "$L/1.md"
printf '# Task 2\n\n## Completed\n\n### Files changed\n- `api/import.py` (edited)\n- web/page.tsx\n' > "$L/2.md"
printf '# Task 3\n\n## Completed\n\n### Files changed\n- docs/guide.md\n- web/other.tsx\n' > "$L/3.md"
printf '# Task 4\n\n## Completed\n\n### Files changed\n- api/shared.py\n' > "$L/4.md"
printf '# Task 5\n\nNo list.\n' > "$L/5.md"
printf '# Task 6\n\nNo list either.\n' > "$L/6.md"
printf '# Task 7\n\n## Completed\n\n### Files changed\n- web/page.tsx\n' > "$L/7.md"
lanes="$(sprintbias_break_lanes "$L"/{1,2,3,4,5,6,7}.md)"
is  "shared code file chains 1, 2 and 7 (longest lane first)" "$(sed -n 1p <<<"$lanes")" "0 1 6"
is  "tasks with no list share one lane" "$(grep -cx '4 5' <<<"$lanes")" "1"
is  "a shared .md file alone does not join a lane" "$(grep -cx '2' <<<"$lanes")" "1"
lacks "a path in prose after the list does not join a lane" "$lanes" "0 1 3"
is  "seven tasks make 4 lanes" "$(wc -l <<<"$lanes" | tr -d ' ')" "4"
# Bare path lines (the common form) count the same as list items.
printf '# Task 8\n\n## Completed\n\n### Files changed\ndocs/sprintbias/lib.sh\nsprint.sh\n' > "$L/8.md"
printf '# Task 9\n\n## Completed\n\n### Files changed\n- docs/sprintbias/help/_registry\n- `sprint.sh`\n' > "$L/9.md"
printf '# Task 10\n\n## Completed\n\n### Files changed\ndocs/sprintbias/help/_registry\n' > "$L/10.md"
is  "bare path lines join a lane, extensionless paths too" "$(sprintbias_break_lanes "$L"/{8,9,10}.md)" "0 1 2"
rm -rf "$L"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
