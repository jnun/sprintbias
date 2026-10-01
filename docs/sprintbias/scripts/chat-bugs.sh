#!/usr/bin/env bash
# shellcheck disable=SC2207
set -euo pipefail

# chat-bugs.sh — Express one-at-a-time sweep of the bug inbox (docs/bugs/).
# Reached via `./sprint.sh chat bugs` — chat.sh's dispatcher routes here. This is
# the bug-shaped sibling of chat-folder.sh, completing chat's grammar:
#   chat            → walk the whole sprint's structural health (chat-sprint.sh)
#   chat <id>       → chat one task through (chat.sh)
#   chat <folder>   → sweep a task stage folder: blocked/next/backlog (chat-folder.sh)
#   chat bugs       → this: sweep the bug inbox, verdict-first
#
# A bug report is NOT a task and docs/bugs/ is NOT a task stage — it is flat, it
# has no Depends-on/Status metadata, and its terminal move is "convert to a fix
# task (or close), then DELETE the report." The inbox holds open reports only.
#   [w] work it   → convert: full fix task from the report, then delete the bug
#   [d] define it → go deep: refine the report itself (repro steps, severity, criteria)
#   [a] close     → already fixed / obsolete, no task → delete the bug
#   [k] kill it   → not a real bug → delete
#   [s] skip / [q] quit
#
# TWO-TIER by model, same as chat-folder: the per-bug verdict runs on the cheap
# TRIAGE model; only "define it" escalates to the strong CHAT model. See: help chat

# ── Config ───────────────────────────────────────────────────────────
_TALK_BUGS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_TALK_BUGS_DIR/../lib.sh"

BUGS_DIR="docs/bugs"

# Colours (RED/YELLOW/BLUE/CYAN/DIM/BOLD/NC) come from lib.sh.
timeout_sec=120
# The per-bug verdict is a single-shot classification (three lines out). Cap
# turns so a misbehaving model can't burn a long session before the wall-clock
# timeout fires — same guard chat-folder/define/split use.
MAX_TURNS=15
AI_MODE="$(sprintbias_ai_mode)"

# Cheap model for the fast verdict pass. The deep "define it" path runs the full
# refinement conversation on the strong TALK model, chosen at that point.
# Coerce foreign pins; empty → provider strong default (grok-4.5 / opus).
_triage_model="$(sprintbias_tier_model TRIAGE)"
_verdict_model_args=()
[ -n "$_triage_model" ] && _verdict_model_args=(--model "$_triage_model")

_chat_model="$(sprintbias_tier_model CHAT)"
_chat_model_args=()
[ -n "$_chat_model" ] && _chat_model_args=(--model "$_chat_model")

trap 'echo ""; echo "Sweep interrupted."; exit 130' INT TERM

