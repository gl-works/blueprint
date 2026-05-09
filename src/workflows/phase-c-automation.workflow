# Phase C: Blueprint Automation

> IRON LAWS (applicable to this phase):
> #2: NO NEW TYPE OUTSIDE .blueprint/<topic>/types.md — enforced by Stage 1 gate
> #3: NO NEW INTERFACE WITHOUT .blueprint/<topic>/contracts.md SPEC — enforced by Stage 2 gate

**Context variables available:** TOPIC, BLUEPRINT_DIR, FROM_STAGE, DESIGN_ONLY

> This phase runs as a delegated sub-agent. Stages are executed inline (no nested sub-agents).
> Reviews have been moved to orchestrator level — they run after this sub-agent completes.

---

### Phase C Rules (all stages)

**Invariant Feasibility Check** — before each stage:
1. List invariants affected by this stage.
2. Can all be achieved given current design.md and artifacts?
3. ALL feasible → proceed.
4. ANY infeasible → PAUSE. Present options to user (keep/downgrade/remove). Record decision.

**Stage Gate** — after each stage:
1. Self-review (listed in stage).
2. Auto-verification (listed in stage).
3. Gate fails → retry once. Fails again → escalate Level 3 (pause, user decides).

**State Update** — after each stage:
1. Write artifacts first.
2. THEN update `.session.md`.
3. Never update state before artifact write.

### Stage 1: Data Blueprint → types.md

**Input:** design.md + invariant list

**Step 1.1: Invariant feasibility check**
Check invariants affecting type decisions. Report if any may be infeasible.

**Step 1.2: Generate types.md**

TASK: Produce types.md — all core data types for the $TOPIC feature in one file.

INPUT (design.md):
--- content of .blueprint/$TOPIC/design.md ---

INVARIANTS:
--- confirmed invariant list ---

FORMAT: Use the project's language syntax (from existing code) or language-agnostic.
Mark new with '// NEW'. Modified with '// MODIFIED' + old→new.

REQUIREMENTS:
1. Every entity in design.md gets a type definition.
2. Every relationship (containment, reference) is explicit.
3. No ambiguous field types — concrete types only.
4. Consider: inputs, outputs, config, errors.
5. All enum variants listed. All struct fields listed.
6. Naming matches design.md and invariants.

SELF-REVIEW:
- All type names consistent with design.md?
- No unreasonable defaults?
- Every entity covered?
- Any types that could be shared/merged?

OUTPUT: .blueprint/$TOPIC/types.md

AUTO-VERIFICATION: No duplicate type definitions. Every referenced type exists.

Write `.blueprint/$TOPIC/types.md` and verify it exists and has content.

**Step 1.3: Stage gate**
Self-review (match entities). Auto-verify: no duplicate types in file.

**Step 1.4: Update state**
```markdown
## Completed
- [x] Stage 1: Data Blueprint
```

**Step 1.5: Trigger 工序 A (test property generation)**

TASK: From types.md, reverse-infer boundary conditions. Write as checkbox list with P0/P1/P2.

INPUT: Read .blueprint/$TOPIC/types.md

FORMAT (test-properties.md):
# Test Properties — $TOPIC
## <TypeName>
- [ ] P0: <boundary condition>
- [ ] P1: <edge case>
...

PRIORITY:
- P0: Invalid/empty inputs, type bounds, missing required fields. MUST test.
- P1: Edge cases, unusual but valid inputs. SHOULD test.
- P2: Concurrency, resource exhaustion, rare paths. NICE to test.

OUTPUT: .blueprint/$TOPIC/test-properties.md

Write `.blueprint/$TOPIC/test-properties.md` and verify it exists.

### Stage 2: Module Contracts → contracts.md

**Input:** design.md + types.md + invariants

**Step 2.0: Dependency check**
If `.blueprint/$TOPIC/types.md` missing → abort: "Stage 2 depends on Stage 1."

**Step 2.1: Invariant feasibility check**

**Step 2.2: Generate contracts.md**

TASK: Define module boundaries and interface signatures for the $TOPIC feature.

INPUT: Read design.md from .blueprint/$TOPIC/design.md
TYPES: Read .blueprint/$TOPIC/types.md
INVARIANTS: from design.md Invariant List

REQUIREMENTS:
1. One interface/trait per module boundary from design.md.
2. All function signatures use types from types.md. No inline types.
3. Each function: name, parameters (with types), return type, description.
4. No circular dependencies between modules.
5. Mark new with // NEW. Modified with // MODIFIED.
6. Distinguish sync vs async.

