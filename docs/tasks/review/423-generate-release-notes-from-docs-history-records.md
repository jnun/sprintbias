# Task 423: Generate release notes from docs/history records

**Feature**: none
**Created**: 2026-10-10
**Docs**: docs/sprintbias/help/_registry, DOCUMENTATION.md
**Plan**: 31
**From plan**: none
**Depends on**: 421
**Dependents**: 439
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-history.sh
**Refined**: 0
**Reworked**: 0

## Problem

Once finished plans leave history records in `docs/history/`, the material for
release notes already exists, but assembling it by hand means opening each
record and rewriting it. A person cutting a release wants one command that
turns "everything finished since the last release" into notes they can paste
or publish.

## Done when (automated)

- [x] `./sprint.sh history` lists history records newest first, one line each:
      finish date, plan id, title. `bash docs/tests/test-history.sh`
- [x] `./sprint.sh history --since <YYYY-MM-DD | git ref>` prints Markdown
      release notes to stdout: one `###` heading per plan with its Goal's first
      sentence, then its `What changed` lines. A date selects records whose
      `**Finished**` date is on or after it. A git ref selects the records in
      `docs/history/` that the ref's tree does not have (committed since, or
      not yet committed), so two releases on one day split correctly.
      `bash docs/tests/test-history.sh`
- [x] Output only, pure shell, no AI; it writes no files. With no records in
      range it prints a one-line notice and exits 0.
      `bash docs/tests/test-history.sh`
- [x] Surfaces in step: `help/_registry`, `help/history.md`, `DOCUMENTATION.md`,
      `docs/guides/command-matrix.md`. `./sprint.sh validate --commands` and
      `bash docs/tests/run-all.sh` pass; one `### Added` bullet in `CHANGELOG.md`.

## Signoff (human)

- [ ] Run `./sprint.sh history --since <last release tag>` in this repo and
      judge whether the output works as release notes with light editing.

## Notes

- Reads the record format from task 421 by its section headings; keep the two
  in step (421's header line carries `**Finished**`, which the date form of
  `--since` filters on).
- Decided: a git ref compares trees (`git ls-tree <ref> -- docs/history`), not
  the ref's commit date, because records are dated by day and a release tag
  can fall mid-day.
- Record lines come from each member's `**Summary**:` line (task 421), which
  the work agent writes for a reader of the project's history. If notes still
  read too internal at signoff, file a follow-up; leave it out of this task.
- Plain word `history` per the common-language lens; one command, flag for
  the notes view, rather than a second command.
- Decided: an argument shaped `YYYY-MM-DD` is a date; anything else is a git
  ref checked with `git rev-parse --verify <ref>^{tree}`. An unknown ref, or a
  ref outside a git work tree, prints one error line and exits non-zero,
  because silently printing every record would pass for real release notes.
  `test-history.sh` covers the bad-ref case.
- Decided: notes list plans oldest first (release-note reading order) while the
  bare list is newest first (timeline view), because each serves its reader.
- Decided: 439's task-batch records (`*-tasks.md`) are 439's to read; this task
  handles plan records and skips files without a `# Plan N:` heading, so 439
  can extend the same reader without changing this output.

## References

docs/sprintbias/scripts/plan-done.sh
docs/sprintbias/help/_registry
docs/guides/command-matrix.md
DOCUMENTATION.md
docs/tasks/next/421-plan-done-writes-a-history-record-to-docs-history.md
docs/tasks/backlog/439-history-record-writes-finished-tasks-into-docs-hi.md
docs/tests/test-plan-lifecycle.sh

## Grounding

**Sources:** `CONTRIBUTING.md` (how a change ships, surfaces kept in step), `docs/sprintbias/help/_registry` (command catalog, one source of truth), `DOCUMENTATION.md` (user manual), `docs/guides/command-matrix.md` (command surface matrix), `docs/sprintbias/guides/doc-style.md` (plain-text output style), task 421 (history record format).
**Terms:**
- None. The project has no glossary; `history`, `record` and `release notes` carry their plain meaning.
**Touching:** docs/sprintbias/scripts/history.sh (new), sprint.sh (dispatch),
docs/sprintbias/help/_registry (`history` row), docs/sprintbias/help/history.md
(new), docs/tests/test-history.sh (new), DOCUMENTATION.md (Commands block),
docs/guides/command-matrix.md (look family), CHANGELOG.md
**Conflicts:**
- Task 421 has since landed (review/ with **Proof**), so the record format is
  the one `plan-done.sh` writes; built and tested against that.
