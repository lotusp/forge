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
- Conventions available: !`test -f .forge/context/conventions.md && echo "YES — will enforce" || echo "NO — proceed without constraints"`
- Testing conventions available: !`test -f .forge/context/testing.md && echo "YES" || echo "NO"`
- Plan files: !`ls .forge/features/*/plan.md 2>/dev/null || echo "(none found)"`

---

## IRON RULES

These rules have no exceptions.

- **Read `context/conventions.md` and `context/testing.md` before writing any code.** Never write code first and check conventions after.
- **Never modify files outside the task's scope list.** If an out-of-scope change is required, stop and invoke the Scope Creep Protocol.
- **Never silently introduce a new pattern.** If the task requires a pattern not in `context/conventions.md` or the existing codebase, invoke the New Pattern Protocol and wait for confirmation.
- **Never silently expand scope.** Even if an adjacent improvement is obvious, log it in the summary rather than making it.
- **Never start a task with unmet dependencies.** Check that each dependency's summary file exists before writing a single line.
- **One task at a time.** If the user provides multiple IDs, implement, summarise, and confirm each before starting the next.
- **Document assumptions as they are made.** Any decision not explicitly specified in the task description or `conventions.md` is an assumption. Record it immediately in the Assumptions Made section — not retrospectively.
- **R21 — Never assume undocumented development conventions.** If the task requires a development practice (unit tests, TDD, commit format, branching, review process) not covered by `conventions.md § Development Workflow` or other context files, Step 0.5 MUST trigger a focused Q&A before implementation begins.
- **R22 — Convention gap answers persist.** Answers to Step 0.5 Q&A MUST be written back to the appropriate context file (default `conventions.md § Development Workflow`; testing-specific → `testing.md`; architecture-level → `architecture.md`). Future runs must not ask the same question again.

---

## Prerequisites

### Locate the task

Search all `.forge/features/*/plan.md` files for the given task ID (e.g. `T003`).

If not found:
```
[forge:code] Task not found

{task-id} was not found in any .forge/features/*/plan.md file.

Available plan files:
- .forge/features/{slug}/plan.md  (tasks T00X – T00Y)
- ...

Please check the task ID and try again.
```

Once found, read the full task entry: description, dependencies, scope, and
acceptance criteria.

### Check dependencies

If the task lists dependencies, verify each dependency's summary file exists
at `.forge/features/{feature-slug}/tasks/T{dep-id}-summary.md`.

```
[forge:code] Dependency not met

{task-id} depends on {dep-id}, which has not been completed.
(.forge/features/{feature-slug}/tasks/{dep-id}-summary.md not found)

Complete {dep-id} first, then retry.
```

### Load conventions

Read `.forge/context/conventions.md` and `.forge/context/testing.md` in full.
Every rule is binding. If they do not exist, note the absence in the summary
and proceed — but flag it.

---

## Process

### Step 0.5 — Convention Gap Check (R21, R22)

Before reading the task scope, check whether `conventions.md` (and
testing.md / architecture.md as relevant) documents the development
practices this task will need. This is a **non-invasive** check: if
the needed conventions are already present, Step 0.5 completes silently
and Step 1 begins immediately.

**0.5.1 — Infer required conventions from task type + scope**

| Task type | Required conventions to check |
|-----------|------------------------------|
| `test` | `testing.md § <framework / location / mock strategy / coverage>` |
| `logic` / `api` / `model` | `conventions.md § Development Workflow` (TDD preference, commit format) |
| `migration` | `conventions.md § Development Workflow` + migration practice |
| `docs` | `conventions.md § Development Workflow § commit format` |
| `skill` / `agent` / `profile` / `kind-def` (claude-code-plugin) | `conventions.md § Artifact Writing + SKILL Format` |

**0.5.2 — Detect gaps**

For each required convention:
```pseudo
required = infer_required_conventions(task)
gaps = []

for conv in required:
    section = find_section(conventions_or_related, conv)
    if section is None or section is empty:
        gaps.append(conv)
```

**0.5.3 — If no gaps: proceed silently**

