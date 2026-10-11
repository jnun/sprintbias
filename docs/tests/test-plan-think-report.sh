#!/usr/bin/env bash
# Test: plan think ends with a change report (task 437).
# Drives plan-think.sh in exec mode through a stub CLI that edits, creates,
# moves and deletes fixture files in a temp project, then checks the report the
# script builds from its own before/after snapshot — no real AI provider runs.

set -euo pipefail

PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT/docs/sprintbias/scripts/plan-think.sh"

has() {
    local desc="$1" haystack="$2" needle="$3"
    if grep -qF -- "$needle" <<<"$haystack"; then
        echo "  PASS: $desc"; PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected '$needle')"; FAIL=$((FAIL + 1))
    fi
}
lacks() {
    local desc="$1" haystack="$2" needle="$3"
    if grep -qF -- "$needle" <<<"$haystack"; then
        echo "  FAIL: $desc (unexpected '$needle')"; FAIL=$((FAIL + 1))
    else
        echo "  PASS: $desc"; PASS=$((PASS + 1))
    fi
}
ok() {
    local desc="$1"; shift
    if "$@"; then echo "  PASS: $desc"; PASS=$((PASS + 1))
    else echo "  FAIL: $desc"; FAIL=$((FAIL + 1)); fi
}

TMP=""
trap 'rm -rf "$TMP"' EXIT

# setup -> fresh project in $P: plan 1 with members #100–#104, committed, then
# #103 and #104 dirtied before the run (the pass touches only #104 further).
setup() {
    rm -rf "$TMP"; TMP="$(mktemp -d)"; P="$TMP/proj"
    mkdir -p "$P/docs/tasks"/{backlog,next,doing,review,done,blocked} "$P/docs/plans" "$P/docs/tmp"
    printf '# Plan 1: P\n\n**Status:** DRAFT\n\n## Goal\n\nG\n\n## Member tasks\n\n- #100 — A\n- #101 — B\n- #102 — C\n- #103 — D\n- #104 — E\n' > "$P/docs/plans/1-p.md"
    for n in 100 101 102 103 104; do
        printf '# Task %s: T\n\n## Problem\n\nX\n' "$n" > "$P/docs/tasks/backlog/$n-t$n.md"
    done
    (cd "$P" && git init -q && git add -A && git -c user.email=t@t -c user.name=t commit -qm init)
    printf 'dirty before\n' >> "$P/docs/tasks/backlog/103-t103.md"
    printf 'dirty before\n' >> "$P/docs/tasks/backlog/104-t104.md"

    STUB="$TMP/stub-cli"
    cat > "$STUB" <<'STUBEOF'
#!/usr/bin/env bash
# Stub agent: act on the plan think fixture per STUB_MODE, then exit.
sed -i.bak 's/^G$/Goal reworded/' docs/plans/1-p.md && rm -f docs/plans/1-p.md.bak
printf -- '- #200 — Delta\n' >> docs/plans/1-p.md
printf '# Task 200: Delta\n\n## Problem\n\nNew\n' > docs/tasks/backlog/200-delta.md
mv docs/tasks/backlog/101-t101.md docs/tasks/next/101-t101.md
rm docs/tasks/backlog/102-t102.md
printf 'pass edit\n' >> docs/tasks/backlog/104-t104.md
cat > docs/tmp/plan-think-1.md <<'REVIEW'
1. **Reality check**
- #100 — KEEP — x.sh:1

2. **What changed**
- `docs/plans/1-p.md` — Goal reworded; #200 added to members (lens: best practice)
- docs/tasks/backlog/200-delta.md — delta for #101 (lens: antifragility)
- docs/tasks/next/101-t101.md — moved to next (lens: elegant design)
- docs/tasks/backlog/104-t104.md: Done when sharpened

3. **Final order**
- docs/tasks/backlog/100-t100.md — not a change line
REVIEW
case "${STUB_MODE:-complete}" in
    complete|held) echo "PLAN THINK COMPLETE — plan 1, 3 members aligned" >> docs/tmp/plan-think-1.md ;;
    fail) exit 3 ;;
esac
if [ "${STUB_MODE:-}" = held ]; then
    printf '# Plan 1 — decisions\n\n- [ ] Plan: goal? — suggested: yes\n' > docs/tmp/plan-1_discuss.md
fi
exit 0
STUBEOF
    chmod +x "$STUB"
}

