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
#   sprintbias_cfg_set KEY VALUE [FILE] — update or append a value (default: tracked config)
#   sprintbias_fast_on            — true when fast mode is on for this run
#   sprintbias_fast_parallel      — fast mode's parallel default for work/polish
#   sprintbias_fast_rules         — what fast mode adds to the finishing rule
#       (subagents, cross-plan reach); prints nothing when fast is off
#   sprintbias_resolve_model SFX  — model resolution: env > config > default;
#       provider-foreign ids remapped (opus on grok → grok-4.5, etc.)
#   sprintbias_coerce_model MODEL — remap Claude/Grok-only ids for active tier
#   sprintbias_tier_model SFX     — resolve + strong default on
#       claude-code (opus) and grok-build (grok-4.5) when config is empty
#   sprintbias_orient             — orientation block every AI prompt carries (instructions, workflow, project map)
#   sprintbias_grounding_rule     — the ## Grounding contract (gate writes, work fills gaps)
#   sprintbias_grounding_conflicts FILE — conflict bullets from a task's ## Grounding
#   sprintbias_profile_check      — no-AI health check of project.md (paths, staleness)
#   sprintbias_doc_sync_rule      — the write side: keep sources accurate or record ### Doc follow-ups
#   sprintbias_doc_followups FILE — follow-up bullets from a finished task
#   sprintbias_file_doc_followups — collect follow-ups from review/ + done/ into one backlog task
#   sprintbias_conversation_method — contents of ai/conversation.md (loud fail if missing)
#   sprintbias_discuss_file SUBJECT — docs/tmp/<subject>_discuss.md (a session's decision checklist)
#   sprintbias_plan_discuss_file ID — docs/tmp/plan-<id>_discuss.md (held decisions)
#   sprintbias_checklist_line SUBJECT — prompt line naming that checklist; flags unchecked lines to resume
#   sprintbias_discuss_open_count FILE — number of unchecked `- [ ]` lines (0 if absent)
#   sprintbias_next_blocked_resolution — prompt: dependent in next/ held on task in blocked/
#       (two-path choice, demote inline for B, hand off to chat for A). Shared
#       by chat-sprint.sh and the chat-next folder walk so the logic is written once.
#   sprintbias_find_task ID [dirs…] — resolve a task file by numeric ID
#   sprintbias_task_stage ID        — lifecycle stage folder name (or empty)
#   sprintbias_task_path ID         — path to the task file (or empty)
#   sprintbias_review_verdict FILE — READY/BLOCKED/COMPLETE stamp from a gate review
#   sprintbias_open_questions / sprintbias_has_open_questions FILE
#   sprintbias_done_when FILE — a task's ## Done when (automated) body (old
#     ## Success criteria reads as it); _heading names it, _testable checks it
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
#   sprintbias_edge_cases         — the edge-case classes (gate, proof rule, breaker)
#   sprintbias_proof_rule         — worker test loop: targeted tests, edge cases,
#       ## Test log, the **Proof**: line that lands a task (work + crew prompts)
#   sprintbias_break_on           — true when the breaker runs after work (BREAK)
#   sprintbias_break_rule FILE    — the breaker's instruction for one landed task
#   sprintbias_break_run FILE LOG — run the breaker headless (work, polish --break, promote)
#   sprintbias_break_signoff JOBS DRY FILE… — breaker before promote sign-off
#   sprintbias_plan_args [--bare] ARG… — normalize plan:N / plan N / bare plan id
#       into SPRINTBIAS_ARGS (work, promote, polish, crew)
#   sprintbias_change_manifest TASK_FILE [FILE…] — build audit change manifest;
#       sets SPRINTBIAS_CHANGED_FILES and SPRINTBIAS_CONTEXT_SOURCE
#   sprintbias_change_snapshot take|diff SNAP [ROOT…] — before/after snapshot of
#       docs/tasks + docs/plans; diff prints new|edited|moved|deleted per file
#       with +/- line counts (what an agent pass touched, no git needed)
#   sprintbias_parse_verdict TOKENS — (stdin) last VERDICT token, case/format tolerant
#   Dependency-graph helpers (pure, unit-testable — no AI):
#     SPRINTBIAS_OPEN_STAGES        — stages still holding incomplete work
#     sprintbias_stage_is_open STAGE — 0 when STAGE is an open (incomplete) stage
#     sprintbias_reverse_edge_value FILE — Dependents value (legacy Blocks fallback)
#     sprintbias_fold_target FILE   — id a task was folded into, or empty
#     sprintbias_classify_dep ID [MISSING_AS] — one token:
#         review|done|doing|next|backlog|blocked|folded|missing (policy knob)
#     sprintbias_has_proof FILE     — 0 when ## Completed carries a passing **Proof**: line
#     sprintbias_dep_landed ID      — 0 when ID is in done/, or review/ with proof
#         (the one "is this prerequisite met" rule; review/ without proof is
#         $SPRINTBIAS_UNPROVEN_LABEL and holds its dependents; a review/ task
#         with **Held**: fix #N counts only once fix #N lands)
#     sprintbias_held_fixes FILE    — fix ids named on FILE's **Held** line
#     sprintbias_add_test_log FILE LINE — append LINE under FILE's ## Test log
#     sprintbias_file_fix_task ID "report" — file a linked fix task for a
#         rejected review/ task (**Fixes**, Crew, Plan, Held, dependent trace)
#     sprintbias_unmet_deps FILE    — dep ids not yet landed (missing = archived)
#     sprintbias_deps_not_sprint_ready FILE — dep ids still in backlog/ or blocked/
#         (empty = every dep is next/doing/review/done, folded, or archived)
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
#     sprintbias_member_standing ID — open | landed | held | unproven | signed-off | missing
#     sprintbias_held_open_fixes ID — fix ids on ID's **Held** line not yet landed
#     sprintbias_held_label ID — 'held: fix #N' (one spelling for every listing)
#     sprintbias_plan_counts PLAN_FILE — open landed signed unproven missing total fixes moved held human
#     sprintbias_plan_state PLAN_FILE — SIGNED OFF | LANDED | STARTED | not started (computed)
#     sprintbias_plan_open_fixes PLAN_FILE — open **Fixes**: tasks aimed at the plan

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
    printf '%s' "Always move task files with: git mv SRC DEST || mv SRC DEST. Run git mv first (preserves history when tracked). When git mv fails — usual for new tasks not yet committed — finish that same move with plain mv, then continue. git commit and ./ship.sh are human-owned by default — run either only when the human explicitly asks for that action in this conversation."
}

# Strip the task template's authoring scaffolding from a task file.
# The template ships each section with a <!-- … --> guidance comment, plus the
# after-work "## Completed / ### Files changed" how-to block and an "AI:" footer.
# Those instruct whoever authors the task; once the task is run they are dead
# weight that costs context on every later read. Remove exactly those known
# template blocks — matched by a signature phrase so an author's own HTML notes
# (Reviewed dates, risk notes) survive — then squeeze the blank lines they leave
# behind. Idempotent: a task with no scaffolding passes through unchanged.
sprintbias_scrub_template_scaffold() {
    local file="$1"
    [ -f "$file" ] || return 0
    command -v awk >/dev/null 2>&1 || return 0
    local tmp
    tmp="$(mktemp 2>/dev/null)" || return 0
    # Detection keys off the "sb:hint" marker every template hint comment now
    # carries (docs/tasks/.TEMPLATE-task.md). The marker is wording-independent:
    # the template's guidance text can be reworded freely and an author's own
    # HTML note never trips it. The frozen phrase list below is the legacy path
    # for tasks minted from the pre-marker template — those exact strings match
    # that historical scaffold and so never need maintenance. Blank lines a
    # removed hint leaves behind are dropped surgically (only the blanks that
    # immediately followed it) so intentional blank lines elsewhere — inside
    # fenced code blocks especially — are never touched.
    if awk '
        function is_scaffold(s) {
            return (s ~ /sb:hint/ ||
                    s ~ /Full task-writing guidance is in/ ||
                    s ~ /audit trail of what was touched/ ||
                    s ~ /Concisely define the problem at a high level/ ||
                    s ~ /What done looks like\. When these/ ||
                    s ~ /Optional helpful hints that assist the developer/ ||
                    s ~ /Direct paths to docs or files known to be related/)
        }
        BEGIN { inc = 0; buf = ""; eat = 0 }
        {
            if (inc) {                          # accumulating a multi-line comment
                buf = buf $0 "\n"
                if ($0 ~ /-->/) {
                    inc = 0
                    if (is_scaffold(buf)) { eat = 1 }
                    else { printf "%s", buf; eat = 0 }
                    buf = ""
                }
                next
            }
            if ($0 ~ /<!--/ && $0 !~ /-->/) { inc = 1; buf = $0 "\n"; next }
            if ($0 ~ /<!--/ && $0 ~ /-->/) {    # single-line comment
                if (is_scaffold($0)) { eat = 1 }
                else { print; eat = 0 }
                next
            }
            if (eat && $0 ~ /^[ \t]*$/) { next } # drop only the blanks a hint left
            eat = 0
            print
        }
        END { if (inc) printf "%s", buf }        # unterminated comment: emit as-is, never lose data
    ' "$file" > "$tmp" && [ -s "$tmp" ]; then
        cat "$tmp" > "$file"
    fi
    rm -f "$tmp" 2>/dev/null
    return 0
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
    # Its sleep first: once the watcher dies the sleep is re-parented and
    # pkill -P can no longer find it (it would linger, holding output open).
    pkill -P "$watcher" 2>/dev/null
    kill "$watcher" 2>/dev/null
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
# Updates a key in-place, or appends it if not present. FILE defaults to the
# tracked config; pass "$SPRINTBIAS_CONFIG_LOCAL_FILE" for a per-machine pin.
sprintbias_cfg_set() {
    local key="$1" value="$2" file="${3:-$SPRINTBIAS_CONFIG_FILE}"
    if [ ! -f "$file" ]; then
        echo "${key}=${value}" > "$file"
        return
    fi
    if grep -q "^${key}=" "$file"; then
        # Escape the replacement for a |-delimited sed s-command: a literal
        # |, &, or \ in the value would otherwise corrupt the substitution.
        local esc_value
        esc_value=$(printf '%s' "$value" | sed 's/[\\&|]/\\&/g')
        sed_inplace "s|^${key}=.*|${key}=${esc_value}|" "$file"
    else
        echo "${key}=${value}" >> "$file"
    fi
}

# ── Fast mode ────────────────────────────────────────────────────────
# sprintbias_fast_on — true when this run is in fast mode (autonomous, high
# throughput); false means steady. The one place scripts read the mode.
# Precedence, highest first:
#   env SPRINTBIAS_FAST   per-run: a leading ./sprint.sh --fast / --steady, or
#                       work / polish --fast, exports it for that one run
#   config.local FAST     per-machine switch, written by ./sprint.sh fast on|off
#   config FAST           tracked default
#   off                   when nothing above is set
sprintbias_fast_on() {
    local v="${SPRINTBIAS_FAST:-$(sprintbias_cfg FAST)}"
    case "$v" in on|ON|On|1|true|yes) return 0 ;; esac
    return 1
}

# sprintbias_fast_parallel [STEADY] — settle the caller's PARALLEL / MAX_JOBS
# for work and polish. STEADY=1 (a --steady flag) runs sequentially; with no
# parallel flag and fast on, run in parallel at 4 jobs; otherwise the flags
# stand (--jobs N keeps its count).
sprintbias_fast_parallel() {
    if [ "${1:-0}" -eq 1 ]; then
        PARALLEL=0
    elif [ "${PARALLEL:-0}" -eq 0 ] && sprintbias_fast_on; then
        PARALLEL=1; MAX_JOBS=4
    fi
}

# sprintbias_fast_state — prints "on" or "off" (for banners and status).
sprintbias_fast_state() {
    if sprintbias_fast_on; then printf 'on'; else printf 'off'; fi
}

# sprintbias_fast_rules — what fast mode adds to the finishing rule
# (sprintbias_assume_rule, every mode): reach. Subagents build missing pieces,
# and a goal may touch another plan's task. Prints nothing when fast is off, so
# callers splice it in unconditionally. Loads in every fast session: keep it short.
sprintbias_fast_rules() {
    sprintbias_fast_on || return 0
    cat <<'EOF'
Fast mode adds reach:
- Start a subagent to build a missing piece the goal needs; it lands in
  review/ with a proof line like any task.
- Touching another plan's task: read that plan's Goal first, serve both goals,
  and add to that plan: Touched by plan N: #id — what and why
EOF
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

# ── Knowing what you need to know ────────────────────────────────────
# docs/sprintbias/project.md (written by `./sprint.sh profile`) is the ONE map
# of where a project's knowledge lives: stack, code layout, commands, sources of
# truth, environments. Every AI prompt orients through sprintbias_orient — one
# wording, every command, every mode and provider. Tasks ground themselves in
# that map through sprintbias_grounding_rule (gate writes it, work fills gaps).
SPRINTBIAS_PROJECT_MAP="${SPRINTBIAS_PROJECT_MAP:-docs/sprintbias/project.md}"

# The instruction file the active provider auto-loads.
_sprintbias_instructions_file() {
    case "$(sprintbias_ai_tier)" in
        claude-code) printf 'CLAUDE.md' ;;
        grok-build)  printf 'AGENTS.md' ;;
        *)           printf 'CLAUDE.md / AGENTS.md' ;;
    esac
}

# Orientation block for every AI prompt: where instructions, workflow, and the
# project map live, and the one policy for sources of truth. No leading or
# trailing newline — callers place it on its own line. Always returns 0.
sprintbias_orient() {
    printf 'Project instructions: %s (auto-loaded when present). SprintBias task workflow: DOCUMENTATION.md.\n' \
        "$(_sprintbias_instructions_file)"
    if [ -f "$SPRINTBIAS_PROJECT_MAP" ]; then
        printf '%s' "Project map: $SPRINTBIAS_PROJECT_MAP — stack, code layout, commands, sources of truth, and environments. Start there and read the sources your work touches; check docs/history/ first for why an area is the way it is. Sources of truth are the authority: never change one to make your work fit it, and when your work conflicts with one, name the conflict instead of working around it. Deploys and secrets are human-owned."
        grep -q '^## Known edges' "$SPRINTBIAS_PROJECT_MAP" 2>/dev/null \
            && printf '%s' " Its ## Known edges lists cases that broke before: test the ones your change touches."
    else
        printf '%s' "Project map: none yet ($SPRINTBIAS_PROJECT_MAP, created with ./sprint.sh profile) — orient from the instructions file and the code; check docs/history/ first for why an area is the way it is. Deploys and secrets are human-owned."
    fi
    return 0
}

