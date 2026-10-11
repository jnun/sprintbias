# Task 441: Human test for plan 31: Plan history in docs/history

**Owner**: human
**Created**: 2026-10-10
**Plan**: 31
**Depends on**: none
**Tests**: none

## Problem

Agents built plan 31 on reasonable assumptions and simulated tests, and kept
moving. This is the one pass a person makes in the real world: on hardware,
in the live product, by eye. Run it when `./sprint.sh plan check 31` reads
LANDED (earlier is fine; what you find feeds the agents sooner).

## Signoff (human)

- [ ] #421: Run `plan done` on a real finished plan and read the record: it should tell you what the plan was for and what it changed in about a page.
- [ ] #421: After the release, a fresh install (CONTRIBUTING.md step 5) shows an empty `docs/history/` with `.gitkeep`.
- [ ] #423: Run `./sprint.sh history --since <last release tag>` in this repo and judge whether the output works as release notes with light editing.
- [ ] #439: Run `./sprint.sh history record` in this repo (the first run backfills every planless task and every retired plan's members) and check the record reads as an honest account of where the project is.

## Results

<!-- sb:hint  One line per check that failed, in your words:
       - fail: the LED stays red after pairing
     ./sprint.sh promote plan:31 files each one as a fix task the agents
     build, then asks you to re-run this test. All passed: leave this empty
     and approve the batch. -->
