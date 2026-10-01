#!/usr/bin/env bash
# profile.sh — the project map. See: ./sprint.sh help profile
#
# profile        — interactive create/update of docs/sprintbias/project.md
# profile show   — print the current map (or how to create one); no AI
# profile check  — no-AI health check: listed paths exist, nothing it tracks
#                  changed since its **Checked:** stamp (work + plan start run it)
#
# project.md is the ONE place that answers "how do I know what I need to know":
# stack, code layout, commands, sources of truth, environments. Every AI prompt
# orients through it (sprintbias_orient in lib.sh).

set -euo pipefail

# ── Config ───────────────────────────────────────────────────────────

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PROFILE_FILE="$PROJECT_ROOT/docs/sprintbias/project.md"
PROFILE_REL="docs/sprintbias/project.md"

# Shared scan instructions — create and update both auto-detect everything.
# Update mode diffs that draft against the existing map and surfaces drift.
SCAN_INSTRUCTION="Start by scanning the project to auto-detect what you can:
- Stack: file extensions, manifests (package.json, Cargo.toml, go.mod,
  pyproject.toml, Gemfile, pom.xml, …), linters/formatters (.eslintrc,
  .prettierrc, rustfmt.toml, .editorconfig, …), test configs and test folders,
  a few source files for error handling and patterns.
- Code: the top-level layout — what lives where, and where new code goes.
- Commands: how to run, test, lint, and build (manifest scripts, Makefile,
  justfile, README, CI steps).
- Sources of truth: documents that hold authority — README, CONTRIBUTING,
  architecture notes, decision records (docs/adr, decisions/), glossary /
  lexicon / taxonomy files, API specs (openapi, graphql schema, proto), design
  system docs, SECURITY.md, style guides. Include the instruction files the
  project owns (CLAUDE.md, AGENTS.md, .cursorrules, …) as sources, read-only.
- Environments: local setup (docker-compose, devcontainer, .env.example —
  variable NAMES only), CI (.github/workflows, .gitlab-ci.yml, …), and deploy
  (deploy workflows, Dockerfile, IaC such as *.tf, platform config such as
  vercel.json / fly.toml / Procfile) with who may deploy."

# ── Arg parsing ──────────────────────────────────────────────────────
# profile [show|check] | profile --help
# Unknown args print usage and exit 1 so a typo never silently starts AI.

