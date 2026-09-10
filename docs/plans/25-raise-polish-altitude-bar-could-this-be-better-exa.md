# Plan 25: Raise polish altitude bar: could-this-be-better examiner

**Created**: 2026-09-10
**Status:** STARTED

## Goal

Raise polish's post-work altitude bar from "it runs / looks fine" to a stacked
**"could this be better?"** examiner whose single source of truth is the
excellence protocol — and whose REOPEN kickbacks a human can skim. Finished
work is judged for real Efficiency and Antifragility, coverage is visible so a
silent skip cannot look like EXCELLENT, and when polish does reopen a task the
`## Rework` note leads with short titled Improve items instead of essay
checkboxes.

Six atomic improvements land in hard order on one shared surface
(`audit-excellence.md` → `refine.md` → report + Rework contracts → one
runtime/docs sync):

1. Sharpen Efficiency into concrete, scale-gated probes.
2. Add Antifragility as a first-class dimension (shared language with
   `plan think` / `chat`), without dropping Robustness edge coverage.
3. Align the refine sweep to that same dimension set and to excellence's
   Audit-marker correctness honesty (presume correct only when a passing
   `## Audit` is on file) — without rewriting the Rework kickback shape
   (that is step 5).
4. Make every excellence finding name its dimension and every excellence
   report show which dimensions were considered (observability of the judge).
5. Make `## Rework` scannable: short titled Improve items with one-line
   done-looks (user-story / technical-spec height), optional hints underneath,
   no brittle line-specific edit recipes, and Improve as the only remaining-work
   list (dogfood lesson from a real polish kickback).
6. Sync runtime prompts and help so a polish run cannot teach an older bar than
   the live protocols — including outdated dimension lists, unconditional
   "presume correct" on the sweep, and essay-style Rework kickbacks — and
   **prove** it on #388 with behavior acceptance: emit or stub-CLI deep-judge
   plus a REOPEN path must show coverage tags and scannable Improve done-looks.
   Protocol file edits alone do not close the plan.

Steps 4 and 5 run in parallel after step 3 because they own **partitioned**
surfaces: #387 owns the excellence **report** contract (and may only require
that refine Improve items use the same dimension *names* when naming gaps —
it does not rewrite Rework structure); #389 owns the refine **`## Rework`**
shape. That partition keeps two writers off the same section while still
sharing vocabulary.

Each phase leaves polish strictly better; together they produce cleaner, more
efficient, more trustworthy judgments — and kickbacks a developer can actually
read. Does not reopen plan 24's plumbing (correctness marker, warm-route,
code-state idempotency) and does not stuff altitude into `polish --code`.

## Why

Plan 24 made the excellence *machinery* honest and durable. Dogfooding and a
grounded read of the live files still show the *examiner* under-specified and
internally inconsistent; a later REOPEN kickback also showed the *human-facing
rework note* under-organized:

- Efficiency in `audit-excellence.md` is a soft one-liner agents can skim past.
- Antifragility is a first-class lens in `plan think` / `chat` but absent from
  polish — fragility can ship after a green excellence pass.
- Refine still always "presumes the work correct" in both `refine.md` and the
  `polish.sh` sweep prompt, even when no `polish --code` ran — plan 24 fixed
  that honesty for excellence, not for the sweep.
- Findings are freeform severity lines; nothing shows which dimensions were
  considered, so under-examination is invisible.
- A real `## Rework (round 1)` mixed action, rationale, and long anchors into
  each checkbox and duplicated the list under Questions — the gaps were right,
  the organization was not; line-specific edit recipes are brittle assumptions
  by the time `work` re-runs.
- Runtime prompts can still enumerate an outdated dimension list or always
  "presume correct," so a protocol upgrade without a sync task never reaches
  the run. Live drift today: `polish-judge.sh` still hardcodes the five old
  dimension names in its step list; `polish.sh`'s refine prompt still says
  "The work is presumed correct."

Grouping keeps that shared touch surface evolving in stack order instead of
colliding. Hard `Depends on` edges: 384 → 385 → 386 → {387, 389} → 388.
Protocol vocabulary first; refine parity next; report coverage and Rework
clarity in parallel after 386 (**partitioned ownership**, not two editors of
the same section); one capstone sync last so prompts and help cannot drift.

## Member tasks

<!-- One "- #ID — short title" line per task; [x] means the task is in done/.
     IDs are references — resolve each against docs/tasks/*/ for location. -->

- #384 — Sharpen polish excellence Efficiency probes for a could-this-be-better pass
- #385 — Add Antifragility as a first-class polish excellence dimension
- #386 — Align polish refine protocol with excellence dimensions and correctness honesty
- #387 — Make polish excellence findings report dimension coverage
- #389 — Make polish ## Rework notes scannable for humans and executors
- #388 — Sync polish judge prompts and help with upgraded excellence bar

## Plan Think

Reviewed again as Platform Architect + Experience Officer through best-practice,
elegant-design, and antifragility lenses. Membership and 384→385→386→{387∥389}→388
order stood; Goal/Why now name the #387/#389 ownership partition so parallel
work cannot race on `refine.md`'s Rework section. All six members remain in
backlog/ and were aligned in place — nothing merged, split, cut, or deferred.
Full analysis: docs/tmp/plan-think-25.md.

Top findings:
1. **Partition coverage from kickback shape.** #387 owns excellence-report
   observability; #389 owns `## Rework` scannability. They share dimension
   *names*, not a second editor of the Rework block. Lens: elegant design
   (one owner per section) + antifragility (no mid-stack merge conflict).
2. **Protocol is the source of truth; sync is the last mile.** Dimensions,
   probes, honesty, report shape, and Rework contract land in
   `audit-excellence.md` / `refine.md` first (384–387, 389); #388 is the single
   place that updates `polish-judge.sh`, the refine prompt in `polish.sh`, and
   help so runtime cannot teach the old bar. Lens: best practice (DRY) +
   antifragility (one sync closes drift).
3. **False assurance and silent skips are the trust failures.** Refine still
   always-presumes (#386 protocol, #388 runner string); findings hide which
   dimensions were considered (#387). Closing both makes polish stronger under
   agent skip-pressure, not merely greener. Lens: antifragility + CXO trust.

<!--
AI: Full plan guidance is in DOCUMENTATION.md → Plans. A plan is a relational
index, not a container: Status is DRAFT | READY | STARTED, and members stay in
their own lifecycle folders. Keep it plain text — no emoji, color, or ASCII art.
See docs/sprintbias/guides/doc-style.md
-->
