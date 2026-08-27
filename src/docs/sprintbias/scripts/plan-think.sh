#!/usr/bin/env bash
# plan-think.sh — Think a plan into alignment. See: ./sprint.sh help plan
#
# Invoked as: ./sprint.sh plan think [id]
# Automated (not conversational) — chat plan authors; plan think improves the
# plan AND aligns its member tasks to it; plan start commits. Two collaborating
# leaders (Platform Architect + Experience Officer) evaluate through three
# lenses — best practice, elegant design / coding standards, antifragility —
# then apply the improved plan to the plan file and rewrite each unstarted
# member's Problem/Success to fit it. A finished member (doing/review/done) is
# trusted as-completed and never reopened; if the plan needs more from it, a new
# delta task is filed via newtask and added to the plan. It never runs plan
# start and never moves files.

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

PLANS_DIR="docs/plans"
PLAN_ID="${1:-}"
# REVIEW_FILE is keyed per plan below, once PLAN_ID is resolved — a fixed shared
# path let one plan's stale analysis survive and satisfy another plan's run.
REVIEW_FILE=""

MODEL="$(sprintbias_tier_model PLAN_THINK)"
TOOLS="Read,Edit,Write,Bash,Grep,Glob"
PERMISSIONS="auto"
MAX_TURNS=50

AI_MODE="$(sprintbias_ai_mode)"

if [ "$AI_MODE" != "emit" ] && ! command -v "$SPRINTBIAS_CLI" &>/dev/null; then
  echo "✗ AI CLI '$SPRINTBIAS_CLI' not found in PATH"
  echo "  Edit docs/sprintbias/config to change CLI, or install the tool."
  echo "  Required by: plan think (improve plan + align its tasks)"
  exit 1
fi

# ── Plan resolve / picker ────────────────────────────────────────────

list_plans() { sprintbias_list_plans; }
find_plan() { sprintbias_find_plan "$1"; }

if [ -z "$PLAN_ID" ]; then
  echo "▸ plan think — pick a plan to think through"
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
    printf "Plan id to think through (or blank to cancel): "
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

# Key the review file to THIS plan so a prior plan's analysis can never be
# mistaken for — or satisfy the completion gate of — this run.
REVIEW_FILE="docs/tmp/plan-think-${PLAN_ID}.md"

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

PROMPT="You are acting as two collaborating leaders who will improve a PLAN before it becomes the sprint, then bring its member tasks into alignment with the improved plan:

- **Chief Platform Architect** — optimizing for backend stability, data integrity, observability, and long-term platform health.
- **Chief Experience Officer** — optimizing for end-user clarity, friction reduction, perceived performance, and trust.

Both of you evaluate every decision through three lenses:
1. **Best practice** — the established, proven way to do this. Avoid reinventing what is already solved and avoid cutting known corners.
2. **Elegant design & coding standards** — the simplest clean design a good engineer would be proud of, consistent with this project's conventions (read CLAUDE.md / DOCUMENTATION.md for them).
3. **Antifragility** — the plan should make the system STRONGER under stress, load, and change, not merely survive it. Prefer designs that degrade gracefully, surface failure signals early, and remove single points of fragility.

**Shared goal:** produce an IMPROVED plan AND ALIGNED member tasks, where backend reliability and user experience reinforce each other rather than compete. This is AUTOMATED — apply your changes directly to the files; do not wait for the user mid-pass.

PROJECT CONTEXT:
CLAUDE.md is auto-loaded with project overview, tech stack, and conventions.
For task workflow details, see DOCUMENTATION.md.

PLAN FILE: $PLAN_FILE
Read it fully (Goal, Why, Status, ordered Member tasks, any parallelism notes).

MEMBER TASKS ($MEMBER_COUNT, in plan order):
$MEMBER_LIST

