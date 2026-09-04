#!/usr/bin/env bash
# docs/sprintbias/cli/claude.sh — Claude Code CLI profile for SprintBias
#
# Defines sprintbias_provider_exec(), which maps the provider-neutral interface used by
# SprintBias scripts to Claude Code's actual CLI flags.
#
# Sourced automatically by config.sh when SPRINTBIAS_CLI=claude (the default).
#
# Live progress: when a script requests buffered --output-format json but
# stderr is still a terminal, the run is upgraded to stream-json and each
# tool call is narrated on stderr as it happens, while stdout receives the
# same single result-JSON object the caller expected. Call sites that
# redirect stderr (parallel runners, captured audit output) automatically
# fall back to the quiet buffered path — no call-site changes needed.
# Control with SPRINTBIAS_STREAM: unset = auto (TTY), 1 = force on, 0 = off.
#
# Transient-failure recovery: a dropped connection mid-run ("API Error:
# Connection closed mid-response") wastes every turn already spent. When a
# non-interactive run fails transiently, this profile waits and RESUMES the
# same session ("pick up where you left off"), falling back to a fresh
# rerun when no session id is recoverable. Sessions are persisted for this
# reason. Control with SPRINTBIAS_RETRIES (default 2, 0 = off) and
# SPRINTBIAS_RETRY_WAIT (seconds between attempts, default 60).
#
# Wedged-stream recovery: the retry loop above only fires once the CLI call
# RETURNS a failure — it cannot rescue a request whose streaming response
# stalls mid-flight and never closes the socket. That failure mode has hung a
# single request for hours (one accepted request, zero events, no teardown)
# while the retry logic sat idle waiting for a failure that never came. To cap
# it, each attempt is wrapped in a wall-clock timeout: if the CLI produces no
# result within SPRINTBIAS_ATTEMPT_TIMEOUT seconds (default 1800 = 30 min, 0 =
# off) it is killed, and the kill is treated as a transient failure so the
# normal wait-and-resume path takes over. Requires `timeout` or `gtimeout`
# (coreutils) on PATH; if neither is present the wrapper is a no-op and a
# hung request can still hang — install coreutils to get the cap.

# Reads stream-json events on stdin; narrates tool activity to stderr and
# emits only the final result event (identical shape to --output-format
# json) on stdout. No single quotes in this code — it is embedded in one.
_SPRINTBIAS_STREAM_FILTER="$(cat <<'PYEOF'
import json, sys
result_line = None
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        ev = json.loads(line)
    except ValueError:
        continue
    t = ev.get("type")
    if t == "system" and ev.get("subtype") == "init":
        model = ev.get("model", "")
        if model:
            print("  . session started (%s)" % model, file=sys.stderr, flush=True)
    elif t == "assistant":
        for blk in (ev.get("message") or {}).get("content") or []:
            if blk.get("type") == "tool_use":
                name = blk.get("name", "?")
                inp = blk.get("input") or {}
                detail = (inp.get("file_path") or inp.get("path")
                          or inp.get("pattern") or inp.get("command")
                          or inp.get("description") or "")
                detail = " ".join(str(detail).split())
                if len(detail) > 100:
                    detail = detail[:97] + "..."
                msg = "  . %s: %s" % (name, detail) if detail else "  . %s" % name
                print(msg, file=sys.stderr, flush=True)
    elif t == "result":
        result_line = line
if result_line:
    print(result_line)
PYEOF
)"

# Canonical transient strings — the errors we KNOW a resume can clear. Retry is a
# denylist now (retry unless fatal or a deterministic cap, see below), so this is
# no longer the gate; it is a known-good short-circuit checked before the
# non-retry denylist, so a clear transient ("API Error: 500 …") always resumes
# even if its text happens to brush a denylist word.
_SPRINTBIAS_TRANSIENT_RE='API Error|Connection (closed|error|reset)|overloaded|rate.?limit|timed? ?out|50[023]|529'

# Failures a human must fix — expired/invalid credentials, a required re-login,
# an exhausted balance. These take PRECEDENCE over the transient check: the
# CLI often prefixes them with "API Error: 401 …", which would otherwise match
# the broad transient pattern above and burn the whole retry budget re-running
# something retrying can never repair. Matching here surfaces them at once.
_SPRINTBIAS_FATAL_RE='invalid.{0,12}(api.?key|token)|authentication_error|unauthoriz|/login|please (run|log|sign).{0,4}(in|/login)|OAuth|token (has )?expired|re-?authenticat|credit balance'

