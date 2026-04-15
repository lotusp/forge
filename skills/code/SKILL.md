---
name: code
description: |
  Implements a specific task from the plan, strictly following project
  conventions. Use with a task ID (e.g. /forge:code T003). Reads the
  plan artifact to find the task, then implements only what that task
  specifies.
argument-hint: "<task-id>"
allowed-tools: "Read Glob Grep Write Edit Bash"
model: sonnet
effort: high
---

## Prerequisites

### Locate the task

Search all `.forge/plan-*.md` files for the given task ID (e.g. `T003`).

If no plan file contains the task ID:
```
[FORGE:CODE] Task not found

{task-id} was not found in any .forge/plan-*.md file.

Available plan files:
- .forge/plan-{slug}.md  (tasks T00X – T00Y)
- ...

Please check the task ID and try again.
```

Once found, read the full task entry: description, dependencies, scope, and
acceptance criteria.

### Check dependencies

If the task lists dependencies (other task IDs), verify that each dependency's
summary file exists at `.forge/code-{dep-id}-summary.md`. Missing summaries
mean the dependency has not been completed.

```
[FORGE:CODE] Dependency not met

{task-id} depends on {dep-id}, which has not been completed.
(.forge/code-{dep-id}-summary.md not found)

Complete {dep-id} first, then retry.
```

### Load conventions

Read `.forge/conventions.md` if it exists. All code produced must comply with
every applicable rule. If conventions.md does not exist, note this and proceed
— but flag the absence in the summary.

---

## Process

### Step 1 — Read the task scope

From the plan entry, extract:
- The exact files to create or modify (the **scope list**)
- What each file change entails
- The acceptance criteria (these drive what "done" means)

Do not infer additional files. If implementing the task correctly requires
touching files not in the scope list, **stop** — see Scope Creep below.

### Step 2 — Read existing files

Read every file in the scope list that already exists. Also read files that
the scope files import or depend on, so the new code fits naturally into the
surrounding patterns.

Note the existing:
- Naming conventions (variables, functions, classes, files)
- Code structure (how similar things are done in adjacent files)
- Error handling style
- Import/export patterns
- Test patterns (if writing test files)

### Step 3 — Implement

Write or edit each file in the scope list. Every decision must be traceable
to either the task specification or the existing code patterns — not personal
preference.

**Naming:** Match the conventions observed in Step 2. If conventions.md
specifies naming rules, those take precedence.

**Patterns:** Replicate the patterns used in adjacent, similar code. Do not
introduce a new pattern without flagging it (see Constraints).

**Database / schema changes:** If the task type is `migration`, generate the
migration script following the project's existing migration format.

**API changes:** If the task type is `api`, update the contract definition
and any generated client code alongside the implementation.

### Step 4 — Verify acceptance criteria

Go through each acceptance criterion in the task entry and confirm it is met.
For criteria that require running the system (e.g. "endpoint returns 200"),
note them as "requires runtime verification" rather than claiming they pass.

### Step 5 — Write the summary

Write `.forge/code-{task-id}-summary.md` (see Output template).

---

## Scope Creep Protocol

If, during implementation, you discover that the task **cannot be completed
correctly** without modifying files outside the scope list:

1. **Stop immediately.** Do not make the out-of-scope change.
2. Write a scope creep report to the user:

```
[FORGE:CODE] Scope expansion needed — stopping

While implementing {task-id}, I found that completing it correctly
also requires changing:

  - `path/to/out-of-scope-file`
    Reason: {why this file needs to change}

Options:
1. Add this file to {task-id}'s scope and continue
2. Create a new task in the plan for this change, and complete it first
3. Proceed without the change (explain trade-off)

Which do you prefer?
```

Wait for the user's decision before continuing.

---

## New Pattern Protocol

If implementing the task requires introducing a pattern not present in
conventions.md or the existing codebase:

```
[FORGE:CODE] New pattern required

To implement {task-id}, I need to introduce a pattern not currently
in the codebase or conventions:

  Pattern: {description}
  Reason it's needed: {why existing patterns don't work here}
  Proposed approach: {what I intend to do}

Should I proceed with this approach, or do you prefer a different one?
```

Wait for confirmation before writing the code.

---

## Output

**Files modified/created:** as specified in the task scope.

**Summary file:** `.forge/code-{task-id}-summary.md`

```markdown
# Code Summary: {task-id}

> Feature: {feature-slug} | 完成时间：YYYY-MM-DD

## Changes Made

| File | Action | Description |
|------|--------|-------------|
| `path/to/file` | created / modified / deleted | What changed and why |

## Key Implementation Decisions

Decisions made during implementation that are not obvious from the code.
Include: pattern choices, trade-offs, why a simpler approach was not used.

## Deviations from Plan

Any intentional differences from what the plan specified, with justification.
Leave empty if none.

## Scope Creep Warnings

Files that need changing but were left untouched because they are out of scope.
Each entry should reference the follow-up action agreed with the user.

## New Patterns Introduced

Any pattern not previously in the codebase, confirmed by the user.
Leave empty if none.

## Acceptance Criteria Status

- [x] Criterion that is met
- [ ] Criterion requiring runtime verification — {what to check}
- [ ] Criterion not yet met — {reason}
```

---

## Interaction Rules

- **Never silently expand scope.** Always report and confirm before touching
  files outside the task's scope list.
- **Never silently introduce new patterns.** Always flag and confirm first.
- **One task at a time.** If the user provides multiple task IDs, implement
  them sequentially, committing and summarising each before starting the next.
- If the task's acceptance criteria are ambiguous, ask for clarification
  before starting implementation — not after.

---

## Constraints

- Modify only files listed in the task's scope. Period.
- Do not refactor, clean up, or improve code outside the scope, even if it
  looks like it needs it. Log it in the summary instead.
- Do not add features or generalisations not required by the acceptance
  criteria. Implement exactly what is specified.
- Do not skip writing the summary file. It is required for dependency checking
  by subsequent tasks.
