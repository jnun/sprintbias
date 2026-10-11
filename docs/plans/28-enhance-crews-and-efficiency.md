# Plan 28: enhance crews and efficiency

**Created**: 2026-10-08
**Status:** DRAFT
**Crew**: none

## Goal

Agents stop waiting on human sign-off. A task counts as landed when it is in
review/ with recorded test proof, and landed work releases its dependents at
once. Humans sign off whole plans in one batch, after one full-suite run, and a
rejection becomes a linked fix task. Solo agents and crews each get a workflow
written for how they work: one context versus maximum parallel throughput.

## Why

Today done/ is the human's final approval and also the point where work counts,
so every dependency chain waits on a person. Crews sit idle and solo runs stall.

## Policy

Every task in this plan uses these names and formats exactly.

- **Landed**: in review/ with a proof line. Landed work releases its
  dependents. In review/ without proof is "in review, unproven" and releases
  nothing.
- **Signed off**: in done/. Only humans move work there, at the end of a task
  or plan, after the full suite passes and the human checks are done.
- Proof line, under ## Completed:
  `**Proof**: YYYY-MM-DD · <targeted test commands> · pass`
- Task sections: `## Done when (automated)` (outcome plus the tests that prove
  it), `## Signoff (human)` (what a person checks), `## Test log` (each failure:
  command, failing test, error excerpt). An old `## Success criteria` section
  reads as Done when (automated).
- Fix tasks: `**Fixes**: #<id>` on the fix task; `**Held**: fix #<new>` on the
  rejected original, which stays in review/ and releases nothing until the fix
  lands.
- **Held** (standing): review/ with proof, a fix not yet landed; shown
  `held: fix #N`.
- Plan states, computed from the folders: STARTED (work open), LANDED (every
  member landed), SIGNED OFF (every member in done/).
- Targeted tests per task; the full suite once, at plan close.

Constraints: plain bash and markdown, no new dependencies; folders stay the
only status; humans own git and done/; prefer a flag on an existing command
over a new command; re-running setup.sh upgrades existing projects without
breaking their tasks.

## Member tasks

- #398 — Dependents wait on done/ instead of proven work in review/
- #399 — Tasks lack a testable automated done-when separate from human sign-off
- #400 — Workers land tasks without targeted test proof or a test log
- #401 — Plan check cannot tell landed work from signed-off work
- #402 — A rejected review/ task has no linked fix task or dependent trace
- #403 — Signing off a plan means one task at a time with no full-suite gate
- #404 — Crew lead routes slowly and leaves members idle
- #405 — Docs treat done/ as the agent gate and blur solo and crew modes
- #406 — Demos do not show a plan finishing on landed work with one sign-off

Parallelism (recorded only; v1 runs in order): 398 and 399 have landed in
review/. 400 ∥ 401 ∥ 402 once both have landed; 400 and 401 each add separate
lib.sh functions, so keep their edits there small. 403 after 401 and 402 (shares
promote.sh with 402). 404 after 400 and 403 (shares crew.sh with 400).
405 ∥ 406 at the end: docs and help versus learning/, disjoint files.

## Signoff (human)

- Run ./sprint.sh learn for the solo demo and the crew demo. Each finishes a
  plan on landed work with one batch sign-off.
- Read the Solo and Crew sections of DOCUMENTATION.md. A new user can tell
  which mode fits them in under a minute.

<!--
AI: Full plan guidance is in DOCUMENTATION.md → Plans. A plan is a relational
index, not a container: Status is DRAFT | READY | STARTED, and members stay in
their own lifecycle folders. Keep it plain text — no emoji, color, or ASCII art.
See docs/sprintbias/guides/doc-style.md
-->
