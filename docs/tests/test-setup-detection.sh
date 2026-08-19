#!/usr/bin/env bash
# Test: setup.sh detection/merge helpers and the scaffold conflict machinery
#
# setup.sh writes into other people's projects, so its "did WE already install
# this?" decisions are the highest-stakes logic in the repo. Two fenced blocks in
# setup.sh carry them, and we extract both verbatim and source them so every
# assertion below runs the exact shipped code rather than a restatement of it:
#
#   `# >>> SprintBias detection helpers` — pure string logic (already_ours,
#     gitignore_merge, sprint_marker_version, ver_lt). No file I/O, no state.
#   `# >>> SprintBias scaffold helpers`   — the version-marker machinery that
#     acts on real paths (classify_target, pointer_block/readme_block, prepend /
#     replace, apply_conflict, resolve_conflict_interactive, resolve_manual_file).
#   `# >>> SprintBias legacy-docs overlay helpers` — 5DayDocs leftover cleanup
#     (counter seed, manual detect, README rewrite, prune).
#
# The scaffold block touches files and prints through msg_*, so its tests run in
# a temp working directory with CURRENT_VERSION / MANUAL_FILE set and the msg_*
# reporters stubbed — the same inputs the installer supplies, minus the UI.

set -euo pipefail

PASS=0
FAIL=0
SETUP_SH="$(cd "$(dirname "$0")/../.." && pwd)/setup.sh"

# --- Extract the fenced helper blocks from setup.sh and source them ---
HELPERS="$(mktemp)"
SCAFFOLD="$(mktemp)"
OVERLAY="$(mktemp)"
WORK="$(mktemp -d)"
trap 'rm -f "$HELPERS" "$SCAFFOLD" "$OVERLAY"; rm -rf "$WORK"' EXIT
awk '/# >>> SprintBias detection helpers/{f=1;next} /# <<< SprintBias detection helpers/{f=0} f' \
    "$SETUP_SH" > "$HELPERS"
awk '/# >>> SprintBias scaffold helpers/{f=1;next} /# <<< SprintBias scaffold helpers/{f=0} f' \
    "$SETUP_SH" > "$SCAFFOLD"
awk '/# >>> SprintBias legacy-docs overlay helpers/{f=1;next} /# <<< SprintBias legacy-docs overlay helpers/{f=0} f' \
    "$SETUP_SH" > "$OVERLAY"

if [ ! -s "$HELPERS" ]; then
    echo "FAIL: could not extract detection helpers from $SETUP_SH (sentinels missing?)"
    exit 1
fi
if [ ! -s "$SCAFFOLD" ]; then
    echo "FAIL: could not extract scaffold helpers from $SETUP_SH (sentinels missing?)"
    exit 1
fi
if [ ! -s "$OVERLAY" ]; then
    echo "FAIL: could not extract legacy-docs overlay helpers from $SETUP_SH (sentinels missing?)"
    exit 1
fi
# shellcheck disable=SC1090
source "$HELPERS"
# shellcheck disable=SC1090
source "$SCAFFOLD"
# shellcheck disable=SC1090
source "$OVERLAY"

assert_true() {
    local desc="$1"; shift
    if "$@"; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected success, got exit $?)"
        FAIL=$((FAIL + 1))
    fi
}

assert_false() {
    local desc="$1"; shift
    if "$@"; then
        echo "  FAIL: $desc (expected failure, got success)"
        FAIL=$((FAIL + 1))
    else
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    fi
}

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc"
        printf '    expected: %q\n' "$expected"
        printf '    actual:   %q\n' "$actual"
        FAIL=$((FAIL + 1))
    fi
}

assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if printf '%s' "$haystack" | grep -qF -- "$needle"; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc (expected to contain '$needle')"
        FAIL=$((FAIL + 1))
    fi
}

assert_not_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if printf '%s' "$haystack" | grep -qF -- "$needle"; then
        echo "  FAIL: $desc (unexpectedly contained '$needle')"
        FAIL=$((FAIL + 1))
    else
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    fi
}

echo "=== test-setup-detection.sh ==="

# ---------------------------------------------------------------------------
# already_ours: matches OUR marker, ignores incidental substrings
# ---------------------------------------------------------------------------

