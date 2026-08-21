# Task 370: Make polish --code fixer/verifier action-biased and sized to finish inside the default turn cap

**Feature**: none
**Created**: 2026-08-20
**Docs**: none
**Plan**: 23
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

The `polish --code` first fixer pass tells the model to explore before it acts:
its pass context is `This is the first audit pass. Be thorough.`
(polish.sh:481) and step 1 of the prompt is `Build impact graph: Grep for
imports/references to changed files.` (polish.sh:497) before it fixes anything.
The conversation method's action-bias rule — "when the answer is clear or one
best practice plainly fits, say so and move on" (conversation.md:6-8) — is the
house style for every other durable-artifact pass, but `--code` does not inherit
it. So the default 30-turn budget (`SPRINTBIAS_AUDIT_MAX_TURNS`, polish.sh:212)
is spent exploring instead of applying a clear best practice on the touched
lines and shipping a verdict, and runs hit the cap that should have finished.
The fix is to shape the fixer/verifier prompt so it acts decisively and is sized
to reach a verdict (and any fixes) inside the default cap.

Audit 366 settled this behavior; this is one of its two follow-ons (sibling
#371 handles what happens when a run still aborts).

## Success criteria

- [x] The `--code` fixer prompt inherits the action-bias rule: on the touched
      lines, apply a clear best practice and stop; reserve deeper investigation
      for genuinely open calls. The first-pass `Be thorough.` framing
      (polish.sh:481) is replaced with an action-biased instruction.
- [x] Exploration is bounded, not the opening move: the impact-graph / grep step
      is scoped to what a fix on the touched lines actually needs (or made a
      follow-on to a decisive fix), so it cannot consume the whole budget before
      any edit lands.
- [x] The fixer/verifier protocol is sized to reach a verdict (and any fixes)
      within the default 30-turn cap: the prompt states the budget expectation
      so the model finishes rather than open-endedly deepens.
- [x] Raising `SPRINTBIAS_AUDIT_MAX_TURNS` is framed as the last resort, not the
      first move — the prompt's default path is "finish inside the cap." (The
      abort-time recovery copy itself is #371's scope; this task owns the prompt
      that keeps runs from needing it.)
- [x] The emit-mode `--code` prompt (polish.sh:254-271) carries the same
      action-bias and finish-in-cap shaping as the headless prompt, so both
      hosting paths behave the same.
- [x] Scope stays on the `--code` prompt only: no change to the loop control,
      the abort/salvage branch, run-result interpretation, or the sweep and
      deep-judge prompts.

## Notes

- The two prompt blocks to shape live in polish.sh: the headless fixer prompt at
  polish.sh:479-508 (first-pass context at :481, step list at :497-499) and the
  emit-mode prompt at polish.sh:254-271. The verifier prompt (polish.sh:462-477)
  is read-only and already terse; touch it only if needed to keep the pair
  coherent.
- Action bias here means the conversation.md posture applied to code: a clear
  best practice on the touched lines is applied and reported, not deliberated.
  It does not mean "edit widely" — `--code` still audits touched lines only
  (polish.sh:498), and untouched-line rewrites remain out of scope.
- This is prompt shaping, not a protocol-file addition. `--code` has no
  standalone protocol doc today (unlike refine.md / audit-excellence.md); adding
  one is optional and only if it reads cleaner than an inline prompt — do not
  expand surface for its own sake (context-cost lens).
- Keep the VERDICT contract intact (PASS|FIXED|FAIL|BLOCKED, last line, one
  token) — the runner parses it verbatim (polish.sh:520).

## Plan Think

### Perspective check

