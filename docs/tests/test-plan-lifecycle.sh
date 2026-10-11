#!/usr/bin/env bash
# Test: plan lifecycle — plan start STARTED latch + plan done audit/delete
# Covers task 290 SC1:
#   - plan start stamps **Status:** STARTED (one-way, no duplicate line on re-run)
#   - plan done refuses (exit 1, plan intact) when any member is not in done/
#   - plan done retires the plan file into a docs/history/ record when every
#     member is in done/ (task 421: record shape, summaries, refusal, failure)
#   - plan done dedups a member id listed twice (harmless when its one file is done/)

set -euo pipefail

PASS=0
FAIL=0
SPRINTBIAS_SRC="$(cd "$(dirname "$0")/../sprintbias" && pwd)"

# Fresh throwaway project with the whole sprintbias tree (plan-start.sh sources
# lib.sh + gate-lib.sh; lib.sh loads a cli/ provider profile). Copying the tree
# gives every runtime dependency without hand-picking files.
setup() {
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT
    mkdir -p "$TMPDIR/docs/plans"
    mkdir -p "$TMPDIR/docs/tasks"/{backlog,next,doing,review,done,blocked}
    cp -R "$SPRINTBIAS_SRC" "$TMPDIR/docs/sprintbias"
    git -C "$TMPDIR" init -q
}

# Write a plan file with the given id, status, and member bullet lines (each a
# full "- [ ] #ID — title" string passed as a trailing arg).
make_plan() {
    local id="$1" status="$2"; shift 2
    local f="$TMPDIR/docs/plans/${id}-throwaway.md"
    {
        echo "# Plan ${id}: Throwaway"
        echo ""
        echo "**Status:** ${status}"
        echo ""
        echo "## Goal"
        echo "Exercise the plan lifecycle."
        echo ""
        echo "## Members"
        local line
        for line in "$@"; do echo "$line"; done
    } > "$f"
    printf '%s' "$f"
}

# Create a task file for member ID in the given lifecycle folder.
# Optional $3 = Depends-on value (default none). Optional $4 = READY stamp.
make_task() {
    local id="$1" folder="$2" deps="${3:-none}" ready="${4:-}"
    {
        printf '# Task %s: member\n\n' "$id"
        printf '**Depends on**: %s\n' "$deps"
        if [ "$ready" = "READY" ]; then
            printf '\n## Questions\n\n**Status: READY**\n'
        fi
    } > "$TMPDIR/docs/tasks/$folder/${id}-member.md"
}

assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    # -- so needles that start with '-' (e.g. "--model needs…") are not flags.
    if grep -qF -- "$needle" <<<"$haystack"; then
        echo "  PASS: $desc"; PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected to contain '$needle')"; FAIL=$((FAIL + 1))
    fi
}

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "  PASS: $desc"; PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected '$expected', got '$actual')"; FAIL=$((FAIL + 1))
    fi
}

echo "=== test-plan-lifecycle.sh ==="

# --- Test 1: plan start stamps STARTED (one-way, idempotent) ---
echo "Test 1: plan start stamps STARTED and never duplicates the status line"
setup
make_plan 100 READY "- [ ] #500 — member" >/dev/null
make_task 500 backlog
(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan.sh start 100 --commit-only >/dev/null 2>&1)
plan="$TMPDIR/docs/plans/100-throwaway.md"
assert_contains "Status flipped to STARTED" "$(cat "$plan")" '**Status:** STARTED'
assert_eq "Member promoted into next/" "true" "$([ -f "$TMPDIR/docs/tasks/next/500-member.md" ] && echo true || echo false)"
# The latch is a set-or-replace of the single status line, so it replaces the
# prior READY line rather than appending — exactly one **Status:** line remains.
count=$(grep -c '^\*\*Status:\*\*' "$plan" || true)
assert_eq "Exactly one **Status:** line (replaced, not appended)" "1" "$count"

# --- Test 2: plan done refuses when a member is not in done/ ---
echo "Test 2: plan done exits non-zero and leaves the plan intact when a member is outside done/"
setup
plan=$(make_plan 101 STARTED "- [x] #501 — done member" "- [x] #502 — review member")
make_task 501 done
make_task 502 review    # in review/, not done/ → must fail
if (cd "$TMPDIR" && bash docs/sprintbias/scripts/plan.sh done 101 >/dev/null 2>&1); then
    echo "  FAIL: plan done should exit non-zero with a member in review/"; FAIL=$((FAIL + 1))
else
    echo "  PASS: plan done exits non-zero with a member in review/"; PASS=$((PASS + 1))
fi
assert_eq "Plan file left intact on failure" "true" "$([ -f "$plan" ] && echo true || echo false)"

# --- Test 3: plan done removes the plan when every member is in done/ ---
echo "Test 3: plan done removes the plan file once every member is in done/"
setup
plan=$(make_plan 102 STARTED "- [x] #503 — a" "- [x] #504 — b")
make_task 503 done
make_task 504 done
if (cd "$TMPDIR" && bash docs/sprintbias/scripts/plan.sh done 102 >/dev/null 2>&1); then
    echo "  PASS: plan done exits zero when all members are in done/"; PASS=$((PASS + 1))
else
    echo "  FAIL: plan done should exit zero when all members are in done/"; FAIL=$((FAIL + 1))
