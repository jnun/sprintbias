Create a new task in docs/tasks/backlog/.

Usage:
  ./sprint.sh newtask "Add login endpoint"
  ./sprint.sh newtask "Add login endpoint" user-auth
  ./sprint.sh newtask "Rework the login copy" --from-plan 24

Pass an optional feature name as the second argument to set the task's
**Feature** field to /docs/features/<name>.md.

--from-plan N sets **From plan**: N — the task came out of plan N's work (a
rework decided while reviewing it, a delta, a put-off item, an enhancement).
It stays out of plan N; once plan N is done, `./sprint.sh newplan "…" from:N`
groups every such follow-up into the next plan. chat plan, plan think, and
polish set it for you.

Tasks get an auto-assigned ID and are built from a battle-tested
template. The file is created ready to edit — fill in **Problem** (high-level
what is wrong) and **Success criteria** (what done looks like) yourself, or
run `./sprint.sh chat <id>` to develop them conversationally. Notes and
References are optional hints and paths; how to implement is the developer's
call.

The header stamps **Plan** (which `docs/plans/N-…` this belongs to),
**Depends on** (prerequisite task IDs), **Dependents** (the reverse edge —
task IDs that wait on this one), and **Tests** (suite scripts that prove the
success criteria for `promote`), all defaulting to `none`.

**Dependents** is the reverse of **Depends on**, not the `blocked/` folder.
**Docs** is what you read while building; **Tests** is what `promote` runs to
close (`docs/tests/*.sh` only — not product `newtest` loops).

Legacy aliases (read only): **Blocks** → **Dependents**, **Proven by** → **Tests**.
