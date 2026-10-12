# Field trial: edge-case catching on a real product

Maintainer guide (does not ship). How to run the edge-case model (finishing
rule, edge-case classes, breaker, known edges) on a real project, measure it,
and bring the results back here.

**Hypothesis.** Agents that test the class of an input, starting from real use,
plus a fresh breaker pass after each task, find most defects before a person
does, at a cost per defect worth paying.

**Primary measure: escaped defects.** Escaped defects are the defects you find
(`promote --reject`, human-test failures, and defects found later in done/
work). Caught defects are what the breaker found (Breaker lines).
`./sprint.sh status --edges` computes both, with no AI.

| Number | Target | Read from |
|---|---|---|
| Catch rate (agents ÷ all found, on checked work) | ≥ 80% | `status --edges` |
| Escapes per 10 tasks, breaker vs no breaker | breaker ≤ half | same, two columns |
| Breaker cost per defect caught | ≤ $3 | same (`· $cost` on Breaker lines) |
| Breaker not run (crash / timeout) | ~0 | same |

The numbers are honest only if **every defect you find goes through
`promote --reject <id> "class: case"`**, including bugs you find weeks later
in `done/` work. The No-breaker column then gives the baseline going forward.

## Setup (once, about 15 minutes)

In this repo:

```bash
./ship.sh                       # release with today's changes
```

In the product (heavymetal is the first trial):

```bash
cd ~/Projects/heavymetal
~/Projects/sprint/setup.sh ~/Projects/heavymetal   # update; keeps tasks, config, IDs
./sprint.sh profile             # project map: Known edges are kept here
cat >> docs/sprintbias/config.local <<'EOF'
# Python tests run on the app's venv; the full suite runs once at plan sign-off
TEST_RUN=scripts/pytest.sh {file}
TEST_SUITE=scripts/pytest.sh
# Field trial: push the breaker harder (per machine, untracked)
BUDGET_BREAK=5.00
BREAK_MAX_TURNS=40
BREAK_TIMEOUT=1200
EOF
./sprint.sh fast on             # optional: 4 parallel lanes, fewer prompts
```

Start the local stack before any breaker run (`./server.sh` or
`docker-compose.dev.yml`). The breaker runs the task's own tests, such as
`scripts/pytest.sh <file>`, so they must run. `TEST_RUN` lets `promote <id>`
run heavymetal's `.py` Tests on the app's venv, and `TEST_SUITE` runs the
whole suite once at plan sign-off. Move both to the tracked config once they
prove out.

## Experiment 1: plan 67, checked after the fact (start here)

Plan 67 (bulk upload for vendors) is LANDED and unchecked: 11 tasks in
`review/` plus human test #1760. It covers CSV import, vendor identity, RBAC, a
migration and web UI, the same class as the CSV demo the model was tuned on.

```bash
./sprint.sh promote plan 67 --dry-run   # what will be checked; moves nothing
./sprint.sh polish --break plan:67      # 5 lanes, the API+web chain in turn
./sprint.sh status --edges plan:67      # what the agents caught
```

Read each task's Breaker line and its `## Test log`. Review the code diffs
before you commit; git stays yours. **Then** run human test #1760, writing
each failure as `- fail: …` under `## Results`. The order matters: the human
test runs after the breaker, so it counts what got past it.

```bash
./sprint.sh promote plan 67             # files a fix task per failure, signs off the rest
./sprint.sh status --edges plan:67      # caught vs escaped for this plan
```

## Experiment 2: a plan built with the model from the start

Pick the next plan you'd build anyway, such as the api-perf group
(#1386–1395) or sync v2. Build it on the normal path, so the edge-case
classes shape the gate and the work, and the breaker runs after each task
lands:

```bash
./sprint.sh plan start N && ./sprint.sh work plan N
# human test, then:
./sprint.sh promote plan N && ./sprint.sh status --edges plan:N
```

Compare with experiment 1. The difference is roughly the effect of building
with the edge-case classes versus checking after the fact.

## Experiment 3: ongoing production escapes

Any defect found later, in any done/ task:

```bash
./sprint.sh promote --reject <id> "class: the case"   # e.g. "csv import: Excel BOM header"
```

It files a linked fix task and adds a Known edges line, and the original
stays signed off. Weekly: `./sprint.sh status --edges`.

## Bring back

- `status --edges` output, overall and per plan.
- The **Escaped past the breaker** list. For each escape, why the classes
  missed it: a class we lack, a real-use form we never named, or a breaker
  that ran out of turns.
- One or two breaker logs (`docs/tmp/log-break-*.json`) from runs that
  missed, and from runs that ran out of turns or time.
- Wall time for `polish --break plan:N` and for sign-off.

Each escape class becomes a change here, in `sprintbias_edge_cases`, the
breaker rule, or the gate contract, tested in `docs/tests/test-edge-cases.sh`
and shipped.

## Brief for the product's agents

Paste into the agent session in the product:

```text
We are trialing SprintBias's edge-case model on this product. Goal: agents find
and fix defects before a person sees the work, and we measure how often they do.

- Build through ./sprint.sh (plan start, work, polish --break, promote). The
  breaker runs after each task lands; keep it on.
- For every input your change accepts, test its class: every form the docs,
  UI and real tools produce (Excel/Numbers/Google CSV exports, BOM, CRLF,
  quoted commas, pasted text), again and after (run twice, older data, hand
  edits), empty / one / many / malformed, and neighbors on the same data.
  Read ## Known edges in docs/sprintbias/project.md first.
- A failing case in your code path: fix it and prove it. One in another
  path: file it with ./sprint.sh newtask "<the failing case>". Never record a
  known failure as a decision.
- Push hard: start from real use, then extremes. Run the project's tests for
  real (local stack up), not by reading code.
- When the person reports a defect, file it with
  ./sprint.sh promote --reject <id> "class: case", even for done/ work.
- Git is the person's (CLAUDE.md Rule 0): edit files, never commit.
- Report with ./sprint.sh status --edges.
```
