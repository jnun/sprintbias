#!/usr/bin/env python3
"""
SprintBias — teamwork, part 3: the plan closes with one sign-off.

A pretend, cinematic run that picks up where `learn team-landing` left off:
every task in plan 14 (the API and iOS logout race) has landed in review/ with
a proof line, including the fix for the task you rejected. The lead checks the
plan, sees LANDED, and runs the full suite once with `promote plan:14
</dev/null`, which moves nothing. Your `promote plan:14` reuses that green run
(nothing changed since; `--fresh` re-runs it), shows every human check in one
list, and asks for one approval. Then you read the diffs, commit, and ship.
Part 3 of 3. Before: `learn teamwork`, `learn team-landing`.
Pure theater: it touches nothing in your project — no files written, no
sessions started, no network.

No dependencies. Just:  python3 team-signoff.py
Flags:  --fast (no delays)   --no-color   -h/--help
"""

import sys
import time
import shutil
import random

# ── flags ────────────────────────────────────────────────────────────────────
FAST = "--fast" in sys.argv
NO_COLOR = "--no-color" in sys.argv or not sys.stdout.isatty()
if "-h" in sys.argv or "--help" in sys.argv:
    print(__doc__)
    sys.exit(0)

# ── ansi palette ──────────────────────────────────────────────────────────────
def _c(code):
    return "" if NO_COLOR else code

RESET  = _c("\033[0m")
BOLD   = _c("\033[1m")
DIM    = _c("\033[2m")
GREEN  = _c("\033[38;5;42m")
CYAN   = _c("\033[38;5;44m")
BLUE   = _c("\033[38;5;39m")
YELLOW = _c("\033[38;5;220m")
ORANGE = _c("\033[38;5;208m")
RED    = _c("\033[38;5;203m")
GREY   = _c("\033[38;5;245m")
PURPLE = _c("\033[38;5;177m")
WHITE  = _c("\033[97m")

WIDTH = min(shutil.get_terminal_size((80, 24)).columns, 78)

# ── timing helpers ────────────────────────────────────────────────────────────
def nap(seconds):
    if not FAST:
        time.sleep(seconds)

def type_out(text, color=WHITE, cps=(0.012, 0.03)):
    """Typewriter effect, char by char, with tiny human jitter."""
    sys.stdout.write(color)
    for ch in text:
        sys.stdout.write(ch)
        sys.stdout.flush()
        if not FAST:
            time.sleep(random.uniform(*cps))
    sys.stdout.write(RESET + "\n")
    sys.stdout.flush()

def line(text="", color="", delay=0.05):
    sys.stdout.write(color + text + RESET + "\n")
    sys.stdout.flush()
    nap(delay)

def prompt_and_type(cmd, where=""):
    """Render a shell prompt, pause like a thinking human, then type the cmd.
    `where` labels which terminal tab the command runs in."""
    tab = f"{DIM}[{where}]{RESET} " if where else ""
    sys.stdout.write(f"{tab}{GREEN}➜{RESET}  {CYAN}~/my-app{RESET} {DIM}${RESET} ")
    sys.stdout.flush()
    nap(random.uniform(0.4, 0.9))
    type_out(cmd, color=WHITE)
    nap(0.35)

def spinner(label, ticks=8, done="done", tone=GREEN, mark="✓"):
    frames = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    if FAST:
        line(f"  {GREY}{label}… {tone}{done}{RESET}")
        return
    for i in range(ticks):
        sys.stdout.write(f"\r  {PURPLE}{frames[i % len(frames)]}{RESET} {GREY}{label}…{RESET}")
        sys.stdout.flush()
        time.sleep(0.09)
    sys.stdout.write(f"\r  {tone}{mark}{RESET} {GREY}{label} — {tone}{done}{RESET}        \n")
    sys.stdout.flush()

def rule(char="─"):
    line(f"{GREY}{char * WIDTH}{RESET}")

def act(title, subtitle):
    print()
    line(f"{BOLD}{ORANGE}{title}{RESET}")
    line(f"{DIM}{subtitle}{RESET}", delay=0.2)
    rule()
    nap(0.3)

def beat(text):
    """A narrator aside — the 'why' between commands."""
    nap(0.2)
    line(f"  {DIM}{PURPLE}❯ {text}{RESET}", delay=0.3)
    nap(0.3)

# ── output atoms (fake SprintBias responses) ───────────────────────────────────
def ok(text):    line(f"  {GREEN}✓{RESET} {text}")
def held(text):  line(f"  {ORANGE}⏸{RESET} {text}")
def moved(a, b): line(f"    {GREY}{a}{RESET} {DIM}→{RESET} {BLUE}{b}{RESET}")
def note(text):  line(f"  {YELLOW}› {text}{RESET}")
def nextstep(t): line(f"  {DIM}next:{RESET} {CYAN}{t}{RESET}")
def out(text):   line(f"  {GREY}{text}{RESET}")

# ── crew atoms: who is talking ────────────────────────────────────────────────
MEMBERS = {"lead": ORANGE, "api": BLUE, "ios": PURPLE}
DATE = "2026-10-08"
API_TEST = "go test ./server/auth -run TestRefreshGrace"
IOS_TEST = "xcodebuild test -only-testing:AuthTests/RetryOnceTests"
FIX_TEST = "xcodebuild test -only-testing:AuthTests/SlowNetworkRetryTests"
CONTRACT = "contract/auth-refresh.json"

def says(name, text):
    """One crew member speaking in its own terminal."""
    line(f"  {MEMBERS[name]}{BOLD}{name:>4}{RESET} {DIM}│{RESET} {WHITE}{text}{RESET}", delay=0.25)

