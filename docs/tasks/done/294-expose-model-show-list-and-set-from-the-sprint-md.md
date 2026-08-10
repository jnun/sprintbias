# Task 294: Expose model show list and set from the SprintBias CLI

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Plan**: 11
**Depends on**: none
**Blocks**: 295, 297
**Parent**: none

**Status: READY**

## Problem

Model selection today is buried: edit `docs/sprintmd/config` (`MODEL_DEFAULT`,
`MODEL_WORK`, `MODEL_CHAT`, …) or set `SPRINTMD_MODEL_*` env vars. There is no
first-class SprintBias command to **see** the effective model for each role,
**list** what the current provider offers, or **set** a default without
hand-editing config. Switching between Claude and Grok models (or pinning
work vs chat) should be a deliberate CLI action, not tribal knowledge.

## Success criteria

- [x] A user-facing command (recommended name: `./sprint.sh model`) supports at
      least:
      - **show** — effective model per role (WORK, CHAT, GATE, …) after
        env → config → tier default resolution; show active CLI/PROVIDER
      - **list** — models available from the current provider when possible
        (`grok models`; Claude equivalent if cheap/reliable, else honest
        “see provider docs” + config keys)
      - **set** — write `MODEL_DEFAULT` and/or `MODEL_<ROLE>` into
        `docs/sprintmd/config` (never invent keys outside the known set)
- [x] Help page + registry entry; name is plain language
- [x] Works for both `claude-code` and `grok-build` installs without requiring
      the other CLI on PATH
- [x] Does not clobber unrelated config; uses existing `sprintmd_cfg_set` (or
      equivalent)
- [x] `model show` makes tier defaults visible (e.g. empty config →
      `grok-4.5` / `opus` via `sprintmd_tier_model` where applicable)

## Notes

- Prefer one `model` command with subcommands over scattering flags only.
- Per-invocation flags for work/chat can land in #295; this task is the
  durable show/list/set surface.
- Setup picker remains provider-level; this is model-level within a provider.
- **From #298 burn (KU-24):** `work` / `gate` / `polish` use
  `sprintmd_resolve_model` only, so empty config does **not** apply tier
  defaults (`opus` / `grok-4.5`). Chat uses `sprintmd_tier_model`. In this task
  (or a one-line follow-up in the same PR): either switch those spine scripts
  to `tier_model` where a strong default is intended, or make `model show`
  print the gap honestly (“WORK: (CLI default — not tier-pinned)”). Prefer
  aligning work/gate/polish with tier_model for provider parity.
- **From #298 (KU-21):** `model list` on Claude has no cheap list API here —
  ship known aliases + pointer, not a fake `claude models` scrape.

## References

docs/sprintmd/lib.sh
docs/sprintmd/config
docs/sprintmd/help/_registry
docs/sprintmd/scripts/
DOCUMENTATION.md

## Questions

**Status: READY**

### Already complete

Nothing is implemented yet — this is a greenfield command. Verified there is no
`model.sh` in `docs/sprintmd/scripts/`, no `cmd_model`/`model)` case in
`sprint.sh`, no `model` row in `help/_registry`, and no `help/model.md`.

The plumbing this task builds on, however, is all present and correct:
- `sprintmd_resolve_model SFX` (lib.sh:240) — env → `MODEL_<SFX>` → `MODEL_DEFAULT`.
- `sprintmd_tier_model SFX` (lib.sh:274) — same, plus `claude-code→opus` /
  `grok-build→grok-4.5` when nothing is pinned. (grok-4.5 is already hardcoded
  here, so `model list`/`show` do not depend on tasks 291–293.)
- `sprintmd_cfg_set KEY VALUE` (lib.sh:218) — in-place update or append, value
  properly escaped; use this for `set` so unrelated keys are untouched.
- `sprintmd_cfg KEY` (lib.sh:210) — reader for `show`.
- `sprintmd_ai_tier` (lib.sh:599) — resolves CLI/PROVIDER to a tier for the
  `show` banner and the `list` provider branch.

The KU-24 gap in the Notes is confirmed: `work` (work.sh:93), `gate`
(gate.sh:57/59, gate-lib.sh:83), and `polish` (polish.sh:135/574/741) all use
`sprintmd_resolve_model` only — so an empty config does NOT apply the opus /
grok-4.5 tier defaults for those roles. Only `chat` (chat.sh:85) uses
`sprintmd_tier_model`.

### Remaining work