SELF-REVIEW:
- Every parameter type exists in types.md?
- No circular dependencies?
- Every interface maps to a design.md module?

AUTO-VERIFICATION: All types in signatures exist in types.md. No circular refs.

OUTPUT: .blueprint/$TOPIC/contracts.md

Write `.blueprint/$TOPIC/contracts.md` and verify it exists.

**Step 2.3: Stage gate**
Self-review + auto-verification.

**Step 2.4: Update state**
```markdown
## Completed
- [x] Stage 1: Data Blueprint
- [x] Stage 2: Module Contracts
```

### Stage 3: Lifecycle Map → lifecycle.md

**Input:** design.md + contracts.md + types.md + invariants

**Step 3.0: Dependency check**
Requires types.md AND contracts.md.

**Step 3.1: Invariant feasibility check**

**Step 3.2: Generate lifecycle.md**

TASK: Draw core data flow for $TOPIC, including ALL branch points.

INPUT: Read design.md, contracts.md, types.md from .blueprint/$TOPIC/

REQUIREMENTS:
1. Flow from entry point to all terminal states.
2. Every branch point explicit (success, error, edge case).
3. Every branch reaches a terminal state (exit, return, error).
4. ASCII flow diagrams. Show main flow, error flows, edge cases.

SELF-REVIEW:
- Every branch reaches terminal state?
- All referenced functions exist in contracts.md?
- No unreachable paths?

AUTO-VERIFICATION: Every branch point should have corresponding error rule (checked in Stage 4).

OUTPUT: .blueprint/$TOPIC/lifecycle.md

Write `.blueprint/$TOPIC/lifecycle.md` and verify it exists.

**Step 3.3: Stage gate**

**Step 3.4: Update state**
```markdown
## Completed
- [x] Stage 1: Data Blueprint
- [x] Stage 2: Module Contracts
- [x] Stage 3: Lifecycle Map
```

**Step 3.5: Trigger 工序 B (test coverage matrix)**

TASK: From lifecycle.md, enumerate ALL branch paths as test coverage checklist.

INPUT: Read .blueprint/$TOPIC/lifecycle.md

FORMAT (test-coverage.md):
# Test Coverage — $TOPIC
## Normal Paths
- [ ] P0: <happy path>
## Error Paths
- [ ] P0: <error path>
## Edge Cases
- [ ] P1: <edge case>
## Rare Paths
- [ ] P2: <rare scenario>

OUTPUT: .blueprint/$TOPIC/test-coverage.md

Write `.blueprint/$TOPIC/test-coverage.md` and verify it exists.

### Stage 4: Error Contract → errors.md

**Input:** lifecycle.md + types.md + invariants

**Step 4.0: Dependency check**
Requires types.md AND lifecycle.md.

**Step 4.1: Invariant feasibility check**
Error-related invariants are especially likely to be infeasible (e.g., "all errors bilingual"). Pay extra attention.

**Step 4.2: Generate errors.md**

TASK: Define error types, propagation rules, retry policies, and user-facing messages.

INPUT: Read lifecycle.md and types.md from .blueprint/$TOPIC/

REQUIREMENTS:
1. Every error branch in lifecycle.md has a rule.
2. Each rule: error name, retry policy, user message, severity.
3. List forbidden patterns (unwrap/expect in non-test code, etc.).
4. Structured format (YAML or structured markdown).

SELF-REVIEW:
- All lifecycle error branches covered?
- No orphan rules?
- User messages are user-comprehensible?

AUTO-VERIFICATION: Every error branch in lifecycle.md has matching rule in errors.md.
Error types exist in types.md or existing codebase.

OUTPUT: .blueprint/$TOPIC/errors.md

Write `.blueprint/$TOPIC/errors.md` and verify it exists.

**Step 4.3: Stage gate**

**Step 4.4: Update state**
```markdown
## Completed
- [x] Stage 1: Data Blueprint
- [x] Stage 2: Module Contracts
- [x] Stage 3: Lifecycle Map
- [x] Stage 4: Error Contract
- [x] 工序 A: Test Properties
- [x] 工序 B: Test Coverage
```

Display:
```
◆ Phase C artifacts complete (4/4 stages + 2 procedures)
◆ Phase C stages done — orchestrator will run multi-perspective reviews next.
```
