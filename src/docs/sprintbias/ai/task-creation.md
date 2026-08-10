# AI Task Creation Protocol

## Core Principle

**A task is a super-helpful user story, not a build script.** Write in plain
English what is wrong and what "done" looks like. The developer — human or AI —
chooses how to implement. Micromanaging steps slows work and closes options.

**Plain text, no decoration.** Skip emoji, color, badges, and drawn ASCII art —
they add no data and cost the next reader context. A tool's own output line is
data; keep it in backticks. Full rule: `docs/sprintbias/guides/doc-style.md`.

Work flows **Feature → Task → Audit**: a task usually builds toward a feature,
and it will later be audited against the problem and success criteria you write
here. Write both so a future auditor can judge "done" without asking you.

## The ultimate task file

Every workable task answers two questions in the body. Everything else is
optional fuel or post-work audit.

| Section | Required? | Job |
|---|---|---|
| **## Problem** | Yes | Clear, simple language. Concisely define the problem at a high level. |
| **## Success criteria** | Yes | What done looks like. When these are met, the task is done. |
| **## Notes** | No | Helpful hints that assist the developer in figuring out how to work the task. |
| **## References** | No | Direct paths to docs or files known to be related. |
| **### Files changed** (under **## Completed**) | After work only | What was touched — for committers, later audits, and "what broke?" |

**How to implement is the developer's decision.** Do not turn the task into a
detailed outline of exact steps unless the work itself is a library or detailed
technical fix — then put the new technical *needs* as outcomes under Success
criteria, not as a prescribed implementation path.

**Where content belongs**

| Content | Location |
|---|---|
| Problem and outcomes | This task file (`## Problem`, `## Success criteria`) |
| Hints for the implementer | `## Notes` (optional) |
| Related paths | `## References` (optional) |
| How to implement (guides, patterns, specs) | `docs/guides/`, `docs/examples/`, `docs/features/` — link, don't inline a build plan |
| After-work audit trail | `## Completed` → `### Files changed` |

The durable brief is **Problem + Success criteria**. Notes and References assist
the developer. Gate's `## Questions` holds the workability stamp, code findings,
remaining outcomes, and open questions still waiting on a decision. Write the
work itself in Problem and Success criteria.

### Questions become instructions

1. **Ask** the question under `### Questions for the developer` (with a
   suggestion when it is a real decision).
2. **Get** the answer from the user or agent.
3. **Convert** the answer into clear instruction or guidance (positive, direct,
   concise).
4. **Update** the task body — `## Success criteria` when it defines done;
   otherwise `## Notes` as guidance the implementer follows.
5. **Delete** the original question — it has been answered.

When every question has been answered this way, that subsection reads
`None — task is fully defined.` Open questions keep the task **BLOCKED** and out
of `next/` until the loop finishes.

**Do not park micro-choices as open questions.** If you can write a useful
`(Suggestion: …)`, apply it as body instruction and omit the question. Only
product forks that change success criteria need a human. Bulk-accept path:
`./sprint.sh settle` (folds every remaining Suggestion, demotes anything still
open).

## Instruct positively

**State the desired path as the rule.** Success criteria say what should be true
when the work is done — not a checklist of things to avoid.

- Prefer: "User can log in with email and password"
- Prefer: "Always edit `docs/`, then commit"
- A lone, concrete "never" is fine when it anchors a genuine invariant
  ("Never create task files by hand — run `./sprint.sh newtask`") where
  the wrong action is costly.
