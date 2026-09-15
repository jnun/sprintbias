# Task 390: Persist the excellence Considered coverage block into the durable Excellence task section

**Feature**: none
**Created**: 2026-09-10
**Docs**: none
**Plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

Task 387 added a `### Considered` coverage block to the excellence report
contract so a reader can tell which altitude dimensions were actually examined —
the plan's whole observability thesis. But that signal only lives in the
ephemeral run output. The durable `## Excellence` section written to the task
file carries Verdict + Summary and no coverage block, so a reader returning to
the task file weeks later still cannot tell what was checked — exactly the
problem #387 set out to solve, just relocated from the report to the record.

## Why

- The durable-record appender has no home for the coverage signal:
  `sprintbias_excellence_block` (docs/sprintbias/lib.sh:2078) emits Date,
  Verdict, Correctness, Tasks filed, Routing, Files reviewed, Context source,
  Code state, then a single Summary body — no Considered field.
- The two persistence paths disagree on whether coverage survives. The emit-mode
  append step instructs the agent to write only a "2–5 sentence Summary"
  (docs/sprintbias/scripts/polish-judge.sh:187-193), dropping the block. The
  headless path extracts the Summary with a regex that grabs everything between
  `## Summary` and `VERDICT:` (`sprintbias_extract_summary`,
  docs/sprintbias/lib.sh:2252), so Considered + Findings survive there only as an
  accidental side effect. A coverage signal that lands in the record on one path
  and vanishes on the other is not a trustworthy record.
- Plan 25's stated case (task 387 Plan Think) is that observability of the judge
  is antifragile: silent under-examination becomes a detectable gap. That
  guarantee is only realized for the durable record if the record carries it.

## Success criteria

- [ ] The durable `## Excellence` section written to a task file carries the
      dimension-coverage signal (which dimensions were considered, distinct from
      which produced findings), not just Verdict + Summary — so a reader of the
      task file alone can tell what was checked.
- [ ] Both persistence paths agree: emit-mode append and the headless extractor
      produce the same coverage record for the same run — no path silently drops
      it and no path captures it only by accident.
- [ ] The coverage field follows the live Dimensions set (no hardcoded closed
      list that rots when Dimensions changes), consistent with #387's contract.
- [ ] No product code is edited by the judge; this adds record fidelity, not a
      new gate. Decide and document how much of the block to persist (full
      Considered list vs. a compact one-line coverage summary).

## Notes

- Coordinate with the runtime-prompt surface #388 syncs and the report contract
  #387 owns — this task is the persistence layer neither of them touched. Reuse
  the coverage the judge already emits; do not add a second coverage mechanism.
- Confirm the full-block-vs-compact-summary decision before building.

## References

docs/sprintbias/ai/audit-excellence.md
docs/sprintbias/lib.sh
docs/sprintbias/scripts/polish-judge.sh
docs/tasks/review/387-make-polish-excellence-findings-report-dimension-c.md

<!-- sb:hint  Direct paths to docs or files known to be related. One path per
     line. Leave empty if none. -->

<!-- sb:hint  After work only — audit trail of what was touched. Helps committers,
     later audits, and "what broke?" recovery. List the product files you
     edited to complete the task — one repo-relative path per line. Leave this
     task file out: its folder location and git history already track it. Copy
     the two headings below to column 0
     (UNINDENTED — they are indented here only so a fresh, unworked task is not
     mistaken for a finished one), then list the paths under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintbias/scripts/example.sh
       docs/sprintbias/help/example.md

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. Do not fill this before work. -->

<!-- sb:hint
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->
