# Task 450: profile check flags a map path with a section anchor (CLAUDE.md#invariants) as missing

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
**Tests**: docs/tests/test-profile.sh
**Refined**: 0
**Reworked**: 0

## Problem

<!-- sb:hint  Clear, simple language. Concisely define the problem at a high
     level — who is stuck, what is wrong, why it matters. 2–5 short sentences.
     User-story height — not a build plan. -->

A project map line can point at one section of a file, such as
`CLAUDE.md#invariants`. sprintbias_profile_check in docs/sprintbias/lib.sh
tests the whole token with `[ -e ]`, so it reports the file as missing even
though `CLAUDE.md` exists, and `work` / `plan start` nag to refresh the map.
Found by the breaker on #445.

## Done when (automated)

<!-- sb:hint  What done looks like, proven by a machine. Each outcome is an
     observable check; name the test or command that proves it in backticks
     (`bash docs/tests/test-login.sh`, `npm test -- login`). When these pass, an
     agent may land the task. A line that lists cases names a check per
     case; an example stands for its class (other formats, re-runs, empty
     input). For a library or detailed technical fix, state the new technical
     needs as outcomes — still not a step outline. -->

- [ ] profile check strips a `#anchor` before testing the path: a map line
      `CLAUDE.md#invariants` with `CLAUDE.md` present checks clean, and with it
      absent names the missing path. Proved in `bash docs/tests/test-profile.sh`.
- [ ] Drift tracking compares the file part only, so a change to `CLAUDE.md`
      flags a map that lists `CLAUDE.md#invariants`.

## Signoff (human)

<!-- sb:hint  What only a person can judge: user stories to try, screens to
     look at, real hardware to try. Never holds the work: in a plan these
     gather into one human test, run at the end. Leave empty when a machine
     proves everything. -->

- [ ]

## Notes

<!-- sb:hint  Optional helpful hints that assist the developer: constraints, edge
     cases, gotchas. Guidance from answered questions also lives here when it
     shapes how (and is not already a success criterion). Leave empty if none. -->

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
