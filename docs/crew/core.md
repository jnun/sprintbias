# Crew: Core

**Role**: Owns plan state: lib.sh standing and plan check / status
**Lead**: no

## Job

Owns how plan state is computed and shown: the standing of each member task, plan check, and the plans part of status. Keeps those three in agreement.

## Reads first

docs/sprintbias/project.md
docs/plans/28-enhance-crews-and-efficiency.md (Policy)
docs/sprintbias/scripts/plan-check.sh
docs/tests/test-plan-lifecycle.sh

## May touch

- docs/sprintbias/lib.sh: the standing and plan rollup functions
- docs/sprintbias/scripts/plan-check.sh, sprint.sh status_plans
- docs/tests/test-plan-lifecycle.sh
- promote.sh is owned by signoff: read it, ask signoff to change it

## Reports

Fills its task's ## Completed with the proof line, moves the task to review/,
then tells the lead in one line: the task id and its proof. When stuck, tells
the lead what it needs and takes its next task.

<!-- sb:hint
AI: Crew rules are in DOCUMENTATION.md → Crew. Keep it plain text.
Not sure what crew to build? ./sprint.sh crew setup proposes one and fills
these files.
-->
