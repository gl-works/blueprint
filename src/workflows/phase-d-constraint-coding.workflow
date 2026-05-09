# Phase D: Constraint Coding — Pattern B Orchestrator Loop

> IRON LAWS (applicable to this phase):
> #1: NO NEW CODE BEFORE BLUEPRINT COMPLETE (.gate-passed created)
> #4: NO COMPLETION CLAIM WITHOUT FRESH VERIFICATION EVIDENCE
> #5'': NO PRODUCTION CODE WITHOUT SPEC-FIRST TEST (Iron Law #5'' — spec-first + mechanical deep checks)
> #6: NO TEST MODIFIED TO PASS. ONLY CODE OR BLUEPRINT.

**Context variables available:** TOPIC, BLUEPRINT_DIR, FROM_STAGE

---

> These instructions are self-executed by the orchestrator (not delegated to a sub-agent).
> The orchestrator runs an outer loop: Wave 0 scaffold → per-module tasks with retry → verification gates.
> This is **Pattern B** — orchestrator owns the loop, each module is an independent task().

---

## D0: Pre-flight Checks

### D0.1: Verify .gate-passed
If `.blueprint/$TOPIC/.gate-passed` does NOT exist → abort:
"Phase D requires .gate-passed. Run blueprint design phase first (/blueprint --design-only for design only)."

### D0.2: Check test infrastructure (first time only)
Detect project testing:
- Try: `cargo test --help`, `npm test`, `pytest --help`, `go test --help`
- Framework found → record command as `$TEST_CMD`
- No framework → install minimal test framework based on detected tech stack.

### D0.3: Read blueprint artifacts
Read ALL from `.blueprint/$TOPIC/`:
- types.md → import types, never recreate
- contracts.md → implement interfaces
- errors.md → follow error rules
- test-properties.md → P0/P1/P2 boundary conditions
- test-coverage.md → coverage matrix
- design.md → Invariant List for mechanical checks

### D0.4: Identify modules and assign categories
From contracts.md, list all modules/interfaces. Order by dependency.

For each module, determine test strategy:
- **Category A — Domain/business logic**: Unit TDD (spec-first, write test before code).
- **Category B — Integration/glue code**: Integration TDD (still requires failing test first).
- **Category C — Declarative/config**: Presence/load test only. Exempt from spec-first and assertion checks.

> There is NO "test-exempt" category. Every module requires tests at the appropriate level.

**State-machine / complex modules** (e.g. protocol.rs, ~500+ lines):
For modules with state transitions, complex branching, or high anchor-bias risk:
pre-split into two sequential tasks per module — (1) test-first: write all tests from
test-properties.md, (2) implement to pass. This avoids anchor bias where the
implementation contaminates test design. Mark these in the todo list as two entries:
  `[ ] <module_A> (tests)`
  `[ ] <module_A> (impl)`

### D0.5: Check for resume
If `.session.md` has Phase D Progress with `completed_modules`:
- Skip completed modules.
- Resume from the first uncompleted module.
- If all modules complete → skip to D2.

---

## Wave 0: Scaffold (single task)

Generate all shared interface files, type definitions, error types, module skeletons, and project config.

```
task(
  category="deep",
  load_skills=[],
  run_in_background=false,
  prompt="
TASK: Generate scaffold for $TOPIC feature.

CONTEXT:
- TOPIC: $TOPIC
- BLUEPRINT_DIR: $BLUEPRINT_DIR
- Read: types.md, contracts.md, errors.md from .blueprint/$TOPIC/

REQUIREMENTS:
1. Create all type definitions from types.md (data structures, enums, type aliases).
2. Create all interface/trait/abstract definitions from contracts.md (signatures only, no implementations).
3. Create all error types from errors.md.
4. Create module skeleton files (one per module directory, with interface stubs).
5. Create any needed project config (Cargo.toml, package.json, tsconfig.json, etc.).
6. Create barrel files (mod.rs / index.ts) as needed.
7. **DO NOT** implement any function bodies — stubs only.
8. **DO NOT** add or modify types beyond what types.md specifies.

OUTPUT: All scaffold files written to the project. Project builds with stubs.
"
)
```

### Wave 0 Verification:
1. **Compilation check**: Project builds without errors (`cargo check` / `tsc --noEmit` / equivalent).
   - Fail → retry scaffold task once.
2. **git init + commit**: 
   ```
   git init && git add -A && git commit -m "scaffold: $TOPIC"
   ```
   This creates a verifiable baseline. The shared interface file is now under git protection.

---

## D1: Per-Module Coding Loop

### D1.0: Initialize todo list

```
todowrite:
  - [ ] <module_A>: <description from contracts.md>
  - [ ] <module_B>: <description>
  ...
```

Order by dependency (lower-dependency modules first).

### D1.x: Module Task + Retry Loop (with integrated verification)

For each module (in dependency order, read next from todo list):

Each module runs a retry loop. Inside the loop: task(module) → if task completes → run
verification gates → all pass → break (module done) / any gate fails → retry.

