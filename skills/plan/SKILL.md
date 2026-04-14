---
name: plan
description: |
  Breaks an approved feature design into an ordered, executable task list
  with clear acceptance criteria and dependency graph. Use after /forge:design
  has produced a design artifact for the feature.
argument-hint: "<feature-slug>"
allowed-tools: "Read Glob Grep"
model: sonnet
effort: medium
---

## Prerequisites

Before planning, read `.forge/design-{feature-slug}.md`. If it does not exist:

```
[FORGE:PLAN] Missing prerequisite

Cannot find .forge/design-{feature-slug}.md.
Please run /forge:design {feature-slug} first.
```

Also scan all existing `.forge/plan-*.md` files to find the highest Task ID
currently in use (e.g. `T007`), so new tasks continue the global sequence.
If no plan files exist yet, start from `T001`.

---

## Process

### Step 1 — Read the design
Read `.forge/design-{feature-slug}.md` in full. Identify every distinct unit
of work mentioned:
- New files to create
- Existing files to modify
- Schema / migration changes
- API contract changes
- Test additions
- Documentation updates

### Step 2 — Decompose into atomic tasks
Each task must be:
- **Completable in one session** — if a task touches more than ~5 files or
  requires more than one logical concern, split it
- **Independently verifiable** — has clear acceptance criteria that can be
  checked without running the full system
- **Scoped to a type**: `infra` / `model` / `migration` / `logic` / `api` /
  `ui` / `test` / `docs`

### Step 3 — Assign Task IDs
Assign IDs continuing from the highest existing ID found in Step 0.
Format: `T{NNN}` with zero-padded three digits (T001, T002, ... T099, T100).

**Task IDs are globally unique across the entire project**, not scoped to a
feature. Never reuse or reset IDs.

### Step 4 — Identify dependencies
For each task, determine which other tasks (by ID) must complete before it
can start. A task has a dependency when it:
- Reads a file created by another task
- Builds on a schema or model defined by another task
- Tests behaviour implemented by another task

### Step 5 — Flag risk
Mark tasks `⚠ 高风险` when they:
- Touch shared infrastructure or configuration
- Involve data migration or schema changes
- Modify a public API contract
- Have unclear acceptance criteria (surface the ambiguity)

### Step 6 — Confirm before writing
Present a brief summary of the task breakdown to the user:

```
[FORGE:PLAN] Task breakdown for {feature-slug}

Tasks identified: N
  T00X  [type]  Task name
  T00Y  [type]  Task name  ← depends on T00X
  ...

Execution order: T00X → T00Y → ...

Ready to write .forge/plan-{feature-slug}.md? (yes / adjust first)
```

If the user requests adjustments, revise and re-confirm before writing.

### Step 7 — Write the plan artifact
Write `.forge/plan-{feature-slug}.md` following the output template below.

---

## Output

**File:** `.forge/plan-{feature-slug}.md`

```markdown
# Plan: {feature-slug}

> 基于：design-{feature-slug}.md
> 生成时间：YYYY-MM-DD

---

## Task List

### T00X — {Task Name} `{type}` [⚠ 高风险]
**描述：** One sentence explaining what this task implements and why.
**依赖：** 无 / T00A, T00B
**范围：**
- Create / modify `path/to/file` — reason
- ...

**验收标准：**
- [ ] Specific, checkable condition
- [ ] ...

**规模预估：** small / medium / large

---

### T00Y — {Task Name} `{type}`
...

---

## Dependency Graph

{ASCII or text representation showing which tasks block which}

Example:
T001 → T003 → T005
T002 → T003

## Risk Register

| Task | Risk | Mitigation |
|------|------|------------|
| T00X | Description of risk | How to reduce it |

## Execution Order

Recommended sequence accounting for dependencies and parallelism opportunities.
Tasks on the same line can run in parallel.

1. T001
2. T002, T003  ← parallel
3. T004
```

---

## Interaction Rules

- **Always confirm the task list before writing the file** (Step 6). The user
  may want to merge, split, or reorder tasks.
- If the design document has an "Open Decisions" section with unresolved items,
  stop and ask the user to resolve them before planning. Unresolved decisions
  produce tasks with unclear scope.
- If a task's scope is ambiguous (you cannot write concrete acceptance
  criteria), flag it rather than inventing criteria.

---

## Constraints

- Do not create tasks for work not mentioned in the design document.
- Do not merge unrelated concerns into a single task to reduce count.
- Do not assign acceptance criteria that require running the full system
  to verify — keep them observable at the file / unit level where possible.
- Do not modify any source files. This skill is read-only except for writing
  the plan artifact.
