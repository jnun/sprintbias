# Task 359: Bring README.md into the Easy Button install shape: versioned marker, manual retarget, conflict deferral

**Feature**: none
**Created**: 2026-08-10
**Docs**: none
**Plan**: 21
**Depends on**: none
**Dependents**: 361, 362
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 1

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

<!-- Clear, simple language. Concisely define the problem at a high level —
     who is stuck, what is wrong, why it matters. 2–5 short sentences.
     User-story height — not a build plan. -->

**Why:** Task 306 decided the Easy Button install shape and named exactly five
scaffold files (GETSTARTED.md, CLAUDE.md, the manual, .gitignore, AGENTS.md).
`README.md` was never in that decision, so it still runs on the *old* rules
while every other file moved to the new ones — and the installer touches it
before the new machinery even exists.

Three concrete gaps, verified against a real install:

1. **Wrong pointer target.** `README_POINTER` (setup.sh:471) hardcodes
   `DOCUMENTATION.md`. When the user owns their own `DOCUMENTATION.md` and our
   manual installs as `SPRINTDOCUMENTATION.md`, `CLAUDE.md` and `AGENTS.md`
   correctly retarget via `$MANUAL_FILE` but README does not. Reproduced: an
   install over a project with its own `DOCUMENTATION.md` leaves README saying
   "Project documentation → see DOCUMENTATION.md" — pointing at the *user's*
   file, not our manual. This is 306's own flagged retarget hazard, missed on
   README because README sits outside the decided batch. The README block is
   also written at setup.sh:636, hundreds of lines *before* `MANUAL_FILE` is
   resolved (setup.sh:1061), so the fix is an ordering change, not a variable
   swap.
2. **No ownership marker.** The injected pointer carries only a text marker
   (`managed by [SprintBias]`), not the versioned sentinel
   (`<!-- SprintBias vX.Y.Z -->`) that 306 made the basis of ours-vs-theirs and
   current-vs-stale. Our README block can therefore never be upgraded — a
   re-run can only see "present" or "absent," never "stale."
3. **Not deferred to `CONFLICTS`.** A user-owned README is silently prepended
   during the batch instead of being deferred, so it is the one scaffold file
   the user cannot direct under `More options?` (Prepend / Overwrite). It is
   also the most visible file in the repo — the one silent whole-file mutation
   with no override path.

Secondary: the `No README.md found. Create one…? [y/N]` prompt (setup.sh:623)
is the last surviving scaffold question on the default path, and its "no"
default means the Easy Button user gets no README pointer at all.

## Success criteria

<!-- What done looks like. When these are met, the task is done.
     Observable checks anyone can verify. For a library or detailed technical
     fix, state the new technical needs as outcomes — still not a step outline. -->

- [x] The README pointer references `$MANUAL_FILE` — so it reads
      `SPRINTDOCUMENTATION.md` on an install where the user owns
      `DOCUMENTATION.md`, matching what CLAUDE.md and AGENTS.md already do.
      Verified by installing over a project that has its own DOCUMENTATION.md.
- [x] The block we inject into a user's README carries the versioned marker
      (`<!-- SprintBias vX.Y.Z -->` … `<!-- end SprintBias -->`), and a re-run
      at a newer version upgrades that block in place while leaving the user's
      body untouched. Pre-rebrand `managed by [sprint.md]` / current
      `managed by [SprintBias]` text pointers are still recognized as ours and
      upgraded to the marked form rather than duplicated.
- [x] README joins the scaffold batch in file order and a user-owned README is
      deferred into `CONFLICTS` like CLAUDE.md/AGENTS.md — silently prepended
      on the default path, and offered Prepend / Overwrite under
      `More options?`.
- [x] The default path asks no README question: absent → create with the
      pointer silently; present → prepend or no-op. The
      `No README.md found. Create one…?` prompt is gone.
- [x] Re-running the installer twice at the same version is a no-op on README —
      one marker, no duplicated block.

## Notes

<!-- Optional helpful hints that assist the developer: constraints, edge cases,
     gotchas. Guidance from answered questions also lives here when it shapes
     how (and is not already a success criterion). Leave empty if none. -->

