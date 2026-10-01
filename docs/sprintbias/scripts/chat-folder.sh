#!/usr/bin/env bash
# shellcheck disable=SC2207
set -euo pipefail

# chat-folder.sh — Express one-at-a-time sweep of a single stage folder
# (blocked/, next/, or backlog/). Reached via `./sprint.sh chat <stage>` —
# chat.sh's dispatcher validates the stage name and routes here. This is the
# THIRD case of chat's grammar, completing `chat [target]`:
#   chat            → walk the whole sprint's structural health (chat-sprint.sh)
#   chat <id>       → chat one task through (chat.sh)
#   chat <folder>   → this: a fast verdict-first sweep of one stage folder
#
# It absorbs the retired `triage` verb: auto-assess each task, you decide per
# task (commit-to-sprint/define/kill/skip/quit), moving briskly through the queue.
# Commit-to-sprint ([w] from backlog/ or blocked/) always runs the shared
# workability gate before next/ — never a raw promote.
#
# TWO-TIER by model to keep triage's fast tempo: the per-task verdict runs on
# the cheap TRIAGE model (single-shot STATUS/SUMMARY/RECOMMENDATION); only
# escalating a task to "define it" hands it to chat.sh, whose full conversation
# runs on the strongest TALK model. Fast cheap sort by default, full depth only
# where you ask for it.
#
# Dependency resolution is INTRINSIC to chat and runs on every file the sweep
# analyzes, exactly as it does for `chat <id>` and the no-arg walk: whenever a
# swept task's `Depends on` points into blocked/, the sweep lifts and defines
# that dependency (via the shared sprintbias_next_blocked_resolution helper and
# chat's own fresh-context chain) so the dependent task can actually be worked.
# The folder argument only selects WHICH files are swept.  See: help chat

# ── Config ───────────────────────────────────────────────────────────
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"
# Promote into next/ only via the shared gate (never raw mv).
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/gate-lib.sh"

STAGE="${1:-}"
case "$STAGE" in
  blocked|next|backlog) : ;;
  *)
    echo "Usage: chat <folder>   (folder must be one of: blocked, next, backlog)"
    exit 1 ;;
esac
DIR="docs/tasks/$STAGE"

# Colours (RED/YELLOW/BLUE/CYAN/DIM/BOLD/NC) come from lib.sh.
timeout_sec=120
# The per-task verdict is a single-shot classification (three lines out). Cap
# turns so a misbehaving model can't burn a long session before the wall-clock
# timeout fires — same guard triage/define/split use.
MAX_TURNS=15
AI_MODE="$(sprintbias_ai_mode)"

# Cheap model for the fast verdict pass (as the old triage did). The deep
# "define it" path shells to chat.sh, which picks the strong TALK model itself.
# Coerce foreign pins; empty → provider strong default (grok-4.5 / opus).
_triage_model="$(sprintbias_tier_model TRIAGE)"
_model_args=()
[ -n "$_triage_model" ] && _model_args=(--model "$_triage_model")

trap 'echo ""; echo "Sweep interrupted."; exit 130' INT TERM

# ── Collect tasks in this folder, numerically ─────────────────────────
all_files=()
if [ -d "$DIR" ]; then
  IFS=$'\n' all_files=($(
    find "$DIR" -maxdepth 1 -type f -name '*.md' -exec basename {} \; \
      | awk -F- '/^[0-9]+-/ { print $0 }' \
      | sort -t- -k1,1n \
      | sed "s|^|$DIR/|"
  )) || true
  unset IFS
fi

