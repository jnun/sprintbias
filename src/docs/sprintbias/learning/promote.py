#!/usr/bin/env python3
"""
SprintBias — close only what's proven: Tests green and deps closed → done/.

A pretend, cinematic run: `promote` walks review/ — green Tests close to done/,
no Tests stays for human sign-off, open Depends on holds, a red suite stays put.
Nothing closes unproven. Pure theater: it touches nothing in your project — no
files written, no tasks moved, no network.

No dependencies. Just:  python3 promote.py
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

def type_out(text, color=WHITE, cps=(0.009, 0.022)):
    """Typewriter effect, char by char, with tiny human jitter."""
    sys.stdout.write(color)
    for ch in text:
        sys.stdout.write(ch)
        sys.stdout.flush()
        if not FAST:
            time.sleep(random.uniform(*cps))
    sys.stdout.write(RESET + "\n")
    sys.stdout.flush()

def line(text="", color="", delay=0.04):
    sys.stdout.write(color + text + RESET + "\n")
    sys.stdout.flush()
    nap(delay)

def prompt_and_type(cmd):
    """Render a shell prompt, pause like a thinking human, then type the cmd."""
    sys.stdout.write(f"{GREEN}➜{RESET}  {CYAN}~/my-app{RESET} {DIM}${RESET} ")
    sys.stdout.flush()
    nap(random.uniform(0.35, 0.75))
    type_out(cmd, color=WHITE)
    nap(0.25)

def spinner(label, ticks=8, done="done", tone=GREEN, mark="✓"):
    frames = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    if FAST:
        line(f"  {GREY}{label}… {tone}{done}{RESET}")
        return
    for i in range(ticks):
        sys.stdout.write(f"\r  {PURPLE}{frames[i % len(frames)]}{RESET} {GREY}{label}…{RESET}")
        sys.stdout.flush()
        time.sleep(0.08)
    sys.stdout.write(f"\r  {tone}{mark}{RESET} {GREY}{label} — {tone}{done}{RESET}        \n")
    sys.stdout.flush()

def rule(char="─"):
    line(f"{GREY}{char * WIDTH}{RESET}")

def act(title, subtitle):
    print()
    line(f"{BOLD}{ORANGE}{title}{RESET}")
    line(f"{DIM}{subtitle}{RESET}", delay=0.15)
    rule()
    nap(0.25)

def beat(text):
    """A narrator aside — the 'why' between commands."""
    nap(0.15)
    line(f"  {DIM}{PURPLE}❯ {text}{RESET}", delay=0.25)
    nap(0.2)

# ── output atoms (fake SprintBias responses) ───────────────────────────────────
def ok(text):    line(f"  {GREEN}✓{RESET} {text}")
def moved(a, b): line(f"    {GREY}{a}{RESET} {DIM}→{RESET} {BLUE}{b}{RESET}")
def note(text):  line(f"  {YELLOW}› {text}{RESET}")
def held(text):  line(f"  {RED}⊘ {text}{RESET}")
def nextstep(t): line(f"  {DIM}next:{RESET} {CYAN}{t}{RESET}")

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}close only what's proven{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — promote test-gates review/ into done/{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.5)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no tasks moved, no network — just the flow, played back.{RESET}")
    print()
    nap(0.9)

def act1():
    act("ACT 1  ·  review/ is not done/",
        "four tasks wait. promote runs Tests — and checks Depends on — before any move.")

    beat("Work put them in review/. Close is test-gated: green suite + closed "
         "deps → done/. Everything else stays.")
    prompt_and_type("./sprint.sh promote --dry-run")
    print()
    line(f"  {CYAN}▸ promote{RESET}  {DIM}dry-run  ·  review/ → done/ (test-gated){RESET}")
    note("4 tasks in review/ — no moves yet, just the verdicts")
    print()
    line(f"  {GREY}board{RESET}", delay=0.08)
    ok(f"{BLUE}71{RESET}  rate-limit the login endpoint  "
       f"{DIM}Tests: docs/tests/login-limit.sh{RESET}")
    ok(f"{BLUE}74{RESET}  add Retry-After header to 429s "
       f"{DIM}Tests: none{RESET}")
    ok(f"{BLUE}80{RESET}  cache the pricing lookup       "
       f"{DIM}Tests: docs/tests/pricing-cache.sh{RESET}")
    ok(f"{BLUE}83{RESET}  bill on downgrade              "
       f"{DIM}Tests: …/bill-downgrade.sh · Depends on: 80{RESET}")
    nap(0.5)

def act2():
    act("ACT 2  ·  four verdicts",
        "green closes · no Tests skips · open dep holds · red stays.")

    beat("Same command for real. Watch each gate fire.")
    prompt_and_type("./sprint.sh promote")
    print()
    line(f"  {CYAN}▸ promote{RESET}  {DIM}review/ → done/ (test-gated){RESET}")
    print()

    # #71 green → done/
    spinner("Tests  #71  " + f"{DIM}docs/tests/login-limit.sh{RESET}",
            ticks=9, done="green")
    ok(f"#71 proven green → done/  {DIM}[docs/tests/login-limit.sh]{RESET}")
    moved("review/71", "done/71")
    print()

    # #74 no Tests → skip
    note(f"#74  no **Tests** — stays in review/ for human sign-off")
    line(f"      {DIM}promote never invents proof; empty Tests is a deliberate skip{RESET}")
    print()

    # #83 green Tests but open Depends on → held
    spinner("Tests  #83  " + f"{DIM}docs/tests/bill-downgrade.sh{RESET}",
            ticks=8, done="green")
    held(f"#83 held in review/ — **Depends on** prerequisite not yet closed:")
    line(f"        {CYAN}#80{RESET}  cache the pricing lookup  "
         f"{DIM}(still in review/ — needs review/ or done/){RESET}")
    line(f"      {DIM}green suite is not enough; deps gate the close the same way they gate the run{RESET}")
    print()

    # #80 red → stay
    spinner("Tests  #80  " + f"{DIM}docs/tests/pricing-cache.sh{RESET}",
            ticks=10, done="FAILED", tone=RED, mark="✗")
    held(f"#80 suite failed — stays in review/")
    line(f"      {GREY}fail:{RESET} {DIM}stale price after 60s window — expected miss, got hit{RESET}")
    print()

    line(f"  {DIM}summary{RESET}  {GREEN}1 promoted{RESET}  ·  "
         f"{RED}1 failed{RESET}  ·  {ORANGE}1 held (dep){RESET}  ·  "
         f"{GREY}1 skipped (no test){RESET}")
    nap(0.4)
    beat("One task closed. Three stayed for three different honest reasons — "
         "none of them a silent move to done/.")
    nap(0.5)

def act3():
    act("ACT 3  ·  after promote",
        "done/ earned one; review/ still holds what isn't proven; plans can finish next.")

    line(f"  {CYAN}done/{RESET}", delay=0.08)
    ok(f"{BLUE}71{RESET}  rate-limit the login endpoint   {GREEN}proven{RESET}")
    print()
    line(f"  {CYAN}review/{RESET} {DIM}— still open for cause{RESET}", delay=0.08)
    note(f"{GREY}74{RESET}  no Tests — human sign-off or attach a suite")
    note(f"{RED}80{RESET}  suite red — fix pricing-cache, re-promote")
    note(f"{ORANGE}83{RESET}  waits on #80 — close 80 first, then 83")
    print()
    note("optional: when every member of a plan sits in done/ —")
    nextstep("./sprint.sh plan done <id>   → retire a fully closed plan")
    print()
    nextstep("fix #80's suite, promote again — #83 will unhold once #80 is done/")
    nap(0.4)
    beat("Closing is earned. Tests green and deps closed — that's the whole gate. "
         "Everything else waits where you can still see it.")
    nap(0.5)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — only proven work closed.{RESET}")
    print()
    line(f"  {DIM}what you just watched:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}Tests green → done/{RESET}    "
         f"{GREY}suite scripts under docs/tests/ must pass{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}no Tests → skip{RESET}       "
         f"{GREY}stays in review/ for human sign-off{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}open Depends on → hold{RESET} "
         f"{GREY}dependent never closes ahead of its prereq{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}red suite → stay{RESET}      "
         f"{GREY}failed proof never reaches done/{RESET}")
    print()
    line(f"  {DIM}the spine:{RESET} "
         f"{CYAN}work → polish → {BOLD}promote{RESET}{CYAN} → plan done{RESET}")
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
