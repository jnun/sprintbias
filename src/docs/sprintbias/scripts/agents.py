#!/usr/bin/env python3
"""agents.py — list the AI sessions running on this machine and on remote hosts.

Called by agents.sh (./sprint.sh agents). Python 3 stdlib only, so the same
file runs on a remote host fed through ssh: `ssh HOST python3 - --collect`.

Reads what Claude Code already writes: one registry file per live session in
~/.claude/sessions/<pid>.json (name, status, cwd, start time) and the session
transcript ~/.claude/projects/<cwd-slug>/<sessionId>.jsonl (topic, last
prompt, model, context size). Adds process facts from `ps` (uptime, CPU and
memory summed over the session's child processes) and where it runs (terminal
app, tty, or tmux window). Nothing is written except by --label.

  agents.py [--json] [--local] [--host H]...   collect and print
  agents.py --collect                          print this machine's sessions as JSON
  agents.py --label [--local] [--host H]...    title each session's terminal with its name
"""

import json
import os
import re
import socket
import subprocess
import sys
import time

CLAUDE_DIR = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.expanduser("~/.claude")
TAIL_BYTES = 512 * 1024  # how much of a transcript to scan from the end

# Ancestor process names that tell us which app holds the session.
TERMINALS = {
    "ghostty": "Ghostty", "terminal": "Terminal", "iterm2": "iTerm", "wezterm-gui": "WezTerm",
    "alacritty": "Alacritty", "kitty": "kitty", "warp": "Warp", "code": "VS Code",
    "cursor": "Cursor", "gnome-terminal-server": "GNOME Terminal", "konsole": "Konsole",
    "sshd": "ssh", "tmux": "tmux", "screen": "screen",
}


def run(cmd, timeout=5):
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return out.stdout if out.returncode == 0 else ""
    except (OSError, subprocess.SubprocessError):
        return ""


def alive(pid):
    try:
        os.kill(pid, 0)
        return True
    except PermissionError:
        return True
    except OSError:
        return False


def process_table():
    """pid -> (ppid, cpu%, rss KB, tty, comm) for every process."""
    table = {}
    for line in run(["ps", "-axo", "pid=,ppid=,%cpu=,rss=,tty=,comm="]).splitlines():
        parts = line.split(None, 5)
        if len(parts) < 6:
            continue
        try:
            table[int(parts[0])] = (int(parts[1]), float(parts[2]), int(parts[3]), parts[4], parts[5])
        except ValueError:
            continue
    return table


def descendants(pid, table):
    kids = {}
    for p, row in table.items():
        kids.setdefault(row[0], []).append(p)
    out, stack = [], [pid]
    while stack:
        for child in kids.get(stack.pop(), []):
            out.append(child)
            stack.append(child)
    return out


def terminal_app(pid, table):
    """Name of the first known app among the session's ancestors."""
    seen = set()
    p = table.get(pid, (0,))[0]
    while p > 1 and p not in seen and p in table:
        seen.add(p)
        name = os.path.basename(table[p][4]).lstrip("-").lower()
        name = name.split()[0] if name else name
        if name in TERMINALS:
            return TERMINALS[name]
        p = table[p][0]
    return ""


def tmux_panes():
    """tty -> 'session:window' for every tmux pane on this machine."""
    panes = {}
    out = run(["tmux", "list-panes", "-a", "-F", "#{pane_tty}\t#{session_name}:#{window_index}"])
    for line in out.splitlines():
        tty, _, where = line.partition("\t")
        panes[tty.replace("/dev/", "")] = where
    return panes