# Deterministic caps and malformed-invocation failures. Unlike a transient blip,
# the NEXT attempt would hit the identical wall — a turn limit is still a turn
# limit, a budget cap still a budget cap, a bad flag still a bad flag — so
# retrying only wastes time and tokens. These are the ONLY non-fatal failures
# that skip the retry; every other observed failure (including novel crash
# strings like error_during_execution) is treated as transient and resumed. Kept
# tight and mostly keyed to the CLI's own structured/usage output so a task whose
# result merely mentions "budget" can't be mistaken for a budget cap.
_SPRINTBIAS_NONRETRY_RE='"subtype" *: *"error_max_turns"|max.?turns (reached|exceeded|limit)|reached.{0,8}max.?turns|max-budget|budget (cap|limit|exceeded)|cost limit|[Uu]nknown (option|argument|flag)|[Uu]nrecognized (option|argument)|^[Uu]sage:'

# OS family — used to tailor the "install a timeout tool" hint below, since the
# package and binary differ per platform (macOS ships none; Linux has it in
# coreutils; Windows' own timeout.exe is an unrelated pause utility).
case "${OSTYPE:-$(uname -s 2>/dev/null)}" in
  darwin*|Darwin*)                   _SPRINTBIAS_OS=macos ;;
  linux*|Linux*)                     _SPRINTBIAS_OS=linux ;;
  msys*|cygwin*|win32|MINGW*|MSYS*)  _SPRINTBIAS_OS=windows ;;
  *)                                 _SPRINTBIAS_OS=unknown ;;
esac

# Per-attempt wall-clock timeout binary. We require GNU coreutils specifically,
# because the guard uses `-k` (kill-after) which busybox's timeout lacks and
# Windows' timeout.exe (a "wait N seconds" prompt tool, NOT a command wrapper)
# does not understand. Verifying via --version rejects both impostors so a
# false positive can't make the guard silently malfunction. Prefer `gtimeout`
# (macOS/Homebrew name) then `timeout` (Linux). Empty when neither qualifies →
# the wrapper below is skipped and a one-time note is printed. GNU timeout
# exits 124 on expiry, or 128+signal (137 = SIGKILL from -k) if TERM is ignored.
_SPRINTBIAS_TIMEOUT_BIN=""
for _sprintbias_cand in gtimeout timeout; do
  if command -v "$_sprintbias_cand" >/dev/null 2>&1 \
     && "$_sprintbias_cand" --version 2>/dev/null | grep -qi coreutils; then
    _SPRINTBIAS_TIMEOUT_BIN="$_sprintbias_cand"; break
  fi
done
unset _sprintbias_cand

# Print, once per shell session, why the wall-clock cap is inactive and how to
# fix it for this OS. Called at task kickoff (first exec) when no usable
# timeout binary was found. Silent when the user disabled the cap themselves.
_sprintbias_warn_no_timeout() {
  [ -n "${_SPRINTBIAS_TIMEOUT_WARNED:-}" ] && return 0
  _SPRINTBIAS_TIMEOUT_WARNED=1
  local fix
  case "$_SPRINTBIAS_OS" in
    macos)   fix="install coreutils for gtimeout — run: brew install coreutils" ;;
    linux)   fix="install GNU coreutils (e.g. 'apt install coreutils' or 'dnf install coreutils')" ;;
    windows) fix="the Windows timeout.exe cannot wrap commands — install GNU coreutils in MSYS2/Git Bash (e.g. 'pacman -S coreutils')" ;;
    *)       fix="install GNU coreutils so 'timeout' (or 'gtimeout') is on PATH" ;;
  esac
  printf 'SprintBias: ⚠ timeout will not work until we %s.\n' "$fix" >&2
  printf '          Until then a wedged/unresponsive API request can hang instead of being capped (set SPRINTBIAS_ATTEMPT_TIMEOUT=0 to silence this).\n' >&2
}

