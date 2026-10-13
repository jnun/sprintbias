Report a new bug in docs/bugs/ (open inbox).

Usage:
  ./sprint.sh newbug "Login fails on Safari"

Fill severity, problem, steps, and success criteria. When ready to schedule
the fix, run `./sprint.sh chat bugs` — it sorts each report: a clear defect
becomes a filled fix task, an unclear one becomes a task that waits on your
answer, and a fixed one is deleted. Clear fixes can skip the inbox:
`./sprint.sh newtask "Fix: …"`.
