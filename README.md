# Blueprint

[中文版](README-cn.md)

---

**You say WHAT. Blueprint handles HOW.**

An OpenCode command that auto-generates types, interfaces, dataflow maps, and error contracts before you write a single line of code — then runs multi-LLM reviews and TDD-codes under those constraints.

All you answer: **What does this feature do?**

---

## WHAT vs HOW

| You (WHAT) | Blueprint (HOW) |
|---|---|
| Write a `design.md` describing your feature | Extracts entities, fills missing edge cases |
| Provide tech stack and constraints | Defines all types in one file |
| Describe functional scenarios | Maps every dataflow branch |
| Tell the agent your preferences | Designs module interfaces, no circular deps |
| **Your time: ~5–10 min** | Generates error handling rules: retry? abort? what user sees? |
| | Infers test boundaries from types, coverage from dataflow |
| | 7 LLMs review from security/perf/arch/business/roleplay angles |
| | Auto-fixes L1 issues, escalates decisions to you |
| | TDD-codes under blueprint constraints |
| | **Total: fully automatic, ~3–5 min for design + review** |

---

## Before vs After

```
Without Blueprint:
  You say WHAT → LLM free-styles → types scattered, interfaces inconsistent, errors silently swallowed

With Blueprint:
  You say WHAT → auto design + review → code under constraints → consistent, complete, maintainable
```

---

## How It Works

```
Phase A (you, ~5 min)     Phase B+C (auto, ~3–5 min)     Phase D (auto, on demand)
───────────────────       ──────────────────────────      ─────────────────────────
Write design.md           /blueprint kicks in             TDD code per blueprint
Describe what it does     Fills gaps, asks questions      Types from types.md only
                          4-stage auto design             Interfaces from contracts.md
                          7 parallel LLM reviews          Errors from errors.md
                          Outputs final report
```

### Phase A — Just answer WHAT
Write a free-form `design.md`. Core entities, module split, tech stack, scenarios. No format required.

### Phase B — BP finds your blind spots
`/blueprint` scans your design, spots gaps, and discusses with you naturally. Like talking to an engineer, not filling a form.

### Phase C — Fully automatic blueprint (3–5 min)
4 sequential stages → `types.md` → `contracts.md` → `lifecycle.md` → `errors.md`, then 7 parallel LLM reviews (security, performance, architecture, business, roleplay, consistency, and a consolidated final report).

### Phase D — Code under constraints
TDD with hard gates: types only from `types.md`, interfaces only from `contracts.md`, errors only from `errors.md`. No bypass.

---

## Quick Start

```bash
cd blueprint/
./install.sh
```

```bash
/blueprint                     # Full pipeline: design + review + code
/blueprint --design-only       # Design only (no coding)
/blueprint --from-stage 3      # Resume from interruption
```

Prerequisites: a `design.md` in the project root.

---

## Output

```
.blueprint/<topic>/
├── design.md              ← Your design (enriched by BP)
├── types.md               ← All types, one file
├── contracts.md           ← Module interfaces
├── lifecycle.md           ← Dataflow with all branches
├── errors.md              ← Error rules (no silent errors)
├── test-properties.md     ← Boundary conditions (P0/P1/P2)
├── test-coverage.md       ← Coverage matrix (P0 must pass)
├── .gate-passed           ← Gate pass sentinel
└── reviews/
    ├── review-security.md
    ├── review-perf.md
    ├── review-arch.md
    ├── review-business.md
    ├── review-roleplay.md
    ├── review-consistency.md
    └── final-report.md    ← Review summary
```

---

## Recommended Model

**DeepSeek V4 Flash** — cheap, powerful, and fast.

Blueprint is developed and tested on **[opencode](https://github.com/opencode-ai/opencode) + oh-my-openagent** with a full-stack DeepSeek V4 Flash configuration.

Recommended for the best plugin experience.

---

## When to Use

| Good for Blueprint | Skip it |
|---|---|
| Multi-file feature development | Renaming a variable |
| Many design decisions to think through | Typo fix |
| Critical path, needs stability | Quick prototype |
| Team collaboration, needs design docs | One-line config change |
