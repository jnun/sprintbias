# Task 431: Chat, plan think and crew sessions decide and close with the calls

**Feature**: none
**Created**: 2026-10-10
**Docs**: none
**Plan**: 32
**From plan**: none
**Depends on**: 424, 430
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-finish-rule.sh, docs/tests/test-fast.sh
**Refined**: 0
**Reworked**: 0

## Problem

The interactive prompts still hold work on the person. chat.sh's demote block moves a task to blocked/ when "a real choice" remains. plan think holds owner calls in a discuss file and hands them to `chat plan` one by one. chat plan says "One question at a time; wait for the answer"; chat sprint keeps a task BLOCKED while a question is open; the steady crew lead "raises decisions for the human one at a time". None of these sessions is asked to close with the calls it made and the next command, and none splices `sprintbias_assume_rule`.

## Done when (automated)

- [x] plan think and crew prompts carry `sprintbias_assume_rule`; chat, chat plan and chat sprint interview instead and leave it out (`bash docs/tests/test-finish-rule.sh`)
- [x] chat.sh moves a task to blocked/ only when it cannot start; every other open choice is decided and recorded (`bash docs/tests/test-finish-rule.sh`)
- [x] plan think acts on every finding that has a reasonable pick and records `Decided:` in the plan; it holds only calls whose answer changes the goal (`bash docs/tests/test-finish-rule.sh`)
- [x] chat plan, chat sprint and the crew lead (both modes) carry no wait-per-question or keep-BLOCKED-while-open line; test-fast.sh's steady-lead check is corrected to the new line, with the reason in this task's ## Test log (`bash docs/tests/test-fast.sh`)
- [x] Each interactive prompt ends with the exact next command; the crew lead also lists the crew's calls, each with `./sprint.sh newtask "<the change you want>"` (`bash docs/tests/test-finish-rule.sh`)

## Signoff (human)

Checked in the plan's one human test, #434.

## References

docs/sprintbias/scripts/chat.sh
docs/sprintbias/scripts/chat-plan.sh
docs/sprintbias/scripts/chat-sprint.sh
docs/sprintbias/scripts/plan-think.sh
docs/sprintbias/scripts/crew.sh
docs/tests/test-fast.sh

## Notes

- Decided: chat.sh's task-refine rule "One question at a time; wait for the answer." (and the close-the-loop line "While any open question remains, leave the file in blocked/") are in scope with the demote block, because they hold work on the person the same way and the Problem names chat as one of the sessions.
- Decided: chat sprint keeps walking findings one per message (that is pacing, not a question gate); its "While a question remains open, keep the task BLOCKED" line goes, and an open question with a suggestion is answered by that suggestion, because the finishing rule from 424 decides by default.
- Decided: plan think still writes the discuss file, but only for calls whose answer changes the goal; everything else is applied and listed as `- Decided: X, because Y` in the plan, because chat plan and `sprintbias_discuss_open_count` already read that file and it stays the one hand-off.
- Decided: the steady crew lead bullet drops "Raise decisions for the human one at a time." in both modes, and test-fast.sh line 272's exact-string check is rewritten to the new bullet, because the old line contradicts the finishing rule; the reason goes in ## Test log.

## Grounding

**Sources:** `docs/sprintbias/lib.sh` (`sprintbias_assume_rule`, the one finishing rule spliced into prompts), `docs/sprintbias/ai/conversation.md` (interactive session voice: one-keystroke questions, recap), `docs/sprintbias/scripts/chat.sh`, `chat-plan.sh`, `chat-sprint.sh`, `plan-think.sh`, `crew.sh` (the prompts this task edits), `docs/tests/test-fast.sh` (fast/steady prompt checks), `docs/tests/test-finish-rule.sh` (cross-surface prompt checks, created by 424), `CONTRIBUTING.md` (surfaces kept in step)
**Terms:**
- None. (No project map or glossary yet.)
**Conflicts:**
- test-fast.sh line 272 asserts the steady lead bullet still says "Raise decisions for the human one at a time." → the task supersedes it; rewrite that check to the new bullet and record why in ## Test log.
- `docs/tests/test-finish-rule.sh` named in Done when does not exist yet → 424 creates it; this task adds its checks there (recorded in **Depends on**).
- `sprintbias_assume_rule` today writes `Decided: X, because Y` without the bullet form and still lets questions wait → 424 rewrites it; splice the rule as 424 leaves it, not the current text.
- chat.sh line 433 and the close-the-loop block also hold work on the person but Done when names only the demote block → settled in Notes (`Decided:`): both are in scope.

## Questions

**Status: READY**

### Already complete
None — no matching implementation found.
- `sprintbias_assume_rule` (docs/sprintbias/lib.sh:748) is spliced only into work.sh:996; chat.sh, chat-plan.sh, chat-sprint.sh, plan-think.sh and crew.sh do not call it.
- chat.sh:224-240 demotes to blocked/ on "a real choice still needed"; chat.sh:210 keeps a blocked task in blocked/ while any question is open; chat.sh:433 "One question at a time; wait for the answer."
- chat-plan.sh:186 "One question at a time; wait for the answer."; chat-sprint.sh:425-426 "While a question remains open, keep the task BLOCKED".
- plan-think.sh:165 holds product/policy/trade-off findings in the discuss file; plan-think.sh:251 and 300-307 raise them one at a time through chat plan.
- crew.sh:249 steady lead bullet "Raise decisions for the human one at a time."; fast lead (crew.sh:250) already says "ask the human only goal questions".
- No interactive prompt asks for a closing list of calls with `./sprint.sh newtask "<the change you want>"` and the next command.

