# Task 378: Make the ## Excellence idempotency guard code-state-aware

**Feature**: none
**Created**: 2026-08-27
**Docs**: none
**Plan**: 24
**Depends on**: 377
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 1

## Problem

The `## Excellence` section is the deep-judge's idempotency signal: once
present, a re-run skips the task (absent `--force`). But the guard
(`sprintbias_excellence_has_section` in `lib.sh` — a bare `grep` for the
`## Excellence` heading) keys on *"was this ever judged,"* not *"was this judged
as it currently stands."* The stamped section records date, verdict, and file
count but no reference to the audited code state. So if the code moves after the
audit, the section is stale — yet nothing re-triggers a judge, and the stale
verdict is presented as current. This is a robustness gap: a stale verdict shown
as fresh.

## Success criteria

- [x] The `## Excellence` section is stamped with what code state it judged — a
      content hash of the audited files' current contents (the resolved manifest,
      not the git-diff text, which churns on line numbers), and optionally the
      commit ref — added as a field on the single `## Excellence` spec 376
      unifies, so both run paths (headless append and emit `APPEND_STEP`) stamp
      the state key identically alongside the existing date/verdict fields.
- [x] On re-run: the guard skips only when the stamp still matches the current
      code state; when the audited files have moved since, it re-judges rather
      than skipping.
- [x] A re-judge REPLACES the prior `## Excellence` section (or supersedes it in
      place) rather than stacking a second one — the "don't stack duplicate
      sections" property the current guard provides is preserved.
- [x] `--force` still re-judges unconditionally.
- [x] The state stamp is written on both run paths — headless (`polish-judge.sh`
      append) and emit (`APPEND_STEP` prompt) — so an emit-mode judgment is
      re-triggerable on the same terms as a headless one.
- [x] Acceptance: editing an audited file after an audit makes the next `polish
      <id>` re-judge automatically; an unchanged tree still skips with the
      "already judged" message.