fi
assert_eq "Plan file removed on full pass" "true" "$([ -f "$plan" ] && echo false || echo true)"

# --- Test 4: plan done dedups a member id listed twice ---
echo "Test 4: a member id listed twice is deduped, not treated as two required files"
setup
plan=$(make_plan 103 STARTED "- [x] #505 — first mention" "- [x] #505 grep report — duplicate mention")
make_task 505 done   # ONE file for the id that appears on two member lines
if (cd "$TMPDIR" && bash docs/sprintbias/scripts/plan.sh done 103 >/dev/null 2>&1); then
    echo "  PASS: plan done passes with a deduped duplicate member id"; PASS=$((PASS + 1))
else
    echo "  FAIL: duplicate member id should dedup to one required file"; FAIL=$((FAIL + 1))
fi
assert_eq "Plan file removed after dedup pass" "true" "$([ -f "$plan" ] && echo false || echo true)"

# --- Test 5: STARTED re-run demotes unstamped next/ → backlog (self-heal) ---
echo "Test 5: unstamped next/ member is demoted to backlog on plan start"
setup
make_plan 104 STARTED "- [ ] #506 — member" >/dev/null
make_task 506 next
out=$(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan.sh start 104 --commit-only 2>&1) || {
    echo "  FAIL: plan start on STARTED should exit 0 non-interactively"
    echo "$out"
    FAIL=$((FAIL + 1))
    out=""
}
if [ -n "$out" ]; then
    assert_contains "Mentions already STARTED" "$out" "already STARTED"
    assert_contains "Demotes not-READY next/ to backlog" "$out" "not READY → backlog/"
    assert_eq "File left next/" "false" \
      "$([ -f "$TMPDIR/docs/tasks/next/506-member.md" ] && echo true || echo false)"
    assert_eq "File now in backlog/" "true" \
      "$([ -f "$TMPDIR/docs/tasks/backlog/506-member.md" ] && echo true || echo false)"
    assert_eq "Still STARTED after re-run" "STARTED" \
      "$(grep -m1 '^\*\*Status:\*\*' "$TMPDIR/docs/plans/104-throwaway.md" | sed 's/.*\*\*Status:\*\*[[:space:]]*//' | tr -d '[:space:]')"
fi

# --- Test 6: non-interactive DRAFT still refuses ---
echo "Test 6: non-interactive plan start refuses DRAFT plans"
setup
make_plan 105 DRAFT "- [ ] #507 — member" >/dev/null
make_task 507 backlog
if (cd "$TMPDIR" && bash docs/sprintbias/scripts/plan.sh start 105 --commit-only >/dev/null 2>&1); then
    echo "  FAIL: non-interactive DRAFT start should exit non-zero"; FAIL=$((FAIL + 1))
else
    echo "  PASS: non-interactive DRAFT start exits non-zero"; PASS=$((PASS + 1))
fi
assert_eq "DRAFT plan left unstarted" "DRAFT" \
  "$(grep -m1 '^\*\*Status:\*\*' "$TMPDIR/docs/plans/105-throwaway.md" | sed 's/.*\*\*Status:\*\*[[:space:]]*//' | tr -d '[:space:]')"

# --- Test 7: stamped READY next/ member stays put ---
echo "Test 7: next/ member already stamped READY stays in next/"
setup
make_plan 106 STARTED "- [ ] #508 — ready member" >/dev/null
make_task 508 next none READY
out=$(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan.sh start 106 --commit-only 2>&1) || {
    echo "  FAIL: plan start should exit 0 for stamped next/ member"
    echo "$out"
    FAIL=$((FAIL + 1))
    out=""
}
if [ -n "$out" ]; then
    assert_contains "Notices already READY in next/" "$out" "already in next/ (READY)"
    assert_eq "Stamped READY stays in next/" "true" \
      "$([ -f "$TMPDIR/docs/tasks/next/508-member.md" ] && echo true || echo false)"
    assert_eq "Stamped READY not demoted to backlog/" "false" \
      "$([ -f "$TMPDIR/docs/tasks/backlog/508-member.md" ] && echo true || echo false)"
fi

# --- Test 8: large plan promotes every member (no hard cap); warn over 10 ---
echo "Test 8: plan start promotes all members (12) and soft-warns over 10"
setup
_bullets=()
for i in $(seq 600 611); do
  make_task "$i" backlog
  _bullets+=("- [ ] #$i — member $i")
done
make_plan 107 READY "${_bullets[@]}" >/dev/null
out=$(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan.sh start 107 --commit-only 2>&1) || {
  echo "  FAIL: plan start on 12-member plan should exit 0"
  echo "$out"
  FAIL=$((FAIL + 1))
  out=""
}
if [ -n "$out" ]; then
  assert_contains "Soft-warns when member count exceeds 10" "$out" "has 12 members"
  assert_contains "Names no hard cap" "$out" "no hard member cap"
  _moved=0
  for i in $(seq 600 611); do
    [ -f "$TMPDIR/docs/tasks/next/${i}-member.md" ] && _moved=$((_moved + 1))
  done
  assert_eq "All 12 members promoted into next/" "12" "$_moved"
  assert_contains "Summary names total member count" "$out" "12 members"
fi

