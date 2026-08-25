#!/usr/bin/env bash
# Test: sprintbias_scrub_template_scaffold (lib.sh).
#
# The task template ships each section with a <!-- … --> guidance comment, an
# after-work "## Completed" how-to block, and an "AI:" footer. work.sh strips
# exactly those when a task is run, so a worked task never carries authoring
# scaffolding and later readers never pay context for it. These asserts lock the
# behavior — and the two antifragility guarantees most likely to regress under a
# careless edit: an author's OWN HTML note survives (no signature false positive)
# and intentional blank lines inside a fenced code block are left untouched
# (no global blank squeeze).
#
# Sources the *repo* lib.sh so asserts hit the real product helper, not a copy.
# Operates only on throwaway files under a mktemp dir; never the real docs/tasks/.
# Discovered by run-all.sh (test-*.sh). Pure shell, no live AI.

set -euo pipefail

PASS=0
FAIL=0
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=/dev/null
source "$REPO/docs/sprintbias/lib.sh"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

ok()   { echo "  PASS: $1"; PASS=$((PASS + 1)); }
bad()  { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }
assert()      { if eval "$2"; then ok "$1"; else bad "$1"; fi; }
assert_not()  { if eval "$2"; then bad "$1"; else ok "$1"; fi; }

# ── A fully scaffolded, filled task with an author note + fenced code ──
cat > "$WORK/a.md" <<'EOF'
# Task 999: Do a real thing

## Problem

<!-- Clear, simple language. Concisely define the problem at a high level —
     who is stuck, what is wrong, why it matters. 2–5 short sentences. -->

The widget explodes on load.

## Success criteria

<!-- What done looks like. When these are met, the task is done. -->

- [x] Widget loads

## Notes

<!-- Optional helpful hints that assist the developer: constraints. -->

<!-- Author note: "What done looks like" here is subjective. Keep me. -->

Example:

```
a


b
```

## References

<!-- Direct paths to docs or files known to be related. One path per line. -->

<!-- After work only — audit trail of what was touched. Helps committers.
       ## Completed
       ### Files changed -->

<!--
AI: Full task-writing guidance is in docs/sprintbias/ai/task-creation.md
Keep it plain text — no emoji. -->
EOF

sprintbias_scrub_template_scaffold "$WORK/a.md"
assert_not "A: every template hint block removed" \
    'grep -qE "Concisely define the problem at a high level|What done looks like\. When these|Optional helpful hints that assist the developer|Direct paths to docs or files known to be related|audit trail of what was touched|Full task-writing guidance is in" "$WORK/a.md"'
assert "A: author HTML note survives (no false positive)" 'grep -q "Author note" "$WORK/a.md"'
assert "A: real Problem content intact" 'grep -q "The widget explodes on load" "$WORK/a.md"'
assert "A: real success criterion intact" 'grep -q "Widget loads" "$WORK/a.md"'
# The fenced block held two blank lines between a and b — both must remain.
fence_blanks=$(awk 'BEGIN{f=0} /^```/{f=!f;next} f&&/^[ \t]*$/{c++} END{print c+0}' "$WORK/a.md")
assert "A: fenced-code blank lines preserved (no squeeze)" '[ "$fence_blanks" = "2" ]'

# ── Idempotent ──
cp "$WORK/a.md" "$WORK/a.bak"
sprintbias_scrub_template_scaffold "$WORK/a.md"
assert "B: second pass is a no-op (idempotent)" 'diff -q "$WORK/a.md" "$WORK/a.bak" >/dev/null'

# ── Worked task: real ## Completed sits next to the instruction block ──
printf '# Task 998\n\n## Problem\n\nBroke.\n\n<!-- After work only — audit trail of what was touched. -->\n\n## Completed\n\n### Files changed\ndocs/real.sh\n' > "$WORK/c.md"
sprintbias_scrub_template_scaffold "$WORK/c.md"
assert_not "C: instruction comment removed" 'grep -q "audit trail of what was touched" "$WORK/c.md"'
assert "C: real ## Completed preserved" 'grep -q "## Completed" "$WORK/c.md"'
assert "C: real ### Files changed preserved" 'grep -q "docs/real.sh" "$WORK/c.md"'

# ── No scaffolding: file is byte-for-byte unchanged ──
printf '# Task 1\n\n## Problem\n\nJust prose.\n' > "$WORK/d.md"
cp "$WORK/d.md" "$WORK/d.bak"
sprintbias_scrub_template_scaffold "$WORK/d.md"
assert "D: scaffold-free file untouched" 'diff -q "$WORK/d.md" "$WORK/d.bak" >/dev/null'

# ── Robustness: missing/empty args and an unterminated comment ──
sprintbias_scrub_template_scaffold "$WORK/absent.md"
assert "E: missing file returns success" '[ $? -eq 0 ]'
sprintbias_scrub_template_scaffold ""
assert "E: empty arg returns success" '[ $? -eq 0 ]'
printf '# Task 2\n\n<!-- After work only — audit trail of what was touched\nnever closed\n' > "$WORK/f.md"
sprintbias_scrub_template_scaffold "$WORK/f.md"
assert "F: unterminated comment keeps its text (no data loss)" 'grep -q "never closed" "$WORK/f.md"'

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
