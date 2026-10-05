# SprintBias prompt for bash (Ubuntu and other Linux, macOS bash 3.2+).
#
# What it shows:
#   line 1   machine  path (branch*)  Sat Oct 04 14:05:09 PDT (UTC-0700)  12s
#   line 2   $
#
#   machine  short host name — blue at home, bold red over SSH, so you always
#            know which computer you are typing into
#   path     where you are, with ~ for your home folder
#   branch   current git branch; * means uncommitted changes
#   clock    date, time, time zone and UTC offset
#   12s      how long the last command took, when it ran 3 seconds or more
#            (needs bash 4.4+; older bash simply leaves it out)
#
# It also sets the terminal tab / window title to the path. Inside tmux the
# title becomes the pane title.
#
# Installed by `./sprint.sh shell install`, which adds one marked
# block to ~/.bashrc that sources this file. Remove with `./sprint.sh shell remove`.
#
# Settings (set before this file is sourced):
#   NO_COLOR=1             same prompt, no colors
#   SPRINTBIAS_SLOW=5      seconds before the duration shows (default 3)

# Only for interactive bash — scripts stay untouched.
[ -n "${BASH_VERSION:-}" ] || return 0
case $- in *i*) ;; *) return 0 ;; esac

# ── Colors (\[ \] tell bash these take no space on screen) ───────────
if [ -n "${NO_COLOR:-}" ]; then
  __sb_host_c='' __sb_path_c='' __sb_branch_c='' __sb_clock_c='' __sb_slow_c='' __sb_off=''
else
  __sb_path_c='\[\e[36m\]' __sb_branch_c='\[\e[35m\]' __sb_clock_c='\[\e[93m\]'
  __sb_slow_c='\[\e[31m\]' __sb_off='\[\e[0m\]'
  if [ -n "${SSH_CONNECTION:-}${SSH_TTY:-}" ]; then
    __sb_host_c='\[\e[1;31m\]'   # remote: loud, so a server never looks like your laptop
  else
    __sb_host_c='\[\e[34m\]'
  fi
fi

# ── Git branch: " (main)" or " (main*)" when there are changes ─────
# One `git status` call gives both the branch and whether anything changed.
# --no-optional-locks keeps the prompt from ever waiting on a busy repo.
__sb_git_branch() {
  __sb_branch=''
  local out line head='' oid='' dirty=''
  out=$(command git --no-optional-locks status --porcelain=v2 --branch \
        --untracked-files=no --ignore-submodules 2>/dev/null) || return
  while IFS= read -r line; do
    case "$line" in
      '# branch.head '*) head=${line#'# branch.head '} ;;
      '# branch.oid '*)  oid=${line#'# branch.oid '} ;;
      '#'*) ;;
      *) dirty='*'; break ;;
    esac
  done <<< "$out"
  [ "$head" = '(detached)' ] && head=${oid:0:7}
  __sb_branch=" ($head$dirty)"
}

# ── Title: tab and window = user@host: path ──────────────────────────
__sb_title() {
  case "${TERM:-dumb}" in dumb|linux) return ;; esac
  local home="$HOME" tilde='~'
  printf '\033]0;%s@%s: %s\007' "${USER:-}" "${HOSTNAME%%.*}" "${PWD/#"$home"/$tilde}"
}

# ── Runs before each prompt ──────────────────────────────────────────
# Keeps $? intact, so any PROMPT_COMMAND that runs after it still sees the
# exit status of your last command.
__sb_precmd() {
  local last=$?
  __sb_slow=''
  if [ -n "${__sb_start:-}" ]; then
    local took=$(( SECONDS - __sb_start ))
    [ "$took" -ge "${SPRINTBIAS_SLOW:-3}" ] && __sb_slow=" ${took}s"
  fi
  __sb_start=''
  __sb_git_branch
  __sb_title
  return $last
}

# Register once, first in line so the timer reads true. Sourcing this file
# again (an update) never adds it twice; your own PROMPT_COMMAND still runs.
case ";${PROMPT_COMMAND:-};" in
  *__sb_precmd*) ;;
  *) PROMPT_COMMAND="__sb_precmd${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac

# Timer start: PS0 is expanded just before a command runs (bash 4.4+). The
# arithmetic records the start time and prints nothing; any PS0 you already
# have is kept after it.
if [ "${BASH_VERSINFO[0]}" -gt 4 ] || { [ "${BASH_VERSINFO[0]}" -eq 4 ] && [ "${BASH_VERSINFO[1]}" -ge 4 ]; }; then
  case "${PS0:-}" in
    *__sb_start*) ;;
    *) PS0='${PS1:0:$((__sb_start=SECONDS, 0))}'"${PS0:-}" ;;
  esac
fi

# ── The prompt ───────────────────────────────────────────────────────
# Line 1: machine, path, branch, clock, timer. Line 2: where you type.
PS1="${__sb_host_c}\h${__sb_off} ${__sb_path_c}\w${__sb_off}"
PS1+="${__sb_branch_c}"'${__sb_branch}'"${__sb_off}"
PS1+=" ${__sb_clock_c}\D{%a %b %d %H:%M:%S %Z (UTC%z)}${__sb_off}"
PS1+="${__sb_slow_c}"'${__sb_slow}'"${__sb_off}"'\n\$ '
