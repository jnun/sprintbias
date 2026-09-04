# Task 383: Redefine `work --max` from unlimited to a bounded high budget ceiling

**Feature**: none
**Created**: 2026-09-04
**Docs**: none
**Plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

`work --max` today clears the per-task budget entirely
(`work.sh:174-176` sets `SPRINTBIAS_BUDGET_WORK=""`), i.e. **truly unlimited**
spend on a Claude run. That is the one place the runaway guard is fully removed —
a wonky model that starts burning tokens on internal monologue under `--max` has
no dollar backstop at all. The rare "this task really is huge" case wants
*headroom*, not *no ceiling*. Give `--max` a high but bounded budget so the
escape hatch keeps a backstop, consistent with the project stance that the
per-task cap IS the runaway guard.

## Success criteria

<!-- sb:hint  What done looks like. When these are met, the task is done.
     Observable checks anyone can verify. -->

- [ ] `work --max` raises the per-task cap to a **high ceiling** (default
      `$100`), sourced from a named, config-overridable key (e.g.
      `BUDGET_WORK_MAX` in `docs/sprintbias/config`, with a lib.sh default), on
      the budget-capable tier (Claude). It no longer clears the cap.
- [ ] Truly-unlimited stays reachable, but only as an explicit power-user
      override: `SPRINTBIAS_BUDGET_WORK=""` (env) still means no cap. Documented,
      not the `--max` default.
- [ ] On a capless tier (Grok / generic), `--max` remains a silent no-op on
      budget — there is no cap to raise — exactly as today. No error, no warning.
- [ ] `loop --max` is untouched: it already means "stop after N tasks" (numeric,
      `loop.sh:35`). This change does not wire `--max` budget into `loop`; a
      raised ceiling under `loop` is set via `BUDGET_WORK_MAX` / config, not a
      flag.
- [ ] Help and docs reflect the new meaning: `help/work.md` (currently
      "`--max`  # clear the budget cap") now says it raises the cap to the
      ceiling; command/doc surfaces stay in sync
      (`./sprint.sh validate --commands` / `--docs`).

## Notes

<!-- sb:hint  Constraints, edge cases, gotchas. -->

- Minimal change site: `work.sh:174-176` currently does
  `if [ "$_NO_LIMITS" -eq 1 ]; then SPRINTBIAS_BUDGET_WORK=""; fi`. Replace the
  clear with a raise to `BUDGET_WORK_MAX` (fall back to a literal `100.00` if the
  key is unset), so the existing `_budget_args`/`sprintbias_budget_capable` path
  at `work.sh:874-876` carries it unchanged.
- Config + default live beside the existing ones: `BUDGET_WORK=10.00` in
  `docs/sprintbias/config`, defaulted in `lib.sh` (~L2400). Add
  `BUDGET_WORK_MAX=100.00` the same way.
- Behavior note for the interactive menu: options 3 & 4 ("Full quality",
  `work.sh:108-109`) pass `--max`. Under this change those full-quality runs get
  the `$100` ceiling instead of unlimited — a safer default, and fine.
- Sibling of task 382 (which owns the budget *disposition* — routing a
  budget-exhausted run to `blocked/`). This task owns only the budget *value* of
  `--max`. They touch adjacent code but are independent and either can ship
  first.

## References

<!-- sb:hint  Direct paths to docs or files known to be related. One path per line. -->

docs/sprintbias/scripts/work.sh
docs/sprintbias/scripts/loop.sh
docs/sprintbias/config
docs/sprintbias/lib.sh
docs/sprintbias/help/work.md

<!-- sb:hint  After work only — audit trail. Copy the two headings below to
     column 0 (UNINDENTED), then list the product files you edited:

       ## Completed

       ### Files changed
       docs/sprintbias/scripts/work.sh
       docs/sprintbias/help/work.md

     Keep the wording exact — `## Completed` and `### Files changed`. Do not fill
     before work. -->

<!-- sb:hint
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->
