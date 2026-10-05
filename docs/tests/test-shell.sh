#!/usr/bin/env bash
# Each check is a string run by eval, so its $vars expand at check time.
# shellcheck disable=SC2016,SC2034
# Test: shell prompt files (docs/sprintbias/shell/) and `sprint shell`
# (scripts/shell.sh). Renders the prompt in a temp git repo for zsh and bash,
# and runs install / install / remove against a temp HOME checking one block,
# a byte-exact restore, and that nothing outside our block changes.

set -euo pipefail

PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SHELL_DIR="$ROOT/docs/sprintbias/shell"
SCRIPT="$ROOT/docs/sprintbias/scripts/shell.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

ok()   { echo "  PASS: $1"; PASS=$((PASS + 1)); }
bad()  { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }
check() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

# ── Syntax ───────────────────────────────────────────────────────────
echo "Syntax"
check "prompt.bash parses"  'bash -n "$SHELL_DIR/prompt.bash"'
check "shell.sh parses"     'bash -n "$SCRIPT"'
if command -v zsh >/dev/null 2>&1; then
  check "prompt.zsh parses" 'zsh -n "$SHELL_DIR/prompt.zsh"'
fi

# ── A git repo to render in ──────────────────────────────────────────
REPO="$TMP/repo"
mkdir -p "$REPO"
(
  cd "$REPO"
  # A fresh repo whose (unborn) branch is main — no commit needed.
  git init -q
  printf 'ref: refs/heads/main\n' > .git/HEAD
)

# ── bash ─────────────────────────────────────────────────────────────
echo "bash prompt"
render_bash() {  # render_bash "<extra env>" → __sb_branch|PS1
  # shellcheck disable=SC2086  # $1 is "" or one NAME=value word
  env TERM=dumb $1 bash --norc --noprofile -i -c '
    . "'"$SHELL_DIR"'/prompt.bash"
    . "'"$SHELL_DIR"'/prompt.bash"      # twice: must not double-register
    cd "'"$REPO"'"; __sb_precmd
    printf "%s|%s|%s\n" "$__sb_branch" "$PROMPT_COMMAND" "$PS1"
  ' 2>/dev/null
}
out="$(render_bash "")"
check "clean repo shows (main)"           '[[ "$out" == " (main)|"* ]]'
check "PROMPT_COMMAND has hook once"      '[ "$(printf "%s" "$out" | grep -o __sb_precmd | wc -l | tr -d " ")" = 1 ]'
check "PS1 has host, path, clock"         '[[ "$out" == *"\\h"*"\\w"*"\\D{"* ]]'
check "PS1 has color codes"               '[[ "$out" == *"\\e["* ]]'
out_nc="$(render_bash "NO_COLOR=1")"
check "NO_COLOR drops color codes"        '[[ "$out_nc" != *"\\e["* ]]'
out_ssh="$(render_bash "SSH_CONNECTION=1.2.3.4")"
check "SSH turns host bold red"           '[[ "$out_ssh" == *"1;31m"* ]]'
echo change > "$REPO/file.txt"; (cd "$REPO" && git add file.txt)
out="$(render_bash "")"
check "dirty repo shows (main*)"          '[[ "$out" == " (main*)|"* ]]'
check "hook keeps the last exit status" \
  '[ "$(TERM=dumb bash --norc -i -c ". \"$SHELL_DIR/prompt.bash\"; (exit 7); __sb_precmd; echo \$?" 2>/dev/null)" = 7 ]'
check "non-interactive bash: no effect" \
  '[ "$(bash --norc -c ". \"$SHELL_DIR/prompt.bash\"; type __sb_precmd >/dev/null 2>&1 && echo yes || echo no")" = no ]'

# ── zsh ──────────────────────────────────────────────────────────────
if command -v zsh >/dev/null 2>&1; then
  echo "zsh prompt"
  zout="$(TERM=dumb zsh -f -i -c '
    source "'"$SHELL_DIR"'/prompt.zsh"
    source "'"$SHELL_DIR"'/prompt.zsh"
    cd "'"$REPO"'"; __sb_precmd
    print -r -- "${__sb_branch}|${(j: :)precmd_functions}|${(j: :)preexec_functions}"
    print -rP -- "$PROMPT"
  ' 2>/dev/null)"
  check "dirty repo shows (main*)"        '[[ "$zout" == " (main*)|"* ]]'
  check "precmd hook registered once"     '[ "$(printf "%s" "$zout" | head -1 | grep -o __sb_precmd | wc -l | tr -d " ")" = 1 ]'
  check "rendered prompt has branch"      '[[ "$zout" == *"repo"*"(main*)"* ]]'
  check "non-interactive zsh: no effect" \
    '[ "$(zsh -f -c "source \"$SHELL_DIR/prompt.zsh\"; (( \$+functions[__sb_precmd] )) && echo yes || echo no")" = no ]'
fi

# ── install / install / remove ───────────────────────────────────────
echo "install and remove"
run() { HOME="$1" XDG_CONFIG_HOME='' ZDOTDIR='' SHELL=/bin/zsh bash "$SCRIPT" "${@:2}" >/dev/null 2>&1; }
blocks() { grep -c '^# >>> sprintbias shell >>>$' "$1" 2>/dev/null || true; }

