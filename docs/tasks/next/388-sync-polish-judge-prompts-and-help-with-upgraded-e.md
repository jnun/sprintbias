# Task 388: Sync polish judge prompts and help with upgraded excellence bar

**Feature**: none
**Created**: 2026-09-10
**Docs**: none
**Plan**: 25
**Depends on**: 387, 389
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

Even when the excellence and refine protocols teach the upgraded
"could this be better?" bar, a polish run can still behave as if the old bar
were in force — because runtime prompts and help are what agents actually load.
Known symptoms today: altitude prompts that enumerate an outdated dimension
list (`polish-judge.sh` still lists the five pre-Antifragility names), a sweep
posture that always treats correctness as established (`polish.sh` refine
prompt: "The work is presumed correct"), and help that never mentions the
upgraded examiner or a scannable Rework kickback. Stale runtime text undoes the
stacked protocol work.

## Success criteria

- [ ] Every polish altitude run (deep-judge, plan-scoped excellence, and
      review/ sweep) teaches the same dimension vocabulary, correctness honesty,
      report coverage expectations, and Rework kickback shape as the live
      protocols — a reader comparing prompt-to-protocol finds no contradictory
      bar.
- [ ] Runtime prefers "follow the protocol" over maintaining a second full copy
      of probes/dimensions that will rot; any remaining inline restatement
      matches the protocol or is removed. Prefer reference so the next dimension
      change does not need another sync task.
- [ ] A developer reading polish help understands, without a long essay, that
      altitude asks "could this be better?" (including Efficiency and
      Antifragility) and that a REOPEN's Improve items are scannable outcomes
      (title + done-look), not edit recipes.
- [ ] Maintainer command catalog language, if it describes polish's quality bar,
      stays consistent with that upgrade — no unrelated guide churn.
- [ ] Code-audit mode (`polish --code`) remains a correctness/conventions/safety
      fixer-verifier — altitude guidance does not leak into it.
- [ ] After the sync, a dry read of excellence and refine emit/headless prompts
      shows one shared vocabulary and one Audit-gated correctness posture —
      including closure of the two known on-disk drifts named in Problem.
- [ ] **Behavior acceptance (not markdown-only):** polish demonstrably teaches
      the new bar. At minimum, emit-mode (or an equivalent stub-CLI run) for
      deep-judge and for a review/ sweep REOPEN path shows in the prompt or
      written task artifact:
      - altitude dimensions including Antifragility (and Efficiency as more
        than a soft one-liner),
      - dimension coverage / finding-tag expectations,
      - Rework Improve items as short title + one-line done-look (not
        line-specific edit recipes; Improve as the only remaining-work list),
      - Audit-gated correctness honesty on the sweep (no unconditional
        "presume correct").
      A reader can point at that prompt or task file and see the upgraded
      contract without trusting that protocol files were edited.

## Notes

Capstone of the stack: protocols and Rework contract (384–387, 389) first, then
one sync so runtime cannot drift. Prefer reference to protocol files over
duplicating long probe lists into every prompt string.

**How to prove the behavior acceptance (implementer picks the lightest path
that still demonstrates):**
1. Preferred: extend the existing stub-CLI polish tests (excellence deep-judge
   and/or refine sweep) so emit or stubbed output asserts the new contracts —
   no live provider required, repeatable in `docs/tests/`.
2. Acceptable: one recorded emit run (`SPRINTBIAS_MODE=emit`) of
   `./sprint.sh polish <fixture-or-task>` and a sweep REOPEN path, with the
   prompt excerpt saved under `docs/tmp/` or pasted into `## Completed`.
3. Optional extra: a live provider dogfood pass — nice, not required if stub
   or emit already shows the contracts.

Do not treat "protocol files differ from before" as acceptance by itself.

## References

