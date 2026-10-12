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
    if grep -qF "$needle" <<<"$haystack"; then
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

# Test 6b: the map's **Test:** line points at TEST_SUITE, which config defines
echo "Test 6b: map Test line ties to TEST_SUITE"
_test_line=$(grep -F '**Test:**' "$SCRIPT_UNDER_TEST" || true)
assert_contains "Test line names TEST_SUITE" "$_test_line" "TEST_SUITE"
assert_contains "Test line names the config file" "$_test_line" 'docs/sprintbias/config'
assert_contains "Scan looks at TEST_SUITE" "$(grep -F 'TEST_SUITE' "$SCRIPT_UNDER_TEST" | grep -v '\*\*Test:\*\*' || true)" "TEST_SUITE"
assert_contains "config defines TEST_SUITE" "$(grep -E '^TEST_SUITE=' "$SPRINTBIAS_SRC/config" || true)" "TEST_SUITE="

# Breaker: the template lines are inside a double-quoted prompt, so every
# backtick on them must be escaped or bash runs it as a command.
_raw=$(grep -nE '^\*\*Test:\*\*|TEST_SUITE in$|docs/sprintbias/config \(run once' "$SCRIPT_UNDER_TEST" || true)
if [ -n "$_raw" ] && ! sed 's/\\`//g' <<<"$_raw" | grep -q '`'; then
    echo "  PASS: Breaker: TEST_SUITE template lines escape every backtick"
    PASS=$((PASS + 1))
else
    echo "  FAIL: Breaker: unescaped backtick on a TEST_SUITE template line ($_raw)"
    FAIL=$((FAIL + 1))
fi
# Breaker: the rendered prompt (the string bash builds) reads the plain form.
_rendered=$(bash -c 'eval "printf %s \"$(sed -n "/^\*\*Test:\*\*/p" "$1")\""' _ "$SCRIPT_UNDER_TEST" 2>&1)
assert_contains "Breaker: rendered Test line reads plain backticks" "$_rendered" '**Test:** `...` — the full suite; set the same command as TEST_SUITE in `docs/sprintbias/config`'
# Breaker: the config the hint names really reads TEST_SUITE (set, then read back).
_cfgdir=$(mktemp -d); mkdir -p "$_cfgdir/docs/sprintbias"
sed 's/^TEST_SUITE=.*/TEST_SUITE=make test/' "$SPRINTBIAS_SRC/config" > "$_cfgdir/docs/sprintbias/config"
cp "$SPRINTBIAS_SRC/lib.sh" "$_cfgdir/docs/sprintbias/lib.sh"
_val=$(cd "$_cfgdir" && bash -c "source docs/sprintbias/lib.sh >/dev/null 2>&1; sprintbias_cfg TEST_SUITE" 2>/dev/null || true)
rm -rf "$_cfgdir"
assert_contains "Breaker: TEST_SUITE set as the hint says reads back" "$_val" "make test"

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
if grep -q 'make' <<<"$output"; then
    echo "  FAIL: a ## Commands entry was treated as a path"
    FAIL=$((FAIL + 1))
else
    echo "  PASS: ## Commands entries are not path-checked"
    PASS=$((PASS + 1))
fi

# Breaker: a map written from the template's **Test:** line (a config path after
# the command) still checks clean; the Commands path is never path-checked,
# even when docs/sprintbias/config is absent.
_map_ok=$(sed 's|^\*\*Test:\*\* `make`$|**Test:** `make test` — the full suite; set the same command as TEST_SUITE in `docs/sprintbias/config`|' "$TMPDIR/docs/sprintbias/project.md")
assert_contains "Breaker: fixture carries the template Test line" "$_map_ok" 'TEST_SUITE in `docs/sprintbias/config`'
printf '%s\n' "$_map_ok" > "$TMPDIR/docs/sprintbias/project.md"
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/profile.sh" check 2>&1) || rc=$?
if grep -q 'sprintbias/config' <<<"$output"; then
    echo "  FAIL: Breaker: the Test line's config path was path-checked ($output)"
    FAIL=$((FAIL + 1))
else
    echo "  PASS: Breaker: the Test line's config path is not path-checked"
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
if grep -q 'not a conflict\|a named list' <<<"$output"; then
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
# A resolved item stays filed: checked, with a note before the original text.
sed -i.bak 's/^- \[ \] `GLOSSARY.md`/- [x] Already true: GLOSSARY.md has it. `GLOSSARY.md`/' "$_tracker" && rm -f "$_tracker.bak"
output=$(_collect)
if [ -z "$output" ] && [ "$(grep -c 'from #7' "$_tracker")" = "1" ]; then
    echo "  PASS: a checked item is not filed again"
    PASS=$((PASS + 1))
else
    echo "  FAIL: checked item re-filed ($output)"
    FAIL=$((FAIL + 1))
fi
# A struck item stays filed: `- [x] ~~text~~ reason (from #N)`.
SB_STRUCK='- [x] ~~`GLOSSARY.md` — add "plan"~~ dropped: no glossary yet (from #7)' \
    awk '/from #7\)/ { print ENVIRON["SB_STRUCK"]; next } { print }' "$_tracker" > "$_tracker.tmp" && mv "$_tracker.tmp" "$_tracker"
