# Task 417: Fast mode lets agents decide and ask only goal questions

**Feature**: none
**Created**: 2026-10-10
**Docs**: none
**Plan**: 30
**From plan**: none
**Depends on**: 415
**Dependents**: 418, 419
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-fast.sh
**Refined**: 0
**Reworked**: 0

## Problem

Agents route every open decision to the person through the full conversation loop, and their questions are open-ended. Work stalls on calls best practice already settles, and agents drift into improving the tool instead of the plan's goal. In fast mode agents should decide, record, and keep moving, asking only questions that change what the user gets.

## Done when (automated)

- [x] A lib.sh function (`sprintbias_fast_rules`) returns one rule block, empty when fast is off, injected by chat, chat plan, crew and work (`bash docs/tests/test-fast.sh` checks each prompt carries the block with fast on and omits it with fast off)
- [x] The block states: decide by best practice, good security, elegant code and best UX; record each call in the task or plan as `Decided: X, because Y`
- [x] The block states: ask only questions whose answer changes the goal or the result; every question is yes/no or numbered 1/2/3 with one `(suggested)` option; reversible calls proceed on the suggested option and are noted; only the one goal-shaping item waits while other work continues
- [x] The block states: improvements to the tool or process become a one-line backlog task and the agent returns to the plan's goal
- [x] The block states the cross-plan rule: read the other plan's Goal before touching its task, serve both goals, and add `Touched by plan N: #id — what and why` to the other plan
- [x] ai/conversation.md states the yes/no or 1/2/3 question format for all modes; DOCUMENTATION.md has a short Fast mode section (`bash docs/tests/test-fast.sh` greps both)
- [x] `bash docs/tests/run-all.sh` passes

## Signoff (human)

- [ ] Run `chat plan` on a real plan with fast on; the agent decides clear calls without asking and every question it asks can be answered with one keystroke

## Notes

Instruct positively (CLAUDE.md principle 4): state the path, keep "never" for the human-owned invariants only. Keep the block short; it loads in every fast session.

Follow the existing prompt-fragment pattern: `sprintbias_excellence_rules`, `sprintbias_parallel_rule` and `sprintbias_proof_rule` in lib.sh are heredoc functions that callers splice into a prompt string. `sprintbias_fast_rules` reads the mode through #415's `sprintbias_fast_on` and prints nothing when it is off, so callers splice it in unconditionally.

Injection points today: chat.sh `APPEND_PROMPT` (~line 353), chat-plan.sh `APPEND_PROMPT` (~line 131), crew.sh member and setup `rules` (~lines 45, 213, 284), work.sh `_task_prompt` (~line 980) and the queue prompts (~lines 1092, 1134). work runs headless, so there a goal question is written into the task file and the agent takes its next task.

The block states the cross-plan rule only. Lifting chat plan's "write only the plan file" boundary and the crew lane rule is #418 and #419's work; both depend on this task.

## References

docs/sprintbias/ai/conversation.md
docs/sprintbias/lib.sh
docs/sprintbias/scripts/chat.sh
docs/sprintbias/scripts/chat-plan.sh
docs/sprintbias/scripts/crew.sh
docs/sprintbias/scripts/work.sh
DOCUMENTATION.md
docs/plans/30-fast-mode-autonomous-agents-fewer-blockers.md

## Grounding

