<!-- SprintBias v0.0.77 -->
# SprintBias

Project management as plain markdown files in folders. No database, no app — the
filesystem *is* the state, so an AI agent reads `ls` and knows everything.

> If this manual is named `SPRINTDOCUMENTATION.md`, that is still this file — the
> installer used that name because you already owned a `DOCUMENTATION.md`. Your
> `CLAUDE.md` / `AGENTS.md` pointers target whichever name landed.

## How it works

Three facts explain the whole system:

1. **A task is a markdown file** describing an outcome in plain language.
2. **Its folder is its status.** Move the file to change status.
3. **The AI runs the pipeline:** `chat` defines work, `work` executes it, `polish`
   perfects it. You approve.

You drive all of it through one command — `./sprint.sh`. Run `./sprint.sh help` for
the full list and `./sprint.sh status` to see where work stands. Everything below is detail.

## Rules for AI agents

Follow these seven and you will not get lost:

1. **Change status by moving the file** between folders. Do not edit a status field.
2. **Create work with `./sprint.sh`** (`newtask`, `newbug`, …). Never write a task
   file or pick an ID by hand — IDs are assigned for you.
3. **Treat `docs/sprintbias/` as read-only.** Your work lives everywhere else under
   `docs/`. (The exceptions: `docs/sprintbias/DOC_STATE.md`, and `project.md`,
   which `./sprint.sh profile` writes.)
4. **Old dates in `review/` or `done/` mean finished, not stale.** Never redo them.
5. **You define, execute, and perfect. The human approves, commits, and ships.**
   Run `git commit` or `./sprint.sh sync` only when the human asks in this conversation.
6. **Raise decisions one at a time.** Whenever the human has two or more calls
   to make, write them as a `- [ ]` checklist in `docs/tmp/<subject>_discuss.md`.
   Then loop: take the first unchecked line, ask with numbered options (best
   practice marked `(suggested)`), do the updates the answer calls for, note
   it, check it off, re-read, next. Settle clear-cut questions yourself.
7. **Start from the project map.** `docs/sprintbias/project.md` says where the
   project's knowledge lives. Ground a task before working it — its `## Grounding`
   names the sources, the terms, and the conflicts. Sources of truth are the
   authority: name a conflict instead of working around it.

## Why folders and plain text

An agent reads context, reasons, converses, and decides. Encoding state as folder
location and work as markdown plays straight to those strengths — no schema to parse,
no jargon to translate, minimal tokens burned. That bias is the name.

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
| `blocked/` | a **decision or question** must be answered *on this task* first |
| `review/` | done, awaiting your approval |
| `done/` | complete |

## Distinctions that trip up agents

- **blocked ≠ dependent.** *Blocked* = an open question about *this* task (lives in
  `blocked/`; fix by answering, then re-gate). *Dependent* = clear but waiting on
  another task via `Depends on` (stays where it is — no move). A chain of dependent
  tasks has zero blocked tasks.
- **plan ≠ folder.** A plan (`docs/plans/N-name.md`) is one file listing related
  task IDs. Members never move into it — each flows through its own lifecycle folder.
  A plan carries `DRAFT → READY → STARTED`; delete it (`plan done`) once every member
  is in `done/`.
- **COMPLETE ≠ done/.** COMPLETE is a verdict ("already built in the code") and routes
  to `review/` for your sign-off — never a silent jump to `done/`. `done/` is where
  *you* (or `promote`) move an approved task.

**Task fields** (metadata, not status):

- `Depends on` — prerequisite IDs. Gates `plan start` (entry), `work` (run), and
  `promote` (close), so work happens and closes in dependency order.
- `Dependents` — reverse edge; graph info only, does not block anything.
- `Plan` — which plan this belongs to (`none` or an id).
- `Crew` — which crew member the task is routed to or held by (`none` or a name).
  In `doing/`, it is the claim: that member owns the task. See **Crew**.
- `Tests` — suite scripts under `docs/tests/` that prove success. `promote` runs them;
  all green → `done/`. `none` means a human signs off.

## The pipeline

Work flows one direction: **backlog → next → doing → review → done**. Follow one
task the whole way:

```bash
./sprint.sh newtask "Add a login button"   # → backlog/12-add-login.md
./sprint.sh chat 12                         # define it, then commit it to the sprint → next/
./sprint.sh work                            # the AI builds it → review/
./sprint.sh promote                         # Tests pass → done/ (no Tests: you approve the move)
```

