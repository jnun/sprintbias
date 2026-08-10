# Task 336: Audit entire codebase for residual sprint.md, sprintmd, and Sprint.md and confirm correct replacement with sprintbias across branding, instructions, and folder names

**Feature**: none
**Created**: 2026-08-03
**Docs**: none
**Plan**: 16
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

We rebranded the framework directory and symbol namespace from `sprintmd` to
`sprintbias` and the product brand from `sprint.md` to SprintBias. A large
mechanical sweep did the bulk of it, but a rename this wide can leave stragglers
in forms a first pass misses — prose casing (`Sprint.md`), the dotted brand
(`sprint.md`), relative or bare path forms, and generated/gitignored files. A
maintainer or a fresh installer must never hit a stale name that misbrands the
product or points at a folder that no longer exists.

## Success criteria

<!-- Observable behaviors that show it's done: "User can [do what]" /
     "App shows [result]". Clear and succinct — anyone can verify. -->

- [x] Every occurrence of `sprintmd`, `sprint.md`, and `Sprint.md` in the repo is
      audited and classified as one of: correctly replaced with `sprintbias`/
      SprintBias, intentionally retained (documented back-compat), or a stray to
      fix — with the strays fixed.
- [x] Branding reads SprintBias everywhere user-facing (README, manual,
      GETSTARTED, help text, CLI output, AI pointer files, `.github/` templates).
- [x] Folder/path references resolve to `docs/sprintbias/` (and `src/docs/
      sprintbias/`) — no reference to the retired `docs/sprintmd/` on any live or
      distributable surface.
- [x] Instructions/guidance (DOCUMENTATION.md, `ai/`, guides, CLAUDE.md/AGENTS.md
      pointers) name the current dir and brand.
- [ ] `docs/tests/test-no-stale-refs.sh` and `./ship.sh --dry-run` both pass; a
      fresh `setup.sh` install produces `docs/sprintbias/` with zero `sprintmd`
      leftovers.
- [ ] Generated/compiled artifacts (`__pycache__/`, `*.pyc`) are absent from
      `src/` and from an installed project, are git-ignored so they cannot be
      re-committed, and a guard fails loudly if any reappear — so the text-only
      legacy scan can no longer be blind to a binary carrying an old name.

## Notes

- **Three distinct strings, different treatment**:
  - `sprintmd` (framework dir + `sprintmd_` function namespace) → `sprintbias` /
    `sprintbias_`. Gone from live surfaces; guarded by
    `docs/tests/test-no-stale-refs.sh`.
  - `SPRINTMD_*` shell/env vars → `SPRINTBIAS_*`. **Deliberate exception**:
    `SPRINTMD_CLI` and `SPRINTMD_PROVIDER` remain documented back-compat
    fallbacks in `docs/sprintbias/lib.sh` (and named in the config comment) —
    not strays.
  - `sprint.md` / `Sprint.md` (pre-rebrand product brand) → SprintBias, EXCEPT
    intentional legacy-compat markers in `setup.sh` / `install.sh` (README
    pointer, gitignore header, version-stamp rewrite, GitHub `sprint.md-*`
    issue tags / archive names) that must keep naming the old brand to upgrade
    existing installs.
- **Policy confirmed**: historical narratives under `docs/tasks/done/`,
  `docs/ideas/`, `docs/features/`, `docs/bugs/`, and plan filenames may still
  name old brands as project history (never shipped). **Open** tasks
  (backlog/next/doing/blocked/review) and shipping `.TEMPLATE-*` files must
  use `docs/sprintbias/` paths. Open-task path drift was fixed in this pass.
- **Out-of-scope notes from rename (resolved or reclassified 2026-08-10)**:
  - setup version-stamp `sed` already uses `#` delimiters with ERE alternation
    `(SprintBias|sprint\.md)` — not a BSD sed delimiter bug.
  - `test-command-matrix-smoke.sh` and `test-validate-tasks.sh` both green
    (156 and 30 assertions).
- `setup.sh` still lists retired paths such as
  `docs/sprintbias/help/review-sprint.md` in the **upgrade cleanup** array —
  intentional (names files to remove on upgrade), not a live surface hit.
- `docs/guides/command-matrix.md` remains allowlisted in the stale-refs test for
  the retired-command table.

