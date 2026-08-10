#!/usr/bin/env bash
# ship.sh — DEV-ONLY release tool. Mirrors the live development tree into the
# distributable src/ and bumps the version. Run from the repo root:
#
#     ./ship.sh            # bump patch  (X.Y.Z -> X.Y.Z+1) and mirror
#     ./ship.sh minor      # bump minor  (X.Y.Z -> X.Y+1.0) and mirror
#     ./ship.sh major      # bump major  (X.Y.Z -> X+1.0.0) and mirror
#     ./ship.sh --dry-run  # show exactly what would change, touch nothing
#     ./ship.sh --no-bump  # mirror only, leave the version alone
#
# THIS SCRIPT IS NOT DISTRIBUTED. It lives at the repo root (never under src/),
# so setup.sh — which only walks src/ — can never copy it into a user's project.
# Do not move it into src/ or docs/sprintbias/.
#
# ── Why this exists ──────────────────────────────────────────────────
# This repo has two trees: docs/ (the live dev environment we edit and test)
# and src/ (the distributable setup.sh installs). Every framework change must
# be mirrored docs/ -> src/ or it never reaches users. Doing that by hand, file
# by file, is the single most error-prone step in this repo. ship.sh makes it
# one command, and — because it mirrors whole trees, not enumerated files — a
# NEW script/help/ai/cli/guide file under docs/sprintbias/ is picked up automatically.
# You only edit ship.sh when a NEW distributable path appears OUTSIDE the trees
# already listed below (a new root file, a brand-new docs/ subtree to ship, or a
# new work-item template — see TEMPLATE_FILES, which lists templates by name
# because their parent dirs hold dev-only work items that must never ship).

set -euo pipefail

# Run from the repo root regardless of caller's CWD.
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Colors (blanked under NO_COLOR, matching sprint.sh) ────────────────
if [ -n "${NO_COLOR:-}" ] || [ ! -t 1 ]; then
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
else
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
fi

# ── Distribution manifest ────────────────────────────────────────────
# Everything that must exist in src/ for a working install. Keep this in sync
# with reality: if you design a new distributable file that does NOT already
# sit under one of the TREE_MIRRORS below, add it here (or add its tree).

# Single files copied from the repo root into src/ (SRC = "src/<same name>").
ROOT_FILES=(
    "sprint.sh"
    "DOCUMENTATION.md"
    "GETSTARTED.md"
)

# Work-item templates: an EXPLICIT file-level copy list, docs/ -> src/docs/.
# These live OUTSIDE docs/sprintbias/ (under docs/tasks/, docs/bugs/, …), so no
# TREE_MIRROR picks them up — yet the docs/ copy is what create-*.sh reads at
# runtime, so docs/ is the edit source and src/ must mirror it. We list each
# .TEMPLATE-* file by name and do NOT add its parent dir to TREE_MIRRORS: those
# dirs hold our dev-only work items (tasks/bugs/features/ideas/tests) that must
# never ship. Entry X maps to src/X (docs/tasks/.TEMPLATE-task.md -> src/docs/…).
TEMPLATE_FILES=(
    "docs/tasks/.TEMPLATE-task.md"
    "docs/bugs/.TEMPLATE-bug.md"
    "docs/features/.TEMPLATE-feature.md"
    "docs/ideas/.TEMPLATE-idea.md"
    "docs/tests/.TEMPLATE-test.md"
    "docs/plans/.TEMPLATE-plan.md"
)

# Whole directory trees mirrored live -> distributable, "LIVE_DIR:SRC_DIR".
# rsync --delete keeps src/ an exact copy: a file deleted from the live tree is
# removed from src/ too. New files under a live tree ship with no edit here.
TREE_MIRRORS=(
    "docs/sprintbias:src/docs/sprintbias"
)

# Paths (relative to a mirrored tree's root) that are DEV-ONLY and must never
# ship: DOC_STATE.md is generated per-install by setup.sh; tmp/ is scratch/logs.
TREE_EXCLUDES=(
    "DOC_STATE.md"
    "tmp"
    "config.local"   # personal CLI/model overlay — dev-local, never shipped
)

