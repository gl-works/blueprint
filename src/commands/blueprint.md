---
description: Blueprint — design-first engineering. Before writing code, produce types, interfaces, lifecycle maps, error contracts, and run multi-perspective reviews. Phase D encodes under blueprint constraints with TDD.
argument-hint: "[--design-only] [--from-stage 1|2|3|4]"
tools:
  read: true
  write: true
  edit: true
  glob: true
  grep: true
  bash: true
  task: true
  question: true
  ast_grep_search: true
  ast_grep_replace: true
  lsp_diagnostics: true
  lsp_find_references: true
  webfetch: true
  look_at: true
---
<objective>
Design-first engineering pipeline for OpenCode.

Blueprint enforces that every piece of code is preceded by:
1. **Phase B — Kickoff**: Completeness check on design.md + gap-filling questions + invariant confirmation
2. **Phase C — Blueprint Automation**: 4 sequential stages (types → contracts → lifecycle → errors) + 2 parallel procedures (test properties, test coverage) + 7 parallel review agents + consolidator → final-report.md + .gate-passed
3. **Phase D — Constraint Coding**: TDD (RED→GREEN→REFACTOR) under blueprint constraints, with module exit gates

**Arguments:**
- `--design-only` — Skip Phase D (coding). Only produce blueprint artifacts.
- `--from-stage <N>` — Resume from a specific stage (1-4) in Phase C.

**Topic auto-detection** (in workflow): new run → prompt once; resume → scan existing blueprints.

**Output:** `.blueprint/<topic>/` directory with full artifacts + final report.
</objective>

<execution_context>
@.blueprint.workflow
</execution_context>

<context>
$ARGUMENTS

Parse `$ARGUMENTS`:
- `--design-only` → `$DESIGN_ONLY=true`
- `--from-stage <N>` → `$FROM_STAGE=N`
- If `--from-stage` is set and only one blueprint directory exists, auto-detect topic

All context files are resolved inside the workflow.
</context>

<process>
Execute the blueprint workflow end-to-end.
Preserve all gates: invariant feasibility checks, stage dependencies, review consolidation, .gate-passed creation, module exit gates.
</process>
