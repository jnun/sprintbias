Show project status — task counts per folder, items in blocked/ that cannot
start (each with its `./sprint.sh chat <id>` line), work in doing/, items in review/ that
**require human review** (sign-off or promote), features, and bugs.

Plans are listed with each member's folder and standing, the computed plan
state (STARTED / LANDED / SIGNED OFF) and three counts: open
(backlog/next/doing/blocked), landed (review/ with a **Proof**: line), signed
off (done/). Members in review/ without proof, held originals (proof in
place, waiting on a `**Held**:` fix; shown `held: fix #N`) and open fix tasks
(`**Fixes**: #N`) are flagged. Nothing is stamped; folders stay the status.

`review/` is not blocked: implementation is done; close needs a human (or
`./sprint.sh promote` when **Tests** is set).

## Edge-case scorecard (`--edges`)

    ./sprint.sh status --edges [plan:N]

Read-only, no AI. How well the agents catch defects before you see the work:

- **Caught by agents** — the `**Breaker**: N cases tried · N fixed · N filed`
  lines on landed tasks (`review/` + `done/`), summed, with the `· $cost` each
  run adds.
- **Found by you (escaped)** — fix tasks carrying `**Fixes**: #N`, filed by
  `promote --reject` (a `review/` task, or a `done/` task found broken later)
  or by a human test's failures.
- Landed tasks split into **Breaker** vs **No breaker** columns, so the escape
  rate per 10 tasks with the breaker sits next to the rate without it.
- **Catch rate** = agent-found ÷ (agent-found + you-found), on checked work.
- **Escaped past the breaker** lists each such fix task: the cases to learn
  from. Report every defect you find through `promote --reject` so the count
  stays honest; each also becomes a `## Known edges` line in the project map.

`plan:N` limits it to plan N's tasks.

Usage:
  ./sprint.sh status
  ./sprint.sh status --edges [plan:N]
