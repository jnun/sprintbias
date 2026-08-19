#!/usr/bin/env python3
"""
SprintBias — browse the learn catalog and play a sandboxed demo.

A pretend, cinematic run: you're new and want to watch the flow before
touching real work. Bare `learn` lists the catalog; `learn <name>` plays one
demo; command-mapped demos also open via `<cmd> --demo`. This is a meta tour
of the catalog itself — not a nested full demo. Pure theater: it touches
nothing in your project — no files written, no tasks moved, no network.

No dependencies. Just:  python3 learn.py
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

# Fake catalog rows — short stand-ins, not a live scan of this folder.
CATALOG = [
    ("example",  "SprintBias — twenty seconds: newtask → chat → work, then git status shows the change."),
    ("session",  "SprintBias — one problem, one session, start to finish."),
    ("gate",     "SprintBias — the gate holds a half-baked task, then a chat sharpens it."),
    ("work",     "SprintBias — one command drains the READY queue: next/ → review/."),
    ("status",   "SprintBias — the whole board at a glance: every stage, plan, and hold."),
]

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}the learn catalog{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — browse demos, play one, trust the sandbox{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.6)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no tasks moved, no network — just the flow, played back.{RESET}")
    print()
    nap(1.0)

def act1():
    act("ACT 1  ·  bare learn lists the catalog",
        "no name → every demo, one line each. pick by situation, not by feature name.")

    beat("You're new. Before changing real files, watch a story of how the "
         "board moves. Start with the catalog.")
    prompt_and_type("./sprint.sh learn")
    print()
    line(f"  {CYAN}Interactive demos{RESET} {DIM}— watch the SprintBias flow run, safely.{RESET}", delay=0.1)
    print()
    line(f"  Available demos {DIM}(play one with:  ./sprint.sh learn <name>):{RESET}", delay=0.08)
    print()
    for name, summary in CATALOG:
        line(f"  {CYAN}{name:<12}{RESET} {summary}", delay=0.08)
    print()
    line(f"  {BLUE}Everything is theater — a demo touches nothing in your project.{RESET}", delay=0.15)
    nap(0.5)
    beat("First line of each demo's docstring is the catalog pitch. Drop a "
         "new *.py in learning/ and it appears — no manifest edit.")
    nap(0.6)

def act2():
    act("ACT 2  ·  learn <name> plays one",
        "name a demo; it runs in the terminal. we only sketch a few lines here.")

    beat("Gate is a good first watch — vague work stops, chat sharpens it, "
         "re-gate lets it through.")
    prompt_and_type("./sprint.sh learn gate")
    print()
    # Sketch only — do NOT nest a full second demo.
    line(f"  {DIM}…playing gate…{RESET}", delay=0.2)
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}the gate — held on purpose{RESET}", delay=0.12)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}", delay=0.12)
    line(f"  {DIM}…ACT 1 · the gate says no…{RESET}", delay=0.15)
    note("cut — you've seen enough to know what \"play a demo\" means")
    nap(0.4)
    beat("In real life that would run the full story. Here we stop early so "
         "this meta-tour doesn't swallow the catalog.")
    nap(0.6)

def act3():
    act("ACT 3  ·  command-mapped demos",
        "many commands also open their story with --demo.")

    beat("Prefer staying on the command you're learning? Same theater, "
         "different front door.")
    prompt_and_type("./sprint.sh work --demo")
    note("plays the work demo — same sandbox as  ./sprint.sh learn work")
    ok("Catalog names and command --demo both land on pure terminal theater.")
    nap(0.4)
    beat("Trust promise everywhere: demos write nothing, call no network, "
         "and need only python3 stdlib.")
    nap(0.6)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — you know how to watch before you do.{RESET}")
    print()
    line(f"  {DIM}the through-line:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}learn{RESET}              "
         f"{GREY}lists the catalog from docstring first lines{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}learn <name>{RESET}       "
         f"{GREY}plays one sandboxed demo{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}<cmd> --demo{RESET}      "
         f"{GREY}same theater, from the command you care about{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}sandbox promise{RESET}    "
         f"{GREY}no files, no moves, no network{RESET}")
    print()
    line(f"  {DIM}try a full story next:{RESET} "
         f"{CYAN}./sprint.sh learn example{RESET}   "
         f"{DIM}·  or{RESET} {CYAN}./sprint.sh learn session{RESET}")
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
