#!/usr/bin/env bash
# plan-think.sh — Dual-persona critique of a plan. See: ./sprint.sh help plan
#
# Invoked as: ./sprint.sh plan think [id]
# Automated (not conversational) — chat plan authors; plan think critiques;
# plan start (245) commits. Retains the dual-persona debate from the retired
# review-sprint command; retargets it from next/ to a plan file's members.

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

PLANS_DIR="docs/plans"
REVIEW_FILE="docs/tmp/plan-think.md"
PLAN_ID="${1:-}"

MODEL="$(sprintbias_tier_model PLAN_THINK)"
TOOLS="Read,Edit,Write,Bash,Grep,Glob"
PERMISSIONS="auto"
MAX_TURNS=50

AI_MODE="$(sprintbias_ai_mode)"

if [ "$AI_MODE" != "emit" ] && ! command -v "$SPRINTBIAS_CLI" &>/dev/null; then
  echo "✗ AI CLI '$SPRINTBIAS_CLI' not found in PATH"
  echo "  Edit docs/sprintbias/config to change CLI, or install the tool."
  echo "  Required by: plan think (dual-persona plan critique)"
  exit 1
fi

# ── Plan resolve / picker ────────────────────────────────────────────

list_plans() { sprintbias_list_plans; }
find_plan() { sprintbias_find_plan "$1"; }

if [ -z "$PLAN_ID" ]; then
  echo "▸ plan think — pick a plan to critique"
  echo ""
  if ! ls "$PLANS_DIR"/*.md >/dev/null 2>&1; then
    echo "No plans yet. Author one first:"
    echo "  ./sprint.sh newplan \"<name>\""
    echo "  ./sprint.sh chat plan <id>"
    exit 1
  fi
  echo "Plans:"
  list_plans
  echo ""
  if [ -t 0 ] && [ -t 1 ]; then
    printf "Plan id to critique (or blank to cancel): "
    read -r PLAN_ID </dev/tty 2>/dev/null || PLAN_ID=""
  else
    echo "Usage: ./sprint.sh plan think <id>"
    exit 1
  fi
  [ -n "$PLAN_ID" ] || { echo "Cancelled."; exit 0; }
fi

if ! [[ "$PLAN_ID" =~ ^[0-9]+$ ]]; then
  echo "Error: '$PLAN_ID' is not a plan id."
  echo "Usage: ./sprint.sh plan think [id]   # plan id, not a task id"
  exit 1
fi

if ! PLAN_FILE="$(find_plan "$PLAN_ID")"; then
  echo "Error: No plan found with ID $PLAN_ID in $PLANS_DIR/"
  echo "Existing plans:"
  list_plans
  exit 1
fi

# Member IDs from the plan file (- #N or - [ ] #N lines)
MEMBER_IDS=$(grep -oE '^- (\[[ xX]\] )?#[0-9]+' "$PLAN_FILE" 2>/dev/null | grep -oE '[0-9]+' | sort -un || true)
MEMBER_COUNT=$(printf '%s\n' "$MEMBER_IDS" | grep -cE '^[0-9]+$' || true)

if [ "${MEMBER_COUNT:-0}" -eq 0 ]; then
  echo "Plan $PLAN_ID has no member tasks yet."
  echo "Author members first: ./sprint.sh chat plan $PLAN_ID"
  exit 1
fi

# Resolve each member to a path for the prompt (best-effort listing).
MEMBER_LIST=""
for id in $MEMBER_IDS; do
  if hit=$(sprintbias_find_task "$id" \
            docs/tasks/backlog docs/tasks/next docs/tasks/doing \
            docs/tasks/blocked docs/tasks/review docs/tasks/done 2>/dev/null); then
    fpath="${hit%%$'\t'*}"
    stage=$(basename "$(dirname "$fpath")")
    MEMBER_LIST="${MEMBER_LIST}
  - #$id ($stage/) $(task_title "$fpath") — $fpath"
  else
    MEMBER_LIST="${MEMBER_LIST}
  - #$id (no file on disk — completed/archived or missing)"
  fi
done

mkdir -p "$(dirname "$REVIEW_FILE")"

echo "▸ Plan: $(basename "$PLAN_FILE")"
echo "▸ Members: $MEMBER_COUNT"
echo ""

# ── Prompt (dual persona, plan-scoped) ───────────────────────────────

PROMPT="You are acting as two collaborating leaders reviewing a PLAN before it becomes the sprint:

- **Chief Platform Architect** — optimizing for backend stability, data integrity, observability, and long-term platform health.
- **Chief Experience Officer** — optimizing for end-user clarity, friction reduction, perceived performance, and trust.

**Shared goal:** critique and improve this plan so backend reliability and user experience reinforce each other rather than compete. This is AUTOMATED analysis, not a conversation — write findings into files; do not wait for the user mid-pass.

PROJECT CONTEXT:
CLAUDE.md is auto-loaded with project overview, tech stack, and conventions.
For task workflow details, see DOCUMENTATION.md.

PLAN FILE: $PLAN_FILE
Read it fully (Goal, Why, Status, ordered Member tasks, any parallelism notes).

MEMBER TASKS ($MEMBER_COUNT, in plan order):
$MEMBER_LIST

Resolve each member ID to its current file under docs/tasks/*/ and read it. Order in the plan is intended execution order.

