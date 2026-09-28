# Task 364: Audit the headless-audit run-result interpretation mechanism end to end

**Feature**: none
**Created**: 2026-08-20
**Docs**: none
**Plan**: 22
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

Every headless audit in SprintBias (polish sweep, polish deep-judge, polish
--code, deps) turns a model run into a decision by reading its result three
separate times: it greps the text for a VERDICT token, python-parses the JSON
for is_error, then python-parses the same JSON again for a summary. The failure
kind is then re-derived downstream by string-matching the human-readable error
message. The result-shape knowledge is hardcoded to Claude Code's JSON inside
lib.sh, so a non-Claude profile (grok, default) silently mis-diagnoses an
aborted run. Nobody has mapped the whole mechanism in one place or decided its
right shape, so fixes keep landing per-symptom. Before writing more code, settle
the mechanism top to bottom and hand the follow-on work a clear task list.

## Success criteria

- [x] One findings section maps every place a headless run's result is
      interpreted — verdict parse, error/abort detection, and summary extraction
      — across polish.sh (sweep + code), polish-judge.sh, and deps.sh, plus the
      result shape each CLI profile (claude.sh, grok.sh, default.sh) actually
      emits for buffered `--output-format json`.
- [x] A recorded decision on the target mechanism (single-pass, profile-owned
      "interpret run" returning a normalized record, vs. keep-and-patch), judged
      against the five lenses, naming the redundant-parse and provider-coupling
      costs.
- [x] Execute-ready follow-on task(s) are filed to backlog/ that implement the
      chosen mechanism — each small enough to `work`, ordered by dependency, and
      added as members of this plan.
- [x] The audit changes no product code itself; its only outputs are the
      findings, the decision, and the filed tasks.

## Notes

- Trigger: a `polish 1014` run aborted on max_turns and was mislabeled "could
  not parse a verdict." An interim fix already sits in docs/ (a
  `sprintbias_run_error` helper plus honest abort messages across the four
  sites), but it is Claude-shape-coupled and re-derives the failure kind by
  prose-matching. The audit should judge whether to supersede it.
- Candidate shape to validate (not assume): a profile-owned
  `profile_interpret_run LOG [rc]` that reads the result once and returns
  outcome=finished|max_turns|no_start|error plus verdict/turns/cost/summary;
  lib.sh dispatches to the active profile; call sites switch on the outcome
  token; one shared next-step-hint builder replaces the duplicated prose match.
- This is an audit: never edit product code (mirror the excellence-audit
  protocol). Per SprintBias convention, "done" for this task is the execute-ready
  follow-on tasks it produces, not just notes.
- Sibling #366 owns the product behavior (fixer action bias, finish inside
  the 30-turn cap, salvage on abort, which lever edits). This task owns
  result interpretation only — do not let follow-ons swallow prompt or
  loop behavior; do not add #366 as a member of plan 22.

## Plan Think

Dual-persona review (Chief Platform Architect / Chief Experience Officer). Both
read the live mechanism before judging: the three reads are real —
`sprintbias_run_error`, `sprintbias_parse_verdict`, `sprintbias_extract_summary`
fire in sequence at polish.sh, polish-judge.sh, and deps.sh — and lib.sh's
error path is hardcoded to Claude's JSON (`is_error`, `subtype`, `errors`,
`duration_ms`, `total_cost_usd`) with the failure kind re-derived by prose.

**Perspective check.**
- *Architect* loves this task on sight: it is the "map the mechanism once, fix
  its shape" move that ends the per-symptom patch cycle. What the Architect
  pushes for is that the decision record name the *interface contract*
  precisely — the exact outcome tokens (finished|max_turns|no_start|error) and
  the exact normalized fields (verdict/turns/cost/summary) — so the follow-on
  tasks inherit a spec, not a vibe. And that the per-profile shape inventory be
  literal: not "which JSON keys differ," but "what each profile actually emits."
  That matters because `default.sh` emits **no JSON at all** (plain text, and
  the interim helper treats a non-JSON log as "finished"), while `grok.sh` maps
  to Anthropic Messages NDJSON — "Claude-shaped result events." So the coupling
  is worse than a key-name mismatch: one profile has no structured result to
  interpret. The Architect wants that recorded as a first-class case.
