# Task 389: Make polish ## Rework notes scannable for humans and executors

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

When polish reopens a task into `next/`, the `## Rework` section is the brief
for the human skimming the kickback and for the next executor. Today that brief
is easy to bury: Improve items mix rationale, step-by-step edit recipes, and
long evidence into one checkbox line, and a parallel "remaining work" block
often restates the same list. A reader cannot answer "what are the N things?"
in a glance. Line-specific edit prescriptions (`path:line`, "change field 4")
are especially brittle — they are often poor assumptions by the time `work`
runs again.

## Success criteria

- [x] A human can skim a REOPEN kickback's `## Rework` in about a minute and
      list every remaining gap by short name without reading an essay.
- [x] Each Improve item is an outcome the next executor can verify: a short
      title plus a one-line done-look (user-story or technical-spec height —
      what must be true when the item is done), not a micromanaged edit recipe.
- [x] Improve items do not prescribe brittle line-specific edits (no required
      `path:line` surgery, no "change field N" as the work itself). File paths
      and anchors may appear only as optional starting-point hints beneath the
      done-look, never as the definition of done.
- [x] Why stays a short case for spending another pass (a few sentences), not a
      second copy of the Improve list.
- [x] Improve is the single remaining-work list on the task — no parallel
      duplicate checklist under Questions or elsewhere that restates the same
      items.
- [x] Titles may use the shared excellence dimension names when naming a gap
      (efficiency, antifragility, …) so vocabulary stays one language with #387
      — without inventing a second tag scheme that fights skim.
- [x] Reopen discipline unchanged: vital few, substantive, bounded, mechanical
      to re-run; clearer organization does not invite more items.
