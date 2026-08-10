Integrity checks for task files (IDs + dependency references).

Usage:
  ./sprint.sh validate              # integrity check all tasks, report issues
  ./sprint.sh validate --fix        # auto-fix safe issues (title ID + Plan reverse index)
  ./sprint.sh validate --fix --dry-run  # show what --fix would change
  ./sprint.sh validate --docs       # check help/*.md for flag drift vs scripts
  ./sprint.sh validate --commands   # check every command is fully surfaced

Default path (no flags) checks what the runtime actually needs — not
template-stamped presence:

  - numeric filename ID
  - title ID matches filename (`# Task N:` == `N-*.md`)
  - no duplicate task IDs across any stage under docs/tasks/*/
  - **Depends on** / **Dependents** tokens are well-formed (numeric IDs or
    none/n/a/-; bare IDs with no file are treated as archived/gone)
  - **Plan** reverse-index matches plan-file membership (plan file is authority;
    primary = lowest plan id when multi-plan; `done/` skipped)
  - **Tests** paths are close-path-sound (report only): every non-`none` path
    exists, lives under `docs/tests/`, and is a runnable script — a typo,
    missing, out-of-tree, or non-executable path is named with its task id

**Dependents** is the reverse of **Depends on**: if A depends on B, then B
lists A under **Dependents**. It is graph metadata, not the `blocked/` folder.
Legacy files may spell it **Blocks**; validate still reads that alias.

**Tests** (suite paths for `promote`) is a close-path field, not a dependency
edge — see `help promote` and `docs/guides/running-tests.md`. This is the
close-side mirror of the two-gate path: `Depends on` gates `work`, `Tests` gates
`promote`. validate report-only-checks the **Tests** paths so a broken one is
loud here (named with its task id) instead of a silent never-promote — it never
flips validate's exit code.

Template fields (**Feature**, ## Problem, ## Success criteria) are not
re-checked — create-task.sh stamps them from .TEMPLATE-task.md. Dependency
cycle detection is out of scope for v1.

--fix rewrites two safe classes only: a mismatched or missing `# Task N:`
title line (to match the filename ID), and a drifted **Plan** field (to the
primary plan that lists the task, or `none`). It does not invent Depends on /
Dependents values or sections.

--docs compares the flags each command's script parses against the flags
its help/*.md documents, and reports either direction of drift. Run it after
touching any command's flags so the docs never fall out of sync. Exit 1 if
drift is found, 0 if clean.

--commands checks that every user-facing command is present across all four
catalog surfaces: the registry (docs/sprintbias/help/_registry, the source of
truth), the sprint.sh dispatch table, its help/<cmd>.md page, and the
DOCUMENTATION.md command list. It fails if a command is registered but not
dispatched (or vice versa), missing a help page, or absent from the manual —
so a new command can never be silently undiscoverable. The ./sprint.sh help
index is generated from the registry, so it never needs hand-syncing. Exit 1
on drift, 0 if clean.
