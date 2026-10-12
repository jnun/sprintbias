List the work you have finished, turn it into release notes, or write down the
finished tasks no plan record covers. Reads the records in docs/history/ — no AI.

Usage:
  ./sprint.sh history                       # one line per record, newest first
  ./sprint.sh history --since 2026-10-01    # release notes since a date
  ./sprint.sh history --since v1.2.0        # release notes since a git tag or commit
  ./sprint.sh history record                # record finished tasks no record covers

What it does:
  bare     — Prints each record, newest first: a plan record as finish date,
             plan id, title; a tasks record as `<date> · tasks · <count> tasks`.

  --since  — Prints Markdown release notes to stdout, oldest plan first: one
             ### heading per plan, the first sentence of its Goal, then its
             What changed lines (each task's title and summary). Tasks records
             follow: their ### Plan N groups, then ### Other work. Paste them
             into a changelog or a release page.
             A date (YYYY-MM-DD) picks records finished on or after it.
             Anything else is a git ref: it picks the records the ref's tree
             does not have yet (committed since, or not committed), so two
             releases on the same day split correctly. An unknown ref prints
             an error and exits non-zero. Nothing in range prints one line and
             exits 0.

  record   — Writes docs/history/YYYY-MM-DD-tasks.md (-2, -3… when that day's
             file exists) for every done/ task that no record names yet and
             that is planless (**Plan**: none, or no **Plan** line) or in a
             retired plan (its file gone from docs/plans/). Retired plans get a
             ### Plan N group (title from git history, else "Plan N"); the rest
             go under ### Other work. Members of open plans wait for
             `plan done`, so each task is written once. The record is staged in
             git; the commit is yours. Nothing new prints "History is up to
             date with done/." and exits 0. Run it before a release.

`plan done` writes one record per finished plan; `history record` covers the
rest. The summaries come from each task's **Summary**: line under ## Completed.
