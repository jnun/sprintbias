Post-work quality pass — three modes, one command.

`polish` is THE post-work quality surface. Three levers stay distinct inside
it; argument shape selects the mode:

  Sweep (bare)     polish [limit] [--rounds N] [--parallel|--fast|--jobs N]
                   Judge every finished task in review/. When a second
                   execution pass would close a real gap, rewrite that same
                   task with concrete improvements and reopen it to next/.
                   Each task is judged independently, so a long queue can fan
                   out concurrently (same flags as work).
                   Protocol: docs/sprintbias/ai/refine.md

  Deep-judge       polish <id|file|task.md>
                   Judge ONE finished piece against a higher bar than "it
                   runs." Target it by task id or by path. Never edits product
                   code — enhancements are filed as backlog tasks via newtask.
                   Protocol: docs/sprintbias/ai/audit-excellence.md

  Code audit       polish --code <id|file|task.md> [passes]
                   Fixer/verifier loop over a finished task's code diff.
                   May fix issues inline. Answers "is it correct?"

Argument shape selects the mode. A bare number is read id-first: if it names
an existing task (in any lifecycle folder) it targets THAT task — the deep
judge, or the code audit under `--code`, uniform with `work`/`chat`. A number
that resolves to no task is a sweep limit. A bare path is the deep judge; the
same path with `--code` is the code audit. `--rounds` stays sweep-only.

── Sweep ──────────────────────────────────────────────────────────────

Where deep-judge files *separate* backlog tasks, the sweep reopens the SAME
task for another pass. Each task is judged in a fresh context so a long
review/ queue never blows one context window.

Verdicts (last line of each task's report):
  PASS     — meets the bar; stays in review/
  REOPEN   — a '## Rework (round N)' section is appended; task re-enters next/
             only via the shared workability gate (READY → next/, else kickback)
  BLOCKER  — work fails its own goal and needs a human; stays in review/

Round cap: keyed on the '**Reworked**:' header counter, which ONLY polish
increments — one bump per confirmed reopen. Once a task's Reworked count
reaches --rounds (default 1) it is capped and skipped. The cap ignores '##
Refine'/'## Rework' headings in the body (a gate pass or hand edit can write
those), so polish never skips a task it has not actually judged; a missing
counter reads as 0. --force overrides the cap for a one-off deeper pass. The
refine pass NEVER edits product code — it appends the '## Rework' section and
the runner bumps the counter.

The round cap (--rounds, default 1) is a per-task rework budget, NOT a
concurrency setting: "round cap: 1" means each task gets one reopen, not that
the sweep runs serially.

Parallel fan-out (sweep only — same surface as work): each task judges in a
fresh context and writes only its own task file, so independent judges overlap
safely.
  --parallel   up to 2 concurrent judges
  --fast       up to 4 concurrent judges
  --jobs N     up to N concurrent judges
Only the judging overlaps: verdict parsing, the '**Reworked**' bump, gate
promotion, and the run counters all stay serialized after each judge returns —
no reopen races the gate and no count is lost. Sequential is the default.
In an orchestration-capable AI session the flags tell the orchestrator to fan
the judge subagents out concurrently (the numeric --jobs cap is a headless-only
knob and is not passed to the orchestrator). Deep-judge and --code stay
single-target: they work within one task file, so the flags are ignored there.

── Deep-judge ─────────────────────────────────────────────────────────

Judges engineering quality (effectiveness, efficiency, design fit,
operability, robustness). Correctness is presumed only when a `polish --code`
has passed on this work; otherwise the run flags it and the judge does not wave
defects by (see the `correctness:` field below). Verdicts:
  EXCELLENT  — meets the bar, nothing filed            (exit 0)
  FILED — n (x → next/, y → backlog/) — n enhancement tasks filed, split by
           where they landed                           (exit 0)
  BLOCKER  — work fails its own task's goal            (exit 1)

Filed tasks default to `backlog/`, the queue a human re-triages later. The vital
few a senior engineer would act on NOW — rated both high-confidence and
high-value — may be warm-routed into `next/` instead, so a good, act-now finding
does not go cold in the backlog. Warm routing goes through the same workability
gate `plan start` uses (it is READY-vetted before it sits in `next/`), never a
raw move, and is hard-capped at 1–2 per audit so the judge cannot fast-track a
whole audit as urgent. The `FILED — n (x → next/, y → backlog/)` summary shows
the split.

