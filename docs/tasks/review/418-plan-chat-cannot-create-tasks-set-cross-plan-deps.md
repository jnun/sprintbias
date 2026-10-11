# Task 418: Plan chat cannot create tasks, set cross-plan deps, or build

**Feature**: none
**Created**: 2026-10-10
**Docs**: none
**Plan**: 30
**From plan**: none
**Depends on**: 415, 417
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-fast.sh
**Refined**: 0
**Reworked**: 0

## Problem

Plan chat may write only its plan file: it cannot create a task, edit one, or set a dependency on a task in another plan, and it has no way to start an agent. A person authoring a plan has to leave the session to run newtask and edit tasks by hand, and a missing piece cannot be built from where it was found.

## Done when (automated)

- [x] In every mode, the plan chat prompt lets the agent run `./sprint.sh newtask`, edit member and non-member task files, set **Depends on** / **Dependents** across plans (both sides, reciprocal), and move tasks between backlog/ and next/ (`bash docs/tests/test-fast.sh` greps the chat-plan prompt with fast off and on)
- [x] With fast on, plan chat passes the full toolset including subagents (`Agent` in `--tools`, as work.sh does) and its prompt allows `plan start`, `work`, and building a missing piece itself or through a subagent, landing it in review/ with a proof line; with fast off the toolset stays `Read,Edit,Write,Bash,Grep,Glob` and the prompt keeps building and starting agents out of reach (`bash docs/tests/test-fast.sh`)
- [x] The plan-file-only boundary is gone everywhere in chat-plan.sh: the "Your ONLY durable write" / "do not run it yourself" BOUNDARY lines, the "you never move or edit task files" opener, the RULES "WRITES: only" and "do not mv task files, do not edit task bodies" lines, the `_OPENING` "Write only the plan file", and the "(read-only over backlog/ …)" banner (`bash docs/tests/test-fast.sh` asserts none of those strings remain)
- [x] In every mode the prompt states that commit, push, `./ship.sh` and moving tasks to done/ stay the human's (`bash docs/tests/test-fast.sh`)
- [x] help/chat.md, help/plan.md and DOCUMENTATION.md describe the wider reach and the fast-only build/start split; `./sprint.sh validate --docs` passes
- [x] `bash docs/tests/run-all.sh` passes

## Signoff (human)

- [ ] In a real `chat plan` session, ask for a missing task and a dependency on another plan's task; both appear without leaving the session

## Notes

Decided with the human (2026-10-10): steady mode gains task create/edit and cross-plan deps (planning work, reversible with git). Building code and starting agents is fast-only. With fast on, `chat plan N` acts as a lead without crew files; `crew` stays for named long-running lanes.

Cross-plan edits follow the rule block from #417 (`sprintbias_fast_rules`): read the other plan's Goal first, serve both goals, and leave `Touched by plan N: #id — what and why` on the other plan. A task keeps its own plan membership. Read the mode only through `sprintbias_fast_on` (#415).

## References

docs/sprintbias/scripts/chat-plan.sh
docs/sprintbias/scripts/work.sh (TOOLS with Agent, line ~165)
docs/sprintbias/help/chat.md
docs/sprintbias/help/plan.md
docs/plans/30-fast-mode-autonomous-agents-fewer-blockers.md (Policy)

## Grounding

