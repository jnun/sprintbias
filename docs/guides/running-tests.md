# Running tests (platform suite)

**Audience:** maintainers and AI agents working on *SprintBias itself*.

**Point an agent here** when you want a full confidence pass after a change —
not when a user of an installed project wants product “test loops”
(`./sprint.sh newtest`).

This guide lives in `docs/guides/` (repo-only, not mirrored into `src/`). It
documents how *we* verify the product before ship.

---

## Two different “tests” folders

| Path | What it is | Who uses it |
|------|------------|-------------|
| `docs/tests/test-*.sh` | **Platform suite** — bash unit/smoke scripts that exercise SprintBias | Maintainers / AI on this repo |
| `docs/tests/*.md` (via `newtest`) | **Product test loops** — user-authored claims about *their* shipped app | End users of an install |
| `docs/tests/.TEMPLATE-test.md` | Template for product test loops | Ships via `./ship.sh` |

**Never confuse them.** The platform suite is `test-*.sh` and `smoke-*.sh`.
Product markdown under `docs/tests/` is not run by the harness.

### Task header: **Tests** (close path)

Tasks may name suite scripts that prove their success criteria:

```markdown
**Tests**: docs/tests/test-plan-lifecycle.sh
```

| | |
|--|--|
| Field name | **Tests** (write this). Legacy **Proven by** is still read. |
| Values | `none` (human sign-off) or one/more paths under `docs/tests/` |
| Close | `./sprint.sh promote` runs every listed script; all green → `review/ → done/` |
| Not for | Product `newtest` loops, guides, or hopeful paths that do not exist yet |

**Docs** = read while building. **Tests** = run to close.

**When an agent sets **Tests****

1. Only if a real `docs/tests/*.sh` already proves the success criteria.
2. After creating/extending such a script in the same change, update the field.
3. Otherwise leave `none` — never invent a path to “look complete.”

---

## Three tiers (cheap → expensive)

Run from the **repo root**. Prefer the cheapest tier that covers your change;
run the full ladder before shipping a plan.

| Tier | Cost | Network | What it proves | How to run |
|------|------|---------|----------------|------------|
| **0 — Integrity** | seconds | no | Task graph + command surfaces agree | `./sprint.sh validate` and `./sprint.sh validate --commands` |
| **1 — Unit** | ~1–5 min | no | All `docs/tests/test-*.sh` (includes offline matrix smoke) | `bash docs/tests/run-all.sh` |
| **2 — Emit + Grok spine** | +~1 min | mostly no | Unit **plus** `smoke-grok-spine.sh` | `bash docs/tests/run-all.sh --emit` |
| **3 — Live / dual-provider** | 30–60 min | yes | Real install + spine on Claude and Grok | See [dual-provider-smoke.md](./dual-provider-smoke.md) |

**Default for an AI after code edits:** tier 0 + tier 1.  
**Default before “this plan is done”:** tier 0 + 1 + 2, then tier 3 if the change touches providers, setup, or the spine.

---

## Quick start (agent recipe)

```bash
# From the SprintBias repo root — always.
cd "$(git rev-parse --show-toplevel)"

# 0) Integrity (task IDs, Depends on / Blocks, optional command catalog)
./sprint.sh validate
./sprint.sh validate --commands    # if you touched help, registry, dispatch, or DOCUMENTATION.md

# 1) Offline unit suite (all docs/tests/test-*.sh)
bash docs/tests/run-all.sh

# 2) Emit / matrix smoke (still offline)
bash docs/tests/run-all.sh --emit

# 3) Only when shipping provider/setup/spine work:
#    follow docs/guides/dual-provider-smoke.md
#    (requires ./ship.sh first, then fresh setup.sh into /tmp)
```

**Pass rule:** every script exits 0 and prints a `Results: N passed, 0 failed`
(or equivalent). `run-all.sh` exits non-zero if any script fails.

**Stop rule:** if tier 1 fails, fix before spending budget on live smoke.

---

## Tier 0 — Integrity (not under docs/tests/)

These are product commands that also gate the *dev* board:

```bash
./sprint.sh validate              # task files: IDs, deps tokens, duplicates
./sprint.sh validate --commands   # registry ↔ sprint.sh dispatch ↔ help ↔ manual
./sprint.sh validate --docs       # if you changed script flags / help text
./sprint.sh status                # sanity: counts and plan rollup
```

After dependency-heavy edits, also:

```bash
./sprint.sh chat plan             # or chat-sprint walk — surfaces one-way edges
```

---

## Tier 1 — Unit suite

### Run all

```bash
bash docs/tests/run-all.sh
# same as: bash docs/tests/run-all.sh --unit
```

