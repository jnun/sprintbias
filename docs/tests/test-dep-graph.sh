#!/usr/bin/env bash
# Test: dependency-graph helpers (task 332 / plan 15, theme B).
#
# Hard asserts over the finished #328/#329/#331 surface so fold rewrite and
# stage classification cannot regress quietly. Runs against a throwaway seeding
# of the glitch matrix (docs/tests/fixtures/dep-glitch-matrix, IDs 9000–9099),
# never the real docs/tasks/. Sources the *repo* lib.sh so the asserts hit real
# product helpers, not copies. No live AI.
#
# Covers:
#   - sprintbias_classify_dep — missing vs folded vs archived-complete (never a
#     silent "unmet empty"), and its divergence from the older sprintbias_unmet_deps
#     walk (lib.sh: a missing prereq reads as satisfied there — asserted, not fixed)
#   - sprintbias_dependents_of — forward (Depends on) + reverse (Dependents/Blocks)
#   - sprintbias_ensure_reciprocal — adds the missing back-edge, idempotent
#   - sprintbias_rewrite_dep_id — fold A→B rewrites both ends, notes the kept file
#   - sprintbias_plan_index_drift — Plan reverse-index drift, both directions
#
# Discovered by run-all.sh (test-*.sh). Pure shell.

set -euo pipefail

PASS=0
FAIL=0
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
SEED="$REPO/docs/tests/fixtures/dep-glitch-matrix/seed.sh"

# Deterministic fold-note date so the kept-file marker asserts exactly.
export SPRINTBIAS_TODAY=2026-08-01

# Fresh throwaway board seeded from the fixture; helpers read docs/tasks/ from
# CWD, so we cd in after sourcing the repo lib.sh (the check-inventory pattern).
BOARD=$(mktemp -d)
trap 'rm -rf "$BOARD"' EXIT
bash "$SEED" "$BOARD" >/dev/null 2>&1
# shellcheck source=/dev/null
source "$REPO/docs/sprintbias/lib.sh"
cd "$BOARD"

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
        echo "  FAIL: $desc (expected to contain '$needle'; got '$haystack')"; FAIL=$((FAIL + 1))
    fi
}

assert_empty() {
    local desc="$1" actual="$2"
    if [ -z "$actual" ]; then
        echo "  PASS: $desc"; PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected empty, got '$actual')"; FAIL=$((FAIL + 1))
    fi
}

echo "=== test-dep-graph.sh ==="

# ── classify_dep: one honest token per class, never silent unmet-empty ──
echo "sprintbias_classify_dep distinguishes missing / folded / archived-complete"
# 9010 has no file anywhere. Default policy names it 'missing' (not '' → the
# old silent green); the archived-is-complete reading is opt-in via the arg.
assert_eq "missing id → 'missing' by default"        "missing" "$(sprintbias_classify_dep 9010)"
assert_eq "missing id → override to 'done' on request" "done"    "$(sprintbias_classify_dep 9010 done)"
# 9011 sits in backlog/ but carries a **Folded into**: 9012 marker — it must
# report 'folded', never its stale backlog stage (kept-but-folded ≠ open work).
assert_eq "folded tombstone → 'folded' (not its backlog stage)" "folded" "$(sprintbias_classify_dep 9011)"
assert_eq "fold target of 9011 is 9012" "9012" "$(sprintbias_fold_target "$(sprintbias_task_path 9011)")"
# Archived-complete prereqs report their real stage.
assert_eq "done prereq → 'done'"     "done"   "$(sprintbias_classify_dep 9001)"
assert_eq "review prereq → 'review'" "review" "$(sprintbias_classify_dep 9002)"

# Divergence from the older walk is real and in scope to pin (not to change):
# sprintbias_unmet_deps drops a missing id (9010) as satisfied so a stale ref can
# never wedge the queue, while classify_dep names it 'missing' for the human.
echo "the older sprintbias_unmet_deps walk still reads a missing prereq as met"
assert_empty  "9055's only dep (missing 9010) is dropped by unmet_deps" \
    "$(sprintbias_unmet_deps docs/tasks/next/9055-*.md)"
