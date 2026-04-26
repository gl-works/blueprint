<purpose>
Design-first engineering pipeline. Before writing any code, produce formalized types, interface contracts, lifecycle maps, and error contracts — then run multi-perspective reviews across those artifacts. After blueprint passes, encode under its constraints with TDD (RED→GREEN→REFACTOR).

This workflow implements the full pipeline:
- Phase B: Kickoff — completeness check + gap-filling + invariant confirmation
- Phase C: Blueprint Automation — 4 stages + 2 procedures + 7 reviews + consolidator
- Phase D: Constraint Coding — TDD loops under blueprint constraints

The orchestrator (Sisyphus) executes this workflow step by step.
</purpose>

<available_agent_types>
Valid subagent types for task() calls in this workflow:
- oracle — Read-only high-IQ reasoning consultant. Use for architecture/debugging decisions.
- explore — Contextual grep for codebase searches.
- librarian — External reference search (docs, OSS examples).
</available_agent_types>

<category_mapping>
Task category choices used in this workflow:
- quick — Pure mechanical matching (cross-file consistency checks)
- deep — Depth analysis: type derivation, module contracts, lifecycle, error protocols, test property generation, business review
- ultrabrain — Multi-perspective judgment: security/perf/arch reviews, roleplay walkthrough, consolidator
</category_mapping>

<terminology>
- TOPIC: User-provided blueprint name (e.g., "core-routing", "oauth-auth")
- BLUEPRINT_DIR: `blueprint/<TOPIC>/` relative to project root
- REVIEWS_DIR: `blueprint/<TOPIC>/reviews/`
- design.md: Input design document (in project root or specified path)
- .session.md: Session state file tracking current progress
- .meta.json: Blueprint metadata (scope, decisions, timestamps)
- .gate-passed: Sentinel file — exists = blueprint passed = can proceed to coding
</terminology>

<iron_laws>
These are non-negotiable. Violation = workflow failure.

IRON LAW #1: NO NEW CODE BEFORE BLUEPRINT COMPLETE (.gate-passed created)
IRON LAW #2: NO NEW TYPE FOR THIS FEATURE OUTSIDE blueprint/<topic>/types.md
IRON LAW #3: NO NEW INTERFACE WITHOUT blueprint/<topic>/contracts.md SPEC
IRON LAW #4: NO COMPLETION CLAIM WITHOUT FRESH VERIFICATION EVIDENCE
IRON LAW #5: NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
IRON LAW #6: NO TEST MODIFIED TO PASS. ONLY CODE OR BLUEPRINT.
</iron_laws>

<process>

<!-- ============================================================ -->
<!-- PROLOGUE: Parse arguments and setup                           -->
<!-- ============================================================ -->
## PROLOGUE

### Step 0: Parse arguments + auto-detect topic

From $ARGUMENTS, extract:
- `$DESIGN_ONLY` = true if `--design-only` present
- `$FROM_STAGE` = N if `--from-stage N` present (valid: 1, 2, 3, 4)

Validate `$FROM_STAGE` must be 1-4 if provided.

**Auto-detect `$TOPIC`:**

A. If `--from-stage` is set and exactly one subdirectory exists under `blueprint/`:
   → `$TOPIC` = that directory name (resuming existing blueprint)

B. If `--from-stage` is set and multiple subdirectories under `blueprint/`:
   → Prompt: "Multiple blueprints found. Which one to resume?"
   ```
   question(
     header: "Select blueprint",
     question: "Which blueprint do you want to resume?",
     options: [list each subdirectory as option]
   )
   ```
   → `$TOPIC` = user selection

C. If neither A nor B (new run):
   → Prompt once for topic name:
   ```
   question(
     header: "Blueprint topic",
     question: "What is this blueprint about? (short name, e.g. core-routing, oauth-auth)",
     followUp: null
   )
   ```
   → `$TOPIC` = sanitized user input (lowercase, replace spaces with hyphens, strip special chars)

Validate `$TOPIC` is non-empty and safe for directory names. If not, re-prompt.

