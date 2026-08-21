# Task 372: Extract the duplicated stream-json _stream_filter into a shared lib.sh helper (work.sh + plan-think.sh)

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

The `_stream_filter` function — an embedded ~35-line Python renderer that turns
stream-json events into one readable progress line per step — now exists as a
byte-identical copy in two scripts: `work.sh` (`docs/sprintbias/scripts/work.sh:1057`)
and `plan-think.sh` (`docs/sprintbias/scripts/plan-think.sh:160`, added by
task 365). Both must stay in lockstep by hand. When the renderer needs a
change — a new tool-hint key, a formatting fix, a field rename in the event
schema — a developer will fix one copy and the other will silently drift,
producing inconsistent live progress across commands. As more commands adopt
streaming logs (polish is a likely next), the duplication compounds.

## Why (excellence audit, task 365)

Surfaced auditing task 365. The change is otherwise sound and meets its goal;
this is a design-fit / maintainability finding, not a defect. The lib.sh
`sprintbias_*` helpers are the established shared home for exactly this kind of
cross-script logic, and the task-365 notes already flagged the awkwardness
("`_stream_filter` is local to `work.sh`") — the copy was a deliberate, pragmatic
choice that this task pays down.

## Success criteria

- [x] A single `sprintbias_stream_filter` (or similarly named) helper lives in
      `docs/sprintbias/lib.sh` and renders stream-json events identically to
      today's `_stream_filter`.
- [x] `work.sh` and `plan-think.sh` both call the shared helper; neither carries
      its own inline copy of the Python renderer.
- [x] Live terminal progress for `work` and `plan think` is unchanged (same
      `->` / `·` / `==` / `!` lines), and the raw log file still captures the
      full stream.
- [x] The `python3`-absent fallback (`|| cat`) is preserved.
- [x] `./ship.sh` mirrors the change into `src/` and bumps `VERSION`.

## Notes

The two copies are byte-identical as of task 365 — a `diff` of the function
bodies confirms it, so extraction is a lift-and-share with no behavior
reconciliation needed. Keep the helper's output contract stable so existing
log consumers and eyeballed progress don't shift.

## Plan Think

### Perspective check

**Chief Platform Architect.** Pure maintainability win, and the Architect signs
off with little hesitation. Two byte-identical ~35-line Python renderers that
must stay in lockstep by hand are a guaranteed future drift bug — fix one, the
other silently rots. lib.sh's `sprintbias_*` helpers are the established shared
home for exactly this cross-script logic, so the task lands in the right place
architecturally. The Architect's only real concern is **regression risk during
the lift**: the extraction must be truly behavior-neutral. The success criteria
cover this well — identical `-> / · / == / !` output, raw log still captures the
full stream, and the `python3`-absent `|| cat` fallback preserved. Because the
two copies are byte-identical today (confirmed by diff), this is a lift-and-share
with no reconciliation, which is the lowest-risk form of dedup. The Architect
would add: verify both call sites still render correctly after extraction, not
just one, since the whole point is that both stay in sync.

