---
name: design
description: |
  Produces a concrete technical design for a feature, grounded in existing
  codebase conventions and prior requirement analysis. Use after /forge:clarify
  has produced a clarify artifact, or when the user provides sufficient context
  directly.
argument-hint: "<feature-slug>"
allowed-tools: "Read Glob Grep"
model: sonnet
effort: high
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

If the user chooses to proceed anyway, ask for a brief description of:
- What needs to be built or changed
- The affected parts of the codebase (if known)
- Any known constraints

**2. Conventions** — try to read `.forge/conventions.md`.

If it does not exist, note this and proceed. Design decisions will be made
without convention constraints, which is acceptable for new projects or
early-stage work. Flag this clearly in the output.

---

## Process

### Step 1 — Understand the requirement

Read `.forge/clarify-{feature-slug}.md` in full (or use the context provided
by the user). Identify:

- What capability is being added or changed
- The affected components and data flows
- Gaps that still exist (things not yet implemented)
- Any constraints or non-goals stated in the clarify artifact

### Step 2 — Understand the conventions

Read `.forge/conventions.md`. Extract the constraints relevant to this feature:
- Architectural layering rules (which layer owns what)
- Naming conventions (files, classes, functions, DB tables)
- Error handling approach
- Testing requirements
- Any "What to Avoid" entries that apply here

If conventions.md does not exist, skip this step.

### Step 3 — Explore technical approaches (use forge-architect agents)

For features with meaningful architectural choices, spawn **2–3 forge-architect
agents in parallel**, each tasked with exploring a different direction:

- Agent 1: the most straightforward extension of existing patterns
- Agent 2: a cleaner approach that may require more upfront work
- Agent 3 (optional): an alternative if there is a genuinely different paradigm

Each agent receives:
- The clarify artifact (or the user's description)
- The relevant sections of conventions.md
- Its assigned direction to explore

Collect the agents' outputs and synthesize them into a comparison.

For small, clearly-scoped features with no real architectural choice, skip
the multi-agent exploration and proceed directly to Step 4.

### Step 4 — Select and define the approach

Present the options and your recommendation to the user if multiple approaches
were explored:

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

Once the approach is confirmed, define it in full detail:
- Exactly which files will be created, modified, or deleted
- What each change entails
- API contract changes (endpoints, request/response shapes)
- Data model changes (new tables, fields, indexes, migrations needed)

### Step 5 — Impact analysis

Identify everything that could break or require updating as a result of
this change:
- Other features or modules that depend on the affected code
- Existing tests that will need updating
- API consumers that may be affected by contract changes
- Configuration or environment variable changes required

Assign a risk level to each impact area: **Low / Medium / High**.

### Step 6 — Surface open decisions

Before writing the design document, identify any decisions that require
human input. These are **blocking** — the design must not proceed past this
point until they are resolved.

Examples of open decisions:
- A security-sensitive choice (auth strategy, data retention)
- A choice that affects other teams or systems
- A trade-off where you genuinely cannot recommend one option over another
- A business rule not derivable from the codebase

Present them as a numbered list and wait for answers:

```
[FORGE:DESIGN] Decisions needed before finalising design ({N} items)

1. {Question}
   Context: {why this matters}
   Options: A) ... B) ...

2. {Question}
   ...

Please answer each item. I will incorporate your answers into the design.
```

Record all answers in the "Key Decisions" section of the output.

If there are no open decisions, proceed directly to Step 7.

### Step 7 — Write the design artifact

Write `.forge/design-{feature-slug}.md` following the output template below.

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

Only include this section if multiple approaches were explored.

| Option | Description | Pros | Cons | Verdict |
|--------|-------------|------|------|---------|
| A — {name} | ... | ... | ... | ✅ Chosen / ❌ Rejected |
| B — {name} | ... | ... | ... | ❌ Rejected — reason |

---

## Component Changes

### New Components

| Path | Type | Responsibility |
|------|------|----------------|
| `path/to/new-file` | class / function / module / config | What it does |

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

Describe any new, modified, or removed API endpoints or function signatures.
Include request/response shapes where relevant.

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

All decisions made during this design session, including those resolved
through user input.

| Decision | Options Considered | Chosen | Rationale |
|----------|--------------------|--------|-----------|
| ... | A / B | A | Because ... |

---

## Constraints & Trade-offs

What was ruled out and why. This section helps future readers understand
why the design is what it is, not just what it is.

---

## Open Decisions

Decisions that **must be resolved before planning can begin**.

Leave this section empty (write _None_) if all decisions are resolved.

| # | Question | Context | Status |
|---|----------|---------|--------|
| 1 | ... | ... | ⏳ Pending / ✅ Resolved: {answer} |
```

---

## Interaction Rules

- **Approach selection is always confirmed with the user** before proceeding
  to write component details. Never assume the first approach is correct.
- **Open Decisions block the process.** Do not write the final design artifact
  until all blocking questions are answered.
- If the clarify artifact contains a "Gaps" section with unresolved items,
  treat each gap as a potential open decision — either design a solution for
  it or flag it explicitly.
- Keep the design at the **what and why** level. Implementation details
  (specific variable names, algorithm internals) belong in the code step.
- If the user asks to proceed without resolving an open decision, record the
  decision as "deferred" with the user's acknowledgement, and add a note in
  the plan that the task carrying the deferred decision carries elevated risk.

---

## Constraints

- Do not modify any source files. This skill is read-only except for writing
  the design artifact.
- Do not include implementation details that pre-empt the `code` skill's
  decisions (e.g. exact variable names, line-by-line logic).
- Do not silently choose between equally viable options — always surface
  the trade-off to the user.
- If conventions.md exists, all component and naming choices must be
  consistent with it. Flag any intentional deviation explicitly.
