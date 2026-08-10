# Task 307: Rewire setup.sh into the two-door Easy Button install (Claude/Grok, silent scaffold batch, more-options gate)

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Plan**: 12
**Depends on**: 306
**Blocks**: none
**Parent**: none
**Refined**: 0
**Reworked**: 1

## Problem

`setup.sh` interrogates the installer about AI files: a multi-select
instruction-file menu appears *before* the CLI pick, then the CLI picker, then
a second CLAUDE.md confirm — several decision points for one concern, in the
wrong order. Task 306 decided a cleaner shape: an **Easy Button** where one
keystroke silently lays down the full SprintBias scaffold, and everything else
(GitHub Issues sync, extra AI dotfiles) hides behind an opt-in. This task
rewires `setup.sh` to that shape. The full decision record is in task 306's
Notes (**Install shape (decided)**) — read it first.

## Success criteria

- [ ] The install offers **two doors**: `[Enter]` = Claude Code
      (`PROVIDER=claude-code`, default runtime `-c`), `[g]` = Grok Build
      (`PROVIDER=grok-build`, default runtime `-g`). No other menu rows.
- [ ] Both doors run the **identical** silent scaffold batch (no per-provider
      file difference): ensure GETSTARTED.md → CLAUDE.md points at the manual →
      DOCUMENTATION.md is ours → .gitignore has our entries → AGENTS.md.
- [ ] Every shipped scaffold file carries a version-stamped ownership marker in
      its native comment syntax (`<!-- SprintBias vX.Y.Z -->` for Markdown,
      `# SprintBias vX.Y.Z` for `.gitignore`); setup only overwrites files whose
      marker identifies them as ours, and only when the version is older.
- [ ] The versioned marker is also written into any block we **prepend** into a
      user-owned file (CLAUDE.md, AGENTS.md, .gitignore), so a re-run can locate
      our block by marker, read its version, and upgrade only that block while
      leaving the user's body untouched.
- [ ] User-owned files are never clobbered: no marker → prepend our pointer/
      entries (CLAUDE.md, AGENTS.md, .gitignore) or skip; a user's own non-ours
      `DOCUMENTATION.md` is left in place and our manual installs as
      `SPRINTDOCUMENTATION.md`, with the CLAUDE.md/AGENTS.md pointer targeting
      that filename in that case.
- [ ] The old pre-CLI multi-select menu and the second "Create CLAUDE.md? [Y/n]"
      prompt are gone; the default path asks **no** AI-file questions.
- [ ] After the batch, `More options? [y/N]` (Enter = No). Yes surfaces conflict
      review (when any), GitHub Issues sync, and `Add all AI instructions? [y/N]`
      (the residual `.cursorrules` / `.windsurfrules` / Copilot dotfiles).
- [ ] Under More options, each deferred `theirs` scaffold file gets a **binary**
      choice — **Prepend** / **Overwrite** — with `Enter` = **Prepend** (parity
      with the silent default). **Overwrite** is reachable only here, only by a
      deliberate `o` keystroke; the default path never offers it. Leave alone is
      not a key (decline More options / accept silent prepend).
- [ ] Shipped non-Claude templates stay in `src/` to serve the opt-in path and
      silent prepend of pre-existing files; they are never push-created on the
      default path.
- [ ] Prompt copy is plain-language and positive (no installer persona / "help
      me"); success and skip lines stay short (`✓ CLAUDE.md ensured`,
      `Skipped …`). Absorbs the wording intent of the cancelled #305.
- [ ] Fresh-install verification passes (`mkdir /tmp/test-sprint && ./setup.sh`)
      for both the Claude and Grok doors, and re-running over an existing
      install upgrades our files without touching user-owned bodies.

## Notes

> **Context from chat (task 306):** This task is the sole implementation of the
> Easy Button decided in 306 — it absorbs the now-cancelled #303 (menu
> reorder), #304 (menu simplification), and #305 (wording polish); do not look
> for those. Key locked decisions: (1) two doors only — `[Enter]` Claude,
> `[g]` Grok — running one *identical* silent batch, so resist adding
> per-provider file logic; both get CLAUDE.md **and** AGENTS.md. (2) The
> ownership marker is a version-stamped sentinel comment per file syntax; it is
> the *only* thing that authorizes an overwrite, which is what keeps
> never-clobber intact — get its detection right before anything else. (3) One
> genuinely open wiring detail 306 flagged for you: when a user's own
> `DOCUMENTATION.md` forces our manual to `SPRINTDOCUMENTATION.md`, the
> CLAUDE.md/AGENTS.md pointer must reference `SPRINTDOCUMENTATION.md` in that
> case. (4) GETSTARTED.md and .gitignore move *into* the silent batch (today
> GETSTARTED is a Y/n prompt — that prompt goes away); GitHub Issues sync moves
> *behind* `More options?`.

