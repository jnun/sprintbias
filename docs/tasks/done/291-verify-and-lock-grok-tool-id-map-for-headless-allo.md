# Task 291: Verify and lock Grok tool ID map for headless allowlists

**Feature**: none
**Created**: 2026-07-30
**Docs**: none
**Plan**: 11
**Depends on**: none
**Blocks**: 292, 296
**Parent**: none

**Status: READY**

## Problem

Headless Grok tool restriction is only as good as the internal ID map in
`cli/grok.sh`. Product docs have used both `run_terminal_cmd` and
`run_terminal_command` for the shell tool; if we map the wrong id, allowlists
fail open or strip shell. Until the live binary’s tool IDs are verified and
pinned with a test, every exec `work` / `gate` / `polish` run under Grok is
guesswork.

## Success criteria

- [x] Against a live `grok` install, record the real internal IDs needed for
      SprintBias’s core surface (at least: read, edit/write, shell, grep, list/dir)
- [x] `cli/grok.sh` map matches live IDs; Bash maps to the verified shell id
- [x] Fail-open on unmapped names remains; Agent/Task still skipped (not in
      `--tools` allowlist)
- [x] Automated test asserts the core Claude-name → Grok-id map (and fails if
      the shell id mapping regresses)
- [x] One-line note in `docs/guides/grok-provider-tier.md` (or capability matrix)
      states verified shell id + re-check date

## Notes

- Prefer probing the running product over stale docs when they conflict.
- Do not invent tool IDs. If an id cannot be verified, leave unmapped and fail
  open with a warning — do not ship a broken empty allowlist.
- `--allowedTools` on Grok is a permission-rule alias; never use it for tool
  allowlists.
- **From #298 burn (KU-01):** live Grok 0.2.114 accepts **both**
  `run_terminal_command` and `run_terminal_cmd` as shell-only `--tools`.
  Prefer emitting `run_terminal_command` (getting-started/hooks/skills); accept
  either as map input. Headless guide still documents `run_terminal_cmd` only
  (doc drift on Grok’s side).
- **From #298 (KU-06):** `--tools not_a_real_tool_xyz` still allowed shell —
  Grok soft-fails bad allowlists. Our fail-open remains correct; do not assume
  strict empty toolset on garbage IDs.
- **From #298 (KU-03):** optional probe — MCP meta-tools under allowlist.

## References

docs/sprintmd/cli/grok.sh
docs/guides/grok-provider-tier.md
docs/tests/test-grok-provider.sh
~/.grok/docs/user-guide/14-headless-mode.md

## Questions

**Status: READY**

### Already complete

- **Tool map (criterion 2, code side).** `_sprintmd_grok_map_tools` in
  `docs/sprintmd/cli/grok.sh:23` maps the full core surface: `Read`→`read_file`,
  `Edit`→`search_replace`, `Write`→`write`, `Bash`→`run_terminal_command`
  (accepting both `run_terminal_command` and `run_terminal_cmd` as input),
  `Grep`→`grep`, `Glob`→`list_dir`. Clean, deduped, matches the KU-01 decision
  to *emit* `run_terminal_command` and *accept* either. What's missing is the
  *live-verified* stamp, not the code — see Remaining work.
- **Fail-open + subagent skip (criterion 3).** COMPLETE. Unmapped names set
  `unknown=1` and `return 1`, so `sprintmd_provider_exec` omits `--tools`
  entirely with a one-shot warning (`grok.sh:43`, `:92`–`:101`).
  `Agent|Task|spawn_subagent` `continue` past the allowlist rather than being
  treated as unknown (`grok.sh:42`). Correct and matches the intent.
- **Automated regression test (criterion 4, mostly).** Test 9 in
  `docs/tests/test-grok-provider.sh:144` asserts the exact map output
  `read_file,search_replace,write,run_terminal_command,grep,list_dir`, the
  Agent-skip case, and the fail-open non-zero on an unknown name. This already
  fails if the shell id regresses. The remaining gap is a positive assertion
  that `run_terminal_cmd` *input* also normalizes to `run_terminal_command`
  (accept-either path is exercised only implicitly).

### Remaining work

The scaffolding is built; this task is now a **verify-and-record** pass, and
`grok` is installed locally (0.2.117), so it can run:

