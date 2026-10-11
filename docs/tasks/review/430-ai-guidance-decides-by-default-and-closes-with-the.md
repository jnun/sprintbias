# Task 430: AI guidance decides by default and closes with the calls

**Feature**: none
**Created**: 2026-10-10
**Docs**: none
**Plan**: 32
**From plan**: none
**Depends on**: 424, 425, 427
**Dependents**: 431
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-finish-rule.sh, docs/tests/test-fast.sh
**Refined**: 0
**Reworked**: 0

## Problem

The AI guidance files teach the old habit. ai/conversation.md decides only when the person defers, ends each message "with the question and wait", and deletes the decision record; its recap lists no calls and no next command. ai/refine.md sends "which of two designs?" to a BLOCKER for a human. ai/task-creation.md defines blocked as "a decision is needed", runs a Q&A interview that waits on each answer, says open questions keep a task BLOCKED, and points at `settle`.

## Done when (automated)

- [x] conversation.md: a chat interviews one issue at a time, each question with a (suggested) pick, and waits for the answer; clear-cut calls are recorded as `- Decided: X, because Y`; the recap ends with the exact next command (`bash docs/tests/test-finish-rule.sh`)
- [x] refine.md: a design choice inside a bounded gap is decided and reopened with `Decided:`; BLOCKER is for work that fails its goal with no bounded fix, or a defect found while correctness is unverified, and each BLOCKER reason names the next command (`bash docs/tests/test-finish-rule.sh`)
- [x] task-creation.md: blocked means cannot start (no reasonable reading, or access the person holds); answered questions become instructions; the Q&A asks and waits per question, and a question left open keeps its suggestion, which `work` takes as the answer (`bash docs/tests/test-finish-rule.sh`)
- [x] conversation.md keeps the yes/no or 1/2/3 one-keystroke form (`bash docs/tests/test-fast.sh`)

## Signoff (human)

Checked in the plan's one human test, #434.

## Notes

- Decided: in a live chat, a goal-changing question still ends the message as a one-keystroke yes/no or 1/2/3 with one `(suggested)` option, and "your call" or no preference takes the suggested option, because conversation.md is the interactive surface where 424's rule allows asking.
- Decided: the work-loop checklist note under each checked line uses the `- Decided: X, because Y` form, and the recap lists those calls before deleting the checklist, because the recap is the only place the person sees the calls once the checklist is gone.
- Decided: depend on 425 as well as 424 and 427, because task-creation.md restates the gate's Questions overlay that 425 rewrites; match its wording rather than drafting a second version.
- Decided: the BLOCKER reason in refine.md stays on the single `VERDICT:` line (short reason naming the command, e.g. `./sprint.sh polish --code`), because scripts parse that line as the last line of output.
- `docs/tests/test-finish-rule.sh` is created by 424; add this task's checks to it.

## References

docs/sprintbias/ai/conversation.md
docs/sprintbias/ai/refine.md
docs/sprintbias/ai/task-creation.md

## Grounding

**Sources:** `CLAUDE.md` (guiding principles: lean into agent bias, instruct positively), `docs/sprintbias/lib.sh` (`sprintbias_assume_rule`, the one finishing rule 424 rewrites; `Decided: X, because Y` form), `docs/sprintbias/ai/conversation.md`, `docs/sprintbias/ai/refine.md`, `docs/sprintbias/ai/task-creation.md` (the AI guidance this task edits), `DOCUMENTATION.md` (lifecycle folders and blocked/ meaning)
**Terms:**
- None. (The project has no glossary file; docs/sprintbias/project.md does not exist yet.)
**Conflicts:**
- task-creation.md defines BLOCKED as "a decision or clarification is needed" and the current gate contract says the same; this task narrows it to "cannot start" → follow 424's finishing rule (no reasonable reading, or access the person holds) and depend on 425 so the gate wording and task-creation.md change together.
- task-creation.md points at `./sprint.sh settle`, which 427 retires → remove the pointer after 427 lands (already a dependency).
- `docs/tests/test-finish-rule.sh` named in Done when does not exist yet → 424 creates it; this task adds its checks there.
- "finishing rule" is not a defined glossary term → read it as 424's `sprintbias_assume_rule`; suggest adding it to DOCUMENTATION.md when a glossary exists.

