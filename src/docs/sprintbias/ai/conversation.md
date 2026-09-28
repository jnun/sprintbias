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

When a review turns up two or more things that need the user's call (a plan
critique, a sprint health pass, a stress-test), lift them up one at a time, so
each gets the user's full attention, a quick decision, and immediate action.

1. **List.** Write `docs/tmp/<subject>_discuss.md` (e.g. `plan-40_discuss.md`):
   one numbered item per issue, most-blocking first. Each item holds the
   problem, the evidence, your recommendation, and an empty `Decision:` line.
   Tell the user how many issues there are with one short title each, then
   raise item 1.
2. **Raise one.** Each message covers exactly one issue: what it is, why it
   matters, and a short numbered list of options. When best practice points to
   one, mark it `(suggested)` and say why in a line; otherwise just ask. End
   with the question and wait. Keep later issues out of the message until
   their turn.
3. **Act on it.** When the user picks (a number, their own answer, or "your
   call" → the suggested option), carry it out right away, record the outcome
   on its `Decision:` line, confirm in one line what changed, and raise the
   next item.
4. **Resume.** The file is the outline and the memory. If a session ends early,
   the next one reads it and picks up at the first empty `Decision:`.
5. **Close.** When every item is decided, give a short recap of what changed
   and delete the discuss file — the updated artifacts are now the record.
