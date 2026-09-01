# shellcheck shell=bash
# docs/sprintbias/scripts/gate.sh — the shared workability gate.
#
# Sourced (not executed) helper — no shebang or `set`; the caller provides those,
# and must have sourced lib.sh first. This is NOT a CLI command: there is no
# registry row, no dispatch arm, no help page. It is a library of gate functions.
#
# The gate runs the READY/BLOCKED/COMPLETE workability review on task files. For each
# file it runs the invariant review contract, writes the ## Questions section +
# stamp, applies the dependency-vs-definition rules, and routes the file by
# verdict (BLOCKED → blocked/, COMPLETE → review/, READY stays where it is — or moves
# to a caller-supplied READY_DIR, e.g. `plan start` promoting a vetted backlog
# member into next/). Open items under ### Questions for the developer keep the
# task BLOCKED until each is answered and turned into body instruction; only then
# is READY/COMPLETE promotion allowed. COMPLETE means work is already in the
# codebase — not the docs/tasks/done/ lifecycle folder.
#
# Every surface that may send a task into next/ (the sprint) shares this one
# implementation so verdicts never drift: `gate` (next/ CLI), `plan start`,
# `chat` folder promote, `chat` close-the-loop from blocked/, and `polish`
# REOPEN. The only supported promote is sprintbias_promote_to_sprint (or the
# same READY_DIR=next/ init + review plan start uses in bulk).
#
# Requires from lib.sh: sprintbias_run, sprintbias_ai_mode, sprintbias_ai_tier,
# sprintbias_tier_model, sprintbias_profile_line, sprintbias_review_verdict,
# move_file, sprintbias_log_path.
#
# Usage:
#   sprintbias_gate_init [KIND] [STAY_DIR] [READY_DIR]  # once — invariant context
#   sprintbias_gate_review FILE              # one task: run + route; sets outputs
#   sprintbias_gate_parallel FILE...         # emit-mode orchestration fan-out
#   sprintbias_promote_to_sprint FILE [KIND] # gate then READY→next/ (only entry)
#
# sprintbias_gate_review sets, on return:
#   SPRINTBIAS_GATE_VERDICT  READY | BLOCKED | COMPLETE | EMIT | NOSTAMP | FAILED
#     EMIT    — emit mode: the surrounding agent runs the review and moves the
#               file itself; nothing to count here.
#     NOSTAMP — the review ran but wrote no verdict stamp; file left in place.
#     FAILED  — the review process errored; file left in place.
#   SPRINTBIAS_GATE_LOG      exec-mode log path, else empty
#   SPRINTBIAS_GATE_ERROR    raw failure cause when VERDICT=FAILED (may be empty),
#                          else empty. Callers apply their own default text.

SPRINTBIAS_GATE_BLOCKED_DIR="docs/tasks/blocked"
SPRINTBIAS_GATE_REVIEW_DIR="docs/tasks/review"

# Sprint context — an index of every OTHER task queued in next/ and waiting in
# backlog/. The reviewer sees one task at a time; without this it reads the task
# in isolation, finds that the code the task builds on doesn't exist yet, and —
# blind to the sibling task that will create it — mistakes a sequencing
# dependency for a blocker. With the index it can attribute a missing
# prerequisite to a real queued task, record it in '**Depends on**', and stay
# READY. Built once; identical for every task's review.
_sprintbias_gate_sprint_index() {
  local label dir f id title
  for label in next backlog; do
    dir="docs/tasks/$label"
    [ -d "$dir" ] || continue
    for f in "$dir"/*.md; do
      [ -e "$f" ] || continue
      id="${f##*/}"; id="${id%%-*}"
      title=$(grep -m1 '^# ' "$f" 2>/dev/null | sed 's/^#[[:space:]]*//')
      [ -n "$title" ] || title="${f##*/}"
      printf '  - %s (%s): %s\n' "$id" "$label" "$title"
    done
  done
}

