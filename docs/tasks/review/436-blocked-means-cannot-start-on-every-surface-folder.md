# Task 436: blocked/ means cannot start on every surface: folder sweep, status, gate, work, loop and help

**Feature**: none
**Created**: 2026-10-10
**Docs**: none
**Plan**: 32
**From plan**: 32
**Depends on**: 424, 425, 426, 427
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-finish-rule.sh
**Refined**: 0
**Reworked**: 0

## Problem

Plan 32 narrowed blocked/ to work that cannot start. That means no reasonable reading, or access or credentials only the person holds. It also rewrote the gate, work, chat, plan think and the AI guidance to match (#424–#431). The surfaces those tasks did not name still teach the old meaning. The `chat <folder>` sweep prompt still sorts a task into BLOCKED for "an unresolved choice, open question, contradiction". That is a live path that parks work the finishing rule would decide. The person also reads "Blocked (needs decision or clarification)" in `status`, the gate's summary, work's drift route and loop's rescue line. help/work.md still says a "product/scope fork that needs a human" lands in blocked/. So the person and the agent get two definitions of the same folder.

Builds on #424 (the finishing rule's blocked/ bar), #425 (gate contract), #426 (work prompts) and #427 (BLOCKED sections end in `chat <id>` then `work <id>`). Start from the code as those tasks left it. Change only the surfaces listed below.

## Done when (automated)

- [x] The folder-sweep prompt in `docs/sprintbias/scripts/chat-folder.sh` defines BLOCKED as cannot start (no reasonable reading, or access or credentials the person holds). An open choice with a reasonable pick is decided and recorded as `- Decided: X, because Y`, and the task is not marked BLOCKED for it. The BLOCKED status line names `./sprint.sh chat <id>` (`bash docs/tests/test-finish-rule.sh`)
- [x] The person-facing blocked labels say "cannot start", or name the actual reason, instead of "needs decision or clarification". This covers `sprint.sh` status, `gate.sh` (both lines), `work.sh`'s drift-outdated route and `loop.sh`'s rescue line. Each ends with or sits above a `./sprint.sh chat <id>` or `./sprint.sh work <id>` line. The routes themselves stay as they are, since #433 owns where an incomplete run lands (`bash docs/tests/test-finish-rule.sh`)
- [x] help/status.md, help/chat.md, help/work.md and guides/use_chat.md describe blocked/ as cannot start. help/work.md's Finish-first paragraph and its "Moves to review/" line carry no fork-stop. The code comments that restate the old meaning (lib.sh, chat.sh, gate-lib.sh, loop.sh, chat-folder.sh) match (`bash docs/tests/test-finish-rule.sh`)
- [x] The other blocked/ labels that say "needs a decision" carry the same meaning: work.sh's gate-BLOCKED line, its route comment, its held-dependency advice (both places) and its worker-blocked fallback reason; chat-sprint.sh's stand-up prompt; and the blocked-dependency phrasing in lib.sh and chat.sh (`bash docs/tests/test-finish-rule.sh`)
- [x] `docs/tests/test-finish-rule.sh` guards it: no file under `docs/sprintbias/` (tests and `__pycache__` excluded), and neither `sprint.sh` nor `DOCUMENTATION.md`, contains "decision or clarification", "decision/clarification", "needs decision", "needs a decision" or "scope fork" (`bash docs/tests/test-finish-rule.sh`)
- [x] The suite stays green (`bash docs/tests/run-all.sh`)

## Signoff (human)

Checked in the plan's one human test, #434 (check 11: a real `./sprint.sh chat blocked` sweep with one design-choice task and one that needs a production key).

## Notes

- Decided: one sweep task instead of reopening #426, #427 or #431, because those tasks landed against their own Done when and the leftover surfaces were never in their lists.
- Decided: the drift-outdated and loop-rescue labels name their real reason ("drift: outdated", "incomplete run") instead of "cannot start", because those tasks did start; where they land is #433's call.
- Decided: the plain-English "needs a human" in ai/accept.md (a task with no criteria needs a person to define done) and polish's `BLOCKED: needs a human` verdict token stay, because both are accurate and #429 already gave polish's BLOCKER line its commands.
- Decided: the sweep also covers the "needs a decision" and "decision/clarification" spellings (work.sh lines around 553, 592, 632, 746, 1435, 1543; chat-sprint.sh 393 and 416; lib.sh 976 and 993; chat.sh 219 and 262; chat-folder.sh 185, 239 and 240; gate.sh 299; help/work.md 89), and the guard bans them, because they teach the same old meaning and a guard on only two spellings would let them stay.
- Decided: interactive chats keep "One question at a time; wait for the answer." (chat.sh, chat-plan.sh), because a live conversation is where the finishing rule allows a goal question, and test-finish-rule.sh pins that line on purpose.

## References

docs/sprintbias/scripts/chat-folder.sh
sprint.sh
docs/sprintbias/scripts/gate.sh
docs/sprintbias/scripts/work.sh
docs/sprintbias/scripts/loop.sh
docs/sprintbias/help/status.md
docs/sprintbias/help/chat.md
docs/sprintbias/help/work.md
docs/sprintbias/guides/use_chat.md
docs/sprintbias/scripts/chat-sprint.sh
docs/sprintbias/scripts/chat.sh
docs/sprintbias/scripts/gate-lib.sh
docs/sprintbias/lib.sh
docs/tests/test-finish-rule.sh

## Grounding

**Sources:** `CLAUDE.md` (guiding principles: common language, positive-first instruction), `CONTRIBUTING.md` (docs/ is live; surfaces kept in step; changelog), `DOCUMENTATION.md` (user manual, folder meanings), `docs/sprintbias/lib.sh` (`sprintbias_finishing_rule`, the canonical blocked/ bar), `docs/sprintbias/scripts/gate-lib.sh` (gate contract), `docs/tests/test-finish-rule.sh` (plan 32 guards)
**Terms:**
- **blocked/** — "blocked/ is for work that cannot start: no reasonable reading of the task, or access or credentials only the person holds." (finishing rule, lib.sh)
- **dependent** — no glossary entry; read as: a task whose **Depends on** names an open task; it is on hold, not blocked.
**Conflicts:**
- The task vs the current code: sprint.sh, gate.sh (398, 442), work.sh (1803), loop.sh (289), chat-folder.sh (119, 184-185, 226) and help/chat.md, help/status.md, help/work.md, guides/use_chat.md still define blocked/ as "needs decision or clarification" → the work rewrites them to the finishing rule's bar; the finishing rule is the source of truth.
- The task's "change only the surfaces listed below" vs other "needs a decision" labels in work.sh, chat-sprint.sh, lib.sh and chat.sh → Decided (Notes): they join the sweep, because they are the same leak and the guard would otherwise miss them.
- Routes vs labels: the drift-outdated and loop-rescue routes still land in blocked/ although those tasks started → labels change, routes stay; #433 owns the route.
- The project has no glossary; "dependent" and "cannot start" have no glossary entry → read as above; Doc follow-up: add both to the manual's folder table if a glossary is created.
**Touching:** docs/sprintbias/scripts/chat-folder.sh, sprint.sh, docs/sprintbias/scripts/gate.sh, docs/sprintbias/scripts/work.sh, docs/sprintbias/scripts/loop.sh, docs/sprintbias/scripts/chat-sprint.sh, docs/sprintbias/scripts/chat.sh, docs/sprintbias/scripts/gate-lib.sh, docs/sprintbias/lib.sh, docs/sprintbias/help/{status,chat,work}.md, docs/sprintbias/guides/use_chat.md, docs/tests/test-finish-rule.sh, CHANGELOG.md

## Why

Plan 32's Goal covers every prompt and script that can stop work. The `chat <folder>` sweep still blocks a task over an open choice, and four status lines still tell the person that blocked/ means "a decision is needed". Until those change, the folder means two things depending on which command the person last ran.

## Questions

**Status: READY**

### Already complete
None — no matching implementation found. Checked:
- chat-folder.sh:119, 184-185 still define BLOCKED as "a decision or clarification is needed" including "unresolved choice, open question, contradiction"; :226 and :240 print the old label; no `Decided:` instruction in the sweep prompt.
- sprint.sh:226, gate.sh:398 and :442, work.sh:1803, loop.sh:289 print "needs/need decision or clarification".
- help/status.md:2, help/chat.md:75 and :79, help/work.md:89 and :103 ("product/scope fork"), :121 ("when a human decision is needed"), guides/use_chat.md:110 and :119 carry the old meaning.
- test-finish-rule.sh has no repo-wide guard for these phrases (it checks lib.sh, the gate contract and work prompts only).
- Prerequisites #424-#427 sit in review/.

### Remaining work
- Rewrite the chat-folder.sh sweep: BLOCKED = cannot start; open choices decided as `- Decided: X, because Y`; BLOCKED status line names `./sprint.sh chat <id>`.
- Relabel the status, gate, work drift, loop rescue and other work.sh blocked lines; keep every route.
- Update help/status.md, help/chat.md, help/work.md, guides/use_chat.md and the code comments listed in Notes.
- Add the repo-wide phrase guard to test-finish-rule.sh; run it and `bash docs/tests/run-all.sh`; add a CHANGELOG bullet.

### Questions for the developer
None — task is fully defined.

## Test log

- `bash docs/tests/run-all.sh` → test-finish-rule.sh "work: drift names its reason (missing: (drift: outdated)")" failed, though the line is in work.sh and the script passed on its own. Cause: `has`/`lacks` piped `printf` into `grep -q`; on a body as large as work.sh, grep exits on the first match, printf takes SIGPIPE, and `pipefail` turns the hit into a miss (and could turn a `lacks` hit into a false pass). Fixed the helpers to use a here-string; 5 repeat runs and the full suite are green.

## Completed

Every shipped surface now gives blocked/ one meaning: work that cannot start. The `chat <folder>` sweep defines BLOCKED as cannot start. It decides an open choice that has a reasonable pick and records it as `- Decided: X, because Y`, and a BLOCKED verdict line names `./sprint.sh chat <id>`. Status, gate, work drift and loop rescue print "cannot start" or their real reason ("drift: outdated", "incomplete run"), each with a `chat <id>` or `work <id>` line below it. All routes are unchanged. The help pages, guides, prompts and comments match, and test-finish-rule.sh guards the old phrases repo-wide.

### Assumptions
- Decided: the headless verdict sweep reports an open choice as READY with the pick in its RECOMMENDATION ('- Decided: X, because Y' to record in ## Notes), because that pass only returns three lines and cannot edit the file; the emit sweep, which can edit, records the Decided line in the task's ## Notes directly.
- Decided: `status` prints a `./sprint.sh chat <id>` line under each blocked task, because the Done when asks every label to sit above a next command and a bare list gave none.
- Decided: loop's rescue line points to `./sprint.sh work <id>`, because a task the run left incomplete was workable; re-running it is the natural next step.
- Decided: gate-lib.sh's "NOT a missing decision on THIS task" became "NOT a reason to block THIS task", and claude.sh's "parked for a human decision it never needed" comment stays, because it describes a crash being misfiled, which still holds.
- Decided: fixed the shared `has`/`lacks` helpers in test-finish-rule.sh (SIGPIPE under pipefail), because the new work.sh checks exposed a real flake that could also hide a `lacks` hit.

### Files changed
- docs/sprintbias/scripts/chat-folder.sh
- sprint.sh
- docs/sprintbias/scripts/gate.sh
- docs/sprintbias/scripts/gate-lib.sh
- docs/sprintbias/scripts/work.sh
- docs/sprintbias/scripts/loop.sh
- docs/sprintbias/scripts/chat.sh
- docs/sprintbias/scripts/chat-sprint.sh
- docs/sprintbias/lib.sh
- docs/sprintbias/help/status.md
- docs/sprintbias/help/chat.md
- docs/sprintbias/help/work.md
- docs/sprintbias/guides/use_chat.md
- docs/tests/test-finish-rule.sh
- CHANGELOG.md

Tests run: `bash docs/tests/test-finish-rule.sh` (120 passed, 5 repeat runs), `./sprint.sh validate --commands`, `./sprint.sh validate --docs`, `bash -n` on every touched script, `./sprint.sh status`, `bash docs/tests/run-all.sh` (34/34 scripts).

**Proof**: 2026-10-10 · bash docs/tests/test-finish-rule.sh; bash docs/tests/run-all.sh · pass
