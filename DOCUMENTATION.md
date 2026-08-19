<!-- SprintBias v0.0.77 -->
# SprintBias

Project management in markdown files. Folders and plain text.

> If this file is named `SPRINTDOCUMENTATION.md` in your project, it is still
> the SprintBias manual — the installer used that name because you already had
> a `DOCUMENTATION.md` of your own. Pointers in `CLAUDE.md` / `AGENTS.md` target
> whichever filename landed.

## Guiding principles

Every design decision in this system passes through these lenses:

1. **Lean into agent bias.** Shape work around what an AI agent does well —
   read context, reason, converse, decide. Prefer commands and tasks that walk
   with those strengths instead of fighting them.
2. **Minimize context cost.** Every file, command, and help page costs context
   when an agent loads it. Fewer, sharper commands beat many overlapping ones.
   Pruning is a feature.
3. **Name in common language.** Plain words that read the same to people and
   agents (`task`, `chat`, `work`, `plan`, `polish`) beat jargon. Lifecycle
   folders `backlog → next → doing → review` are the affordance. If a term
   needs translating, pick a different term.
4. **Instruct positively.** State the desired path as the rule
   ("Always edit `docs/`, then commit"). Prohibition-shaped rule *lists* hand
   the model a map of forbidden behavior and no map of the work — under
   ambiguity it falls into exactly what was described. Reserve a plain
   "never" for genuine invariants where the wrong action is costly.

When principles conflict: **simple, clean, fast, common language, biased
toward action.**

## Task documents

Task files live in `docs/tasks/*/` and describe outcomes in plain language:
- Explain WHAT should happen so anyone can understand the goal
- Keep implementation details in `docs/guides/` and link to them when needed

## Boundaries

**Framework files (do not edit):**
- `DOCUMENTATION.md` (or `SPRINTDOCUMENTATION.md`, if you already had one)
- `sprint.sh`
- `docs/sprintbias/` (framework scripts, AI instructions) — except `DOC_STATE.md`, your own ID/state file

**Your content (create and edit freely):**
- `docs/ideas/` — rough ideas being refined
- `docs/features/` — fully defined feature specs
- `docs/tasks/` — your tasks
- `docs/plans/` — your plans: named groupings that list task IDs (see below)
- `docs/bugs/` — open bug reports (inbox only; convert or close deletes the file)
- `docs/guides/` — your documentation. Style it per `docs/sprintbias/guides/doc-style.md`; run `docs/sprintbias/scripts/prettydoc.py <file>` to align tables
- `docs/tests/` — your test plans
- `docs/designs/` — design system, files, and references for the project
- `docs/examples/` — code standards and worked examples to follow or mimic
- `docs/data/` — data to manage, store, or build (e.g. scaffolding to preload a database)
- `docs/sprintbias/DOC_STATE.md` — your ID and state tracking (the one file you own inside the framework folder)

## AI Agents

This file governs `docs/`. Read it before modifying any task, bug, or feature.

**Rules:**
1. `docs/` is the active project management system — not source code, not stale
2. Tasks in `review/` and `done/` are completed work — old dates mean done, not abandoned
3. Always read `docs/sprintbias/DOC_STATE.md` before creating tasks (get next ID)
4. Use `./sprint.sh` commands when available — don't create task files manually
5. Move tasks by changing folders — folder location = status.
   Always: `git mv SRC DEST || mv SRC DEST` (see Moving Tasks)

**Folder meanings:**
| Folder | Status |
|--------|--------|
| `backlog/` | Planned, not started |
| `next/` | Queued for current sprint |
| `doing/` | Actively being worked on |
| `blocked/` | Needs a decision or clarification before work can start — not merely waiting on another task |
| `review/` | Done, awaiting approval |
| `done/` | Shipped/complete |

**Lexicon — blocked vs. dependent (do not conflate them):**