usage() {
  cat <<'EOF'
Usage:
  ./sprint.sh profile           # create or update the project map (interactive AI)
  ./sprint.sh profile show      # print the current map (no AI)
  ./sprint.sh profile check     # check the map is current: paths exist, nothing it tracks changed (no AI)

Options:
  --help, -h    Show this help
EOF
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

if [ "${1:-}" = "show" ]; then
  if [ -f "$PROFILE_FILE" ]; then
    cat "$PROFILE_FILE"
    exit 0
  fi
  echo "No project profile yet."
  echo "Run:  ./sprint.sh profile"
  echo "to create one at $PROFILE_REL"
  exit 0
fi

if [ "${1:-}" = "check" ]; then
  cd "$PROJECT_ROOT"
  if sprintbias_profile_check; then
    echo -e "${GREEN}✓ Project map is current ($PROFILE_REL)${NC}"
    exit 0
  fi
  exit 1
fi

if [ -n "${1:-}" ]; then
  echo -e "${RED}Unknown argument: $1${NC}" >&2
  usage >&2
  exit 1
fi

# ── Interactive create / update ──────────────────────────────────────

_MODEL="$(sprintbias_tier_model PROFILE)"
_model_args=()
[ -n "$_MODEL" ] && _model_args=(--model "$_MODEL")

# The stamp the check compares against. Computed here so every session writes
# the exact same line, whichever mode or provider runs it.
_CHECKED_LINE="**Checked:** $(date +%Y-%m-%d)"
_head="$(cd "$PROJECT_ROOT" && git rev-parse --short HEAD 2>/dev/null || true)"
[ -n "$_head" ] && _CHECKED_LINE="$_CHECKED_LINE @ $_head"

if [ -f "$PROFILE_FILE" ]; then
  echo "▸ Updating existing profile: $PROFILE_REL"
  _drift="$(cd "$PROJECT_ROOT" && sprintbias_profile_check || true)"
  _drift_block=""
  [ -n "$_drift" ] && _drift_block="

The no-AI check already found:
$_drift"
  MODE_INSTRUCTION="An existing project map is at: $PROFILE_REL — read it first.$_drift_block

Then re-scan the project the same way you would for a first-time create:
$SCAN_INSTRUCTION

Build a draft map from what you detect NOW. Diff it against the existing
$PROFILE_REL and surface drift proactively — do not only ask \"what changed?\"
Call out concrete signals, e.g.:
- a new or removed framework dependency in a manifest
- a new test config, CI workflow, or deploy target
- a new, moved, or deleted source-of-truth document
- language/structure shifts visible from the tree

Walk fields that still match briefly (\"Language still looks like Go — OK?\").
Spend the conversation on detected drift and gaps you could not auto-fill.
Keep it conversational. Update the file in place when done."
else
  echo "▸ Creating project profile: $PROFILE_REL"
  MODE_INSTRUCTION="No project map exists yet. You will create one at: $PROFILE_REL

$SCAN_INSTRUCTION

Then present what you found and ask the user to confirm or correct it.
Only ask about things you could not detect — most projects need 2-3
confirmations, not a questionnaire. Ask which documents are the authority when
two could be (e.g. two READMEs), and who may deploy."
fi

APPEND_PROMPT="You are helping a developer build the project map: the one place every AI
session reads to know where this project's knowledge lives. Agents jump
straight to the paths it names instead of searching, so accuracy matters more
than completeness.

$MODE_INSTRUCTION

HOW TO CONDUCT THE SESSION:
1. Read the project files to auto-detect as much as possible.
2. Present your findings as a draft map (and, on update, call out drift vs the existing file).
3. Ask the user to confirm, correct, or add. Prefer ONE round of questions over one-at-a-time grilling — but answer any follow-ups they raise.
4. Write the final map to $PROFILE_REL.

OUTPUT FORMAT — one screen, these sections, one line per field. Every path in
backticks. Leave out a field the project does not have; add a line under
Sources of truth for any other authority document you confirm.
\`\`\`
# Project Profile

**Language:** ...
**Framework:** ...
**Tests:** ...
**Style:** ...
**Error handling:** ...
**Patterns:** ...

## Code
**Structure:** \`src/\` app code · \`lib/\` shared · ...
**New code goes:** ...

## Commands
**Run:** \`...\`
**Test:** \`...\`
**Lint:** \`...\`
**Build:** \`...\`

## Sources of truth
**Glossary:** \`docs/GLOSSARY.md\` — terms and their meanings (lexicon / taxonomy)
**Architecture:** \`...\` — ...
**Decisions:** \`...\` — ...
**API:** \`...\` — ...
**Security:** \`...\` — ...
**Instructions:** \`CLAUDE.md\` — agent instructions the project owns

## Environments
**Local:** \`...\` — ...
**CI:** \`...\` — ...
**Deploy:** \`...\` — who may deploy (default: human-owned)

$_CHECKED_LINE
\`\`\`

RULES:
- Pointers and one-line facts only; never copy a document's content into the map.
- Record variable NAMES, never secret values. Do not open .env files that hold real values.
- End the file with exactly this line: $_CHECKED_LINE
- You may only write to $PROFILE_REL. Do not modify any other files.
- After writing the file, tell the user it's done: every AI command now orients from it, and \`./sprint.sh profile check\` (run automatically by work and plan start) flags when it drifts."

# profile is a dialogue (confirm fields) — sprintbias_run_interactive keeps the
# CLI attached to the terminal so the user sees live activity and can answer.
# When a live session is not possible, degrade to one-shot and say so (same
# guard and wording pattern as chat.sh).
if [ "$(sprintbias_ai_mode)" = "exec" ] && ! sprintbias_interactive_ok; then
  echo -e "${YELLOW}Note: a live back-and-forth needs an interactive-capable AI CLI (claude or grok) in a real terminal.${NC}"
  echo -e "${YELLOW}Doing a single profile pass instead. To wire up the full interactive experience,${NC}"
  echo -e "${YELLOW}see docs/sprintbias/guides/use_chat.md${NC}"
  echo ""
fi

sprintbias_run_interactive \
  --append-system-prompt "$APPEND_PROMPT" \
  ${_model_args[@]+"${_model_args[@]}"} \
  --tools "Read,Edit,Write,Bash,Grep,Glob" \
  --permissions "auto" \
  --name "profile" \
  "Read the project files and start the profile session."