**Chief Platform Architect.** The Architect likes this task because it attacks a
real reliability failure at its cheapest point: runs that hit the turn cap are
runs that produce no clean verdict and burn budget doing it. Shaping the prompt
so exploration is bounded and a verdict lands inside the default cap is a
stability win with zero new moving parts — no loop changes, no state, no new
files. The Architect will push on two things. First, "sized to finish inside the
cap" must not become "rushed past the impact check that prevents a fix from
breaking a caller" — the grep-for-references step exists because touching a line
can ripple, and bounding it is right, deleting it is not. The success criteria
already say "scoped to what a fix on the touched lines actually needs," which is
the correct framing; hold that line. Second, the Architect wants the two prompt
blocks (headless :479-508 and emit-mode :254-271) to stay genuinely identical in
behavior, because divergent hosting paths are exactly the kind of silent drift
that #372 is separately paying down — the same anti-duplication instinct applies
here.

**Chief Experience Officer.** The CXO reads this as the core trust fix of the
plan. A run that explores for 30 turns and then dies at the cap with no verdict
is the worst possible user experience: slow, and it produces nothing. An
action-biased fixer that applies the obvious best practice on the touched lines
and reports a verdict feels fast and decisive — perceived performance and trust
both improve. The CXO pushes for the finish-in-cap expectation to be stated in
the prompt in plain terms the model will actually honor, and for the VERDICT
contract to stay a single clean token so the user always gets a legible result.
The CXO's one worry: "decisive" must not slide into "confidently wrong on a line
that needed a second look" — action bias is applying the *clear* best practice,
not manufacturing certainty. The conversation.md rule already carries that nuance
("when the answer is clear or one best practice plainly fits"); inheriting it
verbatim protects the CXO's concern.

### Tension and resolution

The one real tension is **thoroughness vs. speed**, and it lives in the
impact-graph step. The Architect wants the reference check preserved because
skipping it is how a "fix" silently breaks a caller; the CXO wants exploration to
stop consuming the whole budget before a single edit lands. This resolves cleanly
in the task's favor, and the phrasing to hold is already in the success criteria:
bound the grep to what a fix on the touched lines needs, or make it a *follow-on*
to a decisive fix rather than the opening move. Impact-awareness is kept; it just
stops being the first thirty turns. Both personas get what they need because the
disagreement is about *ordering and scope of investigation*, not about whether to
investigate at all — reframe exploration as "in service of a fix already
forming," not "before any fix is allowed," and the tension dissolves. The
secondary tension — decisiveness vs. correctness — is not a real conflict once
"action bias = apply the *clear* best practice" is inherited from
conversation.md rather than reinvented; both leaders sign off on that as the
house posture.

## References

docs/sprintbias/scripts/polish.sh
docs/sprintbias/ai/conversation.md
docs/sprintbias/help/polish.md
docs/tasks/doing/366-audit-polish-code-action-bias-turn-cap-and-abort-s.md

## Questions

**Status: READY**

### Already complete
None — no matching implementation found. The current prompts are still in the
pre-fix state this task targets:
- Headless first-pass context is `This is the first audit pass. Be thorough.`
  (polish.sh:481) — no action-bias framing.
- Headless step list opens with `1. Build impact graph: Grep for
  imports/references to changed files.` (polish.sh:497) — exploration is the
  first move, unscoped.
- Emit-mode prompt (polish.sh:264-268) mirrors the same "Build an impact
  graph" opening with no finish-in-cap framing.
- Neither prompt states the 30-turn budget expectation (`MAX_TURNS`,
  polish.sh:212) or points to raising `SPRINTBIAS_AUDIT_MAX_TURNS` as a last
  resort.
- The action-bias rule to inherit exists and reads as described
  (conversation.md:6-8).
- The VERDICT contract to preserve is intact (`PASS|FIXED|FAIL|BLOCKED`, last
  line, parsed at polish.sh:520).

### Remaining work
- Replace the first-pass `Be thorough.` framing (polish.sh:481) with the
  conversation.md action-bias posture applied to code: on the touched lines,
  apply a clear best practice and stop; reserve deeper investigation for
  genuinely open calls.
- Rescope the impact-graph/grep step (polish.sh:497) so it serves a fix already
  forming rather than being the opening move — bound it to what a fix on the
  touched lines needs, or make it a follow-on to a decisive fix.
