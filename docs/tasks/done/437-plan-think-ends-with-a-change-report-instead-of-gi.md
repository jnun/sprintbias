# Task 437: plan think ends with a change report instead of 'git diff' homework

**Feature**: none
**Created**: 2026-10-10
**Docs**: docs/sprintbias/help/plan.md
**Plan**: none
**From plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Fixes**: none
**Crew**: none
**Tests**: docs/tests/test-plan-think-report.sh
**Refined**: 1
**Reworked**: 0

## Problem

A person who runs `./sprint.sh plan think <id>` waits minutes, then is told to
run `git diff` on the plan and its members and `git status` for new delta
tasks. The tool knows exactly what it just touched, yet hands that work back to
the person. They want to read what changed on screen, and keep it as a report,
without leaving the flow.


## Done when (automated)

- [x] On a completed run, plan think prints a "Changes" section listing every file the pass created, edited, moved, or deleted, each with its status (new / edited / moved / deleted) and a one-line summary of what changed (e.g. "Goal reworded; #412 added to members; order 3↔4"), proven by `bash docs/tests/test-plan-think-report.sh`
- [x] The same report is written to `docs/tmp/plan-think-<id>-changes.md` and its path is printed in the completion banner, proven by `bash docs/tests/test-plan-think-report.sh`
- [x] The file list comes from a before/after snapshot the script takes itself (not from the agent's say-so), scoped to the pass: files already dirty before the run are only reported if the pass changed them further, proven by `bash docs/tests/test-plan-think-report.sh`
- [x] Each entry shows a compact diff stat (`+N −M`), and the report ends with an "Unchanged members" line so the person sees what the pass left alone, proven by `bash docs/tests/test-plan-think-report.sh`
- [x] "Next steps" no longer tells the person to run `git diff` / `git status`; step 1 points at the report instead, proven by `! grep -q 'git diff \$PLAN_FILE' docs/sprintbias/scripts/plan-think.sh`
- [x] The partial-run warning path and the run-failed path both print the change report (what was half-updated), and their advice no longer says "Review 'git diff'", proven by `bash docs/tests/test-plan-think-report.sh`
- [x] When held goal questions hand off to `chat plan`, the change report prints before the hand-off (the `exec` today skips everything after it), proven by `bash docs/tests/test-plan-think-report.sh`
- [x] A file that disappears from one path and appears at another with the same basename is reported once as moved (old → new), not as deleted + new, proven by `bash docs/tests/test-plan-think-report.sh`
- [x] The snapshot/diff logic is one documented lib.sh helper (listed in the lib.sh header index) so `plan start`, `polish`, and `chat plan` can adopt it later, proven by `grep -q` on its name in the lib.sh header
- [x] `docs/sprintbias/help/plan.md` names the change report file next to the analysis file, and `CHANGELOG.md` has a `### Changed` bullet under `## Unreleased`, proven by `grep -q 'plan-think-<id>-changes.md' docs/sprintbias/help/plan.md`
- [x] The plan-think prompt asks for **What changed** as one line per touched file, starting with its repo-relative path, and asks for no separate Changes section, proven by `bash docs/tests/test-plan-think-report.sh`
- [x] `bash docs/tests/run-all.sh` passes

## Signoff (human)

- [ ] Run `./sprint.sh plan think <id>` on a real plan; the closing screen tells you what changed without opening git

## Notes

Decided: snapshot the working tree before and after the agent run (content hash of every file under docs/tasks/ and docs/plans/; docs/tmp/ is excluded) and diff the two in shell. This works for untracked new delta tasks and for files that were already dirty, which `git diff` alone gets wrong.

Decided: build a new lib.sh helper for the snapshot, on top of `sprintbias_hash_stdin` (lib.sh, git hash-object with shasum/cksum fallback). There is no existing snapshot to reuse: `sprintbias_change_manifest` reads an `AUDIT_MANIFEST` file, but nothing in the scripts sets it today, and its other sources (task ## Completed, git diff) are not before/after snapshots.

Decided: the change report is its own script-owned file (docs/tmp/plan-think-<id>-changes.md), separate from the agent-owned review file, so a re-run of the agent can never clobber or reorder it.

The one-line "what changed" summary per file comes from the agent's existing **What changed** section of the review file (prompt item 2 in plan-think.sh). Reshape that prompt item so it is one line per file the agent touched, starting with the repo-relative path, then the summary and the lens that drove it. The script parses those lines and joins them to its own snapshot list; add no second "Changes" section. Files the snapshot finds that the agent did not describe still appear, marked "(no summary)" — the snapshot is the truth, the agent only adds words.

Decided: plain text output, no color in the report file; the terminal section may reuse the existing banner style.

Emit mode (prompt handed to the current agent session) cannot snapshot; there, ask the agent to print its per-file **What changed** lines as its final message.

Decided: test-plan-think-report.sh drives plan-think.sh in exec mode through a stub `SPRINTBIAS_CLI` (the pattern in docs/tests/test-audit-code.sh) that edits, creates, moves and deletes fixture files in a temp project, because that proves the snapshot without a live model.

Decided: the snapshot covers docs/tasks/ and docs/plans/ only; ID counters and other framework files a delta `newtask` may bump are out of the report, because the person reviews plans and tasks, not bookkeeping.

Decided: keep the plan-think prompt strings test-finish-rule.sh asserts (## Decided wording, goal-question hold) intact while reshaping item 2, because that suite guards the finishing rule.

Candidate for reuse later: `plan start`, `polish`, and `chat plan` end with the same "go git diff" advice. Out of scope here; file follow-ups if the helper lands cleanly.

## References

docs/sprintbias/scripts/plan-think.sh
docs/sprintbias/scripts/work.sh
docs/sprintbias/lib.sh
docs/sprintbias/help/plan.md
DOCUMENTATION.md

## Refine (round 1)

**Sharpened:** Fixed drift: no work.sh snapshot exists to reuse, so the task now calls for a new lib.sh snapshot helper. Per-file summaries come from the review file's existing "What changed" section, reshaped to one line per file, with no duplicate section. The task now also covers the report printing before the chat-plan hand-off, the run-failed path, move detection, and help and changelog updates.

## Grounding

**Sources:** `CLAUDE.md` / `CONTRIBUTING.md` (docs/ is live; surfaces kept in step; changelog under ## Unreleased), `docs/sprintbias/lib.sh` (header index of shared helpers; `sprintbias_hash_stdin`, `sprintbias_change_manifest`), `docs/sprintbias/scripts/plan-think.sh` (the pass and its closing screens), `docs/sprintbias/help/plan.md` (plan think user help), `DOCUMENTATION.md` (manual), `docs/tests/test-finish-rule.sh` (asserts plan-think prompt wording)
**Terms:**
- None. (The project has no glossary; docs/sprintbias/project.md does not exist yet.)
**Touching:** docs/sprintbias/lib.sh, docs/sprintbias/scripts/plan-think.sh, docs/sprintbias/help/plan.md, DOCUMENTATION.md, CHANGELOG.md, docs/tests/test-plan-think-report.sh
**Conflicts:**
- Task says the snapshot can reuse work.sh (References) vs code: no work.sh snapshot exists and nothing sets `AUDIT_MANIFEST` → build the new lib.sh helper on `sprintbias_hash_stdin`, as Notes decide.
- Hand-off to `chat plan` is an `exec` (plan-think.sh:314) that skips every later line → print the report before the `exec`.
- Emit mode exits early (plan-think.sh:253-270) and cannot snapshot → emit asks the agent to print its per-file **What changed** lines; the snapshot outcomes apply to exec mode only.
- Reshaping prompt item 2 vs test-finish-rule.sh assertions on the same prompt → keep the asserted strings; the full suite (`run-all.sh`) proves it.

## Questions

**Status: READY**

### Already complete
None — no matching implementation found.
- plan-think.sh:321 still says "git diff $PLAN_FILE and members; git status"; :289 says "Review 'git diff'"; the failed path (:325-330) prints no changes.
- No snapshot helper in lib.sh; `sprintbias_change_manifest` (lib.sh:3125) reads an `AUDIT_MANIFEST` no script sets.
- Prompt item 2 (plan-think.sh:219) is free-form "What changed", not one line per file.
- No docs/tests/test-plan-think-report.sh; help/plan.md names only docs/tmp/plan-think-<id>.md.

### Remaining work
- lib.sh snapshot + diff helper (hash every file under docs/tasks/ and docs/plans/, report new/edited/moved/deleted with +N −M), listed in the header index.
- plan-think.sh: snapshot before the run; after it, write docs/tmp/plan-think-<id>-changes.md and print a "Changes" section on the complete, partial, failed and pre-hand-off paths; join agent "What changed" lines by path, "(no summary)" otherwise; end with "Unchanged members".
- Reshape prompt item 2 to one line per touched file starting with its repo-relative path; emit mode asks for those lines as the final message.
- Next steps step 1 points at the report; drop the git diff / git status advice.
- New docs/tests/test-plan-think-report.sh with a stub CLI; help/plan.md names the changes file; CHANGELOG `### Changed` bullet; `bash docs/tests/run-all.sh` passes.

### Questions for the developer
None — task is fully defined.

## Completed

### Assumptions
- Decided: the helper is one function, `sprintbias_change_snapshot take|diff SNAP [ROOT…]`, because one name keeps the two halves together for plan start / polish / chat plan to adopt (follow-up #438).
- Decided: hash every file with one batched `git hash-object --stdin-paths` and fall back to `sprintbias_hash_stdin` per file, because one hash process per file made a snapshot of this repo take ~3.5s; batched it is ~0.15s and the fallback keeps the no-git path.
- Decided: `take` also copies the snapshot roots (one tar stream) into the snapshot dir, because `+N −M` for edited, moved and deleted files needs the before content and git HEAD is wrong for files already dirty.
- Decided: the diff TSV uses `-` for an empty FROM field, because `read` with a tab IFS collapses empty fields.
- Decided: a file the agent does not describe shows "(no summary)"; for a moved file the agent's line is matched by new path first, then old path.
- Decided: in the completed path the report prints right after the completion banner (which names the report file) and before held goal questions, so it is on screen before the `exec` to chat plan; the snapshot dir is removed before that `exec` since it skips the EXIT trap.
- Decided: DOCUMENTATION.md's one-line `plan think` entry stays as it is, because the help page carries the detail and the manual line is still accurate.

### Files changed
- docs/sprintbias/lib.sh
- docs/sprintbias/scripts/plan-think.sh
- docs/sprintbias/help/plan.md
- docs/tests/test-plan-think-report.sh
- CHANGELOG.md

### Follow-ups
- #438 — plan start, polish and chat plan end with the same change report.

### Tests run
- bash docs/tests/test-plan-think-report.sh — 36 passed
- bash docs/tests/test-finish-rule.sh, test-grok-provider.sh, test-command-matrix-smoke.sh — pass
- ./sprint.sh validate --commands; ./sprint.sh validate --docs — clean
- shellcheck -S warning plan-think.sh, test-plan-think-report.sh, lib.sh (helper range) — clean
- bash docs/tests/run-all.sh — 34 of 34 scripts green

**Proof**: 2026-10-10 · bash docs/tests/test-plan-think-report.sh; bash docs/tests/test-finish-rule.sh; bash docs/tests/run-all.sh · pass
