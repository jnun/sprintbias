# Task 443: Work finds and fixes edge cases a task never names

**Feature**: none
**Created**: 2026-10-10
**Docs**: none
**Plan**: none
**From plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-edge-cases.sh, docs/tests/test-profile.sh
**Refined**: 0
**Reworked**: 0

## Problem

`./sprint.sh work` takes a task's example literally. Workers test only the cases
the task lists, never try to break their own change, and park gaps they see in
Decided or Assumption lines (sometimes filed, sometimes not). Two baseline demos
scored 8/11 and 5/11 on hidden edge-case keys; task 397 recorded a failing case
as an Assumption. Users get landed work that breaks on the next input their own
docs promise.

## Done when (automated)

- [x] One shared edge-cases fragment (lib.sh) appears once in the gate, work
      (exec + emit) and crew prompts: `bash docs/tests/test-edge-cases.sh`
- [x] The proof rule asks for an assertion per Done when case and realistic
      edge case, fixes or files failures, and keeps known failures out of
      Decided/Assumptions: `bash docs/tests/test-edge-cases.sh`
- [x] A breaker step runs by default after a task lands in work (exec and both
      emit prompts); BREAK=off and `work --no-break` skip it:
      `bash docs/tests/test-edge-cases.sh`
- [x] `promote --reject` appends a ## Known edges line to the project map when
      one exists; orient points agents at it; `profile check` ignores the
      section and warns over 15 lines: `bash docs/tests/test-edge-cases.sh`
- [x] A follow-up struck as `- [x] ~~text~~ reason (from #N)` is not re-filed:
      `bash docs/tests/test-profile.sh`
- [x] Full suite and catalog checks pass: `bash docs/tests/run-all.sh`,
      `./sprint.sh validate --commands`, `./sprint.sh validate --docs`

## Signoff (human)

- [ ] Re-run the two edge-case demos (orchestrator) and compare scores to 8/11 and 5/11.

## Notes

- Decided: scope is the example's class — a worker covers the whole class the task's example belongs to, within the code path it changes, including the input forms the project's own docs/UI/examples promise; gaps in other code paths are filed with ./sprint.sh newtask carrying the failing case, because a mention alone is lost.
- Decided: a found defect is fixed or filed, never parked in Decided/Assumptions, because Decided records a choice between working options and "works only when X" is an untested case.
- Decided: an independent breaker runs by default after a task lands (exec and both emit prompts), off with BREAK=off in config or work --no-break, with MODEL_BREAK / BUDGET_BREAK keys and bounded turns, because a fresh context finds what the author's context hides.
- Decided: promote --reject appends one line to the project map's ## Known edges (when a map exists), orient tells agents to test those that touch their change, and profile check excludes the section and warns over ~15 lines, because rejected cases are the project's best edge-case memory.
- Decided: the drift-check COMPLETE shortcut lands without a breaker run, because that path changed no code this run.

## References

docs/sprintbias/lib.sh
docs/sprintbias/scripts/work.sh
docs/sprintbias/scripts/gate-lib.sh
docs/sprintbias/scripts/promote.sh
docs/sprintbias/scripts/profile.sh

<!-- sb:hint  After work only — audit trail of what was touched. Helps committers,
     later audits, and "what broke?" recovery. List the product files you
     edited to complete the task — one repo-relative path per line. Leave this
     task file out: its folder location and git history already track it. Copy
     the two headings below to column 0
     (UNINDENTED — they are indented here only so a fresh, unworked task is not
     mistaken for a finished one), then list the paths under "Files changed":

       ## Completed

       **Summary**: <one plain sentence: what changed, for someone reading
       the project's history>

       ### Files changed
       docs/sprintbias/scripts/example.sh
       docs/sprintbias/help/example.md

     When the work rests on something only a person can confirm (a device,
     a live account), add under ## Completed; it joins the plan's human test:

       ### Assumptions
