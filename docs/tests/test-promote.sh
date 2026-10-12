#!/usr/bin/env bash
# Test: promote — the test-gated close path proves itself (task 333 / plan 15).
#
# The one command that closes work is dogfooded here: throwaway fixtures under a
# temp board, no live AI, no touch of the real docs/tasks/. Covers both gates —
# **Tests** gates the close, **Depends on** gates it too:
#   - **Tests** green            → review/ → done/
#   - a failing test             → stays in review/, run exits 1
#   - none / missing field       → skipped, does not fail the run (exit 0)
#   - out-of-tree **Tests** path → stays in review/ with the guardrail message
#   - legacy **Proven by** alias → still read, green → done/
#   - open **Depends on** prereq → held in review/, not moved (self-clears)
#   - plan fully in done/        → prints the plan-retire hint
#   - --reject <id> "report"     → linked fix task (**Fixes**, Crew, Plan),
#     original Held in review/, dependent trace, hold until the fix closes
#   - promote plan:N             → LANDED only; suite once; fix tasks on failure;
#     combined Signoff (human) checklist; one y moves every member to done/;
#     a green run is reused on an unchanged tree, re-run on a change or --fresh;
#     a held original reads "held: fix #N" once
#
# Discovered by run-all.sh (test-*.sh). Pure shell.

set -euo pipefail
# The breaker before sign-off has its own test (test-edge-cases.sh); these
# fixtures check the shell gates, so it stays off here.
export SPRINTBIAS_BREAK=off

PASS=0
FAIL=0
SPRINTBIAS_SRC="$(cd "$(dirname "$0")/../sprintbias" && pwd)"

# Fresh throwaway project carrying the whole sprintbias tree (promote.sh sources
# lib.sh, which loads a cli/ provider profile on demand). Copying the tree gives
# every runtime dependency without hand-picking files — the temp-board pattern
# from test-plan-lifecycle.sh / dep-glitch-matrix.
setup() {
    BOARD=$(mktemp -d)
    trap 'rm -rf "$BOARD"' EXIT
    mkdir -p "$BOARD/docs/tasks"/{backlog,next,doing,review,done,blocked}
    mkdir -p "$BOARD/docs/tests" "$BOARD/docs/plans"
    cp -R "$SPRINTBIAS_SRC" "$BOARD/docs/sprintbias"
    # The sandbox starts from the shipped config; a maintainer's personal
    # config.local (e.g. TEST_SUITE) would change what the tests see.
    rm -f "$BOARD/docs/sprintbias/config.local"
    git -C "$BOARD" init -q
}

# Write a review/ task. Field lines are passed verbatim so a caller can choose
# **Tests** or the legacy **Proven by** spelling, and any **Depends on** value.
#   make_review ID SLUG "**Tests**: docs/tests/x.sh" [DEPENDS_ON]
make_review() {
    local id="$1" slug="$2" field_line="$3" depends="${4:-none}"
    cat > "$BOARD/docs/tasks/review/${id}-${slug}.md" <<EOF
# Task ${id}: ${slug}

**Feature**: none
**Depends on**: ${depends}
${field_line}

## Problem

Throwaway promote fixture — do not implement product behavior from this file.

## Success criteria

- [ ] Fixture only
EOF
}

# A bare task file in an arbitrary lifecycle stage (a prerequisite target).
make_task() {
    local id="$1" slug="$2" stage="$3"
    printf '# Task %s: %s\n\n**Depends on**: none\n**Tests**: none\n' \
        "$id" "$slug" > "$BOARD/docs/tasks/$stage/${id}-${slug}.md"
}

# A green / failing throwaway suite script under the temp board's docs/tests/.
write_pass_test() { printf '#!/usr/bin/env bash\nexit 0\n' > "$BOARD/docs/tests/$1"; chmod +x "$BOARD/docs/tests/$1"; }
write_fail_test() { printf '#!/usr/bin/env bash\nexit 1\n' > "$BOARD/docs/tests/$1"; chmod +x "$BOARD/docs/tests/$1"; }

run_promote() {  # captures stdout+stderr; sets RC and OUT
    set +e
    OUT=$(cd "$BOARD" && bash docs/sprintbias/scripts/promote.sh "$@" 2>&1)
    RC=$?
    set -e
}

in_done()   { [ -f "$BOARD/docs/tasks/done/$1" ] && echo true || echo false; }
in_review() { [ -f "$BOARD/docs/tasks/review/$1" ] && echo true || echo false; }

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "  PASS: $desc"; PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected '$expected', got '$actual')"; FAIL=$((FAIL + 1))
    fi
}

assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if grep -qF -- "$needle" <<<"$haystack"; then
        echo "  PASS: $desc"; PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected output to contain '$needle')"; FAIL=$((FAIL + 1))
    fi
}
assert_not_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if grep -qF -- "$needle" <<<"$haystack"; then
        echo "  FAIL: $desc (expected output not to contain '$needle')"; FAIL=$((FAIL + 1))
    else
        echo "  PASS: $desc"; PASS=$((PASS + 1))
    fi
}

echo "=== test-promote.sh ==="

# --- Test 1: Tests green → done/ ---
echo "Test 1: a task whose **Tests** all pass moves review/ → done/"
setup
write_pass_test green.sh
make_review 700 tests-green "**Tests**: docs/tests/green.sh"
run_promote
assert_eq "exit 0 on a clean green promote" "0" "$RC"
assert_eq "moved to done/" "true" "$(in_done 700-tests-green.md)"
assert_eq "no longer in review/" "false" "$(in_review 700-tests-green.md)"

# --- Test 2: failing test → stays in review/, run exits 1 ---
echo "Test 2: a failing **Tests** script keeps the task in review/ and exits 1"
setup
write_fail_test red.sh
make_review 701 tests-red "**Tests**: docs/tests/red.sh"
run_promote
assert_eq "exit 1 when a named test fails" "1" "$RC"
assert_eq "stays in review/" "true" "$(in_review 701-tests-red.md)"
assert_eq "not moved to done/" "false" "$(in_done 701-tests-red.md)"

# --- Test 3: none / missing → skipped, does not fail the run ---
echo "Test 3: **Tests: none** is skipped for human sign-off and does not fail"
setup
make_review 702 tests-none "**Tests**: none"
run_promote
assert_eq "exit 0 — a skip is not a failure" "0" "$RC"
assert_eq "stays in review/ for a human" "true" "$(in_review 702-tests-none.md)"
assert_contains "reports the skip with its one-line close" "$OUT" "./sprint.sh promote --accept 702"

# --- Test 3b: --accept <id> is the person's sign-off ---
echo "Test 3b: --accept <id> closes a no-Tests task; named Tests still gate; holds apply"
setup
make_review 705 accept-none "**Tests**: none"
make_review 706 accept-other "**Tests**: none"
run_promote --accept 705
assert_eq "accept exits 0" "0" "$RC"
assert_eq "accepted task in done/" "true" "$(in_done 705-accept-none.md)"
assert_contains "says it was your sign-off" "$OUT" "#705  accepted → done/  (your sign-off)"
assert_eq "only the named task moved" "true" "$(in_review 706-accept-other.md)"
write_fail_test accept-red.sh
make_review 707 accept-red "**Tests**: docs/tests/accept-red.sh"
run_promote --accept 707
assert_eq "named Tests still run: red exits 1" "1" "$RC"
assert_eq "red task stays in review/" "true" "$(in_review 707-accept-red.md)"
make_task 708 accept-prereq backlog
make_review 709 accept-held "**Tests**: none" "708"
run_promote --accept 709
assert_eq "an open Depends on still holds" "true" "$(in_review 709-accept-held.md)"
assert_contains "names the open prereq" "$OUT" "#708 → backlog"
run_promote --accept
assert_eq "--accept without an id prints usage" "2" "$RC"
assert_contains "usage names the id" "$OUT" "promote --accept <id>"
run_promote --accept 706 --audit
assert_eq "--accept refuses other modes" "2" "$RC"

# --- Test 4: out-of-tree path → stays in review/ with the guardrail message ---
echo "Test 4: a **Tests** path outside docs/tests/ is refused with a guardrail line"
setup
make_review 703 tests-outside "**Tests**: /etc/passwd"
run_promote
assert_eq "exit 1 on an out-of-tree path" "1" "$RC"
assert_eq "stays in review/ (never ran an arbitrary path)" "true" "$(in_review 703-tests-outside.md)"
assert_contains "names the docs/tests/ guardrail" "$OUT" "not under docs/tests/"

# --- Test 5: legacy **Proven by** alias still read ---
echo "Test 5: the legacy **Proven by** field is still read and gates the close"
setup
write_pass_test proven.sh
make_review 704 proven-alias "**Proven by**: docs/tests/proven.sh"
run_promote
assert_eq "exit 0 via legacy alias" "0" "$RC"
assert_eq "moved to done/ via **Proven by**" "true" "$(in_done 704-proven-alias.md)"

