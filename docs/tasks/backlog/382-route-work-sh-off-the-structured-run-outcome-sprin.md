# Task 382: Route work off the structured run outcome, not rc + grep

**Feature**: none
**Created**: 2026-09-03
**Docs**: none
**Plan**: none
**From plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-run-interpret.sh, docs/tests/test-proof-loop.sh, docs/tests/test-work-resume.sh
**Refined**: 1
**Reworked**: 0

## Problem

`work` decides where a finished task goes from the CLI exit code plus a grep for
`## Completed`. That cannot tell a crash from a turn cap, a spent budget, or a
clean run that forgot its write-up, so crashes get parked in `blocked/` as if a
person owed a decision (the 2026-09-03 incident). Under `loop` it is worse: a
crash `work` deliberately left in `doing/` is swept into `blocked/` after every
iteration. Every other runner already reads the structured outcome the CLI
profile produces; `work` and `loop` should too, and `blocked/` should mean only
"a person owes a decision".

## Done when (automated)

- [ ] The run interpreters read multi-line stream-json logs: they classify from
      the last `"type":"result"` event. `bash docs/tests/test-run-interpret.sh`
      asserts the right `SPRINTBIAS_RUN_OUTCOME` for multi-line logs of a clean
      finish, `error_during_execution`, `error_max_turns`, a spent budget, and
      an empty log, for the claude profile and the `lib.sh` fallback.
- [ ] `work` routes each finished task from `SPRINTBIAS_RUN_OUTCOME` plus the
      `## Completed` check: `finished` with `## Completed` → `review/` (the
      existing no-proof warning stays); `error` or `no_start` → stays in
      `doing/` stamped `failed`; spent budget → `blocked/` stamped `budget`
      ("hit the $N cap: raise BUDGET_WORK or split the task"), never resumed;
      `finished` without `## Completed` → one inline resume with a nudge to
      finish and write `## Completed` or say why not, then `blocked/` stamped
      `incomplete` if still missing. `bash docs/tests/test-proof-loop.sh`
      asserts each route with a stub CLI.
- [ ] Every `work` run first resumes tasks left in `doing/` (once each, in
      place, before scanning `next/`), and `loop` no longer moves `doing/`
      tasks to `blocked/` after an iteration. `bash
      docs/tests/test-work-resume.sh` (new) asserts both, and that a task in
      `doing/` resumed once and still unfinished ends stamped and not resumed
      again in that run.
- [ ] Retries decide "do not retry" from the result's `subtype` when the CLI
      gives one, so a run whose text merely mentions "budget" or "turns" is
      still retried. `bash docs/tests/test-run-interpret.sh` asserts it.
- [ ] Sequential and parallel runs route the same way, and the run journal's
      `routed` and `crashed` events carry the outcome value. `bash
      docs/tests/test-proof-loop.sh` asserts both modes.
- [ ] `bash docs/tests/run-all.sh` passes, and `bash
      docs/tests/smoke-live-dual-provider.sh` passes for Claude and Grok.

## Signoff (human)

None: the automated checks cover it.

## Notes

- Do the interpreter fix first. Today `_SPRINTBIAS_INTERPRET_PY`
  (`cli/claude.sh`) and `_SPRINTBIAS_FALLBACK_INTERPRET_PY` (`lib.sh`) call
  `json.loads` on the whole file and report `finished` when that fails, so
  routing `work` through them before the fix would send every crash to
  `review/`. `_SPRINTBIAS_RESULT_PARSE_PY` in `cli/claude.sh` already picks the
  last result line correctly; share that selection.
- Budget: confirm the real result shape of a spent `--max-budget-usd` run from
  a live log (likely `subtype: error_max_budget_usd`) and map it to its own
  outcome. `_SPRINTBIAS_NONRETRY_RE` matches `max-budget` with a hyphen, so the
  underscore subtype may slip through as retryable today.
- `work` passes no turn limit, so `max_turns` is rare on this path. Keep its
  outcome value; route it like `error`.
- Grok's interpreter has no `is_error` and maps `cancelled` to `max_turns`;
  keep the shared routing free of Claude-only fields.
- Keep the 2026-09-03 hotfix guards (honest exit code, location-aware moves,
  `|| true` around routing). This change swaps only the input to the routing
  decision.
- `loop.sh` has two `doing/` handlers: startup re-queues to `next/`, and each
  iteration sweeps to `blocked/`. Remove the per-iteration sweep and let the
  startup step defer to `work`'s resume.
- A task held in `doing/` reads as unfinished to `sprintbias_unmet_deps`, so
  its dependents keep waiting. That is correct.
- #381 (a `work --resume` journal reader) is closed in favor of the `doing/`
  resume here. Remove the "later gives `work --resume`" comment above the run
  journal in `work.sh`, and the "Follow-up open: `work --resume`" sentence in
  `docs/guides/provider-reality.md`.
- Update `docs/guides/provider-reality.md` (a dated note on the new routing
  and loop behavior), `help/work.md` and `help/loop.md` where they describe
  where failed tasks go, and add a `### Changed` bullet to `CHANGELOG.md`.
- #383 owns the `--max` budget value; this task owns what happens when a run
  spends its budget.

## References

<!-- sb:hint  Direct paths to docs or files known to be related. One path per
     line. Leave empty if none. -->

docs/sprintbias/scripts/work.sh
docs/sprintbias/scripts/loop.sh
docs/sprintbias/cli/claude.sh
docs/sprintbias/cli/grok.sh
docs/sprintbias/lib.sh
docs/guides/provider-reality.md

<!-- sb:hint  After work only — audit trail of what was touched. Helps committers,
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

<!-- sb:hint
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->
