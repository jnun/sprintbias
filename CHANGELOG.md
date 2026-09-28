# Changelog

All notable changes to SprintBias are recorded here, newest first. Versions
follow `src/VERSION` (`X.Y.Z`). This file is repo-only — it is not distributed
into user installs.

Add entries under `## Unreleased` as you finish user-facing work; `./ship.sh`
renames that section to the new version and date on each bump.

## Unreleased

### Added

- Reviews raise issues one at a time. When a `chat` walk (or any agent
  reviewing a plan) finds two or more things that need your call, it lists them
  in `docs/tmp/<subject>_discuss.md`, then raises one issue per message with
  numbered options (the best-practice pick marked suggested), carries out your
  pick right away, and moves to the next. An interrupted session resumes from
  the file.

### Changed

- `plan think` now acts on everything it can settle itself and holds only your
  calls (a product or policy choice, a number only you can set, a cut you might
  contest) in `docs/tmp/plan-<id>_discuss.md`. When it finishes it opens
  `chat plan <id>`, which raises those items one at a time and acts on each
  decision as you make it.
- `plan think` checks every unstarted task against the code before touching it:
  is the problem real, already solved, and needed for the plan's goal? Scope
  creep is trimmed on the spot; tasks that are already done, describe a problem
  the code doesn't have, or don't serve the goal come to you (with file:line
  evidence) as discussion items. The review opens with a per-task verdict list.
  In `chat plan`, each is raised with options fitted to its verdict: close,
  trim, or delete a done-already task; delete or keep a not-real one; delete or
  put off an off-goal one — and the pick is carried out immediately.

## 0.0.127 — 2026-09-21

## 0.0.126 — 2026-09-21

### Changed

- Rewrote the manual (`DOCUMENTATION.md`): shorter and reorganized around how the
  tool actually works — new sections for *How it works*, *Why folders and plain
  text*, *Folders = status*, *Distinctions that trip up agents*, and *The
  pipeline*. Same ground, ~150 fewer lines.
- Audit runs now read each result once. The internal machinery that reads an AI
  audit's output (used by polish and promote) was doing the same work two or
  three times per run; it now reads once and reuses the outcome, verdict, and
  summary. No user-visible change — just less duplicated work.

### Fixed

- `promote` now explains when a judge doesn't finish. When the AI judge runs out
  of turns or never starts, promote says so plainly ("judge did not finish — …")
  and leaves the task in `review/`, instead of blaming a missing verdict. A
  judge that finished but answered oddly is reported separately.
