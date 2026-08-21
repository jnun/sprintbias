# shellcheck shell=bash
# docs/sprintbias/lib.sh — shared helper library for SprintBias scripts
# Sourced (not executed) — no shebang or set -euo pipefail; the caller provides those.
#
# Source this once at the top of any script that needs config or AI access:
#
#     source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib.sh"
#
# Provides:
#   Colours: RED GREEN YELLOW BLUE CYAN DIM BOLD NC
#   sed_escape STRING          — escape special chars for sed replacement
#   sed_inplace ARGS...        — portable in-place sed (macOS + Linux)
#   move_file SRC DEST         — git mv SRC DEST || mv SRC DEST (lifecycle rule)
#   sprintbias_move_rule         — one-line move rule for AI prompts (same behavior)
#   run_with_timeout SECS CMD… — portable timeout (coreutils, gtimeout, or shell)
#   run_with_timeout_dots SECS CMD… — same, with progress dots on the TTY while waiting
#   _sprintbias_heartbeat_start / _stop — tick dots on the TTY during a quiet,
#                                output-captured run so it never looks hung
#   kebab_case STRING          — lowercase, hyphenated slug
#   sprintbias_slug NAME [MAX]    — kebab_case + length cap + empty guard (returns 1)
#   sprintbias_cfg KEY            — read a value: config.local overrides config
#   sprintbias_cfg_set KEY VALUE  — update or append a value in the tracked config
#   sprintbias_resolve_model SFX  — model resolution: env > config > default;
#       provider-foreign ids remapped (opus on grok → grok-4.5, etc.)
#   sprintbias_coerce_model MODEL — remap Claude/Grok-only ids for active tier
#   sprintbias_tier_model SFX     — resolve + strong default on
#       claude-code (opus) and grok-build (grok-4.5) when config is empty
#   sprintbias_profile_line       — one-line pointer to project.md (empty if absent)
#   sprintbias_conversation_method — contents of ai/conversation.md (loud fail if missing)
#   sprintbias_next_blocked_resolution — prompt: dependent in next/ held on task in blocked/
#       (two-path choice, demote inline for B, hand off to chat for A). Shared
#       by chat-sprint.sh and the chat-next folder walk so the logic is written once.
#   sprintbias_find_task ID [dirs…] — resolve a task file by numeric ID
#   sprintbias_task_stage ID        — lifecycle stage folder name (or empty)
#   sprintbias_task_path ID         — path to the task file (or empty)
#   sprintbias_review_verdict FILE — READY/BLOCKED/COMPLETE stamp from a gate review
#   sprintbias_open_questions / sprintbias_has_open_questions FILE
#   sprintbias_set_review_status FILE STATUS — rewrite stamp in last ## Questions
#   sprintbias_accept_suggestions FILE — fold (Suggestion: …) into Notes; clear Qs
#   sprintbias_demote_open_questions FILE [BLOCKED_DIR] — READY+openQ → blocked/
#   sprintbias_sweep_ready_open_questions [NEXT] [BLOCKED] — bulk demote next/
#   sprintbias_log_path KIND NAME — timestamped log path under docs/tmp
#   sprintbias_load_profile [cli] — source the provider profile (sprintbias_provider_exec)
#   sprintbias_ai_tier            — capability tier: claude-code|grok-build|cursor|openai|generic
#   sprintbias_ai_mode            — "emit" or "exec" for the current environment
#   sprintbias_orchestration_capable — true for tiers with emit subagent fan-out
#       (claude-code, grok-build)
#   sprintbias_subagent_type_for ROLE — Grok subagent_type per role (single seam;
#       work|gate|polish|chain → general-purpose today)
#   sprintbias_subagent_tool_name — "Task tool" | "spawn_subagent" for prompt wording
#   sprintbias_subagent_spawn_phrase [purpose] [role] — "Launch a NEW subagent …" fragment
#   sprintbias_subagent_own_fresh [role] — "its OWN fresh subagent (…)" fragment
#   sprintbias_subagent_parallel_dispatch [role] — parallel fan-out instruction line
#   sprintbias_subagent_no_nest   — "you are a worker, do NOT re-spawn" worker line
#   sprintbias_emitted            — true if the last sprintbias_run only emitted a prompt
#   sprintbias_announce_provider  — once per process: ▸ Provider: cli (tier) · mode: …
#   sprintbias_run ARGS…          — run AI: emit prompt to stdout, or exec the CLI
#   sprintbias_interactive_ok     — true if a live session is possible (exec mode,
#       interactive-capable provider, real TTY) — one source of truth
#   sprintbias_tty                — real pty slave path (/dev/ttysNN or /dev/pts/N)
#       for interactive CLI handoffs; falls back to /dev/tty
#   sprintbias_run_interactive A… — like sprintbias_run, but the exec path is a live
#       back-and-forth session (inherits the terminal) instead of one-shot
#   sprintbias_change_manifest TASK_FILE [FILE…] — build audit change manifest;
#       sets SPRINTBIAS_CHANGED_FILES and SPRINTBIAS_CONTEXT_SOURCE
#   sprintbias_parse_verdict TOKENS — (stdin) last VERDICT token, case/format tolerant
#   sprintbias_extract_summary JSON — print the summary text from a CLI JSON log
#   Dependency-graph helpers (pure, unit-testable — no AI):
#     SPRINTBIAS_OPEN_STAGES        — stages still holding incomplete work
#     sprintbias_stage_is_open STAGE — 0 when STAGE is an open (incomplete) stage
#     sprintbias_reverse_edge_value FILE — Dependents value (legacy Blocks fallback)
#     sprintbias_fold_target FILE   — id a task was folded into, or empty
#     sprintbias_classify_dep ID [MISSING_AS] — one token:
#         review|done|doing|next|backlog|blocked|folded|missing (policy knob)
#     sprintbias_dependents_of ID   — ids that depend on ID (forward + reverse edges)
#     sprintbias_rewrite_dep_id FROM TO — fold FROM→TO across Depends on/Dependents/
#         Blocks on every task; leave a fold note on FROM's kept file
#     sprintbias_ensure_reciprocal DEP DEPENDENT — ensure DEP lists DEPENDENT back
#   Plan-membership reverse index (plan file is authority; task **Plan** mirrors):
#     sprintbias_plan_member_ids PLAN_FILE — member task ids, one per line
#     sprintbias_primary_plan_of ID — the task's single primary (lowest) plan id
#     sprintbias_set_task_plan FILE VALUE — write the **Plan** field (none|id)
#     sprintbias_reconcile_task_plan ID — refresh one task's **Plan** from the plans
#     sprintbias_plan_index_drift [--fix] — report/repair Plan drift both ways
#     sprintbias_find_plan ID — path to docs/plans/ID-*.md or fail
#     sprintbias_list_plans — one line per plan: id, title, [STATUS], done/total

_SPRINTBIAS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Colours ──────────────────────────────────────────────────────────
# Honour NO_COLOR by blanking the codes. Consumed by sourcing scripts.
# shellcheck disable=SC2034
if [ -n "${NO_COLOR:-}" ]; then
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' DIM='' BOLD='' NC=''
else
    RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
    BLUE=$'\033[0;34m'; CYAN=$'\033[0;36m'; DIM=$'\033[2m'
    BOLD=$'\033[1m';   NC=$'\033[0m'
fi

# ── Shell utilities ──────────────────────────────────────────────────

sed_escape() {
    printf '%s' "$1" | sed 's;[&/\\];\\&;g'
}

# Detect GNU vs BSD sed once per invocation — `sed --version` is a subprocess
# and sed_inplace runs in hot loops (config writes, task rewrites).
_SPRINTBIAS_SED_GNU=""
sed_inplace() {
    if [ -z "$_SPRINTBIAS_SED_GNU" ]; then
        if sed --version 2>/dev/null | grep -q GNU; then
            _SPRINTBIAS_SED_GNU=1
        else
            _SPRINTBIAS_SED_GNU=0
        fi
    fi
    if [ "$_SPRINTBIAS_SED_GNU" = 1 ]; then
        sed -i "$@"
    else
        sed -i '' "$@"
    fi
}

# Lifecycle move rule (agents + shell share this):
#   git mv SRC DEST || mv SRC DEST
# Always try git mv first (preserves history when tracked). When it fails —
# usual for new tasks not yet committed — finish the same move with plain mv.
move_file() {
    git mv "$1" "$2" 2>/dev/null || mv "$1" "$2"
}

# One-line rule for AI system prompts that tell a model to move task files.
# Same behavior as move_file. Include this string once; show concrete
# `git mv … || mv …` lines for each destination.
sprintbias_move_rule() {
    printf '%s' "Always move task files with: git mv SRC DEST || mv SRC DEST. Run git mv first (preserves history when tracked). When git mv fails — usual for new tasks not yet committed — finish that same move with plain mv, then continue. Leave git commit to the developer unless they asked you to commit."
}

# Portable timeout: run_with_timeout SECONDS CMD [ARGS…]
# For external programs, prefer GNU coreutils `timeout` (or `gtimeout` on
# macOS). Neither can exec a *shell function* — they only run programs on
# PATH — so when the target is a function (e.g. sprintbias_run) we always take
# the shell-watchdog path, which backgrounds the function and kills it on
# expiry. This keeps the timeout guarantee everywhere without export -f /
# bash -c gymnastics. Returns the command's exit code.
run_with_timeout() {
    local secs="$1"; shift
    if [ "$(type -t "${1:-}")" != "function" ]; then
        if command -v timeout >/dev/null 2>&1; then
            timeout "${secs}s" "$@"; return $?
        elif command -v gtimeout >/dev/null 2>&1; then
            gtimeout "${secs}s" "$@"; return $?
        fi
    fi
    # Shell watchdog: handles shell functions and hosts without coreutils.
    # disown the watcher so bash doesn't print a "Terminated" job-control
    # notice when we kill it after the command finishes ahead of the timeout.
    "$@" &
    local pid=$!
    { sleep "$secs" && kill "$pid" 2>/dev/null; } &
    local watcher=$!
    disown "$watcher" 2>/dev/null
    wait "$pid" 2>/dev/null
    local ret=$?
    kill "$watcher" 2>/dev/null
    pkill -P "$watcher" 2>/dev/null
    return $ret
}

# run_with_timeout_dots SECONDS CMD [ARGS…]
# Same timeout contract as run_with_timeout, plus a simple progress ticker so
# long headless AI calls (chat backlog verdicts, etc.) do not look hung.
# Dots go to /dev/tty (or stderr) so they stay visible under
#   out=$(run_with_timeout_dots …)
# Command stdout is captured and replayed on this function's stdout when the
# command finishes — callers still parse the real result. Command stderr is
# discarded during the wait (triage callers already silenced it); banners that
# write /dev/tty (sprintbias_announce_provider) still show.
run_with_timeout_dots() {
    local secs="$1"; shift
    local tmp pid ret n=0 out
    # We own the ticker for this call — suppress any provider-level heartbeat
    # nested inside "$@" so dots never double up. `local` scopes the claim to
    # this call and is inherited by the backgrounded subshell that runs "$@".
    local _SPRINTBIAS_HEARTBEAT_ON=1

    tmp=$(mktemp "${TMPDIR:-/tmp}/sprintbias-wait.XXXXXX") || return 1

    run_with_timeout "$secs" "$@" >"$tmp" 2>/dev/null &
    pid=$!

    out=/dev/tty
    if ! { true >"$out"; } 2>/dev/null; then
        out=/dev/stderr
    fi

    while kill -0 "$pid" 2>/dev/null; do
        # Plain dots, wrapping so they "cross" the terminal over long waits.
        printf '.' >"$out" 2>/dev/null || true
        n=$((n + 1))
        if [ $((n % 48)) -eq 0 ]; then
            printf '\n' >"$out" 2>/dev/null || true
        fi
        sleep 1
    done
    wait "$pid" 2>/dev/null
    ret=$?

    if [ "$n" -gt 0 ]; then
        printf '\n' >"$out" 2>/dev/null || true
    fi

    cat "$tmp"
    rm -f "$tmp"
    return "$ret"
}

# ── Progress heartbeat ───────────────────────────────────────────────
# A headless AI run that captures its own stdout/stderr leaves the terminal
# silent, so a multi-minute pass looks hung. These two helpers tick dots on
# the TTY while such a run is in flight, then close the line. Unlike
# run_with_timeout_dots (which owns the command), these bracket a call the
# provider already runs in the foreground: _start backgrounds a ticker,
# _stop kills it. Both are no-ops when there is no terminal to draw on
# (output captured, piped, or CI) and when a heartbeat is already running
# (an outer run_with_timeout_dots owns the line) so dots never double up.
# Pace with SPRINTBIAS_HEARTBEAT_SECS (default 2). Pair every _start with _stop.
_SPRINTBIAS_HEARTBEAT_PID=""
_sprintbias_heartbeat_start() {
    _SPRINTBIAS_HEARTBEAT_PID=""
    # Skip if an outer ticker already owns the line, or there is no TTY.
    [ -z "${_SPRINTBIAS_HEARTBEAT_ON:-}" ] || return 0
    { true >/dev/tty; } 2>/dev/null || return 0
    _SPRINTBIAS_HEARTBEAT_ON=1
    ( trap 'exit 0' TERM
      n=0
      while :; do
          sleep "${SPRINTBIAS_HEARTBEAT_SECS:-2}"
          printf '.' >/dev/tty 2>/dev/null || exit 0
          n=$((n + 1))
          [ $((n % 48)) -eq 0 ] && printf '\n' >/dev/tty 2>/dev/null
      done ) &
    _SPRINTBIAS_HEARTBEAT_PID=$!
    # disown so bash prints no "Terminated" job notice when we kill it.
    disown "$_SPRINTBIAS_HEARTBEAT_PID" 2>/dev/null || true
}
_sprintbias_heartbeat_stop() {
    if [ -n "${_SPRINTBIAS_HEARTBEAT_PID:-}" ]; then
        kill "$_SPRINTBIAS_HEARTBEAT_PID" 2>/dev/null || true
        _SPRINTBIAS_HEARTBEAT_PID=""
        # Close the dotted line so the next banner/result starts clean.
        { printf '\n' >/dev/tty; } 2>/dev/null || true
    fi
    unset _SPRINTBIAS_HEARTBEAT_ON 2>/dev/null || true
}

