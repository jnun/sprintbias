# Command Matrix

How every SprintBias command earns its name.

A command that won't sit in one cell is the wrong command — fix the command,
not the matrix. This file is the **target-state spec**. When live behavior and
this document disagree, this document wins: file a backlog task, don't edit
the target back down.

**Maintain with the code.** Every time you **create or change a command**
(dispatch, registry, help, script, or family placement), update this matrix in
the same change. New command → new catalog row (and family if needed). Behavior
or flag change that affects what the command *does* → update the row. Retirement
→ move the old name into **Retired names**. Skip only pure internals that never
surface as a user-facing command.

**This guide lives in `docs/guides/` (repo-only, not mirrored into `src/`).**
Provider edges (tools, models, emit) live in
[provider-reality.md](./provider-reality.md).

---

## The loop this surface exists to run

```
chat  →  plan start  →  work  →  polish
 │            │            │         │
 human      commit      automate   quality
 decides    to next/    the queue  after
```

Human judgment injects at **chat**. Logic and automation carry **plan**,
**work**, and **polish**. `loop` is the same spine on autopilot
(`plan start` refill + `work` drain). Everything else is mint, look, or keep.

---

## Two primitives

Prefix		Primitive	Meaning				Output
new*		Create		Mint a scaffold.	A new file, unfilled.
bare verb	Act			Run a process.		Work moved, or read.

`new` is a reserved namespace. Only creators wear it. Everything else is a
verb that does something. Family names **are** the archetype commands —
no abstract layer to translate.

---

## Five act families

Family	Interaction				Touches
chat	Human in the loop, Q&A	One item, one folder, or the board
plan	Decisive compose		The sprint (`next/` is the sprint)
work	Autonomous transform	Tasks in motion
look	Read-only				Surfaces state, no mutation
keep	Housekeeping			Integrity, config, sync, deps

**`chat` shapes. `plan` acts. `work` does.**

- A plan is scaffolded by `newplan` (optional members: ids, ranges, `parent:N`).
  When members are pre-bound, fast-lane next step is `plan start` → `work`
  without full `chat plan` ceremony. Otherwise author with **`chat plan`**, then
  decisive plan verbs: `plan think` (optional critique), `plan start` (gate +
  commit to `next/`; `--commit-only` skips the AI gate).
- There is no bare conversational `plan`. Authoring lives in `chat` so one
  engine owns every human-in-the-loop walk.
- The unit of work stays a **task** (file under `docs/tasks/`, created by
  `newtask`). `work` is the *verb* that executes READY tasks — not a rename of
  the noun.

---

## Target catalog

Only target names. No archaeology in this table.

### Create — `new*`

Command		Mints
newidea [name]	Idea to refine (no name = AI Q&A; with name = template)
newfeature [name]	Feature spec (no name = AI Q&A; with name = template)
newtask		Task (the unit of work)
newplan		Plan (named list of task IDs; trailing ids / ranges / parent:N bind members)
newbug		Bug report (inbox)
newtest		Test loop for a deployed thing

### chat — shape with a human

Command		Does
chat \<id\>		Define / refine / split one task in conversation
chat \<folder\>		Sweep backlog / next / blocked — verdict-first sort
chat plan [id]		Author or refine a plan (plan id; bare = pick one)
chat bugs		Sweep bug inbox → convert or kill
chat			Menu that includes newtask, newplan, chat folder, chat plan (plan id; bare = pick one), chat bugs (bare = work through oldest to newest or until stopped)

One conversational engine. Target chooses depth; the method is always
Probe → Ground → Recommend → Open the floor. Decisions land in the durable
artifact, never only in the chat.

### plan — compose the sprint

Command		Does
plan think [id]	Automated dual-persona critique of a plan
plan start [id]	Gate every member and commit into `next/` (no hard size cap; warn over 10; latches STARTED)
plan done [id]	Retire — delete the plan once every member is in `done/`

`next/` **is** the sprint. A plan file never moves; only member tasks do. A plan
file carries its own `**Status:** DRAFT | READY | STARTED` — STARTED is a
one-way latch set by `plan start` (members committed to `next/`), not a mirror
of where members currently sit. Retirement is deletion via `plan done`, never a
stored DONE status.

### work — autonomous transform

