Close `review/` tasks to `done/` — two gates, your choice of proof.

`work` finishes a task and moves it `doing/ → review/`. From there `done/` is a
human sign-off (`git mv review/… done/`). `promote` automates that last hop two
ways:

- **Default (test-gated, pure shell)** — a task whose **Tests** field names suite
  scripts that all run green closes itself; everything else waits for a human.
  Automation never *guesses* a task is done; it demands a passing suite.
- **`--audit` (AI acceptance judge, opt-in)** — for work without an automated
  suite, an AI reads each task's **Done when (automated)** and judges whether the work
  that landed meets them. It reports by default and moves nothing; add `--move`
  to close the DONE ones. See **Acceptance audit** below.
- **`--accept <id>`** — your sign-off for one task with no **Tests**: it
  closes to `done/`. Named Tests still run and must pass, and the **Held** and
  **Depends on** holds still apply. This is the close line work's end-of-run
  checklist prints.
- **`--reject <id> "what is wrong"`** — send a `review/` task back as a
  linked fix task. See **Reject** below.
- **`plan:N`** — sign off a whole plan in one batch: the full suite once, then
  one approval. See **Plan sign-off** below.

Before closing anything, promote files the ### Doc follow-ups recorded in
review/ and done/ into the one open backlog task that tracks them (see
`./sprint.sh help work`); --dry-run files nothing.

**Two gates, one lifecycle.** The same dependency edge that gates the *run*
also gates the *close*: **`Depends on` gates `work`** (a task does not run until
every prerequisite has landed — `review/` with a `**Proof**:` line — or reached
`done/`), and **`Tests` gates `promote`**
(a task does not close until its suite scripts pass **and** its prerequisites
are already closed). So a dependent never lands in `done/` ahead of the work it
needs — a review/ task whose prerequisite is still open (or in review,
unproven) is *held*, named with its stage, and released automatically on a later run once that prerequisite
closes (a chain closes over successive `promote` runs).

## The contract

Each task in `docs/tasks/review/` may name the suite scripts that prove it:

    **Tests**: docs/tests/test-plan-lifecycle.sh

- One path, or several (comma- or space-separated) — **all** must pass.
- Paths must live under `docs/tests/`. A path elsewhere is treated as a
  mis-authored field and the task stays put — promote never runs an arbitrary
  script.
- Product test *loops* (`./sprint.sh newtest` markdown) are not **Tests**.
- `none` (the template default) or no field → not automatable. The task stays
  in `review/` for your sign-off: `./sprint.sh promote --accept <id>` closes it.
  Automation never guesses a task is done.
- Write **Tests**. Readers still accept legacy **Proven by** for one window.

**Docs** vs **Tests**: **Docs** is what you read while building; **Tests** is
what promote runs to close.

## What it does

For each task in `review/` (or just `[id]`):

1. Read **Tests** (or legacy **Proven by**). `none`/missing → skip (report it,
   leave in `review/`).
2. A **Held** task waits until every fix it names is in `done/`. Check
   **Depends on**: any prerequisite not yet in `review/`/`done/` (still in
   `backlog/next/doing/blocked`, folded, or missing) → *hold* the task, name the
   open prereq and its stage, and leave it in `review/`. Holds self-clear.
3. Run each named test (once per run, even if two tasks share it).
4. Every test green **and** every prerequisite closed → `git mv review/… done/`
   (`|| mv`). Messaging may say “proven green”; the field name is still
   **Tests**. Any test failing, missing, or out-of-tree → stay in `review/`,
   report why.

After promoting, it names any plan whose every member now sits in `done/` so you
can retire it. Retirement stays explicit — promote never deletes a plan:

    ./sprint.sh plan done <id>

## Reject (`--reject`)

    ./sprint.sh promote --reject 412 "Saving crashes with TypeError
    - export drops the last row
    - human: the empty state reads cramped"

Files a fix task through `newtask` (so its id is drawn under the lock) and
moves nothing:

- The fix task carries `**Fixes**: #412` and copies the original's **Crew**,
  **Plan** and **Tests**; it is listed on that plan under the original.
- Each reported item (a `- ` bullet, else a paragraph, so a multi-line error
  excerpt stays one item) becomes a **Done when (automated)** line: a test to
  add. An item marked `human:` or about look, feel or wording goes under
  **Signoff (human)**. The full report goes in the fix task's `## Test log`.
- The original stays in `review/` with `**Held**: fix #<new>`. It releases its
  dependents once the fix lands, and promote closes it once the fix is in
  `done/`.
- Every dependent that has landed (`review/` with proof) or is signed off
  (`done/`) gets a re-check line in its `## Test log`. `done/` dependents are
  flagged in the output and stay where they are.

Output:

    ✓ Filed fix task #415 → docs/tasks/backlog/415-fix-412-….md
      **Fixes**: #412 · **Crew**: alice · **Plan**: 28
      #412 stays in review/ with **Held**: fix #415
      ↺ #413 (landed) builds on #412 — re-check line added to its ## Test log
      ⚑ #409 is signed off (done/) and builds on #412 — re-check line added, not moved

Scripts reuse the same path: `sprintbias_file_fix_task ID "report"` in
`lib.sh`.

## Plan sign-off (`plan:N`)

    ./sprint.sh promote plan:28

Signs off a whole plan at once: the full suite runs once, and you approve the
plan's human test with one answer.

0. **Your results first.** When the plan's human test (the `**Owner**: human`
   task `plan start` made) has `- fail: <what you saw>` lines under
   `## Results`, each becomes a fix task (`--reject` style, held on the human
   test, listed in the plan) and the line turns into `- filed #N: …`. Nothing
   moves; exit 1. This runs at any plan state, so an early test run feeds the
   agents at once.

