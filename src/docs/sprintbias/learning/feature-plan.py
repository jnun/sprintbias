#!/usr/bin/env python3
"""
SprintBias — a feature fans out to tasks, then plan think before plan start.

A pretend, cinematic run: a feature-shaped wish is captured as a task, chat
splits it into concrete children, `newplan` scaffolds a relational plan index,
`chat plan` authors it (plan id, not a task id), a short plan-think pass
catches the things that would bite later — an empty skeleton member, a missing
dependency, two tasks quietly overlapping — and only after those are fixed does
`plan start` commit the sprint. The lesson: don't start on skeletons. Pure
theater: it touches nothing in your project — no files written, no tasks moved,
no network.

No dependencies. Just:  python3 feature-plan.py
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
def held(text):  line(f"  {ORANGE}⏸{RESET} {text}")
def moved(a, b): line(f"    {GREY}{a}{RESET} {DIM}→{RESET} {BLUE}{b}{RESET}")
def note(text):  line(f"  {YELLOW}› {text}{RESET}")
def nextstep(t): line(f"  {DIM}next:{RESET} {CYAN}{t}{RESET}")
def flag(text):  line(f"  {ORANGE}⚑{RESET} {text}")

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

# ── file/plan cards, so you SEE text change ───────────────────────────────────
def card(path, path_color, rows):
    """Render a small file preview: a header path and dim key/value rows."""
    line(f"    {DIM}┌─{RESET} {path_color}{path}{RESET}")
    for k, v in rows:
        line(f"    {DIM}│{RESET}  {GREY}{k}{RESET} {DIM}{v}{RESET}")
    line(f"    {DIM}└─{RESET}")

def plan_card(title, members):
    """A plan is a relational index of members, each with a readiness mark."""
    line(f"    {DIM}┌─{RESET} {PURPLE}{title}{RESET}")
    for mark_color, mark, mid, desc, tail in members:
        tail = f"  {DIM}{tail}{RESET}" if tail else ""
        line(f"    {DIM}│{RESET}  {mark_color}{mark}{RESET} {CYAN}{mid}{RESET} "
             f"{GREY}{desc}{RESET}{tail}")
    line(f"    {DIM}└─{RESET}")

def fix(before, after):
    """Show a task/plan line actually change: red out, green in."""
    line(f"    {RED}- {before}{RESET}")
    nap(0.25)
    line(f"    {GREEN}+ {after}{RESET}")
    nap(0.35)

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}a feature becomes a plan{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — a feature fans out to tasks, gets critiqued, then starts{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.6)
    # Same trust promise as S0/S1/S2 — the sandbox is the first thing you feel.
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no tasks moved, no network — just the flow, played back.{RESET}")
    print()
    nap(1.0)

def act1():
    act("ACT 1  ·  a feature is too big to be a task",
        "\"dark mode\" isn't one thing you can run. break it into tasks that are.")

    beat("You want dark mode. That's a feature — a shape of work, not a task a "
         "single run can finish. Capture the wish, then fan it into concrete pieces.")
    prompt_and_type('./sprint.sh newtask "ship dark mode"')
    ok(f"Created task: {BLUE}docs/tasks/backlog/50-ship-dark-mode.md{RESET}")
    nextstep("it's too big — chat will break it into finishable work")
    nap(0.4)

    beat("Talk the wish open. Chat sizes it up: one job, or several hiding inside?")
    prompt_and_type("./sprint.sh chat 50")
    print()
    claude("\"Ship dark mode\" is three real jobs hiding in a wish. I'll split "
           "it into tasks that each have a clear finish line.")
    you("yes — tokens, the toggle, and remember the choice across reloads.")
    claude("Creating three child tasks with real IDs, then retiring the parent "
           "so nothing points at a hollow wish.")
    nap(0.3)
    spinner("chat: splitting into concrete tasks", ticks=12, done="3 tasks in backlog/")
    line(f"    {GREY}docs/tasks/backlog/{RESET}")
    moved("50-ship-dark-mode.md", f"{DIM}(retired — folded into children){RESET}")
    moved(" ", f"{BLUE}51-define-theme-color-tokens.md{RESET}")
    moved(" ", f"{BLUE}52-add-dark-mode-toggle-in-settings.md{RESET}")
    moved(" ", f"{BLUE}53-persist-theme-choice.md{RESET}")
    nap(0.4)
    beat("Three tasks in backlog/, each finishable on its own. But loose in a "
         "folder they're just a pile — nothing says they're one effort, or which "
         "order they go in.")
    nap(0.7)

def act2():
    act("ACT 2  ·  group them into a plan",
        "scaffold with newplan, then author with chat plan — a relational index, not a folder.")

    beat("Bind the three into a named plan. newplan scaffolds the file — it does "
         "not move any task files; it only records the member IDs.")
    prompt_and_type("./sprint.sh newplan dark-mode 51 52 53")
    ok(f"Created plan: {PURPLE}docs/plans/7-dark-mode.md{RESET}  {GREY}(scaffold){RESET}")
    nextstep("./sprint.sh chat plan 7   → author goal + members into the plan file")
    nap(0.4)

    beat("Now author it. chat plan takes a *plan* id — never a task id — and "
         "writes only the plan file: Goal, ordered members, Status.")
    prompt_and_type("./sprint.sh chat plan 7")
    print()
    claude("Three members already listed. Goal: ship a working dark theme. "
           "I'll record the order and mark the plan READY when you confirm.")
    you("tokens first, then the toggle, then persist. yes — ready.")
    claude("Goal and members written. Plan 7 is READY to think, then start.")
    nap(0.3)
    spinner("chat plan: authoring plan 7", ticks=10, done="DRAFT → READY")
    nap(0.3)
    plan_card("docs/plans/7-dark-mode.md  ·  Goal: ship a working dark theme", [
        (GREEN,  "●", "51", "define theme color tokens", "READY"),
        (GREEN,  "●", "52", "add dark-mode toggle in settings", "READY"),
        (ORANGE, "○", "53", "persist theme choice", "skeleton"),
    ])
    nap(0.4)
    beat("The plan is the index: goal at the top, members below. Notice it already "
         "shows what a folder never could — 53 is a hollow skeleton, and nothing "
         "records that 52 needs 51 first.")
    nap(0.7)

def act3():
    act("ACT 3  ·  plan think — critique before you commit",
        "a dual-persona pass reads the plan cold and finds what would bite in the sprint.")

    beat("Before starting, think the plan. This is the beat real life skips — and "
         "the one that keeps you from starting on skeletons.")
    prompt_and_type("./sprint.sh plan think 7")
    print()
    spinner("plan think: architect × experience, reading all 3 members", ticks=16,
            done="3 issues found")
    print()

    # Issue 1 — an empty skeleton member. Shown filled.
    flag(f"{WHITE}53 is a skeleton{RESET} {GREY}— title only, no Problem, no Success. "
         f"A run couldn't finish it.{RESET}")
    claude("Filling 53 so it's workable, not a placeholder:")
    fix("53 persist theme choice   (Problem: —   Success: —)",
        "53 persist theme choice across sessions")
    card("docs/tasks/backlog/53-persist-theme-choice.md", GREEN, [
        ("Problem ", "a user picks dark, reloads, and the app is light again"),
        ("Success ", "☐ choose dark → reload → still dark, no flash of light"),
    ])
    nap(0.5)

    # Issue 2 — a missing dependency. Shown added.
    flag(f"{WHITE}52 can't run before 51{RESET} {GREY}— the toggle flips tokens that "
         f"51 defines, but its Depends on says none.{RESET}")
    claude("Recording the real edge so the gate orders them:")
    fix("52  Depends on: none", "52  Depends on: 51")
    nap(0.5)

    # Issue 3 — a ship-path / overlap risk. Shown resolved.
    flag(f"{WHITE}52 and 53 overlap{RESET} {GREY}— both claim to \"save the "
         f"preference.\" Two tasks writing the same thing collide.{RESET}")
    claude("Drawing the boundary so work doesn't double up:")
    fix("52 …also saves the choice   ·   53 …also saves the choice",
        "52 flips the theme in-session   ·   53 owns persistence")
    nap(0.5)

    print()
    plan_card("docs/plans/7-dark-mode.md  ·  after think", [
        (GREEN, "●", "51", "define theme color tokens", "READY"),
        (GREEN, "●", "52", "add dark-mode toggle (Depends on: 51)", "READY"),
        (GREEN, "●", "53", "persist theme choice across sessions", "READY"),
    ])
    beat("Same three tasks — but now 53 is real, the 51→52 edge is written down, "
         "and the overlap is gone. Nothing was committed yet; we fixed the plan "
         "while it was still cheap to fix.")
    nap(0.7)

def act4():
    act("ACT 4  ·  plan start — now it's honest",
        "commit the members to next/. start means start, because the plan holds up.")

    beat("Only now — skeleton filled, deps written, overlap resolved — does "
         "starting mean anything. Commit the plan to the sprint.")
    prompt_and_type("./sprint.sh plan start 7")
    spinner("gate: judging all 3 members on the way in", done="3 READY")
    moved("backlog/51", "next/51   · READY ✓")
    moved("backlog/52", "next/52   · READY ✓  (after 51)")
    moved("backlog/53", "next/53   · READY ✓")
    ok(f"Plan 7 started — 3 members in the sprint. {GREY}next/ IS the sprint.{RESET}")
    nextstep("./sprint.sh work   → drains READY tasks, respecting 51 → 52")
    nap(0.5)
    beat("Imagine running this before think: 53 stalls a run on a blank task, and "
         "52 might start before 51 exists. The critique paid for itself the moment "
         "start became honest.")
    nap(0.7)

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — a feature became a plan you can trust.{RESET}")
    print()
    line(f"  {DIM}the through-line:{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}a feature fans out{RESET}     "
         f"{GREY}too big for one run → concrete, finishable tasks{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}a plan is an index{RESET}     "
         f"{GREY}which tasks, how they relate — not a folder dump{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}think before start{RESET}     "
         f"{GREY}critique finds skeletons, missing deps, overlap — cheap to fix now{RESET}")
    line(f"    {PURPLE}•{RESET} {WHITE}start means start{RESET}      "
         f"{GREY}commit only a plan that holds up{RESET}")
    print()
    line(f"  {DIM}the spine you just watched:{RESET} "
         f"{CYAN}newtask → chat → newplan → chat plan → plan think → plan start → work{RESET}")
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