# The grounding contract: before a task is worked, its file names the sources
# it relies on, copies the terms it uses, and settles its conflicts. Shared by
# the gate (writes it) and work (fills what is missing) so both say it once.
sprintbias_grounding_rule() {
    cat <<'EOF'
Grounding (before any other work on the task): the task file carries a
## Grounding section, placed after ## References. Write it when missing; when it
is present, keep it and add what is missing.

## Grounding

**Sources:** the project-map entries this task touches — code structure,
language and style, glossary / lexicon / taxonomy, other sources of truth — as
`path` (what it governs), comma-separated.
**Terms:**
- **term** — definition copied word for word from the glossary / lexicon /
  taxonomy. Only terms this task uses; 'None.' when the project has none.
**Conflicts:**
- <what disagrees with what> → <how the work proceeds>
('None found.' when there are none.)

Conflicts cover the task vs a source of truth, two sources vs each other, the
task vs the current code, and the task vs the SprintBias framework itself (its
folders, rules, or commands). Settle each one here, before work, choosing the
path that keeps the sources of truth intact. A term the glossary lacks is a
conflict line: the reading you use, and a suggestion to add it. A conflict that
changes scope or what done means is decided like any call: the most reasonable
reading, recorded as a Decided: line. A conflict that leaves a source wrong or incomplete (a missing term, an outdated
section) becomes a Doc follow-up when the task completes.
EOF
}

# The write side of the same policy: work that changes what a source of truth
# describes keeps that source accurate, or records the gap for later. Used by
# work (exec + emit). Follow-ups are collected into one backlog task by
# sprintbias_file_doc_followups, so no gap is lost in a done/ file.
sprintbias_doc_sync_rule() {
    cat <<'EOF'
Docs stay in step with the work. When your change alters what a source of truth
describes — an API, the architecture, a term, a command, an environment — update
that document in this task so it states the new facts. Descriptive sources
(glossary / lexicon / taxonomy, architecture, API, README, commands) you update
directly. Governing sources (security policy, decision records, instruction
files such as CLAUDE.md / AGENTS.md) and anything outside this task's scope go
under ## Completed as:

### Doc follow-ups
- `path` — what needs to change and why

Add a line the same way for a project-map change (a source added, moved, or
removed; a changed command or environment) — the map is refreshed with
./sprint.sh profile. Leave the subsection out when there is nothing to follow up.
EOF
}

# The parallel-work contract: several agents may work one checkout at once
# (`work 1443` in one terminal, `work 1452` in another, or a crew). doing/ is
# the claim; each task file is its agent's announcement. Lists the tasks in
# doing/ when the prompt is built (SELF, a task path or name, is left out) and
# tells the agent to look again, since siblings start later. Used by work
# (exec + emit) and crew. Always returns 0.
sprintbias_parallel_rule() {
    local self="${1##*/}" f crew others="" n=0
    for f in docs/tasks/doing/[0-9]*-*.md; do
        [ -f "$f" ] && [ "${f##*/}" != "$self" ] || continue
        n=$((n + 1))
        # A pile of abandoned doing/ files must not bloat every prompt.
        [ "$n" -le 8 ] || continue
        crew="$(sprintbias_meta_value "$f" Crew)"
        case "$crew" in ''|[Nn]one) crew="" ;; *) crew=" (crew: $crew)" ;; esac
        others="${others}
- $f$crew"
    done
    cat <<'EOF'
Parallel work: other agents may share this checkout. Each task in
docs/tasks/doing/ is one of them, and its file is its announcement.
- Announce: add **Touching:** (the files you expect to change) to your task's
  ## Grounding and keep it current. When your tools can message other sessions
  (Claude Code: ListAgents, SendMessage), send each running agent your task id
  and Touching list.
- See theirs with grep -H Touching docs/tasks/doing/*.md at the start and
  whenever a file changes under you. On a shared file, re-read it right before
  each edit and change only your part. Where two tasks rework the same code, the
  lower task id owns it; the other builds around it and notes the overlap under
  ## Completed.
- Changes you did not make belong to another agent: leave them, and never
  stash, reset, checkout, or revert them. A problem you spot in their files
  goes to that agent, or under your ## Completed.
EOF
    [ "$n" -gt 8 ] && others="${others}
- …and $((n - 8)) more in docs/tasks/doing/"
    [ -n "$others" ] && printf 'In doing/ when you started:%s\n' "$others"
    return 0
}

# The edge-case classes every agent tests against: the gate (Done when checks),
# the worker and crew (via sprintbias_proof_rule), and the breaker. One wording,
# loaded once per prompt. Sent with every task, so keep it short.
sprintbias_edge_cases() {
    cat <<'EOF'
Edge cases to test:
1. Each case the task names, and the class its example stands for.
2. Round trips: every form the project's docs, UI, templates or examples tell people
   to write, and what the real tools people use emit (versions, locales, platforms).
3. Again and after: run twice; state left by an earlier version, a half-finished run,
   or a hand edit.
4. Empty, one, many, malformed.
5. Neighbors: other code that reads or writes the same data still works.
EOF
}

# The test-and-proof loop (plan 28 Policy): targeted tests per task, a
# ## Test log of failures, and the **Proof**: line that lands the task (the
# format sprintbias_has_proof reads). Used by work (exec + emit) and crew next
# to sprintbias_parallel_rule. Sent with every task, so keep it short.
sprintbias_proof_rule() {
    cat <<'EOF'
Test loop:
- Build the smallest testable outcome first, then grow it.
- Run targeted tests: the ones ## Done when (automated) names, plus the tests
  for code your **Touching:** files feed. The full suite runs once, at plan close.
- Before landing, add one assertion per ## Done when case and per realistic
  edge case below in the code path you change. Fix each failure; file one in
  another code path: ./sprint.sh newtask "<the failing case>". Decided and
  Assumptions record choices between working options, never a known failure.
- Log each failure under ## Test log (command, failing test, error excerpt).
  Audit the test first (a wrong test gets corrected, with why), fix any clear
  cause, and re-run until green. Still unexplained: land without **Proof**.
- Work that cannot start (no reasonable reading, or access or credentials
  only the person holds): add ## Outcome with **Result**: blocked and a
  one-line **Reason**:. Stop.
- To land, open ## Completed with **Summary**: <one plain sentence: what
  changed, for someone reading the project's history>, end it with the tests
  you ran, then move to review/:
  **Proof**: YYYY-MM-DD · <targeted test commands> · pass
  Without it the task is "in review, unproven" and holds its dependents.

EOF
    sprintbias_edge_cases
}

# The breaker: after a task lands, a fresh-context agent tries to break it.
# On by default; BREAK=off (config / config.local, or env SPRINTBIAS_BREAK)
# or `work --no-break` skips it. Used by work exec (_run_breaker) and both emit
# prompts, so the wording is shared.
sprintbias_break_on() {
    local v="${SPRINTBIAS_BREAK:-$(sprintbias_cfg BREAK)}"
    case "$v" in off|OFF|Off|0|false|no) return 1 ;; esac
    return 0
}

# sprintbias_break_rule TASK_FILE — the breaker's whole instruction. Bounded:
# targeted tests only. Includes the edge-case classes once.
sprintbias_break_rule() {
    cat <<EOF
You are the breaker: a fresh pair of eyes on a task that just landed. Find
what its change gets wrong before a person sees it.
Task file: $1 — read its ## Done when and ## Completed (### Files changed),
then the changed code (git diff on those files, or read them).
- Start from real use: the commands and inputs as people type or paste them
  (the project's README, docs, help and examples; shell quoting; the tools
  they come from), and each form the docs promise. Reach for extremes after
  those pass.
- Write tests designed to fail, drawn from the edge cases below and aimed at
  the changed code, next to the task's tests. Run only them and the task's
  targeted tests.
- A failure that is a real defect: fix the code, re-run the targeted tests,
  and keep the **Proof**: line current. When a - Decided: line caused it,
  re-decide it by best practice, fix, and replace that line (say what
  changed). One in another code path, or one you cannot fix: file it with
  ./sprint.sh newtask "<the failing case>". Cannot fix: also log it under
  ## Test log (command, failing test, error excerpt) and remove **Proof**:.
- A test left failing names its filed task (in its name or a comment such as
  "fails until #N"); only then mark it expected-failure / skip / todo.
- Add under ## Completed: **Breaker**: <N> cases tried · <N> fixed · <N> filed
- Change only the task file, the changed code and its tests.

EOF
    sprintbias_edge_cases
}

# sprintbias_break_run FILE LOG — run the breaker headless on one landed task
# (exec). Bounded: SPRINTBIAS_BREAK_MAX_TURNS (25) turns, BUDGET_BREAK where a
# cap is set (--max clears it), MODEL_BREAK.
# Returns the CLI's exit code; output goes to LOG. Used by work and polish --break.
sprintbias_break_run() {
    local file="$1" log="$2" model args
    model="$(sprintbias_tier_model BREAK)"
    args=(--tools "Read,Edit,Write,Bash,Grep,Glob" --permissions auto \
        --max-turns "${SPRINTBIAS_BREAK_MAX_TURNS:-25}")
    [ -n "$model" ] && args+=(--model "$model")
    if sprintbias_budget_capable && [ -n "${SPRINTBIAS_BUDGET_BREAK:-}" ]; then
        args+=(--budget "$SPRINTBIAS_BUDGET_BREAK")
    fi
    local rc=0
    sprintbias_run -p "$(sprintbias_orient)

$(sprintbias_break_rule "$file")" "${args[@]}" --output-format stream-json > "$log" 2>&1 || rc=$?
    sprintbias_break_stamp_cost "$file" "$log"
    return "$rc"
}

# sprintbias_run_cost LOG — the run's cost in USD (e.g. 1.37) from the last
# stream-json result event in LOG; nothing when the provider reports none.
sprintbias_run_cost() {
    [ -f "$1" ] && command -v python3 >/dev/null 2>&1 || return 0
    python3 - "$1" <<'PY' 2>/dev/null || true
import json, sys
cost = None
for line in open(sys.argv[1], errors="replace"):
    try:
        e = json.loads(line)
    except ValueError:
        continue
    if isinstance(e, dict) and e.get("type") == "result" and e.get("total_cost_usd") is not None:
        cost = e["total_cost_usd"]
if cost is not None:
    print("%.2f" % float(cost))
PY
}

# sprintbias_break_stamp_cost FILE LOG — append "· $N.NN" to FILE's **Breaker**:
# line when LOG reports a cost and the line has none yet (status --edges sums it).
sprintbias_break_stamp_cost() {
    local file="$1" cost
    [ -n "$(sprintbias_break_line "$file")" ] || return 0
    grep -qE '^\*\*Breaker\*\*:.*· \$[0-9]' "$file" && return 0
    cost="$(sprintbias_run_cost "$2")"
    case "$cost" in ""|0.00) return 0 ;; esac
    python3 - "$file" "$cost" <<'PY' || true
import sys
p, cost = sys.argv[1], sys.argv[2]
lines = open(p).read().split("\n")
for i, l in enumerate(lines):
    if l.startswith("**Breaker**:"):
        lines[i] = l.rstrip() + " · $" + cost
        break
open(p, "w").write("\n".join(lines))
PY
}

# sprintbias_break_signoff JOBS DRY FILE… — the breaker before sign-off (promote).
# Checks each FILE with no **Breaker**: line yet (the human test is skipped),
# JOBS at a time, each bounded by SPRINTBIAS_BREAK_TIMEOUT seconds (900). A
# crash or timeout never blocks: it warns and stamps the task checked-not-run.
# DRY=1 lists what would be checked. Sets SPRINTBIAS_BREAK_LOST to the ids that
# lost their **Proof**: line, and SPRINTBIAS_BREAK_EMIT=1 when, in emit mode,
# the caller must hand the check to the agent first (the command is printed).
# Returns 0; does nothing when BREAK is off.
sprintbias_break_signoff() {
    local jobs="$1" dry="$2" f todo=() i n id b today
    shift 2
    SPRINTBIAS_BREAK_LOST=""; SPRINTBIAS_BREAK_EMIT=0
    sprintbias_break_on || return 0
    for f in "$@"; do
        [ -f "$f" ] || continue
        sprintbias_is_human_task "$f" && continue
        [ -n "$(sprintbias_break_line "$f")" ] && continue
        todo+=("$f")
    done
    n=${#todo[@]}
    [ "$n" -gt 0 ] || return 0
    echo "▸ Checking $n task(s) before sign-off (breaker)…"
    if [ "$dry" -eq 1 ]; then
        for f in "${todo[@]}"; do echo "  #$(task_id "$f")  would be checked  $(task_title "$f")"; done
        return 0
    fi
    if [ "$(sprintbias_ai_mode)" = "emit" ]; then
        local ids=""
        for f in "${todo[@]}"; do ids="$ids $(task_id "$f")"; done
        echo "  Run the breaker first, then promote again (or skip it: --no-break):"
        for id in $ids; do echo "    ./sprint.sh polish --break $id"; done
        SPRINTBIAS_BREAK_EMIT=1
        return 0
    fi
    mkdir -p docs/tmp
    local tmp lane l=0 k pids=(); tmp="$(mktemp -d "${TMPDIR:-/tmp}/sb-break.XXXXXX")"
    [ "${jobs:-1}" -ge 1 ] 2>/dev/null || jobs=1
    # Tasks that changed a common file share a lane and run one after another,
    # so two breakers never edit the same file at once; lanes run in parallel.
    while IFS= read -r lane; do
        [ -n "$lane" ] || continue
        ( for k in $lane; do
            f="${todo[$k]}"
            had=0; sprintbias_has_proof "$f" && had=1
            rc=0
            # Detached from the caller's output: the timeout watcher must not
            # hold a $(…) capture open.
            run_with_timeout "${SPRINTBIAS_BREAK_TIMEOUT:-900}" sprintbias_break_run "$f" \
                "$(sprintbias_log_path break "$(basename "$f")")" </dev/null >/dev/null 2>&1 || rc=$?
            printf '%s %s\n' "$had" "$rc" > "$tmp/$k"
          done ) &
        pids+=("$!")
        # A free slot: wait until fewer than JOBS lanes run (bash 3.2 has no wait -n).
        while :; do
            l=0
            for k in "${pids[@]}"; do kill -0 "$k" 2>/dev/null && l=$((l + 1)); done
            [ "$l" -lt "$jobs" ] && break
            sleep 1
        done
    done <<EOT
$(sprintbias_break_lanes "${todo[@]}")
EOT
    wait
    today="${SPRINTBIAS_TODAY:-$(date +%Y-%m-%d)}"
    i=0
    for f in "${todo[@]}"; do
        id="$(task_id "$f")"
        local had=0 rc=1
        [ -f "$tmp/$i" ] && read -r had rc < "$tmp/$i"
        i=$((i + 1))
        if [ "$rc" -ne 0 ] && [ -z "$(sprintbias_break_line "$f")" ]; then
            printf '\n**Breaker**: not run (crashed or timed out, %s) — re-run: ./sprint.sh polish --break %s\n' "$today" "$id" >> "$f"
            echo "  ⚠ #$id  breaker did not finish — checked, not run; signing off as it was"
        else
            b="$(sprintbias_break_line "$f")"
            echo "  #$id  **Breaker**: ${b:-(no line written)}"
        fi
        if [ "$had" = "1" ] && ! sprintbias_has_proof "$f"; then
            SPRINTBIAS_BREAK_LOST="$SPRINTBIAS_BREAK_LOST $id"
        fi
    done
    rm -rf "$tmp"
    SPRINTBIAS_BREAK_LOST="${SPRINTBIAS_BREAK_LOST# }"
    return 0
}

# sprintbias_break_lanes FILE… — group tasks into lanes for parallel breakers:
# one line per lane (longest first), the 0-based indexes of FILE… that run one
# after another.
# Tasks whose ### Files changed lists share a code path join one lane (.md prose
# files do not join lanes); tasks with no list share one lane (unknown reach).
sprintbias_break_lanes() {
    python3 - "$@" <<'PY' 2>/dev/null || { local i=0 f; for f in "$@"; do echo "$i"; i=$((i + 1)); done; }
import re, sys
files = sys.argv[1:]
paths = []
for f in files:
    try:
        text = open(f, errors="replace").read()
    except OSError:
        text = ""
    m = re.search(r"^### Files changed[ \t]*\n(.*?)(?=^#|\Z)", text, re.M | re.S)
    if not m:
        paths.append(None)
        continue
    # List items or bare path lines, up to the first blank line after a path.
    # A stray match only joins two lanes (safe); a missed path runs two
    # breakers on one file at once, so read every line.
    got = set()
    for line in m.group(1).splitlines():
        if not line.strip():
            if got:
                break
            continue
        for p in re.findall(r"[A-Za-z0-9_()./-]+", line.split(" (")[0]):
            p = p.rstrip(".")
            if ("/" in p or re.search(r"\.[A-Za-z0-9]{1,6}$", p)) and not p.lower().endswith(".md"):
                got.add(p)
    paths.append(got)
parent = list(range(len(files)))
def find(i):
    while parent[i] != i:
        parent[i] = parent[parent[i]]
        i = parent[i]
    return i
unknown = [i for i, p in enumerate(paths) if p is None]
for i in range(len(files)):
    for j in range(i):
        if (paths[i] is not None and paths[j] is not None and paths[i] & paths[j]) \
           or (i in unknown and j in unknown):
            parent[find(i)] = find(j)
lanes = {}
for i in range(len(files)):
    lanes.setdefault(find(i), []).append(str(i))
# Longest lane first, so it starts while the short ones fill the other slots.
for lane in sorted(lanes.values(), key=lambda l: (-len(l), int(l[0]))):
    print(" ".join(lane))
PY
}

# sprintbias_test_cmd PATH — the command that runs one **Tests** file, as the
# project runs it: a .sh file with bash; any other file with config TEST_RUN
# ({} is the path, {file} its name; no placeholder appends the path), else a
# .py file with pytest, an executable directly, anything else with bash.
sprintbias_test_cmd() {
    local p="$1" run
    case "$p" in *.sh) printf 'bash %s' "$p"; return 0 ;; esac
    run="${SPRINTBIAS_TEST_RUN:-$(sprintbias_cfg TEST_RUN)}"
    if [ -n "$run" ]; then
        case "$run" in
            *"{}"*|*"{file}"*) run="${run//\{\}/$p}"; printf '%s' "${run//\{file\}/${p##*/}}" ;;
            *) printf '%s %s' "$run" "$p" ;;
        esac
    elif [ "${p%.py}" != "$p" ]; then
        printf 'python3 -m pytest -q %s' "$p"
    elif [ -x "$p" ]; then
        case "$p" in /*) printf '%s' "$p" ;; *) printf './%s' "$p" ;; esac
    else
        printf 'bash %s' "$p"
    fi
}

# sprintbias_break_line FILE — the **Breaker**: summary the breaker wrote, or nothing.
sprintbias_break_line() {
    grep -m1 '^\*\*Breaker\*\*:' "$1" 2>/dev/null | sed 's/^\*\*Breaker\*\*:[[:space:]]*//' || true
}

