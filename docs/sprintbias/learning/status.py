#!/usr/bin/env python3
"""
SprintBias — the whole board at a glance: every stage, plan, and hold, alive.

The panorama. Not one task's journey but the entire project caught mid-stride —
folders lit with work, a plan STARTED and draining, the READY queue, a task held
on a dependency, a week of velocity. This is what `./sprint.sh status` shows you
every morning, rendered in full. Pure theater: it touches nothing in your
project — the numbers are a stand-in for a busy project, not yours.

Want one task's story instead? Watch  ./sprint.sh learn session

No dependencies. Just:  python3 status.py
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
# Panorama register: calm, like S0 — this is a "take it all in" moment, not a
# race. Same atoms as the rest of the catalog, unhurried pacing.
def nap(seconds):
    if not FAST:
        time.sleep(seconds)

def type_out(text, color=WHITE, cps=(0.01, 0.026)):
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
    nap(random.uniform(0.4, 0.8))
    type_out(cmd, color=WHITE)
    nap(0.3)

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
def note(text):  line(f"  {YELLOW}› {text}{RESET}")
def held(text):  line(f"  {RED}⊘ {text}{RESET}")
def nextstep(t): line(f"  {DIM}next:{RESET} {CYAN}{t}{RESET}")

# ── panorama device: the lifecycle board as lit rows ───────────────────────────
# This demo's signature. Every stage is one row — a labelled bar scaled to the
# busiest folder — so you read the whole project's shape in one glance. next/ is
# marked as THE sprint; folders are status, and here they're all talking at once.
BOARD = [
    ("backlog", 12, GREY,   "raw ideas, unsharpened"),
    ("next",     4, CYAN,   "THE sprint — gated, READY to run"),
    ("doing",    2, YELLOW, "in flight right now"),
    ("review",   5, BLUE,   "worked — waiting on you to commit"),
    ("done",    38, GREEN,  "shipped & test-gated closed"),
    ("blocked",  1, RED,    "cannot start yet: unclear, or needs your access"),
]

def board_row(name, count, tone, aside, peak):
    """One lifecycle folder as a scaled bar + count + aside."""
    barlen = 0 if peak == 0 else round(count / peak * 22)
    bar = "█" * max(barlen, 1)
    mark = f"{BOLD}◆{RESET}" if name == "next" else " "
    label = f"{tone}{name:<8}{RESET}"
    countstr = f"{tone}{count:>2}{RESET}"
    line(f"  {mark} {label} {tone}{bar}{RESET} {countstr}  {DIM}{aside}{RESET}", delay=0.09)

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}the whole board, alive{RESET}", delay=0)
    print()
    line(f"   {DIM}a project caught mid-stride — every stage, plan, and hold at once{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.5)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}The numbers are a stand-in for a busy project — not yours. Just the view.{RESET}")
    print()
    nap(0.9)

def act1():
    act("THE BOARD  ·  folders are status",
        "one command, the entire lifecycle — read the whole shape at a glance.")

    beat("Every morning starts the same way: ask the board where everything is.")
    prompt_and_type("./sprint.sh status")
    print()
    line(f"  {BOLD}{WHITE}my-app{RESET}  {DIM}·  62 tasks tracked  ·  the lifecycle, folder by folder{RESET}")
    print()
    peak = max(c for _, c, _, _ in BOARD)
    for name, count, tone, aside in BOARD:
        board_row(name, count, tone, aside, peak)
    print()
    line(f"    {DIM}flow:{RESET} {GREY}backlog{RESET} {DIM}→{RESET} {CYAN}next{RESET} "
         f"{DIM}→{RESET} {YELLOW}doing{RESET} {DIM}→{RESET} {BLUE}review{RESET} "
         f"{DIM}→{RESET} {GREEN}done{RESET}", delay=0.2)
    nap(0.5)
    beat("The ◆ marks next/ — that IS the sprint. Nothing lands there until the "
         "gate says it's workable, so 'READY' means READY.")
    nap(0.6)

def act2():
    act("PLANS IN FLIGHT  ·  work grouped with intent",
        "a plan is a named list of tasks moving together — some drain, some wait.")

    beat("Bigger efforts ride in plans. `status` shows each one's pulse.")
    prompt_and_type("./sprint.sh status")
    print()
    line(f"  {PURPLE}▸ checkout-hardening{RESET}   {GREEN}STARTED{RESET}   "
         f"{GREEN}{'█'*6}{RESET}{GREY}{'░'*4}{RESET}  {DIM}open 1 · landed 1 · signed off 3 (of 5){RESET}", delay=0.12)
    line(f"      {DIM}landed = review/ with a proof line · signed off = done/{RESET}", delay=0.12)
    line(f"  {PURPLE}▸ search-revamp{RESET}        {YELLOW}planning{RESET}  "
         f"{GREY}{'░'*10}{RESET}  {DIM}think complete — not started yet{RESET}", delay=0.12)
    line(f"      {DIM}5 tasks fanned out, critiqued by two personas — awaiting plan start{RESET}", delay=0.12)
    print()
    nap(0.4)
    beat("`plan start` gates every member and commits the ready ones to next/. "
         "`plan done` only clears once all five reach done/ — the plan can't lie.")
    nap(0.6)

def act3():
    act("THE READY QUEUE  ·  what runs next, and what can't yet",
        "next/ drains in one command — but dependency integrity holds the unsafe back.")

    beat("What would `work` pick up right now? And what's it right to hold?")
    prompt_and_type("./sprint.sh status")
    print()
    line(f"  {CYAN}READY in next/{RESET} {DIM}— `work` drains these into review/{RESET}", delay=0.12)
    ok(f"{BLUE}next/71{RESET}  rate-limit the login endpoint")
    ok(f"{BLUE}next/74{RESET}  add Retry-After header to 429s")
    ok(f"{BLUE}next/80{RESET}  cache the pricing lookup")
    print()
    line(f"  {RED}Held{RESET} {DIM}— dependency not satisfied{RESET}", delay=0.12)
    held(f"{GREY}next/83{RESET}  bill on downgrade   {DIM}waits on{RESET} {BLUE}#80{RESET} {DIM}(in next/, not done){RESET}")
    print()
    nap(0.3)
    beat("`validate` cross-checks every Depends on / Dependents pair, so a task "
         "never runs before the thing it needs. The board refuses to lie about it.")
    nap(0.6)

def act4():
    act("MOMENTUM  ·  the board is moving",
        "a living project isn't a snapshot — it's a rate. Here's the last seven days.")

    prompt_and_type("./sprint.sh status")
    print()
    line(f"  {DIM}last 7 days{RESET}   {GREEN}▲ 14 closed{RESET}   {CYAN}9 gated to READY{RESET}   "
         f"{BLUE}5 in review now{RESET}", delay=0.15)
    line(f"  {DIM}throughput{RESET}   {GREEN}{'▁▃▅▂▇▆█'}{RESET}  {DIM}closes/day — trending up{RESET}", delay=0.15)
    print()
    spinner("integrity: task ids, deps, docs, commands", ticks=10, done="all green")
    ok("Board is consistent — every stage, plan, and dependency checks out.")
    nap(0.5)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  that's the whole board — in all its glory.{RESET}")
    print()
    line(f"  {DIM}what you just read in one view:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}every stage at once{RESET}    "
         f"{GREY}backlog · next · doing · review · done · blocked{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}plans with a pulse{RESET}     "
         f"{GREY}started ones drain, planned ones wait for plan start{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}a queue that can't lie{RESET}  "
         f"{GREY}READY runs; dependency-held work waits, honestly{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}momentum, not a still{RESET}  "
         f"{GREY}throughput and integrity, checked every look{RESET}")
    print()
    line(f"  {DIM}the spine underneath it all:{RESET} "
         f"{CYAN}newtask → chat → plan start → work → promote{RESET}")
    print()
    line(f"  {DIM}want one task's journey through it?{RESET} "
         f"{CYAN}./sprint.sh learn session{RESET}")
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
