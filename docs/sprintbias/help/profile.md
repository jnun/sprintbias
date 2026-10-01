The project map — how every agent knows what it needs to know.

docs/sprintbias/project.md is the one place that says where this project's
knowledge lives: stack, code layout (and where new code goes), commands (run /
test / lint / build), sources of truth (glossary / lexicon / taxonomy,
architecture, decisions, API, security, the instruction files you own), and
environments (local, CI, deploy — and who may deploy). Pointers and one-line
facts only; it never copies a document's content, and never records secrets.

Every AI command orients from it. The gate grounds each task in it: the task's
## Grounding names the sources it relies on, the terms it uses, and the
conflicts settled before work.

Usage:
  ./sprint.sh profile           # build or refresh the map (interactive AI; you confirm)
  ./sprint.sh profile show      # print the map (no AI)
  ./sprint.sh profile check     # drift check (no AI) — exit 1 when stale
  ./sprint.sh -g profile        # Grok Build for this run (leading -c = Claude)

profile scans the project, drafts the map, and asks you to confirm only what it
could not detect (which of two READMEs is the authority, who may deploy). On a
refresh it diffs against the existing map and leads with what changed. It ends
the file with a **Checked:** date @ commit stamp.

profile check needs no AI and runs automatically before work and plan start
(silent when current). It flags:
  - no map yet
  - a listed path that no longer exists
  - a tracked file changed since the **Checked:** stamp — sources of truth,
    environment files, manifests, CI/deploy config, new top-level docs
    (code folders under ## Code are not tracked; they change every task)

Refresh with ./sprint.sh profile when it flags drift.
