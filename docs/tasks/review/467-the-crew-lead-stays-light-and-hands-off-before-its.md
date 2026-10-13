# Task 467: The crew lead stays light and hands off before its context runs out

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
**Tests**: docs/tests/test-crew.sh
**Refined**: 0
**Reworked**: 0

## Problem

On heavymetal plan 69, orcha holds the gate results for nine tasks, every subagent's report and every routing decision in one session. A long plan fills the lead's context; when it compacts or crashes, the routing state lives only in that session unless the board is current.

## Done when (automated)

- [x] Member subagents return only the task id, the proof line and any Decided lines. Proven by `bash docs/tests/test-crew.sh`
- [x] The lead keeps one progress file per plan, `docs/tmp/plan-<id>-progress.md`, rewritten after each landing and routing: Done (task, member and agent type that built it, proof), Building, Next (what each pending landing releases and to whom), Open calls. A fresh lead reads it first and resumes from Next, and `crew <lead> plan:N` prints `Resuming plan N from …` when it exists. Proven by `bash docs/tests/test-crew.sh`
- [x] When its context has been compacted or runs long, the lead starts no new subagents, lets the ones in flight land, updates the progress file and names the resume command (`./sprint.sh crew <lead> plan:N` in a fresh session). Proven by `bash docs/tests/test-crew.sh`
- [x] help/crew.md says how a long-running lead hands off. Proven by `./sprint.sh validate --docs`

## Signoff (human)

- [ ] On a long plan, `docs/tmp/plan-<id>-progress.md` is current after each landing, and a fresh `crew <lead> plan:N` resumes from it without re-reading every task.

## Notes

- Decided: progress lives in one uniform file, docs/tmp/plan-<id>-progress.md, beside plan think's docs/tmp/plan-think-<id>.md, because the person asked for one place a fresh lead always looks, and it keeps the plan file short; the ## Crew board keeps the approach, Active line and one line per member.
- Decided: handoff happens at a wave boundary, because background subagents end with the session that started them.
- Follow-up built in #473: `crew <lead>` starts a fresh lead by itself when the progress file turns to Handoff: ready.

## References

docs/sprintbias/scripts/crew.sh
docs/sprintbias/help/crew.md
docs/tests/test-crew.sh

## Completed

**Summary**: The crew lead keeps its context small, keeps docs/tmp/plan-<id>-progress.md current, and hands off to a fresh session before its context runs out.

Fixed in place during the heavymetal plan 69 crew run (2026-10-12), then filed so the record matches the code.

**Proof**: 2026-10-12 · bash docs/tests/test-crew.sh; ./sprint.sh validate --docs · pass

### Files changed
docs/sprintbias/scripts/crew.sh
docs/sprintbias/help/crew.md
docs/tests/test-crew.sh

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
