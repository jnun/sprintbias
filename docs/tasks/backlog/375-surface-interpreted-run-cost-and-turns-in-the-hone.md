# Task 375: Surface interpreted run cost and turns in the honest abort line and audit records

**Feature**: none
**Created**: 2026-08-21
**Docs**: none
**Plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

Task 367 introduced `sprintbias_interpret_run`, whose stated purpose is that
"every audit learns the outcome (and cost/turns/summary) from one read." The
interpreter faithfully captures `SPRINTBIAS_RUN_TURNS`, `SPRINTBIAS_RUN_COST`,
and `SPRINTBIAS_RUN_SUMMARY` on every run — but no call site reads them. Only
`SPRINTBIAS_RUN_VERDICT_TEXT` and `SPRINTBIAS_RUN_OUTCOME` are consumed. The
run size the interpreter paid to collect dead-ends in globals.

The visible cost of this: the shared honest abort line
(`sprintbias_run_hint`) says "hit its turn limit before finishing" with no
mention of how many turns, how long, or how much it cost — even though those
numbers are one variable away. The interim `sprintbias_run_error` that 367
supersedes DID surface "(N turns, Mm SSs, $X.XX)", so the run-mechanics
diagnostics actually got less informative in the transition. An operator
staring at a max_turns abort cannot tell whether it burned 30 turns and $0.10
or ran away to $3, which is exactly the signal they need to decide whether to
raise `SPRINTBIAS_AUDIT_MAX_TURNS` or narrow scope.

## Success criteria

- [ ] A max_turns / error abort reported by an audit (deps.sh, polish.sh
      `--code`, polish-judge.sh, `_route_refine`) shows the run's turns and
      cost when the interpreter captured them — the numbers already sit in
      `SPRINTBIAS_RUN_TURNS` / `SPRINTBIAS_RUN_COST` after
      `sprintbias_interpret_run`.
- [ ] The `## Audit (aborted …)` record polish.sh `--code` appends includes
      the run's turns/cost alongside the existing outcome/mode/edits fields.
- [ ] The turns/cost render degrades cleanly when a field is empty
      (best-effort per the interpreter contract) — no bare "( turns, $)".
- [ ] `SPRINTBIAS_RUN_SUMMARY` either gets a consumer or the decision to keep
      it capture-only is recorded, so the record's contract matches what
      callers actually use.

## Notes

Keep the run-mechanics vocabulary shared: the cleanest fix is to let
`sprintbias_run_hint` (or a small sibling) fold the captured turns/cost into
its line, rather than each site re-formatting them — that preserves 367's
"one honest line, identical across sites" goal. Verdict tokens stay
caller-owned as before.

Do not reintroduce a second JSON read to get the numbers — they are already
in the interpreter's globals; this is purely a display-wiring change.

## References

docs/sprintbias/lib.sh
docs/sprintbias/cli/claude.sh
docs/sprintbias/scripts/polish.sh
docs/sprintbias/scripts/deps.sh
docs/sprintbias/scripts/polish-judge.sh
docs/tasks/review/367-add-a-profile-owned-single-pass-run-interpreter-an.md

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
