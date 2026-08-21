# Task 369: Retire the redundant run_error and extract_summary reads and per-site prose matching

**Feature**: none
**Created**: 2026-08-20
**Docs**: none
**Plan**: 22
**Depends on**: 367, 368
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

Once every audit site reads a run through the single-pass interpreter (#367) on
every provider (#368), the old three-read machinery is dead weight that still
invites the Claude-shape coupling back in. `sprintbias_run_error` and
`sprintbias_extract_summary` each re-parse the JSON, and every call site still
carries a `case "$RUN_ERROR" in *"turn limit"*)` prose-match that re-derives the
failure kind the interpreter already names. This task removes the redundant
reads and the prose-matching so the interpreter is the single source of truth
and there is no second place for provider shape knowledge to creep back.

## Success criteria

- [ ] `sprintbias_run_error` and `sprintbias_extract_summary` are removed from
      lib.sh (their work is folded into the interpreter's single pass — summary
      now comes off the normalized record).
- [ ] Every call site (polish.sh --code + deep-judge, polish-judge.sh, deps.sh)
      reads the run exactly once via the interpreter: it switches on `outcome`,
      uses the record's `summary`, and parses its own verdict tokens on
      `finished`. No site parses the log JSON a second time.
- [ ] The per-site `case "$RUN_ERROR" in *"turn limit"* / *"failed to start"* …`
      prose-matching blocks are gone; the shared honest-message builder from
      #367 renders every user-facing outcome line.
- [ ] All four audits behave identically to before for finished/max_turns/
      no_start/error runs — verified on captured logs for each provider — with no
      remaining reference to the removed helpers anywhere in docs/sprintbias/.

## Notes

- This is the cleanup that makes the win permanent: with the redundant reads
  gone, the only place that knows a provider's result shape is that provider's
  `profile_interpret_run`. That is the anti-regression the whole plan exists for.
- Grep the whole tree (`docs/sprintbias/`) for `sprintbias_run_error` and
  `sprintbias_extract_summary` before finishing — no stragglers, including help
  text or comments that describe the old flow.
- Interpretation only. Do not fold in salvage-on-abort or fixer behavior — that
  is #366, a separate plan.
- Run `./ship.sh` is a release step handled by the maintainer, not this task;
  leave `src/` to the mirror.

## References

docs/sprintbias/lib.sh
docs/sprintbias/scripts/polish.sh
docs/sprintbias/scripts/polish-judge.sh
docs/sprintbias/scripts/deps.sh
docs/tasks/doing/364-audit-the-headless-audit-run-result-interpretation.md
docs/plans/22-fix-the-audit-run-result-interpretation-mechanism.md

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