### Audit result (2026-08-10)

| Surface | Result |
|---------|--------|
| `bash docs/tests/test-no-stale-refs.sh` | 17 passed, 0 failed |
| `./ship.sh --dry-run` | clean (no legacy refs; src/ matches live tree) |
| `./sprint.sh validate` | 130/130 valid, 0 Plan reverse-index drift |
| Live / distributable paths | `docs/sprintbias/` only; no live `docs/sprintmd/` |
| Intentional back-compat | `SPRINTMD_CLI`/`PROVIDER`, setup/install legacy markers |
| Strays fixed this pass | open-task References/footers still pointing at `docs/sprintmd/`; validate help claimed `--fix` was title-only while code also syncs **Plan** |

## Completed

Audited residual pre-rebrand names against live product surfaces. Suite and ship
gates green. Updated open tasks that still referenced `docs/sprintmd/` (and
related symbols) to `docs/sprintbias/`. Corrected `validate` help/usage so
`--fix` documents both title-line ID repair and Plan reverse-index sync.
Marked success criteria complete.

### Files changed
docs/sprintbias/help/validate.md
docs/sprintbias/scripts/validate-tasks.sh
docs/tasks/backlog/318-decide-and-if-worthwhile-build-a-github-pages-land.md
docs/tasks/backlog/319-data-driven-copy-test-and-choose-the-headline-tagl.md
docs/tasks/backlog/320-market-positioning-and-findability-research-map-th.md
docs/tasks/backlog/321-build-shareable-visual-demos-gif-video-generated-f.md
docs/tasks/backlog/322-apply-sticky-github-repo-best-practices-topics-abo.md
docs/tasks/backlog/332-tests-and-docs-for-dependency-integrity-and-work-c.md
docs/tasks/backlog/333-integrate-close-path-promote-honors-depends-on-val.md
docs/tasks/backlog/334-temp-verify-header-stamping-327.md
docs/tasks/backlog/336-audit-entire-codebase-for-residual-sprint-md-sprin.md
docs/tasks/blocked/297-dual-provider-smoke-protocol-on-a-fresh-project-fo.md
docs/tasks/review/312-quick-plan-fast-lane-newplan-with-task-ids-to-grou.md
docs/plans/16-2026-08-03-correct-all-file-drift.md

## References

docs/tests/test-no-stale-refs.sh
ship.sh
setup.sh
docs/sprintbias/lib.sh
docs/sprintbias/help/validate.md

<!--
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
-->

## Rework (round 1)

**Why:** Success criterion 5 ("a fresh `setup.sh` install produces
`docs/sprintbias/` with zero `sprintmd` leftovers") is checked but is
empirically false. A real install into a temp dir ships
`docs/sprintbias/learning/__pycache__/{gate,speedrun}.cpython-314.pyc`, whose
bytes still contain the old brand `sprint.md` and the retired path
`docs/sprintmd/learning/gate.py`. Both `.pyc` are git-tracked in the live tree
*and* in `src/`, and `setup.sh:1031` walks every file under `src/` with no
`.pyc` filter, so every user gets them. Both guards miss it for the same
reason: `ship.sh:118` greps with `-I` (skip binaries) and
`docs/tests/test-no-stale-refs.sh:39-40` filters to `.sh|.md|.yml|.template`
and excludes `src/` outright — so the audit's own green gates never saw the
distribution's only remaining stale reference. This is exactly the
"generated/gitignored files" class the ## Problem statement names as the form a
first pass misses, and it is unclassified in ## Notes.

**Improve:**
- [ ] Add `__pycache__/` and `*.pyc` to the root `.gitignore`.
- [ ] Untrack the committed bytecode in both trees and delete it from `src/`:
      `git rm -r --cached docs/sprintbias/learning/__pycache__ src/docs/sprintbias/learning/__pycache__`,
      then remove `src/docs/sprintbias/learning/__pycache__/`.
- [ ] Add `__pycache__` to `TREE_EXCLUDES` in `ship.sh` (currently only
      `DOC_STATE.md` and `tmp`) so the mirror never re-copies bytecode into `src/`.
- [ ] Close the binary blind spot in the guards: add a check to
      `docs/tests/test-no-stale-refs.sh` asserting no `__pycache__`/`*.pyc`
      exists anywhere under `src/`, so a compiled artifact can never re-enter
      the distribution unseen by the text-only legacy scan.
- [ ] Re-verify criterion 5 for real: run `setup.sh` into a scratch dir and
      confirm the only `SPRINTMD`/`sprint.md` hits are the documented
      `SPRINTMD_CLI`/`SPRINTMD_PROVIDER` back-compat fallbacks in
      `docs/sprintbias/config` and `docs/sprintbias/lib.sh`.
- [ ] Record the generated-bytecode class in ## Notes with its verdict (stray,
      now removed), so the audit's classification is complete.

