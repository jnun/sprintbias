# Task 371: Salvage a polish --code abort: keep landed edits, verify what landed, record partial work, name the right lever

**Feature**: none
**Created**: 2026-08-20
**Docs**: none
**Plan**: 23
**Depends on**: 367
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

When a `polish --code` run aborts (max-turns or a CLI error), the current branch
throws the work away: on `sprintbias_run_error` it deletes the pre-diff tempfile,
sets `VERDICT=ERROR`, and `break`s the fixer/verifier loop (polish.sh:526-530) —
no verifier runs on what already landed, and no delta is captured. Any edits the
fixer made mid-pass sit on disk unverified and unrecorded, and the run's only
next-step is "give a step more room: SPRINTBIAS_AUDIT_MAX_TURNS=60"
(polish.sh:635-636). So a partial fix is treated as a total loss, and the
recovery story pushes a bigger budget instead of banking the work. Contrast the
excellence deep-judge, which on abort counts the tasks it filed before stopping
and records them honestly rather than faking a verdict (polish-judge.sh:200-213)
— `--code` should likewise keep and verify what it produced.

Audit 366 settled this behavior; this is its salvage-and-lever follow-on
(sibling #370 shapes the prompt so runs finish inside the cap in the first
place).

## Success criteria

- [x] On an aborted `--code` step, edits the fixer already made are kept, not
      discarded: the pre/post diff for the step is captured (the same delta-patch
      the normal path writes at polish.sh:535-549), so partial work is visible
      and recoverable rather than deleted at polish.sh:528.
