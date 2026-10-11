#!/usr/bin/env python3
"""
SprintBias — one command drains the READY queue, then one sign-off finishes the plan.

The payoff. next/ is full of gated, READY work and `work` runs it — each task in
its own fresh context, with targeted tests and a proof line, landed in review/.
A held dependent starts the moment its prerequisite lands. The run ends with
your checklist: every call the agents made, one line to change it, and one line
to close each task. Two dials narrow it —
`work N` for a single task, `count N` to cap the drain. Then the finish:
`plan check` reads LANDED, `promote plan:N` runs the full suite once and asks
for one sign-off. Pure theater: it touches nothing in your project — no files
written, no tasks moved, no network.

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
# Plan 12 after plan start: three READY tasks in next/, plus #83 held on #80 so
# the demo shows a dependent starting the moment its prerequisite lands.
# Each entry: id, title, diff line, targeted test.
QUEUE = [
    ("71", "rate-limit the login endpoint",
     "per-IP limiter → 5/min, 429 + Retry-After on the 6th", "login-limit.sh"),
    ("74", "add Retry-After header to 429s",
     "surface the reset window on every throttled response", "retry-after.sh"),
    ("80", "cache the pricing lookup",
     "memoize the price table → one DB hit per minute, not per request", "price-cache.sh"),
]
HELD = ("83", "bill on downgrade",
        "prorate the invoice from the cached price table", "downgrade-bill.sh")
DATE = "2026-10-08"
# Each member's ## Signoff (human) line; None = a task with no human checks.
SIGNOFF = ("Hit login six times: the sixth gets a 429", None,
           "Pricing page loads fast after a deploy",
           "Downgrade a test account: the invoice is right")

def slug(title):
    return title.lower().replace(" ", "-")

def work_one(tid, title, diff, test, fail=None):
    """One task's trip through work: fresh context, targeted tests, a proof
    line, the breaker's edge-case pass, then review/ — landed. `fail` plays one Test log round first."""
    moved(f"next/{tid}", f"doing/{tid}")
    spinner(f"working {tid}  {DIM}{title}{RESET}",
            ticks=random.randint(8, 12), done="changes made")
    line(f"    {GREEN}+ {diff}{RESET}", delay=0.08)
    if fail:
        line(f"    {RED}✗ bash docs/tests/{test}{RESET}  {GREY}{fail}{RESET}", delay=0.1)
        line(f"    {GREY}  → ## Test log, fix, re-run{RESET}", delay=0.1)
    line(f"    {GREEN}✓ bash docs/tests/{test}{RESET}  {DIM}targeted · pass{RESET}", delay=0.08)
    line(f"    {GREY}**Proof**: {DATE} · bash docs/tests/{test} · pass{RESET}", delay=0.08)
    line(f"    {GREEN}✓ breaker{RESET}  {DIM}a fresh agent tried edge cases · 5 tried · 0 broke{RESET}", delay=0.08)
    moved(f"doing/{tid}", f"review/{tid}  · landed")
    nap(0.25)

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}drain the queue, finish the plan{RESET}", delay=0)
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
    for tid, title, _, _ in QUEUE:
        ok(f"{BLUE}next/{tid}{RESET}  {title}")
    print()
    line(f"  {RED}Held{RESET} {DIM}— dependency not landed{RESET}", delay=0.1)
    held(f"{GREY}next/83{RESET}  bill on downgrade   {DIM}waits on{RESET} {BLUE}#80{RESET} {DIM}(not landed yet){RESET}")
    print()
    nap(0.3)
    beat("83 depends on 80. Landed means review/ with a proof line: the tests "
         "passed. The moment 80 lands, 83 can start. No one waits for a sign-off.")
    nap(0.6)

def act2():
    act("ACT 2  ·  drain it",
        "one command, every READY task — targeted tests, a proof line, landed.")

    beat("Each task runs only its own tests, not the whole suite. A failure goes "
         "in the task's ## Test log, gets fixed, and re-runs until green.")
    prompt_and_type("./sprint.sh work")
    line(f"  {GREY}⏳ 1 dependent task(s) start on hold — released automatically{RESET}")
    line(f"  {GREY}   as those prerequisites land (review/ with proof) during this run:{RESET}")
    line(f"  {GREY}    83-bill-on-downgrade.md  (needs: 80 (next/ — runs when its own deps clear)){RESET}")
    print()
    for tid, title, diff, test in QUEUE:
        work_one(tid, title, diff, test,
                 fail="stale price after an update" if tid == "80" else None)
    note("80 landed → 83 released. It starts now, in this same run.")
    work_one(*HELD)
    print()
    ok(f"{BOLD}4 tasks landed.{RESET}  Each in review/ with its proof line.")
    nap(0.4)
    beat("Nothing stopped to ask you. Each call an agent made is waiting at the "
         "end of the run, with one line to change it.")
    checklist()
    beat("Each task ran in a clean context. `work` made the changes and recorded "
         "the proof; it did NOT commit, ship, or sign anything off. Those stay yours.")
    beat("Two dials when you want less: name one task, or cap the run.")
    prompt_and_type("./sprint.sh work 74")
    prompt_and_type("./sprint.sh work count 2")
    nap(0.6)

