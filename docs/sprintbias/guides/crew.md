# Running a Crew

A crew is several AI sessions working one project at the same time, each with a
name and a job. One of them leads. This guide covers setting one up, how the
members stay out of each other's way, and running the whole crew on a shared dev
server. The command reference is `./sprint.sh help crew`; to watch one run,
`./sprint.sh crew --demo`. To watch a crew fix one bug across two codebases,
play the three parts in order: `./sprint.sh learn teamwork` (claim and share),
`learn team-landing` (land, route, reject), `learn team-signoff` (one sign-off).

## When to use a crew

Situation																		Use
One task, or a queue of clear tasks												./sprint.sh work, or loop for autopilot
Several kinds of work at once that you want to steer							a crew
Work that needs different powers (production access, the database, the build)	a crew, one member per power
A big problem that spans many tasks and needs one plan held in mind				a crew with a lead

A crew costs one AI session per member. Two to four members is the usual size.

## Recommended crews

Build the smallest crew that gives every lane one owner. A lane is a kind of
work with its own files or powers (a codebase, the database, production), never
a single task. Not sure? `./sprint.sh crew setup` reads the project, asks up to
three questions, proposes one of these, and fills the member files.

Project shape										Crew (lead first)			Who owns what
One codebase, a clear queue							none						./sprint.sh work, or loop
One codebase, work you want to steer				lead, builder, checker		builder: product code; checker: runs tests, polishes review/, files bugs
Two codebases sharing a contract (API + app)		lead, api, app				each its own codebase; the contract has one owner (usually api)
Any of these, plus production you deploy			add ops						ops: the only member with production credentials
A bug backlog to burn down							lead, fixer-a, fixer-b		split May touch by folder so fixers never meet

The lead's file arrives filled in from `crew add <name> "<role>" --lead`. A
member's file arrives with Reports filled in; you write its Job and May touch.

## Quick start

Step				Command
Guided build		./sprint.sh crew setup (proposes a crew and does the steps below)
Add the lead		./sprint.sh crew add orcha "Keeps everyone rowing: holds the plan, routes tasks" --lead
Add members			./sprint.sh crew add dill "Finds and fixes bugs"
Fill in each file	edit docs/crew/<name>.md: Job, Reads first, May touch, Reports
Start the lead		./sprint.sh crew orcha plan:5 (in its own terminal; assigns plan 5 to orcha)
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
Take a plan				crew <lead> plan:N assigns it (the plan's **Crew** field; one plan per lead) and hands the lead its tasks in waves from their Depends on lines
Split for parallel work	Tasks that run at once need disjoint **Touching:** sets. Overlapping tasks go to one member, or run in order through Depends on, lower id first
Hold the central idea	Writes the approach in the plan file under ## Crew
Route work				Sets each task's Crew field to the member whose role fits, then messages them. Routes all of wave 1 at once
Route on landing		When a member reports a landing, checks the **Proof**: line (plan check shows it landed) and routes the tasks it releases in that same turn. Landed releases; done/ is never the wait
Keep everyone busy		Every member has a task now and one queued next on the board. A blocked member hands the blocker to its owner and starts its next
Trace unsigned work		Marks each released task "built on #N (landed)", so a rejection of #N shows everything it affects
Close the plan			When ./sprint.sh plan check N reads LANDED, runs the full suite once or delegates it, routes each fix task to the member who built the original, then hands the human one sign-off: ./sprint.sh promote plan:N
Escalate				Raises decisions for the human one at a time. The sign-off approval is always the human's

A ## Crew board in a plan file looks like this:

```markdown
## Crew

Approach: fix duplicate detection in the importer first, then the dashboard
count, so the count reads the fixed data. One owner per file.

- dill — #412 landed; now #415 (built on #412 (landed)); next #418
- devops — #413 working (Touching: migrations/); next #416
- cloudy — #414 next, built on #412 (landed) and #413 when it lands
```

### Closing a plan

1. ./sprint.sh plan check N reads LANDED: every member is in review/ with a proof line.
2. The lead runs the full suite once, or has a member run it.
   ./sprint.sh promote plan:N </dev/null runs the project's TEST_SUITE, files a
   fix task per failure, and with no answer moves nothing.
3. Each fix task goes to the member who built the original. A rejection found by
   reading (./sprint.sh promote --reject <id> "report") works the same way. The
   board's "built on" marks show which landed tasks to re-check.
4. When the fixes land and the suite is green, the lead hands the human one
   command: ./sprint.sh promote plan:N. The human answers its approval and the
   whole plan moves to done/.

## Claiming and collisions

Rule																Why it holds
A task's Crew field routes it										The lead sets it; ./sprint.sh crew shows it
Moving a task into doing/ with Crew set to your name is the claim	A file move is atomic, so two members cannot both win
A task in doing/ held by someone else is theirs						Ask the lead instead of taking it
New tasks come from ./sprint.sh newtask only						It locks the ID counter, so parallel members never draw the same ID
Each kind of work has one owner										Set in May touch; the main defense against two sessions editing one file
A member announces its task and **Touching:** files when it starts		Others check those lines before editing; on shared code the lower task id owns it
A member reports each landing: a message to the lead and the proof line in the file	The file is the record, so a restarted session loses no state
Claude Code refuses to save a file changed since it was read		A second writer re-reads and retries instead of overwriting

In fast mode (./sprint.sh fast on) holds and lanes bend so work keeps moving:

Fast rule															Why it holds
A stalled hold can be taken over									Message the holder first; when ./sprint.sh agents shows no live session for it, set Crew to your name and continue
A takeover leaves one line on the plan's ## Crew board				Who took what from whom, and why, so the lead and the holder see it
May touch is a routing preference									Work your lane first; pick up an idle or stalled lane's work rather than wait
The lead builds too												It takes a task when a lane is idle; it asks the human only goal questions
Touching lines, never reverting others, and promote plan:N stay		The same collision rules and the human's sign-off hold in fast mode

## Messages between members

When the AI CLI can message other sessions (Claude Code: ListAgents, then
SendMessage), members reach each other by crew name, because each session
starts under its member name. Messages are for nudges and questions. Anything
that must last goes in a task file or the plan's ## Crew board, so a member
that restarts reads its state from disk. A landing is reported both ways: the
proof line in the task file, then one message to the lead with the task id and
that line. Without messaging (Grok Build), the member writes the landing on
the ## Crew board and the lead re-reads the board each turn.

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
Ongoing		Members land tasks in review/ with proof; the lead routes what each landing releases
Plan close	The lead runs the suite and hands you ./sprint.sh promote plan:N. You approve once, commit, and push
Next day	Start fresh sessions. The board and task files carry the state, not the chat history

## Troubleshooting

Symptom														Fix
crew <name> printed a prompt instead of opening a session	You ran it inside an AI session. Run it from a plain terminal
A member cannot find another by name						Check the session list (ListAgents in Claude Code); restart the missing member with crew <name>
Two members edited the same file							Tighten May touch in their files; have the lead order the work
A member forgot what it was doing							Point it at its task file and the plan's ## Crew board
A member sits idle											The lead queues its next task on the ## Crew board; a blocked member hands off and takes that next task
Members on the server do not show up locally				Sessions are per machine. List and message them from the server
