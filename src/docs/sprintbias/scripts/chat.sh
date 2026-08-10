#!/usr/bin/env bash
# chat.sh — Talk a task through, refining it one detail at a time. See: ./sprint.sh help chat

set -euo pipefail

# ── Per-run model override (--model <id>) ────────────────────────────
# Strip an optional `--model <id>` from anywhere in the args and export it as
# the resolver's per-run lever (SPRINTBIAS_MODEL_DEFAULT) so one `chat` invocation
# — including the folder/bugs/plan sweeps it exec's into — can pin a model
# without editing config. The remaining args keep their shape ($1 = task id /
# folder / plan / bugs) for the dispatch below. See ./sprint.sh model.
_args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --model)
      [ $# -ge 2 ] && [ -n "$2" ] || { echo "✗ --model needs a model id" >&2; exit 1; }
      export SPRINTBIAS_MODEL_DEFAULT="$2"; shift 2 ;;
    *) _args+=("$1"); shift ;;
  esac
done
set -- ${_args[@]+"${_args[@]}"}
unset _args

# ── Config ───────────────────────────────────────────────────────────
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

# ── Args ─────────────────────────────────────────────────────────────

TASK_ID="${1:-}"

# `chat [target]` cases, decided by the argument's SHAPE:
#   (empty)                     → entry menu on a terminal, else the sprint walk
#   newtask [name]              → create a task, then chat it into shape
#   newplan [name]              → create a plan, then author it (chat-plan.sh)
#   numeric id                  → chat that one task through (the rest of this file)
#   stage name (blocked/next/backlog) → express one-at-a-time sweep of that folder
#   bugs                        → sweep the bug inbox
#   plan [id]                   → author a plan conversationally (chat-plan.sh)
#   sprint                      → the whole-sprint structural-health walk by name
#
# No task id → on a real terminal, open the entry menu (chat-menu.sh) so a human
# picks a front door; off a terminal (agent/CI) go straight to the sprint walk.
# chat-sprint.sh runs a deterministic structural-health preflight over next/ +
# blocked/, then walks the findings one at a time in this same one-detail voice.
if [ -z "$TASK_ID" ]; then
  # On a real terminal, open the entry menu (chat-menu.sh) so a human picks a
  # starting point among the conversational front doors. In emit mode or on a
  # pipe (agent-driven, CI) there is no one to answer a menu, so keep the old
  # behaviour and go straight to the whole-sprint structural-health walk.
  # `chat sprint` reaches that walk directly, menu or not.
  _dir="$(dirname "${BASH_SOURCE[0]}")"
  if [ "$(sprintbias_ai_mode)" = "exec" ] && [ -t 0 ] && [ -t 1 ]; then
    _TALK_MENU="$_dir/chat-menu.sh"
    # exec directly when the exec bit survived; fall back to `bash` on filesystems
    # that drop it (WSL/Docker/FAT32) — the same guard run_script uses.
    if [ -x "$_TALK_MENU" ]; then exec "$_TALK_MENU"; else exec bash "$_TALK_MENU"; fi
  fi
  _TALK_SPRINT="$_dir/chat-sprint.sh"
  if [ -x "$_TALK_SPRINT" ]; then exec "$_TALK_SPRINT"; else exec bash "$_TALK_SPRINT"; fi
fi

