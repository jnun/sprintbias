#!/usr/bin/env bash
# chat-plan.sh — Conversational plan authoring. See: ./sprint.sh help chat
#
# Reached via `./sprint.sh chat plan [id]`. chat.sh routes here. This is the
# plan-shaped sibling of chat <id> / chat <folder> / chat bugs:
#   chat plan        → pick a plan to author (like bare chat backlog)
#   chat plan <id>   → author/refine that plan conversationally
#
# chat shapes; plan acts. Authoring writes docs/plans/<id>-*.md; working the
# decision checklist also edits the member tasks each line names. After the
# session the shell refreshes each member's **Plan** reverse index (plan file
# remains membership authority). Member tasks are chosen from backlog/ by ID.
# Authoring writes only the first two of the plan's three statuses: DRAFT while
# authoring → READY when the user confirms (the signal plan start / loop
# --refill gate on). STARTED is latched later by plan start, never here.
#
# Decision checklist: when docs/tmp/plan-<id>_discuss.md has unchecked lines
# (plan think listed your calls there, or an earlier session ended early), the
# session runs the work loop over it first — one issue per message: decide, do
# the updates, check it off, re-read. Otherwise it authors.

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

PLANS_DIR="docs/plans"
PLAN_ID="${1:-}"

# ── Resolve / pick a plan ────────────────────────────────────────────

list_plans() { sprintbias_list_plans; }
find_plan() { sprintbias_find_plan "$1"; }