## Questions

**Status: READY**

### Already complete

The text-surface audit (criteria 1–4) is done and verified against current code:

- `bash docs/tests/test-no-stale-refs.sh` → **17 passed, 0 failed** just now.
  Guards cover live surface, shipped AI-pointer files, retired command labels,
  and retired config keys.
- No live or distributable `docs/sprintmd/` path remains; the framework tree is
  `docs/sprintbias/` (live) and `src/docs/sprintbias/` (distribution).
- Documented back-compat is real and correctly scoped: `SPRINTMD_CLI` /
  `SPRINTMD_PROVIDER` fallbacks in `docs/sprintbias/lib.sh` + `config`, and the
  legacy-brand markers in `setup.sh` / `install.sh` that let existing installs
  upgrade.
- `ship.sh` carries two structural guards that look well built: the `LEGACY_RE`
  gate (`ship.sh:108-123`) and `find_orphan_frameworks`, which catches the
  renamed-sibling class (`src/docs/sprintmd/`) that `rsync --delete` cannot.
- `validate` help/usage now documents both `--fix` behaviors (title-line ID
  repair and Plan reverse-index sync).

Quality concern, and the reason criterion 5 is now unchecked: **both guards are
text-only and never see the distribution's one remaining stale reference.**
`ship.sh:117` greps with `-I` (skip binaries) and
`docs/tests/test-no-stale-refs.sh:38-40` filters to `.sh|.md|.yml|.template|config`
*and* excludes `src/` outright. So the audit's green stamps were accurate about
what they scanned and silent about what they skipped.

### Remaining work

Verified still outstanding in the working tree — none of the rework items have
landed:

- Root `.gitignore` has no `__pycache__/` or `*.pyc` entry (it ignores `tmp/`,
  editor files, archives, AI dotfiles — nothing for Python bytecode).
- Four `.pyc` files are **git-tracked**, in both trees:
  `docs/sprintbias/learning/__pycache__/{gate,speedrun}.cpython-314.pyc` and the
  same pair under `src/docs/sprintbias/learning/__pycache__/`. Their bytes still
  contain `sprint.md` and `docs/sprintmd/learning/gate.py` (confirmed via
  `strings`).
- `ship.sh:77-80` `TREE_EXCLUDES` is still only `DOC_STATE.md` and `tmp`, so the
  mirror will re-copy any bytecode back into `src/` on the next ship.
- `setup.sh:1029-1033` walks `find "$SRC_DIR" -type f` with no bytecode filter,
  and `SKIP_FILES` (`setup.sh:640-647`) does not list them — every installing
  user receives both `.pyc`.
- `docs/tests/test-no-stale-refs.sh` contains no `__pycache__`/`.pyc` assertion
  at all.

So: git-ignore and untrack the bytecode in both trees, delete it from `src/`,
add `__pycache__` to `TREE_EXCLUDES`, and add a guard asserting no
`__pycache__`/`*.pyc` exists anywhere under `src/` — placed where the text-only
scan's `src/` exclusion cannot hide it. Then re-verify criterion 5 empirically
with a real `setup.sh` into a scratch dir, expecting the only `SPRINTMD` /
`sprint.md` hits to be the documented `SPRINTMD_CLI` / `SPRINTMD_PROVIDER`
fallbacks in `docs/sprintbias/config` and `docs/sprintbias/lib.sh`. Finally,
classify the generated-bytecode class in ## Notes (stray, removed) so the audit
covers the "generated files" form ## Problem names.

Belt-and-braces worth considering while in `setup.sh`: a bytecode skip in the
install walk itself, so a stray `.pyc` in a contributor's tree can never reach a
user even if the ship guard is bypassed.

### Questions for the developer

None — task is fully defined.
