<purpose>
Design-first engineering pipeline. Before writing any code, produce formalized types, interface contracts, lifecycle maps, and error contracts — then run multi-perspective reviews across those artifacts. After blueprint passes, encode under its constraints with TDD (RED→GREEN→REFACTOR).

This workflow is a DISPATCH layer. It delegates phase execution to sub-agents (or self-executes B1 for user interaction). Phase-specific instructions are in separate files:
- phase-b1-kickoff.workflow  (orchestrator self-executes)
- phase-b2-finalize.workflow (sub-agent executes)
- phase-c-automation.workflow (sub-agent executes)
- phase-d-constraint-coding.workflow (sub-agent executes)
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

Search order (first match wins):
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
2. `task(subagent_type="general", load_skills=[], run_in_background=false, prompt="<context>TOPIC: $TOPIC\nBLUEPRINT_DIR: $BLUEPRINT_DIR\n</context>\n" + $CONTENT)`
3. Wait. Verify `.blueprint/$TOPIC/design.md` and `.blueprint/$TOPIC/.meta.json` exist.
4. Update `.session.md` to mark Phase B complete.

### Phase C: Blueprint Automation (delegate)

**Skip if:** `--from-stage >= 4` OR Phase C already done (`.gate-passed` exists or `.session.md` marks it).

1. `cat "$HOME/.config/opencode/command/phase-c-automation.workflow"` → save as $CONTENT.
2. `task(subagent_type="general", load_skills=[], run_in_background=false, prompt="<context>TOPIC: $TOPIC\nBLUEPRINT_DIR: $BLUEPRINT_DIR\nFROM_STAGE: $FROM_STAGE\nDESIGN_ONLY: $DESIGN_ONLY\n</context>\n" + $CONTENT)`
3. Wait. Verify `.gate-passed` exists (or user accepted BLOCKED).
4. If `--design-only`: skip Phase D, display "Design-only", exit.

### Phase D: Constraint Coding (delegate)

**Skip if:** `--design-only` is set.

1. `cat "$HOME/.config/opencode/command/phase-d-constraint-coding.workflow"` → save as $CONTENT.
2. `task(subagent_type="general", load_skills=[], run_in_background=false, prompt="<context>TOPIC: $TOPIC\nBLUEPRINT_DIR: $BLUEPRINT_DIR\nFROM_STAGE: $FROM_STAGE\n</context>\n" + $CONTENT)`
3. Wait. Verify all exit gates passed.

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
