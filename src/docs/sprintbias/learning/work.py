#!/usr/bin/env python3
"""
SprintBias — one command drains the READY queue: next/ → review/, hands off.

The payoff. next/ is full of gated, READY work and `work` runs it — each task in
its own fresh context, backlog's promise cashed in. Watch the queue drain: three
tasks picked up, worked, and landed in review/ for you. Then the two variants —
`work N` for a single task, `count N` to cap the drain. Pure theater: it touches
nothing in your project — no files written, no tasks moved, no network.

Where does a READY queue come from? Watch  ./sprint.sh learn session

No dependencies. Just:  python3 work.py
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
# Work register: steady and satisfying — a queue draining, one task at a time.
# Same atoms as S0; pacing sits between session and speedrun.
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

# ── the queue we'll drain ──────────────────────────────────────────────────────
# Three READY tasks in next/ (post plan start), plus one held on a dependency so
# the demo shows work running only what's safe. Each entry: id, title, diff line.
QUEUE = [
    ("71", "rate-limit the login endpoint",
     "per-IP limiter → 5/min, 429 + Retry-After on the 6th"),
    ("74", "add Retry-After header to 429s",
     "surface the reset window on every throttled response"),
    ("80", "cache the pricing lookup",
     "memoize the price table → one DB hit per minute, not per request"),
]

def work_one(tid, title, diff):
    """One task's trip through work: fresh context, next/ → doing/ → review/."""
    moved(f"next/{tid}", f"doing/{tid}")
    spinner(f"working {tid}  {DIM}{title}{RESET}",
            ticks=random.randint(8, 12), done="changes made")
    line(f"    {GREEN}+ {diff}{RESET}", delay=0.08)
    moved(f"doing/{tid}", f"review/{tid}")
    nap(0.25)

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}drain the queue{RESET}", delay=0)
    print()
    line(f"   {DIM}next/ is full of READY work — one command runs all of it{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.5)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no tasks moved, no network — just the flow, played back.{RESET}")
    print()
    nap(0.9)

def act1():
    act("ACT 1  ·  the queue is READY",
        "after plan start, next/ holds gated work — and one thing that must wait.")

    beat("`work` runs everything READY in next/. First, see what's queued — and "
         "why one task isn't going anywhere yet.")
    prompt_and_type("./sprint.sh status")
    print()
    line(f"  {CYAN}READY in next/{RESET} {DIM}— gated, safe to run{RESET}", delay=0.1)
    for tid, title, _ in QUEUE:
        ok(f"{BLUE}next/{tid}{RESET}  {title}")
    print()
    line(f"  {RED}Held{RESET} {DIM}— dependency not satisfied{RESET}", delay=0.1)
    held(f"{GREY}next/83{RESET}  bill on downgrade   {DIM}waits on{RESET} {BLUE}#80{RESET} {DIM}(not done yet){RESET}")
    print()
    nap(0.3)
    beat("83 depends on 80. `work` won't touch it until 80 lands — the queue only "
         "runs what's actually ready. Nothing half-understood, nothing out of order.")
    nap(0.6)

def act2():
    act("ACT 2  ·  drain it",
        "one command, every READY task — each in its own fresh context.")

    beat("Now run the queue. Watch three tasks move next/ → doing/ → review/, "
         "back to back, no babysitting.")
    prompt_and_type("./sprint.sh work")
    note(f"{len(QUEUE)} tasks READY in next/ — working them, freshest context each")
    print()
    for tid, title, diff in QUEUE:
        work_one(tid, title, diff)
    print()
    ok(f"{BOLD}{len(QUEUE)} tasks worked.{RESET}  All in review/ — read the diffs, commit when happy.")
    nap(0.4)
    beat("Each task ran in a clean context — no bleed between them. `work` made "
         "the changes; it did NOT commit or ship. Those calls stay yours, every time.")
    nap(0.6)

def act3():
    act("ACT 3  ·  when you want a narrower drain",
        "same command, two dials — one task by id, or a cap on how many run.")

    beat("Just want one task? Name its id.")
    prompt_and_type("./sprint.sh work 74")
    note("working only 74 — add Retry-After header to 429s")
    moved("next/74", "review/74")
    ok("1 task worked.")
    nap(0.3)

    beat("Draining a huge queue but want to review in batches? Cap it.")
    prompt_and_type("./sprint.sh work count 2")
    note("2 of 6 READY — stopping after two, the rest stay in next/")
    moved("next/71", "review/71")
    moved("next/74", "review/74")
    ok(f"2 tasks worked. {GREY}4 still READY in next/ — run `work` again when you're set.{RESET}")
    nap(0.4)
    beat("Bare `work` drains everything. `work <id>` is a scalpel. `count N` is a "
         "throttle. Same spine, your pace.")
    nap(0.6)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  the queue drained — work is where the plan becomes changes.{RESET}")
    print()
    line(f"  {DIM}what you just watched:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}one command, whole queue{RESET}  "
         f"{GREY}every READY task in next/ → review/{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}fresh context each task{RESET}   "
         f"{GREY}no bleed, no drift between them{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}only what's ready runs{RESET}    "
         f"{GREY}dependency-held work waits its turn{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}you review, commit, and ship{RESET} "
         f"{GREY}work never commits or ships for you{RESET}")
    print()
    line(f"  {DIM}the spine:{RESET} "
         f"{CYAN}newtask → chat → plan start → {BOLD}work{RESET}{CYAN} → promote{RESET}")
    print()
    line(f"  {DIM}where the queue came from?{RESET} "
         f"{CYAN}./sprint.sh learn session{RESET}   "
         f"{DIM}·  the whole board?{RESET} {CYAN}learn status{RESET}")
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
