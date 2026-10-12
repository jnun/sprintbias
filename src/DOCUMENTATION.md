<!-- SprintBias v0.0.77 -->
# SprintBias

Project management as plain markdown files in folders. No database, no app — the
filesystem *is* the state, so an AI agent reads `ls` and knows everything. Folders
and plain text play to what an agent does well: read, reason, decide. That bias is
the name.

> Named `SPRINTDOCUMENTATION.md`? Same manual: you already owned a
> `DOCUMENTATION.md`, and your `CLAUDE.md` / `AGENTS.md` pointers target this name.

## How it works

Three facts explain the whole system:

1. **A task is a markdown file** describing an outcome in plain language.
2. **Its folder is its status.** Move the file to change status.
3. **The AI runs the pipeline:** `chat` defines work, `work` builds and tests it,
   `polish` perfects it. You sign off.

You drive all of it through one command — `./sprint.sh`. Run `./sprint.sh help` for
the full list and `./sprint.sh status` to see where work stands. Everything below is detail.

## Rules for AI agents

Follow these eight and you will not get lost:

1. **Change status by moving the file** between folders. Do not edit a status field.
2. **Create work with `./sprint.sh`** (`newtask`, `newbug`, …). Never write a task
   file or pick an ID by hand — IDs are assigned for you.
3. **Treat `docs/sprintbias/` as read-only.** Your work lives everywhere else under
   `docs/`. (The exceptions: `docs/sprintbias/DOC_STATE.md`, and `project.md`,
   which `./sprint.sh profile` writes.)
4. **Old dates in `review/` or `done/` mean finished, not stale.** Never redo them.
5. **You define, execute, land, and perfect. The human signs off, commits, and ships.**
   Run `git commit` or `./sprint.sh sync` only when the human asks in this conversation.