| | **Blocked** / `**Status: BLOCKED**` | **Dependent / on hold** |
|---|---|---|
| **Means** | A **decision or clarification** must be made about *this* task before anyone can work it | Fully clear and workable; sequentially waiting on another task |
| **Cause** | Unresolved choice, open question, contradiction, or missing clarification *on this task* | A prerequisite task has not finished yet |
| **Where it lives** | `blocked/` folder | Stays in `next/` (or wherever it was); no folder move |
| **How `work` treats it** | Never runs it (it is not READY in the queue) | Holds it until every `**Depends on**` prerequisite reaches `review/` or `done/`, then releases it |
| **How you fix it** | Answer each open question (`chat <id>`), write the answer as instruction in the task body, delete the question, then re-enter through the gate | Finish the prerequisite — or record the edge if it was missing |

The software analogy: you would not say an app is *blocked by* a Python module. You would say it **depends on** that module and **requires** it to be installed. Same here — a task that lists `**Depends on**: 42` is **dependent** (on hold until 42 lands), not blocked. A whole chain of dependent tasks has *zero* blocked tasks even when only one can start right now.

**Task dependency fields** (graph edges, not lifecycle status):
- **`Depends on`** — prerequisite task IDs that must finish before this one can start.
- **`Dependents`** — the reverse edge: task IDs that wait on *this* one. Graph metadata only — it does **not** put those tasks in `blocked/`, and it does not mean this task is blocked. (Older files may say **Blocks**; readers still accept that alias.)
- **`Plan`** — which `docs/plans/N-…` this task belongs to (`none` or the plan id). Reverse index; the plan file remains the membership list.
- **`Tests`** — suite scripts under `docs/tests/` that prove the success criteria. `./sprint.sh promote` runs them and, all green, moves `review/ → done/`. `none` means a human signs off. Product test loops (`newtest`) are not this field. (Legacy alias: **Proven by**.)

Reserve **blocked** / **BLOCKED** for “a decision or clarification is needed.” For sequencing, say **depends on**, **dependent**, **on hold**, or **waiting on**.

**COMPLETE vs. `done/` — don't conflate them either:**
- **COMPLETE** is a *workability verdict* (gate, plan start, folder sweep, drift check): the work is already present in the codebase. The stamp is `**Status: COMPLETE**` under `## Questions` (or a sweep status line). Routing is to **`review/`** for human approval — never a silent leap into `done/`.
- **Open questions** live under `### Questions for the developer`. Flow: ask → answer → convert the answer into instruction in Problem / Success criteria / Notes → delete the question. READY and promotion into `next/` need a clear list (`None — task is fully defined.`).
- **`docs/tasks/done/`** is a *lifecycle folder*: you (or an explicit move) put the task there after approving review. Folder location is status; COMPLETE is not a folder name and is not written as a plan status.
- The one **automated** `review/ → done/` move is `./sprint.sh promote`: a task with **Tests** naming suite scripts that all run green closes itself; work with `none` stays in `review/` for a human. That is how a plan whose tasks are all suite-backed reaches "every member in `done/`" without hand-moves, ready for `./sprint.sh plan done <id>`.
- **Two gates, one lifecycle.** The same dependency edge gates both ends of a task's life: **`Depends on` gates `work`** (a task does not *run* until every prerequisite reaches `review/`/`done/`), and **`Tests` gates `promote`** (a task does not *close* until its suite scripts pass **and** its prerequisites are already closed). So `promote` closes in dependency order — a `review/` task whose prerequisite is still open is *held* (not moved), named with its stage, and released automatically on a later run once that prerequisite closes. A dependent never lands in `done/` ahead of the work it needs. `./sprint.sh validate` mirrors this on the close side with a report-only **Tests**-field check, so a **Tests** path that is a typo, missing, or outside `docs/tests/` is named loudly instead of stranding a task in `review/` forever.

