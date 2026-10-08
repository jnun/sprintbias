#!/usr/bin/env python3
"""
SprintBias — two agents fix an API and an iOS app at once, sharing one contract.

A pretend, cinematic run: iOS users get logged out when a token refresh races a
request. A crew of three (a lead, `api`, `ios`) splits the fix across two
codebases. Each agent claims its task by moving it into doing/, announces the
files it is touching, messages the others, and checks theirs. When both reach
for the shared contract file, the lower task id owns it and the other builds
around it. Then the same work headless: `work 88` and `work 89` side by side.
Pure theater: it touches nothing in your project — no files written, no
sessions started, no network.

No dependencies. Just:  python3 teamwork.py
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

def prompt_and_type(cmd, where=""):
    """Render a shell prompt, pause like a thinking human, then type the cmd.
    `where` labels which terminal tab the command runs in."""
    tab = f"{DIM}[{where}]{RESET} " if where else ""
    sys.stdout.write(f"{tab}{GREEN}➜{RESET}  {CYAN}~/my-app{RESET} {DIM}${RESET} ")
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
def out(text):   line(f"  {GREY}{text}{RESET}")

# ── crew atoms: who is talking ────────────────────────────────────────────────
MEMBERS = {"lead": ORANGE, "api": BLUE, "ios": PURPLE}
CONTRACT = "contract/auth-refresh.json"

def says(name, text):
    """One crew member speaking in its own terminal."""
    line(f"  {MEMBERS[name]}{BOLD}{name:>4}{RESET} {DIM}│{RESET} {WHITE}{text}{RESET}", delay=0.25)

def tool(name, text):
    """A crew member using one of its tools (shown as the AI CLI shows it)."""
    line(f"  {MEMBERS[name]}{name:>4}{RESET} {DIM}│ ⏺ {text}{RESET}", delay=0.2)

def msg(frm, to, text):
    """A message between sessions: the nudge, never the record."""
    line(f"  {MEMBERS[frm]}{frm}{RESET} {DIM}→{RESET} {MEMBERS[to]}{to}{RESET}  "
         f"{GREY}“{text}”{RESET}", delay=0.3)

# ── the show ──────────────────────────────────────────────────────────────────
def banner():
    print()
    line(f"   {BOLD}{WHITE}Sprint{BLUE}Bias{RESET}   {DIM}two codebases, two agents, one contract{RESET}", delay=0)
    print()
    line(f"   {DIM}a pretend run — an API agent and an iOS agent fix one bug side by side{RESET}")
    if not FAST:
        line(f"   {DIM}(run with --fast to skip the pauses){RESET}")
    print()
    nap(0.6)
    line(f"   {GREEN}▪{RESET} {WHITE}This demo touches nothing in your project.{RESET}")
    line(f"     {DIM}No files written, no sessions started, no network — just the flow, played back.{RESET}")
    print()
    nap(1.0)

def act1():
    act("ACT 1  ·  the crew, one owner per codebase",
        "a lead, plus one member for the API and one for the iOS app.")
    beat("The bug: iOS users get logged out when a token refresh races a request. "
         "The fix spans server/ and ios/.")
    prompt_and_type('./sprint.sh crew add lead "Holds the plan, routes tasks" --lead')
    ok("Added crew member: docs/crew/lead.md")
    prompt_and_type('./sprint.sh crew add api "Owns the API server and the contract"')
    ok("Added crew member: docs/crew/api.md")
    prompt_and_type('./sprint.sh crew add ios "Owns the iOS app"')
    ok("Added crew member: docs/crew/ios.md")
    print()
    beat("Fill in May touch in each file. The shared contract gets exactly one owner.")
    line(f"    {BOLD}lead{RESET}  {GREY}May touch:{RESET} {WHITE}plan files, task routing{RESET}")
    line(f"    {BOLD}api{RESET}   {GREY}May touch:{RESET} {WHITE}server/, {CONTRACT}{RESET}")
    line(f"    {BOLD}ios{RESET}   {GREY}May touch:{RESET} {WHITE}ios/  {DIM}(reads the contract; asks api to change it){RESET}")

def act2():
    act("ACT 2  ·  three tasks, one plan",
        "two run in parallel; the end-to-end test waits for both.")
    prompt_and_type('./sprint.sh newtask "API: refresh keeps the old token valid for a grace window"')
    ok(f"Created task: {BLUE}docs/tasks/backlog/88-api-refresh-keeps-the-old-token-valid.md{RESET}")
    prompt_and_type('./sprint.sh newtask "iOS: retry once after a token refresh"')
    ok(f"Created task: {BLUE}docs/tasks/backlog/89-ios-retry-once-after-a-token-refresh.md{RESET}")
    prompt_and_type('./sprint.sh newtask "End-to-end: a refresh race keeps the user logged in"')
    ok(f"Created task: {BLUE}docs/tasks/backlog/90-end-to-end-a-refresh-race-keeps-the-user.md{RESET}")
    note(f"90  **Depends on**: 88, 89   {GREY}(it tests both halves together){RESET}")
    print()
    prompt_and_type('./sprint.sh newplan "iOS logout race" 88 89 90')
    ok(f"Created plan: {PURPLE}docs/plans/14-ios-logout-race.md{RESET}")
    prompt_and_type("./sprint.sh plan start 14")
    moved("backlog/88", "next/88   · READY ✓")
    moved("backlog/89", "next/89   · READY ✓")
    moved("backlog/90", "next/90   · READY ✓  (after 88, 89)")
    ok(f"Plan 14 started — 3 members in the sprint. {GREY}next/ IS the sprint.{RESET}")
    beat("88 and 89 depend on nothing, so they can run at the same time.")

def act3():
    act("ACT 3  ·  start the sessions",
        "one plain terminal per member. the lead goes first.")
    prompt_and_type("./sprint.sh crew lead plan:14", where="tab 1")
    spinner("starting session 'lead' with the lead rules", done="ready")
    says("lead", "Plan 14: iOS logout race. Approach: the API keeps the old token")
    says("lead", "valid for a grace window; the app retries once. One contract file.")
    note("#88 refresh grace window          Crew: api")
    note("#89 retry once after refresh      Crew: ios")
    note("#90 end-to-end race test          Crew: ios   (after 88, 89)")
    ok("plan 14 → ## Crew board written")
    tool("lead", "ListAgents  → lead, api, ios")
    msg("lead", "api", "#88 is yours. You own the contract.")
    msg("lead", "ios", "#89 is yours, then #90 once 88 and 89 are in review.")
    print()
    prompt_and_type("./sprint.sh crew api 88", where="tab 2")
    spinner("starting session 'api'", done="ready")
    prompt_and_type("./sprint.sh crew ios 89", where="tab 3")
    spinner("starting session 'ios'", done="ready")
    beat("Each session starts under its crew name, so the others can message it by that name.")

def act4():
    act("ACT 4  ·  claim, announce, check",
        "the move into doing/ is the claim. the Touching: line is the announcement.")
    says("api", "Claiming #88.")
    moved("next/88", "doing/88  Crew: api")
    tool("api", f"Edit 88 · ## Grounding  + **Touching:** server/auth/refresh.go, {CONTRACT}")
    says("ios", "Claiming #89.")
    moved("next/89", "doing/89  Crew: ios")
    tool("ios", f"Edit 89 · ## Grounding  + **Touching:** ios/Auth/TokenRefresher.swift, {CONTRACT}")
    print()
    msg("api", "ios", f"On #88. Touching refresh.go and {CONTRACT}.")
    msg("ios", "api", f"On #89. Touching TokenRefresher.swift; I read {CONTRACT}.")
    print()
    beat("Messages nudge. The task files are the record, so anyone can check them.")
    prompt_and_type("grep -H Touching docs/tasks/doing/*.md", where="tab 3")
    out(f"docs/tasks/doing/88-api-refresh-keeps-the-old-token-valid.md:**Touching:** server/auth/refresh.go, {CONTRACT}")
    out(f"docs/tasks/doing/89-ios-retry-once-after-a-token-refresh.md:**Touching:** ios/Auth/TokenRefresher.swift, {CONTRACT}")
    held(f"both list {CONTRACT}")
    says("ios", "Shared file. 88 is the lower id, so api owns the contract.")
    says("ios", "I build around its shape and leave the file to api.")

def act5():
    act("ACT 5  ·  the shared contract, without clobbering",
        "re-read right before each edit; change only your part.")
    tool("api", f"Read {CONTRACT}")
    tool("api", f"Edit {CONTRACT}  + \"grace_seconds\": 30, one 401 body: {{\"error\": \"token_expired\"}}")
    tool("api", "Edit server/auth/refresh.go  old token stays valid for grace_seconds")
    msg("api", "ios", "Contract updated: grace_seconds plus one 401 body. Re-read it.")
    print()
    says("ios", "I wanted a retry_after field there too.")
    tool("ios", f"Read {CONTRACT}  {DIM}(re-read: changed since my last look){RESET}")
    says("ios", "grace_seconds already covers it. I use that instead.")
    msg("ios", "api", "Building on grace_seconds. No contract change from me.")
    tool("ios", "Edit ios/Auth/TokenRefresher.swift  one refresh in flight; others wait")
    tool("ios", "Edit ios/Net/APIClient.swift  on token_expired, refresh, retry once")
    print()
    tool("ios", "Bash git status  → server/auth/refresh.go modified")
    says("ios", "Not my change. That's api's work, so I leave it alone.")
    tool("ios", "Edit 89 · ## Completed  + Overlap: built on #88's grace_seconds; no contract edit")
    beat("Lower id owns shared code. The other agent builds around it and writes down the overlap.")

def act6():
    act("ACT 6  ·  the same work, headless",
        "no crew needed: `work <id>` in two terminals runs the same rules.")
    beat("Rewind: the same two tasks, unattended. Each `work` run gets the same parallel-work rules.")
    prompt_and_type("./sprint.sh work 88", where="left")
    prompt_and_type("./sprint.sh work 89", where="right")
    line(f"  {BLUE}88{RESET} {DIM}┆{RESET} {GREY}next/88{RESET} {DIM}→{RESET} {BLUE}doing/88{RESET}   {GREY}Touching: refresh.go, auth-refresh.json{RESET}")
    line(f"  {PURPLE}89{RESET} {DIM}┆{RESET} {GREY}next/89{RESET} {DIM}→{RESET} {BLUE}doing/89{RESET}   {GREY}Touching: TokenRefresher.swift, auth-refresh.json{RESET}")
    line(f"  {PURPLE}89{RESET} {DIM}┆{RESET} {GREY}reads 88's Touching: — contract is 88's; builds around it{RESET}")
    line(f"  {BLUE}88{RESET} {DIM}┆{RESET} {GREEN}+ server/auth/refresh.go{RESET}  {GREY}grace window{RESET}")
    line(f"  {PURPLE}89{RESET} {DIM}┆{RESET} {GREEN}+ ios/Net/APIClient.swift{RESET}  {GREY}retry once{RESET}")
    print()
    beat("A task in doing/ is claimed. A third run on 88 is refused.")
    prompt_and_type("./sprint.sh work 88", where="third")
    line(f"  {RED}✗{RESET} 88 is in doing/ — it may be mid-work, or left by an interrupted run.")
    out("The file can't say which. If a run has it, leave it be.")

def act7():
    act("ACT 7  ·  who holds what, then the finish",
        "check the board, check the sessions, then you approve.")
    prompt_and_type("./sprint.sh crew", where="tab 4")
    line(f"  {BOLD}api{RESET} — Owns the API server and the contract")
    out("  doing/  88  API: refresh keeps the old token valid for a grace window")
    line(f"  {BOLD}ios{RESET} — Owns the iOS app")
    out("  doing/  89  iOS: retry once after a token refresh")
    out("  next/  90  End-to-end: a refresh race keeps the user logged in")
    line(f"  {BOLD}lead{RESET} (lead) — Holds the plan, routes tasks")
    out("  holds nothing")
    print()
    prompt_and_type("./sprint.sh agents --local", where="tab 4")
    line(f"  {BOLD}{BLUE}my-laptop (this machine){RESET}{DIM}  3 agents{RESET}")
    line(f"  {BOLD}lead{RESET}  {DIM}idle 2m  {RESET} {GREY}Terminal ttys002{RESET}  {CYAN}my-app@main{RESET}  {GREY}up 24m{RESET}")
    line(f"  {BOLD}api {RESET}  {GREEN}busy 4s  {RESET} {GREY}Terminal ttys003{RESET}  {CYAN}my-app@main{RESET}  {GREY}up 22m{RESET}")
    line(f"  {BOLD}ios {RESET}  {GREEN}busy 9s  {RESET} {GREY}Terminal ttys004{RESET}  {CYAN}my-app@main{RESET}  {GREY}up 21m{RESET}")
    line(f"  {BOLD}3 agents running{RESET} · 2 busy, 1 idle")
    print()
    says("api", "#88 done, Completed filled in.")
    moved("doing/88", "review/88")
    says("ios", "#89 done, overlap noted.")
    moved("doing/89", "review/89")
    msg("ios", "lead", "#89 in review. Starting #90.")
    moved("next/90", "doing/90  Crew: ios")
    print()
    nextstep("you read both diffs, commit, and ship — the agents edit files and stop")

def outro():
    print()
    rule("═")
    line(f"{BOLD}{GREEN}  done — two codebases, one contract, no clobbering.{RESET}")
    print()
    line(f"  {DIM}the through-line:{RESET}")
    for head, why in (
        ("doing/ is the claim", "each task there is an agent at work"),
        ("Touching: is the hello", "announce your files; grep the others' first"),
        ("lower id owns shared code", "the other builds around it and notes the overlap"),
        ("leave others' changes alone", "you approve, commit, and ship"),
    ):
        line(f"    {PURPLE}•{RESET} {WHITE}{head:<29}{RESET}{GREY}{why}{RESET}")
    print()
    line(f"  {DIM}read more:{RESET} {CYAN}docs/sprintbias/guides/crew.md{RESET}   "
         f"{DIM}rules:{RESET} {CYAN}./sprint.sh help work{RESET}")
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
        act5()
        act6()
        act7()
        outro()
    except KeyboardInterrupt:
        sys.stdout.write(RESET + "\n" + DIM + "  …demo interrupted.\n" + RESET)
        sys.exit(130)

if __name__ == "__main__":
    main()