# sprintbias_assume_rule -> the finishing rule, one string for every mode:
# decide and record, ask only goal questions in a live conversation, keep
# blocked/ for work that cannot start. Spliced by work (exec + emit), the gate,
# plan think and crew: the places that make best-practice calls. The chat
# sessions (chat, chat plan, the sprint walk) leave it out: chat is where
# questions get dug into with the person. Fast mode adds sprintbias_fast_rules.
sprintbias_assume_rule() {
    cat <<'EOF'
Finish the work:
- Decide each open call by best practice, good security, elegant code and the
  best UX. Record each call as one bullet in the file you work on (a task's
  ## Notes before work, its ### Assumptions under ## Completed during work, a
  plan's ## Decided section):
  - Decided: X, because Y
  The person sees every call at the end and changes one with
  ./sprint.sh newtask "<the change you want>".
  Decide and build each design choice inside the example's class (a rounding
  rule, a format, a limit). A scope-out names its task: - Decided: X is out of scope, because Y; filed as #N
- A check only a person can make (real hardware, a live device or account,
  look and feel) goes under ## Signoff (human); build to the most reasonable
  assumption, prove what a test can reach (simulate, stub, fake it), and land.
  These gather into the plan's one human test.
- Ask the person only in a live conversation, and only when the answer changes
  the goal or the result: yes/no, or 1/2/3 with one marked (suggested). Go on
  with the suggested option meanwhile. Without a conversation, decide.
- blocked/ is for work that cannot start: no reasonable reading of the task,
  or access or credentials only the person holds.
- A tool or process idea becomes ./sprint.sh newtask "…"; then back to the goal.
- Commit, push and ./ship.sh stay the person's.
EOF
}

# Print the bullets under '### Doc follow-ups' in FILE (one per line, "- "
# kept). Stops at the next heading. Nothing when absent.
sprintbias_doc_followups() {
    local f="$1"
    [ -f "$f" ] || return 0
    awk '
        /^###? / { in_f = ($0 ~ /^### Doc follow-ups[[:space:]]*$/); next }
        in_f && /^- / { if ($0 !~ /^- *None/) print }
    ' "$f"
}

