# Task 397: Bring project docs in step with landed work

**Feature**: none
**Created**: 2026-10-08
**Docs**: none
**Plan**: none
**From plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Crew**: none
**Tests**: none
**Refined**: 1
**Reworked**: 0

## Problem

Landed work changed facts that project documents describe, or found gaps in
them. Each item in the Follow-ups list at the end of this file names a
document, what must change, and the task it came from. Until an item is fixed,
an agent or person reading that document gets an outdated picture.

## Done when (automated)

- [x] Every Follow-ups item is checked, with the named document stating the
      current facts, or struck with a one-line reason. `sed -n '/^## Follow-ups/,$p'
      docs/tasks/*/397-*.md | grep -c '^- \[ \]'` prints 0.
- [x] For the `agents` item: `docs/guides/provider-reality.md` says `agents`
      reads Claude Code session records (`~/.claude/sessions/<pid>.json`, or
      `$CLAUDE_CONFIG_DIR/sessions`) and that Grok Build support is unknown.
      `grep -n "sessions/" docs/guides/provider-reality.md` finds it.
- [x] For the `docs/history/` item: the `CONTRIBUTING.md` repo map has a
      `docs/history/` row marked "folder only" (our own plan records; users get
      the folder empty). `grep -n 'docs/history/' CONTRIBUTING.md` finds it.
- [x] A follow-up stays filed once whatever its checkbox: after an item is
      checked (`- [x]`), struck, or prefixed with a note, a new
      `sprintbias_file_doc_followups` run adds no copy of it. `bash
      docs/tests/test-profile.sh` covers this (check the filed item, re-run,
      expect no output and one `from #7` line).
- [x] `bash docs/tests/run-all.sh` passes.

## Signoff (human)

None: the automated checks cover it.

## Notes

- Items already true on current files were checked on 2026-10-10, each with
  where it now lives. Only the `agents` item was open then; new items may have
  been appended since.
- `lib.sh` (`SPRINTBIAS_DOC_FOLLOWUPS_MARKER`) appends new items to this task
  while it sits in backlog/. Keep the marker comment and the Follow-ups
  heading as they are.
- Follow-up 7 (`profile` and `TEST_SUITE`) is a feature, not a doc fix; it
  moved to its own task.
