# Changelog

All notable changes to SprintBias are recorded here, newest first. Versions
follow `src/VERSION` (`X.Y.Z`). This file is repo-only — it is not distributed
into user installs.

Add entries under `## Unreleased` as you finish user-facing work; `./ship.sh`
renames that section to the new version and date on each bump.

## Unreleased

## 0.0.141 — 2026-10-12

### Changed
- `crew setup` starts from how your project is already built: it reads your own agent definitions (`.claude/agents/`, roles in AGENTS.md) and standards docs (API, security, permissions, design system, screen specs), makes each builder agent a lane and each reviewer agent a pass, and adds a UI and UX pass when you have a design system or screen specs.
- `crew setup` builds the crew without asking you: it settles each call from what the project shows, records it as a `- Decided:` line, fills the member files, and closes with the crew table, its calls and the start commands.
- No budget cap by default: agents spend what finishing the work takes. To keep each task under a ceiling, set `BUDGET_WORK=5.00` (and `BUDGET_AUDIT`, `BUDGET_BREAK`) in `docs/sprintbias/config.local`; `work --max` clears it for one run.

## 0.0.140 — 2026-10-12

### Changed
- `chat` and `chat plan` report each change they already made as a past-tense `Fixed: …` line, apart from any question, so you can see it is done and needs no answer.
- `crew <name>` starts working as soon as it opens: the lead runs `plan start` on a ready plan and routes wave 1, and a member takes its task, instead of describing its first step and waiting for you.
- The crew lead routes a task to the member whose `May touch` covers what it changes, and sends a step only one member may run (a migration, a deploy) to that member.

## 0.0.139 — 2026-10-12

### Changed
- Bare `./sprint.sh plan check` lists your plans and asks which to check; press Enter to check them all. Without a terminal it checks them all.

## 0.0.138 — 2026-10-11

### Added
- `./sprint.sh status --edges [plan:N]` scores edge-case catching with no AI: defects the agents caught (Breaker lines) vs defects you found (`promote --reject` and human-test failures), split by work the breaker checked vs work it did not, with catch rate, breaker cost and the escapes to learn from.
- `promote --reject <id> "what is wrong"` also takes a `done/` task found broken after sign-off: it files the linked fix task and the Known edges line, and the original stays signed off.
- Parallel breakers (sign-off and `polish --break plan:N`) never share a code file: tasks whose `### Files changed` lists overlap run one after another in a lane, lanes run side by side, and a free slot starts the next lane at once. `polish --break plan:N` now checks the members that have no Breaker line yet, in parallel; re-run a checked task by its id.
- The breaker records its cost on its Breaker line (`· $1.23`), and `BREAK_MAX_TURNS` (25) and `BREAK_TIMEOUT` (900 seconds) can be set in `docs/sprintbias/config` or `config.local`.
- `./sprint.sh polish --break <id|plan:N>` runs the breaker alone on landed work (review/ or done/; for a plan, each landed member but the human test), with no rework or gate, and prints each task's Breaker line plus the next command.
- Rejected cases become project memory: `promote --reject <id> "…"` also adds one line to `## Known edges` in your project map (`docs/sprintbias/project.md`, when you have one), and every agent is told to test the ones its change touches. `profile check` skips that section's paths and asks for a prune past ~15 lines.
- `./sprint.sh history record` writes the finished tasks no plan record covers — planless work and tasks from plans retired before records existed — into one dated file in `docs/history/`, so `history` and `history --since` cover all your finished work. Run it by hand before a release; a second run with nothing new says "History is up to date with done/."
- `./sprint.sh history` lists your finished plans from `docs/history/`, newest first, and `./sprint.sh history --since <date or tag>` prints Markdown release notes for everything finished since then: each plan's goal and one line per change, ready to paste.
- `./sprint.sh help <plain words>` finds the command for what you want to do — `help new idea` or `help idea` opens the newidea page, several matches print a short list, no match says so and exits 1. At a terminal, bare `./sprint.sh help` ends with "What command would you like to understand better?" and, when your words match no single command, offers a read-only AI answer.

