# Task 420: Human test for plan 30: Fast mode: autonomous agents, fewer blockers

**Owner**: human
**Created**: 2026-10-10
**Plan**: 30
**Depends on**: none
**Tests**: none

## Problem

Agents built plan 30 on reasonable assumptions and simulated tests, and kept
moving. This is the one pass a person makes in the real world: on hardware,
in the live product, by eye. Run it when `./sprint.sh plan check 30` reads
LANDED (earlier is fine; what you find feeds the agents sooner).

## Signoff (human)

- [ ] With fast on, run `chat plan` on a real plan: it creates a missing task, sets a dependency on another plan's task, builds a small piece through a subagent, and asks nothing you could not answer with one keystroke.
- [ ] Flip fast off: the next session's banner says steady and permission prompts return.
- [ ] #415: Flip fast on and off; the banner on the next `chat` session says which mode it is in, at a glance
- [ ] #416: Run `./sprint.sh work` with fast on in a scratch project; no permission prompt appears and independent tasks run at once
- [ ] #417: Run `chat plan` on a real plan with fast on; the agent decides clear calls without asking and every question it asks can be answered with one keystroke
- [ ] #418: In a real `chat plan` session, ask for a missing task and a dependency on another plan's task; both appear without leaving the session
- [ ] #419: Run a two-member crew with fast on; stop one member mid-task and watch the other take it over

## Results

<!-- sb:hint  One line per check that failed, in your words:
       - fail: the LED stays red after pairing
     ./sprint.sh promote plan:30 files each one as a fix task the agents
     build, then asks you to re-run this test. All passed: leave this empty
     and approve the batch. -->
