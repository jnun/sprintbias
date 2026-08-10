# Task 335: fix chat define path so the interactive session reliably takes input

**Feature**: none
**Created**: 2026-08-02
**Docs**: none
**Plan**: none
**Depends on**: none
**Dependents**: none
**Parent**: none
**Tests**: none
**Refined**: 1
**Reworked**: 0

<!-- Plan: which docs/plans/N-… this belongs to (membership reverse index).
     Depends on: task IDs that must finish first.
     Dependents: reverse edge — task IDs that wait on this one.
     Parent: task-to-task grouping only (not Plan).
     Docs: guide to read while building.
     Tests: docs/tests/*.sh that prove success criteria for `promote`
     (all must pass → review/ to done/). Product newtest loops are not Tests.
     Legacy aliases (read only): Dependents←Blocks, Tests←Proven by.
     Write only the canonical names. -->

## Problem

When a `./sprint.sh chat <folder>` sweep launches a define session via `[d]`,
the interactive `claude` wedges after its first turn: it prints its reply, then
stops accepting input — keystrokes don't register, `Ctrl-L` won't repaint. The
only escape is to kill it, which also leaves the `sprint.sh → chat-folder.sh →
chat.sh → claude` pipeline holding the task file mid-define (zombie stacks
accumulate). This makes the sweep's define path — the core of `chat <folder>` —
unusable.

**Leading root-cause hypothesis (strong evidence; one confirming experiment
still owed — see criterion 1):** the `[d]` handoff launches the interactive
child with stdin redirected from `</dev/tty`, which opens the terminal
**READ-ONLY**. Every wedged specimen shows stdin `0r  /dev/tty` (device 2,0,
O_RDONLY); a healthy interactive `claude` shows `0u  /dev/ttysNN` (the pty
slave, read-write). Claude Code's interactive TUI appears to need a read-write
terminal on stdin, so under the read-only redirect it renders one turn and then
its input handling wedges. The redirect lives at exactly one place —
`chat-folder.sh:278`, `bash chat.sh "$id" </dev/tty` — and the DIRECT path
(`chat.sh <id>`) has no such redirect, which predicts direct chat works and
`[d]`-launched chat hangs.

**Ruled OUT by evidence (do not chase):**
- *Recording / asciinema* — the wedge reproduces in a **plain terminal** with no
  recorder. Under asciinema the recorder is a bystander (its tokio worker is
  armed on `kevent` for terminal input and would forward; `ASCIINEMA_REC` is
  present but not causal). A separate teardown mode exists (below) but is not
  this bug.
- *`-p`/emit mode* — removes the raw-mode TUI but deletes the live back-and-forth
  that is the whole point of `chat`. Feature removal, not a fix. Out of scope.

**Why audit-first:** the fd-difference evidence is strong but the decisive test
(hold a multi-turn conversation each way) needs live typing that can't be done
from tooling. So criterion 1 runs that experiment to CONFIRM or REFUTE the
hypothesis; the fix follows from the result. If direct chat also wedges, the
cause is the nested interactive `claude` invocation itself (Claude Code 2.1.212)
and the task escalates there — either way it determines why before fixing.

## Success criteria

<!-- Observable behaviors that show it's done: "User can [do what]" /
     "App shows [result]". Clear and succinct — anyone can verify. -->

- [x] **AUDIT — confirm or refute the cause (do this first):** run the decisive
      experiment and record the result in this file. (a) `./sprint.sh chat <id>`
      DIRECTLY in a plain terminal — hold a multi-turn conversation; check
      `lsof -p <claude-pid>` shows stdin `0u` (rw pty). (b) `./sprint.sh chat
      backlog` → `[d]` on the same id — check it wedges after turn 1 and stdin is
      `0r /dev/tty`. Outcome names the cause: (a) works + (b) wedges ⇒ the
      read-only `</dev/tty` handoff is confirmed → proceed to the fix below. Both
      wedge ⇒ the nested interactive `claude` invocation is the cause →
      re-scope to that (escalate; the audit still succeeded).
- [x] **FIX — give the interactive launch a read-write terminal:** the define
      session launched from `[d]` opens stdin on the terminal read-write
      (recommended default `<> /dev/tty`; see Notes for why dropping the redirect
      is riskier), verified by `lsof` showing `0u` on the launched `claude`.
      Whatever change is made must not break the child scripts' own
      `read -r … </dev/tty` prompts that the redirect was there to serve.
- [ ] **RELIABLE — `[d]`-launched define takes input turn after turn**, exactly
      like a direct `chat <id>`: no wedge after the first reply, `Ctrl-L`
      repaints, the conversation completes. This is the task's core success.
- [x] **No regression:** direct `chat <id>` and the folder sweep's own
      `[w]/[k]/[s]/[q]` prompts still work; the fix changes only the interactive
      handoff. (Direct path is untouched; the child prompts each reopen the tty
      with their own `read -r … </dev/tty` — unaffected by the parent's stdin fd.
      Both scripts pass `bash -n`.)

Secondary (fold in if cheap, else spin out — they showed up alongside this bug):
- [ ] **Reap orphans / fail fast:** a documented `doctor`/reap command lists and
      kills orphaned `sprint.sh chat` pipelines (a genuinely dead terminal — the
      teardown mode below — still strands one); and a dead terminal makes the
      pipeline exit rather than hang forever.

## Notes

<!-- Every relevant detail that helps build the solution fast and knowingly:
     decisions, constraints, edge cases, gotchas. Leave empty if none. -->

**Priority — high-leverage infra (fix ahead of sprint work):** this is
`Plan: none` and orthogonal to the live sprint (Plan 15), but a broken `[d]`
define path degrades the very tool used to define and refine every other task —
including Plan 15's. Treat it as higher priority than its unplanned status
implies.

**The key evidence — stdin fd differs between wedged and healthy sessions
(2026-08-02):**
- Every wedged `[d]`-launched `claude` (specimens 58571, 60521, 60111, …):
  `lsof` stdin = `0r  CHR 2,0  /dev/tty` — the controlling-terminal alias,
  opened **O_RDONLY**. Main thread idle in `kevent64` waiting on input.
- A healthy interactive `claude` (a normal session): stdin = `0u  CHR 16,N
  /dev/ttysNN` — the pty slave, **read-write**.
- Source of the read-only fd: `chat-folder.sh:278` — `bash chat.sh "$id"
  </dev/tty` — the `[d]` handoff. `< /dev/tty` opens the terminal O_RDONLY. The
  direct `chat.sh <id>` path adds no redirect (inherits rw terminal).
- Reproduced in a **plain terminal** (no recorder) and repeatedly (4+ times),
  always via the `[d]` path → asciinema is not the cause here.

**Caveat the audit must settle (why criterion 1 exists, not a bare assertion):**
the wedged `claude` DOES hold read-write fds to the pts on 1/2/5/15, so a
read-only fd 0 is not obviously fatal on its own — it may be a correlated marker
of the `</dev/tty` handoff rather than the direct mechanism. The direct-vs-`[d]`
experiment settles whether the redirect is truly causal before committing the
fix. (Track record: two earlier "confirmed" causes this session — read-loop
contention, then asciinema teardown — were both overturned by new evidence.
Hence audit-first.)

**Candidate fixes to A/B once confirmed:** (i) drop the `</dev/tty` on line 278
so the child inherits the real terminal; (ii) `<> /dev/tty` to open read-write;
(iii) don't shell a nested `chat.sh` for `[d]` at all — hand the terminal over
directly. Whichever is chosen must preserve the child scripts' own interactive
`read -r … </dev/tty` prompts (why the redirect was added).

**Recommended default: (ii) `<> /dev/tty`.** Option (i) is only safe if the
parent's stdin is provably still the tty at line 278 — and it may NOT be: a
headless one-shot `claude` runs per file earlier in the sweep loop
(`chat-folder.sh` ~L152–164), and a headless invocation can consume or reposition
the parent's stdin, so dropping the redirect could hand `chat.sh` a
drained/closed stdin and produce a *different* wedge that only shows up mid-sweep
(easy to "confirm fixed" in isolation and still be broken). `<> /dev/tty` opens
the real terminal read-write regardless of what the parent's stdin became — start
the A/B there and only fall back to (i)/(iii) if it fails. (Note: the outer sweep
loop is an array loop — `for i in "${!all_files[@]}"` at L152 — not a pipe, so
iteration itself does not drain stdin; the headless model call is the live risk.)

**A genuinely separate failure mode (teardown — real, but not this bug):** when
`chat` runs inside `asciinema record` and the OUTER terminal is CLOSED, asciinema
is reparented to init (PPID 1, TTY `??`) yet holds the inner pty master open, so
`claude` never gets input nor an EOF and hangs unrecoverably. This is why
orphaned zombie stacks accumulate. It needs the reap/fail-fast handling
(secondary criterion), but it is not the `[d]` wedge above.

**Also seen (spin out — not this task's core):**
- `chat-folder.sh:249` `read -r choice </dev/tty || choice="s"` silently SKIPS
  on a failed tty read — a severed terminal can sweep a whole folder doing
  nothing. Should abort, not skip.
- No lock guards a task while chat holds it: 3+ concurrent sweeps edited the SAME
  `312-*.md` at once — a data race on the durable artifact. Own task (per-task
  chat lock).

**Key files:** `docs/sprintmd/scripts/chat-folder.sh:278` (the `[d]` handoff —
the redirect), `docs/sprintmd/scripts/chat.sh` (interactive launch),
`docs/sprintmd/lib.sh` (`sprintmd_run_interactive`, `sprintmd_interactive_ok`),
`docs/sprintmd/cli/claude.sh` (`sprintmd_provider_interactive`).
## References

docs/sprintmd/scripts/chat-folder.sh
docs/sprintmd/scripts/chat.sh
docs/sprintmd/lib.sh
docs/sprintmd/cli/claude.sh
docs/sprintmd/guides/use_chat.md

<!-- When this task is finished, leave an audit trail of what it touched.
     Reviews and the change manifest read this. Copy the two headings
     below to column 0 (UNINDENTED — they are indented here only so a fresh,
     unworked task is not mistaken for a finished one), then list one
     repo-relative path per line under "Files changed":

       ## Completed

       ### Files changed
       docs/sprintmd/scripts/example.sh
       docs/tasks/.TEMPLATE-task.md

     Keep the wording exact — `## Completed` and `### Files changed` — the tasks
     runner and lib.sh key off them verbatim. -->

<!--
AI: Full task-writing guidance is in docs/sprintmd/ai/task-creation.md
-->

## Refine (round 1)

**Sharpened:** Named `<> /dev/tty` as the recommended fix default and recorded
why "just drop the redirect" is riskier (a per-file headless `claude` earlier in
the sweep loop can drain the parent's stdin; the outer loop is an array loop, so
iteration itself is not the risk); pointed the FIX criterion at that default; and
flagged the task as high-leverage infra to fix ahead of sprint work. Left the
reap/doctor secondary inline per the developer's call.

## Questions

**Status: READY**

### Already complete
Nothing is fixed yet — the diagnosis is done, the code change is not.
- The root-cause redirect is still live exactly where the task describes it:
  `chat-folder.sh:278` — `bash "$(dirname …)/chat.sh" "$task_id" </dev/tty || true`.
  This is the `[d]` handoff and it opens the terminal O_RDONLY, which then
  propagates down through `chat.sh` → `sprintmd_run_interactive`
  (`lib.sh:1234`) → `sprintmd_provider_interactive` (`claude.sh:323`) to the
  launched `claude`, whose stdin is inherited verbatim (`"${cmd[@]}"` at
  `claude.sh:365`, no stdin redirect of its own). The task's fd analysis matches
  the code exactly.
- The DIRECT path (`chat.sh <id>`) adds no `</dev/tty` redirect, so it inherits
  the real read-write terminal — consistent with the task's prediction that
  direct chat works.
- The child scripts' own `read -r … </dev/tty` prompts the redirect was meant to
  serve are real and must be preserved: `chat-folder.sh:249` (the sweep choice
  prompt) and `:289` (the kill confirm). Any fix must not starve these.

### Remaining work
Everything in the success criteria is unstarted and clear to execute:
1. **AUDIT** — run the direct-vs-`[d]` experiment in a plain terminal, confirm
   `0u` (rw pty) on direct and `0r /dev/tty` on `[d]`, and record the outcome in
   this file. This gates which branch the fix takes.
2. **FIX** — change `chat-folder.sh:278` to open the terminal read-write. The
   task's recommended default is `<> /dev/tty` (falling back to dropping the
   redirect or handing the terminal over directly only if that fails). Verify
   `lsof` shows `0u` on the launched `claude`.
3. **RELIABLE / no-regression** — confirm `[d]`-launched define takes input turn
   after turn, and that direct `chat <id>` plus the sweep's own
   `[w]/[k]/[s]/[q]` prompts still work.
4. **Secondary (fold in if cheap, else spin out)** — a `doctor`/reap command for
   orphaned `sprint.sh chat` pipelines, and fail-fast on a dead terminal. The
   task already flags this as optional/spin-out, so deferring it does not reduce
   the fix's completeness.

No cross-task dependency: this is standalone `chat` infra and does not build on
any task in next/ or backlog/. **Depends on: none** is correct.

### Questions for the developer
None — task is fully defined. The cause is diagnosed, the recommended fix
(`<> /dev/tty`) and its A/B fallbacks are named, the audit-first sequencing is
explicit, and the invariant to preserve (child `read … </dev/tty` prompts) is
called out. A developer can start immediately.

## Audit result (2026-08-02)

**Verdict: read-only `</dev/tty` handoff CONFIRMED as the cause (mechanism
proven), by every check tooling can run without a human typing.**

- **Code-level (matches the specimen fd analysis exactly):** the only source of a
  read-only stdin on the launched `claude` was `chat-folder.sh` line 278 —
  `bash …/chat.sh "$task_id" </dev/tty`. It propagates down `chat.sh` →
  `sprintmd_run_interactive` → `sprintmd_provider_interactive` → `claude`, whose
  stdin is inherited verbatim (no redirect of its own). The DIRECT path
  (`chat.sh <id>`) adds no redirect, so it inherits the real read-write terminal
  → predicts `0u` on direct, exactly as the task states.
- **OS-level proof of the fd markers** (run from tooling, no interactive claude):
  a bash probe with `lsof -d 0` shows `< file` opens fd 0 as `ar` (**read-only**,
  = the `0r` of every wedged specimen) while `<> file` opens it as `au`
  (**read-write**, = the `0u` of a healthy session). So `</dev/tty` → `0r` and
  `<>/dev/tty` → `0u` is a provable property of the redirect, not a coincidence.
- **Owed to the developer (needs a human at a keyboard — cannot be done from
  tooling):** the one remaining link is the live multi-turn conversation each way
  (direct vs `[d]`) to observe the wedge disappear and `lsof` show `0u` on the
  *actually-launched* `claude`. The fix applied is the task's recommended default
  `<> /dev/tty`, which is strictly safer than dropping the redirect and holds
  under either audit branch, so it was applied without waiting on that live run.
  Please confirm the RELIABLE criterion (input turn after turn, `Ctrl-L`
  repaints) on your next `chat <folder> → [d]` sweep.

**Not done (deliberately deferred, per the task's own "spin out" framing):** the
secondary `doctor`/reap + fail-fast criterion, and the two "also seen" items
(`:249` skip-on-failed-read, per-task chat lock). These are separate failure
modes (the asciinema teardown orphan), not the `[d]` wedge, and the task marks
them optional. They warrant their own task(s).

## Completed

**Core fix landed (two rounds).**

**Round 1 (incomplete):** `[d]` switched from `</dev/tty` (O_RDONLY → `0r`) to
`<>/dev/tty` (RDWR → `0u` on device 2,0). Necessary but not sufficient.

**Round 2 (2026-08-03, live Grok specimen pid 33675):** developer re-ran
`./sprint.sh -g chat backlog` → `[d]` on task 312. Grok was launched, ran
tool/inference loops at ~99% CPU for minutes, but the TUI still looked hung.
`lsof` on the hung process:

| fd | path | mode |
|----|------|------|
| 0 (stdin) | `/dev/tty` (device 2,0) | `0u` RDWR |
| 1 (stdout) | `/dev/ttys009` | `0u` |
| 2 (stderr) | `/dev/null` | write |

So Round 1's `0u` was achieved, but on the **controlling-terminal alias**, not
the real pty slave. Healthy interactive sessions (task notes + direct `chat`)
show `0u /dev/ttysNN`. Same class of wedge on Claude and Grok.

**Fix now:** `sprintmd_tty` in `lib.sh` resolves the real slave path
(`/dev/ttysNN` / `/dev/pts/N`, fallback `/dev/tty`). Both define handoffs open
it RDWR:

- `chat-folder.sh` `[d]` → `bash chat.sh "$id" <>"$(sprintmd_tty)"`
- `chat-bugs.sh` `[d]` → `sprintmd_run_interactive … <>"$(sprintmd_tty)"`

OS-level proof under `script` (tooling, no human typing):

```
<>"$(sprintmd_tty)"  →  0u CHR 16,N  /dev/ttysNN   # healthy shape
<>/dev/tty           →  0u CHR  2,0  /dev/tty      # Round 1 shape (still wedges)
```

Child `read -r … </dev/tty` prompts and the direct `chat <id>` path are
untouched. All three files pass `bash -n`.

**Criteria status:**
- [x] AUDIT — cause confirmed at code + OS-fd level (see "Audit result" above);
      Round 2 refined it: device path matters, not only O_RDONLY.
- [x] FIX — real pty slave via `sprintmd_tty`; mechanism proven above.
- [x] No regression — direct path untouched; child prompts reopen tty; `bash -n` clean.
- [ ] RELIABLE — still needs the developer's live multi-turn `[d]` sweep after
      Round 2 (kill any orphaned grok/claude from the hung specimen first).
- [ ] Secondary (reap/doctor + fail-fast) — deferred as spin-out per the task's
      own framing; a separate failure mode (asciinema teardown orphan).

**Release note:** the change lives in the live dev tree (`docs/sprintmd/`). The
`src/` distribution mirror is still stale (old `</dev/tty`); mirroring is the
developer's `./ship.sh` release step — not run here because the working tree
carries many other in-flight `docs/sprintmd/` changes a full-tree mirror would
sweep in, and hand-copying to `src/` is disallowed.

### Files changed
docs/sprintmd/lib.sh
docs/sprintmd/scripts/chat-folder.sh
docs/sprintmd/scripts/chat-bugs.sh

