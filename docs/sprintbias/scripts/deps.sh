#!/usr/bin/env bash
# deps.sh — Dependency-update scan. Detects the project's package
# ecosystem(s), runs each one's native "outdated" and "audit" tooling, then
# files ONE backlog task ("Dependency updates") holding three sections:
#   1. Outdated dependencies
#   2. Security advisories
#   3. Upgrade impact & breaking-change risk
# The deterministic bash half detects ecosystems and captures raw tool output;
# the AI half cleans that into the three sections and greps THIS codebase to
# judge impact. See: ./sprint.sh help deps

set -euo pipefail

# ── Config ───────────────────────────────────────────────────────────
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(cd "$SCRIPTS_DIR/.." && pwd)/lib.sh"

MODEL="$(sprintbias_tier_model DEPS)"
TOOLS="Read,Grep,Glob,Edit,Bash,Agent"
PERMISSIONS="auto"
# Tunable so a max-turns abort has a real next step (see the error branch below).
MAX_TURNS="${SPRINTBIAS_AUDIT_MAX_TURNS:-30}"
LOG_DIR="docs/tmp"
# Per-tool wall-clock cap — a slow or network-bound registry check can't wedge
# the whole audit. Override with SPRINTBIAS_DEPS_TIMEOUT.
DEPS_TIMEOUT="${SPRINTBIAS_DEPS_TIMEOUT:-120}"

# ── Preflight ───────────────────────────────────────────────────────
if [ ! -f "docs/sprintbias/DOC_STATE.md" ]; then
  echo -e "${RED}ERROR: docs/sprintbias/DOC_STATE.md not found!${NC}" >&2
  echo "Run ./setup.sh first to initialize the project." >&2
  exit 1
fi

AI_MODE="$(sprintbias_ai_mode)"
if [ "$AI_MODE" != "emit" ] && ! command -v "$SPRINTBIAS_CLI" &>/dev/null; then
  echo "✗ AI CLI '$SPRINTBIAS_CLI' not found in PATH" >&2
  echo "  Edit docs/sprintbias/config to change CLI, or install the tool." >&2
  exit 1
fi

mkdir -p "$LOG_DIR"
RAW_LOG="$LOG_DIR/audit-deps-raw.$(date +%Y%m%d-%H%M%S).$$.md"
: > "$RAW_LOG"

# ── Ecosystem gathering ──────────────────────────────────────────────
DETECTED=()   # human labels, one per detected ecosystem

# first_cmd CANDIDATE…  — print the first candidate found on PATH, or the first
# candidate as a fallback label when none exist (so the skip message names a
# real tool). Handles the pip/pip3, bundle-audit/bundler-audit naming splits.
first_cmd() {
  local c
  for c in "$@"; do
    if command -v "$c" >/dev/null 2>&1; then printf '%s' "$c"; return 0; fi
  done
  printf '%s' "$1"
}

