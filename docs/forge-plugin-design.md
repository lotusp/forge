# Forge — Claude Code Plugin Design

## Vision

Forge is a Claude Code plugin for AI-driven software development on existing systems.

The core paradigm shift: **AI is the developer, humans provide intent and context.** You do not need to be an engineer to use Forge — if you understand the business and can articulate requirements, Forge handles the rest. For engineers, Forge provides deeper control at each step.

Forge is specifically designed for **maintenance and evolutionary development on legacy codebases** — the most common and underserved scenario in real-world software development.

---

## Plugin Identity

| Field | Value |
|-------|-------|
| Name | `forge` |
| Invocation prefix | `/forge:` |
| Target users | Product owners, business analysts, engineers, tech leads |
| Primary scenario | Feature development and maintenance on existing codebases |

---

## End-to-End Skill Flow

```
onboard → calibrate → clarify → design → plan → code → review → test
```

Each skill produces a structured artifact that feeds into the next. Skills can be run independently when context already exists, or sequentially from the beginning.

---

## Skills

### `/forge:onboard`

**Purpose:** Generate a human-readable project map for anyone new to the codebase.

**Input:** Current working directory (the project root or monorepo root).

**Process:**
1. Scan directory structure, entry points, and configuration files
2. Identify tech stack, runtime environments, and infrastructure dependencies
3. Summarize module responsibilities and their relationships
4. Extract local development setup steps (how to run, how to test)

**Output:** `.forge/onboard.md`
- Project purpose and domain overview
- Module/service map with one-line descriptions
- Tech stack summary
- Local setup commands
- Key entry points (APIs, UIs, jobs, events)

**Who uses it:** Anyone joining the project — engineers, PMs, or AI agents in a new session.

---

### `/forge:calibrate`

**Purpose:** Extract the project's implicit coding standards and architectural conventions, then refine them into actionable constraints for all future development.

**Input:** Full codebase scan + `.forge/onboard.md`

**Process — Phase 1 (scan):**
1. Analyze architecture patterns across all modules (layering, naming, package structure)
2. Extract conventions for: logging, error handling, validation, testing, API design, DB access, inter-service communication
3. Identify inconsistencies and contradictions across modules (common in legacy codebases)
4. Detect anti-patterns or areas of known technical debt

**Process — Phase 2 (refine):**
1. Present contradictions and ask the user to adjudicate ("Module A uses X, Module B uses Y — which should new code follow?")
2. Where no contradiction exists, ratify the existing pattern
3. Where legacy patterns are clearly problematic, propose a better direction for new code (without breaking existing code)
4. Produce a final, authoritative conventions document

**Output:** `.forge/conventions.md`
- Architecture & layering rules
- Naming conventions
- Logging standards
- Error/exception handling patterns
- Validation approach
- Testing strategy (unit vs. integration, coverage expectations)
- What to avoid (anti-patterns observed in this codebase)
- Open questions (known gaps, areas needing team decision)

**Note:** This is the most critical artifact in Forge. All downstream skills reference `.forge/conventions.md` as the source of truth.

---

### `/forge:clarify [scenario or requirement]`

**Purpose:** Deeply understand a requirement by tracing existing code paths, mapping data flows, and surfacing unknowns — then asking targeted questions to fill gaps.

**Input:** A natural-language description of a scenario or requirement (can be vague).

**Process:**
1. Identify the relevant entry points, domain concepts, and affected modules
2. Trace the full call chain and data flow end-to-end
3. Map data models, state transitions, and integration points
4. Identify what cannot be determined from code alone (runtime config, external system behavior, business rules not encoded in code)
5. Generate a structured list of unknowns and ask the user to resolve them
6. Incorporate answers and produce a complete technical picture

**Output:** `.forge/clarify-[feature-name].md`
- Scenario restatement (in precise technical terms)
- Current implementation walkthrough (code path, data flow, sequence)
- Affected components and data models
- External dependencies and integration points
- Assumptions made + questions answered
- Gaps identified (what does not yet exist)

**Design note:** Forge never guesses at unknowns — it pauses and asks. The quality of the clarify artifact directly determines the quality of everything downstream.

---

### `/forge:design [feature-name]`

**Purpose:** Produce a concrete technical design for a feature, grounded in the existing codebase conventions and the clarify analysis.

**Input:** `.forge/clarify-[feature-name].md` + `.forge/conventions.md`

**Process:**
1. Define the solution approach and key design decisions
2. Identify what to add, modify, and leave unchanged
3. Perform impact analysis: which existing modules, APIs, and data models are touched
4. Assess risks and propose mitigations (backward compatibility, data migration needs, rollback approach)
5. Surface any design decisions that require human input before proceeding

**Output:** `.forge/design-[feature-name].md`
- Solution overview
- Component changes (new / modified / deleted)
- API contract changes (if any)
- Data model changes (if any)
- Impact analysis: blast radius, regression risks
- Key design decisions with rationale
- Constraints and trade-offs (what was ruled out and why)
- Open decisions requiring human input

---

### `/forge:plan [feature-name]`

**Purpose:** Break the approved design into an ordered, executable task list with clear acceptance criteria.

**Input:** `.forge/design-[feature-name].md`

**Process:**
1. Decompose the design into atomic implementation tasks
2. Order tasks by dependency (what must be done before what)
3. Assign each task a type: `infra`, `model`, `logic`, `api`, `ui`, `test`, `migration`
4. Write acceptance criteria for each task
5. Flag tasks with elevated risk or uncertainty

