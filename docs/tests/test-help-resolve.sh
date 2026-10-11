#!/usr/bin/env bash
# Each check is a string run by eval, so its $vars expand at check time.
# shellcheck disable=SC2016
# Test: conversational help — `./sprint.sh help <plain words>` resolves words to
# one command (exact → joined → registry keywords), a candidate list (exit 0) or
# a miss (exit 1); bare help stays the static list off a terminal and ends with
# the live prompt on one (SPRINTBIAS_HELP_TTY=1 simulates it); a miss offers the
# read-only AI (scripts/help-ask.sh, stubbed here — no real AI runs).
# Runs on a temp board that mirrors an install.

set -euo pipefail

PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

ok()   { echo "  PASS: $1"; PASS=$((PASS + 1)); }
bad()  { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }
check() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

B="$TMP/board"
mkdir -p "$B/docs/sprintbias" "$B/docs/tasks"/{backlog,next,doing,review,done,blocked}
cp -R "$ROOT/docs/sprintbias/." "$B/docs/sprintbias/"
cp "$ROOT/sprint.sh" "$B/sprint.sh"
rm -f "$B/docs/sprintbias/config.local"
unset SPRINTBIAS_FAST SPRINTBIAS_HELP_TTY
export NO_COLOR=1

sb() { (cd "$B" && ./sprint.sh "$@" 2>&1) || true; }
rc() { (cd "$B" && ./sprint.sh "$@" >/dev/null 2>&1); echo $?; }
# tty_help INPUT — bare help on a simulated terminal, INPUT typed at the prompts.
tty_help() { (cd "$B" && printf '%b' "$1" | SPRINTBIAS_HELP_TTY=1 ./sprint.sh help 2>&1) || true; }
tty_rc() { (cd "$B" && printf '%b' "$1" | SPRINTBIAS_HELP_TTY=1 ./sprint.sh help >/dev/null 2>&1); echo $?; }

PROMPT="What command would you like to understand better? (Enter to skip)"

echo "Syntax"
check "sprint.sh parses"   'bash -n "$ROOT/sprint.sh"'
check "help-ask.sh parses" 'bash -n "$ROOT/docs/sprintbias/scripts/help-ask.sh"'

# ── Existing behavior ────────────────────────────────────────────────
echo "Unchanged"
out="$(sb help work)"
check "help work prints the work page"     '[[ "$out" == "./sprint.sh work"* ]] && grep -qF "$(head -1 "$B/docs/sprintbias/help/work.md")" <<<"$out"'
check "work --help matches help work"      '[ "$(sb work --help)" = "$out" ]'
out="$(sb help </dev/null)"
check "bare help off a terminal → list"    '[[ "$out" == *"Create:"* && "$out" == *"help <command>"* ]]'
check "bare help off a terminal → no prompt" '[[ "$out" != *"$PROMPT"* ]]'
check "bare help </dev/null exits 0"       '[ "$(cd "$B" && ./sprint.sh help </dev/null >/dev/null 2>&1; echo $?)" = 0 ]'
check "SPRINTBIAS_HELP_TTY=0 never prompts" '[[ "$(cd "$B" && echo work | SPRINTBIAS_HELP_TTY=0 ./sprint.sh help 2>&1)" != *"$PROMPT"* ]]'

# ── Resolver ─────────────────────────────────────────────────────────
echo "Resolve"
out="$(sb help new idea)"
check "new idea → newidea page"            '[[ "$out" == "./sprint.sh newidea"* ]]'
check "page keeps its demo line"           '[[ "$out" == *"./sprint.sh newidea --demo"* ]]'
check "NEW Idea is case-insensitive"       '[ "$(sb help NEW Idea)" = "$out" ]'
check "idea → newidea (keyword)"           '[ "$(sb help idea)" = "$out" ]'
check "an idea? ignores filler + punctuation" '[ "$(sb help "an idea?")" = "$out" ]'
check "ideas → newidea (plural)"           '[ "$(sb help ideas)" = "$out" ]'
check "single hit exits 0"                 '[ "$(rc help idea)" = 0 ]'
out="$(sb help review)"
check "several hits → candidate list"      '[[ "$out" == *"Commands that match"* && "$out" == *"  promote "* && "$out" == *"  polish "* ]]'
check "candidates carry the summary"       '[[ "$out" == *"After work — quality sweep"* ]]'
check "candidate list prints no page"      '! grep -q "^\./sprint\.sh " <<<"$out"'
check "candidate list exits 0"             '[ "$(rc help review)" = 0 ]'
out="$(sb help xyzzy frobnicate)"
check "miss → one line"                    '[ "$(wc -l <<<"$out" | tr -d " ")" = 1 ]'
check "miss → points at ./sprint.sh help"  '[[ "$out" == *"No command matches"* && "$out" == *"./sprint.sh help"* ]]'
check "miss exits 1"                       '[ "$(rc help xyzzy)" = 1 ]'
check "filler only is a miss"              '[ "$(rc help what is it)" = 1 ]'
check "no path escape via help words"      '[ "$(rc help ../help/work)" = 1 ]'