# A stage name → sweep that whole folder one task at a time (chat-folder.sh,
# which absorbed the retired `triage`). This is checked BEFORE the numeric-id
# path so a folder name never falls through to sprintbias_find_task.
case "$TASK_ID" in
  blocked|next|backlog)
    _TALK_FOLDER="$(dirname "${BASH_SOURCE[0]}")/chat-folder.sh"
    if [ -x "$_TALK_FOLDER" ]; then exec "$_TALK_FOLDER" "$TASK_ID"; else exec bash "$_TALK_FOLDER" "$TASK_ID"; fi
    ;;
  sprint)
    # `chat sprint` — the whole-sprint structural-health walk by name. Bare
    # `chat` reaches the same walk when there is no terminal for the menu.
    _TALK_SPRINT="$(dirname "${BASH_SOURCE[0]}")/chat-sprint.sh"
    if [ -x "$_TALK_SPRINT" ]; then exec "$_TALK_SPRINT"; else exec bash "$_TALK_SPRINT"; fi
    ;;
  newtask)
    # `chat newtask [name]` — create a task, then dive straight into defining it.
    # The create→chat handoff lives here so both this grammar word and the bare
    # `chat` menu's "New task" choice share one implementation. With no name on a
    # terminal, prompt for it; off a terminal (agent/CI) a name is required.
    _NEWNAME="${2:-}"
    if [ -z "$_NEWNAME" ] && [ -t 0 ] && [ -t 1 ]; then
      printf "Short name for the new task: "
      read -r _NEWNAME 2>/dev/null </dev/tty || _NEWNAME=""
    fi
    [ -n "$_NEWNAME" ] || { echo "Usage: ./sprint.sh chat newtask \"<name>\""; exit 1; }
    _SCRIPTS="$(dirname "${BASH_SOURCE[0]}")"
    _out="$(bash "$_SCRIPTS/create-task.sh" "$_NEWNAME")" || { printf '%s\n' "$_out"; exit 1; }
    printf '%s\n' "$_out"
    _nid="$(printf '%s\n' "$_out" | grep -oE 'backlog/[0-9]+' | head -1 | grep -oE '[0-9]+' || true)"
    [ -n "$_nid" ] || { echo "✗ Could not read the new task id — run: ./sprint.sh chat <id>"; exit 1; }
    echo ""
    # Re-enter this same script on the fresh id so the full refine conversation runs.
    _SELF="${BASH_SOURCE[0]}"
    if [ -x "$_SELF" ]; then exec "$_SELF" "$_nid"; else exec bash "$_SELF" "$_nid"; fi
    ;;
  newplan)
    # `chat newplan [name]` — create a plan scaffold, then author it in conversation.
    # Mirror of `chat newtask`: the create→author handoff lives here so both this
    # grammar word and the bare `chat` menu's "New plan" choice share one path.
    _NEWNAME="${2:-}"
    if [ -z "$_NEWNAME" ] && [ -t 0 ] && [ -t 1 ]; then
      printf "Short name for the new plan: "
      read -r _NEWNAME 2>/dev/null </dev/tty || _NEWNAME=""
    fi
    [ -n "$_NEWNAME" ] || { echo "Usage: ./sprint.sh chat newplan \"<name>\""; exit 1; }
    _SCRIPTS="$(dirname "${BASH_SOURCE[0]}")"
    _out="$(bash "$_SCRIPTS/create-plan.sh" "$_NEWNAME")" || { printf '%s\n' "$_out"; exit 1; }
    printf '%s\n' "$_out"
    _pid="$(printf '%s\n' "$_out" | grep -oE 'plans/[0-9]+' | head -1 | grep -oE '[0-9]+' || true)"
    [ -n "$_pid" ] || { echo "✗ Could not read the new plan id — run: ./sprint.sh chat plan <id>"; exit 1; }
    echo ""
    _PLAN="$_SCRIPTS/chat-plan.sh"
    if [ -x "$_PLAN" ]; then exec "$_PLAN" "$_pid"; else exec bash "$_PLAN" "$_pid"; fi
    ;;
  bugs)
    # `bugs` is NOT a task stage — it is the flat bug inbox (docs/bugs/), whose
    # sweep turns reports into fix tasks. Its own script (chat-bugs.sh), routed
    # here alongside the stage folders so the whole chat grammar lives in one place.
    _TALK_BUGS="$(dirname "${BASH_SOURCE[0]}")/chat-bugs.sh"
    if [ -x "$_TALK_BUGS" ]; then exec "$_TALK_BUGS"; else exec bash "$_TALK_BUGS"; fi
    ;;
  plan)
    # `plan` is NOT a task stage — author/refine a plan file in docs/plans/.
    # Optional second arg is a *plan* id (never a task id). Bare `chat plan`
    # picks one. Writes only the plan file; backlog is read-only.
    _TALK_PLAN="$(dirname "${BASH_SOURCE[0]}")/chat-plan.sh"
    if [ -x "$_TALK_PLAN" ]; then exec "$_TALK_PLAN" "${2:-}"; else exec bash "$_TALK_PLAN" "${2:-}"; fi
    ;;
