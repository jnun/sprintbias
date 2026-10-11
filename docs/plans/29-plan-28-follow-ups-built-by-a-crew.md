# Plan 29: Plan 28 follow-ups, built by a crew

**Created**: 2026-10-08
**Status:** STARTED
**Crew**: orcha

## Goal

<!-- What this group of tasks achieves together, and why now. 2–5 sentences —
     the theme that makes these tasks one plan. Aim for well-defined,
     non-conflicting work, ordered so dependencies run first. -->



## Why

<!-- Optional short rationale — why group this work now. Leave empty if the
     Goal already says it. -->



## Member tasks

<!-- One "- #ID — short title" line per task; [x] means the task is in done/.
     IDs are references — resolve each against docs/tasks/*/ for location. -->

- #407 — Plan check calls a held original with proof unproven
- #408 — Batch sign-off lists an open fix task twice
- #409 — Plan close runs the full suite twice
- #410 — The teamwork demo is too long to follow in one sitting
- #411 — The manual grew 460 words agents must load every run
- #413 — Fix #411: The manual grew 460 words agents must load every run

## Crew

Approach: three lanes with disjoint files, so wave 1 runs fully in parallel.
core fixes how plan state reads (lib.sh standing, plan check, status); signoff
owns promote.sh, so #408 and #409 run in order on one member (lower id first);
demos splits the teamwork demo, then trims the manual last, once the behavior
it describes has landed.

- core — #407 landed; next: none queued (lane done unless a fix comes back)
- signoff — #408, #409 landed; next: none queued
- demos — #410, #411 landed; next: none queued

Plan close: every member landed. Lead runs the full suite once, then hands the
human one sign-off: ./sprint.sh promote plan:29

<!--
AI: Full plan guidance is in DOCUMENTATION.md → Plans. A plan is a relational
index, not a container: Status is DRAFT | READY | STARTED, and members stay in
their own lifecycle folders. Keep it plain text — no emoji, color, or ASCII art.
See docs/sprintbias/guides/doc-style.md
-->
