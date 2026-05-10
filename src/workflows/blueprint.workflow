<purpose>
Design-first engineering pipeline. Before writing any code, produce formalized types, interface contracts, lifecycle maps, and error contracts — then run multi-perspective reviews across those artifacts. After blueprint passes, encode under its constraints with TDD (RED→GREEN→REFACTOR).

This workflow is a DISPATCH layer. It delegates phase execution to sub-agents (or self-executes B1 for user interaction). Phase-specific instructions are in separate files:
- phase-b1-kickoff.workflow  (orchestrator self-executes)
- phase-b2-finalize.workflow (sub-agent executes)
- phase-c-automation.workflow (sub-agent executes)
- phase-d-constraint-coding.workflow (orchestrator self-executes — Pattern B loop)
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
- BLUEPRINT_DIR: `.blueprint/<TOPIC>/` relative to project root
- REVIEWS_DIR: `.blueprint/<TOPIC>/reviews/`
- design.md: Input design document (in project root or specified path)
- .session.md: Session state file tracking current progress
- .meta.json: Blueprint metadata (scope, decisions, timestamps)
- .gate-passed: Sentinel file — exists = blueprint passed = can proceed to coding
</terminology>

<iron_laws>
These are non-negotiable. Violation = workflow failure.

IRON LAW #1: NO NEW CODE BEFORE BLUEPRINT COMPLETE (.gate-passed created)
IRON LAW #2: NO NEW TYPE FOR THIS FEATURE OUTSIDE .blueprint/<topic>/types.md
IRON LAW #3: NO NEW INTERFACE WITHOUT .blueprint/<topic>/contracts.md SPEC
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

A. If `--from-stage` is set and exactly one subdirectory exists under `.blueprint/`:
   → `$TOPIC` = that directory name (resuming existing blueprint)

B. If `--from-stage` is set and multiple subdirectories under `.blueprint/`:
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
BLUEPRINT_DIR = ".blueprint/$TOPIC/"
REVIEWS_DIR   = ".blueprint/$TOPIC/reviews/"
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
- path: .blueprint/$TOPIC/
- scope: (to be determined in Phase B)

## Progress
- stage: Phase B (Kickoff)
- status: in_progress

