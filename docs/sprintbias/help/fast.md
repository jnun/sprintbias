Show or flip fast mode — one switch for how freely agents run. No AI is
invoked (keep family).

Usage:
  ./sprint.sh fast        # show the mode, where it comes from, how to flip it
  ./sprint.sh fast on     # fast: agents run autonomously at high throughput
  ./sprint.sh fast off    # steady (the default)

What it does:
  on / off — Writes FAST=on or FAST=off to docs/sprintbias/config.local,
             creating it when absent. The tracked config is left untouched:
             trust is a property of the machine, and config.local is
             gitignored and never ships.
  (bare)   — Prints fast: on or fast: off and where the value comes from.

In fast mode:
  - Agents skip the AI CLI's permission prompts (Claude Code's dangerous
    mode, Grok Build's always-approve; see docs/guides/provider-reality.md).
  - work and polish run independent tasks in parallel, 4 at a time, with no
    flag. --jobs N sets the count; --steady runs one at a time.
  - chat, chat plan, crew and work agents gain reach: a subagent may build
    a missing piece the goal needs, and a goal may touch another plan's task
    (read its Goal, serve both, note "Touched by plan N"). Deciding and
    recording ("Decided: X, because Y") holds in every mode.
  - Commit, push, ship.sh, sign-off to done/ and production credentials stay
    yours by rule. Fast is safest on a dev server or a clean git tree.

One run only (no file is rewritten):
  ./sprint.sh --fast chat 12      # fast for this run
  ./sprint.sh --steady work       # steady for this run
  ./sprint.sh work --fast         # 4 parallel jobs, and fast for this run
  ./sprint.sh polish --fast       # 4 parallel judges, and fast for this run

Precedence (highest first):
  1. --fast / --steady, or env SPRINTBIAS_FAST   this run
  2. config.local FAST                         this machine (fast on|off)
  3. config FAST                               tracked default (off)
  4. off

Where you see it:
  Every AI session's banner ends with  · fast: on  or  · fast: off,
  and ./sprint.sh status shows the mode at the top.

Notes:
  - Scripts read the mode through sprintbias_fast_on in docs/sprintbias/lib.sh.
