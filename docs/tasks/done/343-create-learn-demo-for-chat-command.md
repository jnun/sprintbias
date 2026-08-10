# Task 343: Create learn demo for chat command

**Feature**: none
**Created**: 2026-08-03
**Docs**: none
**Plan**: 18
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 1
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

<!-- The problem as a short user story — who, what they can't do, why it
     matters. Loose Gherkin (Given/When/Then) is welcome, not required.
     2-5 sentences, plain English. -->

A newcomer who already has a rough plan file can't *see* what `chat plan` does
before running it, so conversational plan improvement — sharpening the Goal,
reordering members into the right sequence, spotting a missing or stray task —
stays invisible and feels risky to try on real work. The learning catalog (plan
18) needs one short, watchable vignette — safe theater — of a person walking
`./sprint.sh chat plan <id>` through an *existing* plan and improving it,
touching nothing in their project. This is a standalone demo
`docs/sprintbias/learning/chat.py` that deliberately dramatizes the
**plan-authoring** mode of `chat`, not the single-task sharpen that S1
(`gate.py`) already tells — so it teaches new ground rather than restaging the
gate story.



## Success criteria

<!-- Observable behaviors that show it's done: "User can [do what]" /
     "App shows [result]". Clear and succinct — anyone can verify. -->

- [x] `docs/sprintbias/learning/chat.py` exists: a self-contained, scripted
      vignette (~40-60s) of a person running `./sprint.sh chat plan <id>` on an
      existing plan and improving it — the conversation sharpens the Goal,
      reorders members into the right sequence, and catches a missing/stray
      task, ending with the tightened plan file. It shows the plan-authoring
      mode only (not a single-task refine), so it does not restage S1
      (`gate.py`).
- [x] The story reflects real `chat plan` behavior (see `chat-plan.sh`): the
      only durable write during the walk is the plan file itself — Goal, ordered
      `- #ID — short title` member lines, optional parallelism/conflict notes,
      and the `**Status:**` flip DRAFT → READY on confirm. It does not rewrite
      task bodies or move task files; the one thing it touches on members is the
      `**Plan**` reverse-index field, refreshed by the shell *after* the session.
      It closes by naming the next steps (optional `plan think`, then
      `plan start`) without running them.
- [x] It is a person-in-a-situation scenario, not a flag tour, and matches the
      shared output vocabulary (`type_out`, `spinner`, `beat`, `moved`,
      `claude`/`you`, `ok`/`note`/`held`) so it reads as the same tool talking.
- [x] It honors the trust contract — writes nothing, no network, Python 3
      stdlib only — and states that promise in its banner.
- [x] It honors the standard flags: `--fast` (no delays), `--no-color`
      (auto-dropped on non-TTY), `-h`/`--help` (prints docstring, exit 0), clean
      Ctrl-C (dim `…demo interrupted.`, exit 130). First docstring line is the
      short situational catalog summary.
- [x] `./sprint.sh learn` lists the demo and `./sprint.sh learn chat` plays it.
      Registration is automatic: `learn.sh` scans `learning/*.py`, maps `learn
      <name>` → `<name>.py`, and takes the first non-empty docstring line as the
      catalog summary — so no launcher edit is needed. The file must be named
      exactly `chat.py`.
- [x] The `chat` row in `docs/sprintbias/help/_registry` gains its 5th field so
      the command is associated with its demo. The row is currently 4 fields
      (`command | group | usage | summary`); append ` | chat` to make it
      `command | group | usage | summary | chat`. (The `chat --demo` intercept
      and the `--help` "see it in real life" pointer are the mechanism owned by
      upstream task #314 — in `review/`, not required for this task. `learn chat`
      plays the demo standalone regardless.)
- [x] The learning sandbox check passes:
      `bash docs/sprintbias/tests/learn-sandbox.sh` exits 0 — it plays each demo
      from a throwaway dir and verifies the project file inventory and
      `git status` are unchanged (proves the demo wrote nothing, moved nothing).

## Notes

<!-- Every relevant detail that helps build the solution fast and knowingly:
     decisions, constraints, edge cases, gotchas. Leave empty if none. -->

- Scenario is fixed: `chat plan <id>` improving an *existing* plan. `chat` is the
  widest command in the tool (single task · folder sweep · plan authoring · bugs
  · sprint health); the demo shows plan authoring only. Do not try to tour every
  mode — one situation, told well.
- Stay clear of two neighbors so the demo teaches new ground: S1 (`gate.py`)
  already tells the single-task sharpen, and S3 (`feature-plan.py`) already shows
  feature → tasks → `plan start` (a *creation* flow). This demo is conversational
  *improvement* of a plan that already exists — a different beat.
- Fastest path: copy the newest demo in `learning/`, keep its helper block (each
  demo carries its own copy of the vocabulary helpers — there is no shared
  `_demokit.py` in v1), and rewrite the story. `session.py` (S0) is the reference
  for names, colors, and rhythm. Concretely, that scaffold gives you: the flag
  parse at the top (`FAST = "--fast" in sys.argv`; `NO_COLOR = "--no-color" in
  sys.argv or not sys.stdout.isatty()`; `-h/--help` prints `__doc__` and exits
  0); the ANSI palette; the vocabulary helpers (`type_out`, `spinner`, `beat`,
  `act`, `rule`, `prompt_and_type`, `moved`, `ok`/`note`/`nextstep`,
  `claude`/`you`); a `banner()` that states the touches-nothing promise; and a
  `main()` that catches `KeyboardInterrupt` to print a dim `…demo interrupted.`
  and exit 130. Keep these names verbatim so the demo reads as the same tool.
