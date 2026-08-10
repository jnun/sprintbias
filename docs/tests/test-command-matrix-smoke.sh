#!/usr/bin/env bash
# Test: command-matrix emit smoke
#
# Walks every command in docs/guides/command-matrix.md in a sandbox under
# SPRINTBIAS_MODE=emit — no network, no live CLI. For each command it proves
# three cross-cutting invariants the session dogfood proved once by hand:
#
#   1. A leading -g / -c launcher flag is always accepted — never "Unknown
#      option" (the launcher rejection that would exit 1).
#   2. AI paths announce the provider banner exactly as
#      `▸ Provider: <cli> (<tier>) · mode: emit` (lib.sh:sprintbias_announce_provider).
#   3. Non-AI paths (create / status / search / …) never announce it.
#
# emit mode is the key that makes this network-free: an AI path prints its
# prompt for the surrounding agent and returns instead of shelling out to a
# real CLI, so nothing here launches claude/grok or touches the network.
#
# This does NOT replace the live dual-provider smoke (#301 / #296 / #297); it is
# the cheap, committed regression that keeps the flag + banner + emit contract
# from rotting between live runs.
#
# See: docs/guides/command-matrix.md, docs/tests/test-sprint.sh,
#      docs/tests/test-grok-provider.sh, docs/sprintbias/lib.sh.

set -euo pipefail

PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# ── Sandbox: one framework copy, cheap per-case fixture reseeds ───────
# The expensive part (copying the whole docs/sprintbias/ tree + sprint.sh, exactly
# what a real install ships) happens once. seed_fixtures() then resets only the
# small work-item files before each case, so a command that mutates in bash
# (plan start --commit-only moves a member; deps files a task) can't leak state
# into the next case.
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

build_framework() {
    mkdir -p "$TMPDIR/docs/sprintbias"
    cp -R "$ROOT/docs/sprintbias/." "$TMPDIR/docs/sprintbias/"
    cp "$ROOT/sprint.sh" "$TMPDIR/sprint.sh"

    mkdir -p "$TMPDIR/docs/tasks/backlog" "$TMPDIR/docs/tasks/next" \
             "$TMPDIR/docs/tasks/doing" "$TMPDIR/docs/tasks/review" \
             "$TMPDIR/docs/tasks/done" "$TMPDIR/docs/tasks/blocked" \
             "$TMPDIR/docs/plans" "$TMPDIR/docs/bugs" "$TMPDIR/docs/ideas" \
             "$TMPDIR/docs/features" "$TMPDIR/docs/tmp"

    # Templates the create-*.sh scripts read at runtime.
    cp "$ROOT/docs/tasks/.TEMPLATE-task.md"       "$TMPDIR/docs/tasks/.TEMPLATE-task.md"
    cp "$ROOT/docs/bugs/.TEMPLATE-bug.md"         "$TMPDIR/docs/bugs/.TEMPLATE-bug.md"
    cp "$ROOT/docs/ideas/.TEMPLATE-idea.md"       "$TMPDIR/docs/ideas/.TEMPLATE-idea.md"
    cp "$ROOT/docs/features/.TEMPLATE-feature.md" "$TMPDIR/docs/features/.TEMPLATE-feature.md"
    cp "$ROOT/docs/plans/.TEMPLATE-plan.md"       "$TMPDIR/docs/plans/.TEMPLATE-plan.md"

    cat > "$TMPDIR/docs/sprintbias/DOC_STATE.md" << 'EOF'
# SprintBias Documentation State

**Last Updated**: 2026-01-01
**sprint_VERSION**: 2.2.0
**sprint_TASK_ID**: 50
**sprint_BUG_ID**: 5
EOF

    git -C "$TMPDIR" init -q

    # A code file with a committed diff so `polish --code <file>` has something to
    # judge without reaching for a live diff it can't find.
    echo "console.log('smoke')" > "$TMPDIR/app.js"
    git -C "$TMPDIR" add app.js >/dev/null 2>&1 || true

    # Stub `npm` so `deps` runs its Node ecosystem tooling with zero network:
    # deps gates each check on the binary's presence and swallows its output, so a
    # stub that prints a canned line and exits is enough to reach the AI half.
    mkdir -p "$TMPDIR/stubbin"
    cat > "$TMPDIR/stubbin/npm" << 'EOF'
#!/bin/sh
echo "left-pad  1.0.0  1.3.0  1.3.0  node_modules/left-pad"
exit 0
EOF
    chmod +x "$TMPDIR/stubbin/npm"
}