**Plans vs. the folders above — don't conflate them either:**
- The six folders above are **lifecycle status**: a task lives in exactly one, and moving it *is* how status changes.
- A **plan** (`docs/plans/N-name.md`) is a **relational index, not a status.** It is one file that names a clump of related tasks and lists their IDs. The member tasks are **never moved into it** — each stays in its own lifecycle folder and flows through `backlog → next → …` on its own. A plan is never a lifecycle stage and is never counted or moved as a task; it carries a `**Status:** DRAFT | READY | STARTED` for its own life: `DRAFT` while authoring, `READY` once authored and safe for `plan start` / `loop --refill`, and `STARTED` — a one-way switch set by `plan start` — once its members have been committed to `next/`. Retirement is deletion: when every member sits in `docs/tasks/done/`, `./sprint.sh plan done <id>` removes the file. There is no stored `DONE` and no `NEXT` plan status. Two disambiguations: a plan `**Status:**` is **not** a task folder (`next/` is a lifecycle stage; `STARTED` is a plan field), and plan-level `READY` is **not** the task-level `**Status: READY**` the gate stamps on each member. `docs/plans/` is a sibling of `docs/tasks/`, not a stage inside it.
- Member IDs are references only: moving or working a member task needs no edit to the plan file. Author with `./sprint.sh newplan` / `./sprint.sh chat plan <id>`; optionally critique with `./sprint.sh plan think <id>`; commit into the sprint with `./sprint.sh plan start <id>` (gates **every** listed member — no hard size cap; soft warning over 10 members; READY → `next/`). Single-task promote uses the same gate: `bash docs/sprintbias/scripts/promote-to-sprint.sh <task-file>`. The plan file itself never moves. `./sprint.sh status` rolls up each plan by resolving its members' current folders.

**Do not assume** old file dates mean abandoned. A task from months ago in `done/` is completed history.

---

## Structure

```
docs/
├── sprintbias/             # FRAMEWORK (do not edit)
│   ├── scripts/        # sprint.sh, create-task.sh, etc.
│   ├── ai/             # AI instructions
│   └── DOC_STATE.md    # Project state (ID tracking)
├── ideas/              # Rough ideas being refined
├── features/           # Fully defined feature specs
├── tasks/              # Your work items
│   ├── backlog/        # Planned
│   ├── next/           # Sprint queue
│   ├── doing/          # In progress
│   ├── blocked/        # Needs decision or clarification (not a dependency wait)
│   ├── review/         # Awaiting approval
│   └── done/           # Complete
├── plans/              # Named groupings that LIST task IDs (relational index, not a stage)
├── bugs/               # Open bug reports (inbox; handled reports are deleted)
├── guides/             # Your documentation
├── tests/              # Your test plans
├── designs/            # Design system, files, references
├── examples/           # Code standards & worked examples to mimic
├── data/               # Data to manage, store, or preload
└── tmp/                # Scratch workspace (gitignored)
```

## Creating Work

| What | When | Command |
|------|------|---------|
| **Idea** | Rough concept, needs refinement | `./sprint.sh newidea "User notifications"` or `./sprint.sh newidea` (AI Q&A) |
| **Feature** | Defined capability to build | `./sprint.sh newfeature "User auth"` or `./sprint.sh newfeature` (AI Q&A) |
| **Task** | Specific work item | `./sprint.sh newtask "Add login button"` |
| **Plan** | Group related tasks under one goal | `./sprint.sh newplan "Checkout revamp" 12 13 14` |
| **Bug** | Something broken | `./sprint.sh newbug "Login fails on mobile"` |
| **Test** | Validate a deployed thing, then route what you learn into new work | `./sprint.sh newtest "Signup converts visitors"` |

Each command creates a file with inline guidance. Fill in the sections, then commit.

**IDs are assigned for you.** `newtask` (and `newbug`, `newidea`, `newfeature`,
`newplan`) takes the next sequential number from `DOC_STATE.md`, names the file,
and advances the counter — you never pick or edit a task number by hand. That is
also why the ID is not something to track inside a task's body: the filename
carries it, its lifecycle folder carries status, and git history carries the
rest. Always mint work with these commands rather than creating files manually,
so the numbering stays consistent.

## Commands

Happy path (spine): **`chat → plan start → work → polish`**. `loop` runs that spine on autopilot. `gate` and `split` are off-spine; `polish` is after work. The task *noun* (`docs/tasks/`, `newtask`) stays; the execute *verb* is `work`.

Help groups: **create · chat · plan · work · look · keep**.

> Tired of typing `./sprint.sh`? Add `alias sprint='./sprint.sh'` to your shell
> rc to use `sprint <command>` from a project root (`sprint -g work`,
> `sprint -c chat 12`). `setup.sh` offers this on install; see
> `docs/sprintbias/guides/sprint_command.md` for details and a subdirectory-aware
> variant. Run `./sprint.sh` or `bash sprint.sh` — do not force `sh`/`zsh` on
> the script (any interactive shell is fine as the launcher).

