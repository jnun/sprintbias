# Task 475: chat takes several task ids and talks them through in succession

**Feature**: none
**Created**: 2026-10-13
**Docs**: none
**Plan**: none
**From plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: none
**Refined**: 0
**Reworked**: 0

## Problem

A person with several backlog tasks to define has to run `./sprint.sh chat <id>`
once per task and come back to start each one. `chat bugs` now ends with one
`./sprint.sh chat <id>` line per new task, and the natural next step is to
define them all in one go. One command should take several ids and talk them
through one after another, each in a fresh session:

    ./sprint.sh chat 1890                # one task (today)
    ./sprint.sh chat 1890 1891 1892      # several, in succession (this task)

Today `chat.sh` reads only `$1` (`TASK_ID="${1:-}"`) and silently ignores every
other id, so `chat 1890 1891` defines 1890 and drops the rest without a word.

## Done when (automated)

- [ ] `./sprint.sh chat 11 12 13` runs the full `chat <id>` conversation for 11,
      then 12, then 13, in that order, each in its own `chat.sh` process (fresh
      context) — `bash docs/tests/test-chat-multi.sh`
- [ ] Between tasks it shows `[k/N]` progress and the next id; `q` at that
      prompt stops, and the run ends with a one-line tally of the ids done and
      the ids left, the ids left as a copyable `./sprint.sh chat …` line —
      `bash docs/tests/test-chat-multi.sh`
- [ ] An id with no task file is reported in one line and skipped; the rest
      still run — `bash docs/tests/test-chat-multi.sh`
- [ ] A mix of ids and words (`chat 12 bugs`, `chat backlog 12`) fails with a
      one-line usage message and runs nothing; a single id and every existing
      word form (`bugs`, `plan`, `newtask`, folders, no argument) behave exactly
      as before — `bash docs/tests/test-chat-multi.sh`
- [ ] `--model <id>` anywhere in the args applies to every task in the run —
      `bash docs/tests/test-chat-multi.sh`
- [ ] `chat bugs` adds one line after its per-task lines when it filed more
      than one task: `./sprint.sh chat <id> <id> …    # all of them, in order` —
      `bash docs/tests/test-chat-bugs.sh`
- [ ] The command surfaces agree: `./sprint.sh validate --commands` and
      `./sprint.sh validate --docs` pass, and `bash docs/tests/run-all.sh` is green
- [ ] The interactive leave-session cue in `chat.sh` (the `_EXIT_INSTR` text)
      also names a multi-id run as a place `/quit` returns to —
      `grep` check in `test-chat-multi.sh`

## Signoff (human)

- [ ] On a real terminal with Claude Code, run `./sprint.sh chat <a> <b>` on two
      real backlog tasks: each opens a live session, `/quit` moves to the next,
      and `q` at the between-task prompt stops cleanly.

## Notes

> **Origin:** follow-up to the `chat bugs` rework (2026-10-13). `chat bugs` now
> files every bug report into backlog/ (FIXED → deleted, TASK → fix task, DECIDE
> → task carrying one `### Questions for the developer` item) and ends with a
> "Define each queued task:" list of `./sprint.sh chat <id>` lines. This task
> adds the multi-id form that list can then offer in one line.

How `chat` works today (read these before changing anything):
- `docs/sprintbias/scripts/chat.sh` is the dispatcher and the one-task
  conversation. It first strips `--model <id>` from anywhere in the args and
  exports `SPRINTBIAS_MODEL_DEFAULT` (so a child `chat.sh` inherits it), then
  dispatches on the SHAPE of `$1`: empty → menu or sprint walk; `blocked|next|backlog`
  → `chat-folder.sh`; `sprint`, `newtask`, `newplan`, `bugs`, `plan` → their
  scripts; otherwise a numeric id → the rest of `chat.sh` (find the task, build
  the prompt, `sprintbias_run_interactive`). Put the multi-id branch in that
  dispatch, before the single-id path, and keep the single-id path unchanged.
- The proven pattern for running `chat <id>` from a loop is `chat-folder.sh`
  `[d] define it` (around line 300–320): it runs
  `bash "$(dirname "${BASH_SOURCE[0]}")/chat.sh" "$task_id" <>"$(sprintbias_tty)" || true`.
  The `<>"$(sprintbias_tty)"` matters: Claude and Grok TUIs wedge after one
  turn unless stdin is the real pty slave opened read-write (task 335; see the
  comment on `sprintbias_tty` in `lib.sh`). Use the same line per id, and print
  the same "When finished, type /quit (or quit) to return…" cue before each.
- `chat <id>` can already chain to a task's next unfinished dependency (the
  "FINISH, CLOSE, CHAIN" block in `chat.sh`, `_CONTINUE_INSTR`). Leave that
  as it is; the multi-id loop simply runs the next listed id after `/quit`.
- Off a terminal (exec mode without a TTY) `chat.sh` already degrades to a
  single refinement pass per task, so the loop works there too, with no prompt
  between tasks. In emit mode (an agent is driving), hand the agent one prompt:
  the ids in order, define each with the `chat <id>` method, one at a time.
- Resolve ids with `sprintbias_find_task` (lib.sh), the same lookup the
  single-id path uses.

Decisions already made (change only with a reason):
- Decided: the loop lives in `chat.sh`'s dispatch, not a new command or script,
  because it is the same verb on more than one target (guiding principle: fewer,
  sharper commands; common language).
- Decided: one fresh `chat.sh` process per id, because it keeps each session's
  context small, the same reason `chat` hands off dependency chains.
- Decided: a one-key prompt between tasks (Enter = next, q = stop) rather than
  running straight on, because a person often wants to stop after the decision
  that mattered; Ctrl-C also stops (trap INT and print the ids left).
- Decided: duplicate ids run once, in first-seen order.

Surfaces to keep in step (CONTRIBUTING.md → Making a change, step 3):
- `docs/sprintbias/help/_registry` — the `chat` row's args (`[target]` →
  something like `[target | id…]`) and summary.
- `docs/sprintbias/help/chat.md` — prose and the Usage block
  (`./sprint.sh chat <id> <id> …   # several tasks, one after another`).
- `DOCUMENTATION.md` — the `./sprint.sh chat [target]` line in the command list.
- `docs/guides/command-matrix.md` — the `chat \<id\>` row.
- `docs/sprintbias/scripts/chat-bugs.sh` — the "Define each queued task:" block
  in the summary: add the all-ids line when more than one task was filed.
- `CHANGELOG.md` — one bullet under `## Unreleased` → `### Added`.

Testing: model `docs/tests/test-chat-multi.sh` on `docs/tests/test-chat-bugs.sh`.
It builds a throwaway board, points `SPRINTBIAS_CLI` at a stub script, sets
`SPRINTBIAS_MODE=exec`, and drives the real script through `script(1)` to get a
pseudo-terminal. The stub can append the task id it was handed to a log file, so
the test asserts order, skips, and stop.

## References

docs/sprintbias/scripts/chat.sh
docs/sprintbias/scripts/chat-folder.sh
docs/sprintbias/scripts/chat-bugs.sh
docs/sprintbias/lib.sh
docs/sprintbias/help/_registry
docs/sprintbias/help/chat.md
docs/guides/command-matrix.md
DOCUMENTATION.md
docs/tests/test-chat-bugs.sh
CONTRIBUTING.md