# --- Test 9: member depending on outside-plan backlog dep is held ---
echo "Test 9: member with Depends on outside the plan (backlog) stays in backlog/"
setup
make_plan 108 READY "- [ ] #620 — dependent" >/dev/null
make_task 620 backlog "630"
make_task 630 backlog   # prereq exists but is NOT a plan member
out=$(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan.sh start 108 --commit-only 2>&1) || {
  echo "  FAIL: plan start should exit 0 when holding an unworkable member"
  echo "$out"
  FAIL=$((FAIL + 1))
  out=""
}
if [ -n "$out" ]; then
  assert_contains "Hold message names deps not in sprint" "$out" "held (deps not in sprint)"
  assert_contains "Hold message names the outside dep" "$out" "#630 (backlog/)"
  assert_eq "Dependent left in backlog/" "true" \
    "$([ -f "$TMPDIR/docs/tasks/backlog/620-member.md" ] && echo true || echo false)"
  assert_eq "Dependent not promoted to next/" "false" \
    "$([ -f "$TMPDIR/docs/tasks/next/620-member.md" ] && echo true || echo false)"
  assert_eq "Outside dep left untouched in backlog/" "true" \
    "$([ -f "$TMPDIR/docs/tasks/backlog/630-member.md" ] && echo true || echo false)"
fi

# --- Test 10: co-promote members that depend on each other both enter next/ ---
echo "Test 10: co-promote A→B both in the plan both land in next/"
setup
make_plan 109 READY "- [ ] #640 — prereq" "- [ ] #641 — dependent" >/dev/null
make_task 640 backlog none
make_task 641 backlog "640"
out=$(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan.sh start 109 --commit-only 2>&1) || {
  echo "  FAIL: plan start should exit 0 for co-promote chain"
  echo "$out"
  FAIL=$((FAIL + 1))
  out=""
}
if [ -n "$out" ]; then
  assert_eq "Prereq promoted to next/" "true" \
    "$([ -f "$TMPDIR/docs/tasks/next/640-member.md" ] && echo true || echo false)"
  assert_eq "Dependent co-promoted to next/" "true" \
    "$([ -f "$TMPDIR/docs/tasks/next/641-member.md" ] && echo true || echo false)"
fi

# --- Test 11: dep already in next/ allows dependent promote ---
echo "Test 11: dependent promotes when its dep is already READY in next/"
setup
make_plan 110 READY "- [ ] #650 — dependent" >/dev/null
make_task 650 backlog "651"
make_task 651 next none READY
out=$(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan.sh start 110 --commit-only 2>&1) || {
  echo "  FAIL: plan start should exit 0 when dep is already in next/"
  echo "$out"
  FAIL=$((FAIL + 1))
  out=""
}
if [ -n "$out" ]; then
  assert_eq "Dependent promoted because dep is in next/" "true" \
    "$([ -f "$TMPDIR/docs/tasks/next/650-member.md" ] && echo true || echo false)"
  assert_eq "Existing dep stayed in next/" "true" \
    "$([ -f "$TMPDIR/docs/tasks/next/651-member.md" ] && echo true || echo false)"
fi

# --- Test 12: READY next/ member demoted when dep sits in backlog outside ---
echo "Test 12: READY next/ member with outside backlog dep is demoted"
setup
make_plan 111 STARTED "- [ ] #660 — dependent" >/dev/null
make_task 660 next "661" READY
make_task 661 backlog
out=$(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan.sh start 111 --commit-only 2>&1) || {
  echo "  FAIL: plan start should exit 0 when demoting unworkable next/ member"
  echo "$out"
  FAIL=$((FAIL + 1))
  out=""
}
if [ -n "$out" ]; then
  assert_contains "Demotes next/ member with outside dep" "$out" "demoted next/ → backlog/"
  assert_eq "Dependent demoted to backlog/" "true" \
    "$([ -f "$TMPDIR/docs/tasks/backlog/660-member.md" ] && echo true || echo false)"
  assert_eq "Dependent no longer in next/" "false" \
    "$([ -f "$TMPDIR/docs/tasks/next/660-member.md" ] && echo true || echo false)"
fi

# --- Test: plan start accepts --model (pin for gate; no silent ignore) ---
echo "Test: plan start --model is accepted with --commit-only (no AI)"
setup
make_plan 110 READY "- [ ] #710 — member" >/dev/null
make_task 710 backlog
out=$(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan.sh start 110 --commit-only --model claude-opus-4-8 2>&1) && rc=0 || rc=$?
assert_eq "plan start --model --commit-only exits 0" "0" "$rc"
assert_eq "Member still promoted with --model present" "true" \
  "$([ -f "$TMPDIR/docs/tasks/next/710-member.md" ] && echo true || echo false)"
# Unknown flag must fail loudly (regression: --model used to be silently dropped).
out=$(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan.sh start 110 --commit-only --not-a-flag 2>&1) && rc=0 || rc=$?
assert_eq "Unknown flag exits non-zero" "1" "$rc"
assert_contains "Unknown flag names itself" "$out" "Unknown flag"

# --model without a value must fail.
setup
make_plan 111 READY "- [ ] #711 — member" >/dev/null
make_task 711 backlog
out=$(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan.sh start 111 --commit-only --model 2>&1) && rc=0 || rc=$?
assert_eq "--model without id exits non-zero" "1" "$rc"
assert_contains "--model needs a model id" "$out" "--model needs a model id"

