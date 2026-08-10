# Task 361: Add setup tests for binary conflict UX and MANUAL_FILE paths

**Feature**: none
**Created**: 2026-08-10
**Docs**: none
**Plan**: 21
**Depends on**: 359
**Dependents**: 362
**Parent**: none
**Tests**: docs/tests/test-setup-detection.sh
**Refined**: 1
**Reworked**: 1

## Problem

`test-setup-detection.sh` covers marker/semver/`gitignore_merge` helpers only.
The Easy Button’s high-stakes paths — binary conflict resolve, visible deferral
policy, and `$MANUAL_FILE` / `SPRINTDOCUMENTATION.md` routing — have no pure
test and are easy to regress when #359 rewires README into the same machinery.

- [x] Unit or extracted-helper tests cover `classify_target` outcomes
      (absent / ours-current / ours-old / theirs) for a pointer-style file.
- [x] Conflict action mapping is locked: default/silent path = prepend;
      interactive binary accepts Enter → prepend and `o` → replace/overwrite;
      no Leave branch required.
- [x] A non-interactive smoke or helper test proves that when
      `DOCUMENTATION.md` is theirs, the manual target name is
      `SPRINTDOCUMENTATION.md` (or equivalent pure helper returns that
      choice) and pointer blocks would reference that name.
- [x] After #359, at least one test asserts README uses the versioned marker
      path (or is classified the same as other pointer scaffolds) — fail if
      README still uses only the old text `managed by [SprintBias]` path.
- [x] `bash docs/tests/test-setup-detection.sh` (or the new script if split)
      passes; linked from this task’s **Tests** field.

## Notes

Prefer extending the fenced pure-helper extract pattern in
`test-setup-detection.sh` over a full interactive `./setup.sh` harness.
Interactive UI can stay a manual smoke in #362.

Depends on #359 so README is already on the marker path before asserting it.

Four things found in the code that shape the work:

- The extract sentinels (`setup.sh:492`/`583`) currently fence only the four
  string-pure helpers. Every function this task tests — `classify_target`
  (setup.sh:779), `pointer_block` (790), `_prepend_md_block` /
  `_replace_md_block` (810/823), `apply_conflict` (923),
  `resolve_conflict_interactive` (946) — sits outside that fence. Widen the
  fence or add a second named sentinel pair around the scaffold helpers; the
  point is that the test sources shipped code, never a restatement of it.
- Those helpers are file-touching, not string-pure. Drive them in a `mktemp -d`
  working directory and set `CURRENT_VERSION` in the test (setup.sh only
  assigns it at line 155 from `src/VERSION`, outside any fence). They also call
  `msg_success` / `msg_step` / `msg_error`, so stub those.
- Manual-name resolution is inline in the main flow (setup.sh:1060–1064), not a
  helper. Either lift it into a callable helper inside the fence or assert the
  chain the installer actually runs: a marker-free `DOCUMENTATION.md` →
  `classify_target` returns `theirs` → `MANUAL_FILE=SPRINTDOCUMENTATION.md` →
  `pointer_block` output contains that name.
- `resolve_conflict_interactive` reads a bare `read -r ans`. Feed it a real
  newline (`printf '\n' | …`) rather than `</dev/null` — the test runs under
  `set -euo pipefail` and a failing `read` at EOF aborts the script.

`run-all.sh` globs `test-*.sh` (docs/tests/run-all.sh:60), so a split-out script
named `test-setup-*.sh` is picked up automatically. If you split, update the
**Tests** field to the new path.

## References

setup.sh
docs/tests/test-setup-detection.sh
docs/tests/run-all.sh
docs/tasks/next/359-bring-readme-md-into-the-easy-button-install-shape.md

## Questions

**Status: READY**

### Already complete

All five original success criteria are met and verified in code.
`bash docs/tests/test-setup-detection.sh` → 57 passed, 0 failed;
`bash docs/tests/run-all.sh` → 19/19 scripts green.

- The scaffold fence exists and is real: `# >>> SprintBias scaffold helpers
  (unit-tested) >>>` at setup.sh:743 through setup.sh:1008, extracted by the
  second `awk` scrape at test-setup-detection.sh:32 and sourced with a hard-fail
  on an empty extract (39–46). Assertions run shipped code, not a restatement.