6. **Chat asks; work finishes.** `chat`, `chat plan` and the sprint walk are where
   questions get dug into: one question at a time with the person, each with a
   `(suggested)` answer, until the task or plan is clear. Everywhere else (work,
   the gate, `plan think`, crew), decide each open call by best practice, good
   security, elegant code and the best UX, and record it as a bullet,
   `- Decided: X, because Y` (a task's `## Notes` before work, its `### Assumptions`
   during work, a plan's `## Decided` section). The person sees every call at the end of the run
   and changes one with `./sprint.sh newtask "<the change you want>"`. A question
   left open keeps its `(Suggestion: …)`, and `work` takes it as the answer.
   `blocked/` is for work that cannot start: no reasonable reading, or access only
   the person holds. A tool idea becomes `./sprint.sh newtask "…"`; then back to the goal.
7. **Start from the project map.** `docs/sprintbias/project.md` says where the
   project's knowledge lives. Ground a task before working it — its `## Grounding`
   names the sources, the terms, and the conflicts. Sources of truth are the
   authority: name a conflict instead of working around it. Check `docs/history/`
   first for why an area is the way it is.
8. **Work alongside other agents.** Every task in `doing/` is an agent at work.
   Announce yours with `**Touching:**` (files you expect to change) in its
   `## Grounding`, read the others' at the start and whenever a file changes
   under you, and leave changes you did not make as they are. On shared code
   the lower task id owns it. This holds solo or in a crew (see **Solo** and **Crew**).

## Principles

1. **Lean into agent bias** — build around what AI does well: read, reason, decide.
2. **Minimize context cost** — fewer, sharper commands. Pruning is a feature.
3. **Name in common language** — `task`, `chat`, `work`, `plan`; if a word needs
   translating, pick another.
4. **Instruct positively** — state the desired path; reserve "never" for real invariants.

Tie-breaker: **simple, clean, fast, common language, biased toward action.**

## Structure

```
docs/
├── sprintbias/          # FRAMEWORK — do not edit (except DOC_STATE.md)
│   ├── scripts/         # the commands
│   ├── ai/              # AI instructions
│   ├── guides/          # framework guides, in detail (doc-style, sprint alias, chat, crew)
│   ├── help/            # per-command help pages: how do I do X
│   ├── learning/        # demos you watch: ./sprint.sh learn
│   └── DOC_STATE.md     # ID counters + state (the one framework file you own)
├── ideas/               # rough concepts being refined
├── features/            # fully defined specs
├── tasks/{backlog,next,doing,blocked,review,done}/   # work — folder = status
├── plans/               # named lists of task IDs (an index, not a stage)
├── history/             # finished work: one record per retired plan, plus `history record` files
├── crew/                # one file per named AI session (role, what it may touch)
├── bugs/                # open bug reports (inbox; handled reports are deleted)
├── guides/  tests/  designs/  examples/  data/       # your content
└── tmp/                 # scratch (gitignored)
```

**Yours to edit freely:** everything under `docs/` except `docs/sprintbias/`
(and `DOCUMENTATION.md` / `sprint.sh`). **Framework, do not edit:** those.

## Folders = status

| Folder | Meaning |
|--------|---------|
| `backlog/` | planned, not started |
| `next/` | queued for the current sprint |
| `doing/` | actively worked |
| `blocked/` | can't start: the task is unreadable, or it needs access only you have |
| `review/` | built; **landed** once it carries a proof line, then awaiting your sign-off |
| `done/` | **signed off** by you |

## Distinctions that trip up agents

- **landed ≠ signed off.** A task has *landed* when it sits in `review/` with a proof
  line under `## Completed`: `**Proof**: YYYY-MM-DD · <targeted test commands> · pass`.
  Landed work releases its dependents at once; in `review/` without proof it is
  *in review, unproven* and releases nothing. *Signed off* means `done/`: only humans
  move work there, after the full suite passes and the human checks are done, usually
  a whole plan at once (`promote plan:N`). Targeted tests run per task; the full suite
  runs once, at plan close, and a green run is reused until the tree changes
  (`--fresh` re-runs it).
- **blocked ≠ dependent.** *Blocked* = *this* task can't start (no reasonable
  reading of it, or missing access); fix with `chat <id>`, then re-gate. A
  question with a sensible answer never blocks: the agent takes it, records
  `Decided: X, because Y`, and finishes. *Dependent* = clear but waiting on
  another task via `Depends on` (stays where it is — no move). A chain of dependent
  tasks has zero blocked tasks.
- **plan ≠ folder.** A plan (`docs/plans/N-name.md`) is one file listing related
  task IDs. Members never move into it — each flows through its own lifecycle folder.
  A plan carries `DRAFT → READY → STARTED`; `plan done` retires it into a history
  record in `docs/history/` once every member is in `done/`.
- **COMPLETE ≠ done/.** COMPLETE is a verdict ("already built in the code") and routes
  to `review/` for your sign-off — never a silent jump to `done/`. `done/` is where
  *you* (or `promote`) move an approved task.

**Task fields** (metadata, not status):

- `Depends on` — prerequisite IDs. A dependent runs once each prerequisite has landed
  or is in `done/`. Gates `plan start` (entry), `work` (run), and `promote` (close),
  so work happens and closes in dependency order.
- `Dependents` — reverse edge; graph info only. `Plan` — its plan (`none` or an id).
- `Crew` — the member it is routed to (`none` or a name); in `doing/`, the claim.
- `Tests` — test files under `docs/tests/` that prove success. `promote` runs them
  (`.sh` with bash; others with config `TEST_RUN`, else `.py` with pytest);
  all green → `done/`. `none` means a human signs off.
- `Fixes` — on a fix task, the task it repairs (`#<id>`). `promote --reject` (on a
  review/ task, or a done/ one found broken later) or a failing full suite at
  `promote plan:N` files it.
- `Held` — on the original: `fix #<new>`. It stays in `review/`, shows as
  `held: fix #N` in `plan check` and `status` (apart from *unproven*), releases its
  dependents once the fix lands, and closes once the fix is in `done/`.
- `Owner` — `human` marks a plan's human test: every person-only check in one
  task in `review/`. Agents never work it (`./sprint.sh help promote`).

