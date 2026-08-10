# Task 297: Dual-provider smoke protocol on a fresh project for upcoming plans

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Plan**: 11
**Depends on**: 294, 296
**Blocks**: none
**Parent**: none
**Reworked**: 1
**Refined**: 1

**Status: READY**

## Problem

Upcoming plans ship product changes that must work under both Claude Code and
Grok. We need a short, repeatable smoke that runs a **real task or plan in this
repo** under each provider and confirms both drive the SprintBias spine to an
equivalent, correct outcome — same commands, same lifecycle, results that differ
only by provider tier. Passing the smoke on whatever plan/task is being shipped
*is* the signal it works on both hosts; the tool does not behave differently
once installed, and install-path correctness is a separate, provider-independent
concern (**out of scope here**). When no real work is pending, a standing
**command-matrix doc-sweep** task gives the smoke genuine material so it is never
blocked on "nothing to work." Both legs run in one project (this repo), switching
provider config between them.

## Success criteria

- [ ] Documented protocol (guide under `docs/guides/`, repo-only) for running,
      **in this repo**, a real task/plan under each provider:
      1. Set provider to Claude (`./sprint.sh model …` / config), pick the target
         work — the plan/task being shipped, or the command-matrix sweep fallback
         — and run `./sprint.sh work`.
      2. Switch provider to Grok, reset the same target, run `./sprint.sh work`.
      3. Compare — outcomes equivalent, differing only by provider tier.
- [ ] Both providers run in **one project (this repo)** by switching provider
      config between legs — that is the intended design here, not a bonus.
- [ ] Protocol names exact commands and **objective** pass criteria (not vibes).
- [ ] A standing **command-matrix doc-sweep** task exists as the always-available
      fallback workload, so the smoke is never blocked when the sprint is empty.
      The sweep reconciles `docs/guides/command-matrix.md` against the current
      codebase: every command present, the list complete, each note short and
      clear. It always has genuine drift to fix (real work, repeatable).
- [ ] The dry run actually exercises `work` end-to-end under **each** provider
      against the real target — not a spine of `newtask`/`status` alone. This is
      where the two hosts diverge, so skipping it guts the smoke. The operator
      must:
      1. Run `./sprint.sh work` so the provider's real CLI (`claude`/`grok`)
         launches and does the work (requires the CLI on PATH + auth).
      2. Watch the session live to confirm it drives the spine correctly.
      3. Record pass/fail per provider against an **objective** checklist: the
         correct CLI launched (not the other, no fallback); the task moved
         through the lifecycle (`next`→`doing`→`review`); its success criteria
         were addressed; expected files changed; no crash. All boxes → pass, and
         the two hosts' outcomes differ only by provider tier.
- [ ] Runs in ~30–60 minutes, before marking a later plan's "ship" task done —
      not a multi-day matrix.

## Notes

- This task delivers the **protocol and one dry run**, not perpetual CI of two
  providers.
- **Not a fresh-install test.** The earlier framing (fresh `/tmp` project +
  `./setup.sh` picker + empty-project spine) was dropped: install correctness is
  provider-independent and belongs elsewhere. 297 is strictly the *real-work*
  dual-provider smoke, run in this repo — the tool does not behave differently
  once installed, so proving it on real work here proves it for users.
- **The `work` target** is the plan/task actually being shipped when one is
  pending; otherwise the standing **command-matrix doc-sweep** task. The same
  target runs on both legs so the only variable across hosts is the provider.
- **Existing deliverable needs refocusing.** `docs/guides/dual-provider-smoke.md`
  (and its "Last dry run" table) was written around fresh install; it must be
  rewritten to the in-repo real-work protocol above. The prior pointers from
  README / provider guides stay but should describe the new scope.
- **Boundary with siblings:** 300 owns the *offline* command-matrix emit smoke
  (network-free, no live CLI); 297 is the *live* real-work smoke. The
  command-matrix sweep here is a live-work fixture, not a duplicate of 300.

## References

setup.sh
ship.sh
docs/guides/grok-provider-tier.md
docs/guides/claude-provider-tier.md
GETSTARTED.md

## Completed

