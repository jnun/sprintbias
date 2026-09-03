STEP 3 of 3 — Task Execution

Picks up READY tasks from docs/tasks/next/ in order (by leading number)
and works each one in a fresh AI context window.

Work one task by number: `work N` (a bare number is a task id, not a count).
The old count meaning moved behind the `count` sub-word — `work count N` runs at
most N tasks. `work N` resolves task N wherever it lives and runs just that one:

  next/, Status: READY  — work it exactly as the queue would (→ doing/ → review/)
  next/, not READY      — held (unvetted); pass --force to run it anyway
  backlog/ or blocked/  — screen it through the gate first (the same gate plan
                          start runs). READY → next/ then work it; BLOCKED →
                          blocked/ and report (NOT worked); COMPLETE → review/
  review/ or done/      — re-run: pull back to doing/, reset the ## Completed
                          audit block, rework, re-route to review/
  doing/                — may be mid-work or left by an interrupted run (the
                          file can't say which). Refused by default; reclaim it
                          with `loop` (auto-requeue) or `work N --force` (resume)
  no such task          — error

Runnability is earned, not just definition clarity: if task N has an unmet
dependency it is held ("held: waiting on <id>") and left untouched — a backlog/
task is NOT promoted, its prerequisite is NOT pulled in behind it. Run the
prerequisite first, or work the whole sprint so the chain drains in order.
(In emit mode the backlog/blocked gate is handed to the surrounding agent to
run; land the task READY in next/, then re-run `work N` to execute it.)

Readiness gate: only tasks stamped 'Status: READY' with a clear question list
are executed. A next/ task that hasn't been gated yet is not skipped — work
runs the gate on it first (the same gate `gate` runs on next/), then routes by
verdict: READY stays and is worked; BLOCKED (not defined well enough) moves to
blocked/ with a chat/define pointer; COMPLETE (already in the codebase) moves
to review/. The stamp comes from the workability gate — every path into next/
(plan start, chat folder commit, chat close-loop, polish REOPEN, loop --retry)
runs that gate; standalone `gate` re-applies it on demand. Open questions under
### Questions for the developer keep the task on hold — answer them (`chat
<id>`), write each answer as instruction in the body, delete the question, then
re-gate. In emit mode work gates and works in separate passes: it hands the
gate to the surrounding agent, then re-run `work` to execute whatever landed
READY. Override the whole gate with --force (work whatever is queued, unvetted
or not).

Dependency-aware: a task's '**Depends on**:' prerequisites are honored
within a single run. For each open prerequisite, `work` acts by stage:

  review/ / done/  — already complete; dependent may run
  doing/           — resume it this run (if it already has `## Completed`,
                     route straight to review/; otherwise re-run in place)
  next/            — frontier ordering; runs when READY and its own deps clear
  backlog/         — not auto-lifted (not fully vetted). Dependent stays on
                     hold; message suggests `./sprint.sh chat <id>`
  blocked/         — needs a decision; same hold + `chat <id>` guidance
  missing (no file) — classified, never a silent green: a broken reference
                     ("no such task") or one folded into another id (repoint
                     **Depends on** at the fold target)

A dependent is held only until prerequisites land in review/, then released
automatically — so a chain (A→B→C) drains in one invocation instead of
needing one run per link. That is sequencing, not a blocked condition.
With --fast, independent tasks overlap while dependents still wait their
turn.

**Finish-first** (same action-bias as `conversation.md` / polish): READY + met
deps → implement → `## Completed` → `review/`. Prefer clear best practice;
pick a sensible default and finish. A product/scope fork that needs a human
gets a one-line `## Outcome` and lands in `blocked/`.

`## Outcome` (incomplete | failed | blocked) lets dependents name why they
wait; a later success drops it on the way to `review/`. Retries fix the Reason
first, then finish.