### Changed
- Sign-off runs the breaker: `promote <id>`, `promote --accept` and `promote plan N` first check each landed task that has not been through it (2 at a time, 4 in fast mode; `--steady`, `--jobs N`), skip the plan's human test, and keep a task in `review/` when the breaker had to remove its proof. A breaker crash or timeout never blocks sign-off. `--no-break` or `BREAK=off` skips it; `--dry-run` lists what would be checked, now for `promote plan N` too: it previews the whole sign-off (your human-test results, the breaker list, the batch, whether the suite would run) and moves nothing.
- Plan targets read the same in `work`, `promote`, `polish` and `crew`: `plan 31`, `plan:31`, or a bare `31` when no task 31 exists (`▸ No task 31 — using plan 31.`; when both exist the task wins, with a one-line hint).
- `work` tests the class a task's example stands for, not only the example: the gate names a check per listed case, and workers assert each case plus realistic edge cases (forms your docs and tools produce, re-runs and old state, empty / many / malformed input, neighboring code). A failing case is fixed, or filed with `newtask` when it lives elsewhere, instead of being parked as a Decided or Assumption line. A design choice inside that class (a rounding rule, a format, a limit) is decided and built; a scope-out names the task it filed (`- Decided: X is out of scope, because Y; filed as #N`), and `work`'s end-of-run checklist lists any scope-out without one as an "Unfiled gap" with the `newtask` command to file it.
- After each task lands, a fresh "breaker" agent now tries to break it by default: it writes tests designed to fail, fixes what it can, and leaves the task unproven with the failure in `## Test log` when it cannot. Turn it off with `BREAK=off` in `docs/sprintbias/config`, or for one run with `work --no-break`; `MODEL_BREAK` and `BUDGET_BREAK` tune it. The breaker starts from real use (commands and inputs as people type or paste them, every form the docs promise) before extremes, re-decides and fixes a call that caused a defect, and leaves a test failing only when it names the filed task.
- `plan done` now retires a finished plan into a history record instead of just deleting it: `docs/history/YYYY-MM-DD-plan-N-<slug>.md` keeps the plan's goal, its decisions and one line per task saying what changed, and the command prints a changelog line you can paste. Work agents open `## Completed` with a one-sentence `**Summary**:` for that line, and setup creates an empty `docs/history/`.
- The crew demo (`python3 docs/sprintbias/learning/crew.py`) now plays the lead routing what each landing releases ("built on #41 (landed)") and closing the plan with one `./sprint.sh promote plan:5`, and the project map's `**Test:**` line from `profile` points at `TEST_SUITE` in `docs/sprintbias/config`, the full-suite command `promote plan:N` runs.
- `crew setup` fits projects with many lanes: it writes a member file for every lane (a codebase, the database, production, or a pass over landed work such as stress or security), names the few members the first plan needs running, and points every member at the document holding your project's invariants, the rules every change keeps. The lead writes an `Active:` line on the plan's `## Crew` board, adds a member when a task fits no lane, and sends landings to pass members before plan close. `crew setup` with extra words now prints usage instead of starting a session.
- The project map can point at your invariants: `profile` looks for the document that holds them and adds an optional `**Invariants:**` line under `## Sources of truth`.
- `blocked/` means one thing everywhere: work that cannot start. The `chat <folder>` sweep now decides an open choice and records it as `- Decided: X, because Y` instead of blocking the task, and `status`, `gate`, `work` and `loop` label blocked items "cannot start" (or their real reason) with the `chat <id>` or `work <id>` command next to them.

- `plan think` ends by showing what it changed: each plan and task file it
  created, edited, moved, or deleted, with line counts and a one-line summary,
  plus the members it left alone. The list prints even when a run stops early
  or fails, and is saved to `docs/tmp/plan-think-<id>-changes.md`, so there
  is no `git diff` to run afterwards.

