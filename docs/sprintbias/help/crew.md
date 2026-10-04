Crew — run several named AI sessions on one project, each with a role.

A member is a file, docs/crew/<name>.md: its role, what it reads first,
what it may touch, and how it reports. One member is the lead
(**Lead**: yes). The lead holds the plan, routes tasks to members by
setting their **Crew** field, and keeps a ## Crew section in the plan
file current. Members claim a task by moving it into doing/ and setting
**Crew** to their own name.

Usage:
  ./sprint.sh crew                          list members and the tasks each holds (no AI)
  ./sprint.sh crew add <name> "<role>"      add a member from docs/crew/.TEMPLATE-crew.md
  ./sprint.sh crew add <name> "<role>" --lead   add the lead
  ./sprint.sh crew <name>                   start a session as that member
  ./sprint.sh crew <name> 42                start it on task 42
  ./sprint.sh crew <name> plan:5            start it on plan 5 (the usual start for a lead)

Names use lowercase letters, digits and dashes. The session is named
after the member, so other sessions can message it by that name when
the AI CLI supports messaging between sessions.

How do I:
  set up a crew           add a lead with --lead, then one member per kind of
                          work; fill in May touch so each kind has one owner
  start the day           ./sprint.sh crew <lead> plan:N in one terminal, then
                          crew <name> for each member it routes work to
  hand a task to someone  set the task's **Crew** field to their name (the
                          lead does this) and tell them
  see who holds what      ./sprint.sh crew
  take a task             move it into doing/ and set **Crew** to your name;
                          a task in doing/ held by someone else is theirs
  run a crew on a server  one checkout, one branch, one tmux window per member;
                          see the guide below

Start each member in its own plain terminal; inside an AI session the
command prints the member's prompt instead of opening a session. Files are
the shared state; messages are only the nudge. The human approves, commits
and ships.

Guide: docs/sprintbias/guides/crew.md
