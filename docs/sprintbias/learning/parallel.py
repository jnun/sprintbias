#!/usr/bin/env python3
"""
SprintBias — independence is what makes parallel work safe.

A pretend, cinematic run: two ready tasks that share no files advance on their
own tracks at the same time, then converge in review/. Then a third task that
WOULD edit the same file waits its turn instead — because the safety was never a
magic scheduler, it's disjoint edit surfaces. Pure theater: it touches nothing
in your project — no files written, no tasks moved, no network.

No dependencies. Just:  python3 parallel.py
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
def held(text):  line(f"  {ORANGE}⏸{RESET} {text}")
def moved(a, b): line(f"    {GREY}{a}{RESET} {DIM}→{RESET} {BLUE}{b}{RESET}")
def note(text):  line(f"  {YELLOW}› {text}{RESET}")
def nextstep(t): line(f"  {DIM}next:{RESET} {CYAN}{t}{RESET}")

# ── two-track visual (S5-specific: concurrency you can see) ────────────────────
# Two tasks run at once. Each track carries a letter + its own color so the
# interleaving reads as "both advancing," never one long serial list. Honest by
# construction: a track only ever names its OWN file — the surfaces never touch.
TRACKS = {
    "A": {"tag": BLUE,   "id": "71", "title": "rate-limit the login API",
          "file": "src/api/limits.py"},
    "B": {"tag": PURPLE, "id": "72", "title": "fix the footer copyright year",
          "file": "web/footer.html"},
}

def track(letter, text):
    """One step on a labeled track, colored to its lane."""
    t = TRACKS[letter]
    sys.stdout.write(f"  {t['tag']}{letter}{RESET} {DIM}┆{RESET} ")
    line(text)
    nap(random.uniform(0.12, 0.28))

def edit(letter, detail):
    t = TRACKS[letter]
    track(letter, f"{GREEN}+ {t['file']:<20}{RESET}{GREY}{detail}{RESET}")

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}two tracks, no collisions{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — two independent tasks run at once, then converge{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.6)
    # Same trust promise as S0 — the sandbox is the first thing you feel.
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no tasks moved, no network — just the flow, played back.{RESET}")
    print()
    nap(1.0)

def act1():
    act("ACT 1  ·  two ready tasks, zero shared files",
        "before running anything, look at what each task will touch.")

    beat("Two tasks sit READY in next/. One rewires the login API; the other "
         "edits a web page. Different files, different corners of the app.")
    prompt_and_type("./sprint.sh work --fast")
    note("2 tasks READY in next/ — their edit surfaces don't overlap")
    print()
    line(f"    {BLUE}A{RESET} {DIM}┆{RESET} {GREY}next/71{RESET}  "
         f"{WHITE}rate-limit the login API{RESET}   {DIM}→{RESET} {CYAN}src/api/limits.py{RESET}")
    line(f"    {PURPLE}B{RESET} {DIM}┆{RESET} {GREY}next/72{RESET}  "
         f"{WHITE}fix the footer copyright year{RESET}   {DIM}→{RESET} {CYAN}web/footer.html{RESET}")
    print()
    nap(0.5)
    beat("No file is on both lists. That is the whole safety story — two runs "
         "editing separate files can't overwrite each other. So they go at once.")
    nap(0.7)

def act2():
    act("ACT 2  ·  both tracks advance together",
        "each task works in its own fresh context — output interleaves as they go.")

    beat("`--fast` runs independent tasks concurrently, each in its own fresh "
         "AI context. Watch A and B trade turns — that's two runs, not one.")
    print()
    track("A", f"{GREY}next/71{RESET} {DIM}→{RESET} {BLUE}doing/71{RESET}")
    track("B", f"{GREY}next/72{RESET} {DIM}→{RESET} {BLUE}doing/72{RESET}")
    edit("A", "add 429 + Retry-After after the 6th try")
    edit("B", "render the year dynamically — no more 2019")
    track("A", f"{GREY}next/71{RESET} {DIM}·{RESET} {GREY}tests green{RESET}")
    edit("B", "drop the hard-coded date constant")
    track("B", f"{GREY}next/72{RESET} {DIM}·{RESET} {GREY}page renders{RESET}")
    print()
    nap(0.4)
    track("A", f"{BLUE}doing/71{RESET} {DIM}→{RESET} {GREEN}review/71{RESET}   {GREEN}✓{RESET}")
    track("B", f"{BLUE}doing/72{RESET} {DIM}→{RESET} {GREEN}review/72{RESET}   {GREEN}✓{RESET}")
    print()
    ok(f"{BOLD}2 tasks worked in parallel.{RESET}  Both land in review/ — review each diff.")
    nap(0.5)
    beat("They never coordinated. They didn't need to — nothing they touched "
         "was shared. Independence is what let them overlap safely.")
    nap(0.7)

def act3():
    act("ACT 3  ·  the honest catch — shared files wait",
        "parallel isn't a scheduler untangling conflicts. it just skips the tangle.")

    beat("Now a third task, 73, also edits src/api/limits.py — the same file as "
         "A. Run them together and they'd fight over the same lines.")
    prompt_and_type("./sprint.sh work --fast")
    note("task 73 shares a file with 71 — marked 'Depends on: 71'")
    print()
    line(f"    {BLUE}A{RESET} {DIM}┆{RESET} {GREY}71{RESET}  {WHITE}rate-limit the login API{RESET}   "
         f"{DIM}→{RESET} {CYAN}src/api/limits.py{RESET}")
    line(f"    {ORANGE}C{RESET} {DIM}┆{RESET} {GREY}73{RESET}  {WHITE}log blocked login attempts{RESET}   "
         f"{DIM}→{RESET} {CYAN}src/api/limits.py{RESET}  {ORANGE}← same file{RESET}")
    print()
    held(f"{BOLD}73 waits{RESET} — held until 71 lands (review/ with a proof line), then it runs.")
    moved("next/73", "held · after 71")
    ok(f"71 finishes, {BOLD}then{RESET} 73 starts on the settled file. In order, on purpose.")
    nap(0.5)
    beat("That's the honest model: SprintBias overlaps work that's independent and "
         "sequences work that isn't. No magic engine merges conflicting edits — "
         "you keep surfaces disjoint, and concurrency stays safe.")
    nap(0.7)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — two tracks, no collisions.{RESET}")
    print()
    line(f"  {DIM}the through-line:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}independence is the safety{RESET}  "
         f"{GREY}disjoint files can't overwrite each other{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}parallel is not magic{RESET}       "
         f"{GREY}it overlaps independent work, it can't untangle shared edits{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}shared files sequence{RESET}       "
         f"{GREY}'Depends on' holds a task until the file it shares is settled{RESET}")
    print()
    line(f"  {DIM}what you just watched:{RESET} "
         f"{CYAN}work --fast → two tracks converge; a shared file waits its turn{RESET}")
    print()
    line(f"  {DIM}see the whole spine:{RESET} {CYAN}./sprint.sh learn session{RESET}")
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
