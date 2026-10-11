#!/usr/bin/env bash
# Test: the learning demos run, write nothing, and show what the commands print
# (plan 32, task 432).
#
#   1. Every demo in docs/sprintbias/learning/ runs with --fast --no-color from
#      an empty directory, exits 0, and leaves that directory empty.
#   2. The end-of-run checklist work.py plays is the one work.sh prints: a real
#      work run (stub CLI, one landed task with a call and no Tests) and the
#      demo both carry each checklist line, so the two cannot drift.
#   3. promote.py closes its no-Tests task with promote --accept; no demo names
#      the retired settle command.
#   4. crew.py: the lead routes what a landing releases ("built on #N (landed)")
#      and closes the plan with one promote plan:N.
#
# No live AI. Discovered by run-all.sh.

set -euo pipefail

PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LEARN="$ROOT/docs/sprintbias/learning"

ok()  { echo "  PASS: $1"; PASS=$((PASS + 1)); }
bad() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }
has() { if grep -qF -- "$3" <<<"$2"; then ok "$1"; else bad "$1 (missing: $3)"; fi; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Every demo runs and writes nothing"
mkdir -p "$TMP/empty"
for demo in "$LEARN"/*.py; do
    name="$(basename "$demo")"
    if (cd "$TMP/empty" && python3 -I "$demo" --fast --no-color </dev/null >/dev/null 2>&1); then
        ok "$name exits 0"
    else
        bad "$name exits 0"
    fi
done
if [ -z "$(ls -A "$TMP/empty")" ]; then ok "no demo wrote a file"; else bad "a demo wrote: $(ls -A "$TMP/empty" | tr '\n' ' ')"; fi

echo "work.py shows the checklist work.sh prints"
B="$TMP/board"
mkdir -p "$B"/docs/tasks/{next,doing,review,blocked,backlog,done} "$B/docs/tmp"
printf '# Task 100: Original work\n\nDo the thing.\n\n## Questions\n\n**Status: READY**\n' \
    > "$B/docs/tasks/next/100-original.md"
cat > "$TMP/stub" <<'STUB'
#!/usr/bin/env bash
for f in docs/tasks/doing/*.md; do
  [ -f "$f" ] || continue
  printf '\n## Completed\n\n### Assumptions\n- Decided: limit per IP, because it is simpler\n\n**Proof**: 2026-10-10 · bash t.sh · pass\n' >> "$f"
done
printf '{"type":"result","subtype":"success","num_turns":1,"duration_ms":10,"total_cost_usd":0}\n'
STUB
chmod +x "$TMP/stub"
REAL="$(cd "$B" && SPRINTBIAS_MODE=exec SPRINTBIAS_CLI="$TMP/stub" NO_COLOR=1 \
    bash "$ROOT/docs/sprintbias/scripts/work.sh" </dev/null 2>&1 || true)"
DEMO="$(cd "$TMP/empty" && python3 -I "$LEARN/work.py" --fast --no-color </dev/null 2>&1 || true)"
for want in "▸ Your turn — " \
            "1. Check the 1 call(s) the AI made for you:" \
            "- Decided: limit per IP" \
            'Want one changed? → ./sprint.sh newtask "<the change you want>"' \
            "2. Try the change. Something wrong?" \
            "→ ./sprint.sh promote --reject " \
            "Happy with it? Sign it off (the breaker checks it first):" \
            "→ ./sprint.sh promote --accept "; do
    has "work.sh prints: $want" "$REAL" "$want"
    has "work.py shows:  $want" "$DEMO" "$want"
done

echo "promote.py and settle"
PDEMO="$(cd "$TMP/empty" && python3 -I "$LEARN/promote.py" --fast --no-color </dev/null 2>&1 || true)"
has "promote.py closes the no-Tests task with --accept" "$PDEMO" "./sprint.sh promote --accept 74"
if grep -lw "settle" "$LEARN"/*.py >/dev/null 2>&1; then
    bad "no demo names settle ($(grep -lw settle "$LEARN"/*.py | xargs -n1 basename | tr '\n' ' '))"
else
    ok "no demo names settle"
fi

echo "crew.py routes on landing and closes with one promote plan:N"
CDEMO="$(cd "$TMP/empty" && python3 -I "$LEARN/crew.py" --fast --no-color </dev/null 2>&1 || true)"
has "a member reports its landing" "$CDEMO" "#41 landed"
has "the lead routes what the landing releases" "$CDEMO" "built on #41 (landed)"
has "the lead hands one promote plan:N" "$CDEMO" "One sign-off for you: ./sprint.sh promote plan:5"
if grep -qF "review, commit, and ship" <<<"$CDEMO"; then
    bad "crew.py no longer ends on review, commit, and ship"
else
    ok "crew.py no longer ends on review, commit, and ship"
fi
_routed=$(grep -nF "built on #41 (landed)" <<<"$CDEMO" | head -1 | cut -d: -f1)
_landed=$(grep -nF "review/41" <<<"$CDEMO" | head -1 | cut -d: -f1)
if [ -n "$_routed" ] && [ -n "$_landed" ] && [ "$_landed" -lt "$_routed" ]; then
    ok "#43 is routed after #41 lands"
else
    bad "#43 is routed after #41 lands (landed line ${_landed:-?}, routed line ${_routed:-?})"
fi

# Breaker: the crew demo teaches "the move into doing/ is the claim", so #43
# is claimed (next/43 → doing/43) after #41 lands and before #43 lands.
_line() { { grep -nF -- "$1" <<<"$CDEMO" || true; } | head -1 | cut -d: -f1; }
_l41=$(_line "review/41"); _c43=$(_line "next/43 → doing/43"); _r43=$(_line "review/43")
if [ -n "$_l41" ] && [ -n "$_c43" ] && [ -n "$_r43" ] && [ "$_l41" -lt "$_c43" ] && [ "$_c43" -lt "$_r43" ]; then
    ok "Breaker: #43 is claimed into doing/ after #41 lands, before it lands"
else
    bad "Breaker: #43 claimed between #41 landing and #43 landing (41 ${_l41:-?}, claim ${_c43:-?}, 43 ${_r43:-?})"
fi
# Breaker: the lead runs the full suite only after every member has landed.
_r42=$(_line "review/42"); _suite=$(_line "promote plan:5 </dev/null")
if [ -n "$_suite" ] && [ -n "$_r42" ] && [ -n "$_r43" ] && [ "$_r42" -lt "$_suite" ] && [ "$_r43" -lt "$_suite" ]; then
    ok "Breaker: the full suite runs after #42 and #43 land"
else
    bad "Breaker: full suite after every landing (42 ${_r42:-?}, 43 ${_r43:-?}, suite ${_suite:-?})"
fi
# Breaker: no member starts #43 on its own before #41 lands.
if grep -qF "starting #43" <<<"$CDEMO"; then bad "Breaker: dill starts #43 on its own"; else ok "Breaker: dill waits for the lead to route #43"; fi
# Breaker: one promote plan:N hand-off, and the same output on a second run.
_n=$(grep -cF "One sign-off for you" <<<"$CDEMO" || true)
[ "$_n" = "1" ] && ok "Breaker: exactly one sign-off hand-off" || bad "Breaker: sign-off hand-off appears $_n times"
CDEMO2="$(cd "$TMP/empty" && python3 -I "$LEARN/crew.py" --fast --no-color </dev/null 2>&1 || true)"
[ "$CDEMO" = "$CDEMO2" ] && ok "Breaker: crew.py prints the same on a second run" || bad "Breaker: crew.py output differs run to run"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
