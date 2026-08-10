# Plan 15: Dependency integrity and work completion path

**Created**: 2026-08-01
**Updated**: 2026-08-01
**Status:** STARTED

> A plan is a **relational index, not a container.** Member tasks stay in their
> lifecycle folders. Plan `**Status:**` is **DRAFT | READY | STARTED** only —
> never a folder name, never a stored DONE. Author with `chat plan`, optionally
> critique with `./sprint.sh plan think <id>`, then commit with `plan start`.
> STARTED is a **one-way switch** set by `plan start`; it does not change while
> members move through `next/doing/review/done`. When every member is in
> `docs/tasks/done/`, `./sprint.sh plan done <id>` deletes this file. Progress
> of work is where members live, not this Status field.

## Prerequisite

`work` already stage-classifies open prereqs (doing/ resume; backlog/blocked →
`chat <id>`). That is **runtime hold messaging only**. This plan hardens the
**graph and close path** so stress makes the system clearer, not quieter:
headers, reciprocity, fold/split rewrite, plan reverse index, outcome stamps,
and suite **Tests** on the task file.

## Language contract (locked)

Common language first. One name per concept. Read aliases for one compatibility
window; write only the canonical name. No dual live fields.

| Field | Role | Values | Not |
|-------|------|--------|-----|
| **Plan** | Reverse index of plan membership | `none` or plan id (`15`) | Not task-to-task grouping (**Parent**) |
| **Depends on** | What must finish before this starts | `none` or task ids | Not the `blocked/` folder |
| **Dependents** | What waits on this (reverse edge) | `none` or task ids | Not “this task is blocked.” Legacy write: **Blocks** (read-only alias) |
| **Docs** | Guide to read while building | `none` or path(s) | Not proof of done |
| **Tests** | Suite script(s) that prove success criteria so `promote` may close | `none` or `docs/tests/…sh` paths (all must pass) | Not product test *loops* (`newtest` markdown). Legacy write: **Proven by** (read-only alias) |

**Lexicon**

- **Dependent (on hold)** — sequencing; waits on **Depends on** until prereqs
  reach `review/` or `done/`.
- **Blocked** — this task needs a decision (`blocked/` or **Status: BLOCKED**).
- **Promote** — test-gated hop `review/ → done/`; runs every path in **Tests**.
  Messaging may say “proven green”; the field name is still **Tests**.

**Pairing**

- **Docs** = input while working. **Tests** = proof to close.
- **Depends on** / **Dependents** = two ends of one edge (always reciprocal).
- Plan *file* member list = authority for membership. Task **Plan** = reverse index.

## Antifragile design rules

Stress should leave the board *more* legible, not paper over gaps.

1. **Classify, never silent-green.** A missing prereq id is broken, folded, or
   archived-complete — never “unmet empty” by accident.
2. **Rewrite on mutation.** Fold, split, and retire go through a helper that
   updates **Depends on** and **Dependents**. Agents call the path; they do not
   “remember” edges.
3. **Stamp failure.** Incomplete / failed / blocked routes leave `## Outcome`
   so the next run and every dependent’s hold line can name the reason.
4. **Never auto-lift backlog.** Backlog means not fully vetted. Hold +
   `./sprint.sh chat <id>`.
5. **Migrate on touch.** Old **Blocks** / **Proven by** still read; writers
   emit **Dependents** / **Tests**. No mass rewrite of `done/`.
6. **Proof or human.** Set **Tests** only when a real suite script proves
   success criteria; otherwise `none` and human sign-off in `review/`.
7. **Fixture as memory.** The glitch matrix (IDs 9000–9099) encodes failure
   modes so regressions fail loud.

## Goal

When a task depends on another, the system answers without archaeology:

1. Was the prereq retired or folded into another id?
2. Is it still in backlog (not vetted)?
3. After split/fold, were **Depends on** / **Dependents** rewritten?
4. After a failed work session, can dependents see an **Outcome**?
5. When the work can prove itself, does **Tests** + `promote` close it cleanly —
   and only after its **Depends on** prereqs are themselves closed?

## Why

| Failure mode | Cost if we skip |
|--------------|-----------------|
| Prereq stuck in `doing/` after `## Completed` | Dependents held forever; “disappeared” reading |
| Missing id treated as complete | False green; stale edges look done |
| Fold/split without reverse rewrite | Orphans; one-way findings pile up |
| **Blocks** read as “this is blocked” | Second invented field; broken teachability |
| No **Plan** on the task | Single-file readers lose the plan |
| Failures leave no stamp | Downstream holds have no diagnosis |
| **Proven by** as field name | Process jargon; “Tests” is the common word |

## Themes → members

### A — Header contract

| Task | Delivers |
|------|----------|
| **#327** | Lock headers: **Plan**, **Depends on**, **Dependents**, **Tests**; read aliases **Blocks**, **Proven by**; protocol for when AI sets **Tests** |

### B — Graph machinery

| Task | Delivers |
|------|----------|
| **#328** | lib: classify dep, list dependents, rewrite id A→B, ensure reciprocal edge |
| **#329** | Call sites + AI: fold/split/retire always rewrite; split writes both ends |

