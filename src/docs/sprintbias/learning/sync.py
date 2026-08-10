#!/usr/bin/env python3
"""
SprintBias — push task changes so GitHub issues stay in sync (demo is theater only).

A pretend, cinematic run: tasks moved and edited on disk, and the matching
GitHub issues should catch up. `sync` commits the changed task files, pushes
main, and lets the Actions workflow update issues. This demo plays that shape
only — pure theater. It never commits, never pushes, and never calls the
network. Treat every line as a simulation of a real run.

No dependencies. Just:  python3 sync.py
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

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}task files → GitHub issues{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — the shape of sync, never a real push{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.6)
    # Trust contract is the first thing — keep family writes/pushes in real life.
    line(f"   {GREEN}▪{RESET} {WHITE}This demo is a simulation. It touches nothing.{RESET}")
    line(f"     {DIM}No commits, no push, no network, no GitHub Actions — theater only.{RESET}")
    print()
    nap(1.0)

def act1():
    act("ACT 1  ·  local work is ahead of the issues",
        "three tasks moved on disk; the mirrored GitHub issues are stale.")

    beat("You gated and worked a few tasks. The markdown is right; the issue "
         "board still shows yesterday. Sync is how the files become issues again.")
    note("On disk (not this demo): next/71, review/74, done/42 — uncommitted")
    nap(0.5)
    beat("Real `sync` commits those task files, pushes main, and the workflow "
         "updates issues. Watch the success shape — then remember: nothing here "
         "was pushed.")
    nap(0.6)

def act2():
    act("ACT 2  ·  the simulated sync",
        "commit task changes → push main → Actions updates issues. THEATER ONLY.")

    prompt_and_type("./sprint.sh sync")
    print()
    line(f"  {CYAN}=== SprintBias GitHub Sync ==={RESET}  "
         f"{DIM}(simulated — no git, no network){RESET}")
    print()
    spinner("staging task files under docs/tasks/", ticks=8, done="3 files")
    line(f"  {GREEN}+{RESET} next: 1 file(s)")
    line(f"  {GREEN}+{RESET} review: 1 file(s)")
    line(f"  {GREEN}+{RESET} done: 1 file(s)")
    print()
    line(f"  {DIM}[sim] would commit:{RESET}  sync: update task files for GitHub issue sync")
    spinner("would push to origin/main", ticks=10, done="ok (simulated)")
    print()
    ok(f"{BOLD}Synced 3 file(s).{RESET}  "
       f"{GREY}GitHub Actions would update issues shortly.{RESET}")
    line(f"  {DIM}Check workflow status:{RESET} "
         f"{CYAN}gh run list --workflow=sync-tasks-to-issues.yml --limit 1{RESET}")
    print()
    nap(0.4)
    beat("Default sync only stages changed task files. Need every task rewritten "
         "as issues? Real life has `./sprint.sh sync --all` — that path needs the "
         "gh CLI up front, so a missing tool fails before any commit.")
    nap(0.5)
    note("--all needs the gh CLI (https://cli.github.com); this demo does not run it")
    nap(0.6)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — that was the shape of a sync. nothing was pushed.{RESET}")
    print()
    line(f"  {DIM}the through-line:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}files are the source{RESET}     "
         f"{GREY}task markdown drives the issue board, not the other way{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}sync is commit + push{RESET}   "
         f"{GREY}main moves; Actions updates issues shortly after{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}this demo is theater{RESET}     "
         f"{GREY}no commit, no push, no network — ever{RESET}")
    print()
    line(f"  {DIM}what you just watched:{RESET} "
         f"{CYAN}./sprint.sh sync{RESET}  {DIM}(simulated){RESET}")
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