- *CXO* reads the trigger — a max_turns abort mislabeled "could not parse a
  verdict" — as a **trust bug**: the tool lied about what happened to the user.
  The CXO pushes for the audit to treat the user-facing message vocabulary (the
  shared next-step-hint builder) as a named deliverable, not a side effect of
  the refactor: every outcome should produce one honest, actionable line ("hit
  its turn limit — raise --max-turns or narrow scope"), identical across
  providers. The CXO pushes back on any framing that makes this purely internal
  architecture and forgets the human reading the error.

**Tension and resolution.** The one disagreement is scope and timing of the
follow-on work. The Architect's instinct is a clean, complete profile-owned
interpreter that may touch every site at once; the CXO wants the misleading
message gone now, everywhere. These converge rather than compete — the
single-pass, profile-owned interpreter is *the* thing that makes messages both
honest and provider-correct, so there is no real backend-vs-UX fork here. The
resolution is in how the audit *orders* the follow-on tasks it files: sequence
the thin normalized record (the four outcomes + the shared honest-message
builder) first, so the trust win lands early on all providers, and let the
fuller provider-decoupling (default.sh's no-JSON path, cost/turns preservation
for observability) follow as its own task. The trap to name explicitly, because
the interim fix already fell into it: do not let a fast message patch
re-entrench the Claude shape — that is exactly the regression this audit
exists to stop.

**Sharpening the success criteria (not inventing scope — closing gaps):**
- The per-profile inventory bullet should demand the *plain-text / no-JSON*
  profile be recorded as its own case, not folded into "different shape."
  Today `default.sh` produces no result object, so `is_error` never fires and a
  max_turns abort is silently invisible under that profile.
- Add the user-facing message vocabulary (one honest line per outcome, shared
  across sites) as an explicit named output of the decision, so the follow-on
  interpreter is judged on the message a human sees, not only the record shape.
- The "added as members of this plan" bullet should own *both* sides of the
  reverse index: each filed task carries `**Plan**: 22` and a member line lands
  in the plan. Reverse-index drift is a known recurring failure here; the audit
  should not create new instances of it.
- Record "keep-and-patch, file no new work" as a legitimate terminal outcome.
  The success criteria list it as an alternative; if the audit lands there,
  Phase 2 files zero tasks and the plan closes — that is a valid result, not a
  failed audit.

## References

docs/sprintbias/lib.sh
docs/sprintbias/scripts/polish.sh
docs/sprintbias/scripts/polish-judge.sh
docs/sprintbias/scripts/deps.sh
docs/sprintbias/cli/claude.sh
docs/sprintbias/cli/grok.sh
docs/sprintbias/cli/default.sh

<!-- Direct paths to docs or files known to be related. One path per line.
     Leave empty if none. -->

## Findings — the interpretation mechanism, mapped once

Three shared reads in lib.sh turn a run into a decision:

- `sprintbias_parse_verdict TOKENS` (lib.sh:1908) — greps the run text (case- and
  punctuation-tolerant) for a `VERDICT: <TOKEN>` last line; empty → caller maps
  to UNCLEAR. Operates on the whole captured JSON blob or the log file.
- `sprintbias_run_error LOG` (lib.sh:1963) — python-parses the JSON for
  `is_error`; on error prints one prose line derived from `subtype`
  (`error_max_turns`→"hit its turn limit", `error_during_execution`→"errored
  partway", else "did not finish (<subtype>)") with `num_turns` / `duration_ms` /
  `total_cost_usd` / `errors[0]`. Empty log → "failed to start". **Non-JSON log →
  `sys.exit(1)` = treated as "finished".** All keys are Claude's.
- `sprintbias_extract_summary LOG` (lib.sh:1922) — python-parses the **same** JSON
  again, reads `data['result']`, prefers a `## Summary` section else the 30 lines
  before `VERDICT:` else the tail. On non-JSON → prints "(Could not extract
  summary: …)".

So a run is parsed by python twice and grepped once (**redundant-parse cost**),
and the failure *kind* is re-derived downstream by prose-matching the string
`sprintbias_run_error` returned (`case … *"turn limit"* / *"failed to start"*`).

Call sites — four, and they do **not** agree on order or role:

| Site | Path | verdict | run_error | summary | Order / role |
|------|------|---------|-----------|---------|--------------|
| polish.sh `--code` | 512–562 | :520 | :526 | :562 | verdict parsed, then run_error gates the loop (`VERDICT=ERROR; break`), then summary for next step |
| polish.sh deep-judge | 960–1036 | :980 | :1021 | — | verdict FIRST; run_error consulted **only** in the UNCLEAR fallback to explain *why* no verdict; no summary read |
| polish-judge.sh (excellence sweep) | 200–256 | :237 | :200 | :240 | run_error FIRST (clean order), then verdict, then summary; appends `## Excellence` or `## Excellence (aborted)` |
| deps.sh | 329–370 | :355 | :341 | — | run_error FIRST, then verdict; no summary (deps writes its own task) |

Three different orderings and three different roles for the same helper — one
gate, one fallback-explainer, one pre-check. Each site also re-implements the
same `*"turn limit"* / *"failed to start"*` prose match to pick a next-step hint.

Per-profile result shape for the audit's buffered `--output-format json` (all
four sites run `… 2>/dev/null | tee "$LOG_FILE"`, so profiles stay in buffered
mode and every profile-level warning is silenced to /dev/null):

