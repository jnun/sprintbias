# Plan 32: Bias for finishing, end to end

**Created**: 2026-10-10
**Status:** STARTED
**Crew**: none

## Goal

Agents finish the work. Every prompt and script that can stop work or ask the
person follows one rule (a live chat is the exception: it interviews): take the most reasonable pick, record it as
`Decided: X, because Y`, and keep going. The person is informed, not waited on:
each call shows up at the end of the run with one command to change it, and
every message ends in an action, meaning what to check and the exact command to
run next.

## Why

An audit of gate-lib.sh, work.sh, chat*.sh, plan-think.sh, plan-start.sh,
crew.sh, polish.sh, promote.sh and ai/ found the rule stated in one place
(`sprintbias_assume_rule`) and contradicted in a dozen: fork-stop lines in work,
a 60-line question loop in the gate, a plan start that aborts on one blocked
member, chat sessions that wait per question, and summaries that end on counts.

## Policy

- Decide and record: `- Decided: X, because Y`, under `### Assumptions` in a task
  or in the plan. A changed mind is `./sprint.sh newtask "<the change you want>"`.
- A failing test is audited first: a wrong test is corrected (reason in
  `## Test log`), a clear cause is fixed, the run repeats until green. Still
  unexplained: land in review/ without **Proof**.
- blocked/ holds only work that cannot start: no reasonable reading, or access or
  credentials the person holds.
- Every message to the person ends with what to check and the exact command.
- Commit, push and ship.sh stay the human's.

## Member tasks

<!-- One "- #ID — short title" line per task; [x] means the task is in done/.
     IDs are references — resolve each against docs/tasks/*/ for location. -->

- #424 — One finishing rule: default decides, fast adds only fast-specific reach
- #425 — Shorten the gate question procedure to the finishing rule
- #426 — Work prompts follow the finishing rule end to end
- #427 — Retire settle now that gate and work take suggestions
- #428 — Close a task with no Tests in one command: promote --accept
- #429 — Plan start, promote, polish and the gate end every message in an action
- #430 — AI guidance decides by default and closes with the calls
- #431 — Chat, plan think and crew sessions decide and close with the calls
- #432 — Learning demos show the end-of-run checklist
- #436 — blocked/ means cannot start on every surface: folder sweep, status, gate, work, loop and help
- #434 — Human test for plan 32

Order (Depends on): 424 first. Then 425, 426, 427 (gate-lib.sh, work.sh,
settle surfaces). 428 after 426 (work.sh checklist). 429 after 425 and 428.
430 after 424 and 427; 431 after 430. 432 last of the demos-facing work (426,
428, 429). 436 after 431: it sweeps the surfaces 424–431 did not name, so it
starts from their wording. 434, the human test, runs last.

## Decided

- Decided: run the gate as one parallel reviewer per member (as plan start's emitted prompt directs), because the reviews are independent.
- Decided: work the nine members in this one session, in dependency order, instead of one subagent per task, because every member edits lib.sh, work.sh or gate-lib.sh and the rule's wording has to match across them.
- Decided: `settle` is retired; successor `work <id>` / `chat <id>`, because the gate, work and demote take every suggestion themselves.
- Decided: the no-Tests close is `./sprint.sh promote --accept <id>`, because it pairs with `--reject <id>`.
- Decided: plan start gates blocked/ members with the rest instead of stopping, because one blocked member should not hold the plan.
- Decided: a plan's calls live under `## Decided` (this section), because the plan template has no Policy section.
- Decided: where an incomplete run (no ## Completed) lands stays as is, filed as #433, because changing it touches loop's retry behavior.
- Decided: add #436 as a member, because the `chat <folder>` sweep prompt (chat-folder.sh:119, :184) still marks a task BLOCKED for an open choice, and status, gate, work and loop still print "needs decision or clarification" (sprint.sh:226, gate.sh:398/:442, work.sh:1789, loop.sh:289), so blocked/ still means two things and the Goal ("every prompt and script") is unmet.
- Decided: #436 is a new delta task, not a reopening of #426/#427/#431, because those landed against their own Done when and the leftover surfaces were never on their lists.
- Decided: #433 stays out of the plan (From plan 32), because it changes loop's retry route, and the plan's Goal is met by naming the reason on that route (#436) without moving it.
- Decided: live chats keep "One question at a time; wait for the answer." (chat.sh:439, chat-plan.sh:187), because a live conversation is the one place the finishing rule allows a goal question and test-finish-rule.sh:186/:194 pins it. #431's Done when line "chat plan … carry no wait-per-question line" reads as "no wait on questions the agent can decide", which its Completed delivers.
- Decided: #436's person-only check (a real `chat blocked` sweep) is check 11 of #434, because one human pass per plan is the rule and a second sign-off list would be missed.
- Decided (2026-10-10 audit): #430 and #431's chat bullets are rewritten to what shipped, because 0.0.137 brought the chat interview back after they landed; work, the gate, plan think and crew decide, and live chats interview.
- Decided (2026-10-10 audit): the leftover old-meaning blocked/ lines (gate's chat queue, work's gate summary, help/loop, help/work, help/chat, use_chat, GETSTARTED, command-matrix) are fixed in place and the guard now reads wrapped lines and those files, because they were the same leak #436 targeted.
- Decided (2026-10-10 audit): the folder sweep's [w] now writes its `- Decided:` pick into the task's ## Notes, and the crew lead closes with the crew's calls and `./sprint.sh promote plan:<N>`, because the Policy says decide *and record* and every message ends in a command.

## Signoff (human)

Checked in the plan's one human test, #434 (check 11 covers #436).

## Plan Think

Full review: docs/tmp/plan-think-32.md. Top findings:

1. Members 424–432 have all landed in review/ with Proof, and the suite is green (32 of 32). None needed rewriting.
2. blocked/ still has two meanings. The `chat <folder>` sweep and four status lines still say "needs decision or clarification", so delta task #436 was added before the human test.
3. #431's "no wait-per-question" line and the kept "wait for the answer" in live chats are reconciled: live goal questions wait by design (recorded under ## Decided).

<!--
AI: Full plan guidance is in DOCUMENTATION.md → Plans. A plan is a relational
index, not a container: Status is DRAFT | READY | STARTED, and members stay in
their own lifecycle folders. Keep it plain text — no emoji, color, or ASCII art.
See docs/sprintbias/guides/doc-style.md
-->
