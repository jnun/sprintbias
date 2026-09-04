# Task 382: Route work off the structured run outcome, not rc + grep

**Feature**: none
**Created**: 2026-09-03
**Docs**: none
**Plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

`work.sh` is the only runner that decides a finished task's fate by re-deriving
it from a single scalar — the CLI exit code — plus one `grep '^## Completed'`.
Every other command (polish, deps, the profiles) reads the normalized record the
profile already emits: `SPRINTBIAS_RUN_OUTCOME` ∈ `finished | max_turns |
no_start | error`, via `sprintbias_interpret_run` / `profile_interpret_run`.
Because a scalar can't tell a crash from a turn-cap from a clean-but-empty run,
work mislabels outcomes: the 2026-09-03 real-project incident had an
`error_during_execution` crash routed to `blocked/` as "badly defined," and a
turn-cap crash and a mid-run crash are still handled identically. The hotfix
(same incident) made the exit code honest and made routing crash-safe, but it
kept the lossy rc+grep channel. This task removes the channel: route off the
structured outcome so work reasons from what actually happened, and reserve
`blocked/` for the one thing it is supposed to mean — a human owes a decision.

## Success criteria

<!-- sb:hint  What done looks like. When these are met, the task is done.
     Observable checks anyone can verify. For a library or detailed technical
     fix, state the new technical needs as outcomes — still not a step outline. -->

- [ ] `profile_interpret_run` (and the shared fallback) reads work's stream-json
      **NDJSON** logs correctly: it locates the last `type:result` event and
      classifies from its `is_error`/`subtype`, instead of `json.loads`-ing the
      whole file and silently falling back to `finished` on the parse error.
      Proven by a unit test feeding a real multi-line NDJSON log for each of:
      clean finish, `error_during_execution`, `error_max_turns`, empty/no-start.
- [ ] `work.sh:_route_result` decides the destination from `SPRINTBIAS_RUN_OUTCOME`
      (+ the `## Completed` artifact check), not from `rc` + a grep. Mapping:
      `finished` + `## Completed` → `review/`; `error` / `no_start` → crash, stays
      resumable in `doing/` stamped `failed`; **budget exhaustion → `blocked/`
      stamped `budget`** (decided — see below); `finished` with no `## Completed`
      → bounded inline resume, then `blocked/` (see below). `max_turns` keeps its
      own outcome value for completeness, but note it is near-unreachable in
      work's routed path (next item).
- [ ] Invariant holds **end to end, including under `loop`**: a task leaves
      `doing/` only on affirmative evidence of a terminal state — `## Completed`
      (→ `review/`) or an explicit human-decision stamp (→ `blocked/`). This
      REQUIRES reconciling `loop.sh`, which today has two contradictory `doing/`
      handlers: startup re-queues `doing/` → `next/` (`loop.sh:123-136`), but the
      per-iteration rescue moves all `doing/` residue → `blocked/`
      (`loop.sh:271-277`, "incomplete → needs decision"). That per-iteration
      sweep is exactly what re-launders a crash the runner deliberately left in
      `doing/`. Resolution (decided): **delete loop's per-iteration `doing/` →
      `blocked/` sweep** and let `work.sh` own resumable pickup (next item), so a
      crash is never re-laundered. No CLI failure shape routes to `blocked/` from
      EITHER `work` or `loop`.
- [ ] `doing/` residue is resumed in place, and the pickup rule lives in
      `work.sh` (decided): at the start of ANY work run, resume interrupted
      `doing/` residue — session-resume where a session id is recoverable from the
      log, else a fresh continuation from the task file — BEFORE scanning `next/`.
      This fixes the plain-`work` invisibility (work now sees `doing/`), unifies
      loop's two handlers into this one rule, and keeps side-effect risk low
      (resume continues rather than re-running from scratch). Stay in `doing/`;
      do NOT re-queue to `next/`.
- [ ] Resumability is bounded at **N=1, inline within the run** (decided): on
      `finished`-without-`## Completed`, resume/continue exactly ONCE with an
      explicit nudge ("finish and write `## Completed`, or state why you can't");
      re-check; if still absent → `blocked/` (human). Inline + single means **no
      durable cross-run counter is needed** — this deliberately avoids
      `**Reworked**`, which is already owned by `polish.sh`'s post-work
      rework-round cap and must not be repurposed. The same N=1 bound applies to
      the `doing/`-residue resume above so nothing loops forever.
