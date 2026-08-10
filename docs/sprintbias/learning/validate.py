#!/usr/bin/env python3
"""
SprintBias — catch a broken task graph before work or promote run on it.

A pretend, cinematic run: someone is about to drain next/ and promote, but
first they ask whether the board is honest. `validate` walks every task file
and surfaces real integrity problems — a title that lies about its ID, a bad
Depends on token, Plan reverse-index drift, and a Tests path that would strand
promote later (report only). Then optional `--fix --dry-run` shows the safe
rewrites without writing anything. Pure theater: it touches nothing in your
project — no files written, no tasks moved, no network.

No dependencies. Just:  python3 validate.py
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
def warn(text):  line(f"  {YELLOW}⚠{RESET}  {text}")
def bad(text):   line(f"  {RED}✗{RESET} {text}")
def note(text):  line(f"  {YELLOW}› {text}{RESET}")
def nextstep(t): line(f"  {DIM}next:{RESET} {CYAN}{t}{RESET}")

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}integrity before you run{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — catch a broken task graph before work or promote{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.6)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no tasks moved, no network — just the check, played back.{RESET}")
    print()
    nap(1.0)

def act1():
    act("ACT 1  ·  ask the board if it is honest",
        "next/ is full and promote is next — but is every file still a real graph?")

    beat("You are about to drain READY work and close review/. First: does the "
         "graph still match the files? Integrity is read-first.")
    prompt_and_type("./sprint.sh validate")
    print()
    line(f"  {BOLD}{WHITE}Validating task integrity...{RESET}")
    print()
    spinner("scanning docs/tasks/*/", ticks=10, done="4 issues")
    print()
    bad(f"{GREY}docs/tasks/next/71-rate-limit-login.md{RESET}")
    warn("Title ID (17) does not match filename ID (71)")
    print()
    bad(f"{GREY}docs/tasks/next/83-bill-on-downgrade.md{RESET}")
    warn("Malformed **Depends on** token (not a task ID or none): soon")
    print()
    line(f"  {YELLOW}Plan reverse-index drift (plan file is authority):{RESET}", delay=0.12)
    warn(f"#{BOLD}80{RESET}  Plan: 5 → none  {DIM}(task claims Plan 5; no plan file lists it){RESET}")
    print()
    line(f"  {YELLOW}Tests-field integrity (promote close-path — report only):{RESET}", delay=0.12)
    warn(f"#{BOLD}74{RESET}  Tests: docs/tests/rate-limit.sh → file not found (typo or missing)")
    note("Tests issues are report-only — they never flip validate's exit code")
    print()
    rule()
    line(f"  {BOLD}Summary:{RESET}")
    line(f"    {RED}Invalid files:  2{RESET}")
    line(f"    {YELLOW}Plan drift:     1{RESET}")
    line(f"    {YELLOW}Tests issues:   1 (report only){RESET}")
    print()
    note("Tip: Run with --fix to auto-correct title-line ID mismatches and Plan drift")
    nap(0.5)
    beat("Two issues would break a real run: a title that lies about its ID, and "
         "a Depends on token that is not a number. The Tests miss is loud here so "
         "promote does not strand later — but it stays report-only.")
    nap(0.7)

def act2():
    act("ACT 2  ·  preview the safe fixes",
        "--fix rewrites only title IDs and Plan drift — dry-run first, nothing written.")

    beat("Safe classes only. Bad Depends on tokens and Tests paths need a human — "
         "validate will not invent them. Preview what --fix would touch.")
    prompt_and_type("./sprint.sh validate --fix --dry-run")
    print()
    line(f"  {BOLD}{WHITE}Validating task integrity...{RESET}  {DIM}(--fix --dry-run){RESET}")
    print()
    bad(f"{GREY}docs/tasks/next/71-rate-limit-login.md{RESET}")
    warn("Title ID (17) does not match filename ID (71)")
    line(f"    {BLUE}[DRY RUN]{RESET} Would set title to: # Task 71: rate limit the login endpoint")
    print()
    bad(f"{GREY}docs/tasks/next/83-bill-on-downgrade.md{RESET}")
    warn("Malformed **Depends on** token (not a task ID or none): soon")
    line(f"    {DIM}(not a safe auto-fix — needs a human){RESET}")
    print()
    line(f"  {YELLOW}Plan reverse-index drift (plan file is authority):{RESET}", delay=0.12)
    warn(f"#{BOLD}80{RESET}  Plan: 5 → none")
    line(f"    {BLUE}[DRY RUN]{RESET} Would sync Plan on 1 task → none")
    print()
    rule()
    line(f"  {BOLD}Summary:{RESET}")
    line(f"    {CYAN}Would fix titles:  1{RESET}")
    line(f"    {CYAN}Would sync Plan:   1{RESET}")
    line(f"    {RED}Still invalid:     1{RESET}  {DIM}(bad Depends on — human){RESET}")
    line(f"    {YELLOW}Tests issues:      1 (report only){RESET}")
    print()
    ok("Dry run complete — nothing was written.")
    nextstep("./sprint.sh validate --fix   # apply title + Plan only when you mean it")
    nap(0.5)
    beat("Integrity check is read-first. --fix is deliberate, and only for the "
         "two safe classes. You stay in control of the graph.")
    nap(0.7)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — the graph told the truth before work ran on it.{RESET}")
    print()
    line(f"  {DIM}the through-line:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}read first{RESET}             "
         f"{GREY}default validate only reports — never rewrites{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}loud before promote{RESET}    "
         f"{GREY}Tests paths are report-only so a typo is not silent{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}--fix is deliberate{RESET}    "
         f"{GREY}title ID + Plan reverse index only; dry-run first{RESET}")
    print()
    line(f"  {DIM}what you just watched:{RESET} "
         f"{CYAN}validate → validate --fix --dry-run{RESET}")
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
