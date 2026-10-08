#!/usr/bin/env bash
# crew.sh — Named AI sessions with roles. See: ./sprint.sh help crew
#
#   crew                          list members and the tasks each holds (no AI)
#   crew add <name> "<role>" [--lead]   create docs/crew/<name>.md from the template
#   crew <name> [ID | plan:N]     start an interactive session as that member
#
# A member is a markdown file (docs/crew/<name>.md). A task's **Crew** field
# routes it to a member; a member moving the task into doing/ sets the field to
# its own name, which is the claim. The files are the shared state; messages
# between sessions are only the nudge.

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPTS_DIR/.." && pwd)/lib.sh"

CREW_DIR="docs/crew"
TEMPLATE="$CREW_DIR/.TEMPLATE-crew.md"

usage() {
  echo "Usage: ./sprint.sh crew                            list the crew and what each holds"
  echo "       ./sprint.sh crew add <name> \"<role>\" [--lead]  add a member"
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
    echo "No crew yet. Add one member per role, starting with a lead:"
    echo "  ./sprint.sh crew add lead \"Keeps everyone rowing: holds the plan, routes tasks\" --lead"
    echo "  ./sprint.sh crew add builder \"Builds and runs the project locally\""
  fi
}

# ── crew add ─────────────────────────────────────────────────────────
cmd_add() {
  local name="${1:-}" role="${2:-}" lead="no"
  [ "${3:-}" = "--lead" ] && lead="yes"
  if [ -z "$name" ] || [ -z "$role" ]; then usage; exit 1; fi
  if ! valid_name "$name" || [[ "$name" =~ ^(add|list|help)$ ]]; then
    echo -e "${RED}✗ Crew names use lowercase letters, digits and dashes (not add, list or help): $name${NC}" >&2
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
  awk -v n="$display" -v r="$role" -v l="$lead" '
    /^# Crew: / { print "# Crew: " n; next }
    /^\*\*Role\*\*:/ { print "**Role**: " r; next }
    /^\*\*Lead\*\*:/ { print "**Lead**: " l; next }
    { print }' "$dest" > "$tmp" && mv "$tmp" "$dest"
  echo -e "${GREEN}Added crew member: $dest${NC}"
  echo "Next: fill in Job, Reads first, May touch and Reports, then start it:"
  echo "  ./sprint.sh crew $name"
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

  local work_line self=""
  case "$target" in
    "")
      if [ "$lead" = "yes" ]; then
        work_line="No target was given. Run ./sprint.sh status and ./sprint.sh crew, then ask the human which plan to lead."
      else
        work_line="No target was given. Run ./sprint.sh crew to see what you hold. If it is nothing, ask the lead or the human what to pick up."
      fi ;;
    plan:*)
      local pid="${target#plan:}" pfile
      if ! pfile="$(sprintbias_find_plan "$pid")"; then
        echo -e "${RED}✗ No plan $pid in docs/plans/${NC}" >&2; exit 1
      fi
      work_line="Your work is plan $pid: $pfile." ;;
    *)
      local tfile
      if ! [[ "$target" =~ ^[0-9]+$ ]] || ! tfile="$(sprintbias_task_path "$target")"; then
        echo -e "${RED}✗ No task $target. Pass a task ID or plan:N.${NC}" >&2; exit 1
      fi
      work_line="Your work is task $target: $tfile. Claim it before you start."
      self="$tfile" ;;
  esac

  local rules="You are ${name}, a member of this project's crew. Your role: ${role}.
Your member file is ${file}. It is your job description: read it first, then the Crew section of DOCUMENTATION.md, then docs/sprintbias/project.md if it exists.

${work_line}

Crew rules:
1. The files are the shared state. Anything that must last goes in a task file or the plan file, never only in a message.
2. Claim a task before you work it: move it into docs/tasks/doing/ (git mv SRC DEST || mv SRC DEST) and set its **Crew** field to ${name}. A task in doing/ whose Crew names another member is theirs. Leave it alone and tell the lead if you need it.
3. Stay inside what your member file says you may touch. Hand everything else to the member who owns it (./sprint.sh crew lists everyone).
4. Finish the normal way: fill the task's ## Completed section, move it to review/, then report as your member file says.
5. Other members are reachable by their crew name. Messages are for nudges and questions.
6. The human approves, commits and ships.

$(sprintbias_parallel_rule "$self")"

  if [ "$lead" = "yes" ]; then
    rules="${rules}

You lead this crew. Like a coxswain, you keep everyone rowing in time:
- Hold the central idea of how the plan's problem gets solved. Write it in the plan file under a ## Crew section (add it after ## Member tasks): the approach in a few lines, then one line per member: name, the task IDs they hold, and their state (working, blocked on what, done).
- Route each task by setting its **Crew** field to the member whose role fits, then send that member a short message naming the task.
- Think across the crew: catch two members about to edit the same file, order the work so dependencies land first, and settle conflicts before they turn into merge pain.
- Leave product code to the members. You plan, route, unblock and check finished work.
- Raise decisions for the human one at a time."
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
    "Read your member file and your work, then tell me in two or three lines who you are and what you will do first."
}

# ── Dispatch ─────────────────────────────────────────────────────────
case "${1:-}" in
  ""|list)        cmd_list ;;
  add)            shift; cmd_add "$@" ;;
  -h|--help|help) usage ;;
  *)
    if ! valid_name "$1"; then usage; exit 1; fi
    cmd_start "$@" ;;
esac