1. **Criterion 1 — record live IDs.** Probe the running `grok` binary and record
   the real internal tool IDs for read / edit-write / shell / grep / list. The
   0.2.117 headless docs (`~/.grok/docs/user-guide/14-headless-mode.md`)
   document the shell tool as `run_terminal_cmd`; confirm empirically whether
   0.2.117 still accepts `run_terminal_command` as a `--tools` entry (KU-01
   observed both on 0.2.114).
2. **Criterion 2 — confirm/pin the map.** If live 0.2.117 diverges from the
   0.2.114 findings, reconcile `grok.sh` accordingly. If it agrees, no code
   change — the pin is confirmed.
3. **Criterion 5 — doc note.** Add the missing one-line entry in
   `docs/guides/grok-provider-tier.md` (the "Tool names" section) stating the
   verified shell id and a re-check date. No such note exists today.
4. **Optional test hardening (criterion 4).** Add an assertion that
   `_sprintmd_grok_map_tools "run_terminal_cmd"` → `run_terminal_command` so the
   accept-either normalization is guarded, not just the emit output.
5. Run `./ship.sh` after any `docs/` edit so the map/test mirror into `src/`.

### Questions for the developer

1. Grok on this machine is **0.2.117**, but the KU notes were burned against
   **0.2.114**. Re-verify against the installed 0.2.117 rather than trusting the
   older burn? (Suggestion: yes — probe 0.2.117 directly; if `run_terminal_cmd`
   is now the only accepted `--tools` shell id, keep *accepting* both on input
   but reconsider which one we *emit*. Verifying the running binary over stale
   docs is exactly what the task's own Notes require.)

## Completed

Verified against the **live `grok` 0.2.117** binary installed on this machine
(`grok --version` → `0.2.117 (f1c06093089f)`).

**Criterion 1 — live IDs recorded.** Probed the running binary with
`grok -p … --output-format streaming-json`. The `available_commands` event
exposes the authoritative internal tool registry. Core surface confirmed:

| Claude name | Live 0.2.117 registry id |
|-------------|--------------------------|
| Read | `read_file` |
| Edit | `search_replace` |
| Write | `write` |
| Bash (shell) | `run_terminal_command` |
| Grep | `grep` |
| Glob (list/dir) | `list_dir` |

The canonical registered **shell id is `run_terminal_command`** (the master
registry lists that form, not `run_terminal_cmd`). Empirically, 0.2.117 accepts
**both** `--tools run_terminal_command` and `--tools run_terminal_cmd`
(each `grok -p … --tools <id>` run exited 0). This matches the KU-01 finding
from 0.2.114 and answers developer Q1: keep *emitting* `run_terminal_command`
(now the registry-canonical form), keep *accepting* either on input. The
headless docs (`~/.grok/docs/user-guide/14-headless-mode.md`) still say
`run_terminal_cmd` — Grok-side doc drift, not a code problem.

**Criterion 2 — map confirmed, no code change.** `_sprintmd_grok_map_tools`
in `docs/sprintmd/cli/grok.sh` already maps the full core surface and emits
`run_terminal_command`. Live probe agrees with the pin, so `grok.sh` is
unchanged — the map is now live-verified, not just doc-derived.

**Criterion 3 — fail-open + subagent skip.** Already correct (unmapped →
`return 1` → caller omits `--tools`; `Agent|Task|spawn_subagent` skipped, not
allowlisted). No change.

**Criterion 4 — test hardening.** Added two assertions to Test 9 in
`docs/tests/test-grok-provider.sh` guarding the accept-either normalization:
`run_terminal_cmd` → `run_terminal_command` and `run_terminal_command`
passthrough. Full suite green: **61 passed, 0 failed.**

**Criterion 5 — doc note.** Added a "Verified shell id" note to the Tool names
section of `docs/guides/grok-provider-tier.md`: canonical id
`run_terminal_command`, accepts either, verified 2026-07-30, re-check on next
Grok minor.

Ran `./ship.sh` (v0.0.55 → 0.0.56); `src/` verified a clean mirror. The two
edited files are dev-only (`docs/tests/`, `docs/guides/`) and do not ship; the
shipped profile `grok.sh` needed no change.

### Files changed

docs/tests/test-grok-provider.sh
docs/guides/grok-provider-tier.md
docs/tasks/doing/291-verify-and-lock-grok-tool-id-map-for-headless-allo.md