- [x] A verifier runs on what actually landed before the run reports out — the
      abort no longer `break`s straight past verification. What the verifier
      finds is recorded (verdict on the salvaged delta, or an honest "unverified
      — verifier could not run" when even that step aborts).
- [x] The run records partial work honestly in the task's `## Audit` section:
      the outcome is labeled as an abort with fixes-landed (files touched, delta
      captured, verifier result), never a clean PASS and never a silent ERROR
      that implies nothing happened — mirroring the deep-judge's aborted-note
      posture (polish-judge.sh:201-213).
- [x] The abort recovery copy names the right lever: `--code` is the edit-now
      lever to push clean code forward and re-runs itself; it does not conflate
      with the sweep (which reopens the same task) or deep-judge (which files
      separate work). Raising `SPRINTBIAS_AUDIT_MAX_TURNS` is presented as the
      last resort AFTER the salvaged work is banked, not the first move
      (replacing the current polish.sh:635-636 default).
- [x] The abort branch switches on the honest run outcome from the #367
      interpreter (`outcome` ∈ finished|max_turns|no_start|error), so salvage
      triggers on a real abort and the user-facing line uses the shared honest
      hint — not a re-derived prose match.
- [x] Scope stays on the abort/salvage branch and its recovery copy: no change
      to the first-pass prompt shaping (that is #370), and no change to how a
      finished run's verdict is parsed.

## Notes

- Depends on #367 (plan 22): salvage keys off the honest `outcome` token the
  single-pass interpreter returns, and reuses its shared honest-message builder
  for the recovery line. It depends on the interpreter follow-on, NOT on the
  #364 audit itself. #368 broadens the outcome to grok/default; salvage is
  correct on Claude once #367 lands and simply inherits provider-correctness as
  #368 follows — do not block this task on #368.
- The salvage machinery already mostly exists on the success path: the step
  captures a pre-diff before the fixer runs (polish.sh:435-440) and diffs
  pre/post into a delta patch after (polish.sh:535-549). The abort branch just
  needs to bank that delta and run a verify pass instead of deleting the pre-diff
  and breaking. Reuse the existing diff/verify code rather than adding a parallel
  path.
- Guard the double-abort case: if the salvage verifier itself aborts, do not
  loop — record "landed edits, unverified" once and stop. Salvage is one bounded
  recovery pass, not a new retry loop.
- Interpretation-vs-behavior line: #367/#369 own how a run's result is read and
  the shared hint vocabulary; this task owns what the `--code` loop DOES with an
  abort (keep, verify, record) and which lever the recovery copy names. Keep the
  edits on the loop/copy, not on the interpreter internals.
- Sibling #370 should ideally land first (fewer runs reach the cap), but there is
  no hard code dependency between them — they touch different regions of
  polish.sh (prompt vs abort branch).

## Plan Think

### Perspective check

**Chief Platform Architect.** This is the task the Architect cares most about in
the whole plan, because it is fundamentally about **data integrity and honest
observability**: the current branch deletes the pre-diff, stamps
`VERDICT=ERROR`, and breaks — destroying evidence of work that actually landed on
disk. Discarding real edits and reporting "nothing happened" is a lie the system
tells about its own state, and it makes "what broke?" recovery impossible. The
Architect strongly endorses banking the delta and verifying what landed, and
especially endorses two guardrails the task already names: the double-abort guard
(one bounded salvage pass, never a new retry loop) and reusing the existing
diff/verify machinery instead of forking a parallel path. The Architect's push:
salvage must switch on the honest `outcome` token from #367's interpreter, not a
re-derived prose match — brittle string-matching on error output is precisely the
kind of fragility that makes abort handling unreliable. The task's dependency on
#367 is correct and load-bearing, not incidental. The mirror to the deep-judge's
aborted-note posture (polish-judge.sh:201-213) is the right precedent to
converge on.

**Chief Experience Officer.** The CXO frames this as the **trust-under-failure**
task. Users forgive a tool that fails; they do not forgive a tool that throws
away their work and lies about it. Keeping the landed edits, telling the user
honestly "here is what landed, here is what the verifier found, here is what's
unverified," and naming the *right* next lever is the difference between a
recoverable stumble and a betrayal. The CXO is emphatic about the recovery copy:
today it pushes "just raise the budget to 60," which trains the user to throw
more turns at a wall instead of banking progress. The right lever is `--code`
itself (edit-now, re-runs itself), with the budget bump demoted to last resort
*after* the work is banked. The CXO also wants the `## Audit` record to read as
neither a fake clean PASS nor a silent ERROR — the honest middle state ("abort
with fixes landed") is what preserves trust.

### Tension and resolution

There is almost no tension between the two personas here — both want honesty,
salvage, and the right lever, and they reinforce each other. The genuine tension
is instead **scope and sequencing risk**, and it is between this task and the
plan's dependencies. First, #371 depends on #367 (plan 22, another plan's
backlog). That is a hard cross-plan edge: salvage keys off the honest `outcome`
token and reuses the shared honest-message builder, so #371 cannot correctly land
until #367 does. The task handles this well by noting it inherits
provider-correctness from #368 without blocking on it — Claude-correct once #367
lands is the right bar. The resolution: **#371 must not be started before #367 is
done**, and the plan should make that non-negotiable rather than a preference.
Second, the softer tension with #370: both touch polish.sh, and #370 "should
ideally land first" so fewer runs reach the cap #371 recovers from. This resolves
toward #370-first, but the task correctly notes it is a preference, not a hard
edge — they touch different regions (prompt vs. abort branch). The one thing to
watch is a merge-region overlap if both edits land near the fixer/verifier loop;
sequential execution (V1) sidesteps it entirely, which is why sequential is the
safe default here.

## References

docs/sprintbias/scripts/polish.sh
docs/sprintbias/scripts/polish-judge.sh
docs/sprintbias/help/polish.md
docs/tasks/doing/366-audit-polish-code-action-bias-turn-cap-and-abort-s.md
docs/tasks/backlog/367-add-a-profile-owned-single-pass-run-interpreter-an.md
docs/tasks/backlog/370-make-polish-code-fixer-verifier-action-biased-and.md

## Questions

**Status: READY**

### Already complete
None — no matching implementation found. The abort branch still does the
opposite of what this task asks. Verified against current code:
- `polish.sh:526-531` — on `sprintbias_run_error`, the branch deletes
  `PRE_DIFF_FILE`, sets `VERDICT=ERROR`, and `break`s. No verifier runs on what
  landed; the pre-diff (evidence of partial work) is destroyed.
- `polish.sh:634-636` — recovery copy leads with the
  `SPRINTBIAS_AUDIT_MAX_TURNS=60` budget bump as the first move, not banking work.
- The salvage machinery this task reuses already exists on the success path:
  pre-diff capture at `polish.sh:435-440`, pre/post delta patch at
  `polish.sh:535-549`. The abort branch just needs to bank the delta + verify
  instead of delete + break.
- The precedent to mirror is live at `polish-judge.sh:200-213`: on abort it
  counts what it produced (`FILED_COUNT`) and appends a clearly-labelled aborted
  note rather than faking a verdict.
- Abort detection today still uses `sprintbias_run_error` + prose matching
  (`*"turn limit"*` at 635/637); criterion 5 replaces that with #367's honest
  `outcome` token once that task lands.

### Remaining work
- Bank the fixer's landed edits on an aborted `--code` step: capture the pre/post
  delta patch (reuse the `polish.sh:535-549` code) instead of deleting the
  pre-diff at `polish.sh:528`.
- Run one bounded verifier pass on what landed before reporting out; record its
  result (or "unverified — verifier could not run"). Guard the double-abort case:
  if the salvage verifier itself aborts, record "landed edits, unverified" once
  and stop — no new retry loop.
- Record the outcome honestly in the task's `## Audit` section as an abort with
  fixes-landed (files touched, delta captured, verifier result) — never a clean
  PASS, never a silent ERROR. Mirror the `polish-judge.sh:201-213` posture.
- Rewrite the recovery copy to name `--code` (edit-now, re-runs itself) as the
  right lever; demote the `SPRINTBIAS_AUDIT_MAX_TURNS` bump to last resort AFTER
  the work is banked.
- Switch the abort branch on #367's honest `outcome` token
  (finished|max_turns|no_start|error) and reuse its shared honest-message
  builder for the user-facing line, replacing the re-derived prose match.
- Keep scope on the abort/salvage branch and its copy: no change to first-pass
  prompt shaping (#370) or to how a finished run's verdict is parsed.

Sequencing: **Depends on 367** (already recorded in the header) — salvage keys
off #367's `outcome` token and shared honest-message builder, so it cannot land
correctly until #367 is done. #368 (grok/default breadth) is NOT a blocker —
Claude-correct once #367 lands is the bar. #370 is a soft preference (fewer runs
reach the cap), not a hard code edge; different regions of polish.sh.

### Questions for the developer
None — task is fully defined.

## Completed

Reworked the `--code` abort branch in polish.sh from delete-and-break into a
bounded salvage pass, reusing the existing pre/post diff machinery:

- Factored the success-path delta capture (former polish.sh:535-549) into a
  shared `_capture_step_delta` helper so BOTH the normal path and an abort bank
  the same delta patch. The abort no longer deletes the pre-diff — the fixer's
  landed edits are kept and the delta is written to a patch under docs/tmp/.
- On an aborted fixer step with edits on disk, one bounded salvage verifier runs
  (read-only tools) on what landed; its PASS/FAIL is recorded. The abort no
  longer `break`s straight past verification.
- Double-abort guard: if the salvage verifier itself aborts, it records "landed
  edits unverified" once and stops — a single recovery pass, never a new retry
  loop. A verifier-step abort (read-only, no new delta) likewise records
  unverified without re-running. No edits landed → "nothing to verify".
- The task's `## Audit` append became a dedicated aborted note ("## Audit
  (aborted — fixes landed)" / "— no fixes landed"): abort outcome, edits-landed,
  banked delta path, and verifier result — never a clean PASS, never a silent
  ERROR. Mirrors the deep-judge posture at polish-judge.sh:201-213.
- Recovery copy (`VERDICT=ABORTED`) now names `--code` itself as the edit-now
  lever to push the banked work forward and re-run; `SPRINTBIAS_AUDIT_MAX_TURNS`
  is demoted to a last resort AFTER the work is banked. The branch switches on
  the honest `ABORT_OUTCOME` token from #367's interpreter (captured before the
  salvage verify overwrites `SPRINTBIAS_RUN_OUTCOME`) and uses the shared
  `sprintbias_run_hint` line — no re-derived prose match.
- No change to the first-pass prompt shaping (#370) or to how a finished run's
  verdict is parsed. Help doc updated to document the salvage-on-abort behavior.

Verified end-to-end with a fake CLI across three scenarios: (1) fixer aborts +
edit lands + salvage verifier PASS → banked, verified, honest note; (2) both
fixer and salvage verifier abort → banked once, "unverified", no loop; (3) fixer
aborts with no edit → "nothing to verify". `bash -n` clean.

### Files changed
docs/sprintbias/scripts/polish.sh
docs/sprintbias/help/polish.md

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
- **Files reviewed**: 4
- **Context source**: task ## Completed section

Task 371 reworks the `polish --code` abort branch from delete-and-break into a bounded salvage pass: it banks the fixer's landed edits as a delta patch (reusing the extracted `_capture_step_delta` helper), runs one guarded salvage verifier on what landed, records an honest `## Audit (aborted — fixes landed / no fixes landed)` note, and rewrites the recovery copy to name `--code` itself as the lever with the turn-budget bump demoted to last resort. It correctly switches on #367's honest `SPRINTBIAS_RUN_OUTCOME` token (captured into `ABORT_OUTCOME` before the salvage verify overwrites it) and reuses the shared `sprintbias_run_hint` line. All six success criteria are met against the current code, the double-abort guard is real (records "unverified" once, never loops), and the dependency functions all exist and are wired. The work meets the bar. The one altitude gap: the aborted record is the sole path in `polish.sh` that surfaces no log pointer, so a salvage-verify FAIL dead-ends exactly the "what broke?" recovery the task set out to protect.

### Findings
- [ENHANCEMENT] The ABORTED terminal branch (`polish.sh:770-793`) and `## Audit (aborted)` note (`polish.sh:729-746`) point at neither `$SALVAGE_LOG` (602) nor the step `$LOG_FILE` (552), unlike every other branch (`_route_refine` `See $LOG_FILE`; UNCLEAR "Inspect the log tail" at 798) — a salvage FAIL names the verdict but not where its findings live.
- [NIT] Secondary completeness gap folded into the same task: on a verifier-step abort after an earlier fixer landed edits, `SALVAGE_PATCH` is empty (only set in the fixer-abort branch, 581), so the note prints "Edits landed: yes" without the "Delta banked" pointer even though that earlier step captured one.
- FILED: docs/tasks/backlog/374-point-the-polish-code-aborted-record-at-its-salvag.md — thread the salvage/step log pointer into the aborted report and note; retain the delta pointer on a post-fixer verifier abort.