echo "Test 1: already_ours matches a file we wrote (marker present)"
OURS='> **Project documentation** → see DOCUMENTATION.md (managed by [SprintBias](https://sprintbias.com))'
assert_true "our README pointer is recognized" \
    already_ours "$SPRINT_README_MARKER" "$OURS"

echo "Test 1b: already_ours_readme recognizes current and legacy README markers"
assert_true "current README pointer via already_ours_readme" \
    already_ours_readme "$OURS"
LEGACY_OURS='> **Project documentation** → see DOCUMENTATION.md (managed by [sprint.md](https://github.com/jnun/sprint.md))'
assert_true "legacy sprint.md README pointer still recognized" \
    already_ours_readme "$LEGACY_OURS"
FIVEDAY_OURS='> **Project documentation** → see [`DOCUMENTATION.md`](DOCUMENTATION.md) (managed by [5DayDocs](https://github.com/jnun/5daydocs))'
assert_true "prior-docs 5DayDocs README pointer still recognized" \
    already_ours_readme "$FIVEDAY_OURS"

echo "Test 2: already_ours does NOT fire on an incidental 'SprintBias' mention"
# A host project that merely references the tool by name must not be mistaken
# for one we've already modified.
INCIDENTAL='# My project\nWe use SprintBias to plan work. See setup notes.'
assert_false "bare 'SprintBias' mention is not treated as ours" \
    already_ours "$SPRINT_README_MARKER" "$INCIDENTAL"

echo "Test 3: already_ours does NOT fire on an incidental 'DOCUMENTATION.md' mention"
# The old gate keyed off this filename; an unrelated mention must not match.
DOC_MENTION='See DOCUMENTATION.md for our internal API docs.'
assert_false "bare 'DOCUMENTATION.md' mention is not treated as ours" \
    already_ours "$SPRINT_AI_MARKER" "$DOC_MENTION"

echo "Test 4: already_ours recognizes an AI pointer we wrote"
AI_OURS='Read `DOCUMENTATION.md` before making any changes. It is the single source of truth for how this project is organized, how tasks are managed, and how to use the SprintBias system.'
assert_true "our AI pointer is recognized" \
    already_ours "$SPRINT_AI_MARKER" "$AI_OURS"

echo "Test 5: already_ours matches the marker literally (glob chars are safe)"
# The gitignore marker contains '===' — ensure it's matched as text, not a glob.
GI='# === SprintBias Recommended Entries ===\n.tmp/'
assert_true "gitignore header marker matched literally" \
    already_ours "$SPRINT_GITIGNORE_MARKER" "$(printf '%b' "$GI")"

# ---------------------------------------------------------------------------
# gitignore_merge: fresh install, idempotent re-run, phrased-differently
# ---------------------------------------------------------------------------

RECOMMENDED='# SprintBias temp
.sprint-tmp/
node_modules/

# Editor
.vscode/'

echo "Test 6: fresh install returns all recommended entries"
merged="$(gitignore_merge "$RECOMMENDED" "")"
assert_contains "includes .sprint-tmp/" "$merged" ".sprint-tmp/"
assert_contains "includes node_modules/" "$merged" "node_modules/"
assert_contains "includes .vscode/" "$merged" ".vscode/"

echo "Test 7: idempotent re-run returns nothing (all entries already present)"
existing="$RECOMMENDED"
merged="$(gitignore_merge "$RECOMMENDED" "$existing")"
assert_eq "empty output when nothing new" "" "$merged"

echo "Test 8: existing .gitignore that incidentally contains 'SprintBias'"
# A comment mentioning SprintBias must NOT suppress the real merge — the entries
# it lacks still come through (this is the exact false-positive the old
# grep -q 'SprintBias' early-out caused).
existing='# we track work with SprintBias
build/'
merged="$(gitignore_merge "$RECOMMENDED" "$existing")"
assert_contains "still adds .sprint-tmp/ despite the SprintBias comment" "$merged" ".sprint-tmp/"
assert_contains "still adds node_modules/" "$merged" "node_modules/"

