# Crew Setup

Build the smallest crew that gives every lane of work exactly one owner. A lane
is a kind of work with its own files or powers (a codebase, the database,
production) or a pass over landed work (stress, security), never a single task.
Member files are cheap and sessions are not: write a file for every lane, and
run only the members a plan needs. The recommended shapes are in
docs/sprintbias/guides/crew.md → Recommended crews; start from the closest one.

1. **Read first.** The project map, the instruction file, `./sprint.sh crew`
   (members that already exist), and the open plans in docs/plans/. Name the
   lanes you see: codebases, shared contracts, migrations, deploys, and the
   passes the project needs. Name its invariants too, the rules every change
   keeps (tenant isolation, money that balances, records never edited), and
   find the document that holds them: the map's **Invariants:** line, or its
   sources of truth.
2. **Ask at most three questions, one at a time,** each with your recommended
   answer: which lanes run in parallel, who deploys to production, and where
   each lane runs (this machine, a shared server, or the machine it needs, such
   as a Mac for iOS). Skip any the project already answers.
3. **Propose one crew** as a table: name, lead (yes/no), role, May touch. Lead
   with your pick and one line on why. Then name the active set for the first
   open plan: the members it needs running, about four to six per lead, or
   fewer where your CLI's notes below say so. A solo lane with a clear queue
   needs no crew: recommend `./sprint.sh work` instead and stop.
4. **Build it on a yes.** Run `./sprint.sh crew add <name> "<role>" [--lead]`
   for each new member; members that exist get edits, not re-creation. Then
   fill each file: Job (2-4 sentences on its lane), Reads first (the lane's
   docs and code roots, plus the invariants document), May touch (folders,
   powers, and who owns anything shared), Reports. The lead's sections arrive
   filled; add the project's docs to its Reads first. Keep every file short:
   members read it each session. When no document holds the invariants, file
   one task to write them down (`./sprint.sh newtask "Write down the project's
   invariants"`) and list them in the lead's Job until it lands. The map's
   ## Known edges stays the record of cases that broke; rules live in their
   own document.
5. **Hand off** with the start commands: the lead on a plan
   (`./sprint.sh crew <lead> plan:N`), then one terminal per member of the
   active set (`./sprint.sh crew <name>`).

Ownership rules every crew follows: one owner per kind of work; a shared file
(an API contract, a schema) has one named owner and the others read it and ask;
only one member, or none, holds production credentials. Draw lanes so the
plan's tasks split into disjoint **Touching:** sets: tasks that would touch the
same files go to one member or run in order through Depends on, lower id first.
A pass member's Job names its command (`polish --break` for stress and edge
cases, `polish --code` for security) and its lanes; its May touch is review/
work in those lanes, and the fix tasks it files go back to the builder.

How the crew runs, so the files you fill support it: the lead writes the
active set on the plan's ## Crew board, routes each task the moment its
prerequisites land (review/ with a **Proof**: line), sends each landing to its
pass owners before plan close, keeps every member's next task queued on the
board, and gives a task no member's May touch covers a new member. It closes
the plan when `./sprint.sh plan check N` reads LANDED by running the full suite
once and handing the human one sign-off, `./sprint.sh promote plan:N`. Members
report each landing to the lead with the task id and its proof line.

## Claude Code

**Tuned**: 2026-10-08

- Sessions start under their member names, and members message each other with
  ListAgents, then SendMessage. The lead routes by setting **Crew** and sending
  one message; a member reports each landing the same way (task id and proof
  line), and the lead routes what it releases in that turn.
- The proof line in the task file is the record; the message is the nudge. A
  restarted session reads its state from the files and the ## Crew board.
- Three or four members run comfortably on one machine. A member may use
  subagents for parallel work inside its own lane; the lead may hand the
  plan-close suite run to a subagent or a member.
- Give the lead the strongest model available; members do well on the default.

## Grok Build

**Tuned**: 2026-10-08

- Sessions cannot message each other, so the plan's ## Crew board is the
  channel. Add to each member's Reports: "write each landing (task id and proof
  line) on the plan's ## Crew board; re-read the board and ./sprint.sh crew at
  the start and after each task." Add to the lead's Reports: "re-read the board
  and ./sprint.sh plan check N each turn, then route what landed."
- The lead writes every routing decision, each member's queued next task and
  each "built on #N (landed)" mark on the board, since members learn their
  work only from it.
- Run two or three members at once; each one coordinates through files.
- A member may spawn subagents one level deep; those children do the work and
  spawn none of their own. The lead may give the plan-close suite run to one.

## Other CLIs

- Treat the plan's ## Crew board as the only channel, as for Grok Build: members
  write each landing there and the lead re-reads it. Run two or three
  members at once.
