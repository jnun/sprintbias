#!/usr/bin/env bash
# history.sh — List finished work, turn it into release notes, or record
# finished tasks no plan record covers. See: ./sprint.sh help history
#
# Invoked as: ./sprint.sh history [--since <YYYY-MM-DD | git ref>]
#             ./sprint.sh history record
#
# Pure shell, NO AI. Reads two kinds of record in docs/history/:
#   plan records   `plan done` writes one per retired plan, headed
#                  `# Plan N: <title>`, with `**Finished**: YYYY-MM-DD`,
#                  `## Goal` and `## What changed`
#   tasks records  `history record` writes YYYY-MM-DD-tasks[-N].md, headed
#                  `# Work recorded YYYY-MM-DD`: one `### Plan N: <title>`
#                  group per retired plan, then `### Other work`
# Files with neither heading are skipped.
#
#   bare             one line per record, newest first
#   --since DATE     Markdown release notes for records finished on/after DATE
#   --since REF      release notes for records the git REF's tree lacks
#                    (committed since REF, or not committed yet)
#   record           write a tasks record for every done/ task that no record
#                    names yet and that is planless or in a retired plan
#                    (plan file gone from docs/plans/); open plans' members
#                    wait for `plan done`. The only mode that writes a file.
# Notes list plans oldest first: one ### heading per plan, the first sentence
# of its Goal, then its What changed lines; tasks records follow, their
# ### Plan N groups then ### Other work.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

HISTORY_DIR="docs/history"

usage() { echo "Usage: ./sprint.sh history [--since <YYYY-MM-DD | git ref>] | history record"; }

SINCE=""
HAVE_SINCE=0
RECORD_MODE=0
if [ "${1:-}" = "record" ]; then
  RECORD_MODE=1; shift
  [ $# -eq 0 ] || { echo "Error: history record takes no arguments." >&2; usage >&2; exit 1; }
fi
while [ $# -gt 0 ]; do
  case "$1" in
    --since)
      [ -n "${2:-}" ] || { echo "Error: --since needs a date (YYYY-MM-DD) or a git ref." >&2; usage >&2; exit 1; }
      SINCE="$2"; HAVE_SINCE=1; shift 2 ;;
    *)
      echo "Error: unknown argument '$1'." >&2; usage >&2; exit 1 ;;
  esac
done

# record_rows — one tab-separated row per record: finished, plan id (0 for a
# tasks record), kind (plan | tasks), title or task count, file.
record_rows() {
  local f
  for f in "$HISTORY_DIR"/*.md; do
    [ -f "$f" ] || continue
    awk -v file="$f" '
      { sub(/\r$/, "") }
      !head && /^# / {
        head = 1
        if ($0 ~ /^# Work recorded/) { kind = "tasks"; id = 0; next }
        if ($0 !~ /^# Plan [0-9]+:/) exit
        kind = "plan"
        id = $0; sub(/^# Plan /, "", id); sub(/:.*/, "", id)
        title = $0; sub(/^# Plan [0-9]+:[ \t]*/, "", title)
        next
      }
      kind != "" && fin == "" && /^\*\*Finished\*\*:/ {
        if (match($0, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)) fin = substr($0, RSTART, RLENGTH)
        if (kind == "plan") exit
      }
      kind == "tasks" && /^- #[0-9]+ / { n++ }
      END {
        if (kind == "") exit
        printf "%s\t%s\t%s\t%s\t%s\n", (fin == "" ? "0000-00-00" : fin), id, kind, (kind == "tasks" ? n + 0 : title), file
      }
    ' "$f"
  done
}

# goal_sentence FILE — first sentence of the record's ## Goal prose. A
# sentence ends at . ! or ? before a space and a non-lowercase character, so
# "e.g. one" and "i.e. this" stay inside it.
goal_sentence() {
  awk '
    { sub(/\r$/, "") }
    /^## / { if (on) exit; if ($0 ~ /^## Goal[ \t]*$/) on = 1; next }
    !on { next }
    /^[ \t]*$/ { if (prose != "") exit; next }
    /^###/ || /^[ \t]*([-*+]|[0-9]+\.)[ \t]/ { if (prose != "") exit; next }
    { prose = prose (prose == "" ? "" : " ") $0 }
    END { print prose }' "$1" \
    | sed -E 's/^[[:space:]]+//; s/([.!?])[[:space:]]+[^[:lower:][:space:]].*$/\1/; s/[[:space:]]+$//'
}

# changed_lines FILE — the ## What changed list, each line without its task id
# and task-file path (internal pointers), so it reads as a release note.
changed_lines() {
  awk '
    { sub(/\r$/, "") }
    /^## / { if (on) exit; if ($0 ~ /^## What changed[ \t]*$/) on = 1; next }
    on && /^- / { print }' "$1" \
    | strip_pointers
}