def transcript_facts(cwd, session_id):
    """Topic, last prompt, model, context tokens and last-write time from the transcript."""
    slug = re.sub(r"[^A-Za-z0-9]", "-", cwd)
    path = os.path.join(CLAUDE_DIR, "projects", slug, session_id + ".jsonl")
    facts = {"topic": "", "last_prompt": "", "model": "", "context_tokens": 0, "last_write": 0}
    try:
        facts["last_write"] = int(os.path.getmtime(path))
        with open(path, "rb") as fh:
            fh.seek(max(0, os.path.getsize(path) - TAIL_BYTES))
            lines = fh.read().decode("utf-8", "replace").splitlines()[1:]
    except OSError:
        return facts
    for line in reversed(lines):
        if all(facts[k] for k in ("topic", "last_prompt", "model")):
            break
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        kind = entry.get("type")
        if kind == "ai-title" and not facts["topic"]:
            facts["topic"] = entry.get("aiTitle", "")
        elif kind == "custom-title" and not facts["topic"]:
            facts["topic"] = entry.get("customTitle", "")
        elif kind == "last-prompt" and not facts["last_prompt"]:
            facts["last_prompt"] = entry.get("lastPrompt", "")
        elif kind == "assistant" and not facts["model"] and not entry.get("isSidechain"):
            msg = entry.get("message") or {}
            usage = msg.get("usage") or {}
            if msg.get("model") and usage:
                facts["model"] = msg["model"]
                facts["context_tokens"] = sum(
                    usage.get(k) or 0 for k in
                    ("input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens", "output_tokens"))
    return facts


def crew_role(cwd, name):
    """**Role** line from docs/crew/<name>.md when the session is a crew member."""
    try:
        with open(os.path.join(cwd, "docs", "crew", name + ".md")) as fh:
            for line in fh:
                if line.startswith("**Role**:"):
                    return line.split(":", 1)[1].strip()
    except OSError:
        pass
    return ""


def git_branch(cwd):
    return run(["git", "-C", cwd, "branch", "--show-current"], timeout=3).strip()


def collect():
    """Every live session on this machine, as dicts."""
    host = socket.gethostname().split(".")[0]
    table = process_table()
    panes = tmux_panes()
    sessions = []
    sdir = os.path.join(CLAUDE_DIR, "sessions")
    try:
        files = sorted(f for f in os.listdir(sdir) if f.endswith(".json"))
    except OSError:
        files = []
    for fname in files:
        try:
            with open(os.path.join(sdir, fname)) as fh:
                reg = json.load(fh)
            pid = int(reg["pid"])
        except (OSError, ValueError, KeyError, TypeError):
            continue
        if not alive(pid) or pid not in table:
            continue  # registry file left behind by a session that ended
        family = [pid] + descendants(pid, table)
        tty = table[pid][3]
        cwd = reg.get("cwd", "")
        name = reg.get("name") or reg.get("sessionId", "")[:8]
        where = ("tmux " + panes[tty]) if tty in panes else " ".join(
            x for x in (terminal_app(pid, table), tty if tty not in ("??", "?") else "") if x)
        sessions.append(dict(
            name=name, host=host, pid=pid, tty=tty, where=where,
            tmux=panes.get(tty, ""), status=reg.get("status", ""), kind=reg.get("kind", ""),
            status_since=int((reg.get("statusUpdatedAt") or 0) / 1000),
            started=int((reg.get("startedAt") or 0) / 1000),
            cwd=cwd, project=os.path.basename(cwd), branch=git_branch(cwd) if cwd else "",
            cpu=round(sum(table[p][1] for p in family if p in table), 1),
            mem_mb=round(sum(table[p][2] for p in family if p in table) / 1024),
            children=len(family) - 1, version=reg.get("version", ""),
            role=crew_role(cwd, name), session_id=reg.get("sessionId", ""),
            **transcript_facts(cwd, reg.get("sessionId", "")),
        ))
    if not os.path.isdir(sdir):
        sessions += unregistered(table, panes, host)
    return sessions


def process_cwd(pid):
    link = "/proc/%d/cwd" % pid
    if os.path.exists(link):
        try:
            return os.readlink(link)
        except OSError:
            return ""
    for line in run(["lsof", "-a", "-p", str(pid), "-d", "cwd", "-Fn"]).splitlines():
        if line.startswith("n"):
            return line[1:]
    return ""


