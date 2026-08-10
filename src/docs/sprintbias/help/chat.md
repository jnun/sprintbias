Discuss a task with an AI to turn it into a well-defined, workable task.
`chat` is now the single conversational command — it absorbs what the old
`plan` and `find` stress-test flows used to do. It sizes the task up first,
then routes to the right depth:

  - Blank stub → fills the durable brief (## Problem + ## Success criteria)
    from scratch, one question at a time; optional ## Notes / ## References
    as helpful hints and paths (how to implement stays the developer's call)
  - Several jobs bundled together → proposes a breakdown, and on your OK
    creates the sub-tasks with `./sprint.sh newtask` (real IDs, standard
    template, **Parent** linked back so `newplan "…" parent:N` gathers
    them), then chats through each to add real detail. Edges are kept
    reciprocal — the parent is folded into its first child so nothing points
    at a deleted id — and the original is retired once its children exist.
  - Genuinely one rough job → refines it in place, one detail at a time:
    ask a question, polish your answer with you, edit the file right then,
    move to the next gap.
  - Already looks defined → stress-tests it across goal fit, scope,
    criteria, assumptions, risk, dependencies, and alternatives, recording
    what it finds in a ## Think Notes block.

It can move between these modes mid-session as facts emerge. Either way the
result is a user-story brief: clear problem, what done looks like, optional
hints and file paths — how to implement stays the developer's call; no code.

Use this whenever a task you wrote feels off — blank, half-baked, too big,
or deceptively finished — and you want to think it through out loud. To
split a task without the conversation, use `split`.

With NO task id, on a real terminal `chat` opens a short entry menu — the five
front doors the command matrix names: **new task**, **new plan**, **sweep a
folder** (backlog / next / blocked), **author a plan**, and **bug inbox** — and
routes to whichever you pick. Prefer skipping the menu? Every choice has a direct
word: `chat newtask [name]`, `chat newplan [name]`, `chat <folder>`, `chat plan`,
`chat bugs`. Two more front doors stay direct words rather than menu rows —
`chat <id>` (define one task you already know by number) and `chat sprint` (the
whole-sprint walk). Off a terminal (agent or CI, where nothing can answer a
prompt) bare `chat` goes straight to the sprint walk, so scripted callers keep
their old behaviour.

`chat sprint` (and bare `chat` off a terminal) widens the lens from one task to
the whole sprint — a fast structural-health stand-up over `next/` and `blocked/`.
A shell
preflight (no AI, so cost scales with problems found, not sprint size)
checks dependency integrity, stage correctness, and stale markers, then the
conversation walks what it found one finding at a time, most-blocking first:

  - broken dependency edges (a Depends on / Dependents id with no task on disk;
    a one-way edge where A depends on B but B's Dependents omits A)
  - dependency-stage violations (a `next/` task depending on something still
    in `backlog/` — ordering gap — or in `blocked/` — dependent on hold while
    the prerequisite is undefined)
  - blocked-limbo (a `blocked/` task with no `**Status: BLOCKED**` and no
    `## Questions` — almost always mis-filed; the default fix is to move it
    back to `backlog/` to reconsider)
  - stale-ready (a `next/` task with no `**Status: READY**` stamp)
  - outstanding questions (an open item that leaves a task short of READY) —
    each surfaced verbatim; once you answer, the answer becomes body
    instruction and the question is deleted
  - orphaned parents and dependency cycles

It opens with a ≤3-line summary (queued count, runnable frontier, findings
count) and offers to act on each finding — fix an edge, move a mis-parked
file, stamp a marker — or chain into `chat <id>` for anything that needs
real definition work. This is a health pass ("are dependencies sound and is
every task in the right condition?"), distinct from `plan think`, which is a
dual-persona planning critique of a *plan* ("is this the right grouping?"). A
clean board or an empty `next/` reports and exits without spending a token.

With a STAGE FOLDER name (`blocked`, `next`, or `backlog`), `chat` sweeps that
whole folder one task at a time — an express, verdict-first sort that absorbed
the old `triage` command. For each task it gives a fast verdict (status, a
one-line summary, a recommendation) on a cheap model, then lets you decide.
Verdict **BLOCKED** means a decision or clarification is needed on *this* task —
not “has an open Depends on.” **UNDEFINED** means too thin to act on yet.
Ordinary deps are pipeline ordering: the task is **dependent** (on hold); `work`
holds it until prerequisites finish. A dep that sits in the `blocked/` *folder*
is different (that prerequisite needs a decision) and is called out separately —
the dependent stays on hold; the prerequisite is the blocked one.

  - [w] work it   — from `next/`: start it (`doing/`). From `blocked/` or
                    `backlog/`: **commit to sprint via the shared workability
                    gate** (READY → `next/`, BLOCKED → `blocked/` with a reason,
                    COMPLETE → `review/`). Never a raw promote into `next/`.
  - [d] define it — go deep: hand the task to the full `chat <id>` conversation
                    (the strongest model), the only step that escalates past the
                    fast verdict — this two-tier split keeps the rip-through tempo.
                    When define is done, type `/quit` (or `quit`) to leave the
                    nested session and return to the next task in the sweep
  - [k] kill it   — delete after confirming
  - [s] skip / [q] quit

Dependency resolution is intrinsic to `chat` and runs on every task the sweep
opens, exactly as it does for `chat <id>` and the no-arg walk: when a swept
task's **Depends on** points into `blocked/`, the sweep lifts and defines that
dependency (via the same fresh-context chain) so the dependent task can actually
be worked. The folder argument only chooses WHICH files are opened.

With `plan` (or `plan <id>`), `chat` authors a plan file in `docs/plans/` —
conversational grouping, not task refinement. Bare `chat plan` picks a plan
(like bare `chat backlog`); `chat plan <id>` uses a *plan* id (never a task
id). Create the scaffold first with `newplan`. The walk injects the shared
Conversation Method and writes only the plan file: Goal, ordered member task
IDs (from `backlog/`, read-only — no task moves or edits), parallelism notes
(recorded, not acted on), and `**Status:** DRAFT → READY` when you confirm.
`chat backlog` mutates task files; `chat plan` only records IDs into the plan.
After authoring: optional `./sprint.sh plan think <id>` (dual-persona critique),
then `./sprint.sh plan start <id>` to commit members into the sprint — not here.

With `bugs`, `chat` sweeps the bug inbox (`docs/bugs/`) — the same verdict-first
tempo, but bug-shaped. A bug report is not a task: it lives flat, has no
dependency or status metadata. Handled reports leave the workspace (delete) —
the inbox holds open reports only. For each report the sweep gives a fast
verdict (REPRODUCIBLE / FIXED / UNDEFINED / DUPLICATE / STALE on a cheap model),
then lets you decide:

  - [w] work it   — **convert**: create a fix task filled from the report
                    (Problem, Steps→Problem, Success criteria, origin in Notes),
                    then **delete** the bug file. The task owns the work from
                    here; refine later with `chat <task-id>` if needed.
  - [d] define it — go deep on the *report itself* (the strongest model):
                    sharpen `## Problem`, `## Steps to reproduce`, the severity,
                    and `## Success criteria` until anyone could reproduce and
                    verify the fix. The only step that escalates past the verdict.
                    When done, `/quit` (or `quit`) returns you to the bug sweep
  - [a] close     — already fixed or obsolete, no task → **delete** the report
  - [k] kill it   — not a real bug: delete after confirming
  - [s] skip / [q] quit

Unlike the task-folder sweep, this runs no dependency resolution — bugs have no
dependencies. File a bug first with `./sprint.sh newbug "…"`. Prefer filing a
clear fix as `newtask` when you already know it is real work; use the bug inbox
when reports still need triage.

Usage:
  ./sprint.sh chat              # entry menu on a terminal (else the sprint walk)
  ./sprint.sh chat newtask [name]  # create a task and define it right away
  ./sprint.sh chat newplan [name]  # create a plan and author it right away
  ./sprint.sh chat <task-id>    # chat one task through
  ./sprint.sh chat <folder>     # sweep one folder: blocked, next, or backlog
  ./sprint.sh chat plan [id]    # author a plan (plan id; bare = pick one)
  ./sprint.sh chat bugs         # sweep the bug inbox → fix tasks
  ./sprint.sh chat sprint       # walk the whole sprint's structural health
  ./sprint.sh chat <id> --model <id>   # pin the model for this run only

Provider for this run only (leading flags; does not rewrite config):
  ./sprint.sh -g chat <id>      # Grok Build
  ./sprint.sh -c chat <id>      # Claude Code
Default comes from docs/sprintbias/config (CLI / PROVIDER) or setup.sh.

Model for this run only: add --model <id> anywhere in the args, e.g.
  ./sprint.sh chat 42 --model opus
Precedence, highest first:
  --model flag / SPRINTBIAS_MODEL_CHAT env
    → config MODEL_CHAT → config MODEL_DEFAULT → tier default → CLI default
See and set persistent pins with ./sprint.sh model (help model).

What it does:
  - Sizes the task up first, then splits or refines accordingly
  - Asks one focused question at a time, targeting the biggest gap
  - Lays out open technical decisions with a recommended default and its
    rationale, flagging security and performance trade-offs
  - Polishes each answer, then edits immediately: convert the answer into
    instruction in Problem / Success criteria / Notes, delete the question
  - Fills ## Problem and ## Success criteria as a user-story brief (problem
    + what done looks like); optional ## Notes (hints + guidance from answered
    questions) and ## References (paths)
  - Closes the loop on a blocked task: when every question is answered and
    turned into body instruction, it re-enters the sprint through the shared
    workability gate (same review as `plan start` / folder `[w]`) — READY →
    next/, or BLOCKED while a question is still open
  - Chains to the next dependency that still needs work in a *fresh* context
    so a long session doesn't pile up tokens: it seeds the next task's
    file with a short "Context from chat" note (the decisions that flow
    downstream), then — inside an agent — spins up a new agent for it, or
    in a plain terminal prints the `./sprint.sh chat <id>` to run next.

Searches: blocked/, backlog/, next/, doing/