### Run one

```bash
bash docs/tests/test-create-task.sh
bash docs/tests/test-no-stale-refs.sh
```

### Contract every unit script follows

- Bash 3.2-safe (`set -euo pipefail` or documented variant)
- `PASS` / `FAIL` counters
- Temp trees under `mktemp -d` + `trap` cleanup
- **No live AI** — stub CLIs or pure helpers only
- Final line: `Results: N passed, M failed` and `exit 1` if `FAIL > 0`

### Catalog (what each script covers)

| Script | Under test | Notes |
|--------|------------|--------|
| `test-sprint.sh` | `sprint.sh` router | help, unknown cmds, status shape |
| `test-create-task.sh` | `create-task.sh` | IDs, DOC_STATE, template |
| `test-create-bug.sh` | `create-bug.sh` | same pattern |
| `test-create-feature.sh` | `create-feature.sh` | same pattern |
| `test-create-idea.sh` | `create-idea.sh` | same pattern |
| `test-plan-lifecycle.sh` | plan scripts | draft / start / done shapes |
| `test-validate-tasks.sh` | `validate-tasks.sh` | ID integrity, dep tokens |
| `test-check-alignment.sh` | `check-alignment.sh` | feature ↔ task links |
| `test-context.sh` | `context.sh` | AI context summary |
| `test-profile.sh` | `profile.sh` | non-AI show/help paths |
| `test-cleanup-tmp.sh` | `cleanup-tmp.sh` | stale scratch files |
| `test-setup-detection.sh` | `setup.sh` helpers | install detection + gitignore merge (pure block) **and** the scaffold/conflict machinery: `classify_target`, deferral policy, `apply_conflict`/`apply_deferred_conflicts`, gitignore prepend/replace, never-clobber, manual-name routing (both fenced blocks, extracted) |
| `test-no-stale-refs.sh` | rename guards | retired names must not linger in shipped surfaces |
| `test-grok-provider.sh` | `lib.sh` + grok profile | tier, emit detect, tool map — **not** live TUI |
| `test-audit-code.sh` | `polish.sh --code` | stub CLI |
| `test-audit-excellence.sh` | `polish.sh` deep-judge | stub CLI |
| `test-tasks-excellence.sh` | `work.sh --excellence` | stub CLI; queue does not re-pick enhancements |
| `test-command-matrix-smoke.sh` | full command surface in emit | offline matrix walk; see tier 2 notes |

`run-all.sh --unit` discovers every `docs/tests/test-*.sh` (including the
command-matrix emit smoke). It does **not** run `smoke-*.sh` until `--emit`.

---

## Tier 2 — Emit + Grok spine smoke

```bash
bash docs/tests/run-all.sh --emit
# or piece-wise:
bash docs/tests/test-command-matrix-smoke.sh   # also in unit discovery
bash docs/tests/smoke-grok-spine.sh            # only in --emit
```

| Script | Proves |
|--------|--------|
| `test-command-matrix-smoke.sh` | Every matrix command accepts `-g`/`-c`; AI paths show provider banner in **emit** mode; non-AI paths do not. **No network.** (Included in default unit run because it is `test-*.sh`.) |
| `smoke-grok-spine.sh` | Claude-proven spine under Grok flags; fake `grok` for argv; optional live `grok models` if logged in (skipped otherwise) |

Emit mode (`SPRINTBIAS_MODE=emit`) prints prompts for the surrounding agent instead
of shelling out — that is why these smokes stay agent-safe.

Cross-read: [command-matrix.md](./command-matrix.md).

---

## Tier 3 — Live dual-provider smoke

**Do not invent a half protocol.** Follow:

**[dual-provider-smoke.md](./dual-provider-smoke.md)**

Hard rules from that guide:

1. **`./ship.sh` before smoke** — setup installs from `src/`, not live `docs/`.
2. Fresh `/tmp` projects per provider (Claude leg + Grok leg).
3. Real `claude` / `grok` on PATH for execution steps.
4. Budget ~30–60 minutes; human or long-running agent with network.

Related: `docs/tests/smoke-grok-spine.sh` is a *lighter* Grok check; it does not
replace the full dual-provider ritual.

---

## Fixtures (stress data, not a green/red suite yet)

### Dependency glitch matrix

```bash
bash docs/tests/fixtures/dep-glitch-matrix/seed.sh
bash docs/tests/fixtures/dep-glitch-matrix/check-inventory.sh
```