**Task sections:** `## Done when (automated)` (each outcome with the test or command
that proves it, in backticks; an older `## Success criteria` reads as this),
`## Signoff (human)` (what a person checks at sign-off), `## Test log` (each failure:
command, failing test, error excerpt), and `## Completed`, which ends with the proof line.

**Test loop** (every worker): build the smallest testable outcome first, run the
targeted tests (those Done when names, plus tests for the code your Touching files
feed), log each failure under `## Test log`, then audit it: a wrong test gets
corrected, a clear cause gets fixed, and the run repeats until green. A failure still
unexplained lands in `review/` without proof. Decisions and person-only checks never
hold a task: assume, record `Decided: X, because Y` under `### Assumptions`, land. The
end of the run lists every call for you to check; `newtask` changes one.

**Edge cases** (gate, worker, crew, breaker — one list): a task's example stands for
its class. The gate names a check per listed case; the worker asserts each Done when
case and each realistic case of the class, round trips (every form your docs, UI or
examples tell people to write, and what the real tools people use emit), again and
after (run twice, older state, hand edits), empty / one / many / malformed, and
neighbors (other code on the same data). A failing case is fixed, or filed with
`newtask` when it lives in another code path; Decided and Assumptions record choices
between working options. **Breaker** (on by default): after a task lands, a fresh
agent writes tests designed to fail against the change, fixes what it can, and
removes the proof line for what it cannot (the task lands unproven, the failure in
`## Test log`). Off: `BREAK=off` in `docs/sprintbias/config`, or `--no-break`. `promote` runs it on
any task that has not had it before signing off, so `promote <id>` / `promote plan N`
is the whole human path; `polish --break <id|plan:N>` runs it alone. A plan target
reads `plan N`, `plan:N`, or a bare N when no task N exists (work, promote, polish, crew).
Each run adds `· $cost` to its Breaker line; raise its limits with `BREAK_MAX_TURNS` (25),
`BREAK_TIMEOUT` (900 s) and `BUDGET_BREAK` ($2) in config. `status --edges` scores it:
defects the agents caught vs defects you found (`promote --reject`, including on a `done/`
task found broken later, and human-test failures), with and without the breaker.

## The pipeline

Work flows one direction: **backlog → next → doing → review → done**. Follow one
task the whole way:

```bash
./sprint.sh newtask "Add a login button"   # → backlog/12-add-login.md
./sprint.sh chat 12                         # define it until it's clear
./sprint.sh work 12                         # gate it into next/; the AI builds, tests, lands it → review/
./sprint.sh promote                         # you sign off: Tests pass → done/ (no Tests: promote --accept 12)
```

Tasks enter `next/` **only through the gate** — `work N`, `plan start`, or `chat
<folder>`'s [w] — or through `chat plan` for a task already READY with a tested
Done when. That bar is what keeps `next/` trustworthy.

For grouped work, use the spine **`chat → plan start → work → promote plan:N`**: gather
tasks into a plan, `plan start` commits them all at once, `work` or `loop` lands them,
and one `promote plan:N` signs the plan off. A member in `blocked/` is gated with
the rest: one that can start joins `next/`, and one that still cannot stays in
`blocked/` with its `./sprint.sh chat <id>` line.

`chat plan N` does the planning work in one session: it creates missing tasks,
edits tasks in any plan, and sets **Depends on** / **Dependents** across plans
on both sides. In fast mode it also acts as the plan's lead — it can run `plan
start` and `work` and build a missing piece itself or through a subagent,
landing it in `review/` with a proof line. Use `crew` for named, long-running
lanes. Commit, push, `ship.sh` and `done/` stay yours in every mode.

## Commands

One line each. For flags and detail: `./sprint.sh help <cmd>` (or `<cmd> --help`).
Not sure of the name? `./sprint.sh help <plain words>` (`help new idea`, `help idea`)
finds it with no AI: one match prints its page, several print a short list (exit 0),
none prints one line (exit 1). At a terminal, bare `./sprint.sh help` ends with
`What command would you like to understand better?` — and when your words match no
single command, it offers a read-only AI answer (`Ask the AI instead? [y/N]`).
Groups: **create · chat · plan · work · look · keep**.

```bash
# create — IDs are assigned for you; never make task files by hand
./sprint.sh newidea "..."       # idea (no name = AI Q&A)
./sprint.sh newfeature "..."    # feature (no name = AI Q&A)
./sprint.sh newtask "..."       # task
./sprint.sh newplan "Name" [ids]# plan — a named list of task IDs
./sprint.sh newbug "..."        # bug report
./sprint.sh newtest "Name"      # test loop for a deployed thing

