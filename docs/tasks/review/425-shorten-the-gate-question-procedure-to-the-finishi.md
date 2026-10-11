# Task 425: Shorten the gate question procedure to the finishing rule

**Feature**: none
**Created**: 2026-10-10
**Docs**: none
**Plan**: 32
**From plan**: none
**Depends on**: 424
**Dependents**: 429, 430
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-finish-rule.sh, docs/tests/test-open-questions.sh, docs/tests/test-done-when.sh
**Refined**: 0
**Reworked**: 0

## Problem

The gate contract (`sprintbias_gate_contract` in gate-lib.sh, 240 lines before orientation) spends about 60 lines on questions: an ASK / GET / CONVERT / UPDATE / DELETE loop, a "strict bar" paragraph full of micro-choice examples, the Questions-for-the-developer instructions twice, and a BLOCKED section that tells the person to answer questions. Most of it says "decide" in negative or roundabout words, and it loads for every gated task. Its heredoc is unquoted, so the backticks around `Decided: X, because Y` run as a shell command: the gate prompt silently drops the Decided format and prints "Decided:: command not found".

## Done when (automated)

- [x] The contract splices `sprintbias_assume_rule` and states its question procedure in 12 lines or fewer: decide, write the pick into the body, record `- Decided:` in ## Notes; `### Questions for the developer` reads `None — task is fully defined.` for READY and COMPLETE; BLOCKED only when no reasonable reading exists or the task needs access the person holds (`bash docs/tests/test-finish-rule.sh`)
- [x] The old loop ("GET the answer"), the "Bar for an open question" paragraph and the repeated Questions-list instructions are gone; the contract is at least 30 lines shorter (`bash docs/tests/test-finish-rule.sh`)
- [x] Rendering the contract runs no command substitution: it prints the literal `Decided: X, because Y` and writes nothing to stderr (`bash docs/tests/test-finish-rule.sh`)
- [x] The shell invariants still hold: suggestions are taken, an unsuggested question stamps BLOCKED, an untestable Done when stamps BLOCKED (`bash docs/tests/test-open-questions.sh`, `bash docs/tests/test-done-when.sh`)
- [x] The ## BLOCKED section the contract asks for names what is missing (a reading or access) and ends with `./sprint.sh chat <id>` (`bash docs/tests/test-finish-rule.sh`)

## Signoff (human)

Checked in the plan's one human test, #434.

## Notes

Keep the dependency-vs-blocked guidance (it prevents a real misclassification) but say it once. The emit move instruction (`SPRINTBIAS_GATE_MOVE_INSTR`) repeats the question rule; trim it to point at the contract.

- Decided: the gate records each call as a `- Decided: X, because Y` bullet in ## Notes, because `_task_calls` in work.sh greps `- Decided:` anywhere in the file, so Notes and 424's `### Assumptions` both surface in the end-of-run checklist, and Notes is where the gate already writes settled guidance.
- Decided: fix the heredoc by escaping the backticks (or quoting the static part) while keeping the `$1`, orientation and sprint-index expansions, because the contract still interpolates those values.

## References

docs/sprintbias/scripts/gate-lib.sh
docs/sprintbias/lib.sh
docs/tests/test-open-questions.sh
docs/tests/test-done-when.sh

## Grounding

**Sources:** `CLAUDE.md` (guiding principles: minimize context cost, instruct positively), `CONTRIBUTING.md` (docs/ is live, src/ is mirrored by ship.sh), `docs/sprintbias/lib.sh` (`sprintbias_assume_rule`, the finishing rule task 424 rewrites), `docs/sprintbias/scripts/gate-lib.sh` (`sprintbias_gate_contract`, `SPRINTBIAS_GATE_MOVE_INSTR`), `docs/sprintbias/scripts/work.sh` (`_task_calls` reads `- Decided:` bullets)
**Terms:**
- None. (The project has no glossary or lexicon file.)
**Conflicts:**
- Task 424 records calls under `### Assumptions`; this task records them in ## Notes → keep ## Notes for the gate; `_task_calls` reads `- Decided:` bullets anywhere in the file, so both forms reach the person.
- `docs/tests/test-finish-rule.sh` does not exist yet → task 424 creates it; this task adds its gate-contract checks to that file.

