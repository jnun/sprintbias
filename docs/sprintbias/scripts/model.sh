#!/usr/bin/env bash
# model.sh — see, list, and set the AI model per role. No AI is invoked; this is
# pure config plumbing over docs/sprintbias/config. See: ./sprint.sh help model
#
#   model show            effective model per role (env → config → tier default)
#   model list            models the current provider offers (or a doc pointer)
#   model set KEY VALUE    write MODEL_DEFAULT / MODEL_<ROLE> into config
#
# Model selection has these layers, highest first:
#   1. env  SPRINTBIAS_MODEL_<ROLE>   (this-shell override, never written to disk)
#   2. --model <id> flag            (per-run lever a spine command exports as
#                                    SPRINTBIAS_MODEL_DEFAULT for one invocation)
#   3. config.local MODEL_<ROLE>    (semi-permanent LOCAL pin; wins over config,
#                                    never shipped/committed)
#   4. config      MODEL_<ROLE>     (per-role pin in docs/sprintbias/config)
#   5. config.local / config MODEL_DEFAULT   (global pin; local wins)
# and, when all are empty on an orchestration tier, a strong tier default
# (claude-code → opus, grok-build → grok-4.5) via sprintbias_tier_model.
# The config.local overlay is the ship-safe place for a personal CLI/model pin
# in this dev repo — see DOCUMENTATION.md → Local config overlay.

set -euo pipefail

# ── Config ───────────────────────────────────────────────────────────
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPTS_DIR/.." && pwd)/lib.sh"

# The known role suffixes — one per MODEL_<ROLE> key in docs/sprintbias/config.
# `set` refuses any key outside this set (plus DEFAULT) so a typo can never
# invent a dead config key that no script reads.
KNOWN_ROLES="WORK CHAT GATE FEATURE IDEA SPLIT SPRINT PROFILE CODE_AUDIT EXCELLENCE POLISH AUDIT DEPS TRIAGE PLAN_THINK DRIFT"

usage() {
  cat <<'EOF'
Usage:
  ./sprint.sh model            # same as: model show
  ./sprint.sh model show       # effective model per role (no AI)
  ./sprint.sh model list       # models the current provider offers
  ./sprint.sh model set KEY VALUE
                               # KEY = default | <role> (e.g. work, chat, gate)
                               # writes MODEL_DEFAULT / MODEL_<ROLE> to config

Roles: work chat gate feature idea split sprint profile code_audit
       excellence polish audit deps triage plan_think drift

Examples:
  ./sprint.sh model set default grok-4.5   # global default for every role
  ./sprint.sh model set work opus          # pin just `work`
  ./sprint.sh model set work ""            # clear the pin (fall back to default)

Options:
  --help, -h    Show this help
EOF
}

# ── model source label ───────────────────────────────────────────────
# Print "<effective-model>\t<source>" for a role suffix, mirroring the
# env → config-role → config-default → tier-default → CLI-default precedence so
# `show` can name WHERE each role's model comes from, not just what it is.
role_line() {
  local sfx="$1" env_var="SPRINTBIAS_MODEL_$1" model source
  model="$(sprintbias_tier_model "$sfx")"
  if [ "${!env_var+set}" = "set" ]; then
    source="env $env_var"
  elif [ -n "${SPRINTBIAS_MODEL_DEFAULT:-}" ]; then
    # The per-run lever a spine command's --model <id> flag exports.
    source="--model / env DEFAULT"
  elif [ -n "$(_sprintbias_cfg_read_file "MODEL_$sfx" "$SPRINTBIAS_CONFIG_LOCAL_FILE" || true)" ]; then
    source="config.local MODEL_$sfx"
  elif [ -n "$(_sprintbias_cfg_read_file "MODEL_$sfx" "$SPRINTBIAS_CONFIG_FILE" || true)" ]; then
    source="config MODEL_$sfx"
  elif [ -n "$(_sprintbias_cfg_read_file MODEL_DEFAULT "$SPRINTBIAS_CONFIG_LOCAL_FILE" || true)" ]; then
    source="config.local MODEL_DEFAULT"
  elif [ -n "$(sprintbias_cfg MODEL_DEFAULT)" ]; then
    source="config MODEL_DEFAULT"
  elif [ -n "$model" ]; then
    source="tier default"
  else
    source="CLI default"
  fi
  printf '%s\t%s' "$model" "$source"
}

