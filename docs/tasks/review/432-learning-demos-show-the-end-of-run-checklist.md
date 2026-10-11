# Task 432: Learning demos show the end-of-run checklist

**Feature**: none
**Created**: 2026-10-10
**Docs**: none
**Plan**: 32
**From plan**: none
**Depends on**: 426, 428, 429
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-learning-demos.sh
**Refined**: 0
**Reworked**: 0

## Problem

The demos teach the run's end the old way. work.py stops at "landed" and the plan sign-off and never shows the "Your turn" checklist (the calls, the newtask line, reject, close). promote.py leaves a no-Tests task "for human sign-off" with a hand move. parallel.py mentions settle. No test runs the demos, so their expected output drifts from what the commands print.

## Done when (automated)

- [x] work.py shows the end-of-run checklist with the lines work.sh prints: `▸ Your turn`, `call(s) the AI made for you`, `./sprint.sh newtask "<the change you want>"`, `./sprint.sh promote --reject`, `./sprint.sh promote --accept` (`bash docs/tests/test-learning-demos.sh`)
- [x] promote.py closes its no-Tests task with `./sprint.sh promote --accept <id>` (`bash docs/tests/test-learning-demos.sh`)
- [x] No demo names settle (`bash docs/tests/test-learning-demos.sh`)
- [x] test-learning-demos.sh runs every demo with `--fast --no-color` (exit 0, nothing written) and checks each checklist string appears in both work.sh and work.py, so the two cannot drift (`bash docs/tests/test-learning-demos.sh`)

## Signoff (human)

Checked in the plan's one human test, #434.

## References

docs/sprintbias/learning/work.py
docs/sprintbias/learning/promote.py
docs/sprintbias/learning/parallel.py
docs/sprintbias/learning/README.md

## Notes

- Decided: "No demo names settle" means no demo names the `settle` command (`sprint.sh settle`, `settle` as a step); the plain-English word "settled" in parallel.py stays, because no demo calls the command today and the word reads naturally there.
- Decided: test-learning-demos.sh checks the checklist strings against work.sh's `_report_human_review` and the emit checklist spec as they read after 426 and 428 land, because those tasks set the final wording (428 swaps the no-Tests `git mv` close for `promote --accept`).
- Decided: "nothing written" is proven by running each demo in a temp copy of the repo state (or a temp cwd) and checking `git status --porcelain` / the directory listing is unchanged, because the demos promise "touches nothing in your project".
- run-all.sh picks up any `docs/tests/test-*.sh`, so the new test joins the suite with no wiring.

## Grounding

**Sources:** `docs/sprintbias/scripts/work.sh` (`_report_human_review` and the emit report spec: the checklist text the demo must match), `docs/sprintbias/learning/README.md` (demo catalog and the theater contract), `docs/sprintbias/help/_registry` (command catalog; `settle` retirement is task 427), `docs/tests/run-all.sh` (suite discovery)
**Terms:**
- None.
**Conflicts:**
- Problem says parallel.py mentions settle; the code has only the word "settled" (parallel.py:208, 226) and no demo names the `settle` command → the criterion reads as "no demo names the settle command"; the test greps for the command form and the plain word stays.
- work.sh today closes a no-Tests task with `git mv … docs/tasks/done/`, not `promote --accept` → Depends on 428, which changes work's checklist; this task matches work.sh after 428 lands.

## Questions

**Status: READY**

### Already complete
None — no matching implementation found.
- work.py ends at "landed" in review/ (work.py:151, 191) with no "Your turn" checklist.
- promote.py leaves #74 "stays in review/ for human sign-off" (promote.py:164, 200, 222) with no `promote --accept` line.
- No demo names the `settle` command (grep of docs/sprintbias/learning/).
- No docs/tests/test-learning-demos.sh exists; only `learn` (catalog) is smoke-tested in test-command-matrix-smoke.sh:347.
- Every demo already accepts `--fast` and `--no-color`.

### Remaining work
- work.py: add an end-of-run "Your turn" checklist using the exact lines work.sh prints (calls, newtask line, `promote --reject`, `promote --accept` / `promote <id>`).
- promote.py: close the no-Tests task (#74) with `./sprint.sh promote --accept 74` instead of leaving it for a hand move.
- New docs/tests/test-learning-demos.sh: run every demo with `--fast --no-color` (exit 0, nothing written), assert each checklist string is present in both work.sh and work.py, assert promote.py names `promote --accept`, assert no demo names the `settle` command.
- Update learning/README.md if its work/promote descriptions mention the old ending.

### Questions for the developer
None — task is fully defined.

## Completed

- work.py plays the end-of-run checklist right after the queue lands, worded as work.sh prints it (a call with its newtask line, reject, `promote <id>` for a task with Tests, `promote --accept <id>` for one without); its docstring and outro name the checklist.
- promote.py's no-Tests task waits for "your sign-off" and closes with `./sprint.sh promote --accept 74`; act 3 and the outro follow.
- gate.py, loop.py and status.py say blocked/ means "cannot start", not "needs a decision".
- New `docs/tests/test-learning-demos.sh`: every demo runs with `--fast --no-color` from an empty directory (exit 0, nothing written); a real work run (stub CLI) and work.py carry the same eight checklist lines; promote.py shows `--accept`; no demo names settle.

### Assumptions
- Decided: work.py shows two tasks in full and one line for the other two, because the demo is about the shape of the checklist and a full four-task print scrolls the point away.
- Decided: compare the demo against a real work.sh run instead of grepping work.sh's source, because the source holds shell escapes and the rendered text is what a person sees.

### Files changed
docs/sprintbias/learning/work.py
docs/sprintbias/learning/promote.py
docs/sprintbias/learning/gate.py
docs/sprintbias/learning/loop.py
docs/sprintbias/learning/status.py
CHANGELOG.md
docs/tests/test-learning-demos.sh

**Proof**: 2026-10-10 · bash docs/tests/test-learning-demos.sh · pass

## Plan Think

FINISHED (review/). The demos show the checklist, and test-learning-demos.sh compares them against a real work run. Architect: the drift guard is the antifragile part, since the demos can no longer silently diverge. Experience: what the demo teaches matches what the command prints. Nothing more is needed. Left as-is.
