# Task 442: Bring project docs in step with landed work

**Feature**: none
**Created**: 2026-10-10
**Docs**: none
**Plan**: none
**From plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

Landed work changed what project documents describe, or found gaps in
them (a missing term, a moved source). Each item under ## Follow-ups names
the document, what must change, and the task it came from.

## Done when (automated)

- [x] Every item under ## Follow-ups is resolved: the named document states
      the current facts, or the item is struck with a one-line reason.
- [x] The crew demo shows the lead routing what a landing releases ("built on
      #N (landed)") and closing the plan with one `promote plan:N`:
      `bash docs/tests/test-learning-demos.sh` passes.
- [x] The `profile` map template ties its `**Test:**` line to `TEST_SUITE` in
      `docs/sprintbias/config`: `bash docs/tests/test-profile.sh` passes.
- [x] Touched docs stay consistent: `./sprint.sh validate --docs` and
      `bash docs/tests/test-proof-loop.sh` pass.

## Signoff (human)

- [ ] Run `python3 docs/sprintbias/learning/crew.py`: the ending reads as one
      lead routing on landing and handing you one `promote plan:N`.

## Notes

- Decided: the old `./sprint.sh profile check` criterion is dropped, because no
  follow-up touches a project map and this repo has none (`profile check`
  exits 1 with "No project map yet"), so it can never read clean here.
- Decided: the profile item is done as a template hint (the `**Test:**` line
  names `TEST_SUITE` in config) rather than an interactive offer to set it,
  because a hint costs no new prompt flow; an interactive offer is a separate
  idea for `./sprint.sh newtask`.
- Decided: items already true in the code are ticked below with their
  evidence, because the brief allows resolving or striking each one.
- Plan 28's Policy is our own dogfood record; the line is a one-line edit
  there, not a shipped change.

## References

docs/sprintbias/learning/crew.py
docs/sprintbias/learning/team-signoff.py
docs/sprintbias/scripts/profile.sh
docs/sprintbias/config
docs/plans/28-enhance-crews-and-efficiency.md
docs/tests/test-learning-demos.sh
docs/tests/test-profile.sh

## Grounding

**Sources:** `CLAUDE.md` / `CONTRIBUTING.md` (repo map, how a change ships, surfaces kept in step), `DOCUMENTATION.md` (user manual), `docs/guides/provider-reality.md` (provider known unknowns), `docs/sprintbias/help/_registry` (command catalog), `CHANGELOG.md` (user-facing change log)
**Terms:**
- None. (No glossary; project map not yet created.)
**Touching:** `docs/sprintbias/learning/crew.py`, `docs/sprintbias/scripts/profile.sh`, `docs/tests/test-learning-demos.sh`, `docs/tests/test-profile.sh`, `docs/plans/28-enhance-crews-and-efficiency.md`, `CHANGELOG.md`
**Conflicts:**
- Task Done when (`profile check` clean) vs this repo (no project map, check exits 1) → dropped; see Decided in Notes.
- Follow-up wording "owned by #405/#406" vs current code → those tasks already landed the manual and team-signoff demo; only the crew demo gap remains.
- Profile item phrased as "could" (optional) → built as a template hint; see Decided.

<!-- sb:doc-followups -->
## Follow-ups

- [x] `DOCUMENTATION.md` — the review/ row ("done, awaiting your approval") and the Depends on field should say a dependent releases on landed work (review/ with a proof line) or done/; owned by #405. (from #398)
- [x] `docs/sprintbias/scripts/gate-lib.sh` — the gate prompt says the runner holds a dependent "until those dependencies reach review/ or done/"; it should read "land (review/ with a proof line) or reach done/". Left alone: #399 owned the file this round. (from #398)
- [x] `DOCUMENTATION.md` — the manual does not yet describe the task sections (Done when (automated), Signoff (human)); task 405 owns the docs pass. (from #399)
- [x] `docs/sprintbias/learning/session.py` — the demo still says "Writing that into Success criteria"; task 406 owns the demos. (from #399)
- [x] `DOCUMENTATION.md` — describe the worker test loop (targeted tests, ## Test log, proof line) in the work and crew sections; task 405 owns the solo/crew docs pass. (from #400)
- [x] `docs/sprintbias/scripts/profile.sh` — the project map's `## Commands` → `**Test:**` line could point at `TEST_SUITE`, and `profile` could offer to set it. (from #403)
- [x] `DOCUMENTATION.md` → Crew section — describe the lead routine (split on disjoint Touching, route on landing, next task queued, "built on #N (landed)", plan close ending in one `promote plan:N`) and members reporting each landing (#405). (from #404)
- [x] `docs/sprintbias/learning/` crew demo — show the lead routing on landing and closing the plan with one `promote plan:N` (#406). (from #404)
- [x] `docs/sprintbias/scripts/plan-check.sh` — the LANDED footer still says "Run the full suite, sign members off into done/, then: plan done"; point it at `./sprint.sh promote plan:N` (#405). (from #404)
- [x] `docs/sprintbias/learning/` demos — show a plan finishing on landed work with one `promote plan:N` (owned by #406) (from #405)
- [x] `docs/plans/28-enhance-crews-and-efficiency.md` Policy — add "Held (standing): review/ with proof, a fix not yet landed; shown `held: fix #N`". (from #407)
- [x] `DOCUMENTATION.md` (`Held` field, ~line 136) — mention plan check / status show it as `held: fix #N`. (from #407)
- [x] `CHANGELOG.md` — add under Unreleased / Fixed: "`promote plan:N` lists an open fix task once, as `fix #N for #M`, instead of twice." (outside signoff's files; for the lead) (from #408)
- [x] `CHANGELOG.md` (lead) — ### Changed: "`promote plan:N` reuses a green full-suite run when nothing in the working tree has changed since, so the human's sign-off after the lead's run is free; `--fresh` forces a re-run. A held original now reads `held: fix #N` in its refusal listing." (from #409)
- [x] `docs/tests/test-proof-loop.sh` — Test 5's fixture is ungated, so work.sh emit gates instead of printing the work prompt; its owner should gate the fixture (or set it as already gated) so the full suite is green. (from #415)
- [x] `docs/guides/provider-reality.md` — note `agents` reads Claude Code session records; Grok Build support unknown (from #396)
- [x] `CONTRIBUTING.md` — add a `docs/history/` row ("folder only": our own plan records; users get the folder empty) to the repo map; it is a governing source, so left to the maintainer. (from #421)

## Questions

**Status: READY**

### Already complete
- 14 of 17 follow-ups already hold in the code (ticked above):
  - DOCUMENTATION.md:102 (review/ = landed with proof line), :131 (Depends on releases on landed), :146-153 (task sections, test loop, Test log), :140-141 (`held: fix #N`), :297-303 (crew lead routine).
  - gate-lib.sh:224 reads "lands (review/ with a proof line) or reaches done/".
  - No "Success criteria" left in learning/*.py; team-signoff.py shows a plan closing on landed work with one `promote plan:14`.
  - plan-check.sh:267 LANDED footer points at `./sprint.sh promote plan:$PLAN_ID`.
  - CHANGELOG.md:136-139, :241-245 carry both promote entries.
  - test-proof-loop.sh fixture is stamped READY; suite passes 44/0.
  - provider-reality.md KU-19a covers `agents` and Grok Build.
  - CONTRIBUTING.md:54 has the `docs/history/` row.

### Remaining work
- `docs/sprintbias/learning/crew.py`: after #41 lands, the lead routes what it releases ("built on #41 (landed)"), and the ending hands the human one `./sprint.sh promote plan:N` instead of "review, commit, and ship".
- `docs/sprintbias/scripts/profile.sh`: the map template's `**Test:**` line points at `TEST_SUITE` in `docs/sprintbias/config`.
- `docs/plans/28-enhance-crews-and-efficiency.md` Policy: add "Held (standing): review/ with proof, a fix not yet landed; shown `held: fix #N`".
- Tick the three items under Follow-ups; add a CHANGELOG bullet for the demo/profile change.

### Questions for the developer
None — task is fully defined.

## Completed

**Summary**: The crew demo now shows the lead routing what each landing releases and closing the plan with one `promote plan:N`, the project map's `**Test:**` line points at `TEST_SUITE`, and plan 28's Policy names the standing Held state.

All 17 follow-ups resolved: 14 already held in the code (evidence under ## Questions), 3 done here.

### Assumptions
- Decided: in the crew demo #43 carries `Depends on: #41` and the lead routes it only after #41 lands, because that is the release-on-landed flow the demo must teach; dill no longer starts #43 on its own.
- Decided: the lead's full-suite run is shown as `promote plan:5 </dev/null` ending LANDED, matching team-signoff.py, because that is how the lead runs the suite without moving anything.
- Decided: the profile scan instruction also tells the AI to note when the map's test command and `TEST_SUITE` differ, because the map and config should name one command.

### Files changed
- docs/sprintbias/learning/crew.py
- docs/sprintbias/scripts/profile.sh
- docs/tests/test-learning-demos.sh
- docs/tests/test-profile.sh
- CHANGELOG.md

Tests: `bash docs/tests/test-learning-demos.sh` (60/0), `bash docs/tests/test-profile.sh` (50/0), `./sprint.sh validate --docs` (no drift), `bash docs/tests/test-proof-loop.sh` (44/0).

**Breaker**: 10 cases tried · 1 fixed · 0 filed — crew.py moved #43 doing/→review/ without ever claiming it (next/43 → doing/43 added after the lead routes it).

**Proof**: 2026-10-10 · bash docs/tests/test-learning-demos.sh; bash docs/tests/test-profile.sh; ./sprint.sh validate --docs; bash docs/tests/test-proof-loop.sh · pass
