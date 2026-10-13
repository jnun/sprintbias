#!/usr/bin/env bash
# shellcheck disable=SC2207
set -euo pipefail

# chat-bugs.sh — Fast sort of the bug inbox (docs/bugs/) into backlog tasks.
# Reached via `./sprint.sh chat bugs` — chat.sh's dispatcher routes here. This is
# the bug-shaped sibling of chat-folder.sh, completing chat's grammar:
#   chat            → walk the whole sprint's structural health (chat-sprint.sh)
#   chat <id>       → chat one task through (chat.sh)
#   chat <folder>   → sweep a task stage folder: blocked/next/backlog (chat-folder.sh)
#   chat bugs       → this: sort the bug inbox into backlog tasks
#
# A bug report is NOT a task and docs/bugs/ is NOT a task stage — it is flat, it
# has no Depends-on/Status metadata, and its terminal move is "convert to a fix
# task (or close), then DELETE the report." The inbox holds open reports only.
#
# Every report gets a verdict on the cheap TRIAGE model, which checks the code;
# verdicts run in parallel. Each verdict picks one lane and the sweep acts on it
# with no menu, so the inbox empties in one pass:
#   FIXED  → the code already does it, or a task covers it: delete the report
#   TASK   → a clear defect: fix task in backlog/ (shell copy + one glean pass,
#            gleans in parallel), then delete the report
#   DECIDE → only a person can settle it: the same backlog task, carrying the
#            one question under ### Questions for the developer. An open
#            question keeps a task out of next/ and work until it is answered,
#            so the backlog's own define flow (chat backlog, chat <id>) is the
#            decision queue.
# Emit mode hands the whole sweep to the surrounding agent. See: help chat

# ── Config ───────────────────────────────────────────────────────────
_TALK_BUGS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_TALK_BUGS_DIR/../lib.sh"

BUGS_DIR="docs/bugs"

