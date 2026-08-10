# Task 360: Document the two-door install shape in the shipped manual: doors, silent batch, More options, ownership marker, SPRINTDOCUMENTATION fallback

**Feature**: none
**Created**: 2026-08-10
**Docs**: none
**Plan**: none
**Depends on**: none
**Dependents**: none
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

**Why:** Task 306 decided a new install contract and 307 shipped it, but the
contract is documented nowhere a user or a future maintainer will look. Grepping
`DOCUMENTATION.md`, `GETSTARTED.md`, `docs/sprintbias/`, and `docs/guides/` for
"More options", "SPRINTDOCUMENTATION", "Easy Button", or the two doors returns
nothing. The only record is two task files that move to `done/` and stop being
read.

What that costs, concretely:

- **A real capability is now unfindable.** GitHub Issues sync used to be a
  top-level install question; 306 moved it behind `More options? [y/N]`
  (Enter = No). A user who taps through the Easy Button never sees it, and no
  document tells them it exists or that re-running `./setup.sh` and answering
  `y` is how to get it. Same for the Cursor / Windsurf / Copilot dotfiles.
- **An unexplained file appears in the user's repo.** When the user owns their
  own `DOCUMENTATION.md`, our manual installs as `SPRINTDOCUMENTATION.md` and
  every pointer retargets. Nothing explains why the file is named that, and the
  manual's own text still refers to itself as `DOCUMENTATION.md` throughout.
- **The safety contract is invisible.** "We only overwrite files carrying our
  own versioned marker; yours are prepended, never clobbered" is the single
  most trust-relevant thing the installer does, and the user has no way to know
  it. It is also the invariant a future change is most likely to break without
  a written spec to check against.

## Success criteria

<!-- What done looks like. When these are met, the task is done.
     Observable checks anyone can verify. For a library or detailed technical
     fix, state the new technical needs as outcomes — still not a step outline. -->

- [x] `DOCUMENTATION.md` has a short install section covering: the two doors
      (`[Enter]` Claude Code / `[g]` Grok Build, identical scaffold either way,
      changeable later in `docs/sprintbias/config`), the files the silent batch
      writes, and what `More options?` contains.
- [x] The never-clobber contract is stated in one paragraph a user can trust:
      files carrying our versioned marker are upgraded; files without it are
      yours — prepended or skipped, never overwritten on the default path.
- [x] Re-running `./setup.sh` is documented as the supported way to upgrade an
      install and to turn on anything behind `More options?` (GitHub Issues
      sync, extra AI dotfiles), with the note that a re-run at the same version
      changes nothing.
- [x] The `SPRINTDOCUMENTATION.md` fallback is explained where a user who finds
      that filename will actually look — and the manual's self-references read
      correctly under that name.
- [x] `GETSTARTED.md` points a first-time user at the install section rather
      than restating it.
- [x] `./ship.sh` run so the update reaches `src/`, and
      `./sprint.sh validate --docs` passes.

## Notes

<!-- Optional helpful hints that assist the developer: constraints, edge cases,
     gotchas. Guidance from answered questions also lives here when it shapes
     how (and is not already a success criterion). Leave empty if none. -->

**Scope:** documentation only — no installer behavior changes. Edit
`DOCUMENTATION.md` and `GETSTARTED.md` at the repo root, then `./ship.sh` to
mirror into `src/` and bump the version.

Keep it short. This is user-facing product documentation, not a spec dump: a
reader wants to know what the installer will touch, that their files are safe,
and how to get the optional pieces. The marker mechanics (semver comparison,
block delimiters, legacy `sprint.md` recognition) stay in `setup.sh` comments —
document the *contract*, not the implementation.

Source material is task 306's **Install shape (decided)** section and 307's
**Completed** section; read both before writing, and note that 307's Completed
text still describes a three-way override (Replace / Leave alone / Prepend)
while the shipped installer offers a binary one (Prepend / Overwrite, Enter =
Prepend). The binary form is what setup.sh does today and what the docs should
describe.

## References

<!-- Direct paths to docs or files known to be related. One path per line.
     Leave empty if none. -->

DOCUMENTATION.md
GETSTARTED.md
setup.sh
docs/tasks/review/306-decide-setup-install-ai-defaults-claude-grok-only.md
docs/tasks/review/307-rewire-setup-sh-into-the-two-door-easy-button-inst.md
docs/plans/12-simplify-setup.md

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

## Rework (round 1)

**Why:** The new "Installing SprintBias" section is accurate and correctly
scoped, but the fallback-name work stopped at the new blockquote. Three
self-references still name `DOCUMENTATION.md` unqualified, and on a
`SPRINTDOCUMENTATION.md` install each one now points at the *user's own* file:
`DOCUMENTATION.md:43` lists it under **Framework files (do not edit)** — telling
the user not to edit their own file while leaving the real framework manual
unprotected — and `GETSTARTED.md:23` / `GETSTARTED.md:204` send the reader to
the wrong file for the full reference. Both files install verbatim with no
`$MANUAL_FILE` interpolation, so a static qualifier is the fix. Separately the
task carries no `## Completed` / `### Files changed` block, so `work.sh`'s
router reads it as an unfinished run and every downstream audit falls back to a
whole-working-tree diff.

**Improve:**
- [x] Qualify the `DOCUMENTATION.md` entry in the **Framework files (do not
      edit)** list (`DOCUMENTATION.md:43`) so it covers the fallback name —
      e.g. `` `DOCUMENTATION.md` (or `SPRINTDOCUMENTATION.md`) `` — and reads
      correctly whichever filename the installer landed.