total=${#all_files[@]}
if [ "$total" -eq 0 ]; then
  echo "▸ Sweep $STAGE/"
  echo "  $DIR/ is empty — nothing to walk."
  exit 0
fi

echo -e "${CYAN}=== Sweep $STAGE/: $total task(s), one at a time ===${NC}"

# ── Shared dependency-resolution block (task 225's helper) ────────────
# Written once in lib.sh so the no-arg sprint walk, `chat <id>`, and this folder
# sweep all resolve a dependency that points into blocked/ identically.
NEXT_BLOCKED_RESOLUTION="$(sprintbias_next_blocked_resolution)"

# blocked_deps FILE -> space-separated dependency ids that currently sit in
# blocked/ (need a decision or clarification). The dependent is on hold until
# those resolve; the sweep lifts them via the shared resolution above.
blocked_deps() {
  local file="$1" u out=""
  for u in $(sprintbias_unmet_deps "$file"); do
    if sprintbias_find_task "$u" docs/tasks/blocked >/dev/null 2>&1; then
      out="$out $u"
    fi
  done
  printf '%s' "${out# }"
}

# ── Emit mode: hand the whole sweep to the surrounding agent ──────────
# The agent IS the model here, so there is no separate cheap/strong split to
# make — instead the tempo is a prompt contract: fast verdict first, go deep
# ONLY on request. Dependency resolution rides along on every file.
if [ "$AI_MODE" = "emit" ]; then
  _file_list=$(printf '%s\n' "${all_files[@]}")
  sprintbias_run -p "You are sweeping the $STAGE/ task folder with the developer, one task at a time — a fast verdict-first sort, NOT a full conversation on every file. Rip through the queue; go deep only where asked.

$(sprintbias_orient)

Tasks to sweep, in order:
$_file_list

For EACH task in order:
1. Read the task file and do a QUICK check of the current codebase — a fast size-up, not a deep review.
2. Give a fast VERDICT: task name, stage ($STAGE/), a STATUS (COMPLETE/BLOCKED/UNDEFINED/READY/STALE), a one-sentence summary, and a one-sentence recommendation. Keep it tight — this is the cheap sort pass.
   COMPLETE = work already in the codebase (not "file is in done/").
   READY = clear enough to work. Open **Depends on** alone is NOT blocked — the task is dependent (on hold); work holds ordered tasks until deps finish.
   BLOCKED = a decision or clarification is needed on THIS task. UNDEFINED = too thin to act on yet. Never mark BLOCKED only because another task is still open.
3. Offer the developer the choice:
   [w] work it   — depends on stage:
                   next/ → start it (git mv next/ → doing/)
                   blocked|backlog → COMMIT TO SPRINT via the shared gate only:
                     bash docs/sprintbias/scripts/promote-to-sprint.sh <file>
                     That runs the workability gate: READY → next/, BLOCKED → blocked/
                     (reason in file), COMPLETE → review/. NEVER raw git mv into next/.
   [d] define it — go DEEP: run './sprint.sh chat <id>' so the full chat conversation (strongest model) refines the task and closes the loop. This is the only step that escalates past the fast verdict.
   [k] kill it   — delete after confirming: git rm -f PATH || rm -f PATH
   [s] skip      — leave it where it is
   [q] quit      — stop the sweep
4. Act on the choice within the task pipeline. Entry into next/ is ONLY via promote-to-sprint.sh (gate). Other moves: git mv SRC DEST || mv SRC DEST. Always delete with: git rm -f PATH || rm -f PATH. Then continue to the next task.

DEPENDENCY RESOLUTION — only when a dep sits in blocked/ (needs a decision or clarification), not for ordinary open deps:
When a swept task's '**Depends on**:' names a task that currently sits in blocked/, that dependency still needs a decision and must be resolved before the dependent can run. Resolve it per the shared rule below. A dep that is merely still in backlog/next/doing is normal ordering — the dependent is on hold, not BLOCKED; do not force a define on the dependent.

$NEXT_BLOCKED_RESOLUTION

Be concise and move briskly. One task at a time; wait for the developer between tasks." \
    ${_model_args[@]+"${_model_args[@]}"} \
    --tools "Read,Edit,Write,Bash,Grep,Glob"
  exit 0
fi

# ── Exec mode: interactive loop ──────────────────────────────────────
worked=0
defined=0
killed=0
skipped=0

mkdir -p docs/tasks/next docs/tasks/doing docs/tasks/review

for i in "${!all_files[@]}"; do
  file="${all_files[$i]}"
  idx=$((i + 1))

  # A prior define action may have moved the file out of this folder.
  if [ ! -f "$file" ]; then
    echo -e "\n${DIM}[$idx/$total] (moved or deleted, skipping)${NC}"
    continue
  fi

  taskname=$(basename "$file")

  # Headless one-shot can take a while with no CLI output until it returns.
  echo ""
  echo -e "${DIM}[$idx/$total] $taskname — thinking, wait just a minute…${NC}"

  # ── Fast verdict — cheap TRIAGE model, single shot ─────────────────
  _verdict_prompt="You are sweeping a task file from $STAGE/.

$(sprintbias_orient)
Read the task file at: $file

Then do a quick check of the current codebase to assess the task's status.

Output EXACTLY three lines in this format:

STATUS: <one of: COMPLETE, BLOCKED, UNDEFINED, READY, STALE>
SUMMARY: <one sentence describing what this task is about>
RECOMMENDATION: <one sentence telling the user what to do with it>

Status definitions:
- COMPLETE: Work has already been completed on this task (already present in the codebase). Not the same as the done/ folder — the file may still sit in $STAGE/ until the developer moves it.
- BLOCKED: A decision or clarification is needed on THIS task before work can start (unresolved choice, open question, contradiction, or hollow criteria that force a human answer). An open **Depends on** line alone is NOT blocked — that is dependent/on hold.
- UNDEFINED: Too thin to act on yet — lacks a clear problem statement or actionable success criteria (prefer UNDEFINED for thin writing; BLOCKED when a concrete decision/clarification is required).
- READY: The task is well-defined, relevant, and ready to be worked. Unfinished prerequisites listed under **Depends on** mean the task is dependent (on hold) — normal pipeline ordering; ./sprint.sh work holds it until those deps finish. Still say READY (not BLOCKED).
- STALE: The task is not wrong but feels low-priority or superseded by other work

Rules:
- Be conservative: if in doubt, say READY
- NEVER choose BLOCKED or UNDEFINED only because **Depends on** names another open task
- Keep SUMMARY and RECOMMENDATION each to ONE sentence
- Do not output anything else"

  verdict=$(run_with_timeout_dots "$timeout_sec" sprintbias_run -p "$_verdict_prompt" \
    ${_model_args[@]+"${_model_args[@]}"} --max-turns "$MAX_TURNS" --skip-permissions) || true

  status=$(echo "$verdict" | grep -oE '^STATUS: (COMPLETE|DONE|BLOCKED|UNDEFINED|READY|STALE)' | head -1 | sed 's/^STATUS: //' || true)
  if [ -z "$status" ]; then
    status=$(echo "$verdict" | grep -oE '\b(COMPLETE|DONE|BLOCKED|UNDEFINED|READY|STALE)\b' | head -1 || true)
  fi
  # Legacy model slip: older prompts used DONE for the same meaning.
  [ "$status" = "DONE" ] && status="COMPLETE"
  [ -z "$status" ] && status="UNKNOWN"

  summary=$(echo "$verdict" | grep '^SUMMARY:' | head -1 | sed 's/^SUMMARY: //' || true)
  [ -z "$summary" ] && summary="(no summary returned)"

  recommendation=$(echo "$verdict" | grep '^RECOMMENDATION:' | head -1 | sed 's/^RECOMMENDATION: //' || true)
  [ -z "$recommendation" ] && recommendation="(no recommendation returned)"

  # Dependency awareness — deps of this task that are stuck in blocked/. A
  # dependent task can't be worked until these are defined; [d] resolves them
  # (chat.sh's chain lifts the most-upstream one first).
  bdeps="$(blocked_deps "$file")"

  # ── Display ────────────────────────────────────────────────────────
  echo ""
  echo -e "${BOLD}[$idx/$total] $taskname${NC}"
  echo -e "  Stage:  ${BLUE}$STAGE/${NC}"
  if [ "$status" = "UNKNOWN" ]; then
    echo -e "  Status: ${DIM}(timed out)${NC}"
  elif [ "$status" = "COMPLETE" ]; then
    echo -e "  Status: ${CYAN}COMPLETE${NC} — work already completed on this task"
  elif [ "$status" = "BLOCKED" ]; then
    echo -e "  Status: ${RED}BLOCKED${NC} — needs a decision or clarification (not merely waiting on a dep)"
  elif [ "$status" = "UNDEFINED" ]; then
    echo -e "  Status: ${RED}UNDEFINED${NC} — too thin; needs definition before it can be worked"
  elif [ "$status" = "STALE" ]; then
    echo -e "  Status: ${YELLOW}$status${NC}"
  elif [ "$status" = "READY" ]; then
    echo -e "  Status: ${GREEN}READY${NC}"
  else
    echo -e "  Status: $status"
  fi
  echo "  $summary"
  echo -e "  ${DIM}$recommendation${NC}"
  if [ -n "$bdeps" ]; then
    # Dep in the blocked/ *folder* (needs decision/clarification) — not ordinary open Depends on.
    echo -e "  ${RED}⚠ depends on $bdeps (in blocked/ — needs decision/clarification); [d] lifts it${NC}"
  fi
  echo ""
  case "$STAGE" in
    next) _w_label="Start it" ;;
    *)    _w_label="Commit to sprint (gate)" ;;
  esac
  echo -e "  ${BOLD}[w]${NC} $_w_label  ${BOLD}[d]${NC} Define it (go deep)  ${BOLD}[k]${NC} Kill it  ${BOLD}[s]${NC} Skip  ${BOLD}[q]${NC} Quit"
  printf "  > "
  read -r choice </dev/tty 2>/dev/null || choice="s"

  # ── Act ────────────────────────────────────────────────────────────
  case "$choice" in
    w|W)
      case "$STAGE" in
        blocked|backlog)
          # Invariant: nothing enters next/ without the shared workability gate.
          # Triage STATUS is advisory only — gate decides READY / BLOCKED / COMPLETE.
          echo -e "  ${BLUE}-> Gating before next/…${NC}"
          sprintbias_promote_to_sprint "$file" "chat-${STAGE}"
          echo -e "  ${CYAN}$(sprintbias_promote_summary "$taskname")${NC}"
          [ -n "${SPRINTBIAS_GATE_LOG:-}" ] && [ "${SPRINTBIAS_GATE_VERDICT:-}" = "FAILED" ] \
            && echo -e "  ${DIM}log: $SPRINTBIAS_GATE_LOG${NC}"
          ;;
        next)
          move_file "$file" "docs/tasks/doing/$taskname"
          echo -e "  ${CYAN}-> Moved to doing/${NC}"
          ;;
      esac
      worked=$((worked + 1))
      ;;
    d|D)
      task_id=$(echo "$taskname" | grep -oE '^[0-9]+' || true)
      if [ -n "$task_id" ]; then
        echo -e "  ${BLUE}-> Going deep: launching chat on $task_id...${NC}"
        # Nested TUI owns the terminal until the user leaves it. The conversation
        # can finish while the process is still running — without an exit cue the
        # sweep looks stuck. /quit (or quit / /exit) ends the TUI; then we resume.
        echo -e "  ${DIM}When finished, type /quit (or quit) to return to the sweep.${NC}"
        # chat.sh runs the full conversation on the strong TALK model AND, being
        # chat, resolves this task's blocked dependencies via its own fresh-
        # context chain — the intrinsic dep resolution, not reimplemented here.
        # Open the REAL pty slave READ-WRITE (not the /dev/tty alias, not
        # O_RDONLY): Claude and Grok TUIs need `0u /dev/ttysNN` — `<>/dev/tty`
        # is rw but still wedges after turn 1 (device 2,0; task 335). sprintbias_tty
        # resolves the slave path; `<>` re-opens it so a drained parent stdin
        # cannot break the nested chat. Child `read -r … </dev/tty` prompts
        # reopen the tty themselves and are unaffected.
        bash "$(dirname "${BASH_SOURCE[0]}")/chat.sh" "$task_id" <>"$(sprintbias_tty)" || true
        echo ""
        echo -e "  ${DIM}Chat session complete. Continuing the sweep...${NC}"
        defined=$((defined + 1))
      else
        echo -e "  ${YELLOW}Could not extract task ID. Skipping define.${NC}"
        skipped=$((skipped + 1))
      fi
      ;;
    k|K)
      printf "  Delete %s? [y/N]: " "$taskname"
      read -r confirm </dev/tty 2>/dev/null || confirm="n"
      if [[ "$confirm" =~ ^[Yy]$ ]]; then
        git rm "$file" 2>/dev/null || rm "$file"
        echo -e "  ${RED}-> Deleted${NC}"
        killed=$((killed + 1))
      else
        echo -e "  ${DIM}-> Kept${NC}"
        skipped=$((skipped + 1))
      fi
      ;;
    q|Q)
      echo -e "  ${DIM}-> Quitting sweep${NC}"
      break
      ;;
    *)
      skipped=$((skipped + 1))
      ;;
  esac
done

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}=== Sweep complete ===${NC}"
echo "  Worked:   $worked"
echo "  Defined:  $defined"
echo "  Killed:   $killed"
echo "  Skipped:  $skipped"
