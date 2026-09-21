# Changelog

All notable changes to SprintBias are recorded here, newest first. Versions
follow `src/VERSION` (`X.Y.Z`). This file is repo-only — it is not distributed
into user installs.

Add entries under `## Unreleased` as you finish user-facing work; `./ship.sh`
renames that section to the new version and date on each bump.

## Unreleased

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