def unregistered(table, panes, host):
    """`claude` processes on a host whose build keeps no registry: name them by pid."""
    found = []
    for pid, (ppid, _, _, tty, comm) in table.items():
        if os.path.basename(comm) != "claude" or not alive(pid):
            continue
        if os.path.basename(table.get(ppid, (0, 0, 0, "", ""))[4]) == "claude":
            continue  # a helper the session spawned, not a session
        family = [pid] + descendants(pid, table)
        cwd = process_cwd(pid)
        found.append(dict(
            name="claude-%d" % pid, host=host, pid=pid, tty=tty, tmux=panes.get(tty, ""),
            where=("tmux " + panes[tty]) if tty in panes else " ".join(
                x for x in (terminal_app(pid, table), tty if tty not in ("??", "?") else "") if x),
            status="", kind="", status_since=0, started=0, cwd=cwd,
            project=os.path.basename(cwd), branch=git_branch(cwd) if cwd else "",
            cpu=round(sum(table[p][1] for p in family if p in table), 1),
            mem_mb=round(sum(table[p][2] for p in family if p in table) / 1024),
            children=len(family) - 1, version="", role="", session_id="",
            topic="", last_prompt="", model="", context_tokens=0, last_write=0,
        ))
    return found


def label(sessions):
    """Title each session's terminal tab (or tmux window) with its name."""
    for s in sessions:
        title = s["name"] + (" · " + s["project"] if s["project"] else "")
        if s["tmux"]:
            run(["tmux", "rename-window", "-t", s["tmux"], s["name"]])
            print("  %-18s tmux window %s" % (s["name"], s["tmux"]))
        elif s["tty"] not in ("??", "?", ""):
            try:
                with open("/dev/" + s["tty"], "w") as tty:
                    tty.write("\033]2;%s\007" % title)
                print("  %-18s %s" % (s["name"], s["where"]))
            except OSError as err:
                print("  %-18s could not title %s (%s)" % (s["name"], s["tty"], err.strerror))


def remote(host, mode="--collect"):
    """Run this file on HOST over ssh; returns (sessions, error)."""
    with open(os.path.abspath(__file__), "rb") as src:
        code = src.read()
    cmd = ["ssh", "-T", "-o", "BatchMode=yes", "-o", "ConnectTimeout=10",
           "-o", "ClearAllForwardings=yes", host, "python3", "-", mode]
    try:
        out = subprocess.run(cmd, input=code, capture_output=True, timeout=60)
    except subprocess.TimeoutExpired:
        return [], "timed out"
    except OSError as err:
        return [], err.strerror
    if mode == "--label":
        sys.stdout.write(out.stdout.decode("utf-8", "replace"))
    if out.returncode != 0:
        lines = out.stderr.decode("utf-8", "replace").strip().splitlines()
        return [], lines[-1] if lines else "ssh exited %d" % out.returncode
    if mode == "--label":
        return [], ""
    try:
        sessions = json.loads(out.stdout.decode("utf-8", "replace") or "[]")
    except ValueError:
        return [], "unreadable reply"
    for s in sessions:
        s["host"] = host
    return sessions, ""


# ── Rendering ────────────────────────────────────────────────────────

COLOR = sys.stdout.isatty() and not os.environ.get("NO_COLOR")


def paint(code, text):
    return "\033[%sm%s\033[0m" % (code, text) if COLOR and text else text


def ago(ts, now):
    if not ts:
        return "-"
    secs = max(0, int(now - ts))
    d, rem = divmod(secs, 86400)
    h, rem = divmod(rem, 3600)
    m = rem // 60
    if d:
        return "%dd%02dh" % (d, h)
    if h:
        return "%dh%02dm" % (h, m)
    return "%dm" % m if m else "%ds" % secs


def tokens(n):
    return "-" if not n else ("%.1fM" % (n / 1e6) if n >= 1e6 else "%dk" % round(n / 1000))


