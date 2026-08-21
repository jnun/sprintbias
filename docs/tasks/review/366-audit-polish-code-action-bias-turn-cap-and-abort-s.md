# Task 366: Audit polish --code action bias, turn cap, and abort salvage

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

When a headless `polish --code` run hits the turn cap, the fixer/verifier
loop stops, throws away the pre/post diff, and tells the user to raise
`--max-turns`. The fixer prompt says "Be thorough" and builds an impact
graph first, so the cap is spent on exploration instead of applying a clear
best practice on the touched lines and shipping a verdict. Partial edits
sit unverified. Deep-judge and the sweep get pulled into the same recovery
story even though only `--code` (and maybe a sweep reopen) can push clean
code forward. Headless failure is treated as a labeling problem; resume and
recovery are not designed.

## Success criteria

- [x] One findings section maps the live product behavior, not the JSON
      parse: the `--code` first-pass prompt (including "Be thorough" and
      impact-graph-first), the fixer/verifier loop, what the abort branch
      does with diffs and unverified edits, the current turn-cap next-step
      (`SPRINTBIAS_AUDIT_MAX_TURNS=60`), and which lever actually edits
      (`--code`), reopens the same task (sweep), or files separate work
      (deep-judge).
- [x] A recorded decision covering four named beats, judged against the
      five lenses: (1) action bias — the fixer inherits the conversation
      rule, apply a clear best practice on touched lines and stop;
      (2) finish inside the cap — protocol sized to a verdict (and any
      fixes) within the default 30 turns, exploration bounded, raise
      max-turns last resort; (3) salvage on abort — keep edits the fixer
      already made, run a verifier on what landed, record partial work;
      (4) named lever — "push clean code forward" is `--code` now, sweep
      may reopen the same task, deep-judge files only.
- [x] Execute-ready follow-on task(s) are filed to backlog/ that implement
      the decision — each small enough to `work`, ordered by dependency.
      Salvage follow-ons that need an honest run outcome depend on #364's
      interpreter follow-ons, not on #364 itself.
- [x] The audit changes no product code itself; its only outputs are the
      findings, the decision, and the filed tasks.

## Notes

- Sibling of #364 / plan 22. #364 owns how a headless run's result is
  interpreted (one pass, provider-correct, honest label). This task owns
  what the runner and prompts do with a live code audit: bias, budget,
  salvage, which lever edits. Do not fold this into plan 22, and do not
  let #364's follow-ons swallow prompt or loop behavior.
- Conversation method already states the action-bias rule
  (`docs/sprintbias/ai/conversation.md`); `--code` does not inherit it.
  First fixer pass in `polish.sh` currently says "Be thorough."
- Default cap is `SPRINTBIAS_AUDIT_MAX_TURNS` (30). Current abort hint
  raises it to 60. The decision should make finishing inside 30 the
  desired path.
- Live abort path in `--code`: on `sprintbias_run_error`, delete the
  pre-diff tempfile, set `VERDICT=ERROR`, `break` — no verifier, no
  captured delta. Deep-judge is a contrast case: it counts tasks filed
  before abort and does not fake a verdict; it still offers "give it 60
  turns" as the main recovery.
- Candidate to validate (not assume): fixer prompt inherits conversation
  bias; protocol sized to finish in 30; on abort keep edits, verify what
  landed, record partial work; raise-max-turns last resort; `--code` is
  the edit-now lever.
- This is an audit: never edit product code (mirror the excellence-audit
  protocol). "Done" is the execute-ready follow-on tasks it produces, not
  just notes.

## References

docs/sprintbias/scripts/polish.sh
docs/sprintbias/scripts/polish-judge.sh
docs/sprintbias/ai/conversation.md
docs/sprintbias/ai/refine.md
docs/sprintbias/ai/audit-excellence.md
docs/sprintbias/help/polish.md
docs/tasks/review/364-audit-the-headless-audit-run-result-interpretation.md
docs/plans/22-fix-the-audit-run-result-interpretation-mechanism.md

