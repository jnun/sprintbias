# Task 405: Docs treat done/ as the agent gate and blur solo and crew modes

**Feature**: none
**Created**: 2026-10-08
**Docs**: none
**Plan**: 28
**From plan**: none
**Depends on**: 400, 401, 402, 403, 404
**Dependents**: none
**Parent**: none
**Crew**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

The docs still treat done/ as the point where work counts, which teaches agents
to wait on humans. Solo agents and crews work differently, but the manual mixes
them. A new user can't quickly tell which mode fits.

## Done when (automated)

- [x] DOCUMENTATION.md states the plan 28 policy once (landed vs signed off) and gives Solo and Crew their own sections in their own words. Solo: one context, dependency order in one session, batch related tasks, notes in task files, targeted tests per task and the full suite once at plan close; `work` and `loop`. Crew: split as wide as Touching allows, claim and route through files and messages, land fast, route on landing; `crew`. Proven by `bash docs/tests/test-no-stale-refs.sh`.
- [x] No place in DOCUMENTATION.md, GETSTARTED.md, guides/, help/ or ai/ treats done/ as a gate on agents (Distinctions that trip up agents, The pipeline, Folders = status, task fields, the promote/plan/work/crew help pages); task fields list Done when / Signoff / Test log / Proof / Fixes / Held. `plan done` still requires done/. Proven by `grep -rn "review/ or done/" DOCUMENTATION.md docs/sprintbias/help docs/sprintbias/ai docs/sprintbias/scripts/gate-lib.sh` finding no agent gate.
- [x] The gate prompt in gate-lib.sh says a dependent waits until its dependencies land (review/ with a proof line) or reach done/; the plan-check LANDED footer points at `./sprint.sh promote plan:N`; fix-task wording fits both a review rejection and a full-suite failure. Proven by `bash docs/tests/test-command-matrix-smoke.sh` and the full `bash docs/tests/run-all.sh </dev/null` once at landing.
- [x] Help pages, help/_registry summaries and docs/guides/command-matrix.md match (promote --reject, promote plan:N, TEST_SUITE): `./sprint.sh validate --commands` and `./sprint.sh validate --docs` pass.

## Signoff (human)

- [ ] Read the Solo and Crew sections of DOCUMENTATION.md: a new user can tell which mode fits them in under a minute.
- [ ] One CHANGELOG bullet per user-facing change not already logged.

## Notes

Shared policy, names and formats: docs/plans/28-enhance-crews-and-efficiency.md → Policy. Use them exactly.

Each earlier task logs its own CHANGELOG line and edits its own help page; this task sweeps what is left and writes the two mode sections. Positive instruction, plain words, few lines: the manual is loaded by agents.

## References

docs/plans/28-enhance-crews-and-efficiency.md
DOCUMENTATION.md
GETSTARTED.md
docs/sprintbias/help/
docs/sprintbias/guides/
docs/sprintbias/ai/
docs/guides/command-matrix.md

## Grounding

**Sources:** `docs/plans/28-enhance-crews-and-efficiency.md` (Policy: names and formats for landed, signed off, proof line, task sections, fix tasks, plan states), `CLAUDE.md` / `CONTRIBUTING.md` (guiding principles, surfaces kept in step), `DOCUMENTATION.md` (the manual), `docs/sprintbias/help/_registry` (command catalog), `docs/guides/command-matrix.md` (command matrix)
**Terms:**
- None. (No project glossary; the plan's Policy defines Landed, Signed off, Proof line, Fixes, Held, STARTED / LANDED / SIGNED OFF.)
**Touching:** DOCUMENTATION.md, GETSTARTED.md, docs/sprintbias/help/ (work, plan, promote, crew, newtask, status, _registry), docs/sprintbias/ai/ (task-creation, refine, accept), docs/sprintbias/guides/crew.md, docs/sprintbias/scripts/gate-lib.sh, docs/sprintbias/scripts/plan-check.sh, docs/sprintbias/scripts/promote.sh, docs/sprintbias/lib.sh (fix-task wording only), docs/tests/test-promote.sh (that wording), docs/guides/command-matrix.md, CHANGELOG.md
**Conflicts:**
- Brief asks DOCUMENTATION.md to describe the worker Test loop and the crew lead routine, while principle 2 (context cost) asks for few lines → describe each in a few lines in the Solo / Crew sections and point at `help work`, `help crew` and `guides/crew.md` for detail.
- docs/sprintbias/learning/ demos still show done/-gated finishes → owned by #406 in parallel; this task leaves learning/ alone.

## Questions

**Status: READY**

### Already complete
- #398–#404 landed the behavior: dependency release on landed work (lib.sh), Done when / Signoff sections and the gate check (gate-lib.sh), the worker Test loop (help/work.md), plan states (plan-check.sh, status), `promote --reject` and `promote plan:N` (promote.sh, help/promote.md, registry), crew lead routine (crew.sh, help/crew.md).
- DOCUMENTATION.md Task fields already lists `Fixes`; Commands already list `promote --reject` and `plan:N`.

### Remaining work
- DOCUMENTATION.md: one Policy paragraph; Solo and Crew sections (reorganize ## Crew and rule 8); review/ row, Depends on, Tests, Distinctions, Pipeline; task fields Done when / Signoff / Test log / Proof / Held; `TEST_SUITE` at config and plan close.
- gate-lib.sh line ~283 dependency wording; plan-check.sh LANDED footer; fix-task wording in lib.sh/promote.sh.
- Sweep help (work, plan, promote, crew, newtask, status), ai/ (task-creation.md Depends on), guides/crew.md, GETSTARTED.md for done/-as-gate wording.

### Questions for the developer
None — task is fully defined.

## Completed

DOCUMENTATION.md states the landed vs signed off policy once (Distinctions that
trip up agents), adds Solo or crew / Solo / Crew sections (the old ## Crew
reorganized; rule 8 points at them), the worker Test loop, task sections and the
Held field, and `TEST_SUITE` under Provider and model and in Solo. Folders,
pipeline, Depends on and rules 3/5 now say land vs sign off. GETSTARTED.md,
help (work, plan, newplan, newtask, _registry) and command-matrix.md follow.
gate-lib.sh dependency wording, the plan-check LANDED footer (now
`promote plan:N`) and fix-task wording ("sent back from review") are done.
Full suite once: 27 of 28 scripts pass; test-cleanup-tmp.sh fails as before.

### Files changed
DOCUMENTATION.md
GETSTARTED.md
CHANGELOG.md
docs/sprintbias/help/work.md
docs/sprintbias/help/plan.md
docs/sprintbias/help/newplan.md
docs/sprintbias/help/newtask.md
docs/sprintbias/help/_registry
docs/sprintbias/ai/task-creation.md
docs/sprintbias/scripts/gate-lib.sh
docs/sprintbias/scripts/plan-check.sh
docs/sprintbias/lib.sh
docs/tests/test-promote.sh
docs/guides/command-matrix.md

### Doc follow-ups
- `docs/sprintbias/learning/` demos — show a plan finishing on landed work with one `promote plan:N` (owned by #406)

**Proof**: 2026-10-08 · `bash docs/tests/test-no-stale-refs.sh`, `bash docs/tests/test-command-matrix-smoke.sh`, `bash docs/tests/test-promote.sh`, `bash docs/tests/test-plan-lifecycle.sh`, `bash docs/tests/test-done-when.sh`, `./sprint.sh validate --commands`, `./sprint.sh validate --docs` · pass
