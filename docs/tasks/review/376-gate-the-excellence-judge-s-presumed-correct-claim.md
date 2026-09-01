# Task 376: Gate the excellence judge's presumed-correct claim on an actual code-audit marker

**Feature**: none
**Created**: 2026-08-27
**Docs**: none
**Plan**: 24
**Depends on**: none
**Dependents**: 377
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

The excellence deep-judge presumes a correctness pass that its command shape
never establishes. `audit-excellence.md` opens by asserting *"The code audit
(`polish --code`) already checked correctness... the work is presumed
correct,"* and `polish-judge.sh` repeats that as a hard rule in its prompt. But
nothing in the deep-judge path runs, or even checks for, a prior `polish
--code`. `polish --code` is the only mode that writes a `## Audit` section; the
deep-judge never reads for it. So a `polish <id>` on never-audited work rests
its entire "presumed correct" foundation on something that did not happen — and
a judge that presumes an audit that never ran can wave a real defect through
under "not my job — presumed correct." This is a soundness gap (silent false
assurance), not a nicety.

## Success criteria

- [x] The deep-judge (`polish-judge.sh`) reads the target task's `## Audit`
      section (the `polish --code` marker) before it judges — both whether it
      exists AND its recorded `**Final verdict**:`.
- [x] "Audited" means the code audit ran AND passed. Presence alone is not
      enough: `polish.sh` writes a `## Audit` section for FAIL/BLOCKED/UNCLEAR
      verdicts too (only PASS/FIXED are clean). Correctness is presented as
      established ONLY when a `## Audit` block records a PASS or FIXED verdict.
- [x] Otherwise correctness is never silently presented as established. The run
      emits a clear notice and the appended `## Excellence` section stamps:
      `correctness: audited` (PASS/FIXED `## Audit` present) ·
      `correctness: unverified` (no `## Audit`, or an aborted audit note) ·
      `correctness: failed` (a `## Audit` recording FAIL/BLOCKED/UNCLEAR) — the
      last is worse than unverified and the notice must say so.
- [x] `audit-excellence.md`'s opening posture is rewritten so its "presumed
      correct" claim is *conditional on that marker being present* rather than
      stated as fact — when unverified, the judge is told to treat a stumbled-on
      defect as a DEFECT finding recommending `polish --code`, not to wave it by.
- [x] Acceptance: a deep-judge on a task with no `## Audit` section cannot
      produce an `## Excellence` section that implies it rests on a passed code
      audit.
- [x] Both run paths carry the stamp on identical terms, from ONE field spec.
      Today the two paths already diverge: the headless append stamps
      date/verdict/tasks-filed/files-reviewed/context-source, while the emit
      `APPEND_STEP` prompt (`AI_MODE=emit`) stamps only date/verdict/Summary.
      Before adding `correctness:`, unify the `## Excellence` field set into a
      single source both paths render — the headless appender and the emit prompt
      — so this task's new field, and 377's/378's later fields, land once and
      cannot drift between paths. The emit path must stamp the full field set,
      including `correctness: audited|unverified|failed`, on the same terms as
      headless. (Mechanism is the implementer's call — a shared lib helper that
      emits the block, or a single documented field spec both paths cite — but the
      spec must exist in exactly one place.)
- [x] The "unverified"/"failed" notice is actionable — it points at the fix
      (`./sprint.sh polish --code <id>`), not just a warning.
