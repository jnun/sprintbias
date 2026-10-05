Agents — every AI session running on this machine and on your servers, in one view.

Usage:
  ./sprint.sh agents                  list sessions here and on each AGENT_HOSTS host
  ./sprint.sh agents --local          this machine only
  ./sprint.sh agents --host dev-box   add a host for this run (repeatable)
  ./sprint.sh agents --json           the same facts as JSON, for scripts
  ./sprint.sh agents label            title each terminal tab (or tmux window) with its session name

Each session shows:
  name            the session name other sessions message it by (crew name, or
                  the CLI's own name for it)
  state           busy / waiting (needs you) / idle, and for how long
  where           the terminal app and tty, or the tmux session:window
  project@branch  the folder it started in and its branch
  up / last       how long it has run, and when it last wrote to its transcript
  model / ctx     the model of its last reply and the context it is carrying
  CPU / memory    summed over the session and the processes it started
  ↳ line          crew role, its topic, and the last thing you asked it

Servers: put ssh aliases in AGENT_HOSTS, space-separated, in
docs/sprintbias/config.local (personal, never shipped). The command reaches
each one with ssh in batch mode, so the alias must connect without a prompt
(keys loaded, any cloud login done). A host it cannot reach is shown as
unreachable with the reason; the rest still list. The server needs python3.

How do I:
  see who is working right now   ./sprint.sh agents  (busy and waiting are the ones to look at)
  find a session's tab           read its where column, or run agents label
  keep a tab's name for good     start sessions named: ./sprint.sh crew <name>,
                                 a name given when the CLI starts, or /rename inside one
  check one server only          ./sprint.sh agents --host dev-box with AGENT_HOSTS empty

Notes:
  Reads what Claude Code records about its sessions (~/.claude/sessions and the
  session transcripts). No AI runs and nothing changes except under label.
  Claude Code retitles the terminal as it works, so a label stamp lasts until
  that session's next retitle; a session started with a name keeps it.
  Sessions from older Claude Code builds that keep no registry show as
  claude-<pid>.
