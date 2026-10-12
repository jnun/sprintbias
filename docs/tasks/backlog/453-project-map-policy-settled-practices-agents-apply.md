# Task 453: Project map Policy: settled practices agents apply without re-deciding

**Feature**: none
**Created**: 2026-10-12
**Docs**: none
**Plan**: 34
**From plan**: none
**Depends on**: 452
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-policy.sh
**Refined**: 0
**Reworked**: 0

## Problem

Agents re-decide the same build questions on every task and plan: naming,
where a rule lives, how a transaction commits, which word the UI uses. Each
one costs a model's thinking and adds a `- Decided:` line the person has to
read, even when the project settled it long ago. A project should be able to
write its settled practices down once, as strict policy, and have every agent
apply them without deliberating or re-raising them.

## Done when (automated)

- [ ] The project map (`docs/sprintbias/project.md`) has an optional `## Policy`
  section: one line per settled practice, written as the rule to follow
  (`- Database writes commit once, in the route`), with an optional pointer to
  the document that explains it. `profile` drafts it from the project's own
  decision and standards docs when they exist and leaves it empty otherwise.
  Proven by `bash docs/tests/test-policy.sh`
- [ ] `sprintbias_assume_rule` tells every agent to apply `## Policy` as given:
  a choice the policy answers is built that way, with no Decided line, no
  Consequence and no question. A call that would break a policy line is a
  Consequence that names the line it breaks. Proven by
  `bash docs/tests/test-policy.sh`
- [ ] At sign-off, `promote` (single task and plan:N) lists the run's
  Consequences and prints, for each, the one command that turns it into policy
  (`./sprint.sh policy add "<rule>"`, or the documented edit when no command
  exists), so an accepted call stops being re-decided. Proven by
  `bash docs/tests/test-policy.sh`
- [ ] `profile check` counts `## Policy` lines and asks for a prune past ~20, as
  it does for Known edges. Proven by `bash docs/tests/test-policy.sh`
- [ ] Help (`profile`, `promote`), DOCUMENTATION.md and the command matrix
  describe Policy; `./sprint.sh validate --commands` passes.

## Signoff (human)

- [ ] In heavymetal, add two Policy lines plan 69 already settled (Return always
  names a place; UI words change, identifiers keep their names), re-run
  `./sprint.sh plan think` on a copy of a plan that touches them, and see no
  Decided line re-deciding either.

## Notes

- Decided: Policy lives in the project map, beside Known edges, because every
  AI command already loads the map and a separate file costs context and one
  more thing to find. Lines are rules (positive, imperative), not pointers, the
  same exception Known edges makes.
- Decided: the name is "Policy", because it is the plain word the owner used
  ("a strict policy on how we build software") and plan 32 already uses a
  Policy section for the same idea at plan scope.
- Decided: a Consequence the person accepts is the source of new policy, because
  that is the moment a call becomes settled; the path is offered at sign-off,
  never automatic.
- Decided: `policy add` is a new command only if the help-registry review in
  this task finds no existing home (`profile` subcommand is the first choice:
  `./sprint.sh profile policy "<rule>"`), because fewer commands cost less
  context.

## References

docs/sprintbias/lib.sh (sprintbias_assume_rule)
docs/sprintbias/scripts/profile.sh
docs/sprintbias/scripts/promote.sh
docs/sprintbias/help/profile.md
docs/tasks/backlog/452-plan-think-work-and-crew-surface-consequences-call.md

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
