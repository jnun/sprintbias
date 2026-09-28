# Task 367: Add a profile-owned single-pass run interpreter and shared honest-message builder

**Feature**: none
**Created**: 2026-08-20
**Docs**: none
**Plan**: 22
**Depends on**: none
**Dependents**: 368, 369, 371
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

Every headless audit reads a run's result three separate times — grep the text
for a VERDICT token, python-parse the JSON for `is_error`, python-parse the same
JSON again for a summary — then re-derives the failure kind downstream by
string-matching the human-readable error message. There is no single place that
answers "what happened to this run?" This task introduces that place: a
profile-owned single-pass interpreter plus one shared honest-message builder, so
every audit learns the outcome (and cost/turns/summary) from one read and speaks
one honest line per outcome. Landing this first fixes the trust bug (a max_turns
abort mislabeled "could not parse a verdict") on the Claude path immediately,
without disturbing the other providers.

Audit 364 (plan 22) settled the mechanism; this is its first follow-on.

## Success criteria

- [x] `sprintbias_interpret_run LOG [rc]` exists in lib.sh and returns a
      normalized record with an `outcome` token in
      {finished|max_turns|no_start|error} plus `verdict_text` (the run's result
      text for token parsing), `turns`, `cost`, and `summary`. It dispatches to
      the active profile's `profile_interpret_run` when defined, and falls back
      to today's Claude-shaped `is_error`/`subtype` logic when a profile has not
      yet implemented one (so grok/default keep current behavior until 368).
- [x] `claude.sh` implements `profile_interpret_run`, parsing the Claude result
      JSON exactly once to fill the record (maps `error_max_turns` → max_turns,
      `error_during_execution` → error, empty/absent log → no_start, clean →
      finished).
