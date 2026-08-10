# Using `chat` — the conversational task refiner

`./sprint.sh chat <task-id>` is the one SprintBias command that is a *dialogue*
rather than a one-shot job. It reads a rough task, sizes it up, then works
through it with you one detail at a time — asking a question, polishing your
answer, editing the task file right then, and moving to the next gap. The
result is a user-story brief: clear problem, what "done" looks like, optional
hints (Notes) and paths (References) — how to implement is the developer's
decision; no code and no mandatory build plan.

Because it is a back-and-forth, `chat` needs somewhere to *have* the
conversation. This guide explains the three ways it can run and how to get the
full experience.

## The three ways `chat` runs

Which one you get is decided automatically from your environment (the `MODE`
setting in `docs/sprintbias/config`, your `CLI`, and whether you are at a real
terminal).

### 1. Inside an AI agent session — "emit" mode

If you are already working inside a coding agent (Claude Code, Grok Build,
Cursor, etc.), `chat` prints its instructions into that session and your agent
conducts the conversation directly. You just keep chatting in the tool you are
already in — answer each question, and the agent edits the task file as you go.
This is the default whenever SprintBias detects it is running inside an agent
(`CLAUDECODE`, `GROK_AGENT=1`, Cursor session vars, or an explicit `MODE=emit`).

### 2. A plain terminal with Claude or Grok — "exec" mode (full experience)

If you run `./sprint.sh chat <id>` from an ordinary terminal and a first-class
CLI is installed (`CLI=claude` or `CLI=grok` in config), `chat` launches a
**live, interactive session** on the task:

| Config | Opens |
|--------|--------|
| `CLI=claude` / `PROVIDER=claude-code` | Claude Code REPL |
| `CLI=grok` / `PROVIDER=grok-build` | Grok Build TUI |

It asks its first question and then hands you the prompt — you type your
answer, it edits the file, asks the next question, and so on. This is the full
back-and-forth the command was designed for.

To end it, type **`/quit`** (or **`quit`** / **`/exit`**, or `Ctrl-D` where
the provider accepts it). Your edits are saved to the task file as the
conversation happens, so there is nothing to "commit" at the end — when you
exit, the refined task is already on disk. The session will also tell you this
when the task is defined.

### 3. Anything else — a single refinement pass (degraded)

If `chat` is running in exec mode but there is **no interactive terminal**
(you piped it, or it is in CI or a loop) or your provider has **no interactive
profile** (any CLI other than `claude` or `grok`), a live REPL would just hang
waiting on input. So instead `chat` does one useful pass — it reads the task,
sizes it up, and writes an improved version — then exits. You will see a note
on screen saying this happened and pointing back to this guide.

That single pass is genuinely useful, but it is not the conversation. To get
the real thing, use option 1 or 2 below.

## Getting the full back-and-forth

Pick whichever fits how you work:

- **Run it inside your agent.** Open your task in Claude Code, Grok Build, or
  another coding agent and run `./sprint.sh chat <id>` there. The agent runs the
  conversation itself (emit mode). Nothing to install beyond the agent you
  already use.

- **Install a first-class CLI and use a real terminal.** With `claude` or
  `grok` on your `PATH`, set `CLI` (and ideally `PROVIDER`) via `./setup.sh` or
  `docs/sprintbias/config`, then run `./sprint.sh chat <id>` from an interactive
  shell (not piped, not CI). You get the live session in option 2. For one
  command without editing config: `./sprint.sh -g chat <id>` (Grok) or
  `./sprint.sh -c chat <id>` (Claude).

If you keep landing in the single-pass fallback when you did not expect it,
check:

- **Are you at a real terminal?** Piping the command, or running it from a
  script/CI job, removes the TTY that an interactive session needs.
- **Is `CLI=claude` or `CLI=grok` active?** From config, from `./sprint.sh -c` /
  `-g` for this run, or from `SPRINTBIAS_CLI`. Interactive sessions are wired for
  those profiles today. Other CLIs fall back to the single pass.
- **Is `MODE` forcing something?** In `docs/sprintbias/config`, `MODE=emit` always
  prints the prompt for a surrounding agent; `MODE=exec` always spawns the CLI;
  empty auto-detects. If you set it, make sure it matches how you actually run.

## Folder sweeps (`chat backlog` / `next` / `blocked`) — not a conversation

`./sprint.sh chat <folder>` is a **fast verdict-first sort**, not the
give-and-take of `chat <id>`:

- In a plain terminal (**exec**), each task gets a headless one-shot verdict
  (progress dots while you wait), then a shell menu: `[w] [d] [k] [s] [q]`.
- Only **`[d] Define it`** opens the full interactive chat on that task. That
  nested session owns the terminal until you leave it — when the define is
  done, type **`/quit`** (or **`quit`**) to return to the sweep and the next
  task. A banner before launch and the chat finish line both say so.
- Inside an agent session (**emit**), the surrounding agent walks the queue.

Verdict labels (not lifecycle folders):

| Status | Meaning |
|--------|---------|
| **COMPLETE** | Work may already be in the codebase — triage is advisory; **`[w]` still gates** |
| **READY** | Clear enough to try; open **Depends on** means dependent / on hold (`work` holds) |
| **BLOCKED** | Needs a decision or clarification on *this* task — **not** “has an open dep” |
| **UNDEFINED** | Too thin to act on yet — **not** “has an open dep” |
| **STALE** | Low value / superseded |

From `backlog/` or `blocked/`, **`[w]` commits to the sprint only through the
shared workability gate** (READY → `next/`, BLOCKED → `blocked/` with a reason,
COMPLETE → `review/`). Never a raw promote into `next/`. From `next/`, `[w]`
starts the task (`doing/`).

A dep sitting in the **`blocked/` folder** (needs a decision or clarification)
is called out separately — the dependent is on hold; the prerequisite is blocked.
A dep still in backlog/next is ordinary sequencing, not a blocked condition.

For CLI help on the same surface: `./sprint.sh help chat`.

## What happens when the task is defined

`chat` doesn't just refine and leave you to clean up — it closes the loop and,
when there's more to define, keeps the chain moving without ballooning context.

- **A blocked task re-enters the sprint through the gate.** When you chat through
  a task that `gate` had parked in `blocked/`, each answer becomes instruction
  in the body and the original question is deleted. When the question list is
  clear, `chat` runs the same workability promote as `plan start` / folder
  `[w]`. READY → `next/` and runnable with `./sprint.sh work`; otherwise the
  gate returns BLOCKED. While a question is still open, the task stays in
  `blocked/` and `chat` names what still needs answering.

- **The next dependency is picked up in a fresh context.** Defining one task
  often reveals it depends on another task that still needs a decision. Rather than
  keep chatting in the same session — where the whole conversation stays in
  context and burns tokens — `chat` writes a short **Context from chat** note
  into that next task's file (just the decisions that flow downstream), then
  starts fresh on it: inside an orchestration-capable agent (Claude Code or
  Grok Build) it spins up a *new* subagent for the next task; in a plain
  terminal it prints the `./sprint.sh chat <id>` for you to run in a new window.
  Either way the next session begins with a clean context and reads what it
  needs from the file. When nothing downstream is left undefined, `chat` says
  the chain is complete and stops.

## Choosing the model

`chat` uses `MODEL_CHAT` (then `MODEL_DEFAULT`) from config. On the
`claude-code` and `grok-build` tiers, an empty model falls back to a strong
default (`opus` / `grok-4.5`) via `sprintbias_tier_model`. Pin a model in config
when you want a specific one.
