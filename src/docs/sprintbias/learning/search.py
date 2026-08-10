#!/usr/bin/env python3
"""
SprintBias — find any task by keyword across the whole board.

A pretend, cinematic run: mid-day, the board is large, and you only remember
that the work had "rate limit" in it. One search pulls matches from next/,
review/, and backlog/ without walking folders. Pure theater: it touches
nothing in your project — no files written, no tasks moved, no network.

No dependencies. Just:  python3 search.py
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

def prompt_and_type(cmd):
    """Render a shell prompt, pause like a thinking human, then type the cmd."""
    sys.stdout.write(f"{GREEN}➜{RESET}  {CYAN}~/my-app{RESET} {DIM}${RESET} ")
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
def note(text):  line(f"  {YELLOW}› {text}{RESET}")
def nextstep(t): line(f"  {DIM}next:{RESET} {CYAN}{t}{RESET}")

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}find it by keyword{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — mid-day, the board is large, you only remember a phrase{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.6)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no tasks moved, no network — just the flow, played back.{RESET}")
    print()
    nap(1.0)

def act1():
    act("ACT 1  ·  where did we park the rate-limit work?",
        "dozens of tasks, three stages, one half-remembered phrase.")

    beat("You don't want to open backlog/, next/, and review/ by hand. Search "
         "the whole board for the words you still have.")
    prompt_and_type('./sprint.sh search "rate limit"')
    spinner("scanning tasks across stages", ticks=8, done="3 matches")
    print()
    # Real shape: "  ID  stage  title" then "N task(s) found"
    line(f"  {BOLD}71{RESET}  {CYAN}next{RESET}     rate-limit the login endpoint", delay=0.12)
    line(f"  {BOLD}74{RESET}  {CYAN}review{RESET}   add Retry-After header to 429s", delay=0.12)
    line(f"  {BOLD}91{RESET}  {CYAN}backlog{RESET}  rate-limit magic links", delay=0.12)
    print()
    line(f"  {GREEN}3 task(s) found{RESET}", delay=0.15)
    nap(0.5)
    beat("Same keyword, three stages — next is ready to run, review already "
         "has a related fix, backlog still holds the follow-on.")
    nap(0.6)

def act2():
    act("ACT 2  ·  pick the one you meant",
        "the hit list is short enough to act on.")

    beat("71 is the one you were looking for — still in next/, still READY. "
         "No folder walk required.")
    note(f"71  {GREY}next/{RESET}  rate-limit the login endpoint")
    nextstep("./sprint.sh work 71   → run just that task")
    nap(0.4)
    ok(f"Found by keyword, not by memory of which folder held it.")
    nap(0.6)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — one phrase, the whole board.{RESET}")
    print()
    line(f"  {DIM}the through-line:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}search spans stages{RESET}     "
         f"{GREY}backlog · next · doing · review · done · blocked{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}id + stage + title{RESET}     "
         f"{GREY}enough to act without opening every file{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}no folder walk{RESET}          "
         f"{GREY}keyword in, matches out{RESET}")
    print()
    line(f"  {DIM}what you just watched:{RESET} "
         f"{CYAN}search \"rate limit\" → 3 hits across next/review/backlog{RESET}")
    print()
    line(f"  {DIM}the whole board at a glance?{RESET} "
         f"{CYAN}./sprint.sh learn status{RESET}")
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