- Re-checked 2026-10-10 (second refine): the Follow-ups list held each
  #398-#409 item twice, an annotated checked copy and the original unchecked
  copy. Each original was re-verified against current files and checked as a
  duplicate. Open after this pass: the `agents` item (#396) and the
  `CONTRIBUTING.md` `docs/history/` row (#421).
- Root cause of the duplicates: `sprintbias_file_doc_followups` (lib.sh)
  dedupes by `grep -F "- [ ] <text> (from #N)"`, so any item once checked is
  re-appended on the next work/promote run. Every checked item in this list
  would come back.
- Decided: fix the dedupe in this task (match `<text> (from #N)` regardless of
  the checkbox and any prefix), because otherwise the first Done when check
  cannot stay true. Resolve items by checking them and adding a note before the
  original text; keep the original `<text> (from #N)` intact so it still
  matches.
- Decided: add the `docs/history/` row to `CONTRIBUTING.md` in this task,
  because it is a one-row factual correction (DOCUMENTATION.md, lib.sh and
  `plan done` already create and use `docs/history/`), and closing doc gaps is
  this task's whole purpose; the row matches the existing "folder only" rows.
- Decided: the `agents` note goes under the Known unknowns table in
  `provider-reality.md` (a KU row with OPEN status for Grok Build), because
  that file is where proven and unproven provider behavior is tracked.

## References

docs/guides/provider-reality.md
docs/sprintbias/scripts/agents.py
CONTRIBUTING.md
docs/sprintbias/lib.sh
docs/tests/test-profile.sh

## Grounding

**Sources:** `docs/guides/provider-reality.md` (provider behavior, known knowns / known unknowns), `CONTRIBUTING.md` (repo map: what ships), `DOCUMENTATION.md` (user manual), `CHANGELOG.md` (user-facing change log), `docs/sprintbias/lib.sh` (`SPRINTBIAS_DOC_FOLLOWUPS_MARKER`, appends follow-ups here)
**Terms:**
- None. The project has no glossary file.
**Conflicts:**
- `lib.sh` dedupe vs this task's Done when (0 unchecked items): checked items are re-filed unchecked → Decided (see Notes): fix the dedupe here.
- Follow-ups list vs current files: fifteen unchecked items describe gaps already closed → each checked as a duplicate with where it now lives.
- #421 item says `CONTRIBUTING.md` is "left to the maintainer" vs this task owning doc follow-ups → Decided (see Notes): add the one factual row here.
- `docs/history/` is used by `plan done`, `history record` and the manual, but missing from the CONTRIBUTING repo map → the row this task adds settles it.
**Touching:** `docs/sprintbias/lib.sh` (`sprintbias_file_doc_followups` only), `docs/tests/test-profile.sh`, `docs/guides/provider-reality.md`, `CONTRIBUTING.md`, `CHANGELOG.md`

<!-- sb:doc-followups -->
## Follow-ups

- [x] Done: provider-reality.md KU-19a. `docs/guides/provider-reality.md` — note `agents` reads Claude Code session records; Grok Build support unknown (from #396)
- [x] `DOCUMENTATION.md` — review/ row and Depends on say a dependent releases on landed work. Already true: Folders table and Task fields. (from #398)
- [x] `docs/sprintbias/scripts/gate-lib.sh` — gate prompt wording. Already true: reads "land (review/ with a proof line) or reach done/". (from #398)
- [x] `DOCUMENTATION.md` — describe Done when (automated), Signoff (human). Already true: "Task sections" paragraph. (from #399)
- [x] `docs/sprintbias/learning/session.py` — "Success criteria" wording. Already true: says "Done when (automated)". (from #399)
- [x] `DOCUMENTATION.md` — worker test loop. Already true: "Test loop" paragraph and the landed distinction. (from #400)
- [x] ~~`docs/sprintbias/scripts/profile.sh` — `**Test:**` line could point at `TEST_SUITE`; `profile` could offer to set it.~~ Struck: a feature, moved to its own task. (from #403)
- [x] `DOCUMENTATION.md` → Crew section — lead routine. Already true: Crew section covers disjoint Touching, routing on landing, "built on #N (landed)", one `promote plan:N`. (from #404)
- [x] `docs/sprintbias/learning/` crew demo — lead routes on landing, closes with one `promote plan:N`. Already true: `team-landing.py`, `team-signoff.py`. (from #404)
- [x] `docs/sprintbias/scripts/plan-check.sh` — LANDED footer. Already true: points at `./sprint.sh promote plan:N`. (from #404)
- [x] `docs/sprintbias/learning/` demos — plan finishes with one `promote plan:N`. Already true: `work.py`, `team-signoff.py`. (from #405)
- [x] ~~`docs/plans/28-enhance-crews-and-efficiency.md` Policy — add a "Held (standing)" line.~~ Struck: plan 28 is our own working file; the manual's `Held` field already states the rule. (from #407)
- [x] `DOCUMENTATION.md` `Held` field — mention `held: fix #N`. Already true. (from #407)
- [x] `CHANGELOG.md` — Unreleased / Fixed: open fix task listed once. Already true. (from #408)
- [x] `CHANGELOG.md` — Unreleased / Changed: green full-suite reuse, `--fresh`. Already true. (from #409)
- [x] Duplicate, already true (see above). `DOCUMENTATION.md` — the review/ row ("done, awaiting your approval") and the Depends on field should say a dependent releases on landed work (review/ with a proof line) or done/; owned by #405. (from #398)
- [x] Duplicate, already true: gate-lib.sh line 219. `docs/sprintbias/scripts/gate-lib.sh` — the gate prompt says the runner holds a dependent "until those dependencies reach review/ or done/"; it should read "land (review/ with a proof line) or reach done/". Left alone: #399 owned the file this round. (from #398)
- [x] Duplicate, already true (see above). `DOCUMENTATION.md` — the manual does not yet describe the task sections (Done when (automated), Signoff (human)); task 405 owns the docs pass. (from #399)
- [x] Duplicate, already true: session.py line 156. `docs/sprintbias/learning/session.py` — the demo still says "Writing that into Success criteria"; task 406 owns the demos. (from #399)
- [x] Duplicate, already true (see above). `DOCUMENTATION.md` — describe the worker test loop (targeted tests, ## Test log, proof line) in the work and crew sections; task 405 owns the solo/crew docs pass. (from #400)
- [x] ~~Duplicate.~~ Struck: a feature, moved to its own task. `docs/sprintbias/scripts/profile.sh` — the project map's `## Commands` → `**Test:**` line could point at `TEST_SUITE`, and `profile` could offer to set it. (from #403)
- [x] Duplicate, already true (see above). `DOCUMENTATION.md` → Crew section — describe the lead routine (split on disjoint Touching, route on landing, next task queued, "built on #N (landed)", plan close ending in one `promote plan:N`) and members reporting each landing (#405). (from #404)
- [x] Duplicate, already true (see above). `docs/sprintbias/learning/` crew demo — show the lead routing on landing and closing the plan with one `promote plan:N` (#406). (from #404)
- [x] Duplicate, already true: plan-check.sh LANDED footer names `promote plan:$PLAN_ID`. `docs/sprintbias/scripts/plan-check.sh` — the LANDED footer still says "Run the full suite, sign members off into done/, then: plan done"; point it at `./sprint.sh promote plan:N` (#405). (from #404)
- [x] Duplicate, already true (see above). `docs/sprintbias/learning/` demos — show a plan finishing on landed work with one `promote plan:N` (owned by #406) (from #405)
- [x] ~~Duplicate.~~ Struck: plan 28 is our own working file. `docs/plans/28-enhance-crews-and-efficiency.md` Policy — add "Held (standing): review/ with proof, a fix not yet landed; shown `held: fix #N`". (from #407)
- [x] Duplicate, already true: DOCUMENTATION.md line 141. `DOCUMENTATION.md` (`Held` field, ~line 136) — mention plan check / status show it as `held: fix #N`. (from #407)
- [x] Duplicate, already true: CHANGELOG.md line 231. `CHANGELOG.md` — add under Unreleased / Fixed: "`promote plan:N` lists an open fix task once, as `fix #N for #M`, instead of twice." (outside signoff's files; for the lead) (from #408)
- [x] Duplicate, already true: CHANGELOG.md line 129. `CHANGELOG.md` (lead) — ### Changed: "`promote plan:N` reuses a green full-suite run when nothing in the working tree has changed since, so the human's sign-off after the lead's run is free; `--fresh` forces a re-run. A held original now reads `held: fix #N` in its refusal listing." (from #409)
- [x] Already true on 2026-10-10: `bash docs/tests/test-proof-loop.sh` passes 42/42, Test 5 included. `docs/tests/test-proof-loop.sh` — Test 5's fixture is ungated, so work.sh emit gates instead of printing the work prompt; its owner should gate the fixture (or set it as already gated) so the full suite is green. (from #415)
- [x] Done: CONTRIBUTING.md repo map row. `CONTRIBUTING.md` — add a `docs/history/` row ("folder only": our own plan records; users get the folder empty) to the repo map; it is a governing source, so left to the maintainer. (from #421)

## Questions

**Status: READY**

### Already complete
- 13 of the 15 #398-#409 follow-ups were already true and checked by the first
  refine; their unchecked duplicates are now checked with where each lives
  (gate-lib.sh:219, plan-check.sh LANDED footer, session.py:156,
  DOCUMENTATION.md:141, CHANGELOG.md:129 and :231).
- #415 (`test-proof-loop.sh` Test 5): `bash docs/tests/test-proof-loop.sh`
  passes 42/42 on 2026-10-10; checked.
- `agents` implementation: `docs/sprintbias/scripts/agents.py:27,166` reads
  `$CLAUDE_CONFIG_DIR` or `~/.claude`, then `sessions/<pid>.json`. The doc note
  is still missing: `grep "sessions/" docs/guides/provider-reality.md` finds
  nothing.
- `docs/history/` is in DOCUMENTATION.md and lib.sh but absent from the
  CONTRIBUTING.md repo map.

### Remaining work
- `docs/guides/provider-reality.md`: record that `agents` reads Claude Code
  session records (`~/.claude/sessions/<pid>.json` or
  `$CLAUDE_CONFIG_DIR/sessions`); Grok Build support unknown (KU, OPEN).
- `CONTRIBUTING.md` repo map: add the `docs/history/` "folder only" row.
- `docs/sprintbias/lib.sh` `sprintbias_file_doc_followups`: dedupe on
  `<text> (from #N)` whatever the checkbox; extend `docs/tests/test-profile.sh`
  to check the item, re-run, and expect nothing new.
- Check the last two Follow-ups items, then run `bash docs/tests/run-all.sh`.

### Questions for the developer
None — task is fully defined.

## Completed

**Summary**: Doc follow-ups now stay resolved once checked or annotated (the tracker's dedupe ignores the checkbox and any note before the original text), and `provider-reality.md` and the `CONTRIBUTING.md` repo map record the `agents` session source and `docs/history/`.

### Assumptions
- Decided: an item counts as filed when a tracker bullet *ends* in ` <text> (from #N)`, because a note goes before the text and an end match keeps `(from #7)` from matching `(from #77)`. A struck item stays filed when its original text is kept after the strike, as the items here do.
- Decided: the Grok Build gap is KU-19a, beside KU-19 (sessions / messaging), stamped OPEN.

### Files changed
docs/sprintbias/lib.sh
docs/tests/test-profile.sh
docs/guides/provider-reality.md
CONTRIBUTING.md
CHANGELOG.md

### Notes for the maintainer
- `docs/tasks/backlog/442-bring-project-docs-in-step-with-landed-work.md` (staged, untouched since creation) is a second tracker the old dedupe bug opened today: all 15 of its items are the already-resolved #398-#415 duplicates checked in this task. It can be deleted; with the fix, a fresh run without it files nothing.

Tests: `bash docs/tests/test-profile.sh` (38/38), `bash docs/tests/run-all.sh` (36/36 scripts), plus a copy-of-repo run of `sprintbias_file_doc_followups` that filed nothing.

**Proof**: 2026-10-10 · bash docs/tests/test-profile.sh; bash docs/tests/run-all.sh · pass
