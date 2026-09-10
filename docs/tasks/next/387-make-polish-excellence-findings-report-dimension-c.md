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

- [ ] An excellence report makes each finding attributable to a named altitude
      dimension (severity alone is not enough). Attribution may be a short tag
      or an inline dimension name — keep it scannable, not essay-length.
- [ ] The same report shows which dimensions were considered — including
      dimensions with no finding — so "checked, nothing to file" is visible and
      distinct from "never looked."
- [ ] Coverage means considered, not must-file: zero filed tasks with a full
      considered set remains a valid EXCELLENT outcome.
- [ ] Primary deliverable is the excellence **report** contract in
      `audit-excellence.md`. Do not rewrite the refine `## Rework` section
      structure (#389 owns that). A light compatibility note is enough: when a
      sweep reopens, Improve items should use the same dimension *names* when
      naming gaps — not a second private vocabulary and not a competing Rework
      template.
- [ ] Verdict vocabulary unchanged (excellence: EXCELLENT / FILED / BLOCKER;
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