## Findings — what the live `--code` audit does with a run

The code audit is `polish.sh` MODE=code (polish.sh:206-657): a fixer/verifier
loop of at most `MAX_PASSES*2` steps (default 3 passes → 6 steps), each step one
headless `sprintbias_run` capped at `SPRINTBIAS_AUDIT_MAX_TURNS` (default 30,
polish.sh:212). Mapped against this task's four beats:

**Beat 1 — first-pass prompt is exploration-first, not action-biased.** The
first fixer step sets `PASS_CONTEXT="This is the first audit pass. Be thorough."`
(polish.sh:481). The prompt's step 1 is `Build impact graph: Grep for
imports/references to changed files.` (polish.sh:497), *before* step 3 `Fix
issues you find` (polish.sh:499). The emit-mode `--code` prompt has the same
shape — "Build an impact graph" first, "Fix any issues you find directly" third
(polish.sh:263-267). The conversation method's action-bias rule — "Bias toward
action throughout: when the answer is clear or one best practice plainly fits,
say so and move on" (conversation.md:6-8) — is the house posture for every
durable-artifact pass, but `--code` does not inherit it. Nothing in the prompt
tells the model to apply a clear best practice on the touched lines and stop; the
opening instruction is to be thorough and map the blast radius first. So the
30-turn budget is spent exploring before the first edit lands.

**Beat 2 — no budget shaping; the cap is a hard wall, not a target.** The prompt
never states a turn budget or a "finish inside the cap" expectation. `MAX_TURNS`
is passed to the CLI (polish.sh:517) and only surfaces to the model as an abrupt
truncation. When a step is cut off, the run has no verdict and the loop stops
(see Beat 3). The user-facing next-step then raises the budget: `Give a step
more room:  SPRINTBIAS_AUDIT_MAX_TURNS=60 …` (polish.sh:635-636). So "raise the
cap" is presented as the first move, not the last resort, and finishing inside
30 turns is nobody's stated goal.

**Beat 3 — abort discards the work.** The step captures a pre-diff before the
fixer runs (`PRE_DIFF_FILE`, polish.sh:435-440) and, on the success path, diffs
pre/post into a delta patch afterward (polish.sh:535-549). But on abort the
recovery is thrown away: `if RUN_ERROR=$(sprintbias_run_error "$LOG_FILE")` fires
(polish.sh:526), which **deletes the pre-diff tempfile** (`rm -f
"$PRE_DIFF_FILE"`, polish.sh:528), sets `VERDICT=ERROR`, and `break`s the loop
(polish.sh:529-530). No verifier runs on what already landed; no delta is
captured. Any edits the fixer made mid-pass sit on disk unverified and
unrecorded — a partial fix is treated as a total loss. The `## Audit` section
appended to the task (polish.sh:610-625) then records `Final verdict: ERROR`
with no note that edits landed. Contrast the excellence deep-judge, which on the
same abort counts the tasks it filed before stopping and writes an explicit
`## Excellence (aborted — no verdict)` note rather than faking a verdict
(polish-judge.sh:200-213) — `--code` has no equivalent salvage.

**Beat 4 — the lever split is real but the recovery copy blurs it.** Three
levers push work forward, and only one edits code:
- `--code` (polish.sh:206-657) is the edit-now lever — full-tools fixer
  (`TOOLS_FIXER="Read,Edit,Write,Bash,Grep,Glob,Agent"`, polish.sh:208) that may
  change product code inline, then re-runs itself on the same files.
- the sweep (`refine.md`) never edits code; it reopens the *same* task into
  `next/` for another `work` pass ("your only writes are to the task file",
  refine.md:9).
