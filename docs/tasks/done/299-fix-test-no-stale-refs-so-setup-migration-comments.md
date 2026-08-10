# Task 299: Fix test-no-stale-refs so setup migration comments for retired MODEL_TALK keys do not fail the suite

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Depends on**: none
**Blocks**: 302
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

`docs/tests/test-no-stale-refs.sh` fails the full suite even when the product is
healthy. It greps for retired names like `MODEL_TALK` / `BUDGET_TASKS` and hits
**intentional migration comments** in `setup.sh` that document how old config
keys are rewritten. Maintainers cannot trust “all tests green” as a gate.

## Success criteria

- [x] Running `bash docs/tests/test-no-stale-refs.sh` exits 0 on current main
- [x] True stale product refs (dispatch, help, live config keys) still fail the test
- [x] Migration/history comments in `setup.sh` (or equivalent) are allowlisted or
      scoped out without silencing real regressions
- [x] Document the allowlist rule in the test header in one short paragraph

## Notes

- Failure observed 2026-07-30: `setup.sh` lines around dead-key rewrite of
  `MODEL_TALK`, `MODEL_DEFINE`, `MODEL_TASKS`, `BUDGET_TASKS`.
- Prefer tightening the grep (code vs comments, word boundaries, exclude
  migration blocks) over deleting the historical comments.
- Keep the rename-guard intent: catch leftover `talk`/`tasks` command paths in
  shipped surfaces.

## References

docs/tests/test-no-stale-refs.sh
setup.sh
docs/guides/command-matrix.md

## Questions

**Status: READY**

### Already complete
Nothing yet. Confirmed the reported failure reproduces on current main:
`bash docs/tests/test-no-stale-refs.sh` → **14 passed, 1 failed**, exit 1. The
sole failure is the `MODEL_TALK|MODEL_DEFINE|MODEL_TASKS|BUDGET_TASKS` check
(test lines 156-157) hitting `setup.sh` at lines 1037, 1209, 1214, 1220.

The rest of the test is healthy and the fix should preserve it: the `check()`
helper already carries an exclusion chain (`ship.sh`, `test-no-stale-refs.sh`,
`command-matrix.md`, `docs/plans/`) at lines 52-55 — `setup.sh` is simply not on
it, so the migration block is unguarded. Confirmed `docs/sprintmd/config` is
tracked and in-scope, so a real retired `KEY=value` in the live config would
still be caught after tightening.

### Remaining work
1. Scope `setup.sh`'s dead-key migration block out of the retired-config-key
   check so the suite exits 0, without weakening detection of true stale product
   refs (retired dispatch labels, help pages, and live `KEY=value` config lines).
2. Update the test header paragraph to document the new allowlist rule in one
   short paragraph (success criterion #4).
3. Re-run `bash docs/tests/test-no-stale-refs.sh` and confirm exit 0, then
   sanity-check that a planted `MODEL_TALK=foo` in `docs/sprintmd/config` still
   fails the test (guard against over-scoping).

Important nuance the Problem statement under-states: **only two of the four hits
are comments** (setup.sh:1037, 1209). Lines 1214 (`_dead_keys` array) and 1220
(`_dead_re` regex) are *live* migration code that must name the retired keys in
order to strip them from an upgrading user's config. An "allowlist only the
comment lines" fix would leave those two failing — the scope-out has to cover the
whole migration block (both comments and code).

### Questions for the developer
1. Which scoping mechanism? (Suggestion: tighten the two retired-config-key
   patterns to an assignment form — e.g. `^[[:space:]]*(MODEL_TALK|MODEL_DEFINE|MODEL_TASKS|BUDGET_TASKS)=`
   — so only a real `KEY=value` config line matches. This is minimal (test-only
   edit, no `setup.sh` change), it cleanly clears all four `setup.sh` hits (bare
   name array, alternation regex, and both prose comments), and it matches the
   stated intent of "live config keys" in success criterion #2, since the live
   `docs/sprintmd/config` is tracked and would still be caught. The more general
   alternative — wrap the `setup.sh` block in `# stale-refs-allow-begin/end`
   sentinels and strip those line ranges in the test — is reusable for future
   migration blocks but adds a `setup.sh` edit and awk range-stripping; prefer
   the assignment-anchored patterns unless you expect many more such blocks.)

## Completed

Took the developer's recommended minimal path (option 1): anchored the
retired-config-key check to an assignment form instead of touching `setup.sh`.
The check in `docs/tests/test-no-stale-refs.sh` went from a bare
name/alternation grep

    check 'MODEL_TALK|MODEL_DEFINE|MODEL_TASKS|BUDGET_TASKS' ...

to an assignment-anchored one

    check '^[[:space:]]*(MODEL_TALK|MODEL_DEFINE|MODEL_TASKS|BUDGET_TASKS)=' ...

This clears all four `setup.sh` hits at once — the two prose comments, the
`_dead_keys` array (bare names, space-separated), and the `_dead_re` alternation
(`KEY|KEY|…`, not `KEY=`) — because none of them is a line-start `KEY=`
assignment. A real retired key in the live `docs/sprintmd/config` is still an
assignment line, so it continues to fail.

Documented the allowlist rule in two places: a paragraph in the file header
(success criterion #4) and an inline comment on the check itself explaining why
the anchor scopes the migration block out.

### Verification
- `bash docs/tests/test-no-stale-refs.sh` → **15 passed, 0 failed**, exit 0.
- Over-scoping guard: appended `MODEL_TALK=foo` to `docs/sprintmd/config` → test
  fails on that line (`14 passed, 1 failed`); restored the config afterward
  (`git status` shows it unchanged from its pre-session staged state, no
  `MODEL_TALK` present).
- Test-only edit; `docs/tests/` is not mirrored by `ship.sh`, so no ship step and
  no `setup.sh` change were needed.

### Files changed
docs/tests/test-no-stale-refs.sh
docs/tasks/doing/299-fix-test-no-stale-refs-so-setup-migration-comments.md
