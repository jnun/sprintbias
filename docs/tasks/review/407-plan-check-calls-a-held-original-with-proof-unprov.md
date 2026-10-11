# Task 407: Plan check calls a held original with proof unproven

**Feature**: none
**Created**: 2026-10-08
**Docs**: none
**Plan**: 29
**From plan**: 28
**Depends on**: none
**Dependents**: 411
**Parent**: none
**Fixes**: none
**Crew**: core
**Tests**: docs/tests/test-plan-lifecycle.sh
**Refined**: 0
**Reworked**: 0

## Problem

After a rejection, the original task stays in review/ with its proof line and
`**Held**: fix #N`. plan check and status call it "in review, unproven (no
**Proof**: line)", which is false and sends the human looking for a missing
proof. #401's standing check treats every review/ task that hasn't landed as
unproven; it was built in parallel with #402's Held rule and never learned it.


## Done when (automated)

- [x] `sprintbias_member_standing` returns a distinct `held` standing for a review/ task that has its proof line and a `**Held**:` fix still open; `unproven` stays for a review/ task without a proof line.
- [x] plan check and status show a held task as `held: fix #N` (naming the open fix), and list it apart from unproven tasks; a held plan never reads LANDED.
- [x] `bash docs/tests/test-plan-lifecycle.sh` covers held-with-proof, held-without-proof, and unproven.


## Signoff (human)

- [ ] Reject a task on a scratch board and read plan check: the held line tells you what to do next.


## Notes

Follow-up from plan 28; its Policy applies: docs/plans/28-enhance-crews-and-efficiency.md.

