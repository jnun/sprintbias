# Plan 90: dep-glitch-matrix synthetic

**Created**: 2026-08-01
**Status:** DRAFT

> Synthetic plan for the dependency glitch matrix fixture only.
> Not a real SprintBias product plan. Do not plan start this into a live repo
> board unless you intend to stress-test.

## Goal

Provide a single relational index over fixture tasks 9000–9099 so Plan-field
sync (#331) and status rollups can be exercised.

## Member tasks

- #9001 — Healthy done prereq
- #9002 — Healthy review prereq
- #9003 — Peer in next READY
- #9004 — Peer in next unstamped
- #9005 — Completed orphan still in doing
- #9006 — Incomplete orphan mid-work
- #9007 — Hard-fail residue left in doing
- #9008 — Decision still needed in blocked
- #9009 — Never promoted out of backlog
- #9011 — Folded into 9012 (tombstone)
- #9012 — Fold survivor absorbing 9011
- #9014 — Split child A of deleted 9013
- #9015 — Split child B of deleted 9013
- #9016 — One-way edge: depends on 9017
- #9017 — Missing reverse Blocks for 9016
- #9018 — Cycle participant A
- #9019 — Cycle participant B
- #9020 — Self-dependency
- #9021 — Review prereq without a proof line
- #9030 — Pushed back to backlog after demotion
- #9031 — Never lifted but lists dependents
- #9032 — Incomplete work routed to blocked
- #9033 — Crash left partial edits in doing
- #9036 — Malformed Depends on tokens
- #9037 — Bad inverted range in Depends
- #9038 — Hash-prefixed depends parse
- #9043 — Replacement after 9042 removed
- #9050 — Canary: both prereqs met
- #9051 — Canary: wait peer READY
- #9052 — Canary: wait unstamped peer
- #9053 — Canary: wait doing ## Completed
- #9054 — Canary: wait doing incomplete
- #9055 — Canary: dangling missing 9010
- #9056 — Canary: still depends on folded 9011
- #9057 — Canary: prereq chat-removed 9041
- #9058 — Canary: still depends on replaced 9042
- #9059 — Canary: depends on deleted split parent 9013
- #9060 — Canary: backlog never lifted 9009
- #9061 — Canary: pushed-back prereq 9030
- #9062 — Canary: blocked decision 9008
- #9063 — Canary: incomplete blocked 9032
- #9064 — Canary: hard-fail doing 9007
- #9065 — Canary: met + backlog
- #9066 — Canary: review + doing complete
- #9067 — Canary: next + missing
- #9068 — Chain tip waits on mid
- #9069 — Chain mid waits on root
- #9070 — Chain root incomplete in doing
- #9071 — Diamond left
- #9072 — Diamond right
- #9073 — Diamond root still in backlog
- #9074 — Canary: range depends 9001-9003
- #9075 — Canary: depends on 9017 (one-way pair)
- #9076 — Canary: waits on cycle 9018
- #9077 — Canary: fold stale + doing incomplete
- #9078 — Canary: prereq 9031 demoted with dependents
- #9079 — Canary: runnable but plan drift sibling
- #9080 — Umbrella canary: every glitch class
- #9081 — Plan lists me but Plan field none
- #9083 — Plan field points at missing plan 99
- #9084 — Empty depends field shape
- #9085 — Depends only on healthy done
- #9086 — Blocks lists missing reverse id
- #9087 — Parent points at missing task
- #9089 — READY stamp but open question remains
- #9090 — Depends on a review prereq without proof

## Intentionally omitted members (drift cases)

Ids are code-quoted here so this prose does not itself parse as a member line
(sprintbias_plan_member_ids reads only "- #ID" bullets) — otherwise #9082's
"declared on the task, absent from the plan" drift case would silently heal.

- `#9082` — has **Plan**: 90 on the task but is omitted here
- `#9010`, `#9013`, `#9041`, `#9042` — missing files (dangling / fold / split / replace)

## Fold / split ledger (for classifiers)

| From | To | Kind |
|------|-----|------|
| 9011 | 9012 | fold (tombstone in backlog) |
| 9042 | 9043 | replace (9042 absent) |
| 9013 | 9014 + 9015 | split (parent deleted) |
| 9041 | — | chat-removed (no survivor) |