# chat — the conversational engine
./sprint.sh chat [target]       # id: one task · folder: sweep · plan [id]: author · bugs: inbox · none: sprint health

# plan — group and commit related tasks
./sprint.sh plan think 5        # improve the plan + align its tasks; calls listed under ## Decided
./sprint.sh plan start 5        # gate + commit members into next/ (latches STARTED)
./sprint.sh plan check 5        # read-only: STARTED / LANDED / SIGNED OFF, and each member's standing
./sprint.sh plan check          # pick a plan, or Enter to check them all
./sprint.sh plan polish 5       # excellence-judge the plan's finished work
./sprint.sh plan done 5         # retire the plan into a history record (docs/history/)

# work — execute and finish
./sprint.sh work [N]            # run READY tasks (work N = one by id; count N caps how many; --no-break skips the breaker)
./sprint.sh work plan N         # start plan N if needed, work only its tasks; the rest waits
./sprint.sh loop                # autopilot: plan start refill, then drain next/
./sprint.sh gate [folder]       # off-spine quality gate: re-gate next/ or report elsewhere
./sprint.sh crew [name] [ID]    # list the crew · start a session as one member (add <name> "<role>")
./sprint.sh split <path>        # split a large task into subtasks
./sprint.sh polish [id]         # sweep review/, deep-judge a task, --code audit, or --break <id|plan:N>
./sprint.sh promote [id]        # close review/ → done/ (breaker, then Tests; --accept <id>, --audit, --reject <id> "why",
                                #   plan:N = sign off a LANDED plan with one approval)

# look — read-only
./sprint.sh status              # project status (--edges: caught by agents vs found by you)
./sprint.sh agents              # every AI session here and on your servers
./sprint.sh search <keyword>    # search tasks
./sprint.sh history             # finished work, newest first (--since <date|tag> = release notes)
./sprint.sh history record      # write done/ tasks no plan record covers into docs/history/
./sprint.sh learn [demo]        # watch the flow run (no name lists demos)
./sprint.sh align               # feature alignment

# keep — config & maintenance
./sprint.sh profile             # build/refresh the project map (show = print, check = drift, no AI)
./sprint.sh sync                # push task changes to GitHub
./sprint.sh validate            # integrity-check IDs + deps (--docs, --commands guard the catalog)
./sprint.sh cleanup             # clean stale docs/tmp/ files
./sprint.sh model show          # see/list/set the AI model per role
./sprint.sh config              # set provider + default model (interactive)
./sprint.sh fast [on|off]       # fast mode for this machine (bare = show; off = steady)
./sprint.sh shell               # cozy terminal prompt: machine, path, branch, clock (install / remove)
./sprint.sh deps                # file a task auditing outdated/vulnerable deps
```

> Tired of `./sprint.sh`? Add `alias sprint='./sprint.sh'` to your shell rc.
> `setup.sh` offers this; see `docs/sprintbias/guides/sprint_command.md`.

## Solo or crew

Pick the mode that fits how you run agents. Both share the rules above and land
work the same way.

- **Solo**: one agent at a time, often unattended. It saves context.
- **Crew**: several named sessions you steer at once, each in its own lane. It saves time.

## Solo

Solo optimizes for one context: one agent, the code read once, nothing re-learned.

- **Run in dependency order, in one session.** `work` drains `next/`, releasing each
  dependent as its prerequisite lands; `loop` starts and drains plans on autopilot.
- **Batch related tasks** in one plan, so what one task learned serves the next.
- **Keep notes in the task file** (`## Completed`, `## Test log`, Doc follow-ups).
- **Close with one sign-off.** `promote plan:N` runs the full suite, files fix tasks
  for failures, and asks you for one `y`.