def short_model(model):
    return re.sub(r"^claude-", "", re.sub(r"-\d{8}$", "", model or "")) or "-"


STATUS_COLOR = {"busy": "1;32", "waiting": "1;33", "idle": "2"}


def render(groups, now):
    total, counts = 0, {}
    for host, sessions, error in groups:
        head = paint("1;34", host) + paint("2", "  %d agent%s" % (len(sessions), "" if len(sessions) == 1 else "s"))
        print(head + (paint("31", "  unreachable: " + error) if error else ""))
        if not sessions:
            print(paint("2", "  none running") if not error else "")
            print()
            continue
        rows = []
        for s in sorted(sessions, key=lambda s: s["started"]):
            total += 1
            counts[s["status"] or "?"] = counts.get(s["status"] or "?", 0) + 1
            proj = s["project"] + ("@" + s["branch"] if s["branch"] else "")
            rows.append([
                s["name"],
                # The registry's status time lags; the transcript write is the fresher clock.
                "%s %s" % (s["status"] or "?", ago(max(s["status_since"], s["last_write"]), now)),
                s["where"] or "-",
                proj or "-",
                "up " + ago(s["started"], now),
                "last " + ago(s["last_write"], now),
                short_model(s["model"]),
                "ctx " + tokens(s["context_tokens"]),
                "%.1f%% %dM" % (s["cpu"], s["mem_mb"]),
                "pid %d" % s["pid"],
            ])
        widths = [max(len(r[i]) for r in rows) for i in range(len(rows[0]))]
        for s, r in zip(sorted(sessions, key=lambda s: s["started"]), rows):
            cells = [c.ljust(w) for c, w in zip(r, widths)]
            cells[0] = paint("1", cells[0])
            cells[1] = paint(STATUS_COLOR.get(s["status"], "0"), cells[1])
            cells[3] = paint("36", cells[3])
            print("  " + "  ".join(cells).rstrip())
            about = " — ".join(x for x in (
                s["role"] and "[%s]" % s["role"], s["topic"],
                s["last_prompt"] and '"%s"' % s["last_prompt"].replace("\n", " ")) if x)
            if about:
                width = max(40, _columns() - 6)
                print(paint("2", "    ↳ " + (about if len(about) <= width else about[:width - 1] + "…")))
        print()
    summary = ", ".join("%d %s" % (n, k) for k, n in sorted(counts.items(), key=lambda kv: -kv[1]))
    print(paint("1", "%d agent%s running" % (total, "" if total == 1 else "s")) + (" · " + summary if summary else ""))


def _columns():
    try:
        return os.get_terminal_size().columns
    except OSError:
        return 120


def main(argv):
    hosts, as_json, local_only, labelling = [], False, False, False
    i = 0
    while i < len(argv):
        arg = argv[i]
        if arg == "--collect":
            print(json.dumps(collect()))
            return 0
        if arg == "--label":
            labelling = True
        elif arg == "--json":
            as_json = True
        elif arg == "--local":
            local_only = True
        elif arg == "--host" and i + 1 < len(argv):
            i += 1
            hosts.append(argv[i])
        else:
            print("agents.py: unknown option %s" % arg, file=sys.stderr)
            return 2
        i += 1

    if local_only:
        hosts = []
    if labelling:
        label(collect())
        for host in hosts:
            _, error = remote(host, "--label")
            if error:
                print("  %s: unreachable: %s" % (host, error))
        return 0

    now = time.time()
    groups = [(socket.gethostname().split(".")[0] + " (this machine)", collect(), "")]
    for host in hosts:
        sessions, error = remote(host)
        groups.append((host, sessions, error))
    if as_json:
        print(json.dumps([dict(s, host_error="") for _, ss, _ in groups for s in ss] +
                         [{"host": h, "host_error": e} for h, _, e in groups if e], indent=2))
        return 0
    render(groups, now)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
