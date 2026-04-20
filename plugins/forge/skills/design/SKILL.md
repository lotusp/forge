---
name: design
description: |
  Produces a concrete technical design for a feature, grounded in existing
  codebase conventions and prior requirement analysis. Use after /forge:clarify
  has produced a clarify artifact, or when the user provides sufficient context
  directly.
argument-hint: "<feature-slug>"
allowed-tools: "Read Glob Grep Bash Write"
model: sonnet
effort: high
---

## Runtime snapshot
- Existing .forge features: !`ls .forge/features/ 2>/dev/null || echo "(none)"`
- Conventions available: !`test -f .forge/context/conventions.md && echo "YES — will enforce" || echo "NO — design will be unconstrained"`

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

**1. Feature context** — try to read `.forge/features/{feature-slug}/clarify.md`.

If it does not exist:
```
[forge:design] Missing clarify artifact

.forge/features/{feature-slug}/clarify.md not found.

Options:
1. Run /forge:clarify "{feature-slug}" first (recommended)
2. Proceed anyway — I will ask you for the necessary context

Which do you prefer?
```

If the user chooses to proceed anyway, ask for:
- What needs to be built or changed
- The affected parts of the codebase (if known)
- Any known constraints

**2. Conventions** — try to read `.forge/context/conventions.md`.

If it does not exist, note this and proceed. Flag clearly in the output
that the design was made without convention constraints.

---

## Process

### Step 1 — Understand the requirement

Read `.forge/features/{feature-slug}/clarify.md` in full (or the user's context).
Identify:
- What capability is being added or changed
- The affected components and data flows
- Gaps that still exist (things not yet implemented)
- Open Questions from the clarify artifact — if any are unresolved and
  blocking, ask the user to resolve them before proceeding

### Step 2 — Understand the conventions

Read `.forge/context/conventions.md`. Extract constraints relevant to this feature:
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
`context/conventions.md`, and its assigned direction.

For small, clearly-scoped features with no real architectural choice, skip
multi-agent exploration and proceed directly to Step 4.

### Step 4 — Present options and confirm approach

Present options and recommendation to the user:

```
[forge:design] Approach options for {feature-slug}

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
[forge:design] Decisions needed before finalising design ({N} items)

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

Write `.forge/features/{feature-slug}/design.md` following the output template.

### Step 8 — Append to JOURNAL.md

Append one entry to `.forge/JOURNAL.md`:

```markdown
## YYYY-MM-DD — /forge:design {feature-slug}
- 产出：.forge/features/{slug}/design.md
- 方案：{chosen approach name}, 风险：low / medium / high
- 遗留决策：{N} 个 deferred（见 design.md § Open Decisions）
- 下一步：/forge:tasking {slug}
```

---

## Output

**File:** `.forge/features/{feature-slug}/design.md`

See [output-template.md](reference/output-template.md) for the complete artifact template.

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
- If `.forge/context/conventions.md` exists, all choices must be consistent with it or
  explicitly noted as deviations.
