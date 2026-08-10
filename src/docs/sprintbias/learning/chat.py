#!/usr/bin/env python3
"""
SprintBias — talk an existing plan into shape: goal, order, READY.

A pretend, cinematic run: plan 9 "Passwordless login" is a partial DRAFT —
Goal vague, members unordered, a stray task that doesn't belong, one missing.
`chat plan` walks the draft: sharpens the Goal, reorders members (prereqs first),
drops the stray, adds the missing piece, notes parallelism, and flips DRAFT →
READY on confirm. The only durable write is the plan file. Pure theater: it
touches nothing in your project — no files written, no tasks moved, no network.

No dependencies. Just:  python3 chat.py
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

def claude(text):
    """A streamed line from the assistant in a chat session."""
    sys.stdout.write(f"  {PURPLE}claude{RESET} {DIM}│{RESET} ")
    sys.stdout.flush()
    type_out(text, color=WHITE, cps=(0.006, 0.016))
    nap(0.15)

def you(text):
    """The user's reply in a chat session."""
    sys.stdout.write(f"  {GREEN}you{RESET}    {DIM}│{RESET} ")
    sys.stdout.flush()
    nap(random.uniform(0.4, 0.8))
    type_out(text, color=CYAN, cps=(0.01, 0.024))
    nap(0.15)