# Reset the work-item fixtures to a known, rich state before each case.
# .TEMPLATE-*.md files are dotfiles, so `*.md` never deletes them.
seed_fixtures() {
    rm -f "$TMPDIR"/docs/tasks/backlog/*.md "$TMPDIR"/docs/tasks/next/*.md \
          "$TMPDIR"/docs/tasks/doing/*.md "$TMPDIR"/docs/tasks/review/*.md \
          "$TMPDIR"/docs/tasks/done/*.md "$TMPDIR"/docs/tasks/blocked/*.md \
          "$TMPDIR"/docs/plans/*.md "$TMPDIR"/docs/bugs/*.md \
          "$TMPDIR"/docs/ideas/*.md "$TMPDIR"/docs/features/*.md 2>/dev/null || true

    # A READY task in next/ — the queue `work` / `work <id>` / `work <N>` drain,
    # and the file `split` explodes.
    cat > "$TMPDIR/docs/tasks/next/60-ready-alpha.md" << 'EOF'
# Task 60: Ready alpha

**Feature**: none
**Created**: 2026-07-30
**Depends on**: none
**Blocks**: none

## Problem
Do the alpha thing.

## Success criteria
- [ ] Alpha works

## Questions

**Status: READY**
EOF

    # A READY task with a hash-prefixed unmet Depends-on — the shape chat-sprint's
    # structural walk reasons about (a member waiting on #999).
    cat > "$TMPDIR/docs/tasks/next/62-dep-child.md" << 'EOF'
# Task 62: Dep child

**Depends on**: #999
**Blocks**: none

## Problem
Waits on a prerequisite.

## Success criteria
- [ ] Child ships after its parent

## Questions

**Status: READY**
EOF

    # An UNGATED task in next/ (no Status verdict) so `gate` has something to
    # review — gate short-circuits when every task is already READY.
    cat > "$TMPDIR/docs/tasks/next/63-ungated.md" << 'EOF'
# Task 63: Ungated gamma

**Depends on**: none
**Blocks**: none

## Problem
Something to gate.

## Success criteria
- [ ] Gated
EOF

    # A backlog task so `gate <folder>` (a quality report on backlog/) has
    # something to review — gate short-circuits on an empty folder.
    cat > "$TMPDIR/docs/tasks/backlog/55-backlog-item.md" << 'EOF'
# Task 55: Backlog item

**Depends on**: none
**Blocks**: none

## Problem
A rough idea waiting in the backlog.

## Success criteria
- [ ] Someday
EOF

    # A task in review/ — `polish` (sweep) and `polish <file>` (deep-judge) target.
    cat > "$TMPDIR/docs/tasks/review/61-review-beta.md" << 'EOF'
# Task 61: Review beta

**Depends on**: none
**Blocks**: none

## Problem
Landed in review.

## Success criteria
- [ ] Reviewed

## Completed

### Files changed
app.js
EOF

    # A plan for the gate/author/commit paths (plan think / plan start / chat plan).
    cat > "$TMPDIR/docs/plans/70-sample-plan.md" << 'EOF'
# Plan 70: Sample plan

**Status:** READY

## Members
- #60
EOF

    # A bug report so `chat bugs` has an inbox to sweep.
    cat > "$TMPDIR/docs/bugs/6-smoke-bug.md" << 'EOF'
# Bug 6: Smoke bug

**Severity:** low

## Problem
Something is slightly off.
EOF

    # A manifest so `deps` detects the Node ecosystem (paired with the npm stub).
    cat > "$TMPDIR/package.json" << 'EOF'
{ "name": "smoke", "version": "1.0.0", "dependencies": { "left-pad": "1.0.0" } }
EOF
}

# ── One invocation under one provider flag ───────────────────────────
# Runs `sprint.sh <flag> <args…>` in the sandbox under emit mode, stdin closed,
# stdout+stderr captured together. PATH is prefixed with the stub bin so `deps`
# never shells out to a real npm. The banner is written to stderr (and /dev/tty
# when stderr is not a TTY), so 2>&1 always captures it.
run_cmd() {
    local flag="$1"; shift
    ( cd "$TMPDIR" && SPRINTBIAS_MODE=emit PATH="$TMPDIR/stubbin:$PATH" \
        bash sprint.sh "$flag" "$@" </dev/null 2>&1 ) || true
}

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

# Assert the launcher flag was accepted (no "Unknown option") for one provider.
assert_flag_ok() {
    local desc="$1" out="$2"
    if printf '%s' "$out" | grep -qF -- "Unknown option"; then
        fail "$desc — leading flag rejected as Unknown option"
    else
        pass "$desc — leading flag accepted"
    fi
}

# Assert the provider banner is present and names the right tier for the flag.
# Match the real announce line from lib.sh (▸ Provider: cli (tier) · mode: …),
# not bare "Provider:" prose — `model show` prints config lines with that word.
assert_banner() {
    local desc="$1" flag="$2" out="$3" tier
    case "$flag" in
        -g) tier="grok (grok-build)" ;;
        -c) tier="claude (claude-code)" ;;
    esac
    if printf '%s' "$out" | grep -qF -- "▸ Provider: $tier" \
       && printf '%s' "$out" | grep -qF -- "mode: emit"; then
        pass "$desc — announces '$tier · mode: emit'"
    else
        fail "$desc — missing provider banner for $flag"
    fi
}

# Assert the provider banner is absent (non-AI path).
assert_no_banner() {
    local desc="$1" out="$2"
    if printf '%s' "$out" | grep -qF -- "▸ Provider:"; then
        fail "$desc — non-AI path announced a provider banner"
    else
        pass "$desc — no provider banner (non-AI)"
    fi
}

# expect_ai / expect_noai — run one matrix command under BOTH -g and -c with a
# fresh fixture set each time, and assert the invariants.
expect_ai() {
    local desc="$1"; shift
    local flag out
    for flag in -g -c; do
        seed_fixtures
        out="$(run_cmd "$flag" "$@")"
        assert_flag_ok "$desc [$flag]" "$out"
        assert_banner  "$desc [$flag]" "$flag" "$out"
    done
}

expect_noai() {
    local desc="$1"; shift
    local flag out
    for flag in -g -c; do
        seed_fixtures
        out="$(run_cmd "$flag" "$@")"
        assert_flag_ok  "$desc [$flag]" "$out"
        assert_no_banner "$desc [$flag]" "$out"
    done
}

echo "=== test-command-matrix-smoke.sh ==="
build_framework

# ── create — new* (non-AI template path; no name = AI Q&A, not covered here) ──
echo "Create family (new*) — mints a file, no AI banner:"
expect_noai "newtask"            newtask "Smoke task"
expect_noai "newbug"             newbug "Smoke bug"
expect_noai "newidea <name>"     newidea "Smoke idea"
expect_noai "newfeature <name>"  newfeature "Smoke feature"
expect_noai "newplan"            newplan "Smoke plan" 60
expect_noai "newtest"            newtest "Smoke test"

# ── chat — human in the loop (every target is an AI conversation) ──
echo "Chat family — AI conversation, announces provider:"
expect_ai "chat <id>"        chat 60
expect_ai "chat <folder>"    chat next
expect_ai "chat plan <id>"   chat plan 70
expect_ai "chat bugs"        chat bugs
expect_ai "chat (sprint)"    chat

# ── plan — compose the sprint ──
echo "Plan family:"
expect_ai "plan think <id>"  plan think 70
# Intentional short-circuit: plan start --commit-only skips the workability gate
# for a pure backlog→next mv, so it makes NO AI call and prints no banner.
expect_noai "plan start --commit-only" plan start 70 --commit-only
# Intentional short-circuit: plan done on an unfinished plan refuses (non-zero,
# no AI) — retirement is a bash deletion, never an AI path.
expect_noai "plan done <id> (unfinished)" plan done 70

# ── work — autonomous transform ──
echo "Work family — AI execution, announces provider:"
expect_ai "work (drain next/)" work
expect_ai "work <id>"          work 60
# Cap form is `work count N` (matrix line: "Execute at most N READY tasks").
# A bare number now means a task id, so the cap must use the `count` sub-word.
expect_ai "work count <N> (cap)" work count 1
expect_ai "gate (default next/)" gate
expect_ai "gate <folder>"        gate backlog
expect_ai "split <path>"         split docs/tasks/next/60-ready-alpha.md
expect_ai "loop"                 loop
# Intentional short-circuit: promote is pure shell (NO AI). Fixture 61 has no
# **Tests** field → skipped, stays in review/, exit 0 — no provider banner.
expect_noai "promote"            promote
# Intentional short-circuit: settle folds (Suggestion: …) open questions in
# pure bash. Fixture next/ task is already clear → no-op summary, no AI.
expect_noai "settle"             settle

# ── polish — post-work quality, all three argument shapes ──
echo "Polish modes:"
expect_ai "polish (sweep review/)"     polish
expect_ai "polish --parallel (sweep)"  polish --parallel
expect_ai "polish --fast (sweep)"      polish --fast
expect_ai "polish --jobs N (sweep)"    polish --jobs 3
expect_ai "polish --code <file>"       polish --code app.js
expect_ai "polish <file> (deep-judge)" polish docs/tasks/review/61-review-beta.md

# ── look — read, don't mutate (non-AI) ──
echo "Look family — read-only, no AI banner:"
expect_noai "status"          status
expect_noai "search <kw>"     search smoke
expect_noai "context"         context
expect_noai "align"           align
expect_noai "learn (catalog)" learn

# ── keep — housekeeping ──
echo "Keep family:"
expect_ai   "profile (create)" profile
expect_noai "profile show"     profile show
# Intentional short-circuit: sandbox git has no origin remote, so sync refuses
# before any network access (exit 1) — non-AI bash refusal, no banner.
expect_noai "sync"             sync
expect_noai "validate"         validate
expect_noai "cleanup"          cleanup
# deps reaches its AI half only when a manifest is present (empty tree is an
# intentional short-circuit); the npm stub keeps it network-free.
expect_ai   "deps"             deps
# model is pure config (show/list/set) — no AI, no provider banner.
expect_noai "model show"       model show
expect_noai "model list"       model list

# ── Summary ───────────────────────────────────────────────────────────
echo ""
echo "Results: $PASS passed, $FAIL failed  (of $((PASS + FAIL)) assertions)"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
