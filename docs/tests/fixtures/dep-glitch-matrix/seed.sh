#!/usr/bin/env bash
# seed.sh — Materialize the dependency glitch matrix board.
# See MATRIX.md for the case catalog. ID range 9000–9099.
#
# Usage:
#   bash docs/tests/fixtures/dep-glitch-matrix/seed.sh [TARGET_DIR]
#
# Default TARGET_DIR is this fixture's ./board (committed snapshot).
# Safe to re-run: wipes TARGET/docs/tasks and TARGET/docs/plans first.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-$ROOT/board}"
PLAN_ID=90
PLAN_FILE="docs/plans/${PLAN_ID}-dep-glitch-matrix-synthetic.md"

echo "▸ Seeding dep-glitch matrix → $TARGET"

rm -rf "$TARGET/docs/tasks" "$TARGET/docs/plans"
mkdir -p \
  "$TARGET/docs/tasks/"{backlog,next,doing,blocked,review,done} \
  "$TARGET/docs/plans" \
  "$TARGET/docs/sprintbias" \
  "$TARGET/docs/tmp"

# ── writers ──────────────────────────────────────────────────────────

# write_task STAGE ID SLUG TITLE DEPENDS BLOCKS [EXTRA_BODY]
# EXTRA_BODY is optional free-form markdown appended after Questions/READY.
write_task() {
  local stage="$1" id="$2" slug="$3" title="$4" depends="$5" blocks="$6"
  shift 6 || true
  local dir="$TARGET/docs/tasks/$stage"
  local path="$dir/${id}-${slug}.md"
  mkdir -p "$dir"
  cat > "$path" <<EOF
# Task ${id}: ${title}

**Feature**: none
**Created**: 2026-08-01
**Docs**: none
**Depends on**: ${depends}
**Blocks**: ${blocks}
**Parent**: none
**Plan**: ${PLAN_ID}
**Refined**: 0
**Reworked**: 0

## Problem

Synthetic fixture case for the dependency glitch matrix (Plan 15 / #332).
Title is the case name; do not implement product behavior from this file.

## Success criteria

- [ ] Fixture only — no product work

## Notes

Case id: ${id}. Stage at seed time: ${stage}.
See docs/tests/fixtures/dep-glitch-matrix/MATRIX.md.

## Questions

**Status: READY**

EOF
  if [ "$#" -gt 0 ]; then
    printf '%s\n' "$@" >> "$path"
  fi
}

write_task_unstamped() {
  local stage="$1" id="$2" slug="$3" title="$4" depends="$5" blocks="$6"
  local dir="$TARGET/docs/tasks/$stage"
  local path="$dir/${id}-${slug}.md"
  cat > "$path" <<EOF
# Task ${id}: ${title}

**Feature**: none
**Created**: 2026-08-01
**Docs**: none
**Depends on**: ${depends}
**Blocks**: ${blocks}
**Parent**: none
**Plan**: ${PLAN_ID}

## Problem

Synthetic fixture — deliberately has no READY stamp so work skips it.

## Success criteria

- [ ] Fixture only

## Notes

Case id: ${id}. Unstamped on purpose.
EOF
}

write_task_blocked() {
  local id="$1" slug="$2" title="$3" depends="$4" blocks="$5"
  shift 5 || true
  local path="$TARGET/docs/tasks/blocked/${id}-${slug}.md"
  cat > "$path" <<EOF
# Task ${id}: ${title}

**Feature**: none
**Created**: 2026-08-01
**Docs**: none
**Depends on**: ${depends}
**Blocks**: ${blocks}
**Parent**: none
**Plan**: ${PLAN_ID}

## Problem

Synthetic blocked fixture.

## Success criteria

- [ ] Fixture only

## Questions

**Status: BLOCKED**

- What decision is still open? (synthetic)

EOF
  if [ "$#" -gt 0 ]; then
    printf '%s\n' "$@" >> "$path"
  fi
}

# ── A. Healthy baselines ─────────────────────────────────────────────

write_task done 9001 "healthy-done-prereq" \
  "Healthy done prereq" "none" "9050,9065,9074,9080,9085" \
  "## Completed" \
  "Synthetic done work." \
  "" \
  "### Files changed" \
  "docs/tests/fixtures/dep-glitch-matrix/MATRIX.md"

write_task review 9002 "healthy-review-prereq" \
  "Healthy review prereq" "none" "9050,9066,9074,9080,9079" \
  "## Completed" \
  "Synthetic review work."

write_task next 9003 "peer-next-ready" \
  "Peer in next READY" "none" "9051,9067,9074,9080"

write_task_unstamped next 9004 "peer-next-unstamped" \
  "Peer in next unstamped" "none" "9052,9080"

# ── B. doing/ orphans ────────────────────────────────────────────────

write_task doing 9005 "doing-completed-orphan" \
  "Completed orphan still in doing" "none" "9053,9066,9080" \
  "## Completed" \
  "Work finished; routing to review/ never ran." \
  "" \
  "### Files changed" \
  "docs/tests/fixtures/dep-glitch-matrix/MATRIX.md"

write_task doing 9006 "doing-incomplete-orphan" \
  "Incomplete orphan mid-work" "none" "9054,9070,9077,9080" \
  "## Notes" \
  "Session interrupted before ## Completed."

write_task doing 9007 "doing-hard-fail" \
  "Hard-fail residue left in doing" "none" "9064,9080" \
  "## Outcome" \
  "**Result**: failed" \
  "**Reason**: synthetic CLI exit 1 / budget" \
  "**At**: 2026-08-01" \
  "" \
  "No ## Completed — hard fail path."

write_task doing 9033 "doing-crash-partial" \
  "Crash left partial edits in doing" "none" "none" \
  "## Notes" \
  "Partial edit only; no Outcome stamp yet (pre-#330 shape)."

# ── C. backlog never lifted / pushed back ────────────────────────────

write_task backlog 9009 "never-promoted-prereq" \
  "Never promoted out of backlog" "none" "9060,9080"

write_task backlog 9030 "pushed-back-to-backlog" \
  "Pushed back to backlog after demotion" "none" "9061,9080" \
  "## Notes" \
  "Was in next/; demoted. Dependents still wait in next/."

write_task backlog 9031 "never-lifted-with-dependents" \
  "Never lifted but lists dependents" "none" "9078" \
  "## Notes" \
  "Blocks/Dependents point at next/ canary 9078."

# ── D. blocked ───────────────────────────────────────────────────────

write_task_blocked 9008 "decision-blocked" \
  "Decision still needed in blocked" "none" "9062,9080"

write_task_blocked 9032 "incomplete-routed-blocked" \
  "Incomplete work routed to blocked" "none" "9063,9080" \
  "## Outcome" \
  "**Result**: incomplete" \
  "**Reason**: no ## Completed after run; synthetic budget stop" \
  "**At**: 2026-08-01"

# ── E. fold / remove ─────────────────────────────────────────────────
# 9010 pure missing — no file
# 9011 optional fold note file in backlog with Folded into (or omit file).
# We seed a *tombstone* in backlog so fold is discoverable; canaries that
# still Depend on 9011 show stale edges. A second mode (absent) is 9041.

write_task backlog 9011 "folded-into-9012-tombstone" \
  "Folded into 9012 (tombstone)" "none" "none" \
  "**Folded into**: 9012" \
  "" \
  "## Notes" \
  "Chat/AI folded this task into 9012. Dependents should rewrite 9011→9012." \
  "Tombstone kept so classifiers can detect fold; product may delete instead."

write_task next 9012 "fold-survivor" \
  "Fold survivor absorbing 9011" "none" "9056" \
  "## Notes" \
  "Should list former 9011 dependents in Blocks after rewrite (9056, 9077, 9080)."

# 9041 pure missing (chat removed) — no file
# 9042 missing replaced by 9043
write_task next 9043 "replacement-after-9042" \
  "Replacement after 9042 removed" "none" "9058" \
  "## Notes" \
  "Work that used to be 9042. Edges should rewrite 9042→9043."

# ── F. split; parent deleted ─────────────────────────────────────────
# 9013 missing parent
write_task next 9014 "split-child-a" \
  "Split child A of deleted 9013" "none" "9059" \
  "## Notes" \
  "Parent 9013 deleted mid-chat; rewrite dependents from 9013→9014 (and/or 9015)."

write_task backlog 9015 "split-child-b" \
  "Split child B of deleted 9013" "none" "9059" \
  "## Notes" \
  "Sibling child still in backlog — if rewrite points here, chat to promote."

# ── G. reciprocity / cycles / malformed ──────────────────────────────

write_task next 9016 "one-way-depends-on-9017" \
  "One-way edge: depends on 9017" "9017" "none" \
  "## Notes" \
  "9017 Blocks omits 9016 — reciprocity break."

write_task next 9017 "missing-reverse-for-9016" \
  "Missing reverse Blocks for 9016" "none" "9075" \
  "## Notes" \
  "Should list 9016 in Blocks/Dependents."

write_task next 9018 "cycle-a" \
  "Cycle participant A" "9019" "9076" \
  "## Notes" \
  "Cycle with 9019."

write_task next 9019 "cycle-b" \
  "Cycle participant B" "9018" "none" \
  "## Notes" \
  "Cycle with 9018."

write_task next 9020 "self-depends" \
  "Self-dependency" "9020" "none" \
  "## Notes" \
  "Depends on itself — integrity error or no-op."

write_task next 9036 "malformed-depends-tokens" \
  "Malformed Depends on tokens" "house, (hard), —" "none" \
  "## Notes" \
  "validate should warn; gating ignores bad tokens."

write_task next 9037 "bad-range-depends" \
  "Bad inverted range in Depends" "99-1" "none" \
  "## Notes" \
  "Should not expand to a huge id list."

write_task next 9038 "hash-style-depends" \
  "Hash-prefixed depends parse" "#9002" "none" \
  "## Notes" \
  "Must parse as 9002; if 9002 in review/ → runnable."

# ── H. Canaries (next READY) ─────────────────────────────────────────

write_task next 9050 "canary-healthy-dual-met" \
  "Canary: both prereqs met" "9001, 9002" "none"

write_task next 9051 "canary-wait-peer-ready" \
  "Canary: wait peer READY" "9003" "none"

write_task next 9052 "canary-wait-unstamped-peer" \
  "Canary: wait unstamped peer" "9004" "none"

write_task next 9053 "canary-wait-doing-complete" \
  "Canary: wait doing ## Completed" "9005" "none"

write_task next 9054 "canary-wait-doing-incomplete" \
  "Canary: wait doing incomplete" "9006" "none"

write_task next 9055 "canary-dangling-missing" \
  "Canary: dangling missing 9010" "9010" "none" \
  "## Notes" \
  "9010 has no file — pure dangling edge."

write_task next 9056 "canary-stale-fold-id" \
  "Canary: still depends on folded 9011" "9011" "none" \
  "## Notes" \
  "Should rewrite to 9012 or classify folded-into-9012."

write_task next 9057 "canary-chat-removed-prereq" \
  "Canary: prereq chat-removed 9041" "9041" "none"

write_task next 9058 "canary-replaced-id" \
  "Canary: still depends on replaced 9042" "9042" "none" \
  "## Notes" \
  "Work lives in 9043 now."

write_task next 9059 "canary-split-parent-gone" \
  "Canary: depends on deleted split parent 9013" "9013" "none" \
  "## Notes" \
  "Children 9014 (next) and 9015 (backlog) exist."

write_task next 9060 "canary-backlog-never-lifted" \
  "Canary: backlog never lifted 9009" "9009" "none"

write_task next 9061 "canary-pushed-back-prereq" \
  "Canary: pushed-back prereq 9030" "9030" "none"

write_task next 9062 "canary-blocked-decision" \
  "Canary: blocked decision 9008" "9008" "none"

write_task next 9063 "canary-incomplete-blocked" \
  "Canary: incomplete blocked 9032" "9032" "none"

write_task next 9064 "canary-hard-fail-doing" \
  "Canary: hard-fail doing 9007" "9007" "none"

write_task next 9065 "canary-mixed-met-and-backlog" \
  "Canary: met + backlog" "9001, 9009" "none"

write_task next 9066 "canary-mixed-review-and-doing-complete" \
  "Canary: review + doing complete" "9002, 9005" "none"

write_task next 9067 "canary-mixed-next-and-missing" \
  "Canary: next + missing" "9003, 9010" "none"

# Chain C ← B ← A(doing incomplete): 9068 ← 9069 ← 9070
# 9070 is alias of incomplete root — use 9006 as root to avoid dup, or own file.
# Own chain root 9070 in doing incomplete for clarity.
write_task doing 9070 "chain-root-incomplete" \
  "Chain root incomplete in doing" "none" "9069,9080" \
  "## Notes" \
  "Chain: 9070 → 9069 → 9068."

write_task next 9069 "chain-mid" \
  "Chain mid waits on root" "9070" "9068"

write_task next 9068 "chain-tip" \
  "Chain tip waits on mid" "9069" "none"

# Diamond: 9071 and 9072 need 9073 (backlog)
write_task backlog 9073 "diamond-root-backlog" \
  "Diamond root still in backlog" "none" "9071,9072"

write_task next 9071 "diamond-left" \
  "Diamond left" "9073" "none"

write_task next 9072 "diamond-right" \
  "Diamond right" "9073" "none"

write_task next 9074 "canary-range-depends" \
  "Canary: range depends 9001-9003" "9001-9003" "none"

write_task next 9075 "canary-one-way-victim" \
  "Canary: depends on 9017 (one-way pair)" "9017" "none"

write_task next 9076 "canary-cycle-waiter" \
  "Canary: waits on cycle 9018" "9018" "none"

write_task next 9077 "canary-multihop-fold-and-doing" \
  "Canary: fold stale + doing incomplete" "9011, 9006" "none"

write_task next 9078 "canary-prereq-demoted-with-dependents" \
  "Canary: prereq 9031 demoted with dependents" "9031" "none"

write_task next 9079 "canary-plan-field-ok-runnable" \
  "Canary: runnable but plan drift sibling" "9002" "none" \
  "## Notes" \
  "Itself Plan:90; see 9081–9083 for drift cases."

# Umbrella — dense hold report
write_task next 9080 "umbrella-canary-all-glitch-classes" \
  "Umbrella canary: every glitch class" \
  "9001, 9002, 9003, 9004, 9005, 9006, 9007, 9008, 9009, 9010, 9011, 9013, 9030, 9069" \
  "none" \
  "## Notes" \
  "Single work prepass stress object. Expect a multi-line stage-aware hold" \
  "report after Plan 15 — not a single 'needs: 9001 9002 …' blob."

# ── I. Plan membership drift ─────────────────────────────────────────

write_task next 9081 "plan-listed-task-plan-none" \
  "Plan lists me but Plan field none" "none" "none"
# overwrite Plan field to none
if [[ "$OSTYPE" == darwin* ]]; then
  sed -i '' 's/^\*\*Plan\*\*: .*/**Plan**: none/' \
    "$TARGET/docs/tasks/next/9081-plan-listed-task-plan-none.md"
else
  sed -i 's/^\*\*Plan\*\*: .*/**Plan**: none/' \
    "$TARGET/docs/tasks/next/9081-plan-listed-task-plan-none.md"
fi

write_task next 9082 "plan-field-set-but-omitted-from-plan" \
  "Plan field set but omitted from plan file" "none" "none"

write_task next 9083 "plan-field-points-at-missing-plan" \
  "Plan field points at missing plan 99" "none" "none"
if [[ "$OSTYPE" == darwin* ]]; then
  sed -i '' 's/^\*\*Plan\*\*: .*/**Plan**: 99/' \
    "$TARGET/docs/tasks/next/9083-plan-field-points-at-missing-plan.md"
else
  sed -i 's/^\*\*Plan\*\*: .*/**Plan**: 99/' \
    "$TARGET/docs/tasks/next/9083-plan-field-points-at-missing-plan.md"
fi

# ── L. Other glitches ────────────────────────────────────────────────

write_task next 9084 "empty-depends-vs-none" \
  "Empty depends field shape" "none" "none"

write_task next 9085 "depends-only-on-done" \
  "Depends only on healthy done" "9001" "none"

write_task next 9086 "blocks-lists-missing-id" \
  "Blocks lists missing reverse id" "none" "9199" \
  "## Notes" \
  "Reverse edge points at nonexistent 9199."

write_task next 9087 "orphaned-parent" \
  "Parent points at missing task" "none" "none"
if [[ "$OSTYPE" == darwin* ]]; then
  sed -i '' 's/^\*\*Parent\*\*: .*/**Parent**: 9198/' \
    "$TARGET/docs/tasks/next/9087-orphaned-parent.md"
else
  sed -i 's/^\*\*Parent\*\*: .*/**Parent**: 9198/' \
    "$TARGET/docs/tasks/next/9087-orphaned-parent.md"
fi

# READY stamp lives inside ## Questions (write_task default); append open Q.
write_task next 9089 "ready-but-open-questions" \
  "READY stamp but open question remains" "none" "none" \
  "- Still need to decide synthetic API shape?"

# ── Plan file ────────────────────────────────────────────────────────

MEMBERS=$(
  find "$TARGET/docs/tasks" -name '9*.md' -type f \
    | sed 's|.*/||; s|-.*||' | sort -n | uniq
)

{
  cat <<EOF
# Plan ${PLAN_ID}: dep-glitch-matrix synthetic

**Created**: 2026-08-01
**Status:** DRAFT

> Synthetic plan for the dependency glitch matrix fixture only.
> Not a real SprintBias product plan. Do not plan start this into a live repo
> board unless you intend to stress-test.

## Goal

Provide a single relational index over fixture tasks 9000–9099 so Plan-field
sync (#331) and status rollups can be exercised.

## Member tasks

EOF
  for id in $MEMBERS; do
    # skip pure-missing conceptual ids
    f=$(find "$TARGET/docs/tasks" -name "${id}-*.md" | head -1)
    [ -n "$f" ] || continue
    title=$(grep -m1 '^# ' "$f" | sed 's/^# Task [0-9]*: //')
    # 9082 intentionally omitted from plan list (drift case)
    [ "$id" = "9082" ] && continue
    echo "- #${id} — ${title}"
  done
  cat <<EOF

## Intentionally omitted members (drift cases)

Ids are code-quoted here so this prose does not itself parse as a member line
(sprintbias_plan_member_ids reads only "- #ID" bullets) — otherwise #9082's
"declared on the task, absent from the plan" drift case would silently heal.

- \`#9082\` — has **Plan**: ${PLAN_ID} on the task but is omitted here
- \`#9010\`, \`#9013\`, \`#9041\`, \`#9042\` — missing files (dangling / fold / split / replace)

## Fold / split ledger (for classifiers)

| From | To | Kind |
|------|-----|------|
| 9011 | 9012 | fold (tombstone in backlog) |
| 9042 | 9043 | replace (9042 absent) |
| 9013 | 9014 + 9015 | split (parent deleted) |
| 9041 | — | chat-removed (no survivor) |

EOF
} > "$TARGET/$PLAN_FILE"

# ── DOC_STATE (optional for tools that read it) ──────────────────────
cat > "$TARGET/docs/sprintbias/DOC_STATE.md" <<EOF
# DOC_STATE (synthetic fixture)

**sprint_TASK_ID**: 9099
**sprint_PLAN_ID**: ${PLAN_ID}
**sprint_BUG_ID**: 0
**sprint_FEATURE_ID**: 0
**sprint_IDEA_ID**: 0
EOF

# ── inventory counts ─────────────────────────────────────────────────
count() { find "$TARGET/docs/tasks/$1" -name '*.md' 2>/dev/null | wc -l | tr -d ' '; }

cat > "$TARGET/INVENTORY.txt" <<EOF
dep-glitch-matrix board
generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
target: $TARGET

backlog: $(count backlog)
next:    $(count next)
doing:   $(count doing)
blocked: $(count blocked)
review:  $(count review)
done:    $(count done)

Missing-by-design ids (no file): 9010 9013 9041 9042 9198 9199
Plan: $PLAN_FILE
Catalog: docs/tests/fixtures/dep-glitch-matrix/MATRIX.md
EOF

echo "✓ Seeded."
echo "  backlog=$(count backlog) next=$(count next) doing=$(count doing) blocked=$(count blocked) review=$(count review) done=$(count done)"
echo "  plan: $TARGET/$PLAN_FILE"
echo "  inventory: $TARGET/INVENTORY.txt"
echo ""
echo "Next: bash docs/tests/fixtures/dep-glitch-matrix/check-inventory.sh $TARGET"
