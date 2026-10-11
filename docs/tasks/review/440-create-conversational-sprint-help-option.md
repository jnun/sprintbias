# Task 440: create conversational sprint help option

**Feature**: none
**Created**: 2026-10-10
**Docs**: none
**Plan**: none
**From plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: none
**Refined**: 1
**Reworked**: 0

## Problem

A new user, or an agent, knows what they want to do but not which of the ~30
commands does it. Today they have two options: the static `./sprint.sh help`
list, or reading `DOCUMENTATION.md` end to end. They need a conversational help
that opens with "What command would you like to understand better?", lets them
ask in plain words, and answers with the right `./sprint.sh` command and a
short reason.

The goal is to save context: a quick, deterministic lookup that returns one
small help page, so neither an agent nor a person has to hold the whole
manual in memory to find one command.

## Done when (automated)

- [x] `./sprint.sh help <plain words>` resolves the words to one command and prints that command's help page, exactly as `help <cmd>` does today (demo line included). Matching tries the exact name first, then the words joined (`new idea` → `newidea`, case-insensitive), then a keyword match over `help/_registry` names and descriptions. Proven by `bash docs/tests/test-help-resolve.sh`.
- [x] When several commands match, help prints a short candidate list (name plus its one-line registry description) and exits 0. When nothing matches, it prints one line saying so plus the pointer to `./sprint.sh help`, and exits 1. Proven by `bash docs/tests/test-help-resolve.sh`.
- [x] Existing behavior is unchanged: `help work`, `work --help` and bare `help` print what they print today. When stdin or stdout is not a terminal, bare `help` prints the static list, never prompts, and returns immediately (for example `./sprint.sh help </dev/null` exits 0 with no waiting). Proven by `bash docs/tests/test-help-resolve.sh`.
- [x] On a real terminal, bare `./sprint.sh help` ends with the live prompt `What command would you like to understand better? (Enter to skip)`. The answer goes through the same resolver, and Enter alone exits 0. On a miss, it offers `Ask the AI instead? [y/N]`. A yes opens a read-only AI session seeded with the question. A no, or Enter, exits. Proven by `bash docs/tests/test-help-resolve.sh`, which simulates the terminal or stubs the AI call, so no real AI runs in the suite.
- [x] The AI fallback session is read-only (it edits no files). It is grounded in `DOCUMENTATION.md`, `help/_registry` and `help/*.md`, and answers with the exact `./sprint.sh` command(s) to run plus a short reason. It honors `-c` / `-g` and the configured provider like other AI commands. Proven by inspecting the session's guidance file and the test's stubbed invocation.
- [x] The surfaces are in step. `DOCUMENTATION.md` and `docs/guides/command-matrix.md` describe `help <plain words>` and the terminal prompt, and `CHANGELOG.md` has one `### Added` bullet under `## Unreleased`. `./sprint.sh validate --commands` and `bash docs/tests/run-all.sh` pass.

## Signoff (human)

- [ ] In a terminal, run `./sprint.sh help`, type `new idea` at the prompt, and confirm you land on the newidea page with its examples.
- [ ] At the prompt, type `how do I get my plan into the sprint?` and confirm you land on the plan page (it covers `plan start`). Run `./sprint.sh help` again, type `how do I undo a commit`, answer `y`, and confirm the AI answers with a `./sprint.sh` command or says none fits, with a short reason, and changes no files.
- [ ] As an agent would, run `./sprint.sh help new idea` and `./sprint.sh help idea`, and confirm each answer is instant and useful with no prompt.

## Notes

