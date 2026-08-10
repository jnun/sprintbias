# Task 358: Omit Claude spending caps when provider is Grok (-g or config)

**Feature**: none
**Created**: 2026-08-07
**Docs**: docs/sprintbias/ai/provider-capabilities.md
**Plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 1
**Reworked**: 0

<!-- Plan: which docs/plans/N-… this belongs to (membership reverse index).
     Depends on: task IDs that must finish first.
     Dependents: reverse edge — task IDs that wait on this one.
     Parent: task-to-task grouping only (not Plan).
     Docs: guide to read while building.
     Tests: docs/tests/*.sh that prove success criteria for `promote`
     (all must pass → review/ to done/). Product newtest loops are not Tests.
     Legacy aliases (read only): Dependents←Blocks, Tests←Proven by.
     Write only the canonical names. -->

## Problem

`work` always arms a USD spending cap (`BUDGET_WORK` → neutral `--budget` →
Claude `--max-budget-usd`). Grok Build has no verified budget flag. Today the
Grok profile *accepts* `--budget`, drops it, and warns once per session —
so every Grok `work`/`polish` run still constructs a Claude-only argument and
tells the user the product asked for something Grok cannot do.

That is wrong whether Grok is selected for one run (`./sprint.sh -g work`) or
as the configured default (`CLI=grok` / `PROVIDER=grok-build`), and the same
dishonesty exists on the other non-Claude tiers (`cursor`, `openai`,
`generic`), where `cli/default.sh` drops the flag the same way. The cap should
be emitted only on a tier that can enforce it: decide by capability before the
call sites build `_budget_args`, not by a late drop-with-warning.

The rule is capability-positive, not provider-specific: budget is offered when
the active tier supports a spending cap (today only `claude-code`), and omitted
everywhere else. Adding a provider that gains a USD cap later should be a
one-line change to the capability check, not a new per-provider branch.

## Success criteria

- [x] Budgeted spine commands (`work`, `polish`, `deps`) pass `--budget` only
      when the active tier supports spending caps. On every other tier — Grok
      and the generic tiers alike — no `--budget` reaches the provider profile,
      so a normal run with default config caps set produces no budget drop-warn.
- [x] The capability is expressed as a reusable tier check in the same shape as
      `sprintbias_orchestration_capable` (`lib.sh:1141`), so call sites ask
      "does this tier support caps?" rather than naming a provider.
- [x] When the active tier is Claude (`-c` or default Claude config),
      `BUDGET_WORK` / `BUDGET_AUDIT` still map to Claude `--max-budget-usd` as
      today; `--max` still clears the cap.
- [x] Switching provider for one run works both ways without config rewrite:
      `-g work` omits budget; `-c work` (or Claude default) applies it.
- [x] Help and capability docs describe budget as available "when the tier
      supports it" (today Claude only), not as an unconditional guardrail for
      every provider.
- [x] Durable failure text states only what the system observed — that the run
      ended without a `## Completed` section — and attributes no cause it did
      not measure. No `## Outcome` stamp or dependent hold line blames a
      spending cap. This wording is the same on every tier; nothing in the
      message path is provider-conditional.
- [x] Profile-level drop of unknown `--budget` remains as defense-in-depth for
      callers that still pass it; primary path does not rely on the warning.
- [x] Audit checklist below is walked; every row is either changed, verified
      no change needed, or deferred with a one-line reason in Notes/Completed.

## Notes

### Root cause (as of analysis)

1. **Config always sets caps** — `docs/sprintbias/config` has
   `BUDGET_WORK` / `BUDGET_AUDIT` (dev defaults 10/5; template defaults 5/3).
2. **lib.sh always loads them** into `SPRINTBIAS_BUDGET_WORK` /
   `SPRINTBIAS_BUDGET_AUDIT` with no tier gate
   (`lib.sh` ~1539–1543).
3. **Call sites always forward when non-empty**:
   - `work.sh` → `_budget_args=(--budget "$SPRINTBIAS_BUDGET_WORK")`
   - `polish.sh` → same pattern for `SPRINTBIAS_BUDGET_AUDIT` (multiple sites)
   - `deps.sh` → `SPRINTBIAS_BUDGET_DEPS` if set
4. **Claude profile** maps `--budget` → `--max-budget-usd` (`cli/claude.sh`).
5. **Grok profile** consumes `--budget`, records "budget caps" in `dropped[]`,
   prints once: `SprintBias: grok profile — budget caps not supported…`
   (`cli/grok.sh`). Same pattern in `cli/default.sh` for generic CLIs.
6. **Documented as intentional** — KK-18 / provider-capabilities footnote ³:
   "Budget caps are Claude-only; Grok drops `--budget` with warning." Product
   intent now is: **omit at source** when Grok is active, so Grok is not
   handed a spending-cap command it cannot honor.

### Settled: capability-positive, not provider-specific

The gate asks whether the active tier supports spending caps — it does not name
Grok. Today only `claude-code` is capable; Grok and the generic tiers
(`cursor`, `openai`, `generic`, all served by `cli/default.sh`) all omit.
A provider that gains a real USD flag later should become capable by a one-line
change, not a new branch. `sprintbias_orchestration_capable` (`lib.sh:1141`) is
the working precedent for the shape.

Where the check lives — a helper the call sites consult, a post-load clear in
`lib.sh`, or both — is the implementer's call. Keep the profile-level drop in
`cli/grok.sh` / `cli/default.sh` as defense-in-depth either way.

Do **not** invent a fake USD flag for Grok (KK-18 / plan 11).

`--max` on a capless tier is already a no-op (the cap it would clear was never
armed). Leave it silent — adding a "there was no cap to remove" notice would
re-introduce exactly the chatter this task removes.

Provider resolution already prefers env over config (`-g` sets
`SPRINTBIAS_CLI` / `SPRINTBIAS_PROVIDER` before scripts source `lib.sh`), so
any tier check that uses `sprintbias_ai_tier` covers both flip and config.

### Guardrail honesty

`help/work.md` says the per-run budget cap is "the only guardrail" (no turn
cap). On any capless tier that is false after this fix. Document it as
available when the tier supports it (today Claude only), and say plainly that
other tiers run with no USD cap (optional future: turn caps — out of scope
unless deliberately added).

### Verification is manual

`**Tests**: none` is deliberate — the author verifies by hand rather than
adding automated coverage, so `promote` does not gate on a test for this one.
The success criteria are written to be walkable by hand: run `work` under each
tier and read what reaches the provider and what gets stamped. An implementer
should not go build a test harness for this.

### Say what is known, never guess

The stopped-short text was a hardcoded guess at a cause `work` never measured.
Hedging it ("perhaps budget or access constraints") is still a guess. State the
observed fact — the run ended without `## Completed` — and stop there. A cause
worth recording has to come from something the system actually saw.

This also keeps the message path provider-neutral: with no cause list, there is
no tier-conditional wording to maintain.

### Out of scope

- Inventing Grok budget/token flags
- Changing Claude `--max-budget-usd` behavior
- Renaming `BUDGET_*` config keys
- Hand-editing `src/` (use `./ship.sh` after live `docs/` works)

## Audit checklist

Walk every row. Mark: **edit** | **verify OK** | **defer (reason)**.

### Runtime — call sites that build `--budget`

| # | Path | Role | Status |
|---|------|------|--------|
| 1 | `docs/sprintbias/scripts/work.sh` | Builds `_budget_args` from `SPRINTBIAS_BUDGET_WORK`; `--max` clears it; primary user pain | edit |
| 1b | `docs/sprintbias/scripts/work.sh` (~1068–1075) | Stopped-short reason text guesses "(budget cap or early exit)" and is stamped into `## Outcome`, then read back into dependents' hold lines — must state the observed fact only | edit |
| 2 | `docs/sprintbias/scripts/polish.sh` | Builds `_budget_args` from `SPRINTBIAS_BUDGET_AUDIT` (~3 call sites + `--max`) | edit |
| 3 | `docs/sprintbias/scripts/deps.sh` | Optional `SPRINTBIAS_BUDGET_DEPS` → `--budget` | edit |
| 4 | `docs/sprintbias/scripts/loop.sh` | Comment only ("CLI's own --budget cap…") — wording may need Grok honesty | edit |

### Runtime — load, emit, capability

| # | Path | Role | Status |
|---|------|------|--------|
| 5 | `docs/sprintbias/lib.sh` | Loads `SPRINTBIAS_BUDGET_*` from config; `sprintbias_emit_prompt` strips `--budget`; natural home for `sprintbias_budget_capable` or post-load clear | edit — added `sprintbias_budget_capable` |
| 6 | `docs/sprintbias/config` | `BUDGET_WORK` / `BUDGET_AUDIT` values + comment ("per invocation USD") — should note Claude-only / ignored on Grok | edit — comment only, values unchanged |

### Runtime — provider profiles

| # | Path | Role | Status |
|---|------|------|--------|
| 7 | `docs/sprintbias/cli/claude.sh` | Maps `--budget` → `--max-budget-usd`; keep | verify OK |
| 8 | `docs/sprintbias/cli/grok.sh` | Drop + warn; keep as defense-in-depth; ideally unused for budget on primary path | verify OK |
| 9 | `docs/sprintbias/cli/default.sh` | Drop + warn for generic CLIs | verify OK |

### User-facing help

| # | Path | Role | Status |
|---|------|------|--------|
| 10 | `docs/sprintbias/help/work.md` | Claims budget is the only guardrail; examples for `--max` | edit |
| 11 | `docs/sprintbias/help/polish.md` | `--max` "no budget cap" example | edit |
| 12 | `docs/sprintbias/help/plan.md` | "AI budget" wording is metaphorical (re-gating) — likely no change | verify OK — metaphorical, no change |

### Capability / maintainer guides (repo-only guides under `docs/guides/` do not ship)

| # | Path | Role | Status |
|---|------|------|--------|
| 13 | `docs/sprintbias/ai/provider-capabilities.md` | Matrix row "Budget caps"; footnote ³ drop-with-warn — update if omit-at-source | edit |
| 14 | `docs/guides/provider-reality.md` | KK-18 RESOLVED drop-with-warn — retarget stamp if behavior changes | edit |
| 15 | `docs/guides/grok-provider-tier.md` | Flag map `--budget` → (drop) | edit |
| 16 | `docs/guides/claude-provider-tier.md` | Flag map `--budget` → `--max-budget-usd` | edit |
| 17 | `docs/guides/command-matrix.md` | Only if `work`/`polish` flags or semantics change in the catalog | verify OK — no budget/flag rows; `validate --commands`/`--docs` clean |

### Tests & fixtures

| # | Path | Role | Status |
|---|------|------|--------|
| 18 | `docs/tests/` | No budget coverage exists today, and none is being added — verification is manual by decision (see Notes). **defer** | defer |
| 19 | `docs/tests/fixtures/dep-glitch-matrix/**` | Fixture files hardcode `incomplete: budget` as synthetic test data; hold-line rendering reads whatever reason is in the file, so changing live stamp wording does not break them — **verify OK** expected | verify OK |
| 20 | `docs/tests/smoke-grok-spine.sh`, `smoke-live-dual-provider.sh` | Existing smokes; confirm they still pass and emit no budget drop-warn on the Grok path | verify OK — no budget drop-warn; 5 pre-existing failures unrelated (see Completed) |

### Ship / install / mirror (do not hand-edit `src/` for mirrored paths)

| # | Path | Role | Status |
|---|------|------|--------|
| 21 | `./ship.sh` | After live fix: mirror `docs/sprintbias/` + help; version bump | **defer** — see Completed |
| 22 | `src/docs/sprintbias/**` | Mirror only — verify byte match post-ship, not hand-edit | **defer** — blocked on row 21 |
| 23 | `setup.sh` | Budget migration only touches retired `BUDGET_TASKS`; likely **verify OK** unless installer docs mention caps | verify OK |
| 24 | `DOCUMENTATION.md` | No current BUDGET string; **verify OK** unless work section gains provider note | verify OK — 0 budget refs |
| 25 | `sprint.sh` | `-g`/`-c` already export provider env; **verify OK** unless banner/docs change | verify OK — exports both vars, tier flip confirmed |

### Historical / do not change (context only)

| # | Path | Role | Status |
|---|------|------|--------|
| 26 | `docs/tasks/review/298-…` (KK-18 inventory) | Historical task; optional note, no required edit | defer |
| 27 | `docs/tasks/done/251`, `255`, `270` | Prior Grok profile / budget rename history | defer |
| 28 | `docs/plans/11-grok-firm-up-…` | "Invented budget caps on Grok" anti-goal | defer |

**Deep-pass count:** ~25 live rows to audit; expected **edit** surface is small
(helper + work/polish ± deps + config comment + help + capability guides), with
profiles kept as fallback and ship as the mirror step.

## Refine (round 1)

**Sharpened:** Reframed the rule from "omit on Grok" to capability-positive —
budget is emitted only on a tier that supports spending caps, which fixes the
generic tiers (`cursor`, `openai`, `generic`) in the same pass instead of
leaving them dishonest. Added a criterion that durable failure text state only
what `work` observed and attribute no unmeasured cause, which removes the
hardcoded "(budget cap or early exit)" guess from `## Outcome` stamps and
dependent hold lines — and leaves nothing provider-conditional in the message
path. Settled `**Tests**: none` as a deliberate manual-verification choice, and
collapsed the stale A/B/C design menu now that the seam is decided.

## References

docs/sprintbias/scripts/work.sh
docs/sprintbias/scripts/polish.sh
docs/sprintbias/scripts/deps.sh
docs/sprintbias/lib.sh
docs/sprintbias/config
docs/sprintbias/cli/claude.sh
docs/sprintbias/cli/grok.sh
docs/sprintbias/cli/default.sh
docs/sprintbias/help/work.md
docs/sprintbias/ai/provider-capabilities.md
docs/guides/provider-reality.md
docs/guides/grok-provider-tier.md
docs/guides/claude-provider-tier.md
sprint.sh

## Questions

**Status: READY**

### Already complete

None — no capability gate on budget exists. There is no `sprintbias_budget_capable`
(or equivalent) anywhere in `docs/sprintbias/`. What was verified in the live tree:

- `lib.sh:1574-1578` loads `SPRINTBIAS_BUDGET_WORK` / `SPRINTBIAS_BUDGET_AUDIT`
  from config with no tier gate and falls back to `5.00` / `3.00`, so a cap is
  armed even when config is empty.
- `lib.sh:1176-1181` `sprintbias_orchestration_capable` is the precedent shape
  the new check should copy (single `case` over `sprintbias_ai_tier`).
- Call sites build `--budget` unconditionally: `work.sh:781`,
  `polish.sh:348,705,1017`, `deps.sh:320-321`. `deps.sh` reads
  `SPRINTBIAS_BUDGET_DEPS`, which no config key sets — env-only today, but it
  needs the same gate.
- `cli/claude.sh:146,218` maps `--budget` → `--max-budget-usd` correctly and
  cleanly; keep as-is (criterion 3 holds once the gate lets Claude through).
- Criterion 7's defense-in-depth already exists and looks right:
  `cli/grok.sh:74` and `cli/default.sh:25` consume `--budget`, record
  `"budget caps"` in `dropped[]`, and warn once. No change needed there.
- Criterion 4's provider-resolution seam already works: `sprint.sh:434-442`
  exports `SPRINTBIAS_CLI` / `SPRINTBIAS_PROVIDER` for `-c` / `-g` before any
  script sources `lib.sh`, and `sprintbias_ai_tier` (`lib.sh:1157-1169`) prefers
  `SPRINTBIAS_PROVIDER` over CLI inference — so one tier check covers flip and
  config with nothing extra to build.
- `_outcome_brief` (`work.sh:230-242`) reads **Reason** from the file and
  truncates to 60 chars, so hold lines inherit new stamp wording automatically;
  no separate rendering change is needed (checklist row 19 confirmed —
  `fixtures/dep-glitch-matrix/seed.sh:178,212` hardcode their own reason strings
  and are unaffected: **verify OK**).
- The emit path is already honest: the subagent instructions at
  `work.sh:924-929` ask for `<one line — what stopped it / what remains>` with
  no cause list. Only the exec path guesses.

### Remaining work

- Add the tier check (helper in `lib.sh` in the shape of
  `sprintbias_orchestration_capable`, and/or a post-load clear of
  `SPRINTBIAS_BUDGET_*`) so only `claude-code` is budget-capable.
- Gate every call site through it: `work.sh:781`, `polish.sh:348,705,1017`,
  `deps.sh:320-321`. `--max` keeps clearing the cap on Claude and stays silent
  elsewhere.
- Replace the hardcoded guess in `work.sh:1081-1086` — both the `_stamp_outcome`
  and `_note_fail` strings say `(budget cap or early exit)`. State only the
  observed fact, identically on every tier.
- Fix the two places that teach the guessed cause by example:
  the comment at `work.sh:229` and `help/work.md:68`, which both illustrate a
  hold line as `incomplete: budget`.
- Honest guardrail wording: `help/work.md:101-102` ("the per-run budget cap …
  is the only guardrail"), plus the `--max` "no budget cap" examples in
  `help/work.md:118-119` and `help/polish.md:80`.
- Capability docs: `ai/provider-capabilities.md:32,50-51,80` — matrix row
  "Budget caps" and footnote ³ still describe drop-with-warning as the behavior;
  retarget to omit-at-source (warning demoted to fallback). Then
  `guides/provider-reality.md` KK-18, `guides/grok-provider-tier.md`,
  `guides/claude-provider-tier.md`.
- `config:58-60` comment should say the caps apply on tiers that support them
  (today Claude) and are ignored elsewhere.
- Walk the rest of the checklist rows (loop.sh comment, help/plan.md,
  command-matrix, setup.sh, DOCUMENTATION.md, sprint.sh) and mark each
  **edit** / **verify OK** / **defer**.
- Verify by hand under both tiers, confirm the Grok smokes still pass with no
  budget drop-warn, then `./ship.sh` and check `src/` byte-matches.

### Questions for the developer

None — task is fully defined.

<!-- After work only — audit trail of what was touched. Helps committers,
     later audits, and "what broke?" recovery. Copy the two headings below to
     column 0 (UNINDENTED — they are indented here only so a fresh, unworked
     task is not mistaken for a finished one), then list one repo-relative
     path per line under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintbias/scripts/example.sh
       docs/tasks/.TEMPLATE-task.md

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. Do not fill this before work. -->

<!--
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->

## Completed

Budget is now capability-gated, not provider-named. `sprintbias_budget_capable`
(`lib.sh`, directly under `sprintbias_orchestration_capable` and in the same
single-`case` shape) is the one seam that answers "can this tier enforce a USD
cap?". Today only `claude-code` says yes; Grok Build, Cursor, OpenAI and generic
all say no and get no `--budget` constructed at all. A provider that ships a real
cap flag joins by adding its tier to that `case` — no call-site change.

All five call sites now ask the helper before building `_budget_args`:
`work.sh`, `polish.sh` (3 sites), `deps.sh`. `--max` still clears the cap where
one is armed and stays a silent no-op elsewhere, as decided in Notes.

The durable failure text no longer guesses. `work.sh` stamped
`run stopped short — no '## Completed' section (budget cap or early exit)` into
`## Outcome` and into `_note_fail`; both now read
`run ended without a '## Completed' section` — only what the run observed, and
identical on every tier, so nothing in the message path is provider-conditional.
The two places that taught the guess by example (the `_outcome_brief` comment in
`work.sh` and the hold-line example in `help/work.md`) were updated to match.
`_outcome_brief` renders whatever Reason the file carries, so hold lines
inherited the new wording with no rendering change.

Honesty passes on help and docs: `help/work.md` no longer calls the cap "the only
guardrail" — it applies when the provider supports spending caps (Claude Code
today) and other tiers run uncapped; the `--max` examples in `help/work.md` and
`help/polish.md` now say "clear the budget cap (where one applies)" rather than
implying every run has one. `config` gained a comment saying the caps apply only
on cap-capable tiers and are ignored elsewhere (values unchanged).
`ai/provider-capabilities.md` footnote 3 and the closing tier paragraph now
describe omit-at-source with the profile drop as fallback; `guides/provider-reality.md`
KK-18, `guides/grok-provider-tier.md` and `guides/claude-provider-tier.md` were
retargeted to match. The profile-level drop in `cli/grok.sh` / `cli/default.sh`
was left exactly as-is — defense-in-depth for any caller that still passes the
flag.

### Verified by hand (manual, per the task's `**Tests**: none` decision)

- Tier resolution: `claude`/`claude-code` → capable; `grok-build`, `cursor`,
  `openai`, `generic` → not capable. `sprint.sh -g` / `-c` export both
  `SPRINTBIAS_CLI` and `SPRINTBIAS_PROVIDER`, so the one-run flip and the
  configured default both route through the same check.
- Arg construction with config caps set (10.00/5.00, plus `BUDGET_DEPS=7.00`):
  Claude builds `--budget` for WORK/AUDIT/DEPS; Grok and generic build an empty
  array for all three.
- End-to-end through the real profiles with a stub CLI on PATH:
  Grok without `--budget` → `[-p] [hi] [--model] [x]`, no warning at all;
  Grok with `--budget` → still warns and drops (fallback intact);
  Claude with `--budget` → `[--max-budget-usd] [10.00]` as before.
- `bash -n` clean on all five edited scripts.
- `test-grok-provider.sh` 66/66, `test-profile.sh` 13/13,
  `test-no-stale-refs.sh` 17/17, `test-command-matrix-smoke.sh` 144/144.
  `validate --commands` (25 commands, four surfaces) and `validate --docs`
  (24 flag surfaces) both clean.
- `smoke-grok-spine.sh`: 20 passed / 5 failed — the 5 failures are **pre-existing
  and unrelated** (Grok subagent orchestration wording: `spawn_subagent`,
  `general-purpose`, `nesting depth is one`, gate `PARALLEL`). Confirmed by
  stashing this task's edits and re-running: identical 5 failures at baseline.
  Critically, the smoke emits **no budget drop-warn** on the Grok path.
  `smoke-live-dual-provider.sh` was not run — it is a live-CLI smoke.

### Deferred — ship step not run (checklist rows 21, 22)

`./ship.sh` was **not** run, and `src/` therefore does not yet carry this change.
Reason: `ship.sh` rsyncs whole trees, and `--dry-run` shows **23 paths** queued to
mirror — only 9 of them are this task's. The other 14 (`ai/conversation.md`,
`ai/task-creation.md`, `guides/use_chat.md`, `help/chat.md`, `help/gate.md`,
`help/plan.md`, `scripts/chat-sprint.sh`, `scripts/chat.sh`, `scripts/context.sh`,
`scripts/gate-lib.sh`, `scripts/plan-start.sh`, plus `DOCUMENTATION.md`,
`GETSTARTED.md`, `docs/tasks/.TEMPLATE-task.md`) are unrelated in-flight edits
already in the working tree at task start. Shipping would sweep that unverified
work into the distribution and bump `0.0.75 → 0.0.76` in the same step, which is
the developer's release call, not this task's.

One thing to know before shipping: `docs/sprintbias/config` is **not** in
`ship.sh`'s `TREE_EXCLUDES`, so the mirror will overwrite `src/docs/sprintbias/config`
with the dev values `BUDGET_WORK=10.00` / `BUDGET_AUDIT=5.00`, replacing the
shipped template defaults of `5.00` / `3.00`. That divergence is pre-existing and
not introduced here, but it lands the moment anyone ships — worth a decision
(either re-align the dev config, or exclude/transform it) rather than a surprise.
Note `help/work.md` documents the default as `$5`.

To finish: run `./ship.sh --dry-run`, confirm the other 14 paths are intended,
then `./ship.sh` and verify `src/` byte-matches.

### Files changed
docs/sprintbias/lib.sh
docs/sprintbias/config
docs/sprintbias/scripts/work.sh
docs/sprintbias/scripts/polish.sh
docs/sprintbias/scripts/deps.sh
docs/sprintbias/scripts/loop.sh
docs/sprintbias/help/work.md
docs/sprintbias/help/polish.md
docs/sprintbias/ai/provider-capabilities.md
docs/guides/provider-reality.md
docs/guides/grok-provider-tier.md
docs/guides/claude-provider-tier.md
docs/tasks/doing/358-omit-claude-spending-caps-when-provider-is-grok-g.md