- **claude.sh** — emits one Claude result JSON object: `is_error`, `subtype`,
  `num_turns`, `duration_ms`, `total_cost_usd`, `result`, `session_id`,
  `errors`. `sprintbias_run_error` and `_extract_summary` are written to exactly
  this shape and work correctly. (TTY auto-upgrade to stream-json re-emits an
  identical single result object, and stderr is /dev/null here so it stays
  buffered anyway.)
- **grok.sh** — passes buffered `--output-format json` **through untouched**
  (only `stream-json` is remapped, to `streaming-messages-json`). Grok's buffered
  `json` schema is a **known unknown**: not verified to carry
  `is_error`/`subtype`/`result`. If it doesn't, every grok audit mis-diagnoses
  aborts and gets an empty/garbled summary. (The Claude-shaped events grok *can*
  produce live under `streaming-messages-json` — Anthropic Messages NDJSON — are
  a different, streaming path the audits never request.)
- **default.sh** — **drops `--output-format` entirely** (default.sh:27). The log
  is the model's plain-text stdout — **no result object at all**. `is_error`
  never fires; `sprintbias_run_error` hits the non-JSON branch and returns
  "finished"; `_extract_summary` returns an error string. **A max_turns abort
  under the default profile is silently invisible** — first-class case, worse
  than a key-name mismatch: there is nothing structured to interpret. The
  "dropped JSON output" warning that would hint at this is sent to /dev/null by
  the call sites.

Trigger confirmed: a `polish 1014` run aborted on max_turns and was labeled
"could not parse a verdict" — the tool reported the wrong thing that happened.
On Claude the interim `sprintbias_run_error` helper now fixes the label, but it
is Claude-shape-coupled and re-derives the kind by prose, so grok (unverified
shape) and default (no shape) are still exposed.

## Decision — adopt the profile-owned single-pass interpreter (supersede the interim helper)

**Chosen:** a profile-owned `profile_interpret_run LOG [rc]`, dispatched by
lib.sh (`sprintbias_interpret_run`) to the active profile, returning a
**normalized record** read from the run exactly once:

- `outcome` ∈ **{finished | max_turns | no_start | error}** — the interface
  contract, provider-independent.
- normalized fields: **`verdict_text`** (the run's result text, for the caller's
  own token grep), **`turns`**, **`cost`**, **`summary`**; "unknown" is
  represented honestly (default.sh has no turns/cost).

Verdict token *sets* stay caller-owned (PASS|FIXED|FAIL|BLOCKED for --code,
PASS|REOPEN|BLOCKER for deep-judge, EXCELLENT|FILED|BLOCKER for the excellence
sweep, FILED|CLEAN for deps) — the interpreter normalizes run *mechanics*, not
audit semantics, and hands back the text to grep.

**Named deliverable — one honest message per outcome (the trust fix).** A single
shared `sprintbias_run_hint` maps an outcome token to one actionable line,
identical across all four sites and all providers, replacing the duplicated prose
match: max_turns → "hit its turn limit — raise --max-turns or narrow scope";
no_start → "produced no output — check the CLI's install/auth"; error → "errored
partway — inspect the log"; finished-but-no-verdict → "finished but wrote no
VERDICT token — a formatting slip, not a crash". The audit is judged on the line
a human reads, not only the record shape.

Judged against the five lenses:

1. **Lean into agent bias** — one "what happened to this run?" answer matches how
   an agent reasons about a result; three reads in three orders do not.
2. **Minimize context cost** — collapses two python parses + one grep + four
   copies of a prose match into one pass and one shared hint; removes
   `sprintbias_run_error` and `_extract_summary`. Pruning is the feature.
3. **Name in common language** — `finished / max_turns / no_start / error` read
   the same to people and agents; no `is_error`/`subtype` jargon at call sites.
4. **Instruct positively** — call sites switch on a positive outcome token and
   ask the profile for the record, rather than string-matching a forbidden-prose
   map.
5. **Tie-breaker (simple, clean, fast, common language, biased to action)** —
   simplest correct shape; makes the honest message land early and everywhere.

**Costs named.** *Redundant-parse:* JSON parsed twice by python and grepped once,
per run, at every site — eliminated. *Provider-coupling:* the Claude result
shape is hardcoded in lib.sh, so grok mis-reads (unverified buffered schema) and
default silently reports every abort as "finished"; moving shape knowledge into
each `profile_interpret_run` is the only fix that reaches non-Claude providers
and stops the next per-symptom patch from re-entrenching the Claude shape.

