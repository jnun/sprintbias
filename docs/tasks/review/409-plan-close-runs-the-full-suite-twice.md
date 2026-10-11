# Task 409: Plan close runs the full suite twice

**Feature**: none
**Created**: 2026-10-08
**Docs**: none
**Plan**: 29
**From plan**: 28
**Depends on**: 408
**Dependents**: 411
**Parent**: none
**Fixes**: none
**Crew**: signoff
**Tests**: docs/tests/test-promote.sh
**Refined**: 0
**Reworked**: 0

## Problem

At plan close the full suite runs twice: the crew lead runs `promote plan:N
</dev/null` to find failures early, then the human's `promote plan:N` runs it
again before approval. The policy says the full suite runs once at plan close,
and on a real project the suite can take many minutes.


## Done when (automated)

- [ ] A green suite run by `promote plan:N` records a pass stamp in docs/tmp/ tied to a fingerprint of the working tree (for example `git stash create` or a hash of `git diff HEAD` plus untracked files under the plan's ### Files changed).
- [ ] The next `promote plan:N` reuses the green run when the fingerprint matches, saying so in one line with the run's time; any change re-runs the suite.
- [ ] `--fresh` forces a re-run.
- [ ] `bash docs/tests/test-promote.sh` covers reuse, re-run after a change, and --fresh.
- [ ] `./sprint.sh validate --commands` and `./sprint.sh validate --docs` pass with `--fresh` on the promote surfaces (help/_registry, help/promote.md, DOCUMENTATION.md, docs/guides/command-matrix.md).


## Signoff (human)

- [ ] Run promote plan:N twice on a scratch board with a slow fake suite: the second run skips it and says why.


## Notes

Routed by the lead (orcha): #407 (core) adds a `held` standing in lib.sh and
shows it in plan check and status, but leaves promote.sh to this lane. When
#407 has landed, make promote plan:N's refusal listing show a held original as
`held: fix #N` (one line, no duplicate with the fix itself; see #408).

Follow-up from plan 28; its Policy applies: docs/plans/28-enhance-crews-and-efficiency.md.

The crew lead's plan-close step (crew.sh, guides/crew.md) keeps running the suite; this makes the human's run free when nothing changed. Folders stay the only status: the stamp is a cache in docs/tmp/, never a state.

Fingerprint guidance (settled at gate):
- Fingerprint the whole working tree: HEAD's tree plus tracked changes plus untracked, non-ignored files. Leave out docs/tmp/ (the suite log, the stamp itself, and any scratch the suite writes there) so a run never invalidates itself.
- Fold the TEST_SUITE command string into the fingerprint, so changing the configured suite re-runs it.
- A failed run writes no stamp and clears any old one for that plan.
- When git is unavailable, the fingerprint cannot be taken: run the suite every time.
- Only a green run is reused; reuse goes straight to the human checklist and approval, exactly as after a fresh green run.
- `--fresh` is accepted alongside `plan:N` (today plan:N rejects every other argument); every other combination keeps the "stands alone" refusal.
- Keep the DOCUMENTATION.md addition to a clause or a short line: #411 trims the manual's word count.


## References

docs/sprintbias/scripts/promote.sh
docs/sprintbias/help/promote.md
docs/sprintbias/scripts/crew.sh (plan block)
docs/sprintbias/guides/crew.md (Closing a plan)
docs/tests/test-promote.sh
docs/sprintbias/help/_registry (promote row)
DOCUMENTATION.md, docs/guides/command-matrix.md (command surfaces)
docs/plans/28-enhance-crews-and-efficiency.md (Policy)


## Grounding

**Touching:** docs/sprintbias/scripts/promote.sh, docs/sprintbias/help/promote.md, docs/tests/test-promote.sh, docs/sprintbias/help/_registry (promote row), docs/guides/command-matrix.md (promote row), DOCUMENTATION.md (promote line only)
**Sources:** `docs/plans/28-enhance-crews-and-efficiency.md` (Policy: landed, signed off, full suite once at plan close, folders the only status), `docs/sprintbias/help/_registry` (command catalog; flags per command), `CONTRIBUTING.md` (surfaces that change with a command flag), `docs/sprintbias/scripts/promote.sh` (plan:N sign-off batch)
**Terms:**
- **Landed** — in review/ with a proof line. Landed work releases its dependents. In review/ without proof is "in review, unproven" and releases nothing.
- **Signed off** — in done/. Only humans move work there, at the end of a task or plan, after the full suite passes and the human checks are done.
**Conflicts:**
- Done when bullet 1 scopes untracked files to "the plan's ### Files changed", but plans carry no ### Files changed (members do), and a suite can depend on files no member lists → fingerprint the whole working tree minus docs/tmp/ (see Notes); the bullet's wording is an example, so done is unchanged.
- promote.sh refuses any argument beside plan:N ("plan:N stands alone"), and test-promote.sh asserts that refusal → allow `--fresh` with plan:N only; keep the refusal and its test for every other argument.
- Plan 28 Policy says "the full suite once, at plan close", while crew.sh and guides/crew.md have the lead run it and then hand the human a second run → this task keeps the lead's run and makes the human's run reuse it; crew.sh and guides/crew.md stay as written unless their wording promises a second run.
- `--fresh` is a new flag on promote → registry, help/promote.md, DOCUMENTATION.md and command-matrix.md change together (Done when bullet 5), plus a CHANGELOG `### Changed` bullet.

## Questions

**Status: READY**

### Already complete
None — no matching implementation found. Checked:
- docs/sprintbias/scripts/promote.sh plan:N block (lines ~373-415) runs `bash -c "$SUITE"` unconditionally on every call, writes only docs/tmp/promote-plan-N-suite.log, and keeps no stamp or fingerprint.
- No `--fresh` flag exists in promote.sh, help/promote.md or the help/_registry promote row.
- docs/tests/test-promote.sh Tests 11-15 already count suite runs (`suite_runs`, docs/tmp/suite-runs) on a git-initialised board, a ready base for reuse/re-run/--fresh cases.

### Remaining work
- Write a pass stamp in docs/tmp/ on a green plan:N suite, keyed by plan id and the working-tree fingerprint (Notes).
- On a matching stamp, skip the suite and print one line naming the reused run's time; on a mismatch or `--fresh`, run it.
- Accept `--fresh` with plan:N; keep the stands-alone refusal for everything else.
- Add test-promote.sh cases: second run reuses (suite run count unchanged), an edit re-runs, `--fresh` re-runs; the suite's own docs/tmp/ writes do not break reuse.
- Update the promote surfaces and CHANGELOG; run the validate checks.
- Sequencing: #408 edits the same plan:N block in promote.sh; build on it once it lands.

### Questions for the developer
None — task is fully defined.


## Test log

- `bash docs/tests/run-all.sh` (run by demos, mid-change) · test-promote.sh Test 13 · "suite ran once more (once per batch) (expected '2', got '1')". The reuse was working; Test 13 still expected a second run. It now asserts the reuse (the suite count stays 1, and the run says "Full suite reused: it passed at …"), and Test 16 covers re-runs after a change, after `--fresh`, and after a TEST_SUITE change.
- `bash docs/tests/test-promote.sh` · Test 14 "the held original is listed once" (expected '1', got '2'). My assertion grepped `#742 `, which also matches the fix line "fix #N for #742". It is now anchored to the member line `^    #742 `.

## Completed

A green `promote plan:N` suite run now writes `docs/tmp/promote-plan-N-suite.pass` ("<fingerprint> <time>"). The fingerprint is `git hash-object` over every tracked and untracked, non-ignored file (content plus executable bit), with `docs/tmp/` left out and the TEST_SUITE string folded in. It is read-only and writes no git objects; it took 0.14s on this repo's 635 files. The next plan:N on a matching tree skips the suite and prints one line: "✓ Full suite reused: it passed at <time> and nothing changed since (--fresh re-runs it)." A change or `--fresh` re-runs the suite. A failed run clears the stamp. Without git, the suite runs every time. `--fresh` is accepted only with plan:N; every other combination is still refused.

On the held display: #407 landed, so the plan:N refusal listing now prints a held original as `#N  held: fix #M` through core's `sprintbias_held_label`, on one line and separate from the #408 fix line. lib.sh was read, not edited.

Signoff check, run by hand: a scratch board with a 2s fake suite took 2.3s on the first `promote plan:1` and 0.28s on the second, which printed the reuse line.

The stamp records the fingerprint taken before the suite runs. A suite that writes non-ignored files outside docs/tmp/ will therefore re-run every time, which is the safe direction. crew.sh and guides/crew.md were left as written, because they do not promise a second run.

### Files changed
docs/sprintbias/scripts/promote.sh
docs/sprintbias/help/promote.md
docs/tests/test-promote.sh
docs/sprintbias/help/_registry
docs/guides/command-matrix.md
DOCUMENTATION.md

### Doc follow-ups
- `CHANGELOG.md` (lead) — ### Changed: "`promote plan:N` reuses a green full-suite run when nothing in the working tree has changed since, so the human's sign-off after the lead's run is free; `--fresh` forces a re-run. A held original now reads `held: fix #N` in its refusal listing."

**Proof**: 2026-10-08 · bash docs/tests/test-promote.sh (108/0) · ./sprint.sh validate --commands · ./sprint.sh validate --docs · bash docs/tests/run-all.sh (27/28; test-cleanup-tmp.sh pre-existing) · pass

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
