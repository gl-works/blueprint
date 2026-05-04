# Phase D: Constraint Coding

> IRON LAWS (applicable to this phase):
> #1: NO NEW CODE BEFORE BLUEPRINT COMPLETE (.gate-passed created)
> #4: NO COMPLETION CLAIM WITHOUT FRESH VERIFICATION EVIDENCE
> #5: NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
> #6: NO TEST MODIFIED TO PASS. ONLY CODE OR BLUEPRINT.

---

### Step D-1: Session mode switch

Before starting the TDD loop, switch from design mode to coding-with-TDD mode.

```
╔══════════════════════════════════════════╗
║  PHASE D: CODING WITH TDD               ║
║  No production code without a failing   ║
║  test first.                            ║
╚══════════════════════════════════════════╝
```

**First actions (do NOT edit production code yet):**
1. Read `test-properties.md` → write ONE failing test → confirm RED.
2. Only THEN write the implementation (GREEN).
3. If context is long (>200 messages), update `.session.md` checkpoint and resume later.

**Continuation Rules (priority: override generic continuation prompts):**

When this Phase D receives a TODO CONTINUATION prompt:
1. Each task follows RED→GREEN→REFACTOR. Do NOT skip.
2. If the current task lacks a failing test, write it first.
3. "Done" means: test passes + invariant verified + diagnostics clean.
4. Speed comes from fast cycles, not batch implementation.

---

## Phase D: Constraint Coding

### Rules (apply throughout)

**R4 — No Incremental Patching on Structural Changes:**
When the core data structure layout or access pattern changes (e.g. ring buffer → lookup table, shared state → per-instance), do NOT patch function-by-function. Rewrite the affected module from the new design and re-verify all invariants from scratch.
This does NOT apply to additive changes that preserve existing structure (e.g. adding a field, adding a new function).

### D0: Pre-flight checks

**Step D0.0: Resume from checkpoint**
Check `.session.md` for existing Phase D Progress:
- If `completed_modules` is non-empty → skip those modules, resume from the next uncompleted module.
- If `current_module` is set → start TDD loop directly from that module's next unchecked condition.
- If no Phase D Progress found → start fresh (all modules pending).

**Step D0a: Iron Law #5 compliance — pre-flight scan**
Before any edit, verify test coverage exists for target functions:
1. From `contracts.md`, extract all function signatures that need implementing for each module.
2. For each signature, check if a corresponding test file or test case already exists:
   ```
   ast_grep --pattern '$FUNC_NAME(' --glob '**/*.test.*' | grep $FUNC_NAME
   ```
3. Report: "Contracts list: [N] functions for [M] modules. [K] have existing tests, [L] need new tests."
4. If any module has zero test coverage → note it explicitly.

**Step D0.1: Verify .gate-passed**
If `.blueprint/$TOPIC/.gate-passed` does NOT exist → abort.

**Step D0.2: Check test infrastructure (first time only)**
Detect project testing:
- Try: `cargo test --help`, `npm test --help`, `pytest --help`, `go test --help`
- Framework found → record command as `$TEST_CMD`
- No framework → install minimal test framework based on detected tech stack.

**Step D0.2b: Per-module test strategy assignment**
From `contracts.md`, determine the appropriate test strategy for each module:
- **Category A — Domain/business logic**: Unit TDD (RED→GREEN→REFACTOR with `$TEST_CMD`).
  - Pure functions, data transformations, validation, core algorithms.
- **Category B — Integration/glue code**: Integration TDD (RED→GREEN→REFACTOR with request→response testing).
  - API routes, middleware, framework callbacks.
  - Still requires a failing test first — just a different test type.
- **Category C — Declarative/config**: Presence/load test.
  - Pure config, constant definitions, type re-exports.
  - At minimum: one test that verifies the file loads without error.

Classification heuristics (auto-infer from contract signatures):
- `(A → B)` data transformer → Category A
- `(Request → Response)` handler → Category B
- static/const/type-only export → Category C

> There is NO "test-exempt" category. Every module requires tests at the appropriate level.

**Step D0.3: Read blueprint artifacts**
Read ALL from `.blueprint/$TOPIC/`:
- types.md → import types, never recreate
- contracts.md → implement interfaces
- errors.md → follow error rules
- test-properties.md → checkboxes to satisfy
- test-coverage.md → checkboxes to satisfy

**Step D0.4: Identify modules to code**
From contracts.md, list modules/interfaces. Order by dependency.

**Step D0.4b: Decompose into atomic tasks (windowed)**
For the CURRENT module only (not all modules at once):
1. List all P0 boundary conditions from `test-properties.md` that apply to this module.
2. Generate ONE todo per condition in the following format:
   ```
   [P0] <module>.<field>: <condition> → RED→GREEN→REFACTOR
   ```
   Example: `[P0] KnowledgeYaml.template: missing → Zod schema rejects → RED→GREEN→REFACTOR`
