# Task 293: Specialize Grok subagent types for gate vs work vs polish

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Plan**: 11
**Depends on**: 292
**Blocks**: 296
**Parent**: none

**Status: READY**

## Problem

All Grok orchestration prompts currently say `subagent_type: general-purpose`.
Grok also has `explore` (read/search/shell, no edits) and `plan`, plus
`capability_mode` (`read-only` | `read-write` | `execute` | `all`). Gate and
read-heavy paths do not need full write/implement tools; using the full agent
for every fan-out is slower, riskier, and ignores a free host capability.

## Success criteria

- [x] Shared helper(s) choose worker type (and optional capability_mode) by
      role, e.g.:
      - **work / implement** → `general-purpose`
      - **gate / definition review** → `explore` or `general-purpose` +
        `capability_mode: read-write` limited to task files — pick one policy
        and document it
      - **polish judge** → `general-purpose` (must edit task files only; prompt
        already forbids product code edits)
- [x] All emit fan-out sites use the helper — no ad-hoc type strings
- [x] Claude wording unchanged (still Task tool; no fake Grok types on Claude)
- [x] Brief note in grok-provider-tier guide on which role maps to which type

## Notes

- Gate must still be allowed to Edit/Write the **task file** and move files if
  the emit contract requires it — pure `explore` may be too strict if it cannot
  edit. If so, prefer `general-purpose` + prompt contract, or verify
  `capability_mode: read-write` behavior before locking.
- Nesting depth remains one: workers never orchestrate.
- **From #298 burn (KU-12/13):** gate-lib emit contract **requires** Edit/Write
  on the task file and `git mv` (shell). Pure `explore` (no file edits) is
  **insufficient** for the current gate path. Default recommendation: keep
  gate on `general-purpose` unless a verified capability_mode preserves
  edit + shell for moves.

## References

docs/sprintmd/lib.sh
docs/sprintmd/scripts/gate-lib.sh
docs/sprintmd/scripts/work.sh
docs/sprintmd/scripts/polish.sh
docs/guides/grok-provider-tier.md
~/.grok/docs/user-guide/16-subagents.md

## Questions

**Status: READY**

### Already complete

- **Nothing behavioral is implemented yet.** All four Grok subagent-wording
  helpers still hardcode the type: `lib.sh:640/642` and `lib.sh:659` and
  `lib.sh:671` all emit `subagent_type: general-purpose`. There is no
  role-aware type helper.
- **The seam the task needs already exists and is clean.** Every emit fan-out
  site already routes its subagent wording through a single `sprintmd_subagent_*`
  helper — no ad-hoc `subagent_type` strings live in the script bodies (verified
  in `gate-lib.sh:253`, `work.sh:294`, `polish.sh:926`, `chat.sh:165`, and
  `lib.sh:329` `sprintmd_next_blocked_resolution`). So success-criterion #2
  ("all sites use the helper, no ad-hoc strings") is structurally true today;
  the remaining work is to make the *type* inside those helpers role-parameterized
  rather than a literal.
