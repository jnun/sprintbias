#!/usr/bin/env bash
# Test: profile.sh
# Non-AI paths: show, --help, unknown arg. (Interactive create/update needs a TTY + provider.)

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_UNDER_TEST="$(cd "$(dirname "$0")/../sprintbias/scripts" && pwd)/profile.sh"
SPRINTBIAS_SRC="$(cd "$(dirname "$0")/../sprintbias" && pwd)"

setup() {
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    # profile.sh: SCRIPT_DIR/../../.. is PROJECT_ROOT
    mkdir -p "$TMPDIR/docs/sprintbias/scripts"
    cp "$SCRIPT_UNDER_TEST" "$TMPDIR/docs/sprintbias/scripts/profile.sh"
    cp "$SPRINTBIAS_SRC/lib.sh" "$TMPDIR/docs/sprintbias/lib.sh"
    cp -R "$SPRINTBIAS_SRC/cli" "$TMPDIR/docs/sprintbias/cli"
}

assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if echo "$haystack" | grep -qF "$needle"; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected to contain '$needle')"
        FAIL=$((FAIL + 1))
    fi
}

assert_exit_code() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected exit $expected, got $actual)"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== test-profile.sh ==="

# Test 1: show with no profile — exits 0, helpful message
echo "Test 1: show with no profile"
setup
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/profile.sh" show 2>&1) || rc=$?
assert_exit_code "show no-profile exits 0" "0" "$rc"
assert_contains "Says no profile yet" "$output" "No project profile yet"
assert_contains "Hints at create command" "$output" "./sprint.sh profile"

# Test 2: show with profile — prints file contents
echo "Test 2: show with profile"
setup
cat > "$TMPDIR/docs/sprintbias/project.md" << 'EOF'
# Project Profile
**Language:** Bash
**Framework:** SprintBias
**Tests:** docs/tests
**Style:** shellcheck
**Error handling:** set -euo pipefail
**Structure:** docs/ + src/
**Patterns:** dual tree
EOF
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/profile.sh" show 2>&1) || rc=$?
assert_exit_code "show with profile exits 0" "0" "$rc"
assert_contains "Prints Language" "$output" "**Language:** Bash"
assert_contains "Prints Patterns" "$output" "**Patterns:** dual tree"

# Test 3: --help exits 0
echo "Test 3: --help"
setup
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/profile.sh" --help 2>&1) || rc=$?
assert_exit_code "help exits 0" "0" "$rc"
assert_contains "Usage mentions show" "$output" "profile show"

# Test 4: unknown arg exits 1
echo "Test 4: unknown arg"
setup
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/profile.sh" foobar 2>&1) || rc=$?
assert_exit_code "unknown exits 1" "1" "$rc"
assert_contains "Reports unknown" "$output" "Unknown argument"