# kebab_case "Some Title!" -> "some-title"
kebab_case() {
    printf '%s' "$1" \
        | tr '[:upper:]' '[:lower:]' \
        | sed 's/[^a-zA-Z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//'
}

# sprintbias_slug NAME [MAXLEN] -> a filename-safe slug for NAME.
# kebab-cases NAME, caps it to MAXLEN chars (default 50) and trims any trailing
# hyphen the cut leaves behind. Prints the slug on stdout; a truncation note
# goes to stderr so it never pollutes command-substitution capture. Returns 1
# with empty output when NAME has no slug-able characters (all symbols/unicode)
# so callers reject it instead of writing "NNN-.md" or a hidden ".md".
sprintbias_slug() {
    local name="$1" max="${2:-50}" slug
    slug="$(kebab_case "$name")"
    if [ "${#slug}" -gt "$max" ]; then
        slug="${slug:0:$max}"
        slug="${slug%-}"
        echo -e "${YELLOW}Note: Filename truncated to $max characters${NC}" >&2
    fi
    [ -n "$slug" ] || return 1
    printf '%s' "$slug"
}

SPRINTBIAS_CONFIG_FILE="${SPRINTBIAS_CONFIG_FILE:-${_SPRINTBIAS_LIB_DIR}/config}"
# Semi-permanent LOCAL overlay: same KEY=VALUE format, read with precedence
# OVER the tracked config, never shipped (ship.sh excludes it) and gitignored
# so a personal CLI/model pin never lands in the repo or the distribution.
# A key present here wins; present-but-empty (KEY=) deliberately clears the
# tracked value. Pins here are still below env vars and per-run --model. See
# DOCUMENTATION.md → Local config overlay.
SPRINTBIAS_CONFIG_LOCAL_FILE="${SPRINTBIAS_CONFIG_LOCAL_FILE:-${_SPRINTBIAS_LIB_DIR}/config.local}"

# ── Config reader ────────────────────────────────────────────────────
# Read KEY, preferring config.local over config. Prints the value (possibly
# empty) and returns 0 when KEY is present in FILE; returns 1 when absent so
# the caller can fall through to the next file.
_sprintbias_cfg_read_file() {
    local key="$1" file="$2"
    [ -f "$file" ] || return 1
    awk -F= -v k="$key" '
        !/^[[:space:]]*#/ && $1 == k { val = substr($0, length(k) + 2); found = 1 }
        END { if (found) { print val } else { exit 1 } }
    ' "$file"
}

# Reads KEY from the config, with config.local taking precedence. Returns an
# empty string if the key is absent from both (or neither file exists). A key
# written as `KEY=` in config.local overrides a non-empty tracked value with
# empty — the documented way to clear a shipped/tracked pin locally.
sprintbias_cfg() {
    local key="$1"
    _sprintbias_cfg_read_file "$key" "$SPRINTBIAS_CONFIG_LOCAL_FILE" && return 0
    _sprintbias_cfg_read_file "$key" "$SPRINTBIAS_CONFIG_FILE" && return 0
    return 0
}

# ── Config writer ────────────────────────────────────────────────────
# Updates a key in-place, or appends it if not present.
sprintbias_cfg_set() {
    local key="$1" value="$2"
    if [ ! -f "$SPRINTBIAS_CONFIG_FILE" ]; then
        echo "${key}=${value}" > "$SPRINTBIAS_CONFIG_FILE"
        return
    fi
    if grep -q "^${key}=" "$SPRINTBIAS_CONFIG_FILE"; then
        # Escape the replacement for a |-delimited sed s-command: a literal
        # |, &, or \ in the value would otherwise corrupt the substitution.
        local esc_value
        esc_value=$(printf '%s' "$value" | sed 's/[\\&|]/\\&/g')
        sed_inplace "s|^${key}=.*|${key}=${esc_value}|" "$SPRINTBIAS_CONFIG_FILE"
    else
        echo "${key}=${value}" >> "$SPRINTBIAS_CONFIG_FILE"
    fi
}

# ── Model resolver ───────────────────────────────────────────────────
# Usage: model=$(sprintbias_resolve_model WORK)
#
# Precedence, highest first:
#   env SPRINTBIAS_MODEL_<SUFFIX>  per-role, this-shell override
#   env SPRINTBIAS_MODEL_DEFAULT   per-run lever — what a spine command's
#                                --model <id> flag exports for one invocation
#   config MODEL_<SUFFIX>        per-role pin (config.local overrides config)
#   config MODEL_DEFAULT         global pin  (config.local overrides config)
#   empty                        CLI picks its own
# The two config reads go through sprintbias_cfg, so a semi-permanent local pin
# in docs/sprintbias/config.local wins over the tracked config at each key.
# Non-empty results are coerced for the active provider (see
# sprintbias_coerce_model) so a leftover MODEL_GATE=opus after switching to
# Grok never reaches the CLI as an unknown model id.
sprintbias_resolve_model() {
    local suffix="$1"
    local env_var="SPRINTBIAS_MODEL_${suffix}"
    local val=""

    # Per-role env var wins outright.
    if [ "${!env_var+set}" = "set" ]; then
        val="${!env_var}"
    # A single --model <id> on a spine command exports SPRINTBIAS_MODEL_DEFAULT so
    # one invocation pins every role it touches without editing config. It beats
    # config (a per-run choice should) but yields to an explicit per-role env.
    elif [ -n "${SPRINTBIAS_MODEL_DEFAULT:-}" ]; then
        val="$SPRINTBIAS_MODEL_DEFAULT"
    else
        # Config per-script model
        val=$(sprintbias_cfg "MODEL_${suffix}")
        if [ -z "$val" ]; then
            # Config global default
            val=$(sprintbias_cfg "MODEL_DEFAULT")
        fi
    fi

    sprintbias_coerce_model "$val"
}

# sprintbias_coerce_model MODEL
# Map a resolved model id onto something the active provider understands.
# Empty stays empty (caller / CLI may pick their own default). Claude-only
# aliases (opus, sonnet, haiku, claude-*) on grok-build → grok-4.5; Grok
# aliases (grok-*) on claude-code → opus. Warns once per process when a
# remap happens so the operator can clear stale MODEL_* pins in config.
sprintbias_coerce_model() {
    local model="$1" tier coerced=""
    if [ -z "$model" ]; then
        printf ''
        return 0
    fi
    tier="$(sprintbias_ai_tier)"
    case "$tier" in
        grok-build)
            case "$model" in
                opus|sonnet|haiku|OPUS|SONNET|HAIKU|claude*|Claude*|CLAUDE*)
                    coerced="grok-4.5"
                    ;;
            esac
            ;;
        claude-code)
            case "$model" in
                grok*|Grok*|GROK*)
                    coerced="opus"
                    ;;
            esac
            ;;
    esac
    if [ -n "$coerced" ]; then
        if [ -z "${_SPRINTBIAS_MODEL_COERCE_WARNED:-}" ]; then
            printf 'SprintBias: model %s is not valid for %s — using %s\n' \
                "$model" "$tier" "$coerced" >&2
            printf '  Clear stale MODEL_* pins in docs/sprintbias/config (or re-run setup).\n' >&2
            _SPRINTBIAS_MODEL_COERCE_WARNED=1
        fi
        printf '%s' "$coerced"
        return 0
    fi
    printf '%s' "$model"
}

# ── Tier-aware model resolver ────────────────────────────────────────
# Usage: model=$(sprintbias_tier_model FEATURE)
#
# Like sprintbias_resolve_model, but when nothing is configured (env/config both
# empty) and the provider tier supports model selection, fall back to a strong
# default instead of letting the CLI pick a cheaper one. For interactive,
# reasoning-heavy flows — feature Q&A, idea Feynman, chat — and for the work
# spine (gate / work / polish), the best model is worth it unless the user has
# pinned one.
#   claude-code → opus
#   grok-build  → grok-4.5 (re-verify with `grok models` if the product renames)
# Other tiers return empty (their default.sh passthrough would only warn).
# Provider-foreign pins are already remapped by sprintbias_resolve_model.
sprintbias_tier_model() {
    local suffix="$1" model
    model="$(sprintbias_resolve_model "$suffix")"
    if [ -z "$model" ]; then
        case "$(sprintbias_ai_tier)" in
            claude-code) model="opus" ;;
            grok-build)  model="grok-4.5" ;;
        esac
    fi
    printf '%s' "$model"
}

# ── Task helpers ─────────────────────────────────────────────────────

# Emit a "read project.md" line if a profile exists (else nothing).
# Always returns 0 so it is safe in `var=$(sprintbias_profile_line)` under set -e.
sprintbias_profile_line() {
    [ -f "docs/sprintbias/project.md" ] || return 0
    printf '%s' "
Also read docs/sprintbias/project.md for project-specific stack and conventions."
}

# Load the shared Conversation Method (docs/sprintbias/ai/conversation.md) for
# injection into interactive chat prompts. Prints the file body on stdout.
# Loud-fails (message on stderr, return 1) if the file is missing — callers that
# need the method must not continue without it. Walk-agnostic: same text for
# chat <id>, chat bugs [d], chat-sprint, and (later) chat plan.
sprintbias_conversation_method() {
    local f="$_SPRINTBIAS_LIB_DIR/ai/conversation.md"
    if [ ! -f "$f" ]; then
        echo -e "${RED}ERROR: Conversation Method missing: $f${NC}" >&2
        echo "Expected docs/sprintbias/ai/conversation.md (shipped with SprintBias)." >&2
        return 1
    fi
    cat "$f"
}