# --- newplan backlog: every unplanned backlog task, plan READY ---
echo "Test: newplan <name> backlog binds unplanned backlog tasks and marks READY"
setup
cp "$SPRINTBIAS_SRC/../plans/.TEMPLATE-plan.md" "$TMPDIR/docs/plans/"
printf '# State\n**sprint_TASK_ID**: 12\n**sprint_PLAN_ID**: 4\n**Last Updated**: 2026-01-01\n' \
  > "$TMPDIR/docs/sprintbias/DOC_STATE.md"
for _i in 10 3; do printf '# Task %s: thing\n\n**Plan**: none\n' "$_i" > "$TMPDIR/docs/tasks/backlog/${_i}-thing.md"; done
printf '# Task 12: planned\n\n**Plan**: 2\n' > "$TMPDIR/docs/tasks/backlog/12-planned.md"
out=$(cd "$TMPDIR" && bash docs/sprintbias/scripts/create-plan.sh "Clear the backlog" backlog </dev/null 2>&1) || true
_pf=$(ls "$TMPDIR"/docs/plans/5-*.md 2>/dev/null | head -1)
assert_contains "binds unplanned members lowest first" "$out" "Members: 3 10"
assert_eq "skips a task already in a plan" "0" "$(grep -c '#12' "$_pf" || true)"
assert_eq "member lines sit under ## Member tasks, before ## Signoff" "- #3 — thing" \
  "$(awk '/^## Member tasks/ { m = 1 } /^## Signoff/ { m = 0 } m && /^- #/ { print; exit }' "$_pf")"
assert_eq "plan with bound members is READY" "READY" \
  "$(grep -m1 '^\*\*Status:\*\*' "$_pf" | sed 's/.*\*\*Status:\*\*[[:space:]]*//' | tr -d '[:space:]')"
rc=0
out=$(cd "$TMPDIR" && bash docs/sprintbias/scripts/create-plan.sh "Again" backlog </dev/null 2>&1) || rc=$?
assert_eq "nothing unplanned left exits non-zero" "1" "$rc"
assert_contains "says why" "$out" "no tasks outside a plan"
out=$(cd "$TMPDIR" && bash docs/sprintbias/scripts/create-plan.sh "Empty" </dev/null 2>&1) || true
assert_eq "plan created empty stays DRAFT" "DRAFT" \
  "$(grep -m1 '^\*\*Status:\*\*' "$TMPDIR"/docs/plans/6-*.md | sed 's/.*\*\*Status:\*\*[[:space:]]*//' | tr -d '[:space:]')"

# --- follow-ups: plan done names them, newplan from:N groups them ---
echo "Test: plan done points at follow-ups; newplan from:N groups only those"
setup
cp "$SPRINTBIAS_SRC/../plans/.TEMPLATE-plan.md" "$TMPDIR/docs/plans/"
printf '# State\n**sprint_TASK_ID**: 22\n**sprint_PLAN_ID**: 24\n**Last Updated**: 2026-01-01\n' \
  > "$TMPDIR/docs/sprintbias/DOC_STATE.md"
printf '# Plan 24: Tighten login\n\n**Status:** STARTED\n\n## Members\n- [x] #5 — a\n' > "$TMPDIR/docs/plans/24-tighten-login.md"
printf '# Task 5: a\n\n**Plan**: 24\n' > "$TMPDIR/docs/tasks/done/5-a.md"
printf '# Task 21: rework\n\n**Plan**: none\n**From plan**: 24\n' > "$TMPDIR/docs/tasks/backlog/21-rework.md"
printf '# Task 22: enh\n\n**Plan**: none\n**From plan**: 24\n' > "$TMPDIR/docs/tasks/blocked/22-enh.md"
printf '# Task 23: other\n\n**Plan**: 30\n**From plan**: 24\n' > "$TMPDIR/docs/tasks/backlog/23-other.md"
printf '# Task 9: unrelated\n\n**Plan**: none\n' > "$TMPDIR/docs/tasks/backlog/9-unrelated.md"
out=$(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan-done.sh 24 </dev/null 2>&1) || true
assert_contains "plan done counts follow-ups" "$out" "2 follow-up task(s) came out of this plan"
assert_contains "plan done prints the grouping command" "$out" 'newplan "Tighten login — follow-ups" from:24'
out=$(cd "$TMPDIR" && bash docs/sprintbias/scripts/create-plan.sh "Tighten login — follow-ups" from:24 </dev/null 2>&1) || true
assert_contains "from:N binds only plan 24's unbound follow-ups" "$out" "Members: 21 22"
rc=0
out=$(cd "$TMPDIR" && bash docs/sprintbias/scripts/create-plan.sh "Again" from:24 </dev/null 2>&1) || rc=$?
assert_eq "from:N with nothing left exits non-zero" "1" "$rc"

