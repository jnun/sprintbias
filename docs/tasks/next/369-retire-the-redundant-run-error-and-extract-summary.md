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
`sprintbias_extract_summary` each re-parse the JSON that the interpreter already
read — a second and third place for provider shape knowledge to live. This task
removes those redundant reads so the interpreter is the single source of truth,
and locks in #367's already-centralized failure-kind naming so no per-site prose
match can creep back.

## Success criteria

- [ ] `sprintbias_run_error` and `sprintbias_extract_summary` are removed from
      lib.sh (their work is folded into the interpreter's single pass — summary
      now comes off the normalized record).
- [ ] Every call site (polish.sh --code + deep-judge, polish-judge.sh, deps.sh,
      and the promote.sh audit path) reads the run exactly once via the
      interpreter: it switches on `outcome`, uses the record's `summary`, and
      parses its own verdict tokens on `finished`. No site parses the log JSON a
      second time.
- [ ] No call site re-derives a failure kind by prose-matching a run's error
      text — the shared honest-message builder from #367 (`sprintbias_run_hint`)
      remains the only thing that renders a user-facing outcome line. (Dep #367
      already centralized this; the criterion is here to keep it that way once
      the old helpers are gone.)
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

## Questions

**Status: READY**

### Already complete

The interpreter and honest-message builder this task retires the old machinery
in favor of are shipped (deps 367/368, both in review/):
- `sprintbias_interpret_run` + profile dispatch — lib.sh:2334. All three
  profiles implement `profile_interpret_run` and populate the normalized record,
  including `SPRINTBIAS_RUN_SUMMARY` (claude.sh:560-570, grok.sh:292-302,
  default.sh:72-83). So "summary off the record" is executable at every site now.
- `sprintbias_run_hint` shared honest-message builder — lib.sh:2385.

Two of the four+1 call sites are already fully migrated (one read, switch on
outcome, own verdict parse, no second JSON read):
- `deps.sh:342` — clean.
- `polish.sh` refine router `_route_refine:1149` — clean.

`polish.sh --code` (line 563) and `polish-judge.sh` (line 294) already read via
the interpreter and use `sprintbias_run_hint` on the abort path — but each still
does a second read for the summary (see Remaining work).

### Remaining work

The retirement is not done — both helpers still exist and have live callers:

- Fold summary extraction into the interpreter's single pass, then delete
  `sprintbias_extract_summary` (lib.sh:2244) and `sprintbias_run_error`
  (lib.sh:2285). The fallback interpreter's second read at lib.sh:2372 must fold
  the extraction inline (the profiles already do their own summary).
- Replace the second-read summary calls with the record's `$SPRINTBIAS_RUN_SUMMARY`:
  `polish.sh:676` (PREV_SUMMARY) and `polish-judge.sh:339` (SUMMARY).
- Migrate the `promote.sh` audit path (line 347) off `sprintbias_run_error`: it
  should switch on `SPRINTBIAS_RUN_OUTCOME` from the interpreter and render its
  line via `sprintbias_run_hint`. (This call site was not in the original
  enumeration; criterion 2 now names it. Note `promote --audit` is a live path
  here even though a broader promote-audit gate is backlog task 373 — this task
  only migrates the existing helper call, it does not build 373's feature.)
- Grep `docs/sprintbias/` for both helper names (including help text and
  comments describing the old flow) and confirm zero references remain.
- Verify all audits behave identically to before for finished / max_turns /
  no_start / error on captured logs per provider.

### Questions for the developer

None — task is fully defined.

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
