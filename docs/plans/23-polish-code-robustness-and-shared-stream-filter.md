# Plan 23: polish --code robustness and shared stream_filter

**Created**: 2026-08-20
**Status:** STARTED

## Goal

Harden `polish --code` and pay down duplicated logging plumbing — the polish and
stream-rendering siblings that plan 22 deliberately routed out of its
interpreter work. #370 shapes the fixer/verifier prompt so a run acts decisively
and reaches a verdict inside the default turn cap; #371 salvages an aborted run
by banking and verifying the edits that already landed instead of discarding
them; #372 lifts the byte-identical stream-json renderer out of two scripts into
one shared lib.sh helper. Together they make `--code` finish clean, fail
honestly, and keep live progress rendered from one source.

## Why

These three concern what `polish --code` does and how live progress is rendered,
not how a run's result is read — that is plan 22 (#364/#367–#369). Plan 22
scoped itself to the interpreter and pushed these out as its siblings; this is
their home. #371 keys off plan 22's interpreter (#367), a recorded cross-plan
edge respected at execution, not a reason to merge the plans.

Parallelism (recorded; V1 runs sequential): #372 ∥ {#370, #371} — disjoint files
(#372 touches lib.sh/work.sh/plan-think.sh; #370/#371 touch polish.sh). #370 and
#371 touch different regions of polish.sh (first-pass prompt vs abort/salvage
branch) with no hard code edge, but #370 lands first by preference so fewer runs
reach the cap #371 recovers from. Cross-plan: #371 depends on #367 (plan 22).



## Plan Think

Two-persona review (Chief Platform Architect + Chief Experience Officer).
Full analysis: docs/tmp/plan-think.md. Per-member annotations are in each task
file's ## Plan Think section. Top findings:

1. Strong, coherent plan — tight Goal, correctly-scoped members, honest
   parallelism; needs no structural surgery.
2. Make the cross-plan gate explicit: #371 depends on plan 22's #367 and should
   be held until #367 lands; #370 and #372 carry no such gate and can proceed
   first. Promote this from footnote to a gating instruction.
3. #372 is the independent / anytime member (disjoint files, no #367 gate) — run
   it first or in parallel; keep it in the plan rather than splitting it out.

## Member tasks

<!-- One "- #ID — short title" line per task; [x] means the task is in done/.
     IDs are references — resolve each against docs/tasks/*/ for location. -->


<!--
AI: Full plan guidance is in DOCUMENTATION.md → Plans. A plan is a relational
index, not a container: Status is DRAFT | READY | STARTED, and members stay in
their own lifecycle folders. Keep it plain text — no emoji, color, or ASCII art.
See docs/sprintbias/guides/doc-style.md
-->
- #370 — Make polish --code fixer/verifier action-biased and sized to finish inside the default turn cap
- #371 — Salvage a polish --code abort: keep landed edits, verify what landed, record partial work, name the right lever
- #372 — Extract the duplicated stream-json _stream_filter into a shared lib.sh helper (work.sh + plan-think.sh)