### C — Completion path

| Task | Delivers |
|------|----------|
| **#330** | work: missing-id class, `## Outcome` stamps, hold lines name stage + outcome |
| **#331** | Plan membership ↔ task **Plan** reverse index (reconcile on plan start/validate) |
| **#333** | Close path integrated: `promote` honors **Depends on** (dependency-order close), `validate` checks **Tests** integrity, `test-promote.sh` dogfoods the closer |

### D — Lock it in

| Task | Delivers |
|------|----------|
| **#332** | Fixture asserts + DOCUMENTATION/help; **Tests** paths on plan members where suite covers them |

## Execution order

```
327 ─► 328 ─┬─► 329 ──────────────┐
            ├─► 331 ──────────────┤
            └─► 330 ─► 333 ───────┤
                                  ▼
                                 332
```

1. **#327** first — names and **Tests** protocol; everything reads the contract.
2. **#328** — pure helpers (unit-testable, no AI).
3. **#329** and **#331** after #328 (parallel ok).
4. **#330** after #328 (classify); wording from #327.
5. **#333** after #328 + #330 — wires **Depends on** into `promote`, **Tests**
   into `validate`, and dogfoods the closer; the close path becomes one flow.
6. **#332** last — asserts + docs over finished surfaces, #333 included.

## Member tasks

- [x] #327 — Lock task header language Plan Dependents Tests
- [x] #328 — Add shared dependency-graph helpers classify rewrite fold
- [x] #329 — Enforce reciprocal edges and fold-split-retire rewrite protocol
- [x] #330 — Upgrade work completion path outcome stamps and missing-prereq class
- [x] #331 — Sync plan membership bidirectionally onto task Plan field
- [x] #333 — Integrate close path: promote honors Depends on, validate checks Tests, suite proves promote
- [x] #332 — Suite tests and docs for dependency integrity and completion path

## How to run

```bash
./sprint.sh status                 # plan 15 rollup
./sprint.sh work                   # drains READY next/ (respects Depends on)
./sprint.sh promote                # review/ → done/ when **Tests** all green
bash docs/tests/run-all.sh         # platform suite — see docs/guides/running-tests.md
bash docs/tests/fixtures/dep-glitch-matrix/check-inventory.sh
```

## Decisions (locked)

1. **Dependents** is canonical; **Blocks** is read alias only; migrate on touch.
2. **Tests** is canonical; **Proven by** is read alias only; migrate on touch.
   Promote runs every listed `docs/tests/*.sh`; all must pass. Product
   `newtest` markdown loops never go in **Tests**.
3. **Missing id:** classify via helper — not silent complete. Prefer broken or
   folded-into-N unless a safe archived rule applies (knob in #328; policy in #330).
4. **Who rewrites:** lib helper + call sites (split, chat fold, plan reconcile).
   AI guidance states the positive path.
5. **Outcome stamp:**
   ```
   ## Outcome
   **Result**: incomplete | failed | blocked
   **Reason**: …
   **At**: YYYY-MM-DD
   ```
6. **Plan authority:** plan file member list wins; task **Plan** is reverse index;
   reconcile on `plan start` / validate (chat plan may stay plan-file-only).
7. **Multi-plan:** single primary **Plan** id (lowest id); other memberships
   only on plan files.
8. **Two gates, one lifecycle:** **Depends on** gates `work` (a task does not
   *run* until prereqs reach `review/`/`done/`); **Tests** gates `promote` (a
   task does not *close* until its suite scripts pass). `promote` also honors
   **Depends on** — it closes in dependency order, never landing a dependent in
   `done/` while its prereq is still open. Same edge, both ends of the
   lifecycle (#333).
9. **Broken Tests are loud:** `validate` checks every **Tests** path (exists,
   under `docs/tests/`, runnable). A hopeful/typo path is reported, not a silent
   never-promote (#333).

## Out of scope

- New lifecycle stages or renaming `blocked/`.
- Auto-promoting backlog into `next/` without chat/gate.
- Second membership algorithm on the task file.
- Graph UI.
- Mass rewrite of historical `done/` tasks.
- Replacing product test loops with suite scripts (they stay separate).

## Success when

A human or agent opens any task and can follow **Plan**, **Depends on**,
**Dependents**, and **Tests** without inventing fields; every edge is
reciprocal or explained; every missing prereq is classified; every failed
session leaves **Outcome**; `promote` closes only what **Tests** prove and only
after **Depends on** prereqs are closed; `validate` names any broken **Tests**
path; and the glitch matrix suite fails if silent-green returns.

## Synthetic fixture

`docs/tests/fixtures/dep-glitch-matrix/`

- **MATRIX.md** — fold, split, backlog demotion, doing orphans, Outcome,
  cycles, plan drift, umbrella #9080
- **seed.sh** / **board/** — IDs 9000–9099
- **check-inventory.sh** — false-green detector (promote into #332 asserts)

## Related guides

- [running-tests.md](../guides/running-tests.md) — platform suite ladder
- [dual-provider-smoke.md](../guides/dual-provider-smoke.md) — live ship ritual
