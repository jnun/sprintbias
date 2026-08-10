#!/usr/bin/env bash
# Test: work completion path — hold messaging by stage + `## Outcome` stamps
# (task 332 / plan 15, theme C, over #330's surface).
#
# Two layers, both against a throwaway seeding of the glitch matrix
# (docs/tests/fixtures/dep-glitch-matrix, IDs 9000–9099), never the real board,
# no live AI:
#
#   1. The stage-aware hold-line + outcome-stamp helpers, sourced straight out of
#      the real work.sh so an assert tracks the shipped body (extracted by name,
#      not copied): _format_dep, _needs_clause, _stamp_outcome, _outcome_brief.
#   2. `work N` end to end for the two paths that resolve before any AI: a doing/
#      task is offered a resume, and a next/ task with an open prereq is held.
#
# Discovered by run-all.sh (test-*.sh). Pure shell.

set -euo pipefail

PASS=0
FAIL=0
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
SEED="$REPO/docs/tests/fixtures/dep-glitch-matrix/seed.sh"
WORK="$REPO/docs/sprintbias/scripts/work.sh"

export SPRINTBIAS_TODAY=2026-08-01

BOARD=$(mktemp -d)
trap 'rm -rf "$BOARD"' EXIT
bash "$SEED" "$BOARD" >/dev/null 2>&1
# shellcheck source=/dev/null
source "$REPO/docs/sprintbias/lib.sh"

# Pull one function verbatim from a script: its `name() {` line to the first
# column-0 `}`. Keeps the assert bound to the real source instead of a paste —
# if work.sh's body drifts, this test re-reads the new one on every run.
extract_fn() {  # NAME FILE
    awk -v fn="$1" '
        $0 ~ "^"fn"\\(\\) \\{" { grab = 1 }
        grab { print }
        grab && /^\}/ { exit }
    ' "$2"
}
for fn in _strip_outcome _stamp_outcome _outcome_brief _format_dep _needs_clause; do
    eval "$(extract_fn "$fn" "$WORK")"
done

cd "$BOARD"

assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if printf '%s' "$haystack" | grep -qF "$needle"; then
        echo "  PASS: $desc"; PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected to contain '$needle'; got '$haystack')"; FAIL=$((FAIL + 1))
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

echo "=== test-dep-work.sh ==="

# ── Hold messaging names the stage AND the next action ─────────────────
echo "_format_dep routes each prereq stage to its own action"
# backlog/ and blocked/ → not vetted / needs a decision → ./sprint.sh chat <id>
assert_contains "backlog prereq → chat <id>" "$(_format_dep 9009)" "chat 9009"
assert_contains "blocked prereq → chat <id>" "$(_format_dep 9008)" "chat 9008"
# doing/ splits three ways off the file itself, no fake ownership check:
assert_contains "doing incomplete → resume this run" "$(_format_dep 9006)" "resuming"
assert_contains "doing + ## Completed → route to review/" "$(_format_dep 9005)" "review/"
assert_contains "doing + failed Outcome → surfaces the result" "$(_format_dep 9007)" "failed"
# A blocked prereq with an incomplete Outcome names the reason, not a bare stage.
blk32="$(_format_dep 9032)"
assert_contains "blocked incomplete → shows Outcome result" "$blk32" "incomplete"
assert_contains "blocked incomplete → still offers chat" "$blk32" "chat 9032"
# A missing prereq is a loud broken ref, never a silent green.
assert_contains "missing prereq → broken ref, not silent" "$(_format_dep 9010)" "broken ref"

echo "_needs_clause renders a canary's whole unmet set through _format_dep"
# 9060 depends on the never-lifted backlog task 9009.
assert_contains "9060's needs clause points at chat 9009" \
    "$(_needs_clause docs/tasks/next/9060-*.md)" "chat 9009"

# ── `## Outcome` stamp on an incomplete / failed / blocked route ───────
echo "_stamp_outcome writes a durable, idempotent Outcome block a hold line can read"
stamp_probe() {  # RESULT REASON
    local f="$BOARD/docs/tasks/doing/9999-outcome-probe.md"
    printf '# Task 9999: Outcome probe\n\n**Depends on**: none\n\n## Notes\nbody\n' > "$f"
    _stamp_outcome "$f" "$1" "$2"
    printf '%s' "$f"
}
for res in incomplete failed blocked; do
    f="$(stamp_probe "$res" "synthetic $res reason")"
    body="$(cat "$f")"
    assert_contains "$res: writes the ## Outcome heading" "$body" "## Outcome"
    assert_contains "$res: records **Result**: $res" "$body" "**Result**: $res"
    assert_contains "$res: records the **Reason**" "$body" "synthetic $res reason"
    assert_contains "$res: stamps a dated **At**" "$body" "**At**: 2026-08-01"
    assert_eq "$res: _outcome_brief reads it back for a hold line" \
        "$res: synthetic $res reason" "$(_outcome_brief "$f")"
done
# Re-stamping replaces the block rather than appending a second one.
f="$(stamp_probe incomplete "first")"
_stamp_outcome "$f" failed "second"
assert_eq "a re-stamp leaves exactly one ## Outcome block" "1" \
    "$(grep -c '^## Outcome' "$f")"
assert_contains "the re-stamp reflects the latest result" "$(cat "$f")" "**Result**: failed"

# ── `work N` end to end for the pre-AI paths ───────────────────────────
echo "work N resolves the doing-resume and dependency-hold paths before any AI"
set +e
out="$(bash "$WORK" 9006 2>&1)"; rc=$?
set -e
assert_eq "a doing/ task without --force exits 1 (reclaim, don't clobber)" "1" "$rc"
assert_contains "…and offers the resume path" "$out" "work 9006 --force"

set +e
out="$(bash "$WORK" 9051 2>&1)"; rc=$?
set -e
assert_eq "a next/ task with an open prereq exits 0 (held, not failed)" "0" "$rc"
assert_contains "…and names the id it waits on" "$out" "9003"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