esac

# Anything else that is not a task id is a mistake — guide, don't silently
# search for a nonexistent task. (doing/, review/, done/ are not sweep targets:
# chat works the pipeline forward, not over in-flight or finished work.)
if ! [[ "$TASK_ID" =~ ^[0-9]+$ ]]; then
  echo "Error: '$TASK_ID' is not a task id, a stage folder, 'bugs', or 'plan'."
  echo "Usage:"
  echo "  ./sprint.sh chat              open the entry menu (or, off a terminal, the sprint walk)"
  echo "  ./sprint.sh chat newtask [name]  create a task and define it right away"
  echo "  ./sprint.sh chat newplan [name]  create a plan and author it right away"
  echo "  ./sprint.sh chat <id>         chat one task through (e.g. chat 42)"
  echo "  ./sprint.sh chat <folder>     sweep a folder: blocked, next, or backlog"
  echo "  ./sprint.sh chat bugs         sweep the bug inbox → fix tasks"
  echo "  ./sprint.sh chat plan [id]    author a plan (plan id; bare = pick one)"
  echo "  ./sprint.sh chat sprint       walk the whole sprint's structural health"
  exit 1
fi

# ── Find the task file ───────────────────────────────────────────────

if ! _RESULT="$(sprintbias_find_task "$TASK_ID")"; then
  echo "Error: No task found with ID $TASK_ID in blocked/, backlog/, next/, or doing/"
  exit 1
fi
TASK_FILE="${_RESULT%%$'\t'*}"
TASK_DIR="${_RESULT##*$'\t'}"

TASK_NAME=$(basename "$TASK_FILE")
PARENT_NUM="${TASK_NAME%%-*}"
STAGE="$(basename "$TASK_DIR")"
echo "▸ Talking through: $TASK_NAME"
echo "  Location: $TASK_DIR/"
echo ""

# Interactive, reasoning-heavy review — worth the strongest model unless pinned.
_MODEL="$(sprintbias_tier_model CHAT)"
_model_args=()
[ -n "$_MODEL" ] && _model_args=(--model "$_MODEL")

# ── Launch the conversational review ─────────────────────────────────

_PROFILE_LINE="$(sprintbias_profile_line)"

# When the user chooses to split, the original file is retired once its
# children exist. In emit mode the surrounding agent performs the delete
# (the shell can't act after an emitted prompt); in exec mode the spawned
# CLI does it inline via Bash. Same wording pattern as split.sh.
if [ "$(sprintbias_ai_mode)" = "emit" ]; then
  _RETIRE_INSTR="delete it yourself: git rm $TASK_FILE   (or: rm $TASK_FILE)"
else
  _RETIRE_INSTR="delete it: git rm $TASK_FILE   (or: rm $TASK_FILE)"
fi

# newtask always creates children in backlog/. If the original is further
# along the pipeline (next/doing/blocked), the children must follow it there
# or a split silently drops the work out of that stage. Empty when the
# original is already in backlog, so the common case reads clean.
if [ "$STAGE" = "backlog" ]; then
  _STAGE_MOVE=""
else
  _STAGE_MOVE="Each child is created in backlog/, but the original lives in ${STAGE}/ — move every finished child there with: git mv docs/tasks/backlog/<child-file> $TASK_DIR/<child-file> || mv docs/tasks/backlog/<child-file> $TASK_DIR/<child-file>  so this work stays in ${STAGE}/. "
fi

# ── Close-the-loop: a blocked task that chat answers re-enters the sprint only
# through the shared workability gate (same as plan start / chat-folder [w]).
# Answered questions become body instruction; the gate stamps READY when the
# list is clear, or BLOCKED when a question is still open.
if [ "$STAGE" = "blocked" ]; then
  _CLOSE_LOOP_INSTR="
