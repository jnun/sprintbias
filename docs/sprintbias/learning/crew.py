#!/usr/bin/env python3
"""
SprintBias — a crew of named sessions, one lead keeping everyone rowing.

A pretend, cinematic run: you add a lead and two members, start the lead on a
plan, and watch it route tasks by role. Each member claims its task by moving it
into doing/, the lead catches two members heading for the same file, and the
board shows who holds what. Pure theater: it touches nothing in your project —
no files written, no sessions started, no network.

No dependencies. Just:  python3 crew.py
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


# ── crew-specific atoms: who is talking ─────────────────────────────────────
MEMBERS = {"orcha": ORANGE, "devops": BLUE, "dill": PURPLE}

def says(name, text):
    """One crew member speaking in its own terminal."""
    line(f"  {MEMBERS[name]}{BOLD}{name:>6}{RESET} {DIM}│{RESET} {WHITE}{text}{RESET}", delay=0.25)

def msg(frm, to, text):
    """A message between sessions: the nudge, never the record."""
    line(f"  {MEMBERS[frm]}{frm}{RESET} {DIM}→{RESET} {MEMBERS[to]}{to}{RESET}  "
         f"{GREY}\u201c{text}\u201d{RESET}", delay=0.3)

def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}a crew, one lead, no collisions{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — three named sessions work one plan together{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.6)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no sessions started, no network — just the flow, played back.{RESET}")
    print()
    nap(1.0)

def act1():
    act("ACT 1  ·  write the crew down once",
        "one file per member: its role and what it may touch.")
    beat("Every morning you used to retype who each session was. Write it down once.")
    prompt_and_type('./sprint.sh crew add orcha "Keeps everyone rowing: holds the plan" --lead')
    ok("Added crew member: docs/crew/orcha.md")
    prompt_and_type('./sprint.sh crew add devops "Builds locally, owns migrations"')
    ok("Added crew member: docs/crew/devops.md")
    prompt_and_type('./sprint.sh crew add dill "Finds and fixes bugs"')
    ok("Added crew member: docs/crew/dill.md")
    beat("May touch is the important line: one owner for each kind of work.")

def act2():
    act("ACT 2  ·  the lead takes the plan",
        "orcha reads plan 5 and routes each task to the member whose role fits.")
    prompt_and_type("./sprint.sh crew orcha plan:5")
    spinner("starting session 'orcha' with the lead rules", done="ready")
    says("orcha", "Plan 5: duplicate rows on CSV import. Three tasks.")
    says("orcha", "Approach: fix the importer, then the count that reads it.")
    note("#41 importer flags duplicates     Crew: dill")
    note("#42 unique index on asset tag     Crew: devops")
    note("#43 dashboard count reads clean   Crew: dill")
    ok("plan 5 → ## Crew board written")
    msg("orcha", "dill", "#41 is yours, then #43")
    msg("orcha", "devops", "#42 is yours — migration")
    beat("Messages nudge. The board and the Crew fields are the record.")

def act3():
    act("ACT 3  ·  members claim by moving the file",
        "each in its own terminal; the move into doing/ is the claim.")
    prompt_and_type("./sprint.sh crew dill 41")
    says("dill", "Claiming #41.")
    moved("next/41", "doing/41  Crew: dill")
    prompt_and_type("./sprint.sh crew devops 42")
    says("devops", "Claiming #42.")
    moved("next/42", "doing/42  Crew: devops")
    print()
    says("devops", "The index needs a model change in importer.py.")
    held("orcha: dill is in importer.py for #41 — two writers, one file")
    msg("orcha", "devops", "write the migration only; dill adds the model line in #41")
    says("devops", "Understood. Migration only.")
    beat("The lead thinks across members. A collision caught here never becomes a merge fight.")

def act4():
    act("ACT 4  ·  the board at a glance",
        "anyone can ask who holds what; no AI needed.")
    prompt_and_type("./sprint.sh crew")
    line(f"  {BOLD}orcha{RESET} (lead) — Keeps everyone rowing: holds the plan")
    line(f"    {GREY}holds nothing{RESET}")
    line(f"  {BOLD}devops{RESET} — Builds locally, owns migrations")
    line(f"    {GREY}doing/  42  Unique index on asset tag{RESET}")
    line(f"  {BOLD}dill{RESET} — Finds and fixes bugs")
    line(f"    {GREY}doing/  41  Importer flags duplicates{RESET}")
    line(f"    {GREY}next/  43  Dashboard count reads clean{RESET}")
    print()
    says("dill", "#41 done, Completed filled in.")
    moved("doing/41", "review/41")
    msg("dill", "orcha", "#41 in review; starting #43")
    nextstep("you review, commit, and ship — the crew never commits")

def outro():
    print()
    rule("═")
    print()
    line(f"  {DIM}the through-line:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}files are the shared state{RESET}  "
         f"{GREY}the Crew field and doing/ say who holds what{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}one owner per kind of work{RESET}  "
         f"{GREY}May touch keeps sessions out of each other's files{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}the lead rows the boat{RESET}      "
         f"{GREY}holds the plan, routes, catches collisions, writes no code{RESET}")
    print()
    line(f"  {DIM}read more:{RESET} {CYAN}docs/sprintbias/guides/crew.md{RESET}")
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