# ── Shared walkthrough: dependent in next/ held on an undefined task in blocked/ ──
# Lexicon: <D> is DEPENDENT (on hold) — not blocked. <B> is BLOCKED (needs a
# decision or clarification). The executor HOLDS <D> until every Depends-on
# prerequisite leaves blocked/ and reaches review/ or done/. Both the no-id
# sprint walk (chat-sprint.sh) and the folder walk (chat next) surface this
# edge the same way. Written once here so neither reimplements — and drifts
# from — the other.
#
# Emits the prompt block that tells the conversational layer how to walk ONE such
# edge: present the two real paths as a choice, action Path B (demote) inline,
# hand Path A (define the dependency) off to chat's fresh-context chain, and gate
# the drop path behind an on-the-spot edge audit. Path A's hand-off mirrors
# chat.sh's own emit-vs-exec split: an emit-mode orchestration-capable session
# (claude-code / grok-build) can spawn a fresh subagent; every other environment
# prints the command to run in a fresh window. Always returns 0 so it is safe
# in `x=$(sprintbias_next_blocked_resolution)`.
sprintbias_next_blocked_resolution() {
    local path_a
    if [ "$(sprintbias_ai_mode)" = "emit" ] && sprintbias_orchestration_capable; then
        path_a="Hand this off to a FRESH context — do NOT resolve the dependency inline here. $(sprintbias_subagent_spawn_phrase "the dependency that needs a decision (in blocked/)" chain), aimed at the MOST-UPSTREAM one first (the dependency whose own '**Depends on**' has no unresolved blocked deps left; break ties by lowest id). Its entire instruction: 'Run ./sprint.sh chat <dep-id> and carry that task as far toward READY as you can on your own — read any *Context from chat* note in its file, refine it, and for each answered question convert the answer into body instruction and delete the question; leave only still-open questions under ### Questions for the developer and report those back.' Tell the user you spun up a fresh agent for <dep-id> and say in one line what it is picking up."
    else
        path_a="Hand this off — do NOT resolve the dependency inline here. Tell the user the exact command to run in a FRESH window:  ./sprint.sh chat <dep-id>  (for the most-upstream dependency still in blocked/). Keeping each session's context small is the point of chaining out."
    fi
    printf '%s' "─── DEPENDENT ON HOLD: <D> in next/ depends on <B> still in blocked/ ───
Lexicon: <D> is DEPENDENT (on hold until its prerequisite is done) — not blocked. <B> is BLOCKED (a decision or clarification is needed on <B>). The executor ('work') HOLDS <D> in next/ until every '**Depends on**' prerequisite reaches review/ or done/. Do not merely report this — close the loop. Present the TWO REAL paths as an explicit choice and act on the one the user picks. Do NOT frame 'drop the Depends on line' as a way out of a genuine prerequisite — that only makes <D> LOOK runnable while the work it needs is still undone (the folder-satisfaction trap).

PATH A — RESOLVE THE BLOCKED DEPENDENCY <B> (choose when the dependency is real and still needed):
${path_a}
Either way, chat's own close-the-loop branch re-enters the sprint only through the shared gate (bash docs/sprintbias/scripts/promote-to-sprint.sh <B-file>) — READY → next/, BLOCKED stays when a decision or clarification is still needed — which releases <D> from hold when gate grades READY. You do not rebuild that machinery here; you point at chat <B>.

PATH B — DEMOTE THE DEPENDENT TASK <D> BACK TO backlog/ (choose to pull it out of the sprint):
On the user's OK, action this INLINE: move <D> out of the sprint so next/ holds no work waiting on a task that still needs a decision —  git mv docs/tasks/next/<D-file> docs/tasks/backlog/<D-file> || mv docs/tasks/next/<D-file> docs/tasks/backlog/<D-file>. THEN RE-SCAN next/ for any OTHER task that also depends on <B>: the preflight already emitted a SEPARATE finding for each (next dependent, dep in blocked/) pair, so <B>'s other dependents are already in the findings list — recognize them by the same blocked id <B>, do not run a fresh board scan. Only when NONE remain may you say 'the sprint no longer contains work waiting on <B>.' If siblings remain, name them and offer to resolve each in turn (A or B).

THE DROP PATH — a metadata correction for a STALE or SPURIOUS edge ONLY, and only after an on-the-spot audit:
Dropping the '**Depends on**:' line is NOT one of the two resolution paths above. It is reserved for an edge that is not a genuine dependency. Before you may even offer it, AUDIT THE EDGE on the spot — a bounded, READ-ONLY reasoning step, NOT a gate pass: read WHY <D> needed <B> (what <D>'s Problem/Success actually required from <B>) and check whether that need is already satisfied elsewhere or has become obsolete. ONLY an edge that FAILS this audit (need already met / no longer needed) may be dropped from <D>'s Depends on line. An edge whose need still stands IS a real dependency: route to A or B, never drop. No audit, no drop."
}

# Resolve a task file by numeric ID. Prints "path<TAB>stage-dir" on success.
# Default search order matches the task lifecycle (open stages only).
sprintbias_find_task() {
    local id="$1"; shift
    local dirs=("$@")
    if [ ${#dirs[@]} -eq 0 ]; then
        dirs=(docs/tasks/blocked docs/tasks/backlog docs/tasks/next docs/tasks/doing)
    fi
    local dir match
    for dir in "${dirs[@]}"; do
        match=$(find "$dir" -maxdepth 1 -name "${id}-*.md" 2>/dev/null | head -1) || true
        if [ -n "$match" ]; then
            printf '%s\t%s' "$match" "$dir"
            return 0
        fi
    done
    return 1
}

# The task lifecycle folders, in order. One source of truth for every script
# that iterates stages (search, validate, check-alignment, sync, chat-sprint…).
# shellcheck disable=SC2034
SPRINTBIAS_STAGES=(backlog next doing blocked review "done")

# sprintbias_task_stage ID -> stage folder name (backlog|next|doing|blocked|review|done)
# or empty if no file matches. Scans every lifecycle folder.
sprintbias_task_stage() {
    local id="$1" stage match
    for stage in "${SPRINTBIAS_STAGES[@]}"; do
        match=$(find "docs/tasks/$stage" -maxdepth 1 -name "${id}-*.md" 2>/dev/null | head -1) || true
        if [ -n "$match" ]; then
            printf '%s' "$stage"
            return 0
        fi
    done
    return 1
}

# sprintbias_task_path ID -> absolute-or-relative path to the task file, or empty.
sprintbias_task_path() {
    local id="$1" stage match
    for stage in "${SPRINTBIAS_STAGES[@]}"; do
        match=$(find "docs/tasks/$stage" -maxdepth 1 -name "${id}-*.md" 2>/dev/null | head -1) || true
        if [ -n "$match" ]; then
            printf '%s' "$match"
            return 0
        fi
    done
    return 1
}

# Timestamped log path: sprintbias_log_path gate 42-fix-thing.md
sprintbias_log_path() {
    local kind="$1" name="$2"
    printf 'docs/tmp/log-%s-%s-%s.json' "$kind" "${name%.md}" "$(date +%Y%m%d-%H%M%S)"
}

# task_id "12-fix-auth.md" (or a full path) -> "12"
task_id() {
    local b="${1##*/}"
    printf '%s' "${b%%-*}"
}

# task_title FILE -> first "# " heading, without "# " or a "Task N: " prefix.
# Guards grep so a heading-less file yields empty (not a pipefail non-zero
# that would trip set -e in `x=$(task_title f)`).
task_title() {
    { grep -m1 '^# ' "$1" 2>/dev/null || true; } | sed 's/^# *//; s/^Task [0-9]*: *//'
}

# task_feature FILE -> value of the **Feature**: field (empty if absent).
# Same pipefail/set -e guard as task_title.
task_feature() {
    { grep -m1 '\*\*Feature\*\*:' "$1" 2>/dev/null || true; } | sed 's/.*\*\*Feature\*\*: *//'
}

# sprintbias_review_verdict FILE -> READY | BLOCKED | COMPLETE | "" (no verdict).
# Reads only the LAST "## Questions" section and requires the line-anchored
# bold stamp gate's review writes. A loose grep for "Status: BLOCKED"
# anywhere in the file once mis-routed a READY task to blocked/ because its
# body *quoted* the verdict vocabulary — this helper exists so no script
# ever parses the stamp loosely again.
# COMPLETE = work already in the codebase (moves to review/). Not the done/
# lifecycle folder. Legacy **Status: DONE** stamps normalize to COMPLETE.
sprintbias_review_verdict() {
    local v
    v=$(awk '/^## Questions[[:space:]]*$/{s=""; f=1} f{s=s $0 "\n"} END{printf "%s", s}' "$1" 2>/dev/null \
        | { grep -m1 -oE '^\*\*Status: (READY|BLOCKED|COMPLETE|DONE)\*\*' || true; } \
        | sed 's/\*//g; s/Status: //')
    [ "$v" = "DONE" ] && v="COMPLETE"
    printf '%s' "$v"
}

# sprintbias_open_questions FILE -> one plain line per still-open question (stdout).
# Sources (same convention as chat-sprint / gate):
#   (a) '### Questions for the developer' under ## Questions
#   (b) a strict inline "Open questions:" label in ## Notes
# Keeps top-level list items; drops resolved/answered/decided/settled/none
# sentinels — first word after the marker, or mid-line "— resolved" / "(resolved)".
# Empty output = all questions answered (turned into body instruction). Prefer
# fold-into-body + delete over mid-line markers; markers only prevent false holds.
sprintbias_open_questions() {
    local file="$1"
    {
        awk '
            /^### Questions for the developer[[:space:]]*$/ { cap=1; next }
            cap && /^(## |### )/ { cap=0 }
            cap { print }
        ' "$file"
        awk '
            /^[#>*[:space:]]*[Oo]pen [Qq]uestions?[[:space:]:*]*$/ { cap=1; next }
            cap && (/^[[:space:]]*$/ || /^(## |### )/) { cap=0 }
            cap { print }
        ' "$file"
    } 2>/dev/null \
        | grep -E '^([-*]|[0-9]+\.)[[:space:]]' \
        | grep -viE '^([-*]|[0-9]+\.)[[:space:]]+\**(resolved|answered|decided|settled|none)\b' \
        | grep -viE '(—|–|-)[[:space:]]*\**(resolved|answered|decided|settled)\b' \
        | grep -viE '\((resolved|answered|decided|settled)\)' \
        | sed -E 's/^([-*]|[0-9]+\.)[[:space:]]*//; s/\*\*//g; s/[[:space:]]+/ /g' \
        || true
}

# sprintbias_has_open_questions FILE -> exit 0 when a question still needs an
# answer. Open questions keep the task out of work and out of next/ until each
# answer is written as body instruction and the question is deleted.
sprintbias_has_open_questions() {
    local qs
    qs="$(sprintbias_open_questions "$1")"
    [ -n "$qs" ]
}

# sprintbias_set_review_status FILE STATUS
# Rewrite **Status: …** in the LAST ## Questions section (creates stamp line if
# the section exists without one). STATUS is READY | BLOCKED | COMPLETE.
sprintbias_set_review_status() {
    local file="$1" status="$2"
    [ -f "$file" ] || return 1
    case "$status" in
        READY|BLOCKED|COMPLETE) ;;
        *) return 1 ;;
    esac
    python3 - "$file" "$status" <<'PY' || return 1
import re, sys
path, status = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
parts = re.split(r"(?m)^(?=## Questions\s*$)", text)
if len(parts) < 2:
    sys.exit(1)
head, last = "".join(parts[:-1]), parts[-1]
stamp = f"**Status: {status}**"
if re.search(r"(?m)^\*\*Status: (READY|BLOCKED|COMPLETE|DONE)\*\*", last):
    last = re.sub(
        r"(?m)^\*\*Status: (READY|BLOCKED|COMPLETE|DONE)\*\*",
        stamp,
        last,
        count=1,
    )
else:
    # Insert stamp right after the ## Questions heading.
    last = re.sub(
        r"(?m)^(## Questions\s*\n)",
        r"\1\n" + stamp + "\n",
        last,
        count=1,
    )
open(path, "w", encoding="utf-8").write(head + last)
PY
}

# sprintbias_accept_suggestions FILE
# For each still-open question that carries (Suggestion: …), fold the suggestion
# into ## Notes as a settled decision line and delete the question. Questions
# without a suggestion stay. When the list is empty, write
# "None — task is fully defined." under ### Questions for the developer.
# Prints: settled=N remaining=M
# Exit 0 always when file exists (even if nothing settled).
sprintbias_accept_suggestions() {
    local file="$1"
    [ -f "$file" ] || return 1
    python3 - "$file" <<'PY'
import re, sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()

q_heads = list(re.finditer(r"(?m)^## Questions\s*$", text))
if not q_heads:
    print("settled=0 remaining=0")
    sys.exit(0)
qh_start = q_heads[-1].start()
# From last ## Questions to EOF (or keep rest of file after we splice)
tail = text[qh_start:]
dev = re.search(r"(?m)^### Questions for the developer\s*\n", tail)
if not dev:
    print("settled=0 remaining=0")
    sys.exit(0)
dev_body_rel = dev.end()
# End of developer-questions body: next ## / ### heading after the dev heading
rest_after_dev = tail[dev_body_rel:]
end_m = re.search(r"(?m)^(?:## |### )", rest_after_dev)
if end_m:
    body = rest_after_dev[: end_m.start()]
    after_body = rest_after_dev[end_m.start() :]
else:
    body = rest_after_dev
    after_body = ""

# Parse list items; join continuation lines (indented or non-marker non-blank).
raw_lines = body.splitlines()
items = []  # full multi-line strings without trailing newline
cur = None
for line in raw_lines:
    if re.match(r"^([-*]|[0-9]+\.)\s", line):
        if cur is not None:
            items.append(cur)
        cur = line
    elif cur is not None and line.strip() and not re.match(r"^(## |### )", line):
        cur += " " + line.strip()
    else:
        if cur is not None:
            items.append(cur)
            cur = None
if cur is not None:
    items.append(cur)

sug_re = re.compile(r"\(\s*Suggestion\s*:\s*(.+?)\)\s*$", re.IGNORECASE | re.DOTALL)
sug_re_any = re.compile(r"\(\s*Suggestion\s*:\s*(.+?)\)", re.IGNORECASE | re.DOTALL)

def is_sentinel(plain: str) -> bool:
    if re.match(r"(?i)^(resolved|answered|decided|settled|none)\b", plain):
        return True
    if re.search(r"(?i)(?:—|–|\-)\s*(resolved|answered|decided|settled)\b", plain):
        return True
    if re.search(r"(?i)\((resolved|answered|decided|settled)\)", plain):
        return True
    return False

settled = []
keep = []
for chunk in items:
    plain = re.sub(r"^([-*]|[0-9]+\.)\s*", "", chunk.strip())
    plain = re.sub(r"\*\*", "", plain)
    plain = re.sub(r"\s+", " ", plain).strip()
    if is_sentinel(plain):
        continue
    m = sug_re.search(chunk) or sug_re_any.search(chunk)
    if m:
        suggestion = re.sub(r"\s+", " ", m.group(1).strip())
        topic = sug_re_any.sub("", plain)
        topic = re.sub(r"\s+", " ", topic).strip(" ?.")
        if len(topic) > 120:
            topic = topic[:117] + "..."
        settled.append((topic, suggestion))
    else:
        keep.append(chunk.strip())

if keep:
    renum = []
    n = 1
    for k in keep:
        if re.match(r"^\d+\.\s", k):
            renum.append(re.sub(r"^\d+\.\s", f"{n}. ", k, count=1))
            n += 1
        else:
            renum.append(k)
    new_body = "\n".join(renum) + "\n"
else:
    new_body = "None — task is fully defined.\n"

new_tail = tail[:dev_body_rel] + new_body + after_body
text = text[:qh_start] + new_tail

if settled:
    notes_lines = ["- **Settled (accept suggestions):**"]
    for topic, sug in settled:
        notes_lines.append(f"  - {topic}: {sug}" if topic else f"  - {sug}")
    block = "\n".join(notes_lines) + "\n"
    nm = re.search(r"(?m)^## Notes\s*$", text)
    if nm:
        # Insert block at end of ## Notes (before next ## heading)
        notes_start = nm.end()
        rest = text[notes_start:]
        nxt = re.search(r"(?m)^## ", rest)
        if nxt:
            insert_at = notes_start + nxt.start()
            text = text[:insert_at].rstrip() + "\n\n" + block + "\n" + text[insert_at:]
        else:
            text = text.rstrip() + "\n\n" + block + "\n"
    else:
        q_heads = list(re.finditer(r"(?m)^## Questions\s*$", text))
        at = q_heads[-1].start() if q_heads else len(text)
        text = text[:at] + "## Notes\n\n" + block + "\n" + text[at:]

open(path, "w", encoding="utf-8").write(text)
print(f"settled={len(settled)} remaining={len(keep)}")
PY
}

# sprintbias_demote_open_questions FILE [BLOCKED_DIR]
# Invariant enforcer: READY/COMPLETE + still-open questions must not stay in
# next/. Rewrites stamp to BLOCKED, ensures a ## BLOCKED section, moves the
# file into BLOCKED_DIR (default docs/tasks/blocked). Loud report on stderr.
# Exit 0 if demoted, 1 if not applicable (no open Qs, or already blocked path
# without READY/COMPLETE stamp needing fix).
sprintbias_demote_open_questions() {
    local file="$1"
    local blocked_dir="${2:-docs/tasks/blocked}"
    local name id qs verdict dest
    [ -f "$file" ] || return 1
    sprintbias_has_open_questions "$file" || return 1
    verdict="$(sprintbias_review_verdict "$file")"
    name="$(basename "$file")"
    id="${name%%-*}"
    qs="$(sprintbias_open_questions "$file")"

    # Always fix stamp when open questions remain under READY/COMPLETE, or when
    # the file still lives under next/ with open questions (integrity bug).
    case "$verdict" in
        READY|COMPLETE|"")
            sprintbias_set_review_status "$file" "BLOCKED" || true
            ;;
    esac

    mkdir -p "$blocked_dir"
    dest="$blocked_dir/$name"
    # If already in blocked/, still rewrite stamp + ensure section; no move.
    if [ ! "$file" -ef "$dest" ] 2>/dev/null; then
        case "$file" in
            */next/*|*/doing/*)
                move_file "$file" "$dest"
                file="$dest"
                ;;
        esac
    fi

    # Ensure ## BLOCKED section (reuse gate helper if loaded; else local).
    if declare -F _sprintbias_gate_ensure_blocked_section >/dev/null 2>&1; then
        _sprintbias_gate_ensure_blocked_section "$file"
    elif ! grep -q '^## BLOCKED' "$file" 2>/dev/null; then
        {
            echo ""
            echo "## BLOCKED"
            echo ""
            echo "Open questions remain — cannot stay READY in next/."
            echo "Answer each, write the answer as instruction in the body,"
            echo "delete the question, then: ./sprint.sh settle $id  or  ./sprint.sh chat $id"
            echo "Or accept every (Suggestion: …) with: ./sprint.sh settle $id"
            echo ""
            echo "$qs" | sed 's/^/- /'
        } >> "$file"
    fi

    printf '⊘ %s: READY/COMPLETE + open questions — demoted to blocked/\n' "$id" >&2
    printf '  Open questions still pending:\n' >&2
    printf '%s\n' "$qs" | sed 's/^/    • /' >&2
    printf '  Fix:  ./sprint.sh settle %s   # accept all (Suggestion: …) and clear them\n' "$id" >&2
    printf '    or  ./sprint.sh chat %s     # answer with a human, fold into body\n' "$id" >&2
    printf '  Then re-enter: bash docs/sprintbias/scripts/promote-to-sprint.sh %s\n' "$file" >&2
    printf '  File: %s\n' "$file" >&2
    return 0
}

# sprintbias_sweep_ready_open_questions [NEXT_DIR] [BLOCKED_DIR]
# Scan next/ for READY/COMPLETE (or any) tasks that still have open questions;
# demote each. Prints a banner when any move. Exit 0. Sets
# SPRINTBIAS_SWEEP_DEMOTED to the count.
sprintbias_sweep_ready_open_questions() {
    local next_dir="${1:-docs/tasks/next}"
    local blocked_dir="${2:-docs/tasks/blocked}"
    local f n=0
    SPRINTBIAS_SWEEP_DEMOTED=0
    [ -d "$next_dir" ] || return 0
    for f in "$next_dir"/*.md; do
        [ -f "$f" ] || continue
        if sprintbias_has_open_questions "$f"; then
            if sprintbias_demote_open_questions "$f" "$blocked_dir"; then
                n=$((n + 1))
            fi
        fi
    done
    SPRINTBIAS_SWEEP_DEMOTED=$n
    if [ "$n" -gt 0 ]; then
        printf '\n▸ Integrity sweep: demoted %s next/ task(s) with open questions → blocked/\n' "$n" >&2
        printf '  A READY stamp with open questions is invalid — work will not run them.\n' >&2
        printf '  Bulk-clear suggested answers:  ./sprint.sh settle\n' >&2
        printf '  Or answer one task:            ./sprint.sh chat <id>\n\n' >&2
    fi
    return 0
}

# sprintbias_meta_value FILE FIELD -> value of '**FIELD**:' (empty if absent).
# FIELD is the label without asterisks, e.g. "Depends on" or "Dependents".
# Guards so a missing field never trips set -e under command substitution.
sprintbias_meta_value() {
    local file="$1" field="$2"
    { grep -m1 -iE "^[[:space:]]*\*\*${field}\*\*[[:space:]]*:" "$file" 2>/dev/null || true; } \
        | sed -E 's/^[^:]*:[[:space:]]*//'
}

# sprintbias_iter_id_list VALUE
# Parse a Depends-on / Dependents style value (comma/space list, N-M ranges).
# Emits one line per token:
#   id <N>     — a numeric task ID (ranges expand to one line each)
#   bad <tok>  — a non-numeric token that is not none/n/a/-
# Empty value, missing field, or whole-value 'none' / 'n/a' / '-' emits nothing.
# Shared by sprintbias_unmet_deps (queue gating) and validate-tasks.sh (integrity).
# Cycle detection among Depends-on edges is intentionally out of scope.
sprintbias_iter_id_list() {
    local raw="$1" tok lo hi n
    [ -z "$raw" ] && return 0
    case "$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')" in
        none*|n/a*|-*|'') return 0 ;;
    esac
    # Word-split is intentional: commas become spaces, then each token is
    # classified. Double commas / stray spaces yield empty tokens that skip.
    # Leading '#' is stripped so both "291" and "#291" (plan/chat prose style)
    # parse as the same task id.
    # shellcheck disable=SC2086
    for tok in $(printf '%s' "$raw" | tr ',' ' '); do
        [ -z "$tok" ] && continue
        tok="${tok#\#}"
        if [[ "$tok" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            lo="${BASH_REMATCH[1]}"; hi="${BASH_REMATCH[2]}"
            if [ "$lo" -gt "$hi" ]; then
                printf 'bad %s\n' "$tok"
                continue
            fi
            for ((n=lo; n<=hi; n++)); do
                printf 'id %s\n' "$n"
            done
        elif [[ "$tok" =~ ^[0-9]+$ ]]; then
            printf 'id %s\n' "$tok"
        else
            printf 'bad %s\n' "$tok"
        fi
    done
    return 0
}

# sprintbias_unmet_deps FILE -> prints the space-separated dependency task IDs that
# are NOT yet complete: those still sitting in backlog/, next/, doing/, or
# blocked/. Empty output means every declared dependency is complete (has reached
# review/ or done/) or none were declared — so the task is clear to run.
#
# Reads the '**Depends on**:' metadata field via sprintbias_iter_id_list. 'none',
# an empty value, or a missing field all mean no dependencies. An ID that
# resolves to no task file anywhere is treated as complete (the task finished
# and was archived), so a stale reference can never wedge a queue. Malformed
# tokens are ignored here (queue gating); validate-tasks.sh reports them.
# Lexicon: unmet deps put the task on hold (dependent) — they do not make it
# blocked. Self-clearing: as each dependency lands in review/, the dependent
# becomes runnable on the next pass with no human action.
sprintbias_unmet_deps() {
    local file="$1" raw id unmet=""
    raw=$(sprintbias_meta_value "$file" "Depends on")
    [ -z "$raw" ] && return 0
    while read -r kind tok; do
        [ "$kind" = "id" ] || continue
        id="$tok"
        if find docs/tasks/backlog docs/tasks/next docs/tasks/doing docs/tasks/blocked \
              -maxdepth 1 -name "${id}-*.md" 2>/dev/null | grep -q .; then
            unmet="$unmet $id"
        fi
    done <<EOF
$(sprintbias_iter_id_list "$raw")
EOF
    [ -n "$unmet" ] && printf '%s' "$unmet" | tr ' ' '\n' \
        | grep -E '^[0-9]+$' | sort -un | tr '\n' ' ' | sed 's/[[:space:]]*$//'
    return 0
}

# ── Dependency-graph helpers ─────────────────────────────────────────
# Shared primitives so work/chat/split stop inventing half-answers to the same
# three questions: what stage is a dep in, who depends on a task, and how do we
# rewrite edges when one id folds into another. Built on sprintbias_task_stage /
# sprintbias_task_path / sprintbias_meta_value / sprintbias_iter_id_list. Pure enough
# to unit-test without AI — they read and rewrite files under docs/tasks/ from
# the repo root, no network and no model. Call sites migrate in #329/#330; this
# task only lays the seam. Reverse-edge reads honour both the canonical
# **Dependents** and the legacy **Blocks** spelling (#327 pins the wording).

# Open lifecycle stages — the folders that still hold incomplete work. review/
# and done/ are complete. One source of truth so scripts stop copying the list
# (chat-sprint's local OPEN_STAGES migrates onto this in #329).
# shellcheck disable=SC2034
SPRINTBIAS_OPEN_STAGES=(backlog next doing blocked)

# sprintbias_stage_is_open STAGE -> 0 if the stage holds incomplete work.
sprintbias_stage_is_open() {
    local s
    for s in "${SPRINTBIAS_OPEN_STAGES[@]}"; do
        [ "$s" = "$1" ] && return 0
    done
    return 1
}

# sprintbias_reverse_edge_value FILE -> the reverse-dependency list value.
# Prefers the canonical **Dependents**; falls back to legacy **Blocks** for one
# compatibility window. Empty when neither field is set. Single reader so no
# script re-invents the Dependents←Blocks fallback (chat-sprint's reverse_edge).
sprintbias_reverse_edge_value() {
    local v
    v=$(sprintbias_meta_value "$1" "Dependents")
    [ -n "$v" ] && { printf '%s' "$v"; return 0; }
    sprintbias_meta_value "$1" "Blocks"
}

# sprintbias_fold_target FILE -> the id a task was folded into, or empty.
# Recognizes both fold-note shapes sprintbias_rewrite_dep_id may leave:
#   <!-- folded into #B YYYY-MM-DD -->   (kept-file marker)
#   **Folded into**: B                   (header form)
sprintbias_fold_target() {
    local file="$1" v
    [ -f "$file" ] || return 0
    v=$(sprintbias_meta_value "$file" "Folded into")
    if [ -z "$v" ]; then
        v=$( { grep -m1 -oE '<!-- *folded into #?[0-9]+' "$file" 2>/dev/null || true; } \
                | grep -oE '[0-9]+' | head -1 )
    fi
    v="${v#\#}"
    printf '%s' "$v"
}

# sprintbias_classify_dep ID [MISSING_AS] -> exactly one classification token:
#   review|done|doing|next|backlog|blocked  — the stage the file sits in
#   folded                                  — the file carries a fold marker
#   missing                                 — no file resolves anywhere
# A folded file reports `folded` regardless of the stage it still occupies, so a
# kept-but-folded task never masquerades as open work.
#
# Missing-id policy is deliberately unbaked (plan 15 open decision; #330 sets the
# default). When an id resolves to no file this prints MISSING_AS if given (or
# $SPRINTBIAS_DEP_MISSING_AS), else the literal `missing`. Pass `done` to adopt the
# archived-is-complete reading sprintbias_unmet_deps uses today.
sprintbias_classify_dep() {
    local id="$1" missing_as="${2:-${SPRINTBIAS_DEP_MISSING_AS:-missing}}"
    local stage path
    stage=$(sprintbias_task_stage "$id") || stage=""
    if [ -z "$stage" ]; then
        printf '%s' "$missing_as"
        return 0
    fi
    path=$(sprintbias_task_path "$id") || path=""
    if [ -n "$path" ] && [ -n "$(sprintbias_fold_target "$path")" ]; then
        printf 'folded'
        return 0
    fi
    printf '%s' "$stage"
    return 0
}

# sprintbias_dependents_of ID -> the task ids that depend on ID (its reverse
# edges), one per line, numeric-sorted and de-duped. Two sources, unioned:
#   • every task whose **Depends on** names ID (authoritative forward edge)
#   • ID's own **Dependents** / legacy **Blocks** field (declared reverse edge)
# Scans all lifecycle folders so an edge from an archived task still surfaces.
sprintbias_dependents_of() {
    local id="$1" stage f raw kind tok out="" self
    for stage in "${SPRINTBIAS_STAGES[@]}"; do
        for f in docs/tasks/"$stage"/*.md; do
            [ -e "$f" ] || continue
            raw=$(sprintbias_meta_value "$f" "Depends on")
            [ -z "$raw" ] && continue
            while read -r kind tok; do
                [ "$kind" = "id" ] || continue
                [ "$tok" = "$id" ] && out="$out $(task_id "$f")"
            done <<EOF
$(sprintbias_iter_id_list "$raw")
EOF
        done
    done
    self=$(sprintbias_task_path "$id") || self=""
    if [ -n "$self" ]; then
        raw=$(sprintbias_reverse_edge_value "$self")
        while read -r kind tok; do
            [ "$kind" = "id" ] && out="$out $tok"
        done <<EOF
$(sprintbias_iter_id_list "$raw")
EOF
    fi
    [ -n "$out" ] && printf '%s' "$out" | tr ' ' '\n' \
        | grep -E '^[0-9]+$' | sort -un
    return 0
}

# _sprintbias_rewrite_field FILE FIELD FROM TO
# When FILE's **FIELD** id-list names FROM, rewrite it to TO (drop FROM, keep the
# other ids in first-seen order, de-dup) and edit the line in place. Prints 0 and
# returns 0 when it changed the file, returns 1 otherwise. Range tokens (N-M)
# normalize to explicit ids — the honest cost of surgically breaking a folded id
# out of a range. Internal to the dep-graph rewrite helper.
_sprintbias_rewrite_field() {
    local file="$1" field="$2" from="$3" to="$4"
    local raw kind tok seen=" " ids="" changed=0 new
    raw=$(sprintbias_meta_value "$file" "$field")
    [ -z "$raw" ] && return 1
    case " $(sprintbias_iter_id_list "$raw" | awk '$1=="id"{print $2}' | tr '\n' ' ') " in
        *" $from "*) : ;;
        *) return 1 ;;
    esac
    while read -r kind tok; do
        [ "$kind" = "id" ] || continue
        if [ "$tok" = "$from" ]; then tok="$to"; changed=1; fi
        case "$seen" in *" $tok "*) continue ;; esac
        seen="$seen$tok "
        ids="$ids, $tok"
    done <<EOF
$(sprintbias_iter_id_list "$raw")
EOF
    [ "$changed" = 1 ] || return 1
    new="${ids#, }"
    [ -z "$new" ] && new="none"
    sed_inplace "s|^\([[:space:]]*\)\*\*${field}\*\*[[:space:]]*:.*|\1**${field}**: ${new}|" "$file"
    return 0
}

# sprintbias_rewrite_dep_id FROM TO
# Fold id FROM into TO across every open and archived task: rewrite each
# **Depends on** / **Dependents** / legacy **Blocks** line that names FROM so it
# names TO instead, and leave a one-line fold note on FROM's own file when it is
# kept (`<!-- folded into #TO YYYY-MM-DD -->`, idempotent). Prints one line per
# rewritten file so callers/tests can assert the reach. A positive API — the
# rebuild routes through sprintbias_iter_id_list, not a bag of sed against ids.
# Date comes from $SPRINTBIAS_TODAY when set (deterministic tests), else `date`.
sprintbias_rewrite_dep_id() {
    local from="$1" to="$2" stage f changed fromfile existing today
    [ -n "$from" ] && [ -n "$to" ] || {
        printf 'usage: sprintbias_rewrite_dep_id FROM TO\n' >&2; return 2; }
    for stage in "${SPRINTBIAS_STAGES[@]}"; do
        for f in docs/tasks/"$stage"/*.md; do
            [ -e "$f" ] || continue
            changed=0
            _sprintbias_rewrite_field "$f" "Depends on" "$from" "$to" && changed=1
            _sprintbias_rewrite_field "$f" "Dependents" "$from" "$to" && changed=1
            _sprintbias_rewrite_field "$f" "Blocks" "$from" "$to" && changed=1
            [ "$changed" = 1 ] && printf '%s\n' "$f"
        done
    done
    fromfile=$(sprintbias_task_path "$from") || fromfile=""
    if [ -n "$fromfile" ]; then
        existing=$(sprintbias_fold_target "$fromfile")
        if [ "$existing" != "$to" ]; then
            today="${SPRINTBIAS_TODAY:-$(date +%Y-%m-%d)}"
            printf '\n<!-- folded into #%s %s -->\n' "$to" "$today" >> "$fromfile"
        fi
    fi
    return 0
}

# _sprintbias_write_field FILE FIELD VALUE
# Set **FIELD**'s value in FILE. Rewrites the line in place when the field is
# present (preserving indentation); otherwise inserts "**FIELD**: VALUE" right
# after the **Depends on** line. Returns 1 when the field is absent and there is
# no **Depends on** anchor to insert after. FIELD is a plain label; VALUE is a
# trusted id-list or 'none'. Internal to sprintbias_ensure_reciprocal.
_sprintbias_write_field() {
    local file="$1" field="$2" value="$3" tmp
    if grep -qiE "^[[:space:]]*\*\*${field}\*\*[[:space:]]*:" "$file" 2>/dev/null; then
        sed_inplace "s|^\([[:space:]]*\)\*\*${field}\*\*[[:space:]]*:.*|\1**${field}**: ${value}|" "$file"
        return 0
    fi
    grep -qiE '^[[:space:]]*\*\*Depends on\*\*[[:space:]]*:' "$file" 2>/dev/null || return 1
    tmp=$(mktemp "${TMPDIR:-/tmp}/sprintbias-field.XXXXXX") || return 1
    awk -v f="$field" -v v="$value" '
        { print }
        !ins && $0 ~ /^[[:space:]]*\*\*Depends on\*\*[[:space:]]*:/ {
            match($0, /^[[:space:]]*/); ind=substr($0, 1, RLENGTH)
            print ind "**" f "**: " v
            ins=1
        }
    ' "$file" > "$tmp" && cat "$tmp" > "$file"
    rm -f "$tmp"
    return 0
}

# sprintbias_ensure_reciprocal DEP DEPENDENT
# Make "DEPENDENT depends on DEP" reciprocal: ensure DEP's reverse-edge field
# lists DEPENDENT. No-op when DEP has no file or already lists DEPENDENT. Writes
# to the canonical **Dependents** unless only the legacy **Blocks** is present.
# Prints DEP's file path when it changed it. Optional convenience — call sites
# stay on chat-sprint's inline check until #329 migrates them.
sprintbias_ensure_reciprocal() {
    local dep="$1" dependent="$2" depfile field raw kind tok new seen=" "
    depfile=$(sprintbias_task_path "$dep") || depfile=""
    [ -n "$depfile" ] || return 0
    field="Dependents"
    if [ -z "$(sprintbias_meta_value "$depfile" "Dependents")" ] \
       && [ -n "$(sprintbias_meta_value "$depfile" "Blocks")" ]; then
        field="Blocks"
    fi
    raw=$(sprintbias_reverse_edge_value "$depfile")
    while read -r kind tok; do
        [ "$kind" = "id" ] || continue
        [ "$tok" = "$dependent" ] && return 0
        case "$seen" in *" $tok "*) continue ;; esac
        seen="$seen$tok "
        new="${new:+$new, }$tok"
    done <<EOF
$(sprintbias_iter_id_list "$raw")
EOF
    new="${new:+$new, }$dependent"
    _sprintbias_write_field "$depfile" "$field" "$new" && printf '%s\n' "$depfile"
    return 0
}

# ── Plan-membership reverse index ────────────────────────────────────
# The plan FILE member list is the single authority for "who is in a plan"; the
# task **Plan** field is only a reverse index onto it. These helpers keep the
# two in sync without inventing a second membership algorithm: one reader over
# docs/plans/*.md decides membership, and the task field is rewritten to match
# — never the other direction. Locked (plan 15): a task carries ONE primary
# **Plan** id (the lowest-numbered plan that lists it); any extra memberships
# live only on the plan files. Migrate on touch — done/ is never mass-rewritten.

SPRINTBIAS_PLANS_DIR="${SPRINTBIAS_PLANS_DIR:-docs/plans}"

# sprintbias_plan_member_ids PLAN_FILE -> member task ids, one per line, de-duped
# in first-seen order. Reads the "- #ID — title" member lines (checkbox
# optional). Same extraction plan-start.sh uses to collect members, so the two
# never disagree on who a plan lists.
sprintbias_plan_member_ids() {
    local f="$1"
    [ -f "$f" ] || return 0
    { grep -oE '^- (\[[ xX]\] )?#[0-9]+' "$f" 2>/dev/null || true; } \
        | grep -oE '[0-9]+' | awk '!seen[$0]++'
}

# sprintbias_plan_file_id PLAN_FILE -> the numeric plan id from its filename.
sprintbias_plan_file_id() {
    local b="${1##*/}"
    printf '%s' "${b%%-*}"
}

# sprintbias_primary_plan_of TASK_ID -> the task's single primary plan id, or
# empty when no plan lists it. A task may appear on several plan files; the
# reverse index records only the LOWEST-numbered plan (locked decision). Scans
# docs/plans/*.md, skipping templates.
sprintbias_primary_plan_of() {
    local id="$1" f pid best="" mid
    for f in "$SPRINTBIAS_PLANS_DIR"/*.md; do
        [ -e "$f" ] || continue
        case "${f##*/}" in .TEMPLATE-*|TEMPLATE-*) continue ;; esac
        pid=$(sprintbias_plan_file_id "$f")
        [[ "$pid" =~ ^[0-9]+$ ]] || continue
        while IFS= read -r mid; do
            [ "$mid" = "$id" ] || continue
            if [ -z "$best" ] || [ "$pid" -lt "$best" ]; then best="$pid"; fi
            break
        done <<EOF
$(sprintbias_plan_member_ids "$f")
EOF
    done
    printf '%s' "$best"
}

# sprintbias_set_task_plan TASK_FILE VALUE -> set **Plan** to VALUE ('none' or a
# plan id). Rewrites the line in place when present (preserving indent); for an
# older task with no **Plan** field, inserts it after **Docs** (or **Created**).
# Prints the file path when it changed the value, nothing when already correct.
sprintbias_set_task_plan() {
    local file="$1" value="$2" cur tmp
    [ -f "$file" ] || return 0
    [ -n "$value" ] || value="none"
    cur=$(sprintbias_meta_value "$file" "Plan"); [ -n "$cur" ] || cur="none"
    [ "$cur" = "$value" ] && return 0
    if grep -qiE '^[[:space:]]*\*\*Plan\*\*[[:space:]]*:' "$file" 2>/dev/null; then
        sed_inplace "s|^\([[:space:]]*\)\*\*Plan\*\*[[:space:]]*:.*|\1**Plan**: ${value}|" "$file"
        printf '%s\n' "$file"
        return 0
    fi
    # No **Plan** field (pre-#327 task) — insert after **Docs**, else **Created**.
    local anchor="Docs"
    if ! grep -qiE '^[[:space:]]*\*\*Docs\*\*[[:space:]]*:' "$file" 2>/dev/null; then
        grep -qiE '^[[:space:]]*\*\*Created\*\*[[:space:]]*:' "$file" 2>/dev/null || return 1
        anchor="Created"
    fi
    tmp=$(mktemp "${TMPDIR:-/tmp}/sprintbias-plan.XXXXXX") || return 1
    awk -v v="$value" -v a="$anchor" '
        { print }
        !ins && $0 ~ ("^[[:space:]]*\\*\\*" a "\\*\\*[[:space:]]*:") {
            match($0, /^[[:space:]]*/); ind=substr($0, 1, RLENGTH)
            print ind "**Plan**: " v; ins=1
        }
    ' "$file" > "$tmp" && cat "$tmp" > "$file"
    rm -f "$tmp"
    printf '%s\n' "$file"
    return 0
}

# sprintbias_reconcile_task_plan TASK_ID -> derive the task's primary plan from the
# plan files (the authority) and write it onto the task's **Plan** field ('none'
# when no plan claims it). The one path that writes **Plan**. Skips done/ (no
# mass rewrite). Prints the file path when it changed the field.
sprintbias_reconcile_task_plan() {
    local id="$1" stage path primary
    stage=$(sprintbias_task_stage "$id") || stage=""
    [ -n "$stage" ] && [ "$stage" != "done" ] || return 0
    path=$(sprintbias_task_path "$id") || return 0
    [ -n "$path" ] || return 0
    primary=$(sprintbias_primary_plan_of "$id")
    sprintbias_set_task_plan "$path" "${primary:-none}"
}

# sprintbias_plan_index_drift [--fix] -> report every OPEN or review task whose
# **Plan** field disagrees with the plan files, one per line as
# "ID<TAB>field<TAB>computed". This catches drift both ways: a task that says
# Plan N when no plan lists it (removed member / stale id), and a task that says
# none (or a wrong id) when a plan does list it. With --fix each mismatch is
# rewritten to the computed primary. done/ is left untouched (migrate on touch).
sprintbias_plan_index_drift() {
    local fix=0; [ "${1:-}" = "--fix" ] && fix=1
    local stage f id cur primary
    for stage in backlog next doing blocked review; do
        for f in docs/tasks/"$stage"/*.md; do
            [ -e "$f" ] || continue
            case "${f##*/}" in .TEMPLATE-*|TEMPLATE-*) continue ;; esac
            id=$(task_id "$f")
            [[ "$id" =~ ^[0-9]+$ ]] || continue
            cur=$(sprintbias_meta_value "$f" "Plan"); [ -n "$cur" ] || cur="none"
            primary=$(sprintbias_primary_plan_of "$id"); [ -n "$primary" ] || primary="none"
            [ "$cur" = "$primary" ] && continue
            printf '%s\t%s\t%s\n' "$id" "$cur" "$primary"
            [ "$fix" -eq 1 ] && sprintbias_set_task_plan "$f" "$primary" >/dev/null
        done
    done
    return 0
}

