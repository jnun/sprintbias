#!/usr/bin/env python3
"""
SprintBias — twenty seconds: newtask → chat → work, then git status shows the change.

The product in one breath. Capture a bug, sharpen it, run it to review/, and
the proof is `git status`: a code diff plus a task file that moved. Folders
are status, so git already knows. Pure theater: it touches nothing in your
project — no files written, no tasks moved, no network.

Want the why behind each step? Watch  ./sprint.sh learn session  instead.

No dependencies. Just:  python3 example.py
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

# Stable jitter so a recording of this demo lands near 20s every time.
random.seed(42)

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
RED    = _c("\033[38;5;203m")
GREY   = _c("\033[38;5;245m")
PURPLE = _c("\033[38;5;177m")
WHITE  = _c("\033[97m")

WIDTH = min(shutil.get_terminal_size((80, 24)).columns, 78)

# ── timing helpers ────────────────────────────────────────────────────────────
# Twenty-second register: no narrator asides. The git status at the end is
# the point — everything before it is setup for that beat.
def nap(seconds):
    if not FAST:
        time.sleep(seconds)

def type_out(text, color=WHITE, cps=(0.014, 0.028)):
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
    """Render a shell prompt, a thinking beat, then type the cmd."""
    sys.stdout.write(f"{GREEN}➜{RESET}  {CYAN}~/my-app{RESET} {DIM}${RESET} ")
    sys.stdout.flush()
    nap(random.uniform(0.45, 0.70))
    type_out(cmd, color=WHITE)
    nap(0.22)

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

# ── output atoms (fake SprintBias responses) ───────────────────────────────────
def ok(text):    line(f"  {GREEN}✓{RESET} {text}")
def moved(a, b): line(f"    {GREY}{a}{RESET} {DIM}→{RESET} {BLUE}{b}{RESET}")
def note(text):  line(f"  {YELLOW}› {text}{RESET}")

def claude(text):
    """A streamed line from the assistant in a chat session."""
    sys.stdout.write(f"  {PURPLE}claude{RESET} {DIM}│{RESET} ")
    sys.stdout.flush()
    type_out(text, color=WHITE, cps=(0.010, 0.022))
    nap(0.18)

def you(text):
    """The user's reply in a chat session."""
    sys.stdout.write(f"  {GREEN}you{RESET}    {DIM}│{RESET} ")
    sys.stdout.flush()
    nap(random.uniform(0.45, 0.70))
    type_out(text, color=CYAN, cps=(0.014, 0.028))
    nap(0.18)

# ── the run ───────────────────────────────────────────────────────────────────
def banner():
    # Clean stage for a TTY watch (and for the README GIF). --fast and
    # non-TTY skip it so tests and pipes don't get an ANSI wipe.
    if not FAST and sys.stdout.isatty():
        sys.stdout.write("\033[2J\033[H")
        sys.stdout.flush()
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}twenty seconds{RESET}", delay=0)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    print()
    nap(1.1)

def go():
    prompt_and_type('./sprint.sh newtask "Reject empty password on login"')
    ok(f"{BLUE}docs/tasks/backlog/42-reject-empty-password-on-login.md{RESET}")
    nap(0.65)

    prompt_and_type("./sprint.sh chat 42")
    claude("Empty only, or whitespace too? What should the API return?")
    you("both — 400 with \"password required\".")
    spinner("gate: judging workability", ticks=8, done="READY")
    moved("backlog/42", "next/42   · READY ✓")
    nap(0.6)

    prompt_and_type("./sprint.sh work")
    note("1 task READY in next/ — working it")
    moved("next/42", "doing/42")
    spinner(f"working 42  {DIM}reject empty password on login{RESET}",
            ticks=16, done="changes made")
    line(f"    {GREEN}+ reject empty / whitespace-only → 400 \"password required\"{RESET}")
    moved("doing/42", "review/42")
    ok(f"{BOLD}1 task worked.{RESET}  Waiting on you: review the diff.")
    nap(0.8)

    prompt_and_type("git status")
    line(f"{WHITE}On branch main{RESET}", delay=0.08)
    line(f"{WHITE}Changes to be committed:{RESET}", delay=0.10)
    line(f"{GREEN}        renamed:    docs/tasks/doing/42-reject-empty-password-on-login.md{RESET}", delay=0.12)
    line(f"{GREEN}                    -> docs/tasks/review/42-reject-empty-password-on-login.md{RESET}", delay=0.16)
    print()
    line(f"{WHITE}Changes not staged for commit:{RESET}", delay=0.10)
    line(f"{RED}        modified:   src/auth/login.py{RESET}", delay=0.18)
    nap(1.4)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  the change is a git change.{RESET}")
    line(f"  {DIM}spine:{RESET} {CYAN}newtask → chat → work → review/{RESET}"
         f"  {DIM}proof:{RESET} {WHITE}git status{RESET}")
    print()
    line(f"  {DIM}want the why?{RESET} {CYAN}./sprint.sh learn session{RESET}")
    print()
    rule("═")
    print()
    nap(2.4)

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
