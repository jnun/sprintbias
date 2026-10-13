# Task 470: Crew runs tests on a shared Simulator, database or port one at a time

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

On heavymetal plan 69, five iOS test runs started between 16:07 and 16:11 against one booted Simulator and one DerivedData folder. They killed each other's test app ("Test crashed with signal kill before establishing connection", one result bundle left corrupt), and xcodebuild then spent up to ten minutes in `simctl diagnose` collecting crash logs. The crew split work by files (Touching) but treated the Simulator as free for everyone: the iOS builder, the gate runner and the review passes.

## Done when (automated)

- [x] The crew rules say a shared runtime resource (the iOS Simulator and its build folder, a dev database, a server port) serves one test run at a time, and a member checks for a running one (pgrep xcodebuild for the Simulator) and waits. Proven by `bash docs/tests/test-crew.sh`
- [x] The lead treats shared runtime resources as touched: builds, passes and reviewers that test against the same one run one after another. Proven by `bash docs/tests/test-crew.sh`

## Signoff (human)

- [ ] On the next crew plan with iOS work, no two xcodebuild test runs overlap, and no test fails with "signal kill before establishing connection".

## Notes

- Decided: one run at a time on a shared resource, because a clone per agent (simctl clone plus its own derivedDataPath) needs project script support; a follow-up can add it where a project's test script takes a destination.
- Not a permissions problem: 464 tests ran in the 16:07 bundle; macOS permission prompts stop a launch outright rather than killing a running test.

## References

docs/sprintbias/scripts/crew.sh
docs/tests/test-crew.sh

## Completed

**Summary**: Crew members and the lead now run tests on a shared Simulator, dev database or port one at a time, so parallel work stops killing each other's test runs.

Fixed in place during the heavymetal plan 69 crew run (2026-10-12), then filed so the record matches the code.

**Proof**: 2026-10-12 · bash docs/tests/test-crew.sh · pass

### Files changed
docs/sprintbias/scripts/crew.sh
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
