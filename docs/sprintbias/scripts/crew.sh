#!/usr/bin/env bash
# crew.sh — Named AI sessions with roles. See: ./sprint.sh help crew
#
#   crew                          list members and the tasks each holds (no AI)
#   crew add <name> "<role>" [--lead]   create docs/crew/<name>.md from the template
#   crew setup                    guided build: an AI session proposes a crew and fills its files
#   crew <name> [ID | plan:N]     start an interactive session as that member;
#                                 a lead started on plan:N is assigned that plan
#
# A member is a markdown file (docs/crew/<name>.md). A task's **Crew** field
# routes it to a member; a member moving the task into doing/ sets the field to
# its own name, which is the claim. The files are the shared state; messages
# between sessions are only the nudge.

# Bash reads a script as it runs. A long run can outlive edits to this file
# (an agent's task, or a setup.sh update), so the braces make bash parse the
# whole script before running any of it.
{
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPTS_DIR/.." && pwd)/lib.sh"

CREW_DIR="docs/crew"
TEMPLATE="$CREW_DIR/.TEMPLATE-crew.md"

usage() {
  echo "Usage: ./sprint.sh crew                            list the crew and what each holds"
  echo "       ./sprint.sh crew add <name> \"<role>\" [--lead]  add a member"
  echo "       ./sprint.sh crew setup                        guided build of a crew (AI)"
  echo "       ./sprint.sh crew <name> [ID | plan:N]         start a session as that member"
}

# Lowercase letters, digits and dashes: the name is a file name and a session name.
valid_name() { [[ "$1" =~ ^[a-z][a-z0-9-]*$ ]]; }

member_file() { printf '%s/%s.md' "$CREW_DIR" "$1"; }

# held_by NAME -> "stage<TAB>file" lines for open tasks whose **Crew** is NAME.
held_by() {
  local name="$1" stage f
  for stage in "${SPRINTBIAS_OPEN_STAGES[@]}"; do
    for f in docs/tasks/"$stage"/[0-9]*-*.md; do
      [ -f "$f" ] || continue
      [ "$(sprintbias_meta_value "$f" Crew | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')" = "$name" ] \
        && printf '%s\t%s\n' "$stage" "$f"
    done
  done
  return 0
}

# assigned_plan NAME -> the plan file whose **Crew** is NAME (first match).
assigned_plan() {
  local f
  for f in "${SPRINTBIAS_PLANS_DIR:-docs/plans}"/[0-9]*-*.md; do
    [ -f "$f" ] || continue
    [ "$(sprintbias_meta_value "$f" Crew | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')" = "$1" ] \
      && { printf '%s' "$f"; return 0; }
  done
  return 1
}

# set_plan_crew PLAN_FILE VALUE: write **Crew**: VALUE, adding the field under
# **Status:** when the plan predates it.
set_plan_crew() {
  local plan="$1" val="$2" tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/sprintbias-crew.XXXXXX")"
  if grep -qE '^\*\*Crew\*\*:' "$plan"; then
    awk -v n="$val" '/^\*\*Crew\*\*:/ && !d { print "**Crew**: " n; d = 1; next } { print }' "$plan" > "$tmp"
  else
    awk -v n="$val" '{ print } /^\*\*Status:\*\*/ && !d { print "**Crew**: " n; d = 1 }' "$plan" > "$tmp"
  fi
  mv "$tmp" "$plan" && grep -q "^\*\*Crew\*\*: $val\$" "$plan"
}

# assign_plan PLAN_FILE NAME: a lead leads one plan at a time, so this releases
# any other plan it held, then stamps this one.
assign_plan() {
  local plan="$1" name="$2" prev old
  while old="$(assigned_plan "$name")" && [ "$old" != "$plan" ]; do
    set_plan_crew "$old" none || break
    echo -e "${YELLOW}$name now leads plan $(sprintbias_plan_file_id "$plan"); released plan $(sprintbias_plan_file_id "$old").${NC}"
  done
  prev="$(sprintbias_meta_value "$plan" Crew | tr -d '[:space:]')"
  case "$prev" in ""|[Nn]one|"$name") ;; *) echo -e "${YELLOW}Plan was led by $prev; now led by $name.${NC}" ;; esac
  set_plan_crew "$plan" "$name"
}