Tasks enter `next/` **only through the gate** — `chat`'s commit-to-sprint, `plan
start`, or `gate` — never a raw `mv`. That gate is what keeps `next/` trustworthy.

For grouped work, use the spine **`chat → plan start → work → polish`**: gather tasks
into a plan, `plan start` commits them all at once, `loop` runs it on autopilot.

## Commands

One line each. For flags and detail: `./sprint.sh help <cmd>` (or `<cmd> --help`).
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
./sprint.sh plan think 5        # improve the plan + align its tasks; your calls → chat, one at a time
./sprint.sh plan start 5        # gate + commit members into next/ (latches STARTED)
./sprint.sh plan check 5        # read-only health report (no AI, no moves)
./sprint.sh plan polish 5       # excellence-judge the plan's finished work
./sprint.sh plan done 5         # retire the plan once every member is in done/

# work — execute and finish
./sprint.sh work [N]            # run READY tasks (work N = one by id; count N caps how many)
./sprint.sh loop                # autopilot: plan start refill, then drain next/
./sprint.sh gate [folder]       # off-spine quality gate: re-gate next/ or report elsewhere
./sprint.sh settle [id]         # accept "Suggestion:" answers; demote next/ still needing a human
./sprint.sh crew [name] [ID]    # list the crew · start a session as one member (add <name> "<role>")
./sprint.sh split <path>        # split a large task into subtasks
./sprint.sh polish [id]         # sweep review/, deep-judge a task, or --code audit
./sprint.sh promote [id]        # close review/ → done/ (runs Tests; --audit = AI acceptance judge)

# look — read-only
./sprint.sh status              # project status
./sprint.sh search <keyword>    # search tasks
./sprint.sh learn [demo]        # watch the flow run (no name lists demos)
./sprint.sh align               # feature alignment

# keep — config & maintenance
./sprint.sh profile             # build/refresh the project map (show = print, check = drift, no AI)
./sprint.sh sync                # push task changes to GitHub
./sprint.sh validate            # integrity-check IDs + deps (--docs, --commands guard the catalog)
./sprint.sh cleanup             # clean stale docs/tmp/ files
./sprint.sh model show          # see/list/set the AI model per role
./sprint.sh config              # set provider + default model (interactive)
./sprint.sh deps                # file a task auditing outdated/vulnerable deps
```

> Tired of `./sprint.sh`? Add `alias sprint='./sprint.sh'` to your shell rc.
> `setup.sh` offers this; see `docs/sprintbias/guides/sprint_command.md`.

## Crew

A crew is several AI sessions working the same project at once, each with a name
and a job: a lead that keeps everyone rowing, plus members such as a builder, a
bug fixer or a production operator. Each member is one file, `docs/crew/<name>.md`,
saying its role, what it reads first, what it may touch and how it reports.

```bash
./sprint.sh crew add lead "Keeps everyone rowing: holds the plan, routes tasks" --lead
./sprint.sh crew add fixer "Finds and fixes bugs"
./sprint.sh crew lead plan:5      # start the lead on plan 5 (session named "lead")
./sprint.sh crew fixer 42         # start the fixer on task 42 (session named "fixer")
./sprint.sh crew                  # who is on the crew and what each holds
```

Start each member in its own terminal. The rules every member starts with:

1. **The files are the shared state.** A task's `Crew` field routes it to a member.
   Moving the task into `doing/` and setting `Crew` to your own name is the claim;
   a task in `doing/` held by someone else is theirs.
2. **Stay in your lane.** Each member touches only what its file allows, so two
   sessions never fight over the same work (for example, only the operator holds
   production credentials).
3. **The lead coordinates.** A member file with `**Lead**: yes` runs the plan: it
   holds the central idea of the solution in the plan's `## Crew` section, routes
   tasks, catches collisions across members and unblocks. It leaves product code
   to the others.
4. **Messages nudge, files record.** When the AI CLI can message other sessions
   (Claude Code: `ListAgents`, `SendMessage`), members reach each other by crew name.
   Anything that must last goes in a task or plan file.

`work` and `loop` stay the headless path; a crew is for interactive work you want
to steer. Watch one run with `./sprint.sh crew --demo`. The full guide, including
running a crew on a shared dev server, is `docs/sprintbias/guides/crew.md`.

## Learn more

This manual is the baseline. Three places go further, each for one kind of question:

| Question | Where |
|----------|-------|
| How do I do X with a command? | `./sprint.sh help <cmd>` (pages in `docs/sprintbias/help/`) |
| What does it look like in motion? | `./sprint.sh learn` or `<cmd> --demo` (demos in `docs/sprintbias/learning/`) |
| How does a whole workflow fit together? | `docs/sprintbias/guides/` |

Guides:

| Guide | Covers |
|-------|--------|
| `use_chat.md` | How `chat` runs inside an agent, in a terminal, or as one pass |
| `crew.md` | Running named sessions with a lead, claiming, and a crew on a shared dev server |
| `sprint_command.md` | Typing `sprint` instead of `./sprint.sh` |
| `doc-style.md` | Writing docs and tasks that cost the reader the least |