- deep-judge (`audit-excellence.md`, polish-judge.sh) never edits and never
  reopens; it files *separate* backlog tasks ("enhancements become filed tasks,
  not edits", audit-excellence.md:20-22).

The recovery copy does not keep these straight. The `--code` abort hint and the
deep-judge abort hint both tell the user to "give it 60 turns"
(polish.sh:635-636, polish-judge.sh:221-224), and the sweep's UNCLEAR branch
repeats the same `SPRINTBIAS_AUDIT_MAX_TURNS=60` line (polish.sh:1024-1025). So
"the run didn't finish" resolves to one shared message — raise the budget —
regardless of which lever the user actually needs. Nothing in the `--code`
recovery says "this is the lever that edits; here is what it already changed."

**Cross-cutting: headless failure is a labeling problem today.** Every abort
path (all three levers) reads the run once, discovers there is no verdict, and
prints an honest-but-terminal message that points at a bigger budget or a
re-run. None of them is designed to *resume* or *bank partial work*; the whole
recovery vocabulary is "we couldn't finish — try again with more room." Beat 3
is the concrete instance of that gap for `--code`.

## Decision — action bias, finish-in-cap, salvage on abort, lever-correct recovery

The target behavior, across the four beats, judged against the five lenses
(agent bias, minimize context cost, name in common language, instruct
positively, tie-breaker: simple/clean/fast/common-language/biased-to-action):

**(1) Action bias — the fixer inherits the conversation rule.** The `--code`
fixer prompt applies a clear best practice on the touched lines and stops;
deeper investigation is reserved for genuinely open calls, not the opening move.
The `Be thorough.` first-pass framing (polish.sh:481) is replaced with the
action-biased posture, and the impact-graph step is scoped to what a fix on the
touched lines actually needs rather than run as step 1. *Lenses:* agent bias — a
decisive "apply the obvious fix, report, move on" matches how an agent works a
clear call; instruct positively — the prompt states the desired path (act on the
touched lines) rather than a map of what to avoid; tie-breaker — biased to
action.

**(2) Finish inside the cap — protocol sized to a verdict within 30 turns.** The
fixer/verifier protocol is shaped to reach a verdict (and any fixes) inside the
default 30-turn cap: the prompt states the budget expectation so the model
converges instead of open-endedly deepening; exploration is bounded. Raising
`SPRINTBIAS_AUDIT_MAX_TURNS` becomes the last resort, not the default next-step.
*Lenses:* minimize context cost — a bounded pass spends the budget on the fix,
not on unbounded mapping; simple/fast — finishing in-budget is the cheap common
case; instruct positively — "finish inside the cap" is the stated path.

**(3) Salvage on abort — keep edits, verify what landed, record partial work.**
On an aborted `--code` step, the edits the fixer already made are kept (the
pre/post delta is captured, not deleted), a verifier runs on what landed, and
the run records the partial work honestly in `## Audit` — an abort-with-fixes,
never a clean PASS and never a silent ERROR that implies nothing happened. This
mirrors the deep-judge's aborted-note posture (polish-judge.sh:201-213). The
salvage branch switches on the honest run outcome from the plan-22 interpreter
(#367: `outcome` ∈ finished|max_turns|no_start|error) so it triggers on a real
abort and speaks the shared honest line. *Lenses:* robustness/agent bias —
banking partial work beats discarding it; name in common language — "kept the
edits, verified what landed" is what actually happened; instruct positively —
the run reports what it did, not just what it failed to do.

**(4) Named lever — recovery copy points to the lever that fits.** The `--code`
recovery copy names `--code` as the edit-now lever that pushes clean code
forward and re-runs itself; it does not conflate with the sweep (reopens the
same task) or deep-judge (files separate work). The shared "give it 60 turns"
line stops being the universal answer to "didn't finish"; for `--code` the
default recovery is "here is what already landed and was verified," with a bigger
budget offered last. *Lenses:* name in common language — one lever, one clear
role; minimize context cost — the user is pointed at the right tool, not a
generic retry; instruct positively — the copy states the productive next step.

**Scope guard.** This decision is product behavior of the code audit only. How a
run's *result* is interpreted (one pass, provider-correct, honest label) is
plan 22 / #364, and its follow-ons #367–#369 own the interpreter and the shared
message vocabulary. The salvage beat *consumes* that honest outcome (#367) but
does not build it; the prompt and loop/recovery behavior here are deliberately
NOT members of plan 22.

**Follow-on tasks filed (dependency-ordered):**
- **#370** — Make the `--code` fixer/verifier prompt action-biased and sized to
  finish inside the default turn cap (beats 1 + 2). No dependency — pure prompt
  shaping in polish.sh. Should land first (fewer runs reach the cap).
- **#371** — Salvage a `--code` abort: keep landed edits, verify what landed,
  record partial work, and name the right lever in the recovery copy
  (beats 3 + 4). **Depends on #367** (the honest run-outcome interpreter), NOT on
  #364 itself, per the brief. Sibling of #370; no hard code dependency between
  them (different regions of polish.sh).

Both are `work`-sized. Neither is added as a member of plan 22 (scope guard
above); #371's cross-plan dependency on #367 is recorded on both sides of the
reverse index (#371 `Depends on: 367`; #367 `Dependents: …, 371`).

## Completed

Audit complete. No product code changed — outputs are the findings map above,
the recorded decision, and two execute-ready follow-on tasks filed to backlog/:

- docs/tasks/backlog/370-make-polish-code-fixer-verifier-action-biased-and.md
  (beats 1 + 2; no dependency)
- docs/tasks/backlog/371-salvage-a-polish-code-abort-keep-landed-edits-veri.md
  (beats 3 + 4; Depends on #367, not #364)

Dependency-ordered (#370 then #371); #371's dependency on #367 recorded on both
sides of the reverse index. Neither task is a member of plan 22 — the prompt,
loop, and salvage/recovery behavior are #366's scope, distinct from plan 22's
run-result interpretation.

### Files changed
none (audit — no product files edited)

## Questions

**Status: READY**

### Already complete

None — this is an audit; its deliverables (the findings map, the recorded
decision, the filed follow-on tasks) do not yet exist in the codebase. What I
verified is that the brief's premises are accurate against current code, so the
audit starts from solid ground:

- `--code` first fixer pass is exploration-first: `PASS_CONTEXT="This is the
  first audit pass. Be thorough."` (polish.sh:481), then "Build impact graph"
  before "Fix issues you find" (polish.sh:497-499). Conversation method's
  action-bias rule (conversation.md:6-8) is not inherited here.
- Abort discards recovery: on `sprintbias_run_error`, polish.sh:526-530 deletes
  the pre-diff tempfile, sets `VERDICT=ERROR`, and `break`s the fixer/verifier
  loop — no verifier on what landed, no captured delta.
- Turn-cap next-step raises the budget: polish.sh:635-636 prints
  `SPRINTBIAS_AUDIT_MAX_TURNS=60`. Default cap is 30 (polish.sh:212). The same
  "give it 60 turns" recovery is the deep-judge hint (polish-judge.sh:221-223).
- Lever split is real and currently mixed in recovery copy: `--code` may edit
  (polish.sh:16-17); deep-judge never edits, files backlog tasks
  (polish-judge.sh:7-8; audit-excellence.md); sweep reopens the same task
  (refine.md). #364 / plan 22 own result interpretation only and sit in next/
  as the sibling audit.

### Remaining work

Run the audit and produce its deliverables — the task is not "start coding a
fix," it is the four success criteria:

- Write the findings map of live product behavior: `--code` prompt and
  fixer/verifier loop, abort handling of diffs and unverified edits, the
  raise-max-turns next-step, and which lever edits / reopens / files.
- Record the target-behavior decision against the five lenses, covering the
  four named beats (action bias, finish inside the 30-turn cap, salvage on
  abort, named lever).
- File execute-ready follow-on task(s) to backlog/ — each small enough to
  `work`, dependency-ordered. Salvage follow-ons that need an honest run
  outcome depend on #364's interpreter follow-ons, not on #364 itself. Do not
  add those tasks (or this one) as members of plan 22.
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
