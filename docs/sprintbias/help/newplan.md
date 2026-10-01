Create a plan in docs/plans/.

Usage:
  ./sprint.sh newplan "Method accuracy audit"
  ./sprint.sh newplan "Method accuracy audit" 213 214 215
  ./sprint.sh newplan "Method accuracy audit" 213-220
  ./sprint.sh newplan "Finish split of 335" parent:335
  ./sprint.sh newplan "Login flow — follow-ups" from:24
  ./sprint.sh newplan "Clear the backlog" backlog

Burn through a finished plan's follow-ups in three commands:

  ./sprint.sh newplan "Login flow — follow-ups" from:24   # every task filed from plan 24's work
  ./sprint.sh plan start <id>                             # gate them → next/
  ./sprint.sh work                                        # execute

While you work plan 24 (chat plan decisions, plan think, polish), anything
that needs reworking after the plan is filed with `newtask … --from-plan 24`
and kept out of plan 24. `plan done 24` prints the newplan line above when any
follow-ups are waiting.

A plan is a **relational index, not a container.** It is one file —
`docs/plans/N-name.md` — that names a clump of related tasks and lists their
IDs. The tasks are never moved into it: each stays in its own lifecycle folder
(`backlog → next → doing → …`) and its progress is tracked there. A plan is
never counted or moved as a task; `docs/plans/` is a sibling of `docs/tasks/`,
not a lifecycle stage. A plan created with members bound (ids, `parent:N`,
`from:N`, `backlog`) starts `**Status:** READY` — naming the members is the approval — so
`plan start` runs from an agent session too. A plan created empty starts
`**Status:** DRAFT`; flip it to `READY` once it is authored (`chat plan`).
`plan start` then latches `**Status:** STARTED` (a one-way switch) as it commits
members to `next/`, and once every member reaches `done/`, `./sprint.sh plan
done <id>` retires the plan by deleting the file — there is no stored DONE.

The plan gets an auto-assigned ID from a dedicated `sprint_PLAN_ID` counter
in `docs/sprintbias/DOC_STATE.md` (bumped on creation, exactly like task and bug
IDs). Pass members as extra arguments:

- plain numbers and `N-M` ranges
- **`parent:N`** — bind open-stage task N (if still open) plus every open-stage
  task stamped `**Parent**: N` exactly (not a substring). Fail loud if that is
  the only token and nothing matches. Never pulls `review/` or `done/`.
- **`from:N`** — every open task stamped `**From plan**: N` (filed from plan
  N's work) and not already in another plan, lowest id first. Fail loud if that
  is the only token and nothing matches.
- **`backlog`** — every `backlog/` task not yet in a plan (`**Plan**: none`),
  lowest id first. Tasks already in a plan stay where they are. Fail loud if
  that is the only token and nothing is unplanned. Also works at the prompt.

Omit tokens to pick interactively from `backlog/`.

**Fast lane:** when members are pre-bound (ids and/or `parent:N`), post-create
points at `plan start` → `work` — no full `chat plan` ceremony required.
Optional authoring (`chat plan`) and critique (`plan think`) still work.

```
./sprint.sh plan start <id>              # gate members → next/ (default spine)
./sprint.sh plan start <id> --commit-only  # pure move, no AI gate
./sprint.sh work
```

Member IDs are references only. Binding stamps each member's **Plan** reverse
index. Single-task promote:
`bash docs/sprintbias/scripts/promote-to-sprint.sh <task-file>`. The plan file
itself never moves.

`./sprint.sh status` rolls up each plan by
resolving its member IDs to their current folders — a live view of the clump's
progress without ever treating the plan file as a task.
