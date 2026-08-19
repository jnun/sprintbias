Watch the SprintBias flow run. Reading the manual tells you the lifecycle; a
demo lets you *see* a real session move through it — the gate, the folders, the
spine — with zero setup and zero risk to your project.

A demo is pure terminal theater: python3 + stdlib only, no packages to install.
It writes nothing, moves no task files, and makes no network calls. It runs
the same in a brand-new empty install as it does here.

Usage:
  ./sprint.sh learn                 # list the demos (name + one-line summary)
  ./sprint.sh learn <name>          # play that demo
  ./sprint.sh learn example         # twenty seconds: newtask → chat → work → git status
  ./sprint.sh learn session         # the teaching run: one problem, one session

Flags after the name pass straight through to the demo, for example:
  learn example --fast       # skip the pauses
  learn example --no-color   # plain text, no ANSI colors

Demos:
  example   Twenty seconds. Capture a bug, sharpen it, work it to review/,
            then git status shows the change — code diff plus a task file that moved.
  session   A new user hits a real bug and closes it in one sitting — capture,
            sharpen at the gate, work it to review. The spine: newtask → chat → work.

Two ways in, one player:
  ./sprint.sh learn [name]     # the catalog — list, or play any demo by name
  ./sprint.sh <cmd> --demo     # on-ramp from a command you just typed

When a command has a demo mapped, its --help ends with a one-line pointer
(`Demo:  ./sprint.sh <cmd> --demo`) and `<cmd> --demo` plays that demo through
this same engine. --help explains the command; --demo shows it. Commands with
no demo mapped say so and point you back here. The mapping is data-driven — an
optional 5th field on docs/sprintbias/help/_registry (command → demo name); demos
with no natural host command (e.g. example, session) live only in this catalog.

Notes:
  - Output degrades gracefully when stdout is not a TTY (color is dropped).
  - Ctrl-C stops a demo cleanly.
  - If python3 is missing, learn explains what's needed instead of crashing.
  - Demos live under docs/sprintbias/learning/*.py. Drop a new one in and it
    appears in this list automatically — no launcher change needed.
