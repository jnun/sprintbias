# Task 419: Crew lanes and task holds stall work in fast mode

**Feature**: none
**Created**: 2026-10-10
**Docs**: none
**Plan**: 30
**From plan**: none
**Depends on**: 415, 417
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

Crew members must stay in their member file's lane, a task held by another member is off-limits, and the lead never writes code and sends every decision to the person. When a holder stalls or a lane is idle, work waits instead of moving.

## Done when (automated)

- [x] With fast on, a member's crew prompt lets it take a task held by another member: message the holder first, and when `./sprint.sh agents` shows no live session for the holder, set **Crew** to itself, leave one takeover line on the plan's ## Crew board, and continue (`bash docs/tests/test-fast.sh` checks the crew prompt in emit mode)
- [x] With fast on, the member prompt treats May touch as a routing preference, not a wall; the **Touching:** announcement and the never-revert-others rule stay in the prompt (`bash docs/tests/test-fast.sh`)
- [x] With fast on, the lead prompt lets the lead build and carries the #417 fast rule block in place of "Raise decisions for the human one at a time", asking the person only goal questions (`bash docs/tests/test-fast.sh`)
- [x] With fast off, member and lead prompts are unchanged: the existing rules 2 and 3 and "Leave product code to the members" are present and no takeover text appears (`bash docs/tests/test-crew.sh` and `bash docs/tests/test-fast.sh`)
- [x] help/crew.md and guides/crew.md describe the fast behavior; `./sprint.sh validate --docs` passes
- [x] `bash docs/tests/run-all.sh` passes

## Signoff (human)

- [ ] Run a two-member crew with fast on; stop one member mid-task and watch the other take it over

## Notes

The **Crew** field stays the claim. A takeover leaves one line on the plan's ## Crew board: who took what from whom, and why.

Branch on #415's `sprintbias_fast_on` inside crew.sh `cmd_start` (rules 2 and 3 for members, the last lead bullet for the lead) and splice #417's `sprintbias_fast_rules` into the same `rules` string. Keep the fast wording short and positive; it loads in every crew session.

The human-owned invariants hold in fast mode too: the human approves, commits and ships (rule 6), and promote plan:N stays the human's sign-off.

Add one line to the Crew section of DOCUMENTATION.md pointing at the fast behavior, and a CHANGELOG bullet under Unreleased.

## References

docs/sprintbias/scripts/crew.sh
docs/sprintbias/help/crew.md
docs/sprintbias/guides/crew.md
docs/sprintbias/lib.sh (sprintbias_parallel_rule, the Touching and never-revert text)
docs/tests/test-crew.sh
docs/tasks/next/415-add-a-clear-fast-on-off-switch.md
docs/tasks/next/417-fast-mode-lets-agents-decide-and-ask-only-goal-que.md

## Grounding

**Sources:** `CLAUDE.md` (guiding principles; positive instruction, human-owned actions), `CONTRIBUTING.md` (surfaces kept in step, test ladder), `DOCUMENTATION.md` (Crew section: claims, lanes, ## Crew board), `docs/plans/30-fast-mode-autonomous-agents-fewer-blockers.md` (plan Goal and Policy), `docs/sprintbias/scripts/crew.sh` (member and lead start prompts), `docs/sprintbias/lib.sh` (prompt fragments, fast helpers from #415/#417)
**Terms:**
- None. (No glossary; docs/sprintbias/project.md does not exist yet.)
**Conflicts:**
- The original brief named `docs/sprintbias/tests/test-fast.sh`; the suite lives in `docs/tests/` and #415 creates `docs/tests/test-fast.sh` → use `docs/tests/test-fast.sh`.
- `sprintbias_fast_on` and `sprintbias_fast_rules` do not exist yet in lib.sh → produced by #415 and #417; recorded under **Depends on**, not a blocker.
- The lead rule "Leave product code to the members ... Raise decisions for the human one at a time" (crew.sh ~line 237) and guides/crew.md (orcha: "no product code"; "A task in doing/ held by someone else is theirs — Ask the lead") contradict fast behavior → keep them as the steady text and add the fast variant beside them in the prompt and docs.
- CONTRIBUTING step 3 keeps DOCUMENTATION.md in step with user-facing behavior; the brief named only help and guide → add one line to DOCUMENTATION.md's Crew section as well.

**Touching:** docs/sprintbias/scripts/crew.sh, docs/tests/test-fast.sh, docs/sprintbias/help/crew.md, docs/sprintbias/guides/crew.md, DOCUMENTATION.md, CHANGELOG.md

## Questions

**Status: READY**

### Already complete
None — no matching implementation found. Checked:
- `docs/sprintbias/scripts/crew.sh:220-237` — member rules 2 (held task is off-limits) and 3 (stay in May touch), lead bullet "Leave product code to the members ... Raise decisions for the human one at a time"; no fast branch anywhere in crew.sh.
- `docs/sprintbias/lib.sh:630-655` — `sprintbias_parallel_rule` already carries the **Touching:** announcement and never-revert rule that must stay; no `sprintbias_fast_on` / `sprintbias_fast_rules` yet (#415, #417).
- `docs/sprintbias/help/crew.md`, `docs/sprintbias/guides/crew.md` — describe lanes and holds only; no fast text.
- `docs/tests/test-crew.sh` already tests the member and lead prompts in emit mode; `docs/tests/test-fast.sh` does not exist yet (#415 creates it).

### Remaining work
- Fast branch in crew.sh member rules: takeover of a stalled hold (message holder, check `./sprint.sh agents`, set **Crew**, one ## Crew board line: who took what from whom, and why) and May touch as a routing preference.
- Fast branch in the lead rules: the lead may build; decisions follow `sprintbias_fast_rules`, goal questions only.
- Steady prompts byte-for-byte as today.
- Tests in `docs/tests/test-fast.sh` for fast on/off crew prompts; `docs/tests/test-crew.sh` stays green.
- help/crew.md, guides/crew.md, one DOCUMENTATION.md Crew line, CHANGELOG bullet.

### Questions for the developer
None — task is fully defined.

## Completed

Fast branches in `crew.sh cmd_start`: member rules 2 and 3 (takeover of a stalled hold; May touch as a routing preference) and the lead's last bullet (lead builds; goal questions only). The #417 `sprintbias_fast_rules` block was already spliced into the shared `rules` string, so the lead carries it too. Steady prompts are byte-for-byte as before.

### Assumptions
- Decided: the takeover line format is `Takeover: #id from <holder> to <name>, because <why>`, because the notes ask for who/what/whom/why in one line.
- Decided: the lead's fast bullet keeps "You plan, route, unblock and check landed work" and adds building, because the lead still holds the plan.
- Decided: guides/crew.md keeps its steady rows (orcha "no product code", "Ask the lead") and gains a fast-rule table beside them, per Grounding.

### Files changed
- docs/sprintbias/scripts/crew.sh
- docs/tests/test-fast.sh
- docs/sprintbias/help/crew.md
- docs/sprintbias/guides/crew.md
- DOCUMENTATION.md
- CHANGELOG.md

Tests run: `bash docs/tests/test-fast.sh` (122 pass), `bash docs/tests/test-crew.sh` (76 pass), `./sprint.sh validate --docs` and `--commands` (clean), `bash docs/tests/run-all.sh` (29/29 scripts green).

**Proof**: 2026-10-10 · bash docs/tests/test-fast.sh; bash docs/tests/test-crew.sh; ./sprint.sh validate --docs; bash docs/tests/run-all.sh · pass