**Module task timeout:** Set a 60-minute execution budget per task. If the task
does not complete within budget, treat as timeout (same as task failure → retry).

```
max_retries = 2
retry_count = 0

while retry_count < max_retries:

  task(
    category="deep",
    load_skills=[],
    run_in_background=false,
    prompt="
TASK: Implement module <name> for $TOPIC feature under blueprint constraints.

CONTEXT:
- TOPIC: $TOPIC
- BLUEPRINT_DIR: $BLUEPRINT_DIR
- Read: contracts.md, types.md, errors.md, test-properties.md, test-coverage.md from .blueprint/$TOPIC/
- Module category: [A|B|C] (determined in D0.4)
- <If Category C: this module is Category C — declarative/config. Presence test only.>

IRON LAW #5'' — SPEC-FIRST + MECHANICAL DEEP CHECKS:
1. Write tests from test-properties.md (spec-first, not code-first).
2. Implement to make tests pass.
3. Do NOT skip the RED step (compile-fail → write test → confirm fails).
4. Exception: Category C modules (declarative/config) — presence/load test only.

BLUEPRINT CONSTRAINTS:
- Types from types.md only — no inline/new types.
- Interfaces from contracts.md only — follow signatures exactly.
- Errors from errors.md only — follow error rules (retry policy, user messages).
- **DO NOT** modify the shared interface file (traits.rs / .d.ts / abstract base).

OUTPUT:
- Module implementation files.
- Test files covering all P0 boundary conditions for this module.
- All tests pass with \$TEST_CMD.
"
  )

  if task timed out or failed:
    retry_count += 1
    # Retry is safe: input comes from blueprint files, not from previous task output.
    continue

  # ── Task completed successfully ──
  # Run verification gates. ALL must pass.
  # ast_grep transient failure protection: all ast_grep calls retry once after 1s on failure.

  # Gate 1: COMPILATION CHECK
  Run: cargo check / tsc --noEmit / equivalent
  → Fail → retry_count += 1; continue (re-run task)

  # Gate 2: AST_GREP REFERENCE CHECK
  For each exported function in the module's source files, verify it appears in a test file.
  → Any exported function NOT in tests → retry_count += 1; continue

  # Gate 3: AST_GREP ASSERTION CHECK
  For each test function, verify it contains at least one assert/expect statement.
  → Exemption: Category C modules (declarative/config).
  → Any test without assertion → retry_count += 1; continue

  # Gate 4: P0 TRACEABILITY
  Every P0 boundary condition from test-properties.md for this module must have a
  corresponding test (naming convention test_<p0_name> or tag // p0_<name>).
  → Any P0 without test → retry_count += 1; continue

  # Gate 5: ANTI-BATCH AUDIT (non-blocking)
  Assertion count >= exported function count?
  → No → Flag warning, do NOT block.

  # Gate 6: SHARED INTERFACE PROTECTION
  Run: git diff HEAD -- <shared interface file>
  → No changes → Pass.
  → Changes detected → Review diff:
    - Reasonable (contract fix) → commit update.
    - Violates contracts → revert, retry_count += 1; continue

  # ── All gates passed ──
  break  # Module complete

# ── After retry loop ──

if retry_count < max_retries:
  # Module completed successfully
  todowrite mark "<module_name>" completed
  Update .session.md:
  ## Phase D Progress
  - completed_modules: [<module_names...>]
  - remaining_modules: [<pending_names...>]
  Proceed to next module.

else:
  # Consecutive failures/timeouts — module may be too large.
  # Decompose into sub-phases:
  #   phase 1: Data structures and types
  #   phase 2: Core logic (first half)
  #   phase 3: Core logic (second half)
  #   phase 4: Error handling + edge cases
  # Each sub-phase is an independent task with a clean retry budget.
  
  for each phase in sub_plan:
    task(
      category="deep",
      load_skills=[],
      run_in_background=false,
      prompt="<phase-specific constraints + Iron Law #5'' + blueprint constraints>"
    )
    → Verify: compilation + basic checks.
  
  # Sub-phase tasks do NOT count toward max_retries. Each is treated as fresh.
  After all sub-phases pass: todowrite mark "<module_name>" completed
```

---

## D2: Final Verification

After ALL modules pass their gates:

```
task(
  category="deep",
  load_skills=[],
  run_in_background=false,
  prompt="
TASK: Run full project build and test suite for $TOPIC.

CONTEXT:
- TOPIC: $TOPIC
- BLUEPRINT_DIR: $BLUEPRINT_DIR
- \$TEST_CMD: <detected test command>

VERIFY:
1. Full compilation passes (release/profile build).
2. All tests pass.
3. No regressions in existing tests.
4. All diagnostics clean.

Report any failures. Do NOT fix — just report.
"
)

→ If all pass → Phase D complete.
→ If failures → fix them (each fix is a mini-TDD cycle: failing test → fix → verify).
```

---

## D3: Completion

**Update .session.md:**
```markdown
## Phase D Progress
- completed_modules: [all]
- remaining_modules: []

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
