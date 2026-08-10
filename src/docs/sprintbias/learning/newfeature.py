#!/usr/bin/env python3
"""
SprintBias — turn a product wish into a feature spec you can plan from.

A pretend, cinematic run: a PM names "team invite links" as a product feature —
not a task yet. A one-line `newfeature` stamps the template; bare `newfeature`
walks users, requirements, and success in a short Q&A and lands a real feature
file. Pure theater: it touches nothing in your project — no files written, no
tasks moved, no network.

No dependencies. Just:  python3 newfeature.py
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

def card(path, path_color, rows):
    """Render a small file preview: a header path and dim key/value rows."""
    line(f"    {DIM}┌─{RESET} {path_color}{path}{RESET}")
    for k, v in rows:
        line(f"    {DIM}│{RESET}  {GREY}{k}{RESET} {DIM}{v}{RESET}")
    line(f"    {DIM}└─{RESET}")

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}a wish becomes a feature{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — a product wish lands as a spec you can plan from{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.6)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no tasks moved, no network — just the flow, played back.{RESET}")
    print()
    nap(1.0)

def act1():
    act("ACT 1  ·  stamp the template",
        "you already know the name — get the file down, fill it later.")

    beat("PM wants team invite links. That's a product shape, not a one-run task. "
         "Capture the slot in one line.")
    prompt_and_type('./sprint.sh newfeature "Team invite links"')
    ok(f"Created feature: {BLUE}docs/features/team-invite-links.md{RESET}")
    nextstep("Edit the file to define requirements and acceptance criteria.")
    nap(0.4)
    beat("docs/features/ holds product specs — not backlog tasks. The file is a "
         "place to define who it's for and what success looks like before anyone "
         "fans it into work.")
    nap(0.7)

def act2():
    act("ACT 2  ·  bare newfeature — define it in conversation",
        "no title yet. a short Q&A fills users, requirements, and success.")

    beat("Same wish, talked into shape. Bare `newfeature` asks who it's for, what "
         "it must do, and how you'll know it worked — then writes the file.")
    prompt_and_type("./sprint.sh newfeature")
    note("Starting feature definition Q&A…")
    print()

    claude("What feature would you like to define? Short name and 1–2 sentences "
           "on what it does.")
    you("team invite links — an admin shares a link, invitees join the workspace "
        "without a manual seat add.")
    nap(0.2)

    claude("Who is this for, and what's their situation right now?")
    you("workspace admins onboarding contractors. today they email me, I add "
        "emails one by one, people wait.")
    nap(0.2)

    claude("What must it do — the specific behaviors? (Best practice: one "
           "revocable link per invite, not a forever open door.)")
    you("create a link with a role and expiry, revoke it, show who used it. "
        "no public forever-links.")
    nap(0.2)

    claude("How will you know it works — what does success look like?")
    you("an admin creates a link, a new user joins with the right role, and "
        "revoking blocks further joins.")
    nap(0.3)

    spinner("writing feature file", ticks=10, done="docs/features/team-invite-links.md")
    print()
    ok(f"Created feature: {BLUE}docs/features/team-invite-links.md{RESET}")
    nextstep("Edit the file to define requirements and acceptance criteria.")
    nap(0.3)
    card("docs/features/team-invite-links.md", CYAN, [
        ("Users   ", "workspace admins onboarding contractors"),
        ("Must do ", "create / revoke / audit invite links with role + expiry"),
        ("Success ", "join with correct role; revoke blocks further joins"),
    ])
    nap(0.5)
    beat("A feature is not a task. Next you sharpen requirements in the file, "
         "then fan the work into tasks when you're ready to plan — the feature "
         "file stays the product source of truth.")
    nap(0.7)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — a product wish has a home.{RESET}")
    print()
    line(f"  {DIM}the through-line:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}feature ≠ task{RESET}          "
         f"{GREY}docs/features/ is product, not the sprint queue{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}name or talk{RESET}            "
         f"{GREY}newfeature \"…\" stamps; bare runs the Q&A{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}then plan from it{RESET}       "
         f"{GREY}edit requirements, fan into tasks later{RESET}")
    print()
    line(f"  {DIM}what you just watched:{RESET} "
         f"{CYAN}newfeature \"…\"  ·  newfeature (Q&A) → docs/features/…{RESET}")
    print()
    line(f"  {DIM}when a feature fans into work:{RESET} "
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
