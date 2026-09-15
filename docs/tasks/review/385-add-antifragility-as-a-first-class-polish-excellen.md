# Task 385: Add Antifragility as a first-class polish excellence dimension

**Feature**: none
**Created**: 2026-09-10
**Docs**: none
**Plan**: 25
**Depends on**: 384
**Dependents**: 386
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

When a plan is thought through `plan think` / `chat`, antifragility is already a
first-class lens: stronger under stress, graceful degradation, early failure
signals, fewer single points of fragility. After `work`, polish excellence only
asks Robustness (survive edges). Finished code never faces the same stress
question the plan did, so fragility can ship behind a green excellence pass —
the spine teaches one altitude and audits another.

## Success criteria

- [x] A polish excellence judge treats Antifragility as a first-class dimension
      of the "could this be better?" bar, with the same meaning as plan/chat:
      the change should make the system stronger under stress, load, and change
      — not merely survive edges.
- [x] Graceful degradation, early failure visibility, and removal of single
      points of fragility introduced or left by the change are in scope for
      that dimension.
- [x] Existing Robustness edge coverage (empty input, concurrency, partial
      failure, retry at realistic project edges) still exists — antifragility
      adds altitude; it does not replace edge survival.
- [x] Plan/chat and polish share vocabulary enough that an agent reading either
      surface recognizes the same antifragility idea (a short bridge is enough;
      do not paste the whole plan-think essay into excellence).
- [x] Prefer a distinct Antifragility dimension bullet; a named combined
      expansion of Robustness is acceptable only if both the survive-edges bar
      and the stronger-under-stress bar stay explicit and separately auditable.
- [x] Filing discipline unchanged: vital few only; antifragility nits are nits;
      zero filings remains legitimate.
- [x] Deliverable surface is the excellence protocol Dimensions section (after
      #384's Efficiency probes); runners and help sync later (#388).

## Notes

Stacks on 384 so Efficiency and Antifragility land as one coherent dimension
set. Prefer a distinct dimension; a named combined expansion is fine only if
both bars stay explicit. Runners and help sync later (388).

## References

docs/sprintbias/ai/audit-excellence.md
docs/sprintbias/scripts/plan-think.sh
docs/sprintbias/ai/conversation.md
docs/sprintbias/help/plan.md
docs/plans/25-raise-polish-altitude-bar-could-this-be-better-exa.md

## Plan Think

**Architect:** Closing the plan/chat vs polish vocabulary gap removes a single
point of fragility in the quality spine — the audit must ask what the plan
asked.
**CXO:** Users (and developers reading polish output) should see one altitude
language end to end; a green pass that never asked "stronger under stress?"
is a trust failure.
**Tension:** Distinct dimension vs. bloating the list → prefer distinct;
combined expansion only if both bars stay explicit.
**Lens that drove change:** Antifragility (first-class) + elegant design
(extend Dimensions, do not fork a parallel rubric).

## Questions

**Status: READY**

### Already complete

- Filing discipline already in `docs/sprintbias/ai/audit-excellence.md`
  Severity and Routing: vital few only, nits never filed, zero filings
  legitimate. Looks correct — leave it when adding Antifragility.
- **Robustness** already covers edge survival (empty input, concurrency,
  partial failure, retry at realistic project edges). Correct and clean —
  keep it; Antifragility adds altitude above it.
- Plan/chat source vocabulary already exists in
  `docs/sprintbias/scripts/plan-think.sh` (lens 3: stronger under stress,
  graceful degradation, early failure signals, fewer single points of
  fragility). That is the bridge target, not yet mirrored in excellence.
- Scope boundary already settled: deliverable is the Dimensions section;
  runners (`polish-judge.sh`, refine prompt) and help still enumerate the
  five old names — leave those for #388.

### Remaining work

- After #384's Efficiency probes land, add a distinct **Antifragility**
  dimension bullet under Dimensions in `audit-excellence.md`.
- Phrase it with the same meaning as plan think: the change should make the
  system stronger under stress, load, and change — graceful degradation,
  early failure visibility, and removal of single points of fragility
  introduced or left by the change are in scope.
- Keep Robustness edge coverage intact and separately auditable; do not fold
  antifragility into Robustness unless both bars stay explicit (prefer
  distinct).
- Keep the bridge short — shared vocabulary with plan/chat, not a paste of
  the plan-think essay.
- Do not touch runners or help here (#388).

### Questions for the developer

None — task is fully defined.

## Completed

Added a distinct **Antifragility** dimension bullet to the Excellence Audit
Protocol Dimensions section, immediately after Robustness and after #384's
Efficiency probes. It mirrors `plan think` / `chat` lens 3 (stronger under
stress, load, and change) with a short bridge, keeps Robustness edge coverage
intact and separately auditable, and explicitly frames antifragility as
altitude above edge survival rather than a replacement. Graceful degradation,
early failure visibility, and removal of single points of fragility introduced
or left by the change are named in scope. Filing discipline and runners/help
were left untouched (runners/help sync is #388).

### Files changed

- docs/sprintbias/ai/audit-excellence.md

## Excellence

- **Date**: 2026-09-10
- **Verdict**: EXCELLENT
- **Correctness**: unverified
- **Tasks filed**: 0
- **Routing**: —
- **Files reviewed**: 1
- **Context source**: task ## Completed section
- **Code state**: 3a1bf4f9baeb07de

Task #385 adds a first-class **Antifragility** dimension to the Excellence Audit Protocol's Dimensions section, immediately after Robustness. It meets the bar: a distinct, separately-auditable dimension that mirrors the `plan think` / `chat` stress lens with a short bridge (not a paste), leaves Robustness edge-survival intact, and is wired consistently across every consuming surface (judge runner, refine, help). Correctness is `unverified` (no code audit on record), but this is a prose/protocol change and I found no defect. The most important observation is a positive one: the change closes the single-point-of-fragility it was written to close — the audit now asks the stress question the plan asked.

### Considered
- Effectiveness — clear
- Efficiency — clear
- Design fit — clear
- Operability — clear
- Robustness — clear
- Antifragility — clear

### Findings
- None filed.
