# Task 374: Point the polish --code aborted record at its salvage/step log for a debug trail

**Feature**: none
**Created**: 2026-08-21
**Docs**: none
**Plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

Task 371 taught `polish --code` to salvage an aborted run — keep the landed
edits, run a bounded salvage verifier, and record the outcome honestly. But the
aborted record dead-ends when someone needs to debug it. When the salvage
verifier returns FAIL ("landed edits have open issues"), neither the task's
`## Audit (aborted)` note nor the terminal ABORTED output points at the log
where those issues are described — the record names the verdict and stops. Every
other terminal branch in polish.sh surfaces a log (the sweep's `_route_refine`
consistently prints `See $LOG_FILE`; the code-mode UNCLEAR branch says "Inspect
the log tail in $LOG_DIR/"), so this is the one abort path with no debug trail.
That directly undercuts the task's own stated thesis — honest observability and
"what broke?" recovery.

A second, smaller completeness gap sits in the same note: when a *verifier* step
aborts after an *earlier fixer* step already landed edits, `SALVAGE_PATCH` is
empty (it is only assigned in the fixer-abort branch), so the note prints
"Edits landed: yes" but omits the "Delta banked" pointer even though that
earlier step did capture a delta patch. The landed work is real but its delta
pointer silently drops.

## Success criteria

- [ ] On an aborted `--code` run, the ABORTED terminal output points the
      operator at the relevant log(s) — the aborted step's `$LOG_FILE`, and the
      `$SALVAGE_LOG` when a salvage verifier ran — so a FAIL or partial abort has
      a trail to follow, matching the "Inspect the log tail" affordance the
      UNCLEAR branch already offers (polish.sh:795-799).
- [ ] The `## Audit (aborted)` note records a pointer to the salvage log (or the
      aborted step log) alongside the verifier result, so the debug trail
      survives in the task file, not just on a scrolled-away terminal.
- [ ] When a verifier step aborts after an earlier fixer landed edits, the note's
      "Delta banked" pointer resolves to that earlier step's captured patch
      rather than being dropped — "Edits landed: yes" is never printed without
      the delta it refers to.
- [ ] Scope stays on the aborted record/recovery copy (the ABORTED terminal
      branch and the `## Audit (aborted)` note). No change to salvage control
      flow, the double-abort guard, or how a finished run's verdict is parsed.

## Notes

- The salvage log path already exists as `$SALVAGE_LOG` (polish.sh:602) and the
  aborted step log as `$LOG_FILE` (polish.sh:552); this task threads them into
  the existing ABORTED report (polish.sh:770-793) and aborted-note block
  (polish.sh:729-746). No new machinery — it reuses the log paths already
  captured.
- The delta-pointer gap: `SALVAGE_PATCH` is assigned only in the fixer-abort
  branch (polish.sh:581). The success-path fixer step captures `STEP_PATCH`
  (polish.sh:657-662) but does not retain it for a later verifier abort — retain
  the last captured patch so the aborted note can surface it.
- Small, self-contained follow-on to 371; no dependency on the #367/#368
  interpreter work.

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
