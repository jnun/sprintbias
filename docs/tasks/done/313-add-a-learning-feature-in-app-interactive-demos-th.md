# Task 313: Framework: learn engine, flat learning home, trust guard, S0 session demo

**Feature**: none
**Created**: 2026-07-31
**Docs**: none
**Plan**: 13
**Depends on**: none
**Blocks**: 314, 315, 316, 317, 324, 325, 326
**Parent**: none
**Refined**: 0
**Reworked**: 0

## Problem

A new user installs SprintBias and reads `DOCUMENTATION.md`, but reading the
manual is not the same as *seeing* the flow run. The lifecycle, the gate, and
the spine click only once you watch a real session move through them. There is
no way to *learn by watching* from inside the tool — and no permanent, shipping
home for safe demo scripts. A person should open a catalog (`learn`), play a
named demo, or (later, 314) run `<cmd> --demo` on a real command and watch a
short cinematic walkthrough with no setup and no risk to their project.

## Success criteria

- [x] `./sprint.sh learn` lists available demos (name + one-line description from
      each script's docstring) and tells the user how to play one.
- [x] `./sprint.sh learn <name>` plays that demo and returns cleanly (including
      on Ctrl-C, verified exit 130 + interrupt message); unknown names list what exists.
- [x] Demos live under the **flat** ship home `docs/sprintmd/learning/*.py` (plus
      README owned by 315). The starter **S0** demo is relocated from
      `docs/learning/sprint_demo.py` → `docs/sprintmd/learning/session.py`;
      the non-shipping `docs/learning/` path is removed (no longer the sole copy).
- [x] S0 plays end to end with **python3 + stdlib only** — no third-party deps.
- [x] `--fast` and `--no-color` are honored; output degrades when stdout is not a TTY
      (0 escape sequences when piped).
- [x] When `python3` is unavailable the command fails soft: explains what's missing
      and points at the manual (verified with a python3-less PATH; listing still works).
- [x] **Trust contract (verified, not only asserted):** playing a demo never
      touches the user's project — writes nothing, moves no task files, no
      provider/network. Guard `docs/sprintmd/tests/learn-sandbox.sh` plays each demo
      in a temp dir and asserts zero file changes in the project tree — passes.
- [x] **Fresh-install release gate:** `./ship.sh --dry-run` confirms the new
      `learning/`, `learn.sh`, `learn.md`, and `tests/` paths ship with gates clean;
      a fresh empty install assembled from the live tree lists demos and plays the
      starter end to end with zero writes. (Real `./ship.sh` left to the developer:
      the working tree carries unrelated pending `docs/sprintmd/` edits a ship would
      also mirror + version-bump.)
- [x] `learn` is on all four command surfaces (`help/_registry`, `sprint.sh`
      dispatch, `help/learn.md`, `DOCUMENTATION.md`) and `validate --commands` passes
      (also `validate --docs` clean).
- [x] S0's opening beat surfaces the sandbox promise ("touches nothing in your
      project") so the trust pitch is felt, not only documented.

## Notes

**What we're building:** the **framework** layer of Plan 13 (autolearning), plus
the first story (**S0 — one session**). Later: README/curriculum (315),
**`<cmd> --demo`** on-ramp (314), more stories (317/324/316/325). Keep the
boundary clean: this task owns **play engine + home + S0 + trust proof + `learn`
catalog**. It does **not** own the per-command `--demo` intercept (314), but the
play path must be callable so 314 can resolve registry → same player.

**Layout (locked — flat):**

```text
docs/sprintmd/learning/
  session.py     # S0 (this task)
  README.md      # 315
  …              # later stories; no nested scripts/ until multi-runtime
```

Because `ship.sh` rsyncs the whole `docs/sprintmd/` tree, a new `learning/`
subdir ships automatically — no `ship.sh` manifest edit expected.

**Launcher (`learn.sh`):** resolve demos dir relative to the script; no-arg →
list `*.py` with docstring first line; `<name>` → `exec python3 <path> "$@"` so
flags pass through. Missing python3 → soft message. Unknown name → list. Thin
bash; demos hold content. Auto-register: new `*.py` appears with no launcher change.

**S0 story:** a new user hits a real problem and closes it in one session
(lifecycle + plan/work beats as the sample already sketches). Reframe/rename from
the incubator script; keep it a **situation**, not a feature dump. Optional later:
other runtimes (JS/bash) retell the same stories — out of scope here.

**S0 scope discipline (non-negotiable):** S0 must **not** re-teach S2/S3/S6.
Conversion (bug→task) is 317; feature→plan + plan-think is 324; pure momentum
speed run is 325. If the incubator script already walks all of those, **trim it**
when relocating — one problem, one session, light spine only. Demo only commands
that exist in the product (or clearly mark anything still proposed).

**Constraints:** pure theater — stdlib only, no writes, no network, no provider,
no dependence on the user's real task folders. Identical in a fresh empty install.

**Surfaces:** `_registry`, dispatch, `help/learn.md`, `DOCUMENTATION.md` — then
`./ship.sh`, then fresh-install smoke of `learn`.

**Out of scope:** per-command `--demo` intercept and help line (314), authoring
guide (315), S1–S6 demos.

## References

docs/learning/sprint_demo.py             — incubator S0; relocate under docs/sprintmd/learning/
docs/sprintmd/scripts/create-task.sh     — path-relative + soft-fail pattern
docs/sprintmd/help/_registry             — add learn entry
docs/sprintmd/help/work.md               — help-page shape for help/learn.md
sprint.sh                                — dispatch
ship.sh                                  — mirrors docs/sprintmd/ whole tree
DOCUMENTATION.md                         — document learn
docs/plans/13-autolearning.md            — plan + curriculum

<!-- When this task is finished, leave an audit trail of what it touched.
     Reviews and the change manifest read this. Copy the two headings
     below to column 0 (UNINDENTED — they are indented here only so a fresh,
     unworked task is not mistaken for a finished one), then list one
     repo-relative path per line under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintmd/scripts/example.sh
       docs/tasks/.TEMPLATE-task.md

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. -->

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->

## Plan Think

**Locked decisions.** Full curriculum; flat `docs/sprintmd/learning/` + README;
trust guard + fresh-install gate are hard acceptance. 316/317/324/325 depend on
this engine.

**Perspective check (abbrev.).** Architect: dual-tree relocate + verified
no-writes are release integrity. CXO: plain `learn`, catalog-then-play, sandbox
promise in the first frame. Tension (theater vs determinism) resolves via
`--fast` / non-TTY. No structural change from earlier annotation — only sharper
acceptance and curriculum role as S0.

## Questions

**Status: READY**

### Already complete

Nothing for the `learn` command is wired yet — no launcher, no registry row, no
dispatch arm, no help page, and `docs/sprintmd/learning/` does not exist. But the
**S0 demo content already exists and is in good shape** at the non-shipping
`docs/learning/sprint_demo.py`, and it already satisfies several acceptance
criteria that just need to travel with the relocation:

- **stdlib only** (`sys`, `time`, `shutil`, `random`) — criterion 4 met.
- **`--fast` and `--no-color` honored; non-TTY degrades color** — `NO_COLOR` is
  set on `--no-color` *or* `not sys.stdout.isatty()`; criterion 5 met.
- **Clean Ctrl-C** — `main()` catches `KeyboardInterrupt` and exits 130; the
  demo half of criterion 2 met.
- **No writes / no network** — the script is pure terminal theater (no file or
  socket I/O), so the trust contract should verify green once the guard exists.

These are context, not scope — they carry over when the file is relocated and
reframed. Note the current docstring/outro still pitches it as an "incubator"
showcasing `work N` (310) and `newplan ids` (312); criterion in Notes calls for
reframing it as a *situation* (S0), so expect a copy pass, not a rewrite.

### Remaining work

1. **Build `learn.sh`** under `docs/sprintmd/scripts/`: resolve the demos dir
   relative to the script (mirror `create-task.sh`), no-arg → list `*.py` with
   the docstring first line, `<name>` → `exec python3 <path> "$@"`, missing
   `python3` → soft message pointing at the manual, unknown name → list. Thin
   bash, auto-registering.
2. **Relocate + reframe S0**: `docs/learning/sprint_demo.py` →
   `docs/sprintmd/learning/session.py`; retire the non-shipping copy as the sole
   source; reframe as a situation and add an **opening beat** surfacing the
   sandbox promise ("touches nothing in your project") — criterion 10.
3. **Four surfaces**: registry row, `sprint.sh` dispatch arm + `cmd_learn`,
   `docs/sprintmd/help/learn.md`, and a `DOCUMENTATION.md` §Commands entry; then
   `./sprint.sh validate --commands` passes.
4. **Trust guard**: a check that runs a demo (e.g. `--fast`) in a temp CWD and
   asserts zero file changes in the project tree.
5. **Ship + fresh-install gate**: `./ship.sh`, then `./setup.sh` into an empty
   dir, confirm `learn` lists and `learn session` plays end to end.

### Questions for the developer

1. Which command family should `learn` sit in? `validate --commands` (check 5)
   rejects any group outside `create · chat · plan · work · look · keep`, so a
   new `learn` group would fail the gate. (Suggestion: put it in **`look`** —
   it's read-only, side-effect-free, and "watch the flow run" reads as a look
   verb; no taxonomy change needed and the completeness gate stays green.)
2. Where should the trust guard live and how is it invoked? (Suggestion: a small
   script under `docs/sprintmd/tests/` run by the run-all harness that task 302
   is standing up — `cd` to a temp dir, snapshot the repo tree, run
   `learn session --fast`, diff and assert no changes. Keep it a test, not a
   runtime gate on every `learn` invocation, so playback stays instant.)

## Completed

Built the **learn** engine: catalog + play launcher, the flat shipping home
`docs/sprintmd/learning/`, the relocated + reframed **S0** demo, a verified trust
guard, and all four command surfaces.

**Developer decisions taken** (matching the Questions' suggestions):
- `learn` sits in the **`look`** family (read-only theater) — `validate --commands`
  stays green; no taxonomy change.
- Trust guard lives at `docs/sprintmd/tests/learn-sandbox.sh` — a test, not a
  runtime gate, so playback stays instant. It ships automatically (new subtree
  under `docs/sprintmd/`). It's ready for task 302's run-all harness to call.

**What each piece does**
- `scripts/learn.sh` — thin, auto-registering launcher. No arg → lists every
  `learning/*.py` with its docstring first line (extracted via awk, so listing
  works even without python3). `<name>` → `exec python3` with flags passed
  through. Unknown name → lists what exists. Missing python3 → soft message
  pointing at the manual.
- `learning/session.py` — S0 relocated from the non-shipping
  `docs/learning/sprint_demo.py` (now removed) and **reframed as a situation**,
  not a feature dump. Trimmed to *one problem, one session, light spine*
  (`newtask → chat → work`): dropped the old Act-2/3/4 material that re-taught
  split / newplan / unblock / plan-done (that's 317/324/325's scope) and stopped
  demoing the still-proposed `work N` (310) / `newplan ids` (312). Opening beat
  now leads with the sandbox promise.

**Verification**
- `validate --commands` and `validate --docs` both pass.
- `learn`, `learn session`, unknown-name, `--fast`, `--no-color`, non-TTY
  (0 escape sequences piped), and python3-missing soft-fail all exercised.
- Ctrl-C: `gtimeout --preserve-status -s INT` → exit **130** with the interrupt
  message.
- Trust guard passes (zero project changes; empty sandbox dir).
- Fresh empty install assembled from the live tree: `learn` lists and
  `learn session` plays end to end with no writes. `ship.sh --dry-run` confirms
  the new paths ship with release gates clean (0.0.59 → 0.0.60). The real
  `./ship.sh` is left to the developer since the working tree has unrelated
  pending `docs/sprintmd/` edits a ship would also mirror and version-bump.

### Files changed
docs/sprintmd/learning/session.py
docs/sprintmd/scripts/learn.sh
docs/sprintmd/help/learn.md
docs/sprintmd/help/_registry
docs/sprintmd/tests/learn-sandbox.sh
sprint.sh
DOCUMENTATION.md
docs/learning/sprint_demo.py
