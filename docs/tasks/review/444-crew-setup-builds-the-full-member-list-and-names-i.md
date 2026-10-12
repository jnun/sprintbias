# Task 444: crew setup builds the full member list and names invariants

**Feature**: none
**Created**: 2026-10-11
**Docs**: none
**Plan**: 33
**From plan**: none
**Depends on**: 445
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-crew.sh
**Refined**: 0
**Reworked**: 0

## Problem

crew setup proposes two to four members and stops, so a project with
more lanes (an API, web, iOS and Android, a ledger, production) gets its lanes
squeezed into a few members. It treats the member list (files, cheap) and the
members running at once (sessions, costly) as one number. It also never names
the rules every change keeps, and a plan that needs a lane no member owns
has no rule for filling it.

## Done when (automated)

- [x] ai/crew-setup.md has setup create a member file for every lane the
      project needs and name the active set for the first plan; the size limit
      reads as members running at once (about four to six per lead), not
      members in total. Checked by `bash docs/tests/test-crew.sh`.
- [x] ai/crew-setup.md step 1 names the project's invariants: it points each
      member's Reads first at the document the map's `**Invariants:**` line
      names, and when no document holds them it files a task with
      ./sprint.sh newtask to write them down. It never writes them into
      ## Known edges. `grep` checks in `bash docs/tests/test-crew.sh`.
- [x] A lane can be a pass as well as a codebase: guides/crew.md shows a
      member whose Job runs polish --break or polish --code on review/ work in
      its lanes, and the lead routes landed work in a ship plan to its pass
      owners before plan close.
- [x] guides/crew.md Recommended crews adds: one API with several clients,
      money or regulated data (add a checker), and one line on lanes that only
      build on certain machines (iOS needs a Mac).
- [x] The lead fills an unowned lane: a task no member's May touch covers gets
      a member through ./sprint.sh crew add, recorded as Decided: on the plan's
      ## Crew board, and the human is told which terminal to start. Stated in
      ai/crew-setup.md, guides/crew.md and the DOCUMENTATION.md Crew section.
- [x] The lead writes `Active:` on the plan's ## Crew board. help/crew.md and
      the DOCUMENTATION.md Crew section say the same. `./sprint.sh validate
      --docs` passes.

## Signoff (human)

- [ ] Run ./sprint.sh crew setup on a project shaped like API + web + iOS +
      Android; the proposal covers every lane with an owner and names a small
      active set for the first plan.

## Notes

No template change and no new field: a member's pass goes in its Job and
May touch. Edit only the Crew section of DOCUMENTATION.md, with small edits
after a fresh read (another session edits its status section).

## References

docs/sprintbias/ai/crew-setup.md
docs/sprintbias/scripts/crew.sh
docs/sprintbias/guides/crew.md
docs/sprintbias/help/crew.md
DOCUMENTATION.md
docs/tests/test-crew.sh

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

## Completed

**Summary**: crew setup writes a member for every lane (passes included), names the active set per plan and points members at the project's invariants; the lead writes Active:, adds a member for an unowned lane and feeds landings to pass members.

**Proof**: 2026-10-11 · bash docs/tests/test-crew.sh; ./sprint.sh validate --docs; ./sprint.sh validate --commands · pass

**Breaker**: 4 cases tried · 2 fixed · 0 filed (setup's four-to-six active set now defers to the CLI notes' smaller cap; guides/crew.md no longer says pass members never edit code, since polish --break and --code fix inline) · $0.65

### Files changed
docs/sprintbias/ai/crew-setup.md
docs/sprintbias/scripts/crew.sh
docs/sprintbias/guides/crew.md
docs/sprintbias/help/crew.md
DOCUMENTATION.md
CHANGELOG.md
docs/tests/test-crew.sh
