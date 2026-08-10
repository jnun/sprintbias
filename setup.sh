#!/usr/bin/env bash
# setup.sh - SprintBias unified installer and updater
# Usage:
#   ./setup.sh                  # prompt (default: current directory)
#   ./setup.sh /path/to/project # install/update into that path
#   ./setup.sh ~/code/my-app    # ~ is expanded (target must already exist)
#   SPRINT_TARGET=./my-app ./setup.sh
#
# One-liner from any project (fetches source, then runs this):
#   curl -fsSL https://raw.githubusercontent.com/jnun/sprintbias/main/install.sh | bash
#
# This script handles both fresh installations and updates with version migrations.
# Distribution: src/ mirrors the deployed layout — setup.sh walks it recursively.

# Guard: this script requires bash (arrays, [[ ]], (( )), etc.).
# Running it with sh/dash/zsh will produce cryptic failures.
if [ -z "$BASH_VERSION" ]; then
    echo "Error: setup.sh must be run with bash, not sh." >&2
    echo "Run it as:  ./setup.sh  or  bash setup.sh" >&2
    exit 1
fi

# Note: We intentionally omit set -euo pipefail. This is an interactive
# installer that handles errors via msg_error/msg_warning and ERRORS[].
# set -e would abort mid-install on expected failures (missing optional files,
# user declining prompts); -u would break the BASH_VERSION guard above; and
# -o pipefail would kill grep|wc pipelines that legitimately match zero lines.

# If stdin is a pipe (e.g. `curl ... | bash setup.sh`), try to rebind it
# to the controlling tty so interactive prompts still work. If no tty is
# available (backgrounded process, Docker without -t, daemon, etc.) the
# exec silently fails — bash leaves fd 0 intact, we keep reading from
# the pipe, and prompt_yes_no's EOF fallback handles the empty case.
# File redirection (`bash setup.sh < answers.txt`) is untouched: regular
# files don't match `-p`, so scripted installs continue to work.
if [ -p /dev/stdin ]; then
    # Brace group + 2>/dev/null is required: `exec < /dev/tty 2>/dev/null`
    # parses as exec-with-two-redirects, and bash prints the failure of
    # the first redirect to the *original* fd 2 before the second redirect
    # is applied — the error message leaks. Wrapping in `{ ...; } 2>/dev/null`
    # gives the exec a temporary fd 2 pointing at /dev/null for the
    # duration of the group, so the failure (if any) is silenced. The exec
    # only modifies fd 0; the brace group's temporary fd 2 reverts after.
    { exec < /dev/tty; } 2>/dev/null || true
fi

# Get the SprintBias source directory (where this script lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPRINTBIAS_SOURCE_DIR="$SCRIPT_DIR"

# ============================================================================
# MESSAGE SYSTEM - Consistent, color-coded output
# ============================================================================

# Colors (disabled if not a terminal)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
fi

# Track errors for final summary
ERRORS=()
WARNINGS=()

# Message functions
msg_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

msg_success() {
    echo -e "${GREEN}✓${NC} $1"
}

msg_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    WARNINGS+=("$1")
}

msg_error() {
    echo -e "${RED}✗${NC} $1"
    ERRORS+=("$1")
}

msg_step() {
    echo -e "  ${CYAN}→${NC} $1"
}

msg_header() {
    echo ""
    echo -e "${BOLD}$1${NC}"
}

# Safe file copy with error handling
# Usage: safe_copy "source" "dest" "description"
safe_copy() {
    local src="$1"
    local dest="$2"
    local desc="${3:-$(basename "$src")}"

    if [ ! -f "$src" ]; then
        msg_warning "Source not found: $desc"
        return 1
    fi

    # Check if destination exists and is writable
    if [ -f "$dest" ] && [ ! -w "$dest" ]; then
        msg_error "Cannot write to $dest (permission denied)"
        msg_step "Fix with: chmod u+w \"$dest\""
        return 1
    fi

    # Check if destination directory is writable
    local dest_dir
    dest_dir="$(dirname "$dest")"
    if [ ! -w "$dest_dir" ]; then
        msg_error "Cannot write to directory $dest_dir (permission denied)"
        return 1
    fi

    if cp -f "$src" "$dest" 2>/dev/null; then
        msg_step "Copied $desc"
        return 0
    else
        msg_error "Failed to copy $desc"
        return 1
    fi
}

# Safe directory creation
# Usage: safe_mkdir "path"
safe_mkdir() {
    local dir="$1"
    if [ -d "$dir" ]; then
        return 0
    fi

    if mkdir -p "$dir" 2>/dev/null; then
        msg_step "Created: $dir"
        return 0
    else
        msg_error "Failed to create directory: $dir"
        return 1
    fi
}

# Read current version from source
if [ -f "$SPRINTBIAS_SOURCE_DIR/src/VERSION" ]; then
    CURRENT_VERSION=$(cat "$SPRINTBIAS_SOURCE_DIR/src/VERSION")
else
    echo "Warning: VERSION file not found, defaulting to 1.0.0"
    CURRENT_VERSION="1.0.0"
fi

echo "================================================"
echo "  SprintBias - Project Documentation Setup"
echo "================================================"
echo "  Version: $CURRENT_VERSION"
echo ""

# Target project path: $1, SPRINT_TARGET, or prompt (default: current directory)
if [ -n "${1:-}" ]; then
    TARGET_PATH="$1"
elif [ -n "${SPRINT_TARGET:-}" ]; then
    TARGET_PATH="$SPRINT_TARGET"
else
    echo "Enter the path to your project where SprintBias should be installed:"
    echo "(default: current directory — press Enter for .)"
    read -r TARGET_PATH
    TARGET_PATH="${TARGET_PATH:-.}"
fi

# Expand tilde and resolve relative paths
TARGET_PATH="${TARGET_PATH/#\~/$HOME}"
if [ -z "$TARGET_PATH" ]; then
    msg_error "No path provided"
    exit 1
fi

if [ ! -d "$TARGET_PATH" ]; then
    msg_error "Path does not exist: $TARGET_PATH"
    msg_step "Create the directory first, then run setup again"
    exit 1
fi

TARGET_PATH="$(cd "$TARGET_PATH" 2>/dev/null && pwd)" || {
    msg_error "Cannot access path: $TARGET_PATH"
    msg_step "Check that you have read permissions for this directory"
    exit 1
}

echo ""
echo "Target directory: $TARGET_PATH"
echo ""

# Change to target directory
cd "$TARGET_PATH" || exit 1

# Self-targeting detection
if [ "$TARGET_PATH" = "$SPRINTBIAS_SOURCE_DIR" ]; then
    echo "Note: Target is the SprintBias source directory."
    echo "   This will sync src/ to docs/ for development/testing."
    echo ""
fi

# ============================================================================
# DETECT INSTALLATION STATE
# ============================================================================

INSTALLED_VERSION=""
UPDATE_MODE=false

# Check if SprintBias is already installed. Product version lives only in
# docs/sprintbias/DOC_STATE.md (written from src/VERSION). There is no separate
# migration-epoch ladder — layout cleanups below are path-presence only.
if [ -f "docs/sprintbias/DOC_STATE.md" ]; then
    INSTALLED_VERSION=$(grep '^\*\*sprint_VERSION\*\*:' docs/sprintbias/DOC_STATE.md 2>/dev/null | sed 's/.*:[[:space:]]*//' | head -1)
    [ -n "$INSTALLED_VERSION" ] || INSTALLED_VERSION="unknown"

    UPDATE_MODE=true
    echo "Existing SprintBias installation detected (version $INSTALLED_VERSION)"
    echo "This will update to version $CURRENT_VERSION"
    echo ""
elif [ -f "docs/STATE.md" ]; then
    # Older layout: STATE.md at docs/ root — will be moved to DOC_STATE.md below.
    INSTALLED_VERSION=$(grep '^\*\*sprint_VERSION\*\*:' docs/STATE.md 2>/dev/null | sed 's/.*:[[:space:]]*//' | head -1)
    [ -n "$INSTALLED_VERSION" ] || INSTALLED_VERSION="unknown"

    UPDATE_MODE=true
    echo "Existing SprintBias installation detected (version $INSTALLED_VERSION, older layout)"
    echo "This will update to version $CURRENT_VERSION"
    echo ""
elif [ -d "docs/tasks" ] || [ -d "work/tasks" ] || [ -d "docs/work/tasks" ]; then
    INSTALLED_VERSION="unknown"
    UPDATE_MODE=true
    echo "Existing project docs structure detected"
    echo "This will install/update SprintBias to version $CURRENT_VERSION"
    echo ""
elif [ -f "DOCUMENTATION.md" ]; then
    INSTALLED_VERSION="unknown"
    UPDATE_MODE=true
fi

if $UPDATE_MODE; then
    # Remember for the final summary only — never used as a migration gate.
    ORIGINAL_VERSION="$INSTALLED_VERSION"
    echo "Do you want to continue with the update? [Y/n]"
    read -r CONFIRM
    # Enter (or Y/yes) continues; only an explicit N cancels.
    if [[ -n "$CONFIRM" && ! "$CONFIRM" =~ ^[Yy]([Ee][Ss])?$ ]]; then
        echo "Update cancelled."
        exit 0
    fi