**Sources:** `CLAUDE.md` (guiding principles; principle 4, instruct positively; human-owned actions), `docs/plans/30-fast-mode-autonomous-agents-fewer-blockers.md` (fast mode Goal and Policy), `docs/sprintbias/ai/conversation.md` (conversation method and question format, all modes), `docs/sprintbias/lib.sh` (prompt fragments `sprintbias_excellence_rules`, `sprintbias_parallel_rule`, `sprintbias_proof_rule`; mode reader `sprintbias_fast_on` from #415), `DOCUMENTATION.md` (user manual), `docs/tests/` (suite run by `run-all.sh`)
**Terms:**
- None. The project has no glossary.
**Conflicts:**
- Task named `docs/sprintbias/tests/test-fast.sh`, but the suite lives in `docs/tests/` and #415 creates `docs/tests/test-fast.sh` → extend that file.
- conversation.md already asks with numbered options and one `(suggested)` (work loop step 1) but has no yes/no form and no "one keystroke" rule → extend that step in place for all modes; the fast-only parts (proceed on suggested, only goal questions wait) live in the block.
- The cross-plan rule meets chat-plan.sh's "WRITES: only $PLAN_FILE" boundary and crew.sh rule 3 (stay in your lane) → this task adds the rule text only; #418 and #419 change those boundaries.
- work.sh runs headless (`sprintbias_run -p`), so it cannot ask in a conversation → in work the block's goal question lands in the task file and the run continues with other tasks.
- "Fast mode" and "steady" are new vocabulary with no glossary → read them as plan 30 defines them; the DOCUMENTATION.md section is their definition.
**Touching:** docs/sprintbias/lib.sh, docs/sprintbias/scripts/chat.sh, docs/sprintbias/scripts/chat-plan.sh, docs/sprintbias/scripts/crew.sh, docs/sprintbias/scripts/work.sh, docs/sprintbias/ai/conversation.md, docs/sprintbias/help/fast.md, DOCUMENTATION.md, docs/tests/test-fast.sh, CHANGELOG.md

## Questions

**Status: READY**

### Already complete
None — no matching implementation found. Checked:
- `lib.sh`: no `sprintbias_fast_rules` or `sprintbias_fast_on`; the fragment pattern exists (`sprintbias_excellence_rules` ~line 3264).
- chat.sh, chat-plan.sh, crew.sh and work.sh prompts carry no fast block; chat-plan.sh still says "Write only the plan file".
- `ai/conversation.md` work loop step 1 asks with a numbered list and `(suggested)`; no yes/no form or one-keystroke rule.
- DOCUMENTATION.md has no Fast mode section; `docs/tests/test-fast.sh` does not exist yet (#415 creates it).

### Remaining work
- `sprintbias_fast_rules` in lib.sh: one short, positively worded block covering decide-and-record, goal-only questions in yes/no or 1/2/3 form with one `(suggested)`, tool improvements to a one-line backlog task, and the cross-plan rule; empty when fast is off.
- Splice it into the chat, chat plan, crew (member and setup) and work prompts.
- Extend conversation.md's question step with the yes/no or 1/2/3 format for all modes.
- Short Fast mode section in DOCUMENTATION.md (what changes when on, what stays the human's).
- Cases in `docs/tests/test-fast.sh`: each prompt with fast on carries the block, with fast off omits it; block holds `Decided:`, `(suggested)`, `Touched by plan`.
- One `### Added` bullet in CHANGELOG.md under Unreleased.

### Questions for the developer
None — task is fully defined.

## Completed

- `sprintbias_fast_rules` (lib.sh, next to the other fast-mode helpers) prints a 13-line block when `sprintbias_fast_on`, nothing when off. It covers decide-and-record (`Decided: X, because Y`), goal-only questions in yes/no or 1/2/3 form with one `(suggested)`, reversible calls proceeding, the headless path (question into the task file, take the next task), tool ideas into a one-line backlog task, the cross-plan rule (`Touched by plan N: #id — what and why`), and a closing line that commits, ship and deploys stay with the human.
- Spliced in: chat.sh and chat-plan.sh after the Conversation Method (`${_FAST:+…}`, so fast off leaves the prompt unchanged), crew.sh member and setup rules, work.sh `_task_prompt` (exec) and both emit prompts (it rides with `_proof`).
- ai/conversation.md: move 4 (all modes) and the work-loop Ask step now say to ask so one keystroke answers: yes/no, or 1/2/3 with one `(suggested)`.
- DOCUMENTATION.md: the existing fast-mode paragraph is now a `### Fast mode` subsection under Provider and model, with the four agent rules added. help/fast.md lists them too.
- test-fast.sh: the block's content and length, with fast on and off, for chat, chat plan, crew member, crew setup, work emit (orchestrated + sequential) and work exec (stub CLI); greps for conversation.md and DOCUMENTATION.md.

### Assumptions
- Decided: the block closes with "Commits, ship and deploys stay with the human", because fast mode skips permission prompts and this is the one invariant worth restating. It is phrased positively.
- Decided: chat plan gets the cross-plan rule text only; its "WRITES: only $PLAN_FILE" boundary stays until #418 changes it, as the task Notes say.

### Files changed
docs/sprintbias/lib.sh
docs/sprintbias/scripts/chat.sh
docs/sprintbias/scripts/chat-plan.sh
docs/sprintbias/scripts/crew.sh
docs/sprintbias/scripts/work.sh
docs/sprintbias/ai/conversation.md
docs/sprintbias/help/fast.md
DOCUMENTATION.md
docs/tests/test-fast.sh
CHANGELOG.md

Tests run: `bash docs/tests/test-fast.sh` (82 passed), test-crew, test-proof-loop, test-dep-work, test-plan-lifecycle, test-command-matrix-smoke, `./sprint.sh validate --commands` / `--docs`, `bash docs/tests/run-all.sh` (29/29 scripts green).

**Proof**: 2026-10-10 · bash docs/tests/test-fast.sh; bash docs/tests/run-all.sh · pass