echo "Test 9: partial overlap — only missing entries returned, no orphan headers"
existing='.sprint-tmp/
node_modules/'
merged="$(gitignore_merge "$RECOMMENDED" "$existing")"
assert_not_contains "does not re-add node_modules/" "$merged" "node_modules/"
assert_contains "adds .vscode/" "$merged" ".vscode/"
# The 'SprintBias temp' section is fully covered, so its header must be dropped;
# only the Editor section (which has a new entry) survives.
assert_not_contains "orphan 'SprintBias temp' header dropped" "$merged" "SprintBias temp"
assert_contains "Editor header kept (its section has a new entry)" "$merged" "# Editor"

echo "Test 10: entries phrased differently are NOT deduped (exact-line match)"
# gitignore_merge dedups by exact line. An equivalent-but-differently-written
# entry is intentionally treated as new (we never guess semantic equivalence).
existing='node_modules'          # no trailing slash -> different line
merged="$(gitignore_merge "$RECOMMENDED" "$existing")"
assert_contains "differently-phrased entry still added" "$merged" "node_modules/"

# ---------------------------------------------------------------------------
# sprint_marker_version: the version-stamped ownership marker is the ONLY
# signal that a file is ours (a bare "SprintBias" mention never matches).
# ---------------------------------------------------------------------------

echo "Test 11: reads the version from a Markdown marker"
assert_eq "Markdown marker version parsed" "0.0.58" \
    "$(sprint_marker_version '<!-- SprintBias v0.0.58 -->
# My file')"

echo "Test 11b: reads the version from a legacy sprint.md Markdown marker"
assert_eq "legacy Markdown marker version parsed" "0.0.57" \
    "$(sprint_marker_version '<!-- sprint.md v0.0.57 -->
# My file')"

echo "Test 12: reads the version from a .gitignore marker"
assert_eq "gitignore marker version parsed" "1.2.3" \
    "$(sprint_marker_version '# SprintBias v1.2.3
node_modules/')"

echo "Test 12b: reads the version from a legacy sprint.md .gitignore marker"
assert_eq "legacy gitignore marker version parsed" "1.0.0" \
    "$(sprint_marker_version '# sprint.md v1.0.0
node_modules/')"

echo "Test 13: a bare SprintBias mention has no version (not ours)"
assert_eq "incidental mention -> empty version" "" \
    "$(sprint_marker_version 'We manage work with SprintBias, see setup.')"

# ---------------------------------------------------------------------------
# ver_lt: numeric semver ordering (never string ordering).
# ---------------------------------------------------------------------------

echo "Test 14: older version is strictly less than newer"
assert_true "0.0.9 < 0.0.10 (numeric, not string)" ver_lt "0.0.9" "0.0.10"

echo "Test 15: equal versions are NOT less-than (no needless overwrite)"
assert_false "0.0.58 is not < 0.0.58" ver_lt "0.0.58" "0.0.58"

echo "Test 16: newer version is NOT less than older"
assert_false "0.1.0 is not < 0.0.99" ver_lt "0.1.0" "0.0.99"

# ===========================================================================
# Scaffold helpers — classification, conflict actions, manual-name routing.
#
# From here down the helpers touch real files. Everything runs inside $WORK
# (a temp dir) against the installer's own state variables, with the reporters
# stubbed so assertions read file contents, not terminal output.
# ===========================================================================

CURRENT_VERSION="9.9.9"
MANUAL_FILE="DOCUMENTATION.md"
CONFLICTS=()
FILES_COPIED=1          # non-zero: setup.sh's ((FILES_COPIED++)) is fine at 0,
                        # but this test runs under `set -e`, where it is not.
msg_success() { :; }
msg_step()    { :; }
msg_error()   { :; }
msg_warning() { :; }

cd "$WORK"

USER_BODY='# My Project

Our own instructions live here.'

echo "Test 17: classify_target names all four states of a pointer-style file"
rm -f CLAUDE.md
assert_eq "missing file -> absent" "absent" "$(classify_target CLAUDE.md)"

printf '%s\n' "$(pointer_block)" > CLAUDE.md
assert_eq "file we just wrote -> ours-current:VER" "ours-current:9.9.9" \
    "$(classify_target CLAUDE.md)"

# Same file, product moved on: our older marker authorizes an in-place upgrade.
CURRENT_VERSION="9.9.10"
assert_eq "our older marker -> ours-old:VER" "ours-old:9.9.9" \
    "$(classify_target CLAUDE.md)"
# 9.9.9 < 9.9.10 is the numeric compare — a string compare would call it current.
CURRENT_VERSION="9.9.9"