- Decided: in an AI session promote prints the polish --break command(s) to run first and moves nothing, because promote itself stays shell and the agent runs the breaker.
- Decided: a breaker crash or timeout stamps "**Breaker**: not run" and signs off, because sign-off must never block on a tool failure; polish --break re-runs it.
- Decided: run_with_timeout now kills its watcher's sleep before the watcher, because the orphaned sleep held $(…) output open for the full timeout.
- Decided: polish --break counts only tasks that lost a Proof line this run, because done/ tasks often carry none and would read as failures.
- Decided: post-landing steps (breaker, --audit, --excellence) run on a task this run landed whether the worker moved it to review/ or the router did, because real workers move it themselves (demo 1 v1); the drift-COMPLETE shortcut stays excluded, because it changes no code.
- Decided: a scope-out Decided line without #N or "task N" is listed as an Unfiled gap in the end-of-run checklist, because demo 2 v1 deferred an in-class choice and filed nothing.
       - The scanner sends one line per barcode

     When the work made a source of truth wrong and updating it is out of
     scope (or it is a governing source), add under ## Completed:

       ### Doc follow-ups
       - `docs/GLOSSARY.md` — add "plan"; the code now uses it

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. Do not fill this before work. -->

<!-- sb:hint
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->

## Completed

**Summary**: `work` now tests the class a task's example stands for (one shared edge-cases list in the gate, worker, crew and a new default breaker step), rejected cases feed the project map's Known edges, and struck doc follow-ups are no longer re-filed.

### Files changed
docs/sprintbias/lib.sh
docs/sprintbias/scripts/work.sh
docs/sprintbias/scripts/gate-lib.sh
docs/sprintbias/scripts/promote.sh
docs/sprintbias/scripts/profile.sh
docs/sprintbias/config
docs/sprintbias/help/work.md
docs/sprintbias/help/promote.md
docs/sprintbias/help/profile.md
docs/sprintbias/help/polish.md
docs/sprintbias/help/_registry
docs/sprintbias/scripts/polish.sh
docs/sprintbias/scripts/crew.sh
docs/sprintbias/help/crew.md
GETSTARTED.md
docs/tests/test-promote.sh
docs/tests/test-next-action.sh
docs/tests/test-learning-demos.sh
docs/sprintbias/learning/work.py
docs/tasks/.TEMPLATE-task.md
DOCUMENTATION.md
docs/guides/command-matrix.md
CHANGELOG.md
docs/tests/test-edge-cases.sh
docs/tests/test-profile.sh
docs/tests/test-proof-loop.sh
docs/tests/test-tasks-excellence.sh
docs/tests/test-finish-rule.sh
docs/sprintbias/scripts/edges.sh
sprint.sh
docs/sprintbias/help/status.md
docs/guides/field-trial.md

### Field trial (2026-10-11)
- `status --edges [plan:N]` (edges.sh, no AI): caught (Breaker lines) vs found by you (**Fixes** tasks from --reject and human tests), split breaker vs no breaker, catch rate, cost, escapes listed by their report.
- `promote --reject` takes a done/ task found broken later (linked fix, Known edge, nothing held).
- Breaker cost stamped on its line (stream-json result); BREAK_MAX_TURNS / BREAK_TIMEOUT config keys.
- Parallel breakers run in lanes: tasks sharing a code file in ### Files changed run in turn; a free-slot pool (bash 3.2 safe). `polish --break plan:N` uses it and checks unchecked members only.
- `promote` runs a Tests file as the project does (`sprintbias_test_cmd`, config TEST_RUN); before, `.py` Tests always failed under bash.
- Verified on a scratch ship + setup into a copy of heavymetal (update 0.0.137 → 0.0.138, config kept): plan 67's 11 tasks ran in 5 lanes with a stub CLI, no lane overlap, 14 s vs 22 s serial; status --edges and --reject on done/ checked there.
- Gap filed: #449 (Tests values with arguments).

### Assumptions
- Decided: the crew landing path carries the edge-case list through the proof rule but runs no separate breaker, because decision 3 names the work exec and emit paths and a crew member already lands through its own session.
- Decided: a Known edges line is the reject report as written (bullets joined, 200 chars max) plus `(#id)`; help asks people to phrase it as "class: case", because a no-AI step cannot classify the report.
- Decided: setup.sh's MODEL_* migration list is left alone (it is outside docs/); a missing BREAK / MODEL_BREAK / BUDGET_BREAK key falls back to on / tier default / $2.

**Proof**: 2026-10-11 · bash docs/tests/test-edge-cases.sh, bash docs/tests/test-promote.sh, bash docs/tests/test-profile.sh, bash docs/tests/run-all.sh, ./sprint.sh validate --commands, ./sprint.sh validate --docs · pass
