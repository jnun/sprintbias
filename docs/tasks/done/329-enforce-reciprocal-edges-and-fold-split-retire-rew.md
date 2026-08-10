# Task 329: Enforce reciprocal edges and fold-split-retire rewrite protocol

**Feature**: none
**Created**: 2026-08-01
**Docs**: docs/plans/15-dependency-integrity-and-work-completion-path.md
**Plan**: 15
**Depends on**: 327, 328
**Dependents**: 332
**Parent**: none
**Tests**: none
**Refined**: 1
**Reworked**: 0

## Problem

When a task is split, folded into another, or retired, one side of the edge
often stays stale. Dependents keep `Depends on: 294` after 294 is gone or
renumbered. chat-sprint only *finds* one-way edges — rewrite is not the default
path. Under stress the graph should heal, not accumulate orphans.

## Success criteria

- [x] Positive protocol in AI guidance + help: on fold / split / retire, call
      the rewrite helper so **Depends on** and **Dependents** stay reciprocal
- [x] `split` (and chat paths that mint children) write both ends of new edges
      and update the parent’s **Dependents**
- [x] chat-sprint / validate: one-way and dangling edges remain findings; auto-
      fix on touch via helper when the other file is open and the edge is
      clearly one-sided metadata
- [x] Fold A→B: every open task that depended on A depends on B; A’s
      **Dependents** move onto B
- [x] Retire without fold: never silent wrong-green — surface broken edge or
      treat as complete only under the #330 policy

## Notes

- Antifragile: mutation always goes through the helper; agents do not “remember”
  edges.
- Do not drop **Depends on** to paper over a real prerequisite (DEPENDENT ON
  HOLD rules stay).
- Missing-id *default* policy is #330; this task enforces rewrite + surface.

## References

docs/sprintmd/ai/task-creation.md
docs/sprintmd/scripts/split.sh
docs/sprintmd/scripts/chat-sprint.sh
docs/sprintmd/scripts/chat.sh
docs/sprintmd/lib.sh
docs/plans/15-dependency-integrity-and-work-completion-path.md

## Questions

**Status: READY**

## Completed

Wired the #328 dependency-graph helpers into every mutation call site and stated
the positive rewrite protocol in AI guidance + help. Mutation now routes through
the lib helpers (`sprintmd_ensure_reciprocal`, `sprintmd_rewrite_dep_id`) so both
ends of every edge move together — agents no longer "remember" edges.

- **split.sh** — exec mode now heals the graph deterministically before deleting
  the parent: it snapshots the new children once (before any write, so a
  reciprocity write bumping a prereq's mtime can't make a second `-newer` scan
  readopt it), makes each child's declared **Depends on** reciprocal on the other
  end, then folds the parent into its first (lowest-id) child
  (`sprintmd_rewrite_dep_id`) and makes the moved dependents reciprocal on that
  child. Emit mode gets the same protocol as explicit helper instructions.
- **chat.sh** — SPLIT mode gained a "keep edges reciprocal" step: children get
  both ends via `sprintmd_ensure_reciprocal`, then the parent is folded into its
  first child before it is retired, so nothing is left pointing at a deleted id.
- **chat-sprint.sh** — one-way and dangling-edge findings remain, and their fix
  text (and the conversational act-list) now route the repair through the
  helpers instead of a one-sided hand-edit.
- **ai/task-creation.md** — new "Keep the dependency graph reciprocal (fold /
  split / retire)" section: mint / fold A→B / split / retire-without-fold each
  stated as the positive path through the helper, including that a missing prereq
  is classified (`sprintmd_classify_dep`), never assumed complete (#330 policy).
- **help/split.md**, **help/chat.md** — note that edges are healed automatically
  (children made reciprocal; parent folded into its first child).

Verified the exec-mode heal end-to-end on a scratch board: after splitting a
parent (400) with an external dependent (500) into children 401/402/403, the
external dependent was folded 400→401, the shared prereq (300) listed 401 back,
and every child-to-child edge came out two-way.

Scope note: `validate-tasks.sh` was left as-is. Its dependency check is
token-integrity only and deliberately treats a numeric id that resolves to no
file as archived/OK; reciprocity/dangling findings live in `chat-sprint` (the
walk with an agent present to run the auto-fix helper). Wiring dependency
integrity into `validate` belongs to #333 (which already touches `validate` for
**Tests** integrity), not here.

### Files changed
docs/sprintmd/scripts/split.sh
docs/sprintmd/scripts/chat.sh
docs/sprintmd/scripts/chat-sprint.sh
docs/sprintmd/ai/task-creation.md
docs/sprintmd/help/split.md
docs/sprintmd/help/chat.md
docs/tasks/doing/329-enforce-reciprocal-edges-and-fold-split-retire-rew.md
