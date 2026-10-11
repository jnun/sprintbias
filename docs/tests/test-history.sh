#!/usr/bin/env bash
# Each check is a string run by eval, so its $vars expand at check time.
# shellcheck disable=SC2016
# Test: `./sprint.sh history` (scripts/history.sh, task 423) — the newest-first
# list of plan records in docs/history/, and `--since <date | git ref>` release
# notes (oldest first; ### per plan, Goal's first sentence, What changed lines).
# Covers: date filter, ref filter splitting two same-day records by a commit,
# uncommitted records, empty range, bad ref, non-plan files skipped, no writes.
# `history record` (task 439): planless / no **Plan** line / retired-plan tasks
# written once, open-plan members and recorded ids skipped, retired-plan title
# from git history (else `Plan N`), same-day suffix, empty run, and the list and
# --since notes reading tasks records.

set -euo pipefail

PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

ok()   { echo "  PASS: $1"; PASS=$((PASS + 1)); }
bad()  { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }
check() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

# ── A temp board that mirrors an install ─────────────────────────────
B="$TMP/board"
mkdir -p "$B/docs/sprintbias" "$B/docs/tasks"/{backlog,next,doing,review,done,blocked} "$B/docs/history"
cp -R "$ROOT/docs/sprintbias/." "$B/docs/sprintbias/"
cp "$ROOT/sprint.sh" "$B/sprint.sh"
export NO_COLOR=1
sb() { (cd "$B" && ./sprint.sh "$@" 2>&1); }
g()  { git -C "$B" -c user.name=t -c user.email=t@t "$@"; }

# record DATE ID SLUG TITLE — a plan record in task 421's shape.
record() {
    local f="$B/docs/history/$1-plan-$2-$3.md"
    cat > "$f" <<EOF
# Plan $2: $4

**Finished**: $1 · **Members**: 2

## Goal

$4 for everyone. A second sentence that stays out
of the notes.

## Decided

- Decided: keep it small, because tests.

## What changed

- #${2}1 — First of $2: Users can do the first thing. (docs/tasks/done/${2}1-first.md)
- #${2}2 — Second of $2 (docs/tasks/done/${2}2-second.md)

## Follow-ups

- #${2}9 — Later work (docs/tasks/backlog/${2}9-later.md)
EOF
}

echo "Syntax"
check "history.sh parses" 'bash -n "$ROOT/docs/sprintbias/scripts/history.sh"'

echo "Empty"
out="$(sb history)"; rc=$?
check "no records: one-line notice, exit 0" '[ $rc -eq 0 ] && [ "$(wc -l <<<"$out" | tr -d " ")" = 1 ] && [[ "$out" == *"No history records"* ]]'

g init -q
record 2026-09-01 10 old-work "Old work"
echo "# Notes, not a plan" > "$B/docs/history/README.md"
g add -A && g commit -qm one && g tag v1
record 2026-09-20 11 same-day-a "Same day A"
g add -A && g commit -qm two && g tag v2
record 2026-09-20 12 same-day-b "Same day B"
g add -A && g commit -qm three
record 2026-09-25 13 uncommitted "Not committed"

echo "List"
out="$(sb history)"
check "lists every plan record"             '[ "$(wc -l <<<"$out" | tr -d " ")" = 4 ]'
check "newest first"                        '[[ "$(head -1 <<<"$out")" == "2026-09-25  Plan 13"*"Not committed" ]] && [[ "$(tail -1 <<<"$out")" == "2026-09-01  Plan 10"*"Old work" ]]'
check "skips files without # Plan N:"       '[[ "$out" != *"Notes"* ]]'

echo "Since a date"
out="$(sb history --since 2026-09-20)"
check "on-or-after picks 11, 12, 13"        '[[ "$out" == *"### Same day A"* && "$out" == *"### Same day B"* && "$out" == *"### Not committed"* && "$out" != *"Old work"* ]]'
check "oldest first"                        '[ "$(grep "^###" <<<"$out" | head -1)" = "### Same day A" ] && [ "$(grep "^###" <<<"$out" | tail -1)" = "### Not committed" ]'
check "Goal first sentence only"            '[[ "$out" == *"Same day A for everyone."* && "$out" != *"second sentence"* ]]'
check "What changed lines, ids/paths gone"  'grep -qx -- "- First of 11: Users can do the first thing." <<<"$out" && grep -qx -- "- Second of 11" <<<"$out"'
check "no Decided / Follow-ups in notes"    '[[ "$out" != *"Decided"* && "$out" != *"Later work"* ]]'