# ── Legacy-reference gate ────────────────────────────────────────────
# A byte-clean mirror is necessary but NOT sufficient: it proves src/ matches
# the live tree, not that the distribution is correct. A rename can leave stale
# brand/paths behind (this exact tool once shipped "5DayDocs" in src/CLAUDE.md
# and an orphaned src/docs/5day/ that the mirror never noticed). This pattern is
# the tripwire; scan_legacy applies it to the WHOLE distribution before ship
# declares success. Extend it whenever a rename retires a name.
#
# It matches: the old brand in any spelling; the legacy launcher/dir names; the
# retired framework dir 'sprintmd' in any path form and the lowercase 'sprintmd_'
# symbol namespace (the rebrand renamed both to 'sprintbias'); and
# 'sprint/<framework-subdir>' or a bare 'sprint/' dir (tree diagrams), which is
# NOT the current 'sprintbias/'. 'sprintbias/' has 'b' after 'sprint', so the
# 'sprint/' alternation (slash right after 'sprint') never matches it; the
# subdir/space/EOL requirement after 'sprint/' avoids the workflow noun ("plan a
# sprint", "sprint/backlog index"). The 'sprintmd' alternation is LOWERCASE on
# purpose: the two pre-rebrand env vars SPRINTMD_CLI / SPRINTMD_PROVIDER survive
# as documented back-compat fallbacks in lib.sh and must NOT trip this gate.
LEGACY_RE='5DayDocs|Five Day Docs|5 Day Docs|docs/5day|5day\.sh|sprintmd|(^|[^m])sprint/(scripts|ai|help|cli|guides|lib|config|DOC_STATE|theory|[[:space:]]|$)'

# scan_legacy PATH... — print "file:line:match" for every legacy reference under
# the given files/dirs. Uses find+xargs, NOT grep -r, so gitignored-but-shipped
# files (src/CLAUDE.md, src/.cursorrules, …) are still scanned — a grep that
# honored .gitignore is precisely how the stale brand slipped through before.
scan_legacy() {
    local p ex
    # Prune the same dev-only paths the mirror excludes (DOC_STATE.md, tmp/):
    # they never ship, so a legacy string in an old tmp log must not block a ship.
    local -a prunes=()
    for ex in "${TREE_EXCLUDES[@]}"; do
        prunes+=( -name "$ex" -o )
    done
    for p in "$@"; do
        [ -e "$p" ] || continue
        if [ -d "$p" ]; then
            find "$p" \( "${prunes[@]}" -false \) -prune -o -type f -print0 2>/dev/null \
                | xargs -0 grep -HnIE "$LEGACY_RE" 2>/dev/null || true
        else
            grep -HnIE "$LEGACY_RE" "$p" 2>/dev/null || true
        fi
    done
}

