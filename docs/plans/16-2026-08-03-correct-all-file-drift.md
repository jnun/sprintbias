# Plan 16: Correct all file drift

**Created**: 2026-08-03
**Status:** DRAFT

> A plan is a **relational index, not a container.** Member tasks stay in their
> lifecycle folders. Plan `**Status:**` is **DRAFT | READY | STARTED** only —
> never a folder name, never a stored DONE. Author with `chat plan`, optionally
> critique with `./sprint.sh plan think <id>`, then commit with `plan start`.
> STARTED is a **one-way switch** set by `plan start`; it does not change while
> members move through `next/doing/review/done`. When every member is in
> `docs/tasks/done/`, `./sprint.sh plan done <id>` deletes this file. Progress
> of work is where members live, not this Status field.

## Goal

Leave no silent drift between authoritative surfaces and what open task files,
docs, and shipped paths claim. Plan membership is owned by `docs/plans/N-*.md`
member lists; each open task’s **Plan** field is the reverse index and must match
(primary = lowest plan id when multi-plan). Brand and framework paths resolve to
SprintBias / `docs/sprintbias/` (and the `src/docs/sprintbias/` mirror via
`./ship.sh`), not retired `sprintmd` / `sprint.md` forms except documented
install back-compat. Integrity is proven with current commands:
`./sprint.sh validate` (reports Plan reverse-index drift; `--fix` rewrites
mismatched **Plan** fields and title-line IDs), `./sprint.sh validate --docs` /
`--commands` for help/flag and command-catalog drift, and
`bash docs/tests/test-no-stale-refs.sh` for rename leftovers on live surfaces.
When this plan is done, real integrity failures are not buried under drift noise.

## Why

Drift is cheap to create (hand-edit a plan member list, miss a rebrand form) and
expensive when `validate` noise or a stale path steers an agent or installer
wrong. One pass that reconciles reverse indexes and residual names keeps the
board and the product surface trustworthy without inventing new lifecycle stages.

## Member tasks

<!-- The tasks in this plan, by ID only — one "- #ID — short title" line each
     (checkboxes optional; [x] means the task is in docs/tasks/done/). These are
     references, not paths: resolve each ID against docs/tasks/*/ for location.
     Moving a member needs no edit here unless syncing checkboxes. -->

- [ ] #337 — Audit and correct all Plan reverse-index drift
- [ ] #336 — Audit residual sprint.md / sprintmd naming → sprintbias
