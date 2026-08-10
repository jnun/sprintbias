# Task 345: Create learn demo for split command

**Feature**: none
**Created**: 2026-08-03
**Docs**: none
**Plan**: 18
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 2
**Reworked**: 0

<!-- Plan: which docs/plans/N-… this belongs to (membership reverse index).
     Depends on: task IDs that must finish first.
     Dependents: reverse edge — task IDs that wait on this one.
     Parent: task-to-task grouping only (not Plan).
     Docs: guide to read while building.
     Tests: docs/tests/*.sh that prove success criteria for `promote`
     (all must pass → review/ to done/). Product newtest loops are not Tests.
     Legacy aliases (read only): Dependents←Blocks, Tests←Proven by.
     Write only the canonical names. -->

## Problem

`split` is SprintBias's one-shot decomposer — hand it an oversized task and it
fans that task into 3–10 atomic sub-tasks, orders them by dependency, heals the
graph so both ends of every edge stay reciprocal, then retires the original.
Most users never discover it: it's off-spine, reached only once someone already
has a too-big task, and the learning catalog has no demo for it. So a newcomer
can't *watch* a giant task break cleanly into workable pieces — and can't see
the part that makes split safe to trust: nothing is left dangling when the
parent disappears.

## Success criteria

<!-- Observable behaviors that show it's done: "User can [do what]" /
     "App shows [result]". Clear and succinct — anyone can verify. -->

- [x] A new demo file `docs/sprintbias/learning/split.py` exists and follows the
      house guide (first docstring line = catalog summary; stdlib-only Python 3;
      no deps).
- [x] `./sprint.sh learn` lists it automatically; `./sprint.sh learn split`
      plays it.
- [x] The demo is pure theater — it writes/moves no files, makes no network
      calls, and touches nothing in the user's project (the banner states this).
- [x] The story shows split's distinctive beat: one oversized task fanning into
      several atomic, dependency-ordered sub-tasks, then the parent retired —
      and the graph left whole (a task that depended on the parent now follows
      the first child; every new edge shown reciprocal, nothing dangling).
- [x] `split`'s row in `docs/sprintbias/help/_registry` gains its optional 5th
      pipe field `| split`, so `./sprint.sh split --demo` plays the new demo and
      `split --help` shows the auto-generated "Demo:" pointer.
- [x] The demo honors the house flags: `--fast`, `--no-color`, `-h/--help`, and
      degrades cleanly on non-TTY / Ctrl-C (matching the sibling demos).
- [x] The curriculum map in `docs/sprintbias/learning/README.md` gains split's
      row.
- [x] Change is shipped: `./ship.sh` mirrors `learning/split.py` and the
      registry edit into `src/` and bumps the version.
- [x] `./sprint.sh validate --commands` and `--docs` stay green (registry, help,
      and manual remain in sync after the demo map is added).

## Notes

**The distinguishing beat.** Every other demo follows one task down the spine.
split does the opposite — it takes one task and *multiplies* it. The story to
dramatize is fan-out + graph integrity: a big task splits into ordered children,
the parent is deleted, and the viewer sees the edges heal so nothing dangles.
That last part is split's trust promise and no other demo owns it — don't reduce
this to a generic "big becomes small" montage. Match the voice, palette, and
flag handling of the existing demos.

**The pinned scenario.** Use a parent whose pieces have *real* ordering and that
something else already depends on, so both the fan-out and the heal have teeth
(these are the two things a flat "big → small" list can't show):

- Parent: `docs/tasks/backlog/455-add-company-billing-to-the-dashboard.md` — an
  oversized task the viewer can feel is too big for one sitting.
- It fans into four dependency-ordered children:
  1. Add the `billing` table + migration
  2. Build the billing API endpoint  *(depends on 1)*
  3. Add the permission check to that endpoint  *(depends on 2)*
  4. Show the billing panel in the dashboard UI  *(depends on 3)*
- The heal beat: a **pre-existing** task `461-email-monthly-invoices` depended on
  the whole parent `455`. When `455` is retired, show 461 rewired to follow the
  first child (the migration) — reciprocal on both ends — so nothing points at
  the deleted id. That single moment is the trust payoff; give it a clear beat.

The IDs/titles are illustrative theater — the demo invents them; it must not
read or touch any real task files.

**How `split` actually works today** (source: `docs/sprintbias/scripts/split.sh`)
— narrate this faithfully as theater, don't run it:
- Takes one arg, a path to a task file (the pinned scenario above is the
  parent to dramatize). No conversation — it's one-shot, off-spine.
- An agent reads the task and current code, then creates 3–10 **atomic**
  sub-tasks (one discrete change each, touching as few files as possible) via
  `./sprint.sh newtask '…'`, ordered by dependency (A before B when B needs A).
  It skips work already done. If it would need >10, it makes 2–3 medium tasks
  instead of many micro-tasks.
- Each child gets `**Parent**: <parent-id>` and a `**Depends on**:` line (the
  previous child when order matters, else `none`).
- **Then it heals the graph before retiring the parent** — every edge routed
  through lib helpers so both ends stay in sync: each child's declared
  `Depends on` is made reciprocal (`sprintbias_ensure_reciprocal`), and the
  parent is folded into its first (lowest-id) child (`sprintbias_rewrite_dep_id`)
  so anything that depended on the whole parent now depends on that child
  instead of a deleted id.
- Only after verifying sub-tasks were actually created does it delete the
  original (`git rm`, else `rm`). No sub-tasks detected → original preserved.

**How demos register** (source: `docs/sprintbias/scripts/learn.sh`) — no manifest,
no launcher edit. `learn.sh` resolves `learn <name>` to `learning/<name>.py`;
the no-arg catalog scans `learning/*.py` and uses each module's **first non-empty
docstring line** as its summary. Naming the file `split.py` is what makes
`./sprint.sh learn split` play it and lists it in `./sprint.sh learn`.

**How `split --demo` maps** (source: `docs/sprintbias/help/_registry`, header
comment) — `--demo` is a global dispatcher intercept in `sprint.sh`, not parsed
by `split.sh`. It reads the row's **optional 5th pipe field** = demo-name.
split's row currently has four fields; add `| split` as the fifth. Exact edit
(verified against the registry 2026-08-10):

    before:  split         | work     | <path>              | Off-spine — one-shot split of a large task into subtasks (no conversation)
    after:   split         | work     | <path>              | Off-spine — one-shot split of a large task into subtasks (no conversation) | split

That one edit makes `./sprint.sh split --demo` play `learning/split.py`
(via the `demo_for_cmd` resolver + `--demo` intercept in `sprint.sh`) and adds
the "Demo:  ./sprint.sh split --demo" pointer to `split --help` automatically.
Don't invent a second command→demo scheme.

**Starting point + the house contract to carry** (verified in
`docs/sprintbias/learning/work.py`, 2026-08-10). Practical path: **copy the
newest demo (`work.py`), keep its helper block, rewrite the story.** Each demo is
self-contained — there is intentionally no shared `_demokit.py`, so the file
carries its own copy of these presentation atoms; reuse the names verbatim so
every demo reads as the same tool talking:
- `type_out(text, color, cps)` — typewriter effect with human jitter
- `prompt_and_type(cmd)` — a shell prompt that pauses, then types a command
- `spinner(label, done=…, tone=…, mark=…)` — a working spinner resolving to a
  verdict (`READY` / `done` / colored non-green outcome)
- `act(title, subtitle)` — an act header with a rule beneath it
- `beat(text)` — the narrator aside between commands (the *why*)
- `moved(a, b)` — a lifecycle move, e.g. `backlog/455 → (retired)`
- `ok` / `note` / `held` / `nextstep` — SprintBias's fake response lines
The flag/terminal contract, copied from `work.py`: `FAST = "--fast" in sys.argv`;
`NO_COLOR = "--no-color" in sys.argv or not sys.stdout.isatty()` (auto-plain when
piped); `-h/--help` prints `__doc__` and exits 0; `KeyboardInterrupt` prints a
dim `…demo interrupted.` and exits 130.

**After editing (this is distributable code).** `learning/` ships under
`docs/sprintbias/`, so finish with the repo flow: edit in `docs/`, play it in
place (`./sprint.sh learn split`, `./sprint.sh split --demo`), then `./ship.sh`
to mirror into `src/` and bump the version. Verify catalog/help/manual stay in
sync with `./sprint.sh validate --commands` and `--docs`.

## References

docs/sprintbias/learning/README.md       — house guide: voice, flat layout, auto-registration, trust contract
docs/sprintbias/learning/parallel.py      — closest reference for dramatizing dependency edges between tasks
docs/sprintbias/learning/work.py          — recent skeleton to mirror (docstring, flags, palette, timing helpers)
docs/sprintbias/scripts/split.sh          — the real command this demo narrates (fan-out + graph heal + retire)
docs/sprintbias/scripts/learn.sh          — how a demo name resolves and auto-registers
docs/sprintbias/help/_registry            — add the 5th demo field to split's row (format in its header comment)
sprint.sh                                 — the global --demo / --help intercept and demo resolver
ship.sh                                   — mirror docs/ → src/ and bump version after the change

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
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->

## Plan Think

**Superseded 2026-08-10.** The 2026-08-03 "defer" below rested on the old
*curated-slot* curriculum (a handful of hand-picked S0–S8 stories, where every
extra demo diluted the guided path). That model has since been replaced by
**per-command example coverage** — the 338–357 task family gives every command
its own demo, and task 357 rewrites the README rule to match. Under that policy
`split` is no longer a scarce-slot tradeoff; it's a command that should have a
demo like any other, and it owns a beat (fan-out + graph healing) no other demo
shows. Decision: **build it now**, mirroring the pattern set by task 344 (loop).
The original reasoning is kept below for provenance.

**Perspective check (original, 2026-08-03).**
- *Chief Platform Architect:* `split` is an off-spine, one-shot decomposition of a large task. Low integrity risk, genuinely useful — but it's a power-user tool reached only once someone already has an oversized task. Not a foundational concept the catalog must teach early.
- *Chief Experience Officer:* This is not a first-run moment. A newcomer has nothing to split. Spending a curated demo slot here trades onboarding clarity for an edge case, and every extra demo dilutes the guided path.

**Original resolution (now superseded).** Both ranked this low → **defer** until
the core capture→convert→plan→automate curriculum was complete. Overturned by
the per-command-coverage shift above.

## Refine (round 1)

**Sharpened:** Overturned the stale "defer" verdict — the per-command-coverage
shift (the 338–357 family + task 357's README rewrite) replaced the curated-slot
scarcity the defer was protecting, so `split` gets a demo now. Filled the empty
stub into a real brief mirroring task 344 (loop): a `split.py` demo whose
distinctive beat is fan-out + graph healing (big task → ordered atomic children
→ parent retired → edges reciprocal, nothing dangling), mapped to `split --demo`
via the registry 5th field. Verified split's real behavior in `split.sh` and the
demo registration mechanics, and folded both into Notes with `./ship.sh` +
`validate` steps and per-file References. Pinned a concrete scenario (parent 455
"add company billing" → four dependency-ordered children, plus a pre-existing
task 461 rewired on retire) so both the fan-out and the graph-heal beat have
teeth a flat "big → small" list can't show.

## Refine (round 2)

**Sharpened:** Made the task fully self-contained and verified every mechanic
against current code (2026-08-10): the registry format (4 fields + optional 5th
demo-name, group `work`) and split's exact row; the `--demo` intercept +
`demo_for_cmd` resolver in `sprint.sh`; `learn.sh` name→file + docstring-first-
line auto-registration; and `validate --commands` routing to `check-commands.sh`
(registry/dispatch/help/manual four-surface agreement) with `--docs` as the flag-
drift check. Inlined a copy-paste registry before/after edit and the house
helper vocabulary + flag/TTY/Ctrl-C(130) contract (confirmed present in
`work.py`), so a builder needs nothing outside this file.