- [x] `help/polish.md` (and `DOCUMENTATION.md`'s polish text) are updated to
      describe the code-state stamp and the "re-judge when the code moved"
      behavior, so the shipped idempotency description does not go stale.

## Notes

- Reuse the existing change manifest: `sprintbias_change_manifest` already
  resolves the audited file list and its context source. A hash over that
  resolved manifest's current contents is the natural state key and works even
  when there is no clean commit boundary (working-tree diffs). A commit ref is
  simpler when one exists but is fragile across amends/rebases — prefer the
  content hash, or record both.
- Keep the aborted-note distinction intact: an aborted run writes `## Excellence
  (aborted — no verdict)`, which is deliberately NOT a judged section. The
  state-aware guard must still treat that as "not judged" so a plain re-run
  judges it (today's exact-heading match already does this — do not regress it).
- "Replace, not stack" needs care: the append-only pattern in `polish-judge.sh`
  must become a replace-the-section write for the re-judge path. Scope the edit
  to the `## Excellence` block only; never touch the task's Success criteria,
  `## Completed`, or `## Audit` sections.
- Smallest robustness win of the three; the handoff sequences it last. Composes
  cleanly with 376 (the `correctness:` stamp) and 377 (routing summary) — all
  three add fields to the same `## Excellence` block.
- Interaction with 377 to hold: an automatic re-judge on code-move re-runs the
  full audit, including 377's enhancement filing/warm-routing. "Replace, not
  stack" covers the `## Excellence` section; it does NOT dedup re-filed tasks.
  A code-move re-judge re-filing enhancements is expected (matches today's
  `--force` behavior), but keep the section-replace scoped so it never double-
  writes the block — and note this re-file amplification for the human, since
  auto-re-judge fires more often than a manual `--force`.

## References

docs/sprintbias/lib.sh
docs/sprintbias/scripts/polish-judge.sh
docs/sprintbias/help/polish.md
docs/sprintbias/ai/audit-excellence.md

## Plan Think

- **Platform Architect:** keying idempotency on existence rather than content is
  a classic staleness bug. A content hash over the resolved
  `sprintbias_change_manifest` is the antifragile key — it works even with no
  clean commit boundary (working-tree diffs) and self-heals when files move. A
  commit ref is fragile across amends/rebases; prefer the hash (or record both).
- **Experience Officer:** the user-visible promise is "if I changed the code,
  polish re-judges; if I didn't, it stays quiet." The "replace, not stack"
  requirement protects the reading experience — one current verdict, never a
  pile of dated ones.
- **Tension → resolution:** correctness of the guard vs. not regressing the
  aborted-note distinction. Resolved by scoping the state-aware check to the
  exact `## Excellence` heading (today's match already excludes `## Excellence
  (aborted …)`) and confining the rewrite to that one block. Lens driving the
  change: **antifragility** (stale state can no longer masquerade as fresh).
- **Sequencing:** last — smallest robustness win, and it builds on the block
  format 376/377 establish. Hard-serialized after 377: the gate holds it in
  `next/` until 377 is done, so the three shared-writer edits land strictly in
  order rather than colliding.

### Alignment pass (plan 24 re-review)

- **Both personas, minor sharpening:** the state-hash design (content hash over
  the resolved `sprintbias_change_manifest`, replace-not-stack, aborted-note
  preserved) was already the antifragile answer and stayed intact. Two alignments
  only: the state key is now explicitly a field on 376's single `## Excellence`
  spec (so both run paths stamp it identically), and a Note flags the 377
  interaction — an automatic code-move re-judge re-runs enhancement filing more
  often than a manual `--force`, so the section-replace must stay scoped and the
  re-file amplification should be surfaced to the human. **Lens: antifragility**
  (staleness can't masquerade as fresh) with a correctness assist on the compose.
- **Left as-is:** the guard's core intent — untouched. Task stays in backlog/,
  malleable; no delta task needed.

## Questions

**Status: READY**

### Already complete

The original task (the `polish <id>` path) is fully implemented and verified in
code:

- `polish-judge.sh:73` resolves the manifest state hash before the guard, and
  the code-state-aware guard at `polish-judge.sh:84-94` skips only when a
  `## Excellence` section carries a `Code state` stamp that still matches the
  current hash; a differing stamp re-judges (`↻ Re-judging …`), and a
  stamp-less/unresolvable case degrades to the old "judged once" skip.
- The lib.sh machinery is present and correct: `sprintbias_manifest_state_hash`
  (`lib.sh:2052`) hashes CURRENT file contents behind `::path::` headers,
  `sprintbias_hash_stdin` (`lib.sh:2069`) is the portable backer,
  `sprintbias_excellence_state_key` (`lib.sh:2086`) reads the stamp from the
  EXACT `## Excellence` block (aborted note skipped), and
  `sprintbias_excellence_strip_section` (`lib.sh:2104`) removes just that block
  for the replace-not-stack path.
- Both write paths stamp `Code state` identically — the headless append and the
  emit `APPEND_STEP` prompt (`polish-judge.sh:185-195`) — and `--force` still
  bypasses the guard.
- `help/polish.md` and `DOCUMENTATION.md` describe the stamp and the re-judge
  behavior; the four files are mirrored into `src/` (version 0.0.114).

### Remaining work

Only the **Rework (round 1)** items are left — the staleness fix on the sibling
`plan polish` path. All lib.sh helpers they build on already exist, so this is
mechanical mirroring:

- Make `plan-polish.sh:146-154`'s idempotency pre-filter state-aware, mirroring
  `polish-judge.sh:84-94`: for each finished member carrying a `## Excellence`
  section, resolve its manifest + current hash
  (`sprintbias_change_manifest` → `sprintbias_manifest_state_hash`), read its
  stamped key (`sprintbias_excellence_state_key`), and route to `TO_JUDGE` (not
  `ALREADY`) when the stamp is present, resolvable, and differs. Keep the
  degrade-to-skip fallback (empty current key, missing stamp, or unresolvable
  manifest → skip).
- Update the pre-filter comment (`plan-polish.sh:141-145`) and the "guard-skip
  never reaches this loop" note (`plan-polish.sh:244`) to describe the
  state-aware skip, not existence-only.
- Verify a stale member on the `plan polish` path re-judges and replaces its
  block, while an unchanged member still skips (`plan polish` invokes
  `polish-judge.sh` without `--force`, so its guard re-checks state — the only
  change needed is that the pre-filter stop wrongly parking a stale member).
- Ship after editing (`docs/` → `./ship.sh`), since `plan-polish.sh` mirrors
  into `src/`.

### Questions for the developer

None — task is fully defined.


## Completed

Closed the staleness gap: the `## Excellence` idempotency guard is now
code-state-aware. A stamped verdict can no longer masquerade as fresh after the
audited files move — the re-run re-judges instead of skipping, and replaces the
stale block in place rather than stacking a second one. Composes cleanly on top
of 376's `correctness:` and 377's `routing:` fields — the code-state stamp is one
more line on the single `## Excellence` spec, rendered identically by both run
paths.

**What changed**

- **`lib.sh` — the state key and its machinery.** `sprintbias_excellence_block`
  gained a `code_state` field (arg 8, before `summary`), so both run paths stamp
  it from the one spec. Added `sprintbias_manifest_state_hash` (hashes the CURRENT
  contents of the resolved change manifest — not the git-diff text, which churns
  on line numbers; each file streamed behind a `::path::` header so a byte-clean
  rename still changes the key; empty file list → empty key) and its portable
  `sprintbias_hash_stdin` backer (git hash-object → shasum → cksum, truncated to
  16 chars). Added `sprintbias_excellence_state_key` (reads the stamped `Code
  state` from the EXACT `## Excellence` block only — an aborted note is skipped)
  and `sprintbias_excellence_strip_section` (removes that one block through its
  next `## ` heading, collapsing trailing blanks — Success criteria, `##
  Completed`, `## Audit`, and any `## Excellence (aborted …)` note untouched).
- **`polish-judge.sh` — a state-aware guard + replace-not-stack.** The change
  manifest and its state hash now resolve BEFORE the guard. The guard skips only
  when the task carries a `## Excellence` section AND its stamped Code state still
  matches the current hash; when the files moved, it re-judges (printing a `↻
  Re-judging …` notice). A missing stamp (pre-378 section) or an unresolvable
  manifest degrades to the old "judged once" skip rather than re-judging blindly.
  `--force` still bypasses the guard entirely. On the headless success path the
  block is stripped-then-appended whenever one already exists, so a re-judge
  (forced or auto) replaces rather than stacks; the emit `APPEND_STEP` stamps the
  same `Code state` value and instructs the agent to replace an existing block in
  place. The aborted note also carries the `Code state` line for the record.
- **`help/polish.md` + `DOCUMENTATION.md`.** Document the new `code state:` field,
  the "skip only while the hash matches, else auto re-judge and replace in place"
  behavior, and the note that an auto re-judge (which fires more readily than a
  manual `--force`) re-runs the full audit and so can re-file enhancements.

**Verification**

- `bash -n` clean on `lib.sh` and `polish-judge.sh`.
- Unit-tested the helpers: hash is deterministic, content-sensitive, and empty
  for an empty list; `state_key` extracts the stamp and skips an aborted note;
  `strip_section` removes the exact block (preserving `## Completed` and an
  `## Excellence (aborted …)` note) and collapses trailing blanks; the block
  renders 9 args with `Code state` present and `Summary` last.
- Emit-mode acceptance (`SPRINTBIAS_MODE=emit`): a fresh task emits a prompt
  carrying the real `Code state` hash; a matching stamp SKIPS; a stale stamp
  RE-JUDGES; a legacy stamp-less section SKIPS. Core acceptance held end to end —
  stamp the current hash → unchanged tree skips; edit the audited file → the next
  run auto re-judges; `--force` re-judges even on an unedited match.
- `./sprint.sh validate --commands` and `--docs`: clean, no drift.
- `./ship.sh`: mirrored the 4 files to `src/`, `src/` byte-clean, version
  0.0.113 → 0.0.114.

### Files changed
docs/sprintbias/lib.sh
docs/sprintbias/scripts/polish-judge.sh
docs/sprintbias/help/polish.md
DOCUMENTATION.md
src/docs/sprintbias/lib.sh
src/docs/sprintbias/scripts/polish-judge.sh
src/docs/sprintbias/help/polish.md
src/DOCUMENTATION.md
src/VERSION

## Rework (round 1)

**Why:** The state-aware guard closed the staleness bug on the `polish <id>`
path but not on its sibling `plan polish`. `plan-polish.sh:149` still pre-filters
members with the existence-only `sprintbias_excellence_has_section`, then
`plan-polish.sh:244` notes "a guard-skip never reaches this loop." So a plan
member whose audited files moved since its verdict is parked in `ALREADY` and
never reaches `polish-judge.sh`'s new state-aware guard — it is skipped with
"already judged," presenting a stale verdict as fresh. That is the exact bug this
task set out to kill, still live on a shipped entry point, and the two guards the
code intends to be "the same test" (per `plan-polish.sh:145`) now diverge.

**Improve:**
- [x] Make `plan-polish.sh`'s idempotency pre-filter state-aware. Done via a
      *shared predicate* rather than copy-mirroring `polish-judge.sh`'s inline
      block: extracted `sprintbias_excellence_is_stale <task_file>
      [current_state_key]` into `lib.sh` (resolve manifest → hash → read stamp →
      compare, with the degrade-to-skip rule), and pointed BOTH the single-piece
      guard and the pre-filter at it. The pre-filter now routes a member to
      `TO_JUDGE` when it has a `## Excellence` section that `is_stale`, and to
      `ALREADY` only when the section's stamp still matches the current code.
- [x] Composition stays clean: `plan polish` still invokes `polish-judge.sh`
      without `--force`, whose guard re-checks the same test; the pre-filter no
      longer parks a stale member in `ALREADY`. Verified a stale member re-judges
      and an unchanged member skips.
- [x] Updated the pre-filter comment and the "guard-skip never reaches this loop"
      note to describe the state-aware skip, not existence-only.
- [x] Edited under `docs/`, validated, mirrored to `src/` via `./ship.sh`.

**Done (rework round 1):** Fixed the same staleness bug on the `plan polish`
path, but improved on the "mirror the inline block" plan — a stress-test flagged
that literal-mirroring copies the staleness boolean into two places that can
drift (the exact thing the pre-filter's own comment warned against). Instead
extracted **one** predicate, `sprintbias_excellence_is_stale`, now called by both
`polish-judge.sh`'s guard and `plan-polish.sh`'s pre-filter, so "was this judged
as it currently stands" lives in a single function and a future block-format
change lands once. The predicate takes an optional precomputed state key: the
single-piece guard passes its already-resolved hash (zero redundant work on the
hot skip path); the pre-filter omits it and the predicate resolves each member's
own manifest. Degrade rules and the aborted-note distinction are preserved.
Verified: unit-tested `is_stale` across six cases (stale, fresh, empty-current,
unstamped, no-section, aborted-note) all correct; `bash -n` clean on all three
files; `validate --commands`/`--docs` clean.

**Shipped & re-verified (rework close-out):** `./ship.sh` has since mirrored
`lib.sh` + `polish-judge.sh` + `plan-polish.sh` into `src/` (version now
0.0.116). Re-verified end to end: `bash -n` clean on all three files;
`sprintbias_excellence_is_stale` returns not-stale on a matching stamp (skip),
stale on a moved tree (re-judge), and not-stale on an aborted note (gated by
`has_section`); the `plan-polish.sh` pre-filter routes members through the shared
predicate; the `is_stale` predicate is present in both `docs/` and `src/` for all
three files. (The remaining working-tree diffs in `lib.sh`/`plan-polish.sh` are
task 379's emit-plan work, not this task's.) Nothing left for 378.