**Output:** `.forge/plan-[feature-name].md`
- Ordered task list with types and acceptance criteria
- Dependency graph (which tasks block which)
- Risk-flagged tasks
- Estimated scope (rough: small / medium / large per task)

---

### `/forge:code [task-id]`

**Purpose:** Implement a specific task from the plan, producing code that strictly follows `.forge/conventions.md`.

**Input:** `.forge/plan-[feature-name].md` (specific task) + `.forge/conventions.md` + relevant source files

**Process:**
1. Re-read the conventions and the task acceptance criteria
2. Identify the exact files to create or modify
3. Generate code that matches the project's existing style, naming, and patterns
4. For database/schema changes: generate migration scripts
5. For API changes: update contracts and any affected client code
6. Output a summary of changes made and why

**Constraints:**
- Never introduce patterns not present in `.forge/conventions.md` without flagging it
- Never modify files outside the task's stated scope
- If a task turns out to require broader changes than expected, stop and surface the finding rather than expanding scope silently

**Output:** Modified/created source files + `.forge/code-[task-id]-summary.md` (what was changed and why)

---

### `/forge:review [feature-name or file-path]`

**Purpose:** Review implemented code against project conventions and the feature design, identifying violations and improvement opportunities.

**Input:** Changed files + `.forge/conventions.md` + `.forge/design-[feature-name].md`

**Process:**
1. Check each changed file against the conventions (architecture, naming, error handling, logging, etc.)
2. Verify the implementation matches the design intent
3. Identify any scope creep (changes beyond what the design specified)
4. Flag security concerns, performance risks, and maintainability issues
5. Distinguish between: must-fix (convention violation), should-fix (quality improvement), and consider (optional suggestion)

**Output:** `.forge/review-[feature-name].md`
- Per-file findings categorized as must-fix / should-fix / consider
- Convention compliance summary
- Design adherence assessment
- Overall verdict: ready / needs-work / needs-redesign

---

### `/forge:test [feature-name]`

**Purpose:** Generate a test plan and test code that matches the project's testing conventions and adequately covers the implemented feature.

**Input:** `.forge/design-[feature-name].md` + `.forge/conventions.md` + implemented source files

**Process:**
1. Determine the appropriate test types based on conventions (unit, integration, e2e, contract)
2. Identify test cases: happy path, edge cases, failure modes, boundary conditions
3. Check which existing tests need to be updated due to the changes
4. Generate test code following the project's existing test patterns and naming
5. Flag any scenarios that require test infrastructure not yet in place

**Output:** Test files (following project conventions) + `.forge/test-[feature-name].md`
- Test coverage map (what is tested and at which level)
- Existing tests requiring update
- Known gaps (scenarios not covered and why)
- Any test infrastructure prerequisites

---

## Artifact Store

All Forge artifacts live in `.forge/` at the project root. This directory should be committed to version control — it is the persistent context that makes Forge effective across sessions.

```
.forge/
├── onboard.md                    # Project map
├── conventions.md                # Authoritative coding standards
├── clarify-[feature].md          # Requirement analysis per feature
├── design-[feature].md           # Technical design per feature
├── plan-[feature].md             # Task breakdown per feature
├── code-[task-id]-summary.md     # Implementation summary per task
├── review-[feature].md           # Review findings per feature
└── test-[feature].md             # Test plan per feature
```

---

## Key Design Principles

**1. Context persistence over re-analysis**
Every skill reads from and writes to `.forge/`. Subsequent sessions pick up where the last left off without re-scanning the entire codebase.

**2. Conventions as the single source of truth**
`calibrate` produces the law of the codebase. Every downstream skill (`code`, `review`, `test`) must reference it. If the conventions need updating, run `calibrate` again.

**3. Pause before guessing**
When context is insufficient (missing business rules, external system behavior, ambiguous requirements), Forge surfaces a structured list of questions rather than making assumptions. Assumptions are always made explicit.

**4. Scope discipline**
Each skill operates within its defined scope. `code` does not redesign. `design` does not implement. Scope creep is flagged, not silently absorbed.

**5. Legacy-first, not greenfield**
Forge is optimized for existing codebases with inconsistencies, technical debt, and undocumented behavior. It does not assume a clean architecture. It works with reality, while nudging new code toward better patterns.

**6. Accessible to non-engineers**
Skill names and outputs use plain language. Technical depth is available but not required. A product owner should be able to run `onboard`, `calibrate`, `clarify`, and `design` to get a coherent picture of what needs to be built.

---

## Future Skills (Backlog)

| Skill | Purpose |
|-------|---------|
| `/forge:migrate` | Safely plan and execute DB schema or API breaking changes with rollback strategy |
| `/forge:debt` | Catalog and prioritize technical debt discovered during development |
| `/forge:commit` | Generate structured commit messages and PR descriptions from Forge artifacts |
| `/forge:incident` | Given a production issue or bug report, trace root cause using the codebase and Forge context |

---

## Plugin Structure (Target)

```
forge/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── onboard/
│   │   └── SKILL.md
│   ├── calibrate/
│   │   └── SKILL.md
│   ├── clarify/
│   │   └── SKILL.md
│   ├── design/
│   │   └── SKILL.md
│   ├── plan/
│   │   └── SKILL.md
│   ├── code/
│   │   └── SKILL.md
│   ├── review/
│   │   └── SKILL.md
│   └── test/
│       └── SKILL.md
└── README.md
```