**Scope:** one section of `setup.sh` — move the README block out of its current
early position (setup.sh:621–660) and into the silent scaffold batch
(setup.sh:1128–1140), after `MANUAL_FILE` is resolved, reusing the existing
`scaffold_pointer` / `classify_target` / `_replace_md_block` /
`_prepend_md_block` helpers rather than adding new ones. README is *not* a whole
file we own (we never ship a README — the user owns theirs), so it takes the
pointer-block treatment, never `install_owned_doc`.

One decision the implementer owns: `already_ours_readme` currently matches text
(`managed by [SprintBias]` / legacy `managed by [sprint.md]`). Keep it as a
*legacy* recognizer so pre-marker installs upgrade to the marked block instead
of getting a second pointer; the versioned marker becomes the going-forward
signal.

Two sharp edges found while checking the code:

- `classify_target` calls a legacy text-pointer README "theirs" (no version
  marker), which would defer it to `CONFLICTS` and prepend a *second* pointer.
  The legacy recognizer has to run ahead of that verdict and route to an
  upgrade instead. `_replace_md_block` (setup.sh:823) only strips
  marker-delimited blocks, so removing the old single-line pointer needs its
  own handling.
- `apply_conflict` (setup.sh:923) hardcodes `pointer_block` for kind
  `pointer` — the CLAUDE.md/AGENTS.md wording, not the README blockquote.
  README needs its own kind (or a conflict entry that carries its block) so
  Prepend/Overwrite writes the README pointer, not the AI pointer.

Batch position: add README as a sixth entry after `AGENTS.md`
(setup.sh:1143) and extend the enumerating comment above it; that keeps the
existing five in the order 306 decided.

Ships via `setup.sh` only — the installer is edited directly at the repo root
and is not mirrored by `ship.sh`. Verify with the standard fresh-install check
plus a re-run over an existing install.

## References

<!-- Direct paths to docs or files known to be related. One path per line.
     Leave empty if none. -->

setup.sh
docs/tasks/review/306-decide-setup-install-ai-defaults-claude-grok-only.md
docs/tasks/review/307-rewire-setup-sh-into-the-two-door-easy-button-inst.md
docs/plans/12-simplify-setup.md
docs/tests/test-setup-detection.sh

## Questions

**Status: READY**

### Already complete

All five success criteria are implemented in `setup.sh` and verified by reading
the current code:

- `README_POINTER` is gone; `readme_block()` (setup.sh:758–761) emits
  `<!-- SprintBias vX.Y.Z -->` … `<!-- end SprintBias -->` and interpolates
  `$MANUAL_FILE` into both link text and href, so an install over a user-owned
  `DOCUMENTATION.md` points at `SPRINTDOCUMENTATION.md`.
- `scaffold_readme()` (setup.sh:868–891) checks `already_ours_readme` ahead of
  the `theirs` verdict and routes a legacy text pointer to
  `_replace_readme_pointer`; otherwise it runs the same four states as
  `scaffold_pointer` (create / no-op / upgrade / defer).
- A user-owned README defers via `CONFLICTS+=("readme|…")` (setup.sh:887), and
  `apply_conflict` selects by kind — `readme` → `readme_block`, else
  `pointer_block` (setup.sh:946–949) — so Overwrite writes the README
  blockquote, not the AI-instruction wording.
- README is the sixth entry in the scaffold batch after `AGENTS.md`
  (setup.sh:1160–1161 comment, call at setup.sh:1168), placed after
  `MANUAL_FILE` resolves; the `No README.md found. Create one…? [y/N]` prompt is
  gone (no match anywhere in the file).
- `SPRINT_README_MARKER` remains a substring of what `readme_block` writes, and
  the unit-tested sentinel block (setup.sh:490–514) is intact.

Quality concern — the rework defect is real and reproduces. Running
`_replace_readme_pointer`'s awk (setup.sh:811–815) over a legacy-pointer README
whose body contains "Our docs managed by [SprintBias] on every page." deletes
that body line: the `managed by` rule at setup.sh:812 has no `seen==0` guard, so
it drops every matching line in the file, not just the leading pointer its own
comment describes.