sprintbias_provider_exec() {
  # ── Parse provider-neutral arguments ──────────────────────────────
  local prompt="" model="" max_turns="" tools="" permissions=""
  local output_format="" budget="" name="" system_prompt=""
  local skip_permissions=0
  local -a extra_args=()

  while [ $# -gt 0 ]; do
    case "$1" in
      -p)                    prompt="$2";        shift 2 ;;
      --model)               model="$2";         shift 2 ;;
      --max-turns)           max_turns="$2";     shift 2 ;;
      --tools)               tools="$2";         shift 2 ;;
      --permissions)         permissions="$2";   shift 2 ;;
      --output-format)       output_format="$2"; shift 2 ;;
      --budget)              budget="$2";        shift 2 ;;
      --name)                name="$2";          shift 2 ;;
      --append-system-prompt) system_prompt="$2"; shift 2 ;;
      --skip-permissions)    skip_permissions=1; shift ;;
      # Callers must not need Claude-only flags; profiles own them. Drop if
      # a legacy call site still passes --verbose (we re-add when stream-json).
      --verbose)             shift ;;
      --)                    shift; extra_args+=("$@"); break ;;
      *)                     extra_args+=("$1"); shift ;;
    esac
  done

  # Normalize Grok-oriented format names to Claude's stream-json so dual-host
  # call sites and shared logs stay one contract.
  case "$output_format" in
    streaming-json|streaming-messages-json) output_format="stream-json" ;;
  esac

  # ── Decide on live streaming ──────────────────────────────────────
  # SPRINTBIAS_STREAM: 0 = never, 1 = always, unset/other = auto (stderr TTY).
  # Auto-upgrade only from buffered json → stream-json (live progress). Callers
  # that already request stream-json (work.sh) keep the raw NDJSON path; this
  # profile still adds --verbose below (required for Claude stream-json + -p).
  local stream=0
  if [ "$output_format" = "json" ] && command -v python3 >/dev/null 2>&1; then
    case "${SPRINTBIAS_STREAM:-auto}" in
      0) stream=0 ;;
      1) stream=1 ;;
      *) [ -t 2 ] && stream=1 ;;
    esac
  fi
  local effective_format="$output_format"
  [ "$stream" -eq 1 ] && effective_format="stream-json"

  # ── Retry policy ──────────────────────────────────────────────────
  # Resume only makes sense for non-interactive prompt runs.
  local max_retries="${SPRINTBIAS_RETRIES:-2}"
  local wait_s="${SPRINTBIAS_RETRY_WAIT:-60}"
  [ -n "$prompt" ] || max_retries=0

  local resume_prompt="Our connection broke mid-response and this session has been resumed. Review the conversation above and pick up exactly where you left off — do not redo completed work. If no prior progress is visible, start the task from the beginning using the original instructions. The original output requirements still apply."

  local attempt=0 rc=0 session=""
  local out errf
  out="$(mktemp)" || return 1
  errf="$(mktemp)" || { rm -f "$out"; return 1; }

  # ── Wall-clock guard (built once; applies to every attempt) ───────
  # Prefix the CLI call with `timeout` so a wedged stream that never returns
  # is killed and surfaced as a (transient) failure instead of hanging for
  # hours. `-k 10` follows an ignored TERM with a KILL 10s later. When no
  # GNU timeout binary is available, warn the user once at kickoff and run
  # uncapped rather than failing. SPRINTBIAS_ATTEMPT_TIMEOUT=0 disables entirely.
  local attempt_timeout="${SPRINTBIAS_ATTEMPT_TIMEOUT:-1800}"
  local -a tmo=()
  if [ "$attempt_timeout" -gt 0 ] 2>/dev/null; then
    if [ -n "$_SPRINTBIAS_TIMEOUT_BIN" ]; then
      tmo=("$_SPRINTBIAS_TIMEOUT_BIN" -k 10 "$attempt_timeout")
    else
      _sprintbias_warn_no_timeout
    fi
  fi

  while :; do
    attempt=$((attempt + 1))

    # ── Build the command for this attempt ──────────────────────────
    local -a cmd=("$SPRINTBIAS_CLI")
    if [ "$attempt" -gt 1 ] && [ -n "$session" ]; then
      cmd+=(--resume "$session" -p "$resume_prompt")
    elif [ -n "$system_prompt" ]; then
      cmd+=(--append-system-prompt "$system_prompt")
    elif [ -n "$prompt" ]; then
      cmd+=(-p "$prompt")
    fi

    # Coerce Grok-only model ids if a caller bypassed lib resolve.
    if declare -F sprintbias_coerce_model >/dev/null 2>&1; then
      model="$(sprintbias_coerce_model "$model")"
    fi
    [ -n "$model" ]            && cmd+=(--model "$model")
    [ -n "$max_turns" ]        && cmd+=(--max-turns "$max_turns")
    [ -n "$tools" ]            && cmd+=(--allowedTools "$tools")
    [ -n "$effective_format" ] && cmd+=(--output-format "$effective_format")
    [ -n "$budget" ]           && cmd+=(--max-budget-usd "$budget")
    [ -n "$name" ]             && cmd+=(--name "$name")
    # stream-json in -p mode requires --verbose — whether auto-upgraded from
    # json or requested by the call site (work). Never require callers to know.
    [ "$effective_format" = "stream-json" ] && cmd+=(--verbose)

    if [ "$skip_permissions" -eq 1 ]; then
      cmd+=(--dangerously-skip-permissions)
    elif [ -n "$permissions" ]; then
      cmd+=(--permission-mode "$permissions")
    fi

    if [ ${#extra_args[@]} -gt 0 ]; then
      cmd+=("${extra_args[@]}")
    fi

    # ── Execute ─────────────────────────────────────────────────────
    # CLI stderr is captured for the transient check and replayed at the
    # end; the stream filter's progress lines still reach stderr live.
    : > "$out"; : > "$errf"
    if [ "$stream" -eq 1 ]; then
      local -a _ps
      ${tmo[@]+"${tmo[@]}"} "${cmd[@]}" 2>"$errf" | python3 -c "$_SPRINTBIAS_STREAM_FILTER" > "$out" \
        && _ps=("${PIPESTATUS[@]}") || _ps=("${PIPESTATUS[@]}")
      rc="${_ps[0]}"
    else
      # Both streams are captured to temp files, so the terminal goes dark for
      # the whole run — tick dots on the TTY so it never looks hung. Dots go to
      # /dev/tty, so they still show even when a caller captures stdout via
      # $(...); no-op only when no terminal is attached (piped/CI) or a
      # heartbeat already owns the line.
      _sprintbias_heartbeat_start
      ${tmo[@]+"${tmo[@]}"} "${cmd[@]}" > "$out" 2>"$errf" && rc=0 || rc=$?
      _sprintbias_heartbeat_stop
    fi

    # ── Evaluate: success, hard failure, or transient? ──────────────
    local failed=0
    if [ "$rc" -ne 0 ]; then
      failed=1
    elif grep -q '"is_error": *true' "$out" 2>/dev/null; then
      # Exit 0 but the result object itself reports an error (this is how
      # a mid-response connection drop actually presents).
      failed=1
    fi

    # Classify the failure. The failure-string space is open-ended, so this is a
    # DENYLIST, not an allowlist: retry unless the error is one a retry cannot
    # repair. An allowlist here is what let a novel string (error_during_execution)
    # fall through to "surface silently, never retry" and cost a whole task run.
    local transient=0 timed_out=0
    if [ "$failed" -eq 1 ]; then
      if grep -qiE "$_SPRINTBIAS_FATAL_RE" "$out" "$errf" 2>/dev/null; then
        # Re-auth / expired-token / exhausted-balance: a human must act.
        # Checked FIRST so an "API Error: 401 …" prefix can't be mistaken for
        # a transient blip and silently retried. Leave transient=0 → surface.
        :
      elif [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ]; then
        # Our own wall-clock guard fired (or KILL'd a TERM-ignoring process):
        # a wedged/stalled request. Always retryable, and note it explicitly
        # since the killed CLI may have printed nothing to match the regex.
        transient=1; timed_out=1
      elif grep -qiE "$_SPRINTBIAS_TRANSIENT_RE" "$out" "$errf" 2>/dev/null; then
        # A known-transient string — resume clears it. Checked before the
        # denylist so a clear transient always wins over an incidental word.
        transient=1
      elif grep -qE "$_SPRINTBIAS_NONRETRY_RE" "$out" "$errf" 2>/dev/null; then
        # Deterministic caps (turn/budget) and malformed flags: the next attempt
        # hits the identical wall, so retrying is pure waste. Leave transient=0.
        :
      elif [ -s "$out" ] || [ -s "$errf" ]; then
        # Every OTHER observed failure — an is_error result under a 0 exit, a
        # novel crash string, an unclassified error — defaults to transient and
        # is resumed once. A crash must fall toward "try again", never toward a
        # silently-surfaced dead end.
        transient=1
      fi
      # Empty out AND empty errf (silent startup death) stays transient=0:
      # nothing to resume from, no evidence a retry would differ.
    fi

    if [ "$failed" -eq 0 ] || [ "$transient" -eq 0 ] || [ "$attempt" -gt "$max_retries" ]; then
      # A failure the result JSON reported under a 0 exit code (is_error:true —
      # the mid-response-drop signature) must NOT be handed back as success.
      # Promote it to a non-zero status so the caller routes it as the failure it
      # is, never as "ran clean but wrote nothing". This is the single
      # highest-value guard here: it stops a crash from being laundered into a
      # "badly defined task" and parked for a human decision it never needed.
      if [ "$failed" -eq 1 ] && [ "$rc" -eq 0 ]; then
        rc=1
      fi
      cat "$out"
      [ -s "$errf" ] && cat "$errf" >&2
      rm -f "$out" "$errf"
      return "$rc"
    fi

    # ── Transient failure with retries left: pause, then resume ─────
    local found
    found=$(grep -oE '"session_id" *: *"[^"]*"' "$out" 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)"$/\1/') || true
    [ -n "$found" ] && session="$found"

    local cause="Transient API failure"
    [ "$timed_out" -eq 1 ] && cause="Attempt exceeded ${attempt_timeout}s wall-clock cap (wedged stream)"
    if [ -n "$session" ]; then
      echo "⚠ ${cause} (attempt $attempt/$((max_retries + 1))) — waiting ${wait_s}s, then resuming session ${session:0:8}…" >&2
    else
      echo "⚠ ${cause} (attempt $attempt/$((max_retries + 1))) — waiting ${wait_s}s, then retrying from scratch…" >&2
    fi
    sleep "$wait_s"
  done
}

# This provider can host a live interactive session (see sprintbias_interactive_ok
# in lib.sh, which gates on this flag). Set at source time so the gate sees it.
SPRINTBIAS_PROVIDER_INTERACTIVE=1

# sprintbias_provider_interactive — launch an INTERACTIVE Claude Code session.
#
# sprintbias_provider_exec (above) redirects the CLI's stdout to a temp file so it
# can capture JSON and retry on a dropped connection. That capture is exactly
# what makes it one-shot: with stdout on a pipe the CLI sees a non-TTY, prints
# a single response and exits. A `chat`-style dialogue needs the opposite — the
# CLI must inherit the real terminal so the user can reply turn by turn. This
# function provides that: no stdout capture, no -p/--output-format, no retry
# loop (a human is present to rerun). The initial message is passed as a bare
# positional, NOT via -p, because -p forces non-interactive print mode.
#
# Precondition: only ever reached via sprintbias_run_interactive, which calls
# sprintbias_interactive_ok first — so exec mode and a real TTY are guaranteed here
# and need no re-check. Same argument surface as sprintbias_provider_exec.
sprintbias_provider_interactive() {
  local prompt="" model="" tools="" permissions="" name="" system_prompt=""
  local skip_permissions=0
  local -a extra_args=()

  while [ $# -gt 0 ]; do
    case "$1" in
      -p)                     prompt="$2";        shift 2 ;;
      --model)                model="$2";         shift 2 ;;
      --tools)                tools="$2";         shift 2 ;;
      --permissions)          permissions="$2";   shift 2 ;;
      --name)                 name="$2";          shift 2 ;;
      --append-system-prompt) system_prompt="$2"; shift 2 ;;
      --skip-permissions)     skip_permissions=1; shift ;;
      # Print-only / one-shot flags are meaningless in a live session — consume
      # them so they never leak onto the interactive command line.
      --max-turns|--output-format|--budget) shift 2 ;;
      --verbose)              shift ;;
      --)                     shift; extra_args+=("$@"); break ;;
      *)                      extra_args+=("$1"); shift ;;
    esac
  done

  # Coerce Grok-only model ids if a caller bypassed lib resolve.
  if declare -F sprintbias_coerce_model >/dev/null 2>&1; then
    model="$(sprintbias_coerce_model "$model")"
  fi

  local -a cmd=("$SPRINTBIAS_CLI")
  [ -n "$system_prompt" ] && cmd+=(--append-system-prompt "$system_prompt")
  [ -n "$model" ]         && cmd+=(--model "$model")
  [ -n "$tools" ]         && cmd+=(--allowedTools "$tools")
  [ -n "$name" ]          && cmd+=(--name "$name")
  if [ "$skip_permissions" -eq 1 ]; then
    cmd+=(--dangerously-skip-permissions)
  elif [ -n "$permissions" ]; then
    cmd+=(--permission-mode "$permissions")
  fi
  [ ${#extra_args[@]} -gt 0 ] && cmd+=("${extra_args[@]}")
  # The opening message rides in as a positional so the session starts on it
  # yet stays interactive. -p here would print one answer and exit.
  [ -n "$prompt" ] && cmd+=("$prompt")

  "${cmd[@]}"
}

# The Claude result reader, kept in a variable and run with `python3 -c` (the
# same pattern as _SPRINTBIAS_STREAM_FILTER above). It parses the result JSON
# once and writes five NUL-delimited fields on stdout — outcome, turns, cost,
# verdict text, summary (verdict/summary may be multiline, so NUL is the only
# safe separator). Kept out of a here-doc-in-process-substitution because that
# nesting mis-parses under set -e. No single quotes in this code.
_SPRINTBIAS_INTERPRET_PY="$(cat <<'PYEOF'
import json, sys, re

def emit(outcome, turns="", cost="", verdict="", summary=""):
    sys.stdout.write("\0".join([outcome, str(turns), str(cost),
                                verdict, summary]) + "\0")
    sys.exit(0)

raw = open(sys.argv[1], encoding="utf-8", errors="replace").read()
try:
    d = json.loads(raw)
except Exception:
    # Non-JSON log: treat as finished so the caller can grep raw text.
    emit("finished", "", "", raw, raw[-2000:] if len(raw) > 2000 else raw)

turns = d.get("num_turns", "")
cost = d.get("total_cost_usd", "")
result = d.get("result", "") or ""

def summarize(text):
    if not text:
        return ""
    m = re.search(r"## Summary\n(.*?)(?=\nVERDICT:|\Z)", text, re.DOTALL)
    if m:
        return m.group(1).strip()
    lines = text.strip().split("\n")
    vi = None
    for i, l in enumerate(lines):
        if "VERDICT:" in l:
            vi = i
    if vi is not None and vi > 0:
        return "\n".join(lines[max(0, vi - 30):vi]).strip()
    return text[-2000:] if len(text) > 2000 else text

if d.get("is_error"):
    subtype = d.get("subtype") or "error"
    outcome = {"error_max_turns": "max_turns",
               "error_during_execution": "error"}.get(subtype, "error")
    emit(outcome, turns, cost, result, summarize(result))

emit("finished", turns, cost, result, summarize(result))
PYEOF
)"