echo "Since a git ref"
out="$(sb history --since v2)"
check "same-day split: B in, A out"         '[[ "$out" == *"### Same day B"* && "$out" != *"Same day A"* ]]'
check "uncommitted record included"         '[[ "$out" == *"### Not committed"* ]]'
out="$(sb history --since v1)"
check "v1 picks 11, 12, 13 but not 10"      '[ "$(grep -c "^###" <<<"$out")" = 3 ] && [[ "$out" != *"Old work"* ]]'

echo "Empty range"
out="$(sb history --since 2030-01-01)"; rc=$?
check "future date: notice, exit 0"         '[ $rc -eq 0 ] && [ "$(wc -l <<<"$out" | tr -d " ")" = 1 ] && [[ "$out" == *"No history records since"* ]]'

echo "Errors"
rc=0; out="$(sb history --since no-such-ref)" || rc=$?
check "bad ref: one error line, non-zero"   '[ $rc -ne 0 ] && [ "$(wc -l <<<"$out" | tr -d " ")" = 1 ] && [[ "$out" == *"no-such-ref"* ]]'
rc=0; out="$(sb history --since)" || rc=$?
check "--since without a value fails"       '[ $rc -ne 0 ]'
rc=0; out="$(sb history --bogus)" || rc=$?
check "unknown flag fails"                  '[ $rc -ne 0 ]'
rm -rf "$B/.git"
rc=0; out="$(sb history --since v1)" || rc=$?
check "ref outside a git tree fails"        '[ $rc -ne 0 ]'
out="$(sb history --since 2026-09-01)"
check "date form works without git"         '[ "$(grep -c "^###" <<<"$out")" = 4 ]'

echo "Writes nothing"
before="$(cd "$B" && find . -type f | sort | xargs cksum)"
sb history >/dev/null; sb history --since 2026-01-01 >/dev/null
after="$(cd "$B" && find . -type f | sort | xargs cksum)"
check "board unchanged"                     '[ "$before" = "$after" ]'
out2="$(sb history --since 2026-01-01)"
check "run twice: same notes"               '[ "$out2" = "$(sb history --since 2026-01-01)" ]'

# ── Breaker: real records, hand edits, nested installs ───────────────
echo "Breaker"
P="$TMP/pboard"
mkdir -p "$P/docs/sprintbias" "$P/docs/tasks"/{backlog,next,doing,review,done,blocked} "$P/docs/plans"
cp -R "$ROOT/docs/sprintbias/." "$P/docs/sprintbias/"
cp "$ROOT/sprint.sh" "$P/sprint.sh"
pb() { (cd "$P" && ./sprint.sh "$@" 2>&1); }
printf '# Plan 5: Ship it\n\n## Goal\n\nUsers get faster installs, e.g. one command instead of three. More later.\n\n## Tasks\n\n- [x] #1 — one\n' > "$P/docs/plans/5-ship-it.md"
printf '# Task 1: Fast install\n\n**Plan**: 5\n\n## Completed\n\n**Summary**: Installs run in one step.\n' > "$P/docs/tasks/done/1-fast.md"
pb plan done 5 >/dev/null
out="$(pb history --since 2000-01-01)"
check "plan done record round-trips"        '[ "$(head -1 <<<"$out")" = "### Ship it" ] && grep -qx -- "- Fast install: Installs run in one step." <<<"$out"'
check "Goal keeps e.g. inside the sentence" 'grep -qx "Users get faster installs, e.g. one command instead of three." <<<"$out"'
printf '# Plan 6: Version\n\n**Finished**: 2026-09-02\n\n## Goal\n\nShip v0.2. Then rest?\n\n## What changed\n\n- #1 — X (docs/tasks/done/1-x.md)\n' > "$P/docs/history/2026-09-02-plan-6-v.md"
out="$(pb history --since 2026-09-02)"
check "version dots are not sentence ends"  'grep -qx "Ship v0.2." <<<"$out"'
sed 's/$/\r/' "$P/docs/history/2026-09-02-plan-6-v.md" | sed 's/Plan 6: Version/Plan 7: Crlf/; s/2026-09-02/2026-09-03/' > "$P/docs/history/2026-09-03-plan-7-crlf.md"
out="$(pb history)"
check "CRLF record: no CR in the list"      '[[ "$out" != *$'"'"'\r'"'"'* ]] && grep -q "Plan 7    Crlf$" <<<"$out"'
out="$(pb history --since 2026-09-03)"
check "CRLF record: Goal and changes read"  'grep -qx "### Crlf" <<<"$out" && grep -qx "Ship v0.2." <<<"$out" && grep -qx -- "- X" <<<"$out"'
printf '# Plan 8: No date\n\n## What changed\n\n- #2 — Y (docs/tasks/done/2-y.md)\n' > "$P/docs/history/hand-plan-8.md"
out="$(pb history)"
check "record without Finished lists last"  '[[ "$(tail -1 <<<"$out")" == "0000-00-00  Plan 8"*"No date" ]]'

