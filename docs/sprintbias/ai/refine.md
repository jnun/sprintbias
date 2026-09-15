# Refine Protocol

Judge one finished task against a higher bar than "it runs," exactly like the
excellence audit — but with a different lever. Where `excellence` files
*separate* backlog tasks and never touches the work, `refine` decides one
thing: **is this task worth reopening for another execution pass?** If yes, you
rewrite the task with a concrete, bounded set of improvements and send it back
to `next/`, where `work` will re-execute it in a fresh context.

You still never edit product code. Your only writes are to the task file.

## The Bar

There is a difference between a car that technically runs and one that is
engineered as a system. Both "work." Only one is good. "It runs" is the
minimum, not the standard. You judge for the second kind — but you only act
when a *second execution pass* would close the gap.

## Posture

- **Presume correctness ONLY when a code audit passed.** Read the task's
  `## Audit` marker (`polish --code` writes it), exactly as excellence does:
  `audited` when a plain `## Audit` section records a PASS or FIXED **Final
  verdict**; `unverified` when there is no such section; `failed` when a
  `## Audit` records FAIL/BLOCKED/UNCLEAR (worse than unverified — an audit ran
  and did not clear the work). When `audited`, do not re-litigate syntax, style,
  or conventions — that audit already ran; judge altitude only. When
  `unverified` or `failed`, do NOT presume correctness: a defect you stumble on
  **cannot be waved through as PASS**. Record it and let the verdict fall to
  BLOCKER, with a reason that sends the developer to `./sprint.sh polish --code`
  to establish correctness before this work can clear. Either way you never fix
  it — your only write is the task file.
- **You never edit product code. Not one line.** Your only permitted write is
  the audited task file itself: appending a `## Rework (round N)` section. You
  do NOT touch the `**Reworked**:` header — the runner owns that counter and
  increments it when it confirms your reopen.
- **Judge against the project's own rules first.** Check CLAUDE.md and
  `docs/sprintbias/project.md` before flagging a design choice. A finding that
  contradicts a documented, deliberate decision is a false positive.

## Method

1. **Re-read the original task — header included.** Problem and Success
   criteria are the yardstick, not the diff. **Feature** is the spec it
   serves, **Docs** the guide it should have followed, **References** the
   author's own map of files to reuse.
2. **Read the changed files and their blast radius.** Start from the task's
   `### Files changed` list, then grep for what imports or calls them.
3. **Trace the end-to-end path** as the person who will actually use this —
   entry point → the change → outcome. The highest-value gaps live where the
   path breaks: a capability that exists but cannot be invoked, a config with
   no way to set it, a state you can enter but not leave.
4. **Judge each dimension exactly as the excellence protocol defines them** —
   follow `docs/sprintbias/ai/audit-excellence.md` → Dimensions as the single
   source of truth (Effectiveness; Efficiency with its scale-gated probe set;
   Design fit; Operability; Robustness; Antifragility). Judge the same set
   excellence judges — do not keep a second, hardcoded copy here that drifts.
5. **Decide the verdict** using the routing rules below.

## The one decision: reopen or not

Reopening is not free — it re-runs the task through `work`, spending another
budget cycle. Reopen only when ALL of these hold:

- The gap is **substantive** — it changes whether the work meets its own
  Success criteria or the engineering bar, not a cosmetic nit.
- The fix is **concrete and bounded** — you can name the specific action items,
  and they fit in one more execution pass. "Redesign the module" is not
  bounded; "make the `--json` flag actually reachable from the CLI dispatch"
  is.
- The fix is **mechanical to re-run** — a fresh executor with the task in hand
  could implement it without new human decisions. If it needs a human choice
  (which of two designs? is this even wanted?), it is not a reopen — it is a
  BLOCKER for human attention.

If those do not all hold, the task PASSES. Zero reopens across a whole sweep is
a legitimate, common outcome. Do not invent improvements to look thorough — a
needless reopen costs real money and churns the queue.

## When you reopen

The `## Rework` section is the brief — for the human skimming the kickback and
for the next executor picking the task up cold. Write it so a reader can skim
the titles in about a minute and name every remaining gap, then drop into any
one item and know what "done" looks like. Append this section to the END of the
task file, in this shape:

    ## Rework (round N)

    **Why:** A few sentences — the case for spending another pass. What still
    falls short of the bar and why it is worth another cycle. This is an
    argument, not a second copy of the Improve list.

    **Improve:**
    - [ ] **Short title** — one-line done-look: what must be true when this item
          is done, at user-story or technical-spec height.
          Hint: optional starting points — files, anchors, search terms.
    - [ ] **Another title** — its own one-line done-look, verifiable on its own.

Each Improve item has two required parts and one optional part:
- A **bold short title** — the scannable name of the gap. A reader skimming
  only the titles should be able to list every remaining gap.
- A **one-line done-look** — the outcome the next executor can verify: what is
  true when the item is done, written at user-story or technical-spec height,
  not a step-by-step edit recipe.
- An optional indented **Hint:** line — file paths, anchors, or search terms as
  starting points only. Hints help the executor find evidence faster; they
  never define done.

Rules for the reopen section:
- Use the exact round number N given to you in the prompt. This heading is
  polish's alone — keep it distinct from any pre-work `## Refine` section, so
  the round counter never conflates the two operations.
- Every improvement is an **unchecked** `- [ ]` item — this is the new work.
- Define outcomes, not brittle edits. Do NOT prescribe line-specific surgery
  (`path:line`) or "change field N" as the work itself — those assumptions
  usually rot before `work` re-runs. File paths and anchors belong under an
  optional `Hint:`, never as the definition of done.
- **Improve is the single remaining-work list on the task.** Do not add a
  parallel checklist under Questions or anywhere else that restates the same
  items — one list, no duplicate essay.
- Keep **Why** short. It is the case for another pass, not a re-listing of the
  gaps already named in Improve.
- A title may use a shared excellence dimension name when it sharpens the gap
  (Effectiveness, Efficiency, Design fit, Operability, Robustness,
  Antifragility — the Dimensions set you already judged against). One shared
  vocabulary across both surfaces; do not coin a second private tag scheme, and
  do not let a dimension prefix bloat a title past a skim.
- Do NOT uncheck or alter the task's existing Success criteria or its
  `## Completed` section. The executor needs that history intact.
- Do NOT remove the task's `**Status: READY**` stamp if present — it must
  survive so `work` picks the task up without a re-gate.

Reopen discipline is unchanged (see § The one decision): the vital few,
substantive, bounded, mechanically re-runnable. Clearer organization is not a
license for more items — a scannable list of five is still five.

## Report Format

End with exactly this structure:

    ## Summary
    2–5 sentences: what the work is, whether it meets the bar, and — if you are
    reopening — the single most important reason.

    VERDICT: PASS | REOPEN — <n> improvement(s) | BLOCKER — <reason>

- **PASS** — meets the bar, or the only gaps fail the reopen test above. The
  task stays in `review/`. (exit 0)
- **REOPEN** — you appended a `## Rework (round N)` section; the runner bumps
  the `**Reworked**:` counter and moves the task to `next/` for another pass
  (`git mv SRC DEST || mv SRC DEST`). (exit 0)
- **BLOCKER** — the work fails its own goal and the fix needs a human, not a
  re-run; or you stumbled on a genuine defect while correctness was `unverified`
  or `failed` — that cannot PASS, and the reason points the developer to
  `./sprint.sh polish --code`. The task stays in `review/` for attention.
  (exit 1)

The `VERDICT:` line must be the last line of your output, one uppercase token
after the colon, nothing after it but an optional short reason.
