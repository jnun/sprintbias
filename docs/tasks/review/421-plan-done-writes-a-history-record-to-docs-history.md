# Task 421: plan done writes a history record to docs/history instead of deleting the plan

**Feature**: none
**Created**: 2026-10-10
**Docs**: docs/sprintbias/help/plan.md, DOCUMENTATION.md
**Plan**: 31
**From plan**: none
**Depends on**: none
**Dependents**: 423
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-plan-lifecycle.sh
**Refined**: 0
**Reworked**: 0

## Problem

`plan done` deletes the plan file, so the reason a body of work happened (its
Goal and Why) survives only in git history. The detail of what was built is
scattered across many `done/` task files that nobody reads end to end. Teams
and agents have no clear, digestible record of what each finished plan
delivered.

## Done when (automated)

- [x] On a full pass, `plan done N` writes
      `docs/history/YYYY-MM-DD-plan-N-<slug>.md` (finish date, plan id, the plan
      file's slug) and removes the plan file from `docs/plans/` as today
      (`git rm || rm`). `bash docs/tests/test-plan-lifecycle.sh`
- [x] The record holds, in order: a `# Plan N: <title>` heading; a header line
      with `**Finished**` date and member count; `## Goal` (and `## Why` when
      non-empty) and `## Decided` (when non-empty) copied from the plan;
      `## What changed` with one line per member,
      `- #ID — title: <summary> (docs/tasks/done/<file>.md)`; `## Follow-ups`
      listing tasks stamped `**From plan**: N` when any exist. Empty sections
      are left out. No file lists or proof lines: git and the linked task files
      hold those. `bash docs/tests/test-plan-lifecycle.sh`
- [x] A member's summary is, in order: its `**Summary**:` line under
      `## Completed`; else the first sentence of the prose before the first
      `###` heading or list under `## Completed`; else nothing (title only).
      Fixtures cover all three shapes, including a `## Completed` that opens
      with `### Assumptions`. `bash docs/tests/test-plan-lifecycle.sh`
- [x] The work agent's land step asks for the summary: `sprintbias_proof_rule`
      tells the agent to open `## Completed` with
      `**Summary**: <one plain sentence: what changed, for someone reading the
      project's history>`, and the task template's after-work hint and
      `docs/sprintbias/ai/task-creation.md` show the line.
      `bash docs/tests/run-all.sh`
- [x] After retiring the plan, `plan done` prints a ready-to-paste changelog
      line, `- Plan N: <title> — see docs/history/<record>.md`, and writes to no
      changelog file. `bash docs/tests/test-plan-lifecycle.sh`
- [x] Readers are pointed at the records: `DOCUMENTATION.md` and the AI
      guidance agents load before work (`docs/sprintbias/ai/`) say, in one line
      each, to check `docs/history/` first for why an area is the way it is.
      `bash docs/tests/run-all.sh`
- [x] When `plan done` refuses (a member outside `done/`), no history record is
      written and the plan file is untouched. The record is fully written
      before the plan file is removed; if writing it fails, the plan file stays
      and `plan done` exits non-zero. `bash docs/tests/test-plan-lifecycle.sh`
- [x] Running `plan done` stays pure shell, no AI. The record is `git add`ed when
      the repo is a git work tree; the commit stays the developer's.
      `bash docs/tests/test-plan-lifecycle.sh`
- [x] `setup.sh` creates an empty `docs/history/` (with `.gitkeep`) on fresh
      install and re-run, and never touches records already there: a
      `safe_mkdir "docs/history"` beside `docs/plans` in the directory step,
      asserted by a check the suite runs. `bash docs/tests/run-all.sh`
- [x] Surfaces say "retires the plan into a history record" instead of "deletes
      the plan file": `help/plan.md`, `help/newplan.md`, `help/promote.md`,
      `help/_registry` (the `plan` row's `done:` text), `DOCUMENTATION.md`
      (Plans section and the docs/ tree), `docs/guides/command-matrix.md`,
      `plan-done.sh` header and output, the `plan-check.sh` and `promote.sh`
      comments that say "deletes", and the learning demos that narrate plan
      done. `./sprint.sh validate --commands`
      and `bash docs/tests/run-all.sh` pass.
- [x] One `### Changed` bullet under `## Unreleased` in `CHANGELOG.md`.
      `grep -n 'docs/history' CHANGELOG.md`

## Signoff (human)

- [ ] Run `plan done` on a real finished plan and read the record: it should
      tell you what the plan was for and what it changed in about a page.
- [ ] After the release, a fresh install (CONTRIBUTING.md step 5) shows an
      empty `docs/history/` with `.gitkeep`.

## Notes

- The folder is `docs/history/` — chosen over `data/` (user content, partly
  gitignored by setup) and `log/` (reads as disposable, collides with
  `docs/tmp/log-*.json` and `cleanup`). One file per plan; the date prefix makes
  `ls docs/history/` the timeline, so no index file.
- `docs/history/` is a starter folder: it ships empty; our own records in this
  repo are dev-internal, like `docs/tasks/`.
- Keep the record plain text per `docs/sprintbias/guides/doc-style.md`.
- Pruning `docs/tasks/done/` once records exist is out of scope; dependencies
  and `plan check` read `done/`.
- Read the plan's sections before the plan file is removed.
- Decided: the summary comes from a new `**Summary**:` line, because current
  `## Completed` sections (plan 28 onward) open with `### Assumptions` or a
  file list and carry no prose, so "first sentence of ## Completed" yields
  nothing for most recent work. Older tasks still fall back to their prose.
- Decided: the record carries the plan's `## Decided` section, because a plan's
  calls (plan 32 has ten) are the part of its history git cannot explain.
- Decided: leave file lists and proof lines out of the record, because git and
  the linked `done/` task files already hold them and a 20-task plan would bury
  the story under 60 paths. The record is for reading.
- Decided: print the changelog line instead of writing it (absorbs the old
  #422), because a user's changelog is theirs and one printed line costs
  nothing.
- Decided: point the manual and AI guidance at `docs/history/`, because a
  record no one is told to read saves no one time.
- Decided: `git add` the record, because `plan done` already stages its
  `git rm`; the pair reads as one retirement in `git status`.
- Decided: the setup check is a suite assertion plus a human fresh-install
  signoff, because a fresh install runs after the human-owned release step.
- Decided: no `**Depends on**`, because every helper this needs
  (`sprintbias_find_plan`, `sprintbias_plan_followups`, `sed_inplace`) is in
  `lib.sh` today; 423 and 439 build on this task, not the reverse.

## References

docs/sprintbias/scripts/plan-done.sh
docs/sprintbias/lib.sh
docs/sprintbias/help/_registry
docs/tasks/.TEMPLATE-task.md
docs/sprintbias/ai/task-creation.md
docs/sprintbias/ai/
docs/tests/test-plan-lifecycle.sh
setup.sh
docs/sprintbias/help/plan.md
docs/sprintbias/help/newplan.md
docs/sprintbias/help/promote.md
DOCUMENTATION.md
docs/guides/command-matrix.md
docs/sprintbias/learning/

## Grounding

**Sources:** `CLAUDE.md` / `CONTRIBUTING.md` (repo map, what ships, surfaces
kept in step), `DOCUMENTATION.md` (manual: Plans section, docs/ tree),
`docs/sprintbias/help/_registry` (command catalog), `docs/guides/command-matrix.md`
(command surfaces), `docs/sprintbias/guides/doc-style.md` (record style),
`docs/sprintbias/lib.sh` (`sprintbias_proof_rule`, plan helpers),
`docs/tasks/.TEMPLATE-task.md` (after-work hint), `setup.sh` (starter folders)
**Terms:**
- None. (No project glossary; `docs/sprintbias/project.md` does not exist yet.)
**Conflicts:**
- `plan-done.sh` header and `help/plan.md:148` state "retirement is deletion,
  never a written status" → the task redefines retirement as record + removal;
  rewrite those lines in the same change (the plan file is still removed, so
  "never a stored status on the plan" stays true).
- "history record" is not a defined term in the manual → read it as "one
  plain-text file per retired plan under `docs/history/`"; the DOCUMENTATION.md
  docs/ tree line this task adds defines it.
- `docs/history/` is a new starter folder not in the CONTRIBUTING.md repo map →
  Doc follow-up: add a `docs/history/` row ("folder only") to the map when the
  task completes.
- `.gitkeep` comes from setup's generic empty-dir sweep (`setup.sh:559`), not
  a per-folder write → `safe_mkdir "docs/history"` is enough; no new mechanism.

**Touching:** docs/sprintbias/scripts/plan-done.sh, docs/sprintbias/lib.sh
(`sprintbias_proof_rule` only), docs/tests/test-plan-lifecycle.sh,
docs/tests/test-setup-history.sh (new), setup.sh, docs/tasks/.TEMPLATE-task.md,
docs/sprintbias/ai/task-creation.md, docs/sprintbias/ai/ (one pointer line),
docs/sprintbias/help/{plan,newplan,promote}.md, docs/sprintbias/help/_registry
(`plan` row), DOCUMENTATION.md, docs/guides/command-matrix.md,
docs/sprintbias/scripts/{plan-check,promote}.sh (comments),
docs/sprintbias/learning/{team-signoff,work}.py, CHANGELOG.md

## Questions

**Status: READY**

### Already complete
None — no matching implementation found.
- `docs/sprintbias/scripts/plan-done.sh` verifies members, ticks checkboxes,
  then `git rm || rm` the plan; no record, no changelog line.
- `sprintbias_proof_rule` (`lib.sh:723`) has no `**Summary**:` instruction;
  the task template and `ai/task-creation.md` show no Summary line.
- `setup.sh` (directory step ~line 533) creates no `docs/history/`; the folder
  does not exist in this repo.
- "deletes" wording remains in `plan-check.sh:9`, `promote.sh:39`,
  `help/plan.md:103,148`, `help/promote.md:73`, `command-matrix.md:196`.
- `docs/tests/test-plan-lifecycle.sh` exists and is the place for the new cases.

### Remaining work
- `plan done` writes the record (heading, Finished/member header, Goal, Why,
  Decided, What changed, Follow-ups; empty sections dropped), atomically before
  removing the plan, `git add`s it, and prints the changelog line.
- Summary extraction: `**Summary**:` line → first prose sentence under
  `## Completed` → title only; fixtures for all three, incl. `### Assumptions` first.
- Refusal and write-failure paths leave the plan file untouched, exit non-zero.
- `sprintbias_proof_rule`, task template hint, `ai/task-creation.md` ask for
  the `**Summary**:` line.
- `DOCUMENTATION.md` and `docs/sprintbias/ai/` point readers at `docs/history/`.
- `setup.sh` creates `docs/history/`; a suite check asserts it.
- Wording sweep across help, registry, manual, matrix, scripts, learning demos;
  `validate --commands` and `run-all.sh` green.
- CHANGELOG `### Changed` bullet.

### Questions for the developer
None — task is fully defined.

## Test log

- `bash docs/tests/test-proof-loop.sh` — "Rule stays short (<= 14 lines, got 15)".
  The test was right to guard the budget, and the Summary ask is required by
  this task: folded it into the "To land" bullet and raised the budget to 15
  with a comment naming why. Green after.
- `bash docs/tests/test-setup-detection.sh` — new Test 33 "safe_mkdir: command
  not found": the suite only sources setup.sh's fenced helpers; the test now
  extracts `safe_mkdir` from setup.sh itself. Green after.

## Completed

**Summary**: `plan done` now writes a readable history record of each finished plan to `docs/history/` before removing the plan file, and prints a changelog line to paste.

### Assumptions
- Decided: record header is `**Finished**: YYYY-MM-DD · **Members**: N`, because it matches the bold-field style of every other SprintBias file.
- Decided: Follow-ups lists every task stamped `**From plan**: N` in any folder (members excluded), not only the open unbound ones `newplan from:N` groups, because the record is history and a finished follow-up is still part of it.
- Decided: dropped the step that ticked member checkboxes before removal, because the file is removed right after and the edit made `git rm` refuse a tracked plan (local modifications), silently falling back to an unstaged `rm`.
- Decided: the `docs/history/` pointer also goes in the work prompt's project-map line (`sprintbias_orient` in lib.sh), besides `ai/conversation.md`, `ai/task-creation.md` and `ai/refine.md`, because that line is what every work agent reads before it starts.
- Decided: the record is built in a temp file inside `docs/history/` and renamed into place, so it is whole or absent; the plan is removed only after the rename succeeds.

### Files changed
docs/sprintbias/scripts/plan-done.sh
docs/sprintbias/scripts/plan-check.sh
docs/sprintbias/scripts/promote.sh
docs/sprintbias/lib.sh
docs/sprintbias/ai/conversation.md
docs/sprintbias/ai/task-creation.md
docs/sprintbias/ai/refine.md
docs/sprintbias/help/plan.md
docs/sprintbias/help/newplan.md
docs/sprintbias/help/promote.md
docs/sprintbias/help/_registry
docs/sprintbias/learning/team-signoff.py
docs/sprintbias/learning/work.py
docs/tasks/.TEMPLATE-task.md
docs/tests/test-plan-lifecycle.sh
docs/tests/test-setup-detection.sh
docs/tests/test-proof-loop.sh
docs/guides/command-matrix.md
DOCUMENTATION.md
setup.sh
CHANGELOG.md

### Doc follow-ups
- `CONTRIBUTING.md` — add a `docs/history/` row ("folder only": our own plan records; users get the folder empty) to the repo map; it is a governing source, so left to the maintainer.

Tests run: `bash docs/tests/test-plan-lifecycle.sh` (116 pass), `bash docs/tests/test-setup-detection.sh`, `bash docs/tests/test-proof-loop.sh`, `./sprint.sh validate --commands`, `./sprint.sh validate --docs`, `bash docs/tests/run-all.sh` (35/35 scripts), `grep -n 'docs/history' CHANGELOG.md`.

**Breaker**: 13 cases tried · 4 fixed · 0 filed
- Fixed: a plan file with no `# ` heading made `plan done` exit 1 silently (pipefail on the title grep); it now retires titled "Plan N".
- Fixed: a `**Summary**:` line was cut at its first ". " (e.g. "e.g.") and lost its wrapped second line, the shape the task template shows; the Summary is now taken whole and joined, and only the prose fallback is cut to one sentence (`sprintbias_task_summary`, shared with `history record`).
- Fixed: CRLF plan and task files lost the member summary and put carriage returns in titles and sections; both now read like LF files.
- Fixed: a plan that was `git add`ed but never committed was left as `AD` in the index (git rm refused, rm fallback did not stage); `git rm -f` now stages the removal, since the record already holds the plan.
- Held up: run twice (second run finds no plan, record unchanged, no temp files), `%` and backslashes in titles/goal/summary, refusal, write failure, follow-ups, history neighbors (`test-history.sh`).

**Proof**: 2026-10-11 · bash docs/tests/test-plan-lifecycle.sh; bash docs/tests/run-all.sh; ./sprint.sh validate --commands · pass
