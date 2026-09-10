# Task 386: Align polish refine protocol with excellence dimensions and correctness honesty

**Feature**: none
**Created**: 2026-09-10
**Docs**: none
**Plan**: 25
**Depends on**: 385
**Dependents**: 387, 389
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

Polish has two altitude levers — deep-judge and the review/ sweep — and they
disagree. The sweep still behaves as if correctness were already established and
as if the old dimension list were the bar. Excellence already gates "presume
correct" on a real code-audit marker and (after 384–385) asks Efficiency and
Antifragility. A sweep can PASS work a deep-judge would refuse to wave through,
so false assurance is worse than a visible BLOCKER.

## Success criteria

- [ ] A developer (or agent) running the review/ sweep judges finished work
      against the same altitude dimension set as excellence, including the
      upgraded Efficiency and Antifragility meaning — preferably by depending on
      the excellence protocol as the source of truth rather than maintaining a
      second rotting copy.
- [ ] Correctness honesty matches excellence: presume correct only when a
      passing code-audit record is on the task; otherwise a stumbled-on defect
      cannot be waved through as PASS (BLOCKER, or an explicit path that sends
      the developer to `polish --code`). Mirror excellence's audited /
      unverified / failed posture language where it fits the sweep.
- [ ] Reopen discipline unchanged in spirit: reopen only for substantive,
      concrete, bounded, mechanically re-runnable gaps. Product/design forks
      stay BLOCKER for a human, not REOPEN.
- [ ] Zero reopens across a sweep remains a legitimate, common outcome.
- [ ] This task aligns dimension vocabulary and correctness honesty only — it
      does not redesign the `## Rework` kickback shape (owned by #389) and does
      not change excellence report coverage (owned by #387).
- [ ] Deliverable surface is `refine.md` (protocol). The known `polish.sh`
      runner string that still always "presumes correct" is closed in #388 so
      protocol and runtime do not race.

## Notes

Sweep still never edits product code — only rewrites the task for another
`work` pass. Known runner prompt drift that still always "presumes correct" is
closed in 388 so protocol and runtime do not race.

## References

docs/sprintbias/ai/refine.md
docs/sprintbias/ai/audit-excellence.md
docs/sprintbias/scripts/polish.sh
docs/sprintbias/help/polish.md
docs/plans/25-raise-polish-altitude-bar-could-this-be-better-exa.md

## Plan Think

**Architect:** Two altitude paths with different honesty rules are a platform
integrity bug — best practice is one correctness posture keyed off the Audit
marker.
**CXO:** A sweep PASS that waved a defect feels like betrayal; visible BLOCKER
or an explicit path to `polish --code` preserves trust.
**Tension:** Align refine now vs. also rewriting Rework shape → resolved by
partition: this task owns dimensions + honesty; #389 owns kickback scannability.
**Lens that drove change:** Best practice (DRY / single posture) + antifragility
(false assurance is worse than a visible failure signal).

## Questions

**Status: READY**

### Already complete

- Reopen discipline in `docs/sprintbias/ai/refine.md` (§ The one decision:
  reopen or not) already requires substantive + concrete/bounded + mechanically
  re-runnable gaps; product/design forks stay BLOCKER; zero reopens across a
  sweep is named as a legitimate common outcome. Looks correct — leave it.
- Sweep write boundary already settled: never edit product code; only rewrite
  the task for another `work` pass (`## Rework (round N)`). Correct and clean.
- Scope partition already explicit in this brief and plan 25: this task owns
  refine dimensions + correctness honesty only; #387 owns excellence report
  coverage; #389 owns Rework kickback scannability; #388 owns the
  `polish.sh` refine-prompt "presumed correct" string and runner/help sync.
- Excellence already has the Audit-marker correctness posture to mirror
  (`docs/sprintbias/ai/audit-excellence.md` Posture +
  `sprintbias_correctness_state` in `lib.sh`); refine has not adopted it yet.

### Remaining work

- After #385 lands the upgraded excellence Dimensions (Efficiency probes +
  Antifragility), update `refine.md` Method so the sweep judges that same
  set — prefer "as in the excellence protocol" / follow
  `audit-excellence.md` Dimensions as the source of truth, and drop the
  hardcoded five-name list that will rot again.
- Rewrite `refine.md` Posture correctness honesty to match excellence:
  presume correct only when a passing `## Audit` (PASS/FIXED) is on the
  task (`audited`); when `unverified` or `failed`, a stumbled-on defect is
  BLOCKER (or an explicit path that sends the developer to
  `polish --code`) — never waved through as PASS. Mirror audited /
  unverified / failed language where it fits the sweep (no need to invent
  an excellence-style `correctness:` stamp on refine reports).
- Do not redesign `## Rework` shape (#389), excellence report coverage
  (#387), or the `polish.sh` / help runner strings (#388).

### Questions for the developer

None — task is fully defined.
