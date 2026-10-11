#!/usr/bin/env python3
"""
SprintBias — teamwork, part 2: the work lands, the lead routes, you reject one.

A pretend, cinematic run that picks up where `learn teamwork` left off: the
`api` agent holds #88 and the `ios` agent holds #89 in doing/. Each runs only
its task's tests, writes a proof line, and lands in review/. Landed releases
the next task, so the lead routes #90 without waiting for done/. Then you try
the build on a slow network and reject #89: `promote --reject` files a linked
fix task for the same member, who logs the failing test, fixes it, and lands.
Part 2 of 3. Before: `learn teamwork`. Next: `learn team-signoff`.
Pure theater: it touches nothing in your project — no files written, no
sessions started, no network.

No dependencies. Just:  python3 team-landing.py
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
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}landed releases; a rejection is a fix task{RESET}", delay=0)
    print()
    line(f"   {DIM}teamwork, part 2 of 3 — #88 (api) and #89 (ios) are in doing/; now they land{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.6)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no sessions started, no network — just the flow, played back.{RESET}")
    print()
    nap(1.0)

def act1():
    act("ACT 1  ·  land, and the lead routes on landing",
        "targeted tests, a proof line, review/. landed releases the next task.")
    prompt_and_type("./sprint.sh crew", where="tab 4")
    line(f"  {BOLD}api{RESET} — Owns the API server and the contract")
    out("  doing/  88  API: refresh keeps the old token valid for a grace window")
    line(f"  {BOLD}ios{RESET} — Owns the iOS app")
    out("  next/  90  End-to-end: a refresh race keeps the user logged in")
    out("  doing/  89  iOS: retry once after a token refresh")
    line(f"  {BOLD}lead{RESET} (lead) — Holds the plan, routes tasks")
    out("  leads plan 14: iOS logout race")
    out("  holds nothing")
    print()
    beat("Each member runs only its task's tests, writes the proof line, and lands.")
    tool("api", f"Bash {API_TEST}  → ok")
    tool("api", f"Edit 88 · ## Completed  + **Proof**: {DATE} · {API_TEST} · pass")
    moved("doing/88", "review/88  · landed")
    msg("api", "lead", "#88 landed. Proof line is in the file.")
    tool("ios", f"Bash {IOS_TEST}  → passed")
    tool("ios", f"Edit 89 · ## Completed  + **Proof**: {DATE} · {IOS_TEST} · pass")
    moved("doing/89", "review/89  · landed")
    msg("ios", "lead", "#89 landed. Proof line is in the file.")
    print()
    tool("lead", "Bash ./sprint.sh plan check 14")
    out("Member Folder    Definition  Standing")
    out("#88    review    defined     landed")
    out("#89    review    defined     landed")
    out("#90    next      defined     open")
    says("lead", "88 and 89 landed, so #90 is released. Routing it now.")
    tool("lead", "Edit plan 14 · ## Crew")
    out("- ios — #89 landed; now #90 (built on #88 (landed), #89 (landed))")
    out("- api — #88 landed; next: on call for contract questions")
    msg("lead", "ios", "#90 is yours now, built on #88 and #89 (landed).")
    moved("next/90", "doing/90  Crew: ios")
    beat("Landed releases. Nobody waited for done/, and the board records what #90 is built on.")
    tool("ios", "Edit 90 · ## Completed  + **Proof**: … · pass")
    moved("doing/90", "review/90  · landed")

def act2():
    act("ACT 2  ·  you reject one; the same member fixes it",
        "a rejection is a linked fix task, never a silent rework.")
    beat("You try the build on a slow train network. The app still logs you out.")
    prompt_and_type('./sprint.sh promote --reject 89 "On a slow network the app retries twice and logs out anyway"',
                    where="you")
    ok(f"Filed fix task #91 → {BLUE}docs/tasks/backlog/91-fix-89-ios-retry-once-after-a-token-refresh.md{RESET}")
    out("**Fixes**: #89 · **Crew**: ios · **Plan**: 14")
    out("#89 stays in review/ with **Held**: fix #91")
    out("↺ #90 (landed) builds on #89 — re-check line added to its ## Test log")
    out("Next: shape and run the fix —  ./sprint.sh work 91")
    out("promote closes #89 once #91 is in done/.")
    tool("lead", "Bash ./sprint.sh plan check 14")
    out("Counts:      open 1 · landed 2 · signed off 0  (of 4) · held 1")
    out("#89    review    defined     held: fix #91")
    out("#91    backlog   defined     open")
    beat("Same member, linked fix. #89 is held until #91 lands, and #90 is flagged because it was built on #89.")
    tool("lead", "Edit plan 14 · ## Crew  + ios — now #91 (fixes #89); then re-run #90's tests")
    msg("lead", "ios", "#91 fixes your #89: two retries on a slow network. Then re-check #90.")
    tool("ios", "Bash ./sprint.sh work 91  → gate READY")
    moved("backlog/91", "doing/91  Crew: ios")
    tool("ios", f"Bash {FIX_TEST}  → FAILED: retried 2 times, expected 1")
    tool("ios", "Edit 91 · ## Test log  + the command, the failing test, the error")
    tool("ios", "Edit ios/Net/APIClient.swift  one retry per request, shared across the refresh")
    tool("ios", f"Bash {FIX_TEST}  → passed   {DIM}(#90's tests too){RESET}")
    tool("ios", f"Edit 91 · ## Completed  + **Proof**: {DATE} · {FIX_TEST} · pass")
    moved("doing/91", "review/91  · landed")
    msg("ios", "lead", "#91 landed. #90 re-checked, still green.")

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  part 2 done — four tasks landed, one of them a fix.{RESET}")
    print()
    line(f"  {DIM}the through-line:{RESET}")
    for head, why in (
        ("land with proof", "targeted tests, a **Proof** line, then review/"),
        ("landed releases", "the lead routes the next task on landing"),
        ("a rejection is a fix task", "same member, linked by **Fixes**"),
        ("dependents get a re-check", "work built on the rejected task is flagged"),
    ):
        line(f"    {PURPLE}•{RESET} {WHITE}{head:<29}{RESET}{GREY}{why}{RESET}")
    print()
    nextstep("part 3 — the plan closes with one sign-off:  ./sprint.sh learn team-signoff")
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