# sprintbias_gate_init [KIND] [STAY_DIR] [READY_DIR]
# Resolve the model/tool surface and build the task-independent context every
# review shares: the emit-mode move instruction, the profile pointer, and the
# next/backlog index block. Call once before sprintbias_gate_review /
# sprintbias_gate_parallel.
#   KIND      log-file kind for sprintbias_log_path (default "gate").
#   STAY_DIR  where a READY task stays, for the emit move instruction's wording
#             (default: "its current location"). Ignored when READY_DIR is set.
#   READY_DIR when set, a READY task is MOVED here instead of staying in place —
#             `plan start` passes next/ so a vetted backlog member is promoted
#             into the sprint. Empty (gate) = READY stays where it was.
sprintbias_gate_init() {
  SPRINTBIAS_GATE_KIND="${1:-gate}"
  local stay_dir="${2:-}"
  SPRINTBIAS_GATE_READY_DIR="${3:-}"

  # Tier-aware: empty MODEL_GATE → opus / grok-4.5; foreign pins coerced.
  SPRINTBIAS_GATE_MODEL="$(sprintbias_tier_model GATE)"
  SPRINTBIAS_GATE_TOOLS="Read,Bash,Grep,Glob,Edit,Write"
  SPRINTBIAS_GATE_PERMISSIONS="auto"
  SPRINTBIAS_GATE_MAX_TURNS=40

  # In emit mode the agent moves files itself per its verdict; fold the moves
  # into the prompt. In exec mode the shell moves them by reading the verdict.
  SPRINTBIAS_GATE_MOVE_INSTR=""
  if [ "$(sprintbias_ai_mode)" = "emit" ]; then
    local ready_instr
    if [ -n "$SPRINTBIAS_GATE_READY_DIR" ]; then
      ready_instr="- READY   → git mv the task file to $SPRINTBIAS_GATE_READY_DIR/ || mv it there"
    else
      local stay_where="its current location"
      [ -n "$stay_dir" ] && stay_where="$stay_dir/"
      ready_instr="- READY   → leave the file in $stay_where"
    fi
    SPRINTBIAS_GATE_MOVE_INSTR="

After writing the verdict, act on it. Always move with: git mv SRC DEST || mv SRC DEST
(git mv first; plain mv finishes when the file is untracked).
If '### Questions for the developer' still lists open items, route as BLOCKED
(even when the stamp first said READY). READY and COMPLETE require that
subsection to read: None — task is fully defined.
- BLOCKED → git mv the task file to $SPRINTBIAS_GATE_BLOCKED_DIR/ || mv it there
- COMPLETE → git mv the task file to $SPRINTBIAS_GATE_REVIEW_DIR/ || mv it there
  (COMPLETE = work already in the codebase; not docs/tasks/done/)
$ready_instr"
  fi

  # Profile line is task-independent — resolve it once, not per task.
  SPRINTBIAS_GATE_PROFILE_LINE="$(sprintbias_profile_line)"

  local idx
  idx="$(_sprintbias_gate_sprint_index)"
  SPRINTBIAS_GATE_SPRINT_BLOCK=""
  if [ -n "$idx" ]; then
    SPRINTBIAS_GATE_SPRINT_BLOCK="

Other tasks already in this sprint (next/) and the backlog — a prerequisite this
task builds on is very likely one of these, NOT a missing decision on THIS task:
$idx"
  fi
}