# ── Bug field helpers ─────────────────────────────────────────────────
# bug_desc FILE -> the human title after "# Bug N:", falling back to the
# filename slug so a mangled header never yields an empty task description.
bug_desc() {
  local file="$1" name desc
  desc="$( { grep -m1 -E '^# Bug [0-9]+:' "$file" 2>/dev/null || true; } \
          | sed -E 's/^# Bug [0-9]+:[[:space:]]*//' )"
  if [ -z "$desc" ]; then
    name="$(basename "$file" .md)"
    desc="$(printf '%s' "${name#*-}" | tr '-' ' ')"
  fi
  printf '%s' "$desc"
}

# md_section FILE TITLE -> body under "## TITLE" until the next ## heading.
# Strips HTML comments; trims leading/trailing blank lines.
md_section() {
  local file="$1" title="$2"
  # Body under "## TITLE"; drop HTML comment lines; trim leading/trailing blanks.
  awk -v t="$title" '
    BEGIN { p=0 }
    index($0, "## " t) == 1 { p=1; next }
    p && /^## / { exit }
    p && /^<!--/ { next }
    p { lines[++n] = $0 }
    END {
      start=1; while (start <= n && lines[start] ~ /^[[:space:]]*$/) start++
      end=n; while (end >= start && lines[end] ~ /^[[:space:]]*$/) end--
      for (i = start; i <= end; i++) print lines[i]
    }
  ' "$file"
}

# bug_severity FILE -> CRITICAL|HIGH|MEDIUM|LOW or empty
bug_severity() {
  grep -m1 -E '^\*\*Severity:\*\*' "$1" 2>/dev/null \
    | sed -E 's/.*\*\*Severity:\*\*[[:space:]]*//; s/[[:space:]]*$//' \
    | tr -d '[]' || true
}

# replace_md_section FILE TITLE BODY_FILE
# Replaces the body of "## TITLE" in FILE with the contents of BODY_FILE.
replace_md_section() {
  local file="$1" title="$2" body_file="$3" tmp
  tmp="$(mktemp)"
  awk -v t="$title" -v bf="$body_file" '
    BEGIN {
      while ((getline line < bf) > 0) body = body line "\n"
      close(bf)
    }
    index($0, "## " t) == 1 {
      print
      print ""
      printf "%s", body
      if (body !~ /\n$/) print ""
      print ""
      skip=1
      next
    }
    skip && /^## / { skip=0 }
    skip { next }
    { print }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}

# delete_bug FILE -> remove report from the inbox (git rm, else rm).
delete_bug() {
  local file="$1"
  git rm -f "$file" 2>/dev/null || rm -f "$file"
}

# work_bug FILE -> [w] convert: mint a fix task filled from the report, then
# delete the bug. Breadcrumb lives only on the task. Pure shell (no model).
work_bug() {
  local file="$1" name desc newout taskfile bugid severity
  local problem steps criteria notes_body notes_tmp problem_tmp criteria_tmp
  name="$(basename "$file")"
  bugid="$(printf '%s' "$name" | grep -oE '^[0-9]+' || true)"
  desc="$(bug_desc "$file")"
  severity="$(bug_severity "$file")"

  newout="$(bash "$_TALK_BUGS_DIR/create-task.sh" "Fix: $desc" 2>&1)" || {
    echo "  ${RED}Could not create the fix task:${NC}"
    printf '%s\n' "$newout" | sed 's/^/    /'
    return 1
  }
  taskfile="$(printf '%s' "$newout" | grep -oE 'docs/tasks/backlog/[0-9]+-[^ ]*\.md' | head -1)"
  if [ -z "$taskfile" ] || [ ! -f "$taskfile" ]; then
    echo "  ${RED}Fix task was created but its path could not be located — leaving the bug in place.${NC}"
    return 1
  fi

  problem="$(md_section "$file" "Problem")"
  steps="$(md_section "$file" "Steps to reproduce")"
  criteria="$(md_section "$file" "Success criteria")"

  # Problem: bug problem + optional repro steps (tasks have no Steps section).
  problem_tmp="$(mktemp)"
  {
    if [ -n "$(printf '%s' "$problem" | tr -d '[:space:]')" ]; then
      printf '%s\n' "$problem"
    else
      printf 'Fix: %s\n' "$desc"
    fi
    if [ -n "$(printf '%s' "$steps" | tr -d '[:space:]')" ]; then
      printf '\n### Steps to reproduce\n\n%s\n' "$steps"
    fi
  } > "$problem_tmp"
  replace_md_section "$taskfile" "Problem" "$problem_tmp"
  rm -f "$problem_tmp"

  # Success criteria from the report when present.
  if [ -n "$(printf '%s' "$criteria" | tr -d '[:space:]')" ]; then
    criteria_tmp="$(mktemp)"
    printf '%s\n' "$criteria" > "$criteria_tmp"
    replace_md_section "$taskfile" "Success criteria" "$criteria_tmp"
    rm -f "$criteria_tmp"
  fi

  # Notes: origin only on the task (bug file is deleted).
  notes_tmp="$(mktemp)"
  {
    printf '> **Origin:** bug #%s — %s (converted from docs/bugs/; report deleted)\n' \
      "${bugid:-?}" "$desc"
    [ -n "$severity" ] && printf '\n**Severity (from report):** %s\n' "$severity"
    notes_body="$(md_section "$file" "Notes")"
    if [ -n "$(printf '%s' "$notes_body" | tr -d '[:space:]')" ]; then
      printf '\n%s\n' "$notes_body"
    fi
  } > "$notes_tmp"
  replace_md_section "$taskfile" "Notes" "$notes_tmp"
  rm -f "$notes_tmp"

  delete_bug "$file"
  git add "$taskfile" 2>/dev/null || true
  echo "  ${CYAN}-> Created ${taskfile#docs/tasks/backlog/} and deleted the report${NC}"
}

# ── Collect bugs (flat, numeric-prefixed; template excluded; no subdirs) ─
all_files=()
if [ -d "$BUGS_DIR" ]; then
  IFS=$'\n' all_files=($(
    find "$BUGS_DIR" -maxdepth 1 -type f -name '*.md' -exec basename {} \; \
      | awk -F- '/^[0-9]+-/ { print $0 }' \
      | sort -t- -k1,1n \
      | sed "s|^|$BUGS_DIR/|"
  )) || true
  unset IFS
fi

total=${#all_files[@]}
if [ "$total" -eq 0 ]; then
  echo "▸ Sweep bugs/"
  echo "  $BUGS_DIR/ has no open bug reports — nothing to walk."
  echo "  File one with:  ./sprint.sh newbug \"Brief description\""
  exit 0
fi

echo -e "${CYAN}=== Sweep bugs/: $total report(s), one at a time ===${NC}"

# ── Emit mode: hand the whole sweep to the surrounding agent ──────────
# The agent IS the model, so there is no cheap/strong split — the tempo is a
# prompt contract: fast verdict first, go deep ONLY on request.
if [ "$AI_MODE" = "emit" ]; then
  _file_list=$(printf '%s\n' "${all_files[@]}")
  sprintbias_run -p "You are sweeping the bug inbox ($BUGS_DIR/) with the developer, one report at a time — a fast verdict-first sort, NOT a full conversation on every bug. Rip through the queue; go deep only where asked.

$(sprintbias_orient)
A bug report is NOT a task: it lives flat in $BUGS_DIR/, has no Depends-on/Status metadata. Handled reports leave the workspace: convert to a fix task then DELETE the report, or close/kill by DELETE. No archived/ folder.

Bug reports to sweep, in order:
$_file_list

For EACH report in order:
1. Read the bug file and do a QUICK check of the current codebase — is this still reproducible, or already fixed? A fast size-up, not a deep review.
2. Give a fast VERDICT: bug name, a STATUS (REPRODUCIBLE / FIXED / UNDEFINED / DUPLICATE / STALE), a one-sentence summary, and a one-sentence recommendation. Keep it tight — this is the cheap sort pass.
   - REPRODUCIBLE: the described defect still exists in the code.
   - FIXED: the code already behaves correctly; the report is stale.
   - UNDEFINED: no clear problem, repro steps, or success criteria to act on.
   - DUPLICATE: another bug or task already covers this.
   - STALE: not wrong, but low-value or superseded.
3. Offer the developer the choice:
   [w] work it   — CONVERT to a fix task, then DELETE the report. Do EXACTLY this, in order:
                   a. Run: ./sprint.sh newtask \"Fix: <the bug's short description>\"  (real ID + template)
                   b. Fill the new task from the report: copy ## Problem (include Steps to reproduce under it if present), ## Success criteria, and put origin + severity + any report Notes into the task ## Notes as: > **Origin:** bug #<id> — <title> (converted from docs/bugs/; report deleted)
                   c. DELETE the bug file: git rm -f <bug-file> || rm -f <bug-file>. Do NOT move to archived/.
                   Then move on; ./sprint.sh chat <task-id> can refine the task later if needed.
   [d] define it — go DEEP on the REPORT itself (not a task): refine ## Problem, ## Steps to reproduce, the Severity line, and ## Success criteria until any developer can reproduce and verify the fix. One detail at a time, editing as you go. This is the only step that escalates past the fast verdict.
   [a] close     — already fixed or obsolete, no task needed: DELETE with git rm -f PATH || rm -f PATH. Do not archive.
   [k] kill it   — not a real bug: delete after confirming (git rm -f PATH || rm -f PATH).
   [s] skip      — leave it where it is.
   [q] quit      — stop the sweep.
4. Act on the choice, then continue to the next report.

Be concise and move briskly. One report at a time; wait for the developer between reports." \
    ${_chat_model_args[@]+"${_chat_model_args[@]}"} \
    --tools "Read,Edit,Write,Bash,Grep,Glob"
  exit 0
fi

# ── Exec mode: interactive loop ──────────────────────────────────────
worked=0
defined=0
closed=0
killed=0
skipped=0

for i in "${!all_files[@]}"; do
  file="${all_files[$i]}"
  idx=$((i + 1))

  # A prior action may have moved the file out of the inbox.
  if [ ! -f "$file" ]; then
    echo -e "\n${DIM}[$idx/$total] (moved or deleted, skipping)${NC}"
    continue
  fi

  bugname=$(basename "$file")

  # Headless one-shot can take a while with no CLI output until it returns.
  echo ""
  echo -e "${DIM}[$idx/$total] $bugname — thinking, wait just a minute…${NC}"

  # ── Fast verdict — cheap TRIAGE model, single shot ─────────────────
  _verdict_prompt="You are sweeping a BUG REPORT (not a task) from $BUGS_DIR/.

$(sprintbias_orient)
Read the bug file at: $file

Then do a quick check of the current codebase to assess whether the defect still exists.

Output EXACTLY three lines in this format:

STATUS: <one of: REPRODUCIBLE, FIXED, UNDEFINED, DUPLICATE, STALE>
SUMMARY: <one sentence describing the defect this report is about>
RECOMMENDATION: <one sentence telling the user what to do with it>

Status definitions:
- REPRODUCIBLE: The described defect still exists in the current codebase
- FIXED: The code already behaves correctly; this report is stale
- UNDEFINED: No clear problem, reproduction steps, or success criteria to act on
- DUPLICATE: Another bug report or task already covers this
- STALE: Not wrong, but low-value or superseded by other work

Rules:
- Be conservative: if in doubt, say REPRODUCIBLE
- Keep SUMMARY and RECOMMENDATION each to ONE sentence
- Do not output anything else"

  verdict=$(run_with_timeout_dots "$timeout_sec" sprintbias_run -p "$_verdict_prompt" \
    ${_verdict_model_args[@]+"${_verdict_model_args[@]}"} --max-turns "$MAX_TURNS" --skip-permissions) || true

  status=$(echo "$verdict" | grep -oE '^STATUS: (REPRODUCIBLE|FIXED|UNDEFINED|DUPLICATE|STALE)' | head -1 | sed 's/^STATUS: //' || true)
  if [ -z "$status" ]; then
    status=$(echo "$verdict" | grep -oE '\b(REPRODUCIBLE|FIXED|UNDEFINED|DUPLICATE|STALE)\b' | head -1 || true)
  fi
  [ -z "$status" ] && status="UNKNOWN"

  summary=$(echo "$verdict" | grep '^SUMMARY:' | head -1 | sed 's/^SUMMARY: //' || true)
  [ -z "$summary" ] && summary="(no summary returned)"

  recommendation=$(echo "$verdict" | grep '^RECOMMENDATION:' | head -1 | sed 's/^RECOMMENDATION: //' || true)
  [ -z "$recommendation" ] && recommendation="(no recommendation returned)"

  # ── Display ────────────────────────────────────────────────────────
  echo ""
  echo -e "${BOLD}[$idx/$total] $bugname${NC}"
  if [ "$status" = "UNKNOWN" ]; then
    echo -e "  Status: ${DIM}(timed out)${NC}"
  elif [ "$status" = "FIXED" ]; then
    echo -e "  Status: ${CYAN}$status${NC}"
  elif [ "$status" = "REPRODUCIBLE" ]; then
    echo -e "  Status: ${RED}$status${NC}"
  elif [ "$status" = "UNDEFINED" ] || [ "$status" = "DUPLICATE" ]; then
    echo -e "  Status: ${YELLOW}$status${NC}"
  else
    echo -e "  Status: $status"
  fi
  echo "  $summary"
  echo -e "  ${DIM}$recommendation${NC}"
  echo ""
  echo -e "  ${BOLD}[w]${NC} Work it (convert → task)  ${BOLD}[d]${NC} Define it (go deep)  ${BOLD}[a]${NC} Close (delete)  ${BOLD}[k]${NC} Kill it  ${BOLD}[s]${NC} Skip  ${BOLD}[q]${NC} Quit"
  printf "  > "
  read -r choice </dev/tty 2>/dev/null || choice="s"

  # ── Act ────────────────────────────────────────────────────────────
  case "$choice" in
    w|W)
      if work_bug "$file"; then
        worked=$((worked + 1))
      else
        skipped=$((skipped + 1))
      fi
      ;;
    d|D)
      echo -e "  ${BLUE}-> Going deep: refining the report...${NC}"
      # Nested TUI owns the terminal until the user leaves it (same as chat-folder [d]).
      echo -e "  ${DIM}When finished, type /quit (or quit) to return to the sweep.${NC}"
      # Shared Conversation Method — stated once in ai/conversation.md.
      _METHOD="$(sprintbias_conversation_method)" || exit 1
      _define_prompt="Refine this BUG REPORT with the filer until any developer can reproduce and verify the fix.

