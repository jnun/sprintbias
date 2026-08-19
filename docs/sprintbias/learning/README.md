# Authoring `learn` demos

This folder is SprintBias's **learning catalog** — short, cinematic, sandboxed
demos a brand-new user can *watch* to understand the flow.

## Using it

Watch a demo run in your own terminal — it's a real-world mockup of a command,
as if you were looking over someone's shoulder. Everything is theater: **a demo
touches nothing in your project** (no files, no network), so play freely.

```bash
./sprint.sh learn              # list every demo with a one-line summary
./sprint.sh learn example      # twenty seconds: newtask → chat → work → git status
./sprint.sh learn session      # play one by name
./sprint.sh <cmd> --demo       # play the demo mapped to a command, e.g. work --demo
```

Two ways in for a command: **`--help`** explains the flags and verdicts;
**`--demo`** plays the scenario so you can see it in motion. Pick either.

Flags pass straight through to the demo:

- **`--fast`** — skip the pauses, play at full speed.
- **`--no-color`** — plain text, no ANSI (also automatic when piped to a file).
- **`-h` / `--help`** — describe what that demo shows, then exit.
- **Ctrl-C** — stops cleanly at any point.

Start with `example` for twenty seconds (the change is a git change), `session`
for the whole flow with the why, or `learn` to browse the catalog.

## Authoring demos

The rest of this README is the house guide. Read it before adding a demo so the
catalog grows without rot — one voice, one look, one trust contract.

## Curriculum map

Each demo is a **person in a situation**, not a feature tour. The catalog has two
layers that stack:

1. **Spine stories** — multi-command journeys (capture → convert → plan →
   automate) that teach the flow end to end.
2. **Per-command scenarios** — one short vignette per user-facing command so a
   cold user can watch *that* command's real-world moment without reading docs
   (plan 18). Both layers honor the same trust contract and vocabulary.

### Spine stories

| Story | Lesson (one line)                                   | File              |
|-------|-----------------------------------------------------|-------------------|
| S0    | One problem, one session — start to finish          | `session.py`      |
| 20s   | newtask → chat → work → review/, then git status shows the change | `example.py` |
| S1    | The gate holds a vague task on purpose, then a chat sharpens it | `gate.py` |
| S2    | A bug report becomes a real, workable task          | `bug.py`          |
| S3    | A feature fans out to tasks → `plan think` → `plan start` | `feature-plan.py` |
| S5    | Independence is what makes parallel work safe       | `parallel.py`     |
| S6    | The momentum of the whole spine in one short run    | `speedrun.py`     |
| S7    | The whole board at a glance — every stage, plan, and hold, alive | `status.py` |
| S8    | One command drains the READY queue: next/ → review/, your pace | `work.py` |

### Per-command scenarios (play via `learn <name>` or `<cmd> --demo`)

| Command | Lesson (one line) | File |
|---------|-------------------|------|
| `newidea` | Capture a half-formed idea through eight phases | `newidea.py` |
| `newfeature` | Turn a product wish into a feature spec | `newfeature.py` |
| `newtask` | Capture an interrupting task in one line without breaking flow | `newtask.py` |
| `newplan` | Group known task IDs into a plan in one line | `newplan.py` |
| `newtest` | After deploy, capture a claim you can prove (gates promote) | `newtest.py` |
| `chat` | Talk an existing plan into shape: goal, order, READY | `chat.py` |
| `loop` | Unattended autopilot — refill, drain, gate still holds | `loop.py` |
| `split` | Break an oversized task; the graph stays whole | `split.py` |
| `polish` | A second look at review/ catches work that isn't done | `polish.py` |
| `promote` | Close only what's proven: Tests green + deps closed → done/ | `promote.py` |
| `search` | Find any task by keyword across the whole board | `search.py` |
| `learn` | Browse the catalog and play a sandboxed demo | `learn.py` |
| `align` | Spot feature gaps and orphan tasks before the next sprint | `align.py` |
| `context` | One dump of project state for an agent (or you) | `context.py` |
| `profile` | Capture project conventions so AI commands inherit them | `profile.py` |
| `sync` | Push task changes so GitHub issues stay in sync (theater) | `sync.py` |
| `validate` | Catch a broken task graph before work or promote | `validate.py` |
| `cleanup` | Dry-run first, then clear stale scratch files | `cleanup.py` |
| `deps` | Scan outdated/vulnerable deps; file one backlog task | `deps.py` |