assert_contains "Tracker line is struck" "$(cat "$_tracker")" '[x] ~~`GLOSSARY.md` — add "plan"~~ dropped'
output=$(_collect)
if [ -z "$output" ] && [ "$(grep -c 'from #7' "$_tracker")" = "1" ]; then
    echo "  PASS: a struck item is not filed again"
    PASS=$((PASS + 1))
else
    echo "  FAIL: struck item re-filed ($output)"
    FAIL=$((FAIL + 1))
fi
# The same text from #77 is a different follow-up: #7's line must not hide it.
sed 's/^# Task 7:/# Task 77:/' "$TMPDIR/docs/tasks/review/7-add-plans.md" > "$TMPDIR/docs/tasks/review/77-add-plans.md"
output=$(_collect)
assert_contains "Same text from #77 is filed (not matched by #7)" "$output" "Filed 1 doc follow-up(s)"
rm -f "$TMPDIR/docs/tasks/review/77-add-plans.md"
_files=$(( $(awk '/^### Files changed/{f=1;next} /^#/{f=0} f && NF' "$TMPDIR/docs/tasks/review/7-add-plans.md" | wc -l) ))
assert_exit_code "Files changed list stays separate" "1" "$_files"

# Test 10: the map points at invariants; Known edges stays the breakage record
echo "Test 10: invariants pointer"
_src=$(cat "$SCRIPT_UNDER_TEST")
assert_contains "Map format has an Invariants pointer" "$_src" '**Invariants:** \`...\` — rules every change keeps'
assert_contains "Scan looks for the invariants document" "$_src" "holds the project's invariants"
assert_contains "Rules stay out of Known edges" "$_src" "Rules never go under ## Known edges."

# Breaker: a map written in the new format round-trips through its neighbors —
# profile check path-checks the pointer, Known edges writers and counters
# leave the Invariants line alone.
echo "Test 10b: Breaker: Invariants line in a real map"
setup
mkdir -p "$TMPDIR/docs"
touch "$TMPDIR/docs/INVARIANTS.md"
cat > "$TMPDIR/docs/sprintbias/project.md" << 'EOF'
# Project Profile
**Language:** Bash

## Sources of truth
**Invariants:** `docs/INVARIANTS.md` — rules every change keeps
- not an edge: a stray list line under Sources of truth

**Checked:** 2026-10-11
EOF
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/profile.sh" check 2>&1) || rc=$?
assert_exit_code "Breaker: map with an existing Invariants pointer checks clean" "0" "$rc"
rm "$TMPDIR/docs/INVARIANTS.md"
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/profile.sh" check 2>&1) || rc=$?
assert_exit_code "Breaker: a missing Invariants document fails check" "1" "$rc"
assert_contains "Breaker: names the missing Invariants document" "$output" "docs/INVARIANTS.md"
touch "$TMPDIR/docs/INVARIANTS.md"

# Two edges, added before and after a Known edges section exists.
( cd "$TMPDIR" && source docs/sprintbias/lib.sh && SPRINTBIAS_PROJECT_MAP=docs/sprintbias/project.md \
    && sprintbias_add_known_edge 5 "empty ledger posts a zero entry" \
    && sprintbias_add_known_edge 6 "tenant id dropped on export" )
_map=$(cat "$TMPDIR/docs/sprintbias/project.md")
assert_contains "Breaker: Invariants line survives add_known_edge" "$_map" '**Invariants:** `docs/INVARIANTS.md` — rules every change keeps'
_inv_count=$(grep -c '^\*\*Invariants:\*\*' <<<"$_map")
assert_exit_code "Breaker: Invariants line stays single after two edges" "1" "$_inv_count"
_edges=$(awk '/^## / { in_k = ($0 ~ /^## Known edges/); next } in_k && /^- / { n++ } END { print n + 0 }' "$TMPDIR/docs/sprintbias/project.md")
assert_exit_code "Breaker: Known edges counts only the two edges" "2" "$_edges"
_inv_sec=$(awk '/^## / { sec = $0 } /^\*\*Invariants:/ { print sec }' "$TMPDIR/docs/sprintbias/project.md")
assert_contains "Breaker: Invariants stays under Sources of truth" "$_inv_sec" "## Sources of truth"
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/profile.sh" check 2>&1) || rc=$?
assert_exit_code "Breaker: map with Invariants and edges still checks clean" "0" "$rc"

# Breaker: rules kept in one section of a larger file. The format names the
# section after the backticked path, so profile check sees a real file.
_src=$(cat "$SCRIPT_UNDER_TEST")
assert_contains "Breaker: format shows the section form for Invariants" "$_src" '\`CLAUDE.md\` (## Invariants), never \`CLAUDE.md#invariants\`'
touch "$TMPDIR/CLAUDE.md"
sed -i.bak 's|^\*\*Invariants:\*\*.*|**Invariants:** `CLAUDE.md` (## Invariants) — rules every change keeps|' "$TMPDIR/docs/sprintbias/project.md"
rc=0
output=$(bash "$TMPDIR/docs/sprintbias/scripts/profile.sh" check 2>&1) || rc=$?
assert_exit_code "Breaker: section-form Invariants pointer checks clean" "0" "$rc"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
