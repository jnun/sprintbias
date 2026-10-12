#!/usr/bin/env bash
# edges.sh — The edge-case scorecard: defects the agents caught before you saw
# the work vs defects you found after. See: ./sprint.sh help status
#
# Invoked as: ./sprint.sh status --edges [plan:N]
#
# Pure shell + python3 stdlib, NO AI, read-only. Reads every task file:
#   caught    the **Breaker**: line on landed work (review/ + done/):
#             "<N> cases tried · <N> fixed · <N> filed [· $cost]"
#   found     fix tasks carrying **Fixes**: #N — filed by promote --reject
#             (N is a task) or by a human test's failures (N is a human test)
# Landed tasks split into breaker-checked and unchecked, so the escape rate
# with the breaker sits next to the rate without it.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

usage() { echo "Usage: ./sprint.sh status --edges [plan:N]"; }

PLAN=""
for a in "$@"; do
  case "$a" in
    --edges) ;;  # the mode flag, passed through by ./sprint.sh status
    plan:*) PLAN="${a#plan:}" ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
if [ -n "$PLAN" ] && ! [[ "$PLAN" =~ ^[0-9]+$ ]]; then
  echo "✗ plan:N needs a number (got: plan:$PLAN)" >&2; exit 2
fi
command -v python3 >/dev/null 2>&1 || { echo "✗ status --edges needs python3" >&2; exit 1; }

MAP="${SPRINTBIAS_PROJECT_MAP:-docs/sprintbias/project.md}"

python3 - "docs/tasks" "$PLAN" "$MAP" <<'PY'
import os, re, sys

tasks_dir, plan, map_path = sys.argv[1], sys.argv[2], sys.argv[3]
LANDED = ("review", "done")

def field(text, name):
    m = re.search(r"^\s*\*\*%s\*\*\s*:\s*(.*)$" % re.escape(name), text, re.M | re.I)
    return m.group(1).strip() if m else ""

def num(v):
    m = re.search(r"\d+", v or "")
    return m.group(0) if m else ""

tasks = {}
for stage in sorted(os.listdir(tasks_dir)) if os.path.isdir(tasks_dir) else []:
    d = os.path.join(tasks_dir, stage)
    if not os.path.isdir(d):
        continue
    for name in os.listdir(d):
        m = re.match(r"^(\d+)-.*\.md$", name)
        if not m:
            continue
        try:
            text = open(os.path.join(d, name), errors="replace").read()
        except OSError:
            continue
        title = re.search(r"^# (?:Task \d+: )?(.*)$", text, re.M)
        b = re.search(r"^\*\*Breaker\*\*:\s*(.*)$", text, re.M)
        rep = re.search(r"^- \S+ · (?:sent back from review|found broken after sign-off) \(#\d+\):\s*\n\s*```\n(.*?)\n", text, re.M)
        tasks[m.group(1)] = {
            "report": rep.group(1).strip() if rep else "",
            "id": m.group(1), "stage": stage, "title": title.group(1).strip() if title else name,
            "plan": num(field(text, "Plan")), "fixes": num(field(text, "Fixes")),
            "human": field(text, "Owner").lower() == "human", "breaker": b.group(1) if b else None,
        }

def in_scope(t):
    return not plan or t["plan"] == plan

def breaker_counts(line):
    m = re.search(r"(\d+)\s+cases?\s+tried\D+?(\d+)\s+fixed\D+?(\d+)\s+filed", line)
    cost = re.findall(r"\$(\d+(?:\.\d+)?)", line)
    return (tuple(int(x) for x in m.groups()) if m else None), (float(cost[-1]) if cost else None)

