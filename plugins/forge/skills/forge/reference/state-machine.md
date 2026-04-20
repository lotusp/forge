# Forge Workflow State Machine

This document defines the authoritative state transitions for the Forge
workflow. Referenced by `/forge:forge` and `scripts/status.mjs`.

---

## Workflow Stages (in order)

```
onboard → calibrate → clarify → design → tasking → code → inspect → test
```

Each stage produces an artifact in `.forge/`. The presence of an artifact
is the canonical record that a stage is complete.

---

## Artifact → Stage Mapping

| Artifact | Stage completed |
|----------|----------------|
| `.forge/context/onboard.md` | onboard |
| `.forge/context/conventions.md` | calibrate (conventions dimension) |
| `.forge/context/testing.md` | calibrate (testing dimension) |
| `.forge/context/architecture.md` | calibrate (architecture dimension) |
| `.forge/context/constraints.md` | calibrate (constraints dimension) |
| `.forge/features/{slug}/clarify.md` | clarify for {slug} |
| `.forge/features/{slug}/design.md` | design for {slug} |
| `.forge/features/{slug}/plan.md` | tasking for {slug} |
| `.forge/features/{slug}/tasks/{taskId}-summary.md` | code for {taskId} |
| `.forge/features/{slug}/inspect.md` | inspect for {slug} |
| `.forge/features/{slug}/test.md` | test for {slug} |

---

## State Transitions

### Project-wide preconditions (gate before any feature work)

```
[start]
  │
  ├── .forge/context/onboard.md missing?  → run /forge:onboard
  │
  └── .forge/context/conventions.md missing?  → run /forge:calibrate
```

These are hard gates. No feature work can proceed without both artifacts.

### Per-feature state machine

```
[new feature request]
  │
  ▼
CLARIFY — run /forge:clarify {slug}
  │ produces: .forge/features/{slug}/clarify.md
  ▼
DESIGN — run /forge:design {slug}
  │ produces: .forge/features/{slug}/design.md
  ▼
TASKING — run /forge:tasking {slug}
  │ produces: .forge/features/{slug}/plan.md  (contains T001..TN task list)
  ▼
CODE (loop) — run /forge:code {task-id}  ← repeat for each pending task
  │ produces: .forge/features/{slug}/tasks/{task-id}-summary.md per task
  │ loop exits when all task IDs in plan.md have a summary file
  ▼
INSPECT — run /forge:inspect {slug}
  │ produces: .forge/features/{slug}/inspect.md
  │ verdict: ready / needs-work / needs-redesign
  │
  ├── needs-work? → return to CODE for must-fix items, then re-run INSPECT
  ├── needs-redesign? → return to DESIGN
  │
  ▼
TEST — run /forge:test {slug}
  │ produces: .forge/features/{slug}/test.md
  ▼
[complete]
```

---

## Determining "next action" from state

The `scripts/status.mjs` script applies this logic:

```
1. If no context/onboard.md → suggest onboard
2. If no context/conventions.md → suggest calibrate
3. If explicit task ID given (T001) → suggest code {task-id}
4. If explicit feature slug given:
     - Find slug's current phase (highest artifact present)
     - Suggest the next phase after that
5. If no argument:
     - Find all in-progress features (not complete)
     - Pick the most advanced one (closest to completion wins)
     - Suggest its next phase
6. If no in-progress features and no argument:
     - Ask user for intent
```

---

## Feature phase priority (for "most advanced" selection)

When multiple features are in progress, the orchestrator continues the
one closest to completion first. Priority order (highest = most advanced):

```
inspect > code > tasking > design > clarify
```

Rationale: finishing a feature in progress is more valuable than starting
a new one from scratch.

---

## Edge cases

### "needs-work" after inspect
The `features/{slug}/inspect.md` file exists but the verdict is `needs-work`.
The orchestrator detects this by reading the first few lines of the
inspect artifact. If `needs-work` is found, it routes back to `code`
with the task IDs from the "Findings" section.

(TODO: implement this edge case in `status.mjs` — currently it routes
to `test` once `review-*.md` exists, regardless of verdict.)

### Re-calibrating
Running `/forge:forge calibrate` explicitly always routes to calibrate,
even if `conventions.md` already exists. The calibrate skill handles
the "already exists" warning internally.

### Re-onboarding
Similarly, `/forge:forge onboard` always routes to onboard.

---

## What the orchestrator does NOT do

- Does not merge, commit, or branch (git operations are out of scope)
- Does not run tests (delegates to `/forge:test`)
- Does not modify source files directly (delegates to `/forge:code`)
- Does not skip user confirmation steps required by sub-skills
