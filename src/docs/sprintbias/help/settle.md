Accept suggested answers on open questions — fold into the task body and clear.

Closes the common stall where gate or chat left `### Questions for the developer`
items that already carry `(Suggestion: …)`, so `work` refuses to run a READY
task. **Does not invent answers** — only applies suggestions already written in
the file.

## What it does

1. Finds open questions (same detector as `work` / `gate`).
2. For each item with `(Suggestion: …)`:
   - Appends the pick under `## Notes` as a settled decision.
   - **Deletes** the question (questions only exist while undecided).
3. When the list is empty: writes `None — task is fully defined.`
4. If any questions remain (no suggestion): **demotes** the file out of `next/`
   to `blocked/` with a BLOCKED stamp (READY + open Q is an integrity error).

## Usage

```bash
./sprint.sh settle              # every next/ task with open questions
./sprint.sh settle 966          # one task id (any stage)
./sprint.sh settle --dry-run    # report what would change
./sprint.sh settle --blocked    # also scan blocked/ (bulk clean-up)
```

## When to use

| Situation | Command |
|-----------|---------|
| Sprint stuck: READY but work holds on open Qs | `./sprint.sh settle` then re-check `work` |
| One task with suggested micro-choices | `./sprint.sh settle <id>` |
| Real product decision, no suggestion | `./sprint.sh chat <id>` (human answers) |
| Cleared blocked task back into the sprint | `bash docs/sprintbias/scripts/promote-to-sprint.sh <file>` |

## Related

- `work` — auto-demotes READY + open Q out of `next/` if you skip settle
- `gate` — must leave `None — task is fully defined.` for READY
- `chat` — interactive answer path when settle cannot apply a suggestion

Provider/model flags do not apply — settle is pure file surgery (no AI).