# sprintbias_find_plan ID -> path to docs/plans/ID-*.md, or fail (return 1).
# Shared by plan start/done/think and chat plan so pickers never diverge.
sprintbias_find_plan() {
    local id="$1" match
    [[ "$id" =~ ^[0-9]+$ ]] || return 1
    match=$(find "$SPRINTBIAS_PLANS_DIR" -maxdepth 1 -name "${id}-*.md" 2>/dev/null | head -1) || true
    [ -n "$match" ] && printf '%s' "$match" && return 0
    return 1
}

# sprintbias_plan_member_rollup PLAN_FILE -> "done/total" counts from live folders.
sprintbias_plan_member_rollup() {
    local f="$1" mid stage done=0 total=0
    [ -f "$f" ] || { printf '0/0'; return 0; }
    while IFS= read -r mid; do
        [ -n "$mid" ] || continue
        total=$((total + 1))
        stage=$(sprintbias_task_stage "$mid" 2>/dev/null || true)
        [ "$stage" = "done" ] && done=$((done + 1))
    done <<EOF
$(sprintbias_plan_member_ids "$f")
EOF
    printf '%s/%s' "$done" "$total"
}

# sprintbias_list_plans -> one line per plan for interactive pickers:
#   "  ID  Title  [STATUS]  done/total"
sprintbias_list_plans() {
    local f id title status rollup
    for f in "$SPRINTBIAS_PLANS_DIR"/*.md; do
        [ -f "$f" ] || continue
        case "${f##*/}" in .TEMPLATE-*|TEMPLATE-*) continue ;; esac
        id=$(sprintbias_plan_file_id "$f")
        [[ "$id" =~ ^[0-9]+$ ]] || continue
        title=$(grep -m1 '^# ' "$f" 2>/dev/null | sed 's/^# *//; s/^Plan [0-9]*: *//')
        status=$(grep -m1 -E '^\*\*Status:\*\*' "$f" 2>/dev/null \
            | sed 's/.*\*\*Status:\*\*[[:space:]]*//' | tr -d '[:space:]')
        [ -n "$status" ] || status="(no status)"
        rollup=$(sprintbias_plan_member_rollup "$f")
        printf '  %s  %s  [%s]  %s done\n' "$id" "${title:-${f##*/}}" "$status" "$rollup"
    done
}

