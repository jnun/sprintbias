# Task 429: Plan start, promote, polish and the gate end every message in an action

**Feature**: none
**Created**: 2026-10-10
**Docs**: none
**Plan**: 32
**From plan**: none
**Depends on**: 425, 428
**Dependents**: 432
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-next-action.sh, docs/tests/test-plan-lifecycle.sh, docs/tests/test-promote.sh
**Refined**: 0
**Reworked**: 0

## Problem

Several end-of-run and gate messages report state and stop. `plan start` refuses the whole plan when one member sits in blocked/, and its summary counts blocked, held and error members without commands; its human-test line names no command. `promote` ends on a counts line after an all-green run, an empty review/, an outside hold, or `--audit --move`. `polish` ends on counts when nothing reopened, prints "BLOCKER — needs a human" with no command, and code mode's PASS and warnings lines end without one. The gate prints settled conflicts with no way to change them, and `sprintbias_promote_summary`'s BLOCKED line names no command.

- Decided: `plan start` gates blocked/ members along with backlog members instead of stopping, because the gate takes suggested answers; a member that still cannot start stays in blocked/ and the rest of the plan runs.

## Done when (automated)

- [x] A new `docs/tests/test-next-action.sh` covers each message below and passes; `bash docs/tests/run-all.sh` stays green
- [x] plan start gates blocked/ members with the others; each member still BLOCKED is listed with `./sprint.sh chat <id>`; held and error lines name a command; the human-test line names `./sprint.sh promote plan:<id>`; the last line stays `Next: ./sprint.sh work` (`bash docs/tests/test-plan-lifecycle.sh`, `bash docs/tests/test-next-action.sh`)
- [x] promote ends every run with a `./sprint.sh` command line: empty review/, all green, held, audit with and without `--move` (`bash docs/tests/test-next-action.sh`)
- [x] polish's final summary always ends with a next command; a BLOCKER line names `./sprint.sh polish --code <file>` or `./sprint.sh chat <id>`; code mode's PASS names `./sprint.sh promote` (`bash docs/tests/test-next-action.sh`)
- [x] The gate's conflict print ends with `Disagree? → ./sprint.sh newtask "<the change you want>"` in exec output and in the emit instruction; `sprintbias_promote_summary`'s BLOCKED line names `./sprint.sh chat <id>` (`bash docs/tests/test-next-action.sh`)

- [x] `./sprint.sh validate --docs` passes, and `help/plan.md` and `DOCUMENTATION.md` describe plan start gating blocked/ members instead of stopping

## Signoff (human)

Checked in the plan's one human test, #434.

## Notes

- Decided: `--commit-only` leaves blocked/ members where they are and lists each with `./sprint.sh chat <id>`, because that mode skips the gate and must not push unvetted work into next/.
- Decided: emit mode includes blocked/ members in the review prompts it prints, because the gate treats them the same as backlog members.
- Decided: a promote run whose last line is already a `./sprint.sh` command keeps it; only runs that end on counts gain one, because the goal is one next action per run, not a second line.

## References

docs/sprintbias/scripts/plan-start.sh
docs/sprintbias/scripts/promote.sh
docs/sprintbias/scripts/polish.sh
docs/sprintbias/scripts/gate-lib.sh
docs/tests/test-plan-lifecycle.sh
docs/tests/test-promote.sh
docs/sprintbias/help/plan.md

## Grounding

**Sources:** `CLAUDE.md` (guiding principles; human-owned actions), `CONTRIBUTING.md` (surfaces kept in step), `DOCUMENTATION.md` (lifecycle folders, blocked vs dependent), `docs/sprintbias/help/plan.md` (plan start behavior), `docs/guides/command-matrix.md` (command surfaces)
**Terms:**
- None.
**Conflicts:**
- `help/plan.md` lines 45 and 59 say a blocked/ member stops plan start; this task changes that → update help/plan.md (and any DOCUMENTATION.md line) in the same change.
- `plan-start.sh` lines 330-339 exit 1 on any blocked/ member → replace with gating them alongside backlog members, per the Decided line in Problem.
- **Tests** names `docs/tests/test-next-action.sh`, which does not exist yet → this task creates it.
- Task 427 retires `settle`; the new command lines name `chat`, `promote`, `polish --code` and `newtask` only, so they stay valid after 427.

## Questions

**Status: READY**