fi

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Ensure task pipeline folders exist
ensure_task_folders() {
    safe_mkdir "docs/tasks/backlog"
    safe_mkdir "docs/tasks/next"
    safe_mkdir "docs/tasks/doing"
    safe_mkdir "docs/tasks/blocked"
    safe_mkdir "docs/tasks/review"
    safe_mkdir "docs/tasks/done"
}

# merge_config "$src_config" "$user_config"
# Appends missing KEY=VALUE lines from source to user config.
# Returns 0 if changes were made, 1 if already up to date.
merge_config() {
    local src="$1"
    local dest="$2"
    local changed=false

    while IFS='=' read -r key value; do
        # Skip comments, blank lines
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        # Append key if missing
        if ! grep -q "^${key}=" "$dest" 2>/dev/null; then
            echo "${key}=${value}" >> "$dest"
            changed=true
        fi
    done < "$src"

    $changed && return 0 || return 1
}

# ============================================================================
# PLATFORM CONFIGURATION
# ============================================================================

# Determine current platform (used as default during updates)
CURRENT_PLATFORM=""
if $UPDATE_MODE && [ -f "docs/.platform-config" ]; then
    CURRENT_PLATFORM=$(grep '^PLATFORM=' docs/.platform-config | cut -d'"' -f2)
fi

# --- Two doors: the whole first impression --------------------------------
# [Enter] Claude Code, [g] Grok Build. Both doors run the identical silent
# scaffold batch below — the only difference is the agent CLI/provider written
# into docs/sprintbias/config. No other rows, no other questions here.
echo "Which coding agent will drive SprintBias?"
echo "  [Enter]  Claude Code"
echo "  [g]      Grok Build"
echo ""
printf "Choose [Enter=Claude / g=Grok]: "
read -r DOOR_CHOICE
case "$DOOR_CHOICE" in
    g|G|grok|Grok|GROK) SELECTED_CLI="grok";   SELECTED_PROVIDER="grok-build"  ;;
    *)                  SELECTED_CLI="claude"; SELECTED_PROVIDER="claude-code" ;;
esac
msg_success "Agent: $SELECTED_CLI (provider tier: $SELECTED_PROVIDER)"
echo ""

# GitHub Issues sync is opt-in behind "More options?" at the end. Default to no
# sync; on update, keep whatever the project already had until the user changes
# it there.
if $UPDATE_MODE && [ -n "$CURRENT_PLATFORM" ]; then
    PLATFORM="$CURRENT_PLATFORM"
else
    PLATFORM="none"
fi

# ============================================================================
# CREATE DIRECTORY STRUCTURE
# ============================================================================

msg_header "Creating directory structure..."

# Task pipeline
ensure_task_folders

# Plans — a relational grouping over tasks (docs/plans/N-name.md lists task
# IDs). A sibling of docs/tasks/, NOT a lifecycle stage. Created empty here; the
# .TEMPLATE-plan.md lands via the src/ walk below.
safe_mkdir "docs/plans"

# Other directories
safe_mkdir "docs/ideas"
safe_mkdir "docs/bugs"
safe_mkdir "docs/designs"
safe_mkdir "docs/examples"
safe_mkdir "docs/data"
safe_mkdir "docs/sprintbias/scripts"
safe_mkdir "docs/sprintbias/ai"
safe_mkdir "docs/features"
safe_mkdir "docs/guides"
safe_mkdir "docs/tests"
safe_mkdir "docs/tmp"

# Platform-specific directories
if [ "$PLATFORM" != "none" ]; then
    safe_mkdir ".github/workflows"
    safe_mkdir ".github/ISSUE_TEMPLATE"
fi

# Add .gitkeep files to preserve empty directories
find docs -type d -empty -exec touch {}/.gitkeep \; 2>/dev/null || true
msg_step "Added .gitkeep files to empty directories"

# ============================================================================
# STATE.MD MANAGEMENT
# ============================================================================

msg_header "Managing state tracking..."

safe_mkdir "docs/sprintbias"

if [ ! -f "docs/sprintbias/DOC_STATE.md" ]; then
    # Create new DOC_STATE.md
    if cat > docs/sprintbias/DOC_STATE.md << STATE_EOF
# SprintBias Documentation State

