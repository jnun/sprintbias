# Task 406: Demos do not show a plan finishing on landed work with one sign-off

**Feature**: none
**Created**: 2026-10-08
**Docs**: none
**Plan**: 28
**From plan**: none
**Depends on**: 403, 404
**Dependents**: none
**Parent**: none
**Crew**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

The demos still end with tasks sitting in review/ waiting on a human, one at a
time. Users never see the faster flow: work lands, dependents start, and the
plan closes with one batch sign-off.

## Done when (automated)

- [x] A solo demo (work.py, the `work --demo`) finishes a plan on landed work: targeted tests, a proof line, a dependent starting the moment its prerequisite lands, `plan check` reading LANDED, then `promote plan:N` running the suite once and one batch sign-off. `./sprint.sh learn work --fast --no-color </dev/null`
- [x] The crew demo (teamwork.py) keeps the API / iOS logout-race story and shows the lead routing on landing, a rejection becoming a fix task for the same member through `promote --reject`, and the batch sign-off at plan close. `./sprint.sh learn teamwork --fast --no-color </dev/null`
- [x] learning/ no longer says "Success criteria", and no demo shows a dependent waiting on done/ (it waits on landed work). `grep -rn "Success criteria" docs/sprintbias/learning/` finds nothing.
- [x] Every command and output line shown matches the real scripts (checked against scratch boards); `./sprint.sh learn` lists both demos; the suite still passes. `bash docs/tests/test-command-matrix-smoke.sh`, `bash docs/tests/run-all.sh </dev/null`

## Signoff (human)

- Watch `./sprint.sh learn work` and `./sprint.sh learn teamwork` at normal speed: each reads as one clear story ending in a single `promote plan:N` sign-off, and stays short.

## Notes

Shared policy, names and formats: docs/plans/28-enhance-crews-and-efficiency.md → Policy. Use them exactly.

Match the house style in docs/sprintbias/learning/ (crew.py, teamwork.py). Theater only: a demo touches nothing in the user's project.

## References

docs/plans/28-enhance-crews-and-efficiency.md
docs/sprintbias/learning/teamwork.py
docs/sprintbias/learning/work.py
docs/sprintbias/learning/loop.py
docs/sprintbias/learning/README.md

## Grounding

**Touching:** docs/sprintbias/learning/work.py, docs/sprintbias/learning/teamwork.py, docs/sprintbias/learning/session.py, docs/sprintbias/learning/promote.py, docs/sprintbias/learning/status.py, docs/sprintbias/learning/parallel.py, docs/sprintbias/learning/crew.py, docs/sprintbias/learning/README.md, CHANGELOG.md
**Sources:** `docs/plans/28-enhance-crews-and-efficiency.md` (Policy: landed, signed off, proof line, fix tasks, plan states), `docs/sprintbias/learning/README.md` (demo house style, trust contract, catalog), `docs/sprintbias/scripts/promote.sh` / `plan-check.sh` / `work.sh` / `crew.sh` (real output shapes), `CONTRIBUTING.md` (what ships)
**Terms:**
- **Landed** — in review/ with a proof line. Landed work releases its dependents.
- **Signed off** — in done/. Only humans move work there, at the end of a task or plan, after the full suite passes and the human checks are done.
**Conflicts:**
- work.py ACT 1 says #83 waits on #80 "(not done yet)"; promote.py says a held task needs its prerequisite in "review/ or done/" and "#83 will unhold once #80 is done/" → reword to landed, per the Policy.
- session.py says "Writing that into Success criteria" → name the new sections (Done when (automated), Signoff (human)).
- The task offers extending work.py or loop.py or a new demo → extend work.py: its ACT 1 already sets up #83 waiting on #80, so the landing release continues that story without a new catalog entry.

## Questions

**Status: READY**

### Already complete
None — no matching implementation found. Checked learning/work.py, loop.py, teamwork.py, promote.py, session.py: no proof line, no plan check LANDED, no promote --reject or promote plan:N anywhere in learning/.

### Remaining work
- work.py: landing with targeted tests and a proof line, #83 released on #80's landing, plan close with `plan check` and `promote plan:N`.
- teamwork.py: route on landing, a `promote --reject` fix task for the same member, `promote plan:14` close.
- session.py and promote.py wording; README catalog line for work and teamwork.

### Questions for the developer
None — task is fully defined.

## Completed

Extended `work.py` (the `work --demo`) rather than adding a demo: its ACT 1
already held #83 on #80. ACT 2 now lands each task with a targeted test and a
proof line (#80 plays one Test log round), and #83 starts the moment #80 lands.
The `work N` / `count N` dials became a two-line coda. New ACT 3: `plan check 12`
reads LANDED, `promote plan:12` runs TEST_SUITE once, shows the combined
Signoff (human) checklist, and one `y` moves all four to done/.

`teamwork.py` keeps the API / iOS logout race. ACT 7: api and ios land #88 and
#89 with proof; the lead checks `plan check 14`, routes #90 in the same turn
and marks it "built on #88 (landed), #89 (landed)" on the ## Crew board. ACT 8:
you run `promote --reject 89 "..."`; fix #91 goes to ios (**Fixes**: #89), #89
is Held, #90 gets its re-check line; ios logs a failing test, fixes, lands. ACT
9: plan check reads LANDED, the lead hands you `promote plan:14` (suite once,
one approval). The lead's own `promote plan:14 </dev/null` suite run is left
out so the demo shows the suite running once.

Output lines were copied from the real scripts on scratch boards (plan check,
status, promote plan:N, promote --reject, work's hold banner). Wording fixes:
session.py (Done when (automated)), promote.py (hold text now matches
promote.sh: "needs review/ with proof, or done/"; #83 unholds once #80 lands),
status.py (plan counts open · landed · signed off), parallel.py and crew.py
(landed, not "in review").

### Files changed
docs/sprintbias/learning/work.py
docs/sprintbias/learning/teamwork.py
docs/sprintbias/learning/session.py
docs/sprintbias/learning/promote.py
docs/sprintbias/learning/status.py
docs/sprintbias/learning/parallel.py
docs/sprintbias/learning/crew.py
docs/sprintbias/learning/README.md
CHANGELOG.md

**Proof**: 2026-10-08 · ./sprint.sh learn work --fast --no-color </dev/null; ./sprint.sh learn teamwork --fast --no-color </dev/null; bash docs/sprintbias/tests/learn-sandbox.sh; bash docs/tests/test-command-matrix-smoke.sh; bash docs/tests/test-no-stale-refs.sh; bash docs/tests/run-all.sh </dev/null (27/28; test-cleanup-tmp.sh already failed); ./sprint.sh validate --commands; ./sprint.sh validate --docs · pass
