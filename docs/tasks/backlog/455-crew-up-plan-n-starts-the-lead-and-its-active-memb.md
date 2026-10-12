# Task 455: crew up plan:N starts the lead and its Active members in one command

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
**Tests**: docs/tests/test-crew-up.sh
**Refined**: 0
**Reworked**: 0

## Problem

Running a crew today means opening one terminal per member by hand and
waiting for the lead's Active: line to know which ones. For a swarm (a lead and
members working one plan together, talking by name) the start should be one
command, so the person spends attention on the work instead of on terminals.

## Done when (automated)

- [ ] `./sprint.sh crew up plan:N` starts the lead on plan N, waits for the
  plan's `## Crew` board to carry an `Active:` line, then starts each member it
  names, each in its own tmux window of one session named after the plan, each
  running `./sprint.sh crew <name>`. Proven by `bash docs/tests/test-crew-up.sh`
  (tmux and the AI CLI stubbed)
- [ ] It prints how to watch and leave (`tmux attach -t <session>`, the window
  per member) and, as its last line, the next command. Proven by
  `bash docs/tests/test-crew-up.sh`
- [ ] A member added to `Active:` later is started on the next `crew up
  plan:N`; a member already running is left alone. Proven by
  `bash docs/tests/test-crew-up.sh`
- [ ] Without tmux, or inside an AI session, it prints the per-member commands
  to run by hand and exits 0. Proven by `bash docs/tests/test-crew-up.sh`
- [ ] `help/_registry`, `help/crew.md`, DOCUMENTATION.md and the command matrix
  name `crew up`; `./sprint.sh validate --commands` passes.

## Signoff (human)

- [ ] On heavymetal, `./sprint.sh crew up plan:<N>` opens the lead and the
  Active members, and the members message each other by name while the plan
  runs.

## Notes

- Decided: tmux, because the crew guide already runs a crew on a server this
  way and it is on every Mac and Linux box a developer uses.
- Decided: `up` is a `crew` subcommand, not a new command, because fewer
  commands cost less context.
- Origin: the heavymetal plan 69 crew experiment (2026-10-12), started by
  hand in four terminals.

## References

docs/sprintbias/scripts/crew.sh
docs/sprintbias/help/crew.md
docs/sprintbias/guides/crew.md (server section)

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