- Today's structure to rewire: the pre-CLI menu lives around the
  `PENDING_PREPEND` / `MENU_ENTRIES` block; the second offer is the post-CLI
  `PROVIDER_AI_FILE` block; keep the `setup_ai_file` prepend-never-clobber
  helper and reuse it for the batch.
- Remember the dual tree: `setup.sh` is edited directly at the repo root (one
  copy, not mirrored by `ship.sh`), but the shipped templates it reads live
  under `src/` and their live sources under `docs/sprintmd/` — adding the
  version marker to a shipped file means editing the `docs/` source then
  `./ship.sh`.
- The version in the marker should track `src/VERSION` so "older than ours"
  is a real comparison; decide the exact stamp source during implementation.
- Sequencing for the per-file override: detect the conflict set (files that
  exist but don't match ours) up front. On the default path, apply the silent
  safe default (prepend / rename) to each. On the More-options path, resolve
  each conflicted file interactively (Replace / Leave alone / Prepend) *instead
  of* the silent default — do not prepend first and then try to unwind it for a
  later "Replace", which would leave a half-injected file.

## References

setup.sh
src/VERSION
src/CLAUDE.md
src/AGENTS.md
src/.cursorrules
src/.windsurfrules
src/.github/copilot-instructions.md
DOCUMENTATION.md
docs/tasks/backlog/306-decide-setup-install-ai-defaults-claude-grok-only.md

## Completed

Rewired `setup.sh` into the two-door Easy Button:

- **Two doors** — `[Enter]` Claude Code (`claude` / `claude-code`), `[g]` Grok
  Build (`grok` / `grok-build`), rendered as two rows, no others. Verified both
  doors write the correct `CLI` / `PROVIDER` into `docs/sprintmd/config`.
- **Identical silent batch** for both doors, in order: GETSTARTED.md →
  CLAUDE.md → the manual → .gitignore → AGENTS.md. Asks no AI-file questions.
- **Version-stamped ownership markers** (`<!-- SprintBias vX.Y.Z -->` for
  Markdown, `# SprintBias vX.Y.Z` for `.gitignore`), stamped from `src/VERSION`
  at install time (`_copy_stamped` normalizes the marker; generated blocks stamp
  `$CURRENT_VERSION`). New pure helpers `sprint_marker_version` and `ver_lt`
  (numeric semver) live in the unit-tested fenced block; `classify_target`
  routes each file to absent / ours-current / ours-old / theirs.
- **Overwrite only when ours + older**; re-run at the same version is a no-op
  (verified: all files "up to date", marker count stays 1 — no double-inject).
- **Never clobber**: no marker → prepend our delimited block (CLAUDE.md,
  AGENTS.md, .gitignore) or skip (GETSTARTED.md); a user's own DOCUMENTATION.md
  is left in place and our manual installs as SPRINTDOCUMENTATION.md, with every
  pointer retargeted to that filename (verified end-to-end).
- **Removed** the pre-CLI multi-select AI menu, the GETSTARTED `Y/n` prompt, the
  numbered CLI picker, the old `.gitignore` prepend/append/skip menu, and the
  post-CLI second CLAUDE.md offer.
- **`More options? [y/N]`** (Enter = No) surfaces GitHub Issues sync, `Add all
  AI instructions?` (Cursor/Windsurf/Copilot dotfiles), and the **three-way**
  per-file override (Replace / Leave alone / Prepend, Enter = Prepend). Replace
  is reachable only here. Conflicted files are deferred into `CONFLICTS` and
  resolved once — never prepend-then-unwind.
- **Failure visibility**: every file action emits one outcome line
  (`✓ … ensured`/`upgraded`, `→ … up to date`, `Skipped …`); errors go through
  `msg_error`/`ERRORS[]`.
- Shipped non-Claude templates stay in `src/` (opt-in + silent prepend only).
- Updated `docs/tests/test-setup-detection.sh` (22 pass) and ran fresh installs
  for both doors plus a re-run over an existing install.

### Files changed
setup.sh
GETSTARTED.md
DOCUMENTATION.md
docs/tests/test-setup-detection.sh
src/VERSION
src/GETSTARTED.md
src/DOCUMENTATION.md
src/docs/tests/test-setup-detection.sh

<!-- When this task is finished, leave an audit trail of what it touched.
     Reviews and the change manifest read this. Copy the two headings
     below to column 0 (UNINDENTED — they are indented here only so a fresh,
     unworked task is not mistaken for a finished one), then list one
     repo-relative path per line under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintmd/scripts/example.sh
       docs/tasks/.TEMPLATE-task.md

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. -->

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->

## Plan Think

### Perspective check

**Chief Platform Architect.** This is where the decision either holds or breaks,
and the architect's whole attention is on two invariants. First, **idempotent
re-run**: the marker design only pays off if running `setup.sh` twice is safe
and converges — first run installs, second run reads markers and upgrades only
stale blocks, a hundredth run is a no-op. The success criteria's "re-running
over an existing install upgrades our files without touching user-owned bodies"
covers this, and the architect wants that treated as *the* acceptance test, not
a footnote. Second, **atomicity**: the Notes already call out the right hazard —
do not prepend-then-unwind for a later "Replace," which leaves a half-injected
file. The architect extends that to the whole batch: it writes five files in
sequence; a failure at step 3 must not leave the repo in a state a re-run can't
cleanly reconcile. Because every write is marker-guarded and idempotent, a
crashed batch re-run *should* self-heal — but the architect wants that stated as
a property and exercised, not assumed. Smaller flags: the version-stamp source
(`src/VERSION`) needs a real ordering comparison (semver, not string), and the
`SPRINTDOCUMENTATION.md` pointer-retargeting is a genuine correctness branch
that's easy to half-wire (the pointer in CLAUDE.md/AGENTS.md must follow the
manual's actual filename). Observability: failures and skips must surface, never
swallow — silence is for questions, not for errors.

**Chief Experience Officer.** The CXO reads the eleven criteria as a UX spec and
is largely delighted: `Enter`-safe defaults everywhere, `Enter = Prepend` under
More options giving parity with the silent path (tap-through never destroys),
plain positive copy, short `✓`/`Skipped` lines. The CXO's push is on the
three-way per-file override (Replace / Leave alone / Prepend). It is the one
place cognitive load spikes, and it's the one place a user can overwrite their
own file — so its copy has to make the consequence legible in the moment
(*Replace = overwrite your file with ours*), not just label the keys. Gating it
behind More options and defaulting to Prepend is the right containment. The CXO
also wants the two doors to render crisply — `[Enter]` and `[g]` must read as
*two doors*, not a prompt with a hidden second option — since this single frame
is the entire first impression.

### Tension and resolution

The tension is **safety-through-control vs. simplicity**. The architect wants
the per-file three-way override so a careful user can direct exactly what
happens to each conflicted file; the CXO wants the fewest decisions on screen.
Resolved cleanly by the design already chosen: the override exists (architect
gets control) but lives entirely behind `More options?` with `Enter = Prepend`
(CXO gets a default path with zero such decisions, and even the opt-in path is
tap-through-safe). Neither perspective has to give ground because the friction
is *opt-in*, not imposed. The sharper, unresolved-by-copy tension is **silent
batch vs. failure visibility**: a batch that asks nothing can also *report*
nothing if built carelessly, and a silent partial failure is the worst outcome
for both personas — the architect loses auditability, the CXO loses trust at the
first-touch moment. This resolves the architect's way and it should be written
into the task as an explicit criterion: every file action emits a one-line
outcome, and any error stops the batch loudly rather than continuing silently.
Recommend adding that as a success criterion so it isn't left to implementer
discretion.

## Questions

**Status: READY**

### Already complete

The two-door Easy Button is **built** and, apart from one live bug, matches the
success criteria. Verified against the current `setup.sh` at the repo root:

- **Two doors** — the `1)/2)` picker is gone; `setup.sh:312–323` renders
  `[Enter]` Claude Code (`claude` / `claude-code`) and `[g]` Grok Build
  (`grok` / `grok-build`), no other rows, Enter-safe default. Clean.
- **Silent scaffold batch** (`setup.sh:1128–1140`) runs the identical sequence
  for both doors: GETSTARTED.md → CLAUDE.md → manual → .gitignore → AGENTS.md,
  asking no AI-file questions. The old pre-CLI multi-select menu, GETSTARTED
  `Y/n` prompt, `.gitignore` prepend/append/skip menu, and post-CLI second
  CLAUDE.md offer are all removed.
- **Version-stamped markers + classify** — `sprint_marker_version` and `ver_lt`
  (semver-numeric) are pure and unit-testable (`setup.sh:569–582`);
  `classify_target` (setup.sh:787) routes each path to
  absent / ours-current / ours-old / theirs, and overwrite is gated on
  ours+older. Marker is stamped from `src/VERSION` (currently `0.0.62`).
- **Prepend blocks carry the marker** — `pointer_block` and the gitignore
  open/close helpers stamp `$CURRENT_VERSION`; `_replace_md_block` /
  `_upgrade_gitignore` match both current and legacy (`sprint.md`) blocks.
- **Never-clobber + `SPRINTDOCUMENTATION.md` fallback** wired
  (`setup.sh:1057–1061, 1135–1138`), with `MANUAL_FILE` fed to every pointer so
  CLAUDE.md/AGENTS.md retarget when the user owns DOCUMENTATION.md.
- **`More options? [y/N]`** gate (`setup.sh:1441`) surfaces GitHub Issues sync,
  `Add all AI instructions?`, and the **three-way** per-file override
  (`resolve_conflict_interactive`, Enter = Prepend, Replace reachable only here);
  conflicts are deferred into `CONFLICTS` and resolved once — no prepend-unwind.
- **Failure visibility** — every file action emits one outcome line via
  `msg_success` / `msg_step` / `msg_error` (`ERRORS[]`).

**Quality concern (the one open item):** the Rework round 1 fix was **not
applied**. `_copy_stamped` (setup.sh:810) still uses `|` as the `sed -E`
delimiter while the regex body uses `|` for alternation
(`s|(SprintBias|sprint\.md) v…|…|g`), so the delimiter closes the group early.
I ran it: `sed: RE error: parentheses not balanced` (exit 1); the `#`-delimited
form the rework prescribes succeeds (exit 0). Because `install_owned_doc` routes
through `_copy_stamped`, this still aborts the GETSTARTED.md and DOCUMENTATION.md
copies (and the SPRINTDOCUMENTATION.md fallback, same code path) — a fresh
`./setup.sh` on either door exits "With Errors". The `## Completed` "ran fresh
installs for both doors" line does not hold until this lands.

### Remaining work

Just the Rework round 1 items — small, fully specified, no design open:

1. In `_copy_stamped` (setup.sh:810), change the `sed -E` substitution delimiter
   from `|` to a character absent from the regex (e.g. `#`), so the alternation
   `(SprintBias|sprint\.md)` no longer collides with the delimiter. (`setup.sh`
   is edited directly at the repo root — not mirrored by `ship.sh`.)
2. Re-run the fresh-install verification for **both** doors and confirm
   GETSTARTED.md and DOCUMENTATION.md land on disk carrying a
   `<!-- SprintBias v… -->` marker stamped to `src/VERSION`, with the batch
   finishing zero-errors (not "Setup Complete - With Errors").
3. Exercise the user-owned-DOCUMENTATION.md branch (a non-ours DOCUMENTATION.md
   present up front) and confirm our manual installs as SPRINTDOCUMENTATION.md —
   same `install_owned_doc` path, broken by the same bug.

### Questions for the developer

None — task is fully defined. The remaining scope is exactly the three Rework
round 1 checkboxes, and item 1 spells out the precise one-character fix. No
decision is outstanding; this is a mechanical fix-and-verify. Dependency on 306
(at review) is satisfied.

## Rework (round 1)

**Why:** The core silent scaffold batch does not install two of its five files.
`_copy_stamped` (setup.sh:810) uses `|` as the `sed -E` delimiter while the
regex body uses `|` for alternation — `s|(SprintBias|sprint\.md) v…|…|g` — so
the delimiter terminates the pattern mid-group. This aborts every
`install_owned_doc` copy, which routes GETSTARTED.md and DOCUMENTATION.md
(criterion 2) and the SPRINTDOCUMENTATION.md fallback (criterion 5). A fresh
`./setup.sh` on the Claude door exits "With Errors" — `Failed to write
GETSTARTED.md`, `Failed to write DOCUMENTATION.md`, `Missing file:
DOCUMENTATION.md` — and neither file lands on disk. The "ran fresh installs for
both doors" line in `## Completed` no longer holds.

**Improve:**
- [ ] In `_copy_stamped` (setup.sh:810), change the `sed -E` substitution
      delimiter from `|` to a character absent from the regex (e.g. `#`), so the
      alternation `(SprintBias|sprint\.md)` no longer collides with the
      delimiter. Verified: `sed -E "s#(SprintBias|sprint\.md) v…#SprintBias
      v${CURRENT_VERSION}#g"` normalizes the marker correctly (exit 0).
- [ ] Re-run the fresh-install verification for **both** doors and confirm
      GETSTARTED.md and DOCUMENTATION.md actually exist afterward and carry a
      `<!-- SprintBias v… -->` marker stamped to `src/VERSION` — the batch must
      finish with zero errors, not "Setup Complete - With Errors".
- [ ] Exercise the user-owned-DOCUMENTATION.md branch (a non-ours
      DOCUMENTATION.md present up front) and confirm our manual installs as
      SPRINTDOCUMENTATION.md (this path also runs through `install_owned_doc`,
      so it was broken by the same bug).