1b. CLOSE THE LOOP (this task is in blocked/):
gate parked this task because a question was still open. When every question is
answered — each answer written as instruction in Problem / Success criteria /
Notes, each original question deleted, and '### Questions for the developer'
reads 'None — task is fully defined.' — promote via the shared gate:
1. DELETE any stale '## BLOCKED' section once the question list is clear.
2. Run the promote helper (project root):
     bash docs/sprintbias/scripts/promote-to-sprint.sh $TASK_FILE
   That runs the workability gate: READY → next/, BLOCKED → blocked/ (reason in
   file), COMPLETE → review/. Tell the user the one-line result.
While any open question remains, leave the file in blocked/ and name what still
needs answering."
else
  _CLOSE_LOOP_INSTR=""
fi

# ── Demote-the-other-way: the symmetric partner of close-the-loop. blocked/
# means a decision or clarification is needed — so a task that ENDS the session
# with a real open question shouldn't keep sitting in a workable stage pretending
# to be ready. Only meaningful when the task is NOT already in blocked/ (a
# blocked task that stays unresolved is handled by close-the-loop's own "leave
# it in blocked/" branch), so this is empty for blocked/ and the closing prompt
# reads clean. chat states the demotion plainly because a user who ran chat on
# a "finished" next/ task will not expect it to leave the sprint.
if [ "$STAGE" != "blocked" ]; then
  _DEMOTE_INSTR="

═══ IF A DECISION IS STILL OPEN — RECORD, THEN DEMOTE ═══
If the session ends with a real choice still needed before work can start (a
decision on this task, beyond ordinary dependency waits), move it to BLOCKED:
1. RECORD the open question(s): make the file END with a '## Questions' section
   whose first line is EXACTLY:
     **Status: BLOCKED**
   Under '### Questions for the developer', list each as
   'N. [Question]? (Suggestion: [pick and why])'. Replace any earlier
   '## Questions' section with one clean section.
2. DEMOTE it:  git mv $TASK_FILE docs/tasks/blocked/$TASK_NAME || mv $TASK_FILE docs/tasks/blocked/$TASK_NAME
3. TELL THE USER PLAINLY that you moved this task out of ${STAGE}/ into blocked/
   and name the open question in one line.
4. Then give the same leave-session cue as the finish path (step 5 below)."
else
  _DEMOTE_INSTR=""
fi

# ── Leave the interactive TUI: conversation-complete ≠ process-exit ──
# In a live exec session the host TUI keeps the terminal until the user quits.
# Folder sweeps (chat backlog/next/blocked) only resume after that exit. Tell
# the model to say so explicitly; emit mode already is the surrounding agent
# (no nested TUI), so skip the cue there.
if [ "$(sprintbias_ai_mode)" = "exec" ] && sprintbias_interactive_ok; then
  _EXIT_INSTR="

