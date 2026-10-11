# Task 414: promote plan:N blames a failure that predates the plan on its last member

**Feature**: none
**Created**: 2026-10-08
**Docs**: none
**Plan**: none
**From plan**: 29
**Depends on**: none
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-promote.sh
**Refined**: 1
**Reworked**: 0

## Problem

When the full suite fails at `promote plan:N` and no member's files match the
failure, promote blames the plan's last member anyway. It files a fix task
against that member and holds it. At plan 29's close a failure that predated the
plan (`test-cleanup-tmp.sh` Test 8) was filed as fix #413 against #411, which
had nothing to do with it. Whoever finishes last takes the blame for old
breakage, and the fix task's link points at the wrong work.

## Done when (automated)

- [ ] When no member matches a failure, `promote plan:N` files one unattributed
      fix task: `**Fixes**: none`, no `**Held**` on any member, `**Crew**` set
      to the plan's lead when the plan has one, and a member line added to the
      plan. Output says the failure matches no member's work and names the
      fix task. `bash docs/tests/test-promote.sh` asserts this (rewrite Test
      14b, which today expects a fix for the last member, #743).
- [ ] Re-running `promote plan:N` while that unattributed fix task is still
      open lists it again and files no second one. `bash
      docs/tests/test-promote.sh` asserts one fix task after two runs.
- [ ] A failure that matches a member still files a fix against that member and
      holds it, as today. The existing Test 14 cases keep passing.
- [ ] The sign-off is still refused while the suite is red, and nothing moves.
      `bash docs/tests/test-promote.sh` asserts exit 1 and every member still
      in review/.
- [ ] `bash docs/tests/run-all.sh` passes.

## Signoff (human)

None: the automated checks cover it.

## Notes

- Decided: no baseline of past failures. Attribute by file match only; an
  unmatched failure is unattributed. A red suite still refuses the sign-off;
  the unattributed fix task is the path back to green.
- The fallback is `[ -n "$TARGETS" ] || TARGETS="$LAST"` in `promote.sh`'s
  plan:N failure routing. Replace it with the unattributed path.
- `sprintbias_file_fix_task` (`lib.sh`) takes an original id, refuses an
  original outside review/, and always writes `Fixes` and `Held`. Give it an
  unattributed mode (or add a sibling) that takes the plan instead.
- Pick a stable way to recognize "an open unattributed fix task for this plan"
  so the second run can find it, for example its title or a field. Keep it
  plain and documented in the function header.
- If the `Fixes` field text changes, update the `Fixes` line in
  DOCUMENTATION.md's Task fields in the same change.

## References

docs/sprintbias/scripts/promote.sh (promote plan:N failure routing)
docs/sprintbias/lib.sh (sprintbias_file_fix_task)
docs/tests/test-promote.sh


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

     When the work made a source of truth wrong and updating it is out of
     scope (or it is a governing source), add under ## Completed:

       ### Doc follow-ups
       - `docs/GLOSSARY.md` — add "plan"; the code now uses it

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. Do not fill this before work. -->

<!-- sb:hint
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->