# SprintBias installed in a subfolder of a larger git repo.
M="$TMP/mono"
mkdir -p "$M"
cp -R "$B" "$M/app"
mg() { git -C "$M" -c user.name=t -c user.email=t@t "$@"; }
mg init -q && mg add -A && mg commit -qm base && mg tag m1
record 2026-09-30 14 nested "Nested"
cp "$B/docs/history/2026-09-30-plan-14-nested.md" "$M/app/docs/history/"
out="$( (cd "$M/app" && ./sprint.sh history --since m1 2>&1) )"
check "subfolder install: ref picks only new" '[ "$(grep -c "^###" <<<"$out")" = 1 ] && grep -qx "### Nested" <<<"$out"'

# ── history record ───────────────────────────────────────────────────
R="$TMP/rboard"
mkdir -p "$R/docs/sprintbias" "$R/docs/tasks"/{backlog,next,doing,review,done,blocked} "$R/docs/plans"
cp -R "$ROOT/docs/sprintbias/." "$R/docs/sprintbias/"
cp "$ROOT/sprint.sh" "$R/sprint.sh"
rb() { (cd "$R" && ./sprint.sh "$@" 2>&1); }
rg() { git -C "$R" -c user.name=t -c user.email=t@t "$@"; }

# task ID PLANLINE [SUMMARY] — a done/ task; PLANLINE "" leaves out **Plan**.
task() {
    local f="$R/docs/tasks/done/$1-t$1.md"
    { printf '# Task %s: Task %s title\n\n' "$1" "$1"
      [ -n "$2" ] && printf '**Plan**: %s\n' "$2"
      printf '\n## Completed\n\n'
      [ -n "${3:-}" ] && printf '**Summary**: %s\n' "$3"
      printf '\n### Files changed\n- x\n'; } > "$f"
}
plan() { printf '# Plan %s: %s\n\n## Goal\n\nG.\n\n- #%s\n' "$1" "$2" "$3" > "$R/docs/plans/$1-$3.md"; }

rg init -q
task 1 none "Users can log in."
task 2 ""
task 3 7 "Gone plan work."
task 4 8
task 5 9
task 6 none
task 7 12
plan 7 "Retired seven" p7
plan 12 "Twelve, deleted not committed" p12
plan 9 "Still open" p9
rg add -A && rg commit -qm base
rg rm -q docs/plans/7-p7.md && rg commit -qm "retire 7"
rm "$R/docs/plans/12-p12.md"
mkdir -p "$R/docs/history"
cat > "$R/docs/history/2026-09-01-plan-5-x.md" <<'EOF'
# Plan 5: Earlier

**Finished**: 2026-09-01 · **Members**: 1

## What changed

- #6 — Task 6 title (docs/tasks/done/6-t6.md)

## Follow-ups

- #2 — Task 2 title (docs/tasks/backlog/2-t2.md)
EOF

