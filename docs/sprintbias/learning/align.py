#!/usr/bin/env python3
"""
SprintBias — spot feature gaps and orphan tasks before you plan the next sprint.

A pretend, cinematic run: before planning the sprint you check whether features
have work behind them. Billing is covered; SSO has zero tasks; one orphan task
has no Feature field. Read-only — align reports, it never edits. Pure theater:
it touches nothing in your project — no files written, no tasks moved, no network.

No dependencies. Just:  python3 align.py
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
def held(text):  line(f"  {ORANGE}⏸{RESET} {text}")
def note(text):  line(f"  {YELLOW}› {text}{RESET}")
def nextstep(t): line(f"  {DIM}next:{RESET} {CYAN}{t}{RESET}")

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}features vs tasks{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — spot product gaps before you plan the next sprint{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.6)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no tasks moved, no network — just the flow, played back.{RESET}")
    print()
    nap(1.0)

def act1():
    act("ACT 1  ·  coverage where work exists",
        "billing has tasks linked; the product story and the board agree.")

    beat("Before planning, ask: does every feature you care about have work "
         "behind it? Align is read-only — it reports, never edits.")
    prompt_and_type("./sprint.sh align")
    spinner("analyzing features ↔ tasks", ticks=10, done="report ready")
    print()
    line(f"  {BOLD}================================================{RESET}", delay=0.05)
    line(f"    Feature-Task Alignment Analysis", delay=0.05)
    line(f"  {BOLD}================================================{RESET}", delay=0.05)
    print()
    line(f"  {CYAN}{BOLD}Analyzing Features:{RESET}", delay=0.1)
    print()
    line(f"  {BLUE}{BOLD}Feature:{RESET} billing", delay=0.1)
    line(f"    Status: {BOLD}DOING{RESET}", delay=0.08)
    line(f"    {CYAN}Related Tasks:{RESET}", delay=0.08)
    ok("Task 71 in next/     rate-limit the login endpoint")
    ok("Task 80 in next/     cache the pricing lookup")
    ok("Task 83 in backlog/  bill on downgrade")
    nap(0.5)
    beat("Billing is covered — three tasks already point at the feature. "
         "You're not inventing the sprint from a blank page.")
    nap(0.6)

def act2():
    act("ACT 2  ·  GAP — a feature with zero tasks",
        "SSO is on the product map, but nothing on the board builds it.")

    line(f"  {BLUE}{BOLD}Feature:{RESET} SSO", delay=0.1)
    line(f"    Status: {BOLD}BACKLOG{RESET}", delay=0.08)
    line(f"    {CYAN}Related Tasks:{RESET}", delay=0.08)
    note(f"{BOLD}GAP{RESET}  SSO has {BOLD}0{RESET} tasks — no work references this feature")
    line(f"    {YELLOW}(No tasks currently reference this feature){RESET}", delay=0.12)
    print()
    nap(0.4)
    beat("A feature without tasks is a product promise with no delivery path. "
         "Catch it here — before plan start pretends the sprint covers SSO.")
    nap(0.6)

def act3():
    act("ACT 3  ·  orphan — a task with no Feature field",
        "work that floats free of the product map.")

    line(f"  {CYAN}{BOLD}Orphan tasks (no Feature field):{RESET}", delay=0.1)
    print()
    held(f"Task {BOLD}#99{RESET} in backlog/  tidy the deploy script")
    line(f"      {GREY}Feature: (empty){RESET}  {DIM}— not linked to any feature file{RESET}", delay=0.12)
    print()
    note("Feature is optional — orphans aren't errors. They're a planning signal.")
    ok(f"Align finished. {GREY}No files changed — report only.{RESET}")
    nextstep("fill SSO with tasks, or mark the gap intentional; link #99 if it belongs somewhere")
    nap(0.5)
    beat("Coverage, gaps, orphans — three lenses on the same board. Plan the "
         "sprint with eyes open, not after you've already committed next/.")
    nap(0.6)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — product gaps visible before the sprint.{RESET}")
    print()
    line(f"  {DIM}the through-line:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}coverage{RESET}             "
         f"{GREY}features with linked tasks are already in motion{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}GAP{RESET}                  "
         f"{GREY}a feature with 0 tasks needs work or an honest defer{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}orphan{RESET}               "
         f"{GREY}a task with no Feature field — optional, but worth noticing{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}read-only{RESET}            "
         f"{GREY}align never edits; it only reports{RESET}")
    print()
    line(f"  {DIM}what you just watched:{RESET} "
         f"{CYAN}align → billing covered · SSO GAP · #99 orphan{RESET}")
    print()
    line(f"  {DIM}fan a feature into tasks?{RESET} "
         f"{CYAN}./sprint.sh learn feature-plan{RESET}")
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