- [x] Primary deliverable is the `## Rework` contract in `refine.md` (this task
      owns that section's shape). Excellence report coverage stays #387's;
      runtime teaching of this kickback shape lands in #388.

## Completed

Rewrote the `## When you reopen` contract in `docs/sprintbias/ai/refine.md`.
The Improve-item template now mandates a two-part shape — a **bold short
title** (scannable name of the gap) plus a **one-line done-look** (verifiable
outcome at user-story / technical-spec height) — with an optional indented
`Hint:` line for file paths, anchors, and search terms as starting points only.
Added explicit rules that outlaw brittle `path:line`/"change field N" edits as
the definition of done, keep **Why** as a short case for another pass (not a
re-listing of Improve), name Improve as the single remaining-work list (no
duplicate checklist under Questions or elsewhere), and allow shared excellence
dimension names in titles without a second tag scheme. Reopen discipline is
restated as unchanged — clearer organization is not a license for more items.

### Files changed

- docs/sprintbias/ai/refine.md

## Notes

Dogfood signal: a real polish REOPEN had the right five gaps, but each Improve
line was a paragraph of mixed action/rationale/anchors, and Questions carried a
duplicate remaining-work essay. Desired reader experience:

- Skim titles → know the gaps
- Read one-line done-look → know done
- Optionally use indented hints → find evidence faster
- Never treat a line number as the spec

Example shape (illustrative only — implementer owns exact markdown):

    ## Rework (round 1)

    **Why:** Survey is strong; two owned people-words still have no home.

    **Improve:**
    - [ ] **Company Admin entry** — A complete lexicon entry for Company Admin
          exists under the cluster schema; bare "Admin" is absorbed there;
          summary counts match the entry set.
          Hint: seed slug `company_admin`, company-settings role picker,
          permissions docs.
    - [ ] **Permission admits Owner/self** — The Permission entry records that
          admission can be scope/ownership-based (`resource.action` with scope),
          not role-grid alone.
          Hint: RBAC Scope / owner-hybrid / self-service declarations.

Stacks after 386. Capstone sync (388) should teach this Rework contract at
runtime so judges cannot fall back to essay checkboxes.

## References

docs/sprintbias/ai/refine.md
docs/sprintbias/help/polish.md
docs/sprintbias/ai/task-creation.md
docs/plans/25-raise-polish-altitude-bar-could-this-be-better-exa.md

## Plan Think

**Architect:** Outcome-style Improve items are antifragile under re-execution —
line recipes rot; done-looks survive. Owning Rework shape here keeps #387 off
the same section.
**CXO:** Kickback skim-time is the human experience of polish; essay checkboxes
destroy perceived clarity even when the gaps are right.
**Tension:** Dimension attribution vs. scannable titles → titles may use shared
dimension names; no rigid second tag scheme.
**Lens that drove change:** Elegant design / CXO clarity (title + done-look) +
antifragility (no brittle path:line specs).

## Questions

**Status: READY**

### Already complete

- Reopen discipline in `docs/sprintbias/ai/refine.md` (§ The one decision:
  reopen or not) already requires substantive + concrete/bounded + mechanically
  re-runnable gaps, and treats zero reopens as a legitimate outcome. Looks
  correct — leave it; this task does not loosen or expand that bar.
- Mechanical reopen scaffolding already exists under § When you reopen: exact
  `## Rework (round N)` heading, Why + Improve checklist, unchecked `- [ ]`
  items, and leave Success criteria / `## Completed` / `**Status: READY**`
  untouched. Correct and clean as scaffolding — the *content shape* of Improve
  items is what this task upgrades.
- Scope partition already settled in this brief and plan 25: this task owns the
  `## Rework` contract in `refine.md`; #387 owns excellence report coverage;
  #388 teaches the kickback shape at runtime (`polish.sh` / help). Do not steal
  those surfaces.

### Remaining work

- Rewrite `refine.md` § When you reopen so each Improve item is a short **title**
  plus a one-line done-look (user-story or technical-spec height — what must be
  true when done), scannable in about a minute for the full list of gaps.
- Require that Improve items define outcomes, not brittle edit recipes: no
  required `path:line` surgery or "change field N" as the work itself; file
  paths / anchors only as optional indented starting-point hints under the
  done-look.
- Keep **Why** as a short case for another pass (a few sentences) — not a second
  copy of the Improve list.
- State that Improve is the single remaining-work list on the reopened task —
  no parallel duplicate checklist under Questions or elsewhere restating the
  same items.
- Allow Improve titles to use shared excellence dimension names when naming a
  gap (efficiency, antifragility, …) so vocabulary stays one language with
  #387 — without inventing a second tag scheme.
- Leave reopen discipline, excellence report coverage (#387), and runtime/help
  teaching (#388) alone; Notes' illustrative shape is guidance, not a mandatory
  template.

### Questions for the developer

None — task is fully defined.

## Excellence

- **Date**: 2026-09-10
- **Verdict**: EXCELLENT
- **Correctness**: unverified
- **Tasks filed**: 0
- **Routing**: —
- **Files reviewed**: 1
- **Context source**: task ## Completed section
- **Code state**: 19d75169b1b64608

Task 389 rewrites the `## When you reopen` contract in `refine.md` so a REOPEN's `## Rework` section is scannable: each Improve item is a bold short title plus a one-line verifiable done-look, with optional Hints that never define done, brittle line-surgery outlawed, and Improve named as the single remaining-work list. The work meets its bar — every Success criterion is satisfied, and the shape is consistently reinforced in the runtime prompt (`polish.sh`) and help (`polish.md`) that #388 owns. The most notable altitude observation is a minor context-cost one: the teaching section triple-states a couple of rules ("hint never defines done," "outcomes not edit recipes") — but repetition in an LLM-guidance file is a deliberate adherence technique here, so it stays a nit, not a filing.

### Considered
- Effectiveness — clear (all Success criteria met; judge has contract + runtime + help all teaching the shape)
- Efficiency — clear (1 nit below; hot-path context cost, but intentional prompt repetition)
- Design fit — clear (contract/runtime/help in sync; reuses shared dimension vocabulary; defers to #387/#388 cleanly)
- Operability — clear
- Robustness — clear (`## Refine` vs `## Rework` and `Status: READY`/`Reworked` counter boundaries preserved)
- Antifragility — clear (done-looks survive re-execution where line recipes rot — the explicit goal, delivered)

### Findings
- [NIT][Efficiency] `refine.md:100-132` — "hint never defines done" and "outcomes not edit recipes" each appear across the template, the parts bullets, and the rules bullets; a prune could tighten the loaded-every-run section, but the repetition plausibly aids model adherence, so not filed.

No tasks filed — the work clears the bar and the only observation is a sentence-worthy nit.
