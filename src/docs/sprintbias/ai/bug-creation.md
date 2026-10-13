# AI Bug Documentation Protocol

## Core Principle

**Describe what's broken in plain English.** Focus on observable behavior — what happens vs. what should happen.

**Plain text, no decoration.** Skip emoji, color, badges, and drawn ASCII art — they add no data and cost the next reader context. A tool's own output line is data; keep it in backticks. Full rule: `docs/sprintbias/guides/doc-style.md`.

Bugs are a **triage inbox**, not the work system. Real work lives as tasks after convert.

## Severity Levels

| Level | Meaning |
|---|---|
| CRITICAL | System down, data loss, security issue |
| HIGH | Major feature broken, blocks users |
| MEDIUM | Feature impaired, workaround exists |
| LOW | Minor issue, cosmetic |

## Bug File Naming

`ID-description.md` (e.g., `3-login-timeout.md`)

## Writing a Good Bug Report

### Problem Section

Describe what is happening and what should happen instead. Be specific about the unexpected behavior.

### Steps to Reproduce

Numbered steps someone can follow to see the bug. Include:
- Starting state (logged in? specific page?)
- Exact actions taken
- What you observe at each step

### Success Criteria

Write observable behaviors that confirm the fix works:
- "User can [do what]"
- "System shows [result]"
- "[Action] no longer causes [problem]"

### Draft From the Code

A filer writes what they saw, often one line. Fill the rest from the code
before asking: the starting state, the steps, the severity, and the success
criteria. Then confirm with the filer one item at a time.

### Standards

A report that a screen, button, flow, word or API behaves wrongly or
inconsistently is measured against a written rule. Look in the project's
standards docs (the project map's sources; commonly `docs/guides/` and
`docs/designs/`) and name it:

- A rule exists: a success criterion says the work follows it
  ("The dashboard action cards follow `docs/guides/design-system.md` → Dashboard action cards").
- No rule exists, or it is unclear: the first success criterion is that the
  rule is written or improved, from best practice and the closest existing
  example that does the same job. The fix then follows it.

The rule is what turns one report into a repeatable decision: the next screen
follows it, and the next report improves it.

## After Documenting

When the report is real work, **convert** it — do not keep a parallel bug file:

1. Prefer `./sprint.sh chat bugs`. It sorts every report: already fixed →
   **deleted**; a clear defect → gleaned into a fix task in `backlog/`
   (Problem, steps, Done when naming the **Standard:**, Decided lines where the
   report is thin), then **deleted**; unclear or a bigger decision → the same
   task carrying one question under `### Questions for the developer`, which
   waits in the backlog for an answer (`./sprint.sh chat <id>`).
2. Or create the task yourself: `./sprint.sh newtask "Fix: [description]"` and
   delete the bug when the hand-off is done. Open `docs/bugs/` is for
   unhandled reports only.

If the fix is already obvious, skip the inbox and file a task with `newtask`
directly.
