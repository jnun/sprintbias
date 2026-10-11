#!/usr/bin/env bash
# Test: crew.sh
# Covers crew add, list (with held tasks), name checks, and the prompt a
# member and a lead start with (emit mode, so no AI CLI runs).

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_UNDER_TEST="$(cd "$(dirname "$0")/../sprintbias/scripts" && pwd)/crew.sh"
SPRINTBIAS_SRC="$(cd "$(dirname "$0")/../sprintbias" && pwd)"
DOCS_SRC="$(cd "$(dirname "$0")/.." && pwd)"

setup() {
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    mkdir -p "$TMPDIR/docs/sprintbias/scripts" "$TMPDIR/docs/crew" "$TMPDIR/docs/plans"
    for s in backlog next doing blocked review "done"; do mkdir -p "$TMPDIR/docs/tasks/$s"; done

    cp "$SCRIPT_UNDER_TEST" "$TMPDIR/docs/sprintbias/scripts/crew.sh"
    cp "$SPRINTBIAS_SRC/lib.sh" "$TMPDIR/docs/sprintbias/lib.sh"
    cp -R "$SPRINTBIAS_SRC/cli" "$TMPDIR/docs/sprintbias/cli"
    mkdir -p "$TMPDIR/docs/sprintbias/ai"
    cp "$SPRINTBIAS_SRC/ai/crew-setup.md" "$TMPDIR/docs/sprintbias/ai/crew-setup.md"
    cp "$DOCS_SRC/crew/.TEMPLATE-crew.md" "$TMPDIR/docs/crew/.TEMPLATE-crew.md"
    printf '**sprint_TASK_ID**: 0\n' > "$TMPDIR/docs/sprintbias/DOC_STATE.md"

    git -C "$TMPDIR" init -q
}

crew() { (cd "$TMPDIR" && SPRINTBIAS_MODE=emit bash docs/sprintbias/scripts/crew.sh "$@" 2>&1); }

assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if grep -qF -- "$needle" <<<"$haystack"; then
        echo "  PASS: $desc"; PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected to contain '$needle')"; FAIL=$((FAIL + 1))
    fi
}

assert_not_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if grep -qF -- "$needle" <<<"$haystack"; then
        echo "  FAIL: $desc (did not expect '$needle')"; FAIL=$((FAIL + 1))
    else
        echo "  PASS: $desc"; PASS=$((PASS + 1))
    fi
}

assert_fails() {
    local desc="$1"; shift
    if crew "$@" >/dev/null; then
        echo "  FAIL: $desc (expected non-zero exit)"; FAIL=$((FAIL + 1))
    else
        echo "  PASS: $desc"; PASS=$((PASS + 1))
    fi
}

echo "=== test-crew.sh ==="
setup

echo "Test 1: empty crew explains how to start"
out="$(crew)"
assert_contains "Empty list hints at crew add" "$out" "crew add lead"

echo "Test 2: add writes name, role and lead flag"
crew add orcha "Keeps everyone rowing & routes tasks / plans" --lead >/dev/null
crew add dill "Finds and fixes bugs" >/dev/null
f="$TMPDIR/docs/crew/orcha.md"
assert_contains "Title uses the display name" "$(cat "$f")" "# Crew: Orcha"
assert_contains "Role keeps & and / literally" "$(cat "$f")" "**Role**: Keeps everyone rowing & routes tasks / plans"
assert_contains "Lead flag set" "$(cat "$f")" "**Lead**: yes"
assert_contains "Non-lead flag" "$(cat "$TMPDIR/docs/crew/dill.md")" "**Lead**: no"

echo "Test 2b: the lead's file arrives filled in; a member's keeps its prompts"
lf="$(cat "$TMPDIR/docs/crew/orcha.md")"; mf="$(cat "$TMPDIR/docs/crew/dill.md")"
assert_contains "Lead Job filled" "$lf" "Keeps the crew rowing in time"
assert_contains "Lead May touch filled" "$lf" "The plan's ## Crew board"
assert_not_contains "Lead has no member prompts" "$lf" "One lane per member"
assert_not_contains "No section markers left (lead)" "$lf" "sb:lead"
assert_contains "Member Job prompt" "$mf" "One lane per member"
assert_contains "Member Reports filled" "$mf" "then tells the lead in one line: the task id and its proof"
assert_not_contains "Member has no lead text" "$mf" "Keeps the crew rowing in time"
assert_not_contains "No section markers left (member)" "$mf" "sb:member"

