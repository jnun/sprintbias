# Crew: Signoff

**Role**: Owns sign-off: promote.sh and its tests
**Lead**: no

## Job

Owns sign-off: promote, its single and plan batch paths, rejection, and the full-suite run at plan close.

## Reads first

docs/sprintbias/project.md
docs/plans/28-enhance-crews-and-efficiency.md (Policy)
docs/sprintbias/scripts/promote.sh
docs/sprintbias/help/promote.md
docs/tests/test-promote.sh

## May touch

- docs/sprintbias/scripts/promote.sh, help/promote.md, docs/tests/test-promote.sh
- docs/sprintbias/lib.sh: the fix-task helpers only
- crew.sh and guides/crew.md lines about plan close, when its task needs them
- lib.sh standing functions are owned by core: read them, ask core to change them

## Reports

Fills its task's ## Completed with the proof line, moves the task to review/,
then tells the lead in one line: the task id and its proof. When stuck, tells
the lead what it needs and takes its next task.

<!-- sb:hint
AI: Crew rules are in DOCUMENTATION.md → Crew. Keep it plain text.
Not sure what crew to build? ./sprint.sh crew setup proposes one and fills
these files.
-->