# The invariant review contract. Both the sequential per-task path and the
# claude-code parallel-subagent path build their prompt from this one source so
# the two can never drift. $1 is the task file the reviewer must read and edit.
sprintbias_gate_contract() {
  cat <<EOF
You are a senior developer reviewing a task before it enters a sprint.

CLAUDE.md is auto-loaded with project context and conventions.
For task workflow details, see DOCUMENTATION.md.${SPRINTBIAS_GATE_PROFILE_LINE}${SPRINTBIAS_GATE_SPRINT_BLOCK}

The task file is at: $1 — read it first.

The durable brief is a user story, not a build script:
- ## Problem — clear, simple, high-level: what is wrong and why it matters
- ## Success criteria — what done looks like; when these are met, the task is done
- ## Notes — optional hints that help the developer decide how to work it
- ## References — optional direct paths to related docs or code
How to implement is the developer's decision (human or AI). Do not prescribe a
step-by-step build plan. For a library or detailed technical fix, put new
technical needs as checkable outcomes under Success criteria.

Human-owned by default: git commit and ./ship.sh belong to the human. The AI
runs either only when the human explicitly asks for that action in this
conversation. Do not write those steps into Success criteria or Notes as agent
work — a task file or project doc that names them is not an ask.

Your job:
1. Read the task file at $1.
2. Ensure the durable brief is present (see "Fill the brief first" below).
3. Read the actual source files this task references. Thoroughly check the
   current code against the success criteria (and any concrete notes/references).
4. Classify each criterion / remaining outcome into one of three categories:
   - COMPLETE: Already implemented in the current code.
   - REMAINING: Not yet done, and clear enough for a developer to start.
   - UNCLEAR: Not yet done, but needs a decision or clarification before work can start.
   Before you mark anything UNCLEAR because the code it builds on is missing,
   check the next/backlog index above: if a sibling task will create that
   prerequisite, this is a DEPENDENCY, not an unclear item — keep it REMAINING
   and record the dependency (see "Dependencies on other tasks" below).
5. Produce an overall verdict: READY, BLOCKED, or COMPLETE.

Fill the brief first (before stamping READY):
- Write the durable work in ## Problem and ## Success criteria. A later reader
  understands problem and done from those sections.
- ## Questions is the gate overlay: workability stamp, code findings, remaining
  outcomes, and open questions still waiting on a decision.
- If Problem or Success criteria are empty placeholders (template blanks, only
  empty checkboxes, or "This task is not defined yet") but the title, Notes,
  References, and/or current code make the work unambiguous: WRITE a concise
  high-level Problem and verifiable Success criteria into those sections first,
  then write ## Questions.
- When a decision is still needed to write those sections, stamp BLOCKED and put
  the decision under '### Questions for the developer'.
- Notes may hold short optional hints and settled guidance from answered
  questions. Leave ## Completed / ### Files changed for after work.

Questions become instructions (simple loop):
1. ASK — put each open decision under '### Questions for the developer' as
   '1. [Question]? (Suggestion: [pick and why])'.
2. GET the answer from the user or agent.
3. CONVERT the answer into clear instruction or guidance (positive, direct,
   concise — style samples of phrasing, not live steps: "Use Postgres for the
   store", "Login accepts email and password"). Never convert an answer into
   "run git commit" or "run ./ship.sh" for the AI — those stay human-owned
   unless the human just asked for that action in this conversation.
4. UPDATE the task body with that instruction: ## Success criteria when it
   defines done; otherwise ## Notes as guidance the implementer follows.
5. DELETE the original question from '### Questions for the developer' — it has
   been answered.

When every question is answered this way, write under that heading:
None — task is fully defined.
READY and COMPLETE use that line. Open questions mean BLOCKED until the loop
finishes (task stays out of next/ while questions remain).

**Bar for an open question (strict — most "decisions" fail this bar):**
An open question is ONLY a product/human fork that changes success criteria or
scope and cannot be chosen from the task + code + specs alone. If you can write
a useful (Suggestion: …), **apply that suggestion as body instruction now**
(Remaining work / Success criteria / Notes) and **do not leave the question on
the list**. Micro-choices are never open questions — examples that must be
folded, not asked: icon set (Lucide vs emoji when the design standard already
picks Lucide), which conformant shell/HTML donor to copy, keep vs rename a
gallery id when shareable links imply keep, frame count within a stated range,
static vs trivial CSS animation, "draw the field the criteria already require".
Implementer judgment ("clear enough to execute") is not a question. Prefer zero
open questions and a concrete Remaining work list over a thorough FAQ.

**READY requires an empty question list.** If any list item remains under
### Questions for the developer, the stamp is BLOCKED (the shell enforces this).

How to handle COMPLETE items (already implemented in code):
- Do NOT suggest removing them. They are context for the developer.
- Briefly note that they're complete and whether the implementation looks correct and clean.
- If the implementation has issues (bugs, missing edge cases, inelegant code), flag that as remaining work.
- COMPLETE is a workability verdict, not the docs/tasks/done/ folder.

A task is READY if:
- ## Problem and ## Success criteria are filled (not template blanks)
- There is remaining work to do
- Remaining outcomes are clear enough to execute without asking questions —
  "clear enough" means a developer can choose how to implement, not that every
  step is pre-written
- No major design decisions on THIS task are unresolved
- It may depend on other tasks finishing first — that is sequencing, not BLOCKED
  (see "Dependencies on other tasks" below).

A task is BLOCKED only if a **decision or clarification** is needed on THIS task:
- Remaining outcomes require decisions the developer hasn't made yet
- Criteria contradict each other, or contradict the current code in a way
  that no other queued task would resolve. Code the task builds on being absent
  because a sibling or backlog task hasn't run yet is NOT a contradiction — it is
  a dependency. Only treat a conflict with current code as needing clarification
  when nothing in the next/backlog index would produce what the task assumes.
- Problem / Success criteria cannot be written without a human answer
- The task is entirely implemented already and there is nothing left to do (mark as COMPLETE instead of BLOCKED — stamp **Status: COMPLETE**, which routes to review/, not done/)

Dependencies on other tasks (sequencing — not a blocked condition):
Do NOT mark a task BLOCKED merely because another task must be completed first —
that is exactly what the dependency field is for. A task waiting on a prerequisite
is DEPENDENT (on hold), not blocked. BLOCKED means a decision or clarification
is needed about THIS task. Use the next/backlog index above to identify
prerequisites: if the code, file, or API this task builds on will be produced by
another task in next/ or backlog/, that is a dependency to record, not a reason
to stamp BLOCKED. If executing this task requires other tasks to be finished
first, ensure the task file records them in a bold '**Depends on**:' field near
the top (after the title), listing the task numbers, e.g.
'**Depends on**: 900-920, 922'. Add the field if it is missing, or update it
if it is incomplete. An unmet dependency keeps the task READY (or COMPLETE if already
implemented): the task runner holds it in next/ until those dependencies reach
review/ or done/, then runs it automatically — no one has to babysit the order.
A prerequisite task being *itself* rough, undefined, or not-yet-reviewed is STILL
a dependency, not a reason to stamp THIS task BLOCKED: that upstream task will get
its own decisions on its own turn. Record it in '**Depends on**' and keep this
task READY. Only a decision or clarification THIS task's developer must supply
makes this task BLOCKED.
Reserve BLOCKED strictly for unresolved decisions, contradictions, or missing
clarifications on this task. The test is "could a developer start this if the
prerequisite tasks were already done and no open questions remained?" — if the
only wait is for other tasks to finish, it is READY and dependent (on hold), not
BLOCKED.

Then update the task file by adding a ## Questions section at the end (before any HTML comments).
If a ## Questions section from a previous review already exists, replace it instead of adding a second one.

Structure the ## Questions section exactly like this:

## Questions

**Status: READY**

(or **Status: BLOCKED** / **Status: COMPLETE** — write the stamp exactly in
that bold form, on its own line, directly under the ## Questions heading.
Nothing else on that line; no free prose between the stamp and the first ### heading.
COMPLETE = work already in the codebase → review/. Never use DONE for this stamp;
done/ is only a lifecycle folder after human approval.)

### Already complete
Code findings only: what is already implemented and verified (paths/lines when useful).
Note quality concerns. If nothing is implemented yet: "None — no matching
implementation found." then brief bullets of what you checked. Do not write
process or emptiness commentary ("bare template", "body is empty but title is
clear", "always true before define").

### Remaining work
Audit of what is still left against the success criteria — for the implementer
who runs work. Short concrete outcomes that complement Problem and Success
criteria (the durable brief already holds the full definition).

### Questions for the developer
Open questions waiting on a human product decision — numbered list only:
'1. [Question]? (Suggestion: [pick and why])'
Leave this list empty whenever possible. If you already know the pick, write it
into Remaining work / Notes and omit the question entirely (do not park a
Suggestion here "for later").

When the list is empty, write exactly:
None — task is fully defined.

READY and COMPLETE use that line. A remaining open question means BLOCKED.
A READY stamp with any list item under this heading is an integrity error.

If the verdict is BLOCKED, ALSO add a '## BLOCKED' section directly above ## Questions:

## BLOCKED

One short plain-English paragraph: what decision is still open and what answer
would unblock the work. Another agent (or the developer) should understand it
from this section alone. End by pointing to chat:
"Run ./sprint.sh chat <task-number> to answer these questions and turn each
answer into instruction in the task body." Then re-enter through the gate.

If the verdict is not BLOCKED, delete any ## BLOCKED section left from a previous review.

You may only use Edit/Write on the task file at $1.
EOF
}

# ── Orchestration-capable fast path: parallel subagents ─────────────────────
# On claude-code / grok-build in emit mode, one subagent per task is faster than
# N sequential prompts; reviews are independent. Subagent wording comes from
# sprintbias_subagent_parallel_dispatch (Task tool vs spawn_subagent). Args: the
# task file paths to review (one subagent each).
sprintbias_gate_parallel() {
  local count=$# f _parallel_files=""
  for f in "$@"; do
    _parallel_files="${_parallel_files}
- ${f}"
  done

  sprintbias_run -p "You are orchestrating a parallel task-definition review of $count tasks.

$(sprintbias_subagent_parallel_dispatch gate) Each subagent reviews exactly one file and
follows this contract verbatim, substituting its assigned file path.
$(sprintbias_subagent_no_nest)

COMPLETE SET — gate EVERY listed file. Do not sample, skip, or stop early after a
subset (hosts sometimes limit concurrent subagents; if so, run further waves until
every file has a verdict). The final summary must have exactly $count rows — one
per listed path. Missing a path is a failure of this orchestration, not a pass.

────────────────────────────────────────────────────────────
$(sprintbias_gate_contract "<the task file assigned to this subagent>")${SPRINTBIAS_GATE_MOVE_INSTR}
────────────────────────────────────────────────────────────

Task files to review (one subagent each — all $count required):${_parallel_files}

When every subagent has finished, print a summary table: one row per task with
its file name and final verdict (READY / BLOCKED / COMPLETE). Count the rows —
if fewer than $count, launch another wave for the missing files and finish them."
}

# If the review stamped BLOCKED but didn't write a ## BLOCKED section, synthesize
# one from the open questions so the file stands alone. The reason must live IN
# the file — screen output is evanescent and other agents can only work what is
# written down. $1 is the (already-moved) blocked task file.
_sprintbias_gate_ensure_blocked_section() {
  local file="$1" name
  name="$(basename "$file")"
  grep -q '^## BLOCKED' "$file" && return 0
  # Extract the questions BEFORE opening the append redirection — reading the
  # file while appending to it would copy the half-written section back into
  # itself.
  local _qs
  _qs=$(awk '/^## Questions[[:space:]]*$/{s=""; f=1} f{s=s $0 "\n"} END{printf "%s", s}' "$file" \
          | sed -n '/^### Questions for the developer/,$p' | sed '1d')
  {
    echo ""
    echo "## BLOCKED"
    echo ""
    echo "Needs a decision (gate review $(date +%Y-%m-%d))."
    echo "Answer each question below, write the answer as instruction in the"
    echo "task body, delete the question, then re-enter via the gate."
    echo "Chat: ./sprint.sh chat ${name%%-*}"
    echo "$_qs"
  } >> "$file" \
    || echo "  ⚠ Could not write ## BLOCKED section to $file"
}

# sprintbias_gate_review FILE
# Run the gate on ONE task file in the current AI mode, apply its verdict, and
# report the outcome via the SPRINTBIAS_GATE_* output variables (see header).
# In exec mode the file is moved here (BLOCKED → blocked/, COMPLETE → review/); in
# emit mode the surrounding agent performs the move per the folded-in instruction.
# shellcheck disable=SC2034  # SPRINTBIAS_GATE_VERDICT/LOG/ERROR are outputs read by callers
sprintbias_gate_review() {
  local task_file="$1" task_name
  task_name="$(basename "$task_file")"
  SPRINTBIAS_GATE_LOG=""
  SPRINTBIAS_GATE_ERROR=""

  local prompt
  prompt="$(sprintbias_gate_contract "$task_file")${SPRINTBIAS_GATE_MOVE_INSTR}"

  local _model_args=()
  [ -n "$SPRINTBIAS_GATE_MODEL" ] && _model_args=(--model "$SPRINTBIAS_GATE_MODEL")

  # Emit mode: print the review prompt for the current agent to run and move.
  if [ "$(sprintbias_ai_mode)" = "emit" ]; then
    sprintbias_run -p "$prompt" \
      ${_model_args[@]+"${_model_args[@]}"} \
      --tools "$SPRINTBIAS_GATE_TOOLS" --permissions "$SPRINTBIAS_GATE_PERMISSIONS"
    SPRINTBIAS_GATE_VERDICT="EMIT"
    return 0
  fi

  local log_file
  log_file="$(sprintbias_log_path "$SPRINTBIAS_GATE_KIND" "$task_name")"
  SPRINTBIAS_GATE_LOG="$log_file"

  if sprintbias_run -p "$prompt" \
    ${_model_args[@]+"${_model_args[@]}"} \
    --tools "$SPRINTBIAS_GATE_TOOLS" \
    --permissions "$SPRINTBIAS_GATE_PERMISSIONS" \
    --max-turns "$SPRINTBIAS_GATE_MAX_TURNS" \
    --output-format json > "$log_file"; then

    # Route by the review's verdict stamp (anchored — body text that merely
    # mentions the verdict vocabulary cannot mis-route, see lib.sh).
    # Open questions still on the list keep the task BLOCKED until each is
    # answered and turned into body instruction.
    _verdict="$(sprintbias_review_verdict "$task_file")"
    # Invariant: open questions mean BLOCKED — rewrite the stamp (not only the
    # route) so next/ never keeps a READY file that work must refuse.
    if { [ "$_verdict" = "READY" ] || [ "$_verdict" = "COMPLETE" ]; } \
         && sprintbias_has_open_questions "$task_file"; then
      _verdict="BLOCKED"
      sprintbias_set_review_status "$task_file" "BLOCKED" || true
      echo "  ⚠ Open questions remain — overriding stamp to BLOCKED (cannot stay READY)" >&2
    fi
    case "$_verdict" in
      BLOCKED)
        move_file "$task_file" "$SPRINTBIAS_GATE_BLOCKED_DIR/$task_name"
        _sprintbias_gate_ensure_blocked_section "$SPRINTBIAS_GATE_BLOCKED_DIR/$task_name"
        SPRINTBIAS_GATE_VERDICT="BLOCKED"
        ;;
      COMPLETE)
        move_file "$task_file" "$SPRINTBIAS_GATE_REVIEW_DIR/$task_name"
        SPRINTBIAS_GATE_VERDICT="COMPLETE"
        ;;
      READY)
        # Default (gate): READY stays put. With READY_DIR set (plan start),
        # a vetted member is promoted — moved into next/ — only now that it
        # graded READY, so unready work never touches the sprint.
        # Re-vet of a member already in next/: same path → no-op (do not
        # call move_file on identical src/dest).
        if [ -n "${SPRINTBIAS_GATE_READY_DIR:-}" ]; then
          _ready_dest="$SPRINTBIAS_GATE_READY_DIR/$task_name"
          if [ ! "$task_file" -ef "$_ready_dest" ] 2>/dev/null; then
            move_file "$task_file" "$_ready_dest"
          fi
          unset _ready_dest
        fi
        SPRINTBIAS_GATE_VERDICT="READY"
        ;;
      *)
        SPRINTBIAS_GATE_VERDICT="NOSTAMP"
        ;;
    esac
    unset _verdict
  else
    SPRINTBIAS_GATE_ERROR=$(grep -oE 'API Error[^"]*' "$log_file" 2>/dev/null | tail -1 || true)
    SPRINTBIAS_GATE_VERDICT="FAILED"
  fi
  return 0
}