# ── Terminal prompt ──────────────────────────────────────────────────
echo "Terminal"
# Stub the AI fallback: record its arguments instead of starting a session.
ASKLOG="$TMP/ask.log"
cat > "$B/docs/sprintbias/scripts/help-ask.sh" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" > "$ASKLOG"
EOF
chmod +x "$B/docs/sprintbias/scripts/help-ask.sh"

out="$(tty_help 'new idea\n')"
check "terminal list ends with the prompt" '[[ "$out" == *"Create:"*"$PROMPT"* ]]'
check "answer resolves to the page"        '[[ "$out" == *"./sprint.sh newidea"* ]]'
check "a page offers no AI"                '[[ "$out" != *"Ask the AI instead?"* ]]'
check "Enter alone exits 0"                '[ "$(tty_rc "\\n")" = 0 ]'
check "end of input exits 0"               '[ "$(tty_rc "")" = 0 ]'
rm -f "$ASKLOG"
out="$(tty_help 'how do I undo a commit\nn\n')"
check "miss offers the AI"                 '[[ "$out" == *"No command matches"*"Ask the AI instead? [y/N]"* ]]'
check "no → no AI"                         '[ ! -f "$ASKLOG" ]'
check "no exits 0"                         '[ "$(tty_rc "xyzzy\\nn\\n")" = 0 ]'
check "Enter at y/N → no AI"               'tty_rc "xyzzy\\n\\n" >/dev/null; [ ! -f "$ASKLOG" ]'
out="$(tty_help 'how do I undo a commit\ny\n')"
check "yes opens the AI with the question" '[ "$(cat "$ASKLOG" 2>/dev/null)" = "how do I undo a commit" ]'
rm -f "$ASKLOG"
out="$(tty_help 'review\ny\n')"
check "candidate list offers the AI too"   '[[ "$out" == *"Commands that match"*"Ask the AI instead?"* ]] && [ -f "$ASKLOG" ]'

# ── AI fallback session (stubbed CLI) ────────────────────────────────
echo "AI fallback"
cp "$ROOT/docs/sprintbias/scripts/help-ask.sh" "$B/docs/sprintbias/scripts/help-ask.sh"
GUIDE="$ROOT/docs/sprintbias/ai/help-ask.md"
check "guidance grounds in the registry"   'grep -q "help/_registry" "$GUIDE"'
check "guidance grounds in help pages"     'grep -q "help/<command>.md" "$GUIDE"'
check "guidance grounds in the manual"     'grep -q "DOCUMENTATION.md" "$GUIDE"'
check "guidance answers with ./sprint.sh"  'grep -q "\./sprint.sh" "$GUIDE"'
check "guidance is read-only"              'grep -qi "read-only" "$GUIDE"'

BIN="$TMP/bin"; mkdir -p "$BIN"
for cli in claude grok; do
    cat > "$BIN/$cli" <<EOF
#!/usr/bin/env bash
for a in "\$@"; do printf '%s\n' "\$a"; done > "$TMP/$cli.args"
echo '{"type":"result","subtype":"success","result":"ok","num_turns":1,"session_id":"x"}'
EOF
    chmod +x "$BIN/$cli"
done
ask() {  # ask FLAG — run help-ask.sh through sprint.sh's provider flag, fast on
    (cd "$B" && env -u CLAUDECODE -u CLAUDE_CODE_SESSION_ID -u GROK_AGENT -u AI_AGENT \
        PATH="$BIN:$PATH" SPRINTBIAS_MODE=exec SPRINTBIAS_FAST=on SPRINTBIAS_RETRIES=0 SPRINTBIAS_STREAM=0 \
        bash -c "export SPRINTBIAS_CLI=$1; [ $1 = grok ] && export SPRINTBIAS_PROVIDER=grok-build || export SPRINTBIAS_PROVIDER=claude-code; bash docs/sprintbias/scripts/help-ask.sh 'how do I start?'" >/dev/null 2>&1) || true
}
ask claude
A="$TMP/claude.args"
check "claude: question reaches the CLI"   'grep -qF "how do I start?" "$A"'
check "claude: plan permission mode"       'grep -A1 -x -- "--permission-mode" "$A" | grep -qx plan'
check "claude: read tools only"            'grep -A1 -x -- "--allowedTools" "$A" | grep -qx "Read,Grep,Glob"'
check "claude: fast mode held off"         '! grep -qx -- "--dangerously-skip-permissions" "$A"'
check "claude: guidance appended"          'grep -q "Help: find the command" "$A"'
ask grok
A="$TMP/grok.args"
check "grok (-g): question reaches the CLI" 'grep -qF "how do I start?" "$A"'
check "grok: plan permission mode"         'grep -A1 -x -- "--permission-mode" "$A" | grep -qx plan'
check "grok: fast mode held off"           '! grep -qx -- "--always-approve" "$A"'

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
