#!/usr/bin/env bash
# config.sh — interactive configurator for docs/sprintbias/config. No AI is
# invoked; this is pure config plumbing over sprintbias_cfg_set. It walks the
# user through the choices that matter most day to day — AI provider and the
# default model — and writes them into the tracked config file.
# See: ./sprint.sh help config
#
# The provider picker mirrors setup.sh's two doors (Claude Code / Grok Build);
# the model picker offers that provider's common ids plus a custom escape hatch.
# For fine-grained, per-command models use `./sprint.sh model set`; for a
# personal override that never ships, edit docs/sprintbias/config.local.

set -euo pipefail

# ── Config ───────────────────────────────────────────────────────────
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPTS_DIR/.." && pwd)/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./sprint.sh config           # interactive: pick provider + default model
  ./sprint.sh config --help    # this help

Walks you through the everyday settings in docs/sprintbias/config:
  • AI provider   — Claude Code or Grok Build (CLI + provider tier)
  • Default model — the model every command uses unless a per-role pin or a
                    per-run --model flag overrides it

Related:
  ./sprint.sh model show                 # see the effective model per role
  ./sprint.sh model set <role> <model>   # pin one command
  docs/sprintbias/config.local           # personal overrides (never shipped)
EOF
}

case "${1:-}" in
  --help|-h) usage; exit 0 ;;
  "") : ;;
  *)  echo -e "${RED}Unknown argument: $1${NC}" >&2; usage >&2; exit 1 ;;
esac

# Interactive only — needs a real terminal to read answers.
if [ ! -t 0 ]; then
  echo -e "${YELLOW}config is interactive and needs a terminal.${NC}" >&2
  echo "Edit docs/sprintbias/config directly, or use ./sprint.sh model set <role> <model>." >&2
  exit 1
fi

# ── Current state (effective — includes any config.local overlay) ────
cur_cli="$(sprintbias_cfg CLI)"
cur_provider="$(sprintbias_cfg PROVIDER)"
cur_model="$(sprintbias_cfg MODEL_DEFAULT)"

echo -e "${BOLD}SprintBias configuration${NC}"
echo    "  Provider:       ${cur_provider:-(unset)}  (CLI=${cur_cli:-unset})"
echo    "  Default model:  ${cur_model:-(none — tier default applies)}"
if [ -f "$SPRINTBIAS_CONFIG_LOCAL_FILE" ]; then
  echo -e "  ${DIM}Note: docs/sprintbias/config.local may override these locally.${NC}"
fi
echo ""

# ── 1. Provider ──────────────────────────────────────────────────────
# Default to the current provider so a bare Enter is a no-op.
default_provider_key="c"; [ "$cur_provider" = "grok-build" ] && default_provider_key="g"

echo -e "${BOLD}AI provider${NC}"
echo    "  [c] Claude Code"
echo    "  [g] Grok Build"
printf  'Provider [%s]: ' "$default_provider_key"
read -r provider_ans || provider_ans=""
provider_ans="${provider_ans:-$default_provider_key}"

case "$(printf '%s' "$provider_ans" | tr '[:upper:]' '[:lower:]')" in
  c|claude|claude-code) new_cli="claude"; new_provider="claude-code" ;;
  g|grok|grok-build)    new_cli="grok";   new_provider="grok-build" ;;
  *) echo -e "${RED}Unrecognized choice '$provider_ans' — pick c or g.${NC}" >&2; exit 1 ;;
esac

provider_changed=0; [ "$new_provider" != "$cur_provider" ] && provider_changed=1
echo ""

# ── 2. Default model ─────────────────────────────────────────────────
# Provider-specific menus. Keep the id lists short and current; the custom
# entry is the escape hatch for anything not listed (and for models that ship
# after this menu was written). Update these as the model lineups change.
echo -e "${BOLD}Default model${NC}  ($new_provider)"
declare -a model_ids
if [ "$new_provider" = "claude-code" ]; then
  model_ids=(opus claude-opus-4-8 claude-opus-5 claude-sonnet-5 claude-haiku-4-5)
  echo "  [1] opus              latest Opus — floating alias (tier default)"
  echo "  [2] claude-opus-4-8   pinned Opus 4.8"
  echo "  [3] claude-opus-5     pinned Opus 5"
  echo "  [4] claude-sonnet-5   balanced speed/quality"
  echo "  [5] claude-haiku-4-5  fastest, cheapest"
else
  model_ids=(grok-4.5 grok-4)
  echo "  [1] grok-4.5          strong default for Grok Build"
  echo "  [2] grok-4            prior generation"
  echo -e "  ${DIM}(run \`grok models\` for the authoritative live list)${NC}"
fi
custom_num=$(( ${#model_ids[@]} + 1 ))
echo "  [$custom_num] custom id…"

# Offer "keep current" only when the provider did not change — a kept model from
# the other provider would be a foreign pin the runtime has to coerce.
keep_offered=0
if [ "$provider_changed" -eq 0 ] && [ -n "$cur_model" ]; then
  echo "  [k] keep current ($cur_model)"
  keep_offered=1
  printf 'Model [k]: '
  default_model_choice="k"
else
  printf 'Model [1]: '
  default_model_choice="1"
fi
read -r model_ans || model_ans=""
model_ans="${model_ans:-$default_model_choice}"

new_model=""
case "$model_ans" in
  k|K)
    if [ "$keep_offered" -eq 1 ]; then new_model="$cur_model"
    else echo -e "${RED}'keep' is not available when the provider changed.${NC}" >&2; exit 1; fi
    ;;
  ''|*[!0-9]*)
    echo -e "${RED}Unrecognized choice '$model_ans'.${NC}" >&2; exit 1 ;;
  *)
    if [ "$model_ans" -ge 1 ] && [ "$model_ans" -le "${#model_ids[@]}" ]; then
      new_model="${model_ids[$((model_ans - 1))]}"
    elif [ "$model_ans" -eq "$custom_num" ]; then
      printf 'Custom model id: '
      read -r new_model || new_model=""
      new_model="$(printf '%s' "$new_model" | tr -d '[:space:]')"
      [ -n "$new_model" ] || { echo -e "${RED}No model id entered.${NC}" >&2; exit 1; }
    else
      echo -e "${RED}Choice '$model_ans' is out of range.${NC}" >&2; exit 1
    fi
    ;;
esac
echo ""

# ── 3. Write ─────────────────────────────────────────────────────────
sprintbias_cfg_set CLI "$new_cli"
sprintbias_cfg_set PROVIDER "$new_provider"
sprintbias_cfg_set MODEL_DEFAULT "$new_model"

echo -e "${GREEN}✓${NC} Saved to docs/sprintbias/config"
echo    "  Provider:       $new_provider  (CLI=$new_cli)"
echo    "  Default model:  ${new_model:-(none — tier default applies)}"
echo ""
echo -e "${DIM}Verify:            ./sprint.sh model show${NC}"
echo -e "${DIM}Per-command model: ./sprint.sh model set <role> <model>${NC}"
echo -e "${DIM}Personal override: docs/sprintbias/config.local (wins, never shipped)${NC}"
