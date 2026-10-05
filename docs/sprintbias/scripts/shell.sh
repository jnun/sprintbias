#!/usr/bin/env bash
# shell.sh — set up, refresh, or remove the SprintBias terminal prompt for zsh
# and bash, plus an optional tmux status bar. No AI is invoked.
# See: ./sprint.sh help shell
#
# The prompt files live in docs/sprintbias/shell/. Install copies them to a
# per-user folder (so the prompt survives the project moving) and adds one
# marked block to each chosen file that loads them:
#
#     # >>> sprintbias shell >>>
#     ...
#     # <<< sprintbias shell <<<
#
# The user's files are theirs: we ask first, back up before the first change,
# touch only our block, and `remove` restores each file byte for byte.

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPTS_DIR/.." && pwd)/lib.sh"

SHELL_SRC="$(cd "$SCRIPTS_DIR/../shell" && pwd)"
FILES="prompt.zsh prompt.bash tmux.conf"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/sprintbias/shell"
STATE="$DEST/.state"    # files we created or newline-fixed, so remove is exact
BEGIN_MARK="# >>> sprintbias shell >>>"
END_MARK="# <<< sprintbias shell <<<"

usage() {
  cat <<'EOF'
Usage:
  ./sprint.sh shell                     # status: what is set up on this machine
  ./sprint.sh shell install             # guided: asks about zsh, bash, and tmux
  ./sprint.sh shell install --zsh --tmux   # pick directly (any of --zsh --bash --tmux)
  ./sprint.sh shell remove              # take it all back out

Options:
  --zsh      zsh prompt (the macOS default shell)
  --bash     bash prompt (the Linux / Ubuntu default shell)
  --tmux     tmux status bar with the machine name (for remote server sessions)
  --yes      no questions; with no picks, sets up your login shell + tmux if installed

Each machine needs its own install: run it again on every new server you build.
EOF
}

# ── Small helpers ────────────────────────────────────────────────────

have()        { command -v "$1" >/dev/null 2>&1; }
host_name()   { local h; h="$(uname -n)"; printf '%s' "${h%%.*}"; }
pretty()      { local home="$HOME" tilde='~'; printf '%s' "${1/#"$home"/$tilde}"; }
login_shell() { case "$(basename "${SHELL:-bash}")" in zsh) echo zsh ;; *) echo bash ;; esac; }