- [x] One shared `sprintbias_run_hint` (or equivalent) turns an outcome token
      into a single honest, actionable line — identical across sites — covering
      max_turns ("raise --max-turns or narrow scope"), no_start ("check CLI
      install/auth"), error ("inspect the log"), and finished-but-no-verdict ("a
      formatting slip, not a crash"). Verdict tokens stay caller-owned; only the
      run-mechanics vocabulary is shared.
- [x] The four call sites (polish.sh --code, polish.sh deep-judge, polish-judge.sh,
      deps.sh) switch on the interpreter's `outcome` and use the shared hint;
      each still parses its own verdict token set on `outcome=finished`. No
      change to prompts, turn caps, or loop/salvage behavior (that is #366, not
      this plan).
- [x] Behavior on Claude is unchanged for clean runs and improved on aborts (the
      honest max_turns line replaces the "could not parse a verdict" mislabel).

## Notes

- Verdict token sets are per-audit and stay caller-owned: PASS|FIXED|FAIL|BLOCKED
  (--code), PASS|REOPEN|BLOCKER (deep-judge), EXCELLENT|FILED|BLOCKER (excellence
  sweep), FILED|CLEAN (deps). The interpreter normalizes run mechanics only —
  it hands back the result text; the caller greps its own tokens from it.
- The trap 364 named: do not let this fast message win re-entrench the Claude
  JSON shape. The profile fallback is a bridge for grok/default until 368 ports
  them, not the permanent home of shape knowledge.
- All four sites currently run the CLI with `... 2>/dev/null | tee "$LOG_FILE"`,
  so the profile's own "dropped flag" / retry warnings are already silenced —
  keep the interpreter reading the log file, not stderr.
- This supersedes the interim `sprintbias_run_error` helper; 369 removes it once
  every site is on the interpreter.

> **Context from chat (task 371):** 371 (polish --code salvage) is a hard
> consumer of your two outputs. It needs (a) the `outcome` token to
> distinguish `max_turns` from `error`/`no_start` on its own — the salvage
> branch triggers on any real abort, so a single "aborted" signal is enough,
> but keep the token honest per-mechanic rather than collapsing to a boolean;
> and (b) the shared honest-message builder to be callable for the abort
> recovery line *without* dictating the next-step lever — 371 supplies its own
> lever copy ("re-run --code", budget bump last). So keep the builder's hint
> text caller-supplied or overridable, not hard-coded to the current
> `SPRINTBIAS_AUDIT_MAX_TURNS=60` message. 371 stays Claude-correct on your
> landing alone and inherits grok/default from 368 — you don't need to wait
> on 368 for 371's sake.

## References

docs/sprintbias/lib.sh
docs/sprintbias/cli/claude.sh
docs/sprintbias/scripts/polish.sh
docs/sprintbias/scripts/polish-judge.sh
docs/sprintbias/scripts/deps.sh
docs/tasks/doing/364-audit-the-headless-audit-run-result-interpretation.md
docs/plans/22-fix-the-audit-run-result-interpretation-mechanism.md

## Questions

**Status: READY**

### Already complete
None — no matching implementation found. What I checked:
- `sprintbias_interpret_run`, `sprintbias_run_hint`, and `profile_interpret_run`
  do not exist anywhere under `docs/sprintbias/` (grep clean).
- `claude.sh` defines only `sprintbias_provider_exec` (line 131) and
  `sprintbias_provider_interactive` (line 336) — no `profile_interpret_run`, and
  the profile-dispatch hook this task adds to lib.sh has no counterpart yet.
- The interim helpers this task supersedes are present and still in use:
  `sprintbias_run_error` (lib.sh:2009) and `sprintbias_extract_summary`
  (lib.sh:1963). `sprintbias_run_error` already carries the Claude-shape
  `is_error`/`subtype`/`error_max_turns`/`error_during_execution` logic the
  fallback will reuse.
- The downstream string-matching the Problem names is real: polish.sh:1036–1039
  greps `*"turn limit"*` / `*"failed to start"*` off the human-readable message
  to re-derive the failure kind. The `outcome` token replaces exactly this.

### Remaining work
All four success criteria are unimplemented and clear to execute:
- Add `sprintbias_interpret_run LOG [rc]` to lib.sh: normalized record with
  `outcome` in {finished|max_turns|no_start|error} plus `verdict_text`, `turns`,
  `cost`, `summary`. Dispatch to `profile_interpret_run` when the active profile
  defines it; else fall back to today's Claude-shaped `is_error`/`subtype` logic
  (keeps grok/default working until 368).
- Add `profile_interpret_run` to `claude.sh`, parsing the result JSON once
  (`error_max_turns`→max_turns, `error_during_execution`→error, empty/absent
  log→no_start, clean→finished).
- Add one shared `sprintbias_run_hint` that turns an outcome token into a single
  honest line (max_turns / no_start / error / finished-but-no-verdict). Keep the
  next-step lever text caller-supplied/overridable — 371 supplies its own lever
  copy and must not inherit the hard-coded `SPRINTBIAS_AUDIT_MAX_TURNS=60`
  message (see the task-371 context note).
- Switch the four sites — polish.sh --code (539), polish.sh deep-judge (1034),
  polish-judge.sh (200), deps.sh (341) — to branch on `outcome` and use the
  shared hint; each keeps parsing its own verdict token set on
  `outcome=finished`. No change to prompts, turn caps, or loop/salvage behavior.
- Keep the interpreter reading the log file (not stderr) — all four sites already
  run `... 2>/dev/null | tee "$LOG_FILE"`.
- Leave `sprintbias_run_error`/`sprintbias_extract_summary` in place; 369 retires
  them once every site is on the interpreter. (Note: promote.sh:347 also calls
  `sprintbias_run_error` but is outside this task's four sites — 373/369 own it,
  not this task.)

### Questions for the developer
None — task is fully defined.

## Completed

Added a single-pass, profile-owned run interpreter and one shared honest-message
builder, then moved all four headless-audit sites onto them.

- `sprintbias_interpret_run LOG [rc]` (lib.sh) dispatches to the active profile's
  `profile_interpret_run` when defined, else a self-contained fallback. It sets a
  normalized record via globals `SPRINTBIAS_RUN_OUTCOME`
  (finished|max_turns|no_start|error), `SPRINTBIAS_RUN_VERDICT_TEXT`,
  `SPRINTBIAS_RUN_TURNS`, `SPRINTBIAS_RUN_COST`, `SPRINTBIAS_RUN_SUMMARY`.
- `claude.sh` implements `profile_interpret_run` — one JSON parse emitting five
  NUL-delimited fields (kept in `_SPRINTBIAS_INTERPRET_PY` and run with
  `python3 -c`, matching `_SPRINTBIAS_STREAM_FILTER`; a here-doc nested in the
  process substitution mis-parses under `set -e`). Maps `error_max_turns` →
  max_turns, `error_during_execution` → error, empty/absent log → no_start,
  clean → finished; non-JSON log → finished so raw text still greps a verdict.
- The lib.sh fallback (`_sprintbias_interpret_run_fallback`) reproduces today's
  Claude-shaped `is_error`/`subtype` reading for grok/default until 368 ports
  them; it reuses `sprintbias_extract_summary`. Documented as a bridge, not the
  permanent home of shape knowledge.
- `sprintbias_run_hint OUTCOME [lever]` emits one honest, actionable line for
  max_turns / no_start / error / no_verdict, with a per-outcome default lever
  that a caller (e.g. 371) can override — never hard-coded to the
  `SPRINTBIAS_AUDIT_MAX_TURNS=60` message.
- Call sites switched to branch on `outcome` and use the shared hint, each still
  parsing its own verdict token set from `SPRINTBIAS_RUN_VERDICT_TEXT` on
  `outcome=finished`: polish.sh `--code` (loop + post-loop ERROR report),
  polish.sh deep-judge (`_route_refine`), polish-judge.sh, deps.sh. The three
  `OUTPUT=$(... | tee)` captures became plain `>"$LOG_FILE"` redirects (the
  captured stdout was only ever used for the now-removed verdict grep). No
  change to prompts, turn caps, or loop/salvage behavior.
- Left `sprintbias_run_error`/`sprintbias_extract_summary` in place (369 retires
  `sprintbias_run_error`; promote.sh's remaining call is out of this task's scope).

Verified with synthetic logs under `bash -euo pipefail`: clean→finished(PASS,
turns/cost/summary populated), max_turns, error, empty→no_start, non-JSON→
finished with a greppable verdict, plus the fallback path (profile undefined).
`bash -n` and `shellcheck -S error` clean on all five files. Not yet mirrored to
`src/` — `./ship.sh` is the developer's release step and would sweep in other
pending `docs/` changes.

### Files changed
docs/sprintbias/lib.sh
docs/sprintbias/cli/claude.sh
docs/sprintbias/scripts/polish.sh
docs/sprintbias/scripts/polish-judge.sh
docs/sprintbias/scripts/deps.sh

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

## Excellence

- **Date**: 2026-08-21
- **Verdict**: FILED
- **Tasks filed**: 1
- **Files reviewed**: 7
- **Context source**: task ## Completed section

Task 367 introduces `sprintbias_interpret_run` (a profile-dispatched single-pass run reader), `sprintbias_run_hint` (one shared honest-message builder), and Claude's `profile_interpret_run`, then moves every headless-audit site (deps.sh, polish.sh `--code`, polish-judge.sh, `_route_refine`) onto them. It fully meets its goal: each site reads the run once, branches on a normalized `outcome` token, greps its own verdict set from `SPRINTBIAS_RUN_VERDICT_TEXT`, and the max_turns trust bug is genuinely fixed — an aborted run now says "hit its turn limit" instead of "could not parse a verdict." The design is clean: the Claude JSON shape lives in claude.sh, lib.sh's fallback is a clearly-labeled bridge, `ABORT_OUTCOME` is correctly snapshotted before a salvage read overwrites the globals, and the NUL-delimited read contract is robust. The one altitude gap: the interpreter captures `TURNS`, `COST`, and `SUMMARY` on every run, but no call site consumes them — and the honest abort line is actually less informative about run size than the `sprintbias_run_error` it supersedes.

### Findings
- [ENHANCEMENT] `SPRINTBIAS_RUN_TURNS`/`_COST`/`_SUMMARY` captured on every run (lib.sh:2047-2049, claude.sh:452-455) but read by no site; the shared abort line (`sprintbias_run_hint`, lib.sh:2108) omits turns/cost that `sprintbias_run_error` used to show — operators can't size a max_turns abort.
- FILED: docs/tasks/backlog/375-surface-interpreted-run-cost-and-turns-in-the-hone.md
- [NIT] The `no_verdict` branch of `sprintbias_run_hint` (lib.sh:2120) is unreachable — every site hardcodes its own finished-but-no-verdict copy (deps.sh:359-361, polish.sh:783). Defensive, documented; not worth filing.
- [NIT] The `[rc]` parameter is threaded through all three interpreter functions but never used ("accepted for future use") — spec-mandated by the task's own signature; not worth filing.
