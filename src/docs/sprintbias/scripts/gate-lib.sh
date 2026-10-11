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
# member into next/). The reviewer decides each open call (the finishing rule,
# sprintbias_assume_rule) and records it in ## Notes; the shell takes any
# (Suggestion: …) left on the list and stamps BLOCKED only for a question with
# none. COMPLETE means work is already in the codebase — not the
# docs/tasks/done/ lifecycle folder.
#
# Every surface that may send a task into next/ (the sprint) shares this one
# implementation so verdicts never drift: `gate` (next/ CLI), `plan start`,
# `chat` folder promote, `chat` close-the-loop from blocked/, and `polish`
# REOPEN. The only supported promote is sprintbias_promote_to_sprint (or the
# same READY_DIR=next/ init + review plan start uses in bulk).
#
# Requires from lib.sh: sprintbias_run, sprintbias_ai_mode, sprintbias_ai_tier,
# sprintbias_tier_model, sprintbias_orient, sprintbias_review_verdict,
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
Route by the stamp you wrote (the contract above says when each applies):
- BLOCKED → git mv the task file to $SPRINTBIAS_GATE_BLOCKED_DIR/ || mv it there
- COMPLETE → git mv the task file to $SPRINTBIAS_GATE_REVIEW_DIR/ || mv it there
  (COMPLETE = work already in the codebase; not docs/tasks/done/)
$ready_instr
Then, when its ## Grounding lists conflicts, print them for the human:
▸ Conflicts noted in <task name>:
    - <each conflict line, as written>
    Disagree? → ./sprint.sh newtask \"<the change you want>\""
  fi

  # Orientation is task-independent — resolve it once, not per task.
  SPRINTBIAS_GATE_ORIENT="$(sprintbias_orient)"

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

${SPRINTBIAS_GATE_ORIENT}${SPRINTBIAS_GATE_SPRINT_BLOCK}

The task file is at: $1 — read it first.

