A ready-made terminal prompt that tells you where you are — which machine,
which folder, which git branch — on macOS (zsh or bash) and Linux/Ubuntu
(bash). No AI is invoked.

Quick start:
  1. ./sprint.sh shell install
     It asks about each part — press Enter to take the suggested answer:
       zsh    the macOS default shell
       bash   the Linux / Ubuntu default shell
       tmux   status bar with the machine name, for remote server sessions
  2. Open a new terminal tab (over SSH: log out and back in).
  That's it. Run install again any time to update; shell remove undoes it.

  Each machine needs its own install. When you build a new server, SSH in
  and run ./sprint.sh shell install there too (see Servers below).

Usage:
  ./sprint.sh shell                     # status: what is set up on this machine
  ./sprint.sh shell install             # guided: asks about zsh, bash, tmux
  ./sprint.sh shell install --bash --tmux   # pick parts directly, skip the questions
  ./sprint.sh shell remove              # take everything back out

What you get:
  my-laptop ~/Projects/app (main*)  Sat Oct 04 14:05:09 PDT (UTC-0700) 12s
  %

  machine   short host name — blue on your own computer, bold red over SSH
  path      where you are, ~ for home
  (main*)   git branch; * means uncommitted changes
  clock     date, time, time zone, UTC offset
  12s       how long the last command took, when 3 seconds or more
  title     terminal tab and window show user@host: path

  With tmux, the status bar starts with the host name and turns red
  over SSH, the outer terminal title shows host - session - window, and you
  get mouse support, bigger scrollback, and splits that keep your folder
  (Ctrl-b | and Ctrl-b -).

Options (any mix; naming parts skips those questions):
  --zsh     zsh prompt
  --bash    bash prompt
  --tmux    tmux status bar
  --yes     no questions (for scripts); with no parts named, sets up your
            login shell plus tmux when it is installed

How it installs:
  - Copies prompt.zsh, prompt.bash, and tmux.conf to
    ~/.config/sprintbias/shell/, so it keeps working if the project moves.
  - Adds one marked block to each file you said yes to — ~/.zshrc,
    ~/.bashrc, ~/.tmux.conf. For bash it also covers login shells (macOS
    Terminal, SSH): your login file gets the block too, unless it already
    loads ~/.bashrc. The block names $HOME, not your exact path, so synced
    dotfiles work on every machine:
        # >>> sprintbias shell >>>
        ...
        # <<< sprintbias shell <<<
  - Backs up each file the first time (<file>.sprintbias-bak); remove
    deletes the backup again once your file matches it.
  - Running install again refreshes the files and keeps exactly one block —
    that is how you update after a new SprintBias version.
  - remove deletes the blocks and the copied files; your files go back to
    exactly what they were.

Servers:
  1. SSH in and cd into any project that has SprintBias (setup.sh) in it.
  2. ./sprint.sh shell install — say yes to bash (Ubuntu's shell) and tmux.
     No tmux yet? sudo apt install tmux, then run install again.
  3. Log out and back in.
  The prompt is copied to your home folder, so it keeps working everywhere on
  that server — even if the project goes away. Over SSH the machine name is
  red. If the name is generic (ubuntu, ip-172-31-4-12), rename the server:
      sudo hostnamectl set-hostname web-prod-1

Don't see it?
  - Open a new tab, or run: exec $SHELL
  - Run ./sprint.sh shell to see which parts are set up. Using a shell that
    says "not set up"? Run install again and say yes to it.
  - In tmux already running: tmux source-file ~/.tmux.conf

Settings — add a line like these to ~/.zshrc or ~/.bashrc, above the
SprintBias block:
  export SPRINTBIAS_SLOW=5    # seconds before the timer shows (default 3)
  export NO_COLOR=1           # same prompt without color

Notes:
  - The timer needs zsh or bash 4.4+; macOS's built-in bash 3.2 shows
    everything else.
  - Files only change when you say yes (or pass --yes). Saying no to a part
    leaves it exactly as it is.