# find_orphan_frameworks — print any src/ subtree sitting under a mirror target's
# parent that has NO live docs/ counterpart by name. This is the class rsync
# --delete cannot catch: it prunes INSIDE a target, never a renamed sibling like
# src/docs/sprintmd (left by a docs/sprintmd -> docs/sprintbias move) or src/docs/epics
# (left by a docs/epics -> docs/plans rename). The check is purely STRUCTURAL —
# "src/docs/<name>/ with no docs/<name>/" — so it is brand-agnostic and catches
# the whole class of "renamed live dir, stale src/ sibling," including
# template-only dirs a lib.sh/scripts heuristic would miss.
find_orphan_frameworks() {
    local pair live dist src_parent live_parent d name
    for pair in "${TREE_MIRRORS[@]}"; do
        live="${pair%%:*}"; dist="${pair#*:}"
        src_parent="$(dirname "$dist")"; live_parent="$(dirname "$live")"
        [ -d "$src_parent" ] || continue
        for d in "$src_parent"/*/; do
            [ -d "$d" ] || continue
            d="${d%/}"; name="$(basename "$d")"
            [ -d "$live_parent/$name" ] && continue
            echo "$d"
        done
    done | sort -u
}

# ── Usage ────────────────────────────────────────────────────────────
# Self-contained help text. Kept here (not sed'd out of the header comment)
# so it can never drift with the comment's line numbers.
usage() {
    cat <<'EOF'
ship.sh — DEV-ONLY release tool. Mirrors the live development tree (docs/) into
the distributable src/, verifies the mirror, gates the distribution, and bumps
the version. Run from the repository root.

Usage: ./ship.sh [major|minor|patch] [--dry-run] [--no-bump]

  patch         bump patch (X.Y.Z -> X.Y.Z+1) and mirror   [default]
  minor         bump minor (X.Y.Z -> X.Y+1.0) and mirror
  major         bump major (X.Y.Z -> X+1.0.0) and mirror
  --dry-run     show exactly what would change (incl. gate + version preview),
                touch nothing
  --no-bump     mirror only, leave src/VERSION unchanged
  -h, --help    show this help and exit

Not distributed: this script lives at the repo root, never under src/, so
setup.sh — which only walks src/ — can never copy it into a user's project.
EOF
}

# ── Argument parsing ─────────────────────────────────────────────────
BUMP="patch"
DRY_RUN=0
NO_BUMP=0
for arg in "$@"; do
    case "$arg" in
        major|minor|patch) BUMP="$arg" ;;
        --dry-run)         DRY_RUN=1 ;;
        --no-bump)         NO_BUMP=1 ;;
        -h|--help)         usage; exit 0 ;;
        *)
            echo -e "${RED}✗ Unknown argument: $arg${NC}" >&2
            usage >&2
            exit 1 ;;
    esac
done

# ── Version helper ───────────────────────────────────────────────────
bump_version() {
    local cur="$1" level="$2" major minor patch
    IFS='.' read -r major minor patch <<< "$cur"
    if ! [[ "$major" =~ ^[0-9]+$ && "$minor" =~ ^[0-9]+$ && "$patch" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}✗ src/VERSION is not X.Y.Z: '$cur'${NC}" >&2
        return 1
    fi
    case "$level" in
        major) major=$((major + 1)); minor=0; patch=0 ;;
        minor) minor=$((minor + 1)); patch=0 ;;
        patch) patch=$((patch + 1)) ;;
    esac
    printf '%s.%s.%s' "$major" "$minor" "$patch"
}

# ── Preflight: must be the SprintBias dev root ─────────────────────────
for required in "setup.sh" "src" "docs/sprintbias" "src/VERSION"; do
    if [ ! -e "$required" ]; then
        echo -e "${RED}✗ Not in the SprintBias dev root (missing: $required)${NC}" >&2
        echo "  Run ./ship.sh from the repository root." >&2
        exit 1
    fi
done

# Fail fast on a malformed version BEFORE any files are touched — a bump we
# can't compute must not leave a half-mirrored src/ behind. (Skipped when
# --no-bump, since the version is then irrelevant.)
if [ "$NO_BUMP" -eq 0 ] && ! bump_version "$(cat src/VERSION)" "$BUMP" >/dev/null 2>&1; then
    echo -e "${RED}✗ src/VERSION is not X.Y.Z: '$(cat src/VERSION)' — fix it or use --no-bump${NC}" >&2
    exit 1
fi

echo -e "${BOLD}SprintBias — ship${NC}"
[ "$DRY_RUN" -eq 1 ] && echo -e "${YELLOW}(dry run — no files will change)${NC}"
echo ""

# Exclude flags, built once and reused by rsync (mirror) and diff (preview +
# verify). Keeping both in lockstep is what lets the preview, the copy, and the
# verification all agree on which paths are dev-only.
_rsync_excludes=()
_diff_excludes=()
for ex in "${TREE_EXCLUDES[@]}"; do
    _rsync_excludes+=(--exclude "$ex")
    _diff_excludes+=(--exclude="$ex")
done

# ── Step 1: show pending changes (what this run will mirror) ─────────
# Content-based (diff), NOT timestamp-based: rsync -a resyncs mtimes on every
# run, so an rsync itemize would flag identical files as "changed". git ignores
# mtimes, so the only changes worth reporting are real content adds/edits/prunes.
echo -e "${BLUE}▸ Changes to mirror into src/:${NC}"
CHANGES=0

for f in "${ROOT_FILES[@]}" "${TEMPLATE_FILES[@]}"; do
    if [ ! -f "$f" ]; then
        echo -e "  ${RED}missing live file: $f${NC}"; continue
    fi
    if ! diff -q "$f" "src/$f" >/dev/null 2>&1; then
        marker="~"; [ -f "src/$f" ] || marker="+"
        echo "  $marker $f -> src/$f"; CHANGES=$((CHANGES + 1))
    fi
done

for pair in "${TREE_MIRRORS[@]}"; do
    live="${pair%%:*}"; dist="${pair#*:}"
    # A brand-new tree (dist absent) can't be diffed, so `diff -rq` would print
    # only a stderr error and the preview would silently report ZERO changes —
    # the exact reason an earlier run claimed "2 paths" while creating 62 files.
    # Count the whole tree explicitly instead.
    if [ ! -d "$dist" ]; then
        n=$(find "$live" -type f ! -name DOC_STATE.md -not -path "*/tmp/*" 2>/dev/null | wc -l | tr -d ' ')
        echo "  + $dist (NEW tree — $n files will ship)"; CHANGES=$((CHANGES + n))
        continue
    fi
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        echo "  $line"; CHANGES=$((CHANGES + 1))
    done < <(diff -rq "${_diff_excludes[@]}" "$live" "$dist" 2>/dev/null \
        | sed -E \
            -e "s|^Files (.*) and .* differ|~ \1 (edited)|" \
            -e "s|^Only in ($live[^:]*): (.*)|+ \1/\2 (new — will ship)|" \
            -e "s|^Only in ($dist[^:]*): (.*)|- \1/\2 (stale — will be pruned)|")
done

if [ "$CHANGES" -eq 0 ]; then
    echo "  (none — src/ already matches the live tree)"
else
    echo -e "  ${YELLOW}$CHANGES path(s) will change${NC}"
fi
echo ""

if [ "$DRY_RUN" -eq 1 ]; then
    # Preview the release gates read-only so a dry run is a FULL preview. Scan
    # the live mirror sources (which will become src/) plus the current src/
    # (its hand-maintained files ship unchanged) — that is the distribution the
    # real run would gate.
    gate_preview="$(scan_legacy docs/sprintbias "${ROOT_FILES[@]}" src | sort -u)"
    orphan_preview="$(find_orphan_frameworks)"
    if [ -n "$gate_preview" ] || [ -n "$orphan_preview" ]; then
        echo -e "${YELLOW}▸ Release gates would BLOCK this ship:${NC}"
        [ -n "$gate_preview" ]   && { echo "  legacy references:";     echo "$gate_preview"   | sed 's/^/    /'; }
        [ -n "$orphan_preview" ] && { echo "  orphan framework dirs:"; echo "$orphan_preview" | sed 's/^/    /'; }
    else
        echo -e "${GREEN}▸ Release gates: clean (no legacy refs, no orphan framework dirs)${NC}"
    fi
    echo ""
    # Also preview the version bump so a dry run is a full preview.
    CUR="$(cat src/VERSION)"
    if [ "$NO_BUMP" -eq 0 ]; then
        echo -e "${BLUE}▸ Version:${NC} $CUR -> $(bump_version "$CUR" "$BUMP" 2>/dev/null || echo '?')"
    fi
    echo -e "${YELLOW}Dry run complete. Re-run without --dry-run to apply.${NC}"
    exit 0
fi

# ── Step 2: mirror live -> src/ ──────────────────────────────────────
echo -e "${BLUE}▸ Mirroring live tree into src/…${NC}"

for f in "${ROOT_FILES[@]}" "${TEMPLATE_FILES[@]}"; do
    mkdir -p "$(dirname "src/$f")"
    cp -p "$f" "src/$f"
    echo "  copied $f -> src/$f"
done

for pair in "${TREE_MIRRORS[@]}"; do
    live="${pair%%:*}"; dist="${pair#*:}"
    mkdir -p "$dist"
    rsync -a --delete "${_rsync_excludes[@]}" "$live/" "$dist/"
    echo "  synced $live/ -> $dist/ (excluding: ${TREE_EXCLUDES[*]})"
done

# NB: we deliberately do NOT chmod the shipped files. rsync -a and cp -p mirror
# the live file's exact mode, so an executable script (755) stays executable and
# a *sourced* profile like cli/*.sh (644) stays non-executable. Forcing +x here
# would flip those 644 files to 755 and show up as spurious git mode changes.
# setup.sh runs its own chmod +x on install, so runnability is covered there.
echo ""

# ── Step 3: verify src/ is an exact mirror of the live tree ──────────
# The mirror above is only trustworthy if the trees are provably identical
# afterward. Any residual difference (other than the dev-only excludes) means
# something is wrong — fail loudly rather than ship a broken package. Runs
# BEFORE the version bump so a bad mirror never bumps the version.
echo -e "${BLUE}▸ Verifying src/ matches the live tree…${NC}"
VERIFY_FAIL=0

for f in "${ROOT_FILES[@]}" "${TEMPLATE_FILES[@]}"; do
    if ! diff -q "$f" "src/$f" >/dev/null 2>&1; then
        echo -e "  ${RED}MISMATCH: $f != src/$f${NC}"; VERIFY_FAIL=1
    fi
done

for pair in "${TREE_MIRRORS[@]}"; do
    live="${pair%%:*}"; dist="${pair#*:}"
    if ! out="$(diff -rq "${_diff_excludes[@]}" "$live" "$dist" 2>&1)"; then
        echo -e "  ${RED}Tree differs: $live vs $dist${NC}"
        echo "$out" | sed 's/^/    /'
        VERIFY_FAIL=1
    fi
done

if [ "$VERIFY_FAIL" -ne 0 ]; then
    echo -e "${RED}✗ Verification failed — src/ is NOT a clean mirror. Investigate above.${NC}" >&2
    exit 1
fi
echo -e "  ${GREEN}✓ src/ is a clean mirror of the live tree${NC}"
echo ""

# ── Step 4: release gates over the WHOLE distribution ────────────────
# A clean mirror only proves src == live for the mirrored paths. These gates
# prove the thing the mirror can't: that the ENTIRE shipped src/ — including the
# hand-maintained files ship never mirrors (templates, .github, pointer stubs)
# and any sibling the mirror can't prune — is actually correct. This is the
# check that would have caught both bugs this tool once shipped: stale "5DayDocs"
# brand in gitignored pointer files, and an orphaned src/docs/5day/ tree.
echo -e "${BLUE}▸ Gating the distribution (legacy refs, orphan dirs)…${NC}"
GATE_FAIL=0

legacy_hits="$(scan_legacy src)"
if [ -n "$legacy_hits" ]; then
    echo -e "  ${RED}Legacy references in the distribution:${NC}"
    echo "$legacy_hits" | sed 's/^/    /'
    GATE_FAIL=1
fi

orphans="$(find_orphan_frameworks)"
if [ -n "$orphans" ]; then
    echo -e "  ${RED}Orphan framework dir(s) no manifest entry produces:${NC}"
    echo "$orphans" | sed 's/^/    /'
    echo -e "  ${YELLOW}(a rename left these behind — delete them, then re-ship)${NC}"
    GATE_FAIL=1
fi

# Gate: every hand-maintained distributable must be git-TRACKABLE, not just
# present on disk. The mirror check proves src == live on the filesystem, but
# the distribution ships via git — a file the repo's .gitignore silently
# ignores is missing from any clone, so setup.sh installs a broken tree. This
# is exactly how src/CLAUDE.md, src/.cursorrules, src/.windsurfrules and
# src/.github/copilot-instructions.md once got eaten by an unanchored AI-file
# pattern: on disk they looked perfect, but they were never committable.
# git check-ignore prints (and exits 0 for) any path that IS ignored.
SHIP_MUST_TRACK=(
    src/CLAUDE.md
    src/AGENTS.md
    src/.cursorrules
    src/.windsurfrules
    src/.github/copilot-instructions.md
    src/.gitignore.template
)
if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
    ignored_shipped="$(git check-ignore "${SHIP_MUST_TRACK[@]}" 2>/dev/null || true)"
    if [ -n "$ignored_shipped" ]; then
        echo -e "  ${RED}Shipped file(s) are git-ignored — absent from any clone:${NC}"
        echo "$ignored_shipped" | sed 's/^/    /'
        echo -e "  ${YELLOW}(an over-broad .gitignore pattern matches these — anchor it to the repo root with a leading \"/\")${NC}"
        GATE_FAIL=1
    fi
fi

if [ "$GATE_FAIL" -ne 0 ]; then
    echo -e "${RED}✗ Distribution gate failed — refusing to ship. Fix the above, then re-run.${NC}" >&2
    echo -e "${YELLOW}  (src/ was mirrored but the version was NOT bumped.)${NC}" >&2
    exit 1
fi
echo -e "  ${GREEN}✓ No legacy references, no orphan framework dirs${NC}"
echo ""

# ── Step 5: bump the version (only after every gate has passed) ──────
CUR_VERSION="$(cat src/VERSION)"
if [ "$NO_BUMP" -eq 1 ]; then
    echo -e "${BLUE}▸ Version:${NC} $CUR_VERSION (unchanged — --no-bump)"
else
    NEW_VERSION="$(bump_version "$CUR_VERSION" "$BUMP")"
    printf '%s' "$NEW_VERSION" > src/VERSION
    echo -e "${BLUE}▸ Version:${NC} $CUR_VERSION -> ${GREEN}$NEW_VERSION${NC} ($BUMP)"
fi
echo ""

# ── Done ─────────────────────────────────────────────────────────────
echo -e "${GREEN}${BOLD}✓ Shipped.${NC}"
echo "  Review and commit:"
echo "    git add -A && git status"
echo "    git commit -m \"ship: v$(cat src/VERSION)\""
