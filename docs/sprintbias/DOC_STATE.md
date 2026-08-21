# SprintBias Documentation State

Part of the SprintBias documentation system, not source code for the host project.
Managed by scripts in `docs/sprintbias/scripts/` and by `setup.sh`. Safe to edit by hand
if you need to fix a counter — the field lines below are what scripts parse.

Fields:
- `sprint_VERSION`   — installed product version (from `src/VERSION` via setup/ship)
- `sprint_TASK_ID`   — highest task ID used; next task = this + 1
- `sprint_BUG_ID`    — highest bug ID used; next bug = this + 1
- `sprint_PLAN_ID`   — highest plan ID used; next plan = this + 1
- `Last Updated`   — ISO date; bump when you change a field

---

**Last Updated**: 2026-08-21
**sprint_VERSION**: 0.0.3
**sprint_TASK_ID**: 375
**sprint_BUG_ID**: 3
**sprint_PLAN_ID**: 23