printf '%s\n' "$USER_BODY" > CLAUDE.md
assert_eq "unmarked user file -> theirs" "theirs" "$(classify_target CLAUDE.md)"

echo "Test 18: apply_conflict prepend keeps the user's content, replace does not"
printf '%s\n' "$USER_BODY" > CLAUDE.md
apply_conflict pointer CLAUDE.md CLAUDE.md prepend
prepended="$(cat CLAUDE.md)"
assert_contains "prepend keeps the user's body" "$prepended" "Our own instructions live here."
assert_contains "prepend adds our versioned marker" "$prepended" "<!-- SprintBias v9.9.9 -->"
assert_eq "prepend puts our marker on line 1" "<!-- SprintBias v9.9.9 -->" "$(head -n1 CLAUDE.md)"

printf '%s\n' "$USER_BODY" > CLAUDE.md
apply_conflict pointer CLAUDE.md CLAUDE.md replace
replaced="$(cat CLAUDE.md)"
assert_not_contains "replace drops the user's body" "$replaced" "Our own instructions live here."
assert_contains "replace leaves our block" "$replaced" "<!-- SprintBias v9.9.9 -->"

echo "Test 18b: an unrecognized action falls back to prepend (never to overwrite)"
# apply_conflict's case is `prepend|*)` — anything we can't parse must take the
# safe branch, because the unsafe one destroys a user's file.
printf '%s\n' "$USER_BODY" > CLAUDE.md
apply_conflict pointer CLAUDE.md CLAUDE.md bogus-action
assert_contains "unknown action still keeps the user's body" "$(cat CLAUDE.md)" \
    "Our own instructions live here."

echo "Test 18c: the silent default path prepends every deferred conflict"
# The non-interactive branch (no "More options?") is the path almost every
# install takes. It runs apply_deferred_conflicts over the CONFLICTS queue; that
# helper must parse each "kind|target|name" entry and apply prepend — keeping the
# user's body, never overwriting. Driven behaviorally, not by grepping source.
printf '%s\n' "$USER_BODY" > CLAUDE.md
printf '%s\n' "$USER_BODY" > AGENTS.md
CONFLICTS=("pointer|CLAUDE.md|CLAUDE.md" "pointer|AGENTS.md|AGENTS.md")
apply_deferred_conflicts
assert_eq "prepend put our marker on line 1 of CLAUDE.md" "<!-- SprintBias v9.9.9 -->" \
    "$(head -n1 CLAUDE.md)"
assert_contains "CLAUDE.md keeps the user's body" "$(cat CLAUDE.md)" \
    "Our own instructions live here."
assert_eq "prepend put our marker on line 1 of AGENTS.md" "<!-- SprintBias v9.9.9 -->" \
    "$(head -n1 AGENTS.md)"
assert_contains "AGENTS.md keeps the user's body" "$(cat AGENTS.md)" \
    "Our own instructions live here."
CONFLICTS=()

echo "Test 19: the interactive binary is Enter=Prepend / o=Overwrite, nothing else"
printf '%s\n' "$USER_BODY" > CLAUDE.md
menu="$(printf '\n' | resolve_conflict_interactive pointer CLAUDE.md CLAUDE.md)"
assert_contains "Enter keeps the user's body (prepend)" "$(cat CLAUDE.md)" \
    "Our own instructions live here."
assert_contains "menu offers Prepend on Enter" "$menu" "[Enter]  Prepend"
assert_contains "menu offers Overwrite on o" "$menu" "o)       Overwrite"

printf '%s\n' "$USER_BODY" > CLAUDE.md
printf 'o\n' | resolve_conflict_interactive pointer CLAUDE.md CLAUDE.md >/dev/null
assert_not_contains "o overwrites the user's body" "$(cat CLAUDE.md)" \
    "Our own instructions live here."

# No third branch: any other keystroke is Prepend, and the menu never says Leave.
printf '%s\n' "$USER_BODY" > CLAUDE.md
other="$(printf 'q\n' | resolve_conflict_interactive pointer CLAUDE.md CLAUDE.md)"
assert_contains "an unlisted key falls through to prepend" "$(cat CLAUDE.md)" \
    "Our own instructions live here."
assert_not_contains "no Leave option is offered" "$other" "Leave"