# The folder as a shell file should spell it: "$HOME/…" when under home, so
# the line still works if these files are synced to another machine.
dest_ref() {
  case "$DEST" in
    "$HOME"/*) printf '%s' "\$HOME${DEST#"$HOME"}" ;;
    *)         printf '%s' "$DEST" ;;
  esac
}

ask() {  # ask "Question" [y|n default] → 0 for yes
  [ "$ASSUME_YES" = 1 ] && return 0
  local ans def="${2:-n}" hint="[y/N]"
  [ "$def" = y ] && hint="[Y/n]"
  printf '%s %s ' "$1" "$hint"
  read -r ans || ans=""
  case "${ans:-$def}" in y|Y|yes|YES|Yes) return 0 ;; *) return 1 ;; esac
}

need_terminal() {  # questions need a terminal unless --yes
  if [ "$ASSUME_YES" = 1 ] || [ -t 0 ]; then return 0; fi
  echo -e "${YELLOW}shell $1 asks before changing your files and needs a terminal.${NC}" >&2
  echo "Run it in a terminal, or add --yes (e.g. ./sprint.sh shell $1 --yes)." >&2
  exit 1
}

# ── Which files ──────────────────────────────────────────────────────

zshrc()  { echo "${ZDOTDIR:-$HOME}/.zshrc"; }
bashrc() { echo "$HOME/.bashrc"; }

tmux_conf() {
  local xdg="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"
  if [ ! -e "$HOME/.tmux.conf" ] && [ -f "$xdg" ]; then echo "$xdg"; else echo "$HOME/.tmux.conf"; fi
}

# Login shells (macOS Terminal, SSH) read only the first of these files that
# exists, and skip ~/.bashrc unless it loads it. Print the file that needs the
# block too — nothing when it already loads ~/.bashrc. ~/.bash_profile is
# created only when none exist, since a new one would hide the user's ~/.profile.
bash_login_file() {
  local f
  for f in "$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.profile"; do
    [ -e "$f" ] || continue
    grep -q '\.bashrc' "$f" || echo "$f"
    return 0
  done
  echo "$HOME/.bash_profile"
}

# Every file a block can live in — remove sweeps all of them.
all_targets() {
  zshrc; bashrc; tmux_conf
  printf '%s\n' "$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.profile"
}

# ── The marked block ─────────────────────────────────────────────────

has_block() { [ -f "$1" ] && grep -qxF "$BEGIN_MARK" "$1"; }

state_has() { grep -qxF "$1" "$STATE" 2>/dev/null; }
state_add() { mkdir -p "$DEST"; state_has "$1" || echo "$1" >> "$STATE"; }

# Drop our block (marker lines inclusive) from file $1; every other byte stays.
# With $2 = final (a real remove), also take back the newline install added to
# a file that did not end in one — only while our block is still the last thing.
strip_block() {
  local f="$1" trim=0 tmp
  if [ "${2:-}" = final ] && state_has "nl $f"; then trim=1; fi
  tmp="$(mktemp)"
  awk -v b="$BEGIN_MARK" -v e="$END_MARK" -v trim="$trim" '
    $0 == b { skip = 1; end_at = n; next }
    skip    { if ($0 == e) skip = 0; next }
            { line[++n] = $0 }
    END {
      cut = (trim && n > 0 && end_at == n)
      for (i = 1; i <= n; i++) printf "%s%s", line[i], (i < n || !cut) ? "\n" : ""
    }
  ' "$f" > "$tmp"
  cat "$tmp" > "$f"   # write through, keeping the file's owner and mode
  rm -f "$tmp"
}

# Add (or refresh) the block in file $1 with body $2.
put_block() {
  local f="$1" body="$2"
  if [ ! -e "$f" ]; then
    mkdir -p "$(dirname "$f")"
    : > "$f"
    state_add "created $f"
  elif ! has_block "$f" && [ ! -e "$f.sprintbias-bak" ]; then
    cp -p "$f" "$f.sprintbias-bak"
    echo -e "  ${DIM}backup: $(pretty "$f").sprintbias-bak${NC}"
  fi
  if has_block "$f"; then
    strip_block "$f"
  elif [ -s "$f" ] && [ -n "$(tail -c 1 "$f")" ]; then
    printf '\n' >> "$f"   # the file did not end with a newline
    state_add "nl $f"
  fi
  printf '%s\n%s\n%s\n' "$BEGIN_MARK" "$body" "$END_MARK" >> "$f"
}

# Undo put_block for file $1: drop the block, then the file if we made it, and
# the backup once the file matches it again.
take_block() {
  local f="$1"
  has_block "$f" || return 0
  strip_block "$f" final
  if state_has "created $f" && [ ! -s "$f" ]; then rm -f "$f"; fi
  if [ -e "$f.sprintbias-bak" ] && cmp -s "$f" "$f.sprintbias-bak"; then rm -f "$f.sprintbias-bak"; fi
  echo "  removed from $(pretty "$f")"
}

shell_block() {  # shell_block zsh|bash
  local p
  p="$(dest_ref)/prompt.$1"
  printf '%s\n%s' \
    "# Friendly prompt from SprintBias. Take it out with: ./sprint.sh shell remove" \
    "[ -r \"$p\" ] && . \"$p\""
}

tmux_block() { printf 'source-file -q "%s/tmux.conf"' "$(dest_ref)"; }

# ── Parts: zsh, bash, tmux ───────────────────────────────────────────

part_file() {
  case "$1" in
    zsh)  zshrc ;;
    bash) bashrc ;;
    tmux) tmux_conf ;;
  esac
}

part_installed() { has_block "$(part_file "$1")"; }

copy_files() {
  local f
  mkdir -p "$DEST"
  for f in $FILES; do cp "$SHELL_SRC/$f" "$DEST/$f"; done
}

is_current() {
  local f
  for f in $FILES; do cmp -s "$SHELL_SRC/$f" "$DEST/$f" || return 1; done
}

# ── Commands ─────────────────────────────────────────────────────────

cmd_status() {
  local part found=0 where=""
  [ -n "${SSH_CONNECTION:-}" ] && where="  (over SSH)"
  echo -e "${BOLD}SprintBias shell${NC}"
  echo    "  Machine:  $(host_name)$where   login shell: $(login_shell)"
  for part in zsh bash tmux; do
    if part_installed "$part"; then
      printf "  %-6s ${GREEN}installed${NC}  %s\n" "$part" "$(pretty "$(part_file "$part")")"
      found=1
    elif have "$part"; then
      printf "  %-6s ${DIM}not set up${NC}\n" "$part"
    else
      printf "  %-6s ${DIM}not on this machine${NC}\n" "$part"
    fi
  done
  if [ "$found" = 0 ]; then
    echo    "  Next:     ./sprint.sh shell install"
  elif is_current; then
    echo -e "  Files:    ${GREEN}current${NC} ($(pretty "$DEST"))"
  else
    echo -e "  Files:    ${YELLOW}update available${NC} — run: ./sprint.sh shell install"
  fi
}

# Ask about one shell. Suggests yes for your login shell or one already set up.
ask_shell() {  # ask_shell zsh|bash "description"
  local sh="$1" label def=n
  if ! have "$sh" && ! part_installed "$sh"; then
    echo -e "  ${DIM}$(printf '%-5s' "$sh") — not on this machine, skipped${NC}"
    return 0
  fi
  label="$(printf '%-5s' "$sh") — $2"
  if [ "$(login_shell)" = "$sh" ]; then label="$label (your shell)"; def=y; fi
  if part_installed "$sh"; then label="$label, installed"; def=y; fi
  if ask "  $label?" "$def"; then
    if [ "$sh" = zsh ]; then WANT_ZSH=1; else WANT_BASH=1; fi
  fi
}

# Guided picks: one question per part, defaulting to what fits this machine.
choose_parts() {
  local label
  echo -e "${BOLD}Set up a friendly prompt on $(host_name)${NC}"
  echo    "  Shows the machine name (red over SSH), folder, git branch, and clock."
  echo -e "  ${DIM}y adds or updates it · n leaves that part as it is${NC}"
  echo ""
  ask_shell zsh  "the macOS default shell"
  ask_shell bash "the Linux / Ubuntu default shell"
  if have tmux || part_installed tmux; then
    label="tmux  — status bar with the machine name, for remote server sessions"
    if part_installed tmux; then label="$label, installed"; fi
    if ask "  $label?" y; then WANT_TMUX=1; fi
  else
    echo -e "  ${DIM}tmux  — not installed here. For remote sessions: install it"
    echo -e "          (sudo apt install tmux / brew install tmux), then run this again.${NC}"
  fi
  echo ""
}

cmd_install() {
  local login="" tconf
  need_terminal install

  if [ "$PICKED" = 0 ]; then
    if [ "$ASSUME_YES" = 1 ]; then
      # No questions, no picks: the login shell, plus tmux when it is here.
      if [ "$(login_shell)" = zsh ]; then WANT_ZSH=1; else WANT_BASH=1; fi
      if have tmux; then WANT_TMUX=1; fi
    else
      choose_parts
    fi
  fi
  if [ "$WANT_ZSH$WANT_BASH$WANT_TMUX" = 000 ]; then
    echo "Nothing picked. Nothing changed."
    return 0
  fi

  tconf="$(tmux_conf)"
  if [ "$WANT_BASH" = 1 ]; then login="$(bash_login_file)"; fi

  echo "This will copy the prompt files to $(pretty "$DEST") and add one marked block to:"
  if [ "$WANT_ZSH" = 1 ];  then echo "  $(pretty "$(zshrc)")"; fi
  if [ "$WANT_BASH" = 1 ]; then echo "  $(pretty "$(bashrc)")${login:+  and $(pretty "$login") (read at login)}"; fi
  if [ "$WANT_TMUX" = 1 ]; then echo "  $(pretty "$tconf")"; fi
  ask "Go ahead?" y || { echo "Nothing changed."; return 0; }
  echo ""

  copy_files
  if [ "$WANT_ZSH" = 1 ]; then
    put_block "$(zshrc)" "$(shell_block zsh)"
    echo -e "  ${GREEN}✓${NC} zsh   $(pretty "$(zshrc)")"
  fi
  if [ "$WANT_BASH" = 1 ]; then
    put_block "$(bashrc)" "$(shell_block bash)"
    if [ -n "$login" ]; then put_block "$login" "$(shell_block bash)"; fi
    echo -e "  ${GREEN}✓${NC} bash  $(pretty "$(bashrc)")${login:+ + $(pretty "$login")}"
  fi
  if [ "$WANT_TMUX" = 1 ]; then
    put_block "$tconf" "$(tmux_block)"
    echo -e "  ${GREEN}✓${NC} tmux  $(pretty "$tconf")"
  fi

  echo ""
  echo -e "${BOLD}See it:${NC}"
  if [ -n "${SSH_CONNECTION:-}" ]; then
    echo "  Log out and SSH back in."
  else
    echo "  Open a new terminal tab (or, in this one: exec $(login_shell))."
  fi
  if [ "$WANT_TMUX" = 1 ]; then
    echo "  Running tmux already? tmux source-file $(pretty "$tconf")"
  fi
  echo ""
  echo -e "${DIM}Run this again any time to update. Each machine needs its own install —"
  echo -e "building a new server? SSH in and run ./sprint.sh shell install there too.${NC}"
}

cmd_remove() {
  local f found=""
  while IFS= read -r f; do
    if has_block "$f"; then found=1; fi
  done < <(all_targets)
  if [ -z "$found" ] && [ ! -d "$DEST" ]; then
    echo "SprintBias shell is not installed. Nothing to remove."
    return 0
  fi
  need_terminal remove
  ask "Remove the SprintBias prompt and its files?" || { echo "Nothing changed."; return 0; }
  while IFS= read -r f; do take_block "$f"; done < <(all_targets)
  rm -rf "$DEST"
  rmdir "$(dirname "$DEST")" 2>/dev/null || true
  echo "Done. Open a new terminal tab to get your old prompt back."
}

# ── Arguments ────────────────────────────────────────────────────────

ACTION=status ASSUME_YES=0 PICKED=0 WANT_ZSH=0 WANT_BASH=0 WANT_TMUX=0
for arg in "$@"; do
  case "$arg" in
    install|update)   ACTION=install ;;
    remove|uninstall) ACTION=remove ;;
    status)    ACTION=status ;;
    --zsh)     WANT_ZSH=1;  PICKED=1 ;;
    --bash)    WANT_BASH=1; PICKED=1 ;;
    --tmux)    WANT_TMUX=1; PICKED=1 ;;
    --yes)     ASSUME_YES=1 ;;
    --help|-h) usage; exit 0 ;;
    *) echo -e "${RED}Unknown argument: $arg${NC}" >&2; usage >&2; exit 1 ;;
  esac
done

"cmd_$ACTION"
