#!/usr/bin/env python3
"""
SprintBias — dry-run first, then clear stale scratch files from docs/tmp/.

A pretend, cinematic run: docs/tmp/ is full of stale AI logs and scratch
files after many runs. Bare `cleanup` is a dry run — it lists what would go
and keeps recent files. Opting into `--delete` would confirm, then remove only
the stale set. Pure theater: it touches nothing in your project — no files
deleted, no disk changed, no network.

No dependencies. Just:  python3 cleanup.py
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
def bad(text):   line(f"  {RED}✗{RESET} {text}")
def note(text):  line(f"  {YELLOW}› {text}{RESET}")
def nextstep(t): line(f"  {DIM}next:{RESET} {CYAN}{t}{RESET}")

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}clear the scratch pile safely{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — dry-run first, delete only when you ask{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.6)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo is a simulation. It touches nothing.{RESET}")
    line(f"     {DIM}No files deleted, no disk changed, no network — just the flow, played back.{RESET}")
    print()
    nap(1.0)

def act1():
    act("ACT 1  ·  look before you sweep",
        "bare cleanup is a dry run — list stale scratch, keep what is still fresh.")

    beat("After a busy week, docs/tmp/ holds AI session logs and old audit dumps. "
         "Default is safe: show what would go, delete nothing.")
    prompt_and_type("./sprint.sh cleanup")
    print()
    line(f"  {CYAN}=== docs/tmp/ cleanup ==={RESET}")
    print()
    spinner("classifying scratch files", ticks=8, done="4 stale · 2 recent")
    print()
    line(f"  {RED}Stale (4 files):{RESET}", delay=0.1)
    bad(f"log-work-71.json {DIM}(12 days ago){RESET}")
    bad(f"log-work-74.json {DIM}(9 days ago){RESET}")
    bad(f"audit-deps-raw.20260301-143022.8841.md {DIM}(14 days ago){RESET}")
    bad(f"gate-session-old.json {DIM}(8 days ago){RESET}")
    print()
    line(f"  {GREEN}Recent (2 files — keeping):{RESET}", delay=0.1)
    ok(f"log-work-80.json {DIM}(today){RESET}")
    ok(f"audit-deps-raw.20260328-091102.2201.md {DIM}(2 days ago){RESET}")
    print()
    line(f"  {DIM}Dry run — nothing was deleted.{RESET}")
    line(f"  Run with {CYAN}--delete{RESET} to remove stale files, "
         f"or {CYAN}--all{RESET} to clear everything.")
    nap(0.5)
    beat("Stale means older than seven days, or always-stale session logs. "
         "Recent files stay until you choose --all.")
    nap(0.7)

def act2():
    act("ACT 2  ·  opt in to delete (theater)",
        "--delete would confirm; this demo answers y and only pretends to remove.")

    beat("You reviewed the list. Stale can go. Real life prompts y/N — here we "
         "show a yes, then only simulate the deletes.")
    prompt_and_type("./sprint.sh cleanup --delete")
    print()
    line(f"  {CYAN}=== docs/tmp/ cleanup ==={RESET}  "
         f"{DIM}(simulated — nothing will be removed){RESET}")
    print()
    line(f"  {RED}Stale (4 files):{RESET}", delay=0.08)
    bad(f"log-work-71.json {DIM}(12 days ago){RESET}")
    bad(f"log-work-74.json {DIM}(9 days ago){RESET}")
    bad(f"audit-deps-raw.20260301-143022.8841.md {DIM}(14 days ago){RESET}")
    bad(f"gate-session-old.json {DIM}(8 days ago){RESET}")
    print()
    # Simulated confirmation — never real stdin for delete.
    line(f"  Delete 4 stale files? [y/N] {CYAN}y{RESET}  {DIM}(simulated answer){RESET}")
    nap(0.3)
    print()
    line(f"  {DIM}[sim] would delete{RESET} log-work-71.json")
    line(f"  {DIM}[sim] would delete{RESET} log-work-74.json")
    line(f"  {DIM}[sim] would delete{RESET} audit-deps-raw.20260301-143022.8841.md")
    line(f"  {DIM}[sim] would delete{RESET} gate-session-old.json")
    print()
    ok(f"{BOLD}Would clear 4 files from docs/tmp/{RESET}  "
       f"{GREY}— not deleted in this demo{RESET}")
    nap(0.4)
    beat("No human at the keyboard? Real life has `--force` for CI and scripts "
         "— same stale set, no y/N prompt.")
    note("--force is --delete without confirmation (for scripts and CI)")
    nextstep("./sprint.sh cleanup            # dry run again anytime")
    nap(0.6)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — default is dry-run; delete is opt-in.{RESET}")
    print()
    line(f"  {DIM}the through-line:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}bare cleanup is safe{RESET}   "
         f"{GREY}lists stale scratch; writes nothing{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}delete is deliberate{RESET}  "
         f"{GREY}--delete confirms; --force for unattended CI{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}this demo is theater{RESET}  "
         f"{GREY}no files removed from docs/tmp/ — ever{RESET}")
    print()
    line(f"  {DIM}what you just watched:{RESET} "
         f"{CYAN}cleanup → cleanup --delete{RESET}  {DIM}(simulated){RESET}")
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
