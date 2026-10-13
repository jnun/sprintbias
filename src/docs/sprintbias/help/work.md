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

Work one plan: `work plan N` runs only plan N's member tasks and leaves the
rest of next/ in place (for a closer look, or to do by hand). Members still in
backlog/ come in first through `plan start N` (the same gate), so no separate
start is needed.

Grounding first: before the queue runs, work checks the project map
(profile check — no AI; one line when it has drifted). Each worker then makes
sure its task file has ## Grounding — the sources it relies on, the glossary /
lexicon / taxonomy terms it uses (copied word for word), and its conflicts, each
settled before work. The gate normally writes it; the worker fills gaps. Every
noted conflict is repeated in the end-of-run checklist for that task, so you
can check each call made on your behalf.

Docs stay in step: a worker whose change alters what a source of truth
describes updates it in the same task. Governing sources (security policy,
decision records, CLAUDE.md / AGENTS.md) and out-of-scope gaps go under
## Completed → ### Doc follow-ups. work files every follow-up from review/ and
done/ into one backlog task (Bring project docs in step with landed work) at the
start and end of each run — each line tagged "(from #id)" and filed once.

Parallel agents: `work 1443` and `work 1452` can run side by side, one per
terminal in the same checkout. Each worker announces its files as **Touching:**
in ## Grounding and keeps clear of the others (DOCUMENTATION.md rule 8). A task
in doing/ is claimed: `work N` refuses it without --force. For named sessions
you steer, or agents on a shared server, see `help crew`.

Fast mode (`./sprint.sh fast on`, or `--fast` for one run): agents skip the AI
CLI's permission prompts and the queue runs in parallel, 4 jobs at a time, with
no flag. `--jobs N` sets the count; `--steady` runs one task at a time. Commit,
push, ship.sh and sign-off to done/ stay yours by rule. Fast is safest on a dev
server or a clean git tree. See `help fast`.

Readiness gate: only tasks stamped 'Status: READY' with a clear question list
are executed. A next/ task that hasn't been gated yet is not skipped — work
runs the gate on it first (the same gate `gate` runs on next/), then routes by
verdict: READY stays and is worked; BLOCKED (cannot start) moves to
blocked/ with a `chat <id>` pointer; COMPLETE (already in the codebase) moves
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

  done/            — signed off; dependent may run
  review/ + proof  — landed (a `**Proof**:` line under `## Completed`);
                     dependent may run
  review/, no proof — in review, unproven: dependent holds; the hold line
                     says to promote it or add a proof line
  doing/           — resume it this run (if it already has `## Completed`,
                     route straight to review/; otherwise re-run in place)
  next/            — frontier ordering; runs when READY and its own deps clear
  backlog/         — not auto-lifted (not fully vetted). Dependent stays on
                     hold; message suggests `./sprint.sh chat <id>`
  blocked/         — cannot start yet; same hold + `chat <id>` guidance
  missing (no file) — classified, never a silent green: a broken reference
                     ("no such task") or one folded into another id (repoint
                     **Depends on** at the fold target)

A dependent is held only until prerequisites land (review/ with a proof line,
`**Proof**: YYYY-MM-DD · <test commands> · pass`) or reach done/, then released
automatically — so a chain (A→B→C) drains in one invocation instead of
needing one run per link. That is sequencing, not a blocked condition.
In fast mode, independent tasks overlap while dependents still wait their
turn.

**Finish-first** (same action-bias as `conversation.md` / polish): READY + met
deps → implement → `## Completed` → `review/`. Prefer clear best practice;
decide each open call, record it as `- Decided: X, because Y`, and finish.
Only a task that cannot start (no reasonable reading, or access or credentials
only you hold) gets a one-line `## Outcome` and lands in `blocked/`.

**Test loop** (every worker, solo or crew), in order: build what was defined,
test what was built, adjust what fails, resolve known conflicts, fix all bugs,
submit for review. Build the smallest testable outcome first; run targeted tests (those Done when names, plus the tests for code the
**Touching:** files feed; the full suite runs once, at plan close); log each failure under
`## Test log` and re-run until green; land with the `**Proof**:` line. A task
that lands without one is reported as in review, unproven.

**Edge cases** (gate, worker, crew, breaker — one shared list): the task's
example stands for a class. Workers assert each Done when case and each
realistic case of: the class the example stands for; round trips (every form
the project's docs, UI or examples tell people to write, and what the real
tools people use emit); again and after (run twice, older state, hand edits);
empty, one, many, malformed; neighbors (other code on the same data). A known
bug is fixed now, in the changed code or any code it reaches, as deep as a solid
result needs (a defect a fix uncovers included) — never parked as a Decided or
Assumption line. Each fixed defect is listed under `### Edges found`. A design choice inside the class
(a rounding rule, a format, a limit) is decided and built; a scope-out names
its task (`- Decided: X is out of scope, because Y; filed as #N`), and the
end-of-run checklist lists any without one as an Unfiled gap with its
`newtask` command. Cases a person rejected (`promote --reject`) and every
task's `### Edges found` (added at sign-off) collect in the project map's
`## Known edges`, and agents test the ones their change touches.

