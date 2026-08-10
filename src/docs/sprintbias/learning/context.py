#!/usr/bin/env python3
"""
SprintBias — one command dumps project state so an agent (or you) can load context.

A pretend, cinematic run: a new agent (or a cold human session) needs the board
without walking every folder. `context` prints a concise snapshot — ideas,
features, plans with status, task counts by stage, bugs — a read-only dump
ready to paste into a prompt or skim before you start. Pure theater: it
touches nothing in your project — no files written, no tasks moved, no network.

No dependencies. Just:  python3 context.py
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
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}load the board in one shot{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — new session, no folder walk, full project state{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.6)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no tasks moved, no network — just the flow, played back.{RESET}")
    print()
    nap(1.0)

def act1():
    act("ACT 1  ·  cold start, warm board",
        "an agent (or you) needs project state before the first decision.")

    beat("Don't open ideas/, features/, plans/, and every task stage by hand. "
         "One command dumps a concise snapshot.")
    prompt_and_type("./sprint.sh context")
    spinner("collecting project state", ticks=9, done="snapshot ready")
    print()
    line(f"  {BOLD}# Project Context Summary{RESET}", delay=0.1)
    print()
    nap(0.3)

def act2():
    act("ACT 2  ·  the snapshot",
        "ideas, features, plans, tasks by folder, bugs — enough to orient.")

    line(f"  {CYAN}## Ideas{RESET}  {DIM}(in refinement){RESET}", delay=0.1)
    line(f"    {GREY}3{RESET}  magic-link login · offline mode · usage dashboards", delay=0.1)
    print()
    line(f"  {CYAN}## Features{RESET}", delay=0.1)
    line(f"    {GREY}billing{RESET}  {DIM}DOING{RESET}   ·  {GREY}SSO{RESET}  {DIM}BACKLOG{RESET}   ·  {GREY}search{RESET}  {DIM}NEXT{RESET}", delay=0.1)
    print()
    line(f"  {CYAN}## Plans{RESET}  {DIM}(relational groupings, not a lifecycle stage){RESET}", delay=0.1)
    line(f"    {PURPLE}▸ checkout-hardening{RESET}   {GREEN}STARTED{RESET}   "
         f"{DIM}3 done · 1 review · 1 doing{RESET}", delay=0.12)
    line(f"    {PURPLE}▸ search-revamp{RESET}        {YELLOW}planning{RESET}  "
         f"{DIM}think complete — not started{RESET}", delay=0.12)
    print()
    line(f"  {CYAN}## Tasks by folder{RESET}  {DIM}(folders are status){RESET}", delay=0.1)
    line(f"    {GREY}backlog{RESET} 12   {CYAN}next{RESET} 4   {YELLOW}doing{RESET} 2   "
         f"{BLUE}review{RESET} 5   {GREEN}done{RESET} 38   {RED}blocked{RESET} 1", delay=0.12)
    print()
    line(f"  {CYAN}## Recent Bugs{RESET}", delay=0.1)
    line(f"    {GREY}2 open{RESET}  empty-password-accepted · flaky-rate-limit-test", delay=0.1)
    print()
    line(f"  {CYAN}## Suggested Action{RESET}", delay=0.1)
    note("1 task in blocked/ — resolve it before draining next/")
    nextstep("./sprint.sh chat <blocked-id>   → answer open questions")
    nap(0.5)
    beat("That's the whole orientation pass. An agent can ingest it; a human "
         "can skim it. Same dump either way.")
    nap(0.6)

def act3():
    act("ACT 3  ·  read-only on purpose",
        "context never moves work — it only loads the picture.")

    ok("Snapshot printed. No files written, no tasks moved.")
    note("status is the living board view; context is the pasteable dump for AI")
    nap(0.4)
    beat("Use context when a session starts cold. Use status when you're "
         "already inside the project and want the panorama.")
    nap(0.6)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — project state in one command.{RESET}")
    print()
    line(f"  {DIM}the through-line:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}one dump{RESET}              "
         f"{GREY}ideas · features · plans · tasks · bugs{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}agent-friendly{RESET}        "
         f"{GREY}paste into a prompt or skim before you start{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}read-only{RESET}            "
         f"{GREY}orients you; never changes the board{RESET}")
    print()
    line(f"  {DIM}what you just watched:{RESET} "
         f"{CYAN}context → snapshot → suggested action{RESET}")
    print()
    line(f"  {DIM}the living panorama?{RESET} "
         f"{CYAN}./sprint.sh learn status{RESET}")
    print()
    rule("═")
    print()

def main():
    try:
        banner()
        act1()
        act2()
        act3()
        outro()
    except KeyboardInterrupt:
        sys.stdout.write(RESET + "\n" + DIM + "  …demo interrupted.\n" + RESET)
        sys.exit(130)

if __name__ == "__main__":
    main()