## Questions

**Status: READY**

### Already complete
- `sprintbias_assume_rule` exists (`docs/sprintbias/lib.sh:748`) and is spliced into work prompts (`work.sh:996`), but not into the gate contract.
- The heredoc bug is confirmed: `sprintbias_gate_contract x.md` prints `gate-lib.sh: line 140: Decided:: command not found` twice to stderr (unescaped backticks at gate-lib.sh:203 and :234), and the rendered text drops the format.
- The contract body is currently 219 lines (gate-lib.sh:139 to its closing `EOF`); the ASK/GET/CONVERT loop starts at :213 and the "Bar for an open question" paragraph at :230.
- `docs/tests/test-open-questions.sh` and `docs/tests/test-done-when.sh` exist and cover the shell invariants.

### Remaining work
- Splice `sprintbias_assume_rule` into `sprintbias_gate_contract` and replace the question loop, the strict-bar paragraph and the duplicate Questions-list instructions with one short procedure (12 lines or fewer).
- State the dependency-vs-blocked guidance once.
- Make the contract render with no command substitution (literal `Decided: X, because Y`, empty stderr).
- Rewrite the ## BLOCKED instruction to name the missing reading or access and end with `./sprint.sh chat <id>`.
- Trim `SPRINTBIAS_GATE_MOVE_INSTR` so it points at the contract and keeps only the move table.
- Add the gate-contract checks (line budget, removed phrases, at least 30 lines shorter, clean stderr, BLOCKED wording) to `docs/tests/test-finish-rule.sh`; keep `test-open-questions.sh` and `test-done-when.sh` green.

### Questions for the developer
None — task is fully defined.

## Completed

- `sprintbias_gate_contract` splices `sprintbias_assume_rule`; the question procedure is one 7-line paragraph ("Questions in the gate: decide each one"); verdicts and dependencies are stated once; the BLOCKED section names what is missing and ends with `Run ./sprint.sh chat <task-number>.`
- The contract renders 151 lines (was 240) with nothing on stderr: the unquoted heredoc no longer executes the `Decided:` backticks, because the literal now sits in the spliced quoted rule and the paragraph writes it without backticks.
- The emit move instruction routes by the stamp and points at the contract instead of restating the question rule.
- help/gate.md describes the new behavior; CHANGELOG.md has a Changed and a Fixed bullet.

### Assumptions
- Decided: drop the classification label UNCLEAR, because under the finishing rule an unclear outcome is a call the gate decides, so a third bucket only invited parking.
- Decided: write `- Decided: X, because Y` in the gate paragraph without backticks, because the contract heredoc is unquoted (it interpolates `$1` and the orientation) and plain text cannot run as a command.

### Files changed
docs/sprintbias/scripts/gate-lib.sh
docs/sprintbias/help/gate.md
CHANGELOG.md
docs/tests/test-finish-rule.sh

**Proof**: 2026-10-10 · bash docs/tests/test-finish-rule.sh, bash docs/tests/test-open-questions.sh, bash docs/tests/test-done-when.sh, bash docs/tests/test-plan-lifecycle.sh · pass

## Plan Think

FINISHED (review/). The contract renders 151 lines with nothing on stderr, and the question procedure is one paragraph. Architect: removing the shell command substitution fixed a silent data-loss bug. Experience: the gate stops asking about things it can decide. Tension: gate.sh's summary lines (gate.sh:398, :442) still say "needs decision or clarification". They sit outside this task's contract scope, so delta #436 covers them (context-cost and common-language lenses). Left as-is.