assert_eq     "…but classify_dep still flags that same id" "missing" \
    "$(sprintbias_classify_dep 9010)"

# ── dependents_of: forward edges ∪ declared reverse edges ──────────────
echo "sprintbias_dependents_of unions forward (Depends on) and reverse edges"
# 9017: 9016 depends on it (forward only — 9017's Blocks omits 9016, the one-way
# case); 9075 is on both ends. Both must surface.
dep17="$(sprintbias_dependents_of 9017 | tr '\n' ' ')"
assert_contains "forward-only dependent 9016 found for 9017" "$dep17" "9016"
assert_contains "reverse+forward dependent 9075 found for 9017" "$dep17" "9075"
# 9001 (done): named by several Depends on lines and lists them back in Blocks.
dep01="$(sprintbias_dependents_of 9001 | tr '\n' ' ')"
assert_contains "9050 depends on 9001" "$dep01" "9050"
assert_contains "9085 depends on 9001" "$dep01" "9085"

# ── ensure_reciprocal: add the missing back-edge, then no-op ───────────
echo "sprintbias_ensure_reciprocal closes a one-way edge and is idempotent"
# 9016 depends on 9017 but 9017's reverse field omits 9016. Make it reciprocal.
changed="$(sprintbias_ensure_reciprocal 9017 9016)"
assert_contains "reports the file it changed" "$changed" "9017-"
assert_contains "9017's reverse edge now lists 9016" \
    "$(grep -m1 '^\*\*Blocks\*\*' docs/tasks/next/9017-*.md)" "9016"
assert_empty "second call is a no-op (already reciprocal)" \
    "$(sprintbias_ensure_reciprocal 9017 9016)"

# ── rewrite_dep_id: fold A→B rewrites both ends, notes the kept file ────
echo "sprintbias_rewrite_dep_id folds an id across dependents and marks the kept file"
# Fixture fold 9011→9012: the stale dependent 9056 must now point at 9012.
out="$(sprintbias_rewrite_dep_id 9011 9012)"
assert_contains "rewrite touched the stale dependent 9056" "$out" "9056-"
assert_contains "9056 Depends on now names 9012" \
    "$(grep -m1 '^\*\*Depends on\*\*' docs/tasks/next/9056-*.md)" "9012"

# A clean fold on fresh ids proves the kept-file note (9011 already carried one).
# 9090 stays on disk and is folded into 9092; 9091 depends on 9090.
cat > docs/tasks/backlog/9090-fold-source-kept.md <<'EOF'
# Task 9090: Fold source, kept on disk

**Depends on**: none
**Dependents**: none
EOF
cat > docs/tasks/next/9091-fold-dependent.md <<'EOF'
# Task 9091: Depends on the folded id

**Depends on**: 9090
**Dependents**: none
EOF
sprintbias_rewrite_dep_id 9090 9092 >/dev/null
assert_contains "dependent 9091 rewritten 9090→9092" \
    "$(grep -m1 '^\*\*Depends on\*\*' docs/tasks/next/9091-fold-dependent.md)" "9092"
assert_contains "kept file 9090 gains a dated fold note to 9092" \
    "$(cat docs/tasks/backlog/9090-fold-source-kept.md)" \
    "<!-- folded into #9092 2026-08-01 -->"

# ── plan_index_drift: task **Plan** field vs plan member list, both ways ─
echo "sprintbias_plan_index_drift catches Plan reverse-index drift in both directions"
drift="$(sprintbias_plan_index_drift)"
# 9081: plan 90 lists it, task says Plan: none  (member without the back-index)
assert_contains "9081 drift: listed by plan, field says none" "$drift" \
    "$(printf '9081\tnone\t90')"
# 9082: task says Plan: 90, plan omits it        (back-index claims a non-member)
assert_contains "9082 drift: field says 90, plan omits it" "$drift" \
    "$(printf '9082\t90\tnone')"
# 9083: task points Plan: 99 at a plan that does not exist
assert_contains "9083 drift: field points at a stale plan id" "$drift" "9083"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
