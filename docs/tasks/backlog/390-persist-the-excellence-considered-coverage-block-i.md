# Task 390: Persist the excellence Considered coverage block into the durable Excellence task section

**Feature**: none
**Created**: 2026-09-10
**Docs**: none
**Plan**: none
**From plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-audit-excellence.sh
**Refined**: 1
**Reworked**: 0

## Problem

The excellence judge's report has a `### Considered` block that lists every
quality dimension it checked, so "checked, nothing found" reads differently
from "never looked". The `## Excellence` section saved into the task file has
no field for it. In emit mode the block is lost. In headless mode it survives
only by accident, as raw text inside Summary. A person reading the task file
later cannot reliably tell what the judge checked.

## Done when (automated)

- [ ] `sprintbias_excellence_block` writes a one-line `**Considered**:` field
      naming each dimension the judge listed with `clear` or its finding count,
      and an `N of M` total where M is the number of dimensions in
      `ai/audit-excellence.md`'s `## Dimensions` section. Example:
      `**Considered**: 6 of 6 — Efficiency 1 finding; others clear`.
      `bash docs/tests/test-audit-excellence.sh` asserts the field for a stub
      report.
- [ ] A headless run fills the field from the report's `### Considered` block.
      `bash docs/tests/test-audit-excellence.sh` asserts it in the task file.
- [ ] The emit-mode append step shows the same field with a placeholder the
      agent fills, so both paths write one format. `bash
      docs/tests/test-audit-excellence.sh` asserts the emit prompt contains it.
- [ ] A report with no `### Considered` block, or one missing a dimension,
      shows the gap, e.g. `**Considered**: 4 of 6 — missing: Operability,
      Antifragility`. `bash docs/tests/test-audit-excellence.sh` asserts it.
- [ ] `bash docs/tests/run-all.sh` passes.

## Signoff (human)

None: the automated checks cover it.

## Notes

- Decided: one compact line, not the full block. Summary stays as it is today;
  leave the summary extractor alone.
- Read M from the live `## Dimensions` list in `ai/audit-excellence.md` (six
  today). Hardcode no dimension names in shell.
- The report contract (`### Considered`, one line per dimension marked
  `— clear` or `— N finding(s)`) is in `ai/audit-excellence.md`'s Report
  Format. Parse that; add no second coverage mechanism.
- The emit append step in `polish-judge.sh` renders
  `sprintbias_excellence_block` with placeholders; add the new argument
  there.
- Keep the `## Excellence` field list in step with any reader that parses it
  (grep `sprintbias_excellence_block` and `**Routing**:` readers such as
  `plan-polish.sh`).

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