### Fixed
- `promote` runs each **Tests** file the way your project runs it: `.sh` with bash, other files with the new `TEST_RUN` config (e.g. `TEST_RUN=scripts/pytest.sh {file}`), else `.py` with pytest and an executable directly. Before, every Tests file ran with bash, so a Python test always failed and its task never closed; fix tasks now name the same command.

- Timed-out AI steps no longer leave a stray `sleep` process behind that could hold a command's output open.
- `work --audit` and `--excellence` (and the new breaker) now run on a task the
  worker moved to `review/` itself; before, a self-landed task skipped them.
- A doc follow-up you strike through (`- [x] ~~text~~ reason`) in the "Bring
  project docs in step" task is no longer filed again by `work` or `promote`.
- A doc follow-up you check off (or annotate) in the "Bring project docs in
  step" task stays resolved: `work` and `promote` no longer file it again,
  or open a second tracker task for it.
- `./sprint.sh` no longer ends a `work` or `loop` run with
  `unexpected EOF while looking for matching '"'` when a task edits
  `sprint.sh` itself: the launcher now reads its whole file before running.
- `chat <folder>`'s `[w]` writes the sweep's `- Decided: X, because Y` pick
  into the task's `## Notes` before gating it, so the call is on record.
- The crew lead closes a plan by listing the crew's calls, each changeable with
  `./sprint.sh newtask`, and naming `./sprint.sh promote plan:<N>`.
- Run endings name the exact next command: `work` prints `promote <id>` or
  `promote --accept <id>` for each landed task, `promote --accept --dry-run`
  suggests `--accept` for the real run, and `polish` re-run lines name the
  sweep or the actual files instead of a `<files>` placeholder.
- The gate's chat queue, `work`'s gate summary, `GETSTARTED.md` and the
  `loop`, `work` and `chat` help describe `blocked/` as work that cannot start.

## 0.0.137 — 2026-10-10

### Added

- `work plan N` works only plan N's tasks and leaves everything else in next/
  alone, so other tasks can wait for a closer look or hands-on work. Members
  still in backlog/ are started first through `plan start`, so one command
  takes a plan from backlog to review.

### Changed

- `chat`, `chat plan` and the sprint walk interview you again: one question at
  a time, each with a suggested answer, until the task or plan is clear. Chat
  is where questions and decisions get dug into; `work`, the gate,
  `plan think` and `crew` keep making best-practice calls on their own. A
  question left open when a chat ends keeps its suggestion, and `work` takes
  it as the answer.

## 0.0.136 — 2026-10-10

### Changed

- Agents finish the work in every mode, not only in fast mode: they decide each
  open call by best practice, record it as `- Decided: X, because Y`, and keep
  going. They ask you only in a live conversation and only when the answer
  changes the goal, as yes/no or 1/2/3. Fast mode now adds just reach:
  subagents that build missing pieces, and work across plans.
- The gate's review prompt is 90 lines shorter. It decides each open call and
  records it in the task's Notes as `- Decided: X, because Y`, and it stamps
  BLOCKED only when a task cannot start (no reasonable reading, or it needs
  access only you hold).
- `settle` is retired. The gate and `work` take every `(Suggestion: …)` answer
  themselves, so nothing waits on it. A task that still cannot start says what
  to run: `./sprint.sh chat <id>`, then `./sprint.sh work <id>`.
- One blocked member no longer stops `plan start`: blocked members are gated
  with the rest, so one that can start now joins `next/`, and one that still
  cannot stays in `blocked/` with its `./sprint.sh chat <id>` line.
- Every run of `plan start`, `promote`, `polish` and the gate now ends with the
  exact command to run next, and each settled conflict comes with
  `./sprint.sh newtask "<the change you want>"` to change it.
- The AI guidance for chats, polish and task writing now decides by default:
  a chat makes the clear calls itself, asks you only what changes the goal, and
  ends with the calls it made and the next command; polish decides a design
  choice inside a rework instead of blocking on it; task writing drafts first
  and confirms once.
