# SprintBias prompt for zsh (macOS Terminal, iTerm, Ghostty, Linux).
#
# What it shows:
#   line 1   machine  path (branch*)                  Sat Oct 04 14:05:09 PDT (UTC-0700)  12s
#   line 2   %
#
#   machine  short host name — blue at home, bold red over SSH, so you always
#            know which computer you are typing into
#   path     where you are, with ~ for your home folder
#   branch   current git branch; * means uncommitted changes
#   clock    date, time, time zone and UTC offset (right edge)
#   12s      how long the last command took, when it ran 3 seconds or more
#
# It also sets the terminal tab / window title to the path (plus the running
# command while it runs). Inside tmux the title becomes the pane title.
#
# Installed by `./sprint.sh shell install`, which adds one marked
# block to ~/.zshrc that sources this file. Remove with `./sprint.sh shell remove`.
#
# Settings (set before this file is sourced):
#   NO_COLOR=1             same prompt, no colors
#   SPRINTBIAS_SLOW=5      seconds before the duration shows (default 3)

# Only for interactive shells — scripts and `zsh -c` stay untouched.
[[ -o interactive ]] || return 0

setopt prompt_subst   # lets the prompt read the variables set below

# ── Colors ───────────────────────────────────────────────────────────
if [[ -n ${NO_COLOR:-} ]]; then
  __sb_host_c='' __sb_path_c='' __sb_branch_c='' __sb_clock_c='' __sb_slow_c='' __sb_off=''
else
  __sb_path_c='%F{cyan}' __sb_branch_c='%F{magenta}' __sb_clock_c='%F{11}'
  __sb_slow_c='%F{red}' __sb_off='%f%b'
  if [[ -n ${SSH_CONNECTION:-}${SSH_TTY:-} ]]; then
    __sb_host_c='%B%F{red}'    # remote: loud, so a server never looks like your laptop
  else
    __sb_host_c='%F{blue}'
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
  for line in ${(f)out}; do
    case $line in
      ('# branch.head '*) head=${line#'# branch.head '} ;;
      ('# branch.oid '*)  oid=${line#'# branch.oid '} ;;
      ('#'*) ;;
      (*) dirty='*'; break ;;
    esac
  done
  [[ $head == '(detached)' ]] && head=${oid[1,7]}
  __sb_branch=" (${head//\%/%%}$dirty)"   # %% so a branch name can't inject prompt codes
}

# ── Title: tab = path, window = user@host: path [— command] ──────────
__sb_title() {
  [[ $TERM == (dumb|linux) ]] && return
  local where=${(%):-%~} who=${(%):-%n@%m} cmd=${1:+ — $1}
  print -rn -- $'\e]1;'"$where$cmd"$'\a\e]2;'"$who: $where$cmd"$'\a'
}

# ── Hooks: start the timer before a command, read it after ───────────
__sb_preexec() {
  __sb_start=$SECONDS
  __sb_title "${1[1,80]}"
}

__sb_precmd() {
  __sb_slow=''
  if [[ -n ${__sb_start:-} ]]; then
    local took=$(( SECONDS - __sb_start ))
    (( took >= ${SPRINTBIAS_SLOW:-3} )) && __sb_slow=" ${__sb_slow_c}${took}s${__sb_off}"
  fi
  __sb_start=''
  __sb_git_branch
  __sb_title
}

# Register once — sourcing this file again (an update) never doubles hooks,
# and any precmd/preexec hooks you already have keep working.
(( ${precmd_functions[(Ie)__sb_precmd]} )) || precmd_functions+=(__sb_precmd)
(( ${preexec_functions[(Ie)__sb_preexec]} )) || preexec_functions+=(__sb_preexec)

# ── The prompt ───────────────────────────────────────────────────────
# Line 1: machine, path, branch (clock and timer sit at the right edge).
# Line 2: where you type.
PROMPT="${__sb_host_c}%m${__sb_off} ${__sb_path_c}%~${__sb_off}"
PROMPT+="${__sb_branch_c}"'${__sb_branch}'"${__sb_off}"$'\n''%# '
RPROMPT="${__sb_clock_c}%D{%a %b %d %H:%M:%S %Z (UTC%z)}${__sb_off}"'${__sb_slow}'