# profile_interpret_run LOG [rc] — the Claude reading of a run's result.
# Called by sprintbias_interpret_run (lib.sh). Parses the Claude Code result
# JSON exactly once and fills the normalized record the audits consume:
#   SPRINTBIAS_RUN_OUTCOME  finished | max_turns | no_start | error
#   SPRINTBIAS_RUN_TURNS / _COST / _VERDICT_TEXT / _SUMMARY
# Mapping: subtype error_max_turns -> max_turns, error_during_execution ->
# error, any other is_error subtype -> error, empty/absent log -> no_start,
# a clean result -> finished. A non-JSON log is treated as finished so a caller
# can still grep a verdict from raw text. This is where the Claude JSON shape
# lives — lib.sh's fallback is only a bridge for providers not yet ported.
profile_interpret_run() {
  local log="$1"
  SPRINTBIAS_RUN_OUTCOME="" SPRINTBIAS_RUN_TURNS="" SPRINTBIAS_RUN_COST=""
  SPRINTBIAS_RUN_VERDICT_TEXT="" SPRINTBIAS_RUN_SUMMARY=""
  if [ ! -s "$log" ]; then
    SPRINTBIAS_RUN_OUTCOME="no_start"
    return 0
  fi
  {
    IFS= read -r -d '' SPRINTBIAS_RUN_OUTCOME
    IFS= read -r -d '' SPRINTBIAS_RUN_TURNS
    IFS= read -r -d '' SPRINTBIAS_RUN_COST
    IFS= read -r -d '' SPRINTBIAS_RUN_VERDICT_TEXT
    IFS= read -r -d '' SPRINTBIAS_RUN_SUMMARY
  } < <(python3 -c "$_SPRINTBIAS_INTERPRET_PY" "$log")
  return 0
}