# ── crew (list) ──────────────────────────────────────────────────────
cmd_list() {
  local f name role lead stage task any=0
  for f in "$CREW_DIR"/*.md; do
    [ -f "$f" ] || continue
    any=1
    name="$(basename "$f" .md)"
    role="$(sprintbias_meta_value "$f" Role)"
    lead="$(sprintbias_meta_value "$f" Lead)"
    if [ "$(printf '%s' "$lead" | tr '[:upper:]' '[:lower:]')" = "yes" ]; then
      echo -e "${BOLD}${name}${NC} (lead) — ${role}"
      local lp; lp="$(assigned_plan "$name" || true)"
      [ -n "$lp" ] && echo "    leads plan $(sprintbias_plan_file_id "$lp"): $(task_title "$lp" | sed 's/^Plan [0-9]*: *//')"
    else
      echo -e "${BOLD}${name}${NC} — ${role}"
    fi
    local held=0
    while IFS=$'\t' read -r stage task; do
      [ -n "$task" ] || continue
      held=1
      echo "    ${stage}/  $(task_id "$task")  $(task_title "$task")"
    done < <(held_by "$name")
    [ "$held" -eq 1 ] || echo "    holds nothing"
  done
  if [ "$any" -eq 0 ]; then
    echo "No crew yet. Let an AI session propose one and fill the files:"
    echo "  ./sprint.sh crew setup"
    echo "Or add one member per role yourself, starting with a lead:"
    echo "  ./sprint.sh crew add lead \"Keeps everyone rowing: holds the plan, routes tasks\" --lead"
    echo "  ./sprint.sh crew add builder \"Builds and runs the project locally\""
  fi
}

# ── crew add ─────────────────────────────────────────────────────────
cmd_add() {
  local name="${1:-}" role="${2:-}" lead="no"
  [ "${3:-}" = "--lead" ] && lead="yes"
  if [ -z "$name" ] || [ -z "$role" ]; then usage; exit 1; fi
  if ! valid_name "$name" || [[ "$name" =~ ^(add|list|help|setup)$ ]]; then
    echo -e "${RED}✗ Crew names use lowercase letters, digits and dashes (not add, list, help or setup): $name${NC}" >&2
    exit 1
  fi
  local dest; dest="$(member_file "$name")"
  if [ -f "$dest" ]; then
    echo -e "${YELLOW}$dest already exists — edit it directly.${NC}"
    exit 1
  fi
  copy_template "$TEMPLATE" "$dest" || exit 1
  local display; display="$(printf '%s' "${name:0:1}" | tr '[:lower:]' '[:upper:]')${name:1}"
  # Role text goes in through awk -v, so slashes and ampersands stay literal.
  local tmp; tmp="$(mktemp "${TMPDIR:-/tmp}/sprintbias-crew.XXXXXX")"
  # The template carries a lead and a member version of each section; keep
  # the one this member needs and drop the markers.
  local keep="member"; [ "$lead" = "yes" ] && keep="lead"
  awk -v n="$display" -v r="$role" -v l="$lead" -v keep="$keep" '
    /^<!-- sb:(lead|member) -->$/ { split($2, a, ":"); skip = (a[2] != keep); next }
    /^<!-- \/sb:(lead|member) -->$/ { skip = 0; next }
    skip { next }
    /^# Crew: / { print "# Crew: " n; next }
    /^\*\*Role\*\*:/ { print "**Role**: " r; next }
    /^\*\*Lead\*\*:/ { print "**Lead**: " l; next }
    { print }' "$dest" > "$tmp" && mv "$tmp" "$dest"
  echo -e "${GREEN}Added crew member: $dest${NC}"
  if [ "$lead" = "yes" ]; then
    echo "The lead's Job, May touch and Reports are filled in; add any project docs"
    echo "to Reads first, then start it on a plan:"
    echo "  ./sprint.sh crew $name plan:N"
  else
    echo "Next: fill in Job and May touch (the lane this member owns), then start it:"
    echo "  ./sprint.sh crew $name"
  fi
}

