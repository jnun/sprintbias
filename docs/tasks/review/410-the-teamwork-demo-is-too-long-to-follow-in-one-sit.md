# Task 410: The teamwork demo is too long to follow in one sitting

**Feature**: none
**Created**: 2026-10-08
**Docs**: none
**Plan**: 29
**From plan**: 28
**Depends on**: none
**Dependents**: 411
**Parent**: none
**Fixes**: none
**Crew**: demos
**Tests**: docs/sprintbias/tests/learn-sandbox.sh
**Refined**: 0
**Reworked**: 0

## Problem

`./sprint.sh learn teamwork` now runs nine acts: crew setup, planning,
sessions, claiming, the shared contract, headless work, landing and routing, a
rejection, and the batch sign-off. It is too long to follow in one sitting, and
a user who wants one idea has to sit through all of it.


## Done when (automated)

- [ ] The story splits into two or three focused demos, each playable alone, each with under about 150 lines of story (acts plus outro; the copied house helper block does not count); the split follows the ideas (for example: crew setup and parallel claiming; landing, routing and rejection; plan close and sign-off).
- [ ] The first demo keeps the name `teamwork`, so `./sprint.sh learn teamwork` and the existing pointers to it stay valid.
- [ ] Each demo opens with one line on where it sits in the story and ends pointing at the next (the last points back to the guide).
- [ ] `./sprint.sh learn` lists every part; each plays to the end with `./sprint.sh learn <name> --fast --no-color </dev/null`; `bash docs/sprintbias/tests/learn-sandbox.sh` passes.
- [ ] help/crew.md, guides/crew.md, learning/README.md (spine table) and the crew pointer in learning/work.py's outro name the right demo; `bash docs/tests/test-no-stale-refs.sh` passes.


## Signoff (human)

- [ ] Watch each demo at normal speed: each makes one point, and together they tell the whole story.


## Notes

Follow-up from plan 28; its Policy applies: docs/plans/28-enhance-crews-and-efficiency.md.

Keep the API and iOS logout race as the shared story. Keep each demo self-contained with its own copy of the house helpers, as learning/README.md ("Self-contained for v1") requires; the demos share no module today. New `*.py` files register themselves through their docstring's first line.

DOCUMENTATION.md (line 287) mentions `learn teamwork`; it stays valid because the first part keeps that name. Naming the other parts in the manual belongs to #411, which trims the manual after this lands.

Add a CHANGELOG.md bullet under ## Unreleased (### Changed).


## References

docs/sprintbias/learning/teamwork.py
docs/sprintbias/learning/README.md
docs/sprintbias/learning/work.py
docs/sprintbias/help/crew.md
docs/sprintbias/guides/crew.md
docs/sprintbias/tests/learn-sandbox.sh


## Grounding

**Touching:** docs/sprintbias/learning/teamwork.py, docs/sprintbias/learning/team-landing.py (new), docs/sprintbias/learning/team-signoff.py (new), docs/sprintbias/learning/README.md, docs/sprintbias/help/crew.md (demo pointer), docs/sprintbias/guides/crew.md (demo pointer), CHANGELOG.md (one bullet)
**Sources:** `docs/sprintbias/learning/README.md` (demo house guide: helpers, flags, trust contract, self-contained rule, auto-registration), `docs/plans/28-enhance-crews-and-efficiency.md` (Policy: landed, proof line, Held, Fixes, sign-off), `docs/sprintbias/tests/learn-sandbox.sh` (plays every demo, proves nothing is written), `CONTRIBUTING.md` (surfaces kept in step, changelog)
**Terms:**
- **Landed** — in review/ with a proof line. Landed work releases its dependents. In review/ without proof is "in review, unproven" and releases nothing.
- **Signed off** — in done/. Only humans move work there, at the end of a task or plan, after the full suite passes and the human checks are done.
**Conflicts:**
- Task's "under about 150 lines of script" vs README's self-contained rule (each demo copies a ~150-line helper block; no demo in the catalog is under 150 lines) → count story lines only (acts plus outro); keep demos self-contained.
- Task's Notes allowed a shared module "if the demos already share one" vs README (none exists; a shared kit needs the README changed first) → no shared module.
- Done when listed guides/crew.md, which has no demo pointer today, and missed learning/work.py:273 and DOCUMENTATION.md:287, which name `learn teamwork` → add a pointer to guides/crew.md, update work.py's outro, keep the `teamwork` name so the manual stays valid; manual wording for the other parts goes to #411.
- `crew.py` already demos crew setup and claiming as the per-command scenario → the teamwork parts stay the two-codebase story; crew.py is unchanged.