echo "Test 20: MANUAL_FILE routes to SPRINTDOCUMENTATION.md when the manual is theirs"
printf '%s\n' '# Our internal API docs' > DOCUMENTATION.md   # no marker -> theirs
assert_eq "user-owned DOCUMENTATION.md -> theirs" "theirs" \
    "$(classify_target DOCUMENTATION.md)"
assert_eq "manual retargets to SPRINTDOCUMENTATION.md" "SPRINTDOCUMENTATION.md" \
    "$(resolve_manual_file)"

MANUAL_FILE="$(resolve_manual_file)"
assert_contains "AI pointer block names the retargeted manual" "$(pointer_block)" \
    "SPRINTDOCUMENTATION.md"
assert_contains "README block names the retargeted manual" "$(readme_block)" \
    "SPRINTDOCUMENTATION.md"

echo "Test 20b: MANUAL_FILE stays DOCUMENTATION.md when the manual is ours (or absent)"
printf '<!-- SprintBias v9.9.9 -->\n# Manual\n' > DOCUMENTATION.md
assert_eq "our own manual -> DOCUMENTATION.md" "DOCUMENTATION.md" "$(resolve_manual_file)"
rm -f DOCUMENTATION.md
assert_eq "absent manual -> DOCUMENTATION.md" "DOCUMENTATION.md" "$(resolve_manual_file)"
MANUAL_FILE="$(resolve_manual_file)"

echo "Test 21: README is on the versioned-marker path, like every other scaffold"
# Before #359 the README was recognized only by the text "managed by
# [SprintBias]". It now carries the same <!-- SprintBias vX.Y.Z --> marker as
# the AI pointers, so classify_target governs it and upgrades are in-place.
block="$(readme_block)"
assert_contains "readme_block stamps the versioned marker" "$block" "<!-- SprintBias v9.9.9 -->"
assert_contains "readme_block closes the marker" "$block" "<!-- end SprintBias -->"
assert_contains "readme_block keeps the human-readable attribution" "$block" \
    "managed by [SprintBias]"

printf '%s\n' "$block" > README.md
assert_eq "a README we wrote classifies exactly like a pointer scaffold" \
    "ours-current:9.9.9" "$(classify_target README.md)"

# The legacy text-only pointer is the migration case, not the recognizer: it
# classifies as "theirs" and scaffold_readme upgrades it onto the marker path.
printf '%s\n\n%s\n' \
    '> **Project documentation** → see DOCUMENTATION.md (managed by [SprintBias](https://sprintbias.com))' \
    "$USER_BODY" > README.md
assert_eq "legacy text pointer alone is not a marker" "theirs" "$(classify_target README.md)"
scaffold_readme
assert_eq "scaffold_readme migrates it onto the marker path" "ours-current:9.9.9" \
    "$(classify_target README.md)"
upgraded="$(cat README.md)"
assert_contains "upgrade keeps the user's body" "$upgraded" "Our own instructions live here."
assert_eq "upgrade leaves exactly one pointer line" "1" \
    "$(grep -c 'managed by \[SprintBias\]' README.md)"

echo "Test 22: the deferral policy — a theirs target is queued, not touched"
# scaffold_pointer / scaffold_readme must NOT write a user-owned file inline;
# they append "kind|target|name" to CONFLICTS and leave the file byte-identical
# until the conflict pass runs. This is the visible-deferral guarantee.
CONFLICTS=()
MANUAL_FILE="DOCUMENTATION.md"
printf '%s\n' "$USER_BODY" > CLAUDE.md
before="$(md5 -q CLAUDE.md 2>/dev/null || md5sum CLAUDE.md | cut -d' ' -f1)"
scaffold_pointer CLAUDE.md CLAUDE.md
after="$(md5 -q CLAUDE.md 2>/dev/null || md5sum CLAUDE.md | cut -d' ' -f1)"
assert_eq "scaffold_pointer leaves the theirs file byte-identical" "$before" "$after"
assert_eq "scaffold_pointer queued exactly one conflict" "1" "${#CONFLICTS[@]}"
assert_eq "queued entry is kind|target|name" "pointer|CLAUDE.md|CLAUDE.md" "${CONFLICTS[0]}"