5. LEAVE THE SESSION: after the finish/close/chain steps above (or after demoting), tell the user in one clear line that this conversation is complete and they should type \`/quit\` (or \`quit\` / \`/exit\`) to leave the interactive session. Edits are already on disk — there is nothing to save. If they came from a folder sweep (\`chat backlog\`, \`chat next\`, or \`chat blocked\`), that returns them to the sweep for the next task. Do not open a new question after this cue."
else
  _EXIT_INSTR=""
fi

# ── Chain to the next dependency in a FRESH context. Defining one task often
# surfaces that it depends on another task that still needs a decision; walking
# that chain in THIS conversation piles context up and burns tokens. So we hand
# the next task off through its FILE (a durable note the fresh session reads)
# and start clean:
# emit mode on orchestration-capable tiers spawns a brand-new subagent;
# exec mode can't open a window, so it prints the command for the user to run.
if [ "$(sprintbias_ai_mode)" = "emit" ] && sprintbias_orchestration_capable; then
  _CONTINUE_INSTR="Then CONTINUE THE CHAIN in a fresh context so this session's tokens don't pile up: $(sprintbias_subagent_spawn_phrase "<next-id>" chain). Its entire instruction: 'Run ./sprint.sh chat <next-id> and carry that task as far toward READY as you can on your own — read the *Context from chat* note already in its file, refine it, and for each answered question convert the answer into body instruction and delete the question; leave only still-open questions under ### Questions for the developer and report those back.' Tell the user you have spun up a fresh agent for <next-id> and say in one line what it is picking up."
else
  _CONTINUE_INSTR="Then, to keep each session's context small, do NOT keep going here. Tell the user the next task to define and the exact command to run in a FRESH window:  ./sprint.sh chat <next-id>  — the *Context from chat* note you just wrote means that fresh session already has what it needs."
fi

# ── Context for the size-up and (especially) the stress-test ─────────
# Sprint theme is derived live from next/ (next/ IS the sprint — plan start
# put those tasks there). No cached plan file. Optional supplement: a plan
# file in docs/plans/ whose members currently sit in next/, Goal only.
# Sibling-task overlap scan of the current stage caps at 20 names.
_SPRINT_LINE=""
_next_list=""
_next_count=0
_next_ids=""
for _nf in docs/tasks/next/*.md; do
  [ -f "$_nf" ] || continue
  _next_count=$((_next_count + 1))
  _nid="${_nf##*/}"; _nid="${_nid%%-*}"
  _ntitle=$(grep -m1 '^# ' "$_nf" 2>/dev/null | sed 's/^#[[:space:]]*//')
  [ -n "$_ntitle" ] || _ntitle="${_nf##*/}"
  _next_list="${_next_list}
  - ${_nid}: ${_ntitle}"
  _next_ids="${_next_ids} ${_nid}"
done
_plan_supp=""
if [ "$_next_count" -gt 0 ] && [ -d "docs/plans" ]; then
  for _pf in docs/plans/[0-9]*.md; do
    [ -f "$_pf" ] || continue
    for _nid in $_next_ids; do
      if grep -qE "#${_nid}([^0-9]|$)" "$_pf" 2>/dev/null; then
        _goal=$(awk '/^## Goal/{f=1; next} f && /^## /{exit} f && NF{print; if(++n>=3) exit}' "$_pf" \
          | tr '\n' ' ' | sed 's/[[:space:]]*$//')
        if [ -n "$_goal" ]; then
          _pname=$(grep -m1 '^# ' "$_pf" 2>/dev/null | sed 's/^#[[:space:]]*//')
          [ -n "$_pname" ] || _pname="${_pf##*/}"
          _plan_supp="
- active plan goal (${_pname}): ${_goal}"
        fi
        break 2
      fi
    done
  done
fi
if [ "$_next_count" -gt 0 ]; then
  _SPRINT_LINE="
- current sprint (docs/tasks/next/ — live, ${_next_count} task(s); this IS the sprint):${_next_list}${_plan_supp}"
elif [ -d "docs/tasks/next" ]; then
  _SPRINT_LINE="
- current sprint (docs/tasks/next/): empty — no tasks queued"
fi

_SIBLING_LIST=""
_sibling_count=0
_sibling_collected=0
for sibling in "$TASK_DIR"/*.md; do
  [ -f "$sibling" ] || continue
  _sib_name="$(basename "$sibling")"
  [ "$_sib_name" = "$TASK_NAME" ] && continue
  _sibling_count=$((_sibling_count + 1))
  if [ "$_sibling_collected" -lt 20 ]; then
    _SIBLING_LIST="${_SIBLING_LIST}
  - ${_sib_name}"
    _sibling_collected=$((_sibling_collected + 1))
  fi
done

_SIBLING_LINE=""
if [ "$_sibling_count" -gt 0 ]; then
  _sibling_label="$_sibling_count other tasks"
  [ "$_sibling_count" -gt 20 ] && _sibling_label="first 20 of $_sibling_count tasks"
  _SIBLING_LINE="
- sibling tasks in ${STAGE}/ ($_sibling_label — scan titles for overlap):${_SIBLING_LIST}"
fi

_CONTEXT_BLOCK=""
if [ -n "${_SPRINT_LINE}${_SIBLING_LINE}" ]; then
  _CONTEXT_BLOCK="

CONTEXT — also read these if present; they inform the size-up and especially the stress-test:${_SPRINT_LINE}${_SIBLING_LINE}"
fi

# Shared Conversation Method (probe → ground → recommend → open floor). Loaded
# once here so the method is stated in ai/conversation.md, not restated below.
_METHOD="$(sprintbias_conversation_method)" || exit 1

APPEND_PROMPT="You are a senior engineer reviewing a task with the colleague who wrote it. Talk it through one detail at a time until it is a crisp user-story brief any developer (human or AI) can pick up — problem and what done looks like, without a prescribed build plan.

The task file is at: $TASK_FILE — read it now, before you say anything.${_PROFILE_LINE}${_CONTEXT_BLOCK}

$_METHOD

YOUR GOAL: Turn a rough task into a crisp user-story brief any developer (human or AI) can pick up — fill in a stub, refine one rough job, split several jobs, or stress-test one that already looks done. Result: clear problem + what done looks like; optional hints and paths; every answered question turned into instruction in the body. How to implement is the developer's choice guided by those instructions.

Questions become instructions:
1. ASK one focused question (with a suggestion when it is a real decision).
2. GET the answer.
3. CONVERT the answer into clear instruction or guidance.
4. UPDATE the task body (Success criteria when it defines done; otherwise Notes).
5. DELETE the original question — it has been answered.

STEP 0 — SIZE IT UP FIRST:
In one or two sentences, what this task really is. Then a two-part call:
  (a) DEFINITION STATE — UNDEFINED STUB (Problem/Success empty/placeholder or \"This task is not defined yet\"), MISPLACED BRIEF (Problem/Success still empty but title, Notes, References, or ## Questions Remaining work already state the work clearly — promote that into the body), ROUGH or SEVERAL JOBS (thin, or bundles distinct work), or LOOKS DEFINED (Problem plus verifiable criteria already clear)?
  (b) MODE — FILL-IN, REFINE, SPLIT, or STRESS-TEST below.
Opening frame, not a locked gate: switch modes mid-session when facts warrant (hollow criterion → FILL-IN; multi-job stub → SPLIT; now-clean task → STRESS-TEST). Say so when you switch. Borderline → ask the user. Already clear → confirm, don't invent gaps. Prefer promoting existing clarity into Problem/Success over re-interrogating from zero.

═══ MODE: FILL-IN — undefined stub ═══
Build the durable brief via the REFINE loop. Open: what is the problem, and what does done look like? Then scope, dependencies, optional hints — one question at a time, edit as each lands. If the file already has useful material only under title, Notes, or ## Questions Remaining work, promote that into Problem and Success criteria first, then refine. Drop any \"This task is not defined yet\" marker once content is real. Aim for \"WHAT A FINISHED TASK LOOKS LIKE.\" Do not require a build plan.

═══ MODE: SPLIT — several pieces ═══
1. PROPOSE breakdown first: 3–10 atomic, independently completable sub-tasks, dependencies first. Confirm with the user.
2. On agreement, CREATE each via CLI:
     ./sprint.sh newtask 'short action-oriented description'
   Fill each new docs/tasks/backlog/ file:
     - **Parent**: $PARENT_NUM   (exact — './sprint.sh newplan \"…\" parent:$PARENT_NUM' matches on this)
     - **Depends on**: previous sub-task number when order matters, else 'none'
     - ## Problem, ## Success criteria, optional ## Notes / ## References — see finished-task shape below
3. TALK THROUGH each child with the REFINE loop (not one-line stubs).
4. KEEP EDGES RECIPROCAL — route every edge change through the lib helpers so both ends stay in sync; never hand-edit one side (run: source docs/sprintbias/lib.sh):
   - for each child, for each id N on its **Depends on** line:  sprintbias_ensure_reciprocal N <child-id>
   - fold the parent into its first child so anything that depended on the whole parent follows it instead of a deleted id:  sprintbias_rewrite_dep_id $PARENT_NUM <first-child-id>  — then, for each id that depended on $PARENT_NUM:  sprintbias_ensure_reciprocal <first-child-id> <that-id>
5. FINISH: original's content lives in children. ${_STAGE_MOVE}Confirm, then retire original: ${_RETIRE_INSTR}

═══ MODE: REFINE — one rough job ═══
For EACH detail:
1. ASK one question — the single most important gap (problem clarity, done definition, scope, dependency, edge case, or a real decision the author must make). One question, no preamble. Prefer sharpening Problem and Success criteria over inventing implementation steps.
2. POLISH — tighten and read back: \"So the crux is …\" Correct before it lands.
3. UPDATE the file immediately — one small atomic edit. Convert the answer into
   instruction in the body (Success criteria when it defines done; otherwise
   Notes as guidance). Delete any matching open question under
   '### Questions for the developer'.
4. MOVE ON — note settled vs thin; return to step 1.

═══ MODE: STRESS-TEST — already looks defined ═══
Pressure-test before work: gaps, assumptions, sharper brief. Open with 2–3 sentences (what it does + verdict: well-defined / roughly-defined / has issues), then Q&A one question at a time, most impactful first, each grounded in a criterion/file/section:
1. GOAL ALIGNMENT: feature goals + live sprint in next/ (see CONTEXT)? Mismatch?
2. SCOPE: right size? Split? Too narrow? Sibling overlap?
3. SUCCESS CRITERIA: verifiable by someone else? Complete vs Problem? Vague/missing edges?
4. ASSUMPTIONS: taken for granted? Referenced files/APIs/patterns still exist? Unstated prereqs?
5. RISK: failure modes, performance, security, compatibility.
6. DEPENDENCIES: Depends on / Dependents real? Undeclared must-lands?
7. ALTERNATIVES: simpler way? Premature lock-in?
Stop after material findings (typically 3–7). With agreement, sharpen Problem/Success and optional Notes/References; put residual analysis in '## Think Notes' before HTML comments ('**Reviewed**: <date>', risks, alternatives, assumptions). Do not change Feature/Created/Depends on/Dependents unless asked. Do not turn Notes into a build script.

WHAT A FINISHED TASK LOOKS LIKE (FILL-IN/REFINE parent and every SPLIT child):
- ## Problem — clear, simple, high-level: what is wrong and why it matters (2–5 short sentences).
- ## Success criteria — what done looks like; checkboxes anyone can verify. Meeting these means done. Instructions from answered questions that define done live here.
- ## Notes — optional hints, plus guidance from answered questions that shape how. Leave empty if nothing useful.
- ## References — optional direct paths to related docs or code. One path per line.
- '### Questions for the developer' — open questions only (with a suggestion). Answered questions are already body instructions; the list holds what is still open.
- Leave ## Completed / ### Files changed for after work.

RULES:
- User-story altitude: problem + done. Implementer chooses how, guided by instructions from answered questions. STRESS-TEST sharpens the brief only.
- One question at a time; wait for the answer.
- Edit as each detail settles: answer → body instruction → delete the question.
- Keep moving — short turns.
- Write the durable brief in Problem and Success criteria. ## Questions holds the stamp, findings, and still-open questions.
- Open questions keep the task out of next/ until answered and turned into instruction.
- WRITES: $TASK_FILE, sub-tasks from ./sprint.sh newtask, and the one next-dependency handoff file below. READ anything to check assumptions; write nothing else.

═══ RECORD THE REFINEMENT — BUMP THE PRE-WORK COUNTER ═══
If this session actually SHARPENED the task's definition (any edit to its Problem, Success criteria, Notes, or Think Notes — the FILL-IN, REFINE, or STRESS-TEST work above), record it ONCE for the whole conversation before you finish:
1. Read the current '**Refined**:' header integer (seed it as 0 if the field is somehow absent) and let N = that value + 1. Set the header line to exactly '**Refined**: N'.
2. Add a short pre-work record — place it just BEFORE any closing '## Questions' section if the file has one (so '## Questions' stays last), else at the END of the file:

    ## Refine (round N)

    **Sharpened:** 1–3 sentences naming what this pass clarified — the scope, criterion, or decision that changed.

This is definition-refinement's own record — a PRE-work operation. Use the heading '## Refine (round N)', NEVER '## Rework': '## Rework' and the '**Reworked**:' header belong to polish's POST-work pass, and this pre-work pass must not touch either of them. Only ever move '**Refined**:'.
Do NOT bump or write anything if the conversation changed nothing (a pure STRESS-TEST that confirmed the task was already clean), and do NOT record on a SPLIT's retired parent — its content moved to fresh children that each start at '**Refined**: 0'.

═══ WHEN THE TASK READS CLEARLY — FINISH, CLOSE, CHAIN ═══
Once the task in front of you (the FILL-IN/REFINE/STRESS-TEST parent, or — for a split — its children) reads as fully defined, do these in order:

1. FINISH: tell the user, and show the final state (the refined task, or the list of children with the original retired). If a \"This task is not defined yet\" marker still remains, remove it — the task is defined now. If this session produced both filled-in sections and a '## Think Notes' block, keep '## Think Notes' ahead of any closing '## Questions' section so the file stays coherent.
${_CLOSE_LOOP_INSTR}

2. FIND THE NEXT DEPENDENCY THAT STILL NEEDS WORK: read this task's '**Depends on**:' line. For each dependency number N, look for docs/tasks/blocked/N-*.md or docs/tasks/backlog/N-*.md. A dependency still needs work if that file exists and does NOT contain a line '**Status: READY**' (in blocked/ that usually means a decision or clarification is open). Among those, pick the most upstream one — the dependency whose OWN '**Depends on**' has no unresolved deps left; break ties by lowest number. Call it <next-id>. If there are NO such dependencies, the chain is complete: say so and STOP — do not spawn or recommend anything.

3. HAND OFF THROUGH THE FILE: into <next-id>'s file, under its ## Notes (create the section if absent), write a short blockquote note capturing ONLY what this conversation decided that <next-id>'s author needs to know — the constraints, choices, and interface details that flow downstream. Start it exactly '> **Context from chat (task $PARENT_NUM):**' so a later run can find and replace it instead of stacking a second copy. Keep it to a few sentences; it is a seed, not a transcript.

4. CHAIN: ${_CONTINUE_INSTR}${_DEMOTE_INSTR}${_EXIT_INSTR}"

# chat is a dialogue, not a one-shot job — sprintbias_run_interactive keeps the
# CLI attached to the terminal so the user answers each question in turn. In
# emit mode the surrounding agent supplies that back-and-forth. In exec mode it
# needs an interactive-capable provider on a real terminal; when that is not
# available the run degrades to a single refinement pass — say so plainly and
# point to the guide, rather than pretending the conversation happened. The
# same sprintbias_interactive_ok that routes the run decides the warning, so the
# two can never disagree.
if [ "$(sprintbias_ai_mode)" = "exec" ] && ! sprintbias_interactive_ok; then
  echo -e "${YELLOW}Note: a live back-and-forth needs an interactive-capable AI CLI (claude or grok) in a real terminal.${NC}"
  echo -e "${YELLOW}Doing a single refinement pass instead. To wire up the full chat experience,${NC}"
  echo -e "${YELLOW}see docs/sprintbias/guides/use_chat.md${NC}"
  echo ""
elif [ "$(sprintbias_ai_mode)" = "exec" ] && sprintbias_interactive_ok; then
  # Same exit contract as chat-folder [d]: the TUI owns the terminal until quit.
  echo -e "${DIM}When finished, type /quit (or quit) to end the session.${NC}"
  echo ""
fi

sprintbias_run_interactive \
  --append-system-prompt "$APPEND_PROMPT" \
  ${_model_args[@]+"${_model_args[@]}"} \
  --tools "Read,Edit,Write,Bash,Grep,Glob" \
  --permissions "auto" \
  --name "chat-${TASK_ID}" \
  "Read the task file at $TASK_FILE, size it up, and start chating it through — one detail at a time."
