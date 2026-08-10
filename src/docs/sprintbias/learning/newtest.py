#!/usr/bin/env python3
"""
SprintBias — after deploy, capture a claim you can prove (the gate for promote).

A pretend, cinematic run: you just shipped. The claim is "Signup converts cold
visitors." One line stamps a test loop — claim, how you'll test, what counts as
success — so promote can't wave work into done/ without evidence. Pure theater:
it touches nothing in your project — no files written, no tasks moved, no
network.

No dependencies. Just:  python3 newtest.py
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

def spinner(label, ticks=8, done="done"):
    frames = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    if FAST:
        line(f"  {GREY}{label}… {GREEN}{done}{RESET}")
        return
    for i in range(ticks):
        sys.stdout.write(f"\r  {PURPLE}{frames[i % len(frames)]}{RESET} {GREY}{label}…{RESET}")
        sys.stdout.flush()
        time.sleep(0.09)
    sys.stdout.write(f"\r  {GREEN}✓{RESET} {GREY}{label} — {GREEN}{done}{RESET}        \n")
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
def moved(a, b): line(f"    {GREY}{a}{RESET} {DIM}→{RESET} {BLUE}{b}{RESET}")
def note(text):  line(f"  {YELLOW}› {text}{RESET}")
def nextstep(t): line(f"  {DIM}next:{RESET} {CYAN}{t}{RESET}")

def card(path, path_color, rows):
    """Render a small file preview: a header path and dim key/value rows."""
    line(f"    {DIM}┌─{RESET} {path_color}{path}{RESET}")
    for k, v in rows:
        line(f"    {DIM}│{RESET}  {GREY}{k}{RESET} {DIM}{v}{RESET}")
    line(f"    {DIM}└─{RESET}")

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}a claim you can prove{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — right after deploy, you capture what success must show{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.6)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no tasks moved, no network — just the flow, played back.{RESET}")
    print()
    nap(1.0)

def act1():
    act("ACT 1  ·  right after deploy",
        "shipped is not proven. name the claim while the change is still warm.")

    beat("Signup just went out. The bet you made yourself: cold visitors convert. "
         "If you don't write that down as a testable claim, promote has nothing "
         "honest to gate on later.")
    prompt_and_type('./sprint.sh newtest "Signup converts cold visitors"')
    print()
    ok(f"Created test: {BLUE}docs/tests/signup-converts-cold-visitors.md{RESET}")
    nextstep("Sharpen what you're testing, run it your way, then file follow-ups "
             "with newfeature or newtask.")
    nap(0.4)

    card("docs/tests/signup-converts-cold-visitors.md", GREEN, [
        ("Claim   ", "Signup converts cold visitors"),
        ("How     ", "5 cold visitors · unscripted path · this week"),
        ("Success ", "≥3 of 5 complete signup without help"),
    ])
    nap(0.5)
    beat("Three fields matter: the claim, how you'll test it, what counts as "
         "success. Fill them sharp enough that a stranger could run the loop.")
    nap(0.7)

def act2():
    act("ACT 2  ·  why the loop exists",
        "this file is not a checklist for show — it gates promote.")

    beat("SprintBias will not wave a task into done/ on vibes. `promote` looks "
         "for tests that pass — the claim you can prove. No green loop, no "
         "graduation. That's the contract.")
    note("task can't reach done/ until Tests pass")
    line(f"    {GREY}review/…{RESET} {DIM}→{RESET} {CYAN}promote{RESET} "
         f"{DIM}checks the test loop{RESET} {DIM}→{RESET} "
         f"{GREEN}done/{RESET} {DIM}only when the claim holds{RESET}")
    nap(0.5)
    beat("This demo stops at capture. Running the test and promoting are later "
         "beats — first you need a named claim on disk.")
    nap(0.7)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — the claim is on the board.{RESET}")
    print()
    line(f"  {DIM}the through-line:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}after deploy, write the claim{RESET}  "
         f"{GREY}newtest \"…\" stamps docs/tests/{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}claim · how · success{RESET}         "
         f"{GREY}three fields a stranger can run{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}this loop gates promote{RESET}       "
         f"{GREY}no pass → task stays out of done/{RESET}")
    print()
    line(f"  {DIM}what you just watched:{RESET} "
         f"{CYAN}newtest \"Signup converts cold visitors\" → docs/tests/…{RESET}")
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
