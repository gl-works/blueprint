# Phase C: Blueprint Automation

> IRON LAWS (applicable to this phase):
> #2: NO NEW TYPE OUTSIDE .blueprint/<topic>/types.md — enforced by Stage 1 gate
> #3: NO NEW INTERFACE WITHOUT .blueprint/<topic>/contracts.md SPEC — enforced by Stage 2 gate

**Available agent types for task() calls in this phase:**
- oracle — Read-only high-IQ reasoning consultant. Use for architecture/debugging decisions.
- explore — Contextual grep for codebase searches.
- librarian — External reference search (docs, OSS examples).

**Task category mapping:**
- quick — Pure mechanical matching (cross-file consistency checks)
- deep — Depth analysis: type derivation, module contracts, lifecycle, error protocols, test property generation, business review
- ultrabrain — Multi-perspective judgment: security/perf/arch reviews, roleplay walkthrough, consolidator

**Context variables available:** TOPIC, BLUEPRINT_DIR, FROM_STAGE, DESIGN_ONLY

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
**Category:** `deep`

**Step 1.1: Invariant feasibility check**
Check invariants affecting type decisions. Report if any may be infeasible.

**Step 1.2: Execute subagent**

```
task(
  category="deep",
  load_skills=[],
  description="Generate types.md for $TOPIC",
  prompt="
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
"
)
```

Wait for result. Verify `.blueprint/$TOPIC/types.md` exists and has content.

**Step 1.3: Stage gate**
Self-review (match entities). Auto-verify: no duplicate types in file.

**Step 1.4: Update state**
```markdown
## Completed
- [x] Stage 1: Data Blueprint
```

**Step 1.5: Trigger 工序 A (test property generation)**
```
task(
  category="deep",
  load_skills=[],
  description="Generate test-properties.md for $TOPIC",
  prompt="
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
"
)
```

### Stage 2: Module Contracts → contracts.md

**Input:** design.md + types.md + invariants
**Category:** `deep`

**Step 2.0: Dependency check**
If `.blueprint/$TOPIC/types.md` missing → abort: "Stage 2 depends on Stage 1."

**Step 2.1: Invariant feasibility check**

**Step 2.2: Execute subagent**

```
task(
  category="deep",
  load_skills=[],
  description="Generate contracts.md for $TOPIC",
  prompt="
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
"
)
```

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
**Category:** `deep`

**Step 3.0: Dependency check**
Requires types.md AND contracts.md.

**Step 3.1: Invariant feasibility check**

**Step 3.2: Execute subagent**

```
task(
  category="deep",
  load_skills=[],
  description="Generate lifecycle.md for $TOPIC",
  prompt="
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
"
)
```

**Step 3.3: Stage gate**

**Step 3.4: Update state**
```markdown
## Completed
- [x] Stage 1: Data Blueprint
- [x] Stage 2: Module Contracts
- [x] Stage 3: Lifecycle Map
```

**Step 3.5: Trigger 工序 B (test coverage matrix)**

```
task(
  category="deep",
  load_skills=[],
  description="Generate test-coverage.md for $TOPIC",
  prompt="
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
"
)
```

### Stage 4: Error Contract → errors.md

**Input:** lifecycle.md + types.md + invariants
**Category:** `deep`

**Step 4.0: Dependency check**
Requires types.md AND lifecycle.md.

**Step 4.1: Invariant feasibility check**
Error-related invariants are especially likely to be infeasible (e.g., "all errors bilingual"). Pay extra attention.

**Step 4.2: Execute subagent**

```
task(
  category="deep",
  load_skills=[],
  description="Generate errors.md for $TOPIC",
  prompt="
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
"
)
```

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
◆ Starting multi-perspective reviews...
```

### Phase C — Multi-Perspective Parallel Reviews

**Batch 1 — Run ALL four in parallel:**

```
task(
  category="ultrabrain",
  run_in_background=true,
  load_skills=[],
  description="Security review for $TOPIC",
  prompt="
You are reviewing a Blueprint design. DO NOT take their word. READ the artifacts.

READ: .blueprint/$TOPIC/types.md, .blueprint/$TOPIC/errors.md

CHECK:
1. Sensitive data exposure — secrets, tokens, PII in types?
2. Input validation — external inputs validated?
3. Information leakage — do error messages leak internals?
4. Auth/authorization — mentioned when it should be?

OUTPUT TWO FILES:
- Details: .blueprint/$TOPIC/reviews/review-security.md (full reasoning)
- Summary: .blueprint/$TOPIC/reviews/review-security-summary.md
  ## blocking: true/false
  ## severity: critical/major/minor
  ## affects_stage: 1/2/3/4
  ## finding_count: N
  ## summary: one-line conclusion
"
)

task(
  category="ultrabrain",
  run_in_background=true,
  load_skills=[],
  description="Performance review for $TOPIC",
  prompt="
You are reviewing a Blueprint design. READ the artifacts.

READ: .blueprint/$TOPIC/contracts.md, .blueprint/$TOPIC/lifecycle.md

CHECK:
1. Sync blocking in async paths?
2. Connection reuse (db/network pooling)?
3. Large object passing — unnecessary copying?
4. Hot path — unnecessary allocation?

OUTPUT TWO FILES: review-perf.md + review-perf-summary.md (same summary format)
"
)