A '## Excellence' section (date, verdict, correctness, tasks filed, routing,
files reviewed, context source, code state, summary) is appended to the task file
for the record. The `routing:` field records the warm-route split (e.g. `1 →
next/, 2 → backlog/`). The `correctness:` field records whether a code audit backs
this judgment: `audited` (a passed `polish --code` is on file), `unverified` (none
has run — run one before trusting the verdict), or `failed` (a `polish --code` ran
and did not clear the work — worse than unverified). The `code state:` field is a
content hash of the audited files as they stood when judged.

That section is also the idempotency signal, keyed on the code state: a re-run
skips a piece that already carries one ONLY while the audited files still hash to
the stamped code state (it would otherwise stack a second section and re-file the
same enhancements). When the audited files have MOVED since the verdict, the
stamp is stale, so the re-run re-judges automatically rather than presenting the
old verdict as current — replacing the '## Excellence' block in place, never
stacking a second. An auto re-judge re-runs the full audit, so it can re-file
enhancements just as `--force` does — and it fires more readily than a manual
`--force`, so an edited-then-re-polished task may accrue newly filed tasks.
`--force` re-judges unconditionally. The same guard covers `plan polish`, which
routes through this one judge per member.

── Code audit ─────────────────────────────────────────────────────────

Runs an iterative fixer/verifier loop:
  - FIXER: full tools, can read and edit code, fixes issues
  - VERIFIER: read-only tools, confirms fixes are correct

Context modes (how the audit knows what changed):
  1. MANIFEST FILE — work writes a manifest listing changed files
  2. TASK FILE — parses the ## Completed section for changed files
  3. EXPLICIT FILE LIST — pass file paths directly

Exits 0 (clean) or 1 (warnings). A '## Audit' section is appended when a
task file is provided.

If a step aborts (hits its turn limit or the CLI errors), the edits the fixer
already landed are kept, not thrown away: the delta is banked as a patch, one
bounded verifier pass runs on what landed, and a '## Audit (aborted — fixes
landed)' note records the outcome. Re-run `polish --code` to push that banked
work forward; raising SPRINTBIAS_AUDIT_MAX_TURNS is the last resort if it keeps
stalling on the same step.

Usage:
  ./sprint.sh polish                 # sweep all of review/
  ./sprint.sh polish 874             # deep-judge task 874 (any folder)
  ./sprint.sh polish 3               # sweep at most 3 tasks (if no task 3)
  ./sprint.sh polish --rounds 2      # allow up to 2 reopens per task
  ./sprint.sh polish --parallel      # sweep review/ with 2 concurrent judges
  ./sprint.sh polish --fast          # shorthand for --parallel with 4 judges
  ./sprint.sh polish --jobs N        # sweep with N concurrent judges
  ./sprint.sh polish --force         # sweep: ignore the round cap this run
  ./sprint.sh polish --force 874     # deep-judge: re-judge an already-judged task
  ./sprint.sh polish --max           # clear the budget cap (where one applies)
  ./sprint.sh polish <task.md>       # deep-judge one finished piece
  ./sprint.sh polish file1.py file2  # deep-judge explicit files
  ./sprint.sh polish --code 874      # code-audit task 874
  ./sprint.sh polish --code <task.md> [max-passes]
  ./sprint.sh polish --code f1 f2 -- 3
  ./sprint.sh polish --model <id>    # pin the model for this run only

Provider for this run only (leading flags; does not rewrite config):
  ./sprint.sh -g polish              # Grok Build
  ./sprint.sh -c polish --code f.py  # Claude Code

Model for this run only: add --model <id> (e.g. ./sprint.sh polish --model opus)
to pin every mode's model without editing config. Precedence, highest first:
  --model flag / matching SPRINTBIAS_MODEL_* env (POLISH / EXCELLENCE / CODE_AUDIT)
    → config MODEL_<ROLE> → config MODEL_DEFAULT → tier default → CLI default
See and set persistent pins with ./sprint.sh model (help model).

Full loop:
  ./sprint.sh work                   # execute the sprint → review/
  ./sprint.sh polish                 # raise the bar; reopen what falls short
  ./sprint.sh work                   # re-execute the reopened tasks
