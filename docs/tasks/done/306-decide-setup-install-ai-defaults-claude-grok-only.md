# Task 306: Decide setup install AI defaults: Claude/Grok only, silent CLAUDE.md, no extra AI dotfiles

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Plan**: 12
**Depends on**: none
**Blocks**: 307
**Parent**: none
**Refined**: 1
**Reworked**: 0

## Problem

Setup still asks too many AI-related questions, in the wrong order, and for the
wrong files. A fresh install shows a multi-select of instruction files
(`CLAUDE.md`, `.cursorrules`, Copilot, `AGENTS.md`, Windsurf) *before* the user
picks a CLI; then the CLI picker (Claude / Grok only); then Claude alone may
be asked again about `CLAUDE.md`. Grok gets no instruction-file step even
though it loads `CLAUDE.md` when present.

We want a single, intentional install shape: choose the AI runtime once, get
one silent `CLAUDE.md` ensure (prepend if present, create if missing), and
never push extra root/dot AI files. This task is the **decision record** —
answer every question below before any implementer rewires `setup.sh`.

## Success criteria

- [ ] Every numbered question under ## Questions has a written decision
      (accepted option or explicit custom wording)
- [ ] A one-paragraph **Install shape (decided)** summary is written into Notes
      (or a short subsection under Questions) so implementers need no chat replay
- [ ] Related tasks **#303 #304 #305** are either re-scoped to match the
      decision, cancelled, or explicitly kept with a one-line reason
