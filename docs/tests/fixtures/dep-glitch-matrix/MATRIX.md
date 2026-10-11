# Dependency & work-completion glitch matrix

Synthetic board for Plan 15 (and #332). **ID range 9000–9099** so it never
collides with real SprintBias work. Regenerate with:

```bash
bash docs/tests/fixtures/dep-glitch-matrix/seed.sh
# or into a temp project:
bash docs/tests/fixtures/dep-glitch-matrix/seed.sh /tmp/dep-glitch-board
```

Inspect holds the way `work` would:

```bash
bash docs/tests/fixtures/dep-glitch-matrix/check-inventory.sh
```

## Design rules

1. Every case is a **real task file** (or an intentional absence) with honest
   metadata — no comments-only stubs that parsers skip.
2. **Canary tasks** in `next/` (READY) depend on combinations so one
   `work` prepass would surface many holds at once.
3. **Expected** column is the *desired* product behavior after Plan 15.
   Current code may still treat some `missing` ids as complete — that gap
   is what the plan closes.
4. Reverse edge field: write **Dependents** (canonical). Seed may still emit
   **Blocks** for legacy-reader coverage; check script should accept both.
   Close-path field: **Tests** (suite scripts); legacy **Proven by** is read-only.

---

## Legend

| Code | Stage / state |
|------|----------------|
| `BL` backlog | not vetted; never auto-lift |
| `NX` next READY | in sprint, runnable if deps clear |
| `NU` next unstamped | work skips (no READY) |
| `DO` doing incomplete | orphan / mid-session |
| `DC` doing + ## Completed | finished but not routed |
| `DF` doing + fail residue | hard fail left in doing/ |
| `BK` blocked | decision / incomplete route |
| `RV` review | prereq satisfied for dependents |
| `DN` done | prereq satisfied |
| `MS` missing | no file in any stage |
| `FD` folded | gone or stamped Folded into |
| `SP` split | parent deleted; children remain |
| `1W` one-way edge | Depends without reverse Blocks |
| `CY` cycle | A↔B |
| `PL` plan drift | Plan field ↔ plan member list disagree |

---

## Case catalog

### A — Healthy baselines

| ID | Case | Stage | Depends on | Blocks / Dependents | Expected when a next/ task depends on this |
|----|------|-------|------------|---------------------|-----------------------------------------------|
| 9001 | Healthy done prereq | DN | none | 9050 | **met** — dependent runnable |
| 9002 | Healthy review prereq (has `**Proof**:` line) | RV | none | 9050 | **met** — landed, dependent runnable |
| 9021 | Review prereq without proof | RV | none | 9090 | **hold** — "in review, unproven" + promote/proof note |
| 9003 | Peer in next READY | NX | none | 9051 | **wait** then run 9003 first in same pass |
| 9004 | Peer in next unstamped | NU | none | 9052 | **hold** + gate/chat 9004 (not READY) |

### B — doing/ orphans (work session glitches)

| ID | Case | Stage | Notes | Expected |
|----|------|-------|-------|----------|
| 9005 | Completed orphan | DC | has `## Completed`, still in doing/ | **auto-route → review/** then release dependents |
| 9006 | Incomplete orphan | DO | no Completed; mid-work | **resume this run** (re-run in place) |
| 9007 | Hard-fail residue | DF | no Completed; log pointer in Outcome | **resume or surface Outcome**; do not treat as met |
| 9032 | Incomplete → blocked | BK | routed incomplete, Outcome stamp | **hold** + chat 9032; show Outcome reason |
| 9033 | Crash left in doing | DO | partial edit note only | **resume**; no false complete |

### C — backlog / never lifted / pushed back

| ID | Case | Stage | Notes | Expected |
|----|------|-------|-------|----------|
| 9009 | Never promoted | BL | dependents in next/ | **hold** + `chat 9009`; never auto-lift |
| 9030 | Pushed back to backlog | BL | once had next/ dependents; demoted | **hold** + chat; Dependents still list next/ waiters |
| 9031 | Never lifted with dependents | BL | Blocks lists next/ canaries | same as 9009; reciprocal edge must remain |

### D — blocked /

| ID | Case | Notes | Expected |
|----|------|-------|----------|
| 9008 | Decision blocked | Status BLOCKED + Questions | hold + `chat 9008` |
| 9032 | Incomplete blocked | Outcome incomplete | hold + show Outcome |

### E — fold / remove / ID rewrite failures

| ID | Case | On disk | Dependents still say | Expected |
|----|------|---------|----------------------|----------|
| 9010 | Pure dangling | **MS** | 9055 depends on 9010 | **broken edge** — not silent complete |
| 9011 | Folded into 9012 | FD note file *or* absent | 9056 still Depends on 9011 | rewrite → 9012 **or** classify folded-into-9012 |
| 9012 | Fold survivor | NX READY | should absorb 9011’s dependents | Blocks includes former 9011 waiters after rewrite |
| 9041 | Chat “removed” prereq | MS | 9057 depends on 9041 | broken edge; offer drop only after edge audit |
| 9042 | Replaced by higher id | MS (was 9042) | 9058 still on 9042; work is 9043 | fold rewrite 9042→9043 |

### F — split; parent deleted mid-chat

| ID | Case | On disk | Expected |
|----|------|---------|----------|
| 9013 | Split parent deleted | MS | dependents on 9013 are **broken** until rewrite to 9014/9015 |
| 9014 | Split child A | NX | inherits slice of work; should list Dependents that used to wait on 9013 |
| 9015 | Split child B | BL | not promoted; if rewrite pointed here, hold + chat |
| 9059 | Still depends on deleted parent 9013 | NX | **must** flag broken; protocol: rewrite to 9014+9015 or one survivor |

### G — reciprocity & malformed metadata

| ID | Case | Expected |
|----|------|----------|
| 9016 | Depends on 9017; 9017 omits 9016 in Blocks | one-way finding; auto-fix on touch |
| 9017 | Missing reverse for 9016 | add 9016 to Dependents/Blocks |
| 9018+9019 | Cycle 9018↔9019 both next | cycle finding; work must not infinite-loop (neither runnable) |
| 9020 | Self-depends | treat as no-op or integrity error; not a real hold on others |
| 9036 | Malformed Depends tokens (`house`, `(hard)`) | validate warns; gating ignores bad tokens |
| 9037 | Bad range `99-1` | bad token; no expand |
| 9038 | Hash style `#9002` | parse as 9002 (already supported) |

### H — multi-dep combinations (the real matrix)

| ID | Canary (next READY) | Depends on | What the hold report must show |
|----|---------------------|------------|--------------------------------|
| 9050 | Healthy dual-met | 9001, 9002 | **runnable** (both review/done) |
| 9051 | Wait peer READY | 9003 | needs 9003 (next/ — runs when deps clear) |
| 9052 | Wait unstamped peer | 9004 | needs 9004 (next/ — not READY; chat/gate) |
| 9053 | Wait completed orphan | 9005 | auto-route 9005 then run |
| 9054 | Wait incomplete orphan | 9006 | resume 9006 then run |
| 9055 | Dangling missing | 9010 | broken / missing — not green |
| 9056 | Stale fold id | 9011 | folded→9012 or broken |
| 9057 | Chat-removed | 9041 | broken |
| 9058 | Replaced id | 9042 | rewrite to 9043 |
| 9059 | Split parent gone | 9013 | broken; children 9014/9015 exist |
| 9060 | Backlog never lifted | 9009 | chat 9009 |
| 9061 | Pushed-back prereq | 9030 | chat 9030 |
| 9062 | Blocked decision | 9008 | chat 9008 |
| 9063 | Incomplete blocked | 9032 | chat 9032 + Outcome |
| 9064 | Hard-fail doing | 9007 | resume/surface fail |
| 9065 | Mixed: met + backlog | 9001, 9009 | partial: still hold on 9009 |
| 9066 | Mixed: review + doing-complete | 9002, 9005 | route 9005; then runnable |
| 9067 | Mixed: next + missing | 9003, 9010 | hold both classes |
| 9068 | Chain tip (C) | 9069 | wait mid-chain |
| 9069 | Chain mid (B) | 9070 | wait root |
| 9070 | Chain root incomplete doing | — (DO) | resume first |
| 9071 | Diamond left | 9073 | wait shared root |
| 9072 | Diamond right | 9073 | wait shared root |
| 9073 | Diamond root backlog | BL | chat; both diamonds hold |
| 9074 | Range expand | 9001-9003 | 9001 met, 9002 met, 9003 wait |
| 9075 | One-way edge victim | 9017 | runs only if 9017 complete; reciprocity finding |
| 9076 | Cycle participant | 9018 | not runnable (cycle) |
| 9077 | Multi-hop + fold stale | 9011, 9006 | both classes |
| 9078 | Dependents exist; prereq demoted | 9031 | chat 9031; 9031 Blocks includes 9078 |
| 9079 | Plan field wrong | 9002 | runnable but PL mismatch finding |
| 9080 | Umbrella canary | *many* (see seed) | one-shot stress: every class of hold at once |

### I — plan membership drift

| ID | Case | Expected |
|----|------|----------|
| 9081 | Plan lists 9081; task Plan: none | sync Plan: 90 (synthetic plan id) |
| 9082 | Task Plan: 90; plan omits 9082 | drop Plan or add to plan |
| 9083 | Task Plan: 99 (no such plan) | broken plan pointer |

### J — split children without rewrite (chat session residue)

| ID | Case | Expected |
|----|------|----------|
| 9014 / 9015 | Children exist | healthy tasks |
| 9059 | Still points at 9013 | must not silently complete |

### K — Outcome / failure stamps (product target)

| ID | Stamp | Expected dependents messaging |
|----|-------|-------------------------------|
| 9007 | Result failed | needs 9007 (doing/ — failed: …) |
| 9032 | Result incomplete | needs 9032 (blocked/ — incomplete: …) |

### L — Other glitches

| ID | Case | Expected |
|----|------|----------|
| 9084 | Empty Depends on field vs `none` | both mean no deps |
| 9085 | Depends on done task only | runnable |
| 9090 | Depends on 9021 (review/, no proof) | **hold** — in review, unproven |
| 9086 | Blocks lists missing id 9199 | reverse dangling finding |
| 9087 | Parent: 9198 missing | orphaned parent finding |
| 9088 | Duplicate id files (if seeded conflict) | validate fail — seed avoids true dupes |
| 9089 | READY stamp but open ## Questions | integrity: not actually ready |

---

## Umbrella canary (9080)

`9080` Depends on a **superset** of glitch classes so a single work prepass
prints a dense, realistic hold report:

- met: 9001, 9002  
- next READY: 9003  
- next unstamped: 9004  
- doing complete: 9005  
- doing incomplete: 9006  
- fail doing: 9007  
- blocked: 9008  
- backlog: 9009, 9030  
- missing: 9010  
- fold stale: 9011  
- split parent: 9013  
- chain: 9069 (which needs 9070)  

After Plan 15, every line should name **stage + action** (route / resume /
chat / broken / folded-into).

---

## How this maps to Plan 15 tasks

| Plan task | Matrix slices |
|-----------|----------------|
| #327 headers | Blocks vs Dependents; Plan field cases I |
| #328 helpers | classify every code in Legend |
| #329 fold/split rewrite | E, F, J |
| #330 work path | B, C, D, H, K, umbrella |
| #331 plan sync | I |
| #332 tests | seed + check-inventory + future asserts |

---

## Non-goals of this fixture

- Live AI runs (no tokens).  
- Mutating the real `docs/tasks/` board (IDs 9000+ only inside fixture).  
- Claiming current `work` already implements every Expected cell.