The manual is untouched: `DOCUMENTATION.md` and `src/DOCUMENTATION.md` have zero
occurrences of "README", and the "Silent scaffold (Easy Button)" list
(DOCUMENTATION.md:319–332) still enumerates four numbered entries with no README.
Both copies are byte-identical in that range, so `src/VERSION` (0.0.79) reflects
a shipped tree that documents none of this.

### Remaining work

The three unchecked items under ## Rework (round 1) are the whole of it:

- Guard the `managed by` deletion in `_replace_readme_pointer` (setup.sh:812)
  with the same `seen==0` test the blank-line rule already uses, so nothing
  below the user's first real content line is removed. Prove it with a
  legacy-pointer README whose body also contains the marker text: body line
  survives, top pointer becomes the marked block, one marker total.
- Name README.md in `DOCUMENTATION.md → Installing SprintBias` — add it to the
  "Silent scaffold (Easy Button)" list (created with the pointer when absent,
  our block prepended when the user owns one) keeping the existing entries in
  306's order, and state under "Your files stay yours" that a user-owned README
  defers like CLAUDE.md/AGENTS.md: silent Prepend by default, Overwrite only
  under `More options?`.
- Run `./ship.sh` so the manual edit reaches `src/DOCUMENTATION.md` (the copy
  `setup.sh` installs), then re-verify a fresh install serves the updated text.
  `setup.sh` itself is edited at the repo root and is not mirrored.

Re-run `docs/tests/test-setup-detection.sh` after the awk change — the sentinel
block must still source cleanly.

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

## Completed

README.md now runs on the same rules as every other scaffold file. The pointer
moved out of its early standalone block and into the silent scaffold batch as
the sixth entry, after `MANUAL_FILE` resolves.

- `README_POINTER` (a fixed string naming `DOCUMENTATION.md`) is gone, replaced
  by `readme_block()` sitting next to `pointer_block()`. It emits the versioned
  marker plus the reader-facing blockquote and interpolates `$MANUAL_FILE`
  twice (link text and href), so an install over a user-owned
  `DOCUMENTATION.md` points at `SPRINTDOCUMENTATION.md`. The
  `managed by [SprintBias]` text stays inside the block, keeping
  `SPRINT_README_MARKER` a substring of what we write.
- New `scaffold_readme()` mirrors `scaffold_pointer()`'s four states and adds
  one ahead of them: a README carrying the pre-marker text pointer classifies as
  `theirs`, so `already_ours_readme` is checked first and routes to
  `_replace_readme_pointer()` — a small helper that drops the bare pointer line
  and the blank lines it leaves behind (no marker for `_replace_md_block` to
  match), then writes the marked block above the untouched body.
- A genuinely user-owned README defers via `CONFLICTS+=("readme|…")`, so it gets
  the silent prepend on the default path and Prepend / Overwrite under
  `More options?`. `apply_conflict` now selects the block by kind — `readme` →
  `readme_block`, everything else → `pointer_block` — so Overwrite writes the
  README pointer, not the AI-instruction wording.
- The `No README.md found. Create one…? [y/N]` prompt is deleted; absent →
  created silently. With it went the last content under the
  `Setting up documentation files...` header, which would have printed with
  nothing beneath it, so that section is now titled for what it actually holds
  (detection + decision helpers).
- The unit-tested sentinel block is untouched; `docs/tests/test-setup-detection.sh`
  passes 26/26.

Verified against real installs (each a fresh temp dir, `bash -n` clean):

- Fresh: `README.md ensured`, one marked block naming `DOCUMENTATION.md`.
- Re-run at the same version: `README.md up to date (v0.0.79)`, byte-identical,
  one marker.
- Over a project owning `DOCUMENTATION.md` **and** its own README: pointer reads
  `SPRINTDOCUMENTATION.md`, deferred then silently prepended, user body intact,
  user manual untouched.
- Over a legacy `managed by [sprint.md]` README:
  `pointer upgraded (unversioned → 0.0.79)` — one marker, one pointer line, body
  kept.
- Over an `<!-- SprintBias v0.0.10 -->` README: `upgraded (0.0.10 → 0.0.79)`,
  body kept.
- `More options?` → `o`: `Overwrote README.md with SprintBias pointer`, and the
  file holds the README blockquote (not the AI pointer).