Also mapped: `newbug` → `bug`, `plan` → `feature-plan`, `gate` → `gate`,
`status` → `status`, `work` → `work`. Spine rationale: `docs/plans/13-autolearning.md`.
Per-command coverage: `docs/plans/18-per-command-learn-demos.md`.

## Flat layout rule

Everything lives directly in this folder: `*.py` demos + this `README.md`. No
nested directories. Add a runtime dir (e.g. `js/`) only when a *second* runtime
actually exists — until then, flat keeps the catalog scannable at a glance.

## Auto-registration: docstring first line = catalog summary

There is **no manifest and no launcher edit** to register a demo. `learn.sh`
scans `learning/*.py`, and the **first non-empty line of each module's docstring**
becomes its one-line catalog summary. Drop a new `*.py` in and it appears in
`./sprint.sh learn` immediately.

So the top of every demo looks like this — first docstring line is the pitch:

```python
#!/usr/bin/env python3
"""
SprintBias — the gate holds a half-baked task, then a chat sharpens it.

Longer description for `-h/--help`… what the demo shows, the trust promise.

No dependencies. Just:  python3 gate.py
Flags:  --fast (no delays)   --no-color   -h/--help
"""
```

Keep that first line short and situational — it's what a new user reads when
choosing what to watch.

## Shared output vocabulary

Demos read as one system because they use the same presentation atoms. Match S0
(`session.py`) — same names, same colors, same rhythm:

- **`type_out`** — typewriter effect, char-by-char with tiny human jitter.
- **`spinner(label, done=…)`** — a working spinner that resolves to a verdict
  (`READY`, `BLOCKED`, `done`). Pass `tone`/`mark` to color a non-green outcome.
- **`prompt_and_type(cmd)`** — a shell prompt that pauses, then types a command.
- **`moved(a, b)`** — a lifecycle move, `next/57 → blocked/57`. Folders are status.
- **`beat(text)`** — the narrator aside between commands: the *why*, not the what.
- **`act(title, subtitle)`** — an act header with a rule beneath it.
- **`claude(text)` / `you(text)`** — the two sides of a chat session.
- **`ok` / `note` / `nextstep` / `held`** — SprintBias's fake response lines.

Reuse these names verbatim so every demo feels like the same tool talking.

## Flags and terminal behavior

Every demo honors the same controls — copy the flag block from S0:

- **`--fast`** — skip all pauses (used by tests and impatient viewers).
- **`--no-color`** — drop ANSI; also auto-dropped when stdout is not a TTY.
- **Non-TTY** — piping/redirecting degrades to plain text, no color.
- **Ctrl-C** — caught cleanly; print a dim `…demo interrupted.` and exit `130`.
- **`-h` / `--help`** — print the docstring and exit `0`.

## Trust contract

The whole point is *safe* theater. A demo must:

- **Write nothing.** No files created, no task files moved, no config touched.
- **Make no network calls.**
- **Use the Python 3 standard library only** — no `pip install`, ever. It must
  run identically in a brand-new empty install and here.

The banner states this promise to the viewer as the first thing they feel
("This demo touches nothing in your project."). Keep that line.

## Self-contained for v1

Each demo is **self-contained**: it carries its own copy of the vocabulary
helpers above. There is intentionally **no shared `_demokit.py`** yet. This
trades a little duplication for zero coupling — a demo is one file you can read
top to bottom, and the trust contract is verifiable per file.

Factor a shared kit **only** if duplication genuinely starts to hurt across the
full catalog. If we ever do, this README changes first to record the reversal.

Practical path for a new demo today: **copy the newest demo, keep the helper
block, rewrite the story.**

## The on-ramp pair: `--help` vs `--demo`

For a host-mapped command there are two ways in, and they do different jobs:

- **`--help` explains how the command works** — flags, verdicts, usage.
- **`--demo` plays a python scenario** — a common problem, showcasing that
  command's feature set as safe theater (never a live run against the user's
  project).

`learn` is the **catalog**: it lists every demo and plays ones that have no host
command (e.g. `session`). To map a command to its demo, add the **5th field** on
that command's row in `docs/sprintbias/help/_registry`
(`command | group | usage | summary | demo-name`). A story only populates its own
host row. The demo-field mechanism (`<cmd> --demo` intercept + the `--help`
pointer) is owned by task #314; stories just supply the mapping and the script.
