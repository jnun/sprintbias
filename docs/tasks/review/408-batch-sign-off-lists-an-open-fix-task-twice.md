# Task 408: Batch sign-off lists an open fix task twice

**Feature**: none
**Created**: 2026-10-08
**Docs**: none
**Plan**: 29
**From plan**: 28
**Depends on**: none
**Dependents**: 409
**Parent**: none
**Fixes**: none
**Crew**: signoff
**Tests**: docs/tests/test-promote.sh
**Refined**: 0
**Reworked**: 0

## Problem

When a plan has an open fix task, `promote plan:N` lists it twice: once as a
plan member ("#407 open — backlog/") and once as a fix ("fix #407 for #89 open
— backlog/"). The human reads two problems where there is one.


## Done when (automated)

- [x] `promote plan:N` on a plan with an open fix task names that fix once, as `fix #N for #M` with its folder.
- [x] `bash docs/tests/test-promote.sh` asserts the fix appears exactly once in the refusal output.


## Signoff (human)

None: the automated checks cover it.


## Notes

Follow-up from plan 28; its Policy applies: docs/plans/28-enhance-crews-and-efficiency.md.

A fix task is listed on the original's plan (#402), so it is both a member and an open fix; dedupe in the refusal listing.


## References

docs/sprintbias/scripts/promote.sh (promote plan:N)
docs/sprintbias/lib.sh (sprintbias_plan_open_fixes)
docs/tests/test-promote.sh


## Grounding

**Sources:** `docs/plans/28-enhance-crews-and-efficiency.md` (Policy: landed, Proof line, Held, Fixes, plan states), `docs/sprintbias/scripts/promote.sh` (promote plan:N sign-off batch and its "Still open" refusal listing), `docs/sprintbias/lib.sh` (sprintbias_plan_member_ids, sprintbias_plan_open_fixes, sprintbias_member_standing), `docs/tests/test-promote.sh` (promote suite, Tests 8, 9, 14)
**Terms:**
- **Landed** — in review/ with a proof line. Landed work releases its dependents. In review/ without proof is "in review, unproven" and releases nothing.
- **Fix tasks** — `**Fixes**: #<id>` on the fix task; `**Held**: fix #<new>` on the rejected original, which stays in review/ and releases nothing until the fix lands.
- **Plan states** — computed from the folders: STARTED (work open), LANDED (every member landed), SIGNED OFF (every member in done/).
**Touching:** docs/sprintbias/scripts/promote.sh, docs/tests/test-promote.sh
**Conflicts:**
- None found. Current code matches the Problem: promote.sh prints each open member as `#N  open — <stage>/`, then prints every `sprintbias_plan_open_fixes` row as `fix #N for #M  open — <stage>/`; `--reject` and the suite-failure path list the fix task on the plan (`- #734 — Fix #730`), so it matches both loops → the work dedupes in the refusal listing only.


## Questions

**Status: READY**

### Already complete
- None — no matching implementation found.
- Checked `docs/sprintbias/scripts/promote.sh` lines ~300-317: the member loop has no exclusion for ids that `sprintbias_plan_open_fixes` returns, so an open fix that is also a plan member prints twice.
- `docs/tests/test-promote.sh` Test 14 asserts only that `for #742  open — backlog/` appears (assert_contains), not that the fix appears once.

### Remaining work
- In the `promote plan:N` "Still open" listing, print an open fix task once, as `fix #N for #M  open — <stage>/`; skip its plain `#N  open` member line. Other members (open, unproven, missing) list as today.
- Keep `sprintbias_plan_open_fixes` and `sprintbias_plan_counts` behavior unchanged; the dedupe is a display concern in promote.sh.
- Add an assertion to `docs/tests/test-promote.sh` (Test 14's plan:90 refusal, or a new case) that the fix id appears exactly once in the refusal output, and that it reads `fix #<id> for #742`.
- Run `bash docs/tests/test-promote.sh`, then the suite.

### Questions for the developer
None — task is fully defined.


<!-- sb:hint  After work only — audit trail of what was touched. Helps committers,
     later audits, and "what broke?" recovery. List the product files you
     edited to complete the task — one repo-relative path per line. Leave this
     task file out: its folder location and git history already track it. Copy
     the two headings below to column 0
     (UNINDENTED — they are indented here only so a fresh, unworked task is not
     mistaken for a finished one), then list the paths under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintbias/scripts/example.sh
       docs/sprintbias/help/example.md

     When the work made a source of truth wrong and updating it is out of
     scope (or it is a governing source), add under ## Completed:

       ### Doc follow-ups
       - `docs/GLOSSARY.md` — add "plan"; the code now uses it

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. Do not fill this before work. -->

<!-- sb:hint
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->

## Completed

The `promote plan:N` "Still open" listing now reads the open fixes once,
before the member loop, and skips the plain `#N  open` line for any member
that is an open fix; the fix prints once as `fix #N for #M  open — <stage>/`.
`sprintbias_plan_open_fixes` and `sprintbias_plan_counts` are unchanged.

Test 14 now asserts the refusal reads `fix #<id> for #742  open — backlog/`
and that the fix id appears exactly once. Checked against the old member loop
in a scratch copy: the new assertion fails there (got 2).

Also made `setup()` in test-promote.sh hermetic: it removes the copied
`config.local`. The maintainer's gitignored `docs/sprintbias/config.local`
sets `TEST_SUITE=bash docs/tests/run-all.sh`, which made Test 15 ("with no
TEST_SUITE") fail on this machine before this change.

### Files changed
docs/sprintbias/scripts/promote.sh
docs/tests/test-promote.sh

### Doc follow-ups
- `CHANGELOG.md` — add under Unreleased / Fixed: "`promote plan:N` lists an open fix task once, as `fix #N for #M`, instead of twice." (outside signoff's files; for the lead)

**Proof**: 2026-10-08 · bash docs/tests/test-promote.sh (89 passed, 0 failed); bash docs/tests/run-all.sh (27 of 28 scripts pass, only the known test-cleanup-tmp.sh fails); ./sprint.sh validate --commands; ./sprint.sh validate --docs · pass
