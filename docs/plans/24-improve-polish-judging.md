# Plan 24: improve polish judging

**Created**: 2026-08-27
**Status:** STARTED

## Goal

Close three gaps in the `polish` excellence deep-judge that a downstream project
surfaced from a real run — without weakening the judge's core value (it never
edits product code; improvements are named and queued, not smuggled in). All
three land as fields on the same `## Excellence` block: (376) make the judge's
"presumed correct" claim honest by gating it on an actual `## Audit` marker;
(377) let the vital-few high-confidence findings route to `next/` instead of
always going cold in `backlog/`; (378) make the idempotency guard fire on code
state, not mere section existence, so a stale verdict is never shown as fresh.
Ordered 376 → 377 → 378: soundness fix first, biggest throughput win second,
robustness win last. The three are serialized on purpose (hard `Depends on`
edges) — they all edit the same `## Excellence` writer, so they compose in strict
order rather than shipping independently.

One invariant binds all three: the `## Excellence` block must be defined by a
single field spec that BOTH run paths render identically — the headless append in
`polish-judge.sh` and the `AI_MODE=emit` `APPEND_STEP` prompt. That parity is
already broken today (the emit prompt stamps only date/verdict/Summary while the
headless path also stamps Tasks-filed / Files-reviewed / Context-source), so 376,
landing first, unifies the spec once; 377 and 378 then add their fields to that
one spec instead of re-patching each path independently. Fix parity at the
source, and every later field inherits it for free.

## Why

`polish` is the post-work quality surface, so any gap in it is a gap in the
quality of everything shipped through SprintBias. 376 is a soundness bug (a judge
trusting an audit that never ran), not an optimization, which is why it leads.
Grouping the three keeps their shared touch-points — `polish-judge.sh`,
`audit-excellence.md`, and the `## Excellence` section format — evolving
together instead of colliding.


## Member tasks

<!-- One "- #ID — short title" line per task; [x] means the task is in done/.
     IDs are references — resolve each against docs/tasks/*/ for location. -->


<!--
AI: Full plan guidance is in DOCUMENTATION.md → Plans. A plan is a relational
index, not a container: Status is DRAFT | READY | STARTED, and members stay in
their own lifecycle folders. Keep it plain text — no emoji, color, or ASCII art.
See docs/sprintbias/guides/doc-style.md
-->
- #376 — Gate the excellence judge's presumed-correct claim on an actual code-audit marker
- #377 — Route vital-few excellence findings to next/ instead of always backlog/
- #378 — Make the ## Excellence idempotency guard code-state-aware

## Plan Think

Reviewed as Platform Architect + Experience Officer through best-practice,
elegant-design, and antifragility lenses. The plan's theme, membership, and order
were already sound — nothing merged, split, cut, or deferred. Two real gaps
surfaced by reading the actual `polish-judge.sh`, both now folded into 376/377.
Full analysis: docs/tmp/plan-think-24.md.

Top findings:
1. **Emit-path parity is already broken at the base.** The headless append
   stamps date/verdict/tasks-filed/files-reviewed/context-source; the emit
   `APPEND_STEP` prompt stamps only date/verdict/Summary. Each task bolting "and
   on emit too" onto its own field patches parity on a divergent base and invites
   drift. 376 (first) now owns unifying the block into ONE field spec both paths
   render; 377/378 extend that spec. Lens: best-practice (DRY / single source).
2. **377's FILED counter is blind to `next/`.** `polish-judge.sh` counts filed
   tasks by diffing `backlog/*.md` before/after the run. The moment 377 routes a
   filed task into `next/`, that task leaves `backlog/` and the delta nets it to
   zero — undercounting exactly the warm-routed tasks, and the `FILED — n (x →
   next/, y → backlog/)` split can't be produced by the counter that exists. 377
   now requires the counter to see both destinations. Lens: correctness.
3. **Serialization stands.** Hard `Depends on` edges (376 → 377 → 378) are the
   right call — the shared `## Excellence` writer is one collision point, and
   soundness-first ordering is correct.
