# Task 445: Project map points at the project's invariants

**Feature**: none
**Created**: 2026-10-11
**Docs**: none
**Plan**: 33
**From plan**: none
**Depends on**: none
**Dependents**: 444
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-profile.sh
**Refined**: 0
**Reworked**: 0

## Problem

Projects carry rules every change must keep (tenant isolation, a balanced
ledger, posted entries never edited), but the project map has no place that
points at them. Agents and crew members miss the rules that matter most, and
the only nearby section, ## Known edges, is the record of past breakage
(appended by promote --reject, capped at about 15 lines), not a home for
rules.

## Done when (automated)

- [x] The map format profile asks for lists an optional
      `**Invariants:**` line under ## Sources of truth: a pointer to the
      project document that holds the rules every change keeps. `grep -n
      'Invariants:' docs/sprintbias/scripts/profile.sh` matches inside the
      output format.
- [x] The scan instruction names invariants (rules every change keeps:
      isolation, money, data that is never edited) among the sources of truth
      to look for. `grep -n -i invariant docs/sprintbias/scripts/profile.sh`
      matches inside SCAN_INSTRUCTION.
- [x] ## Known edges keeps its meaning and format: one `- ` line per broken
      case, untouched by this change. `bash docs/tests/test-profile.sh` passes.

## Signoff (human)



## Notes

Pointers only: the map never copies the rules themselves. Leave the
line out when the project has no such document. Known edges belongs to
sprintbias_add_known_edge and the edge scorecard (status --edges); do not
change that section.

## References

docs/sprintbias/scripts/profile.sh
docs/tests/test-profile.sh

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

**Summary**: The project map format gains an optional Invariants pointer under Sources of truth, and profile looks for the document that holds the rules every change keeps.

**Proof**: 2026-10-11 · bash docs/tests/test-profile.sh · pass

**Breaker**: 9 cases tried · 1 fixed · 1 filed · $0.54
- Fixed: rules kept in one section of a larger file invited `CLAUDE.md#invariants`, which profile check flags as a missing path; the format rule now shows the section form `CLAUDE.md` (## Invariants).
- Filed #450: profile check itself treats any `path#anchor` as missing (lib.sh, shared by every map line).

### Files changed
docs/sprintbias/scripts/profile.sh
docs/tests/test-profile.sh
