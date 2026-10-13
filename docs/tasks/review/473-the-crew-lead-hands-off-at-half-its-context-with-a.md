# Task 473: The crew lead hands off early, at a quarter of its context used, with a brain dump, and a new lead takes over

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

On heavymetal plan 69, orcha held nine gate reviews, every subagent report and every routing call in one session. The progress file (#467) records state, but the lead's judgment (why a call was made, what each member is mid-way through, what looked wrong) lived only in its context, and the handoff waited until context was long or compacted, when the lead is least able to sort what matters.

## Done when (automated)

- [x] Once about a quarter of its context window is used (three quarters free), or after a compaction, the lead adds a ## Lead notes section to docs/tmp/plan-<id>-progress.md: everything a new lead needs that the files do not hold, keeping every useful line and removing one only when a newer one replaces it. Proven by `bash docs/tests/test-crew.sh`
- [x] It starts no new subagents, tells running subagents and members in their own terminals that a new lead is coming online (finish, land with proof, report on the progress file), and waits for running subagents to land. Proven by `bash docs/tests/test-crew.sh`
- [x] It makes the file's first line Handoff: ready (date time) and names the restore command, ./sprint.sh crew <lead> plan:N. Proven by `bash docs/tests/test-crew.sh`
- [x] The new lead sees Handoff: ready, prints Taking over plan N, reads the notes and the board, marks Lead: online, tells live members it leads now, and continues from Next. Proven by `bash docs/tests/test-crew.sh`
- [x] crew starts the new lead by itself: in a live session a watcher sees a fresh Handoff: ready line, waits for the lead's last words (CREW_HANDOFF_GRACE, 20s), ends that session, and crew starts a fresh lead in the same terminal. A session ended any other way stops the loop, and so does a lead that hands off within a minute or 50 times (CREW_HANDOFF_MIN, CREW_HANDOFFS). Proven by `bash docs/tests/test-crew.sh` (Test 6f, stub CLI under a pseudo-terminal, macOS bash 3.2 and Debian bash 5)
- [x] help/crew.md says how a lead hands off. Proven by `./sprint.sh validate --docs`

## Signoff (human)

- [ ] On a long plan, the lead hands off at about a quarter of its context used, the notes read as a useful briefing, and a fresh lead comes online in the same terminal by itself and carries on without asking you anything.

## Notes

- Decided: hand off at about a quarter of the context used (three quarters free), because the person found work stays fast and cheap above 75% free and gets token-heavy below it (first set at half, moved 2026-10-12); a member in its own terminal lands its task and asks for a fresh session at the same point; the agent estimates its own usage, so a compaction is the backstop trigger.
- Decided: background subagents cannot be paused, so the lead lets them land before it hands off; members in their own terminals keep working and report to the file.
- Decided: the handoff is scripted, so no one retypes a command: Handoff: ready is the lead's last write, a watcher beside the session ends it with SIGTERM after a short grace, and crew loops to a fresh lead (2026-10-12, the person asked for it). The lead still names ./sprint.sh crew <lead> plan:N as the fallback when no fresh lead starts.
- Decided: the brain dump lives in the progress file under ## Lead notes, beside the state, so a new lead reads one file.

## References

docs/sprintbias/scripts/crew.sh
docs/sprintbias/help/crew.md
docs/tests/test-crew.sh

## Completed

**Summary**: The crew lead now hands off once about a quarter of its context is used: it writes its notes into the plan's progress file, tells the crew a new lead is coming, and crew ends that session and starts a fresh lead in the same terminal, which takes over from that file.

Fixed in place during the heavymetal plan 69 crew run (2026-10-12), then filed so the record matches the code.

**Proof**: 2026-10-12 · bash docs/tests/test-crew.sh (144 passed, macOS and Debian bash 5); ./sprint.sh validate --docs · pass

### Files changed
docs/sprintbias/scripts/crew.sh
docs/sprintbias/help/crew.md
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
