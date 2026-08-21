# Task 373: Add promote --audit: AI acceptance gate that closes review tasks to done

**Feature**: none
**Created**: 2026-08-20
**Docs**: none
**Plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

Nothing closes a batch of `review/` tasks to `done/` without a human moving each
one. `promote` only closes tasks whose **Tests** field names green suite scripts;
everything with `Tests: none` (the template default) waits for a manual `git mv`.
`polish` runs an AI judge per `review/` task but by contract never advances to
`done/`. A user who trusts an AI acceptance judgment wants a check that reads
each finished task, decides whether its Success criteria are actually met, and
closes the ones that pass — without hand-moving files one at a time.

## Success criteria

<!-- What done looks like. When these are met, the task is done.
     Observable checks anyone can verify. For a library or detailed technical
     fix, state the new technical needs as outcomes — still not a step outline. -->

- [ ] `./sprint.sh promote --audit` sweeps every `review/` task (or a single
      `[id]`), judging each independently in a fresh context for doneness against
      its own **Success criteria** and `## Completed` section, and prints a
      DONE / NOT-DONE verdict + one-line reason per task.
- [ ] The audit moves nothing by default — it reports. `promote --audit --move`
      (or a confirmed second step) is what actually `git mv`s DONE tasks
      `review/ → done/`. Auto-advancing to `done/` on an AI verdict stays behind
      an explicit flag, mirroring how `--dry-run` gates today.
- [ ] Default `promote` (pure-shell, test-gated) is unchanged: `--audit` is a
      distinct opt-in mode, and the existing **Depends on** close-gate still
      holds a DONE task whose prerequisite is still open.
- [ ] A new AI protocol file `docs/sprintbias/ai/accept.md` defines the doneness
      bar (acceptance, not excellence, not correctness), and the mode honors the
      emit/headless dual structure and provider/model resolution like `polish`.
- [ ] Help (`help/promote.md`), `_registry` usage string, command-matrix, and
      `DOCUMENTATION.md` all reflect the new mode; `./sprint.sh validate
      --commands` / `--docs` pass; `./ship.sh` mirrors to `src/`.

## Notes

- Chosen design (2026-08-20): fold into `promote`, not a new command and not a
  new `polish` verdict — `promote` is already the only `review/ → done/` surface,
  so fewer/sharper wins. Autonomy is report-first (`--move` to advance), because
  moving to `done/` on an AI judgment is a one-way door.
- Three distinct gates now share the lifecycle end: `promote` (default) asks
  "do the Tests pass?"; `polish` asks "is there a bounded gap worth another
  pass?"; `promote --audit` asks "are the Success criteria met?" Keep the
  doneness bar clearly acceptance-level — it must not drift into polish's
  excellence bar or re-litigate correctness.
- Crosses promote's stated invariant ("automation never guesses a task is
  done") on purpose — hence opt-in via `--audit`, never the default.

## References

<!-- Direct paths to docs or files known to be related. One path per line.
     Leave empty if none. -->

<!-- After work only — audit trail of what was touched. Helps committers,
     later audits, and "what broke?" recovery. List the product files you
     edited to complete the task — one repo-relative path per line. Leave this
     task file out: its folder location and git history already track it. Copy
     the two headings below to column 0
     (UNINDENTED — they are indented here only so a fresh, unworked task is not
     mistaken for a finished one), then list the paths under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintbias/scripts/example.sh
       docs/sprintbias/help/example.md

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. Do not fill this before work. -->

<!--
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->