Show banner:
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  BLUEPRINT :: $TOPIC
┃  Design-first engineering pipeline
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

### Step 1: Find or create blueprint directory

```
BLUEPRINT_DIR = "blueprint/$TOPIC/"
REVIEWS_DIR   = "blueprint/$TOPIC/reviews/"
```

Check if `BLUEPRINT_DIR` already exists:
- If YES and `.session.md` exists → potential resume. Read `.session.md` to determine current stage. If `$FROM_STAGE` also provided, use the higher value (explicit override).
- If YES and `.session.md` does NOT exist → warn user, confirm overwrite.
- If NO → create `BLUEPRINT_DIR` and `REVIEWS_DIR`.

### Step 2: Initial state file

If `.session.md` does not exist (fresh start), write:

```markdown
# Session Blueprint Context

## Active Blueprint
- name: $TOPIC
- path: blueprint/$TOPIC/
- scope: (to be determined in Phase B)

## Progress
- stage: Phase B (Kickoff)
- status: in_progress

## Gate
- gate-passed: ✗
```

### Step 3: Find design.md

Search order (first match wins):
1. `design.md` in project root
2. `$TOPIC.md` in project root
3. `blueprint/$TOPIC/design.md` (if resuming)
4. Prompt user: "Where is your design document? Provide path or paste content."

If nothing found: show error "Blueprint requires a design document (design.md) as input. Write one first, then run /blueprint."

Read the found `design.md` and store its content. Keep it in context for the entire workflow.

<!-- ============================================================ -->
<!-- PHASE B: BLUEPRINT KICKOFF                                    -->
<!-- ============================================================ -->
## Phase B: Blueprint Kickoff

### B1: Update state
```markdown
## Progress
- stage: Phase B (Kickoff)
- status: in_progress
```

### B2: Existing code scan

If the project has existing source code:
1. Use `explore` agent to find:
   - Core type definitions (structs, enums, traits/interfaces)
   - Module/interface boundaries
   - Error handling patterns
2. Read 2-3 representative files to understand conventions:
   - Naming style, error handling approach, module organization
3. Extract 3-5 "code inheritance invariants" — critical conventions:
   - e.g., "All errors implement Error trait and provide user_message()"
   - e.g., "Modules follow src/<module>/ convention"
   - Add these to invariant list with `source: codebase`

If no existing code (greenfield): skip, report "Greenfield project — no code to analyze."

If previous blueprints exist in `blueprint/`:
1. List all subdirectories
2. Read each `design.md` for scope understanding
3. Check for entity/interface conflicts with current design
4. Report: "Existing blueprints found, no conflicts" or "Conflict detected: ..."

### B3: Completeness checklist

Check `design.md` against this checklist. Each item: YES/NO/PARTIAL.

**Entity check:**
- ☐ At least 3 core types/entities mentioned?
- ☐ Each entity has clear responsibility?
- ☐ Entity relationships clear? (containment, reference, independent)

**Module check:**
- ☐ At least 2 module boundaries identified?
- ☐ Each module has clear input/output?
- ☐ Module dependency relationships clear?

**Constraint check:**
- ☐ Tech stack determined (language, framework, database)?
- ☐ Deployment target determined (local/SaaS/self-hosted)?
- ☐ Performance requirements clear (latency, throughput)?
- ☐ Security constraints mentioned (auth, encryption)?

**Invariant check:**
- ☐ At least 3 design invariants?
- ☐ Each invariant mechanically verifiable?
- ☐ Has invariant declaring what NOT to do (scope boundary)?
- ☐ Any "reverse" invariants? (e.g., "no new dependencies")

**Ambiguity check:**
- ☐ Any descriptions interpretable two ways?
- ☐ Obvious omissions? (error handling, logging, configuration)

### B4: Invariant consistency check

Silently check all identified invariants for conflicts:
```
For each pair (Ix, Iy), check if both can be true simultaneously.
- Conflict → mark for user resolution
- No conflict → silent pass
```

### B5: Gap-filling questions

Based on NO/PARTIAL results, identify P0 gaps (entity, module, constraint, invariant).
P1 gaps = ambiguity.