Part of the SprintBias documentation system, not source code for the host project.
Managed by scripts in \`docs/sprintbias/scripts/\` and by \`setup.sh\`. Safe to edit by hand
if you need to fix a counter — the field lines below are what scripts parse.

Fields:
- \`sprint_VERSION\`   — installed product version (from \`src/VERSION\` via setup/ship)
- \`sprint_TASK_ID\`   — highest task ID used; next task = this + 1
- \`sprint_BUG_ID\`    — highest bug ID used; next bug = this + 1
- \`sprint_PLAN_ID\`   — highest plan ID used; next plan = this + 1
- \`Last Updated\`   — ISO date; bump when you change a field

---

**Last Updated**: $(date +%Y-%m-%d)
**sprint_VERSION**: $CURRENT_VERSION
**sprint_TASK_ID**: 0
**sprint_BUG_ID**: 0
**sprint_PLAN_ID**: 0
STATE_EOF
    then
        msg_step "Created docs/sprintbias/DOC_STATE.md"
    else
        msg_error "Failed to create docs/sprintbias/DOC_STATE.md"
    fi
else
    # Reconcile DOC_STATE.md - preserve user data, update product version
    EXISTING_TASK_ID=$(grep '^\*\*sprint_TASK_ID\*\*:' docs/sprintbias/DOC_STATE.md 2>/dev/null | sed 's/.*:[[:space:]]*//' | grep -o '^[0-9]*' | head -1)
    EXISTING_BUG_ID=$(grep '^\*\*sprint_BUG_ID\*\*:' docs/sprintbias/DOC_STATE.md 2>/dev/null | sed 's/.*:[[:space:]]*//' | grep -o '^[0-9]*' | head -1)
    EXISTING_PLAN_ID=$(grep '^\*\*sprint_PLAN_ID\*\*:' docs/sprintbias/DOC_STATE.md 2>/dev/null | sed 's/.*:[[:space:]]*//' | grep -o '^[0-9]*' | head -1)
    # One-shot read of pre-rebrand counter if PLAN_ID never written.
    if [ -z "$EXISTING_PLAN_ID" ]; then
        EXISTING_PLAN_ID=$(grep '^\*\*sprint_EPIC_ID\*\*:' docs/sprintbias/DOC_STATE.md 2>/dev/null | sed 's/.*:[[:space:]]*//' | grep -o '^[0-9]*' | head -1)
    fi

    # Validate and set defaults
    [[ "$EXISTING_TASK_ID" =~ ^[0-9]+$ ]] || EXISTING_TASK_ID=0
    [[ "$EXISTING_BUG_ID" =~ ^[0-9]+$ ]] || EXISTING_BUG_ID=0
    [[ "$EXISTING_PLAN_ID" =~ ^[0-9]+$ ]] || EXISTING_PLAN_ID=0

    if cat > docs/sprintbias/DOC_STATE.md << STATE_EOF
# SprintBias Documentation State

Part of the SprintBias documentation system, not source code for the host project.
Managed by scripts in \`docs/sprintbias/scripts/\` and by \`setup.sh\`. Safe to edit by hand
if you need to fix a counter — the field lines below are what scripts parse.

Fields:
- \`sprint_VERSION\`   — installed product version (from \`src/VERSION\` via setup/ship)
- \`sprint_TASK_ID\`   — highest task ID used; next task = this + 1
- \`sprint_BUG_ID\`    — highest bug ID used; next bug = this + 1
- \`sprint_PLAN_ID\`   — highest plan ID used; next plan = this + 1
- \`Last Updated\`   — ISO date; bump when you change a field

---

**Last Updated**: $(date +%Y-%m-%d)
**sprint_VERSION**: $CURRENT_VERSION
**sprint_TASK_ID**: $EXISTING_TASK_ID
**sprint_BUG_ID**: $EXISTING_BUG_ID
**sprint_PLAN_ID**: $EXISTING_PLAN_ID
STATE_EOF
    then
        msg_step "Updated docs/sprintbias/DOC_STATE.md (preserved IDs: task=$EXISTING_TASK_ID, bug=$EXISTING_BUG_ID, plan=$EXISTING_PLAN_ID)"
    else
        msg_error "Failed to update docs/sprintbias/DOC_STATE.md"
    fi
fi

# Store platform configuration
cat > docs/.platform-config << CONFIG_EOF
# SprintBias Platform Configuration
# Generated: $(date +%Y-%m-%d)
PLATFORM="$PLATFORM"
CONFIG_EOF

# ============================================================================
# DETECTION + DECISION HELPERS
# ============================================================================

# Track counters
FILES_COPIED=0

# README.md — we don't ship one (the user owns theirs), so it takes the same
# version-marked pointer-block treatment as CLAUDE.md / AGENTS.md. The block is
# built by readme_block() in the scaffold section below, after $MANUAL_FILE is
# resolved, so the pointer names our manual even when the user owns
# DOCUMENTATION.md.

# ----------------------------------------------------------------------------
# Detection markers + pure decision helpers
# ----------------------------------------------------------------------------
#
# setup.sh writes into other people's projects, so "did WE already install
# this?" must never be answered by an incidental substring (a stray path, a
# comment, an unrelated tool that happens to mention "SprintBias" or
# "DOCUMENTATION.md"). A wrong "yes" silently skips real work; a wrong "no"
# risks duplicating content. Each update path therefore matches a distinctive
# fragment of the exact text we write — an unambiguous "this is ours" marker —
# not a bare filename.
#
# These markers are substrings of the pointers/headers written elsewhere in
# this file. If you change a pointer's wording, keep its marker a substring of
# the new text.
#
# The block between the SENTINEL lines below is pure (no file I/O, no state) and
# is extracted verbatim by docs/tests/test-setup-detection.sh so the helpers can
# be unit-tested without running the installer. Keep it self-contained.
# >>> SprintBias detection helpers (unit-tested) >>>
SPRINT_README_MARKER='managed by [SprintBias]'                               # in readme_block
SPRINT_README_MARKER_LEGACY='managed by [sprint.md]'                         # pre-rebrand pointer
SPRINT_AI_MARKER='single source of truth for how this project is organized' # in every AI pointer + AI_FALLBACK
SPRINT_GITIGNORE_MARKER='# === SprintBias Recommended Entries ==='            # header written into .gitignore
SPRINT_GITIGNORE_MARKER_LEGACY='# === sprint.md Recommended Entries ==='     # pre-rebrand header

# already_ours MARKER CONTENT
# True (0) when CONTENT contains the fixed-string MARKER — i.e. text we wrote
# on a prior install. Pure: decides on the string passed in, does no file I/O,
# and uses a glob (not a regex) so marker characters are matched literally.
already_ours() {
    local marker="$1" content="$2"
    case "$content" in
        *"$marker"*) return 0 ;;
        *)           return 1 ;;
    esac
}

# already_ours_readme CONTENT — true when CONTENT has our current or legacy
# README pointer marker (pre-SprintBias installs used "managed by [sprint.md]").
already_ours_readme() {
    already_ours "$SPRINT_README_MARKER" "$1" \
        || already_ours "$SPRINT_README_MARKER_LEGACY" "$1"
}

# gitignore_merge RECOMMENDED EXISTING
# Emit (stdout) the subset of the RECOMMENDED block whose entry lines are not
# already present in EXISTING, grouped into their original blank-line-delimited
# sections. A section whose entries are all duplicates is dropped along with
# its comment/header lines, so no orphaned headers appear. Empty output means
# "nothing new to add" — the idempotent case. Pure: a function of its two
# string arguments only, no file I/O, so it is unit-testable in isolation and
# separable from the interactive prompt flow that consumes its result.
gitignore_merge() {
    local recommended="$1" existing="$2"
    local filtered="" section_lines="" section_has_new=false line

    _flush_section() {
        if [ "$section_has_new" = true ] && [ -n "$section_lines" ]; then
            if [ -n "$filtered" ]; then
                filtered="${filtered}"$'\n'
            fi
            filtered="${filtered}${section_lines}"
        fi
        section_lines=""
        section_has_new=false
    }

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*$ ]]; then
            # Blank line = section boundary
            _flush_section
        elif [[ "$line" =~ ^# ]]; then
            # Comment/header — keep in section, decide when we flush
            section_lines="${section_lines}${line}"$'\n'
        elif ! grep -qxF -- "$line" <<< "$existing" 2>/dev/null; then
            # New entry — this section will be emitted
            section_lines="${section_lines}${line}"$'\n'
            section_has_new=true
        fi
        # Duplicate entries are silently dropped
    done <<< "$recommended"
    _flush_section

    printf '%s' "$filtered"
}

# sprint_marker_version CONTENT
# Print the product version stamped in CONTENT (X.Y.Z), or empty if none.
# Recognizes current and legacy ownership markers:
#   Markdown   <!-- SprintBias vX.Y.Z -->   (current)
#              <!-- sprint.md vX.Y.Z -->    (legacy)
#   .gitignore # SprintBias vX.Y.Z         (current)
#              # sprint.md vX.Y.Z          (legacy)
# The presence of a version here is the ONLY signal that a file is ours — a bare
# product-name mention never matches. Pure: reads only its string argument.
sprint_marker_version() {
    printf '%s\n' "$1" \
        | grep -oE '(SprintBias|sprint\.md) v[0-9]+\.[0-9]+\.[0-9]+' \
        | head -n1 \
        | sed 's/^.*v//'
}

# ver_lt A B — true (0) when semver A is strictly older than B, else false.
# Numeric field compare (not string), so v0.0.9 < v0.0.10 sorts correctly.
# Pure: no file I/O.
ver_lt() {
    [ "$1" = "$2" ] && return 1
    [ "$(printf '%s\n%s\n' "$1" "$2" | sort -t. -k1,1n -k2,2n -k3,3n | head -n1)" = "$1" ]
}
# <<< SprintBias detection helpers <<<

# Strict yes/no prompt — loops until the user gives an unambiguous answer.
# Sets the variable named in $1 to "yes" or "no". $2 is the prompt text.
# On EOF (closed stdin, e.g. piped/CI install) defaults to "no" so we never
# mutate user files without an explicit yes, and never hang.
# prompt_yes_no VARNAME "Prompt text" [default]
# default is "yes" or "no" (defaults to "no"). Empty answer / EOF accepts it.
# Shows [Y/n] or [y/N] so Enter advances without typing.
prompt_yes_no() {
    local __varname="$1"
    local __prompt="$2"
    local __default="${3:-no}"
    local __answer
    local __hint
    case "$__default" in
        yes|y|Y) __default="yes"; __hint="[Y/n]" ;;
        *)       __default="no";  __hint="[y/N]" ;;
    esac
    while true; do
        echo "$__prompt $__hint"
        if ! read -r __answer; then
            echo "  (no input — defaulting to $__default)"
            printf -v "$__varname" "%s" "$__default"
            return 0
        fi
        case "$__answer" in
            "")
                printf -v "$__varname" "%s" "$__default"
                return 0
                ;;
            [Yy]|[Yy][Ee][Ss])  printf -v "$__varname" "yes"; return 0 ;;
            [Nn]|[Nn][Oo])      printf -v "$__varname" "no";  return 0 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

# ============================================================================
# COPY DISTRIBUTION FILES — single recursive walk of src/
# ============================================================================
#
# src/ mirrors the deployed layout: every file's relative path under src/
# matches its destination in the target project. The walk below copies each
# file, with behavior determined by list membership, not per-file routing.
#
# Behavior lists (relative paths under src/):
#   SKIP_FILES       — metadata, never copied (VERSION, .gitignore.template)
#   PREPEND_FILES    — AI instruction files: prepend-or-create, never overwrite
#   USER_TERRITORY   — copy only on fresh install; skip if file already exists
#   .github/**       — only copied when platform is github-based
#   Everything else  — standard overwrite via safe_copy

msg_header "Installing distribution files..."

# Handled by the silent scaffold batch (marker-guarded), not the plain walk:
# GETSTARTED.md, DOCUMENTATION.md, CLAUDE.md and AGENTS.md. Skipping them here
# keeps the walk from overwriting a user-owned copy.
SKIP_FILES=(
    "VERSION"
    ".gitignore.template"
    "GETSTARTED.md"
    "DOCUMENTATION.md"
    "CLAUDE.md"
    "AGENTS.md"
)

# The residual AI dotfiles: silently prepended into pre-existing files, and
# push-created only under "More options? → Add all AI instructions".
PREPEND_FILES=(
    ".cursorrules"
    ".windsurfrules"
    ".github/copilot-instructions.md"
)

USER_TERRITORY=(
    "docs/sprintbias/config"
)

# Helper: check if a value is in an array
_in_list() {
    local needle="$1"; shift
    for item in "$@"; do
        [[ "$item" = "$needle" ]] && return 0
    done
    return 1
}

# Fallback content if source AI templates not found
AI_FALLBACK='Read `DOCUMENTATION.md` before making any changes. It is the single source of truth for how this project is organized, how tasks are managed, and how to use the SprintBias system.'

# setup_ai_file "source_template" "target_path" "display_name" [create]
# - If target doesn't exist and create=yes, create it (no prompt)
# - If target doesn't exist and create is unset, skip
# - If target exists without DOCUMENTATION.md reference, prepend automatically
# - If target already references DOCUMENTATION.md, skip
setup_ai_file() {
    local target="$2"
    local name="$3"
    local create="${4:-}"
    local block cls
    block="$(pointer_block)"
    cls="$(classify_target "$target")"

    case "$cls" in
        absent)
            [ "$create" = "yes" ] || return 0
            local target_dir
            target_dir="$(dirname "$target")"
            [ "$target_dir" != "." ] && safe_mkdir "$target_dir"
            if printf '%s\n' "$block" > "$target" 2>/dev/null; then
                msg_success "Created $name"
                ((FILES_COPIED++))
            else
                msg_error "Failed to create $name"
            fi ;;
        ours-current:*)
            msg_step "$name up to date (v${cls#ours-current:})" ;;
        ours-old:*)
            if _replace_md_block "$target" "$block"; then
                msg_success "$name upgraded (${cls#ours-old:} → $CURRENT_VERSION)"
            else
                msg_error "Failed to upgrade $name"
            fi ;;
        theirs)
            if _prepend_md_block "$target" "$block"; then
                msg_success "Prepended SprintBias pointer to $name"
            else
                msg_error "Failed to prepend to $name"
            fi ;;
    esac
}

# Human-friendly label for each AI instruction file path
_ai_label() {
    case "$1" in
        CLAUDE.md)                       echo "Claude Code / Claude" ;;
        .cursorrules)                    echo "Cursor" ;;
        .github/copilot-instructions.md) echo "GitHub Copilot" ;;
        AGENTS.md)                       echo "Agents.md (multi-agent)" ;;
        .windsurfrules)                  echo "Windsurf" ;;
        *)                               echo "$1" ;;
    esac
}

# ----------------------------------------------------------------------------
# Version-marked scaffold: classify, stamp, prepend, upgrade
# ----------------------------------------------------------------------------
# Every scaffold file we ship or prepend carries a version-stamped marker
# (<!-- SprintBias vX.Y.Z --> for Markdown, "# SprintBias vX.Y.Z" for .gitignore).
# That marker is the ONLY thing that authorizes an overwrite — a file with no
# marker is the user's, and we never clobber it. classify_target decides which
# of four states a path is in; the scaffold_* helpers act on that state and emit
# one outcome line each so a silent batch still reports what it did.
#
# The block between the SENTINEL lines below is extracted verbatim by
# docs/tests/test-setup-detection.sh and sourced alongside the detection helpers,
# so the conflict and manual-name decisions are tested as shipped code. These
# helpers touch files (unlike the detection block) — the test drives them in a
# temp directory with CURRENT_VERSION / MANUAL_FILE set and msg_* stubbed. Keep
# every function the installer's conflict UX depends on inside the fence.
# >>> SprintBias scaffold helpers (unit-tested) >>>

# classify_target TARGET -> echoes: absent | ours-current:VER | ours-old:VER | theirs
classify_target() {
    local target="$1" v
    if [ ! -f "$target" ]; then echo "absent"; return; fi
    v="$(sprint_marker_version "$(cat "$target" 2>/dev/null)")"
    if [ -z "$v" ]; then echo "theirs"; return; fi
    if ver_lt "$v" "$CURRENT_VERSION"; then echo "ours-old:$v"; else echo "ours-current:$v"; fi
}

# The Markdown pointer block we write into CLAUDE.md / AGENTS.md / dotfiles.
# Points at $MANUAL_FILE, which is DOCUMENTATION.md unless the user already owns
# one, in which case our manual installs as SPRINTDOCUMENTATION.md.
pointer_block() {
    printf '<!-- SprintBias v%s -->\nRead `%s` before making any changes. It is the single source of truth for how this project is organized, how tasks are managed, and how to use the SprintBias system.\n<!-- end SprintBias -->' \
        "$CURRENT_VERSION" "$MANUAL_FILE"
}

# The Markdown pointer block we write into the user's README.md. Same versioned
# marker as pointer_block, different wording — a README speaks to readers, not
# to agents. Keeps the "managed by [SprintBias]" text so a pre-marker install is
# still recognized by already_ours_readme.
readme_block() {
    printf '<!-- SprintBias v%s -->\n> **Project documentation** → see [`%s`](%s) (managed by [SprintBias](https://sprintbias.com))\n<!-- end SprintBias -->' \
        "$CURRENT_VERSION" "$MANUAL_FILE" "$MANUAL_FILE"
}

# _copy_stamped SRC TARGET — copy SRC to TARGET, normalizing its marker line to
# the current version (atomic via temp file). Rewrites both current SprintBias
# and legacy sprint.md version stamps to the new form.
_copy_stamped() {
    local src="$1" target="$2" tmp
    [ -f "$src" ] || { msg_error "Source missing: $src"; return 1; }
    tmp="$(mktemp "${target}.XXXXXX")" || return 1
    if sed -E "s#(SprintBias|sprint\\.md) v[0-9][0-9A-Za-z.]*#SprintBias v${CURRENT_VERSION}#g" "$src" > "$tmp" 2>/dev/null \
       && mv -f "$tmp" "$target"; then
        return 0
    fi
    rm -f "$tmp"; return 1
}

# _prepend_md_block TARGET BLOCK — put BLOCK above TARGET's existing body.
_prepend_md_block() {
    local target="$1" block="$2" tmp
    tmp="$(mktemp "${target}.XXXXXX")" || return 1
    if { printf '%s\n\n' "$block"; cat "$target"; } > "$tmp" 2>/dev/null \
       && mv -f "$tmp" "$target"; then
        return 0
    fi
    rm -f "$tmp"; return 1
}

# _replace_md_block TARGET BLOCK — swap our existing (older) block for BLOCK,
# leaving the user's body untouched. Matches current SprintBias and legacy
# sprint.md ownership blocks.
_replace_md_block() {
    local target="$1" block="$2" tmp
    tmp="$(mktemp "${target}.XXXXXX")" || return 1
    if { printf '%s\n' "$block"; awk '
        BEGIN{drop=0}
        /<!-- (SprintBias|sprint\.md) v/ {drop=1; next}
        drop==1 && /<!-- end (SprintBias|sprint\.md) -->/ {drop=0; next}
        drop==0 {print}
    ' "$target"; } > "$tmp" 2>/dev/null && mv -f "$tmp" "$target"; then
        return 0
    fi
    rm -f "$tmp"; return 1
}

# _replace_readme_pointer TARGET BLOCK — upgrade a legacy README pointer (a bare
# single line, written before we stamped markers) to the marked BLOCK. Drops the
# old pointer line and the blank lines it left behind at the top, keeping the
# user's body. _replace_md_block can't do this: there is no marker to match.
_replace_readme_pointer() {
    local target="$1" block="$2" tmp body
    body="$(awk '
        seen==0 && /managed by \[(SprintBias|sprint\.md)\]/ {next}
        seen==0 && /^[[:space:]]*$/ {next}
        {seen=1; print}
    ' "$target" 2>/dev/null)"
    tmp="$(mktemp "${target}.XXXXXX")" || return 1
    if { printf '%s\n' "$block"; if [ -n "$body" ]; then printf '\n%s\n' "$body"; fi; } > "$tmp" 2>/dev/null \
       && mv -f "$tmp" "$target"; then
        return 0
    fi
    rm -f "$tmp"; return 1
}

# install_owned_doc SRC TARGET NAME — a whole document that is entirely ours
# (GETSTARTED.md, the manual). Create when absent, upgrade when our marker is
# older, skip a user's own file (never clobber).
install_owned_doc() {
    local src="$1" target="$2" name="$3" cls
    cls="$(classify_target "$target")"
    case "$cls" in
        absent)
            if _copy_stamped "$src" "$target"; then msg_success "$name ensured"; ((FILES_COPIED++)); else msg_error "Failed to write $name"; fi ;;
        ours-current:*) msg_step "$name up to date (v${cls#ours-current:})" ;;
        ours-old:*)
            if _copy_stamped "$src" "$target"; then msg_success "$name upgraded (${cls#ours-old:} → $CURRENT_VERSION)"; else msg_error "Failed to upgrade $name"; fi ;;
        theirs) msg_step "Skipped $name (yours left in place)" ;;
    esac
}

# scaffold_pointer TARGET NAME — an AI pointer file (CLAUDE.md / AGENTS.md).
# Handles create/upgrade/no-op silently; defers a user-owned file to CONFLICTS
# so the batch never prepends-then-unwinds ahead of a possible Overwrite under
# More options. Default path silent-prepends after the batch.
scaffold_pointer() {
    local target="$1" name="$2" block cls
    block="$(pointer_block)"
    cls="$(classify_target "$target")"
    case "$cls" in
        absent)
            if printf '%s\n' "$block" > "$target" 2>/dev/null; then msg_success "$name ensured"; ((FILES_COPIED++)); else msg_error "Failed to write $name"; fi ;;
        ours-current:*) msg_step "$name up to date (v${cls#ours-current:})" ;;
        ours-old:*)
            if _replace_md_block "$target" "$block"; then msg_success "$name upgraded (${cls#ours-old:} → $CURRENT_VERSION)"; else msg_error "Failed to upgrade $name"; fi ;;
        theirs)
            CONFLICTS+=("pointer|$target|$name")
            msg_step "$name exists (yours) — will prepend after batch (or choose under More options)"
            ;;
    esac
}

# scaffold_readme — the user's README.md. Same four states as scaffold_pointer,
# plus one ahead of them: a README carrying our pre-marker text pointer is ours
# even though classify_target sees no marker and calls it "theirs". That one is
# upgraded in place, so an old install gains the marker instead of a second
# pointer. Everything else follows the batch rules — create when absent, upgrade
# our older block, no-op at the current version, defer a user-owned README to
# CONFLICTS for the silent prepend (or Prepend/Overwrite under More options).
scaffold_readme() {
    local target="README.md" name="README.md" block cls
    block="$(readme_block)"
    cls="$(classify_target "$target")"
    if [ "$cls" = "theirs" ] && already_ours_readme "$(cat "$target" 2>/dev/null)"; then
        if _replace_readme_pointer "$target" "$block"; then
            msg_success "$name pointer upgraded (unversioned → $CURRENT_VERSION)"
        else
            msg_error "Failed to upgrade $name"
        fi
        return
    fi
    case "$cls" in
        absent)
            if printf '%s\n' "$block" > "$target" 2>/dev/null; then msg_success "$name ensured"; ((FILES_COPIED++)); else msg_error "Failed to write $name"; fi ;;
        ours-current:*) msg_step "$name up to date (v${cls#ours-current:})" ;;
        ours-old:*)
            if _replace_md_block "$target" "$block"; then msg_success "$name upgraded (${cls#ours-old:} → $CURRENT_VERSION)"; else msg_error "Failed to upgrade $name"; fi ;;
        theirs)
            CONFLICTS+=("readme|$target|$name")
            msg_step "$name exists (yours) — will prepend after batch (or choose under More options)"
            ;;
    esac
}

# --- .gitignore variants (hash-comment marker + per-line entry merge) --------
_gitignore_block_open()  { printf '# SprintBias v%s\n' "$CURRENT_VERSION"; }
_gitignore_block_close() { printf '# end SprintBias\n'; }

_write_gitignore_fresh() {
    { _gitignore_block_open; printf '%s\n' "$GITIGNORE_CONTENT"; _gitignore_block_close; } > .gitignore 2>/dev/null
}

_prepend_gitignore() {
    local existing filtered tmp
    existing="$(cat .gitignore 2>/dev/null)"
    filtered="$(gitignore_merge "$GITIGNORE_CONTENT" "$existing")"
    if [ -z "$filtered" ]; then msg_step ".gitignore already has all recommended entries"; return 0; fi
    tmp="$(mktemp ".gitignore.XXXXXX")" || return 1
    if { _gitignore_block_open; printf '%s\n' "$filtered"; _gitignore_block_close; printf '\n%s\n' "$existing"; } > "$tmp" 2>/dev/null \
       && mv -f "$tmp" .gitignore; then return 0; fi
    rm -f "$tmp"; return 1
}

_upgrade_gitignore() {
    local body filtered tmp
    # Drop current SprintBias or legacy sprint.md ownership blocks, keep body.
    body="$(awk 'BEGIN{d=0} /^# (SprintBias|sprint\.md) v/{d=1;next} d==1 && /^# end (SprintBias|sprint\.md)/{d=0;next} d==0{print}' .gitignore)"
    filtered="$(gitignore_merge "$GITIGNORE_CONTENT" "$body")"
    tmp="$(mktemp ".gitignore.XXXXXX")" || return 1
    if { _gitignore_block_open; printf '%s\n' "$filtered"; _gitignore_block_close; printf '\n%s\n' "$body"; } > "$tmp" 2>/dev/null \
       && mv -f "$tmp" .gitignore; then return 0; fi
    rm -f "$tmp"; return 1
}

scaffold_gitignore() {
    local cls
    cls="$(classify_target ".gitignore")"
    case "$cls" in
        absent)
            if _write_gitignore_fresh; then msg_success ".gitignore ensured"; else msg_error "Failed to write .gitignore"; fi ;;
        ours-current:*) msg_step ".gitignore up to date (v${cls#ours-current:})" ;;
        ours-old:*)
            if _upgrade_gitignore; then msg_success ".gitignore upgraded (${cls#ours-old:} → $CURRENT_VERSION)"; else msg_error "Failed to upgrade .gitignore"; fi ;;
        theirs)
            CONFLICTS+=("gitignore|.gitignore|.gitignore")
            msg_step ".gitignore exists (yours) — will prepend after batch (or choose under More options)"
            ;;
    esac
}

# apply_conflict KIND TARGET NAME ACTION — write one deferred conflict.
# ACTION is prepend | replace (overwrite). No "leave": skip More options to
# leave user files untouched beyond the silent default prepend.
apply_conflict() {
    local kind="$1" target="$2" name="$3" action="$4" block
    # Each pointer kind writes its own block — the README speaks to readers, the
    # AI files to agents. Same marker, different wording.
    case "$kind" in
        readme) block="$(readme_block)" ;;
        *)      block="$(pointer_block)" ;;
    esac
    case "$action" in
        replace)
            if [ "$kind" = "gitignore" ]; then
                _write_gitignore_fresh && msg_success "Overwrote $name with SprintBias entries" || msg_error "Failed to overwrite $name"
            else
                printf '%s\n' "$block" > "$target" 2>/dev/null \
                    && msg_success "Overwrote $name with SprintBias pointer" \
                    || msg_error "Failed to overwrite $name"
            fi ;;
        prepend|*)
            if [ "$kind" = "gitignore" ]; then
                _prepend_gitignore && msg_success "Prepended SprintBias entries to $name" || msg_error "Failed to prepend to $name"
            else
                _prepend_md_block "$target" "$block" && msg_success "Prepended SprintBias pointer to $name" || msg_error "Failed to prepend to $name"
            fi ;;
    esac
}

# resolve_conflict_interactive KIND TARGET NAME — binary override under
# "More options?" only. Enter = Prepend (parity with silent default);
# o = Overwrite (only deliberate keystroke that replaces a user-owned file).
resolve_conflict_interactive() {
    local kind="$1" target="$2" name="$3" ans
    echo ""
    echo "$name already exists and isn't ours:"
    echo "  [Enter]  Prepend   — keep your content, add our block above it"
    if [ "$kind" = "gitignore" ]; then
        echo "  o)       Overwrite — replace $name with SprintBias entries only"
    else
        echo "  o)       Overwrite — replace $name with our pointer only"
    fi
    printf "Choose [Enter=Prepend / o]: "
    read -r ans
    case "$ans" in
        o|O) apply_conflict "$kind" "$target" "$name" replace ;;
        *)   apply_conflict "$kind" "$target" "$name" prepend ;;
    esac
}

# resolve_manual_file — echo the filename our manual installs as. It is
# DOCUMENTATION.md unless the user already owns one we didn't write, in which
# case ours lands as SPRINTDOCUMENTATION.md and every pointer written this run
# targets that name. Decided once, up front, so all pointers agree.
resolve_manual_file() {
    if [ "$(classify_target "DOCUMENTATION.md")" = "theirs" ]; then
        echo "SPRINTDOCUMENTATION.md"
    else
        echo "DOCUMENTATION.md"
    fi
}

# apply_deferred_conflicts — the silent default path. Every user-owned file the
# scaffold_* helpers deferred sits in CONFLICTS as "kind|target|name"; this
# applies the safe default (prepend) to each. It is the branch almost every
# install takes (the one that skips More options), so it is a helper the test
# can drive directly rather than a loop buried in the main flow.
apply_deferred_conflicts() {
    local entry _ck _rest _ct _cn
    for entry in "${CONFLICTS[@]}"; do
        _ck="${entry%%|*}"; _rest="${entry#*|}"; _ct="${_rest%%|*}"; _cn="${_rest#*|}"
        apply_conflict "$_ck" "$_ct" "$_cn" prepend
    done
}
# <<< SprintBias scaffold helpers <<<

# install_github_sync — copy the GitHub Issues sync workflows and issue/PR
# templates from src/.github (the copilot dotfile is handled with the other AI
# instructions, not here). Reachable only under "More options?".
install_github_sync() {
    PLATFORM="github-issues"
    safe_mkdir ".github/workflows"
    safe_mkdir ".github/ISSUE_TEMPLATE"
    local gf rel
    while IFS= read -r gf; do
        rel="${gf#"$SRC_DIR"/}"
        [ "$rel" = ".github/copilot-instructions.md" ] && continue
        safe_mkdir "$(dirname "$rel")"
        if safe_copy "$gf" "$rel" "$rel"; then ((FILES_COPIED++)); fi
    done < <(find "$SRC_DIR/.github" -type f)
    cat > docs/.platform-config <<CFG
# SprintBias Platform Configuration
# Generated: $(date +%Y-%m-%d)
PLATFORM="$PLATFORM"
CFG
    msg_success "GitHub Issues sync installed"
}

# --- Platform=none cleanup: remove sync workflows from prior installs ---
if [ "$PLATFORM" = "none" ]; then
    for wf in ".github/workflows/sync-tasks-to-issues.yml" ".github/workflows/sync-status-to-label.yml"; do
        if [ -f "$wf" ]; then
            if rm -f "$wf" 2>/dev/null; then
                msg_step "Removed $wf (opted out of sync)"
            else
                msg_warning "Could not remove $wf"
            fi
        fi
    done
fi

# --- Walk src/ and install each file by its relative path ---
# Uses a FIFO on fd 3 for find output so stdin stays available for interactive
# prompts inside setup_ai_file. (A plain pipe would steal stdin.)
PENDING_PREPEND=()
SRC_DIR="$SPRINTBIAS_SOURCE_DIR/src"
_find_fifo="$(mktemp -d)/find_fifo"
mkfifo "$_find_fifo"
find "$SRC_DIR" -type f -print0 > "$_find_fifo" &
exec 3< "$_find_fifo"
while IFS= read -r -d '' src_file <&3; do
    rel_path="${src_file#"$SRC_DIR"/}"

    # Skip metadata files
    if _in_list "$rel_path" "${SKIP_FILES[@]}"; then continue; fi

    # Never install compiled Python artifacts. The learning demos are plain .py
    # run in place; bytecode is generated, and its bytes embed the source path
    # and brand it was compiled from (stale bytecode once carried a retired
    # pre-rebrand framework path into every install). ship.sh already excludes
    # these from src/ — this is the second line of defence at install time.
    case "$rel_path" in
        *__pycache__/*|*.pyc|*.pyo) continue ;;
    esac

    # Platform filter: .github/** only for github-based platforms
    if [[ "$rel_path" == .github/* ]]; then
        if [ "$PLATFORM" = "none" ]; then
            continue
        fi
    fi

    # Prepend files (AI instruction files) — defer to after the walk so
    # interactive prompts are grouped together, not scattered among copies.
    if _in_list "$rel_path" "${PREPEND_FILES[@]}"; then
        PENDING_PREPEND+=("$src_file|$rel_path")
        continue
    fi

    # User territory — preserve existing file on update, merge new config keys
    if _in_list "$rel_path" "${USER_TERRITORY[@]}"; then
        if [ -f "$rel_path" ]; then
            if [ "$rel_path" = "docs/sprintbias/config" ]; then
                if merge_config "$SPRINTBIAS_SOURCE_DIR/src/docs/sprintbias/config" "docs/sprintbias/config"; then
                    msg_success "Updated docs/sprintbias/config (added new configuration options)"
                else
                    msg_step "Preserved docs/sprintbias/config (up to date)"
                fi
            else
                msg_step "Preserved $rel_path (user-territory)"
            fi
            continue
        fi
    fi

    # Standard copy
    safe_mkdir "$(dirname "$rel_path")"
    if safe_copy "$src_file" "$rel_path" "$rel_path"; then
        if [[ "$rel_path" == *.sh || "$rel_path" == *.py ]]; then
            chmod +x "$rel_path" 2>/dev/null || msg_warning "Could not make $rel_path executable"
        fi
        ((FILES_COPIED++))
    fi
done
exec 3<&-
rm -f "$_find_fifo" && rmdir "$(dirname "$_find_fifo")" 2>/dev/null

# The manual is DOCUMENTATION.md unless the user already owns one — then ours
# installs as SPRINTDOCUMENTATION.md and every pointer (CLAUDE.md, AGENTS.md,
# and the dotfiles below) targets that name. Decided up front so every pointer
# written this run agrees on the manual's filename.
MANUAL_FILE="$(resolve_manual_file)"

# --- AI dotfiles (deferred from the walk above) ---------------------------
# Pre-existing dotfiles get a silent version-marked prepend; absent ones are
# collected into NEED_CREATE and push-created only under "More options?".
NEED_CREATE=()
for entry in "${PENDING_PREPEND[@]}"; do
    rel_path="${entry#*|}"
    if [ -f "$rel_path" ]; then
        setup_ai_file "" "$rel_path" "$rel_path"
    else
        NEED_CREATE+=("$entry")
    fi
done

# Recommended .gitignore entries (template or inline fallback). Loaded here so
# the scaffold batch below can merge them.
GITIGNORE_TEMPLATE="$SPRINTBIAS_SOURCE_DIR/src/.gitignore.template"
if [ -f "$GITIGNORE_TEMPLATE" ]; then
    GITIGNORE_CONTENT=$(cat "$GITIGNORE_TEMPLATE")
else
    GITIGNORE_CONTENT="# OS Files
.DS_Store
Thumbs.db
desktop.ini

# Editor Files
.vscode/
.idea/
*.swp
*.swo
*~

# Temporary Files
*.tmp
*.temp
*.bak
*.log

# Environment and secrets
.env
.env.*
*.pem
*.key
secrets/

# Local data
docs/data/*.csv
docs/data/*.json
docs/data/*.db

# Design files (large binaries)
docs/designs/*.psd
docs/designs/*.sketch
docs/designs/*.fig"
fi

# ============================================================================
# SILENT SCAFFOLD BATCH — identical for both doors, asks nothing
# ============================================================================
# One keystroke laid down the full SprintBias scaffold. Every file below is
# marker-guarded: absent → create, our marker + older version → upgrade, our
# marker + current version → no-op, no marker (user's) → prepend/skip/rename.
# Nothing here overwrites a user-owned file; that lives behind "More options?".
# A user-owned file that would take a prepend is deferred into CONFLICTS so the
# batch never prepends-then-unwinds ahead of a later Overwrite under More options.

msg_header "Scaffolding SprintBias files..."

CONFLICTS=()

# 1) GETSTARTED.md   2) CLAUDE.md   3) the manual   4) .gitignore   5) AGENTS.md
# 6) README.md
install_owned_doc "$SRC_DIR/GETSTARTED.md" "GETSTARTED.md" "GETSTARTED.md"
scaffold_pointer "CLAUDE.md" "CLAUDE.md"
if [ "$MANUAL_FILE" = "SPRINTDOCUMENTATION.md" ]; then
    msg_step "Your DOCUMENTATION.md left in place; installing manual as SPRINTDOCUMENTATION.md"
fi
install_owned_doc "$SRC_DIR/DOCUMENTATION.md" "$MANUAL_FILE" "$MANUAL_FILE"
scaffold_gitignore
scaffold_pointer "AGENTS.md" "AGENTS.md"
scaffold_readme

# ============================================================================
# LAYOUT CLEANUP (path-presence only — no version ladder)
# ============================================================================
# setup.sh never deletes what is no longer in the distribution. Renames and
# consolidations leave behind folders/files that block a clean tree. Every
# check below is gated only on "does this path exist?" — not on product version.
# User work (task bodies, plan files) is moved; framework-owned files are removed.

# ── STATE.md → docs/sprintbias/DOC_STATE.md ────────────────────────────
if [ -f "docs/STATE.md" ] && [ ! -f "docs/sprintbias/DOC_STATE.md" ]; then
    safe_mkdir "docs/sprintbias"
    if mv docs/STATE.md docs/sprintbias/DOC_STATE.md 2>/dev/null; then
        msg_step "Moved docs/STATE.md → docs/sprintbias/DOC_STATE.md"
    fi
fi

# ── config.sh → flat docs/sprintbias/config (current keys only) ────────
# Hard cut: no dual-read of retired MODEL_TALK / MODEL_TASKS / etc. The
# shipped template is the source of truth; merge_config fills missing keys.
if [ -f "docs/sprintbias/config.sh" ] && [ ! -f "docs/sprintbias/config" ]; then
    echo ""
    echo "Replacing docs/sprintbias/config.sh with flat config (current keys)..."
    if safe_copy "$SPRINTBIAS_SOURCE_DIR/src/docs/sprintbias/config" "docs/sprintbias/config" "docs/sprintbias/config"; then
        mv "docs/sprintbias/config.sh" "docs/sprintbias/config.sh.bak" 2>/dev/null || true
        msg_success "Installed flat config (old config.sh backed up as config.sh.bak)"
        msg_step "Re-set CLI/models in docs/sprintbias/config if you had custom pins"
    fi
fi
# Drop a stale config.sh when the flat file already exists.
if [ -f "docs/sprintbias/config.sh" ] && [ -f "docs/sprintbias/config" ]; then
    mv "docs/sprintbias/config.sh" "docs/sprintbias/config.sh.bak" 2>/dev/null \
        && msg_step "Backed up obsolete docs/sprintbias/config.sh → config.sh.bak" || true
fi

# ── docs/tasks/live/ → done/ ─────────────────────────────────────────
if [ -d "docs/tasks/live" ]; then
    STALE_LIVE_COUNT=$(find "docs/tasks/live" -name "*.md" -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')
    if [ "$STALE_LIVE_COUNT" -gt 0 ]; then
        msg_header "Stale docs/tasks/live/ folder detected"
        echo "The lifecycle folder is done/ (not live/). Your live/ folder still has"
        echo "$STALE_LIVE_COUNT task file(s)."
        echo ""
        echo "Move files from live/ to done/? [Y]es/No"
        read -r LIVE_CLEANUP_CHOICE
        if [[ -z "$LIVE_CLEANUP_CHOICE" ]] || [[ "$LIVE_CLEANUP_CHOICE" =~ ^[Yy] ]]; then
            safe_mkdir "docs/tasks/done"
            if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
                for f in docs/tasks/live/*.md; do
                    [ -f "$f" ] || continue
                    git mv "$f" "docs/tasks/done/" 2>/dev/null || mv "$f" "docs/tasks/done/"
                done
            else
                mv docs/tasks/live/*.md "docs/tasks/done/" 2>/dev/null || true
            fi
            rmdir "docs/tasks/live" 2>/dev/null || true
            msg_success "Moved task files from live/ to done/"
        fi
    else
        rmdir "docs/tasks/live" 2>/dev/null || true
    fi
fi

# ── docs/tasks/working/ → doing/ ─────────────────────────────────────
if [ -d "docs/tasks/working" ]; then
    STALE_WORKING_COUNT=$(find "docs/tasks/working" -name "*.md" -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')
    if [ "$STALE_WORKING_COUNT" -gt 0 ]; then
        msg_header "Stale docs/tasks/working/ folder detected"
        echo "The lifecycle folder is doing/ (not working/). Your working/ folder still has"
        echo "$STALE_WORKING_COUNT task file(s)."
        echo ""
        echo "Move files from working/ to doing/? [Y]es/No"
        read -r WORKING_CLEANUP_CHOICE
        if [[ -z "$WORKING_CLEANUP_CHOICE" ]] || [[ "$WORKING_CLEANUP_CHOICE" =~ ^[Yy] ]]; then
            safe_mkdir "docs/tasks/doing"
            if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
                for f in docs/tasks/working/*.md; do
                    [ -f "$f" ] || continue
                    git mv "$f" "docs/tasks/doing/" 2>/dev/null || mv "$f" "docs/tasks/doing/"
                done
            else
                mv docs/tasks/working/*.md "docs/tasks/doing/" 2>/dev/null || true
            fi
            rmdir "docs/tasks/working" 2>/dev/null || true
            msg_success "Moved task files from working/ to doing/"
        fi
    else
        rmdir "docs/tasks/working" 2>/dev/null || true
    fi
fi

# ── docs/epics/ → docs/plans/ ────────────────────────────────────────
if [ -d "docs/epics" ]; then
    msg_header "Moving docs/epics/ → docs/plans/"
    safe_mkdir "docs/plans"
    for f in docs/epics/* docs/epics/.[!.]* docs/epics/..?*; do
        [ -e "$f" ] || continue
        base="$(basename "$f")"
        case "$base" in
            .|..|.TEMPLATE-epic.md|.gitkeep) continue ;;
        esac
        if [ -e "docs/plans/$base" ]; then
            msg_warning "docs/plans/$base already exists — left docs/epics/$base in place"
            continue
        fi
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
           && git mv "$f" "docs/plans/$base" 2>/dev/null; then
            msg_step "git mv docs/epics/$base → docs/plans/$base"
        elif mv "$f" "docs/plans/$base" 2>/dev/null; then
            msg_step "mv docs/epics/$base → docs/plans/$base"
        else
            msg_warning "Could not move docs/epics/$base"
        fi
    done
    rm -f docs/epics/.TEMPLATE-epic.md docs/epics/.gitkeep 2>/dev/null || true
    if rmdir "docs/epics" 2>/dev/null; then
        msg_success "Removed empty docs/epics/"
    elif [ -d "docs/epics" ]; then
        msg_warning "docs/epics/ still has files — review and remove manually"
    fi
fi

# ── Retired framework files (safe to delete) ─────────────────────────
RETIRED_FRAMEWORK_FILES=(
    # talk → chat
    "docs/sprintbias/scripts/talk.sh"
    "docs/sprintbias/scripts/talk-bugs.sh"
    "docs/sprintbias/scripts/talk-folder.sh"
    "docs/sprintbias/scripts/talk-sprint.sh"
    "docs/sprintbias/help/talk.md"
    "docs/sprintbias/guides/use_talk.md"
    # define → gate
    "docs/sprintbias/scripts/define.sh"
    "docs/sprintbias/help/define.md"
    # tasks (execute) → work
    "docs/sprintbias/scripts/tasks.sh"
    "docs/sprintbias/help/tasks.md"
    # newepic → newplan
    "docs/sprintbias/scripts/create-epic.sh"
    "docs/sprintbias/help/newepic.md"
    "docs/epics/.TEMPLATE-epic.md"
    # look-family renames
    "docs/sprintbias/scripts/ai-context.sh"
    "docs/sprintbias/help/ai-context.md"
    "docs/sprintbias/help/checkfeatures.md"
    # keep-family / retired profession commands
    "docs/sprintbias/scripts/audit-deps.sh"
    "docs/sprintbias/help/audit-deps.md"
    "docs/sprintbias/scripts/audit-code.sh"
    "docs/sprintbias/scripts/audit-excellence.sh"
    "docs/sprintbias/scripts/audit-tasks.sh"
    "docs/sprintbias/help/audit.md"
    "docs/sprintbias/help/excellence.md"
    "docs/sprintbias/help/review-code.md"
    "docs/sprintbias/scripts/review-sprint.sh"
    "docs/sprintbias/help/review-sprint.md"
    # consolidated / removed guidance
    "docs/sprintbias/ai/task-writing-rules.md"
    "docs/sprintbias/ai/sprint-review.md"
    "docs/sprintbias/ai/.gitkeep"
    "docs/sprintbias/theory/feynman-method.md"
    # obsolete INDEX.md orientation pages
    "docs/INDEX.md"
    "docs/tasks/INDEX.md"
    "docs/bugs/INDEX.md"
    "docs/features/INDEX.md"
    "docs/designs/INDEX.md"
    "docs/examples/INDEX.md"
    "docs/data/INDEX.md"
    "docs/guides/INDEX.md"
    "docs/sprintbias/scripts/INDEX.md"
)

_retired_removed=0
for f in "${RETIRED_FRAMEWORK_FILES[@]}"; do
    if [ -f "$f" ]; then
        if git rm -f "$f" >/dev/null 2>&1 || rm -f "$f" 2>/dev/null; then
            msg_step "Removed retired $f"
            _retired_removed=$((_retired_removed + 1))
        else
            msg_warning "Could not remove retired $f"
        fi
    fi
done
if [ "$_retired_removed" -gt 0 ]; then
    msg_success "Pruned $_retired_removed retired framework file(s)"
fi
rmdir "docs/sprintbias/theory" 2>/dev/null || true

# ── Strip dead config keys (hard cut — no value carry to new names) ──
# Runtime only reads the current key set. Old pins (MODEL_TALK, BUDGET_TASKS,
# MODEL_REVIEW_SPRINT, …) are removed so they cannot confuse editors; re-set
# under the current names in docs/sprintbias/config if you still need them.
if [ -f "docs/sprintbias/config" ]; then
    _dead_keys=(
        MODEL_TALK MODEL_DEFINE MODEL_TASKS BUDGET_TASKS
        MODEL_REVIEW_SPRINT
        MODEL_PLAN
    )
    _cfg_tmp="$(mktemp "docs/sprintbias/config.XXXXXX")" || _cfg_tmp=""
    if [ -n "$_cfg_tmp" ]; then
        _dead_re='^(MODEL_TALK|MODEL_DEFINE|MODEL_TASKS|BUDGET_TASKS|MODEL_REVIEW_SPRINT|MODEL_PLAN)='
        if grep -qE "$_dead_re" docs/sprintbias/config 2>/dev/null; then
            if grep -vE "$_dead_re" docs/sprintbias/config > "$_cfg_tmp" 2>/dev/null \
               && mv -f "$_cfg_tmp" docs/sprintbias/config; then
                msg_step "Removed retired model/budget keys from docs/sprintbias/config"
            else
                rm -f "$_cfg_tmp" 2>/dev/null
            fi
        else
            rm -f "$_cfg_tmp" 2>/dev/null
        fi
    fi
    unset _dead_keys _cfg_tmp _dead_re
fi

# ============================================================================
# AI CLI CONFIG — write the door's choice into config
# ============================================================================
# SELECTED_CLI / SELECTED_PROVIDER were set by the two-door pick at the top.

msg_header "AI CLI configuration..."

CONFIG_FILE="docs/sprintbias/config"

# Source lib.sh if available (provides sprintbias_cfg / sprintbias_cfg_set)
_LIB_FILE="docs/sprintbias/lib.sh"
if [ -f "$_LIB_FILE" ]; then
    # shellcheck source=/dev/null
    source "$_LIB_FILE"
fi

# Write CLI and provider tier into the config file
if [ -f "$CONFIG_FILE" ]; then
    if declare -F sprintbias_cfg_set >/dev/null 2>&1; then
        sprintbias_cfg_set CLI "$SELECTED_CLI"
        sprintbias_cfg_set PROVIDER "$SELECTED_PROVIDER"
    else
        for _kv in "CLI=${SELECTED_CLI}" "PROVIDER=${SELECTED_PROVIDER}"; do
            _k="${_kv%%=*}"
            if grep -q "^${_k}=" "$CONFIG_FILE"; then
                sed -i '' "s|^${_k}=.*|${_kv}|" "$CONFIG_FILE"
            else
                echo "$_kv" >> "$CONFIG_FILE"
            fi
        done
    fi
    # Drop model pins that belong to the other provider so a claude→grok
    # (or reverse) switch never leaves MODEL_GATE=opus against CLI=grok.
    # Runtime also coerces foreign ids (sprintbias_coerce_model); this cleans
    # the file so config stays honest.
    _model_keys="MODEL_DEFAULT MODEL_FEATURE MODEL_IDEA MODEL_CHAT MODEL_GATE MODEL_SPLIT MODEL_SPRINT MODEL_WORK MODEL_PROFILE MODEL_CODE_AUDIT MODEL_EXCELLENCE MODEL_POLISH MODEL_AUDIT MODEL_DEPS MODEL_TRIAGE MODEL_PLAN_THINK MODEL_DRIFT"
    _cleared=0
    for _mk in $_model_keys; do
        _mv=""
        if declare -F sprintbias_cfg >/dev/null 2>&1; then
            _mv="$(sprintbias_cfg "$_mk")"
        else
            _mv="$(grep -m1 "^${_mk}=" "$CONFIG_FILE" 2>/dev/null | sed "s/^${_mk}=//" || true)"
        fi
        [ -n "$_mv" ] || continue
        _foreign=0
        case "$SELECTED_PROVIDER" in
            grok-build)
                case "$_mv" in
                    opus|sonnet|haiku|OPUS|SONNET|HAIKU|claude*|Claude*|CLAUDE*) _foreign=1 ;;
                esac
                ;;
            claude-code)
                case "$_mv" in
                    grok*|Grok*|GROK*) _foreign=1 ;;
                esac
                ;;
        esac
        if [ "$_foreign" -eq 1 ]; then
            if declare -F sprintbias_cfg_set >/dev/null 2>&1; then
                sprintbias_cfg_set "$_mk" ""
            else
                sed -i '' "s|^${_mk}=.*|${_mk}=|" "$CONFIG_FILE"
            fi
            _cleared=$((_cleared + 1))
        fi
    done
    msg_success "AI CLI set to: $SELECTED_CLI (provider tier: $SELECTED_PROVIDER)"
    if [ "$_cleared" -gt 0 ]; then
        msg_success "Cleared $_cleared provider-foreign MODEL_* pin(s) from config"
    fi
    unset _model_keys _cleared _mk _mv _foreign
else
    msg_warning "Config file not found: $CONFIG_FILE"
fi

# ============================================================================
# MORE OPTIONS — everything past the Easy Button hides here (Enter = No)
# ============================================================================
# Behind this gate: conflict binary (Prepend/Overwrite), GitHub Issues sync,
# and residual AI dotfiles. Default path never offers Overwrite — it silent-
# prepends deferred conflicts after this prompt.

echo ""
_more_opts_hint="GitHub Issues sync, extra AI files"
if [ ${#CONFLICTS[@]} -gt 0 ]; then
    _more_opts_hint="per-file choices, ${_more_opts_hint}"
fi
prompt_yes_no MORE_OPTIONS "More options? (${_more_opts_hint})" "no"
unset _more_opts_hint

if [ "$MORE_OPTIONS" = "yes" ]; then
    # Conflicts first — the only place a user-owned file can be overwritten.
    for entry in "${CONFLICTS[@]}"; do
        _ck="${entry%%|*}"; _rest="${entry#*|}"; _ct="${_rest%%|*}"; _cn="${_rest#*|}"
        resolve_conflict_interactive "$_ck" "$_ct" "$_cn"
    done

    # --- GitHub Issues sync ---
    echo ""
    prompt_yes_no GH_SYNC "Enable GitHub Issues sync (workflows + issue/PR templates)?" "no"
    if [ "$GH_SYNC" = "yes" ]; then
        install_github_sync
    else
        msg_step "Skipped GitHub Issues sync"
    fi

    # --- Extra AI instruction dotfiles (Cursor, Windsurf, Copilot) ---
    if [ ${#NEED_CREATE[@]} -gt 0 ]; then
        echo ""
        prompt_yes_no ADD_ALL_AI "Add all AI instructions (Cursor, Windsurf, Copilot)?" "no"
        if [ "$ADD_ALL_AI" = "yes" ]; then
            for entry in "${NEED_CREATE[@]}"; do
                rel_path="${entry#*|}"
                setup_ai_file "" "$rel_path" "$rel_path" "yes"
            done
        else
            msg_step "Skipped extra AI instruction files"
        fi
    fi
else
    # Default path: apply the silent safe default (prepend) to each conflict.
    apply_deferred_conflicts
fi

echo ""

# ============================================================================
# VALIDATION
# ============================================================================

msg_header "Running validation checks..."
VALIDATION_PASSED=true

# Check required directories
for dir in docs/tasks/backlog docs/tasks/next docs/tasks/doing docs/tasks/blocked docs/tasks/review docs/tasks/done docs/bugs docs/plans docs/sprintbias/scripts docs/features docs/guides; do
    if [ ! -d "$dir" ]; then
        VALIDATION_PASSED=false
        msg_error "Missing directory: $dir"
    fi
done

# Check required files (manual may be SPRINTDOCUMENTATION.md when user owns DOCUMENTATION.md)
for file in docs/sprintbias/DOC_STATE.md "${MANUAL_FILE:-DOCUMENTATION.md}"; do
    if [ ! -f "$file" ]; then
        VALIDATION_PASSED=false
        msg_error "Missing file: $file"
    fi
done

# Check script executability
for script in docs/sprintbias/scripts/*.sh; do
    if [ -f "$script" ] && [ ! -x "$script" ]; then
        chmod +x "$script" 2>/dev/null || msg_warning "Could not make $script executable"
    fi
done

if [ -f "./sprint.sh" ] && [ ! -x "./sprint.sh" ]; then
    chmod +x ./sprint.sh 2>/dev/null || msg_warning "Could not make ./sprint.sh executable"
fi

# ============================================================================
# OPTIONAL: `sprint` shell shortcut
# ============================================================================
# Offer to add `alias sprint='./sprint.sh'` so the user can type `sprint <cmd>`
# from a project root instead of `./sprint.sh <cmd>`. The alias is relative on
# purpose: it always runs the sprint.sh of whatever project you are standing in,
# so it stays correct across multiple installs and versions. Strictly opt-in,
# fresh installs only, and writes only to the user's own shell rc — nothing
# global, nothing outside the project unless the user says yes. Full details
# (including a subdirectory-aware variant) live in
# docs/sprintbias/guides/sprint_command.md.

if ! $UPDATE_MODE; then
    case "$(basename "${SHELL:-}")" in
        zsh)  SPRINT_SHELL_RC="$HOME/.zshrc" ;;
        bash) SPRINT_SHELL_RC="$HOME/.bashrc" ;;
        *)    SPRINT_SHELL_RC="" ;;
    esac

    SPRINT_ALIAS_LINE="alias sprint='./sprint.sh'"

    if [ -z "$SPRINT_SHELL_RC" ]; then
        msg_step "To type 'sprint' instead of './sprint.sh', see docs/sprintbias/guides/sprint_command.md"
    elif [ -f "$SPRINT_SHELL_RC" ] && grep -qF "$SPRINT_ALIAS_LINE" "$SPRINT_SHELL_RC" 2>/dev/null; then
        msg_step "'sprint' shortcut already present in $SPRINT_SHELL_RC"
    else
        echo ""
        prompt_yes_no SPRINT_ALIAS_CHOICE "Add a 'sprint' shortcut so you can type 'sprint <cmd>' instead of './sprint.sh <cmd>'? (adds an alias to $SPRINT_SHELL_RC)"
        if [ "$SPRINT_ALIAS_CHOICE" = "yes" ]; then
            if printf '\n# SprintBias shortcut — runs ./sprint.sh from a project root (see docs/sprintbias/guides/sprint_command.md)\n%s\n' "$SPRINT_ALIAS_LINE" >> "$SPRINT_SHELL_RC" 2>/dev/null; then
                msg_success "Added 'sprint' shortcut to $SPRINT_SHELL_RC"
                msg_step "Run 'source $SPRINT_SHELL_RC' (or open a new terminal), then use 'sprint help'"
            else
                msg_warning "Could not write to $SPRINT_SHELL_RC — see docs/sprintbias/guides/sprint_command.md to add it manually"
            fi
        else
            msg_step "Skipped 'sprint' shortcut — see docs/sprintbias/guides/sprint_command.md to add it later"
        fi
    fi
fi

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "================================================"
if [ "$VALIDATION_PASSED" = true ] && [ ${#ERRORS[@]} -eq 0 ]; then
    echo -e "  ${GREEN}Setup Complete - All Checks Passed!${NC}"
elif [ ${#ERRORS[@]} -gt 0 ]; then
    echo -e "  ${RED}Setup Complete - With Errors${NC}"
else
    echo -e "  ${YELLOW}Setup Complete - With Warnings${NC}"
fi
echo "================================================"

# Show error summary if any
if [ ${#ERRORS[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}Errors (${#ERRORS[@]}):${NC}"
    for err in "${ERRORS[@]}"; do
        echo "  • $err"
    done
fi

# Show warning summary if any
if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Warnings (${#WARNINGS[@]}):${NC}"
    for warn in "${WARNINGS[@]}"; do
        echo "  • $warn"
    done
fi

echo ""

if $UPDATE_MODE; then
    msg_success "SprintBias updated to version $CURRENT_VERSION"
    echo ""
    if [ -n "${ORIGINAL_VERSION:-}" ] && [ "$ORIGINAL_VERSION" != "$CURRENT_VERSION" ]; then
        echo "  Version:       $ORIGINAL_VERSION → $CURRENT_VERSION"
    else
        echo "  Version:       $CURRENT_VERSION (no change — files re-synced)"
    fi
    echo "  Files synced:  $FILES_COPIED"
    echo "  Scripts synced from src/ and DOC_STATE.md reconciled"
else
    msg_success "SprintBias installed to: $TARGET_PATH"
    echo "Platform: $PLATFORM"
    echo "Files installed: $FILES_COPIED"
    echo ""
    echo "Directory structure created in docs/"
    echo "Scripts available at docs/sprintbias/scripts/"
    echo "Documentation at ${MANUAL_FILE:-DOCUMENTATION.md}"
    echo "AI CLI/model config at docs/sprintbias/config (edit to change CLI or models)"
    echo ""
    echo "Get started:"
    echo "  ./sprint.sh profile                          # Prepare this system for your stack and design choices"
    echo "  ./sprint.sh newtask 'short task descriptor'  # Create a new task"
    echo "  ./sprint.sh newidea 'concept name'           # Outline a new concept"
    echo "  ./sprint.sh newfeature                       # Explain a feature you'd like to build or explain"
    echo ""
    echo "  ./sprint.sh help                             # Show all commands"
    echo ""
    echo "  Tip: type 'sprint' instead of './sprint.sh' — see docs/sprintbias/guides/sprint_command.md"
fi

echo ""

# Exit with error code if there were errors
if [ ${#ERRORS[@]} -gt 0 ]; then
    exit 1
fi