- `classify_target` (setup.sh:746) is covered in all four states, including
  `ours-old` across a 9.9.9 → 9.9.10 bump that a string compare would miss
  (test-setup-detection.sh:263–279).
- `apply_conflict` prepend / replace / unparseable-action-falls-to-prepend are
  locked for the `pointer` kind (281–301), and the interactive binary is driven
  with real newlines — Enter → prepend, `o` → overwrite, unlisted key → prepend,
  no Leave in the menu (310–328).
- Manual routing works end to end: the inline resolution was correctly lifted
  into `resolve_manual_file` (setup.sh:1001) with the main flow as its one
  caller, and both `pointer_block` and `readme_block` are asserted to name the
  retargeted `SPRINTDOCUMENTATION.md` (330–348).
- README is on the marker path after #359: `readme_block` stamps
  `<!-- SprintBias vX.Y.Z -->`, a README we wrote classifies `ours-current:VER`,
  and the legacy text-only pointer classifies `theirs` and is migrated in place
  by `scaffold_readme` (350–376).

Quality of the round-1 work is good — temp-dir isolation, stubbed `msg_*`, and
the `FILES_COPIED=1` seed for `set -e` are all sound. The gaps below are
coverage holes in the highest-risk branches, not defects in what exists.

### Remaining work

Round 1 left three high-stakes branches untested; the eight items under
**## Rework (round 1)** are the outcomes. Current-code pointers:

- The deferred-conflict loop is still inline at setup.sh:1524–1530, outside the
  fence — lift it into a helper the way `resolve_manual_file` was lifted, so the
  silent default path is callable.
- test-setup-detection.sh:303–308 still greps setup.sh's source text for the
  literal `apply_conflict "$_ck" "$_ct" "$_cn" prepend`. Replace it with a
  behavioral assertion that seeds `CONFLICTS` and runs the helper — proving the
  loop parses `kind|target|name` and applies prepend, not that a string exists.
- `CONFLICTS=()` (test-setup-detection.sh:249) is still declared and never read:
  nothing asserts `scaffold_pointer` (setup.sh:862–865) or `scaffold_readme`
  (setup.sh:894–897) queue a `theirs` target and leave the file byte-identical
  until the conflict pass runs.
- `apply_conflict`'s kind→block `case` (setup.sh:954–957) is exercised for
  `pointer` only; the `readme)` branch is unasserted, so swapping the two blocks
  would pass today.
- The whole `gitignore` branch is untested — `_write_gitignore_fresh`
  (setup.sh:905) is the installer's most destructive write. Set
  `GITIGNORE_CONTENT` in the test (setup.sh assigns it at 1125, outside the
  fence) and cover both `prepend` and `replace`.
- `install_owned_doc` (setup.sh:835) has no never-clobber assertion — that
  guarantee is what makes the `SPRINTDOCUMENTATION.md` retarget safe.
- Two stale docs: the fence comment at setup.sh:738 names
  `docs/tests/test-setup-scaffold.sh`, which does not exist (the extractor is
  `test-setup-detection.sh`), and docs/guides/running-tests.md:153 still
  describes the script as detection and gitignore-merge only.
- Leave `bash docs/tests/run-all.sh` green.

### Questions for the developer

None — task is fully defined.

## Completed

**2026-08-10** — 31 new assertions lock the Easy Button's high-stakes install
paths. `bash docs/tests/test-setup-detection.sh` → 57 passed, 0 failed (was 26).
`bash docs/tests/run-all.sh` → 19/19 scripts green.

Kept the single test file rather than splitting: the assert harness is already
there, and the **Tests** field stays accurate.

**Made the shipped code reachable from the test.** Added a second sentinel pair,
`# >>> SprintBias scaffold helpers (unit-tested) >>>` / `# <<< SprintBias
scaffold helpers <<<`, around setup.sh's version-marker machinery
(`classify_target` through `resolve_conflict_interactive`). The test extracts
both fenced blocks with the existing `awk` scrape and sources them, so every
assertion runs installer code, never a restatement. The scaffold block is
file-touching, so its tests run in a `mktemp -d` with `CURRENT_VERSION` /
`MANUAL_FILE` set and `msg_*` stubbed. `FILES_COPIED` is seeded non-zero — the
test runs under `set -e`, where setup.sh's `((FILES_COPIED++))` at 0 would abort
(harmless in setup.sh itself, which has no `set -e`).