- `chat`, `chat plan`, the sprint walk, `plan think` and `crew` sessions now
  carry the same finishing rule. They decide what best practice settles, move a
  task to `blocked/` only when it cannot start, and close with every call they
  made and the next command. `plan think` lists its calls under `## Decided` in
  the plan and holds only questions that change the plan's goal.
- The `work` and `promote` demos now end the way a real run does: the
  "Your turn" checklist with each call the agents made and one line to change
  it, and `promote --accept` closing a task that has no Tests.
- With fast on, a crew keeps moving: a member can take over a stalled task
  after messaging its holder and finding no live session in `./sprint.sh
  agents` (it sets **Crew** and leaves one takeover line on the plan's
  `## Crew` board), May touch becomes a routing preference, and the lead
  builds too and asks you only goal questions. Steady crews work as before.
- `chat plan` now does the planning work in the session: it creates tasks
  with `newtask`, edits tasks in any plan, sets **Depends on** /
  **Dependents** across plans on both sides, and moves READY tasks between
  `backlog/` and `next/`. With fast on it also gets subagents, can run `plan
  start` and `work`, and builds a missing piece to `review/` with a proof line.
  Commit, push, `ship.sh` and `done/` stay yours.
- Fast mode now means fully autonomous: agents skip the AI CLI's permission
  prompts (Claude `--dangerously-skip-permissions`, Grok `--always-approve`),
  and `work` and `polish` run independent tasks in parallel at 4 jobs with no
  flag. `--jobs N` sets the count, `--steady` runs one at a time, and the old
  `work --fast` / `polish --fast` still work. Commit, push, `ship.sh` and
  sign-off stay yours. Fast is safest on a dev server or a clean git tree.

