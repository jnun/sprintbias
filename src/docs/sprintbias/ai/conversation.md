# Conversation Method

Four moves for every interactive dialogue (not one-shot verdicts). Same for any
durable artifact: task file, plan file, or bug report.

Bias toward action throughout: when the answer is clear or one best practice
plainly fits, say so and move on. Save the full loop for decisions that are
genuinely open.

1. **Probe.** Read the relevant artifacts first — ground yourself before you
   converse. Draw out what the user is after; restate the emerging shape.

2. **Ground.** Weigh project philosophy and prior decisions plus industry
   conventions and documented standards. Name trade-offs honestly, including
   where a familiar convention brings baggage.

3. **Recommend — lead with a stance.** Open with your single best pick: the
   best-practice, most efficient solution, stated as one clear recommendation
   and grounded in documented standards and mature, antifragile patterns. Name a
   runner-up when it is genuinely close, and say why yours wins. Flag security
   and performance costs.

4. **Open the floor.** User picks, pushes back, or freestyles; loop until
   settled. Escape hatch: "want me to pick the sensible default?" On defer,
   choose best practice (ties → simpler/faster, options open) and record it.
   **Decisions land in the durable artifact.** On a task file: convert the
   answer into clear instruction in Problem / Success criteria / Notes, then
   delete the open question — the instruction *is* the record.

## Many decisions: one issue at a time

Whenever you hold two or more questions or decisions for the user — after
reading the artifacts, or found along the way — write them as a checklist and
work it with the work loop, one item at a time. Clear-cut questions never
enter the list: settle them with best practice and say so in a line.

**The checklist.** `docs/tmp/<subject>_discuss.md` (the prompt names it; e.g.
`task-231_discuss.md`, `plan-40_discuss.md`). One unchecked line per issue,
most-blocking first; indent an issue's follow-up questions beneath it as their
own lines:

    - [ ] Issue 1 — one singular issue, with your suggested answer
      - [ ] Issue 1, follow-up question — one singular issue
      - [ ] Issue 1, follow-up question — one singular issue
    - [ ] Issue 2 — …

Tell the user in one line how many items there are, then start the loop.

**The work loop.** Read the checklist and take the first unchecked line, top to
bottom. Then:

1. **Ask.** One message, one issue: what it is, why it matters, and a short
   numbered list of options. Mark the option best practice supports
   `(suggested)` with a one-line why; otherwise just ask. End with the question
   and wait.
2. **Work it through.** Answer follow-ups and refine the options until the user
   decides (a number, their own answer, or "your call" → the suggested option).
3. **Do the work.** Carry out the decision now: the doc, task, plan, or code
   updates it calls for.
4. **Note and check it off.** Under the line, add an indented note of what was
   decided and what changed, then mark the line `- [x]` so it is never
   reworked. Confirm the change to the user in one line.
5. **Restart.** Re-read the checklist and take the next unchecked line. A new
   issue that turns up along the way is added as an unchecked line in its
   blocking order and waits its turn.

When no unchecked lines remain, recap what changed in a few lines and delete
the checklist — the updated artifacts are now the record. If a session ends
early, the next one reads the checklist and picks up at the first unchecked
line.