If `gaps` is empty, emit a single line:
```
[forge:code] Conventions covered. Proceeding with T{id}.
```
Then jump to Step 1.

**0.5.4 — If gaps exist: Q&A then persist**

Present a focused, task-scoped Q&A. Only ask about conventions that
THIS task needs (not a general interview):

```
[forge:code T{id}] Convention gap detected

This task ({task-name}) requires {N} development practice(s) that
.forge/context/conventions.md does not yet document:

Q1. {practice name}
    Why: <how it affects this task>
    Options: [A] <choice> / [B] <choice> / [C] <other>
    Recommend: <X>, because <reason>

Q2. {practice name}
    ...

Your answers will be written to {target file} § {target section}
so all future /forge:code runs inherit them silently.
```

Wait for user answers. Once received:

1. Write answers back to the appropriate file + section (per R22)
2. If the file's relevant section doesn't exist, create it with a
   section marker (following onboard's section marker schema)
3. Re-read the conventions file (to have authoritative state)
4. Proceed to Step 1

**0.5.5 — Example: first-task-in-project trigger**

When the very first `/forge:code` runs in a project, it's almost
certain that some development conventions haven't been captured
(because onboard Stage 3 focused on production patterns, not
workflow-level practices like TDD preference). Step 0.5 naturally
interviews the user once, persists answers, and subsequent runs
proceed without friction.

**Non-triggers:** If conventions already cover what this task needs,
do NOT ask again. Respect the user's time.

---

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

**Naming:** Match `context/conventions.md`. If silent, match adjacent similar code.

**Patterns:** Replicate patterns from adjacent code. Never introduce a new
pattern without flagging it first (New Pattern Protocol below).

**Migration scripts:** If type is `migration`, generate following the project's
existing migration format and naming convention.

**API changes:** If type is `api`, update the contract definition and any
generated client code alongside the implementation.

**Assumption tracking:** Whenever you make a decision not grounded in the
task spec or conventions.md, write it down immediately as a draft assumption
entry before continuing. Do not rely on reconstructing these retrospectively.
Format: `Assumed [X] because [basis]. Risk: [low/medium/high].`

### Step 4 — Verify acceptance criteria

Go through each criterion in the task entry and confirm it is met.
For criteria requiring runtime verification, note them explicitly rather
than claiming they pass.

### Step 5 — Write the summary

Write `.forge/features/{feature-slug}/tasks/{task-id}-summary.md`. This file
is required — downstream tasks use it to verify dependency completion, and
`/forge:inspect` reads it to understand which deviations and assumptions were
intentional.

### Step 6 — Append to JOURNAL.md

Append one entry to `.forge/JOURNAL.md` (create the file if it does not exist):

```markdown
## YYYY-MM-DD — /forge:code {task-id} [{feature-slug}]
- 变更：{comma-separated list of files changed}
- 假设：{count} 条 — 详见 tasks/{task-id}-summary.md § Assumptions Made
- 下一步：{next task ID if more remain, or /forge:inspect {slug} if all done}
```

If there were no assumptions, write `假设：无` instead.

---

## Scope Creep Protocol

If implementing the task requires touching files outside the scope list:

1. **Stop immediately.** Do not make the out-of-scope change.
2. Report to the user:

```
[forge:code] Scope expansion needed — stopping

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
[forge:code] New pattern required

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

**Summary file:** `.forge/features/{feature-slug}/tasks/{task-id}-summary.md`

```markdown
# Code Summary: {task-id}

> Feature: {feature-slug} | 完成时间：YYYY-MM-DD

## Changes Made

| File | Action | Description |
|------|--------|-------------|
| `path/to/file` | created / modified / deleted | What changed and why |

## Assumptions Made

Decisions made during implementation that were not explicitly specified in
the task description or `conventions.md`. Each entry must cite its basis.
`/forge:inspect` will not penalise assumptions documented here.

| Assumption | Basis | Risk |
|-----------|-------|------|
| {What was assumed} | {conventions.md §X / adjacent code in Y / design intent} | low / medium / high |

_No assumptions made — all decisions traced to task spec or conventions._ ← use this if none

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