- The record format does not exist yet (421 is in next/, `docs/history/` is absent) → build against 421's Done when as the contract; `**Depends on**: 421` holds this task until it lands.
- 439 says `history` and `--since` also read task-batch records → out of scope here; 439 (which depends on this task) extends the reader. Decided line in Notes.
- No `history` command, `help/history.md` or `docs/tests/test-history.sh` exists → all new; a new command row changes the four command surfaces together, which Done when already names.

## Questions

**Status: READY**

### Already complete
None — no matching implementation found.
- `docs/sprintbias/help/_registry` and `sprint.sh`: no `history` command.
- `docs/sprintbias/help/history.md`, `docs/tests/test-history.sh`, `docs/history/`: absent.
- `plan-done.sh` still deletes the plan file (task 421 pending).
- The repo has `v0.0.*` tags, so the git-ref form of `--since` is testable here.

### Remaining work
- `history`: newest-first list of plan records (date, plan id, title).
- `history --since <date|ref>`: Markdown notes, one `###` per plan with the Goal's first sentence and its `What changed` lines; a date filters on `**Finished**`, a ref compares `docs/history/` trees; a bad ref errors; an empty range prints a notice and exits 0; writes nothing.
- New `docs/tests/test-history.sh` with fixture records covering date, ref (two same-day records split by a commit), empty range and bad ref.
- Surfaces: `_registry`, `help/history.md`, `DOCUMENTATION.md`, `command-matrix.md`; one `### Added` CHANGELOG bullet.

### Questions for the developer
None — task is fully defined.

## Completed

**Summary**: New `./sprint.sh history` lists finished plans from `docs/history/` newest first, and `history --since <date or git ref>` prints Markdown release notes for the plans finished since then.

### Assumptions
- Decided: the notes heading is the plan title alone (`### <title>`), without "Plan N", because a release-note reader does not know plan ids; the bare list keeps the id for the timeline view.
- Decided: each What changed line drops its leading `#ID — ` and trailing `(docs/tasks/done/…md)` path, because both are internal pointers; the line reads `- <task title>: <summary>`.
- Decided: notes carry Goal and What changed only, not Decided or Follow-ups, because the task names those two and the rest is history, not release news.
- Decided: a record with no `**Finished**` line sorts as `0000-00-00` (oldest), so a hand-edited record still lists rather than vanishing.
- Decided: `--since` with no value or any unknown argument prints an error and the usage line and exits 1.

### Files changed
docs/sprintbias/scripts/history.sh
docs/sprintbias/help/history.md
docs/sprintbias/help/_registry
sprint.sh
docs/tests/test-history.sh
DOCUMENTATION.md
docs/guides/command-matrix.md
CHANGELOG.md

Tests run: `bash docs/tests/test-history.sh` (20 pass), `./sprint.sh validate --commands`, `./sprint.sh validate --docs`, `bash docs/tests/run-all.sh` (36/36 scripts), plus `./sprint.sh history --since v0.0.105` in this repo (no records yet: notice, exit 0).

**Breaker**: 9 cases tried · 2 fixed · 0 filed
- Fixed: a Goal with "e.g." was cut at the abbreviation ("Users get faster installs, e.g."); a sentence now ends at . ! ? before a space and a non-lowercase character.
- Fixed: a CRLF (hand-edited on Windows) record lost its Goal and What changed and leaked `\r` into the title; every reader now strips a trailing `\r`.
- Held: real `plan done` round trip, version dots (`v0.2.`), record without `**Finished**`, run twice, SprintBias in a subfolder of a larger git repo with a ref, neighbor `test-plan-lifecycle.sh`.

**Proof**: 2026-10-11 · bash docs/tests/test-history.sh (49 pass); bash docs/tests/test-plan-lifecycle.sh · pass