# ── DOC_STATE (ID allocation) and templates ──────────────────────────

SPRINTBIAS_DOC_STATE="${SPRINTBIAS_DOC_STATE:-docs/sprintbias/DOC_STATE.md}"

# alloc_id KEY [GLOB...] -> prints the next ID for "**KEY**: N".
# Reconciles the DOC_STATE counter with the numeric prefixes of files matched
# by GLOB(s), so a file created by hand (which never bumped the counter) can
# never hand back a colliding ID: next = max(counter, highest-on-disk) + 1.
# With no GLOB it behaves exactly as before (counter + 1). Returns 1 if the
# state file or a valid counter is missing (caller prints the error).
alloc_id() {
    local key="$1"; shift
    local state="$SPRINTBIAS_DOC_STATE" highest disk=0 glob f base n
    [ -f "$state" ] || return 1
    highest=$(grep "^\*\*${key}\*\*:" "$state" | sed 's/.*: *//' | tr -d '[:space:]')
    [[ "$highest" =~ ^[0-9]+$ ]] || return 1
    for glob in "$@"; do
        for f in $glob; do
            [ -e "$f" ] || continue
            base=${f##*/}; n=${base%%-*}
            [[ "$n" =~ ^[0-9]+$ ]] && (( n > disk )) && disk=$n
        done
    done
    (( disk > highest )) && highest=$disk
    printf '%s' "$((highest + 1))"
}

# bump_doc_state KEY VALUE [STATE] -> set "**KEY**: VALUE" (append if missing).
bump_doc_state() {
    local key="$1" value="$2" state="${3:-$SPRINTBIAS_DOC_STATE}"
    if grep -q "^\*\*${key}\*\*:" "$state" 2>/dev/null; then
        sed_inplace "s|^\*\*${key}\*\*:.*|**${key}**: ${value}|" "$state"
    else
        printf '**%s**: %s\n' "$key" "$value" >> "$state"
    fi
}

# copy_template SRC DEST -> validate SRC exists, mkdir DEST's dir, copy.
# Prints a precise error to stderr and returns 1 on any failure, distinguishing
# a missing template from an unwritable destination (read-only tree, permission
# denied) — callers only need `|| exit 1`, no error message of their own.
copy_template() {
    local src="$1" dest="$2"
    if [ ! -f "$src" ]; then
        echo -e "${RED}ERROR: Template file not found: $src${NC}" >&2
        return 1
    fi
    if ! mkdir -p "$(dirname "$dest")" 2>/dev/null; then
        echo -e "${RED}ERROR: Cannot create $(dirname "$dest") — read-only tree or permission denied${NC}" >&2
        return 1
    fi
    if ! cp "$src" "$dest" 2>/dev/null; then
        echo -e "${RED}ERROR: Cannot write $dest — read-only tree or permission denied${NC}" >&2
        return 1
    fi
}

# ── ID-allocation lock ───────────────────────────────────────────────
# Portable advisory mutex via mkdir (an atomic create-or-fail on every POSIX
# filesystem). Serializes the alloc_id → create-file → bump_doc_state sequence
# so two concurrent `newtask`/`newbug` runs never draw the same ID. Best-effort
# by design: a lock we cannot create (read-only tree) or one held too long (a
# crashed run) never hangs the command — we proceed unlocked rather than block
# forever. Auto-released via an EXIT trap. sprintbias_unlock is idempotent.
SPRINTBIAS_LOCK_DIR=""
sprintbias_lock() {
    local lockdir tries=0 stole=0
    lockdir="$(dirname "$SPRINTBIAS_DOC_STATE")/.sprint-alloc.lock"
    while ! mkdir "$lockdir" 2>/dev/null; do
        # A failed mkdir means "already held" only if the dir now exists;
        # otherwise the tree is unwritable — give up and proceed unlocked.
        [ -d "$lockdir" ] || return 0
        tries=$((tries + 1))
        if [ "$tries" -ge 50 ]; then           # ~5s held: assume a stale lock
            [ "$stole" = 1 ] && return 0        # already stole once — proceed
            rmdir "$lockdir" 2>/dev/null
            stole=1; tries=0
            continue
        fi
        sleep 0.1
    done
    SPRINTBIAS_LOCK_DIR="$lockdir"
    trap 'sprintbias_unlock' EXIT
    return 0
}

sprintbias_unlock() {
    [ -n "$SPRINTBIAS_LOCK_DIR" ] && rmdir "$SPRINTBIAS_LOCK_DIR" 2>/dev/null
    SPRINTBIAS_LOCK_DIR=""
}

# ── Provider profile loader ──────────────────────────────────────────
# Sources the provider profile that defines sprintbias_provider_exec().
# Profiles live in docs/sprintbias/cli/<provider>.sh.
sprintbias_load_profile() {
    local cli="${1:-$SPRINTBIAS_CLI}"
    SPRINTBIAS_CLI="$cli"

    local cli_dir="${_SPRINTBIAS_LIB_DIR}/cli"
    local profile="${cli_dir}/${cli}.sh"
    if [ -f "$profile" ]; then
        # shellcheck source=/dev/null
        source "$profile"
    else
        # shellcheck source=/dev/null
        source "${cli_dir}/default.sh"
    fi
}

# ── AI capability tier ───────────────────────────────────────────────
# Prints the provider capability tier this install runs at:
#   claude-code | grok-build | cursor | openai | generic
# Precedence: config/env PROVIDER (written by setup.sh) > inference from
# the CLI binary name. The inference mirrors setup.sh's picker so an install
# that upgrades without re-running the picker still resolves a sane tier.
# Later scripts branch on this: full orchestration (subagents, JSON output)
# on claude-code and grok-build; graceful degradation elsewhere. See the
# capability matrix in docs/sprintbias/ai/provider-capabilities.md.
sprintbias_ai_tier() {
    if [ -n "${SPRINTBIAS_PROVIDER:-}" ]; then
        printf '%s' "$SPRINTBIAS_PROVIDER"
        return
    fi
    case "$SPRINTBIAS_CLI" in
        claude)              printf 'claude-code' ;;
        grok)                printf 'grok-build' ;;
        cursor-agent|cursor) printf 'cursor' ;;
        codex)               printf 'openai' ;;
        *)                   printf 'generic' ;;
    esac
}

