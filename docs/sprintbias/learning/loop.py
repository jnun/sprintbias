#!/usr/bin/env python3
"""
SprintBias — unattended autopilot: refill the sprint, drain work, gate still holds.

A pretend, cinematic run: `loop --refill` drains READY work from next/, then
when the queue empties runs plan start on a READY plan — gating each member as it
commits. One vague member is held out; the ready ones refill next/ and keep
draining. No human at the keyboard, and nothing unready slips through. Pure
theater: it touches nothing in your project — no files written, no tasks moved,
no network.

No dependencies. Just:  python3 loop.py
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

def work_one(tid, title):
    """One iteration: work count 1 → review/."""
    moved(f"next/{tid}", f"doing/{tid}")
    spinner(f"work count 1  {DIM}#{tid} {title}{RESET}",
            ticks=random.randint(7, 10), done="changes made")
    moved(f"doing/{tid}", f"review/{tid}")
    nap(0.2)

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}unattended autopilot{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — loop refills, drains, and the gate still holds{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.5)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no tasks moved, no network — just the flow, played back.{RESET}")
    print()
    nap(0.9)

def act1():
    act("ACT 1  ·  start the autopilot",
        "next/ has ready work; a READY plan waits to refill when the queue empties.")

    beat("Hands off. `loop --refill` keeps the sprint fed and drained until the "
         "hour cap — no babysitting.")
    prompt_and_type("./sprint.sh loop --refill --hours 1")
    print()
    line(f"  {CYAN}▸ loop{RESET}  {DIM}refill on · hours 1 · recover stranded doing/{RESET}")
    ok(f"doing/ empty — nothing stranded to recover")
    print()
    line(f"  {GREY}queue{RESET}   next/ {GREEN}2 READY{RESET}   "
         f"review/ {DIM}0{RESET}   "
         f"plans READY {PURPLE}1{RESET} {DIM}(plan 11){RESET}")
    note("2 in next/ — drain first; refill when empty")
    nap(0.5)

def act2():
    act("ACT 2  ·  drain what's already READY",
        "each iteration: work count 1 → review/. two tasks, then next/ is empty.")

    beat("Loop picks the lowest-id READY task, one fresh context at a time.")
    print()
    line(f"  {DIM}iteration 1{RESET}", delay=0.05)
    work_one("91", "add logout endpoint")
    print()
    line(f"  {DIM}iteration 2{RESET}", delay=0.05)
    work_one("92", "wire logout into the nav")
    print()
    ok(f"next/ empty. {GREY}2 in review/ — both worked unattended.{RESET}")
    nap(0.4)
    beat("Queue drained. With --refill, empty next/ is not a stop — it's a signal "
         "to start the lowest READY plan.")
    nap(0.5)

def act3():
    act("ACT 3  ·  refill — plan start gates as it commits",
        "plan 11 commits members into next/; one vague task is held out.")

    note("next/ empty → plan start on lowest READY plan: 11-session-hardening")
    print()
    spinner("plan start 11: gating members as they commit", ticks=12,
            done="3 READY, 1 held")
    print()
    moved("backlog/101", "next/101   · READY ✓   rotate session secrets")
    moved("backlog/102", "next/102   · READY ✓   expire idle sessions")
    moved("backlog/103", "next/103   · READY ✓   audit log on force-logout")
    print()
    spinner("gate: judging task 104  " + f"{DIM}\"make sessions better\"{RESET}",
            ticks=10, done="not READY", tone=ORANGE, mark="⏸")
    held(f"#104 make sessions better  {DIM}— vague; held in backlog/ "
         f"(not committed to next/){RESET}")
    line(f"      {GREY}Problem:{RESET} {DIM}no symptom, no success check — a run couldn't finish it{RESET}")
    print()
    ok(f"Plan 11 refilled next/ with 3. {GREY}The gate held #104 with nobody watching.{RESET}")
    nap(0.4)
    beat("That's the trust beat. Autopilot refills — but only what passes. "
         "Unready work never slips into the drain.")
    nap(0.5)

def act4():
    act("ACT 4  ·  drain the refill, stop cleanly",
        "three more iterations, then nothing ready — loop exits.")

    print()
    line(f"  {DIM}iteration 3{RESET}", delay=0.05)
    work_one("101", "rotate session secrets")
    print()
    line(f"  {DIM}iteration 4{RESET}", delay=0.05)
    work_one("102", "expire idle sessions")
    print()
    line(f"  {DIM}iteration 5{RESET}", delay=0.05)
    work_one("103", "audit log on force-logout")
    print()
    ok(f"{BOLD}5 tasks worked → review/.{RESET}  next/ empty again.")
    note("no more READY work · no further READY plans · stopping cleanly")
    line(f"  {GREY}held aside:{RESET}  {ORANGE}#104{RESET} {DIM}still not in next/ — needs a decision{RESET}")
    print()
    nextstep("./sprint.sh chat 104   → sharpen, then re-gate when you're back")
    nap(0.4)
    beat("Loop never forced #104. When nothing ready remains, it stops — it "
         "doesn't spin, guess, or raw-promote.")
    nap(0.5)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — autopilot ran; the gate still held.{RESET}")
    print()
    line(f"  {DIM}what you just watched:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}drain then refill{RESET}      "
         f"{GREY}work count 1 per tick; plan start when next/ empties{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}gate on every commit{RESET}   "
         f"{GREY}members enter next/ only if READY{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}unattended, not unsafe{RESET} "
         f"{GREY}vague work held out while ready work keeps moving{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}clean stop{RESET}            "
         f"{GREY}nothing ready → exit, no spinning{RESET}")
    print()
    line(f"  {DIM}not the same as{RESET} {CYAN}learn speedrun{RESET}"
         f"{DIM} — that one's a human-driven race; this is hands-off trust.{RESET}")
    print()
    rule("═")
    print()

def main():
    try:
        banner()
        act1()
        act2()
        act3()
        act4()
        outro()
    except KeyboardInterrupt:
        sys.stdout.write(RESET + "\n" + DIM + "  …demo interrupted.\n" + RESET)
        sys.exit(130)

if __name__ == "__main__":
    main()
