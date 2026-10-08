# Changelog

All notable changes to SprintBias are recorded here, newest first. Versions
follow `src/VERSION` (`X.Y.Z`). This file is repo-only — it is not distributed
into user installs.

Add entries under `## Unreleased` as you finish user-facing work; `./ship.sh`
renames that section to the new version and date on each bump.

## Unreleased

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

### Changed

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
