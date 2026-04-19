---
name: tasking
description: |
  Breaks an approved feature design into an ordered, executable task list
  with clear acceptance criteria and dependency graph. Use after /forge:design
  has produced a design artifact for the feature.
argument-hint: "<feature-slug>"
allowed-tools: "Read Glob Grep"
model: sonnet
effort: medium
---

## Runtime snapshot
- Existing plan files: !`ls .forge/features/*/plan.md 2>/dev/null || echo "(none)"`
- Highest task ID in use: !`grep -rh "^### T[0-9]" .forge/features/*/plan.md 2>/dev/null | grep -oP 'T\d+' | sort -V | tail -1 || echo "none — start from T001"`

---

## IRON RULES

These rules have no exceptions.

- **Task IDs are globally unique across the entire project.** Always scan all existing plan files for the highest ID before assigning new ones. Never reset or reuse IDs.
- **Never create tasks not grounded in the design document.** Every task must map to a component, API change, data model change, or explicitly named work item in the design.
- **Every task must have ≥2 verifiable acceptance criteria.** Criteria that require running the full system are acceptable only when accompanied by at least one static/file-level criterion.
- **Never write the plan file before the task breakdown is confirmed by the user.** The confirmation step (Step 6) is mandatory.
- **Unresolved Open Decisions in the design block planning.** If the design has items in "Open Decisions" that are not marked "deferred with acknowledgement", stop and ask the user to resolve them first.

---

## Prerequisites

Before planning, read `.forge/features/{feature-slug}/design.md`. If it does not exist:

```
[forge:tasking] Missing prerequisite

Cannot find .forge/features/{feature-slug}/design.md.
Please run /forge:design {feature-slug} first.
```

Check the design's "Open Decisions" section. If any item is `⏳ Pending`
(not deferred), surface it:

```
[forge:tasking] Unresolved design decisions

The design has {N} unresolved decision(s). Planning cannot proceed until
these are resolved:

{list items}

Please resolve these in /forge:design, then retry.
```

Also scan all existing `.forge/features/*/plan.md` files to find the highest Task ID
currently in use. New tasks continue from that ID.

---

## Process

### Step 1 — Read the design

Read `.forge/features/{feature-slug}/design.md` in full. Identify every distinct unit
of work:
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
- **Independently verifiable** — has acceptance criteria checkable at the
  file or unit level
- **Scoped to a type**: `infra` / `model` / `migration` / `logic` / `api` /
  `ui` / `test` / `docs`

### Step 3 — Assign Task IDs

Continue from the highest ID found during Prerequisites.
Format: `T{NNN}` zero-padded (T001, T002, ... T099, T100).

### Step 4 — Identify dependencies

For each task, determine which other tasks must complete first. A dependency
exists when the task:
- Reads a file created by another task
- Builds on a schema or model defined by another task
- Tests behaviour implemented by another task

### Step 5 — Flag risk

Mark tasks `⚠ 高风险` when they:
- Touch shared infrastructure or configuration
- Involve data migration or schema changes
- Modify a public API contract
- Have unclear acceptance criteria (surface the ambiguity explicitly)
- Carry a deferred design decision (from "Open Decisions" in design artifact)

### Step 6 — Confirm before writing (mandatory)

Present the task breakdown to the user:

```
[forge:tasking] Task breakdown for {feature-slug}

Tasks identified: N
  T00X  [type]  Task name
  T00Y  [type]  Task name  ← depends on T00X  ⚠ 高风险
  ...

Execution order: T00X → T00Y → ...

Ready to write .forge/features/{feature-slug}/plan.md? (yes / adjust first)
```

Wait for confirmation. If the user requests adjustments, revise and
re-confirm before writing.

### Step 7 — Write the plan artifact

Write `.forge/features/{feature-slug}/plan.md` following the output template.

---

## Output

**File:** `.forge/features/{feature-slug}/plan.md`

See [output-template.md](reference/output-template.md) for the complete artifact template.

---

## Interaction Rules

- **Always confirm before writing** (Step 6). The user may want to merge,
  split, or reorder tasks.
- If the design has Open Decisions marked "deferred", the tasks that carry
  them must be flagged `⚠ 高风险` with the open decision noted.
- If a task's scope is ambiguous, flag it rather than inventing criteria.

---

## Constraints

- Do not create tasks for work not in the design document.
- Do not merge unrelated concerns into one task to reduce count.
- Do not assign criteria requiring full system execution as the only criterion.
- Do not modify any source files.