# ── crew <name> (start a session) ────────────────────────────────────
cmd_start() {
  local name="$1" target="${2:-}" file role lead
  file="$(member_file "$name")"
  if [ ! -f "$file" ]; then
    echo -e "${RED}✗ No crew member '$name'. See ./sprint.sh crew${NC}" >&2
    exit 1
  fi
  role="$(sprintbias_meta_value "$file" Role)"
  lead="$(sprintbias_meta_value "$file" Lead | tr '[:upper:]' '[:lower:]')"

  local work_line self="" plan_block=""
  # A lead with no target resumes the plan assigned to it.
  if [ -z "$target" ] && [ "$lead" = "yes" ]; then
    local ap; ap="$(assigned_plan "$name" || true)"
    [ -n "$ap" ] && target="plan:$(sprintbias_plan_file_id "$ap")"
  fi
  case "$target" in
    "")
      if [ "$lead" = "yes" ]; then
        work_line="No target was given. Run ./sprint.sh status and ./sprint.sh crew, then lead the STARTED plan with open work (the lowest id when several). Say which in one line; the human can redirect you."
      else
        work_line="No target was given. Run ./sprint.sh crew to see what you hold. If it is nothing, take the lowest-id READY task in docs/tasks/next/ that fits your role, set its **Crew** to ${name}, and tell the lead."
      fi ;;
    plan:*)
      local pid="${target#plan:}" pfile
      if ! pfile="$(sprintbias_find_plan "$pid")"; then
        echo -e "${RED}✗ No plan $pid in docs/plans/${NC}" >&2; exit 1
      fi
      work_line="Your work is plan $pid: $pfile."
      if [ "$lead" = "yes" ]; then
        assign_plan "$pfile" "$name"
        local start_line=""
        [ "$(grep -m1 -E '^\*\*Status:\*\*' "$pfile" | tr -d '[:space:]')" = "**Status:**STARTED" ] \
          || start_line="
- The plan is not started. Run ./sprint.sh plan start $pid first: it gates the members READY into next/."
        plan_block="Parallel build: plan $pid is assigned to you. Build as much at once as its dependencies allow. Layout from each member's Depends on, when you started:
$(sprintbias_plan_waves "$pfile")
${start_line}
- Route all of wave 1 at once. No one idles: every member has a task now and one queued next on the board, and works them one at a time.
- Route on landing: when a member reports one, check its **Proof**: line (./sprint.sh plan check $pid shows it landed) and route the tasks it releases in that same turn. Landed releases; done/ is never the wait.
- Mark each released task on the board \"built on #N (landed)\", so a rejection of #N traces to everything it affects.
- A blocked member hands the blocker to its owner (or you) and starts its next task. A member with nothing runnable writes its next task's ## Grounding with **Touching:** so it starts warm.
- Plan close: when plan check reads LANDED, run the full suite once (./sprint.sh promote plan:$pid </dev/null runs it, files a fix task per failure and, with no answer, moves nothing), or have a member run it. Route each fix to the member who built the original. When green, hand the human one sign-off: ./sprint.sh promote plan:$pid. That approval is the human's; never answer it.
- The plan's human test (**Owner**: human, in review/) is the person's. No member waits on it or works it; the fix tasks its ## Results file route like any other."
      fi ;;
    *)
      local tfile
      if ! [[ "$target" =~ ^[0-9]+$ ]] || ! tfile="$(sprintbias_task_path "$target")"; then
        echo -e "${RED}✗ No task $target. Pass a task ID or plan:N.${NC}" >&2; exit 1
      fi
      work_line="Your work is task $target: $tfile. Claim it before you start."
      self="$tfile" ;;
  esac

  # Rules 2 and 3: steady keeps holds and lanes firm; fast lets a member take
  # over a stalled hold and treats May touch as a routing preference.
  local hold_rules
  if sprintbias_fast_on; then
    hold_rules="2. Claim a task before you work it: move it into docs/tasks/doing/ (git mv SRC DEST || mv SRC DEST) and set its **Crew** field to ${name}. A task in doing/ whose Crew names another member is theirs while they work it. To take a held task, message the holder first; when ./sprint.sh agents shows no live session for the holder, set **Crew** to ${name}, add one takeover line to the plan's ## Crew board (Takeover: #id from <holder> to ${name}, because <why>), and continue.
