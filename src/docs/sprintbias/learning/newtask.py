#!/usr/bin/env python3
"""
SprintBias — capture an interrupting task in one line without breaking flow.

A pretend, cinematic run: you're mid-work on task 88 (login rate limit) when a
new problem surfaces — empty-state copy is wrong on settings. One line captures
it into backlog/ and you return to what you were doing. Capture is a reflex,
not a context switch. Pure theater: it touches nothing in your project — no
files written, no tasks moved, no network.

No dependencies. Just:  python3 newtask.py
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

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}capture without breaking flow{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — an interrupting problem lands in one line{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.6)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no tasks moved, no network — just the flow, played back.{RESET}")
    print()
    nap(1.0)

def act1():
    act("ACT 1  ·  mid-flow on 88",
        "you're already in the work — login rate limit is open in doing/.")

    beat("Task 88 is live: rate-limit the login endpoint. Diff half-written, "
         "context loaded. This is the flow you don't want to lose.")
    prompt_and_type("./sprint.sh status")
    print()
    note("working now")
    line(f"    {CYAN}doing/88{RESET}  rate-limit the login endpoint  "
         f"{DIM}· in progress{RESET}")
    print()
    ok(f"{GREY}next/{RESET} holds the rest of the sprint — you're not touching it yet")
    nap(0.5)
    beat("Then something else surfaces. Settings empty-state copy is wrong. Real "
         "problem — but not this problem. If you chase it now, 88 cools off.")
    nap(0.7)

def act2():
    act("ACT 2  ·  one-line capture",
        "get it out of your head and into backlog/ — then go back to 88.")

    beat("Don't open a ticket system. Don't start a second chat. One line: name "
         "the interruption, drop it in backlog/, keep your hands on 88.")
    prompt_and_type('./sprint.sh newtask "fix empty-state copy on settings page"')
    print()
    ok("DOC_STATE.md updated successfully")
    ok(f"Created task: {BLUE}docs/tasks/backlog/89-fix-empty-state-copy-on-settings-page.md{RESET}")
    nextstep("talk it into shape — ./sprint.sh chat 89")
    nap(0.5)
    beat("That's the whole beat. Capture is a reflex — a file in backlog/ with "
         "an id. Shape it later with chat; right now you return to original work.")
    nap(0.4)

    # Return to flow
    line(f"  {DIM}back on 88…{RESET}", delay=0.15)
    note(f"still in {CYAN}doing/88{RESET}  rate-limit the login endpoint")
    line(f"    {GREY}89 sits in backlog/ — it will wait. 88 still owns the keyboard.{RESET}")
    nap(0.7)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — the interruption is safe; the flow is intact.{RESET}")
    print()
    line(f"  {DIM}the through-line:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}one line, not a detour{RESET}  "
         f"{GREY}newtask \"…\" stamps backlog/ and stops{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}capture is a reflex{RESET}    "
         f"{GREY}shape with chat later — not mid-interruption{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}return to the work{RESET}     "
         f"{GREY}doing/ still holds what you were finishing{RESET}")
    print()
    line(f"  {DIM}what you just watched:{RESET} "
         f"{CYAN}(mid 88) → newtask \"…\" → backlog/89 → back to 88{RESET}")
    print()
    line(f"  {DIM}when you shape it later:{RESET} "
         f"{CYAN}./sprint.sh chat 89{RESET}   "
         f"{DIM}·  end to end?{RESET} {CYAN}learn session{RESET}")
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