**Lifted manual-name resolution into a helper.** It was inline in the main flow,
so nothing could call it. It is now `resolve_manual_file()` inside the fence and
the main flow reads `MANUAL_FILE="$(resolve_manual_file)"` — same decision, one
caller, now testable.

What the new assertions cover:

- **`classify_target`, all four states** — absent, `ours-current:9.9.9`,
  `ours-old:9.9.9` after a version bump, and `theirs` for an unmarked user file.
  The ours-old case crosses 9.9.9 → 9.9.10, so a string compare would fail it.
- **Conflict actions** — `prepend` keeps the user's body with our marker on line
  1; `replace` leaves only our block; an unparseable action takes the
  `prepend|*)` safe branch. The silent default path is asserted at its call site
  (it passes `prepend`, never `replace`).
- **The interactive binary** — Enter → prepend, `o` → overwrite, an unlisted key
  → prepend, and the menu never offers a Leave. Driven with `printf '\n' | …` as
  the task notes require; `</dev/null` would abort the test at EOF.
- **Manual routing** — a marker-free user `DOCUMENTATION.md` classifies `theirs`
  → `resolve_manual_file` returns `SPRINTDOCUMENTATION.md` → both `pointer_block`
  and `readme_block` name that file. Ours or absent → `DOCUMENTATION.md`.