# Landed agent work, split by whether the breaker checked it.
g = {k: {"tasks": 0, "escapes": 0, "reject": 0, "human": 0} for k in ("checked", "unchecked")}
tried = fixed = filed = notrun = 0
cost = 0.0; costed = 0
for t in tasks.values():
    if t["stage"] not in LANDED or t["human"] or not in_scope(t):
        continue
    if t["breaker"] is None:
        g["unchecked"]["tasks"] += 1
        continue
    counts, c = breaker_counts(t["breaker"])
    if counts is None:
        notrun += 1
        g["unchecked"]["tasks"] += 1
        t["breaker"] = None
        continue
    g["checked"]["tasks"] += 1
    tried += counts[0]; fixed += counts[1]; filed += counts[2]
    if c is not None:
        cost += c; costed += 1

# A plan counts as checked when any landed member carries breaker counts.
checked_plans = {t["plan"] for t in tasks.values()
                 if t["plan"] and t["breaker"] and t["stage"] in LANDED and not t["human"]}

escaped = []
for f in tasks.values():
    o = tasks.get(f["fixes"])
    if not f["fixes"] or o is None:
        continue
    if o["human"]:
        if not in_scope(o):
            continue
        side = "checked" if o["plan"] in checked_plans else "unchecked"
        how = "human"
    else:
        if o["human"] or not in_scope(o) or o["stage"] not in LANDED + ("backlog", "next", "doing", "blocked"):
            continue
        side = "checked" if o["breaker"] else "unchecked"
        how = "reject"
    g[side]["escapes"] += 1
    g[side][how] += 1
    if side == "checked":
        escaped.append((f, o, how))

C, U = g["checked"], g["unchecked"]
caught = fixed + filed

def rate(e, n):
    return "%.1f" % (10.0 * e / n) if n else "—"

def row(label, a, b=""):
    print("  %-34s %10s   %s" % (label, a, b))

print("=== Edge cases: caught by agents vs found by you ===")
print("Scope: %s" % ("plan %s" % plan if plan else "every task"))
print("")
print("  %-34s %10s   %s" % ("", "Breaker", "No breaker"))
row("Tasks landed (review/ + done/)", C["tasks"], U["tasks"])
row("Found by you (escaped)", C["escapes"], U["escapes"])
row("  via promote --reject", C["reject"], U["reject"])
row("  via a human test", C["human"], U["human"])
row("Escapes per 10 tasks", rate(C["escapes"], C["tasks"]), rate(U["escapes"], U["tasks"]))
print("")
if C["tasks"]:
    print("Breaker on %d task(s): %d cases tried · %d fixed · %d filed" % (C["tasks"], tried, fixed, filed))
elif U["tasks"]:
    print("No breaker-checked work yet. Check a landed plan: ./sprint.sh polish --break plan:N")
else:
    print("No landed work yet. Build some: ./sprint.sh work")
if caught + C["escapes"]:
    print("Catch rate: %d%% — agents found %d, you found %d"
          % (round(100.0 * caught / (caught + C["escapes"])), caught, C["escapes"]))
if costed:
    per = (" · $%.2f per defect caught" % (cost / caught)) if caught else ""
    print("Breaker cost: $%.2f over %d run(s)%s" % (cost, costed, per))
if notrun:
    print("Breaker not run (crash or timeout): %d — re-run: ./sprint.sh polish --break <id>" % notrun)

if escaped:
    print("")
    print("Escaped past the breaker — the cases to learn from:")
    for f, o, how in sorted(escaped, key=lambda x: int(x[0]["id"])):
        src = "human test #%s" % o["id"] if how == "human" else "rejected #%s" % o["id"]
        print("  #%s (%s, %s) %s" % (f["id"], src, f["stage"], (f["report"] or f["title"])[:90]))

known = 0
if os.path.isfile(map_path):
    inside = False
    for line in open(map_path, errors="replace"):
        if line.startswith("## "):
            inside = line.strip().lower() == "## known edges"
            continue
        if inside and line.lstrip().startswith("- "):
            known += 1
    print("")
    print("Known edges in %s: %d" % (map_path, known))
else:
    print("")
    print("No project map yet, so rejected cases are not kept as known edges: ./sprint.sh profile")
PY