docs/sprintbias/scripts/polish-judge.sh
docs/sprintbias/scripts/polish.sh
docs/sprintbias/scripts/plan-polish.sh
docs/sprintbias/lib.sh
docs/sprintbias/help/polish.md
docs/sprintbias/ai/audit-excellence.md
docs/sprintbias/ai/refine.md
docs/guides/command-matrix.md
docs/guides/running-tests.md
docs/tests/test-audit-excellence.sh
docs/plans/25-raise-polish-altitude-bar-could-this-be-better-exa.md

## Plan Think

**Architect:** One sync after protocols land is the DRY / antifragile last mile
— prefer protocol reference so dimension churn does not require another task.
**CXO:** Help must say the new bar in plain language; developers should not
discover Antifragility or scannable Rework only by reading protocol files.
**Tension:** Inline enum convenience vs. future rot → prefer "follow PROTOCOL";
inline only if it matches and is minimal.
**Lens that drove change:** Best practice (single source of truth) +
antifragility (close known runner drift in one place).

## Questions

**Status: READY**

### Already complete
- Protocol-embed pattern is already the right shape: both `polish-judge.sh` and
  `polish.sh` `_refine_prompt` inline `$(<"$PROTOCOL")` so the live protocol is
  the source of truth once 384–387/389 land — keep that; do not grow a second
  full probe copy in the runners.
- Deep-judge correctness honesty is already Audit-gated in the runner
  (`polish-judge.sh` ~153–166 builds `CORRECTNESS_RULE` from
  `sprintbias_correctness_state`); only the dimension *enum* on step 3 is stale.
- `polish --code` prompts stay on correctness / conventions / style / safety
  (`polish.sh` fixer/verifier paths ~266–271, ~505, ~533, ~614) — no altitude
  leak today; preserve that boundary.
- `plan-polish.sh` has no separate dimension list; it routes members through
  `polish-judge.sh`, so fixing the deep-judge prompt covers plan polish too.
- `docs/guides/command-matrix.md` names polish modes but does not enumerate the
  altitude dimension bar — no contradictory catalog language today.
- Existing stub coverage (`docs/tests/test-audit-excellence.sh`) exercises emit
  and exec for deep-judge but does not yet assert Antifragility, coverage tags,
  Audit-gated sweep honesty, or scannable Improve shape.

### Remaining work
- **Depends on 387, 389** (and transitively 384–386): wait for upgraded
  `audit-excellence.md` / `refine.md` (Efficiency probes, Antifragility,
  Audit-gated refine posture, dimension-tagged findings + coverage, scannable
  Rework Improve) before syncing runners/help to them.
- Close known deep-judge drift: replace or drop the hardcoded five-name list in
  `polish-judge.sh` step 3 (`Judge: effectiveness, efficiency, design fit,
  operability, robustness`) — prefer "follow PROTOCOL dimensions" (or a
  minimal restatement that matches the live protocol including Antifragility).
- Close known sweep drift: replace unconditional
  `The work is presumed correct` in `polish.sh` `_refine_prompt` with
  Audit-gated honesty matching excellence / post-386 `refine.md` (presume only
  when a passing `## Audit` is on file).
- Sync `docs/sprintbias/help/polish.md`: deep-judge dimension vocabulary must
  include Antifragility and the upgraded Efficiency bar; sweep/REOPEN help must
  say Improve items are short title + one-line done-look (not edit recipes).
  Keep it short — no essay.
- Prefer protocol reference over duplicating long probe/report contracts in
  prompt strings; any leftover inline restatement must match the protocols.
- Re-check command-matrix only if it starts describing the quality bar; no
  unrelated guide churn.
- Keep `polish --code` free of altitude guidance.
- **Behavior acceptance:** extend stub-CLI / emit tests (preferred) — or record
  one emit run — so deep-judge and a sweep REOPEN path demonstrably teach
  Antifragility + stronger Efficiency, dimension coverage / finding tags,
  scannable Improve (title + done-look; Improve as only remaining-work list),
  and Audit-gated sweep honesty (no unconditional "presume correct"). Protocol
  file diffs alone do not close this task.

### Questions for the developer
None — task is fully defined.
