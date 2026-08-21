# Task 368: Implement profile_interpret_run for grok and default profiles including the no-JSON case

**Feature**: none
**Created**: 2026-08-20
**Docs**: none
**Plan**: 22
**Depends on**: 367
**Dependents**: 369
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

The single-pass interpreter from #367 makes run outcomes honest on the Claude
path, but grok and default still fall back to Claude-shaped JSON parsing. That is
wrong for both: `grok --output-format json` (buffered) emits Grok's own schema,
not verified to carry `is_error`/`subtype`/`result`; and `default.sh` drops
`--output-format` entirely, so its log is plain text with no result object at
all — a max_turns abort under the default profile is silently invisible today
(`is_error` never fires, the non-JSON log is treated as "finished"). This task
gives each non-Claude profile its own `profile_interpret_run` so the honest
outcome and message become provider-correct everywhere, and records the no-JSON
profile as a first-class case rather than a Claude-shape assumption.

## Success criteria

- [ ] `grok.sh` implements `profile_interpret_run`, reading whatever shape
      `grok --output-format json` actually emits for a buffered run (verify the
      real schema before mapping; do not assume Claude keys) and filling the
      normalized record's outcome/verdict_text/turns/cost/summary. If a field is
      genuinely unavailable, it is reported as unknown, not faked.
- [ ] `default.sh` implements `profile_interpret_run` for the no-JSON case: it
      derives `outcome` from the run without a result object — empty log →
      no_start, non-zero rc → error, otherwise finished — and preserves the raw
      stdout as `verdict_text` and a `summary` (tail), so the shared honest
      message and verdict grep still work on a plain-text log.
- [ ] Under the default profile, a run that fails or produces no output is no
      longer reported as "finished"; the honest outcome/message from #367 now
      fires there too.
- [ ] The same outcome tokens and message vocabulary from #367 hold across all
      three profiles — one honest line per outcome, identical wording, whichever
      CLI ran.

## Notes

- default.sh has no structured result, so cost/turns are legitimately unknown
  there — the record must represent "unknown" honestly rather than printing a
  fake 0. Confirm how #367's hint builder renders an unknown cost/turns.
- Whether grok's buffered `json` even carries a usable result/verdict is a known
  unknown flagged by audit 364 — resolve it here (check `grok --help` / a real
  captured log) and record the finding in docs/guides/provider-reality.md.
- Keep to result interpretation. Do not add JSON output to default.sh or change
  what flags a profile forwards — that is a separate capability decision, not
  this task.

## References

docs/sprintbias/cli/grok.sh
docs/sprintbias/cli/default.sh
docs/sprintbias/lib.sh
docs/guides/provider-reality.md
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
