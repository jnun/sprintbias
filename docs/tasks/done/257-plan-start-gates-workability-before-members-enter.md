# Task 257: plan start gates workability before members enter the sprint

**Feature**: none
**Created**: 2026-07-29
**Docs**: docs/guides/command-matrix.md
**Depends on**: 245, 246
**Blocks**: none
**Parent**: none

## Problem

Today `plan start` only moves member tasks `backlog/ → next/`, then a separate
`define` step vets them for workability and stamps READY. That splits one
intent — "make this plan the sprint" — into two moves, and it lets unvetted
work sit in `next/` (the sprint) until someone remembers to define. The right
moment to lift quality is **before** a task becomes sprint work: when the
developer commits the plan, not as a follow-up after promotion.

## Success criteria

- [ ] Superseded by plan members **258–260** (see Notes). This file is the
      design spike / umbrella; do not implement 257 as a single runner task.

## Notes

**Split into an implementable plan** (dogfood):

| ID | Task |
|----|------|
| 258 | extract shared workability gate from define for plan start |
| 259 | plan start gates then promotes members into the sprint |
| 260 | retire define from the plan commit spine and document |

Plan: *plan start gates workability before the sprint* (create with
`newplan` listing 258 259 260). Execution order is sequential: 258 → 259 → 260.

Design locked:

- Gate **before** promote. Unready work never enters `next/`.
- Happy path: `plan start → tasks` (no define on the spine).
- `define` remains for re-gate / folder report; `--commit-only` on plan start
  for pure mv.

When the plan is started with today's `plan start`, members land in `next/`
unstamped — run `./sprint.sh gate` once manually before `work` until 259
ships.

## References

docs/guides/command-matrix.md
docs/sprintmd/scripts/plan-start.sh
docs/sprintmd/scripts/define.sh
docs/sprintmd/scripts/loop.sh
docs/tasks/backlog/258-extract-shared-workability-gate-from-define-for-pl.md
docs/tasks/backlog/259-plan-start-gates-then-promotes-members-into-the-sp.md
docs/tasks/backlog/260-retire-define-from-the-plan-commit-spine-and-docum.md

## Excellence Audit (2026-08-05)

### Summary
The design spike is fully realized by its members (258/259/260, all in
`done/`). `plan start` now gates each backlog member through the shared
`gate-lib.sh` library **before** promoting only READY work into `next/`
(`plan-start.sh:330-361`), with `--commit-only` for a pure filesystem move and
self-healing demotion of unstamped `next/` files (`plan-start.sh:228-247`). The
`define` command was retired entirely — off the spine and out of the CLI —
folded into `gate` (off-spine re-gate) and `chat <id>` (interactive
definition); the retired-name rename is documented (`command-matrix.md:270`,
`DOCUMENTATION.md:153,181`). The gate/promote logic lives in one library so
`gate`, `plan start`, `loop --refill`, folder promote, and `polish` REOPEN can
never drift. Meets the bar; nothing to file.

### Findings
- No BLOCKER, DEFECT, or ENHANCEMENT worth filing.
- [NIT] `plan-start.sh:233-235` — an unstamped `next/` member is left in
  `next/` (not demoted) when a same-named file already exists in `backlog/`.
  This is a duplicate-id state that cannot arise in normal use and is reported
  to the operator; not worth engineering against.
- Verified: src mirror parity clean for `plan-start.sh` and `gate-lib.sh`; the
  257 Notes interim workaround ("run gate manually until 259 ships") is
  resolved since 259 is in `done/`; `loop --refill` invokes `plan start` and
  relies on its gating with no separate define step (`loop.sh:224,233`).

VERDICT: EXCELLENT
