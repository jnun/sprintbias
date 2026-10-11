#!/usr/bin/env bash
# chat-plan.sh — Conversational plan authoring. See: ./sprint.sh help chat
#
# Reached via `./sprint.sh chat plan [id]`. chat.sh routes here. This is the
# plan-shaped sibling of chat <id> / chat <folder> / chat bugs:
#   chat plan        → pick a plan to author (like bare chat backlog)
#   chat plan <id>   → author/refine that plan conversationally
#
# Authoring writes docs/plans/<id>-*.md and the planning work around it: create
# tasks with newtask, edit member and other plans' tasks, set reciprocal
# **Depends on** / **Dependents** across plans, and move tasks between backlog/
# and next/. Fast mode adds building: the Agent tool, plan start, work, and a
# missing piece built here (or by a subagent) to review/ with a proof line.
# Commit, push, ship.sh and done/ stay the human's. After the session the
# shell refreshes each member's **Plan** reverse index (plan file remains
# membership authority).
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
  echo "  (plan file plus task planning: newtask, task edits, cross-plan deps, backlog/ ↔ next/)"
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

_FAST="$(sprintbias_fast_rules)"
_TOOLS="Read,Edit,Write,Bash,Grep,Glob"
sprintbias_fast_on && _TOOLS="$_TOOLS,Agent"
APPEND_PROMPT="You are a senior engineer authoring a PLAN with the colleague who owns the project — a named, ordered grouping of tasks with a clear goal. This is NOT the auto-planner. You shape intent and do the planning work around it: create and edit tasks and wire their dependencies.

Plan file: $PLAN_FILE — read it now, before you say anything.
${_ORIENT}

$_METHOD

${_FAST:+
$_FAST
}
CURRENT BACKLOG SNAPSHOT
$_BACKLOG_BLOCK

WHAT THE PLAN FILE MUST HOLD
- Heading: # Plan $PLAN_ID: <name>
- **Created**: (keep existing)
- **Status:** DRAFT while authoring; READY once the Goal is clear and the members are ordered and non-conflicting
- ## Goal — what this clump of work achieves and why (2–5 sentences)
- ## Why — optional short rationale if useful
- ## Member tasks — ordered list, one line each:
    - #ID — short title
  Order = execution order (dependencies first). Checkboxes optional.
- ## Signoff (human) — optional: what only a person can check across the whole plan. Every member is agent work that lands on assumptions; person-only checks (real hardware, look and feel) live in a member's or the plan's Signoff (human), and plan start gathers them into one human test run at the end. When a candidate member's whole job is a person testing, fold its checks into this section and leave the task out.
- Parallelism notes (optional, under Goal/Why or Notes): record independence found during the walk, e.g. '231 ∥ 234, disjoint files; 237 after 234'. V1 execution stays sequential — capture the intelligence, do not schedule parallel runs."

APPEND_PROMPT="$APPEND_PROMPT

REACH — what this session may do
- The id in play is a plan id. Plan creation/ID allocation is newplan's job — never invent a new plan file.
- Write $PLAN_FILE, and do the planning work it needs:
  - Create a missing task with './sprint.sh newtask \"…\"' (it assigns the id and uses the template), then add it to the member list.
  - Edit task files — members and tasks of other plans: Problem, Done when, Signoff, Notes, fields.
  - Set **Depends on** / **Dependents** across plans, always on both sides: A depends on B means A lists B under **Depends on** and B lists A under **Dependents**.
  - Move tasks between backlog/ and next/ with 'git mv SRC DEST || mv SRC DEST'. A task enters next/ only when its ## Questions reads **Status: READY** and its Done when names a test — the bar the gate holds next/ to; anything short of that stays in backlog/.
- A task keeps its own plan membership: wiring a dependency or editing a task of another plan leaves its **Plan** as it is. Before touching another plan's task, read that plan's Goal, serve both goals, and add to that plan: Touched by plan $PLAN_ID: #id — what and why
- Commit, push, ./ship.sh and moving tasks to done/ stay the human's.

YOUR GOAL
Through focused Q&A, fill or refine this plan until it is an ordered, non-conflicting group of work with a clear goal. This is the time to dig into questions and decisions with the person; work later makes best-practice calls on its own. When the user confirms it is done, flip **Status:** to READY. Partial sessions leave **Status:** DRAFT so nothing is lost.

