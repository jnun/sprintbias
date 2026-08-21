# Plan 22: Fix the audit run-result interpretation mechanism

**Created**: 2026-08-20
**Status:** STARTED

## Goal

Make SprintBias interpret a headless audit run once, correctly, on every
provider. Today the polish and deps audits read each run's result three separate
times (verdict grep, is_error parse, summary parse), re-derive the failure kind
by matching human prose, and assume Claude Code's JSON shape in lib.sh — so a
non-Claude run mis-diagnoses silently. This plan replaces that with a single,
profile-owned interpretation of a run's result, judged and shaped by the audit
that opens it.

The plan runs in two beats. **First, #364 audits the whole mechanism top to
bottom** — every site that reads a run result, every profile's actual result
shape — and settles the target design against the five lenses. **The audit's
output is the rest of this plan's tasks:** #364's "done" is the execute-ready
follow-on task(s) it files to backlog/ (the interpreter, the per-site migration,
the profile methods, retiring the redundant parses). Nothing after the audit is
pre-decided — the audit instructs it.

## Phasing

This plan starts twice, by design. **Phase 1:** it is READY now with #364 as its
only member; `plan start 22` commits the audit to next/, it gets worked, and it
files the follow-on tasks to backlog/. **Phase 2:** reopen this plan
(`chat plan 22`), add those filed tasks as ordered members, and `plan start 22`
again to commit the newly-READY members. The plan is a living index — starting
it does not close it; it grows members as the audit produces them.

## Why

Fixes have been landing per-symptom (the max_turns mislabel was the latest). One
audit that maps the mechanism and fixes its shape once is cheaper than the next
five patches, and it is the only way the fix reaches non-Claude providers rather
than hardcoding the Claude result shape deeper.


## Member tasks

<!-- One "- #ID — short title" line per task; [x] means the task is in done/.
     IDs are references — resolve each against docs/tasks/*/ for location. -->

- #364 — Audit the headless-audit run-result interpretation mechanism end to end
- #365 — plan think: stream a real-time JSON run log to docs/tmp/ (like work/polish)
- #367 — Add a profile-owned single-pass run interpreter and shared honest-message builder
- #368 — Implement profile_interpret_run for grok and default profiles (incl. the no-JSON case)
- #369 — Retire the redundant run_error and extract_summary reads and per-site prose matching

Parallelism: #365 ∥ #364 — independent, disjoint files (#365 touches
plan-think.sh; #364 reads polish.sh/polish-judge.sh/deps.sh). #365 is a sibling
logging fix, not a #364 follow-on, so it does not wait on the audit. V1 runs
sequential; this note records the independence only.

Phase 2 (filed by #364, 2026-08-20): #367 → #368 → #369 run strictly in that
order — a dependency chain, not parallel. #367 lands the interpreter + shared
honest message + Claude profile and wires the four sites (trust win on Claude);
#368 makes it provider-correct on grok/default (the no-JSON case); #369 retires
the redundant reads and prose-matching so the interpreter is the single source
of truth. Reopen the plan and `plan start 22` to commit #367 first.

Out of scope — routed to a separate plan (decided 2026-08-20): #370 → #371
(polish --code action-bias + abort salvage, from audit #366) and #372 (extract
the shared stream_filter into lib.sh, from audit #365) are siblings of this
work, not members. They concern polish --code behavior and logging plumbing, not
run-result interpretation, and keeping this plan scoped to the interpreter is the
clean-scope / context-cost call. #371 depends on #367 (this plan's interpreter):
a recorded cross-plan edge, respected at execution — not a reason to absorb it
here. Stand up their plan with `./sprint.sh newplan`.

## Plan Think

Dual-persona review (Chief Platform Architect / Chief Experience Officer). Full
critique: docs/tmp/plan-think.md. Verdict: strong plan, no structural changes —
the sharpenings are on member #364, not the plan.

Top 3 findings:
1. `default.sh` emits no JSON at all, so the provider-coupling is worse than a
   key-name mismatch — one profile has no result object to interpret and the
   interim helper silently calls that "finished." The audit's per-profile
   inventory must record the no-JSON case as first-class.
2. The user-facing honest message (the trigger was a max_turns abort mislabeled
   "could not parse a verdict") is under-weighted vs. the internal record shape;
   make the message vocabulary an explicit named output of the audit's decision.
3. Guard the Phase-1→Phase-2 handoff: filed tasks must set both sides of the
   reverse index (`**Plan**: 22` + a member line), and "keep-and-patch, file
   nothing" is a valid terminal outcome that simply closes the plan.

<!--
AI: Full plan guidance is in DOCUMENTATION.md → Plans. A plan is a relational
index, not a container: Status is DRAFT | READY | STARTED, and members stay in
their own lifecycle folders. Keep it plain text — no emoji, color, or ASCII art.
See docs/sprintbias/guides/doc-style.md
-->
