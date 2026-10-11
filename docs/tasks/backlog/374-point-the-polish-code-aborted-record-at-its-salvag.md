# Task 374: Point the polish --code aborted record at its salvage/step log for a debug trail

**Feature**: none
**Created**: 2026-08-21
**Docs**: none
**Plan**: none
**From plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-audit-code.sh
**Refined**: 1
**Reworked**: 0

## Problem

When `polish --code` aborts and salvages its landed edits, the record it leaves
points at no log. The `## Audit (aborted ...)` note in the task and the ABORTED
terminal report name the verifier's verdict and stop, so a person debugging a
FAIL has no trail to follow. Every other polish exit names a log. Also, when a
verifier step aborts after an earlier fixer step landed edits, the note says
"Edits landed: yes" but drops the "Delta banked" pointer to that fixer's patch.

## Done when (automated)

- [ ] On an aborted `--code` run, the ABORTED terminal report names the aborted
      step's log, and also the salvage log when a salvage verifier ran.
      `bash docs/tests/test-audit-code.sh` asserts both paths appear in output.
- [ ] The `## Audit (aborted ...)` note written to the task carries a `Log:`
      line naming the same log(s). `bash docs/tests/test-audit-code.sh` asserts
      it in the task file.
- [ ] When a verifier step aborts after an earlier fixer step landed edits, the
      note's `Delta banked` line names that fixer's captured patch.
      `bash docs/tests/test-audit-code.sh` asserts "Edits landed: yes" is
      always followed by a `Delta banked` line.
- [ ] `bash docs/tests/run-all.sh` passes.

## Signoff (human)

None: the automated checks cover it.

## Notes

- Scope is the record only: the ABORTED report and the aborted note. Keep the
  salvage control flow, the double-abort guard, and finished-run verdict parsing
  as they are.
- Log paths already exist: `LOG_FILE` (step log) and `SALVAGE_LOG` (salvage
  verifier log) in `polish.sh`. The UNCLEAR branch's "Inspect the log tail in
  $LOG_DIR/" line is the model to match.
- Delta gap: `SALVAGE_PATCH` is set only in the fixer-abort branch, and
  `_capture_step_delta` resets `STEP_PATCH` on every call. Keep the last
  captured patch in its own variable so a later verifier abort can name it.
- `test-audit-code.sh` has no abort case yet. Its stub CLI prints one fixed
  JSON result. Add a stub that edits a file and then returns a max-turns result
  (`{"is_error":true,"subtype":"error_max_turns",...}`, the shape
  `test-run-interpret.sh` uses) to drive the abort and salvage path.

## References

docs/sprintbias/scripts/polish.sh
docs/sprintbias/help/polish.md
docs/tasks/review/371-salvage-a-polish-code-abort-keep-landed-edits-veri.md

<!-- After work only — audit trail of what was touched. Helps committers,
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

<!--
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->