## Crew

Crew optimizes for throughput: several AI sessions at once, each with a name and a
job, none idle. A lead keeps everyone rowing; members such as a builder, a bug
fixer, a production operator or a security pass do the work. Write a member for
every lane; run only the ones a plan needs. Each member is one file,
`docs/crew/<name>.md`: its role, what it reads first, what it may touch, how it reports.
`./sprint.sh crew setup` proposes a crew and fills the files; `crew <name> [id|plan:N]`
starts a member in its own terminal (`./sprint.sh help crew`). Every member works by these:

1. **Claim and route through files.** A task's `Crew` field routes it to a member.
   Moving it into `doing/` with `Crew` set to your own name is the claim; a task in
   `doing/` held by someone else is theirs. Messages reach members by crew name and
   only nudge; what must last goes in a task or plan file.
2. **Stay in your lane.** Each member touches only what its file allows.
3. **Land fast and report it.** Land each task with its proof line, tell the lead the
   id and proof (or write it on the plan's `## Crew` board), and take your next.
4. **The lead splits and routes.** It holds the plan in its `## Crew` section, with an
   `Active:` line naming who runs; adds a member for a task no lane covers; leaves
   product code to the others; splits work as wide as disjoint `**Touching:**` lists
   allow, and routes what each landing releases, marking it "built on #N (landed)".
   At LANDED it runs the full suite, routes each fix to the member who built the
   original, and hands you one `./sprint.sh promote plan:N`.

With fast on, holds and lanes bend so work keeps moving: a member messages a stalled
holder and, when `./sprint.sh agents` shows no live session for it, takes the task over
(sets `Crew`, leaves one takeover line on the `## Crew` board); `May touch` becomes a
routing preference; the lead builds too and asks you only goal questions.

Without a crew, `work N` in each terminal runs agents side by side (rule 8). Watch a
crew with `./sprint.sh learn teamwork` (three parts). `./sprint.sh help agents` lists
running sessions, servers included. The full guide, including a crew on a shared dev
server, is `docs/sprintbias/guides/crew.md`.

## Learn more

This manual is the baseline. Three places go further, each for one kind of question:

| Question | Where |
|----------|-------|
| How do I do X with a command? | `./sprint.sh help <cmd>` or `help <plain words>` (pages in `docs/sprintbias/help/`) |
| What does it look like in motion? | `./sprint.sh learn` or `<cmd> --demo` (demos in `docs/sprintbias/learning/`) |
| How does a whole workflow fit together? | `docs/sprintbias/guides/` (chat, crew, `sprint` alias, doc style) |

## Moving tasks

Folder location **is** status. Always move with:

```bash
git mv SRC DEST || mv SRC DEST
```

`git mv` keeps history; plain `mv` covers a new, untracked file. The move is the
status change — nothing else to edit.

## Creating work

Use the **create** commands above. Each advances the ID counter in
`docs/sprintbias/DOC_STATE.md` and drops a templated file (`docs/<type>/.TEMPLATE-*`)
to fill in. Naming: tasks/bugs `ID-description.md`; features/ideas `name.md`.
`newplan "Name" from:24` gathers a finished plan's follow-ups and `newplan "Name"
backlog` the whole backlog; then `plan start <id>` and `work`.

## Provider and model

Your CLI, provider, and per-role models live in `docs/sprintbias/config`.

```bash
./sprint.sh config              # pick provider (Claude Code / Grok Build) + default model
./sprint.sh model set work claude-opus-5-5   # pin a model for one role
./sprint.sh -g work             # one run on Grok (-c / --claude for Claude Code)
```

Set `TEST_SUITE` there to your project's full test command (e.g. `TEST_SUITE=npm test`)
for `promote plan:N` to run at plan close. Empty means no full suite runs.

For a personal override that never ships or commits, put the same `KEY=VALUE` lines
in `docs/sprintbias/config.local` (gitignored). Precedence, highest first:
env var → per-run flag → `config.local` → `config` → tier default.

### Fast mode

Fast mode is the switch for how freely agents run: `fast on` lets them work
autonomously at high throughput; `fast off` (steady) is the default. In fast mode
agents skip the AI CLI's permission prompts, and `work` and `polish` run
independent tasks in parallel (4 jobs; `--jobs N` sets the count, `--steady` runs
one at a time). Commit, push, `ship.sh`, sign-off to `done/` and production
credentials stay yours by rule. Fast is safest on a dev server or a clean git
tree. It is per machine, saved as `FAST=` in `config.local`. Put `--fast` or
`--steady` before any command for one run (`./sprint.sh --fast chat 12`);
`work --fast` and `polish --fast` also turn it on for their run. Every AI
session's banner and `status` show `fast: on` or `fast: off`.

Work-side agents decide and keep moving in every mode (rule 6 above). Fast mode adds reach
to `chat`, `chat plan`, `crew` and `work`:

- **Build what is missing.** An agent may start a subagent to build a missing piece
  the goal needs; it lands in `review/` with a proof line like any task.
- **Serve both plans.** Before touching another plan's task, the agent reads
  that plan's Goal, serves both goals, and adds `Touched by plan N: #id — what
  and why` to that plan.

## The project map

`docs/sprintbias/project.md` is the one place that answers "how do I know what I
need to know": stack, code layout, commands, sources of truth (glossary / lexicon /
taxonomy, architecture, decisions, API, security, instruction files), and
environments (local, CI, deploy). It holds pointers, never copies, so agents jump
straight to the right file instead of searching.

`./sprint.sh profile` builds or refreshes it (`show`, `check`: `help profile`).
Every AI command orients from the map; `work` and `plan start` say when it has
drifted. Before a task is worked, the gate writes its **`## Grounding`**: the sources
it relies on, the glossary terms it uses (word for word), and its conflicts — task vs
a source, source vs source, task vs code, or task vs SprintBias — each settled before
work. A conflict that changes scope or what done means becomes a question for you.
`work` grounds what the gate did not and reports every conflict.

**Known edges.** `promote --reject <id> "class: case"` also adds one line to the
map's `## Known edges`; every agent is told to test the ones its change touches.
`profile check` skips the section's paths and asks for a prune past ~15 lines.

**Docs stay in step.** When work changes what a source of truth describes, the
worker updates it in the same task — glossary, architecture, API, README,
commands. Governing sources (security policy, decision records, `CLAUDE.md` /
`AGENTS.md`) and out-of-scope gaps go under `## Completed` → `### Doc follow-ups`
instead; `work` and `promote` collect them into one backlog task, *Bring project
docs in step with landed work*. `polish` flags a change that left a source wrong
with neither.

## Installing

Website: [sprintbias.com](https://sprintbias.com) · Source: [github.com/jnun/sprintbias](https://github.com/jnun/sprintbias)

`./setup.sh` (from a clone or the curl one-liner) installs SprintBias **into your
project**: pick Claude Code `[Enter]` or Grok Build `[g]`, and you get
`GETSTARTED.md`, short `CLAUDE.md`/`AGENTS.md` pointers, this manual, `.gitignore`
entries, a `README.md` pointer, and empty starter folders.

**Your files stay yours.** Files SprintBias owns carry a version marker and are only
overwritten when ours is older; anything else gets a small pointer block or is
skipped. `More options?` offers Prepend/Overwrite, GitHub sync and
Cursor/Windsurf/Copilot dotfiles.

**Update** by re-running `./setup.sh` (or `curl -fsSL
https://raw.githubusercontent.com/jnun/sprintbias/main/install.sh | bash`). Your ID
counters and work stay; retired framework files are cleaned.

---

*Plain folders and markdown. That's it.*
