# Task 379: Align sprintbias_excellence_rules field set with the single ## Excellence spec so plan-polish emit stops dropping the code-state stamp

**Feature**: none
**Created**: 2026-08-27
**Docs**: none
**Plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 1
**Reworked**: 0

## Problem

Task 376 set out to make the `## Excellence` field set render from ONE source so
new fields "cannot drift between paths." It unified the two paths inside
`polish-judge.sh` (the headless appender and the emit `APPEND_STEP`) onto the
`sprintbias_excellence_block` renderer. But `plan polish` in **emit** mode does
not use that renderer — it fans out to subagents whose entire spec is the
`sprintbias_excellence_rules` prose fragment (`lib.sh`), a THIRD, hand-listed
copy of the field set. That copy already diverges: it names date, verdict,
correctness, tasks filed, routing, files reviewed, context source, and Summary —
but **not `code state`** (`lib.sh:2153-2154`). So the very drift 376 declared it
was eliminating is live on the plan-polish emit path today.

## Why

- **The single-spec promise is not actually single.** `sprintbias_excellence_block`
  (`lib.sh:2032-2043`) is the canonical spec both `polish-judge.sh` paths render.
  `sprintbias_excellence_rules` (`lib.sh:2149-2168`) is a parallel prose spec the
  plan-polish emit path (`plan-polish.sh:186,206,229`) hands to its judging
  subagents — and it is missing a field. Every future field (as 377/378 added,
  and any later one) must be hand-mirrored into this second list, which is exactly
  the per-path drift 376 exists to prevent.
- **It silently defeats the code-state freshness guard on that path.** An
  `## Excellence` section written from this fragment carries no
  `- **Code state**:` line. `sprintbias_excellence_state_key` (`lib.sh:2086-2096`)
  then returns empty, so `sprintbias_excellence_is_stale` (`lib.sh:2112-2123`)
  degrades to "not stale" — its documented safe fallback for an unstamped section.
  Net effect: a member judged via `plan polish` under emit mode can never be
  auto-re-judged when its code changes (the 378 guarantee); it reverts to
  "judged once." Graceful, but the freshness feature is silently absent on a real
  shipping path (emit is the dual-provider host mode).

## Success criteria

- [x] The `## Excellence` field set has exactly one authority. The plan-polish
      emit path renders `sprintbias_excellence_block` per member — with the
      deterministic values (code-state hash, correctness, file count, context
      source) injected by the shell and placeholders for what the subagent fills
      (verdict, tasks filed, routing, Summary) — exactly as `polish-judge.sh`
      emit's `APPEND_STEP` does (`polish-judge.sh:186-196`). A field added once to
      the block appears on every path. Do NOT try to keep a hand-listed field list
      in the prose in sync; that is the drift this task exists to end.
- [x] An `## Excellence` section produced by `plan polish` in emit mode carries
      the `- **Code state**:` stamp on the same terms as the other paths, so
      `sprintbias_excellence_is_stale` can detect staleness for emit-plan-judged
      members instead of degrading to always-skip.
- [x] `correctness:` (376) and `routing:` (377) also stay in lockstep across all
      three paths through the one authority — no field lives on some paths only.
- [x] Acceptance (deterministic, no live model): under `SPRINTBIAS_MODE=emit`,
      `plan polish <id>` emits a per-member instruction whose rendered
      `## Excellence` block carries that member's real code-state hash and
      correctness value; a member with no prior `## Excellence` section resolves
      and stamps identically (first-timers are stamped, not left blank).

## Notes

- `sprintbias_excellence_rules` is the judging METHOD, not just a field list — it
  carries the correctness rule (376), the warm-route/routing rule (377), and the
  VERDICT contract. Only ONE clause inside it hand-lists the output fields. Keep
  the rules prose as the single source of *how to judge*; replace ONLY that
  field-listing clause with the rendered `sprintbias_excellence_block`. Deleting
  or rewriting the whole fragment would regress 376's and 377's behavioral rules.
  This mirrors `polish-judge.sh`, which already keeps the method (`PROMPT`) and
  the field spec (`APPEND_STEP`, block-rendered) separate.
- Inject deterministic values, do not let the model derive them. Precompute each
  member's code-state hash, correctness, file count, and context source in
  `plan-polish.sh` and render them into that member's block; the subagent copies
  them verbatim and fills only verdict/tasks/routing/Summary. This preserves the
  "model cannot drift it" property 376/378 valued and, as a bonus, closes the
  correctness gap (today correctness is model-derived from prose on this path).