# Collect every Doc follow-up from finished tasks (review/ + done/) into ONE
# open backlog task, so doc gaps become work instead of dying in done/. The
# tracker is found by its marker; a new one is created (via create-task.sh)
# only when no tracker is waiting in backlog/. Each line carries its source
# task id and is filed once — trackers in any folder count as already filed —
# so this is safe to run at the start and end of every work and promote.
# Prints one summary line when it filed anything. Best-effort: never fails.
SPRINTBIAS_DOC_FOLLOWUPS_MARKER="<!-- sb:doc-followups -->"
sprintbias_file_doc_followups() {
    local marker="$SPRINTBIAS_DOC_FOLLOWUPS_MARKER" f id line item new=() trackers tracker=""
    local scripts_dir="$_SPRINTBIAS_LIB_DIR/scripts"
    trackers=$(grep -lF -- "$marker" docs/tasks/*/*.md 2>/dev/null || true)
    for f in $(grep -l '^### Doc follow-ups' docs/tasks/review/*.md docs/tasks/done/*.md 2>/dev/null || true); do
        grep -qF -- "$marker" "$f" && continue
        id=$(basename "$f" | grep -oE '^[0-9]+' || true)
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            item="- [ ] ${line#- } (from #${id:-?})"
            # Filed already when a tracker bullet holds "<text>" and
            # "(from #N)", whatever its checkbox, strike (~~), or a note added
            # around the text. The closing paren keeps #7 from matching #77.
            if [ -n "$trackers" ] && printf '%s\n' "$trackers" \
                | SB_FU_TEXT="${line#- }" SB_FU_FROM="(from #${id:-?})" xargs awk '
                    BEGIN { t = ENVIRON["SB_FU_TEXT"]; gsub(/~~/, "", t); fr = ENVIRON["SB_FU_FROM"] }
                    /^- / { l = $0; gsub(/~~/, "", l)
                            if (index(l, t) && index(l, fr)) { found = 1; exit } }
                    END { exit !found }' 2>/dev/null; then
                continue
            fi
            new+=("$item")
        done <<< "$(sprintbias_doc_followups "$f")"
    done
    [ ${#new[@]} -eq 0 ] && return 0

    tracker=$(printf '%s\n' "$trackers" | grep '^docs/tasks/backlog/' | head -1 || true)
    if [ -z "$tracker" ]; then
        local out
        out="$(bash "$scripts_dir/create-task.sh" "Bring project docs in step with landed work" 2>&1)" || true
        tracker="$(printf '%s\n' "$out" | grep -oE 'docs/tasks/backlog/[^ ]+\.md' | tail -1)"
        if [ -z "$tracker" ] || [ ! -f "$tracker" ]; then
            echo "▸ Could not file ${#new[@]} doc follow-up(s): task creation failed" >&2
            return 0
        fi
        awk -v m="$marker" -v dw="## $(sprintbias_done_when_heading "$tracker")" '
            /^## Problem/ { print; print ""; print "Landed work changed what project documents describe, or found gaps in"; print "them (a missing term, a moved source). Each item under ## Follow-ups names"; print "the document, what must change, and the task it came from."; print ""; skip = 1; next }
            index($0, dw) == 1 { print; print ""; print "- [ ] Every item under ## Follow-ups is resolved: the named document states"; print "      the current facts, or the item is struck with a one-line reason."; print "- [ ] Project-map items are settled: `./sprint.sh profile check` is clean."; print ""; skip = 1; next }
            /^## / { skip = 0 }
            skip { next }
            { print }
            END { print ""; print m; print "## Follow-ups"; print "" }
        ' "$tracker" > "$tracker.tmp" && mv "$tracker.tmp" "$tracker"
    fi
    printf '%s\n' "${new[@]}" >> "$tracker"
    local tid
    tid=$(basename "$tracker" | grep -oE '^[0-9]+' || true)
    echo "▸ Filed ${#new[@]} doc follow-up(s) into task #${tid:-?} ($tracker)"
    echo "    Docs to bring in step with this work. When you're ready:"
    echo "    → ./sprint.sh work ${tid:-$tracker}"
    return 0
}

# Print the conflict bullets recorded under ## Grounding → **Conflicts:** in
# FILE (one per line, leading "- " kept). Nothing when absent or "None found."
sprintbias_grounding_conflicts() {
    local f="$1"
    [ -f "$f" ] || return 0
    awk '
        /^## / { in_g = ($0 ~ /^## Grounding[[:space:]]*$/); in_c = 0; next }
        in_g && /^\*\*Conflicts:\*\*/ { in_c = 1; next }
        in_g && /^\*\*[A-Za-z ]+:\*\*/ { in_c = 0; next }
        in_c && /^- / { if ($0 !~ /^- *None/) print }
    ' "$f"
}

# Deterministic health check of the project map (no AI). Prints one line per
# problem to stdout and returns 1; prints nothing and returns 0 when current.
# Checks: the map exists, every path it lists exists, and nothing it tracks
# (listed paths, manifests, CI/deploy files, new top-level docs) changed since
# its **Checked:** stamp. Callers that only want a nudge: `… >&2 || true`.
sprintbias_profile_check() {
    local map="$SPRINTBIAS_PROJECT_MAP" issues=0 p missing=()
    if [ ! -f "$map" ]; then
        echo "▸ No project map yet — run ./sprint.sh profile so agents know where your sources of truth live."
        return 1
    fi

    # ## Known edges (lines appended by promote --reject) is read on every task:
    # past ~15 lines, ask for a prune.
    local edges
    edges=$(awk '/^## / { in_k = ($0 ~ /^## Known edges/); next } in_k && /^- / { n++ } END { print n + 0 }' "$map")
    if [ "$edges" -gt 15 ]; then
        echo "▸ Project map has $edges ## Known edges lines (keep ~15) — merge cases of one class, drop ones a test now covers: ./sprint.sh profile"
        issues=1
    fi

    # Listed paths: backticked, space-free tokens outside ## Commands and
    # ## Known edges, each tagged with its section. Every path must exist; only paths outside
    # ## Code are tracked for change (code folders change on every task).
    local tagged paths tracked
    tagged=$(awk '
        /^## / { sec = $0; next }
        sec ~ /^## (Commands|Known edges)/ || /^\*\*Checked:\*\*/ { next }
        { t = (sec ~ /^## Code/) ? "code" : "src"
          while (match($0, /`[^` ]+`/)) { print t "\t" substr($0, RSTART + 1, RLENGTH - 2); $0 = substr($0, RSTART + RLENGTH) } }
    ' "$map" | grep -vE $'\t''([*<>$]|-|https?:)' || true)
    paths=$(printf '%s\n' "$tagged" | cut -f2 | sed '/^$/d' | sort -u)
    tracked=$(printf '%s\n' "$tagged" | awk -F'\t' '$1 == "src" { print $2 }' | sort -u)
    while IFS= read -r p; do
        [ -z "$p" ] && continue
        [ -e "${p%/}" ] || missing+=("$p")
    done <<< "$paths"
    if [ ${#missing[@]} -gt 0 ]; then
        echo "▸ Project map lists ${#missing[@]} path(s) that no longer exist: ${missing[*]} — refresh: ./sprint.sh profile"
        issues=1
    fi

    local stamp sha date
    stamp=$(grep -m1 '^\*\*Checked:\*\*' "$map" || true)
    if [ -z "$stamp" ]; then
        echo "▸ Project map has no **Checked:** stamp — refresh: ./sprint.sh profile"
        return 1
    fi
    date=$(printf '%s' "$stamp" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1 || true)
    sha=$(printf '%s' "$stamp" | sed -n 's/.*@ *\([0-9a-fA-F]\{4,40\}\).*/\1/p')
    if [ -n "$sha" ] && git rev-parse --git-dir >/dev/null 2>&1 \
       && git cat-file -e "${sha}^{commit}" 2>/dev/null; then
        local changed added rel=() f l
        changed=$(git diff --name-only "$sha" -- 2>/dev/null || true)
        added=$( { git diff --name-only --diff-filter=A "$sha" -- 2>/dev/null; \
                   git ls-files --others --exclude-standard 2>/dev/null; } || true)
        while IFS= read -r f; do
            [ -z "$f" ] && continue
            [ "$f" = "$map" ] && continue
            case "${f##*/}" in
                package.json|Cargo.toml|go.mod|pyproject.toml|Gemfile|pom.xml|build.gradle*|composer.json|requirements*.txt|Makefile|Dockerfile*|docker-compose*|compose.y*ml|*.tf)
                    rel+=("$f"); continue ;;
            esac
            case "$f" in .github/workflows/*|.gitlab-ci.yml|.circleci/*) rel+=("$f"); continue ;; esac
            while IFS= read -r l; do
                [ -z "$l" ] && continue
                l="${l%/}"
                if [ "$f" = "$l" ] || [ "${f#"$l"/}" != "$f" ]; then rel+=("$f"); break; fi
            done <<< "$tracked"
        done <<< "$changed"
        while IFS= read -r f; do
            case "$f" in [!/]*.md) [ "${f%/*}" = "$f" ] && rel+=("$f") ;; esac
            case "$f" in docs/[!/]*.md) [ "${f#docs/*/}" = "$f" ] && rel+=("$f") ;; esac
        done <<< "$added"
        if [ ${#rel[@]} -gt 0 ]; then
            local uniq shown n
            uniq=$(printf '%s\n' "${rel[@]}" | sort -u)
            n=$(printf '%s\n' "$uniq" | wc -l | tr -d ' ')
            shown=$(printf '%s\n' "$uniq" | head -4 | paste -sd, - | sed 's/,/, /g')
            [ "$n" -gt 4 ] && shown="$shown, …"
            echo "▸ Project map may be out of date — $n file(s) it tracks changed since ${date:-its last check} ($shown) — refresh: ./sprint.sh profile"
            issues=1
        fi
    fi
    return "$issues"
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

# Question checklist for a chat subject (task-<id>, plan-<id>, …): the goal
# questions for the user, raised one at a time (ai/conversation.md → Many decisions). One path, named
# once, so the writer and the walker cannot drift. plan think writes the plan
# checklist; chat plan works it.
sprintbias_discuss_file() {
    printf 'docs/tmp/%s_discuss.md' "$1"
}
sprintbias_plan_discuss_file() {
    sprintbias_discuss_file "plan-$1"
}

# Count open items in a decision checklist: unchecked `- [ ]` lines, nested
# follow-ups included. Prints 0 when the file is absent.
sprintbias_discuss_open_count() {
    local f="$1" n=0
    [ -f "$f" ] && n=$(grep -cE '^[[:space:]]*- \[ \]' "$f" || true)
    printf '%s' "${n:-0}"
}

# Prompt line naming a session's decision checklist. With open items left from an
# earlier session it says resume there first; otherwise it names the file to
# list into when two or more decisions come up.
sprintbias_checklist_line() {
    local f n
    f="$(sprintbias_discuss_file "$1")"
    n="$(sprintbias_discuss_open_count "$f")"
    if [ "$n" -gt 0 ]; then
        printf '\nDECISION CHECKLIST: %s holds %s unchecked item(s) from an earlier session. Say so in one line, then run the work loop from the first unchecked line before anything else.' "$f" "$n"
    else
        printf '\nDECISION CHECKLIST: %s — when you hold two or more decisions for the user, write them here as a checklist and run the work loop (Conversation Method → Many decisions).' "$f"
    fi
}

# ── Shared walkthrough: dependent in next/ held on an undefined task in blocked/ ──
# Lexicon: <D> is DEPENDENT (on hold) — not blocked. <B> is BLOCKED (cannot
# start: no reasonable reading, or access or credentials the person holds). The executor HOLDS <D> until every Depends-on
# prerequisite leaves blocked/ and lands (review/ with proof, or done/). Both the no-id
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
        path_a="Hand this off to a FRESH context — do NOT resolve the dependency inline here. $(sprintbias_subagent_spawn_phrase "the dependency that cannot start yet (in blocked/)" chain), aimed at the MOST-UPSTREAM one first (the dependency whose own '**Depends on**' has no unresolved blocked deps left; break ties by lowest id). Its entire instruction: 'Run ./sprint.sh chat <dep-id> and carry that task as far toward READY as you can on your own — read any *Context from chat* note in its file, refine it, decide each open question by the finishing rule, write the pick into the body, record it as - Decided: X, because Y, and report those calls back.' Tell the user you spun up a fresh agent for <dep-id> and say in one line what it is picking up."
    else
        path_a="Hand this off — do NOT resolve the dependency inline here. Tell the user the exact command to run in a FRESH window:  ./sprint.sh chat <dep-id>  (for the most-upstream dependency still in blocked/). Keeping each session's context small is the point of chaining out."
    fi
    printf '%s' "─── DEPENDENT ON HOLD: <D> in next/ depends on <B> still in blocked/ ───
Lexicon: <D> is DEPENDENT (on hold until its prerequisite is done) — not blocked. <B> is BLOCKED (<B> cannot start yet). The executor ('work') HOLDS <D> in next/ until every '**Depends on**' prerequisite has landed (in review/ with a **Proof**: line) or is in done/. Do not merely report this — close the loop. Pick the path best practice supports (A when the dependency is real and still needed, B when <D> should leave the sprint), say which and why in one line, and act on it; the user can redirect with one keystroke. Do NOT frame 'drop the Depends on line' as a way out of a genuine prerequisite — that only makes <D> LOOK runnable while the work it needs is still undone (the folder-satisfaction trap).

PATH A — RESOLVE THE BLOCKED DEPENDENCY <B> (choose when the dependency is real and still needed):
${path_a}
Either way, chat's own close-the-loop branch re-enters the sprint only through the shared gate (bash docs/sprintbias/scripts/promote-to-sprint.sh <B-file>) — READY → next/, BLOCKED stays when it still cannot start — which releases <D> from hold when gate grades READY. You do not rebuild that machinery here; you point at chat <B>.

PATH B — DEMOTE THE DEPENDENT TASK <D> BACK TO backlog/ (choose to pull it out of the sprint):
Action this INLINE: move <D> out of the sprint so next/ holds no work waiting on a task that cannot start yet —  git mv docs/tasks/next/<D-file> docs/tasks/backlog/<D-file> || mv docs/tasks/next/<D-file> docs/tasks/backlog/<D-file>. THEN RE-SCAN next/ for any OTHER task that also depends on <B>: the preflight already emitted a SEPARATE finding for each (next dependent, dep in blocked/) pair, so <B>'s other dependents are already in the findings list — recognize them by the same blocked id <B>, do not run a fresh board scan. Only when NONE remain may you say 'the sprint no longer contains work waiting on <B>.' If siblings remain, name them and offer to resolve each in turn (A or B).

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

# sprintbias_task_summary FILE -> one sentence for a history record: the
# **Summary**: line under ## Completed; else the first sentence of the prose
# that opens ## Completed (before any ### heading or list); else empty.
# Shared by `plan done` and `history record`.
sprintbias_task_summary() {
    # The **Summary**: line is taken whole (wrapped lines joined); only the
    # prose fallback is cut to its first sentence. CRLF files read the same.
    awk '
      { sub(/\r$/, "") }
      /^## / { if (on) exit; if ($0 ~ /^## Completed[ \t]*$/) on = 1; next }
      !on { next }
      insum {
        if ($0 ~ /^[ \t]*$/ || /^#/ || /^\*\*[^*]+\*\*:/ || /^[ \t]*([-*+]|[0-9]+\.)[ \t]/) exit
        sub(/^[ \t]+/, ""); summ = summ " " $0; next
      }
      /^\*\*Summary\*\*:/ { sub(/^\*\*Summary\*\*:[ \t]*/, ""); summ = $0; found = 1; insum = 1; next }
      stop { next }
      /^###/ || /^[ \t]*([-*+]|[0-9]+\.)[ \t]/ { stop = 1; next }
      /^[ \t]*$/ { if (prose != "") stop = 1; next }
      /^\*\*[^*]+\*\*:/ || /^<!--/ { next }
      { prose = prose (prose == "" ? "" : " ") $0 }
      END { if (found) print "S" summ; else print "P" prose }' "$1" \
      | sed -E 's/^([SP])[[:space:]]+/\1/; /^P/s/([.!?])[[:space:]].*$/\1/; s/[[:space:]]+$//; s/^[SP]//'
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

# ── Task done-when sections ──────────────────────────────────────────
# A task proves done under '## Done when (automated)' (outcomes plus the tests
# or commands that prove them) and lists what a person checks under
# '## Signoff (human)'. Older tasks carry '## Success criteria' instead; it reads
# as Done when (automated). The heading text is a contract: every reader goes
# through these helpers, so the fallback lives in one place.
SPRINTBIAS_DONE_WHEN_HEADING="Done when (automated)"
SPRINTBIAS_SIGNOFF_HEADING="Signoff (human)"
SPRINTBIAS_DONE_WHEN_LEGACY_HEADING="Success criteria"

# sprintbias_done_when_heading FILE -> the heading text (no '## ') that holds
# FILE's automated done-when: the new heading when present, else the old one.
# With neither, prints the new heading (what a writer should create) and
# returns 1.
sprintbias_done_when_heading() {
    local f="$1"
    if grep -qE '^## Done when \(automated\)[[:space:]]*$' "$f" 2>/dev/null; then
        printf '%s' "$SPRINTBIAS_DONE_WHEN_HEADING"
    elif grep -qE '^## Success criteria[[:space:]]*$' "$f" 2>/dev/null; then
        printf '%s' "$SPRINTBIAS_DONE_WHEN_LEGACY_HEADING"
    else
        printf '%s' "$SPRINTBIAS_DONE_WHEN_HEADING"
        return 1
    fi
}

# sprintbias_done_when FILE -> body of the task's automated done-when section
# (stdout), HTML comments such as the template's sb:hint scaffold removed.
# Empty when the task has neither heading.
sprintbias_done_when() {
    local f="$1" h
    h="$(sprintbias_done_when_heading "$f")" || return 0
    awk -v h="## $h" '
        !cap {
            line = $0; sub(/[[:space:]]+$/, "", line)
            if (line == h) cap = 1
            next
        }
        /^## / { exit }
        incom { if (index($0, "-->")) incom = 0; next }
        {
            gsub(/<!--.*-->/, "")
            if (index($0, "<!--")) { sub(/<!--.*/, ""); incom = 1 }
            print
        }
    ' "$f" 2>/dev/null
}

# sprintbias_done_when_testable FILE -> exit 0 when the automated done-when
# names at least one test or command, written in backticks
# (`bash docs/tests/test-x.sh`, `npm test`). A backticked heading such as
# `## Problem` does not count. The gate keeps a task out of next/ until this holds.
sprintbias_done_when_testable() {
    sprintbias_done_when "$1" | grep -qE '`[^`#[:space:]][^`]*`'
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
# Invariant enforcer: first takes each (Suggestion: …) as its answer; a
# question with none left keeps READY/COMPLETE out of next/. Rewrites stamp to BLOCKED, ensures a ## BLOCKED section, moves the
# file into BLOCKED_DIR (default docs/tasks/blocked). Loud report on stderr.
# Exit 0 if demoted, 1 if not applicable (no open Qs, every Q settled by its
# suggestion, or already blocked path without READY/COMPLETE stamp needing fix).
sprintbias_demote_open_questions() {
    local file="$1"
    local blocked_dir="${2:-docs/tasks/blocked}"
    local name id qs verdict dest
    [ -f "$file" ] || return 1
    sprintbias_has_open_questions "$file" || return 1
    # Speed first: a question with a (Suggestion: …) is answered by it.
    sprintbias_accept_suggestions "$file" >/dev/null 2>&1 || true
    if ! sprintbias_has_open_questions "$file"; then
        printf '▸ %s: took the suggested answer to each open question (## Notes)\n' "$(basename "$file" | cut -d- -f1)" >&2
        return 1
    fi
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
            echo "A question below has no reasonable answer yet, so the task cannot start."
            echo "Give it one (write the answer into the body and delete the question):"
            echo "./sprint.sh chat $id — then run it: ./sprint.sh work $id"
            echo ""
            echo "$qs" | sed 's/^/- /'
        } >> "$file"
    fi

    printf '⊘ %s: READY/COMPLETE + open questions — demoted to blocked/\n' "$id" >&2
    printf '  Open questions still pending:\n' >&2
    printf '%s\n' "$qs" | sed 's/^/    • /' >&2
    printf '  File: %s\n' "$file" >&2
    printf '  Answer it:  ./sprint.sh chat %s   # turn the answer into body instruction\n' "$id" >&2
    printf '  Then run:   ./sprint.sh work %s   # gates it back into next/ and works it\n' "$id" >&2
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
        printf '  Answer each listed task:  ./sprint.sh chat <id>, then ./sprint.sh work <id>\n\n' >&2
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

# sprintbias_plan_followups PLAN_ID
# Open tasks (backlog/next/doing/blocked) that came out of plan PLAN_ID's work —
# stamped **From plan**: PLAN_ID — and are not already bound to another plan.
# One id per line, lowest first. Shared by `newplan … from:N` and `plan done`.
sprintbias_plan_followups() {
    local pid="$1" stage f id from plan
    for stage in "${SPRINTBIAS_OPEN_STAGES[@]}"; do
        for f in "docs/tasks/$stage"/*.md; do
            [ -f "$f" ] || continue
            from=$(sprintbias_meta_value "$f" "From plan"); from="${from//[[:space:]#]/}"
            [ "$from" = "$pid" ] || continue
            plan=$(sprintbias_meta_value "$f" "Plan"); plan="${plan//[[:space:]#]/}"
            case "$plan" in ""|none|None|"$pid") ;; *) continue ;; esac
            id=$(basename "$f" | grep -oE '^[0-9]+' || true)
            [ -n "$id" ] && printf '%s\n' "$id"
        done
    done | sort -n
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

# sprintbias_has_proof FILE -> 0 when FILE records passing test proof: a
# '**Proof**:' line under its column-0 '## Completed' heading, in the plan 28
# format '**Proof**: YYYY-MM-DD · <targeted test commands> · pass'. The line
# must start with a date and end in 'pass'; a proof line that records a
# failure, or one outside ## Completed (template hints, Notes), does not count.
sprintbias_has_proof() {
    local file="$1"
    [ -f "$file" ] || return 1
    awk '
        /^## Completed[[:space:]]*$/ { inc = 1; next }
        /^## / { inc = 0 }
        inc && /^\*\*Proof\*\*:[[:space:]]*[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ \
            && /[[:space:]]pass[[:space:]]*$/ { found = 1; exit }
        END { exit found ? 0 : 1 }
    ' "$file"
}

# The hold reason for a review/ prerequisite with no proof line. One spelling
# so every hold line (work, promote) reads the same.
# shellcheck disable=SC2034
SPRINTBIAS_UNPROVEN_LABEL="in review, unproven"

# sprintbias_dep_landed ID -> 0 when prerequisite ID is met: its file is in
# done/ (signed off), or in review/ with a proof line (landed). 1 for every
# other stage, and for review/ without proof ("in review, unproven"). An ID
# with no file returns 1 here; each caller applies its own missing-id policy
# (sprintbias_unmet_deps reads it as archived-complete, promote holds on it).
# The one rule for "is this prerequisite met": work, loop (through work),
# promote's close gate and the queue prompts all route through it.
sprintbias_dep_landed() {
    local path fix
    path=$(sprintbias_task_path "$1") || return 1
    case "$path" in
        docs/tasks/done/*)   return 0 ;;
        docs/tasks/review/*)
            sprintbias_has_proof "$path" || return 1
            # A rejected original (**Held**: fix #N) releases nothing until
            # every fix it names has landed.
            for fix in $(sprintbias_held_fixes "$path"); do
                sprintbias_dep_landed "$fix" || return 1
            done
            return 0 ;;
        *)                   return 1 ;;
    esac
}

# sprintbias_held_fixes FILE -> the fix task ids named on FILE's '**Held**:'
# line ('**Held**: fix #412' or, after a second rejection, 'fix #412, fix
# #415'), one per line. Empty when the task carries no hold.
sprintbias_held_fixes() {
    sprintbias_meta_value "$1" "Held" | { grep -oE '[0-9]+' || true; }
}

# sprintbias_add_test_log FILE LINE -> append LINE to FILE's '## Test log'
# section, creating the section (before ## Completed, else at the end of the
# file) when it is missing.
sprintbias_add_test_log() {
    local file="$1" line="$2" tmp
    [ -f "$file" ] || return 1
    tmp=$(mktemp "${TMPDIR:-/tmp}/sprintbias-testlog.XXXXXX") || return 1
    SB_LINE="$line" awk '
        BEGIN { l = ENVIRON["SB_LINE"] }
        function flush() { if (pend != "") { printf "%s", pend; pend = "" } }
        /^## Test log[[:space:]]*$/ { intl = 1; have = 1; print; next }
        intl && /^## / { print l; print ""; flush(); intl = 0; done = 1; print; next }
        intl && /^[[:space:]]*$/ { pend = pend $0 "\n"; next }
        intl { flush(); print; next }
        !have && !done && /^## Completed[[:space:]]*$/ {
            print "## Test log"; print ""; print l; print ""; done = 1
        }
        { print }
        END {
            if (intl) { print l; done = 1 }
            else if (!done) { print ""; print "## Test log"; print ""; print l }
        }
    ' "$file" > "$tmp" && cat "$tmp" > "$file"
    rm -f "$tmp"
}

# sprintbias_add_known_edge ID "report" — append one line to the project map's
# ## Known edges (created when missing): the rejected case, so later work on
# that area tests it. Silent no-op without a map. Called by promote --reject.
sprintbias_add_known_edge() {
    local id="$1" text map="$SPRINTBIAS_PROJECT_MAP" tmp
    [ -f "$map" ] || return 0
    text=$(printf '%s\n' "$2" | sed -E 's/^[[:space:]]*([-*]|[0-9]+[.)])[[:space:]]+//' \
        | sed '/^[[:space:]]*$/d' | paste -sd' ' - | tr -s ' ')
    [ -n "$text" ] || return 0
    [ "${#text}" -gt 200 ] && text="${text:0:197}..."
    tmp="$map.edge.$$"
    SB_EDGE="- $text (#$id)" awk '
        BEGIN { e = ENVIRON["SB_EDGE"] }
        /^## / { if (in_k && !done) { print e; print ""; done = 1 } in_k = ($0 ~ /^## Known edges/) }
        in_k && /^[[:space:]]*$/ && !done { blank++; next }
        in_k && blank { for (; blank > 0; blank--) print "" }
        { print }
        END {
            if (in_k && !done) { print e; done = 1 }
            if (!done) { print ""; print "## Known edges"; print ""; print e }
        }' "$map" > "$tmp" && mv "$tmp" "$map"
    return 0
}

# sprintbias_file_fix_task ORIGINAL_ID "report" [TITLE] -> file a linked fix
# task for a rejected review/ task (TITLE defaults to "Fix #ID: <its title>"). One shared path for promote --reject and for failing
# suite output (plan sign-off). The fix task goes through create-task.sh, so its
# id is drawn under the id lock, and carries:
#   **Fixes**: #ORIGINAL_ID, plus the original's **Crew**, **Plan** and **Tests**
#     (and a member line on that plan, right under the original's)
#   ## Done when (automated) — one "add a test" line per reported item; an item
#     marked 'human:' / 'signoff:', or one about look, feel or wording, goes
#     under ## Signoff (human) instead
#   ## Test log — the report verbatim
# Items: each '- ' / '* ' / 'N. ' bullet, else each blank-line paragraph (a
# multi-line error excerpt stays one item). The original stays in review/ with
# '**Held**: fix #NEW' and a Test log line. Each dependent of the original that
# is landed (review/ + proof) or signed off (done/) gets a re-check line in its
# ## Test log; done/ dependents are flagged in the output and never moved.
# Sets SPRINTBIAS_FIX_ID / SPRINTBIAS_FIX_TASK. Returns 1 (message on stderr)
# when ORIGINAL_ID is not in review/, the report is empty, or creation fails.
sprintbias_file_fix_task() {
    local orig_id="$1" report="$2" orig title out fix fid today
    local crew plan tests held items item first testable="" human="" proofcmd=""
    local dep dpath stage p kind signed=0
    SPRINTBIAS_FIX_ID=""; SPRINTBIAS_FIX_TASK=""
    orig=$(sprintbias_task_path "$orig_id") || orig=""
    case "$orig" in
        docs/tasks/review/*) ;;
        # Found broken after sign-off: the fix is linked, the original stays done.
        docs/tasks/done/*) signed=1 ;;
        "") echo "✗ No task #$orig_id found." >&2; return 1 ;;
        *)  echo "✗ #$orig_id is in ${orig#docs/tasks/}; reject works on landed work (review/ or done/)." >&2
            echo "  It has not landed yet — finish it first:  ./sprint.sh work $orig_id" >&2
            return 1 ;;
    esac
    if [ -z "$(printf '%s' "$report" | tr -d '[:space:]')" ]; then
        echo "✗ Say what is wrong: the report becomes the fix task's tests." >&2
        return 1
    fi
    today="${SPRINTBIAS_TODAY:-$(date +%Y-%m-%d)}"
    title=$(task_title "$orig")
    out=$(bash "$_SPRINTBIAS_LIB_DIR/scripts/create-task.sh" "${3:-Fix #$orig_id: $title}" 2>&1) || {
        printf '%s\n' "$out" >&2; return 1; }
    fix=$(printf '%s\n' "$out" | grep -oE 'docs/tasks/backlog/[^ ]+\.md' | tail -1)
    [ -n "$fix" ] && [ -f "$fix" ] || { printf '%s\n' "$out" >&2; return 1; }
    fid=$(task_id "$fix")

    crew=$(sprintbias_meta_value "$orig" "Crew")
    plan=$(sprintbias_meta_value "$orig" "Plan")
    tests=$(sprintbias_meta_value "$orig" "Tests")
    _sprintbias_write_field "$fix" "Fixes" "#$orig_id" || true
    [ -n "$crew" ] && _sprintbias_write_field "$fix" "Crew" "$crew"
    [ -n "$tests" ] && _sprintbias_write_field "$fix" "Tests" "$tests"
    case "$tests" in ""|none|None) ;; *)
        for p in $(printf '%s' "$tests" | tr ',' ' '); do
            proofcmd="${proofcmd:+$proofcmd, }\`$(sprintbias_test_cmd "$p")\`"
        done ;;
    esac

    # Each reported item → a test to add, or a human check.
    items=$(printf '%s\n' "$report" | awk '
        function emit() { if (cur != "") print cur; cur = "" }
        /^[[:space:]]*$/ { emit(); next }
        /^[[:space:]]*([-*]|[0-9]+[.)])[[:space:]]+/ {
            emit(); sub(/^[[:space:]]*([-*]|[0-9]+[.)])[[:space:]]+/, ""); cur = $0; bul = 1; next }
        { sub(/^[[:space:]]+/, ""); cur = (cur == "") ? $0 : cur " " $0 }
        END { emit() }')
    while IFS= read -r item; do
        [ -n "$item" ] || continue
        first="$item"
        [ "${#first}" -gt 160 ] && first="${first:0:157}..."
        if printf '%s' "$item" | grep -qiE '^(human|signoff):'; then
            human="$human- [ ] $(printf '%s' "$first" | sed -E 's/^[A-Za-z]+:[[:space:]]*//')
"
        elif printf '%s' "$item" | grep -qiE '(^|[^a-z])(looks?|feels?|wording|tone|ugly|confusing|hard to read)([^a-z]|$)'; then
            human="$human- [ ] $first
"
        else
            testable="$testable- [ ] Add a test that fails on this, then make it pass: $first${proofcmd:+ ($proofcmd)}
"
        fi
    done <<EOF
$items
EOF
    [ -n "$proofcmd" ] && testable="$testable- [ ] The original's tests still pass: $proofcmd
"
    [ -n "$testable" ] || testable="- [ ] Name the test that proves #$orig_id is fixed, in backticks.
"

    SB_DW="$testable" SB_SO="$human" SB_REP="$report" \
    awk -v oid="$orig_id" -v otitle="$title" -v opath="$orig" -v today="$today" -v signed="$signed" '
        BEGIN { dw = ENVIRON["SB_DW"]; so = ENVIRON["SB_SO"]; rep = ENVIRON["SB_REP"] }
        /^## Problem[[:space:]]*$/ {
            print; print ""
            if (signed) {
                print "Task #" oid " (" otitle ") was signed off, then found broken on " today "."
                print "The reported problems are under ## Test log. Fix them in this task."
            } else {
                print "Task #" oid " (" otitle ") was sent back from review on " today "."
                print "The reported problems are under ## Test log. Fix them in this task; #" oid
                print "stays in review/ (Held) and releases its dependents once this lands."
            }
            print ""; skip = 1; next }
        /^## Done when \(automated\)[[:space:]]*$/ { print; print ""; printf "%s", dw; print ""; skip = 1; next }
        /^## Signoff \(human\)[[:space:]]*$/ { print; print ""; if (so != "") { printf "%s", so; print "" } ; skip = 1; next }
        /^## References[[:space:]]*$/ {
            print; print ""; print opath; print ""
            print "## Test log"; print ""
            print "- " today " · " (signed ? "found broken after sign-off" : "sent back from review") " (#" oid "):"; print ""
            print "```"; print rep; print "```"; print ""
            skip = 1; next }
        /^## / { skip = 0 }
        /^<!-- sb:hint  After work only/ || /^<!-- sb:hint[[:space:]]*$/ { skip = 0 }
        skip { next }
        { print }
    ' "$fix" > "$fix.tmp" && mv "$fix.tmp" "$fix"

    # **Plan**: list the fix on the original's plan (the plan file is the
    # membership authority), right under the original's member line.
    case "$plan" in ""|none|None) ;; *)
        p=$(sprintbias_find_plan "$plan" 2>/dev/null || true)
        if [ -n "$p" ] && [ -f "$p" ]; then
            SB_LINE="- #$fid — $(task_title "$fix")" awk -v oid="$orig_id" '
                BEGIN { line = ENVIRON["SB_LINE"] }
                { print }
                !ins && $0 ~ ("^- (\\[[ xX]\\] )?#" oid "([^0-9]|$)") { print line; ins = 1 }
            ' "$p" > "$p.tmp" && mv "$p.tmp" "$p"
        fi
        sprintbias_set_task_plan "$fix" "$plan" >/dev/null || true ;;
    esac

    SPRINTBIAS_FIX_ID="$fid"; SPRINTBIAS_FIX_TASK="$fix"
    if [ "$signed" -eq 1 ]; then
        # Already signed off: a log line links the fix; nothing is held.
        sprintbias_add_test_log "$orig" "- $today · found broken after sign-off: $(printf '%s\n' "$report" | head -1) → fix #$fid"
        echo "✓ Filed fix task #$fid → $fix"
        echo "  **Fixes**: #$orig_id · **Crew**: ${crew:-none} · **Plan**: ${plan:-none}"
        echo "  #$orig_id stays in done/ (signed off); the fix is linked in its ## Test log"
        return 0
    fi
    # The original stays in review/ and holds its dependents until the fix lands.
    held=$(sprintbias_meta_value "$orig" "Held")
    _sprintbias_write_field "$orig" "Held" "${held:+$held, }fix #$fid" || true
    sprintbias_add_test_log "$orig" "- $today · sent back: $(printf '%s\n' "$report" | head -1) → fix #$fid"

    echo "✓ Filed fix task #$fid → $fix"
    echo "  **Fixes**: #$orig_id · **Crew**: ${crew:-none} · **Plan**: ${plan:-none}"
    echo "  #$orig_id stays in review/ with **Held**: fix #$fid"

    # Dependent trace.
    for dep in $(sprintbias_dependents_of "$orig_id"); do
        dpath=$(sprintbias_task_path "$dep") || continue
        stage=$(sprintbias_task_stage "$dep")
        kind=""
        case "$stage" in
            done)   kind="signed off" ;;
            review) sprintbias_has_proof "$dpath" && kind="landed" ;;
        esac
        if [ -z "$kind" ]; then
            echo "  · #$dep ($stage) waits on #$orig_id — held until fix #$fid lands"
            continue
        fi
        sprintbias_add_test_log "$dpath" "- $today · re-check: prerequisite #$orig_id was sent back (fix #$fid); re-run this task's tests once #$fid lands"
        if [ "$stage" = "done" ]; then
            echo "  ⚑ #$dep is signed off (done/) and builds on #$orig_id — re-check line added, not moved"
        else
            echo "  ↺ #$dep ($kind) builds on #$orig_id — re-check line added to its ## Test log"
        fi
    done
    return 0
}

# sprintbias_unmet_deps FILE -> prints the space-separated dependency task IDs that
# are NOT yet met: those still in backlog/, next/, doing/, or blocked/, and
# those in review/ without a proof line (in review, unproven). Empty output
# means every declared dependency has landed (review/ with proof) or is signed
# off (done/), or none were declared — so the task is clear to run.
#
# Reads the '**Depends on**:' metadata field via sprintbias_iter_id_list. 'none',
# an empty value, or a missing field all mean no dependencies. An ID that
# resolves to no task file anywhere is treated as complete (the task finished
# and was archived), so a stale reference can never wedge a queue. Malformed
# tokens are ignored here (queue gating); validate-tasks.sh reports them.
# Lexicon: unmet deps put the task on hold (dependent) — they do not make it
# blocked. Self-clearing: as each dependency lands in review/ with proof, the
# dependent becomes runnable on the next pass with no human action.
sprintbias_unmet_deps() {
    local file="$1" raw id unmet=""
    raw=$(sprintbias_meta_value "$file" "Depends on")
    [ -z "$raw" ] && return 0
    while read -r kind tok; do
        [ "$kind" = "id" ] || continue
        id="$tok"
        # Missing → archived-complete; otherwise the shared landed rule decides.
        if [ -n "$(sprintbias_task_stage "$id")" ] && ! sprintbias_dep_landed "$id"; then
            unmet="$unmet $id"
        fi
    done <<EOF
$(sprintbias_iter_id_list "$raw")
EOF
    [ -n "$unmet" ] && printf '%s' "$unmet" | tr ' ' '\n' \
        | grep -E '^[0-9]+$' | sort -un | tr '\n' ' ' | sed 's/[[:space:]]*$//'
    return 0
}

# sprintbias_deps_not_sprint_ready FILE -> space-separated dependency task IDs
# that are still outside the sprint: sitting in backlog/ or blocked/. Empty
# output means every declared dependency is already in next/ or doing/ (in the
# sprint), finished (review/ or done/), folded, or archived (no file — treated
# as complete). Distinct from sprintbias_unmet_deps, which also treats next/
# and doing/ as unmet (those are frontier holds for *running* a task). This
# helper answers "may this task enter next/?" — a task whose prerequisite is
# still in backlog/ or blocked/ is not workable for the sprint yet.
sprintbias_deps_not_sprint_ready() {
    local file="$1" raw id class out=""
    raw=$(sprintbias_meta_value "$file" "Depends on")
    [ -z "$raw" ] && return 0
    while read -r kind tok; do
        [ "$kind" = "id" ] || continue
        id="$tok"
        # missing → done (archived-complete); folded is never open work.
        class=$(sprintbias_classify_dep "$id" done)
        case "$class" in
            backlog|blocked) out="$out $id" ;;
        esac
    done <<EOF
$(sprintbias_iter_id_list "$raw")
EOF
    [ -n "$out" ] && printf '%s' "$out" | tr ' ' '\n' \
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
        | { grep -oE '[0-9]+' || true; } | awk '!seen[$0]++'
}

