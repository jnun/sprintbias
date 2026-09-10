# Task 384: Sharpen polish excellence Efficiency probes for a could-this-be-better pass

**Feature**: none
**Created**: 2026-09-10
**Docs**: none
**Plan**: 25
**Depends on**: none
**Dependents**: 385
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

A developer running polish after work expects the excellence pass to ask whether
the landed change wastes work at real project scale. Today Efficiency in
`audit-excellence.md` is a soft one-liner agents can skim past, so a judge can
look thorough on Effectiveness while hot-path waste, unbounded growth, or
multiplicative I/O ships under a green pass. The examiner needs concrete,
positively stated probes — not a vague invitation to "think about efficiency."

## Success criteria

- [ ] A polish excellence judge following the live protocol has a short,
      positively stated Efficiency probe set (roughly a handful of checks) it
      can apply to changed work and its blast radius.
- [ ] Those probes are explicitly gated to this project's real scale — they
      surface meaningful waste, not speculative micro-optimization.
- [ ] The probe set is sufficient to catch at least these classes of gap when
      present: extra work on a hot path per request/item; unbounded growth
      without a cap; repeated work an existing shared path already covers; I/O
      or fan-out that multiplies with input size.
- [ ] Zero filed enhancement tasks remains a valid excellence outcome; sharper
      Efficiency guidance does not invent work. Efficiency nits stay nits.
- [ ] Deliverable surface is the excellence protocol's Dimensions section;
      runners and help stay out of scope for this task (synced later by #388).

## Notes

First brick in plan 25's altitude stack. Plan 24 already hardened excellence
machinery (correctness marker, warm-route, code-state idempotency); this raises
the examiner bar. `polish --code` stays out of scope (correctness only).
Protocol is the deliverable surface; runner/help sync is later in the stack.

Expand the Efficiency bullet under Dimensions in `audit-excellence.md` into a
short positively stated probe set (keep the dimension name). Leave Severity and
Routing's vital-few / zero-filings / nits language in place — do not re-home or
weaken it. Scale-gate every probe to this project's real load, not speculative
micro-optimization.

## References

docs/sprintbias/ai/audit-excellence.md
docs/sprintbias/help/polish.md
docs/plans/24-improve-polish-judging.md
docs/plans/25-raise-polish-altitude-bar-could-this-be-better-exa.md

## Plan Think

**Architect:** Concrete, scale-gated probes make Efficiency an enforceable
platform check instead of aspirational prose — best practice for judge rubrics.
**CXO:** Developers trust a green pass only when the judge clearly asked the
waste question; soft one-liners erode that trust.
**Tension:** Depth vs. inventing filings → resolved by keeping "vital few /
zero filings legitimate" and scale-gating every probe.
**Lens that drove change:** Elegant design (positive, short probe set) +
antifragility (waste classes named so silent skip is harder).

## Questions

**Status: READY**

### Already complete

- Filing discipline already lives in `docs/sprintbias/ai/audit-excellence.md`
  Severity and Routing: "File the vital few, not the trivial many. Zero filed
  tasks is a legitimate outcome"; NITs "Never file." Looks correct and clean —
  keep it when sharpening Efficiency.
- Dimensions already names **Efficiency** (lines ~70–72) with a soft one-liner
  plus a scale hint ("Flag only what matters at the scale this project actually
  runs at"). That is the right heading and the seed of the scale gate — not yet
  a probe set.
- Scope boundary already stated: runners (`polish-judge.sh`, `polish.sh`) and
  `help/polish.md` stay out of this task (#388 syncs them). Verified those
  surfaces still list the old five-dimension enum / soft quality wording; leave
  them alone here.

### Remaining work

- Replace the Efficiency one-liner in `audit-excellence.md` Dimensions with a
  short, positively stated probe set (roughly a handful) the judge applies to
  changed work and its blast radius.
- Make every probe explicitly scale-gated to this project's real load —
  meaningful waste only, not speculative micro-optimization.
- Cover at least these gap classes when present: extra work on a hot path per
  request/item; unbounded growth without a cap; repeated work an existing shared
  path already covers; I/O or fan-out that multiplies with input size.
- Preserve zero-filings-as-valid and "Efficiency nits stay nits" — do not invent
  work via sharper guidance.
- Touch only the excellence protocol Dimensions Efficiency surface; do not edit
  runners or help (deferred to #388).

### Questions for the developer

None — task is fully defined.