- **The gate policy decision is already made and is correct.** The Notes (KU-12/13
  from #298) conclude gate stays on `general-purpose`. I confirmed this against
  `~/.grok/docs/user-guide/16-subagents.md`: `capability_mode: read-write` grants
  file edits **but no shell**, and `execute` grants shell **but no edits**. The
  gate contract needs *both* (Edit/Write the task file **and** `git mv` to move
  it), so neither restricted mode works and `explore` is out entirely. Only
  `general-purpose` (full toolset) satisfies the gate. Decision is sound.

### Remaining work

1. Add a role→type helper in `lib.sh` (e.g. `sprintmd_subagent_type_for <role>`),
   returning the `subagent_type` (and, if ever needed, an optional
   `capability_mode`) per role: `work`, `gate`, `polish`, `chain`. Per the Notes
   and success criteria, every role currently resolves to `general-purpose` — the
   helper is the future-proof seam, not (yet) a behavioral split.
2. Refactor the four `sprintmd_subagent_*` wording helpers to source their Grok
   type from that helper instead of the embedded literal `general-purpose`
   string. Note `work.sh` and `polish.sh` share `sprintmd_subagent_own_fresh`; if
   they should ever diverge, that helper needs a role argument.
3. Keep the Claude branches untouched — Claude still says "Task tool" with no
   Grok type names (success criterion #3).
4. Add a role→type mapping note to the "Subagents (Grok native)" section of
   `docs/guides/grok-provider-tier.md` (lines 80–91), which today lists the types
   generically but does not map roles to them.

### Questions for the developer

1. Given the Notes resolve every role to `general-purpose`, this task delivers a
   centralized role-aware seam plus documentation rather than any actual
   behavioral specialization on the current gate/work/polish paths — is that the
   intended scope? (Suggestion: yes, ship it as the seam + doc note. The value is
   that a future specialization becomes a one-line change in one helper instead
   of edits across four call sites, and the guide records *why* each role is
   general-purpose. Don't force a behavioral split now — the burn note already
   showed restricted modes break the gate.)
2. The **polish** subagent only reads and rewrites the task file (the orchestrator
   moves files, so the judge never needs shell) — it is the one role where
   `capability_mode: read-write` would be a genuine, safe restriction. Apply it,
   or keep polish on plain `general-purpose` per the success criteria? (Suggestion:
   keep it `general-purpose` for this task to match the stated criteria and avoid
   verifying read-write behavior under load, but wire the helper so polish's entry
   is the obvious place to add `read-write` later — capture that as a one-line
   follow-up note rather than doing it here.)

## Completed

Shipped the centralized role→type seam plus documentation, per the scope
resolved in the Questions (Q1: yes, seam + doc note; Q2: keep polish on
`general-purpose` but wire its entry as the obvious place to add `read-write`
later). No behavioral split — the burn note (KU-12/13) already proved restricted
modes break the gate (read-write = edits, no shell; execute = shell, no edits;
gate needs both). Every role resolves to `general-purpose` today.

**What changed:**

1. New `sprintmd_subagent_type_for <role>` in `lib.sh` — the single seam
   returning the Grok `subagent_type` per role (`work | gate | polish | chain`,
   all `general-purpose`). Header comment documents *why* each role is
   general-purpose. A future specialization is a one-line edit here.
2. Refactored the three Grok-branch wording helpers to source their type from the
   seam instead of the embedded literal `general-purpose`:
   `sprintmd_subagent_spawn_phrase [purpose] [role]`,
   `sprintmd_subagent_own_fresh [role]`,
   `sprintmd_subagent_parallel_dispatch [role]`. work/polish share
   `own_fresh` — the role arg is the place they'd diverge.
3. Every emit fan-out site now passes its role explicitly: `work.sh` → `work`,
   `polish.sh` → `polish`, `gate-lib.sh` → `gate`, `chat.sh` +
   `sprintmd_next_blocked_resolution` → `chain`. No ad-hoc type strings remain.
4. Claude branches untouched — still "Task tool", no Grok type names (verified:
   Claude tier emits `its OWN fresh subagent (Task tool)` etc.).
5. Added a role→`subagent_type` mapping table to the "Subagents (Grok native)"
   section of `docs/guides/grok-provider-tier.md`, recording caller + rationale
   per role and flagging polish as the safe future `read-write` candidate.

**Verified:** sourced `lib.sh` under both tiers — all four roles resolve to
`general-purpose` on Grok (incl. an unknown-role fallback) and Claude wording is
unchanged. `bash -n` clean on all five touched scripts.

Note: changes are in `docs/` (live tree) only; run `./ship.sh` to mirror to
`src/` and bump the version (left to the developer).

Follow-up (one line, not done here): specialize `polish` → `general-purpose` +
`capability_mode: read-write` once read-write file-edit behavior is verified
under load — its `sprintmd_subagent_type_for` case is the single edit point.

### Files changed

docs/sprintmd/lib.sh
docs/sprintmd/scripts/work.sh
docs/sprintmd/scripts/polish.sh
docs/sprintmd/scripts/gate-lib.sh
docs/sprintmd/scripts/chat.sh
docs/guides/grok-provider-tier.md
docs/tasks/doing/293-specialize-grok-subagent-types-for-gate-vs-work-vs.md