Command		Does
work			Execute all READY tasks in next/ → review/
work \<id\>		Work ONE task by number; auto-gate into next/ if out of frame, else re-run
work count N	Execute at most N READY tasks (replaces the old bare-number cap)
work --model \<id\>	Pin the model for this run only (also chat / gate / polish)
loop			Autopilot: plan start refill + work drain
gate [folder]	READY-gate next/ (default), or quality report on another folder
settle [id]	Accept (Suggestion: …) open questions; demote READY+openQ out of next/
split \<path\>	One-shot: one large task → atomic children (no conversation)
polish …		Post-work quality: sweep review/, deep-judge a task (id/file), or --code
			(sweep takes work's --parallel/--fast/--jobs N to fan judges out)
promote [id]	Test-gated close: run each review/ task's **Tests**, all green → done/

Happy path: `plan start` → `work`. `plan start` already gates on commit, so
`gate` is off-spine — re-gate after edits, or report on backlog/doing/blocked.
`loop --refill` starts the next READY plan when next/ empties; no separate
gate step on that spine.

`polish` is the one post-work quality surface (sweep / deep-judge / code fix).
Argument shape selects the mode; do not re-split it into sibling commands. A
bare number is read id-first (a number that names an existing task targets that
task, uniform with `work`/`chat`); only a number matching no task is a sweep
limit.

**Completion path — two gates, one lifecycle.** The same dependency edge gates
both ends of a task's life:

- **`Depends on` gates `work`.** A task does not *run* until every prerequisite
  reaches `review/` or `done/`. `work` holds a dependent until then.
- **`Tests` gates `promote`.** A task does not *close* until the suite scripts
  named in its **Tests** field all pass **and** its `Depends on` prerequisites
  are already closed. `promote` is the one automated `review/ → done/` move; a
  task with `Tests: none` waits for human sign-off.

`promote` closes in dependency order: a `review/` task whose `Depends on`
prerequisite is not yet in `review/`/`done/` is *held* (not moved), named with
its stage, and released automatically once that prerequisite closes — a
dependent never lands in `done/` ahead of the work it needs, and a chain closes
over successive `promote` runs. `validate` mirrors this on the close side with a
report-only **Tests**-field pass: a path that is a typo, missing, out-of-tree,
or non-runnable is named with its task id, so a broken **Tests** path is loud,
never a silent never-promote.

When a plan's every member reaches `done/`, `promote` names it for retirement
via `plan done` (which then deletes the plan file). See
`docs/guides/running-tests.md` for the suite ladder.

### look — read, don't mutate

Command		Does
status			Board counts, blocked/ (needs decision), in-progress, features, bugs
search \<kw\>		Find tasks by keyword
learn [name]	Watch the flow run — catalog (no name) or play a sandboxed demo by name
align			Feature ↔ task alignment
context			Project summary for an AI session

`learn` is read-only theater: a demo writes nothing, moves no task files, and
makes no network calls, so it earns the look family. It is **not on the spine** —
watching a demo teaches the chat → plan start → work loop; it never runs it.

`status` stays a noun on purpose — universal CLI habit (`git status`), zero
translation cost. The rest are short verbs or plain nouns that read as
actions when typed.

### keep — housekeep

Command		Does
profile			Create or update project conventions (interactive)
profile show	Print profile, no AI
sync			Push task changes to GitHub
validate		Integrity: IDs, edges, help/docs/commands surface
cleanup			Clear stale scratch files
deps			Scan package ecosystems; file one backlog task on upgrades/advisories
model			Show / list / set effective AI model per role (no AI; config only)
model show		Print CLI, tier, and effective model per role with source
model list		Models the current provider offers (Grok: `grok models`; Claude: known aliases)
model set KEY VALUE	Write `MODEL_DEFAULT` or `MODEL_<ROLE>` into config
config			Interactive: set AI provider + default model in config (no AI)

### Global launcher flags — not commands

Leading flags on `./sprint.sh` (before the command). They apply for **this run
only** and do **not** rewrite `docs/sprintbias/config`. Durable default stays
setup / config; env `SPRINTBIAS_CLI` / `SPRINTBIAS_PROVIDER` is the same override
without the short flag.

Flag			Does
-c / --claude	Claude Code for this run (`CLI=claude`, `PROVIDER=claude-code`)
-g / --grok		Grok Build for this run (`CLI=grok`, `PROVIDER=grok-build`)

```bash
./sprint.sh -g work              # Grok Build this run
./sprint.sh -c chat 12           # Claude Code this run
./sprint.sh --grok loop --refill
sprint -g work                   # same, with the shell alias
```

Placement: **flag, not a command** (see rules below). Do not invent sibling
commands like `work-grok` or a top-level `provider` verb for one-shot switches.
Last leading flag wins if both are passed. Flags after the command name are
command-local, not these.

### Per-command flags — `--help` and `--demo`

Trailing flags on any command (**after** the command name). Command-local, not
the leading launcher flags above.

Flag		Does
--help / -h	Explain the command — usage, flags, behavior (text explains)
--demo		Play the walkthrough mapped to this command (theater shows)

`--help` explains; `--demo` shows. The pair is symmetric and data-driven: an
optional 5th field on `docs/sprintbias/help/_registry` maps a command to a demo
name. When that field is set, the command's `--help` output ends with a one-line
pointer (`Demo:  ./sprint.sh <cmd> --demo`) and `<cmd> --demo` plays that demo
through the same engine as `learn`. Unmapped commands carry **no** pointer (no
dead affordance) and soft-fail on a bare `--demo` — a one-line "no demo, try
`learn`" that exits clean. `learn` owns the catalog and plays by name, so it is
exempt from the `--demo` intercept.

`--demo` is a **flag on a command**, not a command itself and not a leading
launcher flag. Never mint `demo <cmd>`.

---

## Placement rules

If the command...				Then it is...
mints a scaffold file			new* — nothing else wears new
puts a human in the loop		chat (or a chat target)
assembles or commits next/		plan (think or start)
runs or transforms tasks alone	work family
reads without mutating			look
touches integrity/config/sync	keep
overlaps a sibling's job		roll into the sibling — don't add a command
needs two families				split into two commands
fits no family					it's a flag, not a command
carries a profession word		retire the word (`audit`, `excellence`, `review-` as command names)

Registry groups, help sections, and this matrix use the **same six labels**:
`create · chat · plan · work · look · keep`. No parallel taxonomy
(pipeline / workflow / maint / …). Global provider switches stay **launcher
flags** (`-c` / `-g`), not a seventh family.

**Demos are data, not a family.** Placement for the `learn` / `--demo` pair:

If the demo...					Then reach it with...
teaches a host command			registry 5th-field map + `<cmd> --demo`
has no host command				`learn <name>` only (the catalog)

Never mint `demo <cmd>` and never add a demo family — `--demo` is a per-command
flag and `learn` is the one look-family catalog.

---

## Retired names

Dispatch labels below are **deleted outright** — no runtime redirect. Typing a
retired name falls through to generic help. Listed so none return, and so each
behavior's home stays findable.

Old name		Successor				Why it's gone
talk			chat					chat is mutual; talk is one-way / TTS-adjacent
tasks			work					work is the execute verb; task stays the noun
define			gate					honest name for the READY-gate; matches "plan start gates"
checkfeatures	align					verb; feature↔task alignment
ai-context		context					plain word, same job
audit-deps		deps					drop the auditor persona; still files one dep task
sprint (cmd)	plan					"sprint" is a concept — next/ IS the sprint
triage			chat · chat \<folder\>	folded into the conversational engine
find			chat \<id\> · work		stress-test absorbed by chat
review-sprint	plan think				plain plan sub-form
newepic			newplan					"epic" jargon → plan grouping
audit			gate					task-quality is the gate
excellence		polish					post-work quality unifies in polish
review-code		polish --code			code-diff mode of polish

A retired name never returns as a command.

---

## What this is not

- **Not a rename of the task noun.** Files stay under `docs/tasks/`. Creators
  stay `newtask`. Lifecycle folders stay `backlog → next → doing → review →
  done` (+ `blocked`). Only the *execute command* is `work`.
- **Not a second conversational surface.** If it needs a human turn-by-turn,
  it is `chat` or it is wrong.
- **Not a profession kit.** No command teaches the agent to "be an auditor,"
  "run excellence," or "do a code review." Quality verbs are `gate` and
  `polish`; dependency scanning is `deps`.

---

## Live surface lag

When `./sprint.sh help` still shows old labels, the matrix is ahead on purpose.
Close the gap with backlog work driven by the retired-names table — one rename
pass per row if needed, registry + dispatch + help + manual + AI guidance
together so the validator stays green.