## Gate
- gate-passed: ✗
```

### Step 3: Find design.md

Search order (first match wins, case-insensitive):
1. `design.md` in project root
2. `$TOPIC.md` in project root
3. `.blueprint/$TOPIC/design.md` (if resuming)
4. Prompt user: "Where is your design document? Provide path or paste content."

If nothing found: show error "Blueprint requires a design document (design.md) as input."

Read the found `design.md` and store its content in `.blueprint/$TOPIC/design.md`.

<!-- ============================================================ -->
<!-- DISPATCH: Phase execution                                     -->
<!-- ============================================================ -->

## Dispatch Logic

Phase workflow files are deployed to `$HOME/.config/opencode/command/` alongside `.blueprint.workflow`.
Use `cat` to read them (not `read` tool), because `read` resolves relative to the project directory,
not the command directory.

For each phase below:
1. Check whether it should be skipped based on `$FROM_STAGE` and `.session.md`.
2. Get the phase instructions via: `cat "$HOME/.config/opencode/command/phase-<name>.workflow"`
3. Either self-execute (B1) or delegate via `task()` with the content as prompt.
4. Prepend a context header with relevant variables (`$TOPIC`, `$BLUEPRINT_DIR`, and `$FROM_STAGE`/`$DESIGN_ONLY` as needed per phase).

### Phase B1: Kickoff (interactive — self-execute)

**Skip if:** `--from-stage >= 2` OR `.session.md` shows Phase B already completed.

1. `cat "$HOME/.config/opencode/command/phase-b1-kickoff.workflow"` → save as instructions.
2. Follow those instructions as your own. This phase uses `question()` for user interaction.
3. Record decisions and invariants to `.session.md` after B5 completes.

### Phase B2: Finalize artifacts (delegate)

**Skip if:** `--from-stage >= 2` OR Phase B2 already done (B1 writes this flag).

1. `cat "$HOME/.config/opencode/command/phase-b2-finalize.workflow"` → save as $CONTENT.
2. `task(category="unspecified-high", load_skills=[], run_in_background=false, prompt="<context>TOPIC: $TOPIC\nBLUEPRINT_DIR: $BLUEPRINT_DIR\n</context>\n" + $CONTENT)`
3. Wait. Verify `.blueprint/$TOPIC/design.md` and `.blueprint/$TOPIC/.meta.json` exist.
4. Update `.session.md` to mark Phase B complete.

### Phase C: Blueprint Automation (delegate stages) + Reviews (orchestrator level)

**Skip if:** `--from-stage >= 4` OR `.gate-passed` exists in `.blueprint/$TOPIC/`.

1. `cat "$HOME/.config/opencode/command/phase-c-automation.workflow"` → save as $CONTENT.
2. `task(category="deep", load_skills=[], run_in_background=false, prompt="<context>TOPIC: $TOPIC\nBLUEPRINT_DIR: $BLUEPRINT_DIR\nFROM_STAGE: $FROM_STAGE\nDESIGN_ONLY: $DESIGN_ONLY\n</context>\n" + $CONTENT)`
3. Wait. Verify artifacts exist: types.md, contracts.md, lifecycle.md, errors.md, test-properties.md, test-coverage.md.
4. If `--design-only`: continue to reviews (reviews still produce .gate-passed). After reviews, Phase D will be skipped.

5. **Orchestrator-level multi-perspective reviews:**

   Run after Phase C stages complete. All reviews read from `.blueprint/$TOPIC/` file system, not from orchestrator context.

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
         .blueprint/$TOPIC/design.md (Decisions Record + Invariant List)

   CHECK:
   1. Sensitive data exposure — secrets, tokens, PII in types?
   2. Input validation — external inputs validated?
   3. Information leakage — do error messages leak internals?
   4. Auth/authorization — mentioned when it should be?

   SCOPE NOTE: cross-reference findings with design.md's Decisions Record and
   Invariant List. Explicitly out-of-scope / accepted-risk / deferred items →
   flag as minor at most, never BLOCKING.

   OUTPUT TWO FILES:
   - Details: .blueprint/$TOPIC/reviews/review-security.md (full reasoning)
   - Summary: .blueprint/$TOPIC/reviews/review-security-summary.md
      ## blocking: true/false
      ## severity: critical/major/minor
      ## affects_stage: 1/2/3/4
      ## finding_count: N
      ## summary: one-line conclusion
      ## findings:
        - [concrete description] | [file/module] | [severity]
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
         .blueprint/$TOPIC/design.md (Decisions Record + Invariant List)

   CHECK:
   1. Sync blocking in async paths?
   2. Connection reuse (db/network pooling)?
   3. Large object passing — unnecessary copying?
   4. Hot path — unnecessary allocation?

   SCOPE NOTE: cross-reference findings with design.md's Decisions Record and
   Invariant List. Explicitly out-of-scope / accepted-risk / deferred items →
   flag as minor at most, never BLOCKING.

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
         .blueprint/$TOPIC/design.md (Decisions Record + Invariant List)

   CHECK:
   1. Circular dependencies?
   2. Interface abstraction level — right granularity?
   3. Module cohesion — single responsibility?
   4. Extensibility — adding feature changes how many modules?

   SCOPE NOTE: cross-reference findings with design.md's Decisions Record and
   Invariant List. Explicitly out-of-scope / accepted-risk / deferred items →
   flag as minor at most, never BLOCKING.

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

   SCOPE NOTE: cross-reference findings with design.md's Decisions Record and
   Invariant List. Explicitly out-of-scope / accepted-risk / deferred items →
   flag as minor at most, never BLOCKING.

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

    Each persona MUST list concrete findings (missing features, unclear documentation, etc.)
    in its walkthrough section.

    SCOPE NOTE: cross-reference findings with design.md's Decisions Record and
    Invariant List. Explicitly out-of-scope / accepted-risk / deferred items →
    flag as minor at most, never BLOCKING.

    OUTPUT: review-roleplay.md + review-roleplay-summary.md

    Summary format:
      ## blocking: true/false
      ## severity: critical/major/minor
      ## affects_stage: 1/2/3/4
      ## finding_count: N
      ## summary: one-line conclusion
      ## findings:
        - [concrete description] | [file/module] | [severity] | [persona]
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
    ☐ **design.md capabilities vs contracts.md trait methods**
       → List external capabilities found in design.md (API endpoints, CLI commands, events, etc.)
       → For each capability, check if contracts.md has a corresponding trait method
       → PASS: all N capabilities have matching trait methods
       → FAIL: [X, Y, Z] capabilities have no matching trait method
       → Skipped: each skip must list reason (out-of-scope / deferred / non-functional)

    For each FAIL: file, line, description.

    OUTPUT TWO FILES:
    - Details: .blueprint/$TOPIC/reviews/review-consistency.md
    - Summary: .blueprint/$TOPIC/reviews/review-consistency-summary.md
      ## blocking: true/false
      ## severity: critical/major/minor
      ## affects_stage: 1/2/3/4
      ## finding_count: N
      ## summary: one-line conclusion
      ## findings:
        - [concrete description] | [file/module] | [severity]
    "
    )
   ```

   Collect both results.

   **Consolidator + Final Report:**

   ```
   task(
     category="ultrabrain",
     load_skills=[],
     description="Consolidate reviews for $TOPIC",
     prompt="
   You are the CONSOLIDATOR. Read ALL review summaries from .blueprint/$TOPIC/reviews/*-summary.md.
   DO NOT read full review files — unless a summary indicates failure (see BLOCKING RULES 6/7 for exceptions).

   CONFLICT RESOLUTION:
   1. Security (critical) > any other perspective
   2. Architecture vs business → architecture wins
   3. Testability vs performance → testability wins
   4. Same-level non-blocking → you decide

   BLOCKING RULES (automatic):
    1. Security critical → BLOCKING
    2. Any review summary has 'blocking: true' → BLOCKING
    3. Any invariant violation found → BLOCKING
    4. Circular dependency found → BLOCKING
    5. Two+ reviewers agree on blocking → BLOCKING. Disagreement on blocking status → non-blocking unless any flagged as critical.
    6. **Consistency check has any FAIL item → BLOCKING**
       (Read full consistency details if summary indicates failure)
    7. **Independent Convergence: 2+ independent reviewers flag the same concrete issue → BLOCKING**
       → Match by same file path / module / capability name from ## findings fields
       → Roleplay's multiple personas count as independent perspectives
       → Does NOT apply to vague observations (e.g. "design could be clearer")

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
   If "BLOCKED" → do NOT create gate.

   **Display review summary:**
   If READY FOR CODING:
   ```
   ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
   ┃  BLUEPRINT COMPLETE :: $TOPIC
   ┃  Status: READY FOR CODING
   ┃  Artifacts: 6 files, N reviews
   ┃  Gate: .gate-passed created
   ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
   ```
   If BLOCKED:
   ```
   ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
   ┃  BLUEPRINT COMPLETE :: $TOPIC
   ┃  Status: ❌ BLOCKED
   ┃  Artifacts: 6 files, N reviews
   ┃  Gate: ✗ NOT created
   ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
   ```

   **Post-pipeline BLOCKED resolution** (only if BLOCKED):
   The pipeline is complete. Phase D was skipped due to blocking findings.
   You can help the user resolve these findings interactively:

   1. Read the blocking findings from `.blueprint/$TOPIC/reviews/final-report.md`.
   2. Create a `todowrite` list with one todo per blocking finding.
   3. For each finding (user chooses order):
      a. Present the finding text to the user.
      b. **Before any edits**: ask "What's the acceptance criteria for this fix?" Converge scope first.
      c. Discuss and fix using edit/write tools on `.blueprint/$TOPIC/` artifact files.
         For architecturally-complex findings (≥2 valid approaches, multi-file, open-ended):
         → delegate to `task(category="deep")` to keep context lean.
         For simple/mechanical findings (one-line, obvious fix):
         → apply inline.
      d. After each todo is complete, **announce the next uncompleted item** from the list.
         Ask: "Next up: [finding N]. Continue or skip?"
    4. When ALL todos completed:
       Display:
       ```
       ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
       ┃  ✅ All blocking issues resolved.                           ┃
       ┃  All artifact files are now ready for re-validation.        ┃
       ┃                                                             ┃
       ┃  Next step:                                                 ┃
       ┃    /blueprint --from-stage 4 $TOPIC                         ┃
       ┃                                                             ┃
       ┃  (Include any extra flags from original command,             ┃
       ┃   e.g. --design-only, custom design.md path, etc.)          ┃
       ┃                                                             ┃
       ┃  This re-runs Stage 4 + all reviews to verify the fixes,    ┃
       ┃  then proceeds to Phase D (coding) if the gate passes.      ┃
       ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
       ```

6. If `--design-only`: skip Phase D, display "Design-only — Phase D skipped."

### Phase D: Constraint Coding (orchestrator-level Pattern B loop)

**Skip if:** `--design-only` is set.

Phase D is self-executed by the orchestrator (not delegated). Read the workflow file and follow the Pattern B instructions.

1. `cat "$HOME/.config/opencode/command/phase-d-constraint-coding.workflow"` → save as instructions.
2. Follow those instructions as your own — Wave 0 scaffold, per-module loop with retry and verification gates.
3. All modules complete → update `.session.md` and display final banner.

### Completion

When all phases complete:

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

</process>

<success_criteria>
A blueprint run is successful when ALL of:
1. `.blueprint/<TOPIC>/` exists with all 6 artifact files + reviews + .meta.json
2. (If not design-only) All modules coded, tests pass, diagnostics clean
3. (If not design-only) All P0 boundary conditions and coverage items checked
4. No IRON LAW violations
5. .gate-passed file exists (design-only: exists if reviews passed)

If BLOCKED: final-report.md explains what's blocking. No .gate-passed.
</success_criteria>

<session_recovery>
If interrupted mid-workflow:

1. Check `.session.md` in `.blueprint/<TOPIC>/`.
2. Read to determine last completed stage.
3. Verify artifacts match state (Stage N done → artifact file must exist).
4. Consistent → resume from next step.
5. Inconsistent (state says done but file missing) → re-run from that stage.

Manual resume: `/blueprint --from-stage <N>`
</session_recovery>
