#!/usr/bin/env python3
"""
SprintBias — the whole spine in under a minute: capture to review, one breath.

A speed run, not a lesson. One task races through the full lifecycle — captured,
sharpened, run, landed in review/ — with no stopping to explain. It's here to
sell momentum: this is how fast a real problem moves once it's in the pipeline.
Pure theater: it touches nothing in your project — no files written, no tasks
moved, no network.

Want the why behind each step? Watch  ./sprint.sh learn session  instead.

No dependencies. Just:  python3 speedrun.py
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
# Speed-run register: shorter naps and faster typing than S0. Momentum, not
# meditation — the atoms are the same, the pacing is tighter.
def nap(seconds):
    if not FAST:
        time.sleep(seconds)

def type_out(text, color=WHITE, cps=(0.006, 0.016)):
    """Typewriter effect, char by char, with tiny human jitter."""
    sys.stdout.write(color)
    for ch in text:
        sys.stdout.write(ch)
        sys.stdout.flush()
        if not FAST:
            time.sleep(random.uniform(*cps))
    sys.stdout.write(RESET + "\n")
    sys.stdout.flush()

def line(text="", color="", delay=0.03):
    sys.stdout.write(color + text + RESET + "\n")
    sys.stdout.flush()
    nap(delay)

def prompt_and_type(cmd):
    """Render a shell prompt, a quick beat, then type the cmd — fast."""
    sys.stdout.write(f"{GREEN}➜{RESET}  {CYAN}~/my-app{RESET} {DIM}${RESET} ")
    sys.stdout.flush()
    nap(random.uniform(0.15, 0.35))
    type_out(cmd, color=WHITE)
    nap(0.12)

def spinner(label, ticks=6, done="done", tone=GREEN, mark="✓"):
    frames = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    if FAST:
        line(f"  {GREY}{label}… {tone}{done}{RESET}")
        return
    for i in range(ticks):
        sys.stdout.write(f"\r  {PURPLE}{frames[i % len(frames)]}{RESET} {GREY}{label}…{RESET}")
        sys.stdout.flush()
        time.sleep(0.06)
    sys.stdout.write(f"\r  {tone}{mark}{RESET} {GREY}{label} — {tone}{done}{RESET}        \n")
    sys.stdout.flush()

def rule(char="─"):
    line(f"{GREY}{char * WIDTH}{RESET}")

def beat(text):
    """A narrator aside. In the speed run it stays a single short line — the
    momentum register has no room for long 'why' asides (that's what S0 is for)."""
    line(f"  {DIM}{PURPLE}❯ {text}{RESET}", delay=0.15)

# ── output atoms (fake SprintBias responses) ───────────────────────────────────
def ok(text):    line(f"  {GREEN}✓{RESET} {text}")
def moved(a, b): line(f"    {GREY}{a}{RESET} {DIM}→{RESET} {BLUE}{b}{RESET}")
def note(text):  line(f"  {YELLOW}› {text}{RESET}")
def nextstep(t): line(f"  {DIM}next:{RESET} {CYAN}{t}{RESET}")

def claude(text):
    """A streamed line from the assistant in a chat session."""
    sys.stdout.write(f"  {PURPLE}claude{RESET} {DIM}│{RESET} ")
    sys.stdout.flush()
    type_out(text, color=WHITE, cps=(0.004, 0.011))
    nap(0.1)

def you(text):
    """The user's reply in a chat session."""
    sys.stdout.write(f"  {GREEN}you{RESET}    {DIM}│{RESET} ")
    sys.stdout.flush()
    nap(random.uniform(0.25, 0.5))
    type_out(text, color=CYAN, cps=(0.006, 0.016))
    nap(0.1)

# ── momentum device: the spine as a filling track ─────────────────────────────
STAGES = ["capture", "sharpen", "run", "review"]

def track(active):
    """Show the four-stage spine, lighting each stage as we blow past it.
    This is the speed run's signature — you watch the whole spine fill up."""
    parts = []
    for i, name in enumerate(STAGES):
        if i < active:
            parts.append(f"{GREEN}{name}{RESET}")
        elif i == active:
            parts.append(f"{BOLD}{CYAN}{name}{RESET}")
        else:
            parts.append(f"{DIM}{name}{RESET}")
    line("  " + f" {DIM}▸{RESET} ".join(parts), delay=0.1)

# ── the run ───────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}speed run{RESET}", delay=0)
    print()
    line(f"   {DIM}one task, the whole spine — capture to review, no stopping.{RESET}")
    print()
    nap(0.3)
    # Same trust promise as the rest of the catalog — the sandbox first.
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no tasks moved, no network — just the flow, fast.{RESET}")
    print()
    nap(0.6)

def go():
    rule()
    nap(0.2)

    # capture ─────────────────────────────────────────────────────────────────
    track(0)
    prompt_and_type('./sprint.sh newtask "rate-limit the login endpoint"')
    ok(f"{BLUE}docs/tasks/backlog/71-rate-limit-the-login-endpoint.md{RESET}")
    nap(0.25)

    # sharpen ───────────────────────────────────────────────────────────────────
    track(1)
    prompt_and_type("./sprint.sh chat 71")
    claude("Rate-limit by what — IP, account, both? And the ceiling?")
    you("per IP, 5 attempts / minute, then 429.")
    spinner("gate: judging workability", done="READY")
    moved("backlog/71", "next/71   · READY ✓")
    nap(0.2)

    # run ───────────────────────────────────────────────────────────────────────
    track(2)
    prompt_and_type("./sprint.sh work")
    note("1 task READY in next/ — working it")
    moved("next/71", "doing/71")
    spinner(f"working 71  {DIM}rate-limit the login endpoint{RESET}",
            ticks=10, done="changes made")
    line(f"    {GREEN}+ per-IP limiter → 5/min, 429 + Retry-After on the 6th{RESET}")

    # review ─────────────────────────────────────────────────────────────────────
    track(3)
    moved("doing/71", "review/71")
    ok(f"{BOLD}1 task worked.{RESET}  Waiting on you: review the diff, then commit and ship when happy.")
    nap(0.3)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  capture → sharpen → run → review. One breath.{RESET}")
    print()
    line(f"  {DIM}the spine you just watched:{RESET} "
         f"{CYAN}newtask → chat → work{RESET}")
    line(f"  {DIM}the part that's yours:{RESET}     "
         f"{WHITE}review the diff, then commit and ship{RESET}")
    print()
    line(f"  {DIM}want the why behind each move?{RESET} "
         f"{CYAN}./sprint.sh learn session{RESET}")
    print()
    rule("═")
    print()

def main():
    try:
        banner()
        go()
        outro()
    except KeyboardInterrupt:
        sys.stdout.write(RESET + "\n" + DIM + "  …demo interrupted.\n" + RESET)
        sys.exit(130)

if __name__ == "__main__":
    main()
