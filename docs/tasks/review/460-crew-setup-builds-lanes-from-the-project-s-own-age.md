# Task 460: crew setup builds lanes from the project's own agents and standards

**Feature**: none
**Created**: 2026-10-12
**Docs**: none
**Plan**: 35
**From plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-crew.sh
**Refined**: 0
**Reworked**: 0

## Problem

heavymetal already defines its lanes: `.claude/agents/` holds api, db, web, iOS and Android engineers plus security, contract and gate reviewers, and its docs hold a design system and 19 screen specs. crew setup read only the map, the instruction file, existing members and plans, so it could miss lanes the project already defines, and it had no UI and UX pass.

## Done when (automated)

- [x] crew setup reads the project's agent definitions (`.claude/agents/`, roles in AGENTS.md) and standards docs (API, security, permissions, design system, screen specs). Proven by `bash docs/tests/test-crew.sh`
- [x] A builder agent becomes a lane and a reviewer agent a pass; the member's Reads first names the agent file. Proven by `bash docs/tests/test-crew.sh`
- [x] A design system or screen specs add a UI and UX pass; the guide's Recommended crews has a ux row; the lead sends landings to UI and UX passes like stress and security. Proven by `bash docs/tests/test-crew.sh`

## Signoff (human)

- [ ] `./sprint.sh crew setup` on heavymetal keeps the seven members, adds a ux pass reading the design docs, and names plan 69's active set.

## Notes

- Decided: the method names docs/crew/ as where member files live, because the heavymetal run looked for docs/sprintbias/crew and got a failing ls.
- Decided: the project's existing agents and standards are the crew's starting position, because a configured project has already made those calls.

## References

docs/sprintbias/ai/crew-setup.md
docs/sprintbias/guides/crew.md
docs/sprintbias/scripts/crew.sh
docs/tests/test-crew.sh

## Completed

**Summary**: crew setup now builds lanes from the project's own agent definitions and standards docs, and adds a UI and UX pass when there is a design system.

Fixed in place during the heavymetal plan 69 crew run (2026-10-12), then filed so the record matches the code.

**Proof**: 2026-10-12 · bash docs/tests/test-crew.sh · pass

### Files changed
docs/sprintbias/ai/crew-setup.md
docs/sprintbias/guides/crew.md
docs/sprintbias/scripts/crew.sh
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