## Moving tasks

Folder location **is** status. Always move with:

```bash
git mv SRC DEST || mv SRC DEST
```

`git mv` first (keeps history); plain `mv` when it fails (new, untracked file).
Completing the move updates status — nothing else to edit. `git commit` and
`./sprint.sh sync` stay yours to run; `work` never commits on its own.

## Creating work

| What | Command |
|------|---------|
| Idea (rough, needs refining) | `./sprint.sh newidea "..."` |
| Feature (defined capability) | `./sprint.sh newfeature "..."` |
| Task (work item) | `./sprint.sh newtask "..."` |
| Plan (group of tasks) | `./sprint.sh newplan "Name" 12 13 14` |
| Plan for a finished plan's follow-ups | `./sprint.sh newplan "Name" from:24` → `plan start <id>` → `work` |
| Plan for the whole backlog | `./sprint.sh newplan "Name" backlog` → `plan start <id>` → `work` |
| Bug | `./sprint.sh newbug "..."` |
| Test (validate a live thing) | `./sprint.sh newtest "Name"` |

Each command advances the ID counter in `docs/sprintbias/DOC_STATE.md` and drops a
templated file (`docs/<type>/.TEMPLATE-*`) — fill in the sections. Naming:
tasks/bugs `ID-description.md`; features/ideas `name.md`.

## Provider and model

Your CLI, provider, and per-role models live in `docs/sprintbias/config`.

```bash
./sprint.sh config              # pick provider (Claude Code / Grok Build) + default model
./sprint.sh model set work claude-opus-4-8   # pin a model for one role
./sprint.sh -g work             # one run on Grok (-c / --claude for Claude Code)
```

For a personal override that never ships or commits, put the same `KEY=VALUE` lines
in `docs/sprintbias/config.local` (gitignored). Precedence, highest first:
env var → per-run flag → `config.local` → `config` → tier default.

## The project map

`docs/sprintbias/project.md` is the one place that answers "how do I know what I
need to know": stack, code layout, commands, sources of truth (glossary / lexicon /
taxonomy, architecture, decisions, API, security, instruction files), and
environments (local, CI, deploy). It holds pointers, never copies, so agents jump
straight to the right file instead of searching.

```bash
./sprint.sh profile             # build or refresh the map with AI; you confirm it
./sprint.sh profile show        # print it
./sprint.sh profile check       # no AI: listed paths exist, nothing it tracks changed
```

Every AI command orients from the map. `work` and `plan start` run `profile check`
first and print one line when the map has drifted. Before a task is worked, the
gate writes its **`## Grounding`**: the sources it relies on, the glossary terms it
uses (copied word for word), and its conflicts — task vs a source, source vs
source, task vs code, or task vs SprintBias itself — each settled before work.
A conflict that changes scope or what done means becomes a question for you.
`work` fills in grounding the gate did not write and lists every noted conflict
in its end-of-run report.

**Docs stay in step.** When work changes what a source of truth describes, the
worker updates it in the same task — glossary, architecture, API, README,
commands. Governing sources (security policy, decision records, `CLAUDE.md` /
`AGENTS.md`) and out-of-scope gaps go under `## Completed` → `### Doc follow-ups`
instead. `work` and `promote` collect every follow-up from `review/` and `done/`
into one backlog task, *Bring project docs in step with landed work*, each line
tagged with the task it came from and filed once. `polish` flags a change that
left a source wrong with neither.

## Installing

Website: [sprintbias.com](https://sprintbias.com) · Source: [github.com/jnun/sprintbias](https://github.com/jnun/sprintbias)

From a clone (or the curl one-liner), `./setup.sh` installs SprintBias **into your
project**. One question — Claude Code `[Enter]` or Grok Build `[g]` — then the same
scaffold either way: `GETSTARTED.md`, short `CLAUDE.md`/`AGENTS.md` pointers, this
manual, `.gitignore` entries, a `README.md` pointer, and empty starter folders.

**Your files stay yours.** Files SprintBias owns carry a version marker and are only
overwritten when ours is present and older. Files without our marker are yours — we
prepend a small pointer block or skip; `More options?` offers Prepend/Overwrite plus
GitHub sync and Cursor/Windsurf/Copilot dotfiles.

**Update** by re-running `./setup.sh` (or `curl -fsSL
https://raw.githubusercontent.com/jnun/sprintbias/main/install.sh | bash`). Your ID
counters are preserved; retired framework files are cleaned; your work is untouched.

---

*Plain folders and markdown. That's it.*