# --- Plan states (plan 28 Policy): open / landed / signed off, computed ---
# land_task ID: a review/ member with a passing proof line under ## Completed.
land_task() {
    printf '# Task %s: member\n\n**Depends on**: none\n\n## Completed\n\n### Files changed\nx.sh\n\n**Proof**: 2026-10-08 · bash t.sh · pass\n' \
        "$1" > "$TMPDIR/docs/tasks/review/${1}-member.md"
}
plan_check() { (cd "$TMPDIR" && bash docs/sprintbias/scripts/plan-check.sh "$1" </dev/null 2>&1) || true; }
plan_status() { (cd "$TMPDIR" && NO_COLOR=1 bash sprint.sh status </dev/null 2>&1) || true; }
latch_of() { grep -m1 '^\*\*Status:\*\*' "$1" | sed 's/.*\*\*Status:\*\*[[:space:]]*//' | tr -d '[:space:]'; }

echo "Test: every member landed → LANDED, three counts, never stalled; plan done refuses"
setup
cp "$SPRINTBIAS_SRC/../../sprint.sh" "$TMPDIR/sprint.sh"
plan=$(make_plan 120 STARTED "- [ ] #820 — a" "- [ ] #821 — b")
land_task 820; land_task 821
out=$(plan_check 120)
assert_contains "plan check reads LANDED" "$out" "Plan state:  LANDED"
assert_contains "plan check prints the three counts" "$out" "open 0 · landed 2 · signed off 0  (of 2)"
assert_contains "plan check points at sign-off" "$out" "Every member landed"
out=$(plan_status)
assert_contains "status reads LANDED with the counts" "$out" "→ LANDED · open 0 · landed 2 · signed off 0 (of 2)"
assert_eq "state is computed, latch unchanged" "STARTED" "$(latch_of "$plan")"
assert_eq "no LANDED stamp written into the plan" "0" "$(grep -c 'LANDED' "$plan" || true)"
if (cd "$TMPDIR" && bash docs/sprintbias/scripts/plan.sh done 120 >/dev/null 2>&1); then
    echo "  FAIL: plan done must refuse a plan that is landed but not signed off"; FAIL=$((FAIL + 1))
else
    echo "  PASS: plan done refuses a landed plan (needs done/)"; PASS=$((PASS + 1))
fi

echo "Test: review/ without proof → STARTED and flagged in review, unproven"
setup
cp "$SPRINTBIAS_SRC/../../sprint.sh" "$TMPDIR/sprint.sh"
make_plan 121 STARTED "- [ ] #830 — a" "- [ ] #831 — b" "- [ ] #832 — c" >/dev/null
land_task 830
make_task 831 review
make_task 832 backlog
out=$(plan_check 121)
assert_contains "unproven member keeps the plan STARTED" "$out" "Plan state:  STARTED"
assert_contains "counts: open / landed / signed off + unproven" "$out" "open 1 · landed 1 · signed off 0  (of 3) · in review, unproven 1"
assert_contains "plan check flags the unproven member" "$out" "in review, unproven (review/, no **Proof**: line): #831"
out=$(plan_status)
assert_contains "status flags the unproven member" "$out" "⚠ in review, unproven: #831"
assert_contains "status reads STARTED" "$out" "→ STARTED · open 1 · landed 1 · signed off 0 (of 3)"

echo "Test: every member in done/ → SIGNED OFF"
setup
cp "$SPRINTBIAS_SRC/../../sprint.sh" "$TMPDIR/sprint.sh"
make_plan 122 STARTED "- [x] #840 — a" "- [x] #841 — b" >/dev/null
make_task 840 done; make_task 841 done
out=$(plan_check 122)
assert_contains "plan check reads SIGNED OFF" "$out" "Plan state:  SIGNED OFF"
assert_contains "signed-off counts" "$out" "open 0 · landed 0 · signed off 2  (of 2)"
assert_contains "status reads SIGNED OFF" "$(plan_status)" "→ SIGNED OFF · open 0 · landed 0 · signed off 2 (of 2)"

echo "Test: an open fix task (**Fixes**: #N) is flagged and holds the plan out of LANDED"
setup
cp "$SPRINTBIAS_SRC/../../sprint.sh" "$TMPDIR/sprint.sh"
make_plan 123 STARTED "- [ ] #850 — a" >/dev/null
land_task 850
printf '# Task 851: fix\n\n**Fixes**: #850\n' > "$TMPDIR/docs/tasks/backlog/851-fix.md"
out=$(plan_check 123)
assert_contains "open fix keeps the plan STARTED" "$out" "Plan state:  STARTED"
assert_contains "plan check flags the open fix" "$out" "#851 fixes #850 — in backlog/"
assert_contains "status flags the open fix" "$(plan_status)" "⚠ open fix #851 for #850"

echo "Test: a held original (**Held**: fix #N) reads held with proof, unproven without"
setup
cp "$SPRINTBIAS_SRC/../../sprint.sh" "$TMPDIR/sprint.sh"
make_plan 125 STARTED "- [ ] #870 — a" "- [ ] #871 — b" "- [ ] #872 — c" >/dev/null
land_task 870
printf '# Task 870: member\n\n**Depends on**: none\n**Held**: fix #880\n\n## Completed\n\n### Files changed\nx.sh\n\n**Proof**: 2026-10-08 · bash t.sh · pass\n' \
    > "$TMPDIR/docs/tasks/review/870-member.md"
