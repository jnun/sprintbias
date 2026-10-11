# Task 380: Add a shell-side observability signal when an excellence audit exceeds the warm-route cap

**Feature**: none
**Created**: 2026-08-27
**Docs**: none
**Plan**: none
**From plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-audit-excellence.sh, docs/tests/test-plan-polish.sh
**Refined**: 1
**Reworked**: 0

## Problem

An excellence audit may file at most 1 to 2 of its findings straight into
`next/`; the rest go to `backlog/`. That cap keeps `next/` trustworthy, but
only the prompt states it. When a run files 5 tasks into `next/`, the shell
prints a normal `FILED — 5 (5 → next/, ...)` line, and `plan polish` rolls it
into its summary the same way. Nobody sees that the cap was broken.

## Done when (automated)

- [ ] When one excellence run files more than the cap into `next/`,
      `polish-judge.sh` prints a warning to stderr naming the count and the
      cap. The tasks still land and the exit code is unchanged. `bash
      docs/tests/test-audit-excellence.sh` asserts the warning for a stub run
      that files 3 into `next/`, and no warning for a run that files 2.
- [ ] `plan polish` prints the same warning for each member run over the cap,
      next to its rollup line. `bash docs/tests/test-plan-polish.sh` (new)
      asserts it.
- [ ] The cap is one named value in `lib.sh` that both scripts read. `bash
      docs/tests/test-audit-excellence.sh` asserts the three prose sites
      (`ai/audit-excellence.md`, the prompt in `polish-judge.sh`,
      `help/polish.md`) state the same number as that value.
- [ ] `bash docs/tests/run-all.sh` passes.

## Signoff (human)

None: the automated checks cover it.

## Notes

- Decided: warn only. Over-cap tasks still land where the judge filed them;
  the run does not fail. Warm-routing stays the judge's call.
- Reuse the counts already computed: `NEXT_FILED` in `polish-judge.sh` (a
  before/after count of `next/`) and the per-member `**Routing**:` lines
  `plan-polish.sh` sums into `NEXT_TASKS`.
- `test-audit-excellence.sh` already drives `polish.sh` with a stub CLI. A stub
  that writes 3 task files into `docs/tasks/next/` during the run makes
  `NEXT_FILED` read 3.
- Prose today says "1–2" with an en dash; keep the cap at 2.

## References

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