3. May touch in your member file is your routing preference: work there first and hand other lanes to their owner (./sprint.sh crew lists everyone). When that owner is idle or stalled and the work waits, do it yourself."
  else
    hold_rules="2. Claim a task before you work it: move it into docs/tasks/doing/ (git mv SRC DEST || mv SRC DEST) and set its **Crew** field to ${name}. A task in doing/ whose Crew names another member is theirs. Leave it alone and tell the lead if you need it.
3. Stay inside what your member file says you may touch. Hand everything else to the member who owns it (./sprint.sh crew lists everyone)."
  fi

  local rules="You are ${name}, a member of this project's crew. Your role: ${role}.
Your member file is ${file}. It is your job description: read it first, then the Crew section of DOCUMENTATION.md, then docs/sprintbias/project.md if it exists.

${work_line}

Crew rules:
1. The files are the shared state. Anything that must last goes in a task file or the plan file, never only in a message.
${hold_rules}
4. Land the normal way: fill the task's ## Completed section with its proof line, move it to review/, and report the landing (task id and proof line) to the lead by message, or on the plan's ## Crew board when your CLI cannot message. The file is the record, so a restart loses nothing. Then start your next task; when blocked, tell the lead and the owner and take your next.
5. Other members are reachable by their crew name. Messages are for nudges and questions.
6. The human approves, commits and ships.

$(sprintbias_parallel_rule "$self")

$(sprintbias_proof_rule)

$(sprintbias_assume_rule)"
  local fast; fast="$(sprintbias_fast_rules)"
  [ -n "$fast" ] && rules="${rules}

${fast}"

  if [ "$lead" = "yes" ]; then
    local close_plan="<N>"
    case "$target" in plan:*) close_plan="${target#plan:}" ;; esac
    local lead_build="- Leave product code to the members. You plan, route, unblock and check landed work. Decide by the finishing rule above; ask the human only goal questions."
    sprintbias_fast_on && lead_build="- You plan, route, unblock and check landed work, and you build too: take a task yourself when a lane is idle or a member stalls. Decide by the finishing rule above; ask the human only goal questions."
    rules="${rules}

You lead this crew. Like a coxswain, you keep everyone rowing in time:
- Hold the central idea of how the plan gets solved. Keep it in the plan file under ## Crew (after ## Member tasks): the approach in a few lines, an Active: line naming the members this plan needs running, then one line per member: name, task now, task next, state.
- Split for parallel work: tasks that run at once need disjoint **Touching:** sets (or References, before a task has one). Overlapping tasks go to one member, or run in order through **Depends on**, lower id first.
- Route a task by setting its **Crew** field to the member whose lane fits, then message that member the task id. The lane fits when the member's May touch covers what the task changes; a step only one member may run (a migration, a deploy) sends the task to that member.
- A task no member's May touch covers gets an owner: add one with ./sprint.sh crew add <name> \"<role>\", fill its Job and May touch, record a - Decided: line on the board, and tell the human the terminal to start (./sprint.sh crew <name>).
- A member whose Job is a pass over landed work (stress, security) gets each landing in its lanes before plan close; the fix tasks it files go back to the builder.
${lead_build}
- When the plan's work has landed, close with the human: list the calls the crew made (each - Decided: line, with ./sprint.sh newtask \"<the change you want>\" to change one), then the next command: ./sprint.sh promote plan:${close_plan}."
    [ -n "$plan_block" ] && rules="${rules}

