# Task 451: Breaker rewrites a proof line so it no longer ends in pass

**Feature**: none
**Created**: 2026-10-11
**Docs**: none
**Plan**: none
**From plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

After a breaker run fixes something, it rewrites the task's **Proof**: line
with a note after the result (`· pass (after breaker fixes)`, `· pass (110)`).
sprintbias_has_proof only counts a line that ends in `pass`, so the task reads
as unproven and `promote plan:N` holds a plan whose tests are green. Seen on
plan 33: #444 and #446 were held until the notes were removed by hand.

## Done when (automated)

- [ ] A breaker run that fixes something leaves a **Proof**: line that
      sprintbias_has_proof accepts; notes go on the **Breaker**: line, not the
      Proof line. Checked by a case in the breaker's test script.
- [ ] Either the breaker prompt states the exact Proof format and that the line
      ends in `pass`, or sprintbias_has_proof accepts `pass (...)`. Pick one
      and record it as Decided:. A test covers the chosen rule.

## Signoff (human)

<!-- sb:hint  What only a person can judge: user stories to try, screens to
     look at, real hardware to try. Never holds the work: in a plan these
     gather into one human test, run at the end. Leave empty when a machine
     proves everything. -->

- [ ]

## Notes

The breaker functions live in docs/sprintbias/lib.sh near lines 815-915,
which another session is editing for the field trial. Sequence behind that
work, or hand this task to that session.

## References

docs/sprintbias/lib.sh (sprintbias_has_proof, breaker prompt)
docs/tasks/review/444-crew-setup-builds-the-full-member-list-and-names-i.md
docs/tasks/review/446-crew-setup-prints-usage-when-given-extra-arguments.md

<!-- sb:hint  After work only — audit trail of what was touched. Helps committers,
     later audits, and "what broke?" recovery. List the product files you
     edited to complete the task — one repo-relative path per line. Leave this
     task file out: its folder location and git history already track it. Copy
     the two headings below to column 0
     (UNINDENTED — they are indented here only so a fresh, unworked task is not
     mistaken for a finished one), then list the paths under "Files changed":

       ## Completed

       **Summary**: <one plain sentence: what changed, for someone reading
       the project's history>

       ### Files changed
       docs/sprintbias/scripts/example.sh
       docs/sprintbias/help/example.md

     When the work rests on something only a person can confirm (a device,
     a live account), add under ## Completed; it joins the plan's human test:

       ### Assumptions
       - The scanner sends one line per barcode

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
