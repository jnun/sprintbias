Crew — run several named AI sessions on one project, each with a role.

A member is a file, docs/crew/<name>.md: its role, what it reads first,
what it may touch, and how it reports. One member is the lead
(**Lead**: yes). The lead holds the plan, routes tasks to members by
setting their **Crew** field, and keeps a ## Crew section in the plan
file current. Members claim a task by moving it into doing/ and setting
**Crew** to their own name, and report each landing (review/ with a proof
line) to the lead, who routes what it releases in the same turn. At plan
close the lead runs the suite and hands you one sign-off: promote plan:N.

Usage:
  ./sprint.sh crew                          list members and the tasks each holds (no AI)
  ./sprint.sh crew setup                    guided build: an AI session proposes a crew and fills the files
  ./sprint.sh crew add <name> "<role>"      add a member from docs/crew/.TEMPLATE-crew.md
  ./sprint.sh crew add <name> "<role>" --lead   add the lead (its file arrives filled in)
  ./sprint.sh crew <name>                   start a session as that member
  ./sprint.sh crew <name> 42                start it on task 42
  ./sprint.sh crew <name> plan:5            start it on plan 5; for a lead this assigns the
                                            plan and lays its tasks out in parallel waves

Names use lowercase letters, digits and dashes. The session is named
after the member, so other sessions can message it by that name when
the AI CLI supports messaging between sessions.

How do I:
  set up a crew           ./sprint.sh crew setup, or by hand: a lead with --lead,
                          then one member per lane (a kind of work with its own
                          files or powers, or a pass such as security); fill in
                          Job and May touch so each lane has one owner. Shapes:
                          guide → Recommended crews
  start the day           ./sprint.sh crew <lead> plan:N in one terminal, then
                          crew <name> for each member on the board's Active:
                          line; later, crew <lead> alone resumes its plan (one
                          plan per lead)
                          (plan:N, plan N, or a bare N when no task N exists)
  hand a task to someone  set the task's **Crew** field to their name (the
                          lead does this) and tell them
  see who holds what      ./sprint.sh crew (tasks) or ./sprint.sh agents (sessions)
  take a task             move it into doing/, set **Crew** to your name, and list
                          your files as **Touching:** in its ## Grounding; a task
                          in doing/ held by someone else is theirs
  take over a stalled task  fast mode only: message the holder; when ./sprint.sh
                          agents shows no live session for it, set **Crew** to
                          your name and add one takeover line to the plan's
                          ## Crew board (who took what from whom, and why)
  finish a task           land it: proof line under ## Completed, move it to
                          review/, then tell the lead the task id and proof (or
                          write it on the plan's ## Crew board); take your next
  close a plan            when ./sprint.sh plan check N reads LANDED, the lead
                          runs the full suite and routes fixes; you sign off
                          the whole plan with ./sprint.sh promote plan:N
  run agents, no crew     ./sprint.sh work N in each terminal (work 12, work 15);
                          the same doing/ claim and Touching lines keep them apart
  run a crew on a server  one clone on one branch in a fixed path; one tmux window
                          per member running ./sprint.sh crew <name>; on your
                          laptop, add the server's ssh alias to AGENT_HOSTS in
                          docs/sprintbias/config.local so agents lists them; the
                          human commits and pushes from the server

With fast on (./sprint.sh fast on), May touch is a routing preference: a
member works its lane first and picks up an idle or stalled lane's work.
The lead builds too and asks you only goal questions. Promote plan:N stays
your sign-off.

Start each member in its own plain terminal; inside an AI session the
command prints the member's prompt instead of opening a session. Files are
the shared state; messages are only the nudge. The human approves, commits
and ships.

Guide: docs/sprintbias/guides/crew.md
Watch a crew share one fix across two codebases, in three parts:
./sprint.sh learn teamwork, then team-landing, then team-signoff
