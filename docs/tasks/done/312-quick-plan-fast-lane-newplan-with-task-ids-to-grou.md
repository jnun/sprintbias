# Task 312: quick-plan fast lane: newplan with task ids to group and start work without full authoring ceremony

**Feature**: none
**Created**: 2026-07-31
**Docs**: none
**Plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 5
**Reworked**: 1

## Problem

When a user already has a set of tasks in hand — most often children just split
out of one task (`**Parent**: N`) — and wants to work them as a group, the
ceremony still pushes `newplan` → `chat plan` → `plan start`. Trailing ids on
`newplan` already bind members, but there is no one-token way to adopt a split
batch, and post-create messaging still steers into AI authoring even when the
member list is already known. Grouping is a bind, not an authoring problem: the
user needs a named plan over a known set, then `plan start`, so grouped work
reaches `next/` quickly with a real plan left in history and the queue taught
rather than hidden.

## Success criteria

- [x] `newplan "name" 310 311 312` still creates a plan pre-populated with those
      task ids as members (already works — keep + optional cheap regression).
      No `chat plan` required when members are bound this way.
- [x] `newplan "name" parent:N` binds with **B-with-guard**:
      (1) include task **N** only if it exists in an **open** stage
      (`backlog` / `next` / `doing` / `blocked`);
      (2) include every open-stage task stamped `**Parent**: N`;
      (3) never pull `review/` or `done/` solely because of the parent stamp.
      Example: `parent:335` → open #335 (if any) + open children of 335.
      Token lives on `newplan` only — no `plan start` variant.
- [x] The parent match is **exact-id, not substring**: `parent:33` binds only
      tasks stamped for parent 33 — never 335 or 133. (Verify by planting a
      `**Parent**: 335` task and confirming `parent:33` does not pull it.)
- [x] If `parent:N` is the only member token and the guard yields **zero**
      matches, fail loud with a clear error (no empty silent plan). If parent N
      is absent but children matched, create the plan and note
      “parent retired — children only” (or equivalent).
- [x] When members are pre-bound (ids and/or `parent:N`), post-create output
      echoes the members bound and points to `plan start` → `work` — not
      “author with `chat plan`” as the default next step.
- [x] After either bind path, `plan start <id>` gates and commits members to
      `next/` exactly as today — `plan start` argument surface unchanged.
- [x] The plan is a named file under `docs/plans/` (user-supplied name, normal
      plan id allocation) — not throwaway/auto-named.
- [x] Help / registry document the fast lane (`newplan` trailing ids +
      `parent:N` / B-with-guard); nothing auto-creates a plan without explicit
      user invoke. Prefer updating split/chat gather hints from the stale
      `plan N "parent:…"` wording to `newplan "…" parent:N` when touching help.

## Notes

**Scope: Minimal — membership fast lane only.**

| Ship | Skip (not this task) |
|------|----------------------|
| `parent:N` on `newplan` (B-with-guard) | Auto-expand **`Depends on`** into membership |
| Fast-lane next-step copy when members pre-bound | Auto-flip plan **Status** to READY |
| Help / registry / cheap split-hint fixups | `plan start <ids…>` ad-hoc form |
| Keep trailing ids / ranges (already ships) | Silent auto-create of plans |
| | Multi-plan / sequential “messy chain” hardening beyond gate + hold |

**Shape:** `newplan "name" <ids…>` (A, already ships) + `newplan "name" parent:N`
(C, build). Rejected: `plan start <ids…>` (surface-creep + throwaway plans).

**`parent:N` = B-with-guard.** Open stages = `SPRINTBIAS_OPEN_STAGES`. After a
normal `split` the parent file is retired, so the common case is children only.
Implement on `newplan` only — do not revive a `plan` gather verb (stale
`plan N "parent:…"` prompts are leftovers from the retired `sprint` filter).

**No children helper exists as of writing** — `lib.sh` has nothing for
parent/children, so the child scan is part of this task: iterate
`SPRINTBIAS_OPEN_STAGES` and match the stamp line **anchored** (e.g.
`^\*\*Parent\*\*: N$`), not as a substring, so `parent:33` can't grab
`**Parent**: 335`. Dedupe against any explicit ids passed alongside so a mixed
`newplan "n" 335 parent:335` lists 335 once.

**Alignment (command-matrix.md is the target-state spec).** The fast-lane
next-step copy must teach the canonical spine `chat → plan start → work`: with
members pre-bound the chat step is done, so point at `plan start → work`; with
no members, keep pointing at `chat plan`. `newplan` mints, `plan` acts, `work`
does — 312 adds no conversational surface and no new plan sub-verb. Broader
help/registry surface-lag alignment is separate backlog work, not this task.