**Alternatives rejected.** *Keep-and-patch* (extend `sprintbias_run_error` with
per-provider branches): keeps the triple parse and the prose match, and deepens
the Claude coupling — exactly the regression the interim fix already fell into.
*Do nothing / file no tasks* (a legitimate terminal outcome per the brief):
rejected because the default-profile silent mis-diagnosis and the redundant
triple-parse are real, live defects that the plan exists to close.

**Sequencing (ordered to land the trust win first, then decouple, then prune):**
- **#367** — interpreter + shared honest message + claude `profile_interpret_run`,
  wired into the four sites with a Claude-shaped fallback for unported profiles.
  Trust win on Claude immediately; nothing else regresses.
- **#368** — grok + default `profile_interpret_run` (the no-JSON case as
  first-class), making the outcome and message provider-correct everywhere.
- **#369** — remove `sprintbias_run_error` / `sprintbias_extract_summary` and the
  per-site prose-matching, so the interpreter is the single source of truth and
  provider shape knowledge cannot creep back.

Strict dependency chain #367 → #368 → #369; each is `work`-sized. All three carry
`**Plan**: 22` and are listed as members of plan 22 (both sides of the reverse
index). Scope guard honored: none touch prompts, turn caps, or salvage/loop
behavior — that is sibling #366, deliberately **not** a member of plan 22.

## Completed

Audit complete. No product code changed — outputs are this findings map, the
recorded decision, and three execute-ready follow-on tasks filed to backlog/ and
added as members of plan 22:

- docs/tasks/backlog/367-add-a-profile-owned-single-pass-run-interpreter-an.md
- docs/tasks/backlog/368-implement-profile-interpret-run-for-grok-and-defau.md
- docs/tasks/backlog/369-retire-the-redundant-run-error-and-extract-summary.md

Reverse index set on both sides (each task `**Plan**: 22` + member lines in
docs/plans/22); dependency chain 367 → 368 → 369 recorded via Depends on /
Dependents; `./sprint.sh validate` passes (133/133).

### Files changed
none (audit — no product files edited)

## Questions

**Status: READY**

### Already complete

None — this is an audit; its deliverables (the findings map, the recorded
decision, the filed follow-on tasks) do not yet exist in the codebase. What I
verified is that the brief's premises are accurate against current code, so the
audit starts from solid ground:

- The three separate reads are real and fire in sequence at each call site:
  `sprintbias_run_error` (lib.sh:1963), `sprintbias_parse_verdict` (lib.sh:1908),
  `sprintbias_extract_summary` (lib.sh:1922) — invoked at polish.sh:520/526/562
  and polish.sh:980/1021 (deep-judge path), polish-judge.sh:200/237/240, and
  deps.sh:341/355.
- lib.sh's error path is hardcoded to Claude's JSON shape — `sprintbias_run_error`
  keys off `is_error`, `subtype`, `errors`, `num_turns`, `duration_ms`,
  `total_cost_usd` (lib.sh:1975-1988) — and re-derives the failure kind from a
  `subtype`→prose map, exactly the coupling the audit exists to settle.
- Per-profile shapes confirm the "worse than a key mismatch" premise:
  `claude.sh` emits Claude JSON with `is_error`; `grok.sh` maps `stream-json` →
  `streaming-messages-json` (Anthropic Messages NDJSON — Claude-shaped result
  events); `default.sh` **drops** `--output-format json` entirely (default.sh:27
  adds "JSON output" to `dropped`), so under the default profile there is no
  result object at all and `sprintbias_run_error` treats the non-JSON log as
  "finished" (lib.sh:1974). The no-JSON profile is a first-class case, as the
  Plan Think demands.
- Plan 22 exists with #364 as its sole Phase-1 member; the reverse index the
  third success criterion must maintain is in place and awaiting the audit's
  filed tasks.

### Remaining work

Run the audit and produce its deliverables — the task is not "start coding a
fix," it is the four success criteria:

- Write the single findings section mapping every result-interpretation site
  across polish.sh (sweep + deep-judge), polish-judge.sh, and deps.sh, plus the
  literal result shape each profile emits (claude/grok JSON-or-NDJSON;
  default.sh no-JSON as its own case).
- Record the target-mechanism decision judged against the five lenses, naming
  the redundant-parse and provider-coupling costs, the exact outcome tokens
  (finished|max_turns|no_start|error) and normalized fields
  (verdict/turns/cost/summary), and the shared honest-message vocabulary (one
  actionable line per outcome). "Keep-and-patch, file no tasks" is a legitimate
  terminal result if the audit lands there.
- File execute-ready follow-on task(s) to backlog/ — each small enough to `work`,
  dependency-ordered, each carrying `**Plan**: 22`, with matching member lines
  added to docs/plans/22 (both sides of the reverse index).
- Change no product code; outputs are findings, decision, and filed tasks only.

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
