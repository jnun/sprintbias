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

## Questions

**Status: COMPLETE**

### Already complete

All five success criteria are implemented, validated, and already mirrored to
`src/` (both `promote.sh` and `accept.md` diff byte-clean against their `src/`
counterparts).

- `promote --audit` mode: `docs/sprintbias/scripts/promote.sh:149-365`. Sweeps
  every `review/` task (or a single `[id]` via the same gather loop as the
  default mode, lines 67-85), judges each independently — headless one judge per
  task at lines 298-353, or handed to the surrounding agent in emit mode at
  220-281 with a fresh subagent context per task. Prints a per-task
  `DONE / NOT-DONE — reason` verdict (321-352) and a closing tally (355-363).
- Report-first: `--move` gates the actual `git mv`. Without it, DONE tasks print
  "would move to done/ (re-run with --move)" and nothing moves (331-338); the
  summary points at the exact `--audit --move` re-run (361). `--move` outside
  `--audit` is rejected with guidance (58-62).
- Default test-gated mode is untouched (367-508) and remains a distinct branch.
  The **Depends on** close-gate (`task_held_by`, 110-125) applies in audit mode
  too: a DONE task with an open prerequisite is held, not moved (322-330).
- Protocol `docs/sprintbias/ai/accept.md` exists (72 lines) and frames the bar
  as acceptance — explicitly separated from correctness and excellence. The mode
  honors the emit/headless dual structure and model/provider resolution:
  `sprintbias_ai_mode`, `sprintbias_tier_model ACCEPT` (config key `MODEL_ACCEPT`,
  `config:58`), and budget wiring `SPRINTBIAS_BUDGET_AUDIT` (`lib.sh:2419`,
  `config:72`).
- Surfaces all reflect the mode: `help/promote.md` (Acceptance audit section),
  `_registry:40`, `docs/guides/command-matrix.md:132-133`, and
  `DOCUMENTATION.md:111,220`. `./sprint.sh validate --commands` and `--docs` both
  pass clean.

Implementation looks correct and clean, including the NOT-DONE-contains-DONE
substring guard (317-319) and the multibyte em-dash reason strip (342).

### Remaining work

None — the work is fully landed and shipped.

### Questions for the developer

None — task is fully defined.

<!--
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->