```bash
# Creating work
./sprint.sh newidea "My rough idea"   # Create idea (quick template)
./sprint.sh newidea                   # Create idea (AI Q&A — eight phases)
./sprint.sh newfeature "Name"         # Create feature (quick)
./sprint.sh newfeature                # Create feature (AI Q&A)
./sprint.sh newtask "Description"     # Create task
./sprint.sh newplan "Name" [ids]      # Create a plan — a named list of task IDs
./sprint.sh newbug "Description"      # Report a bug
./sprint.sh newtest "Name"            # Create a test loop to validate a deployed thing

# Create a plan (author intent — group related tasks under one goal)
./sprint.sh newplan "Name" [ids]      # 1. Scaffold the plan file (Status: DRAFT)
./sprint.sh chat plan [id]            # 2. Author it in conversation — reads backlog/ read-only,
                                      #    records member IDs + goal, flips DRAFT → READY on confirm.
                                      #    (chat backlog mutates task files; chat plan only records IDs.)
./sprint.sh plan think [id]           # 3. Optional dual-persona critique of the grouping
./sprint.sh plan start [id]           # 4. Commit the plan's members into next/ — latches Status: STARTED
./sprint.sh plan done [id]            # 5. Retire: when every member is in done/, delete the plan file

# Chat & Work (AI-powered — emit inside Claude/Grok/Cursor sessions, or exec via CLI)
# Per-run provider (leading flags; does not rewrite docs/sprintbias/config):
./sprint.sh -g work                   # This run: Grok Build  (-c / --claude for Claude Code)
./sprint.sh --claude chat 12          # This run: Claude Code (same as -c)
./sprint.sh profile [show]            # Create/update project profile (show: print only, no AI)
./sprint.sh chat [target] [--model]   # id: task · folder: sweep · plan [id]: author a plan · bugs: inbox · nothing: sprint health
./sprint.sh work [N] [count N] [--fast] [--model] # Execute READY tasks from next/ — `work N` works one task by id; `count N` caps how many run (--force skips the gate; --audit --excellence chain quality audits)
./sprint.sh loop [--refill] [--retry] # Autopilot — plan start (gates as it commits) then work, drain the queue
./sprint.sh gate [folder] [limit] [--model] # Off-spine quality gate: re-gate next/ (--force) or report on backlog/doing/blocked
./sprint.sh settle [id] [--dry-run]   # Accept (Suggestion: …) open questions — fold into Notes, clear list; demote next/ that still need a human
./sprint.sh split <path>              # Split a large task into subtasks
./sprint.sh polish [limit] [--rounds N] [--model] # Sweep review/: reopen tasks worth another pass
./sprint.sh polish <id|file>          # Deep-judge one finished task (by id or path); file enhancements to backlog/
./sprint.sh polish --code <id|file>   # Code-diff audit (fixer/verifier); may fix issues inline
./sprint.sh promote [id] [--dry-run]  # Test-gated close: run each review/ task's **Tests**, all green → done/
./sprint.sh deps                      # File a backlog task auditing outdated/vulnerable deps

# Look (read-only — surface state, no mutation)
./sprint.sh status                    # View project status
./sprint.sh align                     # Analyze feature alignment
./sprint.sh context                   # Generate AI context summary
./sprint.sh search <keyword>          # Search tasks by keyword
./sprint.sh learn [demo]              # Watch the flow run (no name lists them; example = 20 seconds)

# Keep — sync
./sprint.sh sync [--all]              # Push task changes to GitHub

# Keep — maintenance
./sprint.sh validate [--fix] [--dry-run]  # Integrity-check task IDs + deps (--docs: help/ flag drift; --commands: catalog completeness)
./sprint.sh cleanup [--delete|--force|--all]  # Clean stale files from docs/tmp/
./sprint.sh config                    # Interactive: set AI provider + default model (no AI)
./sprint.sh model show/list/set [k v] # See/list/set the AI model per role (no AI)
                                      #   pin one run: work/chat/gate/polish --model <id>
./sprint.sh help                      # Show all commands
```

## Moving Tasks

Folder location **is** status. Change status by moving the file between
lifecycle folders — not by editing a status field on the task.

**Always move with this exact pattern (agents and humans):**

