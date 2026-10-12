# Plan 34: Consequences and policy: show the calls that matter, stop re-deciding settled ones

**Created**: 2026-10-12
**Status:** READY
**Crew**: none

## Goal

The person sees, first and in plain words, every call an agent made that
changes what people read, what is stored or published, or what a person can do
(Consequences), and every project can write its settled practices down once as
strict Policy that agents apply without spending thinking on them again. A
Consequence the person accepts at sign-off becomes Policy, so the same call is
never re-decided. Every command that edits plan or task files ends with the same
Changes report, Consequences on top. SprintBias ships its own default Policy,
and a correction the person gives an agent becomes a Policy line.

## Why

Agents decide by default now (plan 32), and plan 69 in heavymetal showed the
cost: "Holder", a new product word, was recorded only in one task's Notes, and
the plan's 16 calls mixed product changes with transaction details. Leaning
into agent bias means a strict policy for what is already known to work, so
compute goes to what is new.

## Member tasks

<!-- One "- #ID — short title" line per task; [x] means the task is in done/.
     IDs are references — resolve each against docs/tasks/*/ for location. -->

- #452 — Plan think, work and crew surface Consequences: calls that change words, data keys or what people can do
- #453 — Project map Policy: settled practices agents apply without re-deciding
- #438 — plan start, polish and chat plan end with a change report (sprintbias_change_snapshot) instead of git diff advice
- #454 — SprintBias ships a default Policy and turns a person's corrections into Policy lines

## Decided

- Decided: order is 452 (the Consequence line and where it shows), then 453
  (Policy, which reads and writes Consequences) and 438 (Changes report, which
  opens with them), because both later members build on 452's format.
- Decided: add #454 after 453, because a shipped default Policy and corrections
  that become Policy are what let a project with no instruction file or memory
  start from SprintBias's way of building.

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