For each ready task it:
  - Moves the task file to doing/ (`git mv SRC DEST || mv SRC DEST`)
  - Reads the task, reads CLAUDE.md, makes all code changes
  - Streams progress live (one line per step); full event log in docs/tmp/
  - Checks off completed items, adds a ## Completed summary
  - Moves to review/ (## Outcome → blocked/ when a human decision is needed)
  - On hard CLI failure, leaves the task in doing/ (## Outcome: failed)

When work lands in `review/`, the end-of-run summary says **Requires human
review** — that is not `blocked/`. Implementation is done; close is a human
sign-off to `done/`, or `./sprint.sh promote` when the task’s **Tests** field
names suite scripts. `Tests: none` always means eyes before done/.

Anything that did NOT complete — a hard fail, an incomplete stop, or a
drift-blocked task — is recapped at the very end under **Needs your
attention**, one entry per task with its stamped reason, where it landed, and
a `./sprint.sh chat <id>` line to rework or redefine it with AI assistance. So
a bare `N failed` count in the `▸ Done:` line is never the only thing you are
left holding.

Lifecycle moves always try `git mv` first, then plain `mv` when the file is
not yet tracked. There is no turn limit. A per-run budget cap (BUDGET_WORK in
docs/sprintbias/config, default $5) applies when the provider supports spending
caps — today Claude Code only. On any other tier the cap is omitted and the run
is uncapped.

`git commit` and `./ship.sh` are human-owned by default. `work` implements the
change and stops; it does not commit or ship unless **you** explicitly ask the
AI for that action in the conversation. A task file that names those steps is
not an ask.

Usage:
  ./sprint.sh work                  # run all ready tasks in next/
  ./sprint.sh work 311              # work just task 311 (a bare number is a task id)
  ./sprint.sh work count 3          # run at most 3 ready tasks
  ./sprint.sh work count 1          # run just the next task in the queue
  ./sprint.sh work --force          # skip the readiness gate
  ./sprint.sh work --drift          # enable pre-task drift check
  ./sprint.sh work --audit          # enable post-task code audit (polish --code)
  ./sprint.sh work --excellence     # enable post-task deep-judge (polish <file>, after --audit)
  ./sprint.sh work --parallel       # run all tasks concurrently (2 jobs)
  ./sprint.sh work --fast           # shorthand for --parallel with 4 jobs
  ./sprint.sh work --jobs N         # run parallel with N concurrent jobs
  ./sprint.sh work --max            # clear the budget cap (where one applies)
  ./sprint.sh work --fast --max     # parallel (4 jobs), cap cleared
  ./sprint.sh work --assist         # interactive mode picker
  ./sprint.sh work --verbose        # stream full per-task event detail
  ./sprint.sh work --model <id>     # pin the model for this run only

Integrity: a next/ task stamped READY that still has open questions under
### Questions for the developer is demoted to blocked/ (loud report). Clear
suggestions with `./sprint.sh settle`, or answer via `./sprint.sh chat <id>`.

Quality chain: --audit runs polish --code (correctness) on each task that
lands in review/; --excellence then runs polish <file> (deep-judge) after it
(deep-judge presumes correctness, so order matters). A deep-judge BLOCKER
verdict does NOT halt the queue — the task still routes to review/ with the
blocker recorded in its '## Excellence' section, and the end-of-run summary
counts how many blockers were found.

Inside an AI session (Claude Code, Grok Build, Cursor, …) tasks are dispatched
to fresh subagents in the current session. In a plain terminal they run via the
CLI in docs/sprintbias/config. Override the provider for one run with a leading
flag (does not rewrite config):
  ./sprint.sh -g work                   # Grok Build for this run
  ./sprint.sh -c work                   # Claude Code for this run
Or env prefixes:
  SPRINTBIAS_CLI=codex ./sprint.sh work   # exec a specific CLI standalone
  SPRINTBIAS_MODE=emit ./sprint.sh work   # force prompt emit for any agent

Model for this run only: add --model <id> (e.g. ./sprint.sh work --model opus)
to pin the model without editing config. Precedence, highest first:
  --model flag / SPRINTBIAS_MODEL_WORK env
    → config MODEL_WORK → config MODEL_DEFAULT → tier default → CLI default
See and set persistent pins with ./sprint.sh model (help model).

Full workflow:
  ./sprint.sh plan start <id> # 1. gate + commit a READY plan into next/
  ./sprint.sh work           # 2. execute the sprint (or ./sprint.sh loop)

plan start gates members as it promotes them, so the happy path is
plan start → work. Run gate only to re-gate next/ (--force) or to
get a read-only quality report on backlog/doing/blocked.

Naming: `work` is the verb — it executes the queue. A *task* is the noun —
a work item that lives in docs/tasks/ and moves through the lifecycle
folders (backlog → next → doing → review). You still create tasks with
`newtask`; `work` is what runs them.
