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

## Runtime snapshot
- Conventions available: !`test -f .forge/conventions.md && echo "YES — will enforce" || echo "NO — proceed without constraints"`
- Plan files: !`ls .forge/plan-*.md 2>/dev/null || echo "(none found)"`

---

## IRON RULES

These rules have no exceptions.

- **Read `conventions.md` before writing any code.** Never write code first and check conventions after.
- **Never modify files outside the task's scope list.** If an out-of-scope change is required, stop and invoke the Scope Creep Protocol.
- **Never silently introduce a new pattern.** If the task requires a pattern not in `conventions.md` or the existing codebase, invoke the New Pattern Protocol and wait for confirmation.
- **Never silently expand scope.** Even if an adjacent improvement is obvious, log it in the summary rather than making it.
- **Never start a task with unmet dependencies.** Check that each dependency's summary file exists before writing a single line.
- **One task at a time.** If the user provides multiple IDs, implement, summarise, and confirm each before starting the next.

---

## Prerequisites

### Locate the task

Search all `.forge/plan-*.md` files for the given task ID (e.g. `T003`).

If not found:
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

If the task lists dependencies, verify each dependency's summary file exists
at `.forge/code-{dep-id}-summary.md`.

```
[FORGE:CODE] Dependency not met

{task-id} depends on {dep-id}, which has not been completed.
(.forge/code-{dep-id}-summary.md not found)

Complete {dep-id} first, then retry.
```

### Load conventions

Read `.forge/conventions.md` in full. Every rule is binding. If it does not
exist, note the absence in the summary and proceed — but flag it.

---

## Process

### Step 1 — Read the task scope

Extract from the plan entry:
- The exact files to create or modify (the **scope list**)
- What each file change entails
- The acceptance criteria (these define "done")

Do not infer additional files. Files not on the scope list are out of scope.

### Step 2 — Read existing files

Read every file in the scope list that already exists. Also read files they
import or depend on, so the new code fits naturally into surrounding patterns.

Note the existing:
- Naming conventions in adjacent files
- Code structure (how similar things are done nearby)
- Error handling style
- Import/export patterns
- Test patterns (if writing test files)

### Step 3 — Implement

Write or edit each file in the scope list. Every decision must trace to
either the task specification or the existing code patterns — not preference.

**Naming:** Match conventions.md. If conventions.md is silent, match adjacent
similar code.

**Patterns:** Replicate patterns from adjacent code. Never introduce a new
pattern without flagging it first (New Pattern Protocol below).

**Migration scripts:** If type is `migration`, generate following the project's
existing migration format and naming convention.

**API changes:** If type is `api`, update the contract definition and any
generated client code alongside the implementation.

### Step 4 — Verify acceptance criteria

Go through each criterion in the task entry and confirm it is met.
For criteria requiring runtime verification, note them explicitly rather
than claiming they pass.

### Step 5 — Write the summary

Write `.forge/code-{task-id}-summary.md`. This file is required — downstream
tasks use it to verify dependency completion.

---

## Scope Creep Protocol

If implementing the task requires touching files outside the scope list:

1. **Stop immediately.** Do not make the out-of-scope change.
2. Report to the user:

```
[FORGE:CODE] Scope expansion needed — stopping

While implementing {task-id}, I found that completing it correctly
also requires changing:

  - `path/to/out-of-scope-file`
    Reason: {why this file needs to change}

Options:
1. Add this file to {task-id}'s scope and continue
2. Create a new task in the plan for this change, complete it first
3. Proceed without the change (I'll explain the trade-off)

Which do you prefer?
```

Wait for the user's decision before continuing.

---

## New Pattern Protocol

If the task requires a pattern not in conventions.md or the existing codebase:

```
[FORGE:CODE] New pattern required

To implement {task-id}, I need to introduce a pattern not currently
in the codebase or conventions:

  Pattern: {description}
  Reason: {why existing patterns don't work here}
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

Decisions not obvious from the code: pattern choices, trade-offs, why a
simpler approach was not used.

## Deviations from Plan

Any intentional differences from what the plan specified, with justification.
Leave empty if none.

## Scope Creep Warnings

Files needing changes but left untouched (out of scope). Reference the
follow-up action agreed with the user.

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

- **Never silently expand scope.** Always report and confirm first.
- **Never silently introduce new patterns.** Always flag and confirm first.
- **One task at a time.** Implement, summarise, confirm, then start the next.
- If acceptance criteria are ambiguous, ask before starting — not after.

---

## Constraints

- Modify only files in the task's scope list.
- Do not refactor or improve code outside scope — log it in the summary.
- Do not add features not required by the acceptance criteria.
- Do not skip writing the summary file — it is required for dependency checking.
