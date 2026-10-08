<div align="center">

<img src="https://github.com/jnun/sprintbias/releases/download/demo-assets/sprint-md-logo.gif" alt="SprintBias" width="720">

# Plans live in git.

### Folders are status. Markdown is the work. History is free.

**One board your agents and your team can both see.**  
No database. No SaaS. No login.

**[sprintbias.com](https://sprintbias.com)** · **[GitHub](https://github.com/jnun/sprintbias)**

[![License: MIT](https://img.shields.io/badge/License-MIT-black.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.0.134-blue.svg)](https://github.com/jnun/sprintbias/releases)
![AI: Claude · Grok](https://img.shields.io/badge/AI-Claude%20%C2%B7%20Grok-8A2BE2.svg)

</div>

## Get it

```bash
git clone git@github.com:jnun/sprintbias.git
cd sprintbias
./setup.sh ~/code/my-app     # your project path
```

One question — **Enter** for Claude Code, **`g`** for Grok Build — and the board
is in **your project**. Your own files are left in place.

**Needs:** bash, git, and Claude Code or Grok Build (python3 optional).
Walkthrough: **[GETSTARTED.md](GETSTARTED.md)**.

---

## Try it

Twenty seconds. Capture, sharpen, work it to `review/` — then `git status` shows the change.

```bash
./sprint.sh learn example                   # theater — touches nothing
```

<img src="https://github.com/jnun/sprintbias/releases/download/demo-assets/example.gif" alt="Twenty seconds: newtask, chat, work, git status shows the change" width="720">

Then, in your project:

```bash
./sprint.sh profile                         # once — teach the AI your stack
./sprint.sh newtask "Reject empty password on login"
./sprint.sh chat 42                         # sharpen until it's clear
./sprint.sh work 42                         # gate it, then build it
git status                                  # the change is a git change
./sprint.sh promote                         # Tests pass → done/
```

That’s the whole loop: capture work, see it, ship it.

Then scale up — plans, autopilot, a crew of named sessions, either AI:

```bash
./sprint.sh newplan "Auth" 12 13 && ./sprint.sh plan start 5   # group → next/
./sprint.sh loop --refill --retry                              # autopilot
./sprint.sh crew lead plan:5                                   # one terminal per member
./sprint.sh agents                                             # every session, here and on servers
./sprint.sh -g work                                            # Grok Build (-c = Claude Code)
```

---

## Why it feels light

| What you get | How |
|--------------|-----|
| Work that lasts past one chat | Plain files in the repo |
| One board for agents and humans | Same folders, same markdown |
| Status you can see in `git status` | Move a file = change state |
| Easy exit | Remove the tool — the work stays in git |

- **Folder = status** — `git mv docs/tasks/doing/… docs/tasks/review/` *is* the state change  
- **Agents already speak this** — markdown and paths, no API, no login  
- **Yours to keep** — delete `sprint.sh` anytime; tasks, plans, and history remain  

> Session tools help *inside* a chat. **SprintBias is how the work stays when the chat ends.**

---

## The board (the whole model)

```text
docs/tasks/backlog/   Planned, not started
docs/tasks/next/      Queued for the current sprint
docs/tasks/doing/     In progress
docs/tasks/blocked/   Needs a decision
docs/tasks/review/    Done, awaiting approval
docs/tasks/done/      Shipped
```

The sprint is whatever sits in `next/` right now. No special file — the folder *is* the sprint.

---

## Live here

This repository **runs on SprintBias**. Browse [`docs/tasks/`](docs/tasks/) for a real board.

**[GETSTARTED.md](GETSTARTED.md)** · full manual: **[DOCUMENTATION.md](DOCUMENTATION.md)**

---

## For AI agents

Read **[DOCUMENTATION.md](DOCUMENTATION.md)**. Create work with `./sprint.sh`, not by hand. Folder = status. Don’t edit `docs/sprintbias/`.

---

## Contributing

Issues and PRs welcome — **[CONTRIBUTING.md](CONTRIBUTING.md)**. If this helps your next session start where the last left off, a ⭐ helps someone else find it.

<div align="center">

*Plain folders and markdown. Start with an idea, end with a test.*

MIT © [Jason Nunnelley](https://github.com/jnun)

</div>