# emit_block LABEL DIR TOOL CMD…  — append one raw-output block to $RAW_LOG,
# running CMD from inside DIR (the directory that owns the manifest, so npm/pip/
# cargo/etc. read the right project in a monorepo). TOOL is the binary whose
# presence gates the run; it is deliberately separate from CMD so a plugin
# subcommand (cargo outdated) is gated on the plugin binary (cargo-outdated),
# turning a missing plugin into an honest "skipped" instead of a cryptic "no
# such subcommand". The command's own non-zero exit (npm/composer "outdated"
# exit 1 when anything is outdated) is expected and swallowed — we only want
# its text.
emit_block() {
  local label="$1" dir="$2" tool="$3"; shift 3
  {
    printf '\n### %s\n\n' "$label"
    if ! command -v "$tool" >/dev/null 2>&1; then
      printf '_skipped — `%s` not installed_\n' "$tool"
      return 0
    fi
    local out
    out="$( cd "$dir" && run_with_timeout "$DEPS_TIMEOUT" "$@" 2>&1 )" || true
    [ -n "$out" ] || out="(no output — nothing reported)"
    # Cap each block so a huge tree can't bloat the task file / prompt. Mark the
    # cut explicitly — a silently truncated list must never read as "complete".
    local capped
    capped="$(printf '%s' "$out" | head -c 20000)"
    # Fire the marker when the cap actually shortened the text. Comparing the
    # two lengths (rather than "${#out} > 20000") stays correct for multibyte
    # output, where head's byte cap and ${#out}'s character count diverge.
    if [ "${#capped}" -lt "${#out}" ]; then
      capped="$capped
… [truncated — re-run \`$tool\` directly for the full list]"
    fi
    printf '```\n%s\n```\n' "$capped"
  } >> "$RAW_LOG"
}

# audit_dir ECO DIR  — emit the outdated + advisory blocks for one ecosystem
# rooted in DIR. Every tool runs from DIR (via emit_block) so it reads that
# project's manifest, not the repo root's. LABEL carries the path so a monorepo
# with app/ and api/ produces clearly attributed output.
audit_dir() {
  local eco="$1" dir="$2" label
  label="${dir#./}"; [ "$label" = "." ] && label="(root)"
  case "$eco" in
    node)
      # (Yarn Classic verbs; on Yarn Berry the block captures Berry's
      # "use yarn npm audit" hint rather than data — still an honest signal.)
      local pm=npm
      [ -f "$dir/pnpm-lock.yaml" ] && pm=pnpm
      [ -f "$dir/yarn.lock" ] && pm=yarn
      DETECTED+=("Node / JavaScript — $label ($pm)")
      emit_block "Node — outdated — $label ($pm)"       "$dir" "$pm" "$pm" outdated
      emit_block "Node — security audit — $label ($pm)" "$dir" "$pm" "$pm" audit
      ;;
    python)
      DETECTED+=("Python — $label")
      local pip; pip="$(first_cmd pip pip3)"
      emit_block "Python — outdated — $label ($pip)" "$dir" "$pip" "$pip" list --outdated
      # -r pins the audit to THIS project's requirements when present, instead
      # of the whole environment (pip has no other per-project scoping).
      if [ -f "$dir/requirements.txt" ]; then
        emit_block "Python — advisories — $label (pip-audit -r)" "$dir" pip-audit pip-audit -r requirements.txt
      else
        emit_block "Python — advisories — $label (pip-audit)" "$dir" pip-audit pip-audit
      fi
      ;;
    rust)
      # Gate on the plugin binary so a missing plugin reads as "skipped", not a
      # subcommand error (`command -v cargo` is always true).
      DETECTED+=("Rust — $label")
      emit_block "Rust — outdated — $label (cargo-outdated)"    "$dir" cargo-outdated cargo outdated
      emit_block "Rust — security audit — $label (cargo-audit)" "$dir" cargo-audit    cargo audit
      ;;
    go)
      DETECTED+=("Go — $label")
      emit_block "Go — available module updates — $label"     "$dir" go          go list -u -m all
      emit_block "Go — vulnerabilities — $label (govulncheck)" "$dir" govulncheck govulncheck ./...
      ;;
    php)
      DETECTED+=("PHP — $label")
      emit_block "PHP — outdated — $label (composer)"       "$dir" composer composer outdated
      emit_block "PHP — security audit — $label (composer)" "$dir" composer composer audit
      ;;
    ruby)
      # The bundler-audit gem installs as bundle-audit on most systems and
      # bundler-audit on some; accept either.
      DETECTED+=("Ruby — $label")
      local ba; ba="$(first_cmd bundle-audit bundler-audit)"
      emit_block "Ruby — outdated — $label (bundler)"        "$dir" bundle bundle outdated
      emit_block "Ruby — vulnerabilities — $label ($ba)"     "$dir" "$ba"  "$ba" check --update
      ;;
  esac
}

# ── Discover manifests anywhere in the tree ──────────────────────────
# Monorepos keep manifests in subdirectories (api/, app/, packages/*), so we
# search recursively — but prune dependency/build/VCS trees, or we'd audit our
# dependencies' dependencies and crawl forever. Depth-first, then sorted for
# stable, grouped output. Override the vendor list with SPRINTBIAS_DEPS_PRUNE.
PRUNE_DIRS="${SPRINTBIAS_DEPS_PRUNE:-node_modules vendor .git dist build out target .venv venv env .tox .next .nuxt .svelte-kit .cache coverage bower_components Pods .terraform __pycache__ .gradle}"

prune_expr=()
for d in $PRUNE_DIRS; do prune_expr+=(-name "$d" -o); done
unset "prune_expr[$(( ${#prune_expr[@]} - 1 ))]"   # drop trailing -o

MANIFESTS="$(find . \( -type d \( "${prune_expr[@]}" \) -prune \) -o \
  -type f \( -name package.json -o -name requirements.txt -o -name pyproject.toml \
    -o -name Pipfile -o -name Cargo.toml -o -name go.mod -o -name composer.json \
    -o -name Gemfile \) -print 2>/dev/null | sort)"

# Walk each manifest → (dir, ecosystem), de-duplicating so a dir holding both
# pyproject.toml and requirements.txt is audited once. PROCESSED is a plain
# space-delimited set (bash 3.2 has no associative arrays).
MAX_PROJECTS="${SPRINTBIAS_DEPS_MAX_PROJECTS:-25}"
PROCESSED=""
COUNT=0
SKIPPED=0
while IFS= read -r mf; do
  [ -n "$mf" ] || continue
  dir="$(dirname "$mf")"
  case "$(basename "$mf")" in
    package.json)                        eco=node ;;
    requirements.txt|pyproject.toml|Pipfile) eco=python ;;
    Cargo.toml)                          eco=rust ;;
    go.mod)                              eco=go ;;
    composer.json)                       eco=php ;;
    Gemfile)                             eco=ruby ;;
    *)                                   continue ;;
  esac
  key="$dir|$eco"
  case " $PROCESSED " in *" $key "*) continue ;; esac
  PROCESSED="$PROCESSED $key"
  COUNT=$((COUNT + 1))
  # Cap the number of projects so a sprawling monorepo can't fan out into
  # hundreds of network-bound tool runs. The skip is reported, never silent.
  if [ "$COUNT" -gt "$MAX_PROJECTS" ]; then SKIPPED=$((SKIPPED + 1)); continue; fi
  audit_dir "$eco" "$dir"
done <<EOF
$MANIFESTS
EOF

if [ "${#DETECTED[@]}" -eq 0 ]; then
  echo "▸ No dependency manifests found anywhere in the tree (vendor/build dirs excluded)."
  echo "  Looked for: package.json, requirements.txt, pyproject.toml, Pipfile,"
  echo "  Cargo.toml, go.mod, composer.json, Gemfile."
  echo "  Nothing to audit — no task created."
  rm -f "$RAW_LOG"
  exit 0
fi

if [ "$SKIPPED" -gt 0 ]; then
  echo "⚠ $MAX_PROJECTS-project cap reached — $SKIPPED further project(s) not audited."
  echo "  Raise it with SPRINTBIAS_DEPS_MAX_PROJECTS=<n> to cover them."
fi

echo "▸ Ecosystems detected:"
for e in "${DETECTED[@]}"; do echo "    - $e"; done
echo "  Raw tool output: $RAW_LOG"
echo ""

# Soft duplicate guard — filing is still allowed (a fresh audit is a fresh
# snapshot), but stacking silent duplicates is a smell worth flagging.
for d in backlog next doing; do
  for f in docs/tasks/"$d"/*-audit-dependency-updates.md; do
    [ -e "$f" ] && echo "  ⚠ An open dependency-audit task already exists: $f"
  done
done 2>/dev/null

# ── Create the backlog task (canonical path: ID, lock, DOC_STATE) ────
# Capture (with stderr) instead of letting set -e abort on a non-zero exit, so
# the diagnostic below can surface create-task.sh's own error text.
CREATE_OUT="$(bash "$SCRIPTS_DIR/create-task.sh" "Audit dependency updates" 2>&1)" || true
TASK_FILE="$(printf '%s\n' "$CREATE_OUT" | grep -oE 'docs/tasks/backlog/[^ ]+\.md' | tail -1)"
if [ -z "$TASK_FILE" ] || [ ! -f "$TASK_FILE" ]; then
  echo "✗ Could not create the backlog task." >&2
  printf '%s\n' "$CREATE_OUT" >&2
  exit 1
fi

# ── Seed the task with the section skeleton + raw source data ────────
# Placeholders keep the task useful even if no AI ever runs; the raw appendix
# is the AI's (or a human's) source material and can be trimmed once analysed.
{
  echo ""
  echo "## Ecosystems detected"
  echo ""
  for e in "${DETECTED[@]}"; do echo "- $e"; done
  echo ""
  echo "## Outdated dependencies"
  echo ""
  echo "_Pending analysis — see Source data below._"
  echo ""
  echo "## Security advisories"
  echo ""
  echo "_Pending analysis — see Source data below._"
  echo ""
  echo "## Upgrade impact & breaking-change risk"
  echo ""
  echo "_Pending analysis — see Source data below._"
  echo ""
  echo "---"
  echo ""
  echo "## Source data (raw tool output)"
  echo ""
  echo "_Generated by \`./sprint.sh deps\` on $(date +%Y-%m-%d). Delete once the sections above are filled._"
  cat "$RAW_LOG"
} >> "$TASK_FILE"

echo "▸ Filed task: $TASK_FILE"

# ── Build the analysis prompt ────────────────────────────────────────
PROFILE_LINE="$(sprintbias_profile_line)"

PROMPT="Dependency-update audit. CLAUDE.md is auto-loaded.${PROFILE_LINE}

A backlog task has been created with raw dependency-tool output embedded under
its '## Source data' section:

  TASK FILE: $TASK_FILE

Ecosystems detected: $(printf '%s; ' "${DETECTED[@]}")

Edit that task file (do not create a new one). Replace the three placeholder
sections using the raw Source data plus the actual code in this repo:

1. '## Outdated dependencies' — a clean table:
   | Package | Ecosystem | Current | Latest stable | Bump (patch/minor/major) |
   Use the LATEST STABLE release, not pre-release/beta. Sort major bumps first.

2. '## Security advisories' — a table of known vulnerabilities from the audit
   output:
   | Package | Advisory (CVE/GHSA) | Severity | Vulnerable | Fixed in |
   If the audit output is empty or the tool was skipped, say so explicitly —
   never imply 'clean' when a scanner did not run.

3. '## Upgrade impact & breaking-change risk' — for each notable update
   (every major bump, and any dependency flagged by a security advisory):
   - the semver jump and what typically breaks across it,
   - where THIS codebase uses it — grep/glob for imports and call sites,
   - a risk rating (Low / Medium / High) and the smallest safe next step.
   Skip dependencies this repo does not actually import.

Then delete the '## Source data' section and its heading — the three sections
above replace it. Keep '## Ecosystems detected' as-is.

Do not modify any file other than $TASK_FILE. Finish with a final line:
VERDICT: FILED — <n> outdated, <m> advisories | CLEAN — nothing outdated"

# ── Run ──────────────────────────────────────────────────────────────
# Emit mode: hand the prompt to the surrounding agent (checked via AI_MODE,
# not sprintbias_emitted — the exec path runs sprintbias_run in a command
# substitution where the mode flag can't propagate).
if [ "$AI_MODE" = "emit" ]; then
  sprintbias_run -p "$PROMPT"
  echo ""
  echo "✓ Task filed with raw source data: $TASK_FILE"
  echo "  Run the emitted prompt above to fill in the three analysis sections."
  exit 0
fi

_model_args=()
[ -n "$MODEL" ] && _model_args=(--model "$MODEL")
# Budget only on a cap-capable tier (today Claude Code) — see lib.sh.
_budget_args=()
if sprintbias_budget_capable && [ -n "${SPRINTBIAS_BUDGET_DEPS:-}" ]; then
  _budget_args=(--budget "$SPRINTBIAS_BUDGET_DEPS")
fi

LOG_FILE="$(sprintbias_log_path deps "$(basename "$TASK_FILE")")"

sprintbias_run -p "$PROMPT" \
  ${_model_args[@]+"${_model_args[@]}"} \
  ${_budget_args[@]+"${_budget_args[@]}"} \
  --tools "$TOOLS" \
  --permissions "$PERMISSIONS" \
  --max-turns "$MAX_TURNS" \
  --output-format json >"$LOG_FILE" 2>/dev/null || true

# Did the CLI finish at all? A max-turns abort or a CLI that never started
# produces no verdict for a very different reason than an odd answer format —
# say which, rather than blaming the verdict parse. One read of the run gives
# the outcome and the result text to grep a verdict from.
echo ""
sprintbias_interpret_run "$LOG_FILE"
if [ "$SPRINTBIAS_RUN_OUTCOME" != "finished" ]; then
  echo "⚠ Dependency audit did not finish — $(sprintbias_run_hint "$SPRINTBIAS_RUN_OUTCOME")"
  echo "  The task with raw source data is still filed: $TASK_FILE"
  case "$SPRINTBIAS_RUN_OUTCOME" in
    max_turns)
      echo "  Re-run with more room:  SPRINTBIAS_AUDIT_MAX_TURNS=60 ./sprint.sh deps $TASK_FILE" ;;
    no_start)
      echo "  Confirm the '$SPRINTBIAS_CLI' CLI is installed and authenticated, then re-run." ;;
    *)
      echo "  Inspect $LOG_FILE, then re-run:  ./sprint.sh deps $TASK_FILE" ;;
  esac
  exit 1
fi

VERDICT=$(printf '%s' "$SPRINTBIAS_RUN_VERDICT_TEXT" | sprintbias_parse_verdict 'FILED|CLEAN')
[ -z "$VERDICT" ] && VERDICT="UNCLEAR"

case "$VERDICT" in
  FILED|CLEAN)
    echo "✓ Dependency audit complete ($VERDICT): $TASK_FILE"
    exit 0
    ;;
  *)
    echo "? Dependency audit finished but its final line held no VERDICT token."
    echo "  It ran to completion — a formatting slip, not a crash."
    echo "  The task with raw source data is still filed: $TASK_FILE"
    echo "  Full log: $LOG_FILE"
    exit 1
    ;;
esac
