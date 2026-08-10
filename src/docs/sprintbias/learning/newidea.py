#!/usr/bin/env python3
"""
SprintBias — capture a half-formed idea and walk it through eight phases.

A pretend, cinematic run: a fuzzy "what if" lands as a named scaffold in one
line, then bare `newidea` walks the same spark through eight phases — Spark →
Problem → Landscape → Brainstorm → Bet → Stress Test → Scope → Handoff — and
writes the idea file at the end. Pure theater: it touches nothing in your
project — no files written, no tasks moved, no network.

No dependencies. Just:  python3 newidea.py
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

def spinner(label, ticks=8, done="done"):
    frames = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    if FAST:
        line(f"  {GREY}{label}… {GREEN}{done}{RESET}")
        return
    for i in range(ticks):
        sys.stdout.write(f"\r  {PURPLE}{frames[i % len(frames)]}{RESET} {GREY}{label}…{RESET}")
        sys.stdout.flush()
        time.sleep(0.09)
    sys.stdout.write(f"\r  {GREEN}✓{RESET} {GREY}{label} — {GREEN}{done}{RESET}        \n")
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
def moved(a, b): line(f"    {GREY}{a}{RESET} {DIM}→{RESET} {BLUE}{b}{RESET}")
def note(text):  line(f"  {YELLOW}› {text}{RESET}")
def nextstep(t): line(f"  {DIM}next:{RESET} {CYAN}{t}{RESET}")

def claude(text):
    """A streamed line from the assistant in a chat session."""
    sys.stdout.write(f"  {PURPLE}claude{RESET} {DIM}│{RESET} ")
    sys.stdout.flush()
    type_out(text, color=WHITE, cps=(0.006, 0.016))
    nap(0.2)

def you(text):
    """The user's reply in a chat session."""
    sys.stdout.write(f"  {GREEN}you{RESET}    {DIM}│{RESET} ")
    sys.stdout.flush()
    nap(random.uniform(0.5, 1.0))
    type_out(text, color=CYAN, cps=(0.01, 0.028))
    nap(0.2)

def card(path, path_color, rows):
    """Render a small file preview: a header path and dim key/value rows."""
    line(f"    {DIM}┌─{RESET} {path_color}{path}{RESET}")
    for k, v in rows:
        line(f"    {DIM}│{RESET}  {GREY}{k}{RESET} {DIM}{v}{RESET}")
    line(f"    {DIM}└─{RESET}")

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}a spark becomes a bet{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — a half-formed idea walks eight phases into a file{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.6)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no tasks moved, no network — just the flow, played back.{RESET}")
    print()
    nap(1.0)

def act1():
    act("ACT 1  ·  name it fast",
        "you already know the title — stamp the scaffold and move on.")

    beat("A fuzzy thought just landed: what if failed webhooks auto-retried with "
         "backoff? Don't lose it — name it in one line.")
    prompt_and_type('./sprint.sh newidea "Webhook auto-retry"')
    ok(f"Created idea: {BLUE}docs/ideas/webhook-auto-retry.md{RESET}")
    nextstep("Work through the eight phases — diverge first, converge second.")
    nap(0.4)
    beat("That's the fast path: a titled file with empty phases. Useful when you "
         "want the slot now and the thinking later. The deeper path is bare "
         "`newidea` — a guided walk that fills every phase before it writes.")
    nap(0.7)

def act2():
    act("ACT 2  ·  bare newidea — eight phases",
        "no title yet. talk the spark open, then close it into a bet and a handoff.")

    beat("Same spark, live this time. Bare `newidea` opens a session: diverge "
         "first (Spark → Problem → Landscape → Brainstorm), then converge "
         "(Bet → Stress Test → Scope → Handoff).")
    prompt_and_type("./sprint.sh newidea")
    note("Starting idea refinement session…")
    print()

    # Phase 1–2: show a few real exchanges
    line(f"  {DIM}{GREY}Phase 1 · The Spark{RESET}", delay=0.1)
    claude("What's the idea? What triggered it — a frustration, a hunch, "
           "something you saw?")
    you("failed webhooks just die. what if they auto-retried with backoff?")
    nap(0.25)

    line(f"  {DIM}{GREY}Phase 2 · The Problem{RESET}", delay=0.1)
    claude("That's a solution shape. Who hits this — and what does a silent "
           "drop cost them today?")
    you("ops oncalls. a missed billing webhook means a customer is paid and "
        "we never provision. hours of chase.")
    nap(0.25)

    # Spinner through the middle phases
    spinner("Phase 3 · Landscape", ticks=6, done="existing queues, manual re-fire, vendors")
    spinner("Phase 4 · Brainstorm", ticks=6, done="3 approaches on the table")
    nap(0.2)

    line(f"  {DIM}{GREY}Phase 5 · The Bet{RESET}", delay=0.1)
    claude("Pick a direction as a bet: we believe [approach] will [solve] for "
           "[people] because [insight].")
    you("we believe exponential backoff with a dead-letter after 5 tries will "
        "stop silent drops for ops, because most failures are transient.")
    nap(0.25)

    spinner("Phase 6 · Stress Test", ticks=5, done="poison payloads named")
    spinner("Phase 7 · Scope", ticks=5, done="v1 = one endpoint, 5 retries")
    spinner("Phase 8 · Handoff", ticks=6, done="features listed against the bet")
    nap(0.4)

    beat("Eight phases done. The session asks for a name, writes the file, and "
         "flags which graduation gates are met.")
    spinner("writing idea file", ticks=8, done="docs/ideas/webhook-auto-retry.md")
    print()
    ok(f"Created idea: {BLUE}docs/ideas/webhook-auto-retry.md{RESET}")
    nextstep("Work through the eight phases — diverge first, converge second.")
    nap(0.3)
    card("docs/ideas/webhook-auto-retry.md", PURPLE, [
        ("Spark   ", "failed webhooks die silently — auto-retry with backoff?"),
        ("Problem ", "ops oncalls chase missed billing provision for hours"),
        ("Bet     ", "exp. backoff + dead-letter after 5 → stop silent drops"),
        ("Scope   ", "v1: one endpoint, 5 retries, dead-letter queue"),
        ("Handoff ", "retry worker · dead-letter UI · metrics on drop rate"),
    ])
    nap(0.5)
    beat("A named scaffold is a sticky note. Bare `newidea` is the thinking that "
         "makes the note worth building from — problem, bet, small scope, features "
         "that serve the bet.")
    nap(0.7)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — a spark became a bet you can hand off.{RESET}")
    print()
    line(f"  {DIM}the through-line:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}name it when you know{RESET}   "
         f"{GREY}newidea \"Title\" stamps the scaffold now{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}talk it when you don't{RESET}  "
         f"{GREY}bare newidea walks eight phases, then writes{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}diverge, then converge{RESET}  "
         f"{GREY}open up before you bet, cut, and hand off{RESET}")
    print()
    line(f"  {DIM}what you just watched:{RESET} "
         f"{CYAN}newidea \"…\"  ·  newidea (8 phases) → docs/ideas/…{RESET}")
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