printf '%s\n' "$USER_BODY" > README.md
before="$(md5 -q README.md 2>/dev/null || md5sum README.md | cut -d' ' -f1)"
scaffold_readme
after="$(md5 -q README.md 2>/dev/null || md5sum README.md | cut -d' ' -f1)"
assert_eq "scaffold_readme leaves the theirs file byte-identical" "$before" "$after"
assert_eq "scaffold_readme queued a second conflict" "2" "${#CONFLICTS[@]}"
assert_eq "queued readme entry is kind|target|name" "readme|README.md|README.md" "${CONFLICTS[1]}"
CONFLICTS=()

echo "Test 23: apply_conflict's kind selects the block — readme vs pointer wording"
# The README speaks to human readers; the AI pointer to agents. Same marker,
# different body. Swapping the two block choices in apply_conflict must fail here.
printf '%s\n' "$USER_BODY" > README.md
apply_conflict readme README.md README.md prepend
assert_contains "readme kind writes the README attribution line" "$(cat README.md)" \
    "managed by [SprintBias]"
assert_not_contains "readme kind does NOT write the agent pointer wording" "$(cat README.md)" \
    "before making any changes"

printf '%s\n' "$USER_BODY" > CLAUDE.md
apply_conflict pointer CLAUDE.md CLAUDE.md prepend
assert_contains "pointer kind writes the agent wording" "$(cat CLAUDE.md)" \
    "before making any changes"
assert_not_contains "pointer kind does NOT write the README attribution line" "$(cat CLAUDE.md)" \
    "managed by [SprintBias]"

echo "Test 24: apply_conflict gitignore — prepend merges, replace rewrites fresh"
# _write_gitignore_fresh is the installer's most destructive write; drive both
# actions with a seeded GITIGNORE_CONTENT and a user-owned .gitignore.
GITIGNORE_CONTENT='.sprint-tmp/
node_modules/'
printf '%s\n' 'build/' > .gitignore   # user's own body, no marker
apply_conflict gitignore .gitignore .gitignore prepend
merged="$(cat .gitignore)"
assert_contains "prepend adds the missing SprintBias entry" "$merged" ".sprint-tmp/"
assert_contains "prepend keeps the user's own entry" "$merged" "build/"
assert_eq "prepend puts our marker on line 1" "# SprintBias v9.9.9" "$(head -n1 .gitignore)"

printf '%s\n' 'build/' > .gitignore
apply_conflict gitignore .gitignore .gitignore replace
replaced="$(cat .gitignore)"
assert_contains "replace writes the SprintBias entries" "$replaced" ".sprint-tmp/"
assert_not_contains "replace drops the user's own entry" "$replaced" "build/"
assert_eq "replace opens with our marker" "# SprintBias v9.9.9" "$(head -n1 .gitignore)"
rm -f .gitignore

echo "Test 25: install_owned_doc never clobbers a user-owned target"
# The whole-document installer (GETSTARTED, the manual) must skip a theirs file
# untouched — the guarantee that makes the SPRINTDOCUMENTATION.md retarget safe.
printf '%s\n' '# My own GETSTARTED' > SRC-owned.md   # a "shipped" source
printf '%s\n' "$USER_BODY" > OWNED.md                # a user file with no marker
before="$(md5 -q OWNED.md 2>/dev/null || md5sum OWNED.md | cut -d' ' -f1)"
install_owned_doc SRC-owned.md OWNED.md OWNED.md
after="$(md5 -q OWNED.md 2>/dev/null || md5sum OWNED.md | cut -d' ' -f1)"
assert_eq "install_owned_doc left the user's file byte-identical" "$before" "$after"
assert_not_contains "the user's file did not take our content" "$(cat OWNED.md)" \
    "My own GETSTARTED"
rm -f SRC-owned.md OWNED.md

# ===========================================================================
# Prior-docs overlay — leftover cleanup when SprintBias lands on 5DayDocs
# ===========================================================================

echo "Test 26: legacy_docs_manual_content recognizes our manual across its lineage"
assert_true "H1 5DayDocs is our manual" \
    legacy_docs_manual_content '# 5DayDocs

Project management in markdown files.
- `5day.sh`
- `docs/5day/`'
assert_true "H1 sprint.md is our manual (pre-marker era)" \
    legacy_docs_manual_content '# sprint.md

Project management in markdown files. Folders and plain text.

