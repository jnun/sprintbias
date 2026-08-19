#!/usr/bin/env bash
# Test: no stale legacy references after the SprintBias rename.
#
# Guards the class of bug that slipped through the docs/5day -> docs/sprint ->
# docs/sprintmd -> docs/sprintbias renames: a reference in a form the search
# didn't anticipate (e.g. a relative "../sprint/scripts" that a "docs/sprint"-
# anchored sweep skipped). Any future rename that misses a spot fails here
# instead of at runtime in a user's install.
#
# Scope: functional + distributable surfaces only. The file list comes from git
# (tracked + untracked-but-not-ignored), which excludes .git, the SprintBias
# submodule's internals, and gitignored paths (docs/tmp) for free. We further
# drop the src/ mirror (ship.sh regenerates it from docs/sprintbias and verifies
# it) and dev-internal work-item narratives (tasks/ideas/features/bugs/plans)
# that legitimately discuss project history.
#
# Allowlist rule: checks for retired *config keys* are anchored to an assignment
# form (^\s*KEY=) rather than a bare name, so intentional migration blocks that
# must name a retired key to strip it from an upgrading user's config — comments,
# arrays, and alternation regexes in setup.sh — do not trip the suite, while a
# real retired KEY=value line still fails. Prefer this anchor over deleting the
# historical migration code.
#
# Written for bash 3.2 (macOS default): indexed arrays only, no mapfile.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
PASS=0
FAIL=0

# Build the policed file list once, from git.
FILES=()
while IFS= read -r f; do
    [ -f "$f" ] && FILES+=("$f")
done < <(
    { git ls-files; git ls-files --others --exclude-standard; } 2>/dev/null \
        | grep -E '\.(sh|md|yml|template)$|(^|/)config$' \
        | grep -vE '^(src/|docs/(tasks|ideas|features|bugs|plans)/)' \
        | sort -u
)