# sprintbias_plan_waves PLAN_FILE -> the plan's open members laid out in waves
# for parallel work: wave 1 has no open in-plan prerequisite, wave N waits only
# on earlier waves. Each line names the task, its stage, its **Crew** holder,
# and what it waits on. Finished members (review/, done/) are left out. A
# dependency cycle is listed as Unordered rather than looping. bash 3.2: plain
# space-padded strings, no associative arrays. Always returns 0.
sprintbias_plan_waves() {
    local plan="$1" id path stage open=" " deps=" " remaining wave=0 ready line
    local d crew after outside
    for id in $(sprintbias_plan_member_ids "$plan"); do
        stage="$(sprintbias_task_stage "$id" 2>/dev/null || true)"
        case "$stage" in backlog|next|doing|blocked) open="$open$id " ;; esac
    done
    [ "$open" = " " ] && { echo "Every member is finished (review/ or done/)."; return 0; }
    # deps: "id:dep,dep;" pairs, in-plan open prerequisites only.
    for id in $open; do
        path="$(sprintbias_task_path "$id" 2>/dev/null || true)"
        d=""
        while read -r kind tok; do
            [ "$kind" = id ] && case "$open" in *" $tok "*) d="$d$tok," ;; esac
        done <<EOF
$(sprintbias_iter_id_list "$(sprintbias_meta_value "$path" "Depends on")")
EOF
        deps="$deps$id:$d; "
    done
    remaining="$open"
    while [ -n "${remaining// /}" ]; do
        ready=""
        for id in $remaining; do
            d="${deps#* $id:}"; d="${d%%;*}"
            local blocked=0 x
            for x in ${d//,/ }; do
                case "$remaining" in *" $x "*) blocked=1 ;; esac
            done
            [ "$blocked" -eq 0 ] && ready="$ready$id "
        done
        if [ -z "$ready" ]; then
            echo "Unordered (a dependency cycle holds these; settle it first):"
            for id in $remaining; do echo "- #$id"; done
            break
        fi
        wave=$((wave + 1))
        if [ "$wave" -eq 1 ]; then
            echo "Wave 1 (start together):"
        else
            echo "Wave $wave (each starts when its own prerequisites land in review/ with proof):"
        fi
        for id in $ready; do
            path="$(sprintbias_task_path "$id" 2>/dev/null || true)"
            stage="$(sprintbias_task_stage "$id" 2>/dev/null || true)"
            line="- #$id $(task_title "$path") [$stage/]"
            crew="$(sprintbias_meta_value "$path" Crew)"
            case "$crew" in ''|[Nn]one) ;; *) line="$line crew: $crew" ;; esac
            d="${deps#* $id:}"; d="${d%%;*}"; d="${d%,}"
            [ -n "$d" ] && line="$line, after #${d//,/, #}"
            outside=""
            for x in $(sprintbias_unmet_deps "$path"); do
                case "$open" in *" $x "*) ;; *) outside="$outside #$x" ;; esac
            done
            [ -n "$outside" ] && line="$line, waits outside the plan on$outside"
            echo "$line"
            remaining="${remaining/ $id / }"
        done
    done
    return 0
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