## Guiding principles'
assert_true "H1 SprintBias (unmarked) is our manual" \
    legacy_docs_manual_content '# SprintBias

Project management in markdown files.'
assert_true "guiding-principles fingerprint is our manual, whatever the title" \
    legacy_docs_manual_content '# Docs

1. Lean into agent bias.
2. Minimize context cost.'
assert_true "old Workflow Guide + 5day.sh is our manual" \
    legacy_docs_manual_content '# Documentation and Workflow Guide

Using the 5day.sh Script
The `5day.sh` script is a convenient command interface.'
assert_false "a host project's own DOCUMENTATION.md is not our manual" \
    legacy_docs_manual_content '# My API docs

See DOCUMENTATION.md for endpoints. We use SprintBias for tasks.'
assert_false "only one guiding-principle name present is not enough" \
    legacy_docs_manual_content '# Team handbook

We lean into agent bias when reviewing PRs.'
assert_false "our current marked manual is not flagged (content sniff only)" \
    legacy_docs_manual_content "$(pointer_block)
# SprintBias

Read this before making changes."

echo "Test 27: seed helpers take max(state file, disk prefix), leave empty kinds at 0"
STATE_FIVEDAY='# state
**5DAY_TASK_ID**: 0
**5DAY_BUG_ID**: 0
'
assert_eq "zeroed prior-docs counters stay 0" "0" \
    "$(seed_kind_id "$STATE_FIVEDAY" TASK)"
assert_eq "missing bug counter is 0" "0" \
    "$(seed_kind_id "$STATE_FIVEDAY" BUG)"
assert_eq "missing plan counter is 0" "0" \
    "$(seed_kind_id "$STATE_FIVEDAY" PLAN)"

STATE_MIXED='# state
**sprint_TASK_ID**: 0
**5DAY_TASK_ID**: 14
**sprint_BUG_ID**: 0
**5DAY_BUG_ID**: 0
**sprint_EPIC_ID**: 3
'
assert_eq "max of sprint_ 0 and 5DAY_ 14 is 14" "14" \
    "$(seed_kind_id "$STATE_MIXED" TASK)"
assert_eq "highest_numeric_prefix picks 179 over 12" "179" \
    "$(highest_numeric_prefix 'docs/tasks/done/12-old.md' 'docs/tasks/backlog/179-latest.md')"
assert_eq "leading zeros parse as decimal" "7" \
    "$(highest_numeric_prefix 'docs/tasks/done/007-padded.md')"
assert_eq "no names -> 0" "0" "$(highest_numeric_prefix)"
assert_eq "int_max of counter 0 and disk 179 is 179" "179" \
    "$(int_max 0 179)"
assert_eq "int_max keeps a higher counter than disk" "200" \
    "$(int_max 200 179)"

echo "Test 28: rewrite_legacy_docs_readme rewrites brand/paths, keeps the body"
README_OLD='# Project Name