**Sources:** `CLAUDE.md` / `CONTRIBUTING.md` (human-owned commit and ship.sh; surfaces to keep in step), `DOCUMENTATION.md` (plans, lifecycle folders, chat), `docs/plans/30-fast-mode-autonomous-agents-fewer-blockers.md` (fast-mode policy), `docs/sprintbias/scripts/chat-plan.sh` (plan chat prompt and toolset)
**Terms:**
- None. (No glossary; docs/sprintbias/project.md not created yet.)
**Touching:** docs/sprintbias/scripts/chat-plan.sh, docs/tests/test-fast.sh, docs/sprintbias/help/chat.md, docs/sprintbias/help/plan.md, DOCUMENTATION.md, CHANGELOG.md
**Conflicts:**
- Done when named `docs/sprintbias/tests/test-fast.sh`; the suite lives in `docs/tests/` and siblings 415–417 create `docs/tests/test-fast.sh` → use `docs/tests/test-fast.sh`.
- Done when said the prompt "still forbids commit, push, ship.sh and done/"; the current chat-plan prompt names none of them → add that line in every mode.
- Done when cited chat-plan.sh:157-158; the boundary text sits at lines 99, 131, 157-158, 174-176 and 181 → remove it by content, not line number.
- Old chat-plan header comment (lines 9-12) says authoring writes only the plan file → update the comment with the prompt.
- "fast" is not yet defined in DOCUMENTATION.md → #415/#417 add it; this task uses that reading.
- DOCUMENTATION.md says tasks enter next/ only through the gate, never a raw mv; this task has plan chat move tasks backlog/ ↔ next/ → the prompt lets a task into next/ only when it reads **Status: READY** with a tested Done when (the gate's bar), and the manual names `chat plan` as that path.
- Claude's profile turns `--tools` into `--allowedTools` → the toolset test reads `--allowedTools` from a stub CLI's argv.

## Questions

**Status: READY**

### Already complete
None — no matching implementation found. Checked:
- `docs/sprintbias/scripts/chat-plan.sh:154-177` still limits the session to the plan file, tells the agent not to run newtask, plan start, or edit/move tasks; widening exists only per checklist line in checklist mode (line 197).
- `chat-plan.sh:213` passes `Read,Edit,Write,Bash,Grep,Glob` with no `Agent`; no fast-mode branch.
- No `sprintbias_fast_on` / `sprintbias_fast_rules` in lib.sh yet (#415, #417); no `docs/tests/test-fast.sh` yet (#415 creates it).

### Remaining work
- Rewrite the chat-plan BOUNDARY / RULES / opener / banner / header comment so every mode allows newtask, task create and edit, reciprocal cross-plan Depends on / Dependents, and backlog/ ↔ next/ moves; add the human-owned line (commit, push, ship.sh, done/).
- Branch on `sprintbias_fast_on`: fast adds `Agent` to `--tools` and a prompt block allowing plan start, work, and building (directly or via subagent) to review/ with a proof line; inject `sprintbias_fast_rules`.
- Extend `docs/tests/test-fast.sh` with the chat-plan prompt and toolset assertions for both modes.
- Update help/chat.md, help/plan.md and DOCUMENTATION.md; run `validate --docs` and the full suite.

### Questions for the developer
None — task is fully defined.

## Test log

- `bash docs/tests/test-fast.sh` — chat plan (on/off) toolset checks failed: the stub argv carries `--allowedTools`, not `--tools` → test reads `--allowedTools`; green.
- `bash docs/tests/test-fast.sh` — 4 "work emit" checks failed: work.sh:1105 (another session's live edit) had backticks inside a double-quoted prompt (`Decided:: command not found`). The other session fixed it; green on re-run.
- `bash docs/tests/run-all.sh` — command-matrix-smoke and open-questions failed once while other sessions were editing; both pass alone and in the re-run suite (29/29).

## Completed

Plan chat now does planning work in every mode: newtask, edits to member and other plans' tasks, reciprocal cross-plan **Depends on** / **Dependents** (plus the `Touched by plan N` note), and backlog/ ↔ next/ moves for READY tasks. The human-owned line (commit, push, ./ship.sh, done/) is in every mode. With fast on, `--tools` adds `Agent` and a FAST MODE block allows `plan start`, `work`, and building a missing piece (directly or through a subagent) to review/ with a proof line. With fast off, a RULES line keeps building and agent starts with fast mode. All the plan-file-only strings and the read-only banner are gone. The header comment is updated.

### Assumptions
- Moves into next/ follow the gate's bar (READY plus a tested Done when), so next/ stays trustworthy without running the AI gate from chat.
- The cross-plan rule (read the Goal, serve both goals, `Touched by plan N`) is in the REACH block in every mode, not only in fast via `sprintbias_fast_rules`, because steady mode also edits other plans' tasks now.

### Files changed
- docs/sprintbias/scripts/chat-plan.sh
- docs/tests/test-fast.sh
- docs/sprintbias/help/chat.md
- docs/sprintbias/help/plan.md
- DOCUMENTATION.md
- CHANGELOG.md

### Overlap
- work.sh was being edited by another session during this task (backtick bug at line 1105, since fixed there). Not touched here.

Tests run: `bash docs/tests/test-fast.sh` (104/104), `./sprint.sh validate --docs`, `./sprint.sh validate --commands`, `bash docs/tests/run-all.sh` (29/29 scripts).

**Proof**: 2026-10-10 · bash docs/tests/test-fast.sh; ./sprint.sh validate --docs; bash docs/tests/run-all.sh · pass
