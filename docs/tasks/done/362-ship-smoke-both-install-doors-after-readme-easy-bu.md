# Task 362: Ship smoke both install doors after README Easy Button lands

**Feature**: none
**Created**: 2026-08-10
**Docs**: none
**Plan**: 21
**Depends on**: 359, 361
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 1
**Reworked**: 1

## Problem

Plan 12 closed the core Easy Button, docs landed (#360), and #359 will rewire
README into the same scaffold. Until someone runs a fresh dual-door install
after that rewire, we only know unit helpers pass — not that a user’s first
run still finishes “All Checks Passed” on both Claude and Grok.

Installing clean is only half of a first run. The tree the installer writes
also has to *work* — the commands that need no configured CLI (`model show`,
`newtask`, `status`) must run in the fresh project and resolve the door's own
provider tier. Until those run, `PROVIDER=grok-build` is proven only as a
string in `config`, never as a resolved `grok-4.5` default, which is the one
place a real provider divergence would show up.

## Success criteria

- [x] `./ship.sh` clean (or confirmed no pending docs/sprintbias drift) so
      `setup.sh` installs from current `src/` where relevant.
- [x] Fresh Claude door install into empty `/tmp` dir: **All Checks Passed**;
      GETSTARTED + DOCUMENTATION (or SPRINTDOCUMENTATION) + CLAUDE + AGENTS +
      README carry version markers; `CLI=claude` `PROVIDER=claude-code`.
- [x] Fresh Grok door install: same scaffold; `CLI=grok` `PROVIDER=grok-build`.
- [x] User-owned `DOCUMENTATION.md` branch: manual lands as
      `SPRINTDOCUMENTATION.md`; CLAUDE/AGENTS (and README after #359) point at
      that name.
- [x] User-owned `CLAUDE.md` + existing `README.md`: default path silent-prepends
      (or defers then prepends); re-run at same version is no-op (no double
      marker).
- [x] Notes or Completed records the commands run and pass/fail (audit trail).
- [x] Both fresh trees run the no-CLI spine — `model show`, `newtask`,
      `status` — with real output recorded: `model show` reports the door's own
      `CLI:`/`Provider:` pair, `newtask` creates
      `docs/tasks/backlog/1-smoke-reject-empty-input-on-the-login-form.md`, and
      `status` counts `Backlog: 1`.
- [x] "Compare" is closed with evidence, not inference: the record states which
      models each tree resolves as tier default (Claude vs `grok-4.5`) and
      whether anything beyond the provider tier differed.
- [x] Task and `docs/guides/dual-provider-smoke.md` name the CLI-only remainder
      accurately — `work`/`chat` alone, not the whole spine.

## Notes

Non-interactive: use `SPRINT_TARGET=<dir> ./setup.sh` with the answers piped on
stdin — Enter for Claude / `g` for Grok, then `n` for More options. README
create no longer prompts after #359 (absent → silent create).

Watch the extra confirm: any tree that already has `docs/tasks/`,
`docs/sprintbias/`, or a `DOCUMENTATION.md` sets `UPDATE_MODE` and asks
`Do you want to continue with the update? [Y/n]` (setup.sh:250–259) *before* the
door. The user-owned-DOCUMENTATION branch and every second (re-run) install
therefore need one extra leading Enter in the piped stdin — the two-answer
recipe is only correct for a genuinely empty target.

Record the run in this task and refresh the **Last dry run** table in
`docs/guides/dual-provider-smoke.md`, which is that guide's standing home for
this result.

Order: finish #359, then #361 tests, then this smoke. If smoke fails, fix in
#359/#361 rather than papering over here.

## References

setup.sh
docs/guides/dual-provider-smoke.md
docs/tasks/doing/359-bring-readme-md-into-the-easy-button-install-shape.md
docs/tasks/next/361-add-setup-tests-for-binary-conflict-ux-and-manual.md

## Questions

**Status: READY**

### Already complete

The install half of the smoke is done and recorded (`## Completed`, legs 1–5):
both doors, the `SPRINTDOCUMENTATION.md` branch, silent prepend, and the
same-version re-run all passed at v0.0.81, with the result mirrored into
`docs/guides/dual-provider-smoke.md:187-217` (**Last dry run**) and
`docs/guides/provider-reality.md:210` (Surfaced unknowns). Criteria 1–6 hold.

Preconditions for the rework leg re-verified now:

- `./ship.sh --dry-run` reports `(none — src/ already matches the live tree)`,
  release gates clean, VERSION still **0.0.81** — the recorded smoke version is
  still current, so no re-ship is needed before re-running.
- The rework's premise checks out: `model show` is pure config plumbing —
  `cmd_show` (docs/sprintbias/scripts/model.sh:77-105) reads `SPRINTBIAS_CLI`,
  `sprintbias_ai_tier` (lib.sh:1469-1481, config `PROVIDER` wins), and
  `sprintbias_tier_model` (lib.sh:406-416, `claude-code → opus`,
  `grok-build → grok-4.5`). Nothing launches a CLI, so both trees can run it
  with neither `claude` nor `grok` installed.
- `newtask` and `status` are file-only: `create-task.sh` slugs, allocates an ID,
  writes a file (no AI call anywhere in it); `cmd_status` (sprint.sh:185+) just
  counts lifecycle folders.
- The expected spine output is achievable as written: a fresh install seeds
  `**sprint_TASK_ID**: 0` (setup.sh:399), so the first task is `1`, and
  `sprintbias_slug` (lib.sh:271-281) yields
  `smoke-reject-empty-input-on-the-login-form` (42 chars, under the 50 cap) —
  matching the filename the rework asserts.

Nothing of the offline spine itself exists yet: no `### 6.` subsection in
`## Completed`, no spine rows in the guide's table, and the deferral sentence
still stands at `docs/guides/dual-provider-smoke.md:219-220`.

### Remaining work

- Re-confirm `./ship.sh --dry-run` clean at run time and note the version if it
  has moved off 0.0.81; re-create `/tmp/sb362-claude` and `/tmp/sb362-grok`
  with the recipes already recorded in `## Completed`.
- Run `./sprint.sh model show`, `./sprint.sh newtask "Smoke: reject empty input
  on the login form"`, `./sprint.sh status` in each tree and paste the real
  output into a new `### 6. Offline spine (both doors)` subsection.
- State the compare verdict from that output: Claude tree resolves Claude
  models (`opus`) as tier default, Grok tree resolves `grok-4.5`, and whether
  anything beyond the provider tier diverged. A divergence is a finding for
  #359/#361, not a fix here.
- Correct the CLI attribution: `docs/guides/dual-provider-smoke.md:219-220` and
  the closing lines of this task's `## Completed` should name `work`/`chat` as
  the only CLI-dependent step. Preconditions at `dual-provider-smoke.md:37-39`
  already say this — the two places just have to agree.
- Add spine rows (Claude leg / Grok leg) to the **Last dry run** table in the
  same shape as the existing rows, and extend the
  `docs/guides/provider-reality.md:210` entry so its "no divergence" claim
  rests on the resolved model tier, not on install output alone.
- Remove the throwaway trees when done.

### Questions for the developer

None — task is fully defined.

## Completed

**Smoked 2026-08-10 at VERSION 0.0.81 — PASS on every leg.**

Preconditions checked first: #359 and #361 are both in `review/` (dependencies
satisfied), and `./ship.sh --dry-run` reported
`(none — src/ already matches the live tree)` with release gates clean — so
`setup.sh` installed from the current `src/` and no ship/bump was needed.

All legs non-interactive, run from the repo root, into throwaway `/tmp` trees
(removed afterward). Answer recipe: door choice, then `n` for `More options?`;
a leading blank line where the tree already trips `UPDATE_MODE`.

### 1. Claude door — empty tree

```bash
mkdir -p /tmp/sb362-claude
printf '\nn\n' | SPRINT_TARGET=/tmp/sb362-claude ./setup.sh
```

PASS — `Setup Complete - All Checks Passed!`, 109 files.
`docs/sprintbias/config` → `CLI=claude`, `PROVIDER=claude-code`.
`<!-- SprintBias v0.0.81 -->` present in GETSTARTED.md, DOCUMENTATION.md,
CLAUDE.md, AGENTS.md, README.md (all five).

### 2. Grok door — empty tree

```bash
mkdir -p /tmp/sb362-grok
printf 'g\nn\n' | SPRINT_TARGET=/tmp/sb362-grok ./setup.sh
```

PASS — `All Checks Passed`, 109 files, `✓ Agent: grok (provider tier: grok-build)`.
`CLI=grok`, `PROVIDER=grok-build`. Same five files carry the v0.0.81 marker.
Only difference from leg 1 is the provider pair — no scaffold divergence.

### 3. User-owned `DOCUMENTATION.md`

```bash
printf '# My Project Manual\n...\n' > /tmp/sb362-owndoc/DOCUMENTATION.md
printf '\n\nn\n' | SPRINT_TARGET=/tmp/sb362-owndoc ./setup.sh   # extra Enter: UPDATE_MODE
```

PASS — setup printed
`→ Your DOCUMENTATION.md left in place; installing manual as SPRINTDOCUMENTATION.md`
then `✓ SPRINTDOCUMENTATION.md ensured`; `All Checks Passed`. The user's
`DOCUMENTATION.md` still starts `# My Project Manual` (untouched). Pointers:

- `README.md:2` → ``> **Project documentation** → see [`SPRINTDOCUMENTATION.md`](SPRINTDOCUMENTATION.md) …``
- `CLAUDE.md:2` and `AGENTS.md:2` → ``Read `SPRINTDOCUMENTATION.md` before making any changes.``
- Grep for a bare `DOCUMENTATION.md` reference across those three files: none.
  README is the pointer that regressed before — checked explicitly, correct.

### 4. User-owned `CLAUDE.md` + existing `README.md`, default path

```bash
printf '# My Rules\n...\n'      > /tmp/sb362-prepend/CLAUDE.md
printf '# Cool Project\n...\n'  > /tmp/sb362-prepend/README.md
printf '\nn\n' | SPRINT_TARGET=/tmp/sb362-prepend ./setup.sh
```

PASS — deferred both to `CONFLICTS`
(`→ CLAUDE.md exists (yours) — will prepend after batch`), then silent-prepended
after the `More options? → no`: `✓ Prepended SprintBias pointer to CLAUDE.md`
and `… to README.md`. Both files now carry the marked block above the user's
original content, which is intact.

### 5. Re-run at the same version (idempotence)

```bash
printf '\n\nn\n' | SPRINT_TARGET=/tmp/sb362-prepend ./setup.sh   # extra Enter: UPDATE_MODE
```

PASS — no-op. Setup reported `up to date (v0.0.81)` for GETSTARTED, CLAUDE,
DOCUMENTATION, .gitignore, AGENTS, README and `Preserved docs/sprintbias/config
(up to date)`. md5 of `CLAUDE.md` and `README.md` identical before and after.
Marker counts exactly one pair each in CLAUDE.md, AGENTS.md, README.md — no
double marker.

### Observation (not a defect)

`GETSTARTED.md` carries an opening `<!-- SprintBias v0.0.81 -->` with no
`<!-- end SprintBias -->`. That is correct: it is a wholly SprintBias-owned
file, so there is no user content to close the block against. Only prepend
targets (CLAUDE, AGENTS, README, .gitignore) get the paired wrapper. Recorded
in both guides so a future marker check does not false-positive on it.

### 6. Offline spine (both doors) — rework round 1

**Smoked 2026-08-10 at VERSION 0.0.81 — PASS.** Re-confirmed
`./ship.sh --dry-run` → `(none — src/ already matches the live tree)`, release
gates clean, VERSION still **0.0.81** (no re-ship). Re-created both throwaway
trees with the same recipes as legs 1–2.

Spine commands need no configured CLI. They *do* honor ambient
`SPRINTBIAS_CLI` / `SPRINTBIAS_PROVIDER` env overrides (by design — per-run
override). This smoke ran from a Grok agent session that exports those, so each
command was prefixed with
`env -u SPRINTBIAS_CLI -u SPRINTBIAS_PROVIDER -u SPRINTMD_CLI -u SPRINTMD_PROVIDER -u GROK_AGENT -u CLAUDECODE`
to measure the *installed tree's* config, not the parent session.

#### Claude tree (`/tmp/sb362-claude`)

```text
$ ./sprint.sh model show
AI model configuration
  CLI:      claude
  Provider: claude-code
  Mode:     exec
  Default:  (none — tier default applies)

Effective model per role  (env → config → tier default)
  work         opus          tier default
  chat         opus          tier default
  … (all 16 roles: opus / tier default)

$ ./sprint.sh newtask "Smoke: reject empty input on the login form"
✓ DOC_STATE.md updated successfully
Created task: docs/tasks/backlog/1-smoke-reject-empty-input-on-the-login-form.md

$ ./sprint.sh status
=== Project Status ===
Tasks:
  Backlog:  1
  Next:     0
  Doing:    0
  Blocked:  0
  Review:   0
  Done:     0
```

PASS — `CLI: claude` / `Provider: claude-code`; first task file is exactly
`docs/tasks/backlog/1-smoke-reject-empty-input-on-the-login-form.md`;
`Backlog: 1`.

#### Grok tree (`/tmp/sb362-grok`)

```text
$ ./sprint.sh model show
AI model configuration
  CLI:      grok
  Provider: grok-build
  Mode:     exec
  Default:  (none — tier default applies)

Effective model per role  (env → config → tier default)
  work         grok-4.5      tier default
  chat         grok-4.5      tier default
  … (all 16 roles: grok-4.5 / tier default)

$ ./sprint.sh newtask "Smoke: reject empty input on the login form"
✓ DOC_STATE.md updated successfully
Created task: docs/tasks/backlog/1-smoke-reject-empty-input-on-the-login-form.md

$ ./sprint.sh status
=== Project Status ===
Tasks:
  Backlog:  1
  Next:     0
  Doing:    0
  Blocked:  0
  Review:   0
  Done:     0
```

PASS — `CLI: grok` / `Provider: grok-build`; same task filename; `Backlog: 1`.

#### Compare (step 4) — evidence, not inference

| | Claude tree | Grok tree |
|---|---|---|
| `CLI:` / `Provider:` | `claude` / `claude-code` | `grok` / `grok-build` |
| Tier default (all roles) | **`opus`** | **`grok-4.5`** |
| `newtask` path | identical | identical |
| `status` counts | identical (`Backlog: 1`) | identical |

**Verdict:** the only difference beyond the provider tier is the resolved tier
default model (`opus` vs `grok-4.5`). Scaffold shape, task slug/id allocation,
and status counts are identical. No divergence to kick back to #359/#361.

Trees removed afterward (`rm -rf /tmp/sb362-claude /tmp/sb362-grok`).

Nothing failed, so nothing was kicked back to #359 or #361.

**CLI-only remainder:** only `work` / `chat` still need a configured CLI on
`PATH`. The offline spine (`model show`, `newtask`, `status`) is proven here
with neither binary installed.

### Files changed

docs/tasks/doing/362-ship-smoke-both-install-doors-after-readme-easy-bu.md
docs/guides/dual-provider-smoke.md
docs/guides/provider-reality.md

## Rework (round 1)

**Why:** The smoke proves the installer *writes* a correct tree, not that the
installed tree *runs* — and it closes the record on a wrong reason. Both this
task and `docs/guides/dual-provider-smoke.md:219-220` defer the whole steps‑1–3
spine to "the release operator ... with a configured CLI", but that guide's own
Preconditions (`dual-provider-smoke.md:37-39`) say only `work`/`chat` need a
CLI; `model show` resolves env → config → tier default with no launch
(`docs/sprintbias/scripts/model.sh:5,61-66`) and `newtask`/`status` are pure
file operations. Three offline commands per door were skipped as if blocked.
That also leaves step 4 "Compare" (`dual-provider-smoke.md:148-154`) asserted
from install output alone — `PROVIDER=grok-build` is verified as a string in
`config`, never as a resolved `grok-4.5` tier default, which is the one place
provider divergence would actually surface.

**Improve:**
- [x] Re-create the two throwaway trees (`/tmp/sb362-claude`, `/tmp/sb362-grok`)
      with the same non-interactive recipe already recorded above, at whatever
      VERSION is current — re-confirm `./ship.sh --dry-run` clean first and note
      the version if it moved off 0.0.81.
- [x] In each tree run the offline spine — `./sprint.sh model show`,
      `./sprint.sh newtask "Smoke: reject empty input on the login form"`,
      `./sprint.sh status` — and record the actual output in a new
      `### 6. Offline spine (both doors)` subsection of `## Completed`. Pass =
      `model show` header reports the door's `CLI:`/`Provider:` pair, `newtask`
      creates `docs/tasks/backlog/1-smoke-reject-empty-input-on-the-login-form.md`,
      and `status` counts `Backlog: 1`.
- [x] Close step 4 "Compare" with evidence: state explicitly whether the Claude
      tree resolves Claude models and the Grok tree resolves `grok-4.5` as the
      tier default, and whether any difference beyond the provider tier appeared.
      A divergence here is a finding for #359/#361, not something to fix in this
      task.
- [x] Correct the CLI attribution in both places — this task's `## Completed`
      closing line and `docs/guides/dual-provider-smoke.md` (the sentence at
      lines 219-220) — so the remaining operator step is named as **only**
      `work`/`chat`, not the whole spine.
- [x] Add the spine result as rows in the **Last dry run** table in
      `docs/guides/dual-provider-smoke.md` (Claude leg / Grok leg columns,
      matching the existing table shape) and remove the trees afterward.
