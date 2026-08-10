# Task 314: Per-command --demo flag (help explains, --demo shows)

**Feature**: none
**Created**: 2026-07-31
**Docs**: none
**Plan**: 13
**Depends on**: 313
**Blocks**: 326
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

`--help` is where a user lands when a command confuses them — the perfect moment
to offer a walkthrough. Pointing them at a separate `learn <name>` command is a
second concept to discover. The affordance should be **symmetric with help**:

- **`--help` explains** the command  
- **`--demo` shows** it (plays the matching cinematic demo)  
- **Help text says** how to get the demo: e.g. `./sprint.sh gate --demo` to see
  how it works  

Same command, two flags. No "Show me: run this other command" indirection.

## Success criteria

- [x] For a command that has a demo mapped, `./sprint.sh <cmd> --demo` plays that
      demo via the same engine as `learn` (313) and returns cleanly (Ctrl-C safe).
- [x] That command's `--help` (and `help <cmd>`) **explains as today**, and
      mentions `--demo` — e.g. a closing line:
      `Demo:  ./sprint.sh <cmd> --demo` (or "run with --demo to see how it works").
      Only when a demo is mapped; no dead affordance.
- [x] Mapping is **data-driven** (registry or equivalent): command → demo name,
      not hard-coded per help page. Prefer extending `help/_registry` (e.g. 5th
      field) so one source of truth drives both the help line and the `--demo`
      intercept.
- [x] `./sprint.sh <cmd> --demo` is intercepted in `sprint.sh` the same way
      `--help` is today (before the subcommand script runs) — demos never require
      each script to parse `--demo` itself.
- [x] Commands with **no** demo: `--help` unchanged (no demo line); `--demo`
      fails soft ("no demo for this command" + optional pointer to `./sprint.sh
      learn` for the catalog).
- [x] Flags on the demo path still pass through where useful (`--fast`,
      `--no-color`) or are documented if not — same contract as 313.
- [x] `validate --commands` / `validate --docs` still pass; help for demo-less
      commands stays free of fake demo promises.
- [x] Sparse wiring: only high-leverage commands get a mapping when their story
      exists (e.g. `gate` → S1, `plan` → S3, `newbug` → S2). Catalog-only stories
      (S0 session, S5 parallel, S6 speedrun) stay on `learn` unless a natural
      host command is obvious — do not force a bad mapping.

## Notes

**What `--help` / `--demo` mean on a host command:**

| Flag | Job |
|---|---|
| `<cmd> --help` | **Explains** how that command works (today’s help page + a one-line demo pointer when mapped) |
| `<cmd> --demo` | **Shows** it — plays a python scenario that starts from a **common problem** and lands in that command’s feature set (cinematic theater via 313’s player) |

Example: `./sprint.sh gate --help` explains the gate; `./sprint.sh gate --demo`
plays the “half-baked task held, then sharpened” story. Not a recording of the
live command against the user’s project — a safe scripted scenario.

**Relationship to `learn` (313):**

| Path | Job |
|---|---|
| `<cmd> --demo` | On-ramp from a command you already typed (host-mapped stories only) |
| `learn` / `learn <name>` | Catalog + play by name (incl. demos with **no** host command: session, parallel, speedrun) |

One player underneath — `--demo` resolves name from registry then calls the same
play function as `learn <name>`. **Not** a second command family (`demo chat`).

**Registry format — define once here:** 314 owns the **encoding** of
`command → demo name` (recommended: optional 5th pipe field on
`help/_registry`, empty = no demo). Document the format in the registry header
and in help/learn or the learning README. **Story tasks only populate** that
field for their host command; they do not invent a second mapping scheme.

**Depends on 313** for the play engine and demo home. The **mechanism**
(intercept + help line + empty-field behavior + format) can land as soon as 313
exists, with zero or one mapping. Population: `gate` when 315 lands, `newbug`
when 317 lands, `plan` when 324 lands — each story task’s success line.

**Out of scope:** writing the demo scripts themselves; interactive "press y"
prompts; changing what `learn` lists.

## References

docs/sprintmd/help/_registry             — extend with optional demo name field
sprint.sh                                — --help intercept (~392); mirror for --demo; show_command_help()
docs/tasks/next/313-add-a-learning-feature-in-app-interactive-demos-th.md
docs/plans/13-autolearning.md

<!-- When this task is finished, leave an audit trail of what it touched.
     Reviews and the change manifest read this. Copy the two headings
     below to column 0 (UNINDENTED — they are indented here only so a fresh,
     unworked task is not mistaken for a finished one), then list one
     repo-relative path per line under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintmd/scripts/example.sh

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. -->

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->

## Plan Think

**UX lock (user):** `--help` explains; `--demo` shows; help points at
`<cmd> --demo`, not at `learn <name>`. Printed-pointer-to-learn was the wrong
on-ramp (second concept). Architect: intercept like `--help`, data-driven, no
dead links, soft fail when unmapped. CXO: same command, flag pair, zero discovery
tax.

## Questions

**Status: READY**

### Already complete

Nothing for this task is wired yet. Verified against current code:

- **No `--demo` intercept** — `sprint.sh` intercepts only `--help`/`-h`
  (`sprint.sh:390-399`); there is no `--demo` arm and no `cmd_demo`.
- **Registry is still 4-field** — `docs/sprintmd/help/_registry` has no demo
  column; its header documents exactly four pipe fields.