# sprintbias_plan_args [--bare] ARG… — the one plan-target reader. Fills
# SPRINTBIAS_ARGS with ARG… where `plan:N` and `plan N` both become `plan:N`.
# With --bare, a bare number in target position is a task id first: no task but
# a plan N → `plan:N` (one line says so); both → the task, with a one-line hint.
# A number right after count / --jobs / --rounds / --model, or after `--`, is
# left alone. Messages go to stderr. Used by work, promote, polish and crew.
sprintbias_plan_args() {
    local bare=0 a skip=0 rest=0 prev_plan=0
    [ "${1:-}" = "--bare" ] && { bare=1; shift; }
    SPRINTBIAS_ARGS=()
    for a in "$@"; do
        if [ "$prev_plan" -eq 1 ]; then
            prev_plan=0
            case "$a" in ''|*[!0-9]*) SPRINTBIAS_ARGS+=("plan") ;; *) SPRINTBIAS_ARGS+=("plan:$a"); continue ;; esac
        fi
        if [ "$rest" -eq 1 ] || [ "$skip" -eq 1 ]; then skip=0; SPRINTBIAS_ARGS+=("$a"); continue; fi
        case "$a" in
            --) rest=1 ;;
            count|--jobs|--rounds|--model) skip=1 ;;
            plan) prev_plan=1; continue ;;
            [0-9]*)
                if [ "$bare" -eq 1 ] && [[ "$a" =~ ^[0-9]+$ ]] && sprintbias_find_plan "$a" >/dev/null; then
                    if sprintbias_task_path "$a" >/dev/null; then
                        echo "(plan $a also exists: plan $a)" >&2
                    else
                        echo "▸ No task $a — using plan $a." >&2
                        a="plan:$a"
                    fi
                fi ;;
        esac
        SPRINTBIAS_ARGS+=("$a")
    done
    [ "$prev_plan" -eq 1 ] && SPRINTBIAS_ARGS+=("plan")
    return 0
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

# sprintbias_member_standing ID -> where a plan member stands, by plan 28's
# policy: open (backlog/next/doing/blocked) · landed (review/ with proof) ·
# held (review/ with proof, a **Held**: fix not yet landed — show it with
# sprintbias_held_label) · unproven (review/ without proof, held or not —
# $SPRINTBIAS_UNPROVEN_LABEL) · signed-off (done/) · missing (no task file) ·
# human (the plan's human test, not yet in done/ — the person's turn, never
# agent work, so it never keeps a plan from LANDED).
# The landed test is sprintbias_dep_landed, the one rule dependents use;
# nothing is stamped.
sprintbias_member_standing() {
    local path
    path=$(sprintbias_task_path "$1") || { printf 'missing'; return 0; }
    case "$path" in
        docs/tasks/done/*)   printf 'signed-off'; return 0 ;;
    esac
    sprintbias_is_human_task "$path" && { printf 'human'; return 0; }
    case "$path" in
        docs/tasks/review/*)
            if ! sprintbias_has_proof "$path"; then printf 'unproven'
            elif sprintbias_dep_landed "$1"; then printf 'landed'
            else printf 'held'
            fi ;;
        *)                   printf 'open' ;;
    esac
}

# sprintbias_held_open_fixes ID -> the fix ids on ID's **Held**: line that
# have not landed yet, one per line. Empty when ID holds on nothing.
sprintbias_held_open_fixes() {
    local path fix
    path=$(sprintbias_task_path "$1") || return 0
    for fix in $(sprintbias_held_fixes "$path"); do
        sprintbias_dep_landed "$fix" || printf '%s\n' "$fix"
    done
    return 0
}

# sprintbias_held_label ID -> how a held member reads everywhere (plan check,
# status, promote plan:N): 'held: fix #412', or 'held: fix #412, fix #415'.
sprintbias_held_label() {
    local fixes
    fixes=$(sprintbias_held_open_fixes "$1" | sed 's/^/fix #/' | paste -sd, - | sed 's/,/, /g')
    printf 'held: %s' "$fixes"
}

# sprintbias_plan_open_fixes PLAN_FILE -> "FIX_ID TARGET_ID" per open fix task:
# a task in backlog/next/doing/blocked carrying '**Fixes**: #N', where N or the
# fix task itself is a member of the plan. An open fix is open plan work.
sprintbias_plan_open_fixes() {
    local members stage f fid target
    members=" $(sprintbias_plan_member_ids "$1" | tr '\n' ' ') "
    for stage in "${SPRINTBIAS_OPEN_STAGES[@]}"; do
        for f in docs/tasks/"$stage"/[0-9]*.md; do
            [ -f "$f" ] || continue
            target=$(sprintbias_meta_value "$f" "Fixes" | grep -oE '[0-9]+' | head -1) || true
            [ -n "$target" ] || continue
            fid=$(task_id "$f")
            case "$members" in
                *" $target "*|*" $fid "*) printf '%s %s\n' "$fid" "$target" ;;
            esac
        done
    done
    return 0
}

# sprintbias_plan_counts PLAN_FILE -> one line of counts from live folders:
#   "open landed signed unproven missing total fixes moved held human"
# The plan's human test is not agent work: until it reaches done/ it counts
# only as human (an open human test), never in total.
# open/landed/signed are plan 28's three counts; unproven = review/ without
# proof; fixes = open fix tasks (sprintbias_plan_open_fixes); moved = members
# past next/ (doing/review/done); held = review/ with proof and a fix not yet
# landed. held and human come last so readers of the first eight fields stay
# correct.
sprintbias_plan_counts() {
    local f="$1" mid st open=0 landed=0 signed=0 unproven=0 missing=0 total=0 moved=0 held=0 human=0 fixes
    while IFS= read -r mid; do
        [ -n "$mid" ] || continue
        total=$((total + 1))
        st=$(sprintbias_member_standing "$mid")
        case "$st" in
            open)       open=$((open + 1))
                        [ "$(sprintbias_task_stage "$mid")" = "doing" ] && moved=$((moved + 1)) ;;
            landed)     landed=$((landed + 1)); moved=$((moved + 1)) ;;
            unproven)   unproven=$((unproven + 1)); moved=$((moved + 1)) ;;
            held)       held=$((held + 1)); moved=$((moved + 1)) ;;
            signed-off) signed=$((signed + 1)); moved=$((moved + 1)) ;;
            human)      total=$((total - 1)); human=$((human + 1)) ;;
            *)          missing=$((missing + 1)) ;;
        esac
    done <<EOF
$(sprintbias_plan_member_ids "$f")
EOF
    fixes=$(sprintbias_plan_open_fixes "$f" | grep -c . || true)
    printf '%s %s %s %s %s %s %s %s %s %s\n' "$open" "$landed" "$signed" "$unproven" \
        "$missing" "$total" "${fixes:-0}" "$moved" "$held" "$human"
}

# sprintbias_plan_state PLAN_FILE -> the plan state, computed from the folders
# and never stamped into the file (the **Status:** latch stays DRAFT/READY/
# STARTED):
#   SIGNED OFF  every member in done/ — plan done can retire it
#   LANDED      every member landed or signed off, none open, no open fix —
#               ready for the full suite and sign-off (and the human test,
#               which stays open until the batch closes it)
#   STARTED     work open
#   not started latch not STARTED and no member past next/
#   empty       no members
sprintbias_plan_state() {
    local f="$1" open landed signed unproven missing total fixes moved held human latch
    read -r open landed signed unproven missing total fixes moved held human <<EOF
$(sprintbias_plan_counts "$f")
EOF
    latch=$({ grep -m1 -E '^\*\*Status:\*\*' "$f" 2>/dev/null || true; } \
        | sed 's/.*\*\*Status:\*\*[[:space:]]*//' | tr -d '[:space:]')
    if [ "$total" -eq 0 ]; then printf 'empty'
    elif [ "$signed" -eq "$total" ] && [ "$human" -eq 0 ]; then printf 'SIGNED OFF'
    elif [ $((landed + signed)) -eq "$total" ] && [ "$fixes" -eq 0 ]; then printf 'LANDED'
    elif [ "$latch" != "STARTED" ] && [ "$moved" -eq 0 ] && [ "$fixes" -eq 0 ]; then printf 'not started'
    else printf 'STARTED'
    fi
}

# ── The human test: one per plan ─────────────────────────────────────
# Agents build a plan on reasonable assumptions and land each task in review/
# without waiting on a person. What only a person can check (real hardware,
# the live product, look and feel) gathers in ONE task per plan, the human
# test: **Owner**: human, listed last in the plan, parked in review/ (the
# human's folder). Agents never work it. Its ## Signoff (human) collects the
# plan's and every member's Signoff (human) items and each member's
# ### Assumptions; the human writes '- fail: <what you saw>' under ## Results,
# and promote plan:N turns each into a fix task the agents build. It moves to
# done/ with the plan's batch.

# sprintbias_is_human_task FILE -> exit 0 when the task is **Owner**: human.
sprintbias_is_human_task() {
    [ "$(sprintbias_meta_value "$1" "Owner" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')" = "human" ]
}

# sprintbias_plan_human_test PLAN_FILE -> path of the plan's human test (the
# first member marked **Owner**: human), or nothing.
sprintbias_plan_human_test() {
    local mid path
    for mid in $(sprintbias_plan_member_ids "$1"); do
        path=$(sprintbias_task_path "$mid") || continue
        sprintbias_is_human_task "$path" && { printf '%s' "$path"; return 0; }
    done
    return 0
}

# _sprintbias_items FILE MODE -> one item per line, bullet and checkbox
# stripped, comments dropped; a wrapped bullet joins its first line.
#   MODE signoff  the ## Signoff (human) body
#   MODE assumed  the ### Assumptions body under ## Completed
_sprintbias_items() {
    awk -v mode="$2" '
        function flush() { if (cur != "") print cur; cur = "" }
        mode == "signoff" && /^## Signoff \(human\)[[:space:]]*$/ { cap = 1; next }
        mode == "assumed" && /^## Completed[[:space:]]*$/ { inc = 1; next }
        mode == "assumed" && inc && /^### Assumptions[[:space:]]*$/ { cap = 1; next }
        cap && /^#/ { flush(); exit }
        mode == "assumed" && /^## / { inc = 0 }
        !cap { next }
        incom { if (index($0, "-->")) incom = 0; next }
        {
            gsub(/<!--.*-->/, "")
            if (index($0, "<!--")) { sub(/<!--.*/, ""); incom = 1 }
            if ($0 !~ /[^[:space:]]/) { flush(); next }
            if ($0 ~ /^[[:space:]]*[-*][[:space:]]/) {
                flush(); line = $0
                sub(/^[[:space:]]*[-*][[:space:]]+(\[[ xX]\][[:space:]]*)?/, "", line)
                cur = line
            } else if (cur != "") {
                line = $0; sub(/^[[:space:]]+/, "", line); cur = cur " " line
            }
        }
        END { flush() }
    ' "$1" 2>/dev/null | { grep -E '[^[:space:]]' || true; }
}

