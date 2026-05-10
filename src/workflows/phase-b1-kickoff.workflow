# Phase B1: Blueprint Kickoff (Interactive)

> These instructions are self-executed by the orchestrator (not a sub-agent).
> The orchestrator has `question()` tool — this file uses it.
> IRON LAWS in effect: #1 (no code before gate), #4 (verify before claim)

---

### B1: Update state

Write to `.session.md`:
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

If previous blueprints exist in `.blueprint/`:
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
- ☐ **External interfaces**: every external capability (API endpoint / CLI command / event handler / message subscription / ...) has a module assignment in design.md?
  → Note: this check ensures capabilities are assigned to modules within design.md.
  → It does NOT replace the downstream contracts.md coverage verification (handled by consistency review).

**Constraint check — tech & language:**
- ☐ Primary programming language(s) confirmed?
- ☐ Framework / runtime / database chosen?
- ☐ Deployment persona determined? (personal CLI tool / team service / enterprise production)
- ☐ Target user identified? (developer tool / end-user app / API library)
- ☐ Performance requirements clear? (latency, throughput)

**Constraint check — deployment & security:**
- ☐ Deployment target determined? (local / SaaS / self-hosted / embedded)
- ☐ Security constraints mentioned? (auth, encryption, credential storage)
- ☐ Platform constraints? (Linux/Win/Mac, ARM/x86, container)

**Invariant check:**
- ☐ At least 3 design invariants?
- ☐ Each invariant mechanically verifiable?
- ☐ Has invariant declaring what NOT to do (scope boundary)?
- ☐ Any "reverse" invariants? (e.g., "no new dependencies")

**Orchestration check:**
- ☐ Cross-module side effects identified?
   When module A writes data, does module B need to know? (e.g., create → cache invalidation, state change → notification)
- ☐ Behavior chain complete for each external capability?
   From entry point (API request / CLI command) to terminal state — which modules and operations are involved?

**Alternatives check:** (Rule 2: State Rejected Alternatives)
- ☐ For each design choice where ≥2 reasonable approaches exist, are rejected alternatives stated with reasoning?
- ☐ If alternatives are missing, can you identify at least one design choice where the decision wasn't obvious?
- ☐ Any "obvious choice" that might actually have a viable alternative worth documenting?

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

### B5: Adaptive gap discussion

Based on NO/PARTIAL checklist results, you have a list of gaps (P0 = entity/module/constraint/invariant; P1 = ambiguity).

Discuss these gaps with the user as a natural conversation — not a rigid Q&A.

**How to conduct the discussion:**

1. **Open with context.** Briefly summarize what you found: "I reviewed your design. A few areas could use clarification: [list P0 gaps briefly, 1 sentence each]. Let's go through them."

2. **Discuss each gap naturally.** Explain what's missing and why it matters. The user can ask questions, explore tradeoffs, or make a choice.

3. **Distill into decisions.** After each gap is discussed, summarize the outcome and record it. If the user gave an open-ended answer, reformulate it: "So to confirm, you prefer [interpretation]. Correct?" If the user doesn't have a strong opinion, propose a reasonable default and confirm.

4. **Keep discussion focused.** If the user asks a technical question, answer briefly (1-2 sentences) and steer back.

5. **Check off the list.** Continue until all P0 gaps are addressed or the user signals readiness.

**Ending the discussion:**

End when ANY of:
- All P0 gaps have a decision recorded
- User explicitly says they want to proceed
- You've discussed all gaps and the user has nothing further to add
- A single gap takes more than 2 rounds without resolution → mark it DEFERRED, move on

**Final confirmation (not optional):**

```
question(
  header: "Ready for Phase C?",
  question: "I've gone through the design gaps. Current invariants: [list 2-3 key ones]. Shall I start the automated blueprint generation, or is there something else you'd like to discuss?",
  options: [
    { label: "Start Phase C", description: "Automated design + reviews" },
    { label: "One more thing", description: "I have something else to clarify" }
  ]
)
```

If user picks "One more thing", handle it naturally, then re-confirm.

### After B5 completes

Record decisions and invariants to `.session.md` so Phase B2 can access them:
```markdown
## Phase B Decisions
<list of decisions>

## Phase B Invariants
<list of confirmed invariants>
```

Then signal completion. The orchestrator will proceed to Phase B2.
