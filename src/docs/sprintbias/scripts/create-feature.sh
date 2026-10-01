#!/usr/bin/env bash
set -euo pipefail

# create-feature.sh — Create a feature. See: ./sprint.sh help newfeature

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

# ── Helper: create feature file from template ───────────────────────
create_feature_file() {
    local name="$1"

    # This function's stdout is the return channel (it prints the file path),
    # so every diagnostic must go to stderr or it is swallowed by the caller's
    # command substitution.
    local kebab
    kebab=$(sprintbias_slug "$name") || {
        echo -e "${RED}ERROR: Name has no letters or numbers to build a filename from.${NC}" >&2
        exit 1
    }

    local feature_file="docs/features/${kebab}.md"

    # Honest collision: name the resulting slug. If the name was truncated
    # (sprintbias_slug printed a note above), the user sees the two together —
    # two long names can collapse to the same 50-char slug.
    if [ -f "$feature_file" ]; then
        echo -e "${YELLOW}WARNING: Feature '$kebab' already exists at $feature_file${NC}" >&2
        exit 1
    fi

    local template_file="docs/features/.TEMPLATE-feature.md"
    copy_template "$template_file" "$feature_file" || exit 1

    local created_date
    created_date=$(date +%Y-%m-%d)

    sed_inplace "s/\[FEATURE-NAME\]/$(sed_escape "$name")/g" "$feature_file"
    sed_inplace "s/YYYY-MM-DD/$created_date/g" "$feature_file"

    git add "$feature_file" 2>/dev/null || true

    echo "$feature_file"
}

# ── With argument: fast template creation ───────────────────────────
if [ -n "${1:-}" ]; then
    FEATURE_FILE=$(create_feature_file "$1")
    echo -e "${GREEN}Created feature: $FEATURE_FILE${NC}"
    echo ""
    echo "Next: Edit the file to define requirements and acceptance criteria."
    exit 0
fi

# ── Without argument: AI-assisted Q&A ───────────────────────────────

echo "▸ Starting feature definition Q&A..."
echo ""

_MODEL="$(sprintbias_tier_model FEATURE)"
_model_args=()
[ -n "$_MODEL" ] && _model_args=(--model "$_MODEL")

_ORIENT="$(sprintbias_orient)"

# Live multi-turn Q&A needs an interactive-capable CLI on a real TTY. When exec
# cannot offer one, degrade to a single pass and say so (same contract as chat).
if [ "$(sprintbias_ai_mode)" = "exec" ] && ! sprintbias_interactive_ok; then
  echo -e "${YELLOW}Note: a live feature Q&A needs an interactive-capable AI CLI (claude or grok) in a real terminal.${NC}"
  echo -e "${YELLOW}Doing a single definition pass instead. For the full experience, see docs/sprintbias/guides/use_chat.md${NC}"
  echo ""
fi

TEMPLATE_FILE="docs/features/.TEMPLATE-feature.md"
APPEND_PROMPT="You are a product-minded developer helping a colleague define a new feature through conversation.
${_ORIENT}

YOUR GOAL: Through a focused Q&A, gather enough information to create a well-defined feature document. You will create the file when you have what you need.

HOW TO CONDUCT THE SESSION:

1. START by greeting the user briefly and asking:
   \"What feature would you like to define? Give me a short name and 1-2 sentences on what it does.\"

2. AFTER their answer, ask follow-up questions ONE AT A TIME. Each question should:
   - Target a specific gap in the feature definition
   - Include a best-practice suggestion when relevant, formatted as: \"(Best practice: [recommendation])\"
   - Be concise — no long preambles

   Ask about these areas in order, skipping any already answered:
   a. WHO is this for? What's their situation? → User Stories
   b. What are the specific things it must do? → Functional Requirements
   c. Any non-functional concerns (performance, security, accessibility)? → Non-Functional Requirements
   d. How will you know it works? What does success look like? → Acceptance Criteria

3. WHEN YOU HAVE ENOUGH (typically 4-6 questions), tell the user:
   \"I have enough to write this up. Here's what I'll put in the feature:\"
   Show them a preview of: Overview, User Stories, Requirements, and Acceptance Criteria.

4. AFTER the user confirms (or adjusts), create the feature file:
   - Copy the template at $TEMPLATE_FILE to docs/features/<kebab-case-name>.md
   - Replace [FEATURE-NAME] with the feature name
   - Replace YYYY-MM-DD with today's date
   - Fill in Overview, User Stories, Functional Requirements, Non-Functional Requirements, and Acceptance Criteria from the conversation
   - Remove placeholder content (the blank checkboxes, the \"As a _, I want to _, so that _\" stub)
   - Leave Technical Design, Implementation Tasks, Testing Strategy, and Documentation sections with their template placeholders — those get filled during implementation
   - Stage the file with git add

5. TELL the user the feature has been created and show the file path.

RULES:
- Ask ONE question at a time. Wait for the answer before asking the next.
- Keep the conversation moving — don't repeat what the user said back to them.
- Write in plain English throughout. Focus on what users experience, not implementation.
- You may only create files under docs/features/. Do not modify any other files.
- Do not write code or design the implementation — only define the feature."

sprintbias_run_interactive \
  --append-system-prompt "$APPEND_PROMPT" \
  ${_model_args[@]+"${_model_args[@]}"} \
  --tools "Read,Edit,Write,Bash" \
  --name "newfeature" \
  "Start the feature definition Q&A session."