- [x] `help/polish.md` (and `DOCUMENTATION.md`'s polish text) are updated to
      describe the new `correctness:` field on the `## Excellence` section, so
      the shipped docs do not go stale.
- [x] No product code is edited by the judge; mode boundaries stay crisp (this
      task does not merge `--code` into the deep-judge — see Notes).

## Notes

- The `## Audit` marker is written by `polish.sh` code mode (`polish.sh:748-761`,
  the `## Audit` / `## Audit (aborted …)` append). Two things must be read, not
  one: (a) the heading — the plain `## Audit` (exact-match, mirroring
  `sprintbias_excellence_has_section`) vs. the aborted variants `## Audit
  (aborted …)`, which never count as verified; and (b) the `**Final verdict**:`
  line inside a plain `## Audit` block, because that block is written for
  FAIL/BLOCKED/UNCLEAR runs too — only PASS/FIXED are clean. Keying on heading
  presence alone would stamp `audited` on a task whose audit failed, recreating
  the exact false-assurance this task exists to kill.
- Prefer the smallest change that closes the gap. The default should be
  detect-and-stamp (warn + `correctness: unverified`), which keeps the mode
  boundary crisp and is honest. An opt-in `--audit-first` that runs `polish
  --code` before judging is a reasonable secondary lever but must not become the
  default, and must not blur the two modes' separation.
- Add a shared predicate next to `sprintbias_excellence_has_section` in `lib.sh`
  (e.g. `sprintbias_audit_has_section`) so `plan polish` gets the same behavior
  through the one judge home.
- Do first — the handoff sequences this ahead of 377/378 because it is a
  soundness fix, not a throughput or robustness improvement.

## References

docs/sprintbias/scripts/polish-judge.sh
docs/sprintbias/ai/audit-excellence.md
docs/sprintbias/scripts/polish.sh
docs/sprintbias/lib.sh
docs/sprintbias/help/polish.md

## Plan Think

- **Platform Architect:** the honest win here is data integrity of the verdict —
  an `## Excellence` section that implies a passed code audit when none ran is
  corrupt state. Gating the claim on the `## Audit` marker, via a shared
  `sprintbias_audit_has_section` predicate mirroring the existing
  `sprintbias_excellence_has_section`, keeps one home for the rule.
- **Experience Officer:** operators trust the verdict more when it is candid
  about what it did and did not check. The `correctness: unverified` stamp plus
  an actionable "run `polish --code` first" pointer turns a silent assumption
  into a visible, fixable state.
- **Tension → resolution:** the tempting fix is to auto-run `--code` first, but
  that blurs the two modes. Best-practice + elegant-design lenses both favor
  detect-and-stamp as the default, `--audit-first` as an opt-in — mode
  boundaries stay crisp. Lens driving the change: **best practice** (no false
  assurance) with an **antifragility** assist (the gap becomes a surfaced signal).
- **Sequencing:** first in the plan — soundness leads. It defines the
  `correctness:` field on the `## Excellence` block that 377 and 378 extend, so
  it also unblocks their shared writer.

### Alignment pass (plan 24 re-review)

- **Both personas, one added mandate:** reading `polish-judge.sh` exposed that the
  two run paths already stamp DIFFERENT `## Excellence` fields — headless writes
  five fields + Summary, the emit `APPEND_STEP` prompt writes three. Adding
  `correctness:` to that split base would deepen the drift. **Lens: best practice
  (DRY / single source of truth).** Because 376 lands first and touches the block
  format anyway, it now owns unifying the field set into one spec both paths
  render, so its new field — and 377's/378's — land once. This sharpens the
  existing "both run paths carry the stamp" criterion into "from ONE spec"; it is
  not new scope, it is the elegant-design way to satisfy the criterion already
  present without inviting per-path drift.
- **Left as-is:** the soundness core (gate the claim on a PASS/FIXED `## Audit`
  marker) was already sharp and correct — untouched. Task stays in backlog/,
  malleable; no delta task needed.

## Questions

**Status: READY**

### Already complete

None — no matching implementation found. The gate is not yet built. What I
verified in the current code:

- `polish-judge.sh` never reads for a `## Audit` marker. It builds the prompt
  (lines 133-159) and appends `## Excellence` (lines 244-258) with no
  audit-state check anywhere in the path.
- The two run paths already diverge exactly as the brief states: the headless
  appender stamps Date/Verdict/Tasks filed/Files reviewed/Context source +
  Summary (lines 249-255), while the emit `APPEND_STEP` prompt asks only for
  "date, verdict, and your Summary" (lines 128-131). No shared field spec.
- `audit-excellence.md` states "The work is presumed correct" as unconditional
  fact (line 17, and the prompt echo at polish-judge.sh:137). A DEFECT-finding
  path already exists (lines 17-20), but the presumption is not gated on any
  marker.
- The `## Audit` writer is confirmed at `polish.sh:748-761`, writing
  `**Final verdict**: $VERDICT` where VERDICT ∈ PASS/FIXED/FAIL/BLOCKED/UNCLEAR
  (only PASS/FIXED clean), plus the aborted variants `## Audit (aborted …)` at
  polish.sh:732-746. The Notes' heading/verdict reading plan matches this exactly.
- `sprintbias_excellence_has_section` (lib.sh:1985-1987) is the exact-heading
  predicate to mirror for the new `sprintbias_audit_has_section`.
- `help/polish.md:77` describes the current three-field Excellence section — no
  `correctness:` yet, so it will go stale as the brief warns.

### Remaining work

- Add `sprintbias_audit_has_section` next to `sprintbias_excellence_has_section`
  in `lib.sh` — read both the plain `## Audit` heading (exact-match, excluding
  the `## Audit (aborted …)` variants) AND its `**Final verdict**:` line; only
  PASS/FIXED count as audited.
- In `polish-judge.sh`, derive a correctness state (audited / unverified /
  failed) before judging and emit an actionable notice pointing at
  `./sprint.sh polish --code <id>` for the unverified/failed cases (failed
  flagged as worse than unverified).
- Unify the `## Excellence` field set into ONE spec both paths render — the
  headless appender and the emit `APPEND_STEP` prompt — then add
  `correctness: audited|unverified|failed` once so it (and 377/378's later
  fields) cannot drift between paths.
- Rewrite `audit-excellence.md`'s "presumed correct" posture to be conditional
  on the marker: when unverified, tell the judge to treat a stumbled-on defect
  as a DEFECT finding recommending `polish --code`, not to wave it by. Keep the
  never-edit-code / mode-boundary rules intact.
- Update `help/polish.md` and `DOCUMENTATION.md`'s polish text to describe the
  new `correctness:` field.
- Verify the acceptance property: a deep-judge on a task with no `## Audit`
  section cannot emit an `## Excellence` section implying a passed code audit.
- `./ship.sh` after the docs/ changes land (lib.sh, both scripts, ai/, help/,
  DOCUMENTATION.md all mirror).

### Questions for the developer

None — task is fully defined.


## Completed

Closed the soundness gap: the excellence deep-judge no longer presumes an
audit that never ran. Correctness is now derived from the `## Audit` marker and
gates the judge's posture on every path.

**What changed**

- **`lib.sh` — the one home for the rule.** Added `sprintbias_audit_has_section`
  (mirrors `sprintbias_excellence_has_section`: exact `^## Audit$` heading, so
  the `## Audit (aborted …)` notes never count) and `sprintbias_correctness_state`
  (reads the latest `**Final verdict**:` → `audited` for PASS/FIXED, `failed`
  for FAIL/BLOCKED/UNCLEAR, `unverified` when no plain `## Audit` exists).
  `plan polish` exec routes through the judge and inherits this; `plan polish`
  emit inherits it through the updated `sprintbias_excellence_rules` fragment +
  the rewritten protocol.
- **`lib.sh` — one field spec.** Added `sprintbias_excellence_block`, the single
  renderer for the `## Excellence` section (date · verdict · **correctness** ·
  tasks filed · files reviewed · context source · summary). Both run paths now
  render it, ending the prior divergence (headless wrote 5 fields + Summary; the
  emit `APPEND_STEP` wrote 3).
- **`polish-judge.sh`.** Derives `CORRECTNESS` before judging; prints an
  actionable notice (unverified/failed both point at `./sprint.sh polish --code
  <id>`, and failed is flagged worse than unverified); feeds a conditional
  `CORRECTNESS_RULE` into the prompt (audited → audit altitude only; otherwise →
  do NOT presume correct, treat a stumbled-on defect as a DEFECT finding). The
  headless append and the emit `APPEND_STEP` both render
  `sprintbias_excellence_block`; the emit block bakes in the deterministic
  `correctness:` value so the model cannot drift it. Aborted note also carries
  the correctness line.
- **`audit-excellence.md`.** Opening + Posture rewritten: "presume correctness
  ONLY when a code audit passed," with the `audited`/`unverified`/`failed`
  states spelled out and the DEFECT-finding path for the un-audited case.
- **`help/polish.md` + `DOCUMENTATION.md`.** Document the new `correctness:`
  field and the conditional presumption.

**Verification**

- `bash -n` clean on `lib.sh` and `polish-judge.sh`.
- Unit-tested `sprintbias_correctness_state` across all states: no `## Audit`,
  PASS, FIXED, FAIL, BLOCKED, aborted-note-only, and two-blocks-latest-wins —
  all correct.
- Emit-mode acceptance: a task with no `## Audit` stamps `correctness: unverified`
  in the `## Excellence` block and tells the judge correctness is NOT established;
  a task with a PASS `## Audit` stamps `correctness: audited` and tells it
  correctness IS established.
- `./sprint.sh validate --commands` and `--docs`: clean, no drift.
- `./ship.sh`: mirrored the 5 files to `src/`, `src/` byte-clean, version
  0.0.111 → 0.0.112.

### Files changed
docs/sprintbias/lib.sh
docs/sprintbias/scripts/polish-judge.sh
docs/sprintbias/ai/audit-excellence.md
docs/sprintbias/help/polish.md
DOCUMENTATION.md
src/docs/sprintbias/lib.sh
src/docs/sprintbias/scripts/polish-judge.sh
src/docs/sprintbias/ai/audit-excellence.md
src/docs/sprintbias/help/polish.md
src/DOCUMENTATION.md
src/VERSION

## Excellence

- **Date**: 2026-08-27
- **Verdict**: FILED
- **Correctness**: unverified
- **Tasks filed**: 1
- **Routing**: 0 → next/, 1 → backlog/
- **Files reviewed**: 10
- **Context source**: task ## Completed section
- **Code state**: 37c9a803eed48f29

Task 376 closes a real soundness gap: the excellence deep-judge no longer presumes a code audit that never ran. It reads the `## Audit` marker via a new shared `sprintbias_correctness_state`/`sprintbias_audit_has_section` predicate pair, derives `audited`/`unverified`/`failed` deterministically, prints an actionable notice, feeds a conditional rule into the judge prompt, and stamps `correctness:` on the `## Excellence` block. The block was also unified onto a single renderer (`sprintbias_excellence_block`) that both `polish-judge.sh` paths (headless append + emit `APPEND_STEP`) share, and the protocol/help/DOCUMENTATION were rewritten to match. The work meets its goal end to end — the acceptance property (no `## Audit` → no implied pass) holds, and it integrates cleanly with `work.sh`'s audit-then-judge pipeline. The one altitude gap: the "single field spec" the plan explicitly promised is not actually single — `plan polish` in emit mode renders from a *third*, hand-listed spec (`sprintbias_excellence_rules`) that already drifted.

### Findings
- [ENHANCEMENT] `sprintbias_excellence_rules` (`lib.sh:2153-2154`) — the prose spec `plan polish` emit hands its subagents — omits `code state`, so it drifts from the unified `sprintbias_excellence_block` and silently defeats the code-state staleness guard for emit-plan-judged members (they revert to "judged once"). Filed.
- [NIT] `sprintbias_correctness_state` reads `**Final verdict**:` with a whole-file grep rather than scoping inside the `## Audit` block. Correct today (only `polish.sh`'s `## Audit` writes that string), but a future section adding that line would collide. Not worth filing.
- [NIT] `audit-excellence.md` Posture tells the judge to "stamp the state you were given," but in headless mode the shell renders the block and the agent never stamps; in emit the value is pre-baked. Harmless doc-vs-mechanism nuance.

- FILED → backlog/: docs/tasks/backlog/379-align-sprintbias-excellence-rules-field-set-with-t.md (default)

No BLOCKER — the correctness-gating goal is fully met. No DEFECT — the new shell logic (state derivation, latest-wins verdict, aborted-note exclusion, guard interaction) is sound on inspection. The filed item stays in `backlog/`: the fix is architectural (subagents lack a precomputed hash), not a small act-now edit.