def tool(name, text):
    """A crew member using one of its tools (shown as the AI CLI shows it)."""
    line(f"  {MEMBERS[name]}{name:>4}{RESET} {DIM}│ ⏺ {text}{RESET}", delay=0.2)

def msg(frm, to, text):
    """A message between sessions: the nudge, never the record."""
    line(f"  {MEMBERS[frm]}{frm}{RESET} {DIM}→{RESET} {MEMBERS[to]}{to}{RESET}  "
         f"{GREY}“{text}”{RESET}", delay=0.3)


# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}every task landed; one sign-off closes the plan{RESET}", delay=0)
    print()
    line(f"   {DIM}teamwork, part 3 of 3 — #88, #89, #90 and the fix #91 have all landed{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.6)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no sessions started, no network — just the flow, played back.{RESET}")
    print()
    nap(1.0)

TASKS = (
    ("88", "API: refresh keeps the old token valid for a grace window",
     "Two requests during a refresh both succeed"),
    ("91", "Fix #89: iOS: retry once after a token refresh", None),
    ("89", "iOS: retry once after a token refresh",
     "Leave the app open past token expiry: you stay logged in"),
    ("90", "End-to-end: a refresh race keeps the user logged in",
     "Run the race on a real phone: no logout"),
)

def real(text, color=GREY):
    """One line of real script output, as printed, set in from the margin."""
    line(f"  {color}{text}{RESET}", delay=0.04)

def batch_head():
    """The top of every `promote plan:14` run: the batch, in dependency order."""
    real("▸ promote plan:14  sign-off batch — iOS logout race")
    real("  Plan 14 is LANDED. 5 task(s) to sign off, in dependency order:", WHITE)
    for tid, title, _ in TASKS:
        real(f"    #{tid}  {title}")
    real("    #92  Human test for plan 14")
    print()

def act1():
    act("ACT 1  ·  the lead runs the full suite once",
        "plan state is read from the folders: every member landed means LANDED.")
    tool("lead", "Bash ./sprint.sh plan check 14")
    real("▸ Plan 14 health — Plan 14: iOS logout race")
    real("  Plan state:  LANDED  [**Status:** STARTED]", WHITE)
    real("  Counts:      open 0 · landed 4 · signed off 0  (of 4)")
    real("  Every member landed. Sign the plan off (full suite once, one approval): ./sprint.sh promote plan:14")
    beat("With no answer, promote runs the suite and moves nothing. The approval stays yours.")
    tool("lead", "Bash ./sprint.sh promote plan:14 </dev/null")
    batch_head()
    real("  Running the full suite once:  make test")
    nap(1.0)
    real(f"  {GREEN}✓{RESET}{GREY} Full suite passed. Output: docs/tmp/promote-plan-14-suite.log")
    real("  …the human checklist and the [y/N] prompt, left unanswered…", DIM)
    real("  Not approved — nothing moved. Re-run and answer y to sign off:")
    says("lead", "Plan 14 is LANDED and the suite is green. One sign-off for you: ./sprint.sh promote plan:14")
    beat("A red suite would file a fix task for the member whose files it names, and nothing would move.")

def act2():
    act("ACT 2  ·  one sign-off for the whole plan",
        "the green run is reused; you check, then approve once.")
    prompt_and_type("./sprint.sh promote plan:14", where="you")
    batch_head()
    real(f"  {GREEN}✓{RESET}{GREY} Full suite reused: it passed at {DATE} 14:04 and nothing changed since (--fresh re-runs it).")
    beat("Nothing changed since the lead's run, so yours is free. #91 comes before #89: a fix closes first.")
    real("  Human test #92 — run these, then approve once:", WHITE)
    print()
    real("    - [ ] Use the app on a train for ten minutes: never logged out", WHITE)
    for tid, title, check in TASKS:
        if check:
            real(f"    - [ ] #{tid}: {check}", WHITE)
    beat("Every person-only check in the plan, in one task. The crew never waited on it.")
    print()
    sys.stdout.write(f"    {GREY}Approve plan 14 and move 5 task(s) to done/? [y/N]{RESET} ")
    sys.stdout.flush()
    nap(0.8)
    type_out("y", color=WHITE)
    for tid, _, _ in TASKS:
        real(f"  {GREEN}✓{RESET}{GREY} #{tid} → done/")
    real(f"  {GREEN}✓{RESET}{GREY} #92 → done/")
    print()
    real(f"  Plan 14 is {GREEN}SIGNED OFF{RESET}{GREY}. Retire it:  {CYAN}./sprint.sh plan done 14")
    print()
    nextstep("you read the diffs, commit, and ship — the agents edit files and stop")

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — two codebases, one contract, one sign-off.{RESET}")
    print()
    line(f"  {DIM}the whole story, in three parts:{RESET}")
    for head, why in (
        ("teamwork", "claim in doing/, announce Touching:, lower id owns shared code"),
        ("team-landing", "land with proof; landed releases; a rejection is a fix task"),
        ("team-signoff", "the lead runs the suite once; you reuse it and approve once"),
    ):
        line(f"    {PURPLE}•{RESET} {WHITE}{head:<14}{RESET}{GREY}{why}{RESET}")
    print()
    line(f"  {DIM}read more:{RESET} {CYAN}docs/sprintbias/guides/crew.md{RESET}   "
         f"{DIM}rules:{RESET} {CYAN}./sprint.sh help work{RESET}")
    print()
    rule("═")
    print()

def main():
    try:
        banner()
        act1()
        act2()
        outro()
    except KeyboardInterrupt:
        sys.stdout.write(RESET + "\n" + DIM + "  …demo interrupted.\n" + RESET)
        sys.exit(130)

if __name__ == "__main__":
    main()