for sh in zsh bash; do
  H="$TMP/home-$sh"; mkdir -p "$H"
  rc="$H/.zshrc"; [ "$sh" = bash ] && rc="$H/.bashrc"
  printf 'export FOO=1\nalias ll="ls -l"\n' > "$rc"
  printf 'set -g mouse off' > "$H/.tmux.conf"     # no trailing newline on purpose
  cp "$rc" "$TMP/orig-rc"; cp "$H/.tmux.conf" "$TMP/orig-tmux"

  run "$H" install "--$sh" --tmux --yes
  run "$H" install "--$sh" --tmux --yes
  check "$sh: one block after two installs"  '[ "$(blocks "$rc")" = 1 ]'
  check "$sh: tmux one block"                '[ "$(blocks "$H/.tmux.conf")" = 1 ]'
  check "$sh: tmux user line kept intact"    'grep -qx "set -g mouse off" "$H/.tmux.conf"'
  check "$sh: files copied"                  '[ -f "$H/.config/sprintbias/shell/prompt.$sh" ]'
  check "$sh: backup made"                   'cmp -s "$TMP/orig-rc" "$rc.sprintbias-bak"'
  check "$sh: block uses \$HOME, not a fixed path" 'grep -qF "\$HOME/.config/sprintbias/shell/prompt.$sh" "$rc"'
  check "$sh: block loads in a real shell" \
    '[ "$(HOME="$H" TERM=dumb $sh -i -c "echo \${__sb_host_c+loaded}" 2>/dev/null </dev/null)" = loaded ]'

  echo "# added by the user later" >> "$rc"
  printf '# added by the user later\n' >> "$TMP/orig-rc"
  echo "set -g history-limit 9" >> "$H/.tmux.conf"   # after our block, in a file we newline-fixed
  printf '\nset -g history-limit 9\n' >> "$TMP/orig-tmux"
  run "$H" remove --yes
  check "$sh: rc restored byte for byte"     'cmp -s "$TMP/orig-rc" "$rc"'
  check "$sh: tmux restored byte for byte"   'cmp -s "$TMP/orig-tmux" "$H/.tmux.conf"'
  check "$sh: copied files gone"             '[ ! -d "$H/.config/sprintbias" ]'
  check "$sh: backup kept (file changed since)" '[ -e "$rc.sprintbias-bak" ]'
done

# A shell file we had to create is removed again.
H="$TMP/home-new"; mkdir -p "$H"
run "$H" install --bash --yes
check "new: .bashrc created with block"  '[ "$(blocks "$H/.bashrc")" = 1 ]'
check "new: only picked parts installed" '[ ! -e "$H/.zshrc" ] && [ ! -e "$H/.tmux.conf" ]'
run "$H" remove --yes
check "new: created .bashrc removed"     '[ ! -e "$H/.bashrc" ] && [ ! -e "$H/.bash_profile" ]'

# Login file: a ~/.profile that loads ~/.bashrc (Ubuntu) needs no block; one
# that does not gets the block itself — and no ~/.bash_profile is created to
# hide it.
H="$TMP/home-ubuntu"; mkdir -p "$H"
printf '. "$HOME/.bashrc"\n' > "$H/.profile"; cp "$H/.profile" "$TMP/orig-profile"
run "$H" install --bash --yes
check "login: .profile that loads .bashrc untouched" 'cmp -s "$TMP/orig-profile" "$H/.profile" && [ ! -e "$H/.bash_profile" ]'
run "$H" remove --yes
H="$TMP/home-profile"; mkdir -p "$H"
printf 'export PATH="$HOME/bin:$PATH"\n' > "$H/.profile"; cp "$H/.profile" "$TMP/orig-profile"
run "$H" install --bash --yes
check "login: other .profile gets the block" '[ "$(blocks "$H/.profile")" = 1 ] && [ ! -e "$H/.bash_profile" ]'
run "$H" remove --yes
check "login: .profile restored, backup cleaned" 'cmp -s "$TMP/orig-profile" "$H/.profile" && [ ! -e "$H/.profile.sprintbias-bak" ]'

# Several picks at once: zsh + bash + tmux in one go, one block each.
H="$TMP/home-all"; mkdir -p "$H"
run "$H" install --zsh --bash --tmux --yes
check "all: zsh, bash, tmux each one block" \
  '[ "$(blocks "$H/.zshrc")$(blocks "$H/.bashrc")$(blocks "$H/.tmux.conf")" = 111 ]'
run "$H" remove --yes
check "all: everything removed" '[ ! -e "$H/.zshrc" ] && [ ! -e "$H/.bashrc" ] && [ ! -e "$H/.tmux.conf" ]'

# --yes with no picks: the login shell only (plus tmux when installed).
H="$TMP/home-default"; mkdir -p "$H"
run "$H" install --yes      # run() sets SHELL=/bin/zsh
check "default: login shell (zsh) set up" '[ "$(blocks "$H/.zshrc")" = 1 ] && [ ! -e "$H/.bashrc" ]'

# Asks first: without a terminal and without --yes, nothing changes.
H="$TMP/home-ask"; mkdir -p "$H"
HOME="$H" XDG_CONFIG_HOME='' bash "$SCRIPT" install --bash </dev/null >/dev/null 2>&1 && rc_ask=0 || rc_ask=$?
check "no tty, no --yes: refuses"        '[ "$rc_ask" != 0 ] && [ ! -e "$H/.bashrc" ]'

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