| Path | Role |
|------|------|
| `docs/tests/fixtures/dep-glitch-matrix/MATRIX.md` | Full catalog of fold/split/backlog/doing/blocked cases |
| `seed.sh` | Builds synthetic board (IDs **9000–9099**) |
| `check-inventory.sh` | Classifies canaries with current `lib.sh`; flags **false-green** missing deps |
| `board/` | Committed snapshot |

Use this when changing **Depends on / Blocks / work holds / plan membership**.
It is the stress dataset for Plan 15; hard pass/fail asserts land with #332.

**Never** seed 9000-range tasks into the live `docs/tasks/` board by accident —
always operate under `fixtures/dep-glitch-matrix/board/` or a `/tmp` copy.

---

## Full product stress ladder (AI checklist)

Copy this block into a session when the user says “stress test everything” or
“before ship”:

```text
STRESS LADDER — SprintBias platform
[ ] 1. pwd is repo root; git status understood (do not commit unless asked)
[ ] 2. ./sprint.sh validate
[ ] 3. ./sprint.sh validate --commands   (if commands/help/manual touched)
[ ] 4. bash docs/tests/run-all.sh          # unit
[ ] 5. bash docs/tests/run-all.sh --emit   # matrix + grok spine smoke
[ ] 6. If deps/work/graph touched:
       bash docs/tests/fixtures/dep-glitch-matrix/check-inventory.sh
[ ] 7. Dogfood the changed command(s) in this repo:
       ./sprint.sh help <cmd>
       ./sprint.sh <cmd> …   # emit is fine inside an agent session
[ ] 8. If setup / provider / ship path touched:
       ./ship.sh --dry-run && ./ship.sh
       # then dual-provider-smoke.md (fresh /tmp installs)
[ ] 9. Report: which tiers ran, which scripts failed, what was skipped and why
```

### What “dogfood” means here

This repo **uses** SprintBias to manage itself. After unit green:

- Prefer `./sprint.sh -g …` or `./sprint.sh -c …` for a one-shot provider flip
  (does not rewrite config).
- Prefer **emit** inside an agent session so nested CLIs are not spawned.
- Do **not** treat dogfood task moves as a substitute for `docs/tests/`.

### Fresh-install check (always before release)

```bash
./ship.sh --dry-run
./ship.sh
mkdir -p /tmp/test-sprint-$$
SPRINT_TARGET=/tmp/test-sprint-$$ ./setup.sh   # or interactive
# smoke: ./sprint.sh status  (from the install)
rm -rf /tmp/test-sprint-$$
```

If setup fails, it is a **release blocker**.

---

## Writing a new platform test

1. Add `docs/tests/test-<area>.sh` following an existing create/validate test.
2. Use a temp project tree; copy only `lib.sh`, `cli/`, and scripts you need.
3. Stub AI with a fake CLI on `PATH` or force emit — never require network in tier 1.
4. End with `Results: …` and non-zero exit on failure.
5. Re-run `bash docs/tests/run-all.sh` — discovery picks up `test-*.sh` automatically.
6. Put long protocols in `docs/guides/` (like dual-provider-smoke); keep scripts assertable.

Product test loops for end users remain `./sprint.sh newtest "…"`.

---

## What ships vs what stays here

| Artifact | Ships to users? |
|----------|-----------------|
| `docs/tests/test-*.sh`, `run-all.sh`, `smoke-*.sh` | **No** (dev-only; not in `ship.sh` tree mirror) |
| `docs/tests/.TEMPLATE-test.md` | **Yes** (product test-loop template) |
| `docs/guides/running-tests.md` (this file) | **No** |
| `docs/guides/dual-provider-smoke.md` | **No** |
| `docs/sprintbias/**` | **Yes** (the product) |

---

## Related docs

| Doc | When to open it |
|-----|-----------------|
| [CONTRIBUTING.md](../../CONTRIBUTING.md) | Edit → test → ship workflow |
| [command-matrix.md](./command-matrix.md) | What every command must mean |
| [dual-provider-smoke.md](./dual-provider-smoke.md) | Tier 3 live ritual |
| [dep-glitch-matrix/MATRIX.md](../tests/fixtures/dep-glitch-matrix/MATRIX.md) | Dependency stress cases |
| `DOCUMENTATION.md` | User-facing manual (not this suite) |
| Task **302** | Formalize run-all tiers if you extend the harness |

---

## Failures: how to report

When reporting back to a human, use this shape:

```text
Tier 1: FAIL
  test-no-stale-refs.sh — Results: 40 passed, 2 failed
  … first failing assertion …
Tier 2: SKIPPED (tier 1 red)
Tier 3: SKIPPED
```

Do not mark a plan or task done while tier 1 is red. Do not run tier 3 to
“hope” tier 1 flakes pass — fix the unit first.
