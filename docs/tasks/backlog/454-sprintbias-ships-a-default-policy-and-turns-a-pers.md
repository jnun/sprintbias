# Task 454: SprintBias ships a default Policy and turns a person's corrections into Policy lines

**Feature**: none
**Created**: 2026-10-12
**Docs**: none
**Plan**: 34
**From plan**: none
**Depends on**: 453
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-policy.sh
**Refined**: 0
**Reworked**: 0

## Problem

The practices that make SprintBias's own development work (decide and finish,
one source of truth, shell checks over AI, an investigation ends in tasks)
live in the maintainer's private agent memory, so they help only this repo. A
team adopting SprintBias usually has no instruction file or memory worth
keeping, and its history is the habit it wants to leave. SprintBias should
start every project from its own way of building, and turn each correction the
person gives an agent into a Policy line, so the project learns the way an
agent's memory does, in a file every agent reads.

## Done when (automated)

- [ ] SprintBias ships a default Policy (`docs/sprintbias/ai/policy.md`), at most
  ~12 rules, each one positive line, loaded into every work, gate, plan think,
  crew and chat prompt through `sprintbias_assume_rule` or one shared loader.
  It holds at least:
  - An investigation, audit or decision task is done when it has filed the
    execute-ready task(s) that solve it.
  - Define a fact once; generate or check every other place it shows, with a
    test that fails when they drift.
  - A deterministic check is a script or test, not an AI pass. Independent work
    runs in parallel. A helper step that crashes or times out warns and moves
    on; it never blocks the main flow.
  - Read the working tree for current state; reach for git history only when
    the task asks to compare.
  - blocked/ is for work that cannot start; work waiting on another task is
    dependent and stays where it is.
  - Product copy describes what the product does; sales and pricing copy lives
    outside the code repo.
  - Commit, push and release stay the person's; an agent may stage on request.
  Proven by `bash docs/tests/test-policy.sh`
- [ ] The project map's `## Policy` (#453) adds to and overrides the default: a
  project line that contradicts a default line wins, and the agent applies it
  with no Consequence. Proven by `bash docs/tests/test-policy.sh`
- [ ] A correction becomes Policy: when the person tells an agent, in any chat
  or in a `promote --reject` reason, to do something a different way for good
  ("always", "never", "from now on", or a correction the agent sees will
  recur), the agent offers one Policy line in positive form and writes it to the
  project map on yes. Proven by `bash docs/tests/test-policy.sh` (prompt text)
- [ ] DOCUMENTATION.md has a short Policy section (default, project lines, how
  a correction becomes one), and `docs/sprintbias/ai/policy.md` ships through
  `./ship.sh --dry-run`.

## Signoff (human)

- [ ] In heavymetal, tell a chat session "never name a timestamp checked_out_at,
  use held_since": it offers a Policy line and writes it to the project map;
  a later `plan think` applies it without a Decided line.

## Notes

- Decided: the default Policy is drawn from the maintainer's agent memory for
  this repo (bias for finishing, blocked vs dependent, audit done is tasks,
  command catalog source of truth, speed and stability, git hands-off, repo is
  the tool), keeping only rules true for any software project, because
  SprintBias starts from the position that its way is the best way.
- Decided: SprintBias-only memories (plan terminology, starter folders, talk
  absorbs triage) stay out, because they are about this tool, not about how to
  build software.
- Decided: the default ships as one short file rather than lines seeded into
  every project map, because a framework update must be able to improve it, and
  the map belongs to the project.
- Decided: a correction is offered as Policy, not written silently, because the
  person owns the project's rules.

## References

docs/sprintbias/lib.sh (sprintbias_assume_rule)
docs/sprintbias/ai/conversation.md
docs/sprintbias/scripts/promote.sh (--reject)
docs/tasks/backlog/453-project-map-policy-settled-practices-agents-apply.md

<!-- sb:hint  After work only — audit trail of what was touched. Helps committers,
     later audits, and "what broke?" recovery. List the product files you
     edited to complete the task — one repo-relative path per line. Leave this
     task file out: its folder location and git history already track it. Copy
     the two headings below to column 0
     (UNINDENTED — they are indented here only so a fresh, unworked task is not
     mistaken for a finished one), then list the paths under "Files changed":

       ## Completed

       **Summary**: <one plain sentence: what changed, for someone reading
       the project's history>

       ### Files changed
       docs/sprintbias/scripts/example.sh
       docs/sprintbias/help/example.md

     When the work rests on something only a person can confirm (a device,
     a live account), add under ## Completed; it joins the plan's human test:

       ### Assumptions
       - The scanner sends one line per barcode

     When the work made a source of truth wrong and updating it is out of
     scope (or it is a governing source), add under ## Completed:

       ### Doc follow-ups
       - `docs/GLOSSARY.md` — add "plan"; the code now uses it

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. Do not fill this before work. -->

<!-- sb:hint
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->
