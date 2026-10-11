# Plan 30: Fast mode: autonomous agents, fewer blockers

**Created**: 2026-10-10
**Status:** STARTED
**Crew**: none

## Goal

One clear switch, `./sprint.sh fast on|off`, lets agents work at full speed:
they decide by best practice, good security, elegant code and the best UX, start
subagents to build missing pieces, and reach across plans to edit, create or
take over the tasks a goal needs. They ask the person only yes/no or 1/2/3
questions that change what gets delivered. Steady (off) keeps today's pace, but
plan chat can create and edit tasks and set dependencies across plans in either
mode.

## Why

Agents stall on rules written into the prompts: plan chat may write only its
plan file, crew members stay in their lanes, the lead sends every decision to
the person, and every session waits on permission prompts.

## Policy

- Fast on: no permission prompts, parallel by default (absorbs the old
  `--fast`), decisions recorded as `Decided: X, because Y`.
- Cross-plan: read the other plan's Goal first, serve both goals, and leave
  `Touched by plan N: #id — what and why` on the other plan. A task keeps its
  own plan membership.
- Always the human's, in every mode: commit, push, ship.sh, done/ sign-off,
  production credentials. Agents never revert another agent's changes.

## Member tasks

- #415 — Add a clear fast on/off switch
- #416 — Fast mode skips permission prompts and runs work in parallel
- #417 — Fast mode lets agents decide and ask only goal questions
- #418 — Plan chat cannot create tasks, set cross-plan deps, or build
- #419 — Crew lanes and task holds stall work in fast mode
- #420 — Human test for plan 30

Parallelism (recorded only): 415 first. Then 416 ∥ 417 (cli/ + work.sh +
polish.sh versus lib.sh rule block + ai/conversation.md). Then 418 ∥ 419
(chat-plan.sh versus crew.sh).

## Signoff (human)

- With fast on, run `chat plan` on a real plan: it creates a missing task, sets
  a dependency on another plan's task, builds a small piece through a subagent,
  and asks nothing you could not answer with one keystroke.
- Flip fast off: the next session's banner says steady and permission prompts
  return.

<!--
AI: Full plan guidance is in DOCUMENTATION.md → Plans. A plan is a relational
index, not a container: Status is DRAFT | READY | STARTED, and members stay in
their own lifecycle folders. Keep it plain text — no emoji, color, or ASCII art.
See docs/sprintbias/guides/doc-style.md
-->
