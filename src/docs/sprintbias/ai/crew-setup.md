# Crew Setup

Build the smallest crew that gives every lane of work exactly one owner. A lane
is a kind of work with its own files or powers (a codebase, the database,
production), never a single task. The recommended shapes are in
docs/sprintbias/guides/crew.md → Recommended crews; start from the closest one.

1. **Read first.** The project map, the instruction file, `./sprint.sh crew`
   (members that already exist), and the open plans in docs/plans/. Name the
   lanes you see: codebases, shared contracts, migrations, deploys.
2. **Ask at most three questions, one at a time,** each with your recommended
   answer: which lanes run in parallel, who deploys to production, and whether
   the crew runs on this machine or a shared server. Skip any the project
   already answers.
3. **Propose one crew** as a table: name, lead (yes/no), role, May touch. Lead
   with your pick and one line on why; name a smaller alternative when it is
   close. Two to four members. A solo lane with a clear queue needs no crew:
   recommend `./sprint.sh work` instead and stop.
4. **Build it on a yes.** Run `./sprint.sh crew add <name> "<role>" [--lead]`
   for each new member; members that exist get edits, not re-creation. Then
   fill each file: Job (2-4 sentences on its lane), Reads first (the lane's
   docs and code roots), May touch (folders, powers, and who owns anything
   shared), Reports. The lead's sections arrive filled; add the project's docs
   to its Reads first. Keep every file short: members read it each session.
5. **Hand off** with the start commands: the lead on a plan
   (`./sprint.sh crew <lead> plan:N`), then one terminal per member
   (`./sprint.sh crew <name>`).

Ownership rules every crew follows: one owner per kind of work; a shared file
(an API contract, a schema) has one named owner and the others read it and ask;
only one member, or none, holds production credentials. Draw lanes so the
plan's tasks split into disjoint **Touching:** sets: tasks that would touch the
same files go to one member or run in order through Depends on, lower id first.

How the crew runs, so the files you fill support it: the lead routes each task
the moment its prerequisites land (review/ with a **Proof**: line), keeps every
member's next task queued on the plan's ## Crew board, and closes the plan when
`./sprint.sh plan check N` reads LANDED by running the full suite once and
handing the human one sign-off, `./sprint.sh promote plan:N`. Members report
each landing to the lead with the task id and its proof line.

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
- Prefer two or three members; each one coordinates through files.
- A member may spawn subagents one level deep; those children do the work and
  spawn none of their own. The lead may give the plan-close suite run to one.

## Other CLIs

- Treat the plan's ## Crew board as the only channel, as for Grok Build: members
  write each landing there and the lead re-reads it. Keep the crew to two or
  three members.