# Test 5: one orientation line — no script hand-writes its own preamble
echo "Test 5: every prompt orients through sprintbias_orient"
_hand=$(grep -ln 'is auto-loaded\|sprintbias_profile_line\|Also read docs/sprintbias/project.md' \
    "$SPRINTBIAS_SRC"/scripts/*.sh 2>/dev/null || true)
if [ -z "$_hand" ]; then
    echo "  PASS: no hand-written orientation preambles"
    PASS=$((PASS + 1))
else
    echo "  FAIL: hand-written preamble in: $_hand"
    FAIL=$((FAIL + 1))
fi
for _s in create-idea create-feature work gate-lib chat chat-plan polish promote split; do
    if grep -q 'sprintbias_orient' "$SPRINTBIAS_SRC/scripts/$_s.sh"; then
        echo "  PASS: $_s uses sprintbias_orient"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $_s does not use sprintbias_orient"
        FAIL=$((FAIL + 1))
    fi
done

# Test 6: update-mode prompt re-scans (source check)
echo "Test 6: update mode re-scans and surfaces drift"
if grep -q 'surface drift proactively' "$SCRIPT_UNDER_TEST" \
    && grep -q 'sprintbias_run_interactive' "$SCRIPT_UNDER_TEST"; then
    echo "  PASS: update re-scan + interactive path present"
    PASS=$((PASS + 1))
else
    echo "  FAIL: profile.sh missing re-scan or interactive path"
    FAIL=$((FAIL + 1))
fi

# Test 7: profile check (no AI)
echo "Test 7: profile check"
setup
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/profile.sh" check 2>&1) || rc=$?
assert_exit_code "check with no map exits 1" "1" "$rc"
assert_contains "Says no map yet" "$output" "No project map yet"

mkdir -p "$TMPDIR/src"
touch "$TMPDIR/GLOSSARY.md"
cat > "$TMPDIR/docs/sprintbias/project.md" << 'EOF'
# Project Profile
**Language:** Bash

## Code
**Structure:** `src/` app code

## Commands
**Test:** `make`

## Sources of truth
**Glossary:** `GLOSSARY.md` — terms
**API:** `openapi.yaml` — the contract

**Checked:** 2026-09-29
EOF
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/profile.sh" check 2>&1) || rc=$?
assert_exit_code "check with a missing path exits 1" "1" "$rc"
assert_contains "Names the missing path" "$output" "openapi.yaml"
if echo "$output" | grep -q 'make'; then
    echo "  FAIL: a ## Commands entry was treated as a path"
    FAIL=$((FAIL + 1))
else
    echo "  PASS: ## Commands entries are not path-checked"
    PASS=$((PASS + 1))
fi

touch "$TMPDIR/openapi.yaml"
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/profile.sh" check 2>&1) || rc=$?
assert_exit_code "check with every path present exits 0" "0" "$rc"
assert_contains "Reports current" "$output" "Project map is current"

sed -i.bak '/Checked/d' "$TMPDIR/docs/sprintbias/project.md"
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/profile.sh" check 2>&1) || rc=$?
assert_exit_code "check without a stamp exits 1" "1" "$rc"
assert_contains "Asks for a stamp" "$output" "no **Checked:** stamp"

# Test 8: grounding conflicts are parsed from ## Grounding only
echo "Test 8: grounding conflicts"
cat > "$TMPDIR/task.md" << 'EOF'
# Task 1: Example

## Grounding

**Sources:** `GLOSSARY.md` (terms)
**Terms:**
- **Plan** — a named list of tasks.
**Conflicts:**
- Task says "epic"; glossary says "plan" → using "plan"

## Questions
- not a conflict
EOF
output=$(bash -c "source '$TMPDIR/docs/sprintbias/lib.sh'; sprintbias_grounding_conflicts '$TMPDIR/task.md'")
assert_contains "Reads the conflict line" "$output" 'glossary says "plan"'
if echo "$output" | grep -q 'not a conflict\|a named list'; then
    echo "  FAIL: picked up lines outside **Conflicts:**"
    FAIL=$((FAIL + 1))
else
    echo "  PASS: only **Conflicts:** bullets"
    PASS=$((PASS + 1))
fi
sed -i.bak 's/^- Task says.*/- None found./' "$TMPDIR/task.md"
output=$(bash -c "source '$TMPDIR/docs/sprintbias/lib.sh'; sprintbias_grounding_conflicts '$TMPDIR/task.md'")
if [ -z "$output" ]; then
    echo "  PASS: 'None found.' yields nothing"
    PASS=$((PASS + 1))
else
    echo "  FAIL: 'None found.' reported as a conflict"
    FAIL=$((FAIL + 1))
fi

# Test 9: doc follow-ups become one backlog task, each line filed once
echo "Test 9: doc follow-ups"
setup
cp "$SPRINTBIAS_SRC/scripts/create-task.sh" "$TMPDIR/docs/sprintbias/scripts/"
mkdir -p "$TMPDIR/docs/tasks/"{backlog,next,doing,review,done,blocked}
cp "$SPRINTBIAS_SRC/../tasks/.TEMPLATE-task.md" "$TMPDIR/docs/tasks/"
printf '# State\n**sprint_TASK_ID**: 10\n**Last Updated**: 2026-01-01\n' > "$TMPDIR/docs/sprintbias/DOC_STATE.md"
cat > "$TMPDIR/docs/tasks/review/7-add-plans.md" << 'EOF'
# Task 7: Add plans

## Completed

### Files changed
src/plan.sh

### Doc follow-ups
- `GLOSSARY.md` — add "plan"
EOF
_collect() { ( cd "$TMPDIR" && bash -c 'source docs/sprintbias/lib.sh; sprintbias_file_doc_followups' 2>&1 ); }
output=$(_collect)
assert_contains "Files the follow-up" "$output" "Filed 1 doc follow-up(s)"
_tracker=$(ls "$TMPDIR"/docs/tasks/backlog/*.md 2>/dev/null | head -1)
assert_contains "Tracker carries the item and its source" "$(cat "$_tracker")" '`GLOSSARY.md` — add "plan" (from #7)'
output=$(_collect)
if [ -z "$output" ] && [ "$(grep -c 'from #7' "$_tracker")" = "1" ]; then
    echo "  PASS: re-run files nothing new"
    PASS=$((PASS + 1))
else
    echo "  FAIL: re-run duplicated follow-ups ($output)"
    FAIL=$((FAIL + 1))
fi
_files=$(( $(awk '/^### Files changed/{f=1;next} /^#/{f=0} f && NF' "$TMPDIR/docs/tasks/review/7-add-plans.md" | wc -l) ))
assert_exit_code "Files changed list stays separate" "1" "$_files"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