1. The plan must read **LANDED** (every member in `review/` with a proof line,
   no open fix task; see `./sprint.sh plan check`). Otherwise promote names each
   open, unproven or missing member, each held original once as
   `held: fix #N`, and each open fix task, then stops.
2. It lists the landed members in dependency order and runs your project's
   full suite once: the `TEST_SUITE` command in `docs/sprintbias/config`
   (e.g. `TEST_SUITE=npm test`), with stdin closed; the output goes to
   `docs/tmp/promote-plan-N-suite.log`. With `TEST_SUITE` empty it says no
   suite ran and goes on to the checklist.

   **Reuse.** A green run writes a pass stamp,
   `docs/tmp/promote-plan-N-suite.pass`, keyed to a fingerprint of the working
   tree (every tracked and untracked, non-ignored file, minus `docs/tmp/`) and
   the `TEST_SUITE` command. The next `plan:N` on the same tree skips the suite
   and says so in one line with the run's time, so the lead's run at plan close
   makes yours free. Any change re-runs it; `--fresh` always does; a failed run
   clears the stamp. Without git there is no fingerprint, and the suite runs
   every time. The stamp is a cache: delete it freely.
3. **Suite fails** → a fix task per member whose `### Files changed`,
   **Touching:** or **Tests** paths appear in the failing lines (the plan's
   last member when none match), filed like `--reject` with the failing output.
   Nothing moves; exit 1.
4. **Suite passes** → the human test, refreshed first: the plan's and every
   member's `## Signoff (human)` items, tagged `#ID:`, and each member's
   `### Assumptions`, tagged `#ID assumed:`. An older plan gets its human test
   here. Answer `y` and every member and the human test move to `done/`. Any
   other answer, or no answer (stdin closed), moves nothing and says how to
   report a failure.

Output (suite green):

    Plan 90 is LANDED. 4 task(s) to sign off, in dependency order:
      #742  store
      #741  api
      #743  ui
      #744  Human test for plan 90: Batch

    Running the full suite once:  bash docs/tests/run-all.sh
    ✓ Full suite passed. Output: docs/tmp/promote-plan-90-suite.log

    Human test #744 — run these, then approve once:
      docs/tasks/review/744-human-test-for-plan-90-batch.md

      - [ ] Walk the whole flow once
      - [ ] #741: Call the API from a browser
      - [ ] #742 assumed: The scanner sends one line per barcode
    …
    Approve plan 90 and move 4 task(s) to done/? [y/N]

`promote <id>` still signs off one task at a time. The human test is the one
exception: `promote` and `--audit` pass over it, and it closes only with
`plan:N`.

## Acceptance audit (`--audit`)

Three questions sit at the end of the lifecycle; keep them straight:

- **promote** (default) asks *"do the **Tests** pass?"* — correctness proof.
- **polish** asks *"is there a bounded gap worth another pass?"* — excellence.
- **promote --audit** asks *"is **Done when (automated)** met?"* — acceptance.

`--audit` judges each `review/` task independently in a fresh context against its
own Done when (automated) (an older `## Success criteria` reads as it) and
`## Completed` section (protocol
`docs/sprintbias/ai/accept.md`), never editing anything, and prints a
`DONE` / `NOT-DONE` verdict with a reason per task. It is opt-in because it
crosses the default's "never guess" line on purpose — you are trusting an AI
sign-off in place of a suite.

It **moves nothing by default** — that's report-only, so you can read the
verdicts first. Add **`--move`** to actually close the DONE tasks
`review/ → done/`. The same **Depends on** hold applies: a DONE task whose
prerequisite is still open is held in `review/`, never moved ahead of the work
it needs. When you are unsure, the judge is told to return NOT-DONE — closing to
`done/` is a one-way door.

`--audit` honors a leading `-c`/`-g` provider flag and `--model` like the other
AI passes, and `SPRINTBIAS_MODEL_ACCEPT` / config `MODEL_ACCEPT` pin its model.

## Usage

    ./sprint.sh promote              # gate every review/ task with **Tests**
    ./sprint.sh promote 293          # only task #293
    ./sprint.sh promote --dry-run    # run the tests, report verdicts, move nothing
    ./sprint.sh promote --audit      # AI acceptance judge: report DONE/NOT-DONE, move nothing
    ./sprint.sh promote --audit --move    # …and close the DONE ones to done/
    ./sprint.sh promote --audit --move 293  # audit and close just task #293
    ./sprint.sh promote --accept 293 # your sign-off: close #293 (no Tests)
    ./sprint.sh promote --reject 293 "what is wrong"  # linked fix task; #293 held
    ./sprint.sh promote plan:28      # sign off plan 28: full suite once, one approval
    ./sprint.sh promote plan:28 --fresh  # …re-running the suite even when a green run is reusable

Exit 0 when nothing failed its test; 1 when a named test failed (those tasks
stay in `review/`). Tasks skipped for having no **Tests**, and tasks *held* by
an open `Depends on` prerequisite, do not fail the run — the summary prints how
to close each (`promote --accept <id>` or set **Tests** for skips; promote/finish
the prerequisite for holds, then re-run). Failed rows already list the suite
path reason; the footer repeats the re-run command. `plan:N` exits 1 when the
full suite fails, 0 otherwise.

## Related commands

    work    — execute READY tasks from next/ → review/ (produces promote's input)
    polish  — quality sweep of review/; reopen a task worth another pass
    plan done — retire a plan once every member reached done/ (promote points here)
    gate    — workability gate on next/ (a different gate, before work, not after)

See also: `docs/guides/running-tests.md` (platform suite ladder).
