# Task 380: Add a shell-side observability signal when an excellence audit exceeds the warm-route cap

**Feature**: none
**Created**: 2026-08-27
**Docs**: none
**Plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

The excellence warm-route lane (task 377) rests entirely on a 1–2 cap so the
deep-judge cannot fast-track a whole audit into `next/`. That cap is the
load-bearing guardrail for `next/` discipline, yet it is enforced only as prose
in the protocol and the prompt — the shell that runs the judge has no backstop
and no signal when a run blows past it. `polish-judge.sh` already computes
`NEXT_FILED` from a before/after directory diff (docs/sprintbias/scripts/polish-judge.sh:272),
so it knows exactly how many findings a run warm-routed, but it reports that
number without ever flagging an over-cap run. An operator (or a misbehaving
model) that warm-routes 5 findings sees a normal `FILED — 5 (5 → next/, …)`
line with nothing calling out that the cap was ignored. The one guarantee that
keeps the warm lane trustworthy is invisible at the exact moment it is violated.

## Why

- `polish-judge.sh` warm-routes with no mechanical or observability backstop:
  `NEXT_FILED` (docs/sprintbias/scripts/polish-judge.sh:272) is rendered into the
  verdict/echo (`:359`) and the `## Excellence` `Routing` field (via
  `sprintbias_excellence_block`, docs/sprintbias/lib.sh:2032) with no comparison
  against the 1–2 cap the protocol declares
  (docs/sprintbias/ai/audit-excellence.md:126).
- `plan-polish.sh` aggregates `NEXT_TASKS` across members
  (docs/sprintbias/scripts/plan-polish.sh:295) and prints the rollup split
  (`:310`) with the same blind spot — a plan run that warm-routes far more than
  its members should is indistinguishable from a well-behaved one.
- The cap is the design's stated tension-resolver ("throughput vs `next/`
  discipline, resolved by hard-capping" — task 377 Plan Think). A guarantee that
  self-reports nothing when broken erodes exactly the trust the cap was added to
  protect.

## Success criteria

- [ ] When a single-piece excellence run warm-routes more than the cap (>2 into
      `next/`), `polish-judge.sh` emits a clear over-cap warning to stderr naming
      the count and the cap — the verdict/exit behavior otherwise unchanged (the
      tasks still land; the run is not aborted).
- [ ] `plan polish`'s rollup surfaces the same signal when the per-run or
      aggregate warm-route count exceeds the cap, so a plan pass cannot hide an
      over-cap run inside the "Done:" line.
- [ ] The cap value lives in ONE place (a named constant / lib helper) shared by
      the warning and any prose that cites "1–2", so the number cannot drift
      between the guard and the protocol text.
- [ ] No product code is edited by the judge and the warm-route flow is
      otherwise unchanged; this adds observability, not a hard reject (decide and
      document whether an over-cap run should ever hard-fail, or only warn).

## Notes

- This is a deliberate hardening of a soft, agent-driven constraint — keep
  warm-routing judgment-driven; the ask is a visible signal when the cap is
  exceeded, not a new gate that blocks filing. Confirm the warn-vs-reject
  decision before building.
- Reuse the counts already computed (`NEXT_FILED` in polish-judge.sh,
  `NEXT_TASKS` in plan-polish.sh) — do not add a second counting mechanism.

<!-- sb:hint  Optional helpful hints that assist the developer: constraints, edge
     cases, gotchas. Guidance from answered questions also lives here when it
     shapes how (and is not already a success criterion). Leave empty if none. -->

## References

<!-- sb:hint  Direct paths to docs or files known to be related. One path per
     line. Leave empty if none. -->

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