# sprintbias_plan_human_checks PLAN_FILE -> the human test's checklist, one
# '- [ ] …' line per check: the plan's own Signoff (human) items, then each
# agent member's, tagged '#ID:', then its assumptions, tagged '#ID assumed:'.
sprintbias_plan_human_checks() {
    local plan="$1" mid path item
    while IFS= read -r item; do
        [ -n "$item" ] && printf -- '- [ ] %s\n' "$item"
    done <<EOT
$(_sprintbias_items "$plan" signoff)
EOT
    for mid in $(sprintbias_plan_member_ids "$plan"); do
        path=$(sprintbias_task_path "$mid") || continue
        sprintbias_is_human_task "$path" && continue
        while IFS= read -r item; do
            [ -n "$item" ] && printf -- '- [ ] #%s: %s\n' "$mid" "$item"
        done <<EOT
$(_sprintbias_items "$path" signoff)
EOT
        # A Decided: line is a call the agent made, shown at the end of the run
        # with a newtask line to change it; it is not a check for the person.
        while IFS= read -r item; do
            case "$item" in ""|Decided:*|\*\*Decided:*) continue ;; esac
            printf -- '- [ ] #%s assumed: %s\n' "$mid" "$item"
        done <<EOT
$(_sprintbias_items "$path" assumed)
EOT
    done
    return 0
}

