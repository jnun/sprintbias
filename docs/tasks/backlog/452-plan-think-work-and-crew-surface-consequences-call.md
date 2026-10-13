# Task 452: Plan think, work and crew surface Consequences: calls that change words, data keys or what people can do

**Feature**: none
**Created**: 2026-10-12
**Docs**: none
**Plan**: 34
**From plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-consequences.sh
**Refined**: 0
**Reworked**: 0

## Problem

When an agent decides for the person, every call lands as one `- Decided:` line,
and the few that change the product sit among many technical ones. In
heavymetal plan 69, `plan think` named a new term, "Holder", for the person who
has a unit. That call is recorded only in task 1796's Notes, not in the plan's
16-line Decided list, which opens with transaction flushes and sync triggers. A
call that renames a word, a data key or an action the person uses can conflict
with an earlier vocabulary or the norms of the industry, so the product owner
has to see it at a glance and be able to undo it in one command.

## Done when (automated)

- [ ] `sprintbias_assume_rule` (lib.sh) tells the agent to record a call as a
  Consequence when it adds, renames or changes the meaning of a word people read
  (glossary or lexicon, UI copy), a stored or public name (table, column, API
  field or path, permission, sync or config key), or what a person can do (an
  action added, removed or replaced, a role's reach). Proven by
  `bash docs/tests/test-consequences.sh`
- [ ] A Consequence is one plain-language line a product owner reads without
  the code: `- Consequence: <what changes for people>, was <what it replaces or
  none>; decided in #N`. It appears in the plan's `## Consequences` section,
  above `## Decided`, even when the call was made inside a member task. For a
  task outside a plan, it goes under ## Notes before work, or under
  `### Consequences` in ## Completed during work. Proven by
  `bash docs/tests/test-consequences.sh`
- [ ] A Consequence that conflicts with an existing term in the project's
  glossary or invariants doc names that term on its `was` side. Proven by
  `bash docs/tests/test-consequences.sh` (prompt text check)
- [ ] The plan template (`docs/plans/.TEMPLATE-plan.md`) carries an empty
  `## Consequences` section with an sb:hint. `plan think`'s end report,
  `work`'s "Your turn" checklist and the crew lead's close list the
  Consequences first, each with a `./sprint.sh newtask "<the change you
  want>"` line, before the other calls. Proven by
  `bash docs/tests/test-consequences.sh` and `bash docs/tests/test-finish-rule.sh`
- [ ] `plan done` carries `## Consequences` into the history record, above
  Decided. Proven by `bash docs/tests/test-consequences.sh`
- [ ] Help (`plan`, `work`, `crew`), DOCUMENTATION.md and the `work` learning
  demo show the Consequences list; `./sprint.sh validate --commands` passes.

## Signoff (human)

- [ ] Re-run `./sprint.sh plan think` on a copy of heavymetal's plan 69: the plan
  opens with a short `## Consequences` list naming Holder, Checkout's new
  meaning (and that code identifiers keep the old one), `held_since`, Release
  replaced by Return, and the new notifications table, and a product owner can
  read it without opening a task.

## Notes

- Decided: the section is named "Consequences", because the owner chose the
  word on 2026-10-12 and it reads plainly as "what this call changes for you".
- Decided: a Consequence filters the existing calls (each stays a Decided line
  where the call was made) and points at it with `decided in #N`, because a call
  recorded in two places drifts.
- Decided: the trigger is a fixed list (words, stored or public names, what a
  person can do), not the agent's sense of importance, because the owner asked
  for a deterministic protocol and a fixed list is what a shell check can pin.
- The shape, from plan 69:
  - Consequence: "Holder" is the word for the person who has a unit, was
    "operator" in the UI; decided in #1796
  - Consequence: in the UI, "Checkout" means taking a unit, was placing it at a
    job site; code identifiers keep the old meaning; decided in #1796
  - Consequence: the iOS Release button becomes Return, which always asks where
    the unit was left, was Release with no place; decided in #1803
  - Consequence: new API field `held_since`, was none; decided in #1798
- Second example, from the plan 69 crew gate (2026-10-12): three calls a product
  owner should see first were recorded only in the plan's Decided list:
  - Consequence: the equipment sync list format moves to ls3 on server and iOS,
    was ls2; decided in #1798
  - Consequence: synced equipment rows gain `holder_user_id`, `holder_name`,
    `held_since`, was none; decided in #1798
  - Consequence: a disposed unit you hold shows Release, not Return, was Return
    everywhere; decided in #1803

## References

docs/sprintbias/lib.sh (sprintbias_assume_rule)
docs/sprintbias/scripts/plan-think.sh
docs/sprintbias/scripts/work.sh
docs/sprintbias/scripts/crew.sh
docs/sprintbias/scripts/plan-done.sh
docs/plans/.TEMPLATE-plan.md
docs/tests/test-finish-rule.sh

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
