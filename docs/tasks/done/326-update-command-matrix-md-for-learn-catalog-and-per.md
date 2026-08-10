# Task 326: Update command-matrix.md for learn catalog and per-command --demo

**Feature**: none
**Created**: 2026-07-31
**Docs**: docs/guides/command-matrix.md
**Plan**: 13
**Depends on**: 313, 314
**Blocks**: none
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

`docs/guides/command-matrix.md` is the **target-state spec** for the command
surface: when live behavior and the matrix disagree, the matrix wins and a task
is filed — not the other way around. Plan 13 adds a real command (`learn`) and a
global per-command flag (`--demo`) that are not in the matrix today. If the
framework ships without updating this guide, the matrix lies, smoke tasks that
walk it (e.g. 300) miss the new surface, and placement rules for "is this a
command or a flag?" stay unrecorded for the help/demo pair.

## Success criteria

- [x] **`learn`** appears in the Target catalog under the correct family
      (**look** — read-only theater, no project mutation) with usage that matches
      live help: catalog (`learn`) and play (`learn <name>`).
- [x] **`--demo`** is documented as a **per-command flag** (not a new command and
      not a leading launcher flag like `-g`/`-c`):
      - `--help` explains; `--demo` shows the mapped walkthrough
      - help text points at `<cmd> --demo` when a demo exists
      - unmapped commands: no dead affordance on help; soft fail on bare `--demo`
- [x] Placement rules (or a short subsection) state:
      - demos that teach a host command → registry map + `<cmd> --demo`
      - demos with no host → `learn <name>` only
      - do **not** invent `demo <cmd>` or a seventh family
- [x] Matrix stays consistent with `_registry` / dispatch / help after 313+314
      (same names; no archaeology of rejected "Show me: learn …" pointer design).
- [x] No contradiction with the spine diagram or five act families; `learn` does
      not pretend to be on the chat→plan start→work spine.

## Notes

**Depends on 313 + 314** so the matrix documents *shipped* names and behavior,
not guesses. If only 313 has landed, do not invent `--demo` wording that 314
has not implemented — wait for both, or land `learn` rows first and extend in
the same task once 314 is in review.

**Out of scope:** implementing `learn` or `--demo`; writing demo scripts;
editing `DOCUMENTATION.md` beyond what matrix cross-links already require
(manual updates live on 313/314 surfaces).

**Related:** task 300 walks the matrix for emit smoke — after this update, that
harness should eventually see `learn` (and not treat `--demo` as a command row).

## References

docs/guides/command-matrix.md
docs/plans/13-autolearning.md
docs/sprintmd/help/_registry
docs/tasks/next/313-add-a-learning-feature-in-app-interactive-demos-th.md
docs/tasks/next/314-surface-a-show-me-hook-in-help-that-launches-the-m.md

## Questions

**Status: READY**

### Already complete

Nothing here yet — this is a pure documentation task and its subject matter has
not shipped. Verified against current code:

- **No `learn` row in the matrix.** `docs/guides/command-matrix.md` has no
  `learn` entry in the `look` catalog (or any family), no placement-rule
  mention, and no demo subsection.
- **No `--demo` in the matrix.** The "Global launcher flags — not commands"
  section covers only `-c`/`-g`; there is no per-command `--demo` documentation
  and the placement rules do not distinguish a help/demo flag pair.
- **The shipped surface doesn't exist yet either.** `docs/sprintmd/help/_registry`
  is still 4-field with no `learn` row and no demo column; `sprint.sh` has no
  `--demo` intercept. So there is nothing correct to document from yet — exactly
  why this task waits on 313 + 314.

The `**Depends on**: 313, 314` field is present and correct.

### Remaining work

Once 313 (learn engine + `learn` registry row) and 314 (`--demo` flag +
registry demo field) land, update `docs/guides/command-matrix.md` to match the
*shipped* names and behavior:

