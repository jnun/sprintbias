# Plan 31: Plan history in docs/history

**Created**: 2026-10-10
**Status:** STARTED
**Crew**: none

## Goal

Finished plans become a lasting, readable record. `plan done` writes one
history record per plan into `docs/history/` (goal, decisions, one line per
task, follow-ups) instead of only deleting the plan; `history record` writes
down finished work outside any plan; `./sprint.sh history` lists the records
and turns them into release notes; and the manual and AI guidance send readers
to `docs/history/` first. Ordered so the record format lands first.


## Why

<!-- Optional short rationale — why group this work now. Leave empty if the
     Goal already says it. -->



## Member tasks

<!-- One "- #ID — short title" line per task; [x] means the task is in done/.
     IDs are references — resolve each against docs/tasks/*/ for location. -->

- #421 — plan done writes a history record to docs/history instead of deleting the plan
- #423 — Generate release notes from docs/history records
- #439 — history record writes finished tasks into docs/history
- #441 — Human test for plan 31

## Decided

- Decided: each member's line in a record comes from a new `**Summary**:` line the work agent writes under `## Completed` (#421), because recent `## Completed` sections open with `### Assumptions` and carry no prose to quote.
- Decided: records carry the plan's `## Decided` section, because the calls a plan made are the history git cannot reconstruct.
- Decided: drop the changelog setting (old #422); `plan done` prints a paste-ready line instead (#421), because a user's changelog is theirs.
- Decided: records hold no file lists or proof lines, and #421 points the manual and AI guidance at `docs/history/`, because the records exist to be read.
- Decided: `history --since <ref>` compares trees, not dates (#423), because two releases can land on one day.
- Decided: add #439, `history record`, for `done/` tasks with no plan or whose plan file is gone, because they are over half of `done/`; members of open plans wait for `plan done`, so no task is recorded twice.
- Order: 421, then 423, then 439.

## Signoff (human)

<!-- Optional. What only a person can check across the whole plan: real
     hardware, the full flow end to end. plan start gathers these and every
     member's Signoff (human) into one human test, run once the plan lands.
     Agents never wait on it. Leave empty when tests prove everything. -->

<!--
AI: Full plan guidance is in DOCUMENTATION.md → Plans. A plan is a relational
index, not a container: Status is DRAFT | READY | STARTED, and members stay in
their own lifecycle folders. Keep it plain text — no emoji, color, or ASCII art.
See docs/sprintbias/guides/doc-style.md
-->