# check [-i] <regex> <label> — fail if any policed file (other than this test)
# matches. A leading -i makes the match case-insensitive (for prose patterns
# whose capitalization varies).
check() {
    local ci=""
    if [ "$1" = "-i" ]; then ci="-i"; shift; fi
    local re="$1" label="$2" hits
    if [ ${#FILES[@]} -eq 0 ]; then
        echo "  FAIL: $label (no files to scan — not a git repo?)"
        FAIL=$((FAIL + 1))
        return
    fi
    # Exclude the rename-tooling files that legitimately CONTAIN the legacy
    # names as tripwire patterns / documentation rather than as live references:
    # this test itself, ship.sh (whose LEGACY_RE gate scans for them), setup.sh
    # (detects and removes leftover prior-docs paths on overlay), and the unit
    # test that drives those helpers.
    hits=$(grep $ci -InE "$re" "${FILES[@]}" 2>/dev/null \
        | grep -vE '(^|/)(ship|test-no-stale-refs|setup|test-setup-detection)\.sh:' \
        | grep -vE 'docs/guides/command-matrix\.md:' \
        | grep -vE 'docs/plans/')
    if [ -n "$hits" ]; then
        echo "  FAIL: $label"
        echo "$hits" | sed 's/^/        /'
        FAIL=$((FAIL + 1))
    else
        echo "  PASS: $label"
        PASS=$((PASS + 1))
    fi
}

echo "=== test-no-stale-refs.sh ==="

# Legacy framework directory (any path form).
check 'docs/5day' "no docs/5day path references"

# Legacy launcher name.
check '5day\.sh' "no 5day.sh launcher references"

# Retired framework dirs docs/sprint/ (interim) and docs/sprintmd/ (pre-rebrand),
# both renamed to the current docs/sprintbias/. 'docs/sprintbias' has 'b' after
# 'sprint', so [^b] catches docs/sprint/, docs/sprintmd, docs/sprint at EOL, etc.
# while sparing the live docs/sprintbias path.
check 'docs/sprint([^b]|$)' "no retired docs/sprint or docs/sprintmd path references"

# Pre-rebrand framework dir + lowercase symbol namespace (sprintmd -> sprintbias).
# Live surface must say sprintbias for paths and sprintbias_ for functions. The
# check is LOWERCASE on purpose: the two env vars SPRINTMD_CLI / SPRINTMD_PROVIDER
# survive as documented back-compat fallbacks (lib.sh), so they must NOT trip it.
check 'sprintmd' "no retired sprintmd path or symbol references"

# Relative / bare framework-subdir refs like ../sprint/scripts that a
# 'docs/sprint'-anchored replace would miss. [^m] before 'sprint' skips sprintmd.
check '(^|[^m])sprint/(scripts|ai|help|cli|guides|lib|config|DOC_STATE|theory)' \
    "no bare/relative sprint/ framework references"

# The framework dir shown bare in a path/tree context: "sprint/" followed by
# whitespace or end-of-line (e.g. a directory-tree diagram "└── sprint/"). The
# trailing [[:space:]]|$ requirement avoids matching the workflow-noun prose
# "sprint/backlog" (a 'b' follows the slash, not whitespace).
check '(^|[^m])sprint/([[:space:]]|$)' \
    "no bare sprint/ framework-dir references (tree diagrams)"

# Old brand prose (display names).
check '5DayDocs|Five Day Docs|5 Day Docs' "no legacy brand prose"

# Pre-SprintBias product name. Live surface must say SprintBias (product) while
# keeping ./sprint.sh, alias sprint, and docs/sprintmd/ paths. Dual-compat
# markers in setup/install and the unit tests that pin them are allowlisted;
# so is the retired help path review-sprint.md (filename, not product brand).
if [ ${#FILES[@]} -eq 0 ]; then
    echo "  FAIL: no pre-SprintBias product name (sprint.md) (no files to scan — not a git repo?)"
    FAIL=$((FAIL + 1))
else
    # Allow dual-compat: setup/install markers, unit tests, GitHub sync legacy
    # issue tags (sprint.md-task-id), and the retired review-sprint.md filename.
    _hits=$(grep -InE 'sprint\.md' "${FILES[@]}" 2>/dev/null \
        | grep -vE '(^|/)(ship|test-no-stale-refs|setup|install|test-setup-detection)\.sh:' \
        | grep -vE 'docs/guides/command-matrix\.md:' \
        | grep -vE 'docs/plans/' \
        | grep -vE 'review-sprint\.md' \
        | grep -vE 'METADATA_TAG_LEGACY|sprint\.md-task-id' \
        || true)
    if [ -n "$_hits" ]; then
        echo "  FAIL: no pre-SprintBias product name (sprint.md)"
        echo "$_hits" | sed 's/^/        /'
        FAIL=$((FAIL + 1))
    else
        echo "  PASS: no pre-SprintBias product name (sprint.md)"
        PASS=$((PASS + 1))
    fi
    unset _hits
fi

# Pre-rebrand symbol namespace (task 237). Functions were fiveday_*; env vars
# and shell vars were FIVEDAY_*. Both are now sprintmd_ / SPRINTMD_. ship.sh is
# excluded above — its LEGACY_RE patterns deliberately mention the old paths
# (docs/5day, 5day.sh) as tripwires, not as live symbols.
check -i 'fiveday' "no fiveday/FIVEDAY symbol namespace"
check 'five-day|5-day' "no five-day / 5-day brand prose"

# ── Task 212 stale patterns (docs/guides + docs/tests audit) ─────────
# These guard the specific rot this plan hunted down, so it can never silently
# return. Each is prophylactic: the tree is clean today, and this list keeps it
# clean on every future edit.

# A build/mirror script that never existed. Two guides were deleted for citing
# it; nothing should mention it again. The real mirror tool is ship.sh.
check 'build-distribution\.sh' "no build-distribution.sh references"

# 'setup.sh .' written as if it SYNCS docs/ into src/. setup.sh is the installer
# (it installs INTO a target project); the mirror step is ship.sh. Matching
# 'setup.sh' followed by a literal '.' argument catches the miswritten sync.
check 'setup\.sh[[:space:]]+\.' "no 'setup.sh .' sync claims"

# A root-level /VERSION. Versioning lives at src/VERSION (bumped by ship.sh);
# there is no repo-root VERSION file. Anchor to a path-like '/VERSION' or a
# leading 'VERSION' so ordinary prose ("the VERSION was bumped") is not matched.
check '(^|[^A-Za-z])/VERSION([^A-Za-z]|$)' "no root /VERSION claims"

# Reversed source-of-truth model. docs/ is authored and src/ is the generated
# mirror; any text claiming the reverse ("src/ is source of truth", "edit in
# src") teaches the exact inversion that corrupts the ship workflow.
check -i 'src/ is (the )?source of truth|edit in src' \
    "no reversed src/-is-source-of-truth phrasing"

# Distribution AI-pointer files ship to users but are gitignored, so they are
# absent from the git-based FILES list above. A stale brand here reaches every
# install, so scan them by explicit path. (This blind spot shipped a "5DayDocs"
# reference in src/CLAUDE.md, src/.cursorrules and src/.windsurfrules once.)
pointer_hits=""
for pf in src/CLAUDE.md src/AGENTS.md src/GEMINI.md src/.cursorrules \
          src/.windsurfrules src/.github/copilot-instructions.md; do
    [ -f "$pf" ] || continue
    m=$(grep -InE '5DayDocs|Five Day Docs|docs/5day|5day\.sh' "$pf" 2>/dev/null)
    [ -n "$m" ] && pointer_hits="${pointer_hits}${pf}: ${m}
"
done
if [ -n "$pointer_hits" ]; then
    echo "  FAIL: shipped AI-pointer files free of legacy refs"
    printf '%s' "$pointer_hits" | sed 's/^/        /'
    FAIL=$((FAIL + 1))
else
    echo "  PASS: shipped AI-pointer files free of legacy refs"
    PASS=$((PASS + 1))
fi


# ── Plan 8 retired command surface ──────────────────────────────────
# After the chat/work/gate/align/context/deps remap, live surface paths must
# not teach retired dispatch labels as runnable commands. Command-matrix
# retired-names table and this test's own patterns are allowlisted below.
check '\./sprint\.sh (talk|tasks|define|checkfeatures|ai-context|audit-deps)\b' \
    "no retired ./sprint.sh command invocations on live surface"

# Config keys renamed with the surface (hard cut). Anchored to an assignment
# form (line-start + optional indent + KEY=) so it fires only on a real live
# config line, never on prose. This is deliberate: setup.sh carries a migration
# block that must NAME these retired keys — in comments, in a _dead_keys array,
# and in a _dead_re alternation — to strip them from an upgrading user's config.
# Those references are bare names or alternations (KEY|KEY|…), not KEY= lines, so
# the assignment anchor scopes the whole block out while a planted MODEL_TALK=foo
# in docs/sprintmd/config still fails the check.
check '^[[:space:]]*(MODEL_TALK|MODEL_DEFINE|MODEL_TASKS|BUDGET_TASKS)=' \
    "no retired MODEL_TALK/DEFINE/TASKS or BUDGET_TASKS config keys"

# ── Compiled artifacts in the distribution ───────────────────────────
# Every check above is text-only: the policed list keeps .sh/.md/.yml/.template
# /config and drops src/ outright, and ship.sh's legacy gate greps with -I
# (skip binaries). A .pyc is invisible to both — yet its bytes embed the source
# path and brand it was compiled from, so committed bytecode smuggled
# `docs/sprintmd/learning/gate.py` and `sprint.md` into every install. This
# check is deliberately placed OUTSIDE the text scan: it walks src/ on the
# filesystem, so the src/ exclusion above cannot hide it.
_pyc_hits=$(find src -name '__pycache__' -o -name '*.pyc' -o -name '*.pyo' 2>/dev/null)
if [ -n "$_pyc_hits" ]; then
    echo "  FAIL: no compiled Python artifacts under src/"
    printf '%s\n' "$_pyc_hits" | sed 's/^/        /'
    echo "        Bytecode embeds the path+brand it was compiled from and is"
    echo "        invisible to every text-based scan. Remove it, and confirm"
    echo "        __pycache__/*.pyc are in .gitignore and ship.sh TREE_EXCLUDES."
    FAIL=$((FAIL + 1))
else
    echo "  PASS: no compiled Python artifacts under src/"
    PASS=$((PASS + 1))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