# ── Orchestration-capable tiers ──────────────────────────────────────
# True when emit mode can fan out via native subagents (one fresh worker per
# task). Claude Code uses the Task tool; Grok Build uses spawn_subagent.
# Every multi-task emit gate (work, gate, polish, chat chain, plan start,
# next→blocked) should call this instead of hard-coding a single tier name.
sprintbias_orchestration_capable() {
    case "$(sprintbias_ai_tier)" in
        claude-code|grok-build) return 0 ;;
        *) return 1 ;;
    esac
}

# ── Budget-capable tiers ─────────────────────────────────────────────
# True when the provider CLI can enforce a per-run USD spending cap, so a
# `--budget` argument means something to it. Today only Claude Code has a
# verified flag (`--max-budget-usd`); Grok Build and the generic tiers have
# none, so the cap is omitted at the call site rather than handed over and
# dropped. A provider that gains a real USD cap becomes capable by adding its
# tier to this case — no new branch at any call site. Every place that builds
# `--budget` (work, polish, deps) asks this instead of naming a provider.
sprintbias_budget_capable() {
    case "$(sprintbias_ai_tier)" in
        claude-code) return 0 ;;
        *) return 1 ;;
    esac
}

# Grok subagent_type for an orchestration ROLE. The single seam that decides
# which native worker type each fan-out spawns. Every role currently resolves to
# general-purpose and here is why: gate must Edit/Write the task file AND `git mv`
# it (shell), but no restricted capability_mode grants both (read-write = edits,
# no shell; execute = shell, no edits), so explore/read-write/execute all break
# the gate contract; work implements product code; polish and chain read and
# rewrite/define task files. A future specialization (e.g. polish → read-write)
# is a one-line change here, not edits across the four wording helpers.
# Roles: work | gate | polish | chain. Grok-only — Claude has no type names.
sprintbias_subagent_type_for() {
    case "$1" in
        work|gate|polish|chain) printf 'general-purpose' ;;
        *)                      printf 'general-purpose' ;;
    esac
}

# Short name of the subagent mechanism for prompt wording only.
sprintbias_subagent_tool_name() {
    case "$(sprintbias_ai_tier)" in
        grok-build) printf 'spawn_subagent' ;;
        *)          printf 'Task tool' ;;
    esac
}

# "Launch a NEW subagent …" fragment. Optional $1 = purpose phrase
# (e.g. "the blocked dependency", "<next-id>"). Optional $2 = role for the Grok
# subagent_type (default: chain — its only current caller is the chat handoff).
sprintbias_subagent_spawn_phrase() {
    local purpose="${1:-}" role="${2:-chain}"
    case "$(sprintbias_ai_tier)" in
        grok-build)
            local type; type="$(sprintbias_subagent_type_for "$role")"
            if [ -n "$purpose" ]; then
                printf 'Launch a NEW subagent via spawn_subagent (subagent_type: %s) for %s' "$type" "$purpose"
            else
                printf 'Launch a NEW subagent via spawn_subagent (subagent_type: %s)' "$type"
            fi
            ;;
        *)
            if [ -n "$purpose" ]; then
                printf 'Launch a NEW subagent (Task tool) for %s' "$purpose"
            else
                printf 'Launch a NEW subagent (Task tool)'
            fi
            ;;
    esac
}

# "its OWN fresh subagent (…)" — used by work / polish multi-task prompts.
# $1 = role for the Grok subagent_type (work | polish); default work. work and
# polish share this helper today (both general-purpose); pass the role so a
# future split — e.g. polish → read-write — lands in sprintbias_subagent_type_for.
sprintbias_subagent_own_fresh() {
    local role="${1:-work}"
    case "$(sprintbias_ai_tier)" in
        grok-build)
            printf 'its OWN fresh subagent (spawn_subagent, subagent_type: %s)' "$(sprintbias_subagent_type_for "$role")"
            ;;
        *)
            printf 'its OWN fresh subagent (Task tool)'
            ;;
    esac
}

# One-line parallel dispatch instruction for gate-lib and similar fan-outs.
# $1 = role for the Grok subagent_type; default gate — its only current caller.
sprintbias_subagent_parallel_dispatch() {
    local role="${1:-gate}"
    case "$(sprintbias_ai_tier)" in
        grok-build)
            printf 'Dispatch ONE subagent per task file below, ALL IN PARALLEL (issue every spawn_subagent call in a single message; subagent_type: %s).' "$(sprintbias_subagent_type_for "$role")"
            ;;
        *)
            printf 'Dispatch ONE subagent per task file below, ALL IN PARALLEL (issue every Task tool call in a single message).'
            ;;
    esac
}

