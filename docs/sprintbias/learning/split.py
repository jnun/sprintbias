#!/usr/bin/env python3
"""
SprintBias — break an oversized task into ordered subtasks; the graph stays whole.

A pretend, cinematic run: one giant task fans into four dependency-ordered
children via newtask, the parent is retired, and a pre-existing dependent is
rewired to the first child — reciprocal edges, nothing dangling. That heal is
the trust beat. Pure theater: it touches nothing in your project — no files
written, no tasks moved, no network.

No dependencies. Just:  python3 split.py
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

def edge(a, b, label="Depends on"):
    """Show a dependency edge between two task ids."""
    line(f"    {CYAN}#{a}{RESET} {DIM}—{label}→{RESET} {CYAN}#{b}{RESET}")

def fix(before, after):
    """Show a meta line change: red out, green in."""
    line(f"    {RED}- {before}{RESET}")
    nap(0.2)
    line(f"    {GREEN}+ {after}{RESET}")
    nap(0.3)

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}split a giant into ordered work{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — one oversized task fans out; the graph stays whole{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.5)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no tasks moved, no network — just the flow, played back.{RESET}")
    print()
    nap(0.9)

def act1():
    act("ACT 1  ·  too big for one sitting",
        "455 is a feature-shaped wish hiding four real jobs — and something already waits on it.")

    beat("Someone wrote \"add company billing to the dashboard\" as one task. "
         "That's a week, not a run. And #461 already Depends on 455.")
    prompt_and_type(
        "./sprint.sh split docs/tasks/backlog/455-add-company-billing-to-the-dashboard.md")
    print()
    note("oversized parent  ·  pre-existing dependent: #461 email-monthly-invoices")
    line(f"    {DIM}┌─{RESET} {BLUE}backlog/455-add-company-billing-to-the-dashboard.md{RESET}")
    line(f"    {DIM}│{RESET}  {GREY}Problem{RESET}  company billing lives nowhere; dashboard can't show it")
    line(f"    {DIM}│{RESET}  {GREY}Size{RESET}     table + API + perms + UI — four surfaces")
    line(f"    {DIM}│{RESET}  {GREY}Blocked by this:{RESET}  {CYAN}#461{RESET} {DIM}Depends on: 455{RESET}")
    line(f"    {DIM}└─{RESET}")
    nap(0.5)

def act2():
    act("ACT 2  ·  fan out into ordered children",
        "newtask × 4, dependency chain, Parent set — atomic pieces a run can finish.")

    spinner("split: reading task + code, proposing atomic subtasks", ticks=12,
            done="4 children")
    print()
    ok(f"Created {BLUE}462-add-billing-table-and-migration.md{RESET}")
    line(f"      {GREY}Parent: 455 · Depends on: none{RESET}")
    ok(f"Created {BLUE}463-build-billing-api-endpoint.md{RESET}")
    line(f"      {GREY}Parent: 455 · Depends on: 462{RESET}")
    ok(f"Created {BLUE}464-permission-check-on-billing-endpoint.md{RESET}")
    line(f"      {GREY}Parent: 455 · Depends on: 463{RESET}")
    ok(f"Created {BLUE}465-billing-panel-in-dashboard-ui.md{RESET}")
    line(f"      {GREY}Parent: 455 · Depends on: 464{RESET}")
    print()
    line(f"  {DIM}order (execution){RESET}", delay=0.05)
    edge("463", "462")
    edge("464", "463")
    edge("465", "464")
    nap(0.3)
    beat("Migration first, then API, then perms, then UI. Each child is one "
         "discrete change — and the chain is written both ways as we go.")
    nap(0.5)

def act3():
    act("ACT 3  ·  heal the graph, then retire the parent",
        "461 pointed at 455. After retire, it must not dangle — rewire to the first child.")

    beat("Before 455 disappears, every edge through it is healed. Reciprocal "
         "deps on the new chain, then fold dependents onto the first child.")
    spinner("split: healing dependency graph", ticks=10, done="edges reciprocal")
    print()
    note("child chain — both ends of every Depends on stay in sync")
    line(f"    {GREEN}✓{RESET} 462 ← Dependents: 463")
    line(f"    {GREEN}✓{RESET} 463 ← Dependents: 464   · Depends on: 462")
    line(f"    {GREEN}✓{RESET} 464 ← Dependents: 465   · Depends on: 463")
    line(f"    {GREEN}✓{RESET} 465 · Depends on: 464")
    print()
    note(f"pre-existing dependent {CYAN}#461{RESET} pointed at the whole parent")
    fix("461  Depends on: 455",
        "461  Depends on: 462   (first child — the migration)")
    line(f"    {GREEN}✓{RESET} 462  Dependents: 463, 461  {DIM}— reciprocal edge written{RESET}")
    print()
    spinner("split: retiring parent (subtasks verified)", ticks=8, done="455 removed")
    moved("backlog/455-add-company-billing-to-the-dashboard.md",
          f"{DIM}(retired — deleted; children own the work){RESET}")
    print()
    ok(f"{BOLD}Graph whole.{RESET}  Nothing points at deleted #455.")
    held(f"no dangling id  {DIM}— 461 follows 462; chain 462→463→464→465 intact{RESET}")
    nap(0.4)
    beat("That's split's promise. Fan-out without heal would leave ghosts. "
         "Heal first, delete second — the board stays honest.")
    nap(0.5)

def act4():
    act("ACT 4  ·  what you have now",
        "four finishable tasks in backlog/, ordered; the old wish is gone.")

    line(f"  {CYAN}backlog/{RESET} {DIM}— workable pieces, not a hollow wish{RESET}", delay=0.08)
    ok(f"{BLUE}462{RESET}  add billing table + migration")
    ok(f"{BLUE}463{RESET}  billing API endpoint          {DIM}after 462{RESET}")
    ok(f"{BLUE}464{RESET}  permission check on endpoint  {DIM}after 463{RESET}")
    ok(f"{BLUE}465{RESET}  billing panel in dashboard UI {DIM}after 464{RESET}")
    print()
    line(f"  {GREY}still waiting on the chain:{RESET}  "
         f"{CYAN}#461{RESET} email-monthly-invoices  {DIM}Depends on: 462{RESET}")
    print()
    nextstep("chat / gate the children, or newplan them into a billing plan")
    nap(0.4)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — one giant became four; nothing dangled.{RESET}")
    print()
    line(f"  {DIM}what you just watched:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}fan-out{RESET}               "
         f"{GREY}oversized task → atomic, ordered children via newtask{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}dependency order{RESET}     "
         f"{GREY}each child Depends on the previous when order matters{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}graph heal{RESET}           "
         f"{GREY}dependents of the parent rewire to the first child{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}parent retired last{RESET}  "
         f"{GREY}only after subtasks exist — no hollow delete{RESET}")
    print()
    line(f"  {DIM}off-spine:{RESET} "
         f"{CYAN}./sprint.sh split <path>{RESET}  "
         f"{DIM}— one shot, no conversation{RESET}")
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
