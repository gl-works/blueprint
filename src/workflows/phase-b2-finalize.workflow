# Phase B2: Finalize Design Artifacts

> IRON LAWS (applicable to this phase):
> #2: NO NEW TYPE OUTSIDE .blueprint/<topic>/types.md
> #3: NO NEW INTERFACE WITHOUT .blueprint/<topic>/contracts.md SPEC

---

Read the current state from `.session.md` before starting. The orchestrator has written gap decisions and invariant confirmations.

### B6: Finalize design.md

Write `.blueprint/$TOPIC/design.md` — combine the original design content with the confirmed invariants and decisions.

Structure of the output file:
```
[original design.md content — read from .blueprint/$TOPIC/design.md if written,
 or read from the source design.md path recorded in .session.md]

## Invariant List
I1: ... (source: user|inferred|codebase)
I2: ... (source: user|inferred|codebase)

## Decisions Record
- Q1: [question] → [answer]

## Gap Resolution
- P0 resolved: [list]
- P1 deferred: [list]
```

### B7: Write .meta.json

Read decisions from `.session.md` and write `.blueprint/$TOPIC/.meta.json`:
```json
{
  "topic": "$TOPIC",
  "created_at": "<ISO timestamp>",
  "phase_b_completed_at": "<ISO timestamp>",
  "sources": {
    "invariants": [
      { "id": "I1", "text": "...", "source": "user|inferred|codebase" }
    ],
    "decisions": [ { "question": "...", "answer": "..." } ]
  },
  "gap_resolution": { "resolved": [], "deferred": [] }
}
```

### B8: Update state

Write to `.session.md`:
```markdown
## Progress
- stage: Phase C (Stage 1 — Data Blueprint)
- status: pending
## Completed
- [x] Phase B: Kickoff
```

Display:
```
◆ Phase B complete: [N] invariants, [M] gaps resolved, [K] deferred

  ╭──────────────────────────────────────────────────────╮
  │                                                      │
  │  ☕  Phase B done — sit back and relax.               │
  │     Phase C (design automation) + Phase D (coding)   │
  │     run fully automated from here.                   │
  │     I'll only interrupt if your input is needed      │
  │     on a design decision.                            │
  │                                                      │
  ╰──────────────────────────────────────────────────────╯

◆ Entering Phase C — Blueprint Automation...
```
