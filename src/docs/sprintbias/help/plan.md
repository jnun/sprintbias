Decisive plan verbs — critique, commit, and retire. Authoring is `chat plan`.
`chat plan` also creates and edits tasks and wires dependencies across plans;
with fast on it can run `plan start` and `work` and build a missing piece
itself (see `help chat`).

**plan think [id] [--model <id>]** — think a plan into alignment. Two
collaborating leaders (Platform Architect + Experience Officer) evaluate the
plan through three lenses — best practice, elegant design / coding standards,
antifragility. Before rewriting anything it **reality-checks each unstarted
member against the code**: is the problem real, is it already solved, and does
the work serve the plan's Goal? Each gets a verdict — KEEP, TRIM (scope creep cut
in place), or DONE ALREADY / NOT REAL / OFF GOAL (taken out of the plan, with
file:line evidence; the task file stays). It then **applies** the improved plan to the plan file (Goal, Why,
members, order) and **rewrites the Problem/Done when of each unstarted member**
(backlog/next) to fit it, appending a ## Plan Think note per member. A finished
member (doing/review/done) is trusted as completed-as-defined and never
reopened; if the plan needs more from it, a new delta task is filed with
`newtask` (starting from the current code state) and added to the plan.
Plan-level analysis lands in docs/tmp/plan-think-<id>.md. It decides and applies
every finding with a reasonable pick and lists each call under `## Decided` in
the plan file (`- Decided: X, because Y`; change one with
`./sprint.sh newtask "<the change you want>"`). Only a question whose answer
changes the plan's goal is held, not applied, in docs/tmp/plan-<id>_discuss.md.
When the pass finishes it opens `chat plan <id>` (on a terminal; otherwise it
prints that command), which raises those one at a time with a suggested option
and acts on each pick. It
never runs `plan start` and never moves task files — commitment stays with
`plan start`.
Bare `plan think` picks a plan.

**plan start [id] [--commit-only] [--model <id>]** — gate, then commit that
plan's members into `next/` (the sprint). Promotes **every workable** listed
member — no hard cap on plan size. A soft warning prints when the plan has more
than 10 members; the start still continues and gates/promotes all workable ones.
`next/` IS the sprint, so workability is decided BEFORE a member is runnable:
each backlog member is run through the shared workability gate (the same review
`./sprint.sh gate` runs), and only what grades READY sits in `next/` stamped
for `work`. Location-aware:

  backlog/  → gate in place, then:
                READY   → stamp + move to next/
                BLOCKED → move to blocked/ (cannot start; never visits next/)
                COMPLETE → move to review/ (work already in codebase; not done/)
  next/     → stamped READY → leave (idempotent)
              not READY     → demote to backlog/ (self-heal a bad/accidental mv),
                              then gate with the rest unless --commit-only
  blocked/  → gate with the rest: READY → next/; still BLOCKED → stays, listed
              with ./sprint.sh chat <id> (--commit-only leaves it in place)
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

A member sitting in `blocked/` is gated with the others, so one blocked
member never stops the plan. The gate takes any suggested answers; a member
that can start now joins `next/`, and one that still cannot (no reasonable
reading, or access only you hold) stays in `blocked/` and the summary names its
command: `./sprint.sh chat <id>`.

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
step is `./sprint.sh work`. When the plan or any member lists `## Signoff
(human)` items, the start also makes the plan's **human test**: one
`**Owner**: human` task in `review/`, listed last in the plan, holding every
person-only check. Agents never work or wait on it; you run it once the plan
lands, and `promote plan:N` refreshes it and turns its failures into fix tasks. Lifecycle moves use `git mv SRC DEST || mv SRC DEST`
(git mv first; plain mv finishes when untracked). The developer owns commits.