- Do **not** write prohibition-shaped rule *lists* ("Don't X. Don't Y. Avoid
  Z."). Those hand the implementer (and any agent) a map of forbidden
  behavior and no map of the work — under ambiguity they fall into exactly
  what was described.

Check before saving: success criteria state the desired path. If a criterion
is phrased only as "don't do X", rewrite it as the positive outcome.

## Moving tasks (lifecycle)

Folder location **is** status. When you move a task between `backlog/`,
`next/`, `doing/`, `blocked/`, `review/`, and `done/`, always run:

```bash
git mv SRC DEST || mv SRC DEST
```

`git mv` first (preserves history when tracked). When it fails — usual for
new tasks not yet committed — finish that same move with plain `mv`, then
continue. Leave commits to the developer unless they asked you to commit.
Full table: `DOCUMENTATION.md` → Moving Tasks.

## Keep the dependency graph reciprocal (fold / split / retire)

**Depends on** and **Dependents** are the two ends of one edge — they stay in
sync. When you mint, fold, split, or retire a task, route the edge change
through the shared lib helpers so both ends move together. Never hand-edit one
side and trust yourself to remember the other; the helper is the single writer
so the graph heals under stress instead of accumulating orphans.

Load them once, then call the one that fits (from the repo root):

```bash
source docs/sprintbias/lib.sh
```

- **Mint a child that depends on N** — after you write the child's
  `**Depends on**: N`, make the reverse edge:
  `sprintbias_ensure_reciprocal N <child-id>` (adds the child to N's
  **Dependents**). Do this for every id on the child's **Depends on** line.
- **Fold A into B** — `sprintbias_rewrite_dep_id A B`. Every task that depended
  on A now depends on B, A's **Dependents** move onto B, and A is stamped with
  a fold note. Then, for each task that depended on A,
  `sprintbias_ensure_reciprocal B <that-id>` so B lists them back. Retire A last.
- **Split** — children get reciprocal edges among themselves (the rule above);
  then fold the parent into its first child (`sprintbias_rewrite_dep_id <parent>
  <first-child>`) before retiring the parent, so nothing is left pointing at the
  deleted id. `split` and `chat`'s SPLIT mode already do this.
- **Retire without a fold** — do not silently drop a real prerequisite to make a
  dependent look runnable (the DEPENDENT ON HOLD rules stand). Either fold the
  edge onto its replacement, or leave the broken edge to be surfaced: `chat`
  (the sprint walk) and `validate` report a dangling id, and
  `sprintbias_classify_dep <id>` classifies a missing prereq (broken / folded /
  archived) rather than assuming it complete. A retired task counts as complete
  only under the missing-id policy, never by accident.

## The Q&A Process

Before creating any task, work through these questions with the user:

### 1. Understand the Problem

Ask:
- "What's happening now?"
- "What should happen instead?"
- "When does this occur? (Always? Sometimes? Under specific conditions?)"

Wait for answers. Build understanding together. The answers become **## Problem**.

### 2. Clarify the Scope

Ask:
- "Is this about [specific thing] or something broader?"
- "Are there related issues we should address together or separately?"
- "What's the boundary of this task?"

### 3. Map the Dependencies and Reuse

Dependencies are sequencing, not a blocked state. A task that needs another
task finished first is **dependent** (on hold until that prerequisite lands) —
it is not blocked. **Blocked** / **BLOCKED** means a decision or clarification
is needed about *this* task.

Ask:
- "Does anything need to be done first?" (→ **Depends on** — prerequisites)
- "What other work waits on this one?" (→ **Dependents** — the reverse edge)
- "Which plan does this belong to?" (→ **Plan** — plan membership)
- "What existing files or docs help?" (→ **References** — optional pointers)
- "Is there a guide or feature spec this follows?" (→ **Docs** / **Feature**)
- "What suite script proves the success criteria?" (→ **Tests** — or leave `none`)

**Depends on** and **Dependents** are the two ends of the same edge: if A lists
B under **Depends on**, then B lists A under **Dependents**. Always write
**Dependents** (legacy files may still say **Blocks**; readers accept that alias).
Neither field means the `blocked/` folder — that is a decision on *this* task.

**Docs** vs **Tests**: **Docs** is what you read while building; **Tests** is
what `./sprint.sh promote` runs to close `review/ → done/`. Set **Tests** only
to real `docs/tests/*.sh` paths that prove the success criteria (comma-separate
several — all must pass). Leave `none` when a human must sign off. Do not put
product test loops (`newtest` markdown) in **Tests**. Do not invent a path that
does not exist yet.

### 4. Define Success Behaviorally

Ask:
- "When this is done, what will a user be able to do?"
- "How would you test that it works?"
- "What would you check to verify it's complete?"

The answers become **## Success criteria**. For a library or detailed technical
fix, the criteria may name new technical *needs* as checkable outcomes — still
not a line-by-line build plan.

### 5. Confirm Understanding

Before writing anything, summarize back:
- "So the problem is [X], and we'll know it's fixed when [Y]. Is that right?"

Proceed after confirmation. Optional Notes and References come after that core
is solid — only if they help the developer without prescribing the build.

## Task Structure

### Header Fields

The header carries the task's place in the larger body of work. Set what applies; leave the rest as `none`.

- **Feature** — the feature this builds toward, e.g. `/docs/features/user-auth.md`. `none` if no feature applies.
- **Created** — date the task was created (`YYYY-MM-DD`). Set automatically by `./sprint.sh newtask`; used for time audits.
- **Docs** — a guide the implementer should follow, e.g. `docs/guides/script-template-sync.md`. `none` if there is none.
- **Plan** — the plan this task belongs to, e.g. `15` for `docs/plans/15-…`. Reverse index of plan membership only. `none` if not in a plan. The plan *file* remains the membership authority.
- **Depends on** — prerequisite task IDs that must finish before this one can start. The runner holds a READY dependent task until those land in review/ or done/ — sequencing, not a block.
- **Dependents** — reverse edge: task IDs that wait on this one. Graph metadata only — does not put anyone in `blocked/`. Write **Dependents**; readers still accept legacy **Blocks**.
- **Parent** — a task that groups this one with related work. Task-to-task only; not **Plan**.
- **Tests** — suite scripts that prove the success criteria so `./sprint.sh promote` may move `review/ → done/` without a human. Paths under `docs/tests/` (typically `test-*.sh`); comma-separate several — **all** must pass. `none` = human sign-off in `review/`. Set only when a real script already proves the criteria; a hopeful path that is missing keeps the task in `review/`. Write **Tests**; readers still accept legacy **Proven by**.

### Problem Section

Clear, simple language. Concisely define the problem at a high level — who is
affected, what they can't do today, and why it matters. Loose Gherkin
(Given/When/Then) is welcome but not required. Prefer 2–5 short sentences, as
you'd explain it to a colleague unfamiliar with this area. Do not put the
implementation plan here.

### Success Criteria Section

What done looks like. When these requirements are met, the task is done. Write
observable behaviors that anyone can verify. This is the yardstick audits and
`promote` measure against. Phrase each criterion as the desired path (see
**Instruct positively** above).

Patterns that work:
- "User can [do what]"
- "App shows [result]"
- "[Action] completes within [time]"
- For technical/library tasks: "[API/module] exposes [capability] and [test] covers it"

Example:
```markdown
## Success criteria
- [ ] User can log in with email and password
- [ ] Error message appears when password is wrong
- [ ] Session persists across browser refresh
```

### Notes Section

Optional helpful hints that assist the developer in figuring out how to work the
task: decisions already made, constraints, edge cases, gotchas, pointers to
patterns. Leave empty if there is nothing useful to add. Notes are fuel for the
developer's choice — not a required step list, not a substitute for Problem or
Success criteria.

### References Section

Direct paths to documentation or files known to be related — existing code to
reuse rather than reinvent, specs, examples. One path per line. Leave empty if
none. This is also what an audit checks for design fit, so name files you already
know are involved.

Example:
```markdown
## References
docs/sprintbias/lib.sh — sed helpers, reuse for placeholder substitution
docs/sprintbias/scripts/create-task.sh — existing pattern to follow
docs/features/task-automation.md — spec this serves
```

### Completed / Files changed (after work only)

When the task is finished, leave an audit trail of what it touched. Reviews and
the change manifest read this. Copy the headings to column 0 (unindented), then
list one repo-relative path per line under `### Files changed`. Do **not** fill
this before work — it is an after-work record for committers, later audits, and
quick recovery when something breaks.

```markdown
## Completed

### Files changed
docs/sprintbias/scripts/example.sh
docs/tasks/.TEMPLATE-task.md
```

Keep the wording exact — `## Completed` and `### Files changed` — the tasks
runner and lib.sh key off them verbatim.

## Verify Before Saving

1. **Problem** is clear, simple, and high-level — someone unfamiliar can understand it
2. **Success criteria** state what done looks like; an auditor could check each one
3. Success criteria state the desired path — no prohibition-shaped rule list
4. **Notes** (if any) are optional hints, not a mandatory build plan
5. **References** (if any) are real paths that help; deep HOW lives in guides/examples/features
6. Header fields set what applies (Feature, Docs, Plan, Depends on, Dependents, Tests)
7. **Files changed** is absent until after work
8. The brief stands alone: a later reader does not need gate Remaining work or chat history to know the problem and done