```bash
git mv SRC DEST || mv SRC DEST
```

1. Run `git mv` first — preserves history when the file is already tracked.
2. When `git mv` fails — usual for new tasks not yet committed — finish that
   **same** move with plain `mv` in the same step, then continue the workflow.
3. Leave `git add` / `git commit` to the developer unless they asked you to
   commit. Completing the move is enough to update status.

Lifecycle path:

```bash
git mv docs/tasks/backlog/ID-name.md docs/tasks/next/    || mv docs/tasks/backlog/ID-name.md docs/tasks/next/     # Queue
git mv docs/tasks/next/ID-name.md docs/tasks/doing/      || mv docs/tasks/next/ID-name.md docs/tasks/doing/       # Start
git mv docs/tasks/doing/ID-name.md docs/tasks/blocked/   || mv docs/tasks/doing/ID-name.md docs/tasks/blocked/    # Needs decision/clarification
git mv docs/tasks/blocked/ID-name.md docs/tasks/next/    || mv docs/tasks/blocked/ID-name.md docs/tasks/next/     # Re-queue (via gate)
git mv docs/tasks/doing/ID-name.md docs/tasks/review/    || mv docs/tasks/doing/ID-name.md docs/tasks/review/     # Submit
git mv docs/tasks/review/ID-name.md docs/tasks/done/     || mv docs/tasks/review/ID-name.md docs/tasks/done/      # Complete
```

Scripts use the same rule via `move_file` in `docs/sprintbias/lib.sh`.

## Naming

| Type | Format | Example |
|------|--------|---------|
| Task | `ID-description.md` | `12-fix-auth-error.md` |
| Bug | `ID-description.md` | `3-login-fails.md` |
| Feature/Idea | `name.md` | `user-authentication.md` |

IDs come from `docs/sprintbias/DOC_STATE.md` (sprint_TASK_ID for tasks, sprint_BUG_ID for bugs).

## Key Concepts

**Ideas** = Rough concepts being refined. Start here when unclear.
**Features** = Fully defined specs. What capabilities exist.
**Tasks** = Work items. Move through folders as status changes.
**Plans** = Named groupings that list task IDs. A relational index over tasks, not a status or container — the tasks stay in their own folders.
**DOC_STATE.md** = Source of truth for IDs (`docs/sprintbias/DOC_STATE.md`: `sprint_TASK_ID`, `sprint_BUG_ID`, `sprint_PLAN_ID`).

## Ideas Workflow

When you have a rough idea but haven't thought it through:

```bash
./sprint.sh newidea "User notifications"
```

This creates `docs/ideas/user-notifications.md` with a guided refinement process:
1. **Phase 1:** Define the problem (who has it, why it matters)
2. **Phase 2:** Write in plain English (no jargon)
3. **Phase 3:** List what it does (concrete capabilities)
4. **Phase 4:** Surface open questions

Work through it manually, or ask an AI agent to guide you.

## Templates

Use templates in each folder:
- `docs/ideas/.TEMPLATE-idea.md`
- `docs/tasks/.TEMPLATE-task.md`
- `docs/plans/.TEMPLATE-plan.md`
- `docs/features/.TEMPLATE-feature.md`
- `docs/bugs/.TEMPLATE-bug.md`
- `docs/tests/.TEMPLATE-test.md`

## Choosing your AI provider and model

Your provider and per-command models live in `docs/sprintbias/config`
(`CLI=`, `PROVIDER=`, `MODEL_DEFAULT=`, `MODEL_<ROLE>=`). The quickest way to
set them is the interactive wizard:

```bash
./sprint.sh config     # pick provider (Claude Code / Grok Build) + default model
```

You can also edit the file directly or use `./sprint.sh model set <role>
<model>` for a single command. These choices are semi-permanent: they persist
across updates until you change them.

**Pin a specific model** (e.g. an older, steadier release) instead of the
floating tier default. On Claude Code the empty default resolves to the `opus`
alias, which the CLI expands to the *latest* Opus; set an explicit id to hold a
version:

```bash
./sprint.sh model set default claude-opus-4-8   # every command
./sprint.sh model set work claude-opus-4-8       # just `work`
./sprint.sh model show                           # see the effective model per role
```

### Local config overlay (`config.local`)