## Questions

**Status: READY**

### Already complete
None — no matching implementation found. Checked:
- `docs/sprintbias/ai/conversation.md:25-30` decides only "On defer"; `:56-57` ends with "the question and wait"; `:69-70` recap lists no calls or next command and deletes the record.
- `docs/sprintbias/ai/refine.md:73-75` sends "which of two designs?" to BLOCKER; `:158-162` BLOCKER reason names a command only for the unverified-defect case.
- `docs/sprintbias/ai/task-creation.md:80-87` "Open questions keep the task BLOCKED", `settle` pointer; `:183` "Wait for answers"; `:196-197` blocked = "a decision or clarification is needed".
- `docs/tests/test-fast.sh:311-313` already checks conversation.md for yes/no, 1/2/3 and "one keystroke" (passes today; keep it passing).

### Remaining work
- conversation.md: decide clear calls and record them as `- Decided: X, because Y`; ask only goal- or result-changing questions, one keystroke each; every message ends in an action; recap lists each call with `./sprint.sh newtask "<the change you want>"` and ends with the exact next command.
- refine.md: a design choice inside a bounded gap is decided and reopened with `Decided:`; BLOCKER only for a goal failure with no bounded fix or a defect found while correctness is unverified/failed; each BLOCKER reason names the next command.
- task-creation.md: blocked = cannot start (no reasonable reading, or access the person holds); answered questions become `Decided:` lines; Q&A drafts from the most reasonable reading and confirms once; drop the `settle` pointer.
- Add the conversation/refine/task-creation checks to `docs/tests/test-finish-rule.sh`; keep `bash docs/tests/test-fast.sh` green.

### Questions for the developer
None — task is fully defined.

## Completed

- ai/conversation.md: move 4 is "Decide, or ask one goal question"; clear calls are recorded as `- Decided:` bullets and kept in ## Notes; every message ends in an action; the checklist holds only goal questions; the close lists every call with the newtask line and ends with the exact next command.
- ai/refine.md: a design choice inside a bounded gap is decided and written into the Rework item; "is this wanted?" passes with a newtask line in the Summary; BLOCKER is for a missed goal with no bounded fix (reason names `./sprint.sh chat <id>`) or a defect while correctness is unproven (reason names `./sprint.sh polish --code <file>`).
- ai/task-creation.md: "Questions become decisions" replaces the ask/get/delete loop; blocked = cannot start; the Q&A drafts from the most reasonable reading, asks only goal questions, and confirms once with the calls and the next command.

### Assumptions
- Decided: rename conversation.md's "Many decisions: one issue at a time" heading to "Many questions: one at a time", because only goal questions enter the checklist now; the prompts that cite the old heading (chat-plan.sh, plan-think.sh, lib.sh checklist line) are #431's to update. (Superseded: the heading stays, because 0.0.137 kept chat's one-at-a-time interview; see the audit line below.)
- Decided: keep the checklist file and work loop for goal questions, because a live chat with several goal questions still needs one-at-a-time order and a resumable record.
- Decided (2026-10-10 audit): bullets 1 and 3 are rewritten to what shipped, because 0.0.137 brought the chat interview back (one question at a time, wait for the answer) after this task landed; chat is where questions get dug into, and work, the gate, plan think and crew decide.

### Files changed
docs/sprintbias/ai/conversation.md
docs/sprintbias/ai/refine.md
docs/sprintbias/ai/task-creation.md
CHANGELOG.md
docs/tests/test-finish-rule.sh

**Proof**: 2026-10-10 · bash docs/tests/test-finish-rule.sh, bash docs/tests/test-fast.sh · pass

## Plan Think

FINISHED (review/). conversation.md, refine.md and task-creation.md decide by default and close with the calls. Architect: the guidance now agrees with the prompts that splice it. Experience: a recap lists every call with its newtask line. Nothing more is needed here. help/chat.md and guides/use_chat.md go to #436. Left as-is.
