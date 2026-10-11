# Task 404: Crew lead routes slowly and leaves members idle

**Feature**: none
**Created**: 2026-10-08
**Docs**: none
**Plan**: 28
**From plan**: none
**Depends on**: 400, 403
**Dependents**: 405, 406
**Parent**: none
**Crew**: none
**Tests**: docs/tests/test-crew.sh
**Refined**: 0
**Reworked**: 0

## Problem

A crew lead waits on done/, routes one task at a time, and leaves members
idle between tasks. Rejections can't be traced through work built on unsigned
results. The lead should split for parallel work, route on landing, keep
everyone busy, and own plan close.

## Done when (automated)

- [x] Split for parallel work: the lead prompt (crew.sh plan block), guides/crew.md and ai/crew-setup.md say tasks in one wave need disjoint **Touching:** sets; overlapping tasks run in order through Depends on (lower id first) or go to one member. `bash docs/tests/test-crew.sh`
- [x] Route on landing: when a member reports a landing, the lead checks the proof line (`sprintbias_dep_landed <id>` or the file) and routes its dependents in the same turn, without waiting for done/. `bash docs/tests/test-crew.sh`
- [x] No one idle: each member always has a next task queued on the ## Crew board; a blocked member hands off and takes its next. `bash docs/tests/test-crew.sh`
- [x] Built on unsigned work: the board marks dependents "built on #N (landed)" so a rejection traces to everything it affects. `bash docs/tests/test-crew.sh`
- [x] Plan close: when `plan check` reads LANDED, the lead runs or delegates the full suite, turns failures into fix tasks for the right members (`promote --reject`, or the fix tasks `promote plan:N` files), and hands the human one sign-off batch, `./sprint.sh promote plan:N`, never answering that approval itself. `bash docs/tests/test-crew.sh`
- [x] Members report each landing by message to the lead and by the proof line in the file, so restarting a session loses no state; on Grok Build the landing also goes on the ## Crew board. `bash docs/tests/test-crew.sh`
- [x] Both provider sections in ai/crew-setup.md are re-tuned for these behaviors with today's **Tuned** date. `bash docs/tests/test-crew.sh`
- [x] The waves layout still prints, and the command surfaces agree. `bash docs/tests/test-crew.sh`, `./sprint.sh validate --commands`, `./sprint.sh validate --docs`

## Signoff (human)

- Read the lead's startup prompt (`./sprint.sh crew <lead> plan:N` inside an AI session prints it). It stays short and reads as one clear routine: split, route on landing, keep everyone busy, close the plan.
- Read guides/crew.md → How the lead works. A new crew owner can follow the plan-close steps to one `promote plan:N` sign-off.

## Notes

Shared policy, names and formats: docs/plans/28-enhance-crews-and-efficiency.md → Policy. Use them exactly.

Build on the existing plan:N assignment and sprintbias_plan_waves. Keep the lead prompt short; re-tune the provider sections in ai/crew-setup.md and bump their Tuned dates.

## References

docs/plans/28-enhance-crews-and-efficiency.md
docs/sprintbias/scripts/crew.sh
docs/sprintbias/guides/crew.md
docs/sprintbias/ai/crew-setup.md
docs/sprintbias/help/crew.md
docs/tests/test-crew.sh

## Grounding

**Sources:** `docs/plans/28-enhance-crews-and-efficiency.md` (Policy: landed, signed off, proof line, fix tasks, plan states, full suite once at plan close), `docs/sprintbias/scripts/crew.sh` (lead + member prompts, plan block), `docs/sprintbias/lib.sh` (sprintbias_plan_waves, sprintbias_dep_landed, sprintbias_parallel_rule, sprintbias_proof_rule), `docs/sprintbias/guides/crew.md` (crew guide), `docs/sprintbias/ai/crew-setup.md` (setup procedure + per-provider tuning), `docs/sprintbias/help/crew.md` (command help), `docs/crew/.TEMPLATE-crew.md` (member file Reports), `docs/sprintbias/help/promote.md` (--reject, plan:N)
**Terms:**
- **Landed** — in review/ with a proof line. Landed work releases its dependents. In review/ without proof is "in review, unproven" and releases nothing.
- **Signed off** — in done/. Only humans move work there, at the end of a task or plan, after the full suite passes and the human checks are done.
- **Plan states** — STARTED (work open), LANDED (every member landed), SIGNED OFF (every member in done/).
**Touching:** docs/sprintbias/scripts/crew.sh (lead rules + plan block), docs/sprintbias/guides/crew.md, docs/sprintbias/ai/crew-setup.md, docs/sprintbias/help/crew.md, docs/crew/.TEMPLATE-crew.md (lead/member Reports), docs/tests/test-crew.sh, CHANGELOG.md
**Conflicts:**
- The success criterion says "when every member has landed"; the Policy names that state LANDED → the lead acts when `plan check` reads LANDED.
- `promote plan:N` runs the suite and asks for approval in one command; the lead must never answer that approval → the lead runs `./sprint.sh promote plan:N </dev/null` (suite once, a fix task per failure, and with stdin closed nothing moves) or delegates the run; a fix found by reading uses `promote --reject`; the human runs `promote plan:N` and answers its approval.
- plan-check.sh's LANDED footer still says "Run the full suite, sign members off into done/, then: plan done" rather than naming `promote plan:N` → out of scope here (plan-check.sh belongs to #401/#403); recorded as a Doc follow-up.
- DOCUMENTATION.md's Crew/mode sections and learning/ demos describe the old lead routine → #405 and #406 own them; recorded as Doc follow-ups.