This project uses [5DayDocs](https://github.com/jnun/5daydocs) for task management. See `DOCUMENTATION.md` for workflow details.
Run `./5day.sh status`. Scripts live in docs/5day/scripts.
'
rewritten="$(rewrite_legacy_docs_readme "$README_OLD")"
assert_contains "brand becomes SprintBias" "$rewritten" "SprintBias"
assert_not_contains "old brand is gone" "$rewritten" "5DayDocs"
assert_contains "github link becomes sprintbias.com" "$rewritten" "https://sprintbias.com"
assert_not_contains "old github link is gone" "$rewritten" "github.com/jnun/5daydocs"
assert_contains "launcher becomes sprint.sh" "$rewritten" "./sprint.sh status"
assert_contains "framework path becomes docs/sprintbias/" "$rewritten" "docs/sprintbias/scripts"
assert_contains "user heading kept" "$rewritten" "# Project Name"
assert_contains "DOCUMENTATION.md left as DOCUMENTATION.md" "$rewritten" '`DOCUMENTATION.md`'

echo "Test 29: scaffold_readme upgrades a 5DayDocs banner onto the marker path"
printf '%s\n\n%s\n' \
    '> **Project documentation** → see [`DOCUMENTATION.md`](DOCUMENTATION.md) (managed by [5DayDocs](https://github.com/jnun/5daydocs))' \
    "$USER_BODY" > README.md
assert_eq "5DayDocs banner alone is not a version marker" "theirs" \
    "$(classify_target README.md)"
scaffold_readme
assert_eq "scaffold_readme migrates the 5DayDocs banner onto the marker path" \
    "ours-current:9.9.9" "$(classify_target README.md)"
upgraded="$(cat README.md)"
assert_contains "upgrade keeps the user's body" "$upgraded" "Our own instructions live here."
assert_eq "upgrade leaves exactly one SprintBias pointer" "1" \
    "$(grep -c 'managed by \[SprintBias\]' README.md)"
assert_not_contains "old 5DayDocs banner line is gone" "$upgraded" "managed by [5DayDocs]"

echo "Test 30: drop_legacy_docs_manual removes an unmarked copy of our manual, not a user file"
printf '%s\n' '# 5DayDocs

- `5day.sh`
- `docs/5day/`' > DOCUMENTATION.md
drop_legacy_docs_manual
assert_false "old 5DayDocs manual is gone" test -f DOCUMENTATION.md
assert_eq "resolve_manual_file now returns DOCUMENTATION.md" "DOCUMENTATION.md" \
    "$(resolve_manual_file)"

# The reported case: a pre-marker sprint.md-era manual, unmarked, is replaced too.
printf '%s\n' '# sprint.md

Project management in markdown files. Folders and plain text.

## Guiding principles

1. Lean into agent bias.
2. Minimize context cost.' > DOCUMENTATION.md
drop_legacy_docs_manual
assert_false "old sprint.md-era manual is gone" test -f DOCUMENTATION.md

# Marker guard: our own current manual carries the fingerprint but IS marked, so
# it is upgraded in place by install_owned_doc, never dropped here.
printf '%s\n' '<!-- SprintBias v9.9.9 -->
# SprintBias

1. Lean into agent bias.
2. Minimize context cost.' > DOCUMENTATION.md
drop_legacy_docs_manual || true
assert_true "marked manual with the fingerprint is kept" test -f DOCUMENTATION.md
rm -f DOCUMENTATION.md

printf '%s\n' '# Our internal API docs' > DOCUMENTATION.md
drop_legacy_docs_manual || true
assert_true "user-owned DOCUMENTATION.md is kept" test -f DOCUMENTATION.md
assert_eq "user-owned manual still retargets" "SPRINTDOCUMENTATION.md" \
    "$(resolve_manual_file)"
rm -f DOCUMENTATION.md

echo "Test 31: prune_legacy_docs_leftovers removes framework leftovers, keeps user work"
mkdir -p docs/5day/scripts docs/5day/ai docs/tasks docs/features docs/bugs docs/ideas \
         docs/tasks/backlog
printf '%s\n' '#!/bin/sh' > 5day.sh
printf '%s\n' '# old framework' > docs/5day/lib.sh
printf '%s\n' '# old state' > docs/5day/DOC_STATE.md
printf '%s\n' 'undotted' > docs/tasks/TEMPLATE-task.md
printf '%s\n' 'dotted' > docs/tasks/.TEMPLATE-task.md
printf '%s\n' 'undotted' > docs/features/TEMPLATE-feature.md
printf '%s\n' 'dotted' > docs/features/.TEMPLATE-feature.md
printf '%s\n' 'undotted-only' > docs/bugs/TEMPLATE-bug.md
printf '%s\n' '# Task 179' > docs/tasks/backlog/179-existing.md
printf '%s\n' '**5DAY_TASK_ID**: 0
**5DAY_VERSION**: 4.1.0' > docs/STATE.md

prune_legacy_docs_leftovers
assert_false "5day.sh removed" test -e 5day.sh
assert_false "docs/5day/ removed" test -e docs/5day
assert_false "undotted task template removed" test -e docs/tasks/TEMPLATE-task.md
assert_true "dotted task template kept" test -f docs/tasks/.TEMPLATE-task.md
assert_false "undotted feature template removed" test -e docs/features/TEMPLATE-feature.md
assert_true "dotted feature template kept" test -f docs/features/.TEMPLATE-feature.md
assert_true "undotted bug template kept when no dotted counterpart" \
    test -f docs/bugs/TEMPLATE-bug.md
assert_true "existing task file kept" test -f docs/tasks/backlog/179-existing.md
assert_false "old docs/STATE.md removed after seed" test -e docs/STATE.md

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