echo "Test 3: bad and duplicate names are refused"
assert_fails "Uppercase name refused" add Dill "x"
assert_fails "Reserved name refused" add list "x"
assert_fails "Duplicate refused" add dill "x"
assert_fails "Missing role refused" add newbie

echo "Test 4: list shows who holds what"
printf '# Task 7: Fix the upload\n\n**Crew**: dill\n' > "$TMPDIR/docs/tasks/doing/7-fix-the-upload.md"
printf '# Task 8: Something else\n\n**Crew**: none\n' > "$TMPDIR/docs/tasks/next/8-something-else.md"
out="$(crew)"
assert_contains "Lead is marked" "$out" "orcha"
assert_contains "Lead label" "$out" "(lead)"
assert_contains "Held task listed" "$out" "doing/  7  Fix the upload"
assert_not_contains "Unrouted task not listed" "$out" "Something else"

echo "Test 5: a member starts with the crew rules and its target"
out="$(crew dill 7)"
assert_contains "Names the member" "$out" "You are dill"
assert_contains "Points at the member file" "$out" "docs/crew/dill.md"
assert_contains "Names the task" "$out" "Your work is task 7"
assert_contains "Claim rule" "$out" "set its **Crew** field to dill"
assert_not_contains "No lead rules for a member" "$out" "You lead this crew"

echo "Test 6: the lead gets lead rules on a plan"
printf '# Plan 3: Upload fixes\n\n**Status:** STARTED\n' > "$TMPDIR/docs/plans/3-upload-fixes.md"
out="$(crew orcha plan:3)"
assert_contains "Lead rules" "$out" "You lead this crew"
assert_contains "Plan target" "$out" "Your work is plan 3"

echo "Test 6a: a lead on a plan is assigned it and gets the parallel layout"
mkt() { printf '# Task %s: %s\n\n**Depends on**: %s\n**Crew**: none\n' "$1" "$2" "$3" > "$TMPDIR/docs/tasks/next/$1-t.md"; }
mkt 41 "API grace window" none; mkt 42 "iOS retry" none; mkt 43 "End-to-end test" "41, 42"
printf '# Plan 5: iOS logout race\n\n**Created**: 2026-10-08\n**Status:** DRAFT\n\n## Member tasks\n\n- #41 — a\n- #42 — b\n- #43 — c\n' > "$TMPDIR/docs/plans/5-ios-logout-race.md"
out="$(crew orcha plan:5)"
assert_contains "Plan stamped with its lead" "$(cat "$TMPDIR/docs/plans/5-ios-logout-race.md")" "**Crew**: orcha"
assert_contains "Parallel build block" "$out" "Parallel build: plan 5 is assigned to you"
assert_contains "Wave 1 holds both roots" "$out" "- #41 API grace window [next/]"
assert_contains "Wave 2 waits on both" "$out" "- #43 End-to-end test [next/], after #41, #42"
assert_contains "Unstarted plan says plan start" "$out" "Run ./sprint.sh plan start 5 first"
echo "Test 6a2: the lead prompt carries the routing rules (plan 28)"
assert_contains "Split on disjoint Touching" "$out" "need disjoint **Touching:** sets"
assert_contains "Overlap runs in order, lower id first" "$out" "run in order through **Depends on**, lower id first"
assert_contains "Route on landing" "$out" "Route on landing: when a member reports one, check its **Proof**: line"
assert_contains "Dependents routed the same turn" "$out" "route the tasks it releases in that same turn"
assert_contains "No one idles" "$out" "No one idles: every member has a task now and one queued next on the board"
assert_contains "Built on landed work is marked" "$out" '"built on #N (landed)"'
assert_contains "Blocked member hands off" "$out" "A blocked member hands the blocker to its owner (or you) and starts its next task"
assert_contains "Plan close at LANDED" "$out" "Plan close: when plan check reads LANDED, run the full suite once"
assert_contains "Fixes go to the right member" "$out" "Route each fix to the member who built the original"
assert_contains "One sign-off batch for the human" "$out" "hand the human one sign-off: ./sprint.sh promote plan:5"
assert_contains "Lead never answers the approval" "$out" "That approval is the human's; never answer it"
assert_contains "Board holds task now and next" "$out" "name, task now, task next, state"
assert_contains "Members report landings" "$out" "report the landing (task id and proof line) to the lead by message"
assert_contains "Board is the channel without messaging" "$out" "on the plan's ## Crew board when your CLI cannot message"
out="$(crew orcha)"
assert_contains "Lead resumes its assigned plan" "$out" "Your work is plan 5"
assert_contains "List shows the plan a lead holds" "$(crew)" "leads plan 5: iOS logout race"
out="$(crew dill plan:5)"
assert_not_contains "A member on a plan gets no lead layout" "$out" "Parallel build:"
assert_contains "Member does not take the plan" "$(cat "$TMPDIR/docs/plans/5-ios-logout-race.md")" "**Crew**: orcha"
rm -f "$TMPDIR"/docs/tasks/next/4[123]-t.md "$TMPDIR/docs/plans/5-ios-logout-race.md"