**Chief Experience Officer.** The CXO has the least direct stake here — this is
plumbing, not a user-facing surface — but is not indifferent. Consistent live
progress rendering across `work` and `plan think` *is* an experience property:
when the same event schema renders the same way everywhere, users build a
reliable mental model of what the tool is doing. Drift between commands (one shows
a new tool-hint, the other doesn't) quietly erodes that. So the CXO supports the
extraction as invisible-infrastructure that protects a visible consistency, and
insists on exactly what the criteria already require: the terminal output must not
shift by a single character. As more commands adopt streaming (polish is the
named next), one shared renderer means every future command inherits consistent
progress for free — an experience dividend from a backend cleanup.

### Tension and resolution

There is no meaningful tension between the personas on this task — both want it,
for compatible reasons (the Architect for maintainability, the CXO for
cross-command consistency). The only tension worth naming is **priority within
the plan**: this is the lowest-urgency member. It fixes a latent drift risk, not
an active user-facing failure, whereas #370 and #371 fix runs that today burn
budget or destroy work. That argues for sequencing it last (or running it in
parallel, since it touches disjoint files — lib.sh/work.sh/plan-think.sh, never
polish.sh). It resolves cleanly: **do it, but not first.** Its independence is
actually its strength — with no shared files and no dependency on #367, it can be
picked up any time a contributor wants a clean, self-contained win, including in
parallel with the polish work. The plan's recorded parallelism (#372 ∥ {#370,
#371}) captures this correctly.

## References

docs/sprintbias/lib.sh
docs/sprintbias/scripts/work.sh
docs/sprintbias/scripts/plan-think.sh

## Questions

**Status: READY**

### Already complete
None — no matching implementation found. What I verified:
- The renderer is duplicated as claimed. `work.sh:1057-1092` and
  `plan-think.sh:160-195` each carry an inline `_stream_filter()` — the Python
  bodies (hint keys, `->`/`·`/`==`/`!` lines, `duration_ms`/cost formatting)
  are byte-identical, and both wrap the same `command -v python3 … || cat`
  fallback. Extraction is a true lift-and-share; no behavior reconciliation.
- No `sprintbias_stream_filter` (or similar) exists in `lib.sh` yet. lib.sh is
  the established home for cross-script `sprintbias_*` helpers, so the target
  location is correct.
- Both call sites pipe `… | tee "$log" | _stream_filter` (work.sh:1110,
  plan-think.sh:231); the raw-log tee is upstream of the filter, so log capture
  is independent of the helper and stays intact after the swap.

### Remaining work
- Add `sprintbias_stream_filter` to `docs/sprintbias/lib.sh`, body copied
  verbatim from either existing `_stream_filter` (they are identical), keeping
  the `python3`-absent `|| cat`/`cat` fallback.
- Replace both inline `_stream_filter()` definitions with a call to the shared
  helper at each pipe site (work.sh, plan-think.sh); remove the now-dead local
  functions and their comment blocks.
- Verify BOTH call sites still render identically after the swap — `work`
  (display path) and `plan think` — not just one; the whole point is that they
  stay in sync.
- Run `./ship.sh` to mirror into `src/` and bump `VERSION`.

### Questions for the developer
None — task is fully defined.

## Completed

Extracted the byte-identical `_stream_filter` Python renderer into a single
shared `sprintbias_stream_filter` helper in `lib.sh`, placed next to
`sprintbias_run` (the run-routing home for streaming). Both `work.sh` and
`plan-think.sh` now pipe to the shared helper and no longer carry an inline
copy; their local comment blocks were replaced with a one-line pointer to the
helper. The `python3`-absent `|| cat` / `cat` fallback is preserved verbatim.

Verified: `bash -n` clean on all three files; a functional test fed the four
event shapes (`tool_use`, assistant `text`, non-JSON, `result`) through the
helper and it emitted the identical `-> / · / ! / ==` lines and cost/duration
formatting as before. The raw-log `tee` is upstream of the filter at both call
sites, so log capture is unchanged. `./ship.sh` mirrored the change into `src/`
(clean-mirror verified) and bumped `VERSION` 0.0.102 -> 0.0.103.

### Files changed
docs/sprintbias/lib.sh
docs/sprintbias/scripts/work.sh
docs/sprintbias/scripts/plan-think.sh

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
- **Files reviewed**: 5
- **Context source**: task ## Completed section

Task 372 extracts the byte-identical `_stream_filter` Python renderer out of `work.sh` and `plan-think.sh` into a single `sprintbias_stream_filter` helper in `lib.sh`, placed next to `sprintbias_run` (the streaming-run home). This is a textbook lift-and-share: both call sites now pipe `… | tee "$log" | sprintbias_stream_filter`, the inline copies and their comment blocks are gone, the `python3`-absent `|| cat` fallback is preserved verbatim, and the change is mirrored into `src/` with `VERSION` bumped. I confirmed both scripts source lib.sh, `bash -n` is clean on all three, and a functional pass through the shared helper emits the exact `-> / · / ! / ==` lines and cost/duration formatting the contract specifies. The work fully meets its goal and clears the excellence bar — the only observation is a one-line documentation-index omission not worth filing.

### Findings
- [NIT] The new public `sprintbias_stream_filter` is absent from the lib.sh header "Provides:" catalog (`docs/sprintbias/lib.sh:9-86`), which lists every other helper including its neighbors `sprintbias_run` and `sprintbias_interactive_ok`. Minor index drift; add one line if touched again. Not filed.