YOUR JOB:

**Pass 1 — Per-member annotation:**
Review members in plan order, finishing each fully before the next.
For each member task file that exists, append a ## Plan Think section containing:
1. Perspective check — how each persona views this task, what each would push for or push back on.
2. Tension and resolution — where the two perspectives disagree, state the tradeoff and which way it resolves, and why.

Leave Problem / Success criteria / Notes untouched. Only append the new section.
If a member has no file on disk, note that in the plan-level analysis instead of inventing a file.
If a task is too vague to annotate meaningfully, propose a sharper rewrite of problem/success in the annotation rather than inventing detail.

**Pass 2 — Plan-level critique:**
After every existing member is annotated, review the plan as a unit. Write analysis to $REVIEW_FILE with:

1. **Plan assessment** — coherence of the Goal vs members, risk areas, dependency gaps, order problems.
2. **Recommended changes** — merge, split, reorder, rewrite, cut, or defer members. For each, state what and why so a human or LLM can act without guessing. Prefer edits to the plan file's member list / order over moving tasks.
3. **Final recommended order** — the sequence to run, one-line rationale per position.
4. **Plan-file edits** — concrete edits to $PLAN_FILE (Goal, member list, Status) if needed. Do NOT run plan start and do NOT move task files unless the user already asked outside this run — recommend commands only.

If the plan is already strong, say so and why.

Also append a short ## Plan Think summary block to $PLAN_FILE (before any HTML comments) pointing at $REVIEW_FILE and listing the top 3 findings.

**Style:** Clear, conversational prose — full sentences that commit to a point. Read like a thoughtful colleague.

**Operating principle:** LEAN, but the goal is perfection. If following the structure above would produce a worse critique, break it and explain why.

**Completion signal:** When both passes are finished, make the very last line of $REVIEW_FILE read exactly:
PLAN THINK COMPLETE — <N> members annotated
(replace <N> with the number of member task files you annotated)."

# ── Run ─────────────────────────────────────────────────────────────

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "▸ plan think (dual-persona critique)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

_model_args=()
[ -n "$MODEL" ] && _model_args=(--model "$MODEL")

if sprintbias_run -p "$PROMPT" \
  ${_model_args[@]+"${_model_args[@]}"} \
  --tools "$TOOLS" \
  --permissions "$PERMISSIONS" \
  --max-turns "$MAX_TURNS"; then

  if sprintbias_emitted; then
    echo ""
    echo "▸ Prompt emitted — the critique runs in this agent session."
    echo "  When it finishes: ## Plan Think on member tasks; analysis in $REVIEW_FILE."
    exit 0
  fi

  if [ ! -f "$REVIEW_FILE" ] || ! grep -q '^PLAN THINK COMPLETE' "$REVIEW_FILE"; then
    echo ""
    echo "⚠ plan think ended without a completion marker."
    echo "  $REVIEW_FILE may be missing or partial — inspect it before acting."
    exit 1
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "▸ plan think complete"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "  Member annotations: ## Plan Think on each member task file"
  echo "  Plan analysis:      $REVIEW_FILE"
  echo ""
  echo "Next steps:"
  echo "  1. Review annotations and $REVIEW_FILE"
  echo "  2. Refine with ./sprint.sh chat plan $PLAN_ID if needed"
  echo "  3. Commit with ./sprint.sh plan start $PLAN_ID when READY"
else
  echo ""
  echo "✗ plan think failed"
  exit 1
fi