**Breaker** (on by default): after a task lands, a fresh agent writes tests
designed to fail against the change — real use first (commands and inputs as
people type or paste them, every form the docs promise), extremes after — fixes what it can (re-running targeted
tests and keeping the proof line), neighboring code included, and removes the
proof line for what it cannot fix (filed with `newtask`) — the task then lands in review, unproven,
with the failure under `## Test log`. It adds `**Breaker**: N cases tried · N
fixed · N filed · $cost` under `## Completed`. Bounded: targeted tests only,
BREAK_MAX_TURNS (25) turns, BREAK_TIMEOUT (900 s) at sign-off, and BUDGET_BREAK
when you set one; MODEL_BREAK picks its model. The status scorecard scores it. Turn it off
with `BREAK=off` in docs/sprintbias/config, or `--no-break` for one run.
A `- Decided:` call that caused a defect is re-decided and fixed (the line is
replaced, saying what changed); a test left failing names its filed task
("fails until #N"). Sign-off runs it too: `promote` checks each task that has no Breaker line yet,
so the human path is just `promote <id>` or `promote plan N`. Plan targets read
the same everywhere: `plan N`, `plan:N`, or a bare N when no task N exists.

`## Outcome` (incomplete | failed | blocked) lets dependents name why they
wait; a later success drops it on the way to `review/`. Retries fix the Reason
first, then finish.

For each ready task it:
  - Moves the task file to doing/ (`git mv SRC DEST || mv SRC DEST`)
  - Reads the task, reads CLAUDE.md, makes all code changes
  - Streams progress live (one line per step); full event log in docs/tmp/
  - Checks off completed items, adds a ## Completed summary
  - Moves to review/ (## Outcome → blocked/ only when the task cannot start)
  - On hard CLI failure, leaves the task in doing/ (## Outcome: failed)

When work lands in `review/`, the end-of-run summary says **Requires human
review** — that is not `blocked/`. Landed work has already released its
dependents; what remains is your sign-off to `done/`: `./sprint.sh promote`
when the task’s **Tests** field names suite scripts, `promote plan:N` for a
whole plan. `Tests: none` always means eyes before done/.

Anything that did NOT complete — a hard fail, an incomplete stop, or a
drift-blocked task — is recapped at the very end under **Needs your
attention**, one entry per task with its stamped reason, where it landed, and
a `./sprint.sh chat <id>` line to rework or redefine it with AI assistance. So
a bare `N failed` count in the `▸ Done:` line is never the only thing you are
left holding.

Lifecycle moves always try `git mv` first, then plain `mv` when the file is
not yet tracked. There is no turn limit and, by default, no budget cap: agents
spend what finishing the work takes. To set a ceiling, put BUDGET_WORK=5.00 (or
your number) in docs/sprintbias/config.local; it applies where the provider
supports spending caps, today Claude Code only.

`git commit` and `./ship.sh` are human-owned by default. `work` implements the
change and stops; it does not commit or ship unless **you** explicitly ask the
AI for that action in the conversation. A task file that names those steps is
not an ask.

Usage:
  ./sprint.sh work                  # run all ready tasks in next/
  ./sprint.sh work 311              # work just task 311 (a bare number is a task id)
  ./sprint.sh work count 3          # run at most 3 ready tasks
  ./sprint.sh work count 1          # run just the next task in the queue
  ./sprint.sh work plan 32          # work only plan 32's tasks in next/
  ./sprint.sh work --force          # skip the readiness gate
  ./sprint.sh work --drift          # enable pre-task drift check
  ./sprint.sh work --no-break       # skip the breaker for this run
  ./sprint.sh work --audit          # enable post-task code audit (polish --code)
  ./sprint.sh work --excellence     # enable post-task deep-judge (polish <file>, after --audit)
  ./sprint.sh work --parallel       # run all tasks concurrently (2 jobs)
  ./sprint.sh work --fast           # fast mode for this run: no prompts, 4 jobs
  ./sprint.sh work --steady         # steady for this run: one task at a time
  ./sprint.sh work --jobs N         # run parallel with N concurrent jobs
  ./sprint.sh work --max            # clear the budget cap (where one applies)
  ./sprint.sh work --fast --max     # parallel (4 jobs), cap cleared
  ./sprint.sh work --assist         # interactive mode picker
  ./sprint.sh work --verbose        # stream full per-task event detail
  ./sprint.sh work --model <id>     # pin the model for this run only

Integrity: a next/ task stamped READY that still has open questions under
### Questions for the developer is demoted to blocked/ (loud report). Every
`(Suggestion: …)` is taken first; answer what is left with `./sprint.sh chat <id>`,
then `./sprint.sh work <id>`.

Quality chain: the breaker runs first (default); --audit runs polish --code (correctness) on each task that
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
