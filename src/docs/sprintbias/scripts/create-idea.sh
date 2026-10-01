#!/usr/bin/env bash
set -euo pipefail

# create-idea.sh — Create an idea. See: ./sprint.sh help newidea

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"

# ── Helper: create idea file from template ─────────────────────────
create_idea_file() {
    local name="$1"

    # This function's stdout is the return channel (it prints the file path),
    # so every diagnostic must go to stderr or it is swallowed by the caller's
    # command substitution.
    local kebab
    kebab=$(sprintbias_slug "$name") || {
        echo -e "${RED}ERROR: Name has no letters or numbers to build a filename from.${NC}" >&2
        exit 1
    }

    local idea_file="docs/ideas/${kebab}.md"

    # Honest collision: name the resulting slug. If the name was truncated
    # (sprintbias_slug printed a note above), the user sees the two together —
    # two long names can collapse to the same 50-char slug.
    if [ -f "$idea_file" ]; then
        echo -e "${YELLOW}WARNING: Idea '$kebab' already exists at $idea_file${NC}" >&2
        exit 1
    fi

    local template_file="docs/ideas/.TEMPLATE-idea.md"
    copy_template "$template_file" "$idea_file" || exit 1

    local created_date
    created_date=$(date +%Y-%m-%d)

    sed_inplace "s/\[IDEA-NAME\]/$(sed_escape "$name")/g" "$idea_file"
    sed_inplace "s/YYYY-MM-DD/$created_date/g" "$idea_file"

    git add "$idea_file" 2>/dev/null || true

    echo "$idea_file"
}

# ── With argument: fast template creation ──────────────────────────
if [ -n "${1:-}" ]; then
    IDEA_FILE=$(create_idea_file "$1")
    echo -e "${GREEN}Created idea: $IDEA_FILE${NC}"
    echo ""
    echo "Next: Work through the eight phases — diverge first, converge second."
    exit 0
fi

# ── Without argument: AI-assisted Q&A ──────────────────────────────
# No CLI-presence check: emit mode prints the prompt for the surrounding agent
# when no binary is installed (or already inside a session). Bailing here would
# break that path — same reason create-feature.sh has no such check.

echo "▸ Starting idea refinement session..."
echo ""

_MODEL="$(sprintbias_tier_model IDEA)"
_model_args=()
[ -n "$_MODEL" ] && _model_args=(--model "$_MODEL")

_ORIENT="$(sprintbias_orient)"

# Live multi-turn Q&A needs an interactive-capable CLI on a real TTY. When exec
# cannot offer one, degrade to a single pass and say so (same contract as chat).
if [ "$(sprintbias_ai_mode)" = "exec" ] && ! sprintbias_interactive_ok; then
  echo -e "${YELLOW}Note: a live idea session needs an interactive-capable AI CLI (claude or grok) in a real terminal.${NC}"
  echo -e "${YELLOW}Doing a single refinement pass instead. For the full experience, see docs/sprintbias/guides/use_chat.md${NC}"
  echo ""
fi

TEMPLATE_FILE="docs/ideas/.TEMPLATE-idea.md"
APPEND_PROMPT="You are a thinking partner helping a colleague develop a raw idea into features ready to build. You guide them through eight phases — divergent first (open up), convergent second (close down).
${_ORIENT}

Read docs/sprintbias/ai/feynman-method.md for the full protocol. Follow it closely.

YOUR GOAL: Through an interactive session, guide the user from a raw spark to a set of features. You will create the idea file when the session is complete.

HOW TO CONDUCT THE SESSION:

You will work through eight phases. Ask at least one question per phase before writing content for that phase. Advance to the next phase when the user's answers satisfy the current phase — don't wait for them to say \"next.\"

PHASE 1 — THE SPARK (Divergent)
Ask: \"What's the idea? What triggered it — a frustration, a hunch, something you saw?\"
Capture the raw impulse. One or two exchanges is enough.

PHASE 2 — THE PROBLEM (Divergent)
Dig into who has this problem, how they know, what it costs.
If the user describes a solution, redirect: \"That's a solution — what's the problem underneath it?\"
Challenge vague claims: \"You said everyone — who has it worst?\"

PHASE 3 — THE LANDSCAPE (Divergent)
Map what exists. Suggest angles the user hasn't mentioned — competitors, adjacent solutions, manual workarounds.
Ask what's been tried and what's different about their situation.

PHASE 4 — THE BRAINSTORM (Divergent)
Get at least three different approaches: obvious, lazy, ambitious, weird.
If the user stalls at two, offer a third yourself.
Push for range — the goal is genuine options, not confirming what they already wanted.

PHASE 5 — THE BET (Convergent)
The user picks a direction and states it as: \"We believe [approach] will [solve problem] for [people] because [insight].\"
Help refine until it's specific. A good bet names the approach, problem, audience, and reasoning.

PHASE 6 — THE STRESS TEST (Convergent)
Assume the bet fails. YOU must name at least one reason it could fail and ask the user to respond.
Push back on assumptions: \"You said [X] — how confident are you?\"

PHASE 7 — THE SCOPE (Convergent)
Cut to the smallest thing that tests the bet.
Push for less — if v1 feels big, help find the embarrassingly small version.

PHASE 8 — THE HANDOFF (Convergent)
List features. Each must trace back to the bet. Remove anything that doesn't serve the bet.

AFTER ALL PHASES:
1. Ask the user for an idea name (short, descriptive, kebab-case-friendly).
2. Create the idea file:
   - Copy the template at $TEMPLATE_FILE to docs/ideas/<kebab-case-name>.md
   - Replace [IDEA-NAME] with the idea name
   - Replace YYYY-MM-DD with today's date
   - Fill in all eight phases from the conversation
   - Stage the file with git add
3. Evaluate the graduation checklist and flag any gates not met:
   - Problem validated (Phase 2): names real people with a real cost
   - Landscape checked (Phase 3): shows awareness of what exists
   - Bet articulated (Phase 5): clear hypothesis with \"because\"
   - Stress test completed (Phase 6): at least one failure mode and response
   - Scope defined (Phase 7): hard v1 / later line
   - Features listed (Phase 8): at least one feature tracing to the bet
4. Tell the user the file path and which gates are met vs. not met.

RULES:
- Ask ONE question at a time. Wait for the answer before the next.
- In Phases 1–4, suggest options and angles the user hasn't mentioned. Resist convergence.
- In Phases 5–8, sharpen and pressure-test. Push for specificity and small scope.
- Keep the conversation moving — don't repeat what the user said back to them.
- Write in plain English throughout. No jargon.
- You may only create files under docs/ideas/. Do not modify any other files."

sprintbias_run_interactive \
  --append-system-prompt "$APPEND_PROMPT" \
  ${_model_args[@]+"${_model_args[@]}"} \
  --tools "Read,Edit,Write,Bash" \
  --name "newidea" \
  "Start the idea refinement session."
