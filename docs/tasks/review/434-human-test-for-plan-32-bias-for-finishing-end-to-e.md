# Task 434: Human test for plan 32: Bias for finishing, end to end

**Owner**: human
**Created**: 2026-10-10
**Plan**: 32
**Depends on**: none
**Tests**: none

## Problem

Agents built plan 32 on reasonable assumptions and simulated tests, and kept
moving. This is the one pass a person makes in the real world: on hardware,
in the live product, by eye. Run it when `./sprint.sh plan check 32` reads
LANDED (earlier is fine; what you find feeds the agents sooner).

## Signoff (human)

Run these in this repo, in order; each builds on the one before. Every check
is a behavior: do what it says and compare what you see with "Expect".
Write a failure under ## Results as `- fail: <check number>: <what you saw>`.

- [x] 1. A chat interviews you to build the task.
  Do: `./sprint.sh newtask "Make the status output friendlier"`, then
  `./sprint.sh chat <id>`.
  Expect: it asks one question at a time, each with a (suggested) answer, and
  waits for you; each answer lands in the task as instruction (Problem, Done
  when (automated), Signoff (human), Notes). Clear-cut points it states in a
  line and records as `- Decided: …`. It ends with the next command,
  `./sprint.sh work <id>`.
- [x] 2. The gate decides instead of blocking.
  Do: run the `./sprint.sh work <id>` it named.
  Expect: the task is gated READY (not moved to blocked/); its ## Notes hold
  `- Decided:` lines; no "Decided:: command not found" anywhere in the output.
- [ ] 3. Work finishes without asking and ends with your checklist.
  Expect (same run): no question to you during the run. The end prints
  "▸ Your turn", the task's calls with the newtask line, a
  `./sprint.sh promote --reject <id> "what is wrong"` line, and, since the task
  has no Tests, `./sprint.sh promote --accept <id>`.
- [ ] 4. Closing is one line.
  Do: run the `promote --accept <id>` it printed.
  Expect: "#<id> accepted → done/ (your sign-off)", and the task is in done/.
- [ ] 5. Only work that cannot start goes to blocked/, and says what to run.
  Do: `./sprint.sh newtask "Rotate the production Stripe key"`, then
  `./sprint.sh work <id>`.
  Expect: it lands in blocked/ because it needs access only you hold, and the
  message ends with `./sprint.sh chat <id>`.
- [ ] 6. One blocked member does not stop a plan.
  Do: `./sprint.sh newtask "Add a --version flag to sprint.sh"`, then
  `./sprint.sh newplan "Review check" <that id> <the id from check 5>`, then
  `./sprint.sh plan start <plan id>`.
  Expect: the new task reaches next/; the Stripe task stays in blocked/ and is
  listed with `./sprint.sh chat <id>`; the human-test line names
  `./sprint.sh promote plan:<plan id>`; the last line is `Next: ./sprint.sh work`.
- [ ] 7. plan think applies its calls and lists them.
  Do: `./sprint.sh plan think <plan id>`.
  Expect: the plan file gains a `## Decided` list; it hands you at most the
  questions that change the plan's goal; its last lines name a command.
- [ ] 8. Every end-of-run message ends in a command.
  Do: `./sprint.sh promote --dry-run`, `./sprint.sh plan check <plan id>`.
  Expect: the last line of each names a `./sprint.sh` command.
- [ ] 9. settle is gone.
  Do: `./sprint.sh help | grep settle` and `./sprint.sh settle`.
  Expect: no match, then "Unknown command: settle".
- [ ] 10. The demo matches the real run.
  Do: `./sprint.sh learn work`.
  Expect: its "Your turn" ending reads like what check 3 printed.
- [ ] 11. The blocked/ sweep decides what it can (#436).
  Do: `./sprint.sh newtask "Pick a color scheme for the status output"`, move
  it to blocked/ (`git mv docs/tasks/backlog/<id>-*.md docs/tasks/blocked/ ||
  mv docs/tasks/backlog/<id>-*.md docs/tasks/blocked/`), then
  `./sprint.sh chat blocked`. The Stripe task from check 5 is there too.
  Press [w] on each.
  Expect: the color-scheme task reads READY with a `- Decided: …` pick; [w]
  writes that line into its ## Notes and the gate sends it to next/. The
  Stripe task reads BLOCKED with `./sprint.sh chat <id>` and stays in blocked/.

Clean up after: delete the throwaway tasks from checks 1, 5, 6 and 11 (they
are in done/, blocked/ and next/), and retire the throwaway plan with
`./sprint.sh plan done <plan id>` or delete its file.

## Results

<!-- sb:hint  One line per check that failed, in your words:
       - fail: the LED stays red after pairing
     ./sprint.sh promote plan:32 files each one as a fix task the agents
     build, then asks you to re-run this test. All passed: leave this empty
     and approve the batch. -->

## Plan Think

FINISHED (review/, Owner: human, unrun). Checks 1–10 cover 424–432 end to end; check 11 is delta #436's person-only check, a real `chat blocked` sweep, so the whole plan is one pass.
