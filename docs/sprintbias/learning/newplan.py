#!/usr/bin/env python3
"""
SprintBias — group known task IDs into a plan in one line.

A pretend, cinematic run: four auth tasks already live in backlog (login,
session, logout, tests). You know they belong together — so planning is one
line, not a conversation. `newplan` binds the IDs, stamps the plan file, and
points you at the fast lane. Pure theater: it touches nothing in your project
— no files written, no tasks moved, no network.

No dependencies. Just:  python3 newplan.py
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

def plan_card(title, members):
    """A plan is a relational index of members."""
    line(f"    {DIM}┌─{RESET} {PURPLE}{title}{RESET}")
    for mark_color, mark, mid, desc in members:
        line(f"    {DIM}│{RESET}  {mark_color}{mark}{RESET} {CYAN}{mid}{RESET} "
             f"{GREY}{desc}{RESET}")
    line(f"    {DIM}└─{RESET}")

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}group known work in one line{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — four auth tasks become a named plan without a chat{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.6)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no tasks moved, no network — just the flow, played back.{RESET}")
    print()
    nap(1.0)

def act1():
    act("ACT 1  ·  the pieces are already on the board",
        "four auth tasks captured — you already know they belong together.")

    beat("Login, session, logout, and the tests that prove them. They're sitting "
         "in backlog/ with real IDs. No need to discover the grouping — you have it.")
    prompt_and_type("./sprint.sh status")
    print()
    line(f"  {CYAN}in backlog/{RESET} {DIM}— captured, not yet bound{RESET}", delay=0.1)
    ok(f"{BLUE}102{RESET}  implement login endpoint")
    ok(f"{BLUE}103{RESET}  session token + refresh")
    ok(f"{BLUE}104{RESET}  logout and revoke")
    ok(f"{BLUE}105{RESET}  auth integration tests")
    print()
    nap(0.4)
    beat("Loose IDs in a folder are a pile. A plan is the named index that says "
         "these four are one effort — without moving any task files.")
    nap(0.7)

def act2():
    act("ACT 2  ·  one line binds them",
        "name the plan, list the IDs — scaffolding and membership in a single command.")

    beat("When you know the grouping, planning is not a conversation. It's one "
         "line: title plus the member IDs.")
    prompt_and_type('./sprint.sh newplan "Auth rework" 102 103 104 105')
    print()
    ok("DOC_STATE.md updated (sprint_PLAN_ID=12)")
    ok(f"Created plan: {PURPLE}docs/plans/12-auth-rework.md{RESET}")
    line(f"  {GREY}Members: 102 103 104 105{RESET}")
    print()
    line(f"  {DIM}Next (fast lane — members already bound):{RESET}")
    nextstep("plan start 12  →  work")
    line(f"  {DIM}Optional:{RESET} {CYAN}chat plan 12{RESET}  "
         f"{DIM}/  {CYAN}plan think 12{RESET}")
    nap(0.4)

    plan_card("docs/plans/12-auth-rework.md  ·  Goal: (scaffold — fill or chat plan)", [
        (GREEN, "●", "102", "implement login endpoint"),
        (GREEN, "●", "103", "session token + refresh"),
        (GREEN, "●", "104", "logout and revoke"),
        (GREEN, "●", "105", "auth integration tests"),
    ])
    nap(0.5)
    beat("Members already known → fast lane: plan start, then work. Optional "
         "chat plan / plan think if you want goal prose or a critique pass — "
         "not required when the IDs were the point.")
    nap(0.4)
    beat(f"{DIM}Aside:{RESET} parent:N links exist for hierarchical tasks, but "
         "they're not the hero beat here. When the work is already a flat set of "
         "IDs you trust, `newplan` is the bind.")
    nap(0.7)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — known work, named plan, one line.{RESET}")
    print()
    line(f"  {DIM}the through-line:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}IDs first, plan second{RESET} "
         f"{GREY}capture tasks, then bind the ones you already know{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}one line, not a chat{RESET}    "
         f"{GREY}newplan \"Title\" id id id — membership is the point{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}fast lane next{RESET}         "
         f"{GREY}plan start → work; chat/think are optional polish{RESET}")
    print()
    line(f"  {DIM}what you just watched:{RESET} "
         f"{CYAN}newplan \"Auth rework\" 102 103 104 105{RESET}")
    print()
    line(f"  {DIM}when the feature still needs splitting first:{RESET} "
         f"{CYAN}./sprint.sh learn feature-plan{RESET}")
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
