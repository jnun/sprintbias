#!/usr/bin/env python3
"""
SprintBias — scan outdated and vulnerable deps, file one backlog task with the findings.

A pretend, cinematic run: periodic hygiene. `deps` detects package ecosystems
in the tree, runs each one's native outdated and audit tools (read-only in real
life), and files ONE backlog task with three sections — Outdated, Security
advisories, Upgrade impact. Pure theater: it touches nothing in your project —
no real scan, no task file written, no network.

No dependencies. Just:  python3 deps.py
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

def card(path, path_color, rows):
    """Render a small file preview: a header path and dim key/value rows."""
    line(f"    {DIM}┌─{RESET} {path_color}{path}{RESET}")
    for k, v in rows:
        line(f"    {DIM}│{RESET}  {GREY}{k}{RESET} {DIM}{v}{RESET}")
    line(f"    {DIM}└─{RESET}")

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}deps hygiene, one backlog task{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — scan shape and a filed task, never a real audit{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.6)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo is a simulation. It touches nothing.{RESET}")
    line(f"     {DIM}No real scan, no task write, no network — just the flow, played back.{RESET}")
    print()
    nap(1.0)

def act1():
    act("ACT 1  ·  find the ecosystems",
        "manifests anywhere in the tree — monorepos included, vendor trees pruned.")

    beat("Periodic hygiene: what is outdated, what is vulnerable, and how risky "
         "are the upgrades? One command answers by filing work, not a throwaway log.")
    prompt_and_type("./sprint.sh deps")
    print()
    line(f"  {DIM}[sim] scanning for package.json, requirements.txt, …{RESET}")
    spinner("detecting ecosystems", ticks=10, done="2 found")
    print()
    line(f"  {WHITE}▸ Ecosystems detected:{RESET}")
    line(f"      - Node / JavaScript — (root) (npm)")
    line(f"      - Python — (root)")
    line(f"    {DIM}Raw tool output: docs/tmp/audit-deps-raw.…  (simulated){RESET}")
    print()
    nap(0.4)
    beat("Real life runs each ecosystem's own tools (npm outdated / audit, pip "
         "list --outdated, pip-audit, …). A missing tool is recorded as skipped "
         "— never silently treated as clean.")
    nap(0.6)

def act2():
    act("ACT 2  ·  one backlog task, three sections",
        "Outdated · Security advisories · Upgrade impact — single place to act.")

    spinner("running outdated + audit tools (simulated)", ticks=12, done="findings ready")
    spinner("filing backlog task", ticks=8, done="created (simulated)")
    print()
    task = "docs/tasks/backlog/91-audit-dependency-updates.md"
    ok(f"Filed task: {BLUE}{task}{RESET}")
    print()
    card(task, GREEN, [
        ("Ecosystems", "Node (npm) · Python"),
        ("Outdated  ", "express 4.18.2 → 4.21.2 (minor); requests 2.31.0 → 2.32.3 (minor)"),
        ("Advisories", "GHSA-… medium on lodash — fixed in 4.17.21"),
        ("Impact    ", "lodash used in lib/utils.js — Medium risk, pin then bump"),
    ])
    print()
    line(f"  {GREEN}✓{RESET} Dependency audit complete ({GREEN}FILED{RESET}): "
         f"{BLUE}{task}{RESET}")
    line(f"    {DIM}VERDICT: FILED — 4 outdated, 1 advisory{RESET}")
    print()
    nap(0.4)
    beat("One task, not a pile of logs. Chat it into shape, gate it, work the "
         "upgrades like any other work. The scan was the intake.")
    nextstep("./sprint.sh chat 91   → sharpen and queue when you are ready")
    nap(0.5)
    note("This demo never scanned your tree and never wrote a task file")
    nap(0.6)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — findings become one backlog task, not a log dump.{RESET}")
    print()
    line(f"  {DIM}the through-line:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}native tools, not a reimpl{RESET}  "
         f"{GREY}each ecosystem's outdated + audit CLIs{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}one task, three sections{RESET}    "
         f"{GREY}Outdated · Advisories · Upgrade impact{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}this demo is theater{RESET}        "
         f"{GREY}no scan, no task write, no network{RESET}")
    print()
    line(f"  {DIM}what you just watched:{RESET} "
         f"{CYAN}./sprint.sh deps{RESET}  {DIM}(simulated){RESET}")
    print()
    line(f"   {GREEN}▪{RESET} {WHITE}Simulation complete. Nothing in your project was touched.{RESET}")
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
