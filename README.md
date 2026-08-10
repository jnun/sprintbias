<div align="center">

<img src="https://github.com/jnun/sprintbias/releases/download/demo-assets/sprint-md-logo.gif" alt="SprintBias" width="720">

# Plans live in git.

### Folders are status. Markdown is the work. History is free.

**One board your agents and your team can both see.**  
No database. No SaaS. No login.

**[sprintbias.com](https://sprintbias.com)** · **[GitHub](https://github.com/jnun/sprintbias)**

[![License: MIT](https://img.shields.io/badge/License-MIT-black.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.0.77-blue.svg)](https://github.com/jnun/sprintbias/releases)
![AI: Claude · Grok](https://img.shields.io/badge/AI-Claude%20%C2%B7%20Grok-8A2BE2.svg)

</div>

## Get it

```bash
git clone git@github.com:jnun/sprintbias.git
cd sprintbias
./setup.sh ~/code/my-app     # your project path
```

That puts the board into **your project** — not into this repo.

**Install is an Easy Button:** one door pick — **Enter** = Claude Code, **`g`** =
Grok Build — then a silent scaffold (docs, pointers, gitignore). Your own files
are not clobbered; optional GitHub Issues sync and extra AI dotfiles sit behind
`More options?`. Details: [DOCUMENTATION.md → Installing SprintBias](DOCUMENTATION.md#installing-sprintbias).

Then, from your project:

---

## Try it

```bash
./sprint.sh profile                         # once — teach the AI your stack
./sprint.sh newtask "Reject empty password on login"
./sprint.sh status                          # see the board
./sprint.sh work                            # do the next ready task
```

That’s the whole loop: capture work, see it, ship it.

Group related tasks when you’re ready (fast lane when ids are known):

```bash
./sprint.sh newplan "Auth" 12 13          # or: newplan "Auth" parent:12
./sprint.sh plan start <id>               # gate → next/
./sprint.sh work
# or keep going:
./sprint.sh loop --refill --retry
```

**Claude Code** (`-c`) and **Grok Build** (`-g`) are first-class:

```bash
./sprint.sh -g work
./sprint.sh -c chat 12
```

Maintainers: before a release, smoke both hosts with the
[dual-provider smoke protocol](docs/guides/dual-provider-smoke.md).

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