Ask questions ONE AT A TIME, max 5 rounds. Each question:
1. Present gap: "I noticed [item] is [missing/incomplete]."
2. Offer 2-3 concrete options.
3. Wait for user response.

Example:
```
question(
  header: "Error handling strategy",
  question: "You didn't specify error handling for network failures. How should the system handle them?",
  options: [
    { label: "Auto-retry (3x, backoff)", description: "Exponential backoff, max 3 attempts" },
    { label: "Fail fast", description: "Return error immediately, let caller decide" },
    { label: "Caller decides", description: "Configurable retry policy per call site" }
  ]
)
```

After each answer, update `$GAP_DECISIONS` list.

After 5 rounds, any remaining P0 → escalate: "Unresolved P0 gaps. Recommended to address first. Continue anyway?"

### B6: Finalize design.md

Write `blueprint/$TOPIC/design.md` — combine the design content (already in your context from Step 3) with the appended sections below.

MANDATORY: Do NOT use the `read` tool to re-read the source design.md. The content is already in your context — use it directly.

Structure of the output file:
```
[original design.md content — from your context, do NOT re-read]

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

<!-- ============================================================ -->
<!-- PHASE C: BLUEPRINT AUTOMATION                                -->
<!-- ============================================================ -->
## Phase C: Blueprint Automation

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
--- content of blueprint/$TOPIC/design.md ---

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

OUTPUT: blueprint/$TOPIC/types.md

AUTO-VERIFICATION: No duplicate type definitions. Every referenced type exists.
"
)
```

Wait for result. Verify `blueprint/$TOPIC/types.md` exists and has content.

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

INPUT: Read blueprint/$TOPIC/types.md

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

EXAMPLE:
## Translator
- [ ] P0: input file path empty → reject
- [ ] P0: source_lang empty → reject
- [ ] P1: source_lang 'auto' → trigger auto-detection
- [ ] P2: concurrent calls — no field-level races

