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
#
# Discovered by run-all.sh (test-*.sh). Pure shell.

set -euo pipefail

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
    if printf '%s' "$haystack" | grep -qF "$needle"; then
        echo "  PASS: $desc"; PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected output to contain '$needle')"; FAIL=$((FAIL + 1))
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
assert_contains "reports the skip" "$OUT" "human sign-off"

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

# --- Test 6b: the hold self-clears once the prereq reaches review/ ---
echo "Test 6b: moving the prereq into review/ releases the held dependent on re-run"
mv "$BOARD/docs/tasks/backlog/710-open-prereq.md" "$BOARD/docs/tasks/review/710-open-prereq.md"
run_promote
assert_eq "released once prereq satisfied → done/" "true" "$(in_done 711-dependent.md)"
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

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