- Regression: a user-owned `CLAUDE.md` still receives the AI pointer block.

Scaffold batch order is now GETSTARTED.md, CLAUDE.md, the manual, .gitignore,
AGENTS.md, README.md — the five 306 decided, in place, plus README last.

### Files changed
setup.sh
docs/tasks/doing/359-bring-readme-md-into-the-easy-button-install-shape.md

## Rework (round 1)

**Why:** Two gaps sit outside the five criteria but inside the contract this
task is finishing. (1) `_replace_readme_pointer` (setup.sh:805–822) drops
*every* line matching `managed by [SprintBias|sprint.md]`, not just the leading
pointer its own comment describes — reproduced against a real install: a legacy
README whose body contained "docs managed by [SprintBias] on every page" came
back with that body line silently deleted. That is a user-owned line lost, the
one thing `DOCUMENTATION.md → Your files stay yours` promises never happens.
(2) The shipped manual has zero mentions of README.md: its "Silent scaffold
(Easy Button)" list (DOCUMENTATION.md:322–326) still enumerates four files, so
the installer now creates or prepends to the most visible file in a user's repo
with no question and no documentation. No other member of Plan 21 owns that —
#360 does not mention README, #361 is tests, #362 is smoke.

**Improve:**
- [x] Scope `_replace_readme_pointer`'s deletion to the leading legacy pointer
      only (guard the `managed by` rule with the same `seen==0` test the
      blank-line rule already uses), so nothing below the user's first real
      content line is ever removed. Verify with a legacy-pointer README whose
      body also contains the marker text: the body line survives, the top
      pointer is replaced by the marked block, one marker total.
- [x] Add README.md to `DOCUMENTATION.md → Installing SprintBias`: name it in
      the "Silent scaffold (Easy Button)" ordered list as the file it now is
      (created with the pointer when absent, our block prepended when the user
      owns one), and say in "Your files stay yours" that a user-owned README is
      deferred like CLAUDE.md/AGENTS.md — silent Prepend by default, Overwrite
      only under `More options?`. Keep the existing five entries in the order
      306 decided.
- [x] Run `./ship.sh` so the manual edit reaches `src/DOCUMENTATION.md` (the
      copy `setup.sh` actually installs) and re-verify a fresh install serves
      the updated text.

## Completed (round 1 rework)

Both gaps closed; version is now 0.0.80.

- `_replace_readme_pointer` (setup.sh:812) now guards the `managed by` rule with
  `seen==0`, matching the blank-line rule beside it, so only the leading legacy
  pointer is dropped and nothing below the user's first real content line is
  touched. Verified against a real install: a legacy `managed by [sprint.md]`
  README whose body contained "Our docs managed by [SprintBias] on every page."
  came back with that body line intact, the top pointer replaced by the marked
  block, and one marker total (`pointer upgraded (unversioned → 0.0.79)`).
- `DOCUMENTATION.md → Installing SprintBias` now names README.md. The "Silent
  scaffold (Easy Button)" list gains it as entry 5 (created with the pointer
  when absent, our block prepended when the user owns one) with 306's five
  entries left in place, and "Your files stay yours" states that a user-owned
  README defers like CLAUDE.md/AGENTS.md — silent Prepend by default, Overwrite
  only under `More options?`.
- `./ship.sh` mirrored the manual into `src/DOCUMENTATION.md` and bumped
  0.0.79 → 0.0.80; src verified a clean mirror. A fresh install then served the
  updated manual (README named at DOCUMENTATION.md:329 and :348 in the installed
  copy) and wrote a `<!-- SprintBias v0.0.80 -->` README; re-running at the same
  version reported `README.md up to date (v0.0.80)` with one marker.
- `bash -n setup.sh` clean; `docs/tests/test-setup-detection.sh` 26/26 passing.

### Files changed
setup.sh
DOCUMENTATION.md
src/DOCUMENTATION.md
src/VERSION
docs/tasks/doing/359-bring-readme-md-into-the-easy-button-install-shape.md

Note for the committer: `./ship.sh` mirrors whole trees, so this run also
carried ~38 already-uncommitted `docs/sprintbias/` edits from earlier work into
`src/`. Those are not this task's changes — the files this task authored are the
five listed above.

<!--
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->
