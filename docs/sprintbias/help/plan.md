Decisive plan verbs — critique, commit, and retire. Authoring is `chat plan`.

**plan think [id]** — think a plan into alignment. Two collaborating leaders
(Platform Architect + Experience Officer) evaluate the plan through three
lenses — best practice, elegant design / coding standards, antifragility — then
**apply** the improved plan to the plan file (Goal, Why, members, order) and
**rewrite the Problem/Success of each unstarted member** (backlog/next) to fit
it, appending a ## Plan Think note per member. A finished member
(doing/review/done) is trusted as completed-as-defined and never reopened; if
the plan needs more from it, a new delta task is filed with `newtask` (starting
from the current code state) and added to the plan. Plan-level analysis lands in
docs/tmp/plan-think-<id>.md. It never runs `plan start` and never moves task
files — commitment stays with `plan start`. Bare `plan think` picks a plan.

**plan start [id] [--commit-only]** — gate, then commit that plan's members
into `next/` (the sprint). Promotes **every workable** listed member — no hard
cap on plan size. A soft warning prints when the plan has more than 10 members;
the start still continues and gates/promotes all workable ones. `next/` IS the
sprint, so workability is decided BEFORE a member is runnable: each backlog
member is run through the shared workability gate (the same review
`./sprint.sh gate` runs), and only what grades READY sits in `next/` stamped
for `work`. Location-aware:

  backlog/  → gate in place, then:
                READY   → stamp + move to next/
                BLOCKED → move to blocked/ (needs decision/clarification; never visits next/)
                COMPLETE → move to review/ (work already in codebase; not done/)
  next/     → stamped READY → leave (idempotent)
              not READY     → demote to backlog/ (self-heal a bad/accidental mv),
                              then gate with the rest unless --commit-only
  blocked/  → stop; run chat <id>, then re-run plan start
  doing|review|done → skip with a notice
  missing   → hard error (dangling member)

**Dependencies gate entry to `next/`.** Before promote (gated or `--commit-only`),
each member's **Depends on** is audited. A task is workable for the sprint only
when every prerequisite is already in `next/` or `doing/`, finished
(`review/` / `done/`), or co-promoted in this same start. A dependency still in
`backlog/` or `blocked/` that is not itself being promoted makes the dependent
**unworkable** — it stays in `backlog/` (or is demoted from `next/`) with a hold
message naming the missing dep. Definition clarity alone is not enough; bring
the dep into the sprint first (add it to this plan, start its plan, or finish
it). Co-members that depend on each other may enter `next/` together.

A member already sitting in `blocked/` stops the start with a `chat <id>`
pointer — `blocked/` means a decision or clarification is still needed, so the
start does not silently re-spend AI budget re-gating work someone already
flagged. Resolve it (`chat <id>`), re-queue it to `backlog/`, then re-run
`plan start`.

`--commit-only` skips the AI gate and does the pure, deterministic
`backlog → next` move — for power users, tests, and non-AI environments.
Members are NOT AI-vetted, but the dependency workability filter still runs.
Unstamped `next/` members are still demoted to `backlog/` (healed), but not
re-promoted without a gate.

Bare `plan start` lists plans (id, name, DRAFT/READY/STARTED) and asks which to
start. Plan-file **Status:** READY is separate from the task-level READY the
gate stamps on each member:

  READY    → proceed
  STARTED  → check members (heal misplaced next/, gate remaining; no prompt)
  DRAFT/…  → interactive: auto-mark READY (explicit start is the confirm),
             then gate members; non-interactive (e.g. loop --refill) requires
             **Status:** READY

A successful start latches the plan file to `**Status:** STARTED` — a one-way
switch. STARTED means "members committed to `next/`," not "members currently in
`next/`"; the status does not flip back as members flow on through
`doing/review/done`. A STARTED plan is not re-refilled by `loop --refill`
(refill selects READY plans only).

The run ends with a summary — ready → next/, blocked, done counts — and the next
step is `./sprint.sh work`. Lifecycle moves use `git mv SRC DEST || mv SRC DEST`
(git mv first; plain mv finishes when untracked). The developer owns commits.

**plan polish [id] [--force]** — excellence-judge the plan's finished work. Runs
the same deep-judge as `polish <id>` (one shared unit) over every member that has
reached `review/` or `done/` — the plan-scoped equivalent of polishing one task.
Each finished member is judged against a higher bar than "it runs": it never
edits product code and never reopens the task, appends a `## Excellence` section,
and files any enhancements as new `backlog/` tasks. Members still in
`backlog/next/doing/blocked` are skipped with a notice (not finished yet), and a
member already carrying a `## Excellence` section is skipped as already-judged —
`--force` re-judges it. Bare `plan polish` picks a plan. This is the quality pass
for a plan's completed body of work; `plan think` critiques the plan as a unit,
and the reopen sweep / `--code` audit stay on `polish` itself.

**plan done [id]** — retire a finished plan. When every member task is in
`docs/tasks/done/`, deletes the plan file (retirement is deletion, never a
stored DONE status). If any member is still outstanding, it reports what remains
and does nothing. Bare `plan done` picks a plan.

Usage:
  ./sprint.sh plan think  [id]
  ./sprint.sh plan start  [id] [--commit-only]
  ./sprint.sh plan polish [id] [--force]
  ./sprint.sh plan done   [id]
  ./sprint.sh plan              # prints this usage (no auto-planner)

Provider for this run only (AI subcommands; leading flags; no config rewrite):
  ./sprint.sh -g plan think [id]     # Grok Build
  ./sprint.sh -c plan start [id]     # Claude Code

Family order:
  1. ./sprint.sh newplan "…" [ids|parent:N]   # scaffold (+ fast-lane bind)
  2. ./sprint.sh chat plan [id]     # author (skip when members already bound)
  3. ./sprint.sh plan think [id]    # optional: improve plan + align its tasks
  4. ./sprint.sh plan start [id]    # gate members, commit READY → next/ (latches STARTED)
     ./sprint.sh plan start [id] --commit-only   # pure backlog→next, no AI gate
  5. ./sprint.sh work · loop
  6. ./sprint.sh plan polish [id]    # optional: excellence-judge finished members (review/ + done/)
  7. ./sprint.sh plan done [id]      # all members in done/ → delete the plan file

Use default `plan start` when members need the workability gate. Use
`--commit-only` when members are already READY-stamped, for tests, or when AI
is unavailable — the move is deterministic and unvetted.

`loop --refill` runs `plan start` on the next READY plan (lowest id) — the gate
runs as part of the start, so the sprint refills with vetted work. Only
human-authored plans refill the queue.
