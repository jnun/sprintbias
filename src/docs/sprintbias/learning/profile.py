#!/usr/bin/env python3
"""
SprintBias — capture project conventions so every AI command inherits them.

A pretend, cinematic run: a fresh project (or one with drift) needs conventions
written down. `profile` auto-detects stack from manifests, confirms a few
fields with you, and writes docs/sprintbias/project.md — then chat, gate, and
work inherit those conventions automatically. Pure theater: it touches nothing
in your project — no files written, no tasks moved, no network.

No dependencies. Just:  python3 profile.py
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

# ── output atoms (fake SprintBias responses) ───────────────────────────────────
def ok(text):    line(f"  {GREEN}✓{RESET} {text}")
def note(text):  line(f"  {YELLOW}› {text}{RESET}")
def nextstep(t): line(f"  {DIM}next:{RESET} {CYAN}{t}{RESET}")

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}project conventions{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — detect the stack, confirm, inherit everywhere{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.6)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no tasks moved, no network — just the flow, played back.{RESET}")
    print()
    nap(1.0)

def act1():
    act("ACT 1  ·  fresh project, empty conventions",
        "AI commands need a shared sense of language, tests, and structure.")

    beat("Without a profile, every chat and work run guesses your stack. "
         "Profile scans manifests once and writes the answer down.")
    prompt_and_type("./sprint.sh profile")
    note("Creating project profile: docs/sprintbias/project.md")
    spinner("scanning manifests & tree", ticks=10, done="draft ready")
    print()
    claude("From pyproject.toml + pytest.ini + FastAPI imports I draft:")
    print()
    line(f"  {BOLD}# Project Profile{RESET}", delay=0.08)
    line(f"  {GREY}**Language:**{RESET}     Python 3.12", delay=0.08)
    line(f"  {GREY}**Framework:**{RESET}    FastAPI", delay=0.08)
    line(f"  {GREY}**Tests:**{RESET}        pytest · tests/ · unit + API integration", delay=0.08)
    line(f"  {GREY}**Style:**{RESET}        ruff + black", delay=0.08)
    line(f"  {GREY}**Error handling:**{RESET} HTTPException + typed domain errors", delay=0.08)
    line(f"  {GREY}**Structure:**{RESET}    app/ api · services · models", delay=0.08)
    line(f"  {GREY}**Patterns:**{RESET}     dependency-injected routes, pydantic models", delay=0.08)
    print()
    claude("Looks right? Anything to correct before I write project.md?")
    you("yes — tests live under tests/api and tests/unit. otherwise good.")
    claude("Updated Tests field. Writing docs/sprintbias/project.md.")
    print()
    ok(f"Profile written. {GREY}chat · gate · work will inherit these conventions.{RESET}")
    nap(0.5)
    beat("Two or three confirmations, not eight questions — detect first, "
         "ask only about gaps.")
    nap(0.6)

def act2():
    act("ACT 2  ·  profile show — no AI",
        "re-read what was captured without starting a session.")

    beat("Later you just want to see the file. `show` cats it — no model, "
         "no dialogue.")
    prompt_and_type("./sprint.sh profile show")
    print()
    line(f"  {BOLD}# Project Profile{RESET}", delay=0.08)
    line(f"  {GREY}**Language:**{RESET}     Python 3.12", delay=0.06)
    line(f"  {GREY}**Framework:**{RESET}    FastAPI", delay=0.06)
    line(f"  {GREY}**Tests:**{RESET}        pytest · tests/api · tests/unit", delay=0.06)
    line(f"  {DIM}…{RESET}", delay=0.08)
    print()
    note("Bare `profile` again re-scans and surfaces drift (new deps, new test config).")
    nap(0.5)
    beat("After this, every AI command starts with the same project truth — "
         "no re-explaining FastAPI or pytest each session.")
    nap(0.6)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — conventions captured, inherited automatically.{RESET}")
    print()
    line(f"  {DIM}the through-line:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}detect first{RESET}          "
         f"{GREY}manifests + tree → draft profile{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}confirm briefly{RESET}      "
         f"{GREY}you correct gaps; it writes project.md{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}show is free{RESET}          "
         f"{GREY}profile show cats the file, no AI{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}inherit everywhere{RESET}   "
         f"{GREY}chat · gate · work read the same conventions{RESET}")
    print()
    line(f"  {DIM}what you just watched:{RESET} "
         f"{CYAN}profile → confirm → project.md → profile show{RESET}")
    print()
    line(f"  {DIM}see work use the board?{RESET} "
         f"{CYAN}./sprint.sh learn work{RESET}")
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