- **README on the marker path (#359)** — `readme_block` stamps
  `<!-- SprintBias vX.Y.Z -->`, and a README we wrote classifies
  `ours-current:VER`, identically to an AI pointer. The legacy `managed by
  [SprintBias]` text alone classifies `theirs`, and `scaffold_readme` migrates it
  onto the marker path keeping the user's body and leaving exactly one pointer
  line. If README ever regressed to the text-only recognizer, the
  `ours-current:VER` assertion fails.

Verified beyond the unit tests: `bash -n setup.sh` and `shellcheck -S error` both
clean, and a real install into a scratch project holding its own
`DOCUMENTATION.md` and `README.md` produced `SPRINTDOCUMENTATION.md` alongside
the user's manual, with CLAUDE.md and README.md pointers both naming it — the
`resolve_manual_file` refactor is behavior-preserving end to end.

No `./ship.sh` run: `setup.sh` is the installer and is never distributed, and
`docs/tests/` is repo-only (ship.sh mirrors just `.TEMPLATE-test.md` from it).
No maintainer-guide updates: no user-facing command or provider behavior moved.

### Files changed

setup.sh
docs/tests/test-setup-detection.sh
docs/tasks/doing/361-add-setup-tests-for-binary-conflict-ux-and-manual.md

## Rework (round 1)

**Why:** The Problem names three high-stakes paths; the *visible deferral
policy* is still unlocked — nothing asserts that `scaffold_pointer` /
`scaffold_readme` queue a `theirs` target into `CONFLICTS` and leave it
untouched during the batch (`CONFLICTS=()` is declared at
test-setup-detection.sh:249 and never read). And the most-taken path — the
silent default — is "locked" by grepping setup.sh's source text
(test-setup-detection.sh:306–308, matching the literal `apply_conflict "$_ck"
"$_ct" "$_cn" prepend`), which is the restatement-instead-of-shipped-code the
Notes ruled out; it proves a string exists, not that the loop parses
`kind|target|name` or applies prepend. `apply_conflict` is exercised for the
`pointer` kind only, so the `readme)` block-selection branch and the whole
`gitignore` branch — including `_write_gitignore_fresh`, the most destructive
write in the installer — pass untested.

**Improve:**
- [x] Lift the deferred-conflict loop (setup.sh:1525–1529) into a helper inside
      the scaffold fence — same move already made for `resolve_manual_file` —
      and have the main flow call it.
- [x] Replace the grep-on-source assertion (test-setup-detection.sh:306) with a
      behavioral one: seed `CONFLICTS` with real entries, run the helper, and
      assert each target was prepended (user body kept, marker on line 1).
- [x] Assert the deferral policy: `scaffold_pointer` and `scaffold_readme` on a
      `theirs` target append `kind|target|name` to `CONFLICTS` and leave the
      file byte-identical until the conflict pass runs.
- [x] Lock `apply_conflict`'s kind→block mapping: `readme` writes the README
      wording, `pointer` writes the agent wording — swapping them must fail.
- [x] Cover the `gitignore` conflict branches: `apply_conflict gitignore …
      prepend` adds only the missing entries above the user's body, and `…
      replace` leaves the fresh SprintBias block only. Set `GITIGNORE_CONTENT`
      in the test (setup.sh assigns it at 1125, outside the fence).
- [x] Assert `install_owned_doc` never clobbers: a user-owned target classifies
      `theirs` and is left unchanged — the guarantee that makes the
      `SPRINTDOCUMENTATION.md` retarget safe.
- [x] Fix the fence comment at setup.sh:738 — it points at
      `docs/tests/test-setup-scaffold.sh`, which does not exist; the extractor
      is `docs/tests/test-setup-detection.sh`. Refresh that script's row in
      `docs/guides/running-tests.md:153`, which still describes it as detection
      and gitignore-merge only.
- [x] Keep `bash docs/tests/run-all.sh` green.

## Completed (round 2)

**2026-08-10** — All eight rework items done. 21 more assertions lock the three
high-stakes branches round 1 left open. `bash docs/tests/test-setup-detection.sh`
→ 78 passed, 0 failed (was 57). `bash docs/tests/run-all.sh` → 19/19 green.
`bash -n setup.sh` and `shellcheck -S error setup.sh docs/tests/test-setup-detection.sh`
both clean.

**Lifted the silent-default loop into a helper.** The inline loop at the main
flow is now `apply_deferred_conflicts()` inside the scaffold fence (after
`resolve_manual_file`); the main flow calls it. Same move as round 1's
`resolve_manual_file` — the most-taken install path is now callable from the test.

What the new assertions cover (behavioral, sourcing shipped code — no source greps):

- **Test 18c rewritten** — seeds `CONFLICTS` with real `pointer|…` entries, runs
  `apply_deferred_conflicts`, and asserts each target got our marker on line 1
  with the user's body intact. Proves the loop parses `kind|target|name` and
  prepends, not that a string exists in setup.sh.
- **Test 22 (deferral policy)** — `scaffold_pointer` / `scaffold_readme` on a
  `theirs` target leave the file byte-identical (md5 before == after) and append
  exactly `pointer|CLAUDE.md|CLAUDE.md` / `readme|README.md|README.md` to
  `CONFLICTS`. `CONFLICTS` is now read, not just declared.
- **Test 23 (kind→block mapping)** — `readme` writes the README attribution and
  not the agent wording; `pointer` writes the agent wording and not the README
  attribution. Swapping the two `case` arms in `apply_conflict` fails here.
- **Test 24 (gitignore branches)** — with `GITIGNORE_CONTENT` seeded: `prepend`
  merges the missing entry above the user's body (marker on line 1, `build/`
  kept); `replace` (`_write_gitignore_fresh`) rewrites to our entries only.
- **Test 25 (never-clobber)** — `install_owned_doc` on a `theirs` target leaves
  it byte-identical and does not import our source content.

Also: fixed the fence comment at setup.sh (named a nonexistent
`test-setup-scaffold.sh`) and refreshed the `test-setup-detection.sh` row in
`docs/guides/running-tests.md` to cover the scaffold/conflict machinery.

Verified beyond unit tests: a real install into a scratch project holding its own
`CLAUDE.md` and `README.md` finished **All Checks Passed** and silent-prepended
both files (marker on line 1, user content kept) — the loop→helper extraction is
behavior-preserving.

No `./ship.sh` run: `setup.sh` is the installer and never distributed; `docs/tests/`
and `docs/guides/` are repo-only. No user-facing command or provider behavior moved.

### Files changed

setup.sh
docs/tests/test-setup-detection.sh
docs/guides/running-tests.md
docs/tasks/next/361-add-setup-tests-for-binary-conflict-ux-and-manual.md