### Remaining work
- Splice `sprintbias_assume_rule` into the chat, chat plan, chat sprint and crew (lead and member) prompts.
- chat.sh: demote to blocked/ only when the task cannot start (no reasonable reading, or access the person holds); decide and record every other open choice; drop the wait-per-question and keep-in-blocked-while-open lines.
- plan think: apply every finding with a reasonable pick, record `- Decided: X, because Y` in the plan, hold only goal-changing calls in the discuss file, and update the closing messages to match.
- chat plan, chat sprint, crew lead (both modes): remove wait-per-question and keep-BLOCKED-while-open lines; correct test-fast.sh's steady-lead check with the reason in ## Test log.
- Every interactive prompt closes with its calls (each with `./sprint.sh newtask "<the change you want>"`) and the exact next command.
- Add the checks to `docs/tests/test-finish-rule.sh`; run it and `bash docs/tests/test-fast.sh`; keep help pages and DOCUMENTATION.md in step where they describe these sessions.

### Questions for the developer
None — task is fully defined.

## Test log

- `bash docs/tests/test-fast.sh` — "lead (off): lead bullet unchanged" pinned "Raise decisions for the human one at a time." → corrected to the new steady-lead bullet ("Decide by the finishing rule above; ask the human only goal questions.") plus an absence check, because that line is what this task retires.
- `bash docs/tests/test-finish-rule.sh` — three new "closes with the calls + newtask" checks failed: the needle carried literal backslash-quotes from shell quoting while the prompts print plain quotes → test needle fixed; the prompts were right.

## Completed

- chat.sh splices `sprintbias_assume_rule`; the question loop, REFINE step, STRESS-TEST walk and RULES decide by best practice and ask only goal questions; the demote block applies only when the task cannot start; close-the-loop decides instead of waiting; the chained subagent decides and reports its calls; FINISH lists every call with the newtask line and ends with `./sprint.sh work <id>`.
- chat-plan.sh splices the rule; READY no longer waits on the user's confirmation; members and order are decided and recorded; STOP lists the calls and ends with `./sprint.sh plan start <id>`; RULES ask only goal questions; the checklist section names "Many questions".
- chat-sprint.sh splices the rule; findings name `./sprint.sh chat <id>` / `./sprint.sh gate`; open questions are decided (their suggestion when present); no keep-BLOCKED-while-open, no wait between findings; the recap lists calls and ends with `./sprint.sh work`.
- lib.sh: the checklist line is a QUESTION CHECKLIST for goal questions; `sprintbias_next_blocked_resolution` picks the path best practice supports and acts, the user can redirect; its chain instruction decides and reports calls.
- plan-think.sh splices the rule; it decides and applies every finding with a reasonable pick, lists calls under `## Decided` in the plan, takes DONE ALREADY / NOT REAL / OFF GOAL members out of the plan with evidence, and holds only goal questions; every exit line names a command.
- crew.sh: member and setup prompts carry the rule; the steady and fast lead both decide by it; no-target sessions pick work instead of asking.
- help/plan.md, DOCUMENTATION.md and command-matrix.md describe plan think's new behavior; CHANGELOG.md bullet.

### Assumptions
- Decided: a plan's calls live under a `## Decided` section (and the finishing rule now says so instead of "a plan's Policy"), because the plan template has no Policy section and plan think needs one fixed place to write them.
- Decided: a crew member with no target takes the lowest-id READY task in next/ that fits its role, because asking the lead or the person what to pick up is exactly the wait the plan removes; it still tells the lead.
- Decided: chat-bugs.sh keeps its per-report keep/delete choice, because closing or deleting a person's bug report is their call and the sweep already ends each report with a command; recorded here rather than changed.
- Decided (2026-10-10 audit): bullets 1 and 5 are rewritten to what shipped, because 0.0.137 brought the chat interview back after this task landed; the crew lead's closing list was added in the audit.

### Files changed
docs/sprintbias/scripts/chat.sh
docs/sprintbias/scripts/chat-plan.sh
docs/sprintbias/scripts/chat-sprint.sh
docs/sprintbias/scripts/plan-think.sh
docs/sprintbias/scripts/crew.sh
docs/sprintbias/lib.sh
docs/sprintbias/help/plan.md
DOCUMENTATION.md
docs/guides/command-matrix.md
CHANGELOG.md
docs/tests/test-finish-rule.sh
docs/tests/test-fast.sh

**Proof**: 2026-10-10 · bash docs/tests/test-finish-rule.sh, bash docs/tests/test-fast.sh, bash docs/tests/test-crew.sh, bash docs/tests/test-sprint.sh · pass

## Plan Think

FINISHED (review/). chat, chat plan, chat sprint, plan think and crew splice the rule and close with their calls. Tension: Done when item 4 says chat plan carries "no wait-per-question line", yet chat-plan.sh:187 and chat.sh:439 keep "One question at a time; wait for the answer." Also, test-finish-rule.sh:186 and :194 pin that line. Resolved in plan 32 ## Decided: a live chat is the one place the rule allows a goal question, so waiting there is correct. Read item 4 as "no wait on calls the agent can decide", which the Completed delivers. The `chat <folder>` sweep (chat-folder.sh) was not on this task's list, so delta #436 covers it. Left as-is.