1. **Add `learn` to the Target catalog** under the family 313 actually ships it
   in (the plan and 313's own review point to **`look`** — read-only theater,
   no mutation), with usage mirroring live help: catalog (`learn`) and play
   (`learn <name>`).
2. **Document `--demo` as a per-command flag** — not a new command, not a
   leading launcher flag like `-c`/`-g`. State the pair: `--help` explains,
   `--demo` shows; help points at `<cmd> --demo` when a demo is mapped; unmapped
   commands get no dead affordance and a soft fail on bare `--demo`.
3. **Add placement rules** (short subsection): demos that teach a host command →
   registry map + `<cmd> --demo`; demos with no host → `learn <name>` only; do
   not invent `demo <cmd>` or a seventh family.
4. **Keep it consistent** with `_registry` / dispatch / help after 313+314 (same
   names; no archaeology of rejected "Show me: learn …" pointer design), and
   with the spine diagram / five act families (`learn` is not on the
   chat→plan start→work spine).

### Questions for the developer

None — task is fully defined. It is a documentation task gated only on its two
prerequisites: it will not stamp BLOCKED, it waits in the queue until 313 and
314 reach review/done, then transcribes whatever those tasks shipped. The one
assumption it carries — `learn` lives in the `look` family — is not a decision
this task makes; the matrix mirrors wherever 313 lands the command, and both the
plan and 313's review already point at `look`. If 313 ships `learn` in a
different family, this task documents that instead (and no matrix invariant
would be violated, since `look` is one of the six allowed labels).

## Completed

Both prerequisites had shipped (313 + 314 in `review/`), so the matrix
transcribes shipped names and behavior — no guessing:

- **`learn` row** added to the **look** catalog (`learn [name]` — catalog with no
  name, play a sandboxed demo by name), ordered to match `_registry`
  (status · search · learn · align · context). A short note grounds why it earns
  `look` (writes nothing, no mutation, no network) and states it is **not on the
  spine** — a demo *teaches* chat → plan start → work, never runs it. Fixed the
  stale "other three" count in the look prose to "the rest".

- **`--demo` documented as a per-command flag** in a new
  "Per-command flags — `--help` and `--demo`" subsection, placed right after the
  leading launcher-flags section to contrast the two flag kinds. Captures the
  shipped pair: `--help` explains / `--demo` shows; data-driven 5th registry
  field maps command → demo; mapped commands gain the `Demo: ./sprint.sh <cmd>
  --demo` `--help` pointer; unmapped commands carry no pointer and soft-fail on
  bare `--demo`; `learn` is exempt from the intercept. Explicitly: a flag on a
  command, not a command, not a launcher flag — never `demo <cmd>`.

- **Placement rules** gained a "Demos are data, not a family" block (mini table:
  host command → registry map + `<cmd> --demo`; no host → `learn <name>` only)
  and the "never mint `demo <cmd>` / no seventh family" invariant.

Verified against the shipped surface — `_registry` (`learn | look | [demo]` +
5th `demo-name` field), `sprint.sh` (`cmd_learn`, `demo_for_cmd`, `--demo`
intercept, `--help` demo pointer), and `help/learn.md`. No archaeology of the
rejected "Show me: learn …" printed-pointer design. No contradiction with the
spine diagram or five act families. Matrix-only change per scope
(implementation, demo scripts, and `DOCUMENTATION.md` beyond cross-links are out
of scope). Not shipped to `src/` — `./ship.sh` left to the developer per the
no-commit rule, and `command-matrix.md` is a dev-tree guide not mirrored by
`ship.sh`.

### Files changed
docs/guides/command-matrix.md
docs/tasks/doing/326-update-command-matrix-md-for-learn-catalog-and-per.md

<!-- When this task is finished, leave an audit trail of what it touched.
     Reviews and the change manifest read this. Copy the two headings
     below to column 0 (UNINDENTED — they are indented here only so a fresh,
     unworked task is not mistaken for a finished one), then list one
     repo-relative path per line under "Files changed":

       ## Completed

       ### Files changed
       docs/guides/command-matrix.md

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. -->

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->
