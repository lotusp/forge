---
name: design
description: |
  Produces a concrete technical design for a feature, grounded in existing
  codebase conventions and prior requirement analysis. Use after /forge:clarify
  has produced a clarify artifact, or when the user provides sufficient context
  directly.
argument-hint: "<feature-slug>"
allowed-tools: "Read Glob Grep Bash"
model: sonnet
effort: high
---

## Runtime snapshot
- Existing .forge artifacts: !`ls .forge/ 2>/dev/null || echo "(none)"`
- Conventions available: !`test -f .forge/conventions.md && echo "YES — will enforce" || echo "NO — design will be unconstrained"`

---

## IRON RULES

These rules have no exceptions.

- **Never finalise a design with unresolved Open Decisions.** If the user explicitly asks to defer a decision, mark it "deferred with user acknowledgement" and flag the carrying task as elevated risk.
- **Always present approach options before writing details** (for non-trivial features). Never silently choose an approach without surfacing the trade-off.
- **Design stays at "what and why" level.** No specific variable names, no line-by-line algorithm internals — those belong in `/forge:code`.
- **Every component must specify which conventions layer it belongs to.** A new class without a layer assignment violates the architecture rules.
- **Any deviation from conventions.md must be explicitly flagged**, with the reason stated. Never silently violate a convention.
- **Open Decisions block writing the artifact.** Only deferred-with-acknowledgement items are allowed to remain; all blocking questions must be answered.

---

## Prerequisites

### Required inputs (check in order)

**1. Feature context** — try to read `.forge/clarify-{feature-slug}.md`.

If it does not exist:
```
[FORGE:DESIGN] Missing clarify artifact

.forge/clarify-{feature-slug}.md not found.

Options:
1. Run /forge:clarify "{feature-slug}" first (recommended)
2. Proceed anyway — I will ask you for the necessary context

Which do you prefer?
```

If the user chooses to proceed anyway, ask for:
- What needs to be built or changed
- The affected parts of the codebase (if known)
- Any known constraints

**2. Conventions** — try to read `.forge/conventions.md`.

If it does not exist, note this and proceed. Flag clearly in the output
that the design was made without convention constraints.

---

## Process

### Step 1 — Understand the requirement

Read `.forge/clarify-{feature-slug}.md` in full (or the user's context).
Identify:
- What capability is being added or changed
- The affected components and data flows
- Gaps that still exist (things not yet implemented)
- Open Questions from the clarify artifact — if any are unresolved and
  blocking, ask the user to resolve them before proceeding

### Step 2 — Understand the conventions

Read `.forge/conventions.md`. Extract constraints relevant to this feature:
- Which layer owns the new logic
- Naming rules for new files, classes, functions, DB tables
- Error handling approach
- Testing requirements
- Any "What to Avoid" entries that apply here

### Step 3 — Explore technical approaches (forge-architect agents)

For features with meaningful architectural choices, spawn **2–3 forge-architect
agents in parallel**, each tasked with a different direction:

- Agent 1: the most straightforward extension of existing patterns
- Agent 2: a cleaner approach that may require more upfront work
- Agent 3 (optional): a genuinely alternative paradigm

Each agent receives: the clarify artifact, relevant sections of
conventions.md, and its assigned direction.

For small, clearly-scoped features with no real architectural choice, skip
multi-agent exploration and proceed directly to Step 4.

### Step 4 — Present options and confirm approach

Present options and recommendation to the user:

```
[FORGE:DESIGN] Approach options for {feature-slug}

Option A — {name}: {one sentence}
  Pros: ...
  Cons: ...

Option B — {name}: {one sentence}
  Pros: ...
  Cons: ...

Recommended: Option A, because {reason}.

Confirm approach, or choose a different one?
```

Once confirmed, define it in full detail:
- Exact files to create, modify, or delete
- What each change entails
- API contract changes (endpoints, request/response shapes)
- Data model changes (tables, fields, indexes, migrations)
- The layer each new component belongs to (per conventions.md)

### Step 5 — Impact analysis

Identify everything that could break or require updating:
- Other modules depending on the affected code
- Existing tests that will need updating
- API consumers affected by contract changes
- Configuration or environment variable changes required

Assign a risk level: **Low / Medium / High**.

### Step 6 — Surface open decisions

Identify decisions requiring human input before the design is finalised.
These are blocking — do not write the artifact until they are resolved.

```
[FORGE:DESIGN] Decisions needed before finalising design ({N} items)

1. {Question}
   Context: {why this matters}
   Options: A) ... B) ...

2. {Question}
   ...

Please answer each item.
```

Record all answers in the "Key Decisions" section. If the user explicitly
defers an item, mark it "deferred" and add it to Open Decisions with a
risk note for the plan.

### Step 7 — Write the design artifact

Write `.forge/design-{feature-slug}.md` following the output template.

---

## Output

**File:** `.forge/design-{feature-slug}.md`

```markdown
# Design: {feature-slug}

> 基于：clarify-{feature-slug}.md + conventions.md
> 生成时间：YYYY-MM-DD
> [注：无 clarify artifact，需求来自用户直接描述] ← 删除如不适用
> [注：无 conventions.md，设计不受约定约束] ← 删除如不适用

---

## Solution Overview

Two to four sentences describing the chosen approach and why it fits the
codebase and requirements.

---

## Approach Options

Only include if multiple approaches were explored.

| Option | Description | Pros | Cons | Verdict |
|--------|-------------|------|------|---------|
| A — {name} | ... | ... | ... | ✅ Chosen / ❌ Rejected |
| B — {name} | ... | ... | ... | ❌ Rejected — reason |

---

## Component Changes

### New Components

| Path | Layer | Type | Responsibility |
|------|-------|------|----------------|
| `path/to/new-file` | service / repository / controller / ... | class / function / config | What it does |

### Modified Components

| Path | What Changes | Why |
|------|-------------|-----|
| `path/to/existing-file` | Description of change | Reason |

### Deleted Components

| Path | Reason |
|------|--------|
| `path/to/removed-file` | Why it is being removed |

---

## API Changes

Describe new, modified, or removed API endpoints or function signatures.

_None_ if no API changes.

---

## Data Model Changes

Describe new tables, fields, indexes, or schema changes. Include migration
strategy if data already exists.

_None_ if no data model changes.

---

## Impact Analysis

| Area | Risk | Description |
|------|------|-------------|
| `path/or/module` | Low / Medium / High | What is affected and how |

---

## Key Decisions

| Decision | Options Considered | Chosen | Rationale |
|----------|--------------------|--------|-----------|
| ... | A / B | A | Because ... |

---

## Constraints & Trade-offs

What was ruled out and why. Helps future readers understand the design.

---

## Convention Deviations

Any intentional deviation from conventions.md. If empty, write _None_.

| Convention | Deviation | Reason |
|------------|-----------|--------|

---

## Open Decisions

Must be resolved before planning can begin. Write _None_ if all resolved.

| # | Question | Context | Status |
|---|----------|---------|--------|
| 1 | ... | ... | ⏳ Deferred (user acknowledged) — risk: {level} |
```

---

## Interaction Rules

- **Approach selection is always confirmed** before writing component details.
- **Open Decisions block the artifact.** Only deferred-with-acknowledgement
  items are permitted to remain unresolved.
- Keep the design at the **what and why** level.
- If the clarify artifact has unresolved Open Questions, treat each as a
  potential blocking decision.

---

## Constraints

- Do not modify any source files.
- Do not include implementation code (pseudocode and method signatures only).
- Do not silently choose between viable options — always surface trade-offs.
- If conventions.md exists, all choices must be consistent with it or
  explicitly noted as deviations.
