# Task 327: Lock task header language Plan Dependents Tests

**Feature**: none
**Created**: 2026-08-01
**Docs**: docs/plans/15-dependency-integrity-and-work-completion-path.md
**Plan**: 15
**Depends on**: none
**Dependents**: 328, 329, 330, 331, 332
**Parent**: none
**Tests**: none
**Refined**: 1
**Reworked**: 0

## Problem

Task headers must use one plain name per concept so people and agents never
invent a second field. The reverse dependency edge used to say **Blocks**
(misread as “this task is blocked”). Close-path proof used to say **Proven by**
(process jargon). Plan membership lived only on the plan file. We need a locked
language contract: **Plan**, **Depends on**, **Dependents**, **Docs**, **Tests**
— with read-only aliases for old spellings, and a protocol for when AI sets
**Tests**.

## Success criteria

- [x] Template stamps **Plan**, **Depends on**, **Dependents** (not **Blocks**
      as write target)
- [x] validate / chat-sprint read **Dependents** first, **Blocks** as alias
- [x] AI guidance teaches Depends on / Dependents pairing in common language
- [x] Template and create path stamp **Tests** (not **Proven by** as write target)
- [x] promote reads **Tests** first, **Proven by** as alias; help/registry say
      **Tests**
- [x] Positive protocol documented: when to set **Tests** (real suite path that
      proves success criteria) vs leave `none` (human sign-off)
- [x] **Docs** vs **Tests** taught in one line (read while building vs prove to close)
- [x] newtask help names Plan / Depends on / Dependents / Tests

## Notes

- Locked decisions (plan 15): write **Dependents** and **Tests** only; aliases
  **Blocks** and **Proven by** on read; migrate on touch; no dual live fields.
- Product `newtest` markdown loops never go in **Tests**.
- **Parent** ≠ **Plan**. Plan file remains membership authority; **Plan** on
  the task is reverse index (#331 finishes sync).
- Antifragile: hopeful **Tests** paths that do not exist keep tasks in review/
  forever — prefer `none` until the script is real.

## References

docs/tasks/.TEMPLATE-task.md
docs/sprintmd/ai/task-creation.md
docs/sprintmd/scripts/promote.sh
docs/sprintmd/help/promote.md
docs/sprintmd/help/newtask.md
docs/sprintmd/help/_registry
docs/plans/15-dependency-integrity-and-work-completion-path.md
docs/guides/running-tests.md

## Questions

**Status: READY**

### Already complete

- Template has **Plan**, **Dependents**, and (was) **Proven by** — Dependents
  rename and Plan field largely landed in prior work.
- validate-tasks.sh and chat-sprint prefer Dependents with Blocks fallback.
- task-creation.md and several help pages teach Dependents.

### Remaining work

1. Canonicalize **Tests** everywhere that still writes **Proven by** (template
   done in this plan pass; verify create-task output).
2. promote + help + registry on **Tests** with Proven by alias (in flight).
3. Short protocol block in task-creation / running-tests for setting **Tests**.
4. Confirm newtask help lists all four graph/close fields.

### Questions for the developer

None — language contract is locked on plan 15.

## Completed

The full **Tests** / **Proven by** language contract had already landed across
the live `docs/` tree during the plan-15 pass. Verified every deliverable is
present — no source edits were required:

- **Template + create path** — `docs/tasks/.TEMPLATE-task.md:10` stamps
  `**Tests**: none` (no **Proven by** write target); `create-task.sh` copies the
  template verbatim, so the create path inherits **Tests**. Header comment
  (lines 21-22) records the read-only aliases and "write canonical only".
- **promote reads Tests first, Proven by as alias** — `promote.sh:68-71` prefers
  `**Tests**` and falls back to `**Proven by**`; `help/promote.md` and
  `help/_registry:39` both say **Tests**. `work.sh:418-424` uses the same
  Tests-then-Proven-by read.
- **Positive protocol** — `ai/task-creation.md:92-97` and
  `guides/running-tests.md:42-46` document when to set **Tests** (real
  `docs/tests/*.sh` that proves the criteria) vs leave `none` (human sign-off),
  with the "never invent a hopeful path" antifragile rule.
- **Docs vs Tests one-liner** — present in `task-creation.md:92`,
  `help/promote.md:23`, `help/newtask.md:21`, `running-tests.md:40`.
- **newtask help** — `help/newtask.md:15-24` names Plan, Depends on, Dependents,
  and Tests, plus the legacy-alias note.

All eight success criteria are checked. Task 334 covers the runtime
header-stamping verification separately.

### Files changed

docs/tasks/doing/327-clarify-task-graph-headers-plan-field-and-dependen.md