# ── show ─────────────────────────────────────────────────────────────
cmd_show() {
  local tier mode cli
  cli="$SPRINTBIAS_CLI"
  tier="$(sprintbias_ai_tier)"
  mode="$(sprintbias_ai_mode)"

  echo -e "${BOLD}AI model configuration${NC}"
  echo "  CLI:      $cli"
  echo "  Provider: $tier"
  echo "  Mode:     $mode"
  local dflt; dflt="$(sprintbias_cfg MODEL_DEFAULT)"
  echo "  Default:  ${dflt:-(none — tier default applies)}"
  echo ""
  echo -e "${BOLD}Effective model per role${NC}  (env → config.local → config → tier default)"

  local sfx line model source role
  for sfx in $KNOWN_ROLES; do
    line="$(role_line "$sfx")"
    model="${line%%$'\t'*}"
    source="${line#*$'\t'}"
    role="$(printf '%s' "$sfx" | tr '[:upper:]' '[:lower:]')"
    printf '  %-12s %-14s%s%s%s\n' \
      "$role" "${model:-(cli picks)}" "$DIM" "$source" "$NC"
  done

  echo ""
  if [ -f "$SPRINTBIAS_CONFIG_LOCAL_FILE" ]; then
    echo -e "${DIM}Local overlay: docs/sprintbias/config.local (wins over config; never shipped)${NC}"
  fi
  echo -e "${DIM}Set one with:  ./sprint.sh model set <role> <model>${NC}"
  echo -e "${DIM}Local pin:     add MODEL_<ROLE>=<model> to docs/sprintbias/config.local${NC}"
  echo -e "${DIM}List choices:  ./sprint.sh model list${NC}"
}

# ── list ─────────────────────────────────────────────────────────────
cmd_list() {
  local tier; tier="$(sprintbias_ai_tier)"
  echo -e "${BOLD}Models available on this provider${NC} ($tier)"
  echo ""
  case "$tier" in
    grok-build)
      if command -v "$SPRINTBIAS_CLI" >/dev/null 2>&1; then
        # Grok Build exposes a live model list; show it verbatim.
        if "$SPRINTBIAS_CLI" models 2>/dev/null; then
          echo ""
          echo -e "${DIM}Pin one with:  ./sprint.sh model set default <model>${NC}"
          return 0
        fi
        echo -e "${YELLOW}\`$SPRINTBIAS_CLI models\` returned nothing — showing known aliases.${NC}"
        echo ""
      fi
      echo "Known Grok aliases:"
      echo "  grok-4.5     strong default for grok-build (used when nothing is pinned)"
      echo "  grok-4       prior generation"
      echo ""
      echo "Run \`$SPRINTBIAS_CLI models\` for the authoritative, up-to-date list."
      ;;
    claude-code)
      # No cheap, reliable model-list API here — ship known aliases + a pointer
      # rather than a fake `claude models` scrape (KU-21).
      echo "Known Claude aliases:"
      echo "  opus         strongest — the tier default for claude-code"
      echo "  sonnet       balanced speed/quality"
      echo "  haiku        fastest, cheapest"
      echo ""
      echo "Full model ids and the latest lineup:"
      echo "  https://docs.anthropic.com/en/docs/about-claude/models"
      ;;
    *)
      echo "This provider ($tier) has no model list built in."
      echo "Use a model id your CLI ($SPRINTBIAS_CLI) understands; see its own docs."
      ;;
  esac
  echo ""
  echo -e "${DIM}Pin one with:  ./sprint.sh model set default <model>${NC}"
}

# ── set ──────────────────────────────────────────────────────────────
# model set KEY VALUE — KEY is `default` or a role name (any case). Writes
# MODEL_DEFAULT / MODEL_<ROLE> via sprintbias_cfg_set so no unrelated key is
# touched. An empty VALUE clears the pin (falls back to the next layer).
cmd_set() {
  local key="${1:-}" value="${2:-}"
  if [ -z "$key" ]; then
    echo -e "${RED}ERROR: a key is required${NC}" >&2
    echo "Usage: ./sprint.sh model set <default|role> <model>" >&2
    exit 1
  fi
  # Reject a stray third argument so `model set work opus sonnet` is not
  # silently taken as `work=opus`.
  if [ "$#" -gt 2 ]; then
    echo -e "${RED}ERROR: too many arguments — quote a model id with spaces${NC}" >&2
    echo "Usage: ./sprint.sh model set <default|role> <model>" >&2
    exit 1
  fi

  local ukey cfg_key
  ukey="$(printf '%s' "$key" | tr '[:lower:]' '[:upper:]')"
  if [ "$ukey" = "DEFAULT" ]; then
    cfg_key="MODEL_DEFAULT"
  else
    case " $KNOWN_ROLES " in
      *" $ukey "*) cfg_key="MODEL_$ukey" ;;
      *)
        echo -e "${RED}ERROR: unknown key '$key'${NC}" >&2
        echo "Valid keys: default $(printf '%s' "$KNOWN_ROLES" | tr '[:upper:]' '[:lower:]')" >&2
        exit 1
        ;;
    esac
  fi

  sprintbias_cfg_set "$cfg_key" "$value"
  if [ -n "$value" ]; then
    echo -e "${GREEN}✓${NC} Set $cfg_key=$value in docs/sprintbias/config"
  else
    echo -e "${GREEN}✓${NC} Cleared $cfg_key in docs/sprintbias/config (falls back to the next layer)"
  fi
  echo "  See it in effect:  ./sprint.sh model show"
}

# ── Dispatch ─────────────────────────────────────────────────────────
case "${1:-show}" in
  --help|-h)  usage ;;
  show)       shift; cmd_show ;;
  list)       shift; cmd_list ;;
  set)        shift; cmd_set "$@" ;;
  "")         cmd_show ;;
  *)
    echo -e "${RED}Unknown subcommand: $1${NC}" >&2
    usage >&2
    exit 1
    ;;
esac