printf '# Task 871: member\n\n**Depends on**: none\n**Held**: fix #881\n' > "$TMPDIR/docs/tasks/review/871-member.md"
land_task 872
printf '# Task 880: fix\n\n**Fixes**: #870\n' > "$TMPDIR/docs/tasks/backlog/880-fix.md"
printf '# Task 881: fix\n\n**Fixes**: #871\n' > "$TMPDIR/docs/tasks/next/881-fix.md"
standing() { (cd "$TMPDIR" && source docs/sprintbias/lib.sh && sprintbias_member_standing "$1"); }
assert_eq "held with proof → held" "held" "$(standing 870)"
assert_eq "held without proof → unproven" "unproven" "$(standing 871)"
assert_eq "proof, no hold → landed" "landed" "$(standing 872)"
assert_eq "held label names the open fix" "held: fix #880" \
    "$(cd "$TMPDIR" && source docs/sprintbias/lib.sh && sprintbias_held_label 870)"
out=$(plan_check 125)
assert_contains "held member keeps the plan STARTED" "$out" "Plan state:  STARTED"
assert_contains "counts: held apart from unproven" "$out" "open 0 · landed 1 · signed off 0  (of 3) · held 1 · in review, unproven 1"
assert_contains "member table shows held: fix #N" "$out" "held: fix #880"
assert_contains "plan check lists held apart" "$out" "#870 held: fix #880"
assert_contains "plan check still flags the unproven member" "$out" "in review, unproven (review/, no **Proof**: line): #871"
if grep -qF "#870" <<<"$(grep -F "no **Proof**: line" <<<"$out")"; then
    echo "  FAIL: held member must not be called unproven"; FAIL=$((FAIL + 1))
else
    echo "  PASS: held member is not called unproven"; PASS=$((PASS + 1))
fi
out=$(plan_status)
assert_contains "status member line shows held: fix #N" "$out" "#870   review/  held: fix #880"
assert_contains "status flags held apart" "$out" "⚠ held, waiting on its fix: #870 (held: fix #880)"
assert_contains "status still flags the unproven member" "$out" "⚠ in review, unproven: #871"
# Every fix lands → the original reads landed again (sprintbias_dep_landed).
rm "$TMPDIR/docs/tasks/backlog/880-fix.md"; land_task 880
assert_eq "fix landed → original reads landed" "landed" "$(standing 870)"
make_plan 126 STARTED "- [ ] #870 — a" "- [ ] #872 — c" >/dev/null
assert_contains "held fix landed → plan can read LANDED" "$(plan_check 126)" "Plan state:  LANDED"