# strip_pointers — drop each line's task id and task-file path (internal
# pointers), so it reads as a release note.
strip_pointers() {
  sed -E 's/^- #[0-9]+ — /- /; s/ \(docs\/tasks\/[^)]*\.md\)[[:space:]]*$//'
}

# tasks_notes FILE... — the groups of tasks records (oldest first) merged into
# one block: ### Plan N groups by plan id, then ### Other work.
tasks_notes() {
  awk '
    { sub(/\r$/, "") }
    /^### / { g = $0; next }
    g != "" && /^- #[0-9]+ / {
      k = 999999999
      if (g ~ /^### Plan [0-9]+/) { k = g; sub(/^### Plan /, "", k); sub(/[^0-9].*/, "", k) }
      printf "%s\t%s\t%s\n", k, g, $0
    }' "$@" \
    | sort -t$'\t' -s -k1,1n \
    | awk -F'\t' '
      $2 != cur { if (cur != "") print ""; cur = $2; print $2; print "" }
      { print $3 }' \
    | strip_pointers
}

# ── record: write finished tasks no record names yet ─────────────────
if [ "$RECORD_MODE" -eq 1 ]; then
  source "$PROJECT_ROOT/docs/sprintbias/lib.sh"
  DONE_DIR="docs/tasks/done"
  IN_GIT=0
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 && IN_GIT=1

  # Task ids already written down: every `- #ID —` line in a record, except a
  # plan record's ## Follow-ups (those name open work, not finished work).
  RECORDED=""
  if ls "$HISTORY_DIR"/*.md >/dev/null 2>&1; then
    RECORDED="$(awk '
      FNR == 1 { fu = 0 }
      /^## / { fu = ($0 ~ /^## Follow-ups/) }
      !fu && /^- #[0-9]+ — / { s = $0; sub(/^- #/, "", s); sub(/[^0-9].*/, "", s); print s }
    ' "$HISTORY_DIR"/*.md)"
  fi

  # Pick: unrecorded done/ tasks that are planless (none, or no **Plan** line)
  # or whose plan file is gone. Row: group key, id, file.
  PICKED=""
  for f in "$DONE_DIR"/*.md; do
    [ -f "$f" ] || continue
    id="$(basename "$f" | grep -oE '^[0-9]+' || true)"
    [ -n "$id" ] || continue
    grep -qx "$id" <<<"$RECORDED" && continue
    plan="$(sprintbias_meta_value "$f" "Plan" | tr -d '#' | sed -E 's/^[[:space:]]+//' | grep -oE '^[0-9]+' || true)"
    if [ -n "$plan" ]; then
      plan=$((10#$plan))   # **Plan**: 07 is plan 7
      sprintbias_find_plan "$plan" >/dev/null && continue   # open plan: plan done records it
      key="$plan"
    else
      key=999999999
    fi
    PICKED+="$key"$'\t'"$id"$'\t'"$f"$'\n'
  done

  if [ -z "$PICKED" ]; then
    echo "History is up to date with done/."
    exit 0
  fi

  # retired_plan_title N — the deleted plan file's title from git: HEAD when the
  # deletion is not committed yet, else the parent of the deleting commit.
  # Paths stay relative to the board (`--relative`, `rev:./path`), so a board
  # in a subfolder of a larger repo reads the same.
  retired_plan_title() {
    [ "$IN_GIT" -eq 1 ] || return 0
    local log rev path
    path="$(git ls-tree --name-only HEAD -- docs/plans/ 2>/dev/null | grep -m1 "^docs/plans/$1-.*\.md$" || true)"
    if [ -n "$path" ]; then
      rev="HEAD"
    else
      log="$(git log --relative --diff-filter=D --format=%H --name-only -1 -- "docs/plans/$1-*.md" 2>/dev/null || true)"
      rev="$(sed -n 1p <<<"$log")^"
      path="$(grep -m1 "^docs/plans/$1-" <<<"$log" || true)"
    fi
    [ -n "$path" ] && [ "$rev" != "^" ] || return 0
    git show "$rev:./$path" 2>/dev/null | grep -m1 '^# ' | sed -E 's/^# *(Plan *[0-9]+: *)?//' || true
  }

  TODAY="$(date +%Y-%m-%d)"
  RECORD="$HISTORY_DIR/$TODAY-tasks.md"
  n=2
  while [ -e "$RECORD" ]; do RECORD="$HISTORY_DIR/$TODAY-tasks-$n.md"; n=$((n + 1)); done
  COUNT="$(grep -c . <<<"$PICKED" | tr -d ' ')"

  mkdir -p "$HISTORY_DIR"
  TMP_REC="$(mktemp "$HISTORY_DIR/.record.XXXXXX")"
  trap 'rm -f "$TMP_REC"' EXIT
  {
    printf '# Work recorded %s\n\n' "$TODAY"
    printf '**Finished**: %s · **Tasks**: %s\n' "$TODAY" "$COUNT"
    cur=""
    while IFS=$'\t' read -r key id f; do
      [ -n "$key" ] || continue
      if [ "$key" != "$cur" ]; then
        cur="$key"
        if [ "$key" = 999999999 ]; then
          printf '\n### Other work\n\n'
        else
          title="$(retired_plan_title "$key")"
          printf '\n### Plan %s: %s\n\n' "$key" "${title:-Plan $key}"
        fi
      fi
      title="$(task_title "$f" | tr -d '\r')"
      summ="$(sprintbias_task_summary "$f")"
      if [ -n "$summ" ]; then
        printf -- '- #%s — %s: %s (%s)\n' "$id" "$title" "$summ" "$f"
      else
        printf -- '- #%s — %s (%s)\n' "$id" "$title" "$f"
      fi
    done < <(sort -t$'\t' -k1,1n -k2,2n <<<"$PICKED")
  } > "$TMP_REC"
  mv -f "$TMP_REC" "$RECORD"
  trap - EXIT

  [ "$IN_GIT" -eq 1 ] && { git add -- "$RECORD" 2>/dev/null || true; }
  echo "✓ Recorded $COUNT finished task(s) in $RECORD."
  [ "$IN_GIT" -eq 1 ] && echo "  (The record is staged; the commit is yours.)"
  exit 0
fi

ROWS="$(record_rows)"

# ── Bare: the timeline, newest first ─────────────────────────────────
if [ "$HAVE_SINCE" -eq 0 ]; then
  if [ -z "$ROWS" ]; then
    echo "No history records yet in $HISTORY_DIR/ — ./sprint.sh plan done writes one per finished plan; ./sprint.sh history record covers the rest."
    exit 0
  fi
  sort -t$'\t' -k1,1r -k2,2nr -k5,5r <<<"$ROWS" | while IFS=$'\t' read -r fin id kind title _file; do
    if [ "$kind" = tasks ]; then
      printf '%s · tasks · %s tasks\n' "$fin" "$title"
    else
      printf '%s  Plan %-4s %s\n' "$fin" "$id" "$title"
    fi
  done
  exit 0
fi

# ── --since: pick the records in range ───────────────────────────────
if [[ "$SINCE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  SELECTED="$(awk -F'\t' -v d="$SINCE" '$1 >= d' <<<"$ROWS")"
else
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: '$SINCE' is not a date (YYYY-MM-DD) and this is not a git work tree, so it cannot be a git ref." >&2
    exit 1
  fi
  if ! git rev-parse --verify -q "$SINCE^{tree}" >/dev/null 2>&1; then
    echo "Error: '$SINCE' is not a date (YYYY-MM-DD) or a git ref this repo knows." >&2
    exit 1
  fi
  # Records already in the ref's tree shipped with it; the rest are new.
  OLD="$(git ls-tree -r --name-only "$SINCE" -- "$HISTORY_DIR" 2>/dev/null | sed 's#.*/##')"
  SELECTED="$(OLD="$OLD" awk -F'\t' '
    BEGIN { n = split(ENVIRON["OLD"], a, "\n"); for (i = 1; i <= n; i++) seen[a[i]] = 1 }
    { b = $5; sub(/.*\//, "", b); if (!(b in seen)) print }' <<<"$ROWS")"
fi

if [ -z "$SELECTED" ]; then
  echo "No history records since $SINCE."
  exit 0
fi

# ── Release notes, oldest first ──────────────────────────────────────
# Plan records first, one ### per plan; then the tasks records' groups.
first=1
while IFS=$'\t' read -r _fin _id kind title file; do
  [ "$kind" = plan ] || continue
  [ "$first" -eq 1 ] || echo ""
  first=0
  printf '### %s\n' "$title"
  goal="$(goal_sentence "$file")"
  [ -n "$goal" ] && printf '\n%s\n' "$goal"
  changed="$(changed_lines "$file")"
  [ -n "$changed" ] && printf '\n%s\n' "$changed"
done < <(sort -t$'\t' -k1,1 -k2,2n <<<"$SELECTED")

TASK_FILES=()
while IFS=$'\t' read -r _fin _id kind _title file; do
  [ "$kind" = tasks ] && TASK_FILES+=("$file")
done < <(sort -t$'\t' -k1,1 -k5,5 <<<"$SELECTED")
if [ ${#TASK_FILES[@]} -gt 0 ]; then
  [ "$first" -eq 1 ] || echo ""
  tasks_notes "${TASK_FILES[@]}"
fi
exit 0
