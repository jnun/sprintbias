# Running a Crew

A crew is several AI sessions working one project at the same time, each with a
name and a job. One of them leads. This guide covers setting one up, how the
members stay out of each other's way, and running the whole crew on a shared dev
server. The command reference is `./sprint.sh help crew`; to watch one run,
`./sprint.sh crew --demo`.

## When to use a crew

Situation																		Use
One task, or a queue of clear tasks												./sprint.sh work, or loop for autopilot
Several kinds of work at once that you want to steer							a crew
Work that needs different powers (production access, the database, the build)	a crew, one member per power
A big problem that spans many tasks and needs one plan held in mind				a crew with a lead

A crew costs one AI session per member. Two to four members is the usual size.

## Quick start

Step				Command
Add the lead		./sprint.sh crew add orcha "Keeps everyone rowing: holds the plan, routes tasks" --lead
Add members			./sprint.sh crew add dill "Finds and fixes bugs"
Fill in each file	edit docs/crew/<name>.md: Job, Reads first, May touch, Reports
Start the lead		./sprint.sh crew orcha plan:5 (in its own terminal)
Start each member	./sprint.sh crew dill (one terminal each)
See who holds what	./sprint.sh crew

Run `crew <name>` from a plain terminal. Inside an AI session it prints the
member's startup prompt instead of opening a new session.

## An example crew

One real crew, used to ship a web API and a mobile app:

Name	Lead	Role																			May touch
orcha	yes		Orchestrator. Holds the plan and the central idea, routes tasks, unblocks		plan files, task routing; no product code
devops	no		Local builder. Builds and runs the stack, owns migrations and the dev database	build scripts, migrations, local services
cloudy	no		Cloud production ops. Deploys, backups, cloud resources							production; the only member with production credentials
dill	no		Diligent bug finder and fixer													product code and tests

Name members anything. What matters is that every kind of work has exactly one
owner, written in its file under May touch.

## The member file

Section		Holds
Role		One line. Shown by ./sprint.sh crew
Lead		yes for the one member that coordinates; no for the rest
Job			What the member is for, in two to four sentences
Reads first	Docs and files to read before working. One path per line
May touch	What it edits or runs, and what it hands to someone else
Reports		Where it records progress and who it tells. Default: the task file, then the lead

Keep files short. Each member reads its file at the start of every session.

## How the lead works

The lead is the coxswain: it keeps the crew rowing in time and thinks across
members instead of inside one task.

Duty					How
Hold the central idea	Writes the approach in the plan file under ## Crew
Route work				Sets each task's Crew field to the member whose role fits, then messages them
Prevent collisions		Spots two members heading for the same file and orders the work
Keep the board current	One line per member under ## Crew: tasks held, state
Escalate				Raises decisions for the human one at a time

A ## Crew board in a plan file looks like this:

```markdown
## Crew

Approach: fix duplicate detection in the importer first, then the dashboard
count, so the count reads the fixed data. One owner per file.

- dill — #412 working, #415 next
- devops — #413 migration in review
- cloudy — idle until #412 and #413 are in review, then deploys
```

## Claiming and collisions

Rule																Why it holds
A task's Crew field routes it										The lead sets it; ./sprint.sh crew shows it
Moving a task into doing/ with Crew set to your name is the claim	A file move is atomic, so two members cannot both win
A task in doing/ held by someone else is theirs						Ask the lead instead of taking it
New tasks come from ./sprint.sh newtask only						It locks the ID counter, so parallel members never draw the same ID
Each kind of work has one owner										Set in May touch; the main defense against two sessions editing one file
A member announces its task and **Touching:** files when it starts		Others check those lines before editing; on shared code the lower task id owns it
Claude Code refuses to save a file changed since it was read		A second writer re-reads and retries instead of overwriting

## Messages between members

When the AI CLI can message other sessions (Claude Code: ListAgents, then
SendMessage), members reach each other by crew name, because each session
starts under its member name. Messages are for nudges and questions. Anything
that must last goes in a task file or the plan's ## Crew board, so a member
that restarts reads its state from disk.

## A crew on a shared dev server

The fastest setup is one always-on machine where every member works in one
checkout on one branch. Branches push collaboration cost to merge time and hide
task moves made on another branch. One tree keeps SprintBias's state in one
place and lets every member see every change the moment it lands.

Piece		Setup
Machine		Any always-on Linux box with enough memory for your dev stack plus a few hundred MB per AI session
Checkout	One clone, one branch, in a fixed path. Every member starts there
Git access	A deploy key scoped to this one repo. The human commits and pushes
Sessions	One terminal multiplexer window per member (tmux), each running ./sprint.sh crew <name>
Reaching it	SSH from the laptop, forwarding the dev ports. Remote control apps reach sessions from a phone
Credentials	Give the box the narrowest role that works. Production credentials go only where the operator member runs, or nowhere

Shared resources need one rule each, written into the project's own docs:

Resource					Rule
Source files				Edit freely; ownership by May touch plus the stale-read check
Task IDs					./sprint.sh newtask only
Database migrations			One member owns them, or a locked wrapper script generates them so two never fork the chain
Shared dev database			Read and test freely; risky changes go to a scratch copy first
Dev server with auto-reload	An edit mid-test can restart it; retry a failed request once before debugging
git							The human commits from the box; members edit files and stop

Logging an AI CLI in on a box with no browser: start it in tmux, read the
wrapped login URL with tmux capture-pane -pJ, open it on the laptop, and type
the returned code back with tmux send-keys -l. If the laptop terminal is one the
server does not know (TERM errors, broken keys), install its terminfo once:
infocmp -x $TERM | ssh <box> tic -x -.

## A day with a crew

Time		Do
Start		Start the lead on the plan. It reads the board and routes the day's tasks
Morning		Start each member it routed work to. Each claims, works, and reports
Midday		Run ./sprint.sh crew to see who holds what; answer the lead's questions
End			Members move finished tasks to review/. You review, commit, and push
Next day	Start fresh sessions. The board and task files carry the state, not the chat history

## Troubleshooting

Symptom														Fix
crew <name> printed a prompt instead of opening a session	You ran it inside an AI session. Run it from a plain terminal
A member cannot find another by name						Check the session list (ListAgents in Claude Code); restart the missing member with crew <name>
Two members edited the same file							Tighten May touch in their files; have the lead order the work
A member forgot what it was doing							Point it at its task file and the plan's ## Crew board
Members on the server do not show up locally				Sessions are per machine. List and message them from the server