3. Write these as the active `todowrite` items. Do NOT generate TODOs for P1/P2 yet.
4. When the module is fully complete (all exit gate checks pass), record it in `.session.md` and generate TODOs for the next module.

> Why windowed: 100+ TODOs at once overwhelms the working context. ~10-20 per module keeps the list actionable and prevents batch-processing.

**Step D0.5: Context budget estimation**
Before starting the TDD loop:
1. Count modules: N
2. Count unchecked P0 boundary conditions: M
3. Estimate: ~3-5 tool calls per TDD cycle × M cycles = ~3M-5M tool calls total
4. If M > 30 or N > 4:
   - Propose session breakpoints.
   - For each module completed, update `.session.md` so resumption works.

### D1: TDD Loop

For each module (dependency order):

**Step D1.1: Select boundary condition**
Pick next unchecked item from test-properties.md or test-coverage.md for this module.
P0 first, then P1, then P2.

**Step D1.2: RED — Write failing test**
Write test for the selected boundary condition.
Run `$TEST_CMD` — confirm FAILS (test fails without implementation).
If test passes without implementation → test is wrong. Fix test.

**Step D1.2a: Test-before-code verification**
1. After confirming the test FAILS, record:
   - `$TEST_FILE` = path to the test file just written.
   - `$FAILING_TEST` = name/description of the failing test case.
2. Verify the test file explicitly calls the target function:
   ```
   ast_grep --pattern '$FUNC_NAME(' $TEST_FILE
   ```
   If `$FUNC_NAME` is not found in `$TEST_FILE` → the test does not actually test the target function. Fix the test.
3. Do NOT edit any production file until this verification passes.

**Step D1.3: GREEN — Write minimal implementation**

Minimum code to pass the failing test. Constraints (non-negotiable):
- **ONE exported function OR 15 lines** of net new code per GREEN step.
- Allowed without counting toward the limit:
  - Internal helper functions (private, not in contracts.md) — but they must be called by the tested exported function.
  - Data type definitions (struct, enum, type alias, interface).
- If the implementation requires 2+ exported functions → break into separate TDD cycles.
- Types from `types.md` (import, don't redefine). Interfaces from `contracts.md` (follow signatures). Errors from `errors.md` (follow rules).

Run `$TEST_CMD` — confirm PASSES.

**Step D1.3b: Scope compliance check (post-audit)**
After GREEN passes but before REFACTOR:
1. Extract all exported function names from the modified production files:
   ```
   ast_grep --pattern 'export function $NAME($$$) { $$$ }' <production_files>
   ```
2. Extract all function names referenced in the test file:
   ```
   ast_grep --pattern '$NAME(' --context 0 $TEST_FILE
   ```
3. Compare: every exported function in step 1 must appear in step 2's results.
   - ✅ All tested → continue to REFACTOR.
   - ❌ Unreferenced `[func_X, func_Y]` → Iron Law #5 violation.
     - Roll back the untested functions. Create a new TDD cycle for each.
     - Do NOT proceed to REFACTOR until all exported functions are covered.
4. Internal helpers are NOT checked here — they are implicitly covered by the exported function's tests. Dead helpers are caught in REFACTOR (LSP diagnostics).

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

- ☐ **All P0 boundary conditions** for module checked?
- ☐ **All P0 coverage items** for module checked?
- ☐ **All new tests pass** — `$TEST_CMD` reports zero failures.
- ☐ **No new failures in existing tests** — all previously passing tests still pass.
- ☐ **All new types from types.md** (none invented outside blueprint types).
- ☐ **All edits traceable to requirements/blueprint** — no scope creep.
- ☐ **Iron Law #5 compliance** — ast_grep confirms every new exported function is referenced in a test file.
- ☐ **Compilation passes** — project builds without errors.
- ☐ **R3: Invariant enforcement verified** — Re-read each invariant from the design.md Invariant List. For each one, trace the exact code lines that enforce it. If any invariant is not enforced by the code, fix before passing gate.

Pass → write checkpoint, proceed to next module. Fail → continue TDD loop.

**Per-module checkpoint:**
After the exit gate passes, write progress to `.session.md`:
```markdown
## Phase D Progress
- completed_modules: [<module_name>]
- remaining_modules: [<list_of_pending>]
```

**Failure handling:**

**故障 A: Test correct but fails (blueprint assumption wrong)**
1. Do NOT modify test to make it pass.
2. Update `.blueprint/$TOPIC/types.md` (fix assumption).
3. Update `.blueprint/$TOPIC/test-properties.md` (fix boundary if needed).
4. Continue RED→GREEN.

**故障 B: Test coverage gate not met (missed paths)**
1. Add missing tests.
2. If new boundary conditions found, sync to test-properties.md.
3. Do NOT downgrade P0→P1.

**故障 C: Same failure after 2 retries**
1. Max 2 retries per issue.
2. After 2nd → escalate to user.

### D2: Complete

When all modules pass exit gates:

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
