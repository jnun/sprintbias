# Task 468: work and crew run on Linux bash 5

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
**Tests**: docs/tests/test-fast.sh
**Refined**: 0
**Reworked**: 0

## Problem

Asked whether SprintBias works on Linux, the suite was run in a Debian container (bash 5.2) for the first time: 31 checks across five scripts failed. Every `work` prompt stopped with `lib.sh: line 697: 1: unbound variable`, because sprintbias_parallel_rule read `$1` with no argument; macOS's bash 3.2 lets that pass under `set -u`, bash 5 does not. A crew on a Linux dev server would have failed on its first task. setup.sh also had two `sed -i ''` lines (macOS-only) on a fallback path.

## Done when (automated)

- [x] sprintbias_parallel_rule takes no argument safely (`${1:-}`); `work` emits its prompt on bash 5. Proven by the Debian run of `bash docs/tests/run-all.sh` (37 of 37 after the zsh guard) and `bash docs/tests/test-fast.sh` on macOS
- [x] setup.sh's fallback config edits use a portable sed-to-temp-file-and-move instead of `sed -i ''`.
- [x] test-shell.sh skips the real-shell load check for a shell the machine lacks, as its other zsh checks already do. Proven by `bash docs/tests/test-shell.sh` on Debian (42 of 42) and macOS (48 of 48)
- [x] docs/guides/running-tests.md shows the one-command Debian run to do before a release.

## Signoff (human)

- [ ] Run a crew or `work` on the Linux dev box (heavymetal's EC2) and see the first task build.

## Notes

- Decided: test Linux in a throwaway Debian container on a copy of the repo, because it needs no Linux machine and never touches the working tree.

## References

docs/sprintbias/lib.sh
setup.sh
docs/tests/test-shell.sh
docs/guides/running-tests.md

## Completed

**Summary**: work and crew run on Linux bash 5 again; an unset argument that only macOS's bash forgave stopped every work prompt.

Fixed in place during the heavymetal plan 69 crew run (2026-10-12), then filed so the record matches the code.

**Proof**: 2026-10-12 · docker debian:bookworm-slim bash docs/tests/run-all.sh; bash docs/tests/run-all.sh · pass

### Files changed
docs/sprintbias/lib.sh
setup.sh
docs/tests/test-shell.sh
docs/guides/running-tests.md

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
