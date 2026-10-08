<!-- SprintBias v0.0.134 -->
# Getting Started with SprintBias

SprintBias keeps your project's work as markdown files in your repo. The folder
a task sits in is its status, and an AI agent helps you define and build it.

## What you need

- `bash` and `git`
- [Claude Code](https://claude.com/claude-code) or Grok Build, installed and
  logged in, for the AI commands
- Optional: `python3` (for `agents`, demos, and tidier live output) and `gh`
  (for `sync --all` to GitHub Issues)

## Install

```bash
./setup.sh ~/code/my-app      # from a clone of SprintBias
# or, from inside your project:
curl -fsSL https://raw.githubusercontent.com/jnun/sprintbias/main/install.sh | bash
```

Press **Enter** for Claude Code or **g** for Grok Build. Setup adds
`sprint.sh`, the manual, and the task folders, and leaves your own files in
place. Run it again any time to update.

## First run

```bash
./sprint.sh learn example     # 20-second demo; changes nothing
./sprint.sh profile           # once: the AI maps your stack and docs
```

## The loop

```bash
./sprint.sh newtask "Reject empty password on login"   # → backlog/
./sprint.sh chat 12      # sharpen it with the AI until it's clear
./sprint.sh work 12      # gate it into next/, then the AI builds it → review/
git diff                 # check the change
./sprint.sh promote      # its Tests pass → done/
```

A task with no **Tests** waits in `review/` for you to approve it:
`git mv docs/tasks/review/12-*.md docs/tasks/done/`.

## The board

```text
docs/tasks/backlog/   planned
docs/tasks/next/      the sprint: ready to build
docs/tasks/doing/     in progress
docs/tasks/blocked/   waiting on a decision
docs/tasks/review/    built, waiting for your check
docs/tasks/done/      finished
```

Tasks enter `next/` through the gate: `work 12`, `plan start`, or `chat backlog`.
For other moves, use `git mv SRC DEST || mv SRC DEST`. Plain `work` builds
everything ready in `next/`. `./sprint.sh status` shows the board.

## Going further

```bash
./sprint.sh newplan "Auth" 12 13 14   # group tasks into a plan
./sprint.sh plan start 7              # commit the whole plan to next/
./sprint.sh loop --refill --retry     # keep starting and working plans

./sprint.sh crew add lead "Holds the plan" --lead   # several named AI sessions
./sprint.sh crew lead plan:7                        # one terminal per member
./sprint.sh agents                                  # see every session running

./sprint.sh -g work                   # this run on Grok (-c for Claude Code)
./sprint.sh config                    # set the default AI and model
```

Ideas, features, bugs, and tests have their own commands: `newidea`,
`newfeature`, `newbug`, `newtest`.

`./sprint.sh help` lists every command; `help <command>` explains one.
`DOCUMENTATION.md` is the full manual.
