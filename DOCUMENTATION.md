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

Follow these five and you will not get lost:

1. **Change status by moving the file** between folders. Do not edit a status field.
2. **Create work with `./sprint.sh`** (`newtask`, `newbug`, …). Never write a task
   file or pick an ID by hand — IDs are assigned for you.
3. **Treat `docs/sprintbias/` as read-only.** Your work lives everywhere else under
   `docs/`. (The one exception: `docs/sprintbias/DOC_STATE.md`.)
4. **Old dates in `review/` or `done/` mean finished, not stale.** Never redo them.
5. **You define, execute, and perfect. The human approves, commits, and ships.**
   Run `git commit` or `./sprint.sh sync` only when the human asks in this conversation.

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
│   ├── guides/          # framework guides (doc-style, sprint alias, chat)
│   ├── help/            # per-command help pages
│   └── DOC_STATE.md     # ID counters + state (the one framework file you own)
├── ideas/               # rough concepts being refined
├── features/            # fully defined specs
├── tasks/{backlog,next,doing,blocked,review,done}/   # work — folder = status
├── plans/               # named lists of task IDs (an index, not a stage)
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
./sprint.sh plan think 5        # improve the plan + align its member tasks
./sprint.sh plan start 5        # gate + commit members into next/ (latches STARTED)
./sprint.sh plan check 5        # read-only health report (no AI, no moves)
./sprint.sh plan polish 5       # excellence-judge the plan's finished work
./sprint.sh plan done 5         # retire the plan once every member is in done/

# work — execute and finish
./sprint.sh work [N]            # run READY tasks (work N = one by id; count N caps how many)
./sprint.sh loop                # autopilot: plan start refill, then drain next/
./sprint.sh gate [folder]       # off-spine quality gate: re-gate next/ or report elsewhere
./sprint.sh settle [id]         # accept "Suggestion:" answers; demote next/ still needing a human
./sprint.sh split <path>        # split a large task into subtasks
./sprint.sh polish [id]         # sweep review/, deep-judge a task, or --code audit
./sprint.sh promote [id]        # close review/ → done/ (runs Tests; --audit = AI acceptance judge)

# look — read-only
./sprint.sh status              # project status
./sprint.sh search <keyword>    # search tasks
./sprint.sh learn [demo]        # watch the flow run (no name lists demos)
./sprint.sh align               # feature alignment
./sprint.sh context             # AI context summary

# keep — config & maintenance
./sprint.sh profile             # create/update project profile (show = print only)
./sprint.sh sync                # push task changes to GitHub
./sprint.sh validate            # integrity-check IDs + deps (--docs, --commands guard the catalog)
./sprint.sh cleanup             # clean stale docs/tmp/ files
./sprint.sh model show          # see/list/set the AI model per role
./sprint.sh config              # set provider + default model (interactive)
./sprint.sh deps                # file a task auditing outdated/vulnerable deps
```

> Tired of `./sprint.sh`? Add `alias sprint='./sprint.sh'` to your shell rc.
> `setup.sh` offers this; see `docs/sprintbias/guides/sprint_command.md`.

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
