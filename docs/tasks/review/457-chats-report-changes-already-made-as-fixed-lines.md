# Task 457: Chats report changes already made as Fixed: lines

**Feature**: none
**Created**: 2026-10-12
**Docs**: none
**Plan**: 35
**From plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-finish-rule.sh
**Refined**: 0
**Reworked**: 0

## Problem

In heavymetal, `chat plan 69` repaired a Depends on / Dependents loop and reported it as "One fix:" next to its one real question. The person could not tell whether the fix was done or waiting on them.

## Done when (automated)

- [x] `ai/conversation.md` tells every chat to report each change it already made in the past tense, one line each, as `Fixed: <what changed>`, apart from any question. Proven by `bash docs/tests/test-finish-rule.sh` (chat and chat plan)

## Signoff (human)

- [ ] In a `chat plan` that repairs something, the repair reads `Fixed: …` and the question stands alone.

## Notes

- Decided: one rule in ai/conversation.md, because chat, chat plan and the sweeps all load it.

## References

docs/sprintbias/ai/conversation.md
docs/tests/test-finish-rule.sh

## Completed

**Summary**: Chats now report each change they already made as a past-tense `Fixed:` line, so the person sees it needs no answer.

Fixed in place during the heavymetal plan 69 crew run (2026-10-12), then filed so the record matches the code.

**Proof**: 2026-10-12 · bash docs/tests/test-finish-rule.sh · pass

### Files changed
docs/sprintbias/ai/conversation.md
docs/tests/test-finish-rule.sh

<!-- sb:hint  After work only — audit trail of what was touched. Helps committers,
     later audits, and "what broke?" recovery. List the product files you
     edited to complete the task — one repo-relative path per line. Leave this
     task file out: its folder location and git history already track it. Copy
     the two headings below to column 0
     (UNINDENTED — they are indented here only so a fresh, unworked task is not
     mistaken for a finished one), then list the paths under "Files changed":

       ## Completed

       **Summary**: <one plain sentence: what changed, for someone reading
       the project's history>

       ### Files changed
       docs/sprintbias/scripts/example.sh
       docs/sprintbias/help/example.md

     When the work rests on something only a person can confirm (a device,
     a live account), add under ## Completed; it joins the plan's human test:

       ### Assumptions
       - The scanner sends one line per barcode

     When the work made a source of truth wrong and updating it is out of
     scope (or it is a governing source), add under ## Completed:

       ### Doc follow-ups
       - `docs/GLOSSARY.md` — add "plan"; the code now uses it

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. Do not fill this before work. -->

<!-- sb:hint
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->