# --- Test 6: held by an open Depends-on prereq → not moved ---
echo "Test 6: a task with green Tests but an OPEN Depends-on prereq is held, not moved"
setup
write_pass_test held-green.sh
make_task 710 open-prereq backlog                 # prereq still open (backlog)
make_review 711 dependent "**Tests**: docs/tests/held-green.sh" "710"
run_promote
assert_eq "exit 0 — a dependency hold is not a failure" "0" "$RC"
assert_eq "held in review/ (dependent never leads its prereq)" "true" "$(in_review 711-dependent.md)"
assert_eq "not moved to done/" "false" "$(in_done 711-dependent.md)"
assert_contains "names the open prereq and its stage" "$OUT" "#710 → backlog"

# --- Test 6b: a prereq in review/ without proof still holds (in review, unproven) ---
echo "Test 6b: a prereq moved into review/ with no proof line keeps the dependent held"
mv "$BOARD/docs/tasks/backlog/710-open-prereq.md" "$BOARD/docs/tasks/review/710-open-prereq.md"
run_promote
assert_eq "unproven review/ prereq → dependent still in review/" "true" "$(in_review 711-dependent.md)"
assert_contains "hold names the prereq as in review, unproven" "$OUT" "#710 → in review, unproven"
assert_contains "one note says how to release it (promote or proof)" "$OUT" "**Proof**: YYYY-MM-DD"

# --- Test 6c: the hold self-clears once the prereq lands (review/ + proof) ---
echo "Test 6c: recording a proof line on the review/ prereq releases the dependent on re-run"
printf '\n## Completed\n\n**Proof**: 2026-10-08 · bash docs/tests/x.sh · pass\n' \
    >> "$BOARD/docs/tasks/review/710-open-prereq.md"
run_promote
assert_eq "released once prereq landed → done/" "true" "$(in_done 711-dependent.md)"
assert_eq "no longer held in review/" "false" "$(in_review 711-dependent.md)"

# --- Test 7: plan-retire hint fires when a plan's members all reach done/ ---
echo "Test 7: promoting the last member of a plan prints the plan-retire hint"
setup
write_pass_test plan-green.sh
make_review 720 plan-member "**Tests**: docs/tests/plan-green.sh"
cat > "$BOARD/docs/plans/80-throwaway.md" <<EOF
# Plan 80: Throwaway

**Status:** STARTED

## Member tasks

- #720 — plan member
EOF
run_promote
assert_eq "member moved to done/" "true" "$(in_done 720-plan-member.md)"
assert_contains "names the plan for retirement" "$OUT" "plan done 80"

# --- Test 8: --reject files a linked fix task and holds the original ---------
echo "Test 8: promote --reject files a linked fix task, holds the original, traces dependents"
setup
cp "$SPRINTBIAS_SRC/../tasks/.TEMPLATE-task.md" "$BOARD/docs/tasks/.TEMPLATE-task.md"
write_pass_test rej-green.sh
make_landed() {  # ID SLUG STAGE DEPENDS — a proven task on plan 81, crew alice
    cat > "$BOARD/docs/tasks/$3/$1-$2.md" <<EOF
# Task $1: $2

**Plan**: 81
**Depends on**: $4
**Crew**: alice
**Tests**: docs/tests/rej-green.sh

## Problem

Throwaway reject fixture.

## Completed

**Proof**: 2026-10-08 · bash docs/tests/rej-green.sh · pass
EOF
}
make_landed 730 rejected review none
make_landed 731 dep-landed review 730
make_landed 732 dep-signed done 730
make_landed 733 dep-open next 730
printf '# Plan 81: Throwaway\n\n## Member tasks\n\n- #730 — rejected\n- #731 — dep\n' \
    > "$BOARD/docs/plans/81-throwaway.md"
