# Task 413: Fix #411: The manual grew 460 words agents must load every run

**Feature**: none
**Created**: 2026-10-08
**Docs**: none
**Plan**: 29
**From plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Fixes**: #411
**Crew**: core
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

The full suite fails at plan 29's close on `test-cleanup-tmp.sh` Test 8 ("Recent
also deleted"). #411 did not cause it: the failure predates plans 28 and 29, and
promote plan:N routed it to the plan's last member because no member's files
matched (lead's correction; this task is linked to #411 only by that routing).
The cause: cleanup-tmp.sh was changed on purpose to delete only stale files
("a user who wants everything gone can rm -rf docs/tmp/"), but Test 8 still
expects `--all` to delete recent files too. The script also waits at its
`[y/N]` prompt when a caller leaves stdin open, which hangs the suite.


## Done when (automated)

- [ ] `bash docs/tests/test-cleanup-tmp.sh` passes, with Test 8 asserting the current behavior (recent files are kept; only stale files go), and help/cleanup.md says the same about `--all`.
- [ ] `bash docs/tests/run-all.sh` finishes without hanging when stdin is left open: every cleanup-tmp call in the test feeds its answer or `</dev/null`.
- [ ] `bash docs/tests/run-all.sh </dev/null` passes every script.


## Signoff (human)

None: the automated checks cover it.


## Notes

<!-- sb:hint  Optional helpful hints that assist the developer: constraints, edge
     cases, gotchas. Guidance from answered questions also lives here when it
     shapes how (and is not already a success criterion). Leave empty if none. -->

## References

docs/tasks/review/411-the-manual-grew-460-words-agents-must-load-every-r.md

## Grounding

**Sources:** `docs/sprintbias/scripts/cleanup-tmp.sh` (cleanup behavior: only stale files are removed), `docs/sprintbias/help/cleanup.md` (user-facing contract for `cleanup`), `docs/sprintbias/help/_registry` (cleanup flags: `[--force]`), `docs/guides/running-tests.md` (suite ladder)
**Touching:** docs/tests/test-cleanup-tmp.sh
**Terms:**
- None.
**Conflicts:**
- Test 8 in `docs/tests/test-cleanup-tmp.sh` expects `--all` to delete recent files; the script (comment "Only stale files are ever removed") and help/cleanup.md keep recent files and advertise no `--all` → the test moves to the script's intended behavior; the script stays as is.
- Title says "Fix #411" and **Fixes** names #411, but the failure predates plan 28/29 and was routed by promote plan:N → fields left as they are on the lead's instruction; #414 covers the routing gap.

## Test log

- 2026-10-08 · sent back from review (#411):

```
Full suite failed at plan 29 sign-off: `bash docs/tests/run-all.sh` exited 1. Failing output:
> Passed: 17  Failed: 0
> Results: 10 passed, 0 failed
> Results: 21 passed, 0 failed
> Results: 9 passed, 0 failed
>   FAIL: Recent also deleted (file still exists: /var/folders/5x/8k9mbz8n4pn72wrb8j1c71q00000gn/T/tmp.7FbcOFiPwO/docs/tmp/fresh.txt)
> Results: 13 passed, 1 failed
>   ▸ script FAIL (test-cleanup-tmp.sh) exit=1
> Results: 164 passed, 0 failed  (of 164 assertions)
> Results: 10 passed, 0 failed
> Results: 12 passed, 0 failed
> Results: 11 passed, 0 failed
> Results: 14 passed, 0 failed
> Test 7: unknown member, task and plan fail
> Results: 76 passed, 0 failed
> Results: 25 passed, 0 failed
>   PASS: doing + failed Outcome → surfaces the result
>   PASS: a proof line that records a failure does not count
>   PASS: failed: writes the ## Outcome heading
>   PASS: failed: records **Result**: failed
>   PASS: failed: records the **Reason**
>   PASS: failed: stamps a dated **At**
>   PASS: failed: _outcome_brief reads it back for a hold line
>   PASS: a next/ task with an open prereq exits 0 (held, not failed)
> Results: 46 passed, 0 failed
> Results: 28 passed, 0 failed
> Test 9: tool mapping (map known Claude names; fail-open on unknown)
>   PASS: unmapped tool fails open
> Results: 75 passed, 0 failed
> Results: 18 passed, 0 failed
> Results: 22 passed, 0 failed
>   PASS: Plan file left intact on failure
> Results: 85 passed, 0 failed
> Results: 37 passed, 0 failed
> Test 2: a failing **Tests** script keeps the task in review/ and exits 1
>   PASS: exit 1 when a named test fails
> Test 3: **Tests: none** is skipped for human sign-off and does not fail
>   PASS: exit 0 — a skip is not a failure
>   PASS: exit 0 — a dependency hold is not a failure
>   PASS: error output becomes a test to add
> Test 14: a failing suite files fix tasks for the member whose files failed, and moves nothing
```

- 2026-10-08 · core: `bash docs/tests/test-cleanup-tmp.sh </dev/null` · new Test 9 "Exits 0" failed (got 1): with stdin closed, `read -r confirm` hits EOF under `set -e`, so cleanup-tmp.sh exits 1 instead of printing "Aborted." It still deletes nothing. The script is out of scope here, so Test 9 now asserts only that nothing is deleted; the exit code goes to the lead. Re-run: 15 passed, 0 failed.

## Questions

**Status: READY**

### Already complete
- `docs/sprintbias/help/cleanup.md` already documents only `--force`, says recent files are always kept, and points to `rm -rf docs/tmp/` for a full wipe; no `--all` wording to fix.
- `docs/sprintbias/help/_registry` lists `cleanup [--force]` only; the script has no usage text and ignores unknown flags.

### Remaining work
- Rewrite Test 8 in `docs/tests/test-cleanup-tmp.sh` to assert answering y deletes stale files and keeps recent ones (`--all` wipes nothing extra).
- Feed every cleanup-tmp call in the test its answer or `</dev/null` (Test 3 prompts today and hangs on open stdin).
- Run the full suite with and without `</dev/null`.

### Questions for the developer
None — task is fully defined.

## Completed

Test 8 now asserts the script's intended behavior: answering y deletes stale files and keeps recent ones, and the retired `--all` flag deletes nothing extra. Every cleanup-tmp call in the test now feeds its answer or `</dev/null`. New Test 9: with stdin closed, the prompt deletes nothing. help/cleanup.md and the registry already described stale-only cleanup with no `--all`, so neither changed. The script has no usage text.

Full suite: `bash docs/tests/run-all.sh </dev/null`: 28/28 scripts green. With stdin held open and silent (`sleep 900 | timeout 600 bash docs/tests/run-all.sh`): 28/28 green in about 75s, no hang. `./sprint.sh validate --commands` and `--docs`: clean.

Note: docs/tests/test-cleanup-tmp.sh is outside core's May touch list; the lead routed it here.

### Files changed
docs/tests/test-cleanup-tmp.sh

**Proof**: 2026-10-08 · `bash docs/tests/test-cleanup-tmp.sh` · `bash docs/tests/run-all.sh </dev/null` · `./sprint.sh validate --commands` · `./sprint.sh validate --docs` · pass

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