# A report about how something looks or behaves breaks a written rule or shows
# one is missing. Every bug prompt carries this, so the fix task builds to the
# rule instead of re-guessing the design (the standards loop in lib.sh).
_BUG_STANDARDS="Standards: a report that a screen, button, flow, word or API behaves wrongly or
inconsistently is measured against a written rule. Look in the project's
standards docs (the map's sources; commonly docs/guides/ and docs/designs/) and
name the rule it touches as \`path\` → section. A rule exists: success means the
work follows it. No rule exists, or it is unclear: the first success criterion
is that the rule is written or improved, from best practice and the closest
existing example that does the same job."

# The three lanes, shared by the exec verdict and the emit sweep.
_BUG_LANES="Lanes — pick one, fast. Most reports are FIXED or TASK.
- FIXED: the code (committed or in the working tree) already does what the
  report asks, or another bug or task already covers it. Name the evidence
  (the file, or the covering task's id).
- TASK: a defect you can name, with an expected behavior the report or the code
  makes clear. A thin report whose meaning the code settles is TASK; its gaps
  become recorded assumptions in the task.
- DECIDE: only a person can settle it — you cannot tell what is wrong or what
  right looks like, or the report asks for a product decision or a new approach
  bigger than one fix (a plan). Ask the one question that settles it.
In doubt between FIXED and TASK, pick TASK: a task can close itself, a deleted
report is gone. In doubt between TASK and DECIDE, pick TASK."

# Colours (RED/YELLOW/BLUE/CYAN/DIM/BOLD/NC) come from lib.sh.
timeout_sec=120
# The per-bug verdict is a single-shot classification (four lines out). Cap
# turns so a misbehaving model can't burn a long session before the wall-clock
# timeout fires — same guard chat-folder/define/split use.
MAX_TURNS=15
GLEAN_TIMEOUT=300
# Verdicts and gleans each run this many at a time.
JOBS=4
AI_MODE="$(sprintbias_ai_mode)"

# Cheap model for the fast verdict pass; the CHAT model gleans and runs the
# emit sweep. Coerce foreign pins; empty → provider strong default.
_triage_model="$(sprintbias_tier_model TRIAGE)"
_verdict_model_args=()
[ -n "$_triage_model" ] && _verdict_model_args=(--model "$_triage_model")

_chat_model="$(sprintbias_tier_model CHAT)"
_chat_model_args=()
[ -n "$_chat_model" ] && _chat_model_args=(--model "$_chat_model")

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/sprintbias-bugs.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT
trap 'echo ""; echo "Sweep interrupted."; kill $(jobs -p) 2>/dev/null; exit 130' INT TERM

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
  git rm -qf "$file" 2>/dev/null || rm -f "$file"
}

# copy_bug FILE STANDARD [QUESTION] -> mint a fix task filled from the report
# and print its path. A DECIDE verdict's QUESTION goes under ### Questions for
# the developer. Pure shell (no model); the glean pass rewrites it after.
copy_bug() {
  local file="$1" standard="$2" question="${3:-}" name desc newout taskfile bugid severity
  local problem steps criteria notes_body notes_tmp problem_tmp criteria_tmp
  name="$(basename "$file")"
  bugid="$(printf '%s' "$name" | grep -oE '^[0-9]+' || true)"
  desc="$(bug_desc "$file")"
  severity="$(bug_severity "$file")"

  newout="$(bash "$_TALK_BUGS_DIR/create-task.sh" "Fix: $desc" 2>&1)" || {
    echo -e "  ${RED}Could not create the fix task:${NC}" >&2
    printf '%s\n' "$newout" | sed 's/^/    /' >&2
    return 1
  }
  taskfile="$(printf '%s' "$newout" | grep -oE 'docs/tasks/backlog/[0-9]+-[^ ]*\.md' | head -1)"
  if [ -z "$taskfile" ] || [ ! -f "$taskfile" ]; then
    echo -e "  ${RED}Fix task was created but its path could not be located — leaving the bug in place.${NC}" >&2
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

  # The report's Success criteria become the task's automated done-when
  # (whichever heading the task carries; see lib.sh sprintbias_done_when).
  if [ -n "$(printf '%s' "$criteria" | tr -d '[:space:]')" ]; then
    criteria_tmp="$(mktemp)"
    printf '%s\n' "$criteria" > "$criteria_tmp"
    replace_md_section "$taskfile" "$(sprintbias_done_when_heading "$taskfile")" "$criteria_tmp"
    rm -f "$criteria_tmp"
  fi

  # Notes: origin only on the task (bug file is deleted).
  notes_tmp="$(mktemp)"
  {
    printf '> **Origin:** bug #%s — %s (converted from docs/bugs/; report deleted)\n' \
      "${bugid:-?}" "$desc"
    [ -n "$severity" ] && printf '\n**Severity (from report):** %s\n' "$severity"
    # The verdict's STANDARD line: the rule the fix builds to, or the one it writes first.
    [ -n "$standard" ] && [ "$standard" != "none" ] && printf '\n**Standard:** %s\n' "$standard"
    notes_body="$(md_section "$file" "Notes")"
    if [ -n "$(printf '%s' "$notes_body" | tr -d '[:space:]')" ]; then
      printf '\n%s\n' "$notes_body"
    fi
    [ -n "$question" ] && printf '\n### Questions for the developer\n\n- %s\n' "$question"
  } > "$notes_tmp"
  replace_md_section "$taskfile" "Notes" "$notes_tmp"
  rm -f "$notes_tmp"

  printf '%s' "$taskfile"
}

# The glean instructions, shared by exec (glean_bug) and emit mode.
_GLEAN_RULES="Turn the bug report into an actionable task, as complete as the report and the
code allow, in one pass. Follow docs/sprintbias/ai/task-creation.md.
- ## Problem: who is affected, what is wrong, why it matters, in plain words.
  Keep the filer's meaning; add what the code shows. Keep Steps to reproduce
  under it, and write them from the code when the report has none.
- ## Done when (automated): observable outcomes, each with the test or command
  that proves it. One names the Standard (or says the rule is written first).
- ## Signoff (human): what only a person can judge, such as how a screen looks.
- ## Notes: keep the Origin and Standard lines. Where the report is thin,
  decide the most reasonable reading and record it as - Decided: X, because Y.
  Add no new questions; the backlog defines the rest. A task that already has
  ### Questions for the developer keeps that one question, word for word: it
  waits for a person's decision.
- ## References: the files and docs you read that the work touches.
- Edit only the task file. Change no code.

$_BUG_STANDARDS"

# glean_bug REPORT TASKFILE -> one AI pass rewrites the copied task into an
# actionable one. A helper step: on failure or timeout the shell copy stands.
glean_bug() {
  local file="$1" taskfile="$2"
  run_with_timeout "$GLEAN_TIMEOUT" sprintbias_run -p "$(sprintbias_orient)
Bug report: $file
Task file:  $taskfile (already holds a copy of the report)

$_GLEAN_RULES

$(sprintbias_assume_rule)" \
    ${_chat_model_args[@]+"${_chat_model_args[@]}"} \
    --tools "Read,Edit,Grep,Glob" --permissions "auto" \
    --max-turns "$MAX_TURNS" >/dev/null 2>&1
}

# pool FN N -> run FN 0..N-1 in the background, at most JOBS at once, and wait
# for all of them. Workers write their results to $WORK_DIR, never stdout.
pool() {
  local fn="$1" n="$2" i pids=()
  _sprintbias_heartbeat_start
  for ((i = 0; i < n; i++)); do
    "$fn" "$i" &
    pids+=($!)
    if [ "${#pids[@]}" -ge "$JOBS" ]; then
      wait "${pids[0]}" 2>/dev/null || true
      pids=("${pids[@]:1}")
    fi
  done
  for i in ${pids[@]+"${pids[@]}"}; do wait "$i" 2>/dev/null || true; done
  _sprintbias_heartbeat_stop
}

# field TEXT KEY -> the value after "KEY: " on its first line.
field() { { printf '%s\n' "$1" | grep -m1 "^$2:" || true; } | sed "s/^$2:[[:space:]]*//"; }

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

# ── Emit mode: hand the whole sweep to the surrounding agent ──────────
if [ "$AI_MODE" = "emit" ]; then
  echo -e "${CYAN}=== Sweep bugs/: $total report(s) ===${NC}"
  _file_list=$(printf '%s\n' "${all_files[@]}")
  sprintbias_run -p "You are sorting the bug inbox ($BUGS_DIR/) into backlog tasks, fast. Rip through it; ask the developer nothing.

$(sprintbias_orient)
A bug report is NOT a task: it lives flat in $BUGS_DIR/, has no Depends-on/Status metadata. Handled reports leave the workspace by delete (git rm -qf <path> || rm -f <path>). No archived/ folder.

Bug reports, in order:
$_file_list

For every report: read it, check the current code quickly, pick a lane, and act on it right away. Sort reports in parallel with subagents when you can.
$_BUG_LANES
- FIXED: delete the report. One line: the report and the evidence.
- TASK: ./sprint.sh newtask \"Fix: <the bug's short description>\", fill it from the report by the task rules below, with > **Origin:** bug #<id> — <title> (converted from docs/bugs/; report deleted), the severity and the Standard (as **Standard:** <it>, unless none) in ## Notes, then delete the report. One line: the report and the new task.
- DECIDE: the same as TASK, plus the one question under ### Questions for the developer at the end of ## Notes. One line: the report, the new task and the question.
Then print the tally (fixed, tasks, waiting on your answer) and, for those waiting, each task id with its question and: answer them with ./sprint.sh chat <id> or ./sprint.sh chat backlog.

Task rules:
$_GLEAN_RULES" \
    ${_chat_model_args[@]+"${_chat_model_args[@]}"} \
    --tools "Read,Edit,Write,Bash,Grep,Glob"
  exit 0
fi

# ── Exec mode ────────────────────────────────────────────────────────
fixed=0; tasked=0; not_sorted=0
fixed_lines=(); task_idx=(); task_files=(); task_qs=(); waiting=0
n=$total

echo -e "${CYAN}=== Sort bugs/: $n report(s), $JOBS at a time ===${NC}"
# Announce once here so the parallel runs don't each print the banner.
sprintbias_announce_provider ${_verdict_model_args[@]+"${_verdict_model_args[@]}"}

# ── 1. Verdicts, in parallel — cheap TRIAGE model, single shot ────────
verdict_one() {
  local file="${all_files[$1]}"
  run_with_timeout "$timeout_sec" sprintbias_run -p "You are sorting a BUG REPORT (not a task) from $BUGS_DIR/.

$(sprintbias_orient)
Read the bug file at: $file
Then check the current code quickly to see whether the defect still exists.

Output EXACTLY four lines in this format:

LANE: <FIXED, TASK or DECIDE>
SUMMARY: <one sentence: what the report is about and what the code shows now; for FIXED, the evidence>
QUESTION: <for DECIDE, the one question a person answers to settle it; otherwise none>
STANDARD: <\`path\` → section of the rule this report touches; \`path\` → no rule yet (the doc the rule belongs in); or none when the report makes no design call>

$_BUG_LANES

$_BUG_STANDARDS

Output only those four lines." \
    ${_verdict_model_args[@]+"${_verdict_model_args[@]}"} --max-turns "$MAX_TURNS" --skip-permissions \
    > "$WORK_DIR/v.$1" 2>/dev/null || true
}
pool verdict_one "$n"

# ── 2. Act on each lane, in inbox order ──────────────────────────────
for ((i = 0; i < n; i++)); do
  file="${all_files[$i]}"; bugname="$(basename "$file")"
  verdict="$(cat "$WORK_DIR/v.$i" 2>/dev/null || true)"
  lane="$(field "$verdict" LANE | grep -oE 'FIXED|TASK|DECIDE' | head -1 || true)"
  summary="$(field "$verdict" SUMMARY)"
  question="$(field "$verdict" QUESTION)"
  standard="$(field "$verdict" STANDARD)"
  case "$question" in none|None) question="" ;; esac

  echo ""
  case "$lane" in
    FIXED)
      echo -e "${BOLD}$bugname${NC}  ${CYAN}FIXED${NC} → discarded"
      [ -n "$summary" ] && echo "  $summary"
      delete_bug "$file"
      fixed_lines+=("$bugname — ${summary:-already fixed}")
      fixed=$((fixed + 1))
      ;;
    TASK|DECIDE)
      if [ "$lane" = DECIDE ]; then
        [ -n "$question" ] || question="${summary:-What should happen instead?}"
        echo -e "${BOLD}$bugname${NC}  ${YELLOW}DECIDE${NC} → backlog, waiting on your answer"
        echo "  $question"
      else
        question=""
        echo -e "${BOLD}$bugname${NC}  ${RED}TASK${NC} → backlog"
        [ -n "$summary" ] && echo "  $summary"
      fi
      [ -n "$standard" ] && [ "$standard" != "none" ] && echo -e "  ${DIM}Standard: $standard${NC}"
      if taskfile="$(copy_bug "$file" "$standard" "$question")"; then
        task_idx+=("$i"); task_files+=("$taskfile"); task_qs+=("$question")
        [ -n "$question" ] && waiting=$((waiting + 1))
      else
        not_sorted=$((not_sorted + 1))
      fi
      ;;
    *)
      echo -e "${BOLD}$bugname${NC}  ${DIM}no verdict (timed out) — left for the next run${NC}"
      not_sorted=$((not_sorted + 1))
      ;;
  esac
done

# ── 3. Glean the new tasks in parallel, then delete their reports ─────
nt=${#task_files[@]}
if [ "$nt" -gt 0 ]; then
  echo ""
  echo -e "${DIM}Gleaning $nt report(s) into actionable tasks…${NC}"
  glean_one() {
    glean_bug "${all_files[${task_idx[$1]}]}" "${task_files[$1]}" && : > "$WORK_DIR/g.$1"
  }
  pool glean_one "$nt"
  for ((j = 0; j < nt; j++)); do
    taskfile="${task_files[$j]}"
    delete_bug "${all_files[${task_idx[$j]}]}"
    git add "$taskfile" 2>/dev/null || true
    if [ -f "$WORK_DIR/g.$j" ]; then
      echo -e "  ${CYAN}-> ${taskfile#docs/tasks/backlog/}${NC}"
    else
      echo -e "  ${CYAN}-> ${taskfile#docs/tasks/backlog/}${NC} ${DIM}(kept the report's copy; define it with ./sprint.sh chat <id>)${NC}"
    fi
    tasked=$((tasked + 1))
  done
fi

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}=== Sweep complete ===${NC}"
echo "  Fixed (discarded):  $fixed"
echo "  Tasks (backlog/):   $tasked"
echo "  Waiting on you:     $waiting"
[ "$not_sorted" -gt 0 ] && echo "  Not sorted:         $not_sorted (run again to sort)"
# One copyable line per new task; a task waiting on your answer shows its question.
if [ "$nt" -gt 0 ]; then
  echo ""
  echo "  Define each queued task:"
  for ((j = 0; j < nt; j++)); do
    tf="${task_files[$j]}"
    if [ -n "${task_qs[$j]}" ]; then note="waiting on you: ${task_qs[$j]}"; else note="$(task_title "$tf")"; fi
    echo "    ./sprint.sh chat $(task_id "$tf")    # $note"
  done
fi
if [ "${#fixed_lines[@]}" -gt 0 ]; then
  echo ""
  echo -e "  ${DIM}Discarded as fixed (a tracked report comes back from git history):${NC}"
  for l in "${fixed_lines[@]}"; do echo -e "  ${DIM}  $l${NC}"; done
fi
exit 0