${plan_block}"
  fi

  local model; model="$(sprintbias_tier_model CREW)"
  local -a model_args=()
  [ -n "$model" ] && model_args=(--model "$model")

  if [ "$(sprintbias_ai_mode)" = "exec" ] && sprintbias_interactive_ok; then
    echo -e "${DIM}Starting ${name}. When finished, type /quit to end the session.${NC}"
  fi

  # No --tools list: a crew member needs the full toolset, including whatever
  # the CLI offers for messaging other sessions.
  sprintbias_run_interactive \
    --append-system-prompt "$rules" \
    ${model_args[@]+"${model_args[@]}"} \
    --name "$name" \
    "Read your member file and your work. Tell me in one or two lines who you are and what you are starting, then start it now; this message is the go-ahead."
}

# ── crew setup (guided build) ────────────────────────────────────────
# An AI session reads the project, asks a few questions, proposes the smallest
# crew that gives every lane one owner, then creates and fills the member files.
# Shapes live in guides/crew.md (people read them too); the procedure and the
# per-provider tuning live in ai/crew-setup.md. Only the active provider's
# section is sent, so the other provider's notes cost no context.
cmd_setup() {
  local guide="docs/sprintbias/ai/crew-setup.md" tier heading
  if [ ! -f "$guide" ]; then
    echo -e "${RED}✗ Missing $guide — re-run setup.sh to restore the framework.${NC}" >&2
    exit 1
  fi
  tier="$(sprintbias_ai_tier)"
  case "$tier" in
    claude-code) heading="## Claude Code" ;;
    grok-build)  heading="## Grok Build" ;;
    *)           heading="## Other CLIs" ;;
  esac
  # Everything before the first provider heading, then that provider's section.
  local method
  method="$(awk -v h="$heading" '
    /^## (Claude Code|Grok Build|Other CLIs)$/ { inp = ($0 == h); started = 1; if (inp) print; next }
    !started || inp { print }' "$guide")"

  local rules="You are setting up a SprintBias crew for this project.
$(sprintbias_orient)

$method

$(sprintbias_assume_rule)"
  local fast; fast="$(sprintbias_fast_rules)"
  [ -n "$fast" ] && rules="${rules}

${fast}"

  if [ "$(sprintbias_ai_mode)" = "exec" ] && sprintbias_interactive_ok; then
    echo -e "${DIM}Starting crew setup. When finished, type /quit to end the session.${NC}"
  fi
  sprintbias_run_interactive \
    --append-system-prompt "$rules" \
    --name "crew-setup" \
    "Read the project and any existing crew, then ask me your first question."
}

# ── Dispatch ─────────────────────────────────────────────────────────
case "${1:-}" in
  ""|list)        cmd_list ;;
  add)            shift; cmd_add "$@" ;;
  setup)
    shift
    case "${1:-}" in -h|--help|help) usage; exit 0 ;; esac
    if [ $# -gt 0 ]; then usage >&2; exit 1; fi
    cmd_setup ;;
  -h|--help|help) usage ;;
  *)
    if ! valid_name "$1"; then usage; exit 1; fi
    _name="$1"; shift
    sprintbias_plan_args --bare "$@"
    cmd_start "$_name" ${SPRINTBIAS_ARGS[@]+"${SPRINTBIAS_ARGS[@]}"} ;;
esac
exit
}