- **The play engine this task calls does not exist yet** — `learn.sh`, the
  `learn` registry row, and `docs/sprintmd/learning/session.py` are all absent
  (the `learning/` dir exists but is empty; the S0 demo still lives only at the
  non-shipping `docs/learning/sprint_demo.py`). That is task **313**'s scope,
  and 313 is still in `next/`. This is a **dependency, not a blocker** — already
  correctly recorded as `**Depends on**: 313`.

So this is a clean greenfield mechanism task. No partial work to reconcile.

### Remaining work

The whole mechanism (intercept + help line + data-driven mapping + soft-fail),
landable as soon as 313 exists with zero or one mapping:

1. **Registry 5th field.** Add an optional 5th pipe field (`command → demo
   name`, empty = no demo) and document it in the `_registry` header. **Trap:**
   `print_command_group()` (`sprint.sh:79`) reads exactly four fields with
   `IFS='|' read -r cmd group usage summary` — a 5th field would spill into
   `summary` and print `…|demoname` in `./sprint.sh help`. Update that reader to
   consume (and discard) the 5th field.
2. **`--demo` intercept in `sprint.sh`.** Mirror the `--help` scan at
   `sprint.sh:390-399`: for a non-`help` `CMD`, if any arg is `--demo`, resolve
   the command's 5th registry field and hand the demo name to the same launcher
   313 builds (`learn.sh <name>`), then exit. Never make subcommand scripts
   parse `--demo`.
3. **Soft-fail when unmapped.** `<cmd> --demo` on a command with an empty demo
   field prints "no demo for this command" (+ optional pointer to
   `./sprint.sh learn`) and exits cleanly — no dead affordance.
4. **Help line, only when mapped.** `show_command_help()` (`sprint.sh:125`)
   should append a `Demo:  ./sprint.sh <cmd> --demo` line for commands with a
   demo mapping and stay silent otherwise. Sourcing that from the same registry
   field keeps it a single source of truth.
5. **Keep both validators green (criterion 7).** `validate --commands`
   (`check-commands.sh`) already tolerates extra fields (`cut -f1`,
   `read -r _c _g _rest`). But `validate --docs` (`check-docs.sh`) will report
   `--demo` as **stale** on every mapped command's help page, because `--demo`
   is intercepted globally (like `--help`) and parsed by no subcommand script.
   Exempt `--demo` the same way `--help` is exempted — the `grep -vx -- '--help'`
   filters in both `script_flags()` and `help_flags()`.
6. **Flag pass-through.** `--fast` / `--no-color` reach the demo (same contract
   as 313) or are documented if not.
7. **Population is deferred** — leave mappings empty; story tasks 315 (`gate`),
   317 (`newbug`), 324 (`plan`) each set their own host command's field. Do not
   force mappings for catalog-only stories (S0/S5/S6).

### Questions for the developer

None — task is fully defined. The registry-format decision (5th field) is made
in the task itself, the intercept mirrors the existing `--help` pattern, and
soft-fail / sparse-population behavior is specified. The two validator/display
traps above (items 1 and 5) are concrete engineering details to get right, not
open decisions.

## Completed

Built the whole `--demo` mechanism on top of 313's `learn` engine, with zero
mappings (population is deferred to the story tasks 315/317/324).

- **Registry 5th field.** `_registry` header now documents an optional 5th pipe
  field `demo-name` (empty/omitted = no demo). No command is mapped yet.
- **Reader fix.** `print_command_group()` in `sprint.sh` now reads the 5th
  field into `demo` and discards it, so a future mapping can never spill
  `…|demoname` into the `./sprint.sh help` index.
- **`demo_for_cmd()`** — single source of truth resolving a command → its 5th
  registry field (trimmed), empty when unmapped. Drives both the intercept and
  the help pointer.
- **`--demo` intercept** mirrors the `--help` intercept in `sprint.sh`: for any
  non-`help`/non-`learn` command carrying `--demo`, it resolves the mapped demo
  and replays it through `cmd_learn <name>`, dropping `CMD` and `--demo` and
  passing remaining flags (`--fast`, `--no-color`) straight through. Subcommand
  scripts never parse `--demo`. Verified `rc=0` and Ctrl-C safety inherited from
  `learn.sh`.
- **Soft-fail** when unmapped: `<cmd> --demo` prints "No demo for '<cmd>'." plus
  a pointer to `./sprint.sh learn`, exits 0 — no dead affordance.
- **Help pointer, only when mapped.** `show_command_help()` appends
  `Demo:  ./sprint.sh <cmd> --demo` only when `demo_for_cmd` is non-empty. The
  line is runtime-generated (not stored in the `.md`), so it can't drift.
- **Validators stay green.** Exempted `--demo` alongside `--help` in
  `check-docs.sh` (`script_flags` + `help_flags`). Both `validate --commands`
  and `validate --docs` pass. `check-commands.sh` already tolerated the extra
  field.
- **Docs.** `help/learn.md` now explains the symmetric `learn` vs `<cmd> --demo`
  on-ramps and the data-driven 5th-field mapping.

Tested by temporarily mapping `gate → session`: `gate --help` grew the Demo
line, `gate --demo --fast` played the session demo and exited 0, and the help
index stayed clean — then reverted the mapping (deferred population).

Not shipped to `src/` — left `./ship.sh` for the developer per the no-commit rule.

### Files changed
sprint.sh
docs/sprintmd/help/_registry
docs/sprintmd/scripts/check-docs.sh
docs/sprintmd/help/learn.md