echo "Record"
TODAY="$(date +%Y-%m-%d)"
out="$(rb history record)"; rc=$?
REC="$R/docs/history/$TODAY-tasks.md"
check "writes YYYY-MM-DD-tasks.md, exit 0"  '[ $rc -eq 0 ] && [ -f "$REC" ]'
check "heading + Finished line with count"  '[ "$(head -1 "$REC")" = "# Work recorded $TODAY" ] && grep -qx "\*\*Finished\*\*: $TODAY · \*\*Tasks\*\*: 5" "$REC"'
check "planless task, summary rule"         'grep -qx -- "- #1 — Task 1 title: Users can log in. (docs/tasks/done/1-t1.md)" "$REC"'
check "no **Plan** line counts as none"     'grep -qx -- "- #2 — Task 2 title (docs/tasks/done/2-t2.md)" "$REC"'
check "follow-up mention is not recorded"   '[ "$(grep -c "^- #2 " "$REC")" = 1 ]'
check "retired plan: title from git"        'grep -qx "### Plan 7: Retired seven" "$REC" && grep -q "^- #3 — Task 3 title: Gone plan work. " "$REC"'
check "uncommitted deletion: title from HEAD" 'grep -qx "### Plan 12: Twelve, deleted not committed" "$REC" && grep -q "^- #7 " "$REC"'
check "retired plan, no git file: Plan N"   'grep -qx "### Plan 8: Plan 8" "$REC" && grep -q "^- #4 " "$REC"'
check "open-plan member left for plan done" '! grep -q "^- #5 " "$REC"'
check "already-recorded task skipped"       '! grep -q "^- #6 " "$REC"'
check "plan groups, then Other work last"   '[ "$(grep "^### " "$REC" | tr "\n" "|")" = "### Plan 7: Retired seven|### Plan 8: Plan 8|### Plan 12: Twelve, deleted not committed|### Other work|" ]'
check "record is staged"                    'rg diff --cached --name-only | grep -qx "docs/history/$TODAY-tasks.md"'

echo "Record again"
out="$(rb history record)"; rc=$?
check "nothing new: notice, exit 0, no file" '[ $rc -eq 0 ] && [ "$out" = "History is up to date with done/." ] && [ "$(ls "$R/docs/history" | wc -l | tr -d " ")" = 2 ]'
task 10 none "Later work."
out="$(rb history record)"
check "same day: -2 suffix, only the new task" '[ -f "$R/docs/history/$TODAY-tasks-2.md" ] && grep -q "^- #10 " "$R/docs/history/$TODAY-tasks-2.md" && [ "$(grep -c "^- #" "$R/docs/history/$TODAY-tasks-2.md")" = 1 ]'
rc=0; out="$(rb history record extra)" || rc=$?
check "record with an argument fails"       '[ $rc -ne 0 ]'

echo "Reading tasks records"
out="$(rb history)"
check "list: <date> · tasks · <count> tasks" 'grep -qx "$TODAY · tasks · 5 tasks" <<<"$out" && grep -qx "$TODAY · tasks · 1 tasks" <<<"$out"'
check "list keeps plan records"              'grep -q "^2026-09-01  Plan 5" <<<"$out"'
out="$(rb history --since 2026-09-01)"
check "notes: plan section first"            '[ "$(grep "^### " <<<"$out" | head -1)" = "### Earlier" ]'
check "notes: Plan N groups, Other work last" '[ "$(grep "^### " <<<"$out" | tail -4 | tr "\n" "|")" = "### Plan 7: Retired seven|### Plan 8: Plan 8|### Plan 12: Twelve, deleted not committed|### Other work|" ]'
check "notes: records merged, pointers gone" 'grep -qx -- "- Task 1 title: Users can log in." <<<"$out" && grep -qx -- "- Task 10 title: Later work." <<<"$out" && [[ "$out" != *"docs/tasks"* ]]'
rg add -A && rg commit -qm recorded && rg tag r1
task 11 none
rb history record >/dev/null
out="$(rb history --since r1)"
check "--since ref: only the new tasks record" '[ "$(grep -c "^- " <<<"$out")" = 1 ] && grep -qx -- "- Task 11 title" <<<"$out"'