- The quickest path for both people and agents is deterministic: plain words resolve to a command with no AI. The AI is a fallback for a miss, offered only at a terminal, so agents and CI never reach it.
- `help` is not a row in `help/_registry` (it is handled in `sprint.sh`'s dispatcher), so no new registry row or `help/help.md` is needed unless `validate --commands` asks for one.
- Use the same terminal check bare `chat` already uses (`[ -t 0 ] && [ -t 1 ]`, see `docs/sprintbias/scripts/chat.sh`).
- Keep the AI fallback's guidance short (minimize context cost): load the registry and the manual, answer, stop. Where the session lives is the implementer's call: a small script, or an entry point reusing the chat machinery.
- Decided: one task, not a plan, because it is a single path in `sprint.sh` plus one guidance file and one test.
- Decided (with the author): keep the AI fallback, because a person at a terminal with a question that matches no command still deserves an answer. It stays opt-in, offered only on a miss and only at a terminal. The deterministic resolver is the core and must never load the manual itself; it prints only the one matched page or the short candidate list.
- Decided: a no-match exits 1 and a candidate list exits 0, so agents can branch on the result.

- Decided: the terminal check is overridable by the test (an env hook, or a stubbed `[ -t ]` path) so the suite proves the prompt and the y/N fallback without a real TTY or a real AI; the implementer picks the hook.
- Decided: the AI fallback runs through the provider's interactive entry point with read-only tools (the Claude profile already passes `--allowedTools` / `--permission-mode` on its interactive path, `docs/sprintbias/cli/claude.sh`), because that keeps `-c` / `-g` and the configured provider for free.

## References

sprint.sh
docs/sprintbias/help/_registry
docs/sprintbias/help/newidea.md
docs/sprintbias/scripts/chat.sh
docs/sprintbias/ai/conversation.md
DOCUMENTATION.md
docs/guides/command-matrix.md
docs/tests/test-sprint.sh

## Grounding

**Sources:** `docs/sprintbias/help/_registry` (the command catalog, source of truth for names and one-line descriptions), `sprint.sh` (dispatcher: `show_help`, `show_command_help`, `demo_for_cmd`, the `help` case arm), `docs/sprintbias/scripts/check-commands.sh` (`validate --commands`; `HIDDEN=" help "` keeps `help` out of the registry check), `docs/sprintbias/cli/claude.sh` and `docs/sprintbias/cli/grok.sh` (interactive AI entry points), `docs/sprintbias/ai/` (AI guidance files), `DOCUMENTATION.md` (manual), `docs/guides/command-matrix.md` (command surfaces), `CHANGELOG.md`.
**Touching:** `sprint.sh`, `docs/sprintbias/scripts/help-ask.sh` (new), `docs/sprintbias/ai/help-ask.md` (new), `docs/tests/test-help-resolve.sh` (new), `DOCUMENTATION.md`, `docs/guides/command-matrix.md`, `docs/guides/provider-reality.md`, `CHANGELOG.md`
**Terms:**
- None. The project has no glossary or project map (`docs/sprintbias/project.md` is absent).
**Conflicts:**
- Today `help <unknown>` prints "Unknown command" and exits 1 (`show_command_help`, `sprint.sh`); this task routes a non-exact name through the resolver → keep exit 1 and the `./sprint.sh help` pointer on a true miss, so scripts that branch on it still work.
- `help` has no registry row or `help/help.md`, and `check-commands.sh` hides it on purpose → keep it that way; document `help <plain words>` in `DOCUMENTATION.md` and the command matrix only.
- The Grok profile's interactive path may not expose the same read-only tool list as Claude's → enforce read-only through whatever the profile supports (tool list or permission mode) and record what Grok actually does in `docs/guides/provider-reality.md` if it differs.

## Refine (round 1)

**Sharpened:** Turned a title-only stub into a brief. `help <plain words>` resolves to a command's help page with no AI. On a real terminal, bare `help` ends with a live prompt that goes through the same resolver, and the AI is offered only on a miss.

## Questions

**Status: READY**

### Already complete
None — no matching implementation found.
- `sprint.sh` `help` arm calls `show_command_help "$1"` with only the first word; no join, keyword match, candidate list, or terminal prompt.
- `docs/tests/test-help-resolve.sh` does not exist.
- No AI guidance file for a help fallback in `docs/sprintbias/ai/`.
- Reusable pieces exist: the registry parser pattern (`print_command_group`, `demo_for_cmd`), the `[ -t 0 ] && [ -t 1 ]` check in `chat.sh`, and the interactive provider launch with `--allowedTools` in `cli/claude.sh`.

### Remaining work
- Resolver in `sprint.sh` for `help <words>`: exact name → joined words (case-insensitive) → keyword match over registry names and summaries; one hit prints the page, several print a candidate list (exit 0), none prints one line plus the pointer (exit 1).
- Bare `help` on a real terminal ends with the prompt; non-terminal stays the static list with no wait.
- Opt-in, read-only AI fallback on a miss at a terminal, with a short guidance file; honors `-c` / `-g`.
- New `docs/tests/test-help-resolve.sh` covering all of the above with a simulated terminal and stubbed AI.
- `DOCUMENTATION.md`, `docs/guides/command-matrix.md`, and a `CHANGELOG.md` `### Added` bullet; `./sprint.sh validate --commands` and `bash docs/tests/run-all.sh` pass.

### Questions for the developer
None — task is fully defined.

## Completed

### Assumptions
- Decided: keyword match requires every content word to appear in a command's name or registry summary (filler words dropped, plural s ignored), and keeps the matches whose name holds the most words, because AND matching keeps candidate lists short and lands `help idea` / `help task` on one page.
- Decided: the AI is offered after a candidate list as well as after a miss, because a list still leaves the person without one answer; a single page offers no AI.
- Decided: `how do I get my plan into the sprint?` resolves deterministically to the plan page (its summary names `start` and `sprint`), so the second signoff now uses a question no command covers to reach the AI.
- Decided: answering no (or Enter) at `Ask the AI instead?` exits 0, because the person ended the help session on purpose; the agent-facing `help <words>` miss keeps exit 1.
- Decided: the static `help` list gains one line, `help <plain words>`, because agents read that list to learn what help can do; every other line is unchanged.
- Decided: the test hook is `SPRINTBIAS_HELP_TTY=1/0`, which forces the terminal check on or off.
- Decided: read-only is enforced by `--permissions plan` (both CLIs list `plan` as a `--permission-mode`) plus `--tools Read,Grep,Glob`, with fast mode held off inside `help-ask.sh` so `--skip-permissions` never outranks plan mode. Recorded as KK-18c in `docs/guides/provider-reality.md`.
- Decided: candidate summaries are cut to one terminal line (65 chars + …), because a few registry summaries run several hundred characters.

### Files changed
- sprint.sh
- docs/sprintbias/scripts/help-ask.sh
- docs/sprintbias/ai/help-ask.md
- docs/tests/test-help-resolve.sh
- DOCUMENTATION.md
- docs/guides/command-matrix.md
- docs/guides/provider-reality.md
- CHANGELOG.md

## Test log
- `bash docs/tests/test-help-resolve.sh` — script died after "Resolve": `out="$(sb help xyzzy …)"` hit `set -e` on the intended exit 1. Test fix: the `sb` / `tty_help` capture helpers end in `|| true`.
- `bash docs/tests/test-help-resolve.sh` — FAIL `no path escape via help words` with `help ../../sprint`: the resolver correctly listed commands matching the keyword `sprint` (no file escape). Test fix: use `help ../help/work`, which must miss with exit 1.

Tests run: `bash docs/tests/test-help-resolve.sh` (48 pass), `bash docs/tests/test-sprint.sh`, `bash docs/tests/test-command-matrix-smoke.sh`, `bash docs/tests/test-no-stale-refs.sh`, `./sprint.sh validate --commands`, `./sprint.sh validate --docs`, `bash docs/tests/run-all.sh` (35/35 scripts).

**Proof**: 2026-10-10 · bash docs/tests/test-help-resolve.sh; ./sprint.sh validate --commands; bash docs/tests/run-all.sh · pass
