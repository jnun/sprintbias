# Task 466: The crew lead runs members as subagents from their profiles

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

Running heavymetal plan 69 as a crew meant the lead plus one terminal per member (db, api, ios, checker, later ux and stress). The member files already say what each one is, and heavymetal's .claude/agents/ already defines api-engineer, db-engineer, ios-engineer and the reviewers, so the lead could start them itself. A terminal per member spends the person's time to give a view most runs do not need.

## Done when (automated)

- [x] The lead runs each routed task as a background subagent when its member has no live session: the agent type the member's Reads first names (the project's own agent), or the general-purpose agent, given the member file, the task path and the member rules; a whole wave at once, routing each release as a landing returns. Proven by `bash docs/tests/test-crew.sh`
- [x] A member with a live session gets a message instead. Proven by `bash docs/tests/test-crew.sh`
- [x] Subagents start none of their own, so the lead starts each pass's reviewer agents (security, contracts, gates) on the landing itself. Proven by `bash docs/tests/test-crew.sh`
- [x] crew setup hands off one start command (the lead on the plan); help/crew.md, the crew guide, DOCUMENTATION.md and the Claude tuning say `crew <name>` in its own terminal is for a member you want to watch or steer. Proven by `bash docs/tests/test-crew.sh` and `./sprint.sh validate --docs`

## Signoff (human)

- [ ] On heavymetal, `./sprint.sh crew orcha plan:69` alone runs wave 1 (#1796, #1797, #1799) as three subagents of the project's own agent types, and routes #1798 to db when #1797 lands.

## Notes

- Decided: subagents are the default and terminals the opt-in, because time is the expense and the files carry all the state a member needs.
- Decided: the lead checks ./sprint.sh agents before spawning, because a member someone started by hand must not be doubled.

## References

docs/sprintbias/scripts/crew.sh
docs/sprintbias/ai/crew-setup.md
docs/sprintbias/help/crew.md
docs/sprintbias/guides/crew.md
DOCUMENTATION.md
docs/tests/test-crew.sh

## Completed

**Summary**: The crew lead now runs each member as a subagent of the project's own agent type, so one command runs a whole plan; separate terminals are for watching a member.

Fixed in place during the heavymetal plan 69 crew run (2026-10-12), then filed so the record matches the code.

**Proof**: 2026-10-12 · bash docs/tests/test-crew.sh; bash docs/tests/test-finish-rule.sh; ./sprint.sh validate --docs · pass

### Files changed
docs/sprintbias/scripts/crew.sh
docs/sprintbias/ai/crew-setup.md
docs/sprintbias/help/crew.md
docs/sprintbias/guides/crew.md
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
