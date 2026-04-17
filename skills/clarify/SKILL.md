---
name: clarify
description: |
  Deeply analyzes a requirement by tracing existing code paths, mapping data
  flows, and surfacing unknowns. Use when given a feature request or change
  requirement before design begins. Produces a structured clarify artifact
  that feeds into /forge:design.
argument-hint: "<requirement description>"
allowed-tools: "Read Glob Grep Bash"
model: sonnet
effort: high
---

## Runtime snapshot
- Existing .forge artifacts: !`ls .forge/ 2>/dev/null || echo "(none)"`
- Onboard available: !`test -f .forge/onboard.md && echo "YES" || echo "NO — exploration will take longer"`
- Conventions available: !`test -f .forge/conventions.md && echo "YES" || echo "NO"`

---

## IRON RULES

These rules have no exceptions.

- **Confirm interpretation before exploring.** If the requirement is vague or ambiguous, restate it and get confirmation before reading a single file.
- **Never assume answers to business rules.** Any rule, constraint, or edge case that cannot be read directly from the code is a question — not an assumption.
- **Use forge-explorer agents for tracing.** Do not trace call chains manually from memory. Spawn agents for each distinct entry point.
- **Never write the clarify artifact before questions are answered.** If the user ends the session early, write what is known and populate Open Questions — never invent answers.
- **Do not propose solutions.** Clarify is about understanding what exists and what is needed — not how to build it. Any design suggestion belongs in `/forge:design`.

---

## Prerequisites

Read `.forge/onboard.md` if it exists — it provides the module map and entry
points needed to locate relevant code quickly. If it does not exist, proceed
without it; exploration will take longer.

Read `.forge/conventions.md` if it exists — useful context for understanding
whether the requirement fits or conflicts with current patterns.

---

## Process

### Step 1 — Understand the requirement

Parse the user's input. Identify:
- The core capability being requested (in one sentence)
- The affected business domain or user-facing feature
- Key entities, actions, and data mentioned

Restate the requirement in precise technical terms and confirm with the user
before exploring if the input is vague. Do not start code exploration until
the interpretation is confirmed.

### Step 2 — Derive the feature slug

Generate a feature slug: 2–4 English words, kebab-case, capturing the essence
of the requirement. Example: `phone-verification`, `order-export-csv`.

Check that no existing `.forge/clarify-{slug}.md` uses the same slug. If a
collision exists, append a disambiguating word.

### Step 3 — Locate entry points

Based on the requirement, identify where in the codebase this feature starts:
- HTTP routes or GraphQL resolvers
- CLI command handlers
- Event/message consumers
- Scheduled job handlers
- Public API functions or exported module interfaces

Use Glob and Grep to find candidates. Read the most likely entry point files.

### Step 4 — Spawn forge-explorer agents

For each distinct entry point (or code path) identified, spawn a
**forge-explorer** agent. Each agent traces one path end-to-end and returns:
- The full call chain (with `file:line` references)
- Data flow (what data enters, how it transforms, where it goes)
- External dependencies encountered (third-party services, queues, DBs)
- Side effects observed (writes, events emitted, notifications sent)

Run agents in parallel when multiple entry points exist.

If the feature is entirely **new** (no existing code path to trace), skip
this step. Move directly to Step 5 and note that the implementation gap
covers the full requirement.

### Step 5 — Synthesise findings

Merge the agents' outputs. Build a single picture of:
- The current implementation (if any)
- All affected components and their relationships
- Where the gaps are (what doesn't exist yet that the requirement needs)

### Step 6 — Identify unknowns

Review the synthesised picture and list everything that **cannot be determined
from the codebase alone**:
- Business rules not encoded in code (pricing logic, eligibility rules)
- External system behaviour (third-party API contracts, SLA expectations)
- Runtime configuration (feature flags, environment-specific values)
- Implicit requirements not stated (edge cases, error behaviour, scale)
- Decisions with non-obvious correct answers (security trade-offs, UX choices)

### Step 7 — Ask structured questions

Group unknowns by importance and ask the user to resolve them. Present in
batches of at most 5. For each question:
- State the question clearly
- Explain why it matters (what design decision it unblocks)
- Offer options where you can, with a recommendation if applicable

```
[FORGE:CLARIFY] Questions — batch 1 of N

1. {Question}
   Why it matters: {Impact on design}
   Options: A) ... B) ...  (Recommend A because ...)

2. {Question}
   Why it matters: {Impact on design}

...

Please answer each. Type "skip" to defer any item to Open Questions.
```

After each batch is answered, incorporate the answers and ask the next batch
if there is one.

### Step 8 — Write the clarify artifact

Once all batches are resolved (or the user chooses to stop), write
`.forge/clarify-{feature-slug}.md` following the output template.

---

## Output

**File:** `.forge/clarify-{feature-slug}.md`

See [output-template.md](reference/output-template.md) for the complete artifact template.

---

## Interaction Rules

- **Confirm your interpretation first** before exploring if the requirement
  is vague or ambiguous.
- **Do not assume answers to unknowns.** Every business rule or edge case
  not readable from code must be listed as a question.
- **Batch questions, do not dump them all at once.** Present the most
  important 5 first.
- If the user says "just proceed" for a question, record a reasonable
  assumption in Assumptions Made and move on.
- If the user ends the session early, write the artifact with what is known
  and populate Open Questions.

---

## Constraints

- Do not modify any source files. This skill is read-only.
- Do not propose solutions or design decisions.
- Do not invent answers to unknown business rules.
