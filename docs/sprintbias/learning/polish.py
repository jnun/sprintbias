#!/usr/bin/env python3
"""
SprintBias — a second look at review/ catches work that isn't actually done.

A pretend, cinematic run: three tasks sit in review/ looking finished. `polish`
sweeps them — two pass and stay, one reopens: weak success criteria, a missing
edge case, ## Rework appended, gated back into next/. The felt lesson is a
second-look safety net before close. Pure theater: it touches nothing in your
project — no files written, no tasks moved, no network.

No dependencies. Just:  python3 polish.py
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
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}second look before close{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — polish sweeps review/ and catches rot{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.5)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no tasks moved, no network — just the flow, played back.{RESET}")
    print()
    nap(0.9)

def act1():
    act("ACT 1  ·  work looked done",
        "three tasks in review/ after work — ready to promote, or so it seems.")

    beat("The drain landed everything in review/. Before close, a second look — "
         "`polish` sweeps the folder for work that only looks finished.")
    prompt_and_type("./sprint.sh polish")
    print()
    line(f"  {CYAN}▸ polish{RESET}  {DIM}sweep review/  ·  3 tasks{RESET}")
    note("judging each task against its Problem + Success — not a flag tour")
    print()
    line(f"  {GREY}in review/{RESET}", delay=0.08)
    ok(f"{BLUE}71{RESET}  rate-limit the login endpoint")
    ok(f"{BLUE}74{RESET}  add Retry-After header to 429s")
    ok(f"{BLUE}80{RESET}  cache the pricing lookup")
    nap(0.5)

def act2():
    act("ACT 2  ·  the sweep",
        "PASS stays put; REOPEN appends ## Rework and sends weak work back through the gate.")

    print()
    spinner("polish: task 71  " + f"{DIM}rate-limit the login endpoint{RESET}",
            ticks=9, done="PASS")
    ok(f"#71 PASS  {DIM}— stays in review/{RESET}")
    line(f"      {GREY}Success holds: 6th try → 429; limiter wired; tests named{RESET}")
    print()
    nap(0.25)
    spinner("polish: task 74  " + f"{DIM}add Retry-After header to 429s{RESET}",
            ticks=12, done="REOPEN", tone=ORANGE, mark="↺")
    print()
    note(f"{BOLD}REOPEN{RESET} — looks done, isn't. Weak success criteria; edge case missing.")
    line(f"      {GREY}Success:{RESET} {DIM}\"header present\" — but no value, no unit, no "
         f"check that clients can sleep on it{RESET}")
    line(f"      {GREY}Gap:{RESET}     {DIM}429 without a reset window still leaves clients "
         f"guessing how long to wait{RESET}")
    ok(f"Appended {BOLD}## Rework{RESET} with what the second look found.")
    moved("review/74", "next/74   · reopened via gate")
    line(f"      {DIM}gate re-screens on the way back in — not a raw folder shove{RESET}")
    print()
    nap(0.25)
    spinner("polish: task 80  " + f"{DIM}cache the pricing lookup{RESET}",
            ticks=9, done="PASS")
    ok(f"#80 PASS  {DIM}— stays in review/{RESET}")
    nap(0.4)
    beat("Two stayed. One came back. The safety net is the point — rot doesn't "
         "get a free pass into done/ just because work already ran.")
    nap(0.5)

def act3():
    act("ACT 3  ·  after the sweep",
        "review/ is honest again; the reopened task waits for a real fix.")

    line(f"  {CYAN}review/{RESET} {DIM}— still candidates for promote{RESET}", delay=0.08)
    ok(f"{BLUE}71{RESET}  rate-limit the login endpoint   {GREEN}PASS{RESET}")
    ok(f"{BLUE}80{RESET}  cache the pricing lookup        {GREEN}PASS{RESET}")
    print()
    line(f"  {CYAN}next/{RESET} {DIM}— reopened, with ## Rework as the brief{RESET}", delay=0.08)
    note(f"{ORANGE}74{RESET}  add Retry-After header to 429s   "
         f"{DIM}— fix the success check, cover the reset window{RESET}")
    print()
    line(f"  {DIM}summary{RESET}  {GREEN}2 PASS{RESET}  ·  {ORANGE}1 REOPEN{RESET}  ·  "
         f"{GREY}0 left vague without a reason{RESET}")
    print()
    nextstep("./sprint.sh work 74   → rework with ## Rework in context")
    nextstep("./sprint.sh promote   → close only what's proven (after rework lands)")
    nap(0.4)
    beat("Deep-judge and --code exist for sharper audits — this demo's hero is "
         "the default sweep: review/ gets a second look before you trust it closed.")
    nap(0.5)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — second look caught what \"done\" missed.{RESET}")
    print()
    line(f"  {DIM}what you just watched:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}sweep review/{RESET}          "
         f"{GREY}one command, every task that looked finished{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}PASS stays{RESET}             "
         f"{GREY}solid work remains a promote candidate{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}REOPEN is honest{RESET}       "
         f"{GREY}## Rework + gate back to next/ — not a silent fail{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}safety net before close{RESET} "
         f"{GREY}polish, then promote — rot doesn't ship{RESET}")
    print()
    line(f"  {DIM}the spine:{RESET} "
         f"{CYAN}work → {BOLD}polish{RESET}{CYAN} → promote{RESET}")
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