Resolve each member ID to its current file under docs/tasks/*/ and read it. Order in the plan is intended execution order.

YOUR JOB — three passes, in order:

**Pass 1 — Improve the plan.**
Critique the plan as a unit through both personas and the three lenses: coherence of Goal vs members, risk areas, dependency gaps, order problems, and anywhere a lens is violated. Decide the improved plan — which members to merge, split, reorder, cut, defer, or add, plus the corrected Goal / Why and the final execution order. Then APPLY those decisions directly to $PLAN_FILE: edit the Goal, Why, the member list, and the order into their improved form. Only cut, defer, or split a member that is still in **(backlog/)** or **(next/)** — a member already in **(doing/)**, **(review/)**, or **(done/)** represents committed or finished work and stays in the plan (reordering its line is fine; removing it would orphan real work). When you do cut or defer an eligible member, remove it from the plan's member list and record why in the review — leave its task file on disk for the human. Do NOT run plan start, do NOT move task files, and do NOT change **Status:** (plan start owns commitment and latches STARTED).

**Pass 2 — Align each surviving member to the improved plan.**
Work members in the improved order, finishing each fully before the next. Each member's line above is tagged with its current lifecycle folder in parentheses — **let that folder decide how far you edit**:

- Member in **(backlog/)** or **(next/)** — not yet worked, still malleable. REWRITE its **Problem** and **Success criteria** so they fit the improved plan's Goal and order and satisfy the three lenses — sharp Problem, testable Success, execute-ready. Sharpen and align; stay truthful to the task's intent and do not invent scope.
- Member in **(doing/)**, **(review/)**, or **(done/)** — trust it as completed exactly as it was originally defined; its code already exists on disk. Do NOT rewrite its Problem/Success — changing the acceptance bar after the code was built against it is a regression. Two sub-cases:
  - The improved plan needs nothing more from it → leave it untouched (just annotate below).
  - The improved plan genuinely needs MORE from it — a real blocker, not cosmetic drift → do NOT reopen the finished task. Instead file a NEW delta task with:
        ./sprint.sh newtask \"<short description of the delta the plan now needs>\"
    then append **Problem**, **Success criteria**, and a **Why** to the created file in docs/tasks/backlog/. Write it to START FROM THE CURRENT CODE/FILESYSTEM STATE (the finished member already landed) and add ONLY the new fix — do not re-describe work that already exists. Reference the completed member by id (\"builds on #<member id>\"). Then add the new task's id to $PLAN_FILE's member list so it becomes part of the plan and plan start will gate it. Record the filing in the member's annotation and in the review.

For every member whose file exists, in either case, leave Notes and any Depends on / Dependents lines intact and append a lean ## Plan Think section recording: how each persona views this task, the key tension and how it resolved, which lens drove any change, and — for a worked member — whether you left it as-is or filed a delta task (name its id). If a member has no file on disk, note that in the review instead of inventing a file.

**Pass 3 — Record.**
Write the plan-level analysis to $REVIEW_FILE with:
1. **What changed** — the edits you applied to the plan and to each member, and why (name the lens).
2. **Final order** — the committed execution sequence, one-line rationale per position.
3. **Cut / deferred** — any members removed from the plan and why.
4. **Delta tasks filed** — any new tasks you created for a finished member that the plan now needs more from (id + one line + which member it builds on), or \"none\".
5. **Open risks** — dependency gaps or fragility that remain for a human to weigh.
Also append a short ## Plan Think summary block to $PLAN_FILE (before any HTML comments) pointing at $REVIEW_FILE and listing the top 3 findings.

If the plan and its tasks are already strong and aligned, make minimal edits and say so plainly.

**Style:** Clear, conversational prose — full sentences that commit to a point. Read like a thoughtful colleague.

**Operating principle:** LEAN, but the goal is perfection. If following the structure above would produce a worse result, break it and explain why.

**Completion signal:** When all three passes are finished, make the very last line of $REVIEW_FILE read exactly:
PLAN THINK COMPLETE — plan $PLAN_ID, <N> members aligned
(replace <N> with the number of member task files you edited; keep the literal text \"plan $PLAN_ID\" so this run's marker cannot be confused with another plan's)."

# Live progress rendering is sprintbias_stream_filter (lib.sh) — one readable
# line per stream-json step, shared with work.sh so both show the same live
# progress while the full raw stream lands in the log file.

# ── Run ─────────────────────────────────────────────────────────────

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "▸ plan think (improve plan + align its tasks)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

_model_args=()
[ -n "$MODEL" ] && _model_args=(--model "$MODEL")

# Emit mode: hand the prompt to the surrounding agent. No log file — the run
# happens in this session, and the early exit below mirrors the old behavior.
if [ "$AI_MODE" = "emit" ]; then
  sprintbias_run -p "$PROMPT" \
    ${_model_args[@]+"${_model_args[@]}"} \
    --tools "$TOOLS" \
    --permissions "$PERMISSIONS" \
    --max-turns "$MAX_TURNS"
  echo ""
  echo "▸ Prompt emitted — the plan-think pass runs in this agent session."
  echo "  When it finishes: plan file + backlog/next members edited in place,"
  echo "  ## Plan Think on each member, analysis in $REVIEW_FILE."
  exit 0
fi

# Exec mode: stream the raw event log to docs/tmp/ in real time (like work) —
# tee the full provider-neutral stream to the file while sprintbias_stream_filter renders
# readable progress on the terminal. --output-format stream-json is translated
# per profile by sprintbias_run (Claude keeps it; others map/drop as needed).
LOG_FILE="$(sprintbias_log_path plan-think "$PLAN_ID")"

if sprintbias_run -p "$PROMPT" \
  ${_model_args[@]+"${_model_args[@]}"} \
  --tools "$TOOLS" \
  --permissions "$PERMISSIONS" \
  --max-turns "$MAX_TURNS" \
  --output-format stream-json 2>&1 | tee "$LOG_FILE" | sprintbias_stream_filter; then

  if [ ! -f "$REVIEW_FILE" ] || ! grep -q "^PLAN THINK COMPLETE — plan $PLAN_ID," "$REVIEW_FILE"; then
    echo ""
    echo "⚠ plan think ended without a completion marker — the run may be partial."
    echo "  This pass edits files in place: $PLAN_FILE and its backlog/next members"
    echo "  may be half-updated. Review 'git diff' before acting; 'git restore' undoes it."
    echo "  Analysis (may be missing/partial): $REVIEW_FILE"
    echo "  Full run log: $LOG_FILE"
    exit 1
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "▸ plan think complete"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "  Plan file:     Goal / members / order updated in place"
  echo "  Member tasks:  backlog/next aligned; finished members annotated (never reopened)"
  echo "  Plan analysis: $REVIEW_FILE  (see 'Delta tasks filed')"
  echo ""
  echo "Next steps:"
  echo "  1. Review edits — git diff $PLAN_FILE and members; git status for any new delta tasks"
  echo "  2. Refine with ./sprint.sh chat plan $PLAN_ID if needed"
  echo "  3. Commit with ./sprint.sh plan start $PLAN_ID when READY"
else
  echo ""
  echo "✗ plan think failed"
  echo "  Run log: $LOG_FILE"
  exit 1
fi
