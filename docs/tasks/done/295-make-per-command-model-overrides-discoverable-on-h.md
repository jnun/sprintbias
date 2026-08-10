# Task 295: Make per-command model overrides discoverable on help and common flags

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Plan**: 11
**Depends on**: 294
**Blocks**: 297
**Parent**: none

**Status: READY**

## Problem

Env overrides (`SPRINTMD_MODEL_WORK`, `SPRINTMD_MODEL_CHAT`, …) already win over
config, but help pages barely teach them, and there is no consistent
`--model <id>` on the commands people run most. Users who want “this one work
run on model X” should not need to export env vars from memory.

## Success criteria

- [x] Document on `model` help + relevant command help (`work`, `chat`, `gate`,
      `polish` at minimum): precedence
      `flag/env → MODEL_<ROLE> → MODEL_DEFAULT → tier default → CLI default`
- [x] Where cheap and consistent, add optional `--model <id>` to high-traffic
      scripts so a single invocation can pin without editing config
      (implementation may set `SPRINTMD_MODEL_*` for that process)
- [x] No silent ignore: unknown flag errors; empty model clears only if
      explicitly designed (prefer pin, not accidental clear)
- [x] README or DOCUMENTATION one-liner points at `./sprint.sh model` and
      per-run override

## Notes

- Do not add `--model` to every obscure script — prioritize the spine.
- Keep flag parsing consistent with existing long-options style.

## References

docs/sprintmd/help/work.md
docs/sprintmd/help/chat.md
docs/sprintmd/scripts/work.sh
docs/sprintmd/scripts/chat.sh
docs/sprintmd/lib.sh

## Questions

**Status: READY**

### Already complete

Nothing in *this* task's scope is implemented — verified against the current
code:
- No `--model` flag exists on any script. `work.sh` (line 93) reads only
  `sprintmd_resolve_model WORK`; `chat.sh` (line 85) reads `sprintmd_tier_model
  CHAT`; `gate.sh`/`polish.sh` read `sprintmd_resolve_model` per role. None
  accept a per-invocation `--model` override.
- Help pages do NOT teach precedence. `help/work.md` (lines 68–70) only says
  "set `SPRINTMD_MODEL_WORK`"; `help/chat.md` says nothing about models. Neither
  shows the `flag/env → MODEL_<ROLE> → MODEL_DEFAULT → tier default → CLI
  default` chain, and there is no `./sprint.sh model` pointer.
- No README/DOCUMENTATION one-liner about per-run model override.

The plumbing this task builds on is present and correct:
- `sprintmd_resolve_model SFX` (lib.sh:240) — env `SPRINTMD_MODEL_<SFX>` →
  config `MODEL_<SFX>` → config `MODEL_DEFAULT` → empty.
- `sprintmd_tier_model SFX` (lib.sh:274) — same, plus the `opus`/`grok-4.5` tier
  default when nothing is pinned.
- `polish.sh` already has a clean `while [ $# -gt 0 ]` parser (lines 50–74) that
  consumes two-token flags (`--rounds N`) and **errors on unknown flags**
  (`-*) … _usage`). Adding `--model <id>` there is trivial and consistent.
- `work.sh` (for-loop, lines 17–36) and `gate.sh` (for-loop, lines 22–33) do
  NOT have that shape: `work.sh` silently ignores unknown flags, and `gate.sh`
  errors only on non-numeric tokens. Success criterion 3 ("no silent ignore")
  therefore means a small parser rework for `work.sh` specifically.

### Remaining work