The durable brief is a user story, not a build script:
- ## Problem — clear, simple, high-level: what is wrong and why it matters
- ## Done when (automated) — what done looks like, each outcome with the test or
  command that proves it, written in backticks (\`bash docs/tests/test-x.sh\`).
  When these pass, an agent may land the task.
- ## Signoff (human) — what only a person can judge (user stories to try,
  screens to look at); checked at sign-off before done/
- ## Notes — optional hints that help the developer decide how to work it
- ## References — optional direct paths to related docs or code
How to implement is the developer's decision (human or AI). Do not prescribe a
step-by-step build plan. For a library or detailed technical fix, put new
technical needs as checkable outcomes under Done when (automated).
An older task with ## Success criteria instead: that section reads as Done when
(automated). Rename its heading to ## Done when (automated) and add
## Signoff (human) after it when you sharpen it.

Human-owned by default: git commit and ./ship.sh belong to the human. The AI
runs either only when the human explicitly asks for that action in this
conversation. Do not write those steps into Done when, Signoff or Notes as agent
work — a task file or project doc that names them is not an ask.

Your job:
1. Read the task file at $1.
2. Ensure the durable brief is present (see "Fill the brief first" below).
3. Read the actual source files this task references. Thoroughly check the
   current code against Done when (automated) (and any concrete notes/references).
4. Sort each outcome: COMPLETE (already in the code), REMAINING (still to do),
   or a call to decide (see "Questions in the gate"). Code missing because a
   queued task will build it is a dependency (see "Dependencies").
5. Ground the task: write or complete its ## Grounding section (see "Grounding"
   below), settling each conflict in place.
6. Produce an overall verdict: READY, BLOCKED, or COMPLETE.

Fill the brief first (before stamping READY):
- Write the durable work in ## Problem, ## Done when (automated) and
  ## Signoff (human). Split a mixed list: what a test or command proves goes
  under Done when (automated); what needs a person's judgment goes under
  Signoff (human).
- Done when (automated) names at least one test or command in backticks — the
  existing suite script that covers the change, or the new test the work adds
  (name its path). READY requires this (the shell enforces it).
- Template blanks with a clear title, Notes, References or code: write a
  concise Problem and a testable Done when (automated) from them.
- Notes may hold short hints and the calls you made. Leave ## Completed /
  ### Files changed for after work.

$(sprintbias_grounding_rule)

$(sprintbias_assume_rule)

Questions in the gate: decide each one. Write the pick into the body (Done when
when a test proves it, Signoff (human) when a person checks it, otherwise
Notes) and record it in ## Notes as - Decided: X, because Y. Fold micro-choices
and implementer judgment without a line. '### Questions for the developer'
then reads: None — task is fully defined. READY and COMPLETE require that
line; the shell takes any (Suggestion: …) left there as the answer and stamps
BLOCKED for a question without one.

Verdicts:
- READY — Problem and Done when (automated) are filled, Done when names a test
  or command in backticks, work remains, and a developer can start. Waiting on
  other tasks is fine (see Dependencies).
- COMPLETE — everything is already in the code (stamp **Status: COMPLETE**;
  it routes to review/, not done/). Note what is implemented and any defect
  as remaining work.
- BLOCKED — the task cannot start: no reasonable reading of it exists (its
  criteria contradict each other or the code, and no queued task resolves
  that), or it needs access or credentials only the person holds. A person-only
  check is never a reason: move it to ## Signoff (human) and stamp READY.

Dependencies (sequencing, never BLOCKED): when this task builds on work another
task in next/ or backlog/ will produce — even a rough one — record those ids
in a bold '**Depends on**:' field near the top (e.g. '**Depends on**: 900-920,
922'), adding or completing it, and keep the verdict. The runner holds the task
until each prerequisite lands (review/ with a proof line) or reaches done/.

Then add a ## Questions section at the end of the task file (before any HTML
comments), replacing one left by a previous review:

## Questions

**Status: READY**

(or **Status: BLOCKED** / **Status: COMPLETE** — that bold stamp on its own
line directly under ## Questions, nothing else on the line. Never DONE.)

### Already complete
Code findings: what is already implemented and verified (paths/lines when
useful) and any quality concern. Nothing yet: "None — no matching
implementation found." and brief bullets of what you checked.

### Remaining work
Short concrete outcomes still left against Done when (automated), for the
implementer who runs work.

### Questions for the developer
None — task is fully defined.

For BLOCKED, also add a '## BLOCKED' section directly above ## Questions: one
plain paragraph naming what is missing (the reading, or the access) and what
would let the work start, ending with: Run ./sprint.sh chat <task-number>.
Otherwise delete any ## BLOCKED section left from a previous review.

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
    echo "Cannot start yet (gate review $(date +%Y-%m-%d)): a question below has no"
    echo "reasonable answer. Write the answer into the body and delete the question:"
    echo "./sprint.sh chat ${name%%-*} — then run it: ./sprint.sh work ${name%%-*}"
    echo "$_qs"
  } >> "$file" \
    || echo "  ⚠ Could not write ## BLOCKED section to $file"
}

# Write the ## BLOCKED reason for a READY stamp the shell refused because the
# task's Done when (automated) names no test or command. $1 is the task file
# (still in place; the BLOCKED route moves it next).
_sprintbias_gate_untestable_section() {
  local file="$1" name
  name="$(basename "$file")"
  grep -q '^## BLOCKED' "$file" && return 0
  {
    echo ""
    echo "## BLOCKED"
    echo ""
    echo "Done when (automated) names no test or command (gate review $(date +%Y-%m-%d))."
    echo "Name the test or command that proves each outcome, in backticks: the suite"
    echo "script that covers the change, or the new test the work adds. Then re-enter"
    echo "via the gate: ./sprint.sh chat ${name%%-*} — then run it: ./sprint.sh work ${name%%-*}"
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
  SPRINTBIAS_GATE_CONFLICTS=""

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
    # Invariant: a question with no suggestion means BLOCKED — rewrite the
    # stamp (not only the route) so next/ never keeps a READY file work refuses.
    # Speed first: take every (Suggestion: …) as the answer before judging.
    if sprintbias_has_open_questions "$task_file"; then
      sprintbias_accept_suggestions "$task_file" >/dev/null 2>&1 || true
    fi
    if { [ "$_verdict" = "READY" ] || [ "$_verdict" = "COMPLETE" ]; } \
         && sprintbias_has_open_questions "$task_file"; then
      _verdict="BLOCKED"
      sprintbias_set_review_status "$task_file" "BLOCKED" || true
      echo "  ⚠ A question has no suggested answer — overriding stamp to BLOCKED" >&2
    fi
    # Invariant: READY needs a testable Done when (automated) — a test or
    # command in backticks — so the worker can prove the task done.
    if [ "$_verdict" = "READY" ] && ! sprintbias_done_when_testable "$task_file"; then
      _verdict="BLOCKED"
      sprintbias_set_review_status "$task_file" "BLOCKED" || true
      _sprintbias_gate_untestable_section "$task_file"
      echo "  ⚠ Done when (automated) names no test or command — overriding stamp to BLOCKED (cannot stay READY)" >&2
    fi
    # Surface the conflicts the review settled under ## Grounding, so the human
    # sees them now — not only when they next open the file.
    SPRINTBIAS_GATE_CONFLICTS="$(sprintbias_grounding_conflicts "$task_file")"
    if [ -n "$SPRINTBIAS_GATE_CONFLICTS" ]; then
      echo "  ▸ Conflicts noted in $task_name (## Grounding):" >&2
      printf '%s\n' "$SPRINTBIAS_GATE_CONFLICTS" | sed 's/^/    /' >&2
      echo "    Disagree? → ./sprint.sh newtask \"<the change you want>\"" >&2
    fi
    case "$_verdict" in
      BLOCKED)
        # A member re-gated from blocked/ (plan start) is already in place.
        [ "$task_file" -ef "$SPRINTBIAS_GATE_BLOCKED_DIR/$task_name" ] 2>/dev/null \
          || move_file "$task_file" "$SPRINTBIAS_GATE_BLOCKED_DIR/$task_name"
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
    BLOCKED)  echo "⊘ BLOCKED → blocked/: $name → ./sprint.sh chat ${name%%-*}" ;;
    COMPLETE) echo "✓ COMPLETE → review/: $name" ;;
    EMIT)     echo "▸ Gate review emitted for $name — run the prompt above (READY → next/)." ;;
    NOSTAMP)  echo "✗ gate NOSTAMP: $name — left in place (no verdict written) → retry: ./sprint.sh work ${name%%-*}" ;;
    FAILED)
      echo "✗ gate FAILED: $name — left in place"
      [ -n "${SPRINTBIAS_GATE_ERROR:-}" ] && echo "  ${SPRINTBIAS_GATE_ERROR}"
      [ -n "${SPRINTBIAS_GATE_LOG:-}" ] && echo "  log: $SPRINTBIAS_GATE_LOG"
      ;;
    *)        echo "? gate ${SPRINTBIAS_GATE_VERDICT:-unknown}: $name" ;;
  esac
}