Bug: $file — read now. NOT a task (## Problem, ## Steps to reproduce, **Severity:**, ## Success criteria, ## Notes). No Depends on/Dependents/Parent/Status.

$_METHOD

GOAL: unambiguous report. Gaps: vague Problem, bad steps, Severity mismatch, non-observable success. One gap at a time; edit as each lands.

RULES:
- One question at a time. Observable behaviour only — no code/patches.
- Steps: numbered, clear start, followable cold.
- Success: checkboxes (\"User can …\" / \"System shows …\" / \"[x] no longer causes [y]\").
- WRITES: only $file. When clear: show final state; convert via chat bugs → [w] (creates the fix task and deletes this report).
- LEAVE THE SESSION: when the report is clear, tell the user in one line to type \`/quit\` (or \`quit\` / \`/exit\`) to leave this interactive session and return to the bug sweep. Edits are already on disk. Do not open a new question after that cue."
      # Real pty slave RDWR — same handoff as chat-folder [d] (see sprintbias_tty).
      # <>/dev/tty wedges Claude/Grok TUIs after turn 1; </dev/tty is O_RDONLY.
      sprintbias_run_interactive \
        --append-system-prompt "$_define_prompt" \
        ${_chat_model_args[@]+"${_chat_model_args[@]}"} \
        --tools "Read,Edit,Write,Bash,Grep,Glob" \
        --permissions "auto" \
        --name "chat-bug-${bugname%%-*}" \
        "Read the bug report at $file, size it up, and start refining it — one detail at a time." <>"$(sprintbias_tty)" || true
      echo ""
      echo -e "  ${DIM}Refinement complete. Continuing the sweep...${NC}"
      defined=$((defined + 1))
      ;;
    a|A)
      delete_bug "$file"
      echo -e "  ${CYAN}-> Closed — report deleted (no task)${NC}"
      closed=$((closed + 1))
      ;;
    k|K)
      printf "  Delete %s? [y/N]: " "$bugname"
      read -r confirm </dev/tty 2>/dev/null || confirm="n"
      if [[ "$confirm" =~ ^[Yy]$ ]]; then
        delete_bug "$file"
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
echo "  Worked (→ fix task):  $worked"
echo "  Defined:              $defined"
echo "  Closed (deleted):     $closed"
echo "  Killed:               $killed"
echo "  Skipped:              $skipped"