# sprintbias_promote_to_sprint FILE [KIND]
# The only supported way to move a task into next/ (the sprint). Runs the shared
# workability gate; routes by verdict:
#   READY    → next/   (stamped workable)
#   BLOCKED  → blocked/ (reason written into the file)
#   COMPLETE → review/ (work already in the codebase)
# Never raw-mv into next/. KIND is the log-file kind (default: promote).
# Sets SPRINTBIAS_GATE_* like sprintbias_gate_review. Returns 0 after a completed
# review attempt; non-zero only when the file is missing.
sprintbias_promote_to_sprint() {
  local task_file="${1:?sprintbias_promote_to_sprint: file required}"
  local kind="${2:-promote}"
  if [ ! -f "$task_file" ]; then
    SPRINTBIAS_GATE_VERDICT="FAILED"
    SPRINTBIAS_GATE_ERROR="file not found: $task_file"
    SPRINTBIAS_GATE_LOG=""
    return 1
  fi
  mkdir -p docs/tasks/next "$SPRINTBIAS_GATE_BLOCKED_DIR" "$SPRINTBIAS_GATE_REVIEW_DIR"
  # Always re-init so READY_DIR is next/ even if a prior stay-in-place gate init
  # ran in this process.
  sprintbias_gate_init "$kind" "docs/tasks/next" "docs/tasks/next"
  sprintbias_gate_review "$task_file"
}

# Human one-liner for a promote/gate verdict (stdout). Safe when VERDICT unset.
sprintbias_promote_summary() {
  local name="${1:-task}"
  case "${SPRINTBIAS_GATE_VERDICT:-}" in
    READY)    echo "✓ READY → next/: $name" ;;
    BLOCKED)  echo "⊘ BLOCKED → blocked/: $name" ;;
    COMPLETE) echo "✓ COMPLETE → review/: $name" ;;
    EMIT)     echo "▸ Gate review emitted for $name — run the prompt above (READY → next/)." ;;
    NOSTAMP)  echo "✗ gate NOSTAMP: $name — left in place (no verdict written)" ;;
    FAILED)
      echo "✗ gate FAILED: $name — left in place"
      [ -n "${SPRINTBIAS_GATE_ERROR:-}" ] && echo "  ${SPRINTBIAS_GATE_ERROR}"
      [ -n "${SPRINTBIAS_GATE_LOG:-}" ] && echo "  log: $SPRINTBIAS_GATE_LOG"
      ;;
    *)        echo "? gate ${SPRINTBIAS_GATE_VERDICT:-unknown}: $name" ;;
  esac
}