OUTPUT: blueprint/$TOPIC/test-properties.md
"
)
```

### Stage 2: Module Contracts → contracts.md

**Input:** design.md + types.md + invariants
**Category:** `deep`

**Step 2.0: Dependency check**
If `blueprint/$TOPIC/types.md` missing → abort: "Stage 2 depends on Stage 1."

**Step 2.1: Invariant feasibility check**

**Step 2.2: Execute subagent**

```
task(
  category="deep",
  load_skills=[],
  description="Generate contracts.md for $TOPIC",
  prompt="
TASK: Define module boundaries and interface signatures for the $TOPIC feature.

INPUT: Read design.md from blueprint/$TOPIC/design.md
TYPES: Read blueprint/$TOPIC/types.md
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

OUTPUT: blueprint/$TOPIC/contracts.md
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

INPUT: Read design.md, contracts.md, types.md from blueprint/$TOPIC/

REQUIREMENTS:
1. Flow from entry point to all terminal states.
2. Every branch point explicit (success, error, edge case).
3. Every branch reaches a terminal state (exit, return, error).
4. ASCII flow diagrams. Show main flow, error flows, edge cases.

FORMAT:
```
Input -> parse() -> Config
  | invalid -> print_help() -> exit(1)
  +- valid -> process()
  |   +- success -> output() -> exit(0)
  |   +- retryable -> retry(3) -> all fail -> error_exit()
  |   +- fatal -> error_exit()
```

SELF-REVIEW:
- Every branch reaches terminal state?
- All referenced functions exist in contracts.md?
- No unreachable paths?

AUTO-VERIFICATION: Every branch point should have corresponding error rule (checked in Stage 4).

OUTPUT: blueprint/$TOPIC/lifecycle.md
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

INPUT: Read blueprint/$TOPIC/lifecycle.md

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

PRIORITY:
- P0: Main flows + critical error paths. Must pass.
- P1: Secondary flows + edge cases. Should pass.
- P2: Unlikely scenarios. Nice to have.

OUTPUT: blueprint/$TOPIC/test-coverage.md
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

INPUT: Read lifecycle.md and types.md from blueprint/$TOPIC/

REQUIREMENTS:
1. Every error branch in lifecycle.md has a rule.
2. Each rule: error name, retry policy, user message, severity.
3. List forbidden patterns (unwrap/expect in non-test code, etc.).
4. Structured format (YAML or structured markdown).

FORMAT:
```yaml
rules:
  - error: FileNotFound
    retry: false
    severity: error
    user_message: 'File not found: {path}'
  - error: NetworkError
    retry: true
    retry_config: { max_attempts: 3, backoff: exponential }
    severity: error
    user_message: 'Network failed after {attempts} retries'
forbidden_patterns:
  - pattern: '.unwrap()'
    context: 'non-test code'
```

SELF-REVIEW:
- All lifecycle error branches covered?
- No orphan rules?
- User messages are user-comprehensible?

AUTO-VERIFICATION: Every error branch in lifecycle.md has matching rule in errors.md.
Error types exist in types.md or existing codebase.

OUTPUT: blueprint/$TOPIC/errors.md
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

READ: blueprint/$TOPIC/types.md, blueprint/$TOPIC/errors.md

CHECK:
1. Sensitive data exposure — secrets, tokens, PII in types?
2. Input validation — external inputs validated?
3. Information leakage — do error messages leak internals?
4. Auth/authorization — mentioned when it should be?

OUTPUT TWO FILES:
- Details: blueprint/$TOPIC/reviews/review-security.md (full reasoning)
- Summary: blueprint/$TOPIC/reviews/review-security-summary.md
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

READ: blueprint/$TOPIC/contracts.md, blueprint/$TOPIC/lifecycle.md

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

READ: blueprint/$TOPIC/contracts.md, blueprint/$TOPIC/lifecycle.md

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

READ: blueprint/$TOPIC/design.md, blueprint/$TOPIC/lifecycle.md

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

READ from blueprint/$TOPIC/:
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
MECHANICAL CROSS-FILE CHECK. Read ALL from blueprint/$TOPIC/.

CHECKLIST:
☐ lifecycle.md references only types defined in types.md
☐ errors.md covers every error branch in lifecycle.md
☐ contracts.md uses only types from types.md
☐ contracts.md function params have input sources in lifecycle.md
☐ Every type in types.md referenced by >= 1 other artifact

For each FAIL: file, line, description.

OUTPUT: blueprint/$TOPIC/reviews/review-consistency.md
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
You are the CONSOLIDATOR. Read ALL review summaries from blueprint/$TOPIC/reviews/*-summary.md.
DO NOT read full review files — summaries only.

CONFLICT RESOLUTION:
1. Security (critical) > any other perspective
2. Architecture vs business → architecture wins
3. Testability vs performance → testability wins
4. Same-level non-blocking → you decide

BLOCKING RULES (automatic):
1. Security critical → BLOCKING
2. Any invariant violation found → BLOCKING
3. Circular dependency found → BLOCKING
4. Two+ reviewers disagree → only BLOCKING if both flagged blocking

OUTPUT: blueprint/$TOPIC/reviews/final-report.md

# Blueprint Final Report: $TOPIC

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
If final report status is "READY FOR CODING" → create `blueprint/$TOPIC/.gate-passed` (empty file).
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

<!-- ============================================================ -->
<!-- PHASE D: CONSTRAINT CODING                                    -->
<!-- ============================================================ -->
## Phase D: Constraint Coding

### D0: Pre-flight checks

**Step D0.1: Verify .gate-passed**
If `blueprint/$TOPIC/.gate-passed` does NOT exist → abort with "Gate not passed. Complete Phase C first or re-run with --design-only."

**Step D0.2: Check test infrastructure (first time only)**
Detect project testing:
- Try: `cargo test --help`, `npm test --help`, `pytest --help`, `go test --help`
- Framework found → record command as `$TEST_CMD`
- No framework → install minimal test framework based on detected tech stack (Cargo.toml, package.json, requirements.txt, go.mod, etc.)

**Step D0.3: Read blueprint artifacts**
Read ALL from `blueprint/$TOPIC/`:
- types.md → import types, never recreate
- contracts.md → implement interfaces
- errors.md → follow error rules
- test-properties.md → checkboxes to satisfy
- test-coverage.md → checkboxes to satisfy

**Step D0.4: Identify modules to code**
From contracts.md, list modules/interfaces. Order by dependency (no circular deps — guaranteed by Stage 2).

### D1: TDD Loop

For each module (dependency order):

**Step D1.1: Select boundary condition**
Pick next unchecked item from test-properties.md or test-coverage.md for this module.
P0 first, then P1, then P2.

**Step D1.2: RED — Write failing test**
Write test for selected boundary condition.
Run `$TEST_CMD` — confirm FAILS.
If test passes without implementation → test is wrong. Fix test.

**Step D1.3: GREEN — Write minimal implementation**
Minimum code to pass test.
- Types from types.md (import, don't redefine).
- Interfaces from contracts.md (follow signatures).
- Errors from errors.md (follow rules).
- No extra abstractions.

Run `$TEST_CMD` — confirm PASSES.

**Step D1.4: REFACTOR — Clean up**
- Eliminate duplication from GREEN step.
- Simplify complex expressions.
- Clear naming.
- Behavior unchanged — tests still pass.

Run `$TEST_CMD` — all pass.
Run `lsp_diagnostics` on changed files — zero errors.

**Step D1.5: Check off item**
Mark `[x]` in test-properties.md or test-coverage.md.

**Step D1.6: Check exit gate for current module**
When ALL items for this module are checked:
- ☐ All P0 boundary conditions for module checked?
- ☐ All P0 coverage items for module checked?
- ☐ All new tests pass?
- ☐ No new failures in existing tests?
- ☐ All new types from types.md (none invented)?
- ☐ All edits traceable to requirements/blueprint?

Pass → next module. Fail → continue TDD loop.

**Failure handling:**

**故障 A: Test correct but fails (blueprint assumption wrong)**
1. Do NOT modify test to make it pass.
2. Update `blueprint/$TOPIC/types.md` (fix assumption).
3. Update `blueprint/$TOPIC/test-properties.md` (fix boundary if needed).
4. Commit with "blueprint-fix: $TOPIC: <description>".
5. Continue RED→GREEN.

**故障 B: Test coverage gate not met (missed paths)**
1. Add missing tests.
2. If new boundary conditions found, sync to test-properties.md.
3. Do NOT downgrade P0→P1.

**故障 C: Same failure after 2 retries**
1. Max 2 retries per issue.
2. After 2nd → escalate to user: "Tried [approach] twice, [failure]. Need your input."

### D2: Complete

When all modules pass exit gates:

**Update .session.md:**
```markdown
## Completed
- [x] All phases complete
## Gate
- gate-passed: ✓
```

**Final display:**
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  BLUEPRINT FULL COMPLETE :: $TOPIC
┃  ◆ All artifacts generated
┃  ◆ All reviews passed
┃  ◆ All modules coded under blueprint
┃  ◆ All tests passing
┃  ◆ Gate: passed
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

</process>

<success_criteria>
A blueprint run is successful when ALL of:
1. `blueprint/<TOPIC>/` exists with all 6 artifact files + reviews + .meta.json
2. (If not design-only) All modules coded, tests pass, diagnostics clean
3. (If not design-only) All P0 boundary conditions and coverage items checked
4. No IRON LAW violations
5. .gate-passed file exists (design-only: exists if reviews passed)

If BLOCKED: final-report.md explains what's blocking. No .gate-passed.
</success_criteria>

<session_recovery>
If interrupted mid-workflow:

1. Check `.session.md` in `blueprint/<TOPIC>/`.
2. Read to determine last completed stage.
3. Verify artifacts match state (Stage N done → artifact file must exist).
4. Consistent → resume from next step.
5. Inconsistent (state says done but file missing) → re-run from that stage.

Manual resume: `/blueprint --from-stage <N>`
</session_recovery>