run_promote --reject 730 'Saving crashes with "TypeError: x is undefined"
- export drops the last row
- human: the empty state reads cramped'
assert_eq "reject exits 0" "0" "$RC"
FIX=$(ls "$BOARD"/docs/tasks/backlog/*-fix-730-*.md 2>/dev/null | head -1)
FIXID=$(basename "${FIX:-none}" | grep -oE '^[0-9]+' || true)
assert_eq "fix task filed through newtask (next id)" "734" "$FIXID"
FIXBODY=$(cat "$FIX" 2>/dev/null || true)
assert_contains "fix task carries **Fixes**" "$FIXBODY" "**Fixes**: #730"
assert_contains "fix task copies **Crew**" "$FIXBODY" "**Crew**: alice"
assert_contains "fix task copies **Plan**" "$FIXBODY" "**Plan**: 81"
assert_contains "each reported bug becomes a test to add" "$FIXBODY" "Add a test that fails on this, then make it pass: export drops the last row"
assert_contains "error output becomes a test to add" "$FIXBODY" 'make it pass: Saving crashes with "TypeError: x is undefined"'
assert_contains "test lines name the suite in backticks" "$FIXBODY" '`bash docs/tests/rej-green.sh`'
SIGNOFF=$(awk '/^## Signoff \(human\)/{s=1;next} /^## /{s=0} s' "$FIX")
assert_contains "untestable item goes to Signoff (human)" "$SIGNOFF" "- [ ] the empty state reads cramped"
assert_contains "fix task keeps the report in its Test log" "$FIXBODY" "## Test log"
assert_contains "fix listed on the original's plan" "$(cat "$BOARD/docs/plans/81-throwaway.md")" "- #734 — Fix #730"
assert_eq "original stays in review/" "true" "$(in_review 730-rejected.md)"
assert_contains "original carries **Held**" "$(cat "$BOARD/docs/tasks/review/730-rejected.md")" "**Held**: fix #734"
assert_contains "landed dependent gets a re-check line" \
    "$(cat "$BOARD/docs/tasks/review/731-dep-landed.md")" "re-check: prerequisite #730 was sent back (fix #734)"
assert_contains "signed-off dependent gets a re-check line" \
    "$(cat "$BOARD/docs/tasks/done/732-dep-signed.md")" "re-check: prerequisite #730 was sent back"
assert_contains "done/ dependent is flagged in the output" "$OUT" "#732 is signed off (done/)"
assert_eq "done/ dependent is not moved" "true" "$(in_done 732-dep-signed.md)"
if grep -q "re-check" "$BOARD/docs/tasks/next/733-dep-open.md"; then
    echo "  FAIL: open dependent got a re-check line"; FAIL=$((FAIL + 1))
else
    echo "  PASS: open dependent gets no re-check line"; PASS=$((PASS + 1))
fi

# --- Test 9: Held holds dependents until the fix lands, the original until done/ ---
echo "Test 9: a Held original releases nothing until its fix lands, and closes after the fix is in done/"
run_promote
assert_eq "held original stays in review/" "true" "$(in_review 730-rejected.md)"
assert_contains "hold names the open fix" "$OUT" "fix #734 → backlog"
assert_eq "landed dependent of a held original stays in review/" "true" "$(in_review 731-dep-landed.md)"
assert_contains "dependent hold names the held prereq" "$OUT" "#730 → held (fix #734 not landed)"
# The fix lands (review/ + proof): dependents release, the original still waits.
mv "$FIX" "$BOARD/docs/tasks/review/"
FIX="$BOARD/docs/tasks/review/$(basename "$FIX")"
printf '\n## Completed\n\n**Proof**: 2026-10-08 · bash docs/tests/rej-green.sh · pass\n' >> "$FIX"
run_promote --dry-run
assert_contains "once the fix lands the dependent releases" "$OUT" "#731  proven green"
assert_contains "the original waits for its fix in done/" "$OUT" "fix #734 → review"
# The fix is signed off: the original closes.
mv "$FIX" "$BOARD/docs/tasks/done/"
run_promote
assert_eq "original closes once its fix is in done/" "true" "$(in_done 730-rejected.md)"

# --- Test 10: --reject guards ----------------------------------------------
echo "Test 10: --reject refuses a non-review/ task and an empty report"
run_promote --reject 733 "broken"
assert_eq "an unlanded id is refused" "1" "$RC"
assert_contains "names why" "$OUT" "reject works on landed work (review/ or done/)"
# Found broken after sign-off: a linked fix task is filed; the original stays done.
run_promote --reject 730 "breaks on an empty file"
assert_eq "a done/ task can be reported broken" "0" "$RC"
assert_contains "says the original stays signed off" "$OUT" "#730 stays in done/ (signed off)"
assert_not_contains "no close-later promise for a done/ task" "$OUT" "promote closes #730"
assert_eq "original stays in done/" "true" "$(in_done 730-rejected.md)"
_sfix=$(grep -l '^\*\*Fixes\*\*: #730$' "$BOARD"/docs/tasks/backlog/*.md 2>/dev/null | tail -1)
assert_eq "the fix task links the original" "true" "$([ -n "$_sfix" ] && echo true || echo false)"
assert_contains "the fix says it broke after sign-off" "$(cat "$_sfix" 2>/dev/null)" "was signed off, then found broken"
assert_contains "the original's test log links the fix" "$(cat "$BOARD/docs/tasks/done/730-rejected.md")" "found broken after sign-off: breaks on an empty file"
run_promote --reject 731
assert_eq "missing report prints usage" "2" "$RC"
assert_contains "usage names the report" "$OUT" 'promote --reject <id> "what is wrong"'

# --- Test 10b: a **Tests** file runs the way the project runs it -----------
echo "Test 10b: .py runs through TEST_RUN or pytest, an executable directly"
setup
printf 'import sys\nsys.exit(0)\n' > "$BOARD/docs/tests/green_check.py"
printf 'import sys\nsys.exit(1)\n' > "$BOARD/docs/tests/red_check.py"
make_review 760 py-green "**Tests**: docs/tests/green_check.py"
make_review 761 py-red "**Tests**: docs/tests/red_check.py"
printf '\nTEST_RUN=python3 {}\n' >> "$BOARD/docs/sprintbias/config"
run_promote
assert_eq "TEST_RUN runs a green .py: done/" "true" "$(in_done 760-py-green.md)"
assert_eq "TEST_RUN runs a red .py: stays in review/" "true" "$(in_review 761-py-red.md)"
assert_contains "red .py names its exit" "$OUT" "docs/tests/red_check.py → FAIL (exit 1)"
# {file} is the name alone, run from the tests folder (scripts/pytest.sh style).
printf '#!/usr/bin/env bash\ncd docs/tests && python3 "$1"\n' > "$BOARD/run-py.sh"
sed -i.bak 's#^TEST_RUN=python3 {}$#TEST_RUN=bash run-py.sh {file}#' "$BOARD/docs/sprintbias/config"
mv "$BOARD/docs/tasks/done/760-py-green.md" "$BOARD/docs/tasks/review/"
run_promote 760
assert_eq "TEST_RUN with {file}: done/" "true" "$(in_done 760-py-green.md)"
# Not .sh, no TEST_RUN: an executable file runs directly (its own shebang).
sed -i.bak '/^TEST_RUN=bash run-py.sh/d' "$BOARD/docs/sprintbias/config"
printf '#!/usr/bin/env python3\nimport sys\nsys.exit(0)\n' > "$BOARD/docs/tests/exec_check"
chmod +x "$BOARD/docs/tests/exec_check"
make_review 762 exec-green "**Tests**: docs/tests/exec_check"
run_promote 762
assert_eq "an executable test runs by its shebang: done/" "true" "$(in_done 762-exec-green.md)"
# The fix task's proof command names the same runner.
printf '\nTEST_RUN=scripts/pytest.sh {file}\n' >> "$BOARD/docs/sprintbias/config"
cp "$SPRINTBIAS_SRC/../tasks/.TEMPLATE-task.md" "$BOARD/docs/tasks/.TEMPLATE-task.md"
run_promote --reject 761 "an empty row crashes"
_fx=$(grep -l '^\*\*Fixes\*\*: #761$' "$BOARD"/docs/tasks/backlog/*.md 2>/dev/null | tail -1 || true)
assert_contains "fix task proof uses the project's runner" "$(cat "$_fx")" '`scripts/pytest.sh red_check.py`'
assert_not_contains "never bash on a .py" "$(cat "$_fx")" 'bash docs/tests/red_check.py'

# --- Test 11-15: promote plan:N — the sign-off batch ------------------------
# A plan member: landed (review/ + proof) unless STAGE says otherwise.
#   make_member ID SLUG STAGE DEPENDS FILES SIGNOFF
# FILES lands under ### Files changed; SIGNOFF (may be empty = old task with no
# ## Signoff (human) section) becomes that section's one checkbox.
make_member() {
    local f="$BOARD/docs/tasks/$3/$1-$2.md"
    {
        printf '# Task %s: %s\n\n**Plan**: 90\n**Depends on**: %s\n**Crew**: bob\n**Tests**: docs/tests/plan-green.sh\n\n## Problem\n\nThrowaway batch fixture.\n\n' "$1" "$2" "$4"
        [ -n "$6" ] && printf '## Signoff (human)\n\n- [ ] %s\n\n' "$6"
        printf '## Completed\n\n### Files changed\n%s\n\n**Proof**: 2026-10-08 · bash docs/tests/plan-green.sh · pass\n' "$5"
    } > "$f"
}
plan_board() {
    setup
    cp "$SPRINTBIAS_SRC/../tasks/.TEMPLATE-task.md" "$BOARD/docs/tasks/.TEMPLATE-task.md"
    write_pass_test plan-green.sh
    # Members listed out of dependency order: 741 needs 742.
    make_member 741 api review 742 "src/api.js" "Call the API from a browser"
    make_member 742 store review none "src/store.js" ""
    make_member 743 ui review 741 "src/ui.js
src/ui.css" "The settings screen reads clearly"
    cat > "$BOARD/docs/plans/90-batch.md" <<EOF
# Plan 90: Batch

**Status:** STARTED

## Member tasks

- #741 — api
- #742 — store
- #743 — ui

## Signoff (human)

- [ ] Walk the whole flow once
EOF
}
# The suite counts its runs in docs/tmp/suite-runs and prints $2 on exit $1.
set_suite() {
    mkdir -p "$BOARD/docs/tmp"
    printf '#!/usr/bin/env bash\necho run >> docs/tmp/suite-runs\nprintf "%%s\\n" "%s"\nexit %s\n' "$2" "$1" \
        > "$BOARD/docs/tests/full-suite.sh"
    printf 'TEST_SUITE=bash docs/tests/full-suite.sh\n' >> "$BOARD/docs/sprintbias/config.local"
}
suite_runs() { [ -f "$BOARD/docs/tmp/suite-runs" ] && grep -c run "$BOARD/docs/tmp/suite-runs" || echo 0; }
all_review() { for f in 741-api 742-store 743-ui; do [ -f "$BOARD/docs/tasks/review/$f.md" ] || { echo false; return; }; done; echo true; }

echo "Test 11: promote plan:N on a plan that is not LANDED names what is open and runs nothing"
plan_board
set_suite 0 "all green"
mv "$BOARD/docs/tasks/review/743-ui.md" "$BOARD/docs/tasks/doing/743-ui.md"
run_promote plan:90 </dev/null
assert_eq "not-LANDED exits 0" "0" "$RC"
assert_contains "says the plan is not LANDED" "$OUT" "Plan 90 is STARTED, not LANDED"
assert_contains "names the open member and its folder" "$OUT" "#743  open — doing/"
assert_eq "suite did not run" "0" "$(suite_runs)"

echo "Test 12: a LANDED plan runs the suite once, shows the combined checklist, and moves nothing without an answer"
plan_board
set_suite 0 "all green"
run_promote plan:90 </dev/null
assert_eq "exit 0" "0" "$RC"
assert_eq "suite ran exactly once" "1" "$(suite_runs)"
ORDER=$(printf '%s\n' "$OUT" | grep -oE '^    #74[0-9]' | head -3 | tr -d ' #' | tr '\n' ' ')
assert_eq "landed tasks listed in dependency order" "742 741 743 " "$ORDER"
HT=$(ls "$BOARD"/docs/tasks/review/*-human-test-for-plan-90-*.md 2>/dev/null | head -1)
HTID=$(basename "${HT:-0-x}" | cut -d- -f1)
assert_eq "an older plan gets its human test in review/" "true" "$([ -n "$HT" ] && echo true || echo false)"
assert_contains "the human test is the person's" "$(cat "${HT:-/dev/null}")" "**Owner**: human"
assert_contains "it is listed last in the plan" "$(tail -n +1 "$BOARD/docs/plans/90-batch.md")" "- #$HTID — Human test for plan 90"
assert_contains "plan's own human checks" "$OUT" "- [ ] Walk the whole flow once"
assert_contains "member checks tagged by task" "$OUT" "- [ ] #741: Call the API from a browser"
assert_contains "names the human test" "$OUT" "Human test #$HTID — run these, then approve once:"
assert_contains "asks once, the human test closing with the batch" "$OUT" "Approve plan 90 and move 4 task(s) to done/? [y/N]"
assert_contains "says how to report a failure" "$OUT" "Write '- fail: <what you saw>' under ## Results"
assert_contains "no answer moves nothing" "$OUT" "Not approved — nothing moved"
assert_eq "every member still in review/" "true" "$(all_review)"

echo "Test 13: answering y on an unchanged tree reuses the green run and moves every member to done/"
run_promote plan:90 <<< "y"
assert_eq "exit 0" "0" "$RC"
assert_eq "suite reused, not re-run (its docs/tmp/ writes do not count as a change)" "1" "$(suite_runs)"
assert_contains "says the run was reused, with its time" "$OUT" "Full suite reused: it passed at 20"
assert_eq "741 in done/" "true" "$(in_done 741-api.md)"
assert_eq "742 in done/" "true" "$(in_done 742-store.md)"
assert_eq "743 in done/" "true" "$(in_done 743-ui.md)"
assert_eq "the human test in done/" "true" "$(in_done "$(basename "$HT")")"
assert_contains "plan reads SIGNED OFF" "$OUT" "Plan 90 is SIGNED OFF"

echo "Test 14: a failing suite files fix tasks for the member whose files failed, and moves nothing"
plan_board
set_suite 1 "FAIL: src/store.js: save drops the last row"
run_promote plan:90 <<< "y"
assert_eq "suite failure exits 1" "1" "$RC"
assert_eq "suite ran once" "1" "$(suite_runs)"
assert_eq "nothing moved, even with y piped" "true" "$(all_review)"
FIX=$(ls "$BOARD"/docs/tasks/backlog/*-fix-742-*.md 2>/dev/null | head -1)
assert_eq "fix task filed for the member that touched src/store.js" "true" "$([ -n "$FIX" ] && echo true || echo false)"
assert_contains "fix task carries the failing output" "$(cat "${FIX:-/dev/null}")" "save drops the last row"
assert_contains "original is held for its fix" "$(cat "$BOARD/docs/tasks/review/742-store.md")" "**Held**: fix #"
assert_eq "no fix task for an unrelated member" "" "$(ls "$BOARD"/docs/tasks/backlog/*-fix-741-*.md 2>/dev/null || true)"
assert_eq "a failed run leaves no pass stamp" "false" \
    "$([ -f "$BOARD/docs/tmp/promote-plan-90-suite.pass" ] && echo true || echo false)"
run_promote plan:90 </dev/null
assert_contains "the open fix keeps the plan from LANDED" "$OUT" "for #742  open — backlog/"
FIXID=$(basename "${FIX:-0-x}" | cut -d- -f1)
assert_contains "the held original reads held: fix #N" "$OUT" "#742  held: fix #$FIXID"
assert_eq "the held original is listed once" "1" \
    "$(printf '%s\n' "$OUT" | grep -c '^    #742 ' || true)"
assert_contains "the fix reads as fix #N for #742" "$OUT" "fix #$FIXID for #742  open — backlog/"
assert_eq "the open fix is listed once, not also as a plain member" "1" \
    "$(printf '%s\n' "$OUT" | grep -c "#$FIXID " || true)"

echo "Test 14b: a failure that names no member's files goes to the plan's last member"
plan_board
set_suite 1 "Error: something unrelated broke"
run_promote plan:90 </dev/null
assert_eq "exits 1" "1" "$RC"
assert_eq "fix task filed for the last member (#743)" "true" \
    "$(ls "$BOARD"/docs/tasks/backlog/*-fix-743-*.md >/dev/null 2>&1 && echo true || echo false)"

echo "Test 15: with no TEST_SUITE the batch says no suite ran and still shows the checklist"
plan_board
run_promote plan:90 <<< "n"
assert_contains "says plainly no suite ran" "$OUT" "No full suite: TEST_SUITE is empty"
assert_contains "checklist still shown" "$OUT" "- [ ] #743: The settings screen reads clearly"
assert_eq "answer n moves nothing" "true" "$(all_review)"
run_promote plan:90 742
assert_eq "plan:N refuses other arguments" "2" "$RC"
run_promote plan:90 --audit --fresh
assert_eq "--fresh does not unlock other arguments" "2" "$RC"
run_promote --fresh
assert_eq "--fresh without plan:N is refused" "2" "$RC"
assert_contains "and says it applies to plan:N" "$OUT" "--fresh applies to plan:N only"

echo "Test 16: a change to the tree re-runs the suite; --fresh re-runs it on an unchanged tree"
plan_board
set_suite 0 "all green"
run_promote plan:90 </dev/null
assert_eq "first run ran the suite" "1" "$(suite_runs)"
assert_contains "first run writes a pass stamp" "$(cat "$BOARD/docs/tmp/promote-plan-90-suite.pass" 2>/dev/null)" "20"
run_promote plan:90 </dev/null
assert_eq "unchanged tree reuses the run" "1" "$(suite_runs)"
echo "// edit" > "$BOARD/src-edit.js"
run_promote plan:90 </dev/null
assert_eq "a new file re-runs the suite" "2" "$(suite_runs)"
assert_contains "and says it ran" "$OUT" "Running the full suite once"
run_promote plan:90 </dev/null
assert_eq "the re-run is reused next time" "2" "$(suite_runs)"
echo "// more" >> "$BOARD/docs/tests/plan-green.sh"
run_promote plan:90 </dev/null
assert_eq "an edited file re-runs the suite" "3" "$(suite_runs)"
run_promote plan:90 --fresh </dev/null
assert_eq "--fresh re-runs on an unchanged tree" "4" "$(suite_runs)"
assert_eq "--fresh run exits 0" "0" "$RC"
printf 'TEST_SUITE=bash docs/tests/full-suite.sh  \n' >> "$BOARD/docs/sprintbias/config.local"
printf 'TEST_SUITE=bash  docs/tests/full-suite.sh\n' >> "$BOARD/docs/sprintbias/config.local"
run_promote plan:90 </dev/null
assert_eq "a changed TEST_SUITE command re-runs the suite" "5" "$(suite_runs)"
set_suite 1 "FAIL: now broken"
run_promote plan:90 </dev/null
assert_eq "a failing run exits 1" "1" "$RC"
assert_eq "a failing run clears the stamp" "false" \
    "$([ -f "$BOARD/docs/tmp/promote-plan-90-suite.pass" ] && echo true || echo false)"

echo "Test 17: the human test gathers assumptions, skips the agents' paths, and its failures come back as fix tasks"
plan_board
set_suite 0 "all green"
printf '\n### Assumptions\n- The reader holds the phone upright\n- Decided: cache for a minute, because it is simpler\n' >> "$BOARD/docs/tasks/review/742-store.md"
run_promote plan:90 </dev/null
HT=$(ls "$BOARD"/docs/tasks/review/*-human-test-for-plan-90-*.md 2>/dev/null | head -1)
HTID=$(basename "${HT:-0-x}" | cut -d- -f1)
assert_contains "an assumption becomes a check" "$(cat "${HT:-/dev/null}")" "- [ ] #742 assumed: The reader holds the phone upright"
assert_not_contains "a Decided: call is not a check" "$(cat "${HT:-/dev/null}")" "cache for a minute"
run_promote plan:90 </dev/null
assert_eq "a refresh with nothing new adds no line" "1" "$(grep -c 'phone upright' "${HT:-/dev/null}")"
run_promote --dry-run </dev/null
assert_not_contains "promote leaves the human test alone" "$OUT" "#$HTID "
run_promote "$HTID" </dev/null
assert_contains "promote <id> on the human test points at the plan batch" "$OUT" "promote plan:90"
printf -- '- fail: the save button does nothing on the tablet\n' >> "$HT"
run_promote plan:90 <<< "y"
assert_eq "a reported failure exits 1" "1" "$RC"
assert_eq "nothing moved, even with y" "true" "$(all_review)"
HFIX=$(ls "$BOARD"/docs/tasks/backlog/*-fix-"$HTID"-the-save-button*.md 2>/dev/null | head -1)
assert_eq "the failure is a fix task named for it" "true" "$([ -n "$HFIX" ] && echo true || echo false)"
assert_contains "the fix task carries the report" "$(cat "${HFIX:-/dev/null}")" "the save button does nothing on the tablet"
assert_contains "the result line is marked filed" "$(cat "$HT")" "- filed #$(basename "${HFIX:-0-x}" | cut -d- -f1): the save button"
run_promote plan:90 </dev/null
assert_eq "no second fix task for the same line" "1" "$(ls "$BOARD"/docs/tasks/backlog/*-fix-"$HTID"-*.md | wc -l | tr -d ' ')"
assert_contains "the open fix keeps the plan from LANDED" "$OUT" "Plan 90 is STARTED, not LANDED"

echo "Test 18: members closed one by one leave the plan LANDED, not SIGNED OFF, until the human test closes"
plan_board
run_promote plan:90 </dev/null
HT=$(ls "$BOARD"/docs/tasks/review/*-human-test-for-plan-90-*.md 2>/dev/null | head -1)
run_promote </dev/null
assert_eq "the members closed on their tests" "true" "$(in_done 741-api.md)"
run_promote plan:90 <<< "y"
assert_contains "the plan still asks for the human test" "$OUT" "Approve plan 90 and move 1 task(s) to done/? [y/N]"
assert_eq "the human test closes with the y" "true" "$(in_done "$(basename "${HT:-x}")")"
assert_contains "then the plan reads SIGNED OFF" "$OUT" "Plan 90 is SIGNED OFF"


echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