- The story spine should mirror the real `chat plan` walk (from `chat-plan.sh`,
  "HOW TO WALK"): SIZE UP the existing plan ("this is a partial draft") →
  sharpen the GOAL → propose/reorder MEMBERS (existing backlog IDs, prerequisites
  first) → walk ORDER + CONFLICTS, flagging one parallelism/independence note →
  flip `**Status:**` DRAFT → READY on the user's confirm → STOP, reminding
  optional `plan think <id>` then `plan start <id>`. Use invented tasks/plan for
  the theater — never a real plan id.
- What the on-screen plan file should look like (so it matches reality): heading
  `# Plan <id>: <name>`, `**Created**`, `**Status:** DRAFT`→`READY`, `## Goal`
  (2–5 sentences), optional `## Why`, and `## Member tasks` as ordered
  `- #ID — short title` lines (order = execution order). A one-line parallelism
  annotation (e.g. `231 ∥ 234, disjoint files; 237 after 234`) is a nice, real
  touch.
- Real behavior to stay faithful to: bare `chat plan` picks a plan; `chat plan
  <id>` targets one (a *plan* id, never a task id); the scaffold is created first
  with `newplan`. The walk reads backlog/ read-only and its only durable write is
  the plan file; task bodies are never rewritten (the shell refreshes each
  member's `**Plan**` reverse-index field after the session). The demo itself, of
  course, writes nothing at all — it only depicts this.
- Atomic and independent: build against what `chat plan` does *today*, with no
  dependency on other plan-18 tasks. The demo file plus its registry mapping are
  complete on their own; `./sprint.sh learn chat` plays it.

## References

<!-- Direct files that help build this — existing code to reuse (don't
     reinvent), specs, examples. One path per line. Leave empty if none. -->

docs/sprintbias/learning/README.md        (house guide: vocabulary, trust contract, flags)
docs/sprintbias/learning/session.py        (S0 — copy this scaffold; reference for names/colors/rhythm)
docs/sprintbias/learning/gate.py           (S1 — the single-task sharpen this demo must NOT restage)
docs/sprintbias/learning/feature-plan.py   (S3 — the feature→tasks→plan start flow to stay clear of)
docs/sprintbias/scripts/chat-plan.sh       (the real command: HOW TO WALK, what it writes, boundaries)
docs/sprintbias/scripts/learn.sh           (auto-registration: learn <name> → <name>.py, docstring summary)
docs/sprintbias/tests/learn-sandbox.sh     (the sandbox check the demo must pass)
docs/sprintbias/help/chat.md               (chat's full surface; plan-mode paragraph)
docs/sprintbias/help/_registry             (add the 5th field on the `chat` row)
docs/plans/18-per-command-learn-demos.md   (parent plan; per-command coverage decision, build recipe)

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

**Resolution (2026-08-10):** Problem and Success criteria are now defined — this
is a standalone `learning/chat.py` dramatizing the `chat plan` mode (improving an
*existing* plan). The "don't build a generic chat demo" argument below is
**superseded** by plan 18's owner decision (full per-command coverage); the "show
a mode S1 doesn't" guidance is **honored** by choosing plan authoring over the
single-task sharpen. Kept as history.

**Stub status:** empty template. Sharper draft proposed at end.

**Perspective check.**
- *Chief Platform Architect:* `chat` is the conversational engine with the widest surface in the whole tool (id / folder sweep / plan authoring / bugs). A single demo can't represent all of it, and safe theater of a dialogue is easy to fake but easy to misrepresent. Whatever ships must not imply chat does more (or less) than it does.
- *Chief Experience Officer:* A chat *sharpening a vague task* is the signature "aha" of SprintBias — but S1 (`gate.py`) already tells exactly that: the gate holds a half-baked task, then a chat sharpens it. Re-telling it is choice overload, not clarity.

**Tension and resolution.** Both flag duplication with S1. Resolution: **do not build a generic `chat` demo.** If chat earns a demo at all, it must show a *mode S1 doesn't* — a folder sweep (`chat next`) or plan authoring (`chat plan`) — so it teaches new ground instead of restaging the gate story.

**Sharper rewrite (only if kept):** *Problem:* users don't realize one `chat` sweeps a whole folder, not just one task. *Success:* a demo shows `chat next` walking several tasks conversationally, distinct from the S1 single-task sharpen.

## Refine (round 1)

**Sharpened:** Filled Problem and Success from the empty stub and locked the
scenario: a standalone `learning/chat.py` dramatizing `chat plan <id>` improving
an *existing* plan (owner chose this over the `chat next` folder-sweep draft).
Chose plan authoring specifically to teach new ground — clear of S1 (`gate.py`,
single-task sharpen) and S3 (`feature-plan.py`, feature→tasks→`plan start`
creation). Then made it fully self-contained against the live codebase: verified
`chat-plan.sh` and folded in its real walk spine and write behavior (durable
write is the plan file only; the shell refreshes members' `**Plan**` field
after — task bodies untouched); named the exact `_registry` 5th-field edit and
scoped out the `chat --demo` intercept as #314's mechanism (in review, not a
blocker — `learn chat` plays standalone); pinned the `learn.sh` auto-registration
(`learn chat` → `chat.py`, docstring summary), the reference scaffold atoms from
`session.py`, the on-screen plan-file anatomy, and the exact sandbox command.
