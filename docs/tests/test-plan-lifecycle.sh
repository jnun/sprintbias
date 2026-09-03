#!/usr/bin/env bash
# Test: plan lifecycle — plan start STARTED latch + plan done audit/delete
# Covers task 290 SC1:
#   - plan start stamps **Status:** STARTED (one-way, no duplicate line on re-run)
#   - plan done refuses (exit 1, plan intact) when any member is not in done/
#   - plan done deletes the plan file when every member is in done/
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
    if echo "$haystack" | grep -qF "$needle"; then
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

# --- Test 3: plan done deletes the plan when every member is in done/ ---
echo "Test 3: plan done deletes the plan file once every member is in done/"
setup
plan=$(make_plan 102 STARTED "- [x] #503 — a" "- [x] #504 — b")
make_task 503 done
make_task 504 done
if (cd "$TMPDIR" && bash docs/sprintbias/scripts/plan.sh done 102 >/dev/null 2>&1); then
    echo "  PASS: plan done exits zero when all members are in done/"; PASS=$((PASS + 1))
else
    echo "  FAIL: plan done should exit zero when all members are in done/"; FAIL=$((FAIL + 1))
fi
assert_eq "Plan file deleted on full pass" "true" "$([ -f "$plan" ] && echo false || echo true)"

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
assert_eq "Plan file deleted after dedup pass" "true" "$([ -f "$plan" ] && echo false || echo true)"

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

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