HOW TO AUTHOR
1. SIZE UP: read the plan file and skim backlog titles. In 1–2 sentences, say what this plan currently is (empty scaffold / partial draft / looks READY).
2. GOAL first if thin: probe what the user wants this clump to achieve; ground in project profile and existing features; recommend a crisp Goal and write it.
3. MEMBERS: propose an ordered set of backlog tasks that serve the goal. Prefer existing backlog items over inventing work. Name trade-offs (scope too wide, missing prereq, conflict). On agreement, write the member list by ID + title. Re-read task files when titles alone are not enough.
4. ORDER + CONFLICTS: walk dependency edges between members; put prerequisites first. Flag file-overlap / independence as parallelism annotations (recorded only).
5. STATUS: keep DRAFT until the user confirms the plan is ready to start; then set **Status:** READY exactly (same READY word tasks use). Never invent other status values.
6. STOP when READY and the member list is ordered and non-conflicting — show the final plan state, recap what was decided, and end with the next command: './sprint.sh plan start $PLAN_ID' (optional first: './sprint.sh plan think $PLAN_ID'). The plan file itself never moves.

RULES
- One question at a time; wait for the answer.
- Executive-summary altitude: what and why, not how. No code.
- Write within REACH, plus $DISCUSS_FILE when you list two or more decisions. Read anything to ground recommendations.
- The shell refreshes **Plan** reverse-index fields after this session."

if sprintbias_fast_on; then
  APPEND_PROMPT="$APPEND_PROMPT

FAST MODE — build and start from here
You act as the plan's lead.
- You may run './sprint.sh plan start $PLAN_ID' and './sprint.sh work' when the plan is READY.
- When a missing piece turns up, build it: file it with newtask, then do the work yourself or hand it to a subagent (Agent tool). Land it in review/ with a proof line under ## Completed — **Proof**: YYYY-MM-DD · <test commands> · pass."
else
  APPEND_PROMPT="$APPEND_PROMPT
- Building code and starting agents (plan start, work, subagents) is fast mode's job; here, file the task and name the next command for the user."
fi

# Decision checklist — plan think's held calls (or an unfinished session's)
# come first, worked by the loop in ai/conversation.md. Each decided line
# may also edit the docs it names and close or delete tasks.
_OPENING="Read the plan at $PLAN_FILE and the backlog, size it up, and start authoring — one detail at a time."
if [ "$MODE" = "checklist" ]; then
  APPEND_PROMPT="$APPEND_PROMPT

DECISION CHECKLIST FIRST — $DISCUSS_FILE
plan think applied everything it could decide and listed your calls here. Run the work loop from 'Many decisions: one issue at a time' over its unchecked lines before any other authoring.

MEMBER TASKS (plan order):$MEMBER_LIST

- Frame each line by its verdict:
  - DONE ALREADY — show where the code already does what the task asks (file:line per Done when item) and any gap left. Options: close it (move the task to review/ so promote verifies it), trim it to just the gap and keep it, or remove it from the plan and delete it.
  - NOT REAL — walk through what was investigated and the evidence that the problem the task describes is not actually a problem in the code. Options: delete the task, or keep it if the user knows something the code does not show — then rewrite its Problem around that fact.
  - OFF GOAL — list why the work is off topic for this plan's Goal. Options: delete it, or put it off (remove it from the plan and set its **From plan** to $PLAN_ID; the task stays in backlog/ and groups with this plan's follow-ups).
  - DECISION — the problem and the options.
- Whenever a decision is \"this needs reworking, but after this plan\", offer REWORK LATER as an option: file it with './sprint.sh newtask \"…\" --from-plan $PLAN_ID', give it a Problem, a Done when (automated) naming its proving test, and keep it OUT of this plan. When the plan is done, './sprint.sh newplan \"…\" from:$PLAN_ID' groups every such follow-up into the next plan.
- When a task leaves the plan (closed, deleted, put off), check off its remaining lines with the note 'skipped — task left the plan'.
- Doing the work for a line may also: edit any doc the line names; move a closed task to review/ with 'git mv SRC DEST || mv SRC DEST'; delete a task the user chose to delete; drop removed or deferred ids from the plan's member list. Finished members (doing/review/done) keep their Problem and Done when — when the plan needs more from one, file a delta with './sprint.sh newtask \"…\" --from-plan $PLAN_ID' and add it to the plan.
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
  --tools "$_TOOLS" \
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
