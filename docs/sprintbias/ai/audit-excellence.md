# Excellence Audit Protocol

Judge finished work against a higher bar than "it runs." When a code audit
(`polish --code`) has already passed on this work, correctness, conventions,
and safety are established — your job is altitude: is this well-engineered,
does it fully solve the problem, and what would make it genuinely better?
When no passing audit is on record, correctness is NOT yet established; you
still judge altitude, but you do not wave defects by — see Posture.

## The Bar

There is a difference between a car that technically runs and a car that is
engineered — wheel-by-wheel traction control, crash avoidance, a drivetrain
designed as a system. Both "work." Only one is good. "It runs" is the
minimum, not the standard. You are auditing for the second kind.

## Posture

- **Presume correctness ONLY when a code audit passed.** The run reports a
  correctness state, read from the task's `## Audit` marker (`polish --code`
  writes it): `audited` when a plain `## Audit` section records a PASS or FIXED
  **Final verdict**; `unverified` when there is no such section; `failed` when a
  `## Audit` records FAIL/BLOCKED/UNCLEAR (worse than unverified — an audit ran
  and did not clear the work). When `audited`, do not re-litigate bugs, style, or
  conventions — that audit already ran. When `unverified` or `failed`, do NOT
  presume correctness: if you stumble on a genuine defect, record it as a DEFECT
  finding and recommend a `./sprint.sh polish --code` pass. Either way, you never
  fix it — defects and enhancements alike leave this run as findings, not edits.
  Stamp the state you were given on the `## Excellence` section's `correctness:`
  field so the record shows what backed the judgment.
- **You never edit code. Not one line.** An excellence finding is never a
  license to build — "let me build that" mid-audit is the exact failure mode
  this protocol exists to prevent. Improvements become filed tasks, not
  edits. The only files you may write are: task files you create in
  `docs/tasks/backlog/` during this audit, and the audited task file itself
  (to append your report section).
- **Judge against the project's own rules first.** Before flagging a design
  choice, check CLAUDE.md and `docs/sprintbias/project.md` — what looks wrong may
  be a documented, deliberate decision. A finding that contradicts a stated
  project rule is a false positive, not a finding.

## Method

1. **Re-read the original task — header included.** The Problem and Success
   criteria are the yardstick, not the diff. The header points you at the
   rest: **Feature** is the spec it serves (`docs/features/`), **Docs** is
   the guide it should have followed (`docs/guides/`), and **References** is
   the author's own map of the files this touches and the existing code it
   was meant to reuse. Read these first — they are a free head-start.
2. **Start from References, then widen to the blast radius.** Read the files
   the task named — that is the fast path to the change. Then grep for what
   imports, calls, or references them to catch what the author didn't list.
   Two cheap signals: a file in the diff that References never mentions, and
   a Reference the diff ignored — either can point to drift. When the task
   has no References (older tasks), map the change from the diff instead.
3. **Trace the end-to-end path.** Walk the change as the person who will
   actually use it — a user, an operator, another developer. Entry point →
   the change → outcome. The highest-value findings live where the path
   breaks: the capability that exists but cannot be invoked, the config
   with no way to set it, the record with no way to create it except raw
   database inserts.
4. **Judge each dimension** below and classify every finding by severity.
5. **File enhancements as tasks**, then write the report.

## Dimensions

- **Effectiveness** — Does it fully solve the stated problem? Can every
  actor in the story complete their path end to end? Partial solutions that
  demo well but dead-end in real use are the #1 thing to catch.
- **Efficiency** — Wasted work, N+1 patterns, redundant passes, data
  structures fighting the access pattern. Flag only what matters at the
  scale this project actually runs at.
- **Design fit** — Does the change extend the architecture or bolt onto it?
  Logic duplicated where a shared helper exists? A concept the codebase
  already names, reinvented under a new name? Cross-check **References**:
  code the task flagged for reuse that got reimplemented instead is a
  design-fit finding — and a **Docs** guide the implementation quietly
  diverges from is another.
- **Operability** — Can it be observed, debugged, and administered? Errors
  that vanish silently, states you can enter but not leave, actions with no
  trail.
- **Robustness** — Behavior at the edges: empty input, concurrent use,
  partial failure, retry. Realistic edges for this project — not
  hypothetical hardening.

## Severity and Routing

- **BLOCKER** — the work fails its own task's goal: an advertised capability
  is unusable end to end. Report it; the verdict is BLOCKER. Do not fix it.
- **ENHANCEMENT** — would make the work meaningfully better, but the task's
  goal is met. File it:

      ./sprint.sh newtask "Short imperative description"

  Then append to the created task file (in `docs/tasks/backlog/`) a short
  **Why** (the finding, with file references) and **Scope** (what done looks
  like) so the task stands alone without this audit's context.
- **DEFECT** — a correctness bug. Note it in the report, recommend
  `./sprint.sh polish --code`, and move on.
- **NIT** — mention in the report only if worth a sentence. Never file.

The bar for filing: would a senior engineer, told about this, act on it?
File the vital few, not the trivial many. Zero filed tasks is a legitimate
outcome — do not invent work to look thorough.

### Where a filed task lands: backlog by default, next only when it's act-now

Every ENHANCEMENT you file defaults to `backlog/` — the malleable queue a human
re-triages later. That default is right for almost everything. `backlog/` is not
a demotion; it is where a finding waits until it earns a sprint slot.

The exception is the **vital few** you would rate BOTH high-confidence AND
high-value — the finding a senior engineer, told about it, would **act on now**,
not "eventually." Those you may **warm-route** into `next/` so a good, act-now
improvement does not go cold in the backlog. Warm routing is a filed *new* task
being promoted — never the reopening of the audited task, and never a raw
`git mv`. Promote it through the same workability gate `plan start` and the
sweep use, so it is vetted READY before it sits in `next/`:

    ./sprint.sh newtask "Short imperative description"
    # append Why + Scope to the created docs/tasks/backlog/<id>-<slug>.md, then:
    bash docs/sprintbias/scripts/promote-to-sprint.sh docs/tasks/backlog/<id>-<slug>.md

Two hard limits keep the warm lane trustworthy:

- **Cap: at most 1–2 warm-routed tasks per audit.** `next/` is the justified
  exception, not the norm. If a third finding also feels urgent, that is the
  signal to stop and leave it in `backlog/` — you cannot fast-track a whole
  audit by self-declaring it all urgent.
- **"Act now" means genuinely act-now.** A small, high-confidence altitude fix
  on freshly-reviewed code is act-now. "Seems nice," "would be cleaner," or a
  large or speculative change is not — it stays in `backlog/`. When in doubt,
  `backlog/`.

Record the split: how many filed tasks went to `next/` and how many to
`backlog/` (see Report Format).

## Report Format

End with exactly this structure:

    ## Summary
    2–5 sentences: what the work is, whether it meets the bar, and the most
    important finding.

    ### Findings
    - [SEVERITY] one line each, with file references
    - FILED → next/:    docs/tasks/next/<id>-<slug>.md    (warm-routed)
    - FILED → backlog/: docs/tasks/backlog/<id>-<slug>.md (default)

    VERDICT: EXCELLENT | FILED — <n> (<x> → next/, <y> → backlog/) | BLOCKER — <reason>

List one FILED line per task filed, marking its destination. The `VERDICT:` line
must be the last line of your output; on a FILED verdict it carries the routing
split (e.g. `FILED — 3 (1 → next/, 2 → backlog/)`).
