# Task 387: Make polish excellence findings report dimension coverage

**Feature**: none
**Created**: 2026-09-10
**Docs**: none
**Plan**: 25
**Depends on**: 386
**Dependents**: 388
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

After a polish excellence pass, a reader cannot tell which altitude dimensions
were actually considered. Findings are freeform severity lines, so an agent can
skip Efficiency or Antifragility and still look EXCELLENT. Under-examination
hides behind a green verdict; the judge itself is not observable.

## Success criteria

- [x] An excellence report makes each finding attributable to a named altitude
      dimension (severity alone is not enough). Attribution may be a short tag
      or an inline dimension name — keep it scannable, not essay-length.
- [x] The same report shows which dimensions were considered — including
      dimensions with no finding — so "checked, nothing to file" is visible and
      distinct from "never looked."
- [x] Coverage means considered, not must-file: zero filed tasks with a full
      considered set remains a valid EXCELLENT outcome.
- [x] Primary deliverable is the excellence **report** contract in
      `audit-excellence.md`. Do not rewrite the refine `## Rework` section
      structure (#389 owns that). A light compatibility note is enough: when a
      sweep reopens, Improve items should use the same dimension *names* when
      naming gaps — not a second private vocabulary and not a competing Rework
      template.
- [x] Verdict vocabulary unchanged (excellence: EXCELLENT / FILED / BLOCKER;
      refine: PASS / REOPEN / BLOCKER).
- [ ] Runtime prompts that restate the report contract sync in #388.

## Notes

Stacks on the upgraded dimension set and refine alignment. Runtime prompts that
restate the report contract sync in 388.

Prefer a short dimension tag on each finding line (after severity), e.g.
`[ENHANCEMENT][Efficiency] …` or `[ENHANCEMENT] Efficiency — …`. Keep the
coverage signal compact — a Considered / Dimensions-checked list of every
altitude dimension named under Dimensions, including those with no finding.
Do not hardcode a closed name list that will rot; follow the live Dimensions
section after #384–#385.

## References

docs/sprintbias/ai/audit-excellence.md
docs/sprintbias/ai/refine.md
docs/sprintbias/scripts/polish-judge.sh
docs/plans/25-raise-polish-altitude-bar-could-this-be-better-exa.md

## Plan Think

**Architect:** Observability of the judge is antifragile — silent under-
examination becomes a detectable gap in the record.
**CXO:** A green EXCELLENT only earns trust when the reader can see what was
checked; coverage is the trust signal, not more filings.
**Tension:** Require dimension tags on Rework Improve items vs. keep #389's
scannable titles → resolved by ownership partition: this task owns the
excellence report; refine gets shared *names* only, not a Rework rewrite.
**Lens that drove change:** Antifragility (fail loudly on skip) + elegant
design (one owner per surface).

## Questions

**Status: READY**

### Already complete

- Verdict vocabulary in `docs/sprintbias/ai/audit-excellence.md` Report Format
  is already `EXCELLENT | FILED | BLOCKER` (and refine stays
  `PASS | REOPEN | BLOCKER`). Correct — leave unchanged.
- Ownership partition already explicit in this brief and plan 25: this task
  owns the excellence **report** contract; #389 owns `## Rework` shape; #388
  syncs runtime prompts/help that restate the contract.
- Filing discipline already settled in Severity and Routing: vital few, zero
  filings legitimate, nits stay nits — coverage must not invent work.
- `**Depends on**: 386` already recorded (386 → 385 → 384); runner will hold
  until the upgraded dimension set and refine name-alignment land.
- Live reports today (`## Excellence` → `### Findings`) are severity-only
  lines — e.g. `[ENHANCEMENT] …` with no dimension tag and no
  considered-dimensions signal (`audit-excellence.md:146-151`). That gap is
  the work, not a prior partial implementation.

### Remaining work

- Rewrite the excellence **Report Format** in `audit-excellence.md` so every
  finding line attributes a named altitude dimension (short tag after
  severity preferred; inline name acceptable). Severity alone is not enough.
- Add a compact coverage signal in that same report (e.g. Considered /
  Dimensions checked) listing every dimension from the live Dimensions
  section — including dimensions with no finding — so "checked, nothing to
  file" is visible and distinct from "never looked."
- Keep coverage = considered, not must-file: full considered set + zero
  filings remains a valid EXCELLENT outcome.
- Add only a light compatibility note (protocol prose, not a Rework rewrite):
  when a refine sweep reopens, Improve items that name a gap should use the
  same dimension *names* as excellence — no second vocabulary and no
  competing Rework template (#389 owns Rework structure).
- Do not change verdict tokens; do not edit `polish-judge.sh` / `polish.sh` /
  help here (#388 owns that sync).

### Questions for the developer

None — task is fully defined.

## Completed

Rewrote the excellence **Report Format** in `audit-excellence.md`: every finding
line now carries both a severity and a dimension tag (`[ENHANCEMENT][Efficiency]
…`), so severity alone can no longer hide which altitude lens produced a finding.
Added a `### Considered` block — one line per dimension in the live Dimensions
section, including dimensions with no finding, each marked `— clear` or with its
finding count — making the judge observable: a full list with zero findings is a
real EXCELLENT (checked, nothing to file), a missing dimension a visible gap. The
block explicitly follows the live Dimensions set rather than a hardcoded closed
list, and coverage stays *considered, not must-file* (no manufactured findings to
fill a row).

Added a light compatibility note to `refine.md`'s reopen rules: when an Improve
item names a gap, it reuses excellence's dimension words (the same Dimensions set
already judged against), so both surfaces share one vocabulary. No change to the
`## Rework` section shape (#389 owns that) and no competing template.

Verdict vocabulary is untouched (excellence: EXCELLENT / FILED / BLOCKER; refine:
PASS / REOPEN / BLOCKER). Runtime prompts / `polish-judge.sh` / help are out of
scope — #388 syncs those.

### Files changed

- docs/sprintbias/ai/audit-excellence.md
- docs/sprintbias/ai/refine.md

## Excellence

- **Date**: 2026-09-10
- **Verdict**: FILED
- **Correctness**: unverified
- **Tasks filed**: 1
- **Routing**: 0 → next/, 1 → backlog/
- **Files reviewed**: 2
- **Context source**: task ## Completed section
- **Code state**: 7156edc0055e21e3

Task 387 rewrote the excellence **Report Format** in `audit-excellence.md` so every finding line carries a `[SEVERITY][Dimension]` tag and a new `### Considered` block lists every live dimension (including those with no finding), and added a light shared-vocabulary note to `refine.md`. The change is clean, meets all of its own success criteria, and correctly resists drift by instructing the reader to follow the live Dimensions section rather than a hardcoded list — the contract itself is EXCELLENT. The one altitude gap is beyond the contract: the coverage signal the whole plan-25 stack exists to create lands only in the ephemeral run output — the durable `## Excellence` task section (`sprintbias_excellence_block`, lib.sh:2078) still persists only Verdict + Summary, so a reader of the task file later still cannot tell what was checked. Correctness state was `unverified` (no passing `## Audit` marker); I judged altitude only and stumbled on no defect — the doc change introduces no correctness bug.

### Considered
- Effectiveness — clear (report contract fully solves its scoped problem)
- Efficiency — clear (doc-only; trivial, justified context cost)
- Design fit — clear (follows live Dimensions, no hardcoded closed list, consistent style)
- Operability — 1 finding
- Robustness — clear ("follow the live Dimensions section" self-heals when Dimensions changes)
- Antifragility — clear (the contract change is itself the antifragile move: silent under-examination becomes a detectable gap)

### Findings
- [ENHANCEMENT][Operability] The `### Considered` coverage block is defined in the report contract but has no home in the durable record: `sprintbias_excellence_block` (docs/sprintbias/lib.sh:2078) has no Considered field, the emit-mode append step tells the agent to write only a "2–5 sentence Summary" (docs/sprintbias/scripts/polish-judge.sh:187-193), and the headless path preserves it only as an accidental side effect of `sprintbias_extract_summary`'s regex (docs/sprintbias/lib.sh:2252) — the two persistence paths disagree, so the coverage signal is not a trustworthy part of the record. #388 (runtime prompt sync) did not touch persistence; unowned.
- FILED → backlog/: docs/tasks/backlog/390-persist-the-excellence-considered-coverage-block-i.md (default)