# _sprintbias_insert_after FILE HEADING_RE ITEM_RE -> insert $SB_ADD (lines,
# newline-terminated) after the last ITEM_RE line of the HEADING_RE section,
# or right under the heading when the section has none. With no such heading,
# after the file's last ITEM_RE line, else at the end.
_sprintbias_insert_after() {
    awk -v h="$2" -v it="$3" '
        { buf[NR] = $0 }
        $0 ~ it { any = NR }
        !head && $0 ~ h { head = NR; sec = 1; next }
        sec && /^## / { sec = 0 }
        sec && $0 ~ it { last = NR }
        END {
            at = last ? last : (head ? head : any)
            if (!at) { at = NR; print_blank = 1 }
            for (i = 1; i <= NR; i++) {
                print buf[i]
                if (i == at) { if (!last && (head || print_blank)) print ""; printf "%s", ENVIRON["SB_ADD"] }
            }
        }
    ' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}

# sprintbias_plan_ensure_human_test PLAN_FILE -> create or refresh the plan's
# human test and print its path. Creates it (in review/, listed last in the
# plan) only when the plan has human checks; a refresh appends only checks it
# does not already list, so a re-run that finds nothing new writes nothing.
sprintbias_plan_ensure_human_test() {
    local plan="$1" pid title checks ht new line have out fix fid today
    pid=$(sprintbias_plan_file_id "$plan")
    checks=$(sprintbias_plan_human_checks "$plan")
    ht=$(sprintbias_plan_human_test "$plan")
    if [ -n "$ht" ]; then
        have=$(_sprintbias_items "$ht" signoff)
        new=""
        while IFS= read -r line; do
            [ -n "$line" ] || continue
            grep -qxF -- "${line#- \[ \] }" <<<"$have" && continue
            new="$new$line
"
        done <<EOT
$checks
EOT
        if [ -n "$new" ]; then
            SB_ADD="$new" _sprintbias_insert_after "$ht" '^## Signoff \\(human\\)[[:space:]]*$' '^[[:space:]]*[-*][[:space:]]'
        fi
        printf '%s' "$ht"
        return 0
    fi
    [ -n "$checks" ] || return 0

    title=$(grep -m1 '^# ' "$plan" 2>/dev/null | sed 's/^# *//; s/^Plan [0-9]*: *//')
    out=$(bash "$_SPRINTBIAS_LIB_DIR/scripts/create-task.sh" "Human test for plan $pid: $title" 2>&1) || {
        printf '%s\n' "$out" >&2; return 1; }
    fix=$(printf '%s\n' "$out" | grep -oE 'docs/tasks/backlog/[^ ]+\.md' | tail -1)
    [ -n "$fix" ] && [ -f "$fix" ] || { printf '%s\n' "$out" >&2; return 1; }
    fid=$(task_id "$fix")
    today="${SPRINTBIAS_TODAY:-$(date +%Y-%m-%d)}"
    cat > "$fix" <<EOT
# Task $fid: Human test for plan $pid: $title

**Owner**: human
**Created**: $today
**Plan**: $pid
**Depends on**: none
**Tests**: none

## Problem

Agents built plan $pid on reasonable assumptions and simulated tests, and kept
moving. This is the one pass a person makes in the real world: on hardware,
in the live product, by eye. Run it when \`./sprint.sh plan check $pid\` reads
LANDED (earlier is fine; what you find feeds the agents sooner).

## Signoff (human)

$checks

## Results

<!-- sb:hint  One line per check that failed, in your words:
       - fail: the LED stays red after pairing
     ./sprint.sh promote plan:$pid files each one as a fix task the agents
     build, then asks you to re-run this test. All passed: leave this empty
     and approve the batch. -->
EOT
    move_file "$fix" "docs/tasks/review/${fix##*/}"
    fix="docs/tasks/review/${fix##*/}"
    SB_ADD="- #$fid — Human test for plan $pid
" _sprintbias_insert_after "$plan" '^## Member tasks[[:space:]]*$' '^- (\\[[ xX]\\] )?#[0-9]+'
    printf '%s' "$fix"
}

# sprintbias_human_test_failures HT -> the "- fail: …" lines under ## Results
# (comments skipped), one per line. Read-only; used by filing and --dry-run.
sprintbias_human_test_failures() {
    awk '/^## Results[[:space:]]*$/ { cap = 1; next } cap && /^## / { exit }
         !cap { next }
         incom { if (index($0, "-->")) incom = 0; next }
         index($0, "<!--") { if (!index($0, "-->")) incom = 1; next }
         /^[[:space:]]*[-*][[:space:]]*[Ff][Aa][Ii][Ll]:/ { print }' "$1" 2>/dev/null
}

# sprintbias_human_test_file_failures HT_FILE -> file one fix task per
# '- fail: …' line under the human test's ## Results and mark the line
# '- filed #N: …' so it is never filed twice. Prints how many it filed.
sprintbias_human_test_file_failures() {
    local ht="$1" hid line text n=0
    hid=$(task_id "$ht")
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        text=$(printf '%s' "$line" | sed -E 's/^[[:space:]]*[-*][[:space:]]*[Ff][Aa][Ii][Ll]:[[:space:]]*//')
        sprintbias_file_fix_task "$hid" "$text" "Fix #$hid: $(printf '%s' "$text" | cut -c1-60)" >/dev/null || continue
        SB_OLD="$line" SB_NEW="- filed #$SPRINTBIAS_FIX_ID: $text" awk '
            BEGIN { o = ENVIRON["SB_OLD"]; nw = ENVIRON["SB_NEW"] }
            !d && $0 == o { print nw; d = 1; next } { print }
        ' "$ht" > "$ht.tmp" && mv "$ht.tmp" "$ht"
        echo "    fix #$SPRINTBIAS_FIX_ID ← $text" >&2
        n=$((n + 1))
    done <<EOT
$(sprintbias_human_test_failures "$ht")
EOT
    printf '%s' "$n"
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
# Optional args: when called as sprintbias_announce_provider "$@" from
# sprintbias_run, peeks for --model <id> and appends · model: <id> so the
# pin the CLI will receive is visible before "session started (…)". Ends with
# · fast: on|off so the session's mode reads at a glance.
sprintbias_announce_provider() {
    [ -n "${_SPRINTBIAS_PROVIDER_ANNOUNCED:-}" ] && return 0
    _SPRINTBIAS_PROVIDER_ANNOUNCED=1
    local cli tier mode line model="" peek_next=0 a
    cli="${SPRINTBIAS_CLI:-?}"
    tier="$(sprintbias_ai_tier)"
    mode="$(sprintbias_ai_mode)"
    for a in "$@"; do
      if [ "$peek_next" -eq 1 ]; then
        model="$a"
        break
      fi
      case "$a" in
        --model) peek_next=1 ;;
      esac
    done
    if [ -n "$model" ]; then
      line=$(printf '▸ Provider: %s (%s) · mode: %s · model: %s' "$cli" "$tier" "$mode" "$model")
    else
      line=$(printf '▸ Provider: %s (%s) · mode: %s' "$cli" "$tier" "$mode")
    fi
    line="$line · fast: $(sprintbias_fast_state)"
    printf '%s\n' "$line" >&2
    if [ ! -t 2 ] && { true >/dev/tty; } 2>/dev/null; then
        printf '%s\n' "$line" >/dev/tty 2>/dev/null || true
    fi
}

# sprintbias_run — route an AI request to emit or exec based on the mode.
# Same argument surface as the provider profiles.
# In fast mode the run skips the CLI's permission prompts: --skip-permissions
# leads the args, and every profile lets it win over the call site's
# --permissions. Human-owned actions stay walled by rule, not by prompt.
sprintbias_run() {
    sprintbias_announce_provider "$@"
    sprintbias_fast_on && set -- --skip-permissions "$@"
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
# Fast mode adds --skip-permissions here too, as in sprintbias_run.
sprintbias_run_interactive() {
    sprintbias_announce_provider "$@"
    sprintbias_fast_on && set -- --skip-permissions "$@"
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

# True when a task file carries a completed (non-aborted) '## Audit' section —
# the marker `polish --code` writes on a finished code audit. Mirrors
# sprintbias_excellence_has_section: matches the exact '## Audit' heading ONLY,
# so the '## Audit (aborted …)' notes never count as a real audit. Presence
# alone is NOT proof of correctness — a FAIL/BLOCKED/UNCLEAR audit also writes
# this heading; read the recorded verdict with sprintbias_correctness_state.
sprintbias_audit_has_section() {
    grep -qE '^## Audit$' "$1" 2>/dev/null
}

# The correctness state of a finished task, derived from the '## Audit' marker
# `polish --code` writes (polish.sh, `**Final verdict**:`). The excellence
# deep-judge gates its "presumed correct" posture on this: correctness is
# presented as established ONLY when a code audit actually ran AND passed.
# Echoes exactly one token:
#   audited     a plain '## Audit' block records a PASS or FIXED **Final verdict**
#   failed      a plain '## Audit' block records FAIL/BLOCKED/UNCLEAR — worse
#               than unverified: an audit ran and did NOT clear the work
#   unverified  no '## Audit' block (or only an aborted note) — never audited
sprintbias_correctness_state() {
    local file="$1" verdict
    [ -n "$file" ] && [ -f "$file" ] || { echo "unverified"; return; }
    if ! sprintbias_audit_has_section "$file"; then
        echo "unverified"; return
    fi
    verdict=$(grep -E '^- \*\*Final verdict\*\*:' "$file" 2>/dev/null | tail -1 \
        | sed -E 's/^- \*\*Final verdict\*\*:[[:space:]]*//' | tr -d '[:space:]')
    case "$verdict" in
        PASS|FIXED) echo "audited" ;;
        *)          echo "failed" ;;
    esac
}

# The ONE source of truth for the '## Excellence' section's field set. Both run
# paths render THIS: polish-judge.sh's headless appender passes real values, and
# its emit-mode APPEND_STEP prompt passes placeholders the judging agent fills.
# Keeping the field list here means a new field lands once and cannot drift
# between paths. Args, in order:
#   date verdict correctness tasks_filed routing files_reviewed context_source code_state summary
# `routing` records where the filed tasks went — the warm-route split, e.g.
# "1 → next/, 2 → backlog/" (or "—" when nothing was filed). `code_state` is the
# content hash of the audited files at judgment time (sprintbias_manifest_state_hash)
# — the idempotency guard re-judges when it no longer matches the current tree.
sprintbias_excellence_block() {
    printf '\n## Excellence\n\n'
    printf -- '- **Date**: %s\n' "$1"
    printf -- '- **Verdict**: %s\n' "$2"
    printf -- '- **Correctness**: %s\n' "$3"
    printf -- '- **Tasks filed**: %s\n' "$4"
    printf -- '- **Routing**: %s\n' "$5"
    printf -- '- **Files reviewed**: %s\n' "$6"
    printf -- '- **Context source**: %s\n' "$7"
    printf -- '- **Code state**: %s\n' "$8"
    printf '\n%s\n' "$9"
}

# sprintbias_manifest_state_hash CHANGED_FILES  -> print a content hash (or "").
# The idempotency state key: a hash over the CURRENT contents of the audited
# files (the resolved change manifest), not the git-diff text — the diff churns
# on line numbers, the contents are what actually moved. Each file is streamed
# behind a path header so a rename that preserves bytes still changes the hash.
# Missing files contribute only their header. Empty input yields the empty
# string, which the guard reads as "no state to compare" (skip, not re-judge).
sprintbias_manifest_state_hash() {
    local files="$1" f
    [ -n "$(printf '%s' "$files" | tr -d '[:space:]')" ] || { echo ""; return; }
    {
        printf '%s\n' "$files" | while IFS= read -r f; do
            [ -n "$f" ] || continue
            printf '::%s::\n' "$f"
            [ -f "$f" ] && cat "$f"
        done
    } | sprintbias_hash_stdin
}

# sprintbias_hash_stdin  (reads stdin) -> print a short, stable content hash.
# git is a hard dependency of sprintbias, so git hash-object is the primary
# hasher (stable blob SHA-1, machine-independent); shasum/cksum are fallbacks so
# the guard degrades rather than errors if git is somehow absent. Truncated to
# 16 chars for a readable stamp — both write and compare truncate identically.
sprintbias_hash_stdin() {
    local h=""
    if command -v git >/dev/null 2>&1; then
        h="$(git hash-object --stdin 2>/dev/null || true)"
    fi
    if [ -z "$h" ] && command -v shasum >/dev/null 2>&1; then
        h="$(shasum -a 256 | cut -d' ' -f1)"
    fi
    [ -z "$h" ] && h="$(cksum | tr -d ' ')"
    printf '%s\n' "${h:0:16}"
}

# sprintbias_change_snapshot take SNAP [ROOT…]  -> record ROOTs into dir SNAP.
# sprintbias_change_snapshot diff SNAP          -> what changed since `take`.
# A before/after view of the working tree that a script takes itself, so it can
# report what an agent pass touched without trusting the agent's say-so and
# without git (new files are untracked; already-dirty files would show old
# edits). ROOTs default to docs/tasks docs/plans. `take` writes SNAP/index
# (hash<TAB>path per file: one batched git hash-object, sprintbias_hash_stdin
# per file as the fallback), SNAP/roots, and
# a copy of each file under SNAP/tree/ for the line counts. `diff` re-hashes the
# same roots and prints one TSV line per changed file, sorted by path:
#   STATUS<TAB>PATH<TAB>FROM<TAB>ADDED<TAB>REMOVED
# STATUS is new | edited | moved | deleted. FROM is the old path for moved
# (a path gone and a path new with the same basename pair up as one move),
# "-" otherwise (a placeholder `read` will not collapse). ADDED/REMOVED are
# diff line counts. A file already dirty before `take` appears only if it
# changed again. Always returns 0.
sprintbias_change_snapshot() {
    local mode="${1:-}" snap="${2:-}" root f
    [ -n "$snap" ] || return 0
    _snap_index() {  # _snap_index ROOT… -> hash<TAB>path per file, sorted by path
        local list hashes
        list="$(for root in "$@"; do
                    [ -d "$root" ] && find "$root" -type f ! -name '.DS_Store' 2>/dev/null
                done | LC_ALL=C sort)"
        [ -n "$list" ] || return 0
        # One git process for every file; sprintbias_hash_stdin per file if not.
        hashes="$(printf '%s\n' "$list" | git hash-object --stdin-paths 2>/dev/null || true)"
        if [ "$(printf '%s\n' "$hashes" | grep -c .)" = "$(printf '%s\n' "$list" | grep -c .)" ]; then
            paste <(printf '%s\n' "$hashes" | cut -c1-16) <(printf '%s\n' "$list")
        else
            printf '%s\n' "$list" | while IFS= read -r f; do
                printf '%s\t%s\n' "$(sprintbias_hash_stdin < "$f")" "$f"
            done
        fi
    }
    _snap_count() {  # ADDED<TAB>REMOVED between two files (either may be absent)
        local a="${1:-/dev/null}" b="${2:-/dev/null}" out
        [ -f "$a" ] || a=/dev/null
        [ -f "$b" ] || b=/dev/null
        out="$(diff "$a" "$b" 2>/dev/null || true)"
        printf '%s\t%s' \
            "$(printf '%s\n' "$out" | grep -c '^>' || true)" \
            "$(printf '%s\n' "$out" | grep -c '^<' || true)"
    }
    case "$mode" in
        take)
            shift 2
            [ "$#" -gt 0 ] || set -- docs/tasks docs/plans
            mkdir -p "$snap/tree"
            printf '%s\n' "$@" > "$snap/roots"
            _snap_index "$@" > "$snap/index"
            [ -s "$snap/index" ] && cut -f2 "$snap/index" | tar -cf - -T - 2>/dev/null \
                | tar -xf - -C "$snap/tree" 2>/dev/null || true
            ;;
        diff)
            [ -f "$snap/index" ] || return 0
            local now edited gone added paired="" path from base roots=()
            while IFS= read -r root; do [ -n "$root" ] && roots+=("$root"); done < "$snap/roots"
            now="$(_snap_index ${roots[@]+"${roots[@]}"})"
            # One join: E<TAB>path (hash moved), G<TAB>path (gone), A<TAB>path (added).
            local joined
            joined="$(awk -F'\t' '
                NR == FNR { old[$2] = $1; next }
                $2 == "" { next }
                ($2 in old) { if (old[$2] != $1) print "E\t" $2; seen[$2] = 1; next }
                { print "A\t" $2 }
                END { for (p in old) if (!(p in seen)) print "G\t" p }
            ' "$snap/index" <(printf '%s\n' "$now") | LC_ALL=C sort)"
            edited="$(printf '%s\n' "$joined" | sed -n 's/^E\t//p')"
            gone="$(printf '%s\n' "$joined" | sed -n 's/^G\t//p')"
            added="$(printf '%s\n' "$joined" | sed -n 's/^A\t//p')"
            {
                while IFS= read -r path; do
                    [ -n "$path" ] || continue
                    printf 'edited\t%s\t-\t%s\n' "$path" "$(_snap_count "$snap/tree/$path" "$path")"
                done <<< "$edited"
                while IFS= read -r path; do
                    [ -n "$path" ] || continue
                    base="${path##*/}" from=""
                    while IFS= read -r f; do
                        [ -n "$f" ] || continue
                        [ "${f##*/}" = "$base" ] || continue
                        case $'\n'"$paired"$'\n' in *$'\n'"$f"$'\n'*) continue ;; esac
                        from="$f"; break
                    done <<< "$gone"
                    if [ -n "$from" ]; then
                        paired="${paired}${from}"$'\n'
                        printf 'moved\t%s\t%s\t%s\n' "$path" "$from" "$(_snap_count "$snap/tree/$from" "$path")"
                    else
                        printf 'new\t%s\t-\t%s\n' "$path" "$(_snap_count "" "$path")"
                    fi
                done <<< "$added"
                while IFS= read -r f; do
                    [ -n "$f" ] || continue
                    case $'\n'"$paired"$'\n' in *$'\n'"$f"$'\n'*) continue ;; esac
                    printf 'deleted\t%s\t-\t%s\n' "$f" "$(_snap_count "$snap/tree/$f" "")"
                done <<< "$gone"
            } | LC_ALL=C sort -t$'\t' -k2,2
            ;;
    esac
    unset -f _snap_index _snap_count
    return 0
}

# sprintbias_excellence_state_key TASK_FILE -> print the stamped Code state hash.
# Reads the `- **Code state**:` field from the EXACT '## Excellence' block only
# (an aborted note or another heading is skipped), so the guard compares like
# with like. Empty when the field is absent — a section written before code-state
# stamping — which the guard treats as "nothing to compare" (skip, not re-judge).
sprintbias_excellence_state_key() {
    awk '
        /^## Excellence$/ { inblk=1; next }
        inblk && /^## / { inblk=0 }
        inblk && /^- \*\*Code state\*\*:/ {
            sub(/^- \*\*Code state\*\*:[[:space:]]*/, "")
            gsub(/[[:space:]]/, "")
            print; exit
        }
    ' "$1" 2>/dev/null
}

# sprintbias_excellence_is_stale TASK_FILE [CURRENT_STATE_KEY] -> exit 0 when the
# task carries a '## Excellence' verdict that no longer matches the current code
# state (re-judge), exit 1 otherwise (never judged, still matches, or can't tell
# → skip). This is the ONE staleness test both entry points share — the
# single-piece guard (polish-judge.sh) and the plan-scoped pre-filter
# (plan-polish.sh) — so "was this judged as it currently stands" is decided in one
# place and the two guards cannot drift apart. Pass the current-state hash when
# the caller already resolved it (the single-piece guard needs it for stamping);
# omit it and the predicate resolves it from the task's own change manifest (the
# pre-filter's per-member case). Degrade rule preserved: an unstamped section
# (written before code-state stamping) or an unresolvable manifest counts as NOT
# stale — never re-judge blindly. Resolving the manifest clobbers the
# SPRINTBIAS_CHANGED_FILES/_CONTEXT_SOURCE globals, so callers that need those
# must read them before calling, or pass the hash in to avoid the resolve.
sprintbias_excellence_is_stale() {
    local f="$1" current stamped
    sprintbias_excellence_has_section "$f" || return 1
    stamped="$(sprintbias_excellence_state_key "$f")"
    if [ "$#" -ge 2 ]; then
        current="$2"
    else
        sprintbias_change_manifest "$f"
        current="$(sprintbias_manifest_state_hash "$SPRINTBIAS_CHANGED_FILES")"
    fi
    [ -n "$current" ] && [ -n "$stamped" ] && [ "$current" != "$stamped" ]
}

# sprintbias_excellence_strip_section TASK_FILE — remove the single '## Excellence'
# block in place so a re-judge REPLACES it rather than stacking a second one.
# Scoped to the exact '## Excellence' heading through the next '## ' heading (or
# EOF): Success criteria, ## Completed, ## Audit, and any '## Excellence (aborted
# …)' note are untouched. Trailing blank lines are collapsed so the re-appended
# block keeps one clean separator.
sprintbias_excellence_strip_section() {
    local f="$1"
    awk '
        /^## Excellence$/ { skip=1; next }
        skip && /^## / { skip=0 }
        !skip {
            if ($0 ~ /^[[:space:]]*$/) { blank++; next }
            while (blank-- > 0) print ""
            blank=0; print
        }
    ' "$f" > "$f.tmp" && mv "$f.tmp" "$f" || rm -f "$f.tmp"
}

# The excellence judge's rules + verdict contract, as a prompt fragment. The
# single-piece judge (polish-judge.sh) inlines the full protocol directly; the
# plan-scoped orchestrator (plan-polish.sh) hands this compact fragment to each
# fan-out subagent so both paths state the same rules and the same VERDICT line
# every caller parses. The full method lives in docs/sprintbias/ai/audit-excellence.md.
sprintbias_excellence_rules() {
    cat <<'EOF'
Follow docs/sprintbias/ai/audit-excellence.md exactly. Your writes are exactly
two: a new backlog task (via ./sprint.sh newtask "<desc>", plus --from-plan <id>
when the audited task names a **Plan**) for each enhancement
you find, and an appended '## Excellence' section on the audited task file —
write it EXACTLY as the pre-rendered block you are given for this task, filling
only the placeholders (verdict, tasks filed, routing, Summary) and copying every
other field verbatim; do not invent, drop, or reorder fields. Everything else is
read-only here — the task's Success criteria,
its ## Completed section, its folder, and all product code — so an enhancement is
filed, never built, and the task is never reopened. Default every filed task to
backlog/; warm-route at most 1–2 that clear the "a senior engineer would act now"
bar into next/ by promoting them through the shared gate (promote-to-sprint.sh),
never a raw git mv. Record the split as routing (e.g. "1 → next/, 2 → backlog/").
Presume the code correct
ONLY when a passing code audit is on record: a plain '## Audit' section (not an
'aborted' note) whose **Final verdict** is PASS or FIXED — stamp correctness:
audited. Otherwise stamp correctness: unverified (no ## Audit) or correctness:
failed (a ## Audit recording FAIL/BLOCKED/UNCLEAR — worse than unverified), do
NOT presume correctness, and treat any defect you stumble on as a DEFECT finding
recommending ./sprint.sh polish --code rather than waving it by.
End with: VERDICT: EXCELLENT | FILED — <n> enhancement task(s) (<x> → next/, <y> → backlog/) | BLOCKER — <reason>.
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
# Dispatches to the active profile's profile_interpret_run when defined. Every
# shipped profile now implements its own — claude (Claude result JSON), grok
# (Grok's native "text"/"stopReason" shape), and default (the no-JSON plain-log
# case). The fallback below stays only as a defensive bridge for any profile
# that defines sprintbias_provider_exec but no profile_interpret_run.
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

# Bridge interpreter for any profile that defines sprintbias_provider_exec but
# no profile_interpret_run. All shipped profiles (claude/grok/default) now own
# their own reader, so this is a defensive fallback only. It reproduces the
# Claude-shaped is_error/subtype reading. Not the permanent home of shape
# knowledge — each profile owns its own shape in cli/<name>.sh.
_sprintbias_interpret_run_fallback() {
    local log="$1"
    SPRINTBIAS_RUN_OUTCOME="" SPRINTBIAS_RUN_TURNS="" SPRINTBIAS_RUN_COST=""
    SPRINTBIAS_RUN_VERDICT_TEXT="" SPRINTBIAS_RUN_SUMMARY=""
    if [ ! -s "$log" ]; then
        SPRINTBIAS_RUN_OUTCOME="no_start"
        return 0
    fi
    # One pass: outcome + the verdict text + the summary. The summary is derived
    # inline here so no site reads the log a second time — the profiles already
    # do their own summary, and this bridge is the only other reader.
    {
        IFS= read -r -d '' SPRINTBIAS_RUN_OUTCOME
        IFS= read -r -d '' SPRINTBIAS_RUN_VERDICT_TEXT
        IFS= read -r -d '' SPRINTBIAS_RUN_SUMMARY
    } < <(python3 -c "$_SPRINTBIAS_FALLBACK_INTERPRET_PY" "$log")
    : "${SPRINTBIAS_RUN_OUTCOME:=finished}"
    return 0
}

# The fallback interpreter's single-pass reader (see above). Kept in a variable
# so the here-string parser never has to nest a heredoc inside <(…). Emits three
# NUL-terminated fields: outcome, verdict text, summary.
_SPRINTBIAS_FALLBACK_INTERPRET_PY="$(cat <<'PY'
import json, sys, re
def summarize(text):
    m = re.search(r'## Summary\n(.*?)(?=\nVERDICT:|\Z)', text, re.DOTALL)
    if m:
        return m.group(1).strip()
    lines = text.strip().split('\n')
    vi = None
    for i, l in enumerate(lines):
        if 'VERDICT:' in l:
            vi = i
    if vi is not None and vi > 0:
        return '\n'.join(lines[max(0, vi - 30):vi]).strip()
    if text:
        return text[-2000:] if len(text) > 2000 else text
    return '(no output captured)'
def emit(outcome, verdict_text, summary):
    sys.stdout.write('\0'.join([outcome, verdict_text, summary]) + '\0')
try:
    raw = open(sys.argv[1]).read()
except Exception:
    raw = ''
try:
    d = json.loads(raw)
except Exception:
    # non-JSON log: caller greps the raw text for a verdict
    emit('finished', raw, summarize(raw)); sys.exit(0)
if not d.get('is_error'):
    result = d.get('result', '')
    emit('finished', result, summarize(result)); sys.exit(0)
subtype = d.get('subtype') or 'error'
outcome = {'error_max_turns': 'max_turns',
           'error_during_execution': 'error'}.get(subtype, 'error')
emit(outcome, '', '')
PY
)"

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

# Budgets: empty = no cap, so agents finish the work. A project that wants a
# ceiling sets one (BUDGET_WORK=5.00 keeps each task under $5).
SPRINTBIAS_BUDGET_WORK="${SPRINTBIAS_BUDGET_WORK-$(sprintbias_cfg BUDGET_WORK)}"

SPRINTBIAS_BUDGET_AUDIT="${SPRINTBIAS_BUDGET_AUDIT-$(sprintbias_cfg BUDGET_AUDIT)}"

SPRINTBIAS_BUDGET_BREAK="${SPRINTBIAS_BUDGET_BREAK-$(sprintbias_cfg BUDGET_BREAK)}"

SPRINTBIAS_BREAK_MAX_TURNS="${SPRINTBIAS_BREAK_MAX_TURNS:-$(sprintbias_cfg BREAK_MAX_TURNS)}"
: "${SPRINTBIAS_BREAK_MAX_TURNS:=25}"

SPRINTBIAS_BREAK_TIMEOUT="${SPRINTBIAS_BREAK_TIMEOUT:-$(sprintbias_cfg BREAK_TIMEOUT)}"
: "${SPRINTBIAS_BREAK_TIMEOUT:=900}"

SPRINTBIAS_AUDIT_MAX_PASSES="${SPRINTBIAS_AUDIT_MAX_PASSES:-$(sprintbias_cfg AUDIT_MAX_PASSES)}"
: "${SPRINTBIAS_AUDIT_MAX_PASSES:=2}"

# Load provider profile (defines sprintbias_provider_exec)
sprintbias_load_profile "$SPRINTBIAS_CLI"
