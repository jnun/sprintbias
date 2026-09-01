#!/usr/bin/env python3
"""
SprintBias — one problem, one session, start to finish.

A pretend, cinematic run: a new user hits a real bug, defines it, and works it
through the lifecycle in one sitting — watching the gate screen the task and the
folders carry it from backlog to review. Pure theater: it touches nothing in
your project — no files written, no tasks moved, no network.

No dependencies. Just:  python3 session.py
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

def claude(text):
    """A streamed line from the assistant in a chat session."""
    sys.stdout.write(f"  {PURPLE}claude{RESET} {DIM}│{RESET} ")
    sys.stdout.flush()
    type_out(text, color=WHITE, cps=(0.006, 0.016))
    nap(0.2)

def you(text):
    """The user's reply in a chat session."""
    sys.stdout.write(f"  {GREEN}you{RESET}    {DIM}│{RESET} ")
    sys.stdout.flush()
    nap(random.uniform(0.5, 1.0))
    type_out(text, color=CYAN, cps=(0.01, 0.028))
    nap(0.2)

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}one problem, one session{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — a new user fixes a bug end to end{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.6)
    # Criterion: the sandbox promise is the FIRST thing you feel.
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no tasks moved, no network — just the flow, played back.{RESET}")
    print()
    nap(1.0)

def act1():
    act("ACT 1  ·  the 3am one-off",
        "login accepts an empty password. capture it, sharpen it, queue it.")

    beat("A real bug just bit you. Don't lose it — make it a task.")
    prompt_and_type('./sprint.sh newtask "reject empty password on login"')
    ok(f"Created task: {BLUE}docs/tasks/backlog/42-reject-empty-password-on-login.md{RESET}")
    nextstep("fill the Problem + a success check, then define it")
    nap(0.5)

    beat("It lands in backlog/ — the folder IS the status. Now talk it into shape "
         "so a headless run can actually execute it.")
    prompt_and_type("./sprint.sh chat 42")
    print()
    claude("The title says \"reject empty password.\" Empty only, or also all-"
           "whitespace? And do you want a specific message back to the user?")
    you("both — empty and whitespace-only. return a 400 with \"password required\".")
    claude("Clear and testable. Writing that into Success criteria and screening "
           "it for readiness.")
    print()
    nap(0.4)
    spinner("gate: judging workability", done="READY")
    moved("backlog/42", "next/42   · READY ✓")
    ok(f"Task 42 defined and queued. {GREY}next/ IS the sprint.{RESET}")
    nap(0.5)
    beat("The gate didn't rubber-stamp it — a vague task would've stopped in "
         "blocked/ for a decision instead of running half-understood.")
    nap(0.7)

def act2():
    act("ACT 2  ·  run it to review",
        "one command drains the ready queue and does the work.")

    beat("42 is READY in next/. `work` picks up every ready task and runs it in a "
         "fresh context — here, just the one.")
    prompt_and_type("./sprint.sh work")
    note("1 task READY in next/ — working it")
    moved("next/42", "doing/42")
    spinner("working 42  " + f"{DIM}reject empty password on login{RESET}",
            ticks=12, done="changes made")
    diff_add = lambda t: line(f"    {GREEN}+ {t}{RESET}")
    diff_add("reject empty / whitespace-only password → 400 \"password required\"")
    moved("doing/42", "review/42")
    ok(f"{BOLD}1 task worked.{RESET}  Review the diff and commit when happy.")
    nap(0.5)
    beat("backlog → next → doing → review, each move an honest status change. "
         "sprint.sh made the changes; it did NOT commit or ship — those calls stay yours.")
    nap(0.7)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — one problem, one session.{RESET}")
    print()
    line(f"  {DIM}the through-line:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}folders are status{RESET}     "
         f"{GREY}backlog → next → doing → review{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}the gate guards{RESET}        "
         f"{GREY}only READY work runs; vague work waits in blocked/{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}you stay in control{RESET}    "
         f"{GREY}it works the queue; you review, commit, and ship{RESET}")
    print()
    line(f"  {DIM}the spine you just watched:{RESET} "
         f"{CYAN}newtask → chat → work{RESET}")
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
