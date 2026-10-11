#!/usr/bin/env python3
"""
SprintBias — the gate holds a half-baked task, then a chat sharpens it.

A pretend, cinematic run: someone tries to push a vague task into the sprint.
The gate stops it with a clear reason, a short chat sharpens the Problem and a
testable success check, and a re-gate lets it through. The point is honesty —
the gate is a real guardrail, not a rubber stamp. Pure theater: it touches
nothing in your project — no files written, no tasks moved, no network.

No dependencies. Just:  python3 gate.py
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
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}the gate — held on purpose{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — a vague task is stopped, sharpened, then let through{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.6)
    # Same trust promise as S0 — the sandbox is the first thing you feel.
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no tasks moved, no network — just the flow, played back.{RESET}")
    print()
    nap(1.0)

def act1():
    act("ACT 1  ·  the gate says no",
        "a half-written task tries to jump into the sprint. it doesn't get to.")

    beat("You jotted a task earlier and want it running now. Everything into "
         "next/ — the sprint — passes the workability gate first.")
    prompt_and_type("./sprint.sh gate --force")
    note("1 task in next/ — reviewing workability")
    print()
    spinner("gate: judging task 57  " + f"{DIM}\"make login better\"{RESET}",
            ticks=12, done="BLOCKED", tone=ORANGE, mark="⏸")
    print()
    held(f"{BOLD}BLOCKED{RESET} — not workable yet. A headless run couldn't tell when it's done.")
    line(f"      {GREY}Problem:{RESET} {DIM}\"make login better\" — better how? no symptom, no user impact.{RESET}")
    line(f"      {GREY}Success:{RESET} {DIM}no testable check — nothing a run could prove it hit.{RESET}")
    ok(f"Wrote a {BOLD}## Questions{RESET} section into the task with what's missing.")
    moved("next/57", "blocked/57   · cannot start: no reasonable reading")
    nap(0.5)
    beat("This is the guardrail doing its job. Vague work waits in blocked/ "
         "instead of running half-understood and burning a context on a guess.")
    nap(0.7)

def act2():
    act("ACT 2  ·  a short chat sharpens it",
        "answer the gate's questions — turn a wish into a testable task.")

    beat("The task isn't wrong, just thin. Talk it into shape; chat rewrites "
         "Problem and Success right in the file.")
    prompt_and_type("./sprint.sh chat 57")
    print()
    claude("The gate flagged \"make login better\" as untestable. What actually "
           "goes wrong today — and how would we know it's fixed?")
    you("brute force. someone can hammer the login with no limit. lock it after "
        "5 bad tries for 15 minutes.")
    claude("Now it's provable. Writing the Problem as the brute-force gap and a "
           "Success check a run can verify: 6th attempt inside 15 min → blocked.")
    print()
    nap(0.4)
    ok(f"Problem + Success rewritten. {GREY}Same task, now workable.{RESET}")
    nextstep("re-gate it — the only way back into next/ is through the gate")
    nap(0.6)
    beat("No sneaking it in with a raw move. Sharpened work re-enters the sprint "
         "the same way everything does — by passing the gate.")
    nap(0.7)

def act3():
    act("ACT 3  ·  re-gate — this time it passes",
        "same gate, same task, real answers. now it's READY.")

    prompt_and_type("./sprint.sh chat 57   " + f"{DIM}# close the loop → re-gate{RESET}")
    print()
    spinner("gate: re-judging task 57", ticks=10, done="READY")
    ok(f"{BOLD}READY{RESET} — clear problem, testable success. Cleared for a headless run.")
    moved("blocked/57", "next/57   · READY ✓")
    ok(f"Task 57 is back in the sprint. {GREY}next/ IS the sprint — now run it.{RESET}")
    nextstep("./sprint.sh work   → drains READY tasks to review/")
    nap(0.5)
    beat("The gate didn't block you — it blocked a guess. Two minutes of chat "
         "bought a task a run can actually finish.")
    nap(0.7)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — held on purpose, then let through.{RESET}")
    print()
    line(f"  {DIM}the through-line:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}the gate is a guardrail{RESET}   "
         f"{GREY}vague work stops in blocked/, it doesn't run{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}blocked is not broken{RESET}     "
         f"{GREY}it means \"cannot start yet\" — define it, don't delete it{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}one door into next/{RESET}       "
         f"{GREY}everything enters the sprint through the same gate{RESET}")
    print()
    line(f"  {DIM}what you just watched:{RESET} "
         f"{CYAN}gate (BLOCKED) → chat → gate (READY){RESET}")
    print()
    line(f"  {DIM}see it end to end:{RESET} {CYAN}./sprint.sh learn session{RESET}")
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