if [ -z "$PLAN_ID" ]; then
  echo "▸ chat plan — pick a plan to author"
  echo ""
  if ! ls "$PLANS_DIR"/*.md >/dev/null 2>&1; then
    echo "No plans yet. Create one first:"
    echo "  ./sprint.sh newplan \"<name>\" [task-id ...]"
    exit 1
  fi
  echo "Plans:"
  list_plans
  echo ""
  if [ -t 0 ] && [ -t 1 ]; then
    printf "Plan id to author (or blank to cancel): "
    read -r PLAN_ID </dev/tty 2>/dev/null || PLAN_ID=""
  else
    echo "Usage: ./sprint.sh chat plan <id>"
    echo "Pass a plan id, or run interactively to pick one."
    exit 1
  fi
  [ -n "$PLAN_ID" ] || { echo "Cancelled."; exit 0; }
fi

if ! [[ "$PLAN_ID" =~ ^[0-9]+$ ]]; then
  echo "Error: '$PLAN_ID' is not a plan id."
  echo "Usage:"
  echo "  ./sprint.sh chat plan          pick a plan to author"
  echo "  ./sprint.sh chat plan <id>     author plan <id> (plan id, not a task id)"
  echo "Create a plan first with: ./sprint.sh newplan \"<name>\""
  exit 1
fi

if ! PLAN_FILE="$(find_plan "$PLAN_ID")"; then
  echo "Error: No plan found with ID $PLAN_ID in $PLANS_DIR/"
  echo "Create one with: ./sprint.sh newplan \"<name>\""
  echo "Existing plans:"
  list_plans
  exit 1
fi

PLAN_NAME=$(basename "$PLAN_FILE")
DISCUSS_FILE="$(sprintbias_plan_discuss_file "$PLAN_ID")"

MEMBER_IDS="$(sprintbias_plan_member_ids "$PLAN_FILE")"
MEMBER_LIST=""
for _id in $MEMBER_IDS; do
  if _hit=$(sprintbias_find_task "$_id" \
            docs/tasks/backlog docs/tasks/next docs/tasks/doing \
            docs/tasks/blocked docs/tasks/review docs/tasks/done 2>/dev/null); then
    _fpath="${_hit%%$'\t'*}"
    MEMBER_LIST="${MEMBER_LIST}
  - #$_id ($(basename "$(dirname "$_fpath")")/) $(task_title "$_fpath") — $_fpath"
  else
    MEMBER_LIST="${MEMBER_LIST}
  - #$_id (no file on disk)"
  fi
done
unset _id _hit _fpath

echo "▸ Authoring plan: $PLAN_NAME"
echo "  File: $PLAN_FILE"
if [ -f "$DISCUSS_FILE" ]; then
  MODE="checklist"
  echo "  Checklist: $DISCUSS_FILE ($(sprintbias_discuss_open_count "$DISCUSS_FILE") unchecked) — worked one at a time, first"
else
  MODE="author"
  echo "  (read-only over backlog/ — only this plan file will be written)"
fi
echo ""

# ── Model + method ──────────────────────────────────────────────────

_MODEL="$(sprintbias_tier_model CHAT)"
_model_args=()
[ -n "$_MODEL" ] && _model_args=(--model "$_MODEL")

_ORIENT="$(sprintbias_orient)"
_METHOD="$(sprintbias_conversation_method)" || exit 1

# Snapshot of backlog for the prompt (titles only — agent re-reads files as needed).
_BACKLOG_LIST=""
_backlog_n=0
for _bf in docs/tasks/backlog/*.md; do
  [ -f "$_bf" ] || continue
  _backlog_n=$((_backlog_n + 1))
  if [ "$_backlog_n" -le 40 ]; then
    _BACKLOG_LIST="${_BACKLOG_LIST}
  - $(basename "$_bf") — $(task_title "$_bf")"
  fi
done
if [ "$_backlog_n" -eq 0 ]; then
  _BACKLOG_BLOCK="backlog/ is empty — the user may still name IDs that live in other folders, or decide the plan needs newtask first."
elif [ "$_backlog_n" -gt 40 ]; then
  _BACKLOG_BLOCK="backlog/ has $_backlog_n tasks (first 40 titles below; read the rest from disk as needed):${_BACKLOG_LIST}"
else
  _BACKLOG_BLOCK="backlog/ tasks available to group (${_backlog_n}):${_BACKLOG_LIST}"
fi

APPEND_PROMPT="You are a senior engineer authoring a PLAN with the colleague who owns the project — a named, ordered grouping of tasks with a clear goal. This is NOT task refinement and NOT the auto-planner. You shape intent; outside the decision checklist you never move or edit task files.

Plan file: $PLAN_FILE — read it now, before you say anything.
${_ORIENT}

$_METHOD

CURRENT BACKLOG SNAPSHOT
$_BACKLOG_BLOCK

WHAT THE PLAN FILE MUST HOLD
- Heading: # Plan $PLAN_ID: <name>
- **Created**: (keep existing)
- **Status:** DRAFT while authoring; READY only when the user confirms the plan is ready to start
- ## Goal — what this clump of work achieves and why (2–5 sentences)
- ## Why — optional short rationale if useful
- ## Member tasks — ordered list, one line each:
    - #ID — short title
  Order = execution order (dependencies first). Checkboxes optional.
- Parallelism notes (optional, under Goal/Why or Notes): record independence found during the walk, e.g. '231 ∥ 234, disjoint files; 237 after 234'. V1 execution stays sequential — capture the intelligence, do not schedule parallel runs."

APPEND_PROMPT="$APPEND_PROMPT

BOUNDARY — group vs refine
- You operate on PLANS only. The id in play is a plan id. Plan creation/ID allocation is newplan's job — never invent a new plan file.
- Your ONLY durable write is $PLAN_FILE. Read docs/tasks/backlog/ (and any other task file you need for conflict analysis) but do not edit, move, or create task files. If a needed task does not exist, recommend './sprint.sh newtask \"…\"' and let the user run it — do not run it yourself.
- chat backlog mutates task files; chat plan only records IDs into the plan. Keep that boundary absolute.

YOUR GOAL
Through focused Q&A, fill or refine this plan until it is an ordered, non-conflicting group of work with a clear goal. When the user confirms it is done, flip **Status:** to READY. Partial sessions leave **Status:** DRAFT so nothing is lost.

HOW TO AUTHOR
1. SIZE UP: read the plan file and skim backlog titles. In 1–2 sentences, say what this plan currently is (empty scaffold / partial draft / looks READY).
2. GOAL first if thin: probe what the user wants this clump to achieve; ground in project profile and existing features; recommend a crisp Goal and write it.
3. MEMBERS: propose an ordered set of backlog tasks that serve the goal. Prefer existing backlog items over inventing work. Name trade-offs (scope too wide, missing prereq, conflict). On agreement, write the member list by ID + title. Re-read task files when titles alone are not enough.
4. ORDER + CONFLICTS: walk dependency edges between members; put prerequisites first. Flag file-overlap / independence as parallelism annotations (recorded only).
5. STATUS: keep DRAFT until the user confirms the plan is ready to start; then set **Status:** READY exactly (same READY word tasks use). Never invent other status values.
6. STOP when READY and the member list is ordered and non-conflicting — show the final plan state and remind: optional './sprint.sh plan think $PLAN_ID' (dual-persona critique), then './sprint.sh plan start $PLAN_ID' gates members and commits READY ones into next/. The plan file itself never moves.

RULES
- One question at a time; wait for the answer.
- Executive-summary altitude: what and why, not how. No code.
- WRITES: only $PLAN_FILE while authoring, plus $DISCUSS_FILE when you list two or more decisions. READ anything else to ground recommendations.
- Do not run plan start, do not mv task files, do not edit task bodies (the shell
  refreshes **Plan** reverse-index fields after this session)."

# Decision checklist — plan think's held calls (or an unfinished session's)
# come first, worked by the loop in ai/conversation.md. Each decided line
# widens the write boundary to the member tasks and docs it names.
_OPENING="Read the plan at $PLAN_FILE and the backlog, size it up, and start authoring — one detail at a time. Write only the plan file."
if [ "$MODE" = "checklist" ]; then
  APPEND_PROMPT="$APPEND_PROMPT

DECISION CHECKLIST FIRST — $DISCUSS_FILE
plan think applied everything it could settle and listed your calls here. Run the work loop from 'Many decisions: one issue at a time' over its unchecked lines before any other authoring.

MEMBER TASKS (plan order):$MEMBER_LIST

- Frame each line by its verdict:
  - DONE ALREADY — show where the code already does what the task asks (file:line per Success criterion) and any gap left. Options: close it (move the task to review/ so promote verifies it), trim it to just the gap and keep it, or remove it from the plan and delete it.
  - NOT REAL — walk through what was investigated and the evidence that the problem the task describes is not actually a problem in the code. Options: delete the task, or keep it if the user knows something the code does not show — then rewrite its Problem around that fact.
  - OFF GOAL — list why the work is off topic for this plan's Goal. Options: delete it, or put it off (remove it from the plan and set its **From plan** to $PLAN_ID; the task stays in backlog/ and groups with this plan's follow-ups).
  - DECISION — the problem and the options.
- Whenever a decision is \"this needs reworking, but after this plan\", offer REWORK LATER as an option: file it with './sprint.sh newtask \"…\" --from-plan $PLAN_ID', give it a Problem and Success criteria, and keep it OUT of this plan. When the plan is done, './sprint.sh newplan \"…\" from:$PLAN_ID' groups every such follow-up into the next plan.
- When a task leaves the plan (closed, deleted, put off), check off its remaining lines with the note 'skipped — task left the plan'.
- Doing the work widens the BOUNDARY above for that line only: edit the plan file, the Problem / Success criteria / Notes of member tasks in backlog/ or next/, or any doc the line names; move a closed task to review/ with 'git mv SRC DEST || mv SRC DEST'; delete a task the user chose to delete; drop removed or deferred ids from the plan's member list. Finished members (doing/review/done) keep their Problem and Success criteria — when the plan needs more from one, file a delta with './sprint.sh newtask \"…\" --from-plan $PLAN_ID' and add it to the plan. No other task moves, no plan start.
- When no unchecked lines remain, delete $DISCUSS_FILE, recap, and continue authoring if anything is left to settle."
  _OPENING="Read $DISCUSS_FILE and the plan at $PLAN_FILE. Say how many lines are unchecked, then run the work loop from the first one — one issue per message; do the updates, note it, check it off, re-read, next."
fi

# ── Interactive contract (same as chat.sh) ───────────────────────────
if [ "$(sprintbias_ai_mode)" = "exec" ] && ! sprintbias_interactive_ok; then
  echo -e "${YELLOW}Note: a live plan-authoring walk needs an interactive-capable AI CLI (claude or grok) in a real terminal.${NC}"
  echo -e "${YELLOW}Doing a single pass instead. To wire up the full experience,${NC}"
  echo -e "${YELLOW}see docs/sprintbias/guides/use_chat.md${NC}"
  echo ""
fi

sprintbias_run_interactive \
  --append-system-prompt "$APPEND_PROMPT" \
  ${_model_args[@]+"${_model_args[@]}"} \
  --tools "Read,Edit,Write,Bash,Grep,Glob" \
  --permissions "auto" \
  --name "chat-plan-${PLAN_ID}" \
  "$_OPENING"

# Refresh **Plan** reverse index for every member this plan now lists (and any
# open task that drifted). Plan file remains the membership authority.
_fixed=0
while IFS= read -r _line; do
  [ -n "$_line" ] || continue
  _fixed=$((_fixed + 1))
done < <(sprintbias_plan_index_drift --fix 2>/dev/null || true)
if [ "$_fixed" -gt 0 ]; then
  echo -e "${DIM}↻ Refreshed **Plan** reverse index on ${_fixed} task(s).${NC}"
fi
unset _fixed _line
