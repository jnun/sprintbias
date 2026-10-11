# Task 411: The manual grew 460 words agents must load every run

**Feature**: none
**Created**: 2026-10-08
**Docs**: none
**Plan**: 29
**From plan**: 28
**Depends on**: 407, 409, 410
**Held**: fix #413
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: demos
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

DOCUMENTATION.md grew from 2,941 to 3,405 words in plan 28. Agents load the
manual, so every word costs context on every run. Some of the growth repeats
what help pages and guides/crew.md already say.


## Done when (automated)

- [ ] DOCUMENTATION.md is at or under 3,000 words (`wc -w DOCUMENTATION.md`) with no rule, policy or command lost: anything cut is a pointer to the help page or guide that holds it.
- [ ] It reflects this plan: the held standing (#407), the reused suite run (#409), and the split demos (#410). `grep -n -i 'held' DOCUMENTATION.md` shows the held standing named apart from "in review, unproven"; the plan-close text says a green suite run is reused until the tree changes (`--fresh` re-runs); every `learn <name>` the manual names appears in `./sprint.sh learn` output.
- [ ] `./sprint.sh validate --docs`, `./sprint.sh validate --commands` and `bash docs/tests/test-no-stale-refs.sh` pass.


## Signoff (human)

- [ ] Read Solo and Crew: a new user can tell which mode fits in under a minute.


## Notes

From the lead (orcha), on #407 landing: the manual's `Held` field entry should
say a held original shows as `held: fix #N` in plan check and status (a fourth
standing next to open / landed / signed off). Keep it to one clause.

Follow-up from plan 28; its Policy applies: docs/plans/28-enhance-crews-and-efficiency.md.

Candidates: the Crew section's agents/AGENT_HOSTS paragraph (guides/crew.md has it), repeated landing explanations, command lists that help/_registry already generates. Keep the policy stated once.


## References

DOCUMENTATION.md
docs/sprintbias/guides/crew.md
docs/sprintbias/help/


## Grounding

**Touching:** DOCUMENTATION.md, docs/sprintbias/learning/teamwork.py (task slugs), docs/sprintbias/learning/team-landing.py, docs/sprintbias/learning/team-signoff.py, docs/sprintbias/learning/README.md (S9.3 row)
**Sources:** `DOCUMENTATION.md` (the user manual agents load every run), `docs/plans/28-enhance-crews-and-efficiency.md` (Policy: Landed, Signed off, Proof line, Held, Fixes, plan states, suite once at close), `docs/sprintbias/guides/crew.md` (full crew guide; home for detail cut from the manual's Crew section), `docs/sprintbias/help/_registry` (command catalog; generates the help index), `docs/sprintbias/help/` (per-command pages), `docs/sprintbias/guides/doc-style.md` (writing docs that cost the reader the least), `CLAUDE.md` (guiding principles: minimize context cost)
**Terms:**
- **Landed** — in review/ with a proof line. Landed work releases its dependents. In review/ without proof is "in review, unproven" and releases nothing.
- **Signed off** — in done/. Only humans move work there, at the end of a task or plan, after the full suite passes and the human checks are done.
- **Held** — `**Held**: fix #<new>` on the rejected original, which stays in review/ and releases nothing until the fix lands.
**Conflicts:**
- The project has no glossary or project map (docs/sprintbias/project.md absent) → use plan 28's Policy as the term source; no glossary follow-up needed for this task.
- "held standing" is a term #407 introduces in code, not yet in the Policy or the manual → use #407's landed wording (`held: fix #N`) and state it once in the manual's Distinctions/Fields text beside "in review, unproven".
- #407, #409 and #410 each change behavior the manual describes and may touch DOCUMENTATION.md themselves → this task runs after them and owns the final word count; fold their manual edits into the 3,000-word budget rather than reverting them.
- The demo names #410 will choose are unknown today → read them from `./sprint.sh learn` after #410 lands; the manual names at most the first demo and points at `learn` for the rest.
- Done when asks to add three facts while cutting 405+ words → net cut is measured on the final file; added text counts toward the 3,000 limit.

## Questions

**Status: READY**

### Already complete
None — no matching implementation found.
- `wc -w DOCUMENTATION.md` reads 3405 today (target at or under 3,000).
- Manual mentions Held (line ~136) and the full suite once at `promote plan:N` (lines ~108, ~245, ~279, ~349) but has no held standing, no reused suite run, and names only `learn teamwork` (line ~287).
- `./sprint.sh validate --docs`, `validate --commands` and `bash docs/tests/test-no-stale-refs.sh` pass today (18 passed).

### Remaining work
- After #407, #409 and #410 land, cut DOCUMENTATION.md to at most 3,000 words. Candidates: the `agents`/`AGENT_HOSTS` paragraph in Crew (guides/crew.md holds it), landing and full-suite explanations repeated across Folders, Distinctions, Solo and Crew (state the policy once and point to it), and command-list detail the help pages already cover.
- Replace each cut with a one-line pointer to the help page or guide that holds it; confirm the target holds the cut fact before cutting.
- Add the held standing, the reused green suite run (and `--fresh`), and the split demo names, each stated once.
- Keep Solo and Crew short enough that their opening contrast decides the mode.
- Run the three validators plus `wc -w DOCUMENTATION.md`.

### Questions for the developer
None — task is fully defined.

<!-- sb:hint  After work only — audit trail of what was touched. Helps committers,
     later audits, and "what broke?" recovery. List the product files you
     edited to complete the task — one repo-relative path per line. Leave this
     task file out: its folder location and git history already track it. Copy
     the two headings below to column 0
     (UNINDENTED — they are indented here only so a fresh, unworked task is not
     mistaken for a finished one), then list the paths under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintbias/scripts/example.sh
       docs/sprintbias/help/example.md

     When the work made a source of truth wrong and updating it is out of
     scope (or it is a governing source), add under ## Completed:

       ### Doc follow-ups
       - `docs/GLOSSARY.md` — add "plan"; the code now uses it

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. Do not fill this before work. -->

<!-- sb:hint
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->

## Test log

- 2026-10-08 · `bash docs/tests/run-all.sh </dev/null` (full suite, once) · 27 passed, 1 failed: `test-cleanup-tmp.sh` ("Recent also deleted"), which already failed before this plan.
- 2026-10-08 · sent back: Full suite failed at plan 29 sign-off: `bash docs/tests/run-all.sh` exited 1. Failing output: → fix #413


## Completed

DOCUMENTATION.md: 3,410 words before (after signoff's #409 edit), 2,930 after
(`wc -w`). The landing policy is stated once, in Distinctions; the other
sections point to it.

Added, each once: the held standing in the `Held` field entry (`held: fix #N`
in plan check and status, apart from *unproven*); the reused green suite run
and `--fresh` in Distinctions (landed ≠ signed off); "three parts" beside
`learn teamwork` in Crew. The only `learn <name>` in the manual is `teamwork`.

Cut, and where it now lives:
- "Why folders and plain text" section → folded into the two-line intro.
- Crew command block (setup, add, lead plan:N, start a member, roster) → one
  sentence plus `./sprint.sh help crew`; `crew` stays in Commands.
- `agents` / `AGENT_HOSTS` / `agents label` paragraph and the Commands
  comment → `./sprint.sh help agents` (pointer in Crew).
- ListAgents / SendMessage and the production-credentials example → guides/crew.md (Messages between members, Recommended crews).
- Solo's "test per task, suite per plan" repeat → Distinctions; `TEST_SUITE` → Provider and model.
- promote and plan check comment detail (--audit judge, --reject wording, counts) → `help promote`, `help plan`.
- Guides table → one row in Learn more plus the Structure line.
- Creating work table → the create commands in Commands; the `from:N` / `backlog` plan rows kept as one sentence (`help newplan`).
- Profile show/check block → `help profile`; the Doc follow-ups detail (tagging, filed once) → `help work`.
- Moving tasks' commit sentence → rule 5. Installing, rule 6 and the file-name note tightened, nothing dropped.

Demos re-checked on a scratch board (copy of today's docs/sprintbias, TEST_SUITE=true) against the real `plan check`, `promote --reject` and `promote plan:14`:
- team-landing: added the lead's `plan check` after the rejection, showing `held 1` and `#89 ... held: fix #91` (#407). Other lines unchanged.
- team-signoff: the lead now runs `promote plan:14 </dev/null` (full suite once, nothing moved, per the lead's plan-close rule), and your `promote plan:14` shows the real "✓ Full suite reused: … (--fresh re-runs it)." line (#409).
- teamwork: task file slugs for #88 and #90 now match what `newtask` writes.
- learning/README.md S9.3 row says the lead runs the suite and your sign-off reuses it.

### Files changed
DOCUMENTATION.md
docs/sprintbias/learning/teamwork.py
docs/sprintbias/learning/team-landing.py
docs/sprintbias/learning/team-signoff.py
docs/sprintbias/learning/README.md

**Proof**: 2026-10-08 · wc -w DOCUMENTATION.md (2930); ./sprint.sh validate --docs; ./sprint.sh validate --commands; bash docs/tests/test-no-stale-refs.sh; ./sprint.sh learn teamwork|team-landing|team-signoff --fast --no-color </dev/null; bash docs/sprintbias/tests/learn-sandbox.sh · pass