def plan_card(title, status, goal, members, parallel=None):
    """On-screen plan file: path, Status, Goal, ordered members, optional note."""
    line(f"    {DIM}┌─{RESET} {PURPLE}{title}{RESET}")
    line(f"    {DIM}│{RESET}  {GREY}Status{RESET}  {status}")
    line(f"    {DIM}│{RESET}  {GREY}Goal{RESET}    {DIM}{goal}{RESET}")
    line(f"    {DIM}│{RESET}  {GREY}Members{RESET}")
    for mid, desc, tail in members:
        tail_s = f"  {DIM}{tail}{RESET}" if tail else ""
        line(f"    {DIM}│{RESET}    {CYAN}- #{mid}{RESET} {GREY}— {desc}{RESET}{tail_s}")
    if parallel:
        line(f"    {DIM}│{RESET}  {GREY}Order{RESET}   {DIM}{parallel}{RESET}")
    line(f"    {DIM}└─{RESET}")

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}talk a plan into shape{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — chat plan sharpens an existing DRAFT{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.5)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no tasks moved, no network — just the flow, played back.{RESET}")
    print()
    nap(0.9)

def act1():
    act("ACT 1  ·  size up a partial draft",
        "plan 9 exists — Goal thin, members unordered, one stray, one missing.")

    beat("`chat plan` authors an existing plan file. First, open plan 9 and see "
         "what the draft is actually saying.")
    prompt_and_type("./sprint.sh chat plan 9")
    print()
    note("reading docs/plans/9-passwordless-login.md  ·  Status: DRAFT")
    print()
    plan_card(
        "docs/plans/9-passwordless-login.md",
        f"{ORANGE}DRAFT{RESET}",
        "ship passwordless login somehow",
        [
            ("212", "login endpoint", ""),
            ("299", "redesign landing page", f"{RED}stray?{RESET}"),
            ("210", "magic-link email", ""),
            ("214", "e2e test", ""),
            ("211", "one-time token store", ""),
        ],
    )
    print()
    claude("Partial draft. Goal is vague — \"somehow\" isn't shippable. Members "
           "are unordered: endpoint sits above the email and token work it needs. "
           "#299 redesign landing page doesn't belong. And nothing rate-limits "
           "magic-link requests — that piece is missing.")
    nap(0.5)

def act2():
    act("ACT 2  ·  sharpen the Goal",
        "turn a wish into something a sprint can finish.")

    claude("What does \"passwordless login\" mean when it's done — for a real user?")
    you("user enters email, gets a one-time magic link, clicks it, lands "
        "signed in. no password field at all.")
    claude("Clear. Goal becomes: a user signs in with email + magic link only — "
           "no password — and abuse is rate-limited.")
    print()
    nap(0.3)
    ok(f"Goal rewritten in the plan file. {GREY}Task bodies untouched.{RESET}")
    nap(0.5)

def act3():
    act("ACT 3  ·  reorder members, drop the stray, fill the gap",
        "prerequisites first; only work that belongs; one missing piece added.")

    claude("Order for real work: email (#210) and token store (#211) can land "
           "independently. Login endpoint (#212) after both. Rate-limit magic "
           "links is missing — that's #213. E2E (#214) last. Drop #299 — landing "
           "page isn't this plan.")
    you("yes — 210 ∥ 211, then 212, then 213, then 214. drop 299.")
    claude("Writing the ordered member list and a one-line parallelism note. "
           "Only the plan file changes.")
    print()
    spinner("chat plan: rewriting members + order", ticks=10, done="plan file updated")
    print()
    plan_card(
        "docs/plans/9-passwordless-login.md  ·  after authoring",
        f"{ORANGE}DRAFT{RESET}",
        "email + magic link only; no password; abuse rate-limited",
        [
            ("210", "magic-link email", ""),
            ("211", "one-time token store", ""),
            ("212", "login endpoint", "after 210 + 211"),
            ("213", "rate-limit magic links", "added"),
            ("214", "e2e test", "last"),
        ],
        parallel="210 ∥ 211 independent; 212 after both; 213 next; 214 last",
    )
    print()
    held(f"#299 redesign landing page  {DIM}— dropped from the plan (stays in backlog){RESET}")
    ok(f"#213 rate-limit magic links  {DIM}— added; Plan reverse-index refreshed after session{RESET}")
    nap(0.4)
    beat("Parallelism is written down so start won't serialize work that could "
         "run side by side — and so 212 never starts before its prereqs.")
    nap(0.5)

def act4():
    act("ACT 4  ·  DRAFT → READY",
        "confirm, flip status, stop — think and start stay optional next steps.")

    claude("Goal sharp, members ordered, stray gone, missing piece in. Mark plan "
           "9 READY?")
    you("yes — ready.")
    print()
    spinner("chat plan: Status DRAFT → READY", ticks=8, done="READY")
    print()
    plan_card(
        "docs/plans/9-passwordless-login.md",
        f"{GREEN}READY{RESET}",
        "email + magic link only; no password; abuse rate-limited",
        [
            ("210", "magic-link email", ""),
            ("211", "one-time token store", ""),
            ("212", "login endpoint", "after 210 + 211"),
            ("213", "rate-limit magic links", ""),
            ("214", "e2e test", "last"),
        ],
        parallel="210 ∥ 211 independent; 212 after both; 213 next; 214 last",
    )
    print()
    ok(f"{BOLD}Plan 9 READY.{RESET}  Only durable write: the plan file.")
    print()
    nextstep("./sprint.sh plan think 9   → optional critique before commit")
    nextstep("./sprint.sh plan start 9   → gate members into next/")
    nap(0.4)
    beat("This demo stops here. think and start are the next real commands — "
         "you run them when you mean to commit the sprint, not during authoring.")
    nap(0.5)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — a partial draft became a READY plan.{RESET}")
    print()
    line(f"  {DIM}what you just watched:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}chat plan authors plans{RESET}  "
         f"{GREY}plan id, not a task id — Goal, members, Status{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}order is the work{RESET}       "
         f"{GREY}prereqs first; drop strays; fill gaps{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}one durable write{RESET}       "
         f"{GREY}the plan file only — task bodies stay put{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}READY is a decision{RESET}     "
         f"{GREY}confirm flips DRAFT → READY; think/start next{RESET}")
    print()
    line(f"  {DIM}neighbors:{RESET} "
         f"{CYAN}learn gate{RESET} {DIM}(single-task sharpen) ·{RESET} "
         f"{CYAN}learn feature-plan{RESET} {DIM}(create then start){RESET}")
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
