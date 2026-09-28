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

- [x] A developer (or agent) running the review/ sweep judges finished work
      against the same altitude dimension set as excellence, including the
      upgraded Efficiency and Antifragility meaning — preferably by depending on
      the excellence protocol as the source of truth rather than maintaining a
      second rotting copy.
- [x] Correctness honesty matches excellence: presume correct only when a
      passing code-audit record is on the task; otherwise a stumbled-on defect
      cannot be waved through as PASS (BLOCKER, or an explicit path that sends
      the developer to `polish --code`). Mirror excellence's audited /
      unverified / failed posture language where it fits the sweep.
- [x] Reopen discipline unchanged in spirit: reopen only for substantive,
      concrete, bounded, mechanically re-runnable gaps. Product/design forks
      stay BLOCKER for a human, not REOPEN.
- [x] Zero reopens across a sweep remains a legitimate, common outcome.
- [x] This task aligns dimension vocabulary and correctness honesty only — it
      does not redesign the `## Rework` kickback shape (owned by #389) and does
      not change excellence report coverage (owned by #387).
- [x] Deliverable surface is `refine.md` (protocol). The known `polish.sh`
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

## Completed

Aligned `refine.md` (the review/ sweep protocol) with the excellence audit on
the two axes this task owns:

- **Dimensions (Method step 4)** now point to
  `docs/sprintbias/ai/audit-excellence.md` → Dimensions as the single source of
  truth (Effectiveness; Efficiency with its scale-gated probe set; Design fit;
  Operability; Robustness; Antifragility), replacing the hardcoded five-name
  list that would rot as excellence's set moves.
- **Posture correctness honesty** now mirrors excellence's `audited` /
  `unverified` / `failed` states off the task's `## Audit` marker. Presume
  correct only when a `## Audit` records PASS/FIXED; when `unverified` or
  `failed`, a stumbled-on defect cannot be waved through as PASS — the verdict
  falls to BLOCKER with a reason routing the developer to
  `./sprint.sh polish --code`. The BLOCKER routing line reflects the same path.

Reopen discipline, the sweep's never-edit-product-code boundary, the `## Rework`
shape (#389), excellence report coverage (#387), and the `polish.sh`/help runner
strings (#388) were left untouched, per the scope partition.

### Files changed

docs/sprintbias/ai/refine.md

## Excellence

- **Date**: 2026-09-10
- **Verdict**: EXCELLENT
- **Correctness**: unverified
- **Tasks filed**: 0
- **Routing**: —
- **Files reviewed**: 1
- **Context source**: task ## Completed section
- **Code state**: 19d75169b1b64608

Task 386 aligns the review/ sweep protocol (`refine.md`) with the excellence audit on the two axes it owns: correctness honesty and dimension vocabulary. The Posture now mirrors excellence's `audited`/`unverified`/`failed` states read off the task's `## Audit` marker (a stumbled defect on unverified/failed work falls to BLOCKER routing to `polish --code`, never a silent PASS), and Method step 4 drops the hardcoded five-name dimension list to defer to `audit-excellence.md` → Dimensions as the single source of truth. The work meets its bar cleanly: the runner (`polish.sh` `_refine_prompt`, lines 950-956) already builds the matching Audit-gated `correctness_rule`, so protocol and runtime do not race, and the same-diff `## Rework`-shape rewrite belongs to sibling task 389 (both edit `refine.md`; all of plan 25 is uncommitted together), not a scope violation by 386. Correctness is unverified — I found no defect.

### Considered
- Effectiveness — clear (both owned axes met; dimensions + honesty aligned end-to-end with the runner)
- Efficiency — clear (per-judge extra read of `audit-excellence.md` is the deliberate DRY tradeoff the task chartered; bounded, not real-load waste)
- Design fit — clear (reuses `sprintbias_correctness_state` + `## Audit` marker; SSOT pointer matches the polish family's protocol-embed pattern)
- Operability — clear (verdict + reason surface the correctness state; runner logs it)
- Robustness — clear (three documented Audit states covered; edge classification lives in `lib.sh`, unchanged)
- Antifragility — clear (this is the antifragile win: removes false-assurance sweep PASS on unverified work; kills the second rotting dimension copy)

### Findings
- None filed. One NIT (not filed, not on 386's surface): the sweep inlines only `refine.md`, so its judge must chase a cross-file pointer to `audit-excellence.md` for the Dimensions, whereas the deep-judge gets them inline. Re-inlining would reintroduce the rotting-copy problem 386 was chartered to remove, and 388 added stub coverage asserting the sweep prompt teaches the contracts — so this is a `polish.sh` runner consideration, speculative, and correctly left alone.