- [ ] Budget exhaustion is handled deliberately (decided): it routes to
      `blocked/` with a distinct `budget` stamp ("hit the $N cap — raise budget
      or split the task") and is **never auto-resumed** — resuming re-enters the
      same context and re-burns the cap, which is the worst case for a runaway
      loop. Work's main runs pass **no `--max-turns`** (uncapped by design), so
      `error_max_turns` is near-unreachable in the routed path; budget is the
      live deterministic cap. Identify its real result shape/subtype against a
      live budget-capped log and add it to the interpreter's mapping rather than
      letting it fall into generic `error`. (The default cap stays `$10`/task,
      Claude-only; the raised-ceiling escape hatch is a separate sibling task —
      see Notes.)
- [ ] Retry non-retryability keys off the structured `subtype` where the CLI
      provides one, so `_SPRINTBIAS_NONRETRY_RE`'s free-text budget/turn/flag
      matching can no longer mis-classify a failed run whose result text merely
      mentions those words.
- [ ] Behavior parity across the runner: sequential and parallel paths, and the
      resume/already-moved cases the hotfix added, all route identically off the
      structured outcome. The run-journal `routed`/`crashed` events reflect the
      new outcome vocabulary.
- [ ] Dual-host parity preserved: Grok's `profile_interpret_run`
      (`cancelled → max_turns`, no `is_error` key) feeds the same
      `SPRINTBIAS_RUN_OUTCOME` contract work now consumes — verified by the
      dual-provider smoke, no Claude-only assumption leaks into shared routing.

## Notes

<!-- sb:hint  Optional helpful hints that assist the developer: constraints, edge
     cases, gotchas. Guidance from answered questions also lives here when it
     shapes how (and is not already a success criterion). Leave empty if none. -->

- This **supersedes** the rc+grep routing hardened by the 2026-09-03 hotfix. The
  hotfix stays as belt-and-suspenders (honest exit code, crash-safe moves under
  `set -e`, `|| true` guards) — do not remove those; this change sits on top,
  swapping the *decision input* from `rc` to `SPRINTBIAS_RUN_OUTCOME`.
- The NDJSON fix is the load-bearing prerequisite and the main risk —
  **verified empirically 2026-09-03**: fed a real 3-line stream-json crash log
  (`subtype:error_during_execution`), `profile_interpret_run` returns
  `finished` and dumps the raw file as the verdict; the same crash as a single
  JSON object returns `error` correctly. So pointing work at the interpreter
  BEFORE this fix would route every crash to `review/` — worse than the
  incident. Today `_SPRINTBIAS_INTERPRET_PY` does `open().read()` then
  `json.loads(raw)`; on NDJSON that raises and the `except` emits `finished`.
  The stream filter (`_SPRINTBIAS_STREAM_FILTER`) already isolates the final
  `type:result` line — mirror that selection in the interpreter so both agree.
- **`loop.sh` is in scope, not just `work.sh`.** The incident's home is the
  headless long-run (`loop`), and `loop.sh:271-277` mislabels crashes
  independently of `work.sh`. The 2026-09-03 hotfix's "crash stays in `doing/`"
  guarantee holds only for a DIRECT `work` invocation; under `loop` the
  per-iteration sweep overrides it. Reconciling loop's two `doing/` handlers is
  part of making the invariant true. Scope decision (2026-09-03): the loop fix
  stays in THIS task, not backported into the incident hotfix (a half-fix to
  loop's two contradictory handlers mid-incident would deepen the
  inconsistency); the provider-reality note is narrowed to say the hotfix's
  "crash → `doing/`, not `blocked/`" guarantee holds for a direct `work` run only
  until this lands.
- Keep the "leave `doing/` only on affirmative evidence" change explicit and
  visible in the run summary and journal: a no-`## Completed` clean run changing
  from `blocked/` to resumable is a user-facing behavior change. Dependents are
  unaffected by design — a task held in `doing/` still reads as incomplete to
  `sprintbias_unmet_deps`, so a dependent correctly keeps waiting.
- `max_turns` keeps a distinct outcome value for completeness, but do not build
  much around it: work's main runs are uncapped, so it is near-unreachable in the
  routed path. Keep the three stamps (`failed` crash, `budget`, `incomplete`)
  separable in `## Outcome` and the closing recap.
- **Decisions settled (2026-09-04)** and encoded in the criteria above: resume
  bound N=1 inline; default budget `$10`/task stays (liberal, capped, not
  wide-open — the cap IS the runaway guard, model-agnostic); budget exhaustion →
  `blocked/`/`budget`, never auto-resumed; `doing/` residue stays and is resumed
  by `work.sh`; loop's per-iteration `doing/` → `blocked/` sweep is deleted.
- **Sibling task (separate, independently shippable):** redefine `work --max`
  from *unlimited* (today it clears the cap) to a *bounded high ceiling*
  (~`$100`) for the rare super-complex task — a runaway backstop even on the
  escape hatch. NOT reusable as `loop --max` (already taken: numeric
  stop-after-N-tasks). That is a small budget-value change, kept out of this
  task so it can ship without the routing refactor. See its own task file.
- Provider-behavior change → update `docs/guides/provider-reality.md`
  (Reliability & exec parity KK/KU + a dated Surfaced-unknowns note) and, if any
  user-facing command surface shifts, `docs/guides/command-matrix.md`.

## References

<!-- sb:hint  Direct paths to docs or files known to be related. One path per
     line. Leave empty if none. -->

docs/sprintbias/scripts/work.sh
docs/sprintbias/scripts/loop.sh
docs/sprintbias/cli/claude.sh
docs/sprintbias/cli/grok.sh
docs/sprintbias/lib.sh
docs/guides/provider-reality.md

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

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. Do not fill this before work. -->

<!-- sb:hint
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji, color, or ASCII art. See docs/sprintbias/guides/doc-style.md
-->
