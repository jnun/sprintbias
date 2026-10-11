# Task 383: Redefine `work --max` from unlimited to a bounded high budget ceiling

**Feature**: none
**Created**: 2026-09-04
**Docs**: none
**Plan**: none
**From plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-work-budget.sh
**Refined**: 1
**Reworked**: 0

## Problem

`work --max` removes the per-task spending cap entirely, so a Claude run under
`--max` has no dollar limit. A model stuck in a loop can spend without bound,
and the interactive menu's "Full quality" options pass `--max` for every run.
The rare huge task needs more room, but still needs a ceiling.

## Done when (automated)

- [ ] `work --max` sets the per-task cap to `BUDGET_WORK_MAX` (config key,
      `100.00` in `docs/sprintbias/config`, same fallback in `lib.sh`), in
      place of clearing it. `bash docs/tests/test-work-budget.sh` asserts the
      resolved budget is `100.00` with `--max`, the config value without it,
      and a config override of `BUDGET_WORK_MAX` is honored.
- [ ] On a tier with no spending caps (Grok, generic), `--max` still adds no
      budget flag and prints nothing extra. `bash
      docs/tests/test-work-budget.sh` asserts it.
- [ ] `help/work.md` says `--max` raises the cap to `BUDGET_WORK_MAX`, and
      states the real default (`BUDGET_WORK`, $10 in config).
      `./sprint.sh validate --commands` and `./sprint.sh validate --docs`
      pass.
- [ ] `bash docs/tests/run-all.sh` passes.

## Signoff (human)

None: the automated checks cover it.

## Notes

- Decided: no uncapped path. The cap is the runaway guard; a user who needs
  more raises `BUDGET_WORK_MAX` in config.
- The change site is the `_NO_LIMITS` block in `work.sh` that sets
  `SPRINTBIAS_BUDGET_WORK=""`. The existing `--budget` pass-through carries the
  new value unchanged.
- Add `BUDGET_WORK_MAX` beside `BUDGET_WORK` in `config` and in `lib.sh`'s
  defaults block, with the same env-then-config-then-default order.
- `help/work.md` today says the default is $5; the shipped config sets
  `BUDGET_WORK=10.00`. Fix that line in the same change.
- `loop --max N` is a different flag (stop after N attempts). Leave `loop`
  alone.
- Add a `### Changed` bullet to `CHANGELOG.md`: `--max` now raises the cap to
  a ceiling instead of removing it.
- Sibling of #382, which owns what happens after a run hits its budget. This
  task owns only the value. Either can land first.

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