# ── Breaker (task 439): history record in real-world shapes ──────────
echo "Record breaker"
# Subfolder install: git paths are repo-root relative, the board is not.
M2="$TMP/mono2"
mkdir -p "$M2/app/docs/sprintbias" "$M2/app/docs/tasks/done" "$M2/app/docs/plans"
cp -R "$ROOT/docs/sprintbias/." "$M2/app/docs/sprintbias/"
cp "$ROOT/sprint.sh" "$M2/app/sprint.sh"
m2() { git -C "$M2" -c user.name=t -c user.email=t@t "$@"; }
printf '# Plan 4: Nested retired\n\n## Goal\n\nG.\n' > "$M2/app/docs/plans/4-n.md"
printf '# Plan 6: Nested uncommitted\n\n## Goal\n\nG.\n' > "$M2/app/docs/plans/6-u.md"
printf '# Task 1: One\n\n**Plan**: 4\n' > "$M2/app/docs/tasks/done/1-one.md"
printf '# Task 2: Two\n\n**Plan**: 6\n' > "$M2/app/docs/tasks/done/2-two.md"
m2 init -q && m2 add -A && m2 commit -qm base
m2 rm -q app/docs/plans/4-n.md && m2 commit -qm "retire 4"
rm "$M2/app/docs/plans/6-u.md"
(cd "$M2/app" && ./sprint.sh history record >/dev/null 2>&1)
NREC="$(ls "$M2/app/docs/history/"*-tasks.md 2>/dev/null | head -1)"
check "subfolder install: committed deletion keeps its title"   'grep -qx "### Plan 4: Nested retired" "$NREC"'
check "subfolder install: uncommitted deletion keeps its title" 'grep -qx "### Plan 6: Nested uncommitted" "$NREC"'
check "subfolder install: record is staged"  'm2 diff --cached --name-only | grep -q "^app/docs/history/.*-tasks.md$"'

# No git, no docs/history yet, CRLF task, zero-padded and #-prefixed plan ids.
N="$TMP/nogit"
mkdir -p "$N/docs/sprintbias" "$N/docs/tasks/done" "$N/docs/plans"
cp -R "$ROOT/docs/sprintbias/." "$N/docs/sprintbias/"
cp "$ROOT/sprint.sh" "$N/sprint.sh"
nb() { (cd "$N" && ./sprint.sh "$@" 2>&1); }
printf '# Plan 7: Open\n\n## Goal\n\nG.\n' > "$N/docs/plans/7-open.md"
printf '# Task 1: Crlf title\r\n\r\n**Plan**: none\r\n\r\n## Completed\r\n\r\n**Summary**: Windows works.\r\n' > "$N/docs/tasks/done/1-crlf.md"
printf '# Task 2: Padded\n\n**Plan**: 07\n' > "$N/docs/tasks/done/2-padded.md"
printf '# Task 3: Hashed\n\n**Plan**: #7\n' > "$N/docs/tasks/done/3-hashed.md"
printf '# Task 4: Spaced name\n\n**Plan**: none\n' > "$N/docs/tasks/done/4-spaced name.md"
printf 'no heading at all\n' > "$N/docs/tasks/done/5-bare.md"
rc=0; out="$(nb history record)" || rc=$?
NREC="$(ls "$N/docs/history/"*-tasks.md 2>/dev/null | head -1)"
check "no git, no history dir: writes, exit 0" '[ $rc -eq 0 ] && [ -f "$NREC" ] && [[ "$out" != *staged* ]]'
check "CRLF task: no CR in the record"         '! grep -q $'"'"'\r'"'"' "$NREC" && grep -qx -- "- #1 — Crlf title: Windows works. (docs/tasks/done/1-crlf.md)" "$NREC"'
check "Plan 07 is open plan 7: left out"       '! grep -q "^- #2 " "$NREC"'
check "Plan #7 is open plan 7: left out"       '! grep -q "^- #3 " "$NREC"'
check "space in file name kept whole"          'grep -qx -- "- #4 — Spaced name (docs/tasks/done/4-spaced name.md)" "$NREC"'
check "task with no heading still recorded"    'grep -q "^- #5 " "$NREC"'
check "Finished count matches lines"           'grep -q "\*\*Tasks\*\*: $(grep -c "^- #" "$NREC")$" "$NREC"'
out="$(nb history)"
check "list reads the record"                  'grep -qx "$TODAY · tasks · 3 tasks" <<<"$out"'

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