# No-nesting rule for a SPAWNED worker's own instruction. The orchestrator owns
# fan-out; a worker that re-spawns fails because native nesting depth is one
# (Grok Build; Claude Task subagents likewise cannot launch further subagents).
# Tier-worded so Claude says "Task tool" and Grok says "spawn_subagent". Belongs
# only inside a worker's instruction string, never in a standalone/exec prompt.
sprintbias_subagent_no_nest() {
    case "$(sprintbias_ai_tier)" in
        grok-build)
            printf 'You are a worker, not an orchestrator: do the work yourself and do NOT call spawn_subagent — nesting depth is one, so a worker that re-spawns fails.'
            ;;
        *)
            printf 'You are a worker, not an orchestrator: do the work yourself and do NOT launch further subagents (Task tool).'
            ;;
    esac
}

# ── AI execution mode ────────────────────────────────────────────────
# emit — print the prompt to stdout for the surrounding agent to execute
#        (used when already inside an AI session, or no CLI is installed).
# exec — spawn the configured CLI binary (standalone terminal, loops, CI).
#
# Precedence: SPRINTBIAS_MODE env > config MODE > auto-detect.
# Auto-detect: a coding-agent session → emit; else exec if the CLI exists,
# otherwise emit as a last resort (better to show the prompt than to fail).
# Resolved once and cached: nothing this depends on (env, config, CLI
# presence) changes within a single invocation, and sprintbias_run calls this on
# every AI request — the uncached path spawns awk+tail (via sprintbias_cfg) each
# time, which is hot in the audit/triage/work loops.
_SPRINTBIAS_MODE_CACHE=""
sprintbias_ai_mode() {
    [ -n "$_SPRINTBIAS_MODE_CACHE" ] && { printf '%s' "$_SPRINTBIAS_MODE_CACHE"; return; }

    local m="${SPRINTBIAS_MODE:-$(sprintbias_cfg MODE)}"
    if [ -z "$m" ]; then
        # Agent-session env vars: Claude Code, Cursor, Grok Build (GROK_AGENT=1).
        # Only vars confirmed in real sessions — do not invent markers.
        if [ -n "${CLAUDECODE:-}" ] || [ -n "${CLAUDE_CODE_SESSION_ID:-}" ] \
           || [ -n "${CURSOR_TRACE_ID:-}" ] || [ -n "${CURSOR_SESSION_ID:-}" ] \
           || [ -n "${GROK_AGENT:-}" ] \
           || [ -n "${AI_AGENT:-}" ] || [ -n "${SPRINTBIAS_IN_AGENT:-}" ]; then
            m="emit"
        elif command -v "$SPRINTBIAS_CLI" >/dev/null 2>&1; then
            m="exec"
        else
            m="emit"
        fi
    fi
    _SPRINTBIAS_MODE_CACHE="$m"
    printf '%s' "$m"
}

SPRINTBIAS_LAST_MODE=""
sprintbias_emitted() { [ "$SPRINTBIAS_LAST_MODE" = "emit" ]; }