def checklist():
    """The end-of-run checklist, worded as work.sh prints it."""
    print()
    line(f"{CYAN}▸ Your turn — 4 task(s) built and waiting for you in docs/tasks/review/{RESET}", delay=0.1)
    print()
    line(f"  {BLUE}#71{RESET}  {WHITE}rate-limit the login endpoint{RESET}", delay=0.06)
    line(f"    1. Check the 1 call(s) the AI made for you:", delay=0.06)
    line(f"         {GREY}- Decided: limit per IP, not per account, because credential "
         f"stuffing spreads across accounts{RESET}", delay=0.06)
    line(f"       Want one changed? → {CYAN}./sprint.sh newtask \"<the change you want>\"{RESET}", delay=0.06)
    line(f"    2. Try the change. Something wrong?", delay=0.06)
    line(f"       → {CYAN}./sprint.sh promote --reject 71 \"what is wrong\"{RESET}", delay=0.06)
    line(f"    3. Happy with it? Run its tests; green closes it:", delay=0.06)
    line(f"       → {CYAN}./sprint.sh promote 71{RESET}", delay=0.06)
    print()
    line(f"  {BLUE}#74{RESET}  {WHITE}add Retry-After header to 429s{RESET}", delay=0.06)
    line(f"    1. Try the change. Something wrong?", delay=0.06)
    line(f"       → {CYAN}./sprint.sh promote --reject 74 \"what is wrong\"{RESET}", delay=0.06)
    line(f"    2. Happy with it? Sign it off (the breaker checks it first):", delay=0.06)
    line(f"       → {CYAN}./sprint.sh promote --accept 74{RESET}", delay=0.06)
    print()
    line(f"  {DIM}#80 and #83 follow the same shape.{RESET}", delay=0.06)
    print()
    nap(0.4)

def act3():
    act("ACT 3  ·  the plan finishes: one sign-off",
        "every member landed — the full suite runs once, you approve once.")

    beat("Back to plan 12. Every task is in review/ with proof. plan check says so.")
    prompt_and_type("./sprint.sh plan check 12")
    line(f"  {GREY}Plan state:{RESET}  {GREEN}LANDED{RESET}  {DIM}[**Status:** STARTED]{RESET}")
    line(f"  {GREY}Counts:{RESET}      open 0 · landed 4 · signed off 0  {DIM}(of 4){RESET}")
    line(f"  {GREY}Every member landed. Sign the plan off (full suite once, one approval):{RESET} "
         f"{CYAN}./sprint.sh promote plan:12{RESET}")
    print()
    beat("Now the full suite (TEST_SUITE in your config), once for the whole plan. "
         "Then one checklist and one answer.")
    prompt_and_type("./sprint.sh promote plan:12")
    line(f"  {GREY}Plan 12 is LANDED. 5 task(s) to sign off, in dependency order:{RESET}")
    for tid, title, _, _ in QUEUE + [HELD]:
        line(f"    {BLUE}#{tid}{RESET}  {GREY}{slug(title)}{RESET}", delay=0.04)
    line(f"    {BLUE}#84{RESET}  {GREY}Human test for plan 12{RESET}", delay=0.04)
    line(f"  {GREY}Running the full suite once:{RESET}  {WHITE}bash docs/tests/run-all.sh{RESET}")
    nap(1.0)
    ok(f"Full suite passed. Output: {GREY}docs/tmp/promote-plan-12-suite.log{RESET}")
    print()
    beat("Every person-only check in the plan sits in one task: the human test. "
         "The agents never waited on it.")
    line(f"  {WHITE}Human test #84{RESET} {GREY}— run these, then approve once:{RESET}")
    for (tid, title, _, _), check in zip(QUEUE + [HELD], SIGNOFF):
        if check:
            line(f"    {GREY}- [ ]{RESET} {BLUE}#{tid}:{RESET} {WHITE}{check}{RESET}", delay=0.08)
    print()
    sys.stdout.write(f"  {GREY}Approve plan 12 and move 5 task(s) to done/? [y/N]{RESET} ")
    sys.stdout.flush()
    nap(0.8)
    type_out("y", color=WHITE)
    for tid, *_ in QUEUE + [HELD]:
        ok(f"#{tid} → done/")
    ok("#84 → done/")
    ok(f"Plan 12 is {GREEN}SIGNED OFF{RESET}. Retire it into docs/history/:  {CYAN}./sprint.sh plan done 12{RESET}")
    nap(0.4)
    beat("Agents land work. You sign it off — once per plan, not once per task. "
         "Then you commit and ship.")
    nap(0.6)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  the queue drained, the plan signed off — one approval.{RESET}")
    print()
    line(f"  {DIM}what you just watched:{RESET}")
    for head, why in (
        ("one command, whole queue", "every READY task in next/ → review/"),
        ("targeted tests, a proof line", "landed = review/ + proof"),
        ("landing releases dependents", "83 started the moment 80 landed"),
        ("your checklist at the end", "every call, one line to change or close each"),
        ("one sign-off per plan", "full suite once, then you approve"),
    ):
        line(f"    {PURPLE}•{RESET} {WHITE}{head:<30}{RESET}{GREY}{why}{RESET}")
    print()
    line(f"  {DIM}the spine:{RESET} "
         f"{CYAN}newtask → chat → plan start → {BOLD}work{RESET}{CYAN} → promote plan:N{RESET}")
    print()
    line(f"  {DIM}where the queue came from?{RESET} "
         f"{CYAN}./sprint.sh learn session{RESET}   "
         f"{DIM}·  with a crew?{RESET} {CYAN}learn teamwork{RESET}")
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