- Resolve for EVERY to-judge member, including first-timers. The 378 pre-filter
  (`plan-polish.sh:149-158`) routes members with no `## Excellence` section
  straight to `TO_JUDGE` without resolving their manifest, and calls `is_stale`
  only for members that already have a section. Rendering a per-member block needs
  the hash/correctness/file-count/context-source resolved for all of them — work
  the loop does not do today.
- Watch the global clobber 378 flagged. `sprintbias_change_manifest` (called
  inside `is_stale` and by any direct resolve) overwrites the
  `SPRINTBIAS_CHANGED_FILES` / `SPRINTBIAS_CONTEXT_SOURCE` globals each call, so
  capture each member's values into locals before the next loop iteration.
- Emit-only. The exec path already routes each member through `polish-judge.sh`
  (`plan-polish.sh:247`), which renders the block correctly — do not touch it.
- Scoped separately from 376/377/378 on purpose: all three define "both run
  paths" as `polish-judge.sh`'s headless + emit `APPEND_STEP`; none covers the
  plan-polish emit renderer, so this drift is out of their acceptance and needs
  its own task.

## References

docs/sprintbias/lib.sh
docs/sprintbias/scripts/plan-polish.sh
docs/sprintbias/scripts/polish-judge.sh

## Refine (round 1)

**Sharpened:** Committed criterion 1 to the proven single-source shape —
plan-polish emit renders `sprintbias_excellence_block` per member (deterministic
fields injected by the shell, placeholders for the subagent), mirroring
`polish-judge.sh` emit's `APPEND_STEP` — and dropped the weaker "generate the
prose from the spec" branch. Added Notes distinguishing the rules fragment
(judging METHOD — keep) from its field-listing clause (replace with the block),
the first-timer resolution requirement, and the `sprintbias_change_manifest`
global-clobber guard. Added a deterministic emit-mode acceptance criterion.

## Completed

Ended the third-path drift: `plan polish` in emit mode no longer hands its
subagents the loose `sprintbias_excellence_rules` prose (a hand-listed field set
missing `code state`). The shell now renders a per-member `## Excellence` block
from the ONE spec (`sprintbias_excellence_block`) with each member's deterministic
fields baked in — the same pattern `polish-judge.sh` emit's `APPEND_STEP` already
uses — so the field set is single-sourced across all three excellence paths and
an emit-plan-judged section now carries the `Code state` stamp that 378's
staleness guard reads.

**What changed**

- **`lib.sh` — `sprintbias_excellence_rules`.** Removed the hand-listed field
  parenthetical (date, verdict, correctness, …) from the one clause that carried
  it. The fragment keeps the judging METHOD it owns (correctness rule from 376,
  warm-route/routing rule from 377, the VERDICT contract) and now instructs the
  subagent to write the `## Excellence` section EXACTLY as the pre-rendered block
  it is given, filling only the placeholders. The field set lives solely in
  `sprintbias_excellence_block`.
- **`plan-polish.sh` — emit path.** Replaced the shared `_rules`-only,
  path-only member list with a per-member render loop: for each finished
  member, resolve its change manifest (`sprintbias_change_manifest`), content
  hash (`sprintbias_manifest_state_hash`), correctness
  (`sprintbias_correctness_state`), file count, and context source into locals
  (guarding against the `SPRINTBIAS_CHANGED_FILES`/`_CONTEXT_SOURCE` global
  clobber), then render `sprintbias_excellence_block` with those values injected
  and verdict/tasks/routing/Summary left as placeholders. Both emit branches
  (orchestration-capable and the single-agent fallback) now hand each member its
  own rendered block. The exec path was already correct and is untouched.

**Verification**

- `bash -n` clean on `lib.sh` and `plan-polish.sh`.
- Emit-mode acceptance (`SPRINTBIAS_MODE=emit ./sprint.sh plan polish 24 --force`):
  the emitted orchestration prompt carries a per-member `## Excellence` block for
  each finished member (376, 377), each with a real, non-empty `Code state` hash
  (`86350a547e3daeaf`), a resolved `Correctness: unverified`, `Files reviewed: 10`,
  and a `Context source`, while verdict/tasks/routing/Summary remain placeholders.
  Resolution runs per member regardless of whether a prior section exists, so a
  first-time member is stamped identically.

**Not done here (human step):** `./ship.sh` to mirror `lib.sh` + `plan-polish.sh`
into `src/` and bump the version — required before installing into a live project
to test.

### Files changed
docs/sprintbias/lib.sh
docs/sprintbias/scripts/plan-polish.sh