# Print the prompt (system prompt + user prompt + trailing positionals) for
# the surrounding agent to act on. Provider-only flags are consumed/ignored.
sprintbias_emit_prompt() {
    local prompt="" system_prompt=""
    local -a rest=()
    while [ $# -gt 0 ]; do
        case "$1" in
            -p)                     prompt="$2";        shift 2 ;;
            --append-system-prompt) system_prompt="$2"; shift 2 ;;
            --model|--max-turns|--tools|--permissions|--output-format|--budget|--name)
                                    shift 2 ;;
            --skip-permissions)     shift ;;
            --)                     shift; rest+=("$@"); break ;;
            *)                      rest+=("$1"); shift ;;
        esac
    done

    printf '%s\n' "── SprintBias: run the following in this session ──────────────"
    [ -n "$system_prompt" ] && printf '%s\n\n' "$system_prompt"
    [ -n "$prompt" ] && printf '%s\n' "$prompt"
    [ ${#rest[@]} -gt 0 ] && printf '%s\n' "${rest[*]}"
    printf '%s\n' "─────────────────────────────────────────────────────────────"
}

# sprintbias_announce_provider — one-line banner so a leading -g/-c, env override,
# or config default is obvious before a long silent headless CLI run.
# Prints once per process (multi-task work/polish only announce on the first
# AI call). Always writes stderr; if stderr is not a TTY (common when callers
# do `sprintbias_run … 2>/dev/null | tee log`), also writes /dev/tty so the
# human still sees the line without double-printing on a normal terminal.
sprintbias_announce_provider() {
    [ -n "${_SPRINTBIAS_PROVIDER_ANNOUNCED:-}" ] && return 0
    _SPRINTBIAS_PROVIDER_ANNOUNCED=1
    local cli tier mode line
    cli="${SPRINTBIAS_CLI:-?}"
    tier="$(sprintbias_ai_tier)"
    mode="$(sprintbias_ai_mode)"
    line=$(printf '▸ Provider: %s (%s) · mode: %s' "$cli" "$tier" "$mode")
    printf '%s\n' "$line" >&2
    if [ ! -t 2 ] && { true >/dev/tty; } 2>/dev/null; then
        printf '%s\n' "$line" >/dev/tty 2>/dev/null || true
    fi
}

# sprintbias_run — route an AI request to emit or exec based on the mode.
# Same argument surface as the provider profiles.
sprintbias_run() {
    sprintbias_announce_provider
    SPRINTBIAS_LAST_MODE="$(sprintbias_ai_mode)"
    if [ "$SPRINTBIAS_LAST_MODE" = "emit" ]; then
        sprintbias_emit_prompt "$@"
        return 0
    fi
    sprintbias_provider_exec "$@"
}

# sprintbias_stream_filter — render stream-json events as one readable line per
# step so a live run is visible on the terminal. Reads NDJSON on stdin (the
# provider-neutral stream-json contract) and prints:
#   -> tool_use    · assistant text    == result summary    ! non-JSON line
# Non-JSON lines (e.g. CLI errors on stderr) pass through prefixed with '!'.
# Shared by every command that streams a live run (work, plan think, …); the
# raw stream is captured upstream via `tee` before this filter, so log capture
# is independent of it. When python3 is absent, falls back to `cat` so the run
# still shows the raw stream rather than nothing.
sprintbias_stream_filter() {
    if command -v python3 >/dev/null 2>&1; then
        python3 -u -c '
import json, sys
def hint(inp):
    for k in ("file_path", "command", "pattern", "description", "path"):
        if inp.get(k):
            return " ".join(str(inp[k]).split())[:100]
    return ""
for line in sys.stdin:
    line = line.rstrip("\n")
    if not line:
        continue
    try:
        e = json.loads(line)
    except ValueError:
        print("  ! " + line)
        continue
    t = e.get("type")
    if t == "assistant":
        for b in e.get("message", {}).get("content", []):
            if b.get("type") == "tool_use":
                print("  -> %s %s" % (b.get("name", "?"), hint(b.get("input", {}))))
            elif b.get("type") == "text" and b.get("text", "").strip():
                txt = " ".join(b["text"].split())
                print("   · " + (txt[:200] + "..." if len(txt) > 200 else txt))
    elif t == "result":
        secs = int(e.get("duration_ms", 0) / 1000)
        print("  == %s: %s turns, %dm %02ds, $%.2f" % (
            e.get("subtype", "?"), e.get("num_turns", "?"),
            secs // 60, secs % 60, e.get("total_cost_usd") or 0))
' || cat
    else
        cat
    fi
}

# sprintbias_interactive_ok — true when a live back-and-forth session is actually
# possible right now. The single source of truth for that decision, consulted
# both by sprintbias_run_interactive (to route the run) and by callers like
# chat.sh (to decide whether to warn about a degraded single pass) — so the
# warning and the behaviour can never drift apart. All three conditions must
# hold:
#   1. exec mode        — in emit mode the surrounding agent is the session.
#   2. provider opt-in  — the loaded profile sets SPRINTBIAS_PROVIDER_INTERACTIVE=1
#                         and defines sprintbias_provider_interactive (claude does;
#                         others don't, so they degrade to one-shot).
#   3. a real terminal  — both stdin and stdout are TTYs; a REPL on a pipe or in
#                         CI would just block on input that never arrives.
# Adding interactive support to another provider is one line in its profile —
# no edits here or in callers.
sprintbias_interactive_ok() {
    [ "$(sprintbias_ai_mode)" = "exec" ]                        || return 1
    [ "${SPRINTBIAS_PROVIDER_INTERACTIVE:-0}" = 1 ]             || return 1
    declare -F sprintbias_provider_interactive >/dev/null 2>&1 || return 1
    [ -t 0 ] && [ -t 1 ]
}

# sprintbias_tty — real pty slave path for nested interactive CLI handoffs.
# Prints e.g. /dev/ttys009 (macOS) or /dev/pts/0 (Linux). Falls back to /dev/tty
# only when the real path cannot be resolved.
#
# Why this exists: Claude Code and Grok Build TUIs need stdin on the *actual*
# pty slave (lsof shows healthy sessions as `0u /dev/ttysNN`). Opening
# `<>/dev/tty` is read-write but still attaches device 2,0 — and both TUIs
# wedge after the first turn under that shape (task 335: O_RDONLY was
# necessary but not sufficient; the device path matters too). Callers that
# launch a nested interactive session from a menu (chat-folder [d], chat-bugs
# [d]) should open stdin with:  … <>"$(sprintbias_tty)"
sprintbias_tty() {
    local t
    if t=$(tty 2>/dev/null) && [ -n "$t" ] && [ -c "$t" ]; then
        printf '%s' "$t"
        return 0
    fi
    # stdin may already be non-tty (redirected or drained by an earlier
    # headless CLI). Resolve via this process's controlling terminal — ps
    # reports ttysNN / pts/N without the /dev/ prefix on macOS and Linux.
    t=$(ps -p $$ -o tty= 2>/dev/null | tr -d ' ')
    case "$t" in
        ""|\?) printf '%s' /dev/tty ;;
        /*)
            if [ -c "$t" ]; then printf '%s' "$t"
            else printf '%s' /dev/tty
            fi
            ;;
        *)
            if [ -c "/dev/$t" ]; then printf '%s' "/dev/$t"
            else printf '%s' /dev/tty
            fi
            ;;
    esac
}

# sprintbias_run_interactive — like sprintbias_run, but opens a LIVE conversation the
# user can reply to turn by turn instead of a one-shot run. Routing:
#   emit — identical to sprintbias_run. The surrounding agent already gives the
#          user an interactive session, so we just hand it the prompt to run.
#   exec — when sprintbias_interactive_ok, call sprintbias_provider_interactive, which
#          inherits the terminal (no stdout capture, no -p/JSON) so the CLI
#          stays in its REPL. Otherwise degrade to the one-shot exec path.
# Used by chat.sh — the one command that is a dialogue rather than a job.
sprintbias_run_interactive() {
    sprintbias_announce_provider
    SPRINTBIAS_LAST_MODE="$(sprintbias_ai_mode)"
    if [ "$SPRINTBIAS_LAST_MODE" = "emit" ]; then
        sprintbias_emit_prompt "$@"
        return 0
    fi
    if sprintbias_interactive_ok; then
        sprintbias_provider_interactive "$@"
    else
        sprintbias_provider_exec "$@"
    fi
}

# ── Audit helpers ────────────────────────────────────────────────────
# Shared by polish.sh code-audit and deep-judge modes. Extracted so a fix
# to the manifest priority chain or the summary parser lands in both.

# sprintbias_change_manifest TASK_FILE [EXPLICIT_FILE…]
# Build the change manifest an audit runs against. Priority:
#   AUDIT_MANIFEST env > explicit file list > task ## Completed > git diff.
# Pass TASK_FILE ("" if none) as the first arg and any explicit files after
# it; callers must keep the bash-3.2 empty-array guard when forwarding an
# array (sprintbias_change_manifest "$TASK_FILE" ${FILES[@]+"${FILES[@]}"}).
# Sets two output variables rather than printing (the result is multi-line
# and $(...) runs in a subshell):
#   SPRINTBIAS_CHANGED_FILES  — newline-separated changed-file list (may be empty)
#   SPRINTBIAS_CONTEXT_SOURCE — human label of where the list came from
# shellcheck disable=SC2034  # output vars, read by callers
sprintbias_change_manifest() {
    local task_file="$1"; shift
    local -a explicit=("$@")
    SPRINTBIAS_CHANGED_FILES=""
    SPRINTBIAS_CONTEXT_SOURCE=""

    # 1. Manifest file from work.sh (most reliable — exact before/after snapshot)
    if [ -n "${AUDIT_MANIFEST:-}" ] && [ -f "${AUDIT_MANIFEST}" ]; then
        SPRINTBIAS_CHANGED_FILES=$(grep -v '^$' "$AUDIT_MANIFEST" || true)
        SPRINTBIAS_CONTEXT_SOURCE="manifest from work.sh"

    # 2. Explicit file list from CLI args
    elif [ ${#explicit[@]} -gt 0 ]; then
        SPRINTBIAS_CHANGED_FILES=$(printf '%s\n' "${explicit[@]}")
        SPRINTBIAS_CONTEXT_SOURCE="explicit file list"

    # 3. Task file's ## Completed section
    elif [ -n "$task_file" ] && grep -q '^## Completed' "$task_file"; then
        local completed files_sub
        completed=$(sed -n '/^## Completed/,/^## /{ /^## /d; p; }' "$task_file")
        # Prefer the author's own "### Files changed" list — the positively
        # scoped answer to "what did this task touch." Scanning the whole
        # Completed prose misreads a path merely MENTIONED in passing (e.g. a
        # script named as out-of-scope) as a change; the explicit list can't.
        # Fall back to the full prose only when the subsection is absent
        # (older tasks that predate the convention).
        files_sub=$(printf '%s\n' "$completed" \
            | sed -n '/^### Files changed/,/^#/{ /^#/d; p; }')
        [ -n "$(printf '%s' "$files_sub" | tr -d '[:space:]')" ] && completed="$files_sub"
        SPRINTBIAS_CHANGED_FILES=$(printf '%s\n' "$completed" \
            | grep -oE '[a-zA-Z0-9_/./-]+\.[a-zA-Z]{1,5}' \
            | sort -u \
            | while read -r f; do [ -f "$f" ] && echo "$f"; done || true)
        SPRINTBIAS_CONTEXT_SOURCE="task ## Completed section"

    # 4. Fallback: git working tree diff
    else
        local staged
        SPRINTBIAS_CHANGED_FILES=$(git diff --name-only 2>/dev/null || true)
        staged=$(git diff --cached --name-only 2>/dev/null || true)
        SPRINTBIAS_CHANGED_FILES=$(printf '%s\n%s' "$SPRINTBIAS_CHANGED_FILES" "$staged" | sort -u | grep -v '^$' || true)
        SPRINTBIAS_CONTEXT_SOURCE="git working tree diff"
    fi
}

# ── Excellence judge — shared bits ───────────────────────────────────
# The excellence deep-judge (polish <id>, plan polish) has one home:
# polish-judge.sh. These two helpers are what its callers share so the guard and
# the rules live in exactly one place each.

# True when a task file already carries a judged ## Excellence section — the
# idempotency signal. A finished piece is judged once; a re-run skips it unless
# --force, so it never stacks a second section or re-files the same enhancements.
# polish-judge.sh enforces this per file; plan-polish.sh pre-filters members with
# it before it builds any prompt.
#
# Matches the exact '## Excellence' heading ONLY — an aborted run writes a
# '## Excellence (aborted — no verdict)' note that is deliberately NOT a judged
# section, so a plain re-run (after raising the turn budget) judges the task
# instead of skipping it as already done.
sprintbias_excellence_has_section() {
    grep -qE '^## Excellence$' "$1" 2>/dev/null
}

# The excellence judge's rules + verdict contract, as a prompt fragment. The
# single-piece judge (polish-judge.sh) inlines the full protocol directly; the
# plan-scoped orchestrator (plan-polish.sh) hands this compact fragment to each
# fan-out subagent so both paths state the same rules and the same VERDICT line
# every caller parses. The full method lives in docs/sprintbias/ai/audit-excellence.md.
sprintbias_excellence_rules() {
    cat <<'EOF'
Follow docs/sprintbias/ai/audit-excellence.md exactly. Your writes are exactly
two: a new backlog task (via ./sprint.sh newtask "<desc>") for each enhancement
you find, and an appended '## Excellence' section on the audited task file (date,
verdict, tasks filed, and your Summary). Everything else is read-only here — the
task's Success criteria, its ## Completed section, its folder, and all product
code — so an enhancement is filed, never built, and the task is never reopened.
Judge the finished work against the higher bar; the code is presumed correct.
End with: VERDICT: EXCELLENT | FILED — <n> enhancement task(s) | BLOCKER — <reason>.
EOF
}

# sprintbias_parse_verdict TOKENS  (reads stdin) -> print the last verdict token.
# TOKENS is a |-separated list of accepted UPPERCASE tokens, e.g.
#   printf '%s' "$OUTPUT" | sprintbias_parse_verdict 'PASS|FIXED|FAIL|BLOCKED'
# The audit scripts pin the verdict to a "VERDICT: <TOKEN>" last line, but a
# model that writes "Verdict — pass" or "**VERDICT: PASS**" would silently
# degrade to UNCLEAR under an exact-uppercase grep. This tolerates case, any
# run of whitespace/punctuation between VERDICT and the token (colon, em/en
# dash, hyphen), and surrounding markdown emphasis. Returns the matched token
# uppercased, or nothing (caller maps empty -> UNCLEAR). Always exits 0 so it
# is safe under set -e in a command substitution.
sprintbias_parse_verdict() {
    local tokens="$1"
    grep -oiE "VERDICT[[:space:][:punct:]]*($tokens)" \
        | tail -1 \
        | grep -oiE "($tokens)" \
        | tr '[:lower:]' '[:upper:]' \
        || true
}

# sprintbias_extract_summary JSON_LOG_FILE -> print the audit summary text.
# Prefers a "## Summary" section; else the 30 lines before a VERDICT: line
# (a strict superset that only fires when ## Summary is absent — the normal
# path is byte-identical for both audits); else the tail of the result.
# Always prints something so callers under set -e never trip.
sprintbias_extract_summary() {
    local json_file="$1"
    python3 -c "
import json, sys, re
try:
    data = json.load(open(sys.argv[1]))
    text = data.get('result', '')
    # Try ## Summary section first
    m = re.search(r'## Summary\n(.*?)(?=\nVERDICT:|\Z)', text, re.DOTALL)
    if m:
        print(m.group(1).strip())
    else:
        lines = text.strip().split('\n')
        verdict_idx = None
        for i, l in enumerate(lines):
            if 'VERDICT:' in l:
                verdict_idx = i
        if verdict_idx is not None and verdict_idx > 0:
            start = max(0, verdict_idx - 30)
            print('\n'.join(lines[start:verdict_idx]).strip())
        elif text:
            print(text[-2000:] if len(text) > 2000 else text)
        else:
            print('(no output captured)')
except Exception as e:
    print(f'(Could not extract summary: {e})')
" "$json_file" 2>/dev/null || echo "(Could not extract summary)"
}

# sprintbias_run_error JSON_LOG_FILE -> did the AI CLI fail to finish this run?
# The audit scripts run the CLI with --output-format json; that result object
# carries is_error/subtype/errors even when no verdict text was produced (a
# max-turns abort has no 'result' field at all). Callers used to ignore those
# fields and mis-report every non-finish as "could not parse a verdict".
#
# On a run that did NOT finish normally, print a one-line plain-language
# diagnosis to stdout and return 0 (so `if MSG=$(sprintbias_run_error log)` is
# the "did not finish" branch). On a clean/success result, print nothing and
# return 1 (proceed to parse the verdict). An empty/absent log means the CLI
# never started; a non-JSON log is treated as "finished" so the caller can still
# grep a verdict from raw text.
sprintbias_run_error() {
    local json_file="$1"
    if [ ! -s "$json_file" ]; then
        printf "the AI CLI produced no output — it likely failed to start (check '%s' install/auth)\n" "$SPRINTBIAS_CLI"
        return 0
    fi
    python3 - "$json_file" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)          # non-JSON log: let the caller try a raw verdict grep
if not d.get("is_error"):
    sys.exit(1)          # clean result: proceed to parse the verdict
subtype = d.get("subtype") or "error"
errs = d.get("errors") or []
turns = d.get("num_turns", "?")
secs = int((d.get("duration_ms") or 0) / 1000)
cost = d.get("total_cost_usd") or 0
reason = {
    "error_max_turns": "hit its turn limit before finishing",
    "error_during_execution": "errored partway through",
}.get(subtype, "did not finish (%s)" % subtype)
detail = ("; " + errs[0]) if errs else ""
print("the audit %s (%s turns, %dm %02ds, $%.2f)%s" % (
    reason, turns, secs // 60, secs % 60, cost, detail))
sys.exit(0)
PY
}

# sprintbias_interpret_run LOG [rc] -> read a run's result exactly once.
# Answers "what happened to this run?" in one place, so every audit stops
# reading the same log three times (grep for a verdict, parse is_error, parse a
# summary) and stops re-deriving the failure kind from a human-readable string.
# Sets these globals (the normalized record):
#   SPRINTBIAS_RUN_OUTCOME      finished | max_turns | no_start | error
#   SPRINTBIAS_RUN_VERDICT_TEXT the run's result text (caller greps its own
#                               VERDICT token set from this on outcome=finished)
#   SPRINTBIAS_RUN_TURNS        turns spent (best-effort; may be empty)
#   SPRINTBIAS_RUN_COST         USD spent  (best-effort; may be empty)
#   SPRINTBIAS_RUN_SUMMARY      the run's summary text (best-effort)
# Dispatches to the active profile's profile_interpret_run when defined (Claude
# does; see cli/claude.sh). When a profile has not implemented one yet
# (grok/default until task 368), it falls back to today's Claude-shaped
# is_error/subtype logic so those providers keep their current behavior.
# The optional rc is accepted for future use — the record is derived from the
# log file, not stderr (every call site runs the CLI as `... 2>/dev/null`, so
# the profile's own dropped-flag / retry warnings are already silenced).
sprintbias_interpret_run() {
    local log="$1"
    if declare -F profile_interpret_run >/dev/null 2>&1; then
        profile_interpret_run "$log" "${2:-}"
    else
        _sprintbias_interpret_run_fallback "$log" "${2:-}"
    fi
}

# Bridge interpreter for providers whose profile has not defined
# profile_interpret_run yet (task 368 ports grok/default onto their own). It
# reproduces today's Claude-shaped is_error/subtype reading so those providers'
# behavior is unchanged. Not the permanent home of shape knowledge — each
# profile owns its own shape once it implements profile_interpret_run.
_sprintbias_interpret_run_fallback() {
    local log="$1"
    SPRINTBIAS_RUN_OUTCOME="" SPRINTBIAS_RUN_TURNS="" SPRINTBIAS_RUN_COST=""
    SPRINTBIAS_RUN_VERDICT_TEXT="" SPRINTBIAS_RUN_SUMMARY=""
    if [ ! -s "$log" ]; then
        SPRINTBIAS_RUN_OUTCOME="no_start"
        return 0
    fi
    SPRINTBIAS_RUN_OUTCOME=$(python3 - "$log" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    print("finished"); sys.exit(0)   # non-JSON log: caller greps raw text
if not d.get("is_error"):
    print("finished"); sys.exit(0)
subtype = d.get("subtype") or "error"
print({"error_max_turns": "max_turns",
       "error_during_execution": "error"}.get(subtype, "error"))
PY
    )
    : "${SPRINTBIAS_RUN_OUTCOME:=finished}"
    if [ "$SPRINTBIAS_RUN_OUTCOME" = "finished" ]; then
        SPRINTBIAS_RUN_VERDICT_TEXT="$(cat "$log")"
        SPRINTBIAS_RUN_SUMMARY="$(sprintbias_extract_summary "$log")"
    fi
    return 0
}

# sprintbias_run_hint OUTCOME [lever] -> one honest, actionable line for a run
# that did not produce a usable verdict. Shared so every audit speaks the same
# run-mechanics vocabulary; only the verdict tokens stay caller-owned. OUTCOME
# is an interpreter outcome (max_turns | no_start | error) or the pseudo-token
# no_verdict (the run finished but its final line held no VERDICT token). The
# optional lever overrides the default next-step copy, so a caller with its own
# recovery flow (e.g. polish --code salvage, task 371) supplies its own lever
# rather than inheriting a hard-coded one.
sprintbias_run_hint() {
    local outcome="$1" lever="${2:-}"
    case "$outcome" in
        max_turns)
            printf 'hit its turn limit before finishing — %s' \
                "${lever:-raise --max-turns or narrow scope}" ;;
        no_start)
            printf "produced no output, so the '%s' CLI likely failed to start — %s" \
                "$SPRINTBIAS_CLI" "${lever:-check its install/auth}" ;;
        error)
            printf 'errored partway through — %s' \
                "${lever:-inspect the log}" ;;
        no_verdict)
            printf 'finished but wrote no VERDICT token — %s' \
                "${lever:-a formatting slip, not a crash; re-run}" ;;
        *)
            printf 'did not finish — %s' "${lever:-inspect the log}" ;;
    esac
}

# ── Auto-load on source ─────────────────────────────────────────────
# Populate shell variables from config, with env overrides and defaults.
# Back-compat: the pre-rebrand env vars SPRINTMD_CLI / SPRINTMD_PROVIDER still
# override, so anyone who already exported them keeps working. Precedence:
# new SPRINTBIAS_* env → legacy SPRINTMD_* env → config file → built-in default.
SPRINTBIAS_CLI="${SPRINTBIAS_CLI:-${SPRINTMD_CLI:-$(sprintbias_cfg CLI)}}"
: "${SPRINTBIAS_CLI:=claude}"

# Capability tier. Empty is fine — sprintbias_ai_tier infers it from the CLI.
SPRINTBIAS_PROVIDER="${SPRINTBIAS_PROVIDER:-${SPRINTMD_PROVIDER:-$(sprintbias_cfg PROVIDER)}}"

SPRINTBIAS_BUDGET_WORK="${SPRINTBIAS_BUDGET_WORK:-$(sprintbias_cfg BUDGET_WORK)}"
: "${SPRINTBIAS_BUDGET_WORK:=5.00}"

SPRINTBIAS_BUDGET_AUDIT="${SPRINTBIAS_BUDGET_AUDIT:-$(sprintbias_cfg BUDGET_AUDIT)}"
: "${SPRINTBIAS_BUDGET_AUDIT:=3.00}"

SPRINTBIAS_AUDIT_MAX_PASSES="${SPRINTBIAS_AUDIT_MAX_PASSES:-$(sprintbias_cfg AUDIT_MAX_PASSES)}"
: "${SPRINTBIAS_AUDIT_MAX_PASSES:=2}"

# Load provider profile (defines sprintbias_provider_exec)
sprintbias_load_profile "$SPRINTBIAS_CLI"