task(
  category="ultrabrain",
  run_in_background=true,
  load_skills=[],
  description="Architecture review for $TOPIC",
  prompt="
You are reviewing a Blueprint design. READ the artifacts.

READ: .blueprint/$TOPIC/contracts.md, .blueprint/$TOPIC/lifecycle.md

CHECK:
1. Circular dependencies?
2. Interface abstraction level — right granularity?
3. Module cohesion — single responsibility?
4. Extensibility — adding feature changes how many modules?

OUTPUT TWO FILES: review-arch.md + review-arch-summary.md
"
)

task(
  category="deep",
  run_in_background=true,
  load_skills=[],
  description="Business review for $TOPIC",
  prompt="
You are reviewing a Blueprint design. READ the artifacts.

READ: .blueprint/$TOPIC/design.md, .blueprint/$TOPIC/lifecycle.md

CHECK:
1. Requirements coverage — every scenario has a flow?
2. Missing scenarios — obvious user story not covered?
3. Error message readability — comprehensible to end users?
4. Scope fidelity — nothing beyond what was asked?

OUTPUT TWO FILES: review-business.md + review-business-summary.md
"
)
```

Collect all 4 results. If any failed, retry once.

Generate batch 1 summary by concatenating all `*-summary.md` content.

**Batch 2 — Run both in parallel:**

```
task(
  category="ultrabrain",
  run_in_background=true,
  load_skills=[],
  description="Roleplay walkthrough for $TOPIC",
  prompt="
You are reviewing by roleplaying personas. READ all artifacts.

READ from .blueprint/$TOPIC/:
- types.md, contracts.md, lifecycle.md, errors.md
- reviews/*-summary.md (batch 1)

Walk through same scenario from THREE personas:
- reviewer-junior: 'Can I understand from docs alone?'
- reviewer-ops: 'Where are logs? How to debug failures?'
- reviewer-user: 'Output file overwritten without warning?'

OUTPUT: review-roleplay.md + review-roleplay-summary.md
"
)

task(
  category="quick",
  run_in_background=true,
  load_skills=[],
  description="Consistency check for $TOPIC",
  prompt="
MECHANICAL CROSS-FILE CHECK. Read ALL from .blueprint/$TOPIC/.

CHECKLIST:
☐ lifecycle.md references only types defined in types.md
☐ errors.md covers every error branch in lifecycle.md
☐ contracts.md uses only types from types.md
☐ contracts.md function params have input sources in lifecycle.md
☐ Every type in types.md referenced by >= 1 other artifact

For each FAIL: file, line, description.

OUTPUT: .blueprint/$TOPIC/reviews/review-consistency.md
"
)
```

Collect both results.

### Phase C — Consolidator + Final Report

**Execute consolidator:**

```
task(
  category="ultrabrain",
  load_skills=[],
  description="Consolidate reviews for $TOPIC",
  prompt="
You are the CONSOLIDATOR. Read ALL review summaries from .blueprint/$TOPIC/reviews/*-summary.md.
DO NOT read full review files — summaries only.

CONFLICT RESOLUTION:
1. Security (critical) > any other perspective
2. Architecture vs business → architecture wins
3. Testability vs performance → testability wins
4. Same-level non-blocking → you decide

BLOCKING RULES (automatic):
1. Security critical → BLOCKING
2. Any review summary has `blocking: true` → BLOCKING
3. Any invariant violation found → BLOCKING
4. Circular dependency found → BLOCKING
5. Two+ reviewers disagree → only BLOCKING if both flagged blocking

OUTPUT: .blueprint/$TOPIC/reviews/final-report.md

Status: READY FOR CODING | BLOCKED

Scope:
  In Scope: [...]
  Out of Scope: [...]
  Deferred: [...]

Artifacts:
  types.md       ✅ N types
  contracts.md   ✅ N interfaces
  lifecycle.md   ✅ N branches, all terminated
  errors.md     ✅ N error types
  test-properties.md ✅ N conditions
  test-coverage.md   ✅ N items

Reviews:
  Security      ✅ Pass (0 blocking)
  Performance   ✅ Pass
  Architecture  ✅ Pass
  Business      ⚠️ N minor
  Roleplay      ✅ Pass
  Consistency   ✅ Pass

Decisions:
  [conflict resolution records]

Invariant Disputes:
  I3 | Retained | Kept as-is
"
)
```

Wait for consolidator result.

**Create .gate-passed:**
If final report status is "READY FOR CODING" → create `.blueprint/$TOPIC/.gate-passed` (empty file).
If "BLOCKED" → do NOT create gate. Warn: "BLOCKED. Fix issues, re-run with --from-stage=4."

**Display final summary:**
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  BLUEPRINT COMPLETE :: $TOPIC
┃  Status: READY FOR CODING
┃  Artifacts: 6 files, N reviews
┃  Gate: .gate-passed created
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

**If `$DESIGN_ONLY=true`:** workflow ends here. Display "Design-only — Phase D skipped."

**Update .session.md:**
```markdown
## Progress
- stage: Phase C (Complete)
- status: completed
## Completed
- [x] Phase B: Kickoff
- [x] Stage 1: Data Blueprint
- [x] 工序 A: Test Properties
- [x] Stage 2: Module Contracts
- [x] Stage 3: Lifecycle Map
- [x] 工序 B: Test Coverage
- [x] Stage 4: Error Contract
- [x] Reviews (Batch 1 + Batch 2)
- [x] Consolidator + Final Report
- [ ] Phase D: Constraint Coding
## Gate
- gate-passed: ✓
```
