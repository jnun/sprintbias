Continuous task runner — **autopilot spine**: plan start refill + work drain.

Wraps `work` to run one task at a time, each in a fresh CLI context.
Failures don't halt the run — tasks that land in blocked/ (need a decision
or clarification) are skipped and the loop continues to the next task.

Usage:
  ./sprint.sh loop                       # drain next/ via work
  ./sprint.sh loop --hours 2             # stop after 2 hours
  ./sprint.sh loop --max 10              # stop after 10 tasks
  ./sprint.sh loop --cooldown 30         # 30s pause between tasks
  ./sprint.sh loop --refill              # plan start next READY plan, then work, when next/ empties
  ./sprint.sh loop --retry               # retry tasks that landed in blocked/ this run (once)
  ./sprint.sh loop --refill --retry      # full autopilot
  ./sprint.sh loop --model <id>          # pin the model for the whole run (see ./sprint.sh model)

--model pins every AI leg of the loop — the refill gate, the retry gate, and
the work drain — for this run only (it does not rewrite config).
Other flags (--audit, --drift, --fast, etc.) are forwarded to work.

How it improves on a single `work` pass:
  - Fresh context window per task (no context pollution)
  - Failures don't stop the run
  - Recovers orphaned tasks from doing/ (interrupted runs)
  - Smart retry: re-queues tasks that landed in blocked/ during THIS run (once)
  - Auto-refill: plan start on the next READY plan, then work (no auto-planner) —
    plan start gates members as it promotes them, so no separate gate step on the spine
  - Active plan goal exported as SPRINTBIAS_ACTIVE_PLAN_GOAL for run context
  - Time-boxed execution with --hours
  - Cooldown between tasks to pace API usage

Provider for this run only (leading flags; does not rewrite config):
  ./sprint.sh -g loop --refill       # Grok Build
  ./sprint.sh -c loop --hours 2      # Claude Code

Composable with Claude Code's /loop (or equivalent) for crash recovery:
  /loop ./sprint.sh loop --hours 2
