Clear scratch files from docs/tmp/.

Usage:
  ./sprint.sh cleanup              # show stale files, then prompt to delete
  ./sprint.sh cleanup --force      # delete stale files (no prompt)

Stale = AI session logs (log-*.json) plus anything older than 7 days.
Recent files are always kept. --force skips the y/N prompt for scripts and
CI where no one is at the keyboard. To wipe everything, rm -rf docs/tmp/.