Fix the standing in one place (lib.sh) so plan check, status and promote plan:N agree. `sprintbias_held_fixes FILE` (#402) lists a task's fixes.

A held task without a proof line reads `unproven`: the missing proof is the
first thing to fix. `held` applies only once the proof line is present and a
named fix has not landed (once every named fix lands, the original reads
`landed`, as `sprintbias_dep_landed` already decides).


## References

docs/sprintbias/lib.sh (sprintbias_member_standing, sprintbias_dep_landed, sprintbias_held_fixes)
docs/sprintbias/scripts/plan-check.sh
sprint.sh (status_plans)
docs/tests/test-plan-lifecycle.sh


## Grounding

**Touching:** docs/sprintbias/lib.sh (sprintbias_member_standing, sprintbias_plan_counts, sprintbias_plan_state; new sprintbias_held_open_fixes, sprintbias_held_label), docs/sprintbias/scripts/plan-check.sh, sprint.sh (status_plans), docs/tests/test-plan-lifecycle.sh, docs/sprintbias/help/plan.md, docs/sprintbias/help/status.md
**Sources:** `docs/plans/28-enhance-crews-and-efficiency.md` (Policy: Landed, Proof line, Held, Fixes, plan states), `docs/sprintbias/lib.sh` (sprintbias_member_standing, sprintbias_plan_counts, sprintbias_plan_state — the one standing rule), `docs/sprintbias/scripts/plan-check.sh`, `sprint.sh` (status_plans), `docs/sprintbias/scripts/promote.sh` (promote plan:N refusal listing), `docs/tests/test-plan-lifecycle.sh`
**Terms:**
- **Landed** — in review/ with a proof line. Landed work releases its dependents. In review/ without proof is "in review, unproven" and releases nothing.
- **Fix tasks** — `**Fixes**: #<id>` on the fix task; `**Held**: fix #<new>` on the rejected original, which stays in review/ and releases nothing until the fix lands.
- **Plan states** — computed from the folders: STARTED (work open), LANDED (every member landed), SIGNED OFF (every member in done/).
**Conflicts:**
- Plan 28 Policy names "in review, unproven" but has no word for a held original with proof → use the standing `held`, shown as `held: fix #N`; suggest adding "Held (standing)" to plan 28's Policy terms as a Doc follow-up.
- Held without a proof line: the Done-when line "unproven stays for a review/ task without a proof line" governs → it reads `unproven` (settled in Notes).
- Task #408 edits the same promote.sh refusal listing (dedupe open fixes) → no ordering needed; whichever lands second merges onto the other's listing and keeps both behaviors.
- No project map or glossary exists (docs/sprintbias/project.md absent) → plan 28's Policy serves as the term source.


## Questions

**Status: READY**

### Already complete
None — no matching implementation found. Checked:
- `docs/sprintbias/lib.sh` `sprintbias_member_standing` (~line 2180): review/ returns `landed` when `sprintbias_dep_landed` passes, else `unproven` — a held original with proof falls into `unproven`.
- `sprintbias_dep_landed` (~line 1461) already treats Held correctly (not landed until every named fix lands); `sprintbias_held_fixes` (~line 1481) exists.
- `sprintbias_plan_counts` has no `held` bucket; a new standing would fall into its `*)` branch and count as missing.
- `plan-check.sh`, `sprint.sh status_plans` and `promote.sh` (~line 304) only special-case `unproven`; promote's `*)` branch would print a held task as "open".
- `docs/tests/test-plan-lifecycle.sh` covers unproven (~line 388) but no held case.

### Remaining work
- `sprintbias_member_standing` returns `held` for review/ + proof line + an unlanded fix from `sprintbias_held_fixes`; `unproven` for review/ without proof (held or not); `landed` once all fixes land.
- `sprintbias_plan_counts` counts `held` (and as moved); `sprintbias_plan_state` keeps a plan with any held member out of LANDED. Keep the count line's field order stable for its three readers (plan-check.sh, status_plans, plan_state) or update all three.
- plan check: per-member Standing column shows `held: fix #N`; a separate flag block lists held members apart from the unproven block; counts line gains `held N` when non-zero.
- status (`sprint.sh status_plans`): member line shows `held: fix #N`; separate held flag line.
- promote plan:N refusal listing: a `held` case naming the open fix instead of falling into "open".
- `docs/tests/test-plan-lifecycle.sh`: fixtures and asserts for held-with-proof (`held: fix #N`, plan not LANDED), held-without-proof (`unproven`), and plain unproven (existing test still passes).
- `help/plan.md` / `help/status.md` and DOCUMENTATION.md if they describe the standings list.

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


## Completed

`sprintbias_member_standing` now returns `held` for a review/ task with its
proof line and a `**Held**:` fix not yet landed; review/ without proof stays
`unproven` (held or not); once every fix lands it reads `landed`. Two reusable
helpers: `sprintbias_held_open_fixes ID` (unlanded fix ids) and
`sprintbias_held_label ID` (`held: fix #N`, the one spelling for every
listing). `sprintbias_plan_counts` appends `held` as a 9th field (the first
eight keep their order; plan-check.sh, status_plans and plan_state read it).
A held member never counts as landed, so the plan stays out of LANDED.
plan check shows `held: fix #N` in the Standing column, `held N` in Counts and
a separate Held flag block; status shows it on the member line and a separate
`⚠ held, waiting on its fix:` line.

Overlap: promote.sh (owned by signoff, #408/#409) still falls into `*)` "open"
for a held member; #409 can print `sprintbias_held_label "$mid"` there.

### Files changed
docs/sprintbias/lib.sh
docs/sprintbias/scripts/plan-check.sh
sprint.sh
docs/tests/test-plan-lifecycle.sh
docs/sprintbias/help/plan.md
docs/sprintbias/help/status.md
CHANGELOG.md

### Doc follow-ups
- `docs/plans/28-enhance-crews-and-efficiency.md` Policy — add "Held (standing): review/ with proof, a fix not yet landed; shown `held: fix #N`".
- `DOCUMENTATION.md` (`Held` field, ~line 136) — mention plan check / status show it as `held: fix #N`.

Full suite: `bash docs/tests/run-all.sh </dev/null` → 27 passed, 1 failed (test-cleanup-tmp.sh, failing before this change). `./sprint.sh validate --commands` and `--docs` clean.

**Proof**: 2026-10-08 · bash docs/tests/test-plan-lifecycle.sh; bash docs/tests/test-dep-work.sh; bash docs/tests/test-promote.sh; bash docs/tests/test-proof-loop.sh · pass
