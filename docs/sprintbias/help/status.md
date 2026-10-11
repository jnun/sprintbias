Show project status — task counts per folder, items in blocked/ that cannot
start (each with its `./sprint.sh chat <id>` line), work in doing/, items in review/ that
**require human review** (sign-off or promote), features, and bugs.

Plans are listed with each member's folder and standing, the computed plan
state (STARTED / LANDED / SIGNED OFF) and three counts: open
(backlog/next/doing/blocked), landed (review/ with a **Proof**: line), signed
off (done/). Members in review/ without proof, held originals (proof in
place, waiting on a `**Held**:` fix; shown `held: fix #N`) and open fix tasks
(`**Fixes**: #N`) are flagged. Nothing is stamped; folders stay the status.

`review/` is not blocked: implementation is done; close needs a human (or
`./sprint.sh promote` when **Tests** is set).

Usage:
  ./sprint.sh status