- The end of a `work` run now gives each finished task a numbered checklist:
  check the calls the AI made for you (`newtask` to change one), try the change
  (`promote --reject <id> "…"` if it's wrong), then the one command that closes
  it. Filed doc follow-ups name their task and the `work <id>` that handles them.
- Questions no longer stall work. The gate and `work` take each suggested
  answer, record it as `Decided: X, because Y`, and finish; only a task with no
  reasonable reading, or one that needs access you hold, goes to `blocked/`.
- A failing test is audited before you hear about it: a wrong test gets
  corrected, a clear cause gets fixed and re-run. A failure still unexplained
  lands in `review/` without proof, and the checklist points you at its log.
- The manual is shorter (2,930 words, down from 3,410): detail that lived in
  two places now sits in its help page or guide, with a pointer. It also covers
  the `held: fix #N` standing and the reused suite run at sign-off.
- `promote plan:N` reuses a green full-suite run when nothing in the working
  tree has changed since, so your sign-off after the lead's run costs no second
  run; `--fresh` forces one. A held original reads `held: fix #N` in its
  refusal listing.
- New tasks split "done" in two: `## Done when (automated)` (the outcome plus
  the test or command that proves it) and `## Signoff (human)` (what a person
  checks). The gate keeps a task out of `next/` until Done when names a test or
  command in backticks. Older tasks with `## Success criteria` keep working;
  that section reads as Done when (automated).
- A task in `review/` now releases its dependents only when it has landed:
  a `**Proof**: YYYY-MM-DD · <test commands> · pass` line under its
  `## Completed`. Without one it is "in review, unproven" and its dependents
  hold, in `work`, `loop` and `promote` alike; the hold message says to sign it
  off (`promote` or move to `done/`) or add the proof line. Tasks in `done/`
  release their dependents as before.
- Workers in `work` and `crew` now follow one test loop: build the smallest
  testable outcome first, run only the targeted tests (the ones Done when names
  plus the tests for the files they touch), log each failure under
  `## Test log`, and land with a `**Proof**:` line. `work` reports a task that
  lands without proof as in review, unproven, and a worker that stops on a
  decision keeps its own `## Outcome` reason in `blocked/`.
- `plan check` and `status` now show each plan's state as STARTED, LANDED or
  SIGNED OFF, with three counts: open, landed (in `review/` with proof) and
  signed off (in `done/`). A plan whose work has all landed reads LANDED,
  ready for the full suite and sign-off, not stalled. Both reports flag
  `review/` tasks without a proof line and open fix tasks (`**Fixes**: #N`).
  The state is computed from the folders and never written into the plan;
  `plan done` still needs every member in `done/`.
- A crew lead now keeps every member busy and routes on landing: it splits
  the plan so tasks running at once touch different files, routes a task's
  dependents the moment it lands (proof line in `review/`), keeps each
  member's next task queued on the plan's `## Crew` board, and marks work
  "built on #N (landed)". When `plan check` reads LANDED it runs the full
  suite, routes the fix tasks, and hands you one sign-off:
  `./sprint.sh promote plan:N`. Members report each landing to the lead, or on
  the board when the CLI cannot message.
- The manual now has separate **Solo** and **Crew** sections, so you can tell
  which fits in a minute, and states once that landed work (in `review/` with
  a proof line) releases its dependents while `done/` is your sign-off.
  `GETSTARTED.md` and the help pages say the same. A LANDED `plan check` now
  points at `./sprint.sh promote plan:N`, and fix tasks read "sent back from
  review", which fits a rejection and a failed full suite alike.
- The `work` and `teamwork` demos now finish a plan the new way: tasks land
  with targeted tests and a proof line, a dependent starts the moment its
  prerequisite lands, and `promote plan:N` runs the full suite once for one
  sign-off. `teamwork` also shows the lead routing on landing and
  `promote --reject` sending a fix back to the same crew member. The other
  demos now say "landed" where they used to wait on `done/`.
- The crew story is now three short demos you can watch one at a time:
  `./sprint.sh learn teamwork` (set up a crew; two agents claim work and share
  a contract), `learn team-landing` (work lands, the lead routes, you reject
  one) and `learn team-signoff` (the plan closes with one sign-off). Each says
  where it sits in the story and points at the next.

### Added

- `./sprint.sh promote --accept <id>` closes a task with no **Tests** in one
  line: your sign-off. Named Tests still run, and dependency holds still apply.
  The end-of-run checklist and promote's skip summary print it for each task.
- In fast mode, `chat`, `chat plan`, `crew` and `work` agents may start
  subagents to build missing pieces, and note `Touched by plan N` when they work
  another plan's task.

- `./sprint.sh fast on` / `fast off` is one switch for fast mode on this
  machine (saved in `config.local`; off is "steady"); bare `fast` shows the
  mode. `--fast` / `--steady` before any command set it for one run, and
  `work --fast` / `polish --fast` turn it on for theirs. Every AI session's
  banner and `status` show `fast: on` or `fast: off`.

- One human test per plan. `plan start` gathers every person-only check (the
  plan's and each member's `## Signoff (human)`) into a single task marked
  `**Owner**: human`, parked in `review/` and listed last in the plan. Agents
  never work it or wait on it: the plan lands without it. Workers build to the
  most reasonable assumption, record it under `### Assumptions`, and land;
  `promote plan:N` adds those assumptions to the human test. Write
  `- fail: <what you saw>` under its `## Results` and `promote plan:N` files
  each as a fix task for the agents; a clean run closes the test with the
  batch. The gate no longer stamps a task BLOCKED for a check only a person
  can make.

- `./sprint.sh promote --reject <id> "what is wrong"` sends a `review/` task
  back as a linked fix task. The fix task (`**Fixes**: #<id>`, same Crew and
  Plan) turns each reported problem into a test to add, with anything only a
  person can judge under Signoff (human). The original stays in `review/` with
  `**Held**: fix #<new>`: its dependents wait until the fix lands, and
  `promote` closes it once the fix is in `done/`. Landed and signed-off
  dependents get a re-check line in their `## Test log`. New tasks carry a
  `**Fixes**: none` field.
- `./sprint.sh promote plan:N` signs off a whole plan in one batch. Once the
  plan reads LANDED it runs your full suite once (the new `TEST_SUITE` setting
  in `docs/sprintbias/config`), files fix tasks for the members whose files
  failed, and on a pass shows the plan's combined Signoff (human) checklist;
  answering `y` moves every member to `done/`. `promote <id>` still signs off
  one task at a time.

### Fixed

- A plan's human test no longer lists the agents' `Decided:` calls as checks
  for you to run; those calls appear in the end-of-run checklist instead.
- The gate's review prompt now carries the `Decided: X, because Y` format. An
  unquoted backtick had been running it as a shell command, which dropped the
  text and printed "Decided:: command not found".
- `work`, `polish`, `promote`, `crew` and `loop` no longer crash with a syntax error at the end of a long run when their own script file was edited mid-run (by a task or a `setup.sh` update); bash now reads the whole script before running it.
- `newplan` with task ids writes the member list under `## Member tasks` again, instead of after the closing comment at the end of the file.
- `promote plan:N` lists an open fix task once, as `fix #N for #M`, instead of
  twice.
- `plan check` and `status` no longer call a rejected task "in review,
  unproven" when its proof line is in place. A `review/` task waiting on its
  fix now reads `held: fix #N`, naming the fix to work next, and is listed
  apart from tasks that are missing their proof line.

## 0.0.135 — 2026-10-08

### Added

- Agents working in parallel (`work 1443` in one terminal, `work 1452` in
  another, or a crew) now coordinate by default. Each one is told the other
  tasks in `doing/`, announces the files it expects to change as a
  `**Touching:**` line in its task, checks the others' lines before editing,
  messages them when its tools can, and leaves changes it did not make alone.
  The manual gains rule 8, "Work alongside other agents."
- New demo, `./sprint.sh learn teamwork`: a lead, an API agent and an iOS
  agent fix one bug across two codebases at once. Watch them claim tasks,
  announce their files, message each other, share one contract file without
  overwriting it, and hand finished work to you to review and commit.
- `./sprint.sh crew setup`: a guided build. An AI session reads your project,
  asks up to three questions, proposes the smallest crew that gives each kind
  of work one owner, then creates and fills the member files. Its advice is
  tuned separately for Claude Code and Grok Build. The crew guide gains a
  Recommended crews table for building one by hand.
- Assign a plan to a crew: `./sprint.sh crew <lead> plan:N` records the
  lead in the plan's new `**Crew**` field and hands it the plan's tasks laid
  out in parallel waves from their `Depends on` lines. The lead routes a whole
  wave at once and starts each later task as soon as its own prerequisites
  land. `crew <lead>` alone resumes its plan, and `./sprint.sh crew` shows
  which plan each lead holds.

### Changed

- `crew add <name> "<role>" --lead` now writes a filled-in lead file (its
  job, what it reads, what it may touch, how it reports) instead of empty
  hints. A member's file arrives with its Reports filled and clearer prompts
  for its Job and May touch.
- `./sprint.sh help` gains a short "Several agents at once" section: `work N`
  in each terminal or a crew on one machine, and a crew on a shared server
  (one clone, one branch, a tmux window per member, `AGENT_HOSTS` so `agents`
  lists them). `help crew`, `help work` and the manual give the same steps.
- `GETSTARTED.md` is rewritten for today's tool: what you need installed, one
  install step, `profile` on first run, the `newtask → chat → work N → promote`
  loop, plans, crews and `agents`, and picking Claude Code or Grok Build. It no
  longer tells you to move tasks into `next/` by hand.

### Fixed

- The getting-started loop and the manual's pipeline now use `work 12` to gate
  and build a single task. They used to say `chat 12` puts the task into
  `next/`, which it does not, so a plain `work` afterwards found nothing to do.

## 0.0.134 — 2026-10-06

### Changed

- `config` offers the current Claude models: Opus 5.5, Sonnet 5.5 and Haiku 4.5
  (Opus 4.8 and Opus 5 are gone from the menu; the custom entry still takes any
  id). Examples in the manual and help now use `claude-opus-5-5`.

### Fixed

- `config` now warns when `docs/sprintbias/config.local` pins the provider or
  default model to something else, since that local pin wins over the choice you
  just saved and would otherwise leave you on the old model without notice.

## 0.0.133 — 2026-10-05

## 0.0.132 — 2026-10-05

### Added

- `agents` shows every AI session running on this machine and on your servers:
  name, busy/idle/waiting, which terminal tab or tmux window it lives in,
  project and branch, uptime, last activity, model, context size, CPU and
  memory, and the topic and last prompt. Add servers by ssh alias in
  `AGENT_HOSTS`. `agents label` titles each terminal with its session name.
  Reads what Claude Code already records; no AI runs.
- `shell` sets up a friendly terminal prompt on macOS and Linux: machine name
  (bold red over SSH, so a server never looks like your laptop), folder, git
  branch with a `*` for uncommitted changes, clock with time zone, and how long
  slow commands took. `shell install` walks you through zsh (macOS default),
  bash (Linux default), and a tmux status bar that keeps the machine name in
  view during remote sessions. It adds one marked block per file; run it again
  to update, run it on each new server, and `shell remove` puts your files
  back exactly as they were.

## 0.0.131 — 2026-10-04

### Added

- `crew` runs several named AI sessions on one project, each with a role. A
  member is a file in `docs/crew/` (`crew add <name> "<role>" [--lead]`);
  `crew <name> [ID | plan:N]` starts a session by that name; plain `crew` lists
  who holds what. A lead coordinates the rest through the plan's `## Crew`
  section, and a new task field, `Crew`, routes a task to a member and marks
  the claim once it is in `doing/`.
- Crew guide (`docs/sprintbias/guides/crew.md`), including running a crew on a
  shared dev server, and a `crew --demo` you can watch. The manual gains a
  "Learn more" section pointing to help pages, demos and guides.

## 0.0.130 — 2026-09-30

## 0.0.129 — 2026-09-30

### Added

- `profile` builds the project map: `docs/sprintbias/project.md` now records
  where the project's knowledge lives — code layout, run/test/lint/build
  commands, sources of truth (glossary / lexicon / taxonomy, architecture,
  decisions, API, security, instruction files), and environments (local, CI,
  deploy, and who may deploy) — ending with a `**Checked:**` date @ commit stamp.
- `profile check` (no AI) flags a missing map, listed paths that no longer
  exist, and tracked files changed since the last check. `work` and
  `plan start` run it first and print one line when the map has drifted.
- Tasks are grounded before they are worked. The gate writes `## Grounding`
  into each task: the sources it relies on, the glossary terms it uses (copied
  word for word), and its conflicts — task vs a source, source vs source, task
  vs code, or task vs SprintBias itself — each settled before work. A conflict
  that changes scope becomes a question for you. `work` fills in missing
  grounding, and both the gate and `work` print every noted conflict.
- Docs stay in step with the work. A worker whose change alters what a source
  of truth describes updates it in the same task; governing sources (security
  policy, decision records, `CLAUDE.md` / `AGENTS.md`) and out-of-scope gaps are
  recorded under `### Doc follow-ups`. `work` and `promote` collect them into one
  backlog task, *Bring project docs in step with landed work*, each line tagged
  with its source task and filed once. `polish` flags a change that left a
  source wrong with neither.

- Rework decided while working a plan is grouped for after the plan. Tasks
  filed from plan N's work — "rework later" decisions in `chat plan`, deltas
  from `plan think`, put-off members, `polish` enhancements — carry
  `**From plan**: N` (`newtask "…" --from-plan N`) and stay out of plan N.
  `plan done N` lists them and prints the one command that groups them:
  `newplan "… — follow-ups" from:N` → `plan start <id>` → `work`.
- `newplan "Name" backlog` puts every backlog task not yet in a plan into a new
  plan. `from:N` and `backlog` also work at the interactive member prompt and
  mix with ids and `parent:N`.
- A plan created with its members named (ids, `parent:N`, `from:N`, `backlog`)
  starts `READY`, so `plan start` runs from an agent session too. A plan created
  empty still starts `DRAFT`.

### Removed

- `context` is retired: use `status` for project state and `profile` for what
  an agent needs to know.

### Changed

- Every AI command now orients the same way: one line naming the instruction
  file your provider loads (`CLAUDE.md` or `AGENTS.md`), the manual, and the
  project map, with one policy — sources of truth are the authority, conflicts
  are named rather than worked around, deploys and secrets are human-owned.
  Grok runs are no longer told to read `CLAUDE.md`.
- `chat` raises decisions one at a time in every session, not just reviews.
  When the AI has two or more calls for you, it writes them as a checklist in
  `docs/tmp/<subject>_discuss.md` (e.g. `task-231_discuss.md`) and works it
  one line at a time: ask, settle it with you, make the updates, note the
  decision, check it off, re-read, next. Checked lines are never reworked, and
  the next `chat` on that task or plan picks up at the first unchecked line.
- `plan think` lists the decisions it holds for you in the same checklist
  form, plan-level first and then task by task, and `chat plan` works through
  it the same way.
- `chat <id>` now checks the task against the current code in its opening read.
  Next to *well-defined?*, *worth more discussion?*, and *best-practice path*,
  it asks *aligned with the current code?* and names any drift: moved or renamed
  paths, outdated dependencies, stale assumptions, work already done, or a
  change in direction. It then updates the brief to match before refining.

### Fixed

- `plan check` and `chat plan` on a plan with no member tasks no longer exit
  silently: `plan check` reports the plan as empty, and `chat plan` opens
  authoring.

## 0.0.128 — 2026-09-28

### Added

- Reviews raise issues one at a time. When a `chat` walk (or any agent
  reviewing a plan) finds two or more things that need your call, it lists them
  in `docs/tmp/<subject>_discuss.md`, then raises one issue per message with
  numbered options (the best-practice pick marked suggested), carries out your
  pick right away, and moves to the next. An interrupted session resumes from
  the file.

### Changed

- `plan think` now acts on everything it can settle itself and holds only your
  calls (a product or policy choice, a number only you can set, a cut you might
  contest) in `docs/tmp/plan-<id>_discuss.md`. When it finishes it opens
  `chat plan <id>`, which raises those items one at a time and acts on each
  decision as you make it.
- `plan think` checks every unstarted task against the code before touching it:
  is the problem real, already solved, and needed for the plan's goal? Scope
  creep is trimmed on the spot; tasks that are already done, describe a problem
  the code doesn't have, or don't serve the goal come to you (with file:line
  evidence) as discussion items. The review opens with a per-task verdict list.
  In `chat plan`, each is raised with options fitted to its verdict: close,
  trim, or delete a done-already task; delete or keep a not-real one; delete or
  put off an off-goal one — and the pick is carried out immediately.

## 0.0.127 — 2026-09-21

## 0.0.126 — 2026-09-21

### Changed

- Rewrote the manual (`DOCUMENTATION.md`): shorter and reorganized around how the
  tool actually works — new sections for *How it works*, *Why folders and plain
  text*, *Folders = status*, *Distinctions that trip up agents*, and *The
  pipeline*. Same ground, ~150 fewer lines.
- Audit runs now read each result once. The internal machinery that reads an AI
  audit's output (used by polish and promote) was doing the same work two or
  three times per run; it now reads once and reuses the outcome, verdict, and
  summary. No user-visible change — just less duplicated work.

### Fixed

- `promote` now explains when a judge doesn't finish. When the AI judge runs out
  of turns or never starts, promote says so plainly ("judge did not finish — …")
  and leaves the task in `review/`, instead of blaming a missing verdict. A
  judge that finished but answered oddly is reported separately.