- [ ] Any follow-on implementation work is listed (new task ids or “fold into
      existing #N”) — this task does not implement setup changes itself

## Notes

### Install shape (decided)

An **Easy Button**: one keystroke lays down the full SprintBias scaffold
silently. Everything else lives behind an opt-in "More options?" gate.

**Two doors, identical file batch.** `[Enter]` = Claude Code
(`PROVIDER=claude-code`, default runtime `-c`); `[g]` = Grok Build
(`PROVIDER=grok-build`, default runtime `-g`). The *only* difference between
the two doors is that runtime setting — both run the exact same silent batch
below. There is no per-provider file difference; both get `CLAUDE.md` **and**
`AGENTS.md`.

**Silent batch (both doors), in order:**

1. **GETSTARTED.md** — add if missing (no prompt; silent).
2. **CLAUDE.md** — if present, ensure it references `DOCUMENTATION.md`; prepend
   the pointer when our marker is absent. Create from the shipped template if
   missing. Never clobber the user's body.
3. **DOCUMENTATION.md** — if it's ours (marker present), overwrite when it's an
   older version (upgrade). If a *non-ours* `DOCUMENTATION.md` already exists
   (the user's own), do not clobber it — install our manual as
   `SPRINTDOCUMENTATION.md` instead.
4. **.gitignore** — prepend our required ignore entries when our marker is
   absent; create and inject if the file is missing.
5. **AGENTS.md** — same ours/theirs rule as CLAUDE.md: overwrite when it's an
   older version of ours; prepend our values when it's the user's; copy ours
   when none exists.

**Then:** `More options? [y/N]` (Enter = No). Yes surfaces the things pulled out
of the default path:

- **Per-file conflict override** (when any deferred `theirs` conflicts exist;
  resolved **first**). Binary choice per file: **Prepend** (`Enter`) or
  **Overwrite** (`o`). Default path never asks — it silent-prepends. Leave alone
  is not a key: decline More options to avoid Overwrite, or accept silent prepend.
- **GitHub Issues sync.**
- **`Add all AI instructions? [y/N]`** — the residual non-Claude/non-AGENTS
  dotfiles (`.cursorrules`, `.windsurfrules`, Copilot).

### Ownership marker ("is this file ours?")

The overwrite-if-ours / prepend-if-theirs branches all depend on reliably
telling our files from the user's. Decision: **every shipped scaffold file
carries a version-stamped sentinel comment in its native syntax.**

- Markdown (`CLAUDE.md`, `AGENTS.md`, `DOCUMENTATION.md`, `GETSTARTED.md`):
  `<!-- SprintBias vX.Y.Z -->` (`//` is not a Markdown comment)
- `.gitignore`: `# SprintBias vX.Y.Z`

One line does double duty: presence = "ours" (safe to overwrite); the version
= current (leave) vs older (upgrade/overwrite). Absence = the user's file →
prepend-or-skip, never clobber. This keeps the never-clobber principle intact:
we only ever overwrite files we can positively identify as our own.

The versioned marker is written **wherever we place content**, not only on
fresh full-file installs. When we prepend our pointer/entries into a
user-owned file (CLAUDE.md, AGENTS.md, .gitignore), the injected block carries
its own `SprintBias vX.Y.Z` line. A re-run then finds *our* block inside the
user's file, reads its version, and upgrades just that block — leaving the
user's body untouched. Without the version on the injected snippet we could
detect "ours is present" but not "ours is stale."

### Current setup surface (inventory)

| Step | Today | Orthogonal to AI? |
|------|--------|-------------------|
| Target path | always | — |
| Platform | 1 GitHub Issues / 2 no sync (default) | Yes |
| GETSTARTED.md | Y/n (default no) | Yes |
| AI instruction multi-select | CLAUDE, .cursorrules, copilot, AGENTS, windsurf | **No — target of this decision** |
| .gitignore | prepend / append / skip (default) | Yes |
| AI CLI | 1 Claude / 2 Grok (required, no Enter) | **No — simplify** |
| Provider file offer | Claude→CLAUDE [Y]; Grok→none | **No — fold into silent ensure** |
| Latent tiers (not in menu) | cursor, codex→openai, generic | Decide: stay latent only? |

Shipped pointer templates under `src/`: `CLAUDE.md`, `AGENTS.md`,
`.cursorrules`, `.windsurfrules`, `.github/copilot-instructions.md` (same
three-line DOCUMENTATION.md pointer).

### Related work (fate decided)

The Easy Button absorbs all three siblings, so they are **cancelled** and their
intent folds into one implement task, **#307**:

- **#303** (reorder AI-file offers after the CLI pick) — obsolete: the default
  path has no offers at all; they're silent. Nothing to reorder. Cancelled.
- **#304** (replace the multi-select menu) — satisfied by design: the
  multi-select collapses into a single `Add all AI instructions? [y/N]` behind
  *More options*. Cancelled.
- **#305** (polish prompt wording) — GETSTARTED goes silent (no prompt to
  polish); the new copy ("More options?", "Add all AI instructions?", the batch
  `✓ …` success lines) is written directly in #307. Cancelled.

Rationale for folding into one task rather than three: the Easy Button is a
single coherent rewrite of one section of `setup.sh`; splitting it would
fragment a single edit and cost context to keep synced (fewer, sharper tasks).

**#307** — Rewire setup.sh into the two-door Easy Button install.

### Out of scope for this decision task

- Model coerce / tier_model cleanup (separate thread)
- Runtime `-g` / `-c` flags (already shipped)
- Changing pointer *content* beyond “one file, silent ensure”

## References

setup.sh
src/CLAUDE.md
src/AGENTS.md
src/.cursorrules
src/.windsurfrules
src/.github/copilot-instructions.md
docs/tasks/backlog/303-unify-setup-ai-instruction-file-offers-with-the-cl.md
docs/tasks/backlog/304-replace-the-multi-select-ai-instruction-file-menu.md
docs/tasks/backlog/305-polish-setup-prompt-wording-for-getstarted-and-ai.md
Claude.md (product principles: optional scaffolding, never clobber user files)

## Decisions (locked 2026-07-30)

All decided in product conversation. See **Install shape (decided)** in Notes
for the full spec; implementers need no chat replay.

1. **AI CLI picker shape** — `[Enter]` = Claude Code; `[g]` = Grok Build. Two
   doors, no other menu rows. (Note: `g` replaces the earlier `2`, to match the
   shipped `-g`/`-c` runtime convention.)
2. **Instruction files for both doors** — silent-ensure **both** `CLAUDE.md`
   *and* `AGENTS.md` (same batch for Claude and Grok), plus the rest of the
   scaffold (GETSTARTED, DOCUMENTATION, .gitignore). No per-provider difference.
   Broader than the original "only CLAUDE.md" suggestion.
3. **Multi-select create menu** — removed from the default path entirely. The
   only path to extra dotfiles is `More options? → Add all AI instructions?
   [y/N]`. Existing files still get silent prepend (never clobber).
4. **Second "Create CLAUDE.md? [Y/n]" prompt** — deleted; folded into the
   silent batch. The whole scaffold is silent on the default path.
5. **Shipped non-Claude templates** (`.cursorrules`, `.windsurfrules`, Copilot)
   — kept in `src/` to serve the opt-in "Add all AI instructions" path and
   silent prepend of pre-existing files. Never push-created on the default path.
6. **Platform / GETSTARTED / .gitignore** — changed, not left orthogonal:
   GETSTARTED and .gitignore move *into* the silent batch (no prompts);
   GitHub Issues sync moves *behind* `More options?`.
7. **Follow-on** — one implement task, **#307**; siblings #303/#304/#305
   cancelled and absorbed (see Related work).

### Open question for #307 (not a blocker)

- When a user's own non-ours `DOCUMENTATION.md` forces our manual to install as
  `SPRINTDOCUMENTATION.md`, the `CLAUDE.md`/`AGENTS.md` pointer must reference
  `SPRINTDOCUMENTATION.md` in that case (not the generic `DOCUMENTATION.md`).
  #307 owns wiring this pointer-target choice; flagged so it isn't missed.

## Refine (round 1)

**Sharpened:** Replaced the undecided "lean proposal + 7 open questions" with a
locked **Easy Button** spec — two doors (`[Enter]` Claude / `[g]` Grok) running
one identical silent scaffold batch (GETSTARTED, CLAUDE.md, DOCUMENTATION.md,
.gitignore, AGENTS.md), everything else behind a `More options?` gate; a
version-stamped sentinel comment (`<!-- SprintBias vX.Y.Z -->`) as the
"is-it-ours" ownership marker guarding overwrite-vs-prepend; and folded
#303/#304/#305 into one new implement task #307.

## Plan Think

### Perspective check

**Chief Platform Architect.** This task's real payload is the *ownership
marker* — the version-stamped sentinel that is the only thing authorizing an
overwrite. From a data-integrity view this is the correct spine: never mutate a
byte we can't positively prove is ours, and let the version field decide
leave-vs-upgrade. The architect signs off on the design but pushes on its
fragility. A marker in a file's body is a soft signal: a user can copy our
`CLAUDE.md`, edit it heavily, and keep the marker — now we "own" a file that is
really theirs and we'll happily overwrite it on the next upgrade. Conversely a
user can strip the marker and we'll re-prepend, doubling our block. Both are
implementation risks the decision record correctly punts to #307, but the
architect wants the *decision* to name the invariant explicitly: the marker
grants overwrite **only** to the block it delimits (the injected snippet), never
to surrounding body — which the spec's "upgrade just that block" language does
capture. The architect also flags the silent `DOCUMENTATION.md` overwrite-on-
upgrade as the one place we mutate a whole file without asking; the
`SPRINTDOCUMENTATION.md` fallback for non-ours manuals is the right guard, and
the marker-gated upgrade keeps it honest.

**Chief Experience Officer.** This is the task the CXO has been waiting for: the
first-run experience today asks AI-file questions in the wrong order and leaks
adoption at the exact moment trust is being formed. Collapsing to two doors and
a silent batch is exactly right — one keystroke, no interrogation, positive
copy. The CXO pushes on one word: *silent*. Silent must mean "asks nothing," not
"shows nothing." A user who watches an installer write files to their repo with
zero output will not trust it; the `✓ CLAUDE.md ensured` / `Skipped …` lines are
non-negotiable and the decision already bakes them in. The CXO also wants
`More options?` to be genuinely discoverable — GitHub Issues sync moving behind
it means a real user need now sits one "N-by-default" prompt away from being
missed; acceptable because the target user of the Easy Button is the person who
wants defaults, and the power user reads prompts.

### Tension and resolution

The core tension is **silence vs. transparency**. The CXO optimizes for a
frictionless, question-free first run; the architect optimizes for the user
knowing precisely what changed on their disk — especially the two operations
that mutate whole files (DOCUMENTATION.md upgrade, fresh full-file installs).
Resolved in the architecture, not by compromise: "silent" is scoped to
*questions*, while *outcomes* are always printed (`✓ …` / `Skipped …`), and the
only overwrites that ever happen are marker-proven-ours. So the CXO gets a
zero-question path and the architect gets an auditable one from the same design;
they reinforce rather than trade off. The single residual disagreement is
whether the DOCUMENTATION.md upgrade should ever be truly silent — the architect
would prefer even a one-line `↑ DOCUMENTATION.md upgraded v1.2→v1.3` over a bare
`✓`, and that resolves the architect's way at negligible UX cost. This is the
right decision record; its risk is entirely in the fidelity of the marker
detection, which is #307's burden to prove.

## Questions

**Status: COMPLETE**

### Already complete

This is a decision-record task, not an implementation task — its deliverable is
the recorded decision, and every part is present and internally consistent:

- **All numbered questions decided.** The `## Decisions (locked 2026-07-30)`
  section answers all seven with concrete choices (two-door `[Enter]`/`[g]`
  picker, silent-ensure both CLAUDE.md and AGENTS.md, multi-select removed from
  the default path, second CLAUDE.md prompt deleted, non-Claude templates kept
  in `src/` for the opt-in path, GETSTARTED/.gitignore into the silent batch,
  one follow-on task).
- **Install-shape summary written.** `### Install shape (decided)` gives the
  full two-door / silent-batch / More-options spec plus the version-stamped
  ownership-marker design, so #307 needs no chat replay.
- **Sibling fate decided and executed.** `### Related work (fate decided)`
  cancels #303/#304/#305 with a one-line reason each and folds their intent into
  #307. Verified on disk: all three now live in `docs/tasks/done/`.
- **Follow-on listed and live.** #307 exists in `docs/tasks/backlog/`, is titled
  "Rewire setup.sh into the two-door Easy Button install," and carries
  `**Depends on**: 306` — the dependency is wired the correct direction.

The unchecked boxes under `## Success criteria` are cosmetic; the substance each
box asks for is present in the body. The record is thorough (Refine round 1 and
Plan Think perspective check both applied) and carries no unresolved decision.

### Remaining work

None for this task. All implementation of the decided install shape is #307's
scope (this task explicitly "does not implement setup changes itself"). The one
carried-forward detail — pointing CLAUDE.md/AGENTS.md at `SPRINTDOCUMENTATION.md`
when a non-ours manual forces that filename — is already recorded under
`### Open question for #307 (not a blocker)` and owned by #307.

### Questions for the developer

None — task is fully defined. Every decision it exists to make is made and
recorded; the follow-on (#307) is created and correctly linked.

## Excellence Audit

### Summary

Task 306 is a decision record, and it holds up: every question it set out to
answer is answered, the **Install shape (decided)** spec is complete enough that
#307 built from it without a chat replay, and the sibling tasks it absorbed
(#303/#304/#305) are genuinely resolved on disk. The latest revision — replacing
the three-way per-file override with a binary **Prepend** / **Overwrite** and
resolving conflicts *first* under `More options?` — is a real improvement:
fewer keys, and the destructive branch now sits behind one deliberate `o`. I
verified the decision end to end against the shipped installer (fresh install
both doors, re-run idempotency, user-owned-everything, and the More-options
override) and it behaves as decided. The one gap with teeth: the decision
enumerates five scaffold files and `README.md` is not among them, so README
still runs on the old rules — silently mutated, no versioned marker, and its
pointer hardcoded to `DOCUMENTATION.md` even when our manual installed as
`SPRINTDOCUMENTATION.md`.

### Findings

- [ENHANCEMENT] `README.md` sits outside the decided install shape. Verified on
  a project owning its own `DOCUMENTATION.md`: `CLAUDE.md`/`AGENTS.md` retarget
  to `SPRINTDOCUMENTATION.md`, but README's injected pointer (setup.sh:471,
  written at setup.sh:636 — long before `MANUAL_FILE` is resolved at
  setup.sh:1061) still points at the *user's* `DOCUMENTATION.md`. It also
  carries no versioned marker, so our block can never be upgraded, and it is
  not deferred into `CONFLICTS`, so it is the one scaffold file with no
  `More options?` override. FILED as #359.
- [ENHANCEMENT] The decided install contract is undocumented. Nothing in
  `DOCUMENTATION.md`, `GETSTARTED.md`, `docs/sprintbias/`, or `docs/guides/`
  mentions the two doors, the silent batch, `More options?`, the ownership
  marker, or the `SPRINTDOCUMENTATION.md` fallback — so GitHub Issues sync (now
  behind the gate) is effectively unfindable, and the never-clobber contract is
  invisible to the user it protects. FILED as #360.
- [NIT] #307's `## Completed` and `## Questions` still describe the **three-way**
  override (Replace / Leave alone / Prepend) that this task's revision retired;
  the shipped `resolve_conflict_interactive` is binary. #307's success criteria
  are correct — only its narrative is stale. Worth a one-line fix when #307 is
  next touched.

Verified working, no action needed: both doors write the correct `CLI`/`PROVIDER`
and run an identical batch; re-run at the same version is a clean no-op (one
marker per file, no double-inject); user-owned `CLAUDE.md`/`AGENTS.md`/
`.gitignore` bodies survive prepend intact; the `_copy_stamped` `sed` delimiter
bug from #307's Rework round 1 is fixed and `GETSTARTED.md`/`DOCUMENTATION.md`
land stamped.

VERDICT: FILED — 2 enhancement task(s)

## Excellence

- **Date**: 2026-08-10
- **Verdict**: FILED
- **Tasks filed**: 2
- **Files reviewed**: 78
- **Context source**: git working tree diff

Task 306 is a decision record, and it holds up. Every question it set out to answer is answered, the **Install shape (decided)** spec is complete enough that #307 built from it without a chat replay, and the absorbed siblings (#303/#304/#305) are genuinely resolved on disk. The revision in this change — three-way per-file override → binary **Prepend**/**Overwrite**, with conflicts resolved *first* under `More options?` — is a real improvement: fewer keys, and the destructive branch now sits behind one deliberate `o`. I traced the decision end to end against the shipped installer in `/tmp` (fresh install on both doors, re-run idempotency, install over a fully user-owned project, and the More-options override) and it behaves exactly as decided. The gap with teeth: the decision enumerates five scaffold files and `README.md` isn't one of them, so README still runs on the old rules — silently mutated, unmarked, and pointing at the wrong manual.

### Findings

- [ENHANCEMENT] `README.md` sits outside the decided install shape. Verified on a project owning its own `DOCUMENTATION.md`: `CLAUDE.md`/`AGENTS.md` retarget to `SPRINTDOCUMENTATION.md`, but README's pointer (`setup.sh:471`, written at `setup.sh:636` — long before `MANUAL_FILE` resolves at `setup.sh:1061`) still points at the *user's* `DOCUMENTATION.md`. It also carries no versioned marker (so our block can never be upgraded) and isn't deferred into `CONFLICTS` (so it's the one scaffold file with no override).
- [ENHANCEMENT] The decided install contract is undocumented — nothing in `DOCUMENTATION.md`, `GETSTARTED.md`, `docs/sprintbias/`, or `docs/guides/` mentions the two doors, the silent batch, `More options?`, the ownership marker, or the `SPRINTDOCUMENTATION.md` fallback. GitHub Issues sync moved behind the gate and is now effectively unfindable.
- [NIT] `docs/tasks/review/307-…md` lines 138 and 263 still describe the retired three-way override; the shipped `resolve_conflict_interactive` is binary. Its success criteria are correct — only the narrative is stale.
- FILED: docs/tasks/backlog/359-bring-readme-md-into-the-easy-button-install-shape.md
- FILED: docs/tasks/backlog/360-document-the-two-door-install-shape-in-the-shipped.md

Verified working, no action needed: both doors write correct `CLI`/`PROVIDER` and run an identical batch; re-run at the same version is a clean no-op (one marker per file, no double-inject); user-owned `CLAUDE.md`/`AGENTS.md`/`.gitignore` bodies survive prepend intact; #307's Rework round 1 `sed` delimiter bug is fixed and both docs land stamped. The audit report is appended to the task file; no code was edited and the temp installs are cleaned up.