For a personal, semi-permanent override that **never ships and is never
committed**, create `docs/sprintbias/config.local` — same `KEY=VALUE` format as
`config`. Any key there wins over `config`; setting a key empty (`KEY=`) clears
`config`'s value locally. It is gitignored, so your pin never lands in the repo
or (in the SprintBias source tree) in the distribution.

```bash
# docs/sprintbias/config.local
CLI=grok                       # use Grok for your runs
MODEL_DEFAULT=claude-opus-4-8  # pin a steadier model for yourself
```

Precedence, highest first: environment variable
(`SPRINTBIAS_MODEL_<ROLE>` / `SPRINTBIAS_CLI` …) → per-run flag
(`--model <id>`, `-c` / `-g`) → `config.local` → `config` → tier default. Use
env vars or per-run flags for a single shell or invocation; use `config.local`
for a machine-local default that sticks.

## Installing SprintBias

Website: [sprintbias.com](https://sprintbias.com) · Source: [github.com/jnun/sprintbias](https://github.com/jnun/sprintbias)

From a clone of this repo (or the one-liner installer), `./setup.sh` installs
SprintBias **into your project** — not into this repository.

### Two doors

One question at the start:

| Choice | Runtime |
|--------|---------|
| **[Enter]** | Claude Code (`CLI=claude`, `PROVIDER=claude-code`) |
| **[g]** | Grok Build (`CLI=grok`, `PROVIDER=grok-build`) |

Both doors run the **same** file scaffold. The only difference is the AI CLI
written into `docs/sprintbias/config`. Change it later by editing that file or
using `./sprint.sh -c` / `-g` for a single run.

### Silent scaffold (Easy Button)

On the default path (accept defaults after the door), setup asks **no**
AI-file questions. It ensures, in order:

1. `GETSTARTED.md` (this quick start)
2. `CLAUDE.md` and `AGENTS.md` (short pointers at this manual)
3. This manual as `DOCUMENTATION.md` — or as **`SPRINTDOCUMENTATION.md`** if
   you already own a non-SprintBias `DOCUMENTATION.md`
4. `.gitignore` entries SprintBias needs
5. `README.md` — created with a one-line pointer at this manual when you have
   no README; when you already own one, our small block is prepended above your
   text

Missing files are created. Files we already installed are upgraded when our
version marker is older. A re-run at the **same** version is a no-op on those
files.

### Your files stay yours

Scaffold files we fully own carry a version stamp
(`<!-- SprintBias vX.Y.Z -->` in Markdown, `# SprintBias vX.Y.Z` in
`.gitignore`). **We only overwrite whole files we can prove are ours** (marker
present and older). If a file exists without our marker, it is yours: we
prepend our small block or skip — never blind-clobber on the default path.
Under `More options?`, conflicted pointer files offer **Prepend** (Enter) or
**Overwrite** (`o`); Overwrite is the only deliberate path that replaces a
user-owned file.

A `README.md` you already own is deferred the same way `CLAUDE.md` and
`AGENTS.md` are: the default path silently prepends our pointer block above
your text, and `More options?` offers **Prepend** or **Overwrite** for it.

### More options?

After the batch: `More options? [y/N]` (Enter = No). Yes can include:

- Per-file Prepend / Overwrite for user-owned scaffold files (when any)
- **GitHub Issues sync** (workflows + issue/PR templates)
- **Add all AI instructions** (Cursor / Windsurf / Copilot dotfiles)

Those stay opt-in so the first run stays one or two keystrokes.

### Updating an install

Re-run setup from the SprintBias repo (or the curl installer). Same path is
how you upgrade framework files **and** how you turn on anything still behind
`More options?`.

```bash
cd /path/to/sprintbias
git pull
./setup.sh
# Enter your project path when prompted
```

Or from your project:

```bash
curl -fsSL https://raw.githubusercontent.com/jnun/sprintbias/main/install.sh | bash
```

Your `DOC_STATE.md` counters (task IDs, bug IDs, plan IDs) are preserved, and
lifted if files on disk already use a higher ID. Retired framework files from
an earlier docs system (old launcher, old framework folder, undotted templates)
are removed; your tasks, features, bugs, and ideas stay.

---

*Plain folders and markdown. That's it.*
