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

- [x] A polish excellence judge following the live protocol has a short,
      positively stated Efficiency probe set (roughly a handful of checks) it
      can apply to changed work and its blast radius.
- [x] Those probes are explicitly gated to this project's real scale — they
      surface meaningful waste, not speculative micro-optimization.
- [x] The probe set is sufficient to catch at least these classes of gap when
      present: extra work on a hot path per request/item; unbounded growth
      without a cap; repeated work an existing shared path already covers; I/O
      or fan-out that multiplies with input size.
- [x] Zero filed enhancement tasks remains a valid excellence outcome; sharper
      Efficiency guidance does not invent work. Efficiency nits stay nits.
- [x] Deliverable surface is the excellence protocol's Dimensions section;
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

## Completed

Expanded the **Efficiency** dimension under Dimensions in
`docs/sprintbias/ai/audit-excellence.md` from a soft one-liner into a short,
positively stated probe set the excellence judge applies to changed work and
its blast radius. Four scale-gated probes, each framed as the good shape to
confirm rather than a defect to hunt:

- **Hot path stays lean** — catches extra per-request/per-item work.
- **Growth is capped** — catches unbounded accumulation.
- **Shared work is reused** — catches recompute/re-fetch an existing shared
  path already covers.
- **I/O and fan-out stay sub-linear where they can** — catches reads/writes/
  calls that multiply with input size.

Each probe is explicitly gated to "the scale this project actually runs at —
a real cost at real load, never a speculative micro-optimization." Closed the
set by preserving filing discipline: "these probes surface meaningful waste;
they do not manufacture it. An Efficiency nit stays a nit, and zero filings
remains a valid outcome (see Severity and Routing)." The dimension name is
unchanged, and Severity/Routing's vital-few / zero-filings / nits language is
left in place. Runners and `help/polish.md` untouched — deferred to #388.

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

Task 384 expanded the **Efficiency** dimension in `audit-excellence.md` from a soft one-liner into four positively stated, scale-gated probes (hot path lean, growth capped, shared work reused, I/O/fan-out sub-linear). It meets the altitude bar: the probes cover every gap class the task named, each is explicitly gated to real load, and the set closes by preserving filing discipline so sharper guidance can't manufacture work. The change stayed inside its scope boundary — the runner (`polish-judge.sh:219`) and `help/polish.md:79` already reference the scale-gated probes and antifragility, so the deferred #388 sync landed and the end-to-end path is coherent.

Correctness state: **unverified** (no `## Audit` marker). I found no genuine defect and nothing that rises to an enhancement a senior engineer would act on.

### Considered
- Effectiveness — clear
- Efficiency — clear
- Design fit — clear
- Operability — clear
- Robustness — clear
- Antifragility — clear

### Findings
- [NIT][Effectiveness] `audit-excellence.md:85` — "a pass per pass is the shape to catch" reads oddly as an anti-pattern example (likely "a pass per item"); the first two examples still carry the meaning. Mentioned only, not filed.

No tasks filed — zero filings is the honest outcome here.
