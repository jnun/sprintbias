# Task 456: Fast work and crew leave person-only tasks in next/ alone

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
**Tests**: docs/tests/test-person-only.sh
**Refined**: 0
**Reworked**: 0

## Problem

Before starting a fast crew on heavymetal plan 69, the person had to move five
tasks out of next/ by hand: App Store Connect listings (1478, 1479), approving
public copy (1620), turning on DPoP in production (1648) and a plan 48 device
sign-off (1735). Each one only a person can do, and none carries **Owner**:
human, so fast `work` or an idle crew member would pick them up. `work` never
reads **Owner**. A fast swarm needs next/ to hold only work an agent can do.

## Done when (automated)

- [ ] `work`, `work plan N` and crew members skip a next/ task whose **Owner** is
  `human`, and list it once at the end of the run as yours, with the command to
  close it. Proven by `bash docs/tests/test-person-only.sh`
- [ ] The gate grades a task whose whole job needs the person's access or
  judgment (store listings, production switches, approvals, device sign-off)
  as cannot start for agents: it sets **Owner**: human and leaves it out of
  next/, with the reason in one line. Proven by
  `bash docs/tests/test-person-only.sh` (prompt text check)
- [ ] `./sprint.sh status` shows person-only tasks under their own line, not in
  the sprint count. Proven by `bash docs/tests/test-person-only.sh`
- [ ] Help for `work` and `crew` names the rule; `./sprint.sh validate --docs`
  passes.

## Signoff (human)

- [ ] On heavymetal, put 1478 and 1735 back in next/ with **Owner**: human,
  run `./sprint.sh --fast work --dry-run`: neither is picked.

## Notes

- Decided: **Owner**: human is the one marker, because human tests already use
  it and one field beats a list of keywords.
- Decided: the tasks stay visible (status, end-of-run list), because hiding
  person work is how it gets forgotten.
- Origin: heavymetal plan 69 crew run, 2026-10-12.

## References

docs/sprintbias/scripts/work.sh
docs/sprintbias/scripts/crew.sh
docs/sprintbias/lib.sh (gate)

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