Everything. Build one `model` command with `show` / `list` / `set` subcommands:
1. `docs/sprintmd/scripts/model.sh` — source lib.sh; iterate the known role
   suffixes (WORK, CHAT, GATE, FEATURE, IDEA, SPLIT, SPRINT, PROFILE,
   CODE_AUDIT, EXCELLENCE, POLISH, AUDIT, DEPS, TRIAGE, PLAN_THINK, DRIFT) from
   config for `show`; `grok models` on grok-build, static aliases + pointer on
   claude-code for `list` (per KU-21 — no fake `claude models` scrape); write
   `MODEL_DEFAULT`/`MODEL_<ROLE>` via `sprintmd_cfg_set` for `set`, rejecting any
   key outside the known set.
2. Wire it: `cmd_model` + a `model)` case in `sprint.sh` (mirror `cmd_deps`).
3. `help/_registry` row (group `keep` or `look`) + `help/model.md` page.
4. `DOCUMENTATION.md` command listing entry.
5. Run `./ship.sh` to mirror to `src/` and bump version.
6. `./sprint.sh validate --commands` must pass (registry ↔ dispatch ↔ help ↔
   manual all agree — see [[command-catalog-source-of-truth]]).

### Questions for the developer

1. KU-24: align `work`/`gate`/`polish` with `tier_model`, or just report the gap
   in `model show`? (Suggestion: do BOTH, but scope the code change carefully —
   switching work/gate/polish to `sprintmd_tier_model` gives Claude/Grok parity
   with chat, but it also makes empty-config `work` default to `opus`, which
   interacts with `BUDGET_WORK=5.00`. Recommend making the one-line switch in
   this PR AND having `model show` label the resolver each role uses, so the
   behavior stays legible after the change. If you'd rather not touch spine
   cost behavior here, ship `model show` labeling the gap honestly
   ("WORK: <model> — CLI default, not tier-pinned") and leave the switch to a
   follow-up. Either satisfies the success criteria.)

2. Which command group for the registry row? (Suggestion: `keep` — it's a
   config-management action alongside `profile`/`validate`, and `set` mutates
   `docs/sprintmd/config`. `look` would fit `show`/`list` but not `set`.)

## Completed

Built one `model` command with `show` / `list` / `set` subcommands — pure
config plumbing over `docs/sprintmd/config`, no AI invoked.

- **`docs/sprintmd/scripts/model.sh`** (new). `show` iterates the 16 known role
  suffixes and prints each role's effective model via `sprintmd_tier_model`
  plus a source label (`env <VAR>` / `config MODEL_<ROLE>` / `config
  MODEL_DEFAULT` / `tier default` / `CLI default`) so the resolution is legible,
  under a banner of active CLI / provider tier / mode / MODEL_DEFAULT. `list`
  runs `grok models` on grok-build (degrading to known aliases + pointer when
  the CLI is absent), and on claude-code ships opus/sonnet/haiku aliases + the
  models-docs URL (no fake `claude models` scrape, per KU-21). `set KEY VALUE`
  writes `MODEL_DEFAULT` (KEY=`default`) or `MODEL_<ROLE>` via
  `sprintmd_cfg_set`, rejecting any key outside the known set and any stray
  third arg; an empty VALUE clears the pin.
- Wired `cmd_model` + a `model)` dispatch case into `sprint.sh` (mirrors
  `cmd_deps`).
- Registry row (`keep` group, per Q2 suggestion) + `help/model.md` page +
  `DOCUMENTATION.md` listing entry.
- `./sprint.sh validate --commands` passes (23 commands surfaced across all
  four surfaces). `./ship.sh` mirrored to `src/` and bumped 0.0.56 → 0.0.57.

**KU-24 (Q1):** No change needed — the working tree already resolves
`WORK`/`GATE`/`POLISH`/`CODE_AUDIT`/`EXCELLENCE`/`AUDIT` and every other role
through `sprintmd_tier_model` (verified by grepping all scripts; no role uses
bare `sprintmd_resolve_model`). So the tier default (`opus` / `grok-4.5`)
already applies on empty config. `model show` labels each role's source, making
this legible without a spine-cost change in this PR.

Verified live: `model show` (claude + `-g` grok), `model list` (both tiers,
grok live list resolved), `set default`/`set work`/clear, unknown-key
rejection, and `SPRINTMD_MODEL_<ROLE>` env override all behave correctly; config
left byte-clean after restore.

### Files changed
docs/sprintmd/scripts/model.sh
sprint.sh
docs/sprintmd/help/_registry
docs/sprintmd/help/model.md
DOCUMENTATION.md
src/docs/sprintmd/scripts/model.sh
src/sprint.sh
src/docs/sprintmd/help/_registry
src/docs/sprintmd/help/model.md
src/DOCUMENTATION.md
src/VERSION