Authored a single dedicated protocol guide (Question 1's recommended shape):
`docs/guides/dual-provider-smoke.md` — repo-only, not mirrored into `src/`,
since it is a maintainer release ritual and installed projects should not
receive it (pointing a shipped file at it would be a dead link in user trees).

The guide names exact commands and pass criteria for: fresh `mkdir` +
`./setup.sh` picking Claude → tiny spine (`model show` → `newtask` → `status` →
`work`); a second fresh tree picking Grok → same spine; the model show/switch
step (`./sprint.sh model show|list|set`, with a `docs/sprintbias/config` fallback);
and a compare step. It enforces **ship-before-smoke** (`./ship.sh` mirrors
`docs/sprintbias → src/`; `setup.sh` installs from `src/`, so the install path is
what gets tested — no hand-copy). It keeps single-project dual-config as an
explicit optional bonus (per-run `-c`/`-g` flags), not a requirement. Budget is
stated as ~30–60 min. Boundary with sibling task 301 (automate the
non-interactive subset) is stated in the guide so they don't collide.

**One dry run performed** (captured in the guide's "Last dry run" table). Using
the current shipped `src/`, non-interactive `./setup.sh` into `/tmp/sm-claude`
(door=Enter) and `/tmp/sm-grok` (door=g) both finished with
`All Checks Passed`. Config wrote `CLI=claude`/`PROVIDER=claude-code` and
`CLI=grok`/`PROVIDER=grok-build` respectively; `./sprint.sh model show` reported
provider-correct tier defaults (`opus` vs `grok-4.5`); `newtask` + `status`
created and counted a task in each tree. The agent-execution `work` step is
provider-configured (needs `claude`/`grok` on PATH + auth) and is left to the
release operator per the protocol's scope. Temp trees removed (`rm -rf`).

Pointers added from `README.md` (repo-only) and both provider guides
(`grok-provider-tier.md`, `claude-provider-tier.md`). No pointer added to
`GETSTARTED.md` because it ships to user projects, which do not receive the
repo-only guide.

### Files changed
docs/guides/dual-provider-smoke.md
README.md
docs/guides/grok-provider-tier.md
docs/guides/claude-provider-tier.md
docs/tasks/doing/297-dual-provider-smoke-protocol-on-a-fresh-project-fo.md

## Rework (round 1)

**Why:** The guide's whole value is Success-criterion #2 — "names exact
commands and pass criteria (not vibes)" — but step 3's model-switch command is
wrong. `docs/guides/dual-provider-smoke.md:136` writes
`./sprint.sh model set MODEL_DEFAULT grok-4.5`, yet `cmd_set` in
`docs/sprintbias/scripts/model.sh:154–182` only accepts `default` or a role name
as the key (it uppercases the arg and matches `DEFAULT` or `KNOWN_ROLES`, never
`MODEL_DEFAULT`). Copy-pasting the documented line fails with
`ERROR: unknown key 'MODEL_DEFAULT'`, and the step-3 pass criteria at line 140
cascades off a command that never runs.

**Improve:**
- [ ] Fix `docs/guides/dual-provider-smoke.md:136` to use the accepted key form
      — `./sprint.sh model set default grok-4.5` (matches `model.sh` usage at
      lines 43 and 147). Adjust the trailing comment/pass line (140) if needed so
      it still reads correctly.
- [ ] Re-verify every remaining `./sprint.sh model ...` invocation in the guide
      against `model.sh`'s dispatch and `cmd_set` key rules, so no other step
      names a command that errors when run verbatim.

## Refine (round 1)

**Sharpened:** Repointed the whole task. Two problems fell out of one review:
(1) the "one dry run" never exercised `work` — the provider-specific step where
the hosts actually diverge — yet criterion #4 was checked; (2) more fundamentally
the task was framed as a **fresh-install** smoke, but install correctness is
provider-independent and not what a dual-provider check should prove. Decision:
**297 becomes a real-work, in-repo dual-provider smoke.** Run `work` on the
plan/task actually being shipped under Claude, then under Grok, in this repo
(switching provider config between legs), and confirm equivalent, correct
outcomes via an **objective** checklist (right CLI launched, task moved
`next`→`doing`→`review`, criteria addressed, files changed, no crash, no
divergence beyond provider tier). A standing **command-matrix doc-sweep** task is
the always-available fallback workload so the smoke is never blocked on an empty
sprint. Fresh-install framing, `/tmp` trees, and the "ship-before-setup" spine
were removed. Consequence: the existing guide `dual-provider-smoke.md` was built
on the old premise and must be rewritten; success boxes were re-opened. The
Rework (round 1) command-string fix is now moot (that guide step is being
replaced).

## Questions

**Status: READY**

### Status after the refocus

The first pass authored `docs/guides/dual-provider-smoke.md` and ran a dry run —
but both were built on the now-dropped fresh-install premise, so they are
**partially off-target, not done**:

- **Guide** — exists and is well-formed, but it describes fresh `/tmp` install +
  setup picker + an install/config/model spine. It must be **rewritten** to the
  in-repo real-work protocol (Claude leg → Grok leg on the same real target →
  objective compare).
- **Dry run** — the captured "Last dry run" table proves
  install/config/`model show`/`newtask`, i.e. exactly the install-path steps now
  out of scope. It does **not** prove a real-work `work` run under either
  provider, which is now the core of the task.
- **Reusable** — README + provider-guide pointers stay (rescope the wording);
  `./sprint.sh model show/list/set` is real (dep 294 landed) and is still how the
  Claude/Grok legs switch provider tier. The old Rework (round 1) `model set` fix
  is subsumed by the rewrite.

### Remaining work

1. **Rewrite the guide** `docs/guides/dual-provider-smoke.md` to the in-repo
   real-work protocol: pick target (the shipping plan/task, or the command-matrix
   sweep fallback) → set Claude, `./sprint.sh work` → reset the same target, set
   Grok, `./sprint.sh work` → objective compare. Drop the
   fresh-install/`/tmp`/setup sections.
2. **Create the standing command-matrix doc-sweep task** as the always-available
   fallback workload — reconcile `docs/guides/command-matrix.md` against the
   codebase (every command present, list complete, each note short and clear).
   Keep it distinct from sibling 300's offline emit smoke.
3. **Run the real-work dry run** under each provider against a real target, watch
   live, and record objective pass/fail per host (needs `claude`/`grok` on
   PATH + auth).

### Questions for the developer

None — fully defined and READY. The task was repointed this session from a
fresh-install smoke to an in-repo real-work dual-provider smoke; scope is the
three items above.