### Already complete
None — no matching implementation found.
- `plan-start.sh:330-339` still stops the whole start on a blocked/ member; the summary at line 575 prints counts with no commands; the human-test line names no command.
- `gate-lib.sh:508-512` prints Grounding conflicts with no `Disagree?` line; `sprintbias_promote_summary` (`gate-lib.sh:577`) BLOCKED line has no `chat <id>`.
- `polish.sh:1205-1208` BLOCKER prints "needs a human" with no command.
- `docs/tests/test-next-action.sh` does not exist.

### Remaining work
- plan start: gate blocked/ members with backlog members; list still-BLOCKED members with `./sprint.sh chat <id>`; command lines for held and error members; human-test line names `./sprint.sh promote plan:<id>`; keep `Next: ./sprint.sh work` last.
- promote: every exit path (empty review/, all green, held, `--audit` with and without `--move`) ends on a `./sprint.sh` command.
- polish: final summary ends with a next command; BLOCKER names `polish --code <file>` or `chat <id>`; code-mode PASS names `./sprint.sh promote`.
- gate: conflict print (exec and emit instruction) ends with the `Disagree?` newtask line; promote_summary BLOCKED names `chat <id>`.
- Add `docs/tests/test-next-action.sh`; update help/plan.md, DOCUMENTATION.md, CHANGELOG `## Unreleased`.

### Questions for the developer
None — task is fully defined.

## Test log

- `bash docs/tests/test-next-action.sh` (new) — "plan start: human test names promote plan:N" failed: the sandbox board had no `docs/tasks/.TEMPLATE-task.md`, so `create-task.sh` could not make the human test → test setup fixed (the board copies the template, as an install has it); plan-start.sh was right.

## Completed

- plan start: blocked/ members are gated with the backlog members (the gate leaves a BLOCKED member in place instead of a same-path move); `--commit-only` leaves them in blocked/; the summary lists each member that cannot start with `./sprint.sh chat <id>`, gate errors with `./sprint.sh plan start <id>`, holds with `./sprint.sh chat plan <id>`, and the human test with `./sprint.sh promote plan:<id>`. help/plan.md describes it.
- promote: empty review/ → `./sprint.sh work`; missing id → `./sprint.sh search <id>`; all green → `Next: ./sprint.sh status`; dry run → the real command; plan-mode holds and human-test failures name `./sprint.sh promote plan:<id>`; audit names a reject line per NOT-DONE task, a re-judge line for unclear ones, and status after `--move`; the emit audit prompt asks for the same.
- polish: the final summary always ends in `./sprint.sh work` or `./sprint.sh promote`; a BLOCKER prints both commands (`polish --code <file>` for a defect, `chat <id>` for a missed goal); code-mode PASS names `./sprint.sh promote <id>`, warnings and no-start name the re-run; empty and capped sweeps name their command; the emit report asks for the same.
- gate: the conflict print (exec and emit) ends with `Disagree? → ./sprint.sh newtask "<the change you want>"`; `sprintbias_promote_summary` BLOCKED names `./sprint.sh chat <id>`, NOSTAMP names `./sprint.sh work <id>`.

### Assumptions
- Decided: after an all-green promote the next command is `./sprint.sh status`, because commit is the person's and status shows what is left to build or sign off.
- Decided: a polish BLOCKER prints both possible commands, because the shell cannot tell which kind of blocker the judge meant and its reason is in the log beside them.

### Files changed
docs/sprintbias/scripts/plan-start.sh
docs/sprintbias/scripts/promote.sh
docs/sprintbias/scripts/polish.sh
docs/sprintbias/scripts/gate-lib.sh
docs/sprintbias/help/plan.md
CHANGELOG.md
docs/tests/test-next-action.sh

**Proof**: 2026-10-10 · bash docs/tests/test-next-action.sh, bash docs/tests/test-plan-lifecycle.sh, bash docs/tests/test-promote.sh, bash docs/tests/test-audit-code.sh, bash docs/tests/test-audit-excellence.sh · pass

## Plan Think

FINISHED (review/). plan start gates blocked/ members, and every promote, polish and gate exit names a command. Architect: one blocked member no longer stops the whole plan, which removes a single point of failure (the antifragility lens). Experience: every run ends in an action. Tension: `status` still prints "Blocked (needs decision or clarification)" (sprint.sh:226). That message was outside this task's list, so delta #436 covers it. Left as-is.