echo "Test: plan start gathers every person-only check into one human test in review/"
setup
cp "$SPRINTBIAS_SRC/../tasks/.TEMPLATE-task.md" "$TMPDIR/docs/tasks/.TEMPLATE-task.md"
f=$(make_plan 127 READY "- [ ] #890 — a" "- [ ] #891 — b")
printf '\n## Signoff (human)\n\n- [ ] Pair it with a real speaker\n' >> "$f"
make_task 890 backlog
printf '\n## Signoff (human)\n\n- [ ] The tone sounds right on the device\n' >> "$TMPDIR/docs/tasks/backlog/890-member.md"
make_task 891 backlog
out=$(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan.sh start 127 --commit-only 2>&1)
ht=$(ls "$TMPDIR"/docs/tasks/review/*-human-test-for-plan-127-*.md 2>/dev/null | head -1)
assert_eq "one human test in review/" "1" "$(ls "$TMPDIR"/docs/tasks/review/*-human-test-*.md 2>/dev/null | wc -l | tr -d ' ')"
assert_contains "start names it" "$out" "Human test: docs/tasks/review/"
assert_contains "it holds the plan's check" "$(cat "${ht:-/dev/null}")" "- [ ] Pair it with a real speaker"
assert_contains "and each member's, tagged" "$(cat "${ht:-/dev/null}")" "- [ ] #890: The tone sounds right on the device"
assert_contains "the plan lists it" "$(cat "$f")" "Human test for plan 127"
assert_eq "agent members still entered next/" "2" "$(ls "$TMPDIR"/docs/tasks/next/ | wc -l | tr -d ' ')"
(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan.sh start 127 --commit-only >/dev/null 2>&1)
assert_eq "a re-run makes no second human test" "1" "$(ls "$TMPDIR"/docs/tasks/review/*-human-test-*.md | wc -l | tr -d ' ')"
for id in 890 891; do
    mv "$TMPDIR"/docs/tasks/*/$id-member.md "$TMPDIR/docs/tasks/review/"
    printf '\n## Completed\n\n**Proof**: 2026-10-10 · bash x · pass\n' >> "$TMPDIR/docs/tasks/review/$id-member.md"
done
assert_contains "landed members make the plan LANDED while the human test waits" "$(plan_check 127)" "Plan state:  LANDED"
assert_contains "plan check points at the human test" "$(plan_check 127)" "Run the human test:"

echo "Test: a DRAFT plan with nothing moved reads not started"
setup
make_plan 124 DRAFT "- [ ] #860 — a" >/dev/null
make_task 860 backlog
assert_contains "not started while the latch is DRAFT" "$(plan_check 124)" "Plan state:  not started (DRAFT)"

# --- history record: plan done writes docs/history/<date>-plan-N-<slug>.md ---
echo "Test: plan done writes a history record before removing the plan"
setup
TODAY=$(date +%Y-%m-%d)
cat > "$TMPDIR/docs/plans/40-sharper-login.md" <<'PLAN'
# Plan 40: Sharper login

**Status:** STARTED

## Goal

Users log in with email and password.

## Why

<!-- Optional short rationale. -->

## Member tasks

<!-- One line per task. -->
- [ ] #601 — form
- [x] #602 — session
- #603 — errors

## Decided

- Decided: sessions last a day, because people log in daily.

## Signoff (human)

<!-- Optional. -->
PLAN
printf '# Task 601: Login form\n\n## Completed\n\n### Assumptions\n- one\n\n**Summary**: The login form takes email and password.\n\n### Files changed\na.sh\n' \
  > "$TMPDIR/docs/tasks/done/601-login-form.md"
printf '# Task 602: Session cookie\n\n## Completed\n\nSessions now persist for a day. Cookies are signed.\nSecond line.\n\n### Files changed\nb.sh\n' \
  > "$TMPDIR/docs/tasks/done/602-session-cookie.md"
printf '# Task 603: Error copy\n\n## Completed\n\n### Assumptions\n- Errors read plainly. Really.\n\n**Proof**: 2026-10-10 · bash x · pass\n' \
  > "$TMPDIR/docs/tasks/done/603-error-copy.md"
printf '# Task 610: Rate limit\n\n**Plan**: none\n**From plan**: 40\n' > "$TMPDIR/docs/tasks/backlog/610-rate-limit.md"
out=$(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan-done.sh 40 </dev/null 2>&1) || true
rec="$TMPDIR/docs/history/$TODAY-plan-40-sharper-login.md"
assert_eq "record written at docs/history/<date>-plan-N-<slug>.md" "true" "$([ -f "$rec" ] && echo true || echo false)"
assert_eq "plan file removed after the record" "false" "$([ -f "$TMPDIR/docs/plans/40-sharper-login.md" ] && echo true || echo false)"
body=$(cat "$rec" 2>/dev/null || true)
assert_eq "record opens with the plan heading" "# Plan 40: Sharper login" "$(head -1 <<<"$body")"
assert_contains "header line: finish date and member count" "$body" "**Finished**: $TODAY · **Members**: 3"
assert_contains "Goal copied" "$body" "Users log in with email and password."
assert_eq "empty Why (comment only) left out" "0" "$(grep -c '^## Why' <<<"$body" || true)"
assert_contains "Decided copied" "$body" "- Decided: sessions last a day, because people log in daily."
assert_eq "sections in order" "## Goal|## Decided|## What changed|## Follow-ups|" \
  "$(grep '^## ' <<<"$body" | tr '\n' '|')"
assert_contains "Summary line wins, even after ### Assumptions" "$body" \
  "- #601 — Login form: The login form takes email and password. (docs/tasks/done/601-login-form.md)"
assert_contains "else the first sentence of the opening prose" "$body" \
  "- #602 — Session cookie: Sessions now persist for a day. (docs/tasks/done/602-session-cookie.md)"
assert_contains "else title only (### Assumptions first, no prose)" "$body" \
  "- #603 — Error copy (docs/tasks/done/603-error-copy.md)"
assert_contains "follow-ups listed" "$body" "- #610 — Rate limit (docs/tasks/backlog/610-rate-limit.md)"
assert_eq "no proof lines or file lists in the record" "0" "$(grep -cE 'Proof|Files changed|a\.sh' <<<"$body" || true)"
assert_contains "prints a ready-to-paste changelog line" "$out" \
  "- Plan 40: Sharper login — see docs/history/$TODAY-plan-40-sharper-login.md"
assert_eq "writes no changelog file" "false" "$([ -e "$TMPDIR/CHANGELOG.md" ] && echo true || echo false)"
assert_contains "record is staged in a git work tree" "$(git -C "$TMPDIR" diff --cached --name-only)" \
  "docs/history/$TODAY-plan-40-sharper-login.md"

echo "Test: a plan with no follow-ups and no Decided leaves those sections out"
setup
plan=$(make_plan 41 STARTED "- [x] #620 — a")
make_task 620 done
(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan-done.sh 41 </dev/null >/dev/null 2>&1) || true
body=$(cat "$TMPDIR/docs/history/$TODAY-plan-41-throwaway.md" 2>/dev/null || true)
assert_eq "only Goal and What changed" "## Goal|## What changed|" "$(grep '^## ' <<<"$body" | tr '\n' '|')"

echo "Test: a refused plan done writes no record"
setup
plan=$(make_plan 42 STARTED "- [x] #630 — a" "- [x] #631 — b")
make_task 630 done
make_task 631 review
before=$(cat "$plan")
(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan-done.sh 42 </dev/null >/dev/null 2>&1) || true
assert_eq "no record on refusal" "0" "$(ls "$TMPDIR/docs/history" 2>/dev/null | wc -l | tr -d ' ')"
assert_eq "plan file untouched on refusal" "$before" "$(cat "$plan")"

echo "Test: a record that cannot be written keeps the plan and exits non-zero"
setup
plan=$(make_plan 43 STARTED "- [x] #640 — a")
make_task 640 done
before=$(cat "$plan")
: > "$TMPDIR/docs/history"     # a file where the folder should be → write fails
rc=0
(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan-done.sh 43 </dev/null >/dev/null 2>&1) || rc=$?
assert_eq "exits non-zero when the record fails" "1" "$rc"
assert_eq "plan file untouched when the record fails" "$before" "$(cat "$plan" 2>/dev/null)"

echo "Test: breaker — a wrapped Summary is kept whole, e.g. and all"
setup
plan=$(make_plan 44 STARTED "- [x] #650 — a")
printf '# Task 650: Dates\n\n## Completed\n\n**Summary**: Dates now read the e.g. ISO form, for someone reading\nthe project history.\n\n### Files changed\nx.sh\n' \
  > "$TMPDIR/docs/tasks/done/650-dates.md"
(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan-done.sh 44 </dev/null >/dev/null 2>&1) || true
assert_contains "Summary line joined across its wrap, not cut at a period" \
  "$(cat "$TMPDIR/docs/history/$TODAY-plan-44-throwaway.md" 2>/dev/null)" \
  "- #650 — Dates: Dates now read the e.g. ISO form, for someone reading the project history. (docs/tasks/done/650-dates.md)"

echo "Test: breaker — a plan with no # heading still retires, titled Plan N"
setup
printf '**Status:** STARTED\n\n## Goal\n\nShip it.\n\n## Members\n- [x] #660 — a\n' > "$TMPDIR/docs/plans/45-no-head.md"
make_task 660 done
rc=0
out=$(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan-done.sh 45 </dev/null 2>&1) || rc=$?
assert_eq "headless plan exits 0" "0" "$rc"
assert_eq "headless plan record heading falls back to Plan N" "# Plan 45: Plan 45" \
  "$(head -1 "$TMPDIR/docs/history/$TODAY-plan-45-no-head.md" 2>/dev/null)"

echo "Test: breaker — CRLF plan and task files read like LF ones"
setup
printf '# Plan 46: Windows\r\n\r\n**Status:** STARTED\r\n\r\n## Goal\r\n\r\nWorks on Windows.\r\n\r\n## Members\r\n- [x] #670 — a\r\n' \
  > "$TMPDIR/docs/plans/46-windows.md"
printf '# Task 670: Line endings\r\n\r\n## Completed\r\n\r\n**Summary**: CRLF files read the same.\r\n' \
  > "$TMPDIR/docs/tasks/done/670-line-endings.md"
(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan-done.sh 46 </dev/null >/dev/null 2>&1) || true
body=$(cat "$TMPDIR/docs/history/$TODAY-plan-46-windows.md" 2>/dev/null || true)
assert_eq "no carriage returns in the record" "0" "$(tr -cd '\r' <<<"$body" | wc -c | tr -d ' ')"
assert_contains "CRLF Goal copied" "$body" "Works on Windows."
assert_contains "CRLF member summary read" "$body" \
  "- #670 — Line endings: CRLF files read the same. (docs/tasks/done/670-line-endings.md)"

echo "Test: breaker — plan done twice: the second run finds no plan, the record stays"
setup
plan=$(make_plan 47 STARTED "- [x] #680 — a")
make_task 680 done
(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan-done.sh 47 </dev/null >/dev/null 2>&1) || true
first=$(cat "$TMPDIR/docs/history/$TODAY-plan-47-throwaway.md" 2>/dev/null || true)
rc=0
(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan-done.sh 47 </dev/null >/dev/null 2>&1) || rc=$?
assert_eq "second run exits 1 (no plan)" "1" "$rc"
assert_eq "record unchanged by the second run" "$first" "$(cat "$TMPDIR/docs/history/$TODAY-plan-47-throwaway.md" 2>/dev/null)"
assert_eq "no temp files left in docs/history" "1" "$(ls -A "$TMPDIR/docs/history" | wc -l | tr -d ' ')"

echo "Test: breaker — % and backslashes in plan and task text print literally"
setup
printf '# Plan 48: 100%% done\n\n**Status:** STARTED\n\n## Goal\n\nCut 50%% of C:\\\\temp.\n\n## Members\n- [x] #690 — a\n' \
  > "$TMPDIR/docs/plans/48-percent.md"
printf '# Task 690: %%s title\n\n## Completed\n\n**Summary**: Handles %%d and \\\\n literally.\n' > "$TMPDIR/docs/tasks/done/690-pct.md"
out=$(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan-done.sh 48 </dev/null 2>&1) || true
body=$(cat "$TMPDIR/docs/history/$TODAY-plan-48-percent.md" 2>/dev/null || true)
assert_eq "title with % kept" "# Plan 48: 100% done" "$(head -1 <<<"$body")"
assert_contains "Goal with % and backslash kept" "$body" 'Cut 50% of C:\\temp.'
assert_contains "member line with %s / %d kept" "$body" '- #690 — %s title: Handles %d and \\n literally.'
assert_contains "changelog line with % kept" "$out" "- Plan 48: 100% done — see"

echo "Test: breaker — a staged, uncommitted plan has its removal staged too"
setup
plan=$(make_plan 49 STARTED "- [x] #695 — a")
make_task 695 done
git -C "$TMPDIR" add docs/plans/49-throwaway.md
(cd "$TMPDIR" && bash docs/sprintbias/scripts/plan-done.sh 49 </dev/null >/dev/null 2>&1) || true
assert_eq "plan gone from the index, not left as AD" "" "$(git -C "$TMPDIR" status --short docs/plans)"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