run() {  # run MODE -> output of plan think 1 (exit code in RC)
    RC=0
    OUT="$(cd "$P" && env -u CLAUDECODE -u CLAUDE_CODE_SESSION_ID -u AI_AGENT -u SPRINTBIAS_IN_AGENT \
        STUB_MODE="$1" SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$STUB" SPRINTBIAS_FAST=off \
        bash "$SCRIPT" 1 </dev/null 2>&1)" || RC=$?
    REPORT="$(cat "$P/docs/tmp/plan-think-1-changes.md" 2>/dev/null || true)"
}

echo "=== test-plan-think-report.sh ==="

echo "Completed run"
setup; run complete
ok    "exits 0" [ "$RC" -eq 0 ]
has   "prints a Changes section"              "$OUT" "▸ Changes"
has   "banner names the report file"          "$OUT" "Change report: docs/tmp/plan-think-1-changes.md"
ok    "report file written" [ -f "$P/docs/tmp/plan-think-1-changes.md" ]
has   "edited plan, stat + agent summary"     "$REPORT" "- edited  docs/plans/1-p.md  +2 −1 — Goal reworded; #200 added to members (lens: best practice)"
has   "new delta task"                        "$REPORT" "- new     docs/tasks/backlog/200-delta.md  +5 −0 — delta for #101 (lens: antifragility)"
has   "move reported once, old → new"         "$REPORT" "- moved   docs/tasks/backlog/101-t101.md → docs/tasks/next/101-t101.md  +0 −0 — moved to next (lens: elegant design)"
lacks "moved file not also new"               "$REPORT" "new     docs/tasks/next/101-t101.md"
lacks "moved file not also deleted"           "$REPORT" "deleted docs/tasks/backlog/101-t101.md"
has   "deleted file, no agent summary"        "$REPORT" "- deleted docs/tasks/backlog/102-t102.md  +0 −5 — (no summary)"
has   "pre-dirty file changed again: only the pass's lines" "$REPORT" "- edited  docs/tasks/backlog/104-t104.md  +1 −0 — Done when sharpened"
lacks "pre-dirty file left alone is not reported" "$REPORT" "103-t103.md"
lacks "docs/tmp is outside the snapshot"      "$REPORT" "docs/tmp/"
has   "counts every change"                   "$REPORT" "Changes (5):"
has   "ends with Unchanged members"           "$(tail -1 "$P/docs/tmp/plan-think-1-changes.md")" "Unchanged members: #100, #103"
lacks "report file is plain text (no color)"  "$REPORT" $'\033'
has   "next step 1 points at the report"      "$OUT" "1. Read what changed"
lacks "no git diff homework"                  "$OUT" "git diff"
lacks "no git status homework"                "$OUT" "git status"

echo "Partial run (no completion marker)"
setup; run partial
ok    "exits 1" [ "$RC" -eq 1 ]
has   "prints the change report"              "$OUT" "▸ Changes"
has   "names the run as partial"              "$REPORT" "Run: partial"
has   "lists what was half-updated"           "$OUT" "docs/plans/1-p.md"
lacks "no Review 'git diff' advice"           "$OUT" "git diff"

echo "Failed run"
setup; run fail
ok    "exits 1" [ "$RC" -eq 1 ]
has   "says it failed"                        "$OUT" "✗ plan think failed"
has   "prints the change report"              "$OUT" "▸ Changes"
has   "names the run as failed"               "$REPORT" "Run: failed"
lacks "no git diff advice"                    "$OUT" "git diff"

echo "Held goal questions"
setup; run held
has   "names the held questions"              "$OUT" "goal question(s) held"
_order="$(printf '%s\n' "$OUT" | grep -nE '▸ Changes|goal question\(s\) held' | cut -d: -f2- | tr '\n' '|')"
has   "report prints before the hand-off"     "$_order" "▸ Changes|"
ok    "script prints the report before exec chat-plan" \
      awk '/print_change_report "complete"/ { r=NR } /exec "\$_CHAT_PLAN"/ { e=NR } END { exit !(r && e && r < e) }' "$SCRIPT"

echo "Prompt"
PROMPT_SRC="$(cat "$SCRIPT")"
has   "What changed is one line per file, path first" "$PROMPT_SRC" "**What changed** — one line per file you created, edited, moved or deleted, starting with its repo-relative path"
has   "asks for no separate Changes section"  "$PROMPT_SRC" "Write no separate Changes section"
has   "emit mode asks for the lines as the final message" "$PROMPT_SRC" "**Final message:** print your **What changed** lines"
has   "lib.sh header lists the snapshot helper" "$(sed -n '1,200p' "$ROOT/docs/sprintbias/lib.sh")" "sprintbias_change_snapshot"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