**Guardrails:** explicit user intent only; named plan in history; surface
`plan start` → `work` to teach the queue; skip only `chat plan` authoring —
never the workability gate.

**Deps vs plans (design, not work):** membership and **Depends on** stay
separate. Runtime hold (`sprintbias_unmet_deps`) serializes cross-plan /
out-of-plan prereqs; multi-plan membership stays allowed (primary = lowest id,
#331). A later task may *report* open prereqs outside the plan at `plan start`.

**Sibling:** task 310 = single-task rush (`work N`); 312 = grouped bind → named
plan → `plan start`. Same reuse principle.

## Think Notes

**Reviewed**: 2026-08-03

- **Risk:** An antique *open* parent still enters the plan under B-with-guard;
  gate handles unworkable; user may rework/retire it. Prefer that over
  resurrecting `done/` parents.
- **Rejected:** children-only (A); bare parent+any-stage (B); auto-`Depends on`
  closure at `newplan`.
- **Assumption:** trailing-id path in `create-plan.sh` remains correct; this
  task extends it, does not rewrite it.

## References

docs/sprintbias/scripts/create-plan.sh   — `newplan`; add `parent:N`; branch next-step copy
docs/sprintbias/scripts/plan-start.sh    — reused unchanged
docs/sprintbias/lib.sh                   — open-stage helpers (`SPRINTBIAS_OPEN_STAGES`)
docs/sprintbias/help/newplan.md          — document fast lane
docs/sprintbias/help/plan.md             — chat plan skippable when members pre-bound
docs/sprintbias/help/_registry           — surfaces agree (validate --commands)
docs/sprintbias/scripts/split.sh         — stamps **Parent**: N; update gather hint if cheap
docs/tasks/review/310-work-a-task-by-number.md  — sibling rush path

<!-- When this task is finished, leave an audit trail of what it touched.
     Reviews and the change manifest read this. Copy the two headings
     below to column 0 (UNINDENTED — they are indented here only so a fresh,
     unworked task is not mistaken for a finished one), then list one
     repo-relative path per line under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintbias/scripts/example.sh
       docs/tasks/.TEMPLATE-task.md

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. -->

<!--
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
-->

## Refine (round 1)

**Sharpened:** Created and fully defined this task (split out of the 310
conversation). Settled the shape — `newplan "name" <ids>` plus a
`newplan "name" parent:N` split shortcut, both reusing `plan start` unchanged;
rejected an ad-hoc `plan start <ids>` form as surface-creep. Fixed the intent:
the fast lane only fires on explicit user intent to group work, keeps a named
plan in history for posterity, and surfaces the queue to teach the process — it
skips only `chat plan` authoring, never the workability gate.

## Refine (round 2)

**Sharpened:** Locked **Minimal** scope — ship `parent:N` on `newplan`,
fast-lane next-step messaging when members are pre-bound, and help/registry;
treat trailing-id binding as already done. Corrected the stale claim that
`plan N "parent:…"` already gathers members. Reframed the Problem around the
real gap (no split-batch token + messaging still steers into `chat plan`) so
the work matches the problem we intend to solve.

## Refine (round 3)

**Sharpened:** Confirmed 312 stays membership-only (no `Depends on` auto-expand).
Locked **`parent:N` = B-with-guard** (open parent N if present + open children;
never pull review/done by stamp alone). Recorded collision policy as design
note / possible follow-up, not this task’s work.

## Refine (round 4)

**Sharpened:** Final polish for implementability — promoted zero-match fail-loud
and “parent retired — children only” into Success criteria; collapsed Notes to
a ship/skip table; aligned headers with the task template; marked
**Status: READY**. No open decisions remain.

## Refine (round 5)

**Sharpened:** Verified against `command-matrix.md` (target-state spec) — 312 is
consistent, no conflict: `newplan` mints, `plan start` acts, and pre-bound
members legitimately skip `chat plan` for the `plan start → work` spine. Added a
success criterion pinning **exact-id parent matching** (`parent:33` ≠
`**Parent**: 335`) to close a silent-collision class with zero live fixtures,
and Notes flagging that no children helper exists (the child scan + cross-path
dedupe are part of the work). Anchored the next-step copy to the matrix spine;
left broader help/registry surface-lag alignment as separate backlog work.

## Completed

Shipped the membership fast lane on `newplan`:

- Trailing ids / ranges still pre-populate members (unchanged path).
- `parent:N` binds open-stage parent N (if open) plus open-stage children with
  exact `**Parent**: N` (not substring). Zero matches with only `parent:` tokens
  fails loud. Absent open parent + matching children notes
  “parent … is not open — binding children only”.
- Pre-bound post-create copy points at `plan start` → `work` (and documents
  `--commit-only`); empty member lists still steer to `chat plan`.
- Help (`newplan.md`, `plan.md`, `chat.md`), `_registry`, `command-matrix.md`,
  and split/chat gather hints updated; stale `plan N "parent:…"` strings gone.
- `plan start` surface unchanged; plan files remain named under `docs/plans/`.

Verified: parent+child bind smoke; `parent:9000` fails when only Parent 90001
exists; `test-plan-lifecycle.sh` green.

### Files changed
docs/sprintbias/scripts/create-plan.sh
docs/sprintbias/help/newplan.md
docs/sprintbias/help/plan.md
docs/sprintbias/help/chat.md
docs/sprintbias/help/_registry
docs/sprintbias/scripts/split.sh
docs/sprintbias/scripts/chat.sh
docs/guides/command-matrix.md

Rework round 1 (2026-08-10):
docs/sprintbias/help/_registry
docs/sprintbias/scripts/create-plan.sh
docs/sprintbias/scripts/check-commands.sh
src/ (mirrored via ./ship.sh — v0.0.85)

## Questions

**Status: READY**

### Already complete

All eight success criteria are implemented and verified in the live tree:

- **Trailing ids / ranges** — `create-plan.sh:51-65` (`expand_ids`, comma +
  `N-M` range handling). Unchanged path, still correct.
- **`parent:N` B-with-guard** — `create-plan.sh:70-95` (`expand_parent_token`).
  Parent included only via an open-stage lookup; children scanned across
  `SPRINTBIAS_OPEN_STAGES` only, so `review/` and `done/` are never pulled by
  stamp alone.
- **Exact-id parent match** — `create-plan.sh:84-87` normalizes the stamp and
  compares with `[ "$pval" = "$pid" ]`. `parent:33` cannot grab `**Parent**: 335`.
- **Zero-match fail-loud** — `create-plan.sh:129-133`, exit 1 when `parent:`
  tokens are the only member source and nothing matched. Retired-parent note at
  `create-plan.sh:92-94`.
- **Cross-path dedupe** — `create-plan.sh:126` (`awk '!seen[$0]++'`), so
  `newplan "n" 335 parent:335` lists 335 once.
- **Fast-lane next-step copy** — `create-plan.sh:247-256` points at
  `plan start → work` (plus `--commit-only`) when members are pre-bound; the
  empty-member branch still steers to `chat plan`.
- **`plan start` surface unchanged**; plan files stay named under `docs/plans/`.
- **Help / docs** — `help/newplan.md:7,25,31` documents both bind forms; no
  stale `plan N "parent:…"` gather hints remain anywhere under
  `docs/sprintbias/` or `docs/guides/`.

Quality concerns are confined to the two defects the rework round found, both
reconfirmed against current code (see Remaining work). Nothing here needs
removing.

### Remaining work

None — all five Rework (round 1) items landed on 2026-08-10 and shipped in
v0.0.85. See **Resolved** at the end of Rework (round 1) for what changed and
how each was verified. The findings that drove them are kept below for the
record:

- **Registry pipe still breaks two shipped surfaces.**
  `help/_registry:26` still reads `<name> [task-id...|parent:N]`. Reproduced:
  `./sprint.sh help` prints `newplan <name> [task-id...       parent:N]` with
  the summary gone, and `./sprint.sh newplan --demo` reports
  `Unknown demo: Createaplan—namedtask-IDlist;…`. Rewrite the usage field so it
  contains no literal `|` (e.g. `<name> [ids / N-M / parent:N]`).
- **The interactive prompt is a second, weaker parser.**
  `create-plan.sh:155-165` re-implements a reduced copy of the argv loop.
  Confirmed by simulating that loop verbatim: `335,parent:336` binds only 335
  and silently drops `parent:336`; a typo like `parnt:335` yields nothing with
  no error; and the branch has no zero-match guard, so it can write the empty
  plan success criterion 4 forbids. Factor the argv member-token loop (comma
  splitting, `parent:N` match, unrecognized-token error, zero-match fail-loud)
  into one function and call it from **both** paths, then confirm those three
  cases behave identically at the prompt.
- **Drift risk in the parent's own lookup.** `create-plan.sh:73-74` hardcodes
  `docs/tasks/backlog next doing blocked` while the error message at
  `create-plan.sh:131` names `SPRINTBIAS_OPEN_STAGES` as the source of truth.
  The two agree today (`lib.sh:965`) but must not be able to drift — resolve the
  lookup from the array.
- **Registry-format guard — note the spec correction.** A "more than 5 fields"
  check would **not** catch this bug: the mangled `newplan` row splits into
  exactly 5 fields, and 6 legitimate demo rows already have 5 (23 rows have 4).
  Add the guard to `check-commands.sh` as a **5th-field validity** check
  instead: when a row has a 5th field, it must name an existing
  `docs/sprintbias/learning/<demo>.py`. That fires precisely on this row and on
  any future embedded pipe, while leaving real demo rows green. Keeping a
  hard "no more than 5 fields" cap alongside it is fine as a cheap backstop.
- **Mirror after fixing.** `src/docs/sprintbias/help/_registry` carries the same
  broken row, so the breakage is live for installed users — run `./ship.sh`
  once the fixes are in.

### Questions for the developer

None — task is fully defined.

## Rework (round 1)

**Why:** The core `parent:N` bind is correct (verified: exact-id match, review/done
excluded, dedupe, retired-parent note, fail-loud exit 1). But the `_registry` row
for `newplan` now contains a literal `|` inside field 3
(`<name> [task-id...|parent:N]`), and `_registry` is pipe-delimited — `sprint.sh`
splits with `IFS='|'` on the documented promise that "no field contains a pipe."
That single character breaks two shipped surfaces: `./sprint.sh help` prints
`newplan <name> [task-id...       parent:N]` with the summary gone, and
`demo_for_cmd` reads the mangled summary as a demo name, so `newplan --help`
advertises a demo and `./sprint.sh newplan --demo` errors with
`Unknown demo: Createaplan—namedtask-IDlist;…`. `validate --commands` passes
because it only checks name presence, so nothing caught it. Separately, the
interactive prompt in `create-plan.sh:135-166` advertises `parent:N` but re-parses
tokens with a reduced copy of the argv loop, so it silently drops members and can
create the empty plan success criterion 4 forbids.

**Improve:**
- [x] Rewrite the `newplan` row in `docs/sprintbias/help/_registry` so no field
      contains a literal `|` (e.g. usage `<name> [ids / N-M / parent:N]`).
      Verify `./sprint.sh help` shows the full summary on one clean row and
      `./sprint.sh newplan --demo` no longer reports an unknown demo.
- [x] Factor the argv member-token loop in `docs/sprintbias/scripts/create-plan.sh`
      (comma splitting, `parent:N` match, unrecognized-token error, zero-match
      fail-loud) into one function and call it from BOTH the argv path and the
      interactive prompt path, so the two behave identically.
- [x] With that shared parser in place, confirm at the interactive prompt:
      `335,parent:336` binds both (today the comma-joined `parent:` token is
      silently dropped), a typo like `parnt:335` errors instead of being ignored,
      and a `parent:N` with zero open matches fails loud rather than writing an
      empty plan.
- [x] In `expand_parent_token`, resolve the parent's own open-stage lookup from
      `SPRINTBIAS_OPEN_STAGES` instead of the hardcoded
      `docs/tasks/backlog next doing blocked` list — the error message already
      claims that array is the source of truth, so the two must not drift.
- [x] Add a registry-format check to `docs/sprintbias/scripts/check-commands.sh`
      that fails when a row has more than 5 pipe-delimited fields, so this class
      of breakage cannot ship silently again.

**Resolved (2026-08-10).** All five landed and shipped in v0.0.85.

- **Registry row** is now `<name> [ids / parent:N]` — no literal `|`. Dropped
  `N-M` from the hint to fit `sprint.sh:89`'s 32-char pad, so the row renders
  aligned with the summary intact; ranges stay documented in `help/newplan.md`.
  `./sprint.sh newplan --demo` plays again.
- **One parser, both paths.** `collect_member_tokens` (comma split, ranges,
  `parent:N`, loud error on anything else) plus `bind_members` (dedupe +
  no-empty-silent-plan guard) in `create-plan.sh`; the argv branch and the
  interactive branch both call `bind_members` and nothing else.
- **Interactive prompt verified on an isolated board**, driven through a real
  pty: `9003,parent:9001` → binds 9003 + 9001 + 9002 (previously bound 9003 and
  silently dropped the parent token); `parnt:9001` → `unrecognized member token`,
  0 plans written; `parent:9999` → `matched no open tasks`, 0 plans written. The
  argv path produces identical results, and `parent:900` still refuses to pull
  9001/9002 (exact-id guard survives the open-stage refactor).
- **Spec correction on the registry guard.** The rework note assumed the mangled
  row split into exactly 5 fields and that a field-count cap would miss it — it
  actually splits into 6, so the cap does catch it. Both guards are implemented
  anyway: a >5-field cap, and 5th-field validity (when present it must name a
  real `learning/<demo>.py`), which catches a stray pipe that lands on a legal
  field count. Each was proved by planting the corresponding malformed row.
- **Mirrored.** `./ship.sh` → v0.0.85; `src/docs/sprintbias/help/_registry` is
  clean, so the breakage is resolved for installed users.

Verified after the changes: `docs/tests/run-all.sh` 22/22 green; `./sprint.sh
validate` 127/127 valid; `validate --commands` and `validate --docs` green.