## Questions

**Status: READY**

### Already complete
None — no matching implementation found.
- docs/sprintbias/learning/teamwork.py is one 411-line demo: helpers through line 154, nine acts (lines 155-368, about 215 lines of story), outro, main.
- `./sprint.sh learn teamwork --fast --no-color` plays today (236 lines of output); `learn` lists `teamwork` and `crew`.
- Pointers to `learn teamwork`: help/crew.md:60, learning/README.md:61, learning/work.py:273, DOCUMENTATION.md:287; guides/crew.md has none.

### Remaining work
- Split teamwork.py into two or three self-contained demos along the ideas, first one still `teamwork`, each story under about 150 lines.
- Opening line (place in the story) and closing pointer (next part) in each.
- Update help/crew.md, guides/crew.md, learning/README.md spine table, work.py outro pointer; CHANGELOG bullet.
- Run each part with `--fast --no-color </dev/null`, then `bash docs/sprintbias/tests/learn-sandbox.sh` and `bash docs/tests/test-no-stale-refs.sh`.

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

## Test log

- 2026-10-08 · `bash docs/tests/run-all.sh </dev/null` (full suite, run once as the lead asked) · 26 passed, 2 failed. `test-cleanup-tmp.sh` fails before this change ("Recent also deleted"). `test-promote.sh` Test 13 "suite ran once more (once per batch) (expected '2', got '1')" is #409's in-progress change to promote.sh / test-promote.sh (signoff's lane); no file of this task feeds it.

## Completed

Split the nine-act `teamwork` demo into three self-contained demos along the
ideas, each with its own copy of the house helpers (no shared module) and the
API / iOS logout race as the shared story. Story lines (acts plus outro):
teamwork 135, team-landing 82, team-signoff 64. Each banner says which part of
three it is; each outro points at the next part, and the last points back to
docs/sprintbias/guides/crew.md. crew.py is unchanged.

- `teamwork` (part 1, name kept): set up a crew, plan, start sessions, claim
  into doing/, announce Touching:, lower id owns the shared contract, the same
  work headless with `work 88` / `work 89`.
- `team-landing` (part 2): land with proof, the lead routes #90 on landing,
  `promote --reject 89` files fix #91 for the same member.
- `team-signoff` (part 3): `plan check 14` reads LANDED, `promote plan:14`
  runs the full suite once and asks for one approval.

Script output copied from the scripts as they stand on 2026-10-08: the crew
roster (crew.sh), the plan check member table and LANDED lines
(plan-check.sh), the reject lines (lib.sh sprintbias_file_fix_task and
promote.sh), and the promote plan:N batch (promote.sh), now with real task
titles and layout in place of slugs. learning/work.py's outro already names
`learn teamwork`, still part 1, so it needed no edit.

Outputs that may shift once in-flight work lands (re-check in #411 or a follow-up):
- #407 (lib.sh standing, plan-check.sh): plan check's Standing column and held
  labels in team-landing ACT 1 and team-signoff ACT 1.
- #408 / #409 (promote.sh): the `promote plan:14` listing, the "Running the
  full suite once" line and the approval lines in team-signoff ACT 2; the
  `promote --reject` lines in team-landing ACT 2.

### Files changed
docs/sprintbias/learning/teamwork.py
docs/sprintbias/learning/team-landing.py
docs/sprintbias/learning/team-signoff.py
docs/sprintbias/learning/README.md
docs/sprintbias/help/crew.md
docs/sprintbias/guides/crew.md
CHANGELOG.md

DOCUMENTATION.md line 287 still names `learn teamwork`, which stays valid.
Naming team-landing and team-signoff in the manual is #411's job (it is
already filed, so no Doc follow-ups entry here).

**Proof**: 2026-10-08 · ./sprint.sh learn teamwork --fast --no-color </dev/null; ./sprint.sh learn team-landing --fast --no-color </dev/null; ./sprint.sh learn team-signoff --fast --no-color </dev/null; bash docs/sprintbias/tests/learn-sandbox.sh; bash docs/tests/test-no-stale-refs.sh; ./sprint.sh validate --commands; ./sprint.sh validate --docs · pass