- [x] Qualify the two unqualified manual references in `GETSTARTED.md`
      (line 23 "outlines the entire ruleset for docs", line 204 "For the full
      reference, read …") the same way, matching the phrasing already used at
      `GETSTARTED.md:8`. Keep it short — a parenthetical, not a repeat of the
      blockquote.
- [x] Append a `## Completed` section with a `### Files changed` list naming
      exactly the files this task touched (`DOCUMENTATION.md`, `GETSTARTED.md`,
      and their `src/` mirrors), headings verbatim at column 0.
- [x] Re-run `./ship.sh` so both edits reach `src/`, and confirm
      `./sprint.sh validate --docs` still passes.

Leave the **Silent scaffold (Easy Button)** numbered list untouched — task 359's
own Rework (round 1) owns adding `README.md` and fixing that list's ordering.
Do not restate installer mechanics; this round is only about the fallback name
reading correctly and the audit trail existing.

## Questions

**Status: READY**

### Already complete

The round-0 documentation work is in place and reads well:

- `DOCUMENTATION.md:299-374` — the **Installing SprintBias** section covers all
  four criteria: two doors (`299-317`, table plus "same scaffold either way,
  change it later in `docs/sprintbias/config`"), the silent batch file list
  (`319-332`), the never-clobber contract in one paragraph (`334-343`, marker
  format, prove-it-is-ours rule, Prepend/Overwrite binary — correctly matching
  the shipped installer rather than 307's stale three-way text), `More options?`
  contents (`345-353`), and re-run-to-upgrade with the same-version no-op note
  (`355-374`).
- `DOCUMENTATION.md:6-9` — the `SPRINTDOCUMENTATION.md` fallback blockquote sits
  at the top of the manual, where a reader who opened that filename lands first.
- `GETSTARTED.md:6-9` — points at the install section instead of restating it,
  and already carries the fallback-name parenthetical that the two remaining
  references should match.
- `./ship.sh` was run: `DOCUMENTATION.md` and `GETSTARTED.md` are byte-identical
  to their `src/` mirrors, and `./sprint.sh validate --docs` passes clean.

Scope held to documentation — `setup.sh` is untouched, and the marker mechanics
correctly stayed out of the manual.

### Remaining work

All four Rework (round 1) items are still open — verified against the files:

- `DOCUMENTATION.md:43` still lists a bare `` `DOCUMENTATION.md` `` under
  **Framework files (do not edit)**. On a fallback install this points at the
  user's own file. Qualify it (e.g. `` `DOCUMENTATION.md` (or
  `SPRINTDOCUMENTATION.md`) ``). This is the only unqualified self-reference
  left in the manual — lines 6-9 and 326-327 already read correctly.
- `GETSTARTED.md:23` ("DOCUMENTATION.md outlines the entire ruleset for docs")
  and `GETSTARTED.md:204` ("For the full reference, read `DOCUMENTATION.md`.")
  are both unqualified. Add the same short parenthetical used at
  `GETSTARTED.md:8-9` — a parenthetical, not a repeat of the blockquote.
- This task file carries no `## Completed` / `### Files changed` block, so
  `work.sh` reads it as an unfinished run and downstream audits fall back to a
  whole-working-tree diff. Append it with headings verbatim at column 0, listing
  `DOCUMENTATION.md`, `GETSTARTED.md`, and their `src/` mirrors.
- Re-run `./ship.sh` so both edits reach `src/`, then confirm
  `./sprint.sh validate --docs` still passes (it passes today, so any failure is
  from this round's edits).

Leave the **Silent scaffold (Easy Button)** numbered list at
`DOCUMENTATION.md:319-332` alone — task 359 owns it.

### Questions for the developer

None — task is fully defined.

## Completed

Round 0 wrote the **Installing SprintBias** section of the manual (two doors,
silent scaffold file list, never-clobber contract, `More options?` contents,
re-run-to-upgrade) plus the `SPRINTDOCUMENTATION.md` blockquote at the top of
`DOCUMENTATION.md` and the install pointer in `GETSTARTED.md`.

Round 1 closed the fallback-name gap. Three self-references still named
`DOCUMENTATION.md` unqualified, each of which points at the *user's own* file on
a fallback install. All three now carry the same short parenthetical used at
`GETSTARTED.md:8`:

- `DOCUMENTATION.md:43` — the **Framework files (do not edit)** entry now reads
  `` `DOCUMENTATION.md` (or `SPRINTDOCUMENTATION.md`, if you already had one) ``,
  so the do-not-edit rule lands on the framework manual under either name.
- `GETSTARTED.md:23` — "DOCUMENTATION.md (or `SPRINTDOCUMENTATION.md`) outlines
  the entire ruleset for docs."
- `GETSTARTED.md:204` — "For the full reference, read `DOCUMENTATION.md` (or
  `SPRINTDOCUMENTATION.md`)."

The **Silent scaffold (Easy Button)** numbered list was left untouched — task
359 owns it. No installer behavior changed; `setup.sh` is unmodified.

`./ship.sh` mirrored both files into `src/` and bumped the version 0.0.80 →
0.0.81; ship's own verify confirms `src/` is a byte-clean mirror.
`./sprint.sh validate --docs` passes (25 commands checked, no flag drift).

### Files changed
DOCUMENTATION.md
GETSTARTED.md
src/DOCUMENTATION.md
src/GETSTARTED.md
src/VERSION
docs/tasks/doing/360-document-the-two-door-install-shape-in-the-shipped.md