- State the default-cap expectation in the prompt so the model finishes inside
  ~30 turns, with raising `SPRINTBIAS_AUDIT_MAX_TURNS` framed as the last resort.
- Apply the same action-bias and finish-in-cap shaping to the emit-mode prompt
  (polish.sh:254-271) so both hosting paths behave identically.
- Keep scope on the `--code` prompt only: no loop-control, abort/salvage,
  run-result, sweep, or deep-judge changes; verifier prompt (polish.sh:462-477)
  touched only if needed to keep the pair coherent; VERDICT contract preserved.

### Questions for the developer
None — task is fully defined.

## Completed

Shaped the `--code` fixer and emit-mode prompts in polish.sh:

- Headless first-pass context (`This is the first audit pass. Be thorough.`)
  replaced with the conversation.md action-bias posture applied to code: apply a
  clear best-practice fix on the touched lines and move on; reserve deeper
  investigation for genuinely open calls.
- Reordered the headless step list so auditing/fixing the touched lines is the
  opening move and the impact-graph grep became a bounded follow-on ("before a
  fix that could ripple… scope this check to the fix in hand, not the whole
  tree"), so exploration can no longer consume the budget before an edit lands.
- Added the finish-in-cap expectation to the headless prompt ("You have
  ~$MAX_TURNS turns… act decisively rather than deepening open-endedly"), with
  raising `SPRINTBIAS_AUDIT_MAX_TURNS` framed as the last resort.
- Mirrored the same action-bias + finish-in-cap shaping into the emit-mode
  prompt so both hosting paths behave identically.
- Left the loop control, abort/salvage branch, run-result interpretation, and
  the read-only verifier prompt untouched. VERDICT contract intact.

Verified `bash -n docs/sprintbias/scripts/polish.sh` passes. The mirror to
`src/` via `./ship.sh` is left to the developer — the working tree already
carries unrelated in-progress edits that a whole-tree mirror would bundle and
version-bump alongside this change.

### Files changed
docs/sprintbias/scripts/polish.sh

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
- **Verdict**: EXCELLENT
- **Tasks filed**: 0
- **Files reviewed**: 3
- **Context source**: task ## Completed section

Task 370 reshapes the `polish --code` fixer/verifier prompts (both the headless block at `polish.sh:513–549` and the emit-mode block at `polish.sh:263–276`) so the model applies the clear best practice on touched lines and reaches a verdict instead of exploring until it hits the turn cap. The work meets every success criterion cleanly: the first-pass `Be thorough.` framing is replaced with the conversation.md action-bias posture, the impact-graph grep is demoted from opening move to a scoped follow-on ("serves a fix already forming"), the finish-in-cap expectation is stated with `SPRINTBIAS_AUDIT_MAX_TURNS` framed as last resort, and the VERDICT contract is intact. Scope held to the prompt — the salvage/interpret machinery elsewhere in the diff is sibling tasks' in-progress work, not this one's.

Two altitude touches worth naming as strengths rather than gaps: the prompt interpolates `$MAX_TURNS` so it stays honest when a user raises the cap (says "~60 turns," not a hardcoded 30), and the emit-mode prompt carries the *behavioral* shaping ("act decisively, don't deepen open-endedly") while correctly omitting the cap mechanics — the emit host has no `SPRINTBIAS_AUDIT_MAX_TURNS` to reference, so echoing it there would have been wrong. The help doc (`help/polish.md:101`) and conversation.md (`:6–8`) both stay consistent with the new copy; no doc drift.

### Findings
- [NIT] The headless first-pass `PASS_CONTEXT` (`polish.sh:515–517`) and step 1 of the prompt body (`polish.sh:533–534`) both state the action-bias posture, mild within-prompt redundancy — reinforcing rather than harmful, not worth a task.
- No BLOCKER, DEFECT, or ENHANCEMENT. The capability is invocable end to end via `polish --code`; the change is prompt-only and fully within its stated scope.