**plan check [id]** — read-only plan health report. Pure shell, **no AI, no
moves** — the inverse of `plan start` (gates + moves) and `plan done` (deletes).
It reads the plan and its members and prints one glance at where the plan stands,
changing nothing:

  - **Plan state** — computed from the folders, never stamped into the plan
    file (its **Status:** latch stays DRAFT/READY/STARTED): `STARTED` (work
    open) · `LANDED` (every member landed: in `review/` with a **Proof**: line,
    ready for the full suite and sign-off; the human test, which only you
    run, never holds it) · `SIGNED OFF` (every member and the human test in
    `done/` — the point `plan done` would retire it). `not started` while the
    latch is not STARTED and no member has moved past `next/`.
  - **Counts** — open (`backlog/next/doing/blocked`) · landed (`review/` with
    proof) · signed off (`done/`). Flags name each `review/` member without
    proof (in review, unproven), each held original (`review/` with proof and a
    `**Held**:` fix not yet landed, shown `held: fix #N`) and each open fix task
    (`**Fixes**: #N`); any of them keeps the plan out of LANDED.
  - **Lifecycle** — which folder each member sits in
    (`backlog/next/doing/blocked/review/done`), plus a count rollup so the
    spread is visible at a glance. A member listed in the plan with no task file
    is reported `missing`, not silently dropped.
  - **Definition** — how well-formed each member is: `undefined` (not fully
    defined — placeholder success criteria, open `### Questions for the
    developer`, or sitting in `blocked/`) · `defined` (real success criteria, no
    open questions — and every worked member in `review/`/`done/`, which was
    necessarily defined enough to run) · `in process` (a live `doing/` claim) ·
    `abandoned` (a stale `doing/` claim left with a failure stamp — the state
    `work` reclaims).

Bare `plan check` reports the sole plan, or lists plans to choose from. Use it
any time to see a plan's standing without spending AI budget or moving a file.

**plan polish [id] [--force] [--model <id>]** — excellence-judge the plan's
finished work. Runs the same deep-judge as `polish <id>` (one shared unit) over
every member that has reached `review/` or `done/` — the plan-scoped equivalent
of polishing one task.
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
When tasks were filed from the plan's work (**From plan**: N — reworks, deltas,
put-off items, enhancements), plan done names them and prints the command that
groups them into the next plan: `./sprint.sh newplan "… — follow-ups" from:N`.

Usage:
  ./sprint.sh plan think  [id] [--model <id>]
  ./sprint.sh plan start  [id] [--commit-only] [--model <id>]
  ./sprint.sh plan check  [id]              # read-only health report (no AI, no moves)
  ./sprint.sh plan polish [id] [--force] [--model <id>]
  ./sprint.sh plan done   [id]
  ./sprint.sh plan              # prints this usage (no auto-planner)

Provider for this run only (AI subcommands; leading flags; no config rewrite):
  ./sprint.sh -g plan think [id]     # Grok Build
  ./sprint.sh -c plan start [id]     # Claude Code

Model for this run only: add --model <id> (e.g. ./sprint.sh plan start 23 --model claude-opus-5-5).
Precedence (same as work/chat/gate/polish):
  --model flag / SPRINTBIAS_MODEL_<ROLE> env
    → config MODEL_<ROLE> → config MODEL_DEFAULT → tier default → CLI default
Roles: plan think → PLAN_THINK · plan start → GATE · plan polish → EXCELLENCE.
Persist a pin with: ./sprint.sh model set gate claude-opus-5-5
(or `model set default …`). The short alias `opus` follows Claude's latest;
pin a full id when you want a specific generation.

Family order:
  1. ./sprint.sh newplan "…" [ids|parent:N]   # scaffold (+ fast-lane bind)
  2. ./sprint.sh chat plan [id]     # author (skip when members already bound)
  3. ./sprint.sh plan think [id]    # optional: improve plan + align its tasks
  4. ./sprint.sh plan start [id]    # gate members, commit READY → next/ (latches STARTED)
     ./sprint.sh plan start [id] --commit-only   # pure backlog→next, no AI gate
  5. ./sprint.sh work · loop        # members land in review/ with a proof line
  6. ./sprint.sh plan polish [id]    # optional: excellence-judge finished members (review/ + done/)
  7. ./sprint.sh promote plan:[id]   # LANDED → full suite once, one approval → done/
  8. ./sprint.sh plan done [id]      # all members in done/ → delete the plan file

  Anytime: ./sprint.sh plan check [id]   # read-only "where does this stand?" — no AI, no moves

Use default `plan start` when members need the workability gate. Use
`--commit-only` when members are already READY-stamped, for tests, or when AI
is unavailable — the move is deterministic and unvetted.

`loop --refill` runs `plan start` on the next READY plan (lowest id) — the gate
runs as part of the start, so the sprint refills with vetted work. Only
human-authored plans refill the queue.