## Questions

**Status: READY**

### Already complete
- crew.sh plan block (lines ~185-200): plan assignment, waves from sprintbias_plan_waves, "start a later task the moment its own prerequisites land", "same files go to one member, or one waits". Correct; to be tightened into the new rules.
- sprintbias_dep_landed (lib.sh) and sprintbias_proof_rule exist and are sent to every crew session.
- `promote --reject` and `promote plan:N` exist (#402, #403).

### Remaining work
- Rewrite the lead rules + plan block in crew.sh around: split on disjoint Touching, route on landing (check proof, route dependents same turn), next task queued per member, "built on #N (landed)" board marks, plan close at LANDED ending in one `promote plan:N` for the human. Keep it no longer than today.
- Member rule: report each landing by message and the proof line.
- Mirror in guides/crew.md (How the lead works, board example), ai/crew-setup.md (both provider sections, Tuned dates), help/crew.md, and the lead/member Reports in .TEMPLATE-crew.md.
- test-crew.sh assertions for each rule; waves still print.

### Questions for the developer
None — task is fully defined.

## Test log

- `bash -c 'source docs/sprintbias/lib.sh; sprintbias_has_proof <this file>'`
  → exit 1: a wrapped prose line in ## Completed began with "## Crew board",
  which reads as a new heading and ends the section before the proof line.
  Re-wrapped; re-run passes.

Every targeted test run passed. One weak assertion caught in review: `grep -F` with a two-line
needle matches either line, so the multi-line needles in test-crew.sh (the old
member Reports check and two new Grok checks) now use single-line needles.

## Completed

The lead prompt now runs plan 28's routine: split on disjoint **Touching:**
sets (overlap goes to one member or runs in order, lower id first), route on
landing in the same turn, a task now and a task next for every member on
the ## Crew board, "built on #N (landed)" marks, and plan close at LANDED ending in
one `./sprint.sh promote plan:N` the human answers. The lead rules shrank to
four bullets to pay for the plan block. Members report each landing by message
and by the proof line; without messaging, on the ## Crew board. Both provider
sections in ai/crew-setup.md are re-tuned (Tuned dates stay 2026-10-08, today).

The plan-close suite run uses `./sprint.sh promote plan:N </dev/null`: it runs
TEST_SUITE, files a fix task per failure, and with stdin closed moves nothing,
so the lead never answers the approval. The human's `promote plan:N` then runs
the suite a second time before asking.

### Files changed
docs/sprintbias/scripts/crew.sh
docs/sprintbias/guides/crew.md
docs/sprintbias/ai/crew-setup.md
docs/sprintbias/help/crew.md
docs/crew/.TEMPLATE-crew.md
docs/tests/test-crew.sh
CHANGELOG.md

### Doc follow-ups
- `DOCUMENTATION.md` → Crew section — describe the lead routine (split on disjoint Touching, route on landing, next task queued, "built on #N (landed)", plan close ending in one `promote plan:N`) and members reporting each landing (#405).
- `docs/sprintbias/learning/` crew demo — show the lead routing on landing and closing the plan with one `promote plan:N` (#406).
- `docs/sprintbias/scripts/plan-check.sh` — the LANDED footer still says "Run the full suite, sign members off into done/, then: plan done"; point it at `./sprint.sh promote plan:N` (#405).

**Proof**: 2026-10-08 · bash docs/tests/test-crew.sh; bash docs/tests/test-proof-loop.sh; ./sprint.sh validate --commands; ./sprint.sh validate --docs · pass