Everything in the four success criteria:
1. **Document precedence** on `work`/`chat`/`gate`/`polish` help pages (and the
   new `model` help page from #294): the full
   `flag/env → MODEL_<ROLE> → MODEL_DEFAULT → tier default → CLI default` chain.
2. **Add optional `--model <id>`** to the spine scripts (`work`, `chat`, `gate`,
   `polish`) so one invocation can pin a model. Simplest implementation: the
   flag exports `SPRINTMD_MODEL_<ROLE>` (or a run-wide default) for that process
   so it flows through the existing resolver on both the emit and exec paths.
3. **Error on unknown flags** where a script currently swallows them (chiefly
   `work.sh`); keep empty-value handling a deliberate pin, not an accidental
   clear.
4. **README/DOCUMENTATION one-liner** pointing at `./sprint.sh model` and the
   per-run override.
5. `./ship.sh` to mirror + bump; help/manual stay consistent (a doc-only change
   to help pages must keep `./sprint.sh validate --commands` green — see
   [[command-catalog-source-of-truth]]).

**Depends on 294** (already recorded): #294 creates the `./sprint.sh model`
command and its help page (which criterion 1 documents and criterion 4 points
at), and it decides the KU-24 resolver question (whether `work`/`gate`/`polish`
switch to `sprintmd_tier_model`). Criterion 1's "tier default" step is only
accurate for those roles if #294 makes that switch — see Q1.

### Questions for the developer

1. Where should the `--model` override live — a global flag in `sprint.sh`
   (like `-g`/`-c`) or a per-script flag on each spine command? (Suggestion:
   add `--model` per-script on `work`/`chat`/`gate`/`polish`, setting
   `SPRINTMD_MODEL_<ROLE>` for that process. It reuses the existing resolver
   with zero lib changes and keeps each role's override precise. A global
   `sprint.sh --model X` is tempting for "common flags," but it can't know the
   role and `sprintmd_resolve_model` doesn't consult a `SPRINTMD_MODEL_DEFAULT`
   env today — you'd have to extend the resolver. If you do want the global
   form, add a single `SPRINTMD_MODEL_DEFAULT` env fallback in
   `sprintmd_resolve_model` after the per-role env and before config, and export
   it from a leading `--model` flag.)

2. Does criterion 1's precedence chain include "tier default" for
   `work`/`gate`/`polish`, or only for `chat`? (Suggestion: document whatever
   #294 lands. If #294 aligns `work`/`gate`/`polish` to `sprintmd_tier_model`
   (its recommended path), the single chain applies everywhere. If it does not,
   write the chain per-resolver — note that `work`/`gate`/`polish` skip the
   tier-default step and fall straight to the CLI default — so the help never
   over-promises a tier pin that role doesn't get.)

## Completed

Both open questions resolved by what #294 actually landed:
- **Q2 — tier default everywhere.** #294 wired `work` (`sprintmd_tier_model
  WORK`), `gate` (`AUDIT`→`GATE`), and `polish` (`POLISH`/`EXCELLENCE`/
  `CODE_AUDIT`) to the tier-aware resolver, so the single chain
  `flag/env → MODEL_<ROLE> → MODEL_DEFAULT → tier default → CLI default` is
  accurate for every role. Documented that exact chain, unchanged.
- **Q1 — per-run lever, not a global flag.** Took the resolver-fallback option
  the question itself flagged: added an `SPRINTMD_MODEL_DEFAULT` env layer to
  `sprintmd_resolve_model` (after the per-role env, before config), and each
  spine command's `--model <id>` simply `export`s it. One lever pins every role
  a single invocation touches — no per-role guessing, and `gate`/`polish` (which
  read 2–3 roles each) are covered uniformly. Precedence proven by test:
  per-role env > `--model`/env DEFAULT > config `MODEL_<ROLE>` > config
  `MODEL_DEFAULT` > tier default. The flag wins over config (a per-run choice
  should) but yields to an explicit per-role env already in the shell.

What shipped:
1. **Resolver (`lib.sh`)** — `sprintmd_resolve_model` now consults env
   `SPRINTMD_MODEL_DEFAULT` between the per-role env and config; header comment
   rewritten to the full precedence list. Non-empty results still flow through
   `sprintmd_coerce_model`, so a provider-foreign `--model opus` on Grok is
   remapped just like a config pin.
2. **`--model <id>` on the spine** — `work`, `chat`, `gate`, `polish`. Each
   exports `SPRINTMD_MODEL_DEFAULT` for that process; `chat` strips it from any
   position before its shape-based dispatch (and it flows into the
   folder/bugs/plan sweeps it exec's into). Flag parsing matches each script's
   existing long-option style.
3. **No silent ignore** — `work.sh` previously swallowed unknown tokens; it now
   errors on any unrecognized argument (catch-all `*`) and on a dangling
   `--jobs`/`--model`. Every `--model` handler rejects an empty/missing value
   (a deliberate pin, never an accidental clear). `gate`/`polish`/`chat` already
   errored on unknown flags; kept.
4. **Docs** — precedence chain + `--model` usage on `help/work`, `help/chat`,
   `help/gate`, `help/polish`; `help/model` gained the lever as layer 2 and a
   per-run-override section; `model show` labels the lever as a source
   (`--model / env DEFAULT`) and its header comment lists it. `DOCUMENTATION.md`
   command line points at the per-run override.
5. **Ship + verify** — `./ship.sh` mirrored byte-clean and bumped v0.0.59 →
   v0.0.60. `validate --commands` and `validate --docs` both green (help/script
   flag surfaces agree — see [[command-catalog-source-of-truth]]);
   `shellcheck -S warning` clean on all five changed scripts; error and
   value-consumption paths tested per command.

### Files changed

docs/sprintmd/lib.sh
docs/sprintmd/scripts/work.sh
docs/sprintmd/scripts/chat.sh
docs/sprintmd/scripts/gate.sh
docs/sprintmd/scripts/polish.sh
docs/sprintmd/scripts/model.sh
docs/sprintmd/help/work.md
docs/sprintmd/help/chat.md
docs/sprintmd/help/gate.md
docs/sprintmd/help/polish.md
docs/sprintmd/help/model.md
DOCUMENTATION.md