echo "Test 6b: members get the parallel-work rule and see the others in doing/"
printf '# Task 9: Tidy the footer\n\n**Crew**: orcha\n' > "$TMPDIR/docs/tasks/doing/9-tidy-the-footer.md"
out="$(crew dill 7)"
assert_contains "Parallel rule" "$out" "Parallel work:"
assert_contains "Announce via Touching" "$out" "**Touching:**"
assert_contains "Test loop rule" "$out" "Test loop:"
assert_contains "Proof line format" "$out" "**Proof**: YYYY-MM-DD · <targeted test commands> · pass"
assert_contains "Finish with the proof line" "$out" "## Completed section with its proof line"
assert_contains "Sibling listed with holder" "$out" "docs/tasks/doing/9-tidy-the-footer.md (crew: orcha)"
assert_not_contains "Own task not listed as a sibling" "$out" "- docs/tasks/doing/7-fix-the-upload.md"
rm -f "$TMPDIR/docs/tasks/doing/9-tidy-the-footer.md"

echo "Test 6c: a pile of doing/ files is capped so the prompt stays small"
for i in 20 21 22 23 24 25 26 27 28 29; do
    printf '# Task %s: Old\n' "$i" > "$TMPDIR/docs/tasks/doing/$i-old.md"
done
out="$(crew dill 7)"
assert_contains "Overflow summarized" "$out" "and 2 more in docs/tasks/doing/"
assert_not_contains "Ninth sibling not listed" "$out" "- docs/tasks/doing/29-old.md"
rm -f "$TMPDIR"/docs/tasks/doing/2[0-9]-old.md

echo "Test 6d: crew setup sends the method plus only the active provider's tuning"
out="$(cd "$TMPDIR" && SPRINTBIAS_PROVIDER=claude-code SPRINTBIAS_MODE=emit bash docs/sprintbias/scripts/crew.sh setup 2>&1)"
assert_contains "Setup method" "$out" "Build the smallest crew"
assert_contains "Claude tuning sent" "$out" "## Claude Code"
assert_not_contains "Grok tuning not sent to Claude" "$out" "## Grok Build"
assert_contains "Setup draws lanes for disjoint Touching" "$out" "split into disjoint **Touching:** sets"
assert_contains "Setup names the one sign-off" "$out" "handing the human one sign-off"
assert_contains "Claude: landings by message" "$out" "a member reports each landing the same way"
out="$(cd "$TMPDIR" && SPRINTBIAS_PROVIDER=grok-build SPRINTBIAS_MODE=emit bash docs/sprintbias/scripts/crew.sh setup 2>&1)"
assert_contains "Grok tuning sent" "$out" "## Grok Build"
assert_not_contains "Claude tuning not sent to Grok" "$out" "## Claude Code"
assert_contains "Grok: landings go on the board" "$out" "Add to each member's Reports: \"write each landing (task id and proof"
assert_contains "Grok: lead re-reads the board" "$out" "and ./sprint.sh plan check N each turn, then route what landed"
assert_fails "setup is a reserved name" add setup "x"

echo "Test 6e: provider tuning dates are present (warns past 90 days)"
while IFS= read -r d; do
    if ! age=$(python3 -c "import datetime,sys;print((datetime.date.today()-datetime.date.fromisoformat(sys.argv[1])).days)" "$d" 2>/dev/null); then
        echo "  FAIL: unreadable Tuned date '$d'"; FAIL=$((FAIL + 1)); continue
    fi
    if [ "$age" -gt 90 ]; then
        echo "  WARN: a crew-setup Tuned date is $age days old — re-tune it (docs/guides/provider-reality.md)"
    fi
    echo "  PASS: Tuned date $d"; PASS=$((PASS + 1))
done < <(sed -n 's/^\*\*Tuned\*\*: *//p' "$SPRINTBIAS_SRC/ai/crew-setup.md")

echo "Test 7: unknown member, task and plan fail"
assert_fails "Unknown member" nobody
assert_fails "Unknown task" dill 999
assert_fails "Unknown plan" orcha plan:99

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
